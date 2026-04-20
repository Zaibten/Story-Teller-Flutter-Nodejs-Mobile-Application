import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Bouncing star score indicator ───────────────────────────────────────────
class StarScoreWidget extends StatelessWidget {
  final int stars;
  final int score;
  const StarScoreWidget({Key? key, required this.stars, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 3; i++)
          _PulseStar(filled: i < stars, delay: Duration(milliseconds: i * 100)),
        const SizedBox(width: 8),
        Text(
          '$score',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ],
    );
  }
}

class _PulseStar extends StatefulWidget {
  final bool filled;
  final Duration delay;
  const _PulseStar({required this.filled, required this.delay});

  @override
  State<_PulseStar> createState() => _PulseStarState();
}

class _PulseStarState extends State<_PulseStar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    if (widget.filled) {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward().then((_) => _ctrl.reverse());
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        widget.filled ? Icons.star_rounded : Icons.star_border_rounded,
        color: widget.filled ? const Color(0xFFFFE66D) : Colors.white30,
        size: 26,
      ),
    );
  }
}

// ── Confetti burst ───────────────────────────────────────────────────────────
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({Key? key}) : super(key: key);

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_ConfettiPiece> _pieces = [];
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 50; i++) {
      _pieces.add(_ConfettiPiece(
        x: _rng.nextDouble(),
        y: -_rng.nextDouble() * 0.3,
        vx: (_rng.nextDouble() - 0.5) * 0.4,
        vy: 0.3 + _rng.nextDouble() * 0.5,
        color: _confettiColors[_rng.nextInt(_confettiColors.length)],
        size: 6 + _rng.nextDouble() * 8,
        rot: _rng.nextDouble() * math.pi * 2,
        vrot: (_rng.nextDouble() - 0.5) * 0.2,
      ));
    }
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..forward();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static const _confettiColors = [
    Color(0xFFFF6B6B), Color(0xFFFFE66D), Color(0xFF4ECDC4),
    Color(0xFF7C6FFF), Color(0xFFFF9F43), Color(0xFF44CF6C),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final t = _ctrl.value;
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _ConfettiPainter(_pieces, t, size),
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  double x, y, vx, vy, size, rot, vrot;
  Color color;
  _ConfettiPiece({
    required this.x, required this.y, required this.vx, required this.vy,
    required this.color, required this.size, required this.rot, required this.vrot,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double t;
  final Size screenSize;
  _ConfettiPainter(this.pieces, this.t, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final cx = (p.x + p.vx * t) * size.width;
      final cy = (p.y + p.vy * t) * size.height;
      if (cy > size.height + 20) continue;
      final paint = Paint()..color = p.color.withOpacity(1 - t * 0.4);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rot + p.vrot * t * 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

// ── Animated count-up ────────────────────────────────────────────────────────
class AnimatedCountUp extends StatefulWidget {
  final int value;
  final TextStyle? style;
  const AnimatedCountUp({Key? key, required this.value, this.style}) : super(key: key);

  @override
  State<AnimatedCountUp> createState() => _AnimatedCountUpState();
}

class _AnimatedCountUpState extends State<AnimatedCountUp> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _prev = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _anim = Tween<double>(begin: 0, end: widget.value.toDouble()).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedCountUp old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _prev = old.value;
      _anim = Tween<double>(begin: _prev.toDouble(), end: widget.value.toDouble()).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
      );
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Text(_anim.value.round().toString(), style: widget.style),
    );
  }
}

// ── Animated game button ─────────────────────────────────────────────────────
class GameButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final double borderRadius;
  final EdgeInsets padding;

  const GameButton({
    Key? key,
    required this.child,
    this.onTap,
    this.color = const Color(0xFF7C6FFF),
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  }) : super(key: key);

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Countdown timer ring ─────────────────────────────────────────────────────
class TimerRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int secondsLeft;
  const TimerRing({Key? key, required this.progress, required this.secondsLeft}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = progress > 0.5
        ? const Color(0xFF44CF6C)
        : progress > 0.25
            ? const Color(0xFFFFE66D)
            : const Color(0xFFFF6B6B);
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            '$secondsLeft',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
