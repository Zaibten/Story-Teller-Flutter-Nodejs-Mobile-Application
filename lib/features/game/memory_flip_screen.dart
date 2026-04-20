import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'game_widgets.dart';
import 'sound_service.dart';

// ── Card model ───────────────────────────────────────────────────────────────

class _MemCard {
  final int id;
  final int pairId;
  final String emoji;
  final Color color;
  bool isFlipped;
  bool isMatched;
  bool isWrong;

  _MemCard({
    required this.id,
    required this.pairId,
    required this.emoji,
    required this.color,
    this.isFlipped = false,
    this.isMatched = false,
    this.isWrong = false,
  });
}

// ── Memory flip screen ───────────────────────────────────────────────────────

class MemoryFlipScreen extends StatefulWidget {
  const MemoryFlipScreen({Key? key}) : super(key: key);

  @override
  State<MemoryFlipScreen> createState() => _MemoryFlipScreenState();
}

class _MemoryFlipScreenState extends State<MemoryFlipScreen> with TickerProviderStateMixin {
  final SoundService _sound = SoundService();
  final math.Random _rng = math.Random();

  int _score = 0;
  int _moves = 0;
  int _level = 1;
  bool _gameOver = false;
  bool _showConfetti = false;
  bool _canFlip = true;
  int _stars = 3;

  late List<_MemCard> _cards;
  final List<int> _flipped = [];
  int _secondsElapsed = 0;
  late Timer _timerTick;
  int _timeLimit = 60;

  static const _emojis = [
    ['🐶','🐱','🐭','🐹','🐰','🦊','🐻','🐼'],
    ['🦁','🐯','🦄','🐸','🐧','🦋','🦀','🐳'],
    ['🌸','🌺','🌹','🌻','🍎','🍊','🍋','🍇'],
  ];
  static const _colors = [
    Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFF7C6FFF),
    Color(0xFFFF9F43), Color(0xFF44CF6C), Color(0xFFFF78C4),
    Color(0xFF5BC0EB), Color(0xFFE8C547),
  ];

  void _initLevel() {
    final pairCount = 4 + (_level - 1) * 2; // 4,6,8 pairs
    final setIdx = (_level - 1).clamp(0, _emojis.length - 1);
    final available = List.from(_emojis[setIdx])..shuffle(_rng);
    final selected = available.take(pairCount).toList();

    _timeLimit = 60 + _level * 10;
    _secondsElapsed = 0;
    _moves = 0;
    _canFlip = true;
    _flipped.clear();

    final cardList = <_MemCard>[];
    for (int i = 0; i < selected.length; i++) {
      final col = _colors[i % _colors.length];
      cardList.add(_MemCard(id: i * 2, pairId: i, emoji: selected[i], color: col));
      cardList.add(_MemCard(id: i * 2 + 1, pairId: i, emoji: selected[i], color: col));
    }
    cardList.shuffle(_rng);
    _cards = cardList;

    try { _timerTick.cancel(); } catch (_) {}
    _timerTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
        if (_secondsElapsed >= _timeLimit && !_gameOver) {
          _gameOver = true;
          _timerTick.cancel();
        }
      });
    });

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _timerTick = Timer(Duration.zero, () {});
    _initLevel();
  }

  void _onCardTap(int idx) async {
    if (!_canFlip) return;
    if (_cards[idx].isFlipped || _cards[idx].isMatched) return;
    if (_flipped.length >= 2) return;

    await _sound.playFlip();
    setState(() {
      _cards[idx].isFlipped = true;
      _flipped.add(idx);
    });

    if (_flipped.length == 2) {
      _canFlip = false;
      _moves++;
      final a = _flipped[0];
      final b = _flipped[1];

      if (_cards[a].pairId == _cards[b].pairId) {
        // Match!
        await Future.delayed(const Duration(milliseconds: 300));
        await _sound.playSuccess();
        setState(() {
          _cards[a].isMatched = true;
          _cards[b].isMatched = true;
          _score += math.max(10, 50 - _moves * 2);
          _flipped.clear();
          _canFlip = true;
        });

        if (_cards.every((c) => c.isMatched)) {
          _timerTick.cancel();
          await _sound.playWin();
          // Calculate stars
          final ratio = _secondsElapsed / _timeLimit;
          _stars = ratio < 0.4 ? 3 : ratio < 0.7 ? 2 : 1;
          setState(() {
            _showConfetti = true;
          });
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;
          setState(() {
            _showConfetti = false;
            _level++;
            _initLevel();
          });
        }
      } else {
        // No match
        await Future.delayed(const Duration(milliseconds: 700));
        await _sound.playError();
        setState(() {
          _cards[a].isWrong = true;
          _cards[b].isWrong = true;
        });
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          _cards[a].isFlipped = false;
          _cards[b].isFlipped = false;
          _cards[a].isWrong = false;
          _cards[b].isWrong = false;
          _flipped.clear();
          _canFlip = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _timerTick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeLeft = (_timeLimit - _secondsElapsed).clamp(0, _timeLimit);
    final pairCount = _cards.length ~/ 2;
    final cols = pairCount <= 4 ? 4 : pairCount <= 6 ? 4 : 4;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D1B69), Color(0xFF11084A)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHUD(timeLeft),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _cards.length,
                        itemBuilder: (_, i) => _FlipCard(
                          card: _cards[i],
                          onTap: () => _onCardTap(i),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_gameOver) _buildGameOver(),
              if (_showConfetti) const ConfettiOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHUD(int timeLeft) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { _timerTick.cancel(); Navigator.pop(context, _score); },
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
          StarScoreWidget(stars: _stars, score: _score),
          const Spacer(),
          TimerRing(
            progress: timeLeft / _timeLimit,
            secondsLeft: timeLeft,
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text('Moves', style: TextStyle(color: Colors.white54, fontSize: 10)),
                Text('$_moves', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOver() {
    final allMatched = _cards.every((c) => c.isMatched);
    return Container(
      color: Colors.black,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1e1040),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(allMatched ? '🎉' : '⏰', style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              Text(
                allMatched ? 'You did it!' : "Time's up!",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text('Score: $_score  |  Moves: $_moves',
                  style: TextStyle(color: Colors.white60, fontSize: 15)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GameButton(
                    color: const Color(0xFF7C6FFF),
                    onTap: () {
                      setState(() {
                        _score = 0;
                        _level = 1;
                        _gameOver = false;
                        _initLevel();
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
                    onTap: () { _timerTick.cancel(); Navigator.pop(context, _score); },
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

// ── Flip card widget ─────────────────────────────────────────────────────────

class _FlipCard extends StatefulWidget {
  final _MemCard card;
  final VoidCallback onTap;
  const _FlipCard({required this.card, required this.onTap});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.card.isFlipped && !old.card.isFlipped) {
      _flipCtrl.forward();
    } else if (!widget.card.isFlipped && old.card.isFlipped) {
      _flipCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (_, __) {
          final angle = _flipAnim.value * math.pi;
          final showFront = angle > math.pi / 2;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: _buildFront(),
                  )
                : _buildBack(),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    final card = widget.card;
    Color borderColor = Colors.transparent;
    if (card.isMatched) borderColor = const Color(0xFF44CF6C);
    if (card.isWrong) borderColor = const Color(0xFFFF6B6B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: card.isMatched
            ? card.color.withOpacity(0.3)
            : card.isWrong
                ? const Color(0xFFFF6B6B).withOpacity(0.2)
                : const Color(0xFF2D1B69),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: card.isMatched
              ? const Color(0xFF44CF6C)
              : card.isWrong
                  ? const Color(0xFFFF6B6B)
                  : card.color.withOpacity(0.6),
          width: card.isMatched || card.isWrong ? 2.5 : 1.5,
        ),
        boxShadow: card.isMatched
            ? [BoxShadow(color: const Color(0xFF44CF6C).withOpacity(0.3), blurRadius: 8)]
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(card.emoji, style: const TextStyle(fontSize: 28)),
            if (card.isMatched)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF44CF6C), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3D2A8A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Center(
        child: Icon(Icons.question_mark_rounded, color: Colors.white.withOpacity(0.4), size: 28),
      ),
    );
  }
}
