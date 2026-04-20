import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'game_widgets.dart';
import 'sound_service.dart';

// ── Game data models ─────────────────────────────────────────────────────────

class _Drop {
  double x; // 0..1 lane position
  double y; // 0..1 vertical
  Color color;
  int lane;
  bool caught;
  bool missed;
  double speed;
  final String id;

  _Drop({
    required this.x,
    required this.y,
    required this.color,
    required this.lane,
    required this.speed,
    required this.id,
    this.caught = false,
    this.missed = false,
  });
}

class _Bucket {
  final int lane;
  final Color color;
  final String label;
  double shake;

  _Bucket({required this.lane, required this.color, required this.label, this.shake = 0});
}

// ── Main game screen ─────────────────────────────────────────────────────────

class ColorMatchScreen extends StatefulWidget {
  const ColorMatchScreen({Key? key}) : super(key: key);

  @override
  State<ColorMatchScreen> createState() => _ColorMatchScreenState();
}

class _ColorMatchScreenState extends State<ColorMatchScreen> with TickerProviderStateMixin {
  final SoundService _sound = SoundService();
  final math.Random _rng = math.Random();

  int _score = 0;
  int _lives = 3;
  int _level = 1;
  bool _gameOver = false;
  bool _showConfetti = false;
  int _caught = 0;
  int _targetCatch = 10;

  final List<_Drop> _drops = [];
  late List<_Bucket> _buckets;
  late Timer _gameLoop;
  late Timer _spawnTimer;
  int _frameCount = 0;

  static const _bucketConfigs = [
    {'color': Color(0xFFFF6B6B), 'label': 'Red'},
    {'color': Color(0xFF4ECDC4), 'label': 'Teal'},
    {'color': Color(0xFFFFE66D), 'label': 'Yellow'},
    {'color': Color(0xFF7C6FFF), 'label': 'Purple'},
  ];

  @override
  void initState() {
    super.initState();
    _initBuckets();
    _startGame();
  }

  void _initBuckets() {
    _buckets = List.generate(4, (i) => _Bucket(
      lane: i,
      color: _bucketConfigs[i]['color'] as Color,
      label: _bucketConfigs[i]['label'] as String,
    ));
  }

  void _startGame() {
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), _tick);
    _spawnTimer = Timer.periodic(Duration(milliseconds: (1200 - _level * 80).clamp(400, 1200)), _spawnDrop);
  }

  void _spawnDrop(_) {
    if (_gameOver) return;
    final lane = _rng.nextInt(4);
    _drops.add(_Drop(
      id: '${DateTime.now().millisecondsSinceEpoch}_$lane',
      x: (lane + 0.5) / 4,
      y: 0,
      color: _buckets[lane].color,
      lane: lane,
      speed: (0.004 + _level * 0.0008).clamp(0.003, 0.012),
    ));
  }

  void _tick(Timer _) {
    if (_gameOver || !mounted) return;
    _frameCount++;
    setState(() {
      for (final drop in _drops) {
        if (!drop.caught && !drop.missed) {
          drop.y += drop.speed;
          if (drop.y > 1.05) {
            drop.missed = true;
            _lives--;
            _sound.playError();
            if (_lives <= 0) {
              _gameOver = true;
              _gameLoop.cancel();
              _spawnTimer.cancel();
            }
          }
        }
      }
      _drops.removeWhere((d) => d.missed || (d.caught && d.y > 1.1));
    });
  }

  void _onBucketTap(int lane) async {
    if (_gameOver) return;
    // Find lowest drop in this lane
    _Drop? target;
    double maxY = -1;
    for (final d in _drops) {
      if (d.lane == lane && !d.caught && !d.missed && d.y > maxY) {
        maxY = d.y;
        target = d;
      }
    }
    if (target == null) return;

    // Check color match
    if (target.color == _buckets[lane].color) {
      await _sound.playPop();
      setState(() {
        target!.caught = true;
        _score += 10 * _level;
        _caught++;
        if (_caught >= _targetCatch) {
          _level++;
          _caught = 0;
          _targetCatch = 10 + _level * 2;
          _showConfetti = true;
          _sound.playWin();
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) setState(() => _showConfetti = false);
          });
        }
      });
    } else {
      await _sound.playError();
      setState(() {
        _lives--;
        _buckets[lane].shake = 1;
        if (_lives <= 0) {
          _gameOver = true;
          _gameLoop.cancel();
          _spawnTimer.cancel();
        }
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _buckets[lane].shake = 0);
      });
    }
  }

  @override
  void dispose() {
    _gameLoop.cancel();
    _spawnTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final laneWidth = size.width / 4;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Stack(
          children: [
            // Game area
            Positioned.fill(
              bottom: 120,
              child: Stack(
                children: [
                  // Lane dividers
                  for (int i = 1; i < 4; i++)
                    Positioned(
                      left: i * laneWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 1, color: Colors.white.withOpacity(0.05)),
                    ),
                  // Drops
                  for (final drop in _drops)
                    if (!drop.missed)
                      _DropWidget(drop: drop, size: size, laneWidth: laneWidth),
                ],
              ),
            ),
            // Buckets
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                children: List.generate(4, (i) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () => _onBucketTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        transform: Matrix4.translationValues(
                          _buckets[i].shake * 4 * math.sin(_frameCount * 0.5),
                          0,
                          0,
                        ),
                        height: 80,
                        decoration: BoxDecoration(
                          color: _buckets[i].color.withOpacity(0.2),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          border: Border.all(color: _buckets[i].color, width: 2.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.water_drop_rounded, color: _buckets[i].color, size: 26),
                            const SizedBox(height: 2),
                            Text(
                              _buckets[i].label,
                              style: TextStyle(
                                color: _buckets[i].color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
              ),
            ),
            // HUD
            _buildHUD(size),
            // Progress bar
            Positioned(
              top: 56,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_caught/$_targetCatch', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      Text('Level $_level', style: const TextStyle(color: Color(0xFF4ECDC4), fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _caught / _targetCatch,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF4ECDC4)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            // Game over
            if (_gameOver) _buildGameOver(),
            // Confetti
            if (_showConfetti) const ConfettiOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHUD(Size size) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, _score),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: Colors.white70),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFFFE66D), size: 18),
                const SizedBox(width: 4),
                AnimatedCountUp(
                  value: _score,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(children: List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.favorite_rounded,
              size: 22,
              color: i < _lives ? const Color(0xFFFF6B6B) : Colors.white12,
            ),
          ))),
        ],
      ),
    );
  }

  Widget _buildGameOver() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: const Color(0xFF1e2a3a), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌊', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              const Text('All buckets spilled!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Score: $_score', style: const TextStyle(fontSize: 18, color: Color(0xFF4ECDC4))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GameButton(
                    color: const Color(0xFF4ECDC4),
                    onTap: () {
                      setState(() {
                        _score = 0; _lives = 3; _level = 1; _caught = 0;
                        _drops.clear(); _gameOver = false;
                        _gameLoop.cancel(); _spawnTimer.cancel();
                        _startGame();
                      });
                    },
                    child: const Row(children: [
                      Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  GameButton(
                    color: Colors.white12,
                    onTap: () => Navigator.pop(context, _score),
                    child: const Text('Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Drop widget ──────────────────────────────────────────────────────────────

class _DropWidget extends StatelessWidget {
  final _Drop drop;
  final Size size;
  final double laneWidth;

  const _DropWidget({required this.drop, required this.size, required this.laneWidth});

  @override
  Widget build(BuildContext context) {
    final gameHeight = size.height - 220;
    final cx = drop.x * size.width;
    final cy = drop.y * gameHeight;

    return Positioned(
      left: cx - 20,
      top: cy - 20,
      child: AnimatedOpacity(
        opacity: drop.caught ? 0 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 40,
          height: 44,
          child: CustomPaint(
            painter: _DropPainter(drop.color),
          ),
        ),
      ),
    );
  }
}

class _DropPainter extends CustomPainter {
  final Color color;
  _DropPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    final r = size.width / 2;

    // Teardrop shape
    final path = Path();
    path.moveTo(cx, 0);
    path.cubicTo(cx + r * 1.2, size.height * 0.4, cx + r, size.height * 0.8, cx, size.height);
    path.cubicTo(cx - r, size.height * 0.8, cx - r * 1.2, size.height * 0.4, cx, 0);
    path.close();
    canvas.drawPath(path, paint);

    // Shine
    final shinePaint = Paint()..color = Colors.white.withOpacity(0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - r * 0.25, size.height * 0.25), width: r * 0.5, height: r * 0.35),
      shinePaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
