import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';

import '../../providers/user_provider.dart';
import '../../services/audio.dart';
import '../../../common/widgets/header.dart'; // Import the MagicHeader

enum GameId { numberPop, colorMatch, memoryFlip, quickTap, shapeMatcher, patternRepeat }

class GameModel {
  final GameId id;
  final String title;
  final String description;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final int minAge;
  final int maxAge;

  const GameModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.minAge,
    required this.maxAge,
  });
}

const List<GameModel> kGames = [
  GameModel(
    id: GameId.numberPop,
    title: 'Number Pop',
    description: 'Tap numbers in order! Fast reflexes needed.',
    emoji: '🔢',
    primaryColor: Color(0xFFE94560),
    secondaryColor: Color(0xFFC62A40),
    minAge: 5,
    maxAge: 12,
  ),
  GameModel(
    id: GameId.colorMatch,
    title: 'Color Match',
    description: 'Match the color to the word! Brain training.',
    emoji: '🎨',
    primaryColor: Color(0xFF533483),
    secondaryColor: Color(0xFF3B1E6B),
    minAge: 6,
    maxAge: 14,
  ),
  GameModel(
    id: GameId.memoryFlip,
    title: 'Memory Flip',
    description: 'Find matching pairs! Test your memory.',
    emoji: '🧠',
    primaryColor: Color(0xFF0F3460),
    secondaryColor: Color(0xFF16213E),
    minAge: 4,
    maxAge: 12,
  ),
  GameModel(
    id: GameId.quickTap,
    title: 'Quick Tap',
    description: 'Tap the target as fast as you can!',
    emoji: '⚡',
    primaryColor: Color(0xFFFF6B6B),
    secondaryColor: Color(0xFFEE5A5A),
    minAge: 5,
    maxAge: 99,
  ),
  GameModel(
    id: GameId.shapeMatcher,
    title: 'Shape Matcher',
    description: 'Match the shapes before time runs out!',
    emoji: '🔺',
    primaryColor: Color(0xFF4ECDC4),
    secondaryColor: Color(0xFF44B3A8),
    minAge: 4,
    maxAge: 10,
  ),
  GameModel(
    id: GameId.patternRepeat,
    title: 'Pattern Repeat',
    description: 'Remember and repeat the pattern!',
    emoji: '🔄',
    primaryColor: Color(0xFFFFB74D),
    secondaryColor: Color(0xFFFF9800),
    minAge: 6,
    maxAge: 12,
  ),
];

// ============================================================================
// HAPTIC HELPER
// ============================================================================
class HapticHelper {
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void heavy() => HapticFeedback.heavyImpact();
  static void error() => HapticFeedback.vibrate();
  static void success() {
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 100), () => HapticFeedback.lightImpact());
  }
  static void levelUp() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 120), () => HapticFeedback.heavyImpact());
    Future.delayed(const Duration(milliseconds: 240), () => HapticFeedback.mediumImpact());
  }
}

// ============================================================================
// SOUND SERVICE
// ============================================================================
class SoundService {
  final AudioService _audioService = AudioService();
  bool get isMuted => _audioService.isMuted;
  Future<void> toggleMute() async => await _audioService.toggleMute();
  Future<void> pauseMusic() async => await _audioService.pauseMusic();
  Future<void> resumeMusic() async => await _audioService.resumeMusic();
  Future<void> playPop() async => await _audioService.playPop();
  Future<void> playCorrect() async => await _audioService.playCorrect();
  Future<void> playWrong() async => await _audioService.playWrong();
  Future<void> playWin() async => await _audioService.playWin();
  Future<void> playLevelUp() async => await _audioService.playLevelUp();
  Future<void> dispose() async => await _audioService.dispose();
}

// ============================================================================
// STAR PARTICLE WIDGET
// ============================================================================
class StarParticle {
  double x, y, size, speed, opacity;
  Color color;
  StarParticle({required this.x, required this.y, required this.size, required this.speed, required this.opacity, required this.color});
}

class ParticlesBurst extends StatefulWidget {
  final bool active;
  final Color color;
  const ParticlesBurst({Key? key, this.active = false, required this.color}) : super(key: key);
  @override
  State<ParticlesBurst> createState() => _ParticlesBurstState();
}

class _ParticlesBurstState extends State<ParticlesBurst> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Map<String, double>> _particles;
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _particles = List.generate(12, (_) => {
      'angle': _rand.nextDouble() * 2 * math.pi,
      'distance': 40 + _rand.nextDouble() * 60,
      'size': 4 + _rand.nextDouble() * 8,
    });
  }

  @override
  void didUpdateWidget(ParticlesBurst old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _ctrl.forward(from: 0);
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
      animation: _ctrl,
      builder: (_, __) {
        if (_ctrl.value == 0) return const SizedBox.shrink();
        return SizedBox(
          width: 200, height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: _particles.map((p) {
              final t = _ctrl.value;
              final dx = math.cos(p['angle']!) * p['distance']! * t;
              final dy = math.sin(p['angle']!) * p['distance']! * t;
              return Positioned(
                left: 100 + dx - p['size']! / 2,
                top: 100 + dy - p['size']! / 2,
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: Container(
                    width: p['size']!, height: p['size']!,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// ============================================================================
// ANIMATED BACKGROUND WIDGET
// ============================================================================
class AnimatedGameBackground extends StatefulWidget {
  final List<Color> colors;
  final List<String> emojis;
  const AnimatedGameBackground({Key? key, required this.colors, this.emojis = const []}) : super(key: key);
  @override
  State<AnimatedGameBackground> createState() => _AnimatedGameBackgroundState();
}

class _AnimatedGameBackgroundState extends State<AnimatedGameBackground> with TickerProviderStateMixin {
  late AnimationController _waveCtrl;
  late AnimationController _floatCtrl;
  final _rand = Random();
  late List<_FloatingItem> _items;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);

    _items = List.generate(widget.emojis.isEmpty ? 0 : 8, (i) => _FloatingItem(
      emoji: widget.emojis[_rand.nextInt(widget.emojis.length)],
      x: _rand.nextDouble(),
      y: _rand.nextDouble(),
      size: 20 + _rand.nextDouble() * 24,
      phase: _rand.nextDouble() * math.pi * 2,
      speed: 0.4 + _rand.nextDouble() * 0.6,
    ));
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveCtrl, _floatCtrl]),
      builder: (_, __) {
        return Stack(
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(widget.colors[0], widget.colors[1], _waveCtrl.value)!,
                    Color.lerp(widget.colors[1], widget.colors[0], _waveCtrl.value)!,
                  ],
                ),
              ),
            ),
            // Animated blobs
            ...List.generate(3, (i) {
              final phase = i * math.pi * 2 / 3;
              final x = 0.2 + 0.6 * ((math.sin(_waveCtrl.value * math.pi * 2 + phase) + 1) / 2);
              final y = 0.2 + 0.6 * ((math.cos(_waveCtrl.value * math.pi * 2 + phase) + 1) / 2);
              return Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment(x * 2 - 1, y * 2 - 1),
                  widthFactor: 0.5,
                  heightFactor: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.colors[i % widget.colors.length].withOpacity(0.15),
                    ),
                  ),
                ),
              );
            }),
            // Floating emojis
            ..._items.map((item) {
              final floatY = math.sin(_waveCtrl.value * math.pi * 2 * item.speed + item.phase) * 20;
              return Positioned(
                left: item.x * MediaQuery.of(context).size.width,
                top: item.y * MediaQuery.of(context).size.height + floatY,
                child: Opacity(
                  opacity: 0.15,
                  child: Text(item.emoji, style: TextStyle(fontSize: item.size)),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _FloatingItem {
  final String emoji;
  final double x, y, size, phase, speed;
  _FloatingItem({required this.emoji, required this.x, required this.y, required this.size, required this.phase, required this.speed});
}

// ============================================================================
// SCORE PILL WIDGET
// ============================================================================
class ScorePill extends StatefulWidget {
  final String label;
  final String value;
  final Color color;
  const ScorePill({Key? key, required this.label, required this.value, required this.color}) : super(key: key);
  @override
  State<ScorePill> createState() => _ScorePillState();
}

class _ScorePillState extends State<ScorePill> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  String _prev = '';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _prev = widget.value;
  }

  @override
  void didUpdateWidget(ScorePill old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final scale = 1.0 + (_ctrl.value < 0.5 ? _ctrl.value : 1 - _ctrl.value) * 0.3;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              boxShadow: [BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.label, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600, letterSpacing: 1.0)),
                const SizedBox(height: 2),
                Text(widget.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// GAME OVER CARD
// ============================================================================
class GameOverCard extends StatefulWidget {
  final bool isWin;
  final int score;
  final String winText;
  final String loseText;
  final Color color;
  final VoidCallback onReplay;
  final VoidCallback onBack;
  const GameOverCard({
    Key? key, required this.isWin, required this.score,
    required this.winText, required this.loseText,
    required this.color, required this.onReplay, required this.onBack,
  }) : super(key: key);
  @override
  State<GameOverCard> createState() => _GameOverCardState();
}

class _GameOverCardState extends State<GameOverCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => FadeTransition(
        opacity: _fade,
        child: Transform.scale(
          scale: _scale.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15)),
                const BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.isWin ? '🎉' : '😅', style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text(
                  widget.isWin ? widget.winText : widget.loseText,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: widget.color),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: widget.color, size: 20),
                      const SizedBox(width: 8),
                      Text('Score: ${widget.score}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: widget.color)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(label: 'Back', icon: Icons.home_rounded, color: Colors.grey.shade400, onTap: widget.onBack),
                    const SizedBox(width: 16),
                    _ActionButton(label: 'Play Again!', icon: Icons.replay_rounded, color: widget.color, onTap: widget.onReplay, isPrimary: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap, this.isPrimary = false});
  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: widget.isPrimary ? 24 : 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: widget.isPrimary ? LinearGradient(colors: [widget.color, widget.color.withOpacity(0.8)]) : null,
              color: widget.isPrimary ? null : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
              boxShadow: widget.isPrimary ? [BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))] : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: widget.isPrimary ? Colors.white : Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text(widget.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: widget.isPrimary ? Colors.white : Colors.grey.shade600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// LEVEL UP BANNER
// ============================================================================
class LevelUpBanner extends StatefulWidget {
  final int level;
  final Color color;
  const LevelUpBanner({Key? key, required this.level, required this.color}) : super(key: key);
  @override
  State<LevelUpBanner> createState() => _LevelUpBannerState();
}

class _LevelUpBannerState extends State<LevelUpBanner> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scale = Tween<double>(begin: 0.3, end: 1.15).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)));
    _ctrl.forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => FadeTransition(
        opacity: _fade,
        child: Transform.scale(
          scale: _scale.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [widget.color, widget.color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🚀', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 4),
                const Text('LEVEL UP!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3)),
                Text('Level ${widget.level}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GAMES SCREEN WITH MAGIC HEADER (UPDATED)
// ============================================================================
class GamesScreen extends StatefulWidget {
  static const String routeName = '/games';
  const GamesScreen({Key? key}) : super(key: key);
  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _entranceCtrl;
  final SoundService _sound = SoundService();
  final Map<GameId, int> _highScores = {};

  late AnimationController _bounceController;
  late AnimationController _waveController;
  late AnimationController _glowController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController1;
  late AnimationController _sparkleController2;
  late AnimationController _modalController;
  late AnimationController _moodController;
  late AnimationController _moodCardController;

  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _modalScaleAnimation;
  late Animation<double> _modalFadeAnimation;
  late Animation<double> _moodScaleAnimation;
  late Animation<double> _moodFadeAnimation;
  late Animation<double> _moodCardScaleAnimation;

  // Animation controllers for MagicHeader (these will be passed to the header)
  late AnimationController _magicWaveController;
  late AnimationController _magicFloatController;
  late AnimationController _magicPulseController;
  late AnimationController _magicSparkleController1;
  late AnimationController _magicSparkleController2;
  late AnimationController _magicGlowController;
  late AnimationController _magicShimmerController;
  
  late Animation<double> _magicWaveAnimation;
  late Animation<double> _magicFloatAnimation;
  late Animation<double> _magicPulseAnimation;
  late Animation<double> _magicSparkleAnimation1;
  late Animation<double> _magicSparkleAnimation2;
  late Animation<double> _magicGlowAnimation;
  late Animation<double> _magicShimmerAnimation;

  @override
  void initState() {
    super.initState();
    _setupMagicHeaderAnimations();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _bounceController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _sparkleController1 = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _sparkleController2 = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _modalController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _moodController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _moodCardController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _waveAnimation = CurvedAnimation(parent: _waveController, curve: Curves.easeInOut);
    _floatAnimation = Tween<double>(begin: -3, end: 3).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _modalScaleAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _modalController, curve: Curves.elasticOut));
    _modalFadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _modalController, curve: Curves.easeIn));
    _moodScaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(CurvedAnimation(parent: _moodController, curve: Curves.easeOutBack));
    _moodFadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _moodController, curve: Curves.easeIn));
    _moodCardScaleAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _moodCardController, curve: Curves.easeOutBack));

    WidgetsBinding.instance.addPostFrameCallback((_) { AudioService().init(); });
  }

  void _setupMagicHeaderAnimations() {
    _magicWaveController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _magicWaveAnimation = CurvedAnimation(parent: _magicWaveController, curve: Curves.easeInOut);

    _magicFloatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _magicFloatAnimation = Tween<double>(begin: -6, end: 6).animate(CurvedAnimation(parent: _magicFloatController, curve: Curves.easeInOut));

    _magicPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _magicPulseAnimation = _magicPulseController;

    _magicSparkleController1 = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _magicSparkleAnimation1 = _magicSparkleController1;

    _magicSparkleController2 = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _magicSparkleAnimation2 = _magicSparkleController2;

    _magicGlowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _magicGlowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _magicGlowController, curve: Curves.easeInOut));

    _magicShimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _magicShimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(CurvedAnimation(parent: _magicShimmerController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _magicWaveController.dispose();
    _magicFloatController.dispose();
    _magicPulseController.dispose();
    _magicSparkleController1.dispose();
    _magicSparkleController2.dispose();
    _magicGlowController.dispose();
    _magicShimmerController.dispose();
    _bounceController.dispose(); 
    _waveController.dispose(); 
    _glowController.dispose();
    _floatController.dispose(); 
    _pulseController.dispose(); 
    _sparkleController1.dispose();
    _sparkleController2.dispose(); 
    _modalController.dispose(); 
    _moodController.dispose();
    _moodCardController.dispose(); 
    _floatCtrl.dispose(); 
    _entranceCtrl.dispose();
    _sound.dispose();
    super.dispose();
  }

  void _openGame(GameModel game) async {
    HapticHelper.light();
    await _sound.playPop();
    if (!mounted) return;
    await _sound.pauseMusic();

    Widget screen;
    switch (game.id) {
      case GameId.numberPop: screen = NumberPopScreen(sound: _sound); break;
      case GameId.colorMatch: screen = ColorMatchScreen(sound: _sound); break;
      case GameId.memoryFlip: screen = MemoryFlipScreen(sound: _sound); break;
      case GameId.quickTap: screen = QuickTapScreen(sound: _sound); break;
      case GameId.shapeMatcher: screen = ShapeMatcherScreen(sound: _sound); break;
      case GameId.patternRepeat: screen = PatternRepeatScreen(sound: _sound); break;
    }

    final result = await Navigator.of(context).push<int>(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => screen,
        transitionsBuilder: (_, anim, __, child) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: FadeTransition(opacity: anim, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );

    await _sound.resumeMusic();
    if (result != null) {
      setState(() {
        final prev = _highScores[game.id] ?? 0;
        if (result > prev) _highScores[game.id] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF1)],
          ),
        ),
        child: SafeArea(
          child: Column(
         children: [
  // HEADER + MIC TOGETHER
  Stack(
    clipBehavior: Clip.none,
    children: [
      MagicHeader(
        waveAnimation: _magicWaveAnimation,
        floatAnimation: _magicFloatAnimation,
        pulseAnimation: _magicPulseAnimation,
        sparkleAnimation1: _magicSparkleAnimation1,
        sparkleAnimation2: _magicSparkleAnimation2,
        glowAnimation: _magicGlowAnimation,
        shimmerAnimation: _magicShimmerAnimation,
        selectedCharacterName: user.name.split(" ")[0],
        hasSelectedCharacter: true,
        height: 180,
      ),

      // 🎤 MIC BUTTON (RIGHT SIDE FIXED)
      Positioned(
        top: 55,
        right: 20, // ✅ proper spacing from right
        child: _MuteButton(sound: _sound),
      ),
    ],
  ),

  // GAME GRID
  Expanded(child: _buildGameGrid()),
], ),
        ),
      ),
    );
  }

  Widget _buildGameGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ListView.builder(
        itemCount: kGames.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SlideTransition(
              position: Tween<Offset>(begin: Offset(0, 0.3 + i * 0.1), end: Offset.zero).animate(
                CurvedAnimation(parent: _entranceCtrl, curve: Interval(i * 0.15, 1.0, curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _entranceCtrl, curve: Interval(i * 0.15, 1.0)),
                child: _EnhancedGameCard(
                  game: kGames[i],
                  highScore: _highScores[kGames[i].id],
                  onTap: () => _openGame(kGames[i]),
                  floatCtrl: _floatCtrl,
                  index: i,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// ENHANCED GAME CARD
// ============================================================================
class _EnhancedGameCard extends StatefulWidget {
  final GameModel game;
  final int? highScore;
  final VoidCallback onTap;
  final AnimationController floatCtrl;
  final int index;
  const _EnhancedGameCard({required this.game, required this.onTap, this.highScore, required this.floatCtrl, required this.index});
  @override
  State<_EnhancedGameCard> createState() => _EnhancedGameCardState();
}

class _EnhancedGameCardState extends State<_EnhancedGameCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  late Animation<double> _scale, _elevate, _floatOffset;
  bool _burst = false;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
    _elevate = Tween<double>(begin: 0, end: 12).animate(_hoverCtrl);
    _floatOffset = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: widget.floatCtrl, curve: Interval(widget.index * 0.1, 1.0, curve: Curves.easeInOutSine)),
    );
  }

  @override
  void dispose() { _hoverCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { _hoverCtrl.forward(); HapticHelper.light(); },
      onTapUp: (_) {
        _hoverCtrl.reverse();
        setState(() => _burst = true);
        Future.delayed(const Duration(milliseconds: 100), () { if (mounted) setState(() => _burst = false); });
        widget.onTap();
      },
      onTapCancel: () => _hoverCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _floatOffset,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, -_floatOffset.value),
          child: AnimatedBuilder(
            animation: _hoverCtrl,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 116,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.game.primaryColor, widget.game.secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: widget.game.primaryColor.withOpacity(0.45),
                          blurRadius: 20 + _elevate.value,
                          offset: Offset(0, 6 + _elevate.value / 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(right: -20, top: -20,
                          child: Container(width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.12)))),
                        Positioned(right: 35, bottom: -35,
                          child: Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08)))),
                        Positioned(left: -15, bottom: -15,
                          child: Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.07)))),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              // Emoji container with glow
                              Container(
                                width: 68, height: 68,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                ),
                                child: Center(child: Text(widget.game.emoji, style: const TextStyle(fontSize: 34))),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(widget.game.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3)),
                                    const SizedBox(height: 4),
                                    Text(widget.game.description, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.85)), maxLines: 2),
                                    if (widget.highScore != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFE66D), size: 13),
                                          const SizedBox(width: 4),
                                          Text('Best: ${widget.highScore}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFFFE66D))),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(16)),
                                    child: Text('${widget.game.minAge}-${widget.game.maxAge}y', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: 38, height: 38,
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle),
                                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_burst)
                    IgnorePointer(child: ParticlesBurst(active: _burst, color: widget.game.primaryColor)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MUTE BUTTON
// ============================================================================
class _MuteButton extends StatefulWidget {
  final SoundService sound;
  const _MuteButton({required this.sound});
  @override
  State<_MuteButton> createState() => _MuteButtonState();
}

class _MuteButtonState extends State<_MuteButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _isMuted = false;
  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _isMuted = widget.sound.isMuted;
  }
  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        HapticHelper.light();
        await widget.sound.toggleMute();
        setState(() { _isMuted = widget.sound.isMuted; });
      },
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          return Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 8 + _pulseCtrl.value * 4, offset: const Offset(0, 2))],
            ),
            child: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: const Color(0xFF1a1a2e), size: 20),
          );
        },
      ),
    );
  }
}

// ============================================================================
// NUMBER POP GAME — NEXT LEVEL
// ============================================================================
class NumberPopScreen extends StatefulWidget {
  final SoundService sound;
  const NumberPopScreen({Key? key, required this.sound}) : super(key: key);
  @override
  State<NumberPopScreen> createState() => _NumberPopScreenState();
}

class _NumberPopScreenState extends State<NumberPopScreen> with TickerProviderStateMixin {
  List<int> numbers = [];
  int currentNumber = 1;
  int score = 0;
  int highScore = 0;
  int level = 1;
  int combo = 0;
  bool isGameOver = false;
  int highlightedNumber = -1;
  bool _showLevelUp = false;
  bool _burstActive = false;
  int _burstIndex = -1;
  late AnimationController _shakeCtrl;
  late AnimationController _levelUpCtrl;
  late AnimationController _comboCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _bgCtrl;
  late Animation<double> _comboScale;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _levelUpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _comboCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _comboScale = Tween<double>(begin: 1.0, end: 1.6).animate(CurvedAnimation(parent: _comboCtrl, curve: Curves.easeOutBack));
    _initGame();
  }

  void _initGame() {
    int gridSize = 3 + (level - 1) ~/ 2;
    if (gridSize > 5) gridSize = 5;
    int total = gridSize * gridSize;
    List<int> nums = List.generate(total, (i) => i + 1)..shuffle();
    setState(() { numbers = nums; currentNumber = 1; isGameOver = false; highlightedNumber = -1; });
  }

  void _onNumberTap(int number, int index) {
    if (isGameOver) return;
    setState(() { highlightedNumber = index; });
    Future.delayed(const Duration(milliseconds: 150), () { if (mounted && highlightedNumber == index) setState(() => highlightedNumber = -1); });

    if (number == currentNumber) {
      HapticHelper.success();
      widget.sound.playCorrect();
      setState(() {
        _burstIndex = index; _burstActive = true;
        score += 10 + (combo * 2); combo++; currentNumber++;
      });
      Future.delayed(const Duration(milliseconds: 100), () { if (mounted) setState(() => _burstActive = false); });
      _comboCtrl.forward().then((_) => _comboCtrl.reset());
      if (currentNumber > numbers.length) _levelUp();
    } else {
      HapticHelper.error();
      widget.sound.playWrong();
      _shakeCtrl.forward().then((_) => _shakeCtrl.reset());
      setState(() { isGameOver = true; combo = 0; });
    }
  }

  void _levelUp() {
    HapticHelper.levelUp();
    setState(() { level++; combo = 0; _showLevelUp = true; if (score > highScore) highScore = score; });
    widget.sound.playLevelUp();
    _levelUpCtrl.forward().then((_) {
      _levelUpCtrl.reset();
      setState(() => _showLevelUp = false);
      _initGame();
    });
  }

  void _resetGame() {
    HapticHelper.light();
    setState(() { level = 1; score = 0; combo = 0; });
    _initGame();
  }

  @override
  void dispose() { _shakeCtrl.dispose(); _levelUpCtrl.dispose(); _comboCtrl.dispose(); _pulseCtrl.dispose(); _bgCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    int gridSize = math.min(3 + (level - 1) ~/ 2, 5);
    return Scaffold(
      body: Stack(
        children: [
          AnimatedGameBackground(
            colors: const [Color(0xFFFFE0E6), Color(0xFFFFF0F2), Color(0xFFFFD0D8)],
            emojis: const ['🔢', '⭐', '🎯', '💥', '🔥'],
          ),
          SafeArea(
            child: Column(
              children: [
                GameScreenHeader(
                  title: 'Number Pop',
                  subtitle: 'Tap numbers in order! 🔢',
                  color: const Color(0xFFE94560),
                  emoji: '🔢',
                  sound: widget.sound,
                  onBack: () { HapticHelper.light(); Navigator.pop(context, score); },
                  scoreWidgets: [
                    ScorePill(label: 'LEVEL', value: '$level', color: const Color(0xFFE94560)),
                    AnimatedBuilder(
                      animation: _comboCtrl,
                      builder: (_, __) => Transform.scale(
                        scale: _comboScale.value,
                        child: ScorePill(label: 'COMBO', value: '$combo', color: const Color(0xFFFFB74D)),
                      ),
                    ),
                    ScorePill(label: 'SCORE', value: '$score', color: const Color(0xFFE94560)),
                    ScorePill(label: 'BEST', value: '$highScore', color: const Color(0xFFFFD700)),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _shakeCtrl,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(math.sin(_shakeCtrl.value * math.pi * 8) * 8, 0),
                        child: child,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(20),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridSize, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1,
                            ),
                            itemCount: numbers.length,
                            itemBuilder: (_, i) => _PopNumberButton(
                              number: numbers[i],
                              onTap: () => _onNumberTap(numbers[i], i),
                              isDisabled: isGameOver,
                              isHighlighted: highlightedNumber == i,
                              isNext: numbers[i] == currentNumber,
                              pulseCtrl: _pulseCtrl,
                              showBurst: _burstActive && _burstIndex == i,
                            ),
                          ),
                          if (_showLevelUp)
                            LevelUpBanner(level: level, color: const Color(0xFFE94560)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isGameOver)
                  GameOverCard(
                    isWin: false, score: score,
                    winText: 'Amazing!', loseText: 'Wrong order!',
                    color: const Color(0xFFE94560),
                    onReplay: _resetGame,
                    onBack: () { HapticHelper.light(); Navigator.pop(context, score); },
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.touch_app_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Tap 1 → ${numbers.isEmpty ? "?" : numbers.length} in order!', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PopNumberButton extends StatefulWidget {
  final int number;
  final VoidCallback onTap;
  final bool isDisabled, isHighlighted, isNext, showBurst;
  final AnimationController pulseCtrl;
  const _PopNumberButton({required this.number, required this.onTap, this.isDisabled = false, this.isHighlighted = false, this.isNext = false, this.showBurst = false, required this.pulseCtrl});
  @override
  State<_PopNumberButton> createState() => _PopNumberButtonState();
}

class _PopNumberButtonState extends State<_PopNumberButton> with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late Animation<double> _tapScale;
  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _tapScale = Tween<double>(begin: 1.0, end: 0.88).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
  }
  @override
  void dispose() { _tapCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapCtrl.forward(),
      onTapUp: (_) { _tapCtrl.reverse(); if (!widget.isDisabled) widget.onTap(); },
      onTapCancel: () => _tapCtrl.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_tapCtrl, widget.pulseCtrl]),
        builder: (_, __) {
          final isActive = widget.isHighlighted;
          final isNext = widget.isNext && !widget.isDisabled;
          return Transform.scale(
            scale: _tapScale.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(colors: [Color(0xFFFFB74D), Color(0xFFFF6B00)])
                        : isNext
                            ? const LinearGradient(colors: [Color(0xFFFFE066), Color(0xFFFFB74D)])
                            : LinearGradient(colors: [Colors.white, Colors.grey.shade50]),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: (isActive || isNext) ? const Color(0xFFFFB74D).withOpacity(0.6) : Colors.grey.withOpacity(0.2),
                        blurRadius: (isActive || isNext) ? 16 + widget.pulseCtrl.value * 6 : 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: isNext ? Border.all(color: const Color(0xFFFFB74D), width: 2.5) : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text('${widget.number}',
                      style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900,
                        color: (isActive || isNext) ? Colors.white : const Color(0xFFE94560),
                      ),
                    ),
                  ),
                ),
                if (widget.showBurst)
                  IgnorePointer(child: ParticlesBurst(active: widget.showBurst, color: const Color(0xFFE94560))),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// COLOR MATCH GAME — NEXT LEVEL
// ============================================================================
class ColorMatchScreen extends StatefulWidget {
  final SoundService sound;
  const ColorMatchScreen({Key? key, required this.sound}) : super(key: key);
  @override
  State<ColorMatchScreen> createState() => _ColorMatchScreenState();
}

class _ColorMatchScreenState extends State<ColorMatchScreen> with TickerProviderStateMixin {
  final List<ColorItem> items = [
    ColorItem('RED', Colors.red), ColorItem('BLUE', Colors.blue), ColorItem('GREEN', Colors.green),
    ColorItem('YELLOW', Colors.yellow.shade700), ColorItem('PURPLE', Colors.purple), ColorItem('ORANGE', Colors.orange),
  ];
  ColorItem? currentItem;
  int score = 0, highScore = 0, timeLeft = 30, streak = 0;
  bool isPlaying = false, isGameOver = false;
  bool _burst = false;
  Timer? _timer;
  late AnimationController _shakeCtrl, _correctCtrl, _streakCtrl, _pulseCtrl, _bgCtrl;
  late Animation<double> _streakScale;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _correctCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _streakCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _streakScale = Tween<double>(begin: 1.0, end: 1.4).animate(CurvedAnimation(parent: _streakCtrl, curve: Curves.easeOutBack));
    _startGame();
  }

  void _startGame() {
    setState(() { score = 0; timeLeft = 30; streak = 0; isPlaying = true; isGameOver = false; _nextQuestion(); });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && timeLeft > 0) { setState(() => timeLeft--); if (timeLeft == 0) _endGame(); }
    });
  }

  void _nextQuestion() { setState(() => currentItem = items[Random().nextInt(items.length)]); }

  void _checkAnswer(String selected) {
    if (!isPlaying || isGameOver) return;
    if (currentItem != null && selected == currentItem!.text) {
      HapticHelper.success();
      widget.sound.playCorrect();
      _correctCtrl.forward().then((_) => _correctCtrl.reset());
      _streakCtrl.forward().then((_) => _streakCtrl.reset());
      setState(() { streak++; score += 10 + (streak * 2); if (score > highScore) highScore = score; timeLeft = math.min(timeLeft + 1, 60); _burst = true; });
      Future.delayed(const Duration(milliseconds: 100), () { if (mounted) setState(() => _burst = false); });
      _nextQuestion();
    } else {
      HapticHelper.error();
      widget.sound.playWrong();
      _shakeCtrl.forward().then((_) => _shakeCtrl.reset());
      setState(() { streak = 0; if (score > 5) score -= 5; });
    }
  }

  void _endGame() {
    _timer?.cancel();
    setState(() { isPlaying = false; isGameOver = true; });
    widget.sound.playWin();
  }

  @override
  void dispose() { _timer?.cancel(); _shakeCtrl.dispose(); _correctCtrl.dispose(); _streakCtrl.dispose(); _pulseCtrl.dispose(); _bgCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedGameBackground(
            colors: const [Color(0xFFEDE7F6), Color(0xFFF3E5F5), Color(0xFFE8EAF6)],
            emojis: const ['🎨', '🌈', '🎭', '✨', '💜'],
          ),
          SafeArea(
            child: Column(
              children: [
                GameScreenHeader(
                  title: 'Color Match', subtitle: 'Match word to color! 🎨',
                  color: const Color(0xFF533483), emoji: '🎨', sound: widget.sound,
                  onBack: () { HapticHelper.light(); _timer?.cancel(); Navigator.pop(context, score); },
                  scoreWidgets: [
                    AnimatedBuilder(
                      animation: _streakCtrl,
                      builder: (_, __) => Transform.scale(scale: _streakScale.value,
                        child: ScorePill(label: 'STREAK', value: '$streak', color: const Color(0xFFFFB74D))),
                    ),
                    ScorePill(label: 'SCORE', value: '$score', color: const Color(0xFF533483)),
                    ScorePill(label: 'BEST', value: '$highScore', color: const Color(0xFFFFD700)),
                    _TimerPill(timeLeft: timeLeft, totalTime: 30),
                  ],
                ),
                if (isPlaying && currentItem != null) ...[
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _shakeCtrl,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(math.sin(_shakeCtrl.value * math.pi * 6) * 10, 0),
                        child: child,
                      ),
                      child: AnimatedBuilder(
                        animation: _correctCtrl,
                        builder: (_, child) => Transform.scale(scale: 1.0 + _correctCtrl.value * 0.05, child: child),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              margin: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: currentItem!.color,
                                borderRadius: BorderRadius.circular(36),
                                boxShadow: [BoxShadow(color: currentItem!.color.withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 12))],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(currentItem!.text, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Colors.black26, offset: Offset(2, 2), blurRadius: 4)])),
                                    const SizedBox(height: 8),
                                    Text('What color is this text?', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
                                  ],
                                ),
                              ),
                            ),
                            if (_burst)
                              IgnorePointer(child: ParticlesBurst(active: _burst, color: currentItem!.color)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildColorOptions(),
                ],
                if (isGameOver)
                  GameOverCard(
                    isWin: true, score: score, winText: "Time's Up!", loseText: "Time's Up!",
                    color: const Color(0xFF533483), onReplay: _startGame,
                    onBack: () { HapticHelper.light(); Navigator.pop(context, score); },
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('${timeLeft}s remaining • Tap the matching color!', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOptions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
        children: items.map((item) => _ColorOptionButton(item: item, onTap: () => _checkAnswer(item.text), isEnabled: isPlaying && !isGameOver, pulseCtrl: _pulseCtrl)).toList(),
      ),
    );
  }
}

class _ColorOptionButton extends StatefulWidget {
  final ColorItem item;
  final VoidCallback onTap;
  final bool isEnabled;
  final AnimationController pulseCtrl;
  const _ColorOptionButton({required this.item, required this.onTap, required this.isEnabled, required this.pulseCtrl});
  @override
  State<_ColorOptionButton> createState() => _ColorOptionButtonState();
}

class _ColorOptionButtonState extends State<_ColorOptionButton> with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(_tapCtrl);
  }
  @override
  void dispose() { _tapCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { if (widget.isEnabled) _tapCtrl.forward(); },
      onTapUp: (_) { _tapCtrl.reverse(); if (widget.isEnabled) { HapticHelper.light(); widget.onTap(); } },
      onTapCancel: () => _tapCtrl.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_tapCtrl, widget.pulseCtrl]),
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 108, padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [widget.item.color, widget.item.color.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: widget.item.color.withOpacity(0.45), blurRadius: 10 + widget.pulseCtrl.value * 4, offset: const Offset(0, 5))],
            ),
            child: Text(widget.item.text, textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13, shadows: [Shadow(color: Colors.black38, offset: Offset(1, 1), blurRadius: 2)])),
          ),
        ),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  final int timeLeft, totalTime;
  const _TimerPill({required this.timeLeft, required this.totalTime});
  @override
  Widget build(BuildContext context) {
    final fraction = (timeLeft / totalTime).clamp(0.0, 1.0);
    final color = fraction > 0.5 ? Colors.greenAccent : (fraction > 0.25 ? Colors.orangeAccent : Colors.redAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('TIME', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600, letterSpacing: 1.0)),
          const SizedBox(height: 2),
          Text('${timeLeft}s', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class ColorItem {
  final String text;
  final Color color;
  ColorItem(this.text, this.color);
}

// ============================================================================
// MEMORY FLIP GAME — NEXT LEVEL
// ============================================================================
class MemoryFlipScreen extends StatefulWidget {
  final SoundService sound;
  const MemoryFlipScreen({Key? key, required this.sound}) : super(key: key);
  @override
  State<MemoryFlipScreen> createState() => _MemoryFlipScreenState();
}

class _MemoryFlipScreenState extends State<MemoryFlipScreen> with TickerProviderStateMixin {
  late List<MemoryCard> cards;
  int score = 0, moves = 0, matchedPairs = 0;
  int? firstIndex, secondIndex;
  bool isWaiting = false, isGameOver = false;
  late AnimationController _matchCtrl, _winCtrl, _pulseCtrl;
  final List<String> emojis = ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼'];

  @override
  void initState() {
    super.initState();
    _matchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _winCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _initGame();
  }

  void _initGame() {
    List<MemoryCard> c = [];
    for (var e in emojis) {
      c.add(MemoryCard(emoji: e, isFlipped: false, isMatched: false, id: DateTime.now().millisecondsSinceEpoch + c.length));
      c.add(MemoryCard(emoji: e, isFlipped: false, isMatched: false, id: DateTime.now().millisecondsSinceEpoch + c.length + 1000));
    }
    c.shuffle();
    setState(() { cards = c; score = 0; moves = 0; matchedPairs = 0; firstIndex = null; secondIndex = null; isWaiting = false; isGameOver = false; });
  }

  void _onCardTap(int index) {
    if (isWaiting || isGameOver || cards[index].isMatched || firstIndex == index) return;
    HapticHelper.light();
    widget.sound.playPop();
    setState(() { cards[index] = cards[index].copyWith(isFlipped: true); moves++; });
    if (firstIndex == null) {
      setState(() => firstIndex = index);
    } else if (secondIndex == null) {
      setState(() => secondIndex = index);
      _checkMatch();
    }
  }

  void _checkMatch() {
    isWaiting = true;
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (cards[firstIndex!].emoji == cards[secondIndex!].emoji) {
        HapticHelper.success();
        widget.sound.playCorrect();
        _matchCtrl.forward().then((_) => _matchCtrl.reset());
        setState(() {
          cards[firstIndex!] = cards[firstIndex!].copyWith(isMatched: true);
          cards[secondIndex!] = cards[secondIndex!].copyWith(isMatched: true);
          matchedPairs++; score += 10;
          if (matchedPairs == emojis.length) { isGameOver = true; _winCtrl.forward(); widget.sound.playWin(); HapticHelper.levelUp(); }
        });
      } else {
        HapticHelper.error();
        widget.sound.playWrong();
        setState(() { cards[firstIndex!] = cards[firstIndex!].copyWith(isFlipped: false); cards[secondIndex!] = cards[secondIndex!].copyWith(isFlipped: false); });
      }
      setState(() { firstIndex = null; secondIndex = null; isWaiting = false; });
    });
  }

  @override
  void dispose() { _matchCtrl.dispose(); _winCtrl.dispose(); _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedGameBackground(
            colors: const [Color(0xFFE3F0FF), Color(0xFFEEF5FF), Color(0xFFD8ECFF)],
            emojis: const ['🧠', '🐶', '🐱', '⭐', '🎴'],
          ),
          SafeArea(
            child: Column(
              children: [
                GameScreenHeader(
                  title: 'Memory Flip', subtitle: 'Find matching pairs! 🧠',
                  color: const Color(0xFF0F3460), emoji: '🧠', sound: widget.sound,
                  onBack: () { HapticHelper.light(); Navigator.pop(context, score); },
                  scoreWidgets: [
                    ScorePill(label: 'SCORE', value: '$score', color: const Color(0xFF0F3460)),
                    ScorePill(label: 'MOVES', value: '$moves', color: const Color(0xFF4A90D9)),
                    ScorePill(label: 'PAIRS', value: '$matchedPairs/${emojis.length}', color: const Color(0xFFFFD700)),
                  ],
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.88),
                    itemCount: cards.length,
                    itemBuilder: (_, i) => AnimatedBuilder(
                      animation: _matchCtrl,
                      builder: (_, __) => Transform.scale(
                        scale: _matchCtrl.isAnimating && cards[i].isMatched ? 1.08 : 1.0,
                        child: _EnhancedMemoryCard(card: cards[i], onTap: () => _onCardTap(i), isDisabled: isGameOver || isWaiting, pulseCtrl: _pulseCtrl),
                      ),
                    ),
                  ),
                ),
                if (isGameOver)
                  GameOverCard(
                    isWin: true, score: score, winText: 'You Win! 🎉', loseText: 'You Win! 🎉',
                    color: const Color(0xFF0F3460), onReplay: _initGame,
                    onBack: () { HapticHelper.light(); Navigator.pop(context, score); },
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text('Pairs: $matchedPairs/${emojis.length} • Moves: $moves', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MemoryCard {
  final String emoji; final bool isFlipped, isMatched; final int id;
  MemoryCard({required this.emoji, required this.isFlipped, required this.isMatched, required this.id});
  MemoryCard copyWith({String? emoji, bool? isFlipped, bool? isMatched, int? id}) =>
      MemoryCard(emoji: emoji ?? this.emoji, isFlipped: isFlipped ?? this.isFlipped, isMatched: isMatched ?? this.isMatched, id: id ?? this.id);
}

class _EnhancedMemoryCard extends StatefulWidget {
  final MemoryCard card; final VoidCallback onTap; final bool isDisabled; final AnimationController pulseCtrl;
  const _EnhancedMemoryCard({required this.card, required this.onTap, this.isDisabled = false, required this.pulseCtrl});
  @override
  State<_EnhancedMemoryCard> createState() => _EnhancedMemoryCardState();
}

class _EnhancedMemoryCardState extends State<_EnhancedMemoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
  }
  @override
  void dispose() { _tapCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { if (!widget.isDisabled && !widget.card.isMatched) _tapCtrl.forward(); },
      onTapUp: (_) { _tapCtrl.reverse(); if (!widget.isDisabled && !widget.card.isMatched) widget.onTap(); },
      onTapCancel: () => _tapCtrl.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_tapCtrl, widget.pulseCtrl]),
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: widget.card.isMatched
                  ? const LinearGradient(colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)])
                  : (widget.card.isFlipped
                      ? const LinearGradient(colors: [Colors.white, Color(0xFFF0F4FF)])
                      : const LinearGradient(colors: [Color(0xFF0F3460), Color(0xFF1A4A80)])),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: widget.card.isMatched
                      ? const Color(0xFF2F80ED).withOpacity(0.45)
                      : (widget.card.isFlipped ? Colors.grey.withOpacity(0.2) : const Color(0xFF0F3460).withOpacity(0.3)),
                  blurRadius: widget.card.isFlipped ? 8 + widget.pulseCtrl.value * 4 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: (widget.card.isFlipped || widget.card.isMatched)
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(widget.card.emoji, key: ValueKey(widget.card.emoji), style: const TextStyle(fontSize: 30)))
                  : const Icon(Icons.help_outline_rounded, size: 28, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// QUICK TAP GAME — NEXT LEVEL
// ============================================================================
class QuickTapScreen extends StatefulWidget {
  final SoundService sound;
  const QuickTapScreen({Key? key, required this.sound}) : super(key: key);
  @override
  State<QuickTapScreen> createState() => _QuickTapScreenState();
}

class _QuickTapScreenState extends State<QuickTapScreen> with TickerProviderStateMixin {
  int score = 0, highScore = 0, timeLeft = 10, targetIndex = 0;
  bool isPlaying = false, isGameOver = false;
  bool _burst = false;
  Timer? _gameTimer, _moveTimer;
  late AnimationController _targetCtrl, _pulseCtrl, _missCtrl;

  @override
  void initState() {
    super.initState();
    _targetCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
    _missCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _startGame();
  }

  void _startGame() {
    setState(() { score = 0; timeLeft = 10; isPlaying = true; isGameOver = false; _randomizeTarget(); });
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && timeLeft > 0) { setState(() => timeLeft--); if (timeLeft == 0) _endGame(); }
    });
    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (mounted && isPlaying && !isGameOver) { _randomizeTarget(); _targetCtrl.forward().then((_) => _targetCtrl.reset()); }
    });
  }

  void _randomizeTarget() => setState(() => targetIndex = Random().nextInt(9));

  void _onTap(int index) {
    if (!isPlaying || isGameOver) return;
    if (index == targetIndex) {
      HapticHelper.success();
      widget.sound.playCorrect();
      _targetCtrl.forward().then((_) => _targetCtrl.reset());
      setState(() { score++; if (score > highScore) highScore = score; timeLeft = math.min(timeLeft + 1, 20); _burst = true; });
      Future.delayed(const Duration(milliseconds: 100), () { if (mounted) setState(() => _burst = false); });
      _randomizeTarget();
    } else {
      HapticHelper.error();
      widget.sound.playWrong();
      _missCtrl.forward().then((_) => _missCtrl.reset());
      setState(() { if (score > 0) score--; });
    }
  }

  void _endGame() {
    _gameTimer?.cancel(); _moveTimer?.cancel();
    setState(() { isPlaying = false; isGameOver = true; });
    widget.sound.playWin(); HapticHelper.levelUp();
  }

  @override
  void dispose() { _gameTimer?.cancel(); _moveTimer?.cancel(); _targetCtrl.dispose(); _pulseCtrl.dispose(); _missCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedGameBackground(
            colors: const [Color(0xFFFFE8E8), Color(0xFFFFF3F3), Color(0xFFFFDDDD)],
            emojis: const ['⚡', '⭐', '🎯', '💥', '🔥'],
          ),
          SafeArea(
            child: Column(
              children: [
                GameScreenHeader(
                  title: 'Quick Tap', subtitle: 'Tap the star FAST! ⚡',
                  color: const Color(0xFFFF6B6B), emoji: '⚡', sound: widget.sound,
                  onBack: () { HapticHelper.light(); _gameTimer?.cancel(); _moveTimer?.cancel(); Navigator.pop(context, score); },
                  scoreWidgets: [
                    ScorePill(label: 'SCORE', value: '$score', color: const Color(0xFFFF6B6B)),
                    ScorePill(label: 'BEST', value: '$highScore', color: const Color(0xFFFFD700)),
                    _TimerPill(timeLeft: timeLeft, totalTime: 10),
                  ],
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 14, mainAxisSpacing: 14),
                    itemCount: 9,
                    itemBuilder: (_, i) {
                      final isTarget = i == targetIndex;
                      return AnimatedBuilder(
                        animation: Listenable.merge([_targetCtrl, _pulseCtrl, _missCtrl]),
                        builder: (_, __) => GestureDetector(
                          onTap: () => _onTap(i),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: isTarget && _targetCtrl.isAnimating ? 1.12 : 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: isTarget
                                        ? const LinearGradient(colors: [Color(0xFFFFE066), Color(0xFFFFB300)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                                        : LinearGradient(colors: [Colors.white, Colors.grey.shade50]),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isTarget ? const Color(0xFFFFB300).withOpacity(0.6) : Colors.grey.withOpacity(0.2),
                                        blurRadius: isTarget ? 18 + _pulseCtrl.value * 8 : 6,
                                        offset: const Offset(0, 4),
                                        spreadRadius: isTarget ? _pulseCtrl.value * 2 : 0,
                                      ),
                                    ],
                                    border: Border.all(color: isTarget ? const Color(0xFFFFB300) : Colors.grey.shade200, width: isTarget ? 2.5 : 1),
                                  ),
                                  child: Center(
                                    child: isTarget
                                        ? Text('⭐', style: TextStyle(fontSize: 40 + _pulseCtrl.value * 4))
                                        : const Icon(Icons.circle_outlined, size: 32, color: Colors.grey),
                                  ),
                                ),
                              ),
                              if (_burst && isTarget)
                                IgnorePointer(child: ParticlesBurst(active: _burst, color: const Color(0xFFFFB300))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (isGameOver)
                  GameOverCard(
                    isWin: true, score: score, winText: "Time's Up!", loseText: "Time's Up!",
                    color: const Color(0xFFFF6B6B), onReplay: _startGame,
                    onBack: () { HapticHelper.light(); Navigator.pop(context, score); },
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text('${timeLeft}s left • Tap the glowing star!', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SHAPE MATCHER GAME — NEXT LEVEL
// ============================================================================
class ShapeMatcherScreen extends StatefulWidget {
  final SoundService sound;
  const ShapeMatcherScreen({Key? key, required this.sound}) : super(key: key);
  @override
  State<ShapeMatcherScreen> createState() => _ShapeMatcherScreenState();
}

class _ShapeMatcherScreenState extends State<ShapeMatcherScreen> with TickerProviderStateMixin {
  final List<ShapeItem> shapes = [
    ShapeItem('🔴', 'Red Circle', Colors.red), ShapeItem('🔵', 'Blue Square', Colors.blue),
    ShapeItem('🟢', 'Green Triangle', Colors.green), ShapeItem('🟡', 'Yellow Star', Colors.yellow.shade700),
    ShapeItem('🟣', 'Purple Heart', Colors.purple), ShapeItem('🟠', 'Orange Diamond', Colors.orange),
  ];
  ShapeItem? currentShape;
  int score = 0, highScore = 0, timeLeft = 20, level = 1;
  bool isPlaying = false, isGameOver = false;
  bool _burst = false;
  bool _showLevelUp = false;
  Timer? _timer;
  late AnimationController _correctCtrl, _levelUpCtrl, _pulseCtrl, _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _correctCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _levelUpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _startGame();
  }

  void _startGame() {
    setState(() { score = 0; timeLeft = 20; level = 1; isPlaying = true; isGameOver = false; _nextQuestion(); });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted && timeLeft > 0) { setState(() => timeLeft--); if (timeLeft == 0) _endGame(); }
    });
  }

  void _nextQuestion() => setState(() => currentShape = shapes[Random().nextInt(shapes.length)]);

  void _checkAnswer(ShapeItem selected) {
    if (!isPlaying || isGameOver) return;
    if (currentShape != null && selected.emoji == currentShape!.emoji) {
      HapticHelper.success();
      widget.sound.playCorrect();
      _correctCtrl.forward().then((_) => _correctCtrl.reset());
      setState(() { score += 10 * level; if (score > highScore) highScore = score; timeLeft = math.min(timeLeft + 2, 30); _burst = true; });
      Future.delayed(const Duration(milliseconds: 100), () { if (mounted) setState(() => _burst = false); });
      if (score >= level * 50) _levelUp(); else _nextQuestion();
    } else {
      HapticHelper.error();
      widget.sound.playWrong();
      _shakeCtrl.forward().then((_) => _shakeCtrl.reset());
      setState(() { if (score > 5) score -= 5; });
    }
  }

  void _levelUp() {
    HapticHelper.levelUp();
    setState(() { level++; _showLevelUp = true; });
    widget.sound.playLevelUp();
    _levelUpCtrl.forward().then((_) { _levelUpCtrl.reset(); setState(() => _showLevelUp = false); _nextQuestion(); });
  }

  void _endGame() { _timer?.cancel(); setState(() { isPlaying = false; isGameOver = true; }); widget.sound.playWin(); }

  @override
  void dispose() { _timer?.cancel(); _correctCtrl.dispose(); _levelUpCtrl.dispose(); _pulseCtrl.dispose(); _shakeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedGameBackground(
            colors: const [Color(0xFFE0FAF9), Color(0xFFEDFDFC), Color(0xFFCCF5F3)],
            emojis: const ['🔺', '🔵', '🟡', '🟢', '🔷'],
          ),
          SafeArea(
            child: Column(
              children: [
                GameScreenHeader(
                  title: 'Shape Matcher', subtitle: 'Find the matching shape! 🔺',
                  color: const Color(0xFF4ECDC4), emoji: '🔺', sound: widget.sound,
                  onBack: () { HapticHelper.light(); _timer?.cancel(); Navigator.pop(context, score); },
                  scoreWidgets: [
                    ScorePill(label: 'LEVEL', value: '$level', color: const Color(0xFF4ECDC4)),
                    ScorePill(label: 'SCORE', value: '$score', color: const Color(0xFF4ECDC4)),
                    ScorePill(label: 'BEST', value: '$highScore', color: const Color(0xFFFFD700)),
                    _TimerPill(timeLeft: timeLeft, totalTime: 20),
                  ],
                ),
                if (isPlaying && currentShape != null) ...[
                  Expanded(
                    flex: 2,
                    child: AnimatedBuilder(
                      animation: _shakeCtrl,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(math.sin(_shakeCtrl.value * math.pi * 6) * 10, 0),
                        child: child,
                      ),
                      child: AnimatedBuilder(
                        animation: _correctCtrl,
                        builder: (_, child) => Transform.scale(scale: 1.0 + _correctCtrl.value * 0.06, child: child),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [currentShape!.color.withOpacity(0.15), currentShape!.color.withOpacity(0.05)]),
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(color: currentShape!.color.withOpacity(0.3), width: 2),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(currentShape!.emoji, style: const TextStyle(fontSize: 90)),
                                    const SizedBox(height: 12),
                                    Text('Find: ${currentShape!.name}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: currentShape!.color)),
                                  ],
                                ),
                              ),
                            ),
                            if (_showLevelUp) LevelUpBanner(level: level, color: const Color(0xFF4ECDC4)),
                            if (_burst) IgnorePointer(child: ParticlesBurst(active: _burst, color: currentShape!.color)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
                        itemCount: shapes.length,
                        itemBuilder: (_, i) => _ShapeButton(shape: shapes[i], onTap: () => _checkAnswer(shapes[i]), pulseCtrl: _pulseCtrl),
                      ),
                    ),
                  ),
                ],
                if (isGameOver)
                  GameOverCard(
                    isWin: true, score: score, winText: "Time's Up!", loseText: "Time's Up!",
                    color: const Color(0xFF4ECDC4), onReplay: _startGame,
                    onBack: () { HapticHelper.light(); Navigator.pop(context, score); },
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text('${timeLeft}s • Level $level • Tap the matching shape!', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapeButton extends StatefulWidget {
  final ShapeItem shape; final VoidCallback onTap; final AnimationController pulseCtrl;
  const _ShapeButton({required this.shape, required this.onTap, required this.pulseCtrl});
  @override
  State<_ShapeButton> createState() => _ShapeButtonState();
}

class _ShapeButtonState extends State<_ShapeButton> with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
  }
  @override
  void dispose() { _tapCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { _tapCtrl.forward(); HapticHelper.light(); },
      onTapUp: (_) { _tapCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _tapCtrl.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_tapCtrl, widget.pulseCtrl]),
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [widget.shape.color, widget.shape.color.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: widget.shape.color.withOpacity(0.45), blurRadius: 10 + widget.pulseCtrl.value * 4, offset: const Offset(0, 4))],
            ),
            child: Center(child: Text(widget.shape.emoji, style: const TextStyle(fontSize: 38))),
          ),
        ),
      ),
    );
  }
}

class ShapeItem {
  final String emoji, name; final Color color;
  ShapeItem(this.emoji, this.name, this.color);
}

// ============================================================================
// PATTERN REPEAT GAME — NEXT LEVEL
// ============================================================================
class PatternRepeatScreen extends StatefulWidget {
  final SoundService sound;
  const PatternRepeatScreen({Key? key, required this.sound}) : super(key: key);
  @override
  State<PatternRepeatScreen> createState() => _PatternRepeatScreenState();
}

class _PatternRepeatScreenState extends State<PatternRepeatScreen> with TickerProviderStateMixin {
  final List<Color> patternColors = [Colors.red, Colors.blue, Colors.green, Colors.yellow.shade700, Colors.purple, Colors.orange];
  final List<String> patternEmojis = ['🔴', '🔵', '🟢', '🟡', '🟣', '🟠'];
  final List<String> patternNames = ['Red', 'Blue', 'Green', 'Yellow', 'Purple', 'Orange'];

  List<int> sequence = [], userInput = [];
  int level = 1, score = 0, highScore = 0;
  bool isShowingPattern = false, isGameOver = false;
  int currentHighlightIndex = -1;
  bool _showLevelUp = false;
  late AnimationController _blinkCtrl, _levelUpCtrl, _pulseCtrl, _shakeCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _levelUpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _startNewRound();
  }

  void _startNewRound() {
    setState(() { userInput.clear(); sequence.add(Random().nextInt(6)); isShowingPattern = true; });
    _showPattern();
  }

  void _showPattern() async {
    await Future.delayed(const Duration(milliseconds: 400));
    for (int i = 0; i < sequence.length; i++) {
      setState(() => currentHighlightIndex = sequence[i]);
      widget.sound.playPop(); HapticHelper.light();
      _blinkCtrl.forward().then((_) => _blinkCtrl.reset());
      await Future.delayed(const Duration(milliseconds: 550));
      setState(() => currentHighlightIndex = -1);
      await Future.delayed(const Duration(milliseconds: 250));
    }
    setState(() => isShowingPattern = false);
  }

  void _onColorTap(int index) {
    if (isShowingPattern || isGameOver) return;
    HapticHelper.light();
    setState(() { userInput.add(index); currentHighlightIndex = index; });
    widget.sound.playPop();
    _blinkCtrl.forward().then((_) => _blinkCtrl.reset());
    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) setState(() => currentHighlightIndex = -1); });

    if (userInput.last != sequence[userInput.length - 1]) {
      HapticHelper.error();
      _shakeCtrl.forward().then((_) => _shakeCtrl.reset());
      _gameOver();
      return;
    }

    if (userInput.length == sequence.length) {
      HapticHelper.levelUp();
      setState(() { score += 10 * level; if (score > highScore) highScore = score; level++; _showLevelUp = true; });
      widget.sound.playCorrect();
      _levelUpCtrl.forward().then((_) {
        _levelUpCtrl.reset();
        setState(() => _showLevelUp = false);
        _startNewRound();
      });
    }
  }

  void _gameOver() {
    setState(() => isGameOver = true);
    widget.sound.playWin();
  }

  void _resetGame() {
    setState(() { sequence.clear(); userInput.clear(); level = 1; score = 0; isGameOver = false; });
    _startNewRound();
  }

  @override
  void dispose() { _blinkCtrl.dispose(); _levelUpCtrl.dispose(); _pulseCtrl.dispose(); _shakeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedGameBackground(
            colors: const [Color(0xFFFFF8E1), Color(0xFFFFFDE7), Color(0xFFFFF0C0)],
            emojis: const ['🔄', '🎵', '⭐', '🌀', '💫'],
          ),
          SafeArea(
            child: Column(
              children: [
                GameScreenHeader(
                  title: 'Pattern Repeat', subtitle: 'Watch then repeat! 🔄',
                  color: const Color(0xFFFFB74D), emoji: '🔄', sound: widget.sound,
                  onBack: () { HapticHelper.light(); Navigator.pop(context, score); },
                  scoreWidgets: [
                    ScorePill(label: 'LEVEL', value: '$level', color: const Color(0xFFFFB74D)),
                    ScorePill(label: 'SCORE', value: '$score', color: const Color(0xFFFFB74D)),
                    ScorePill(label: 'BEST', value: '$highScore', color: const Color(0xFFFFD700)),
                  ],
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _shakeCtrl,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(math.sin(_shakeCtrl.value * math.pi * 8) * 8, 0),
                      child: child,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Status text
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              key: ValueKey(isShowingPattern),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isShowingPattern ? [const Color(0xFF667EEA), const Color(0xFF764BA2)] : [const Color(0xFF11998E), const Color(0xFF38EF7D)],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [BoxShadow(color: (isShowingPattern ? const Color(0xFF667EEA) : const Color(0xFF11998E)).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(isShowingPattern ? '👀' : '👆', style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Text(isShowingPattern ? 'Watch the pattern...' : 'Now repeat it!',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                          // Progress dots
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(sequence.length, (i) {
                              final isDone = i < userInput.length;
                              return Container(
                                width: 10, height: 10,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDone ? const Color(0xFF11998E) : Colors.grey.shade300,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                          // Color grid
                          GridView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.3),
                            itemCount: 6,
                            itemBuilder: (_, i) => _PatternButton(
                              color: patternColors[i], name: patternNames[i], emoji: patternEmojis[i],
                              isHighlighted: currentHighlightIndex == i,
                              isDisabled: isShowingPattern || isGameOver,
                              onTap: () => _onColorTap(i),
                              pulseCtrl: _pulseCtrl,
                            ),
                          ),
                          if (_showLevelUp) ...[
                            const SizedBox(height: 16),
                            LevelUpBanner(level: level, color: const Color(0xFFFFB74D)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (isGameOver)
                  GameOverCard(
                    isWin: false, score: score, winText: 'Great Memory!', loseText: 'Wrong Pattern!',
                    color: const Color(0xFFFFB74D), onReplay: _resetGame,
                    onBack: () { HapticHelper.light(); Navigator.pop(context, score); },
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text('Sequence length: ${sequence.length} • Watch then repeat!', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternButton extends StatefulWidget {
  final Color color; final String name, emoji; final bool isHighlighted, isDisabled; final VoidCallback onTap; final AnimationController pulseCtrl;
  const _PatternButton({required this.color, required this.name, required this.emoji, required this.isHighlighted, required this.isDisabled, required this.onTap, required this.pulseCtrl});
  @override
  State<_PatternButton> createState() => _PatternButtonState();
}

class _PatternButtonState extends State<_PatternButton> with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut));
  }
  @override
  void dispose() { _tapCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { if (!widget.isDisabled) _tapCtrl.forward(); },
      onTapUp: (_) { _tapCtrl.reverse(); if (!widget.isDisabled) widget.onTap(); },
      onTapCancel: () => _tapCtrl.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_tapCtrl, widget.pulseCtrl]),
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isHighlighted
                    ? [widget.color, Colors.white, widget.color]
                    : [widget.color, widget.color.withOpacity(0.6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: widget.isHighlighted ? widget.color.withOpacity(0.9) : widget.color.withOpacity(0.4),
                  blurRadius: widget.isHighlighted ? 24 + widget.pulseCtrl.value * 8 : 10,
                  offset: const Offset(0, 4),
                  spreadRadius: widget.isHighlighted ? 2 : 0,
                ),
              ],
              border: widget.isHighlighted ? Border.all(color: Colors.white, width: 3) : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.emoji, style: TextStyle(fontSize: widget.isHighlighted ? 28 : 24)),
                const SizedBox(height: 2),
                Text(widget.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, shadows: [Shadow(color: Colors.black38, offset: Offset(1, 1))])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GAME SCREEN HEADER (Kept for individual games)
// ============================================================================
class GameScreenHeader extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color color;
  final String emoji;
  final List<Widget> scoreWidgets;
  final VoidCallback onBack;
  final SoundService? sound;
  const GameScreenHeader({
    Key? key, required this.title, required this.subtitle,
    required this.color, required this.emoji, required this.scoreWidgets,
    required this.onBack, this.sound,
  }) : super(key: key);
  @override
  State<GameScreenHeader> createState() => _GameScreenHeaderState();
}

class _GameScreenHeaderState extends State<GameScreenHeader> with SingleTickerProviderStateMixin {
  late AnimationController _waveCtrl;
  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }
  @override
  void dispose() { _waveCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(widget.color, widget.color.withBlue(255), _waveCtrl.value)!,
                widget.color.withOpacity(0.85),
              ],
            ),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
            boxShadow: [BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Row(
                  children: [
                    _GameBackButton(onTap: widget.onBack, color: widget.color),
                    const SizedBox(width: 12),
                    Text(widget.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                          Text(widget.subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
                        ],
                      ),
                    ),
                    if (widget.sound != null) _MuteButton(sound: widget.sound!),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: widget.scoreWidgets,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GameBackButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color color;
  const _GameBackButton({required this.onTap, required this.color});
  @override
  State<_GameBackButton> createState() => _GameBackButtonState();
}

class _GameBackButtonState extends State<_GameBackButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(_ctrl);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}