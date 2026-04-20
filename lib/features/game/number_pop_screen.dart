import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'game_widgets.dart';
import 'sound_service.dart';

class NumberPopScreen extends StatefulWidget {
  const NumberPopScreen({Key? key}) : super(key: key);

  @override
  State<NumberPopScreen> createState() => _NumberPopScreenState();
}

class _NumberPopScreenState extends State<NumberPopScreen> with TickerProviderStateMixin {
  final SoundService _sound = SoundService();
  final math.Random _rng = math.Random();

  int _score = 0;
  int _lives = 3;
  int _level = 1;
  int _nextExpected = 1;
  int _totalBalloons = 5;
  bool _gameOver = false;
  bool _levelComplete = false;
  bool _showConfetti = false;

  late Timer _spawnTimer;
  final List<_Balloon> _balloons = [];
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  static const _colors = [
    Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFF7C6FFF),
    Color(0xFFFF9F43), Color(0xFF44CF6C), Color(0xFFFF78C4),
    Color(0xFF5BC0EB), Color(0xFFE8C547),
  ];

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
    _startLevel();
  }

  void _startLevel() {
    _balloons.clear();
    _nextExpected = 1;
    _totalBalloons = 4 + _level;
    _levelComplete = false;
    _spawnBalloons();
  }

  void _spawnBalloons() {
    final size = MediaQuery.of(context).size;
    final numbers = List.generate(_totalBalloons, (i) => i + 1)..shuffle(_rng);
    for (int i = 0; i < numbers.length; i++) {
      final col = _colors[_rng.nextInt(_colors.length)];
      _balloons.add(_Balloon(
        number: numbers[i],
        x: 0.1 + _rng.nextDouble() * 0.8,
        y: 0.15 + _rng.nextDouble() * 0.65,
        color: col,
        size: 64 + _rng.nextDouble() * 24,
        ctrl: AnimationController(vsync: this, duration: Duration(milliseconds: 600 + i * 80))
          ..forward(),
      ));
    }
    setState(() {});
  }

  void _onTapBalloon(_Balloon balloon) async {
    if (_gameOver || _levelComplete) return;
    if (balloon.popped) return;

    if (balloon.number == _nextExpected) {
      await _sound.playPop();
      setState(() {
        balloon.popped = true;
        _score += 10 * _level;
        _nextExpected++;
      });

      if (_nextExpected > _totalBalloons) {
        await _sound.playSuccess();
        setState(() {
          _levelComplete = true;
          _showConfetti = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        setState(() {
          _level++;
          _showConfetti = false;
          _startLevel();
        });
      }
    } else {
      await _sound.playError();
      _shakeCtrl
        ..reset()
        ..forward();
      setState(() {
        _lives--;
        if (_lives <= 0) _gameOver = true;
      });
    }
  }

  @override
  void dispose() {
    for (final b in _balloons) {
      b.ctrl.dispose();
    }
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF87CEEB), Color(0xFFE0F7FA)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Clouds (decorative)
              ..._buildClouds(size),
              // HUD
              _buildHUD(),
              // Game area
              if (!_gameOver)
                ..._balloons.map((b) => _BalloonWidget(
                  balloon: b,
                  onTap: () => _onTapBalloon(b),
                  screenSize: size,
                )),
              // Instruction
              if (!_gameOver)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Pop number  ',
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6B6B),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$_nextExpected',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Text('  next!', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ),
                ),
              // Level complete
              if (_levelComplete)
                Center(
                  child: _PulseWidget(
                    child: Text(
                      'Level $_level Done! 🎉',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                ),
              // Game over overlay
              if (_gameOver) _buildGameOverOverlay(),
              // Confetti
              if (_showConfetti) const ConfettiOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildClouds(Size size) {
    return [
      Positioned(top: 30, left: 20, child: _CloudShape(width: 80, opacity: 0.7)),
      Positioned(top: 60, right: 30, child: _CloudShape(width: 100, opacity: 0.5)),
      Positioned(top: 15, left: size.width * 0.4, child: _CloudShape(width: 60, opacity: 0.6)),
    ];
  }

  Widget _buildHUD() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.pop(context, _score),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: Color(0xFF333333)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFFFE66D), size: 20),
                const SizedBox(width: 4),
                AnimatedCountUp(
                  value: _score,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Level $_level',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          // Lives
          Row(
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Icon(
                Icons.favorite_rounded,
                size: 24,
                color: i < _lives ? const Color(0xFFFF6B6B) : Colors.grey.withOpacity(0.4),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😢', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text('Game Over!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFFFF6B6B))),
              const SizedBox(height: 8),
              Text('Score: $_score', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GameButton(
                    color: const Color(0xFF4ECDC4),
                    onTap: () {
                      setState(() {
                        _score = 0;
                        _lives = 3;
                        _level = 1;
                        _gameOver = false;
                        _startLevel();
                      });
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text('Play Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GameButton(
                    color: const Color(0xFFFF6B6B),
                    onTap: () => Navigator.pop(context, _score),
                    child: const Row(
                      children: [
                        Icon(Icons.home_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text('Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
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

// ── Balloon data model ───────────────────────────────────────────────────────

class _Balloon {
  final int number;
  double x, y;
  final Color color;
  final double size;
  bool popped;
  final AnimationController ctrl;

  _Balloon({
    required this.number,
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.ctrl,
    this.popped = false,
  });
}

// ── Balloon widget ───────────────────────────────────────────────────────────

class _BalloonWidget extends StatefulWidget {
  final _Balloon balloon;
  final VoidCallback onTap;
  final Size screenSize;
  const _BalloonWidget({required this.balloon, required this.onTap, required this.screenSize});

  @override
  State<_BalloonWidget> createState() => _BalloonWidgetState();
}

class _BalloonWidgetState extends State<_BalloonWidget> with SingleTickerProviderStateMixin {
  late AnimationController _popCtrl;
  late Animation<double> _popScale;

  @override
  void initState() {
    super.initState();
    _popCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _popScale = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _popCtrl, curve: Curves.easeInBack),
    );
  }

  @override
  void didUpdateWidget(_BalloonWidget old) {
    super.didUpdateWidget(old);
    if (widget.balloon.popped && !old.balloon.popped) {
      _popCtrl.forward();
    }
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.balloon;
    final size = widget.screenSize;
    final left = b.x * size.width - b.size / 2;
    final top = b.y * size.height - b.size / 2;

    return Positioned(
      left: left,
      top: top,
      child: ScaleTransition(
        scale: b.popped
            ? _popScale
            : Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(parent: b.ctrl, curve: Curves.elasticOut),
              ),
        child: GestureDetector(
          onTap: b.popped ? null : widget.onTap,
          child: _BalloonPainter(
            color: b.color,
            number: b.number,
            size: b.size,
          ),
        ),
      ),
    );
  }
}

class _BalloonPainter extends StatefulWidget {
  final Color color;
  final int number;
  final double size;
  const _BalloonPainter({required this.color, required this.number, required this.size});

  @override
  State<_BalloonPainter> createState() => _BalloonPainterState();
}

class _BalloonPainterState extends State<_BalloonPainter> with SingleTickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1800 + math.Random().nextInt(600)),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _float.value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Stack(
                children: [
                  // Shine
                  Positioned(
                    top: widget.size * 0.12,
                    left: widget.size * 0.2,
                    child: Container(
                      width: widget.size * 0.25,
                      height: widget.size * 0.2,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      '${widget.number}',
                      style: TextStyle(
                        fontSize: widget.size * 0.38,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: const Offset(1, 2))],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // String
            Container(width: 2, height: 14, color: widget.color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

// ── Cloud shape ──────────────────────────────────────────────────────────────

class _CloudShape extends StatelessWidget {
  final double width;
  final double opacity;
  const _CloudShape({required this.width, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: width,
        height: width * 0.5,
        child: CustomPaint(painter: _CloudPainter()),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    canvas.drawOval(Rect.fromLTWH(0, size.height * 0.3, size.width, size.height * 0.7), paint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.4), size.height * 0.45, paint);
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.3), size.height * 0.55, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.45), size.height * 0.38, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Pulse widget ─────────────────────────────────────────────────────────────

class _PulseWidget extends StatefulWidget {
  final Widget child;
  const _PulseWidget({required this.child});

  @override
  State<_PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<_PulseWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.95, end: 1.08).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
