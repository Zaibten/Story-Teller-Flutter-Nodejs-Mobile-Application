import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';

import '../../providers/user_provider.dart';
import '../../services/audio.dart';

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
// SOUND SERVICE
// ============================================================================

// ============================================================================
// SOUND SERVICE (Updated with AudioService)
// ============================================================================

class SoundService {
  final AudioService _audioService = AudioService();
  
  bool get isMuted => _audioService.isMuted;

  Future<void> toggleMute() async {
    await _audioService.toggleMute();
  }

  Future<void> pauseMusic() async {
    await _audioService.pauseMusic();
  }

  Future<void> resumeMusic() async {
    await _audioService.resumeMusic();
  }

  Future<void> playPop() async {
    await _audioService.playPop();
  }

  Future<void> playCorrect() async {
    await _audioService.playCorrect();
  }

  Future<void> playWrong() async {
    await _audioService.playWrong();
  }

  Future<void> playWin() async {
    await _audioService.playWin();
  }

  Future<void> playLevelUp() async {
    await _audioService.playLevelUp();
  }
  
  Future<void> dispose() async {
    await _audioService.dispose();
  }
}
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

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
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
    
    // Initialize animations
    _waveAnimation = CurvedAnimation(parent: _waveController, curve: Curves.easeInOut);
    _floatAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _modalScaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _modalController, curve: Curves.elasticOut),
    );
    _modalFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _modalController, curve: Curves.easeIn),
    );
    _moodScaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _moodController, curve: Curves.easeOutBack),
    );
    _moodFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _moodController, curve: Curves.easeIn),
    );
    _moodCardScaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _moodCardController, curve: Curves.easeOutBack),
    );
    
    // Initialize audio service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService().init();
    });
  }

  @override
  void dispose() {
    // Dispose all animation controllers
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
    
    // Dispose audio service
    _sound.dispose();
    
    super.dispose();
  }

void _openGame(GameModel game) async {
  await _sound.playPop();
  if (!mounted) return;

  // Pause background music when game starts
  print('Opening game, pausing music');
  await _sound.pauseMusic();

  Widget screen;
  switch (game.id) {
    case GameId.numberPop:
      screen = NumberPopScreen(sound: _sound);
      break;
    case GameId.colorMatch:
      screen = ColorMatchScreen(sound: _sound);
      break;
    case GameId.memoryFlip:
      screen = MemoryFlipScreen(sound: _sound);
      break;
    case GameId.quickTap:
      screen = QuickTapScreen(sound: _sound);
      break;
    case GameId.shapeMatcher:
      screen = ShapeMatcherScreen(sound: _sound);
      break;
    case GameId.patternRepeat:
      screen = PatternRepeatScreen(sound: _sound);
      break;
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

  // Resume background music when returning from game
  print('Returning from game, resuming music');
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8ECF1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: _buildGameGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  

Widget _buildHeader() {
  final user = Provider.of<UserProvider>(context).user;
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: SafeArea(
      child: Column(
        children: [
          Stack(
            children: [
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return Container(
                    height: screenHeight * 0.19,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(const Color(0xFF667EEA), const Color(0xFF764BA2), _waveAnimation.value)!,
                          Color.lerp(const Color(0xFF764BA2), const Color(0xFFF093FB), _waveAnimation.value)!,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(35),
                        bottomRight: Radius.circular(35),
                      ),
                    ),
                  );
                },
              ),

              // Speaker Icon at Top Right
              Positioned(
                top: 100,
                right: 16,
                child: _MuteButton(sound: _sound),
              ),

              Positioned(
                top: -30,
                right: -20,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 80 + _pulseController.value * 15,
                      height: 80 + _pulseController.value * 15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.015,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // LEFT SIDE
                        AnimatedBuilder(
                          animation: _floatController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatAnimation.value),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: AnimatedBuilder(
                                      animation: _sparkleController1,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: 0.9 + (_sparkleController1.value * 0.2),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white.withOpacity(0.6),
                                                  blurRadius: 10,
                                                  spreadRadius: 1,
                                                )
                                              ],
                                            ),
                                            child: Image.asset(
                                              "assets/images/logo.png",
                                              width: 30,
                                              height: 30,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "MAGIC STORY",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "Adventure Awaits!",
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // RIGHT SIDE USER
                        AnimatedBuilder(
                          animation: _glowAnimation,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person, color: Color(0xFF667EEA), size: 12),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    user.name.split(" ")[0],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, color: Colors.yellow, size: 10),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.yellow, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Create Magic Story",
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  Widget _buildGameGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          for (int i = 0; i < kGames.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 0.3 + i * 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _entranceCtrl,
                  curve: Interval(i * 0.15, 1.0, curve: Curves.easeOutCubic),
                )),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _entranceCtrl,
                    curve: Interval(i * 0.15, 1.0),
                  ),
                  child: _GameCard(
                    game: kGames[i],
                    highScore: _highScores[kGames[i].id],
                    onTap: () => _openGame(kGames[i]),
                    floatCtrl: _floatCtrl,
                    index: i,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GameCard extends StatefulWidget {
  final GameModel game;
  final int? highScore;
  final VoidCallback onTap;
  final AnimationController floatCtrl;
  final int index;
  
  const _GameCard({
    required this.game,
    required this.onTap,
    this.highScore,
    required this.floatCtrl,
    required this.index,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  late Animation<double> _scale;
  late Animation<double> _elevate;
  late Animation<double> _floatOffset;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut));
    _elevate = Tween<double>(begin: 0, end: 8).animate(_hoverCtrl);
    _floatOffset = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: widget.floatCtrl,
        curve: Interval(widget.index * 0.1, 1.0, curve: Curves.easeInOutSine),
      ),
    );
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverCtrl.forward(),
      onTapUp: (_) { _hoverCtrl.reverse(); widget.onTap(); },
      onTapCancel: () => _hoverCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _floatOffset,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, -_floatOffset.value),
          child: AnimatedBuilder(
            animation: _hoverCtrl,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.game.primaryColor, widget.game.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: widget.game.primaryColor.withOpacity(0.3),
                      blurRadius: 16 + _elevate.value,
                      offset: Offset(0, 4 + _elevate.value / 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Animated background circles
                    Positioned(
                      right: -20,
                      top: -20,
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + value * 0.2,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      right: 30,
                      bottom: -30,
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 700),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.7 + value * 0.3,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text(
                                widget.game.emoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.game.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.game.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                  maxLines: 2,
                                ),
                                if (widget.highScore != null) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFE66D), size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Best: ${widget.highScore}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFFFE66D),
                                        ),
                                      ),
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Ages ${widget.game.minAge}-${widget.game.maxAge}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Icon(Icons.play_circle_rounded, color: Colors.white, size: 32),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await widget.sound.toggleMute();
        setState(() {
          _isMuted = widget.sound.isMuted;
        });
      },
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 8 + _pulseCtrl.value * 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: const Color(0xFF1a1a2e),
              size: 20,
            ),
          );
        },
      ),
    );
  }
}
class _FloatingEmojis extends StatefulWidget {
  @override
  State<_FloatingEmojis> createState() => _FloatingEmojisState();
}

class _FloatingEmojisState extends State<_FloatingEmojis> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
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
      builder: (_, __) => SizedBox(
        width: 60,
        height: 40,
        child: Stack(
          children: [
            Positioned(
              top: 4 + _ctrl.value * 4,
              right: 0,
              child: _floatingEmoji('🎮', 24),
            ),
            Positioned(
              bottom: 2 + _ctrl.value * 3,
              left: 0,
              child: _floatingEmoji('⭐', 20),
            ),
            Positioned(
              top: 14 + _ctrl.value * 2,
              left: 12,
              child: _floatingEmoji('🎲', 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _floatingEmoji(String emoji, double size) {
    return Text(emoji, style: TextStyle(fontSize: size));
  }
}

// ============================================================================
// NUMBER POP GAME (Enhanced with White Background)
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
  bool isWin = false;
  int highlightedNumber = -1;
  late AnimationController _shakeCtrl;
  late AnimationController _popCtrl;
  late AnimationController _levelUpCtrl;
  late AnimationController _comboCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _levelUpScale;
  late Animation<double> _comboScale;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _popCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _levelUpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _comboCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _levelUpScale = Tween<double>(begin: 0.5, end: 1.2).animate(CurvedAnimation(parent: _levelUpCtrl, curve: Curves.elasticOut));
    _comboScale = Tween<double>(begin: 1.0, end: 1.5).animate(CurvedAnimation(parent: _comboCtrl, curve: Curves.easeOutBack));
    _initGame();
  }

  void _initGame() {
    int gridSize = 3 + (level - 1) ~/ 2;
    if (gridSize > 5) gridSize = 5;
    int totalNumbers = gridSize * gridSize;
    List<int> nums = List.generate(totalNumbers, (i) => i + 1);
    nums.shuffle();
    setState(() {
      numbers = nums;
      currentNumber = 1;
      isGameOver = false;
      isWin = false;
      highlightedNumber = -1;
    });
  }

  void _onNumberTap(int number, int index) {
    if (isGameOver) return;
    
    setState(() {
      highlightedNumber = index;
    });
    
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && highlightedNumber == index) {
        setState(() {
          highlightedNumber = -1;
        });
      }
    });
    
    if (number == currentNumber) {
      widget.sound.playCorrect();
      _popCtrl.forward().then((_) => _popCtrl.reset());
      
      setState(() {
        score += 10 + (combo * 2);
        combo++;
        currentNumber++;
      });
      
      _comboCtrl.forward().then((_) => _comboCtrl.reset());
      
      if (currentNumber > numbers.length) {
        _levelUp();
      }
    } else {
      widget.sound.playWrong();
      _shakeCtrl.forward().then((_) => _shakeCtrl.reset());
      setState(() {
        isGameOver = true;
        combo = 0;
      });
    }
  }

  void _levelUp() {
    setState(() {
      level++;
      combo = 0;
      if (score > highScore) highScore = score;
    });
    widget.sound.playLevelUp();
    _levelUpCtrl.forward().then((_) {
      _levelUpCtrl.reset();
      _initGame();
    });
  }

  void _resetGame() {
    setState(() {
      level = 1;
      score = 0;
      combo = 0;
    });
    _initGame();
  }

  void _goBack() {
    Navigator.pop(context, isWin ? score : null);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _popCtrl.dispose();
    _levelUpCtrl.dispose();
    _comboCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int gridSize = 3 + (level - 1) ~/ 2;
    if (gridSize > 5) gridSize = 5;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildGameHeader(),
SizedBox(height: 10),
              const Text('Number Pop', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFFE94560))),
                 const Text('Tap numbers in order!', style: TextStyle(fontSize: 12, color: Colors.grey)),
              
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _shakeCtrl,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          math.sin(_shakeCtrl.value * math.pi * 8) * 5,
                          0,
                        ),
                        child: child,
                      );
                    },
                    child: Stack(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(24),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridSize,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                          itemCount: numbers.length,
                          itemBuilder: (context, index) {
                            return AnimatedBuilder(
                              animation: _popCtrl,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _popCtrl.isAnimating && numbers[index] == currentNumber - 1 ? 1.2 : 1.0,
                                  child: _NumberButton(
                                    number: numbers[index],
                                    onTap: () => _onNumberTap(numbers[index], index),
                                    isDisabled: isGameOver,
                                    isHighlighted: highlightedNumber == index,
                                    isNext: numbers[index] == currentNumber,
                                    pulseCtrl: _pulseCtrl,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _levelUpCtrl,
                          builder: (context, child) {
                            if (_levelUpCtrl.isAnimating) {
                              return Center(
                                child: Transform.scale(
                                  scale: _levelUpScale.value,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(40),
                                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.auto_awesome, size: 48, color: Color(0xFFE94560)),
                                        const SizedBox(height: 8),
                                        Text('Level $level!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE94560))),
                                        const Text('Great job!', style: TextStyle(fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isGameOver) _buildGameOverOverlay(),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFFE94560)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Text('Number Pop', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE94560))),
                // const Text('Tap numbers in order!', style: TextStyle(fontSize: 12, color: Colors.grey)),
              
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE94560).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('LEVEL', style: TextStyle(fontSize: 10, color: Color(0xFFE94560))),
                Text('$level', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE94560))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          AnimatedBuilder(
            animation: _comboCtrl,
            builder: (context, child) {
              return Transform.scale(
                scale: _comboScale.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: combo > 0 ? const Color(0xFFFFB74D).withOpacity(0.2) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text('COMBO', style: TextStyle(fontSize: 10, color: Color(0xFFFFB74D))),
                      Text('$combo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('SCORE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('$score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE94560))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE66D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('BEST', style: TextStyle(fontSize: 10, color: Color(0xFFFFB74D))),
                Text('$highScore', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied, size: 48, color: isWin ? Color(0xFFFFB74D) : Colors.grey),
          const SizedBox(height: 12),
          Text(isWin ? 'Perfect! 🎉' : 'Game Over!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(isWin ? 'You completed all numbers!' : 'Wrong number! Tap to try again.', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE94560), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Text('Play Again', style: TextStyle(fontSize: 16))),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('Tap numbers from 1 to ${numbers.length} in order!', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final int number;
  final VoidCallback onTap;
  final bool isDisabled;
  final bool isHighlighted;
  final bool isNext;
  final AnimationController pulseCtrl;
  
  const _NumberButton({
    required this.number,
    required this.onTap,
    this.isDisabled = false,
    this.isHighlighted = false,
    this.isNext = false,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedBuilder(
        animation: pulseCtrl,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: isHighlighted 
                  ? const LinearGradient(colors: [Color(0xFFFFB74D), Color(0xFFFF9800)])
                  : (isNext && !isDisabled 
                      ? const LinearGradient(colors: [Color(0xFFFFE66D), Color(0xFFFFB74D)])
                      : const LinearGradient(colors: [Colors.white, Colors.white])),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isHighlighted || (isNext && !isDisabled))
                      ? const Color(0xFFFFB74D).withOpacity(0.5) 
                      : Colors.grey.withOpacity(0.3),
                  blurRadius: isHighlighted || (isNext && !isDisabled) ? 16 + pulseCtrl.value * 4 : 8,
                  offset: Offset(0, isHighlighted || (isNext && !isDisabled) ? 8 : 4),
                ),
              ],
              border: Border.all(
                color: isNext && !isDisabled && !isHighlighted
                    ? const Color(0xFFFFB74D)
                    : Colors.grey[200]!,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold, 
                  color: (isHighlighted || (isNext && !isDisabled)) 
                      ? Colors.white 
                      : const Color(0xFFE94560),
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
// COLOR MATCH GAME (White Background)
// ============================================================================

class ColorMatchScreen extends StatefulWidget {
  final SoundService sound;
  const ColorMatchScreen({Key? key, required this.sound}) : super(key: key);

  @override
  State<ColorMatchScreen> createState() => _ColorMatchScreenState();
}

class _ColorMatchScreenState extends State<ColorMatchScreen> with TickerProviderStateMixin {
  final List<ColorItem> items = [
    ColorItem('RED', Colors.red),
    ColorItem('BLUE', Colors.blue),
    ColorItem('GREEN', Colors.green),
    ColorItem('YELLOW', Colors.yellow.shade700),
    ColorItem('PURPLE', Colors.purple),
    ColorItem('ORANGE', Colors.orange),
  ];
  
  ColorItem? currentItem;
  int score = 0;
  int highScore = 0;
  int timeLeft = 30;
  int streak = 0;
  bool isPlaying = false;
  bool isGameOver = false;
  Timer? _timer;
  late AnimationController _shakeCtrl;
  late AnimationController _correctCtrl;
  late AnimationController _streakCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _streakScale;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _correctCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _streakCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _streakScale = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _streakCtrl, curve: Curves.easeOutBack));
    _startGame();
  }

  void _startGame() {
    setState(() {
      score = 0;
      timeLeft = 30;
      streak = 0;
      isPlaying = true;
      isGameOver = false;
      _nextQuestion();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && timeLeft > 0) {
        setState(() => timeLeft--);
        if (timeLeft == 0) _endGame();
      }
    });
  }

  void _nextQuestion() {
    final random = Random();
    final item = items[random.nextInt(items.length)];
    setState(() => currentItem = item);
  }

  void _checkAnswer(String selectedColor) {
    if (!isPlaying || isGameOver) return;
    
    if (currentItem != null && selectedColor == currentItem!.text) {
      widget.sound.playCorrect();
      _correctCtrl.forward().then((_) => _correctCtrl.reset());
      _streakCtrl.forward().then((_) => _streakCtrl.reset());
      setState(() {
        streak++;
        score += 10 + (streak * 2);
        if (score > highScore) highScore = score;
        timeLeft += 1;
        if (timeLeft > 60) timeLeft = 60;
      });
      _nextQuestion();
    } else {
      widget.sound.playWrong();
      _shakeCtrl.forward().then((_) => _shakeCtrl.reset());
      setState(() {
        streak = 0;
        if (score > 5) score -= 5;
      });
    }
  }

  void _endGame() {
    if (!isPlaying) return;
    _timer?.cancel();
    setState(() {
      isPlaying = false;
      isGameOver = true;
    });
    widget.sound.playWin();
  }

  void _resetGame() {
    _startGame();
  }

  void _goBack() {
    _timer?.cancel();
    Navigator.pop(context, score);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    _correctCtrl.dispose();
    _streakCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (isPlaying && currentItem != null) ...[
                Expanded(
                  child: AnimatedBuilder(
                    animation: _shakeCtrl,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(math.sin(_shakeCtrl.value * math.pi * 6) * 8, 0),
                        child: child,
                      );
                    },
                    child: AnimatedBuilder(
                      animation: _correctCtrl,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _correctCtrl.isAnimating ? 1.05 : 1.0,
                          child: Container(
                            margin: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: currentItem!.color,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
                            ),
                            child: Center(
                              child: Text(
                                currentItem!.text,
                                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                _buildColorOptions(),
              ],
              if (isGameOver) _buildGameOverOverlay(),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF533483)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Color Match', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF533483))),
                const Text('Match the word to the color!', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _streakCtrl,
            builder: (context, child) {
              return Transform.scale(
                scale: _streakScale.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: streak > 0 ? const Color(0xFFFFB74D).withOpacity(0.2) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text('STREAK', style: TextStyle(fontSize: 10, color: Color(0xFFFFB74D))),
                      Text('$streak', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('SCORE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('$score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF533483))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('BEST', style: TextStyle(fontSize: 10, color: Color(0xFFFFB74D))),
                Text('$highScore', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: items.map((item) {
          return GestureDetector(
            onTap: isPlaying && !isGameOver ? () => _checkAnswer(item.text) : null,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                return Container(
                  width: 100,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [item.color, item.color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withOpacity(0.5),
                        blurRadius: 8 + _pulseCtrl.value * 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    item.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, shadows: [
                      Shadow(color: Colors.black38, offset: Offset(1, 1), blurRadius: 2),
                    ]),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Time\'s Up!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Final Score: $score', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF533483), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Text('Play Again', style: TextStyle(fontSize: 16))),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('Time Left: ${timeLeft}s', style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 24),
          Icon(Icons.color_lens, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          const Text('Tap the matching color!', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
// MEMORY FLIP GAME (White Background)
// ============================================================================

class MemoryFlipScreen extends StatefulWidget {
  final SoundService sound;
  const MemoryFlipScreen({Key? key, required this.sound}) : super(key: key);

  @override
  State<MemoryFlipScreen> createState() => _MemoryFlipScreenState();
}

class _MemoryFlipScreenState extends State<MemoryFlipScreen> with TickerProviderStateMixin {
  late List<MemoryCard> cards;
  int score = 0;
  int moves = 0;
  int matchedPairs = 0;
  int? firstIndex;
  int? secondIndex;
  bool isWaiting = false;
  bool isGameOver = false;
  late AnimationController _flipCtrl;
  late AnimationController _matchCtrl;
  late AnimationController _winCtrl;
  late AnimationController _pulseCtrl;

  final List<String> emojis = ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼'];

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _matchCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _winCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _initGame();
  }

  void _initGame() {
    List<MemoryCard> newCards = [];
    for (var emoji in emojis) {
      newCards.add(MemoryCard(emoji: emoji, isFlipped: false, isMatched: false, id: DateTime.now().millisecondsSinceEpoch + newCards.length));
      newCards.add(MemoryCard(emoji: emoji, isFlipped: false, isMatched: false, id: DateTime.now().millisecondsSinceEpoch + newCards.length));
    }
    newCards.shuffle();
    setState(() {
      cards = newCards;
      score = 0;
      moves = 0;
      matchedPairs = 0;
      firstIndex = null;
      secondIndex = null;
      isWaiting = false;
      isGameOver = false;
    });
  }

  void _onCardTap(int index) {
    if (isWaiting || isGameOver) return;
    if (cards[index].isMatched) return;
    if (firstIndex != null && secondIndex != null) return;
    if (firstIndex == index) return;

    widget.sound.playPop();
    setState(() {
      cards[index] = cards[index].copyWith(isFlipped: true);
      moves++;
    });

    if (firstIndex == null) {
      setState(() => firstIndex = index);
    } else if (secondIndex == null && firstIndex != index) {
      setState(() => secondIndex = index);
      _checkMatch();
    }
  }

  void _checkMatch() {
    isWaiting = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        if (cards[firstIndex!].emoji == cards[secondIndex!].emoji) {
          widget.sound.playCorrect();
          _matchCtrl.forward().then((_) => _matchCtrl.reset());
          setState(() {
            cards[firstIndex!] = cards[firstIndex!].copyWith(isMatched: true);
            cards[secondIndex!] = cards[secondIndex!].copyWith(isMatched: true);
            matchedPairs++;
            score += 10;
            if (matchedPairs == emojis.length) {
              isGameOver = true;
              _winCtrl.forward();
              widget.sound.playWin();
            }
          });
        } else {
          widget.sound.playWrong();
          setState(() {
            cards[firstIndex!] = cards[firstIndex!].copyWith(isFlipped: false);
            cards[secondIndex!] = cards[secondIndex!].copyWith(isFlipped: false);
          });
        }
        setState(() {
          firstIndex = null;
          secondIndex = null;
          isWaiting = false;
        });
      }
    });
  }

  void _resetGame() {
    _initGame();
  }

  void _goBack() {
    Navigator.pop(context, score);
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _matchCtrl.dispose();
    _winCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _matchCtrl,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _matchCtrl.isAnimating && cards[index].isMatched ? 1.1 : 1.0,
                          child: _MemoryCardWidget(
                            card: cards[index],
                            onTap: () => _onCardTap(index),
                            isDisabled: isGameOver || isWaiting,
                            pulseCtrl: _pulseCtrl,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (isGameOver) _buildGameOverOverlay(),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF0F3460)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Memory Flip', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F3460))),
                const Text('Find matching pairs!', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('SCORE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('$score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F3460))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('MOVES', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('$moves', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F3460))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return AnimatedBuilder(
      animation: _winCtrl,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + _winCtrl.value * 0.1,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 48, color: Color(0xFFFFB74D)),
                const SizedBox(height: 12),
                const Text('You Won! 🎉', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('Score: $score | Moves: $moves', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F3460), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Text('Play Again', style: TextStyle(fontSize: 16))),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('Pairs Matched: ${matchedPairs}/${emojis.length}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class MemoryCard {
  final String emoji;
  final bool isFlipped;
  final bool isMatched;
  final int id;

  MemoryCard({required this.emoji, required this.isFlipped, required this.isMatched, required this.id});

  MemoryCard copyWith({String? emoji, bool? isFlipped, bool? isMatched, int? id}) {
    return MemoryCard(
      emoji: emoji ?? this.emoji,
      isFlipped: isFlipped ?? this.isFlipped,
      isMatched: isMatched ?? this.isMatched,
      id: id ?? this.id,
    );
  }
}

class _MemoryCardWidget extends StatelessWidget {
  final MemoryCard card;
  final VoidCallback onTap;
  final bool isDisabled;
  final AnimationController pulseCtrl;
  
  const _MemoryCardWidget({
    required this.card,
    required this.onTap,
    this.isDisabled = false,
    required this.pulseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled || card.isMatched ? null : onTap,
      child: AnimatedBuilder(
        animation: pulseCtrl,
        builder: (context, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: card.isFlipped || card.isMatched 
                  ? const LinearGradient(colors: [Colors.white, Colors.white])
                  : const LinearGradient(colors: [Color(0xFF0F3460), Color(0xFF1A1A4E)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (card.isFlipped || card.isMatched) ? Colors.grey.withOpacity(0.3) : const Color(0xFF0F3460).withOpacity(0.3),
                  blurRadius: 8 + (card.isFlipped ? pulseCtrl.value * 4 : 0),
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: (card.isFlipped || card.isMatched)
                  ? AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(card.emoji, key: ValueKey(card.emoji), style: const TextStyle(fontSize: 32)),
                    )
                  : const Icon(Icons.question_mark, size: 32, color: Colors.white54),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// QUICK TAP GAME (White Background)
// ============================================================================

class QuickTapScreen extends StatefulWidget {
  final SoundService sound;
  const QuickTapScreen({Key? key, required this.sound}) : super(key: key);

  @override
  State<QuickTapScreen> createState() => _QuickTapScreenState();
}

class _QuickTapScreenState extends State<QuickTapScreen> with TickerProviderStateMixin {
  int score = 0;
  int highScore = 0;
  int timeLeft = 10;
  int targetIndex = 0;
  bool isPlaying = false;
  bool isGameOver = false;
  Timer? _gameTimer;
  Timer? _moveTimer;
  late AnimationController _tapCtrl;
  late AnimationController _targetCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _targetCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _startGame();
  }

  void _startGame() {
    setState(() {
      score = 0;
      timeLeft = 10;
      isPlaying = true;
      isGameOver = false;
      _randomizeTarget();
    });
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && timeLeft > 0) {
        setState(() => timeLeft--);
        if (timeLeft == 0) _endGame();
      }
    });
    _startMovingTarget();
  }

  void _startMovingTarget() {
    _moveTimer?.cancel();
    _moveTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted && isPlaying && !isGameOver) {
        _randomizeTarget();
        _targetCtrl.forward().then((_) => _targetCtrl.reset());
      }
    });
  }

  void _randomizeTarget() {
    setState(() {
      targetIndex = Random().nextInt(9);
    });
  }

  void _onTap(int index) {
    if (!isPlaying || isGameOver) return;
    
    if (index == targetIndex) {
      widget.sound.playCorrect();
      _tapCtrl.forward().then((_) => _tapCtrl.reset());
      setState(() {
        score++;
        if (score > highScore) highScore = score;
        timeLeft += 1;
        if (timeLeft > 20) timeLeft = 20;
      });
      _randomizeTarget();
      _targetCtrl.forward().then((_) => _targetCtrl.reset());
    } else {
      widget.sound.playWrong();
      setState(() {
        if (score > 0) score--;
      });
    }
  }

  void _endGame() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    setState(() {
      isPlaying = false;
      isGameOver = true;
    });
    widget.sound.playWin();
  }

  void _resetGame() {
    _startGame();
  }

  void _goBack() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    Navigator.pop(context, score);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _moveTimer?.cancel();
    _tapCtrl.dispose();
    _targetCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _targetCtrl,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: targetIndex == index && _targetCtrl.isAnimating ? 1.1 : 1.0,
                          child: GestureDetector(
                            onTap: () => _onTap(index),
                            child: AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: targetIndex == index 
                                        ? const LinearGradient(colors: [Color(0xFFFFB74D), Color(0xFFFF9800)])
                                        : const LinearGradient(colors: [Colors.white, Colors.white]),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: targetIndex == index 
                                            ? const Color(0xFFFFB74D).withOpacity(0.5) 
                                            : Colors.grey.withOpacity(0.3),
                                        blurRadius: targetIndex == index ? 16 + _pulseCtrl.value * 4 : 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: targetIndex == index ? const Color(0xFFFFB74D) : Colors.grey[200]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _tapCtrl,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _tapCtrl.isAnimating ? 0.9 : 1.0,
                                        child: Center(
                                          child: targetIndex == index
                                              ? const Icon(Icons.star, size: 40, color: Colors.white)
                                              : const Icon(Icons.circle_outlined, size: 40, color: Colors.grey),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (isGameOver) _buildGameOverOverlay(),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFFFF6B6B)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Tap', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B))),
                const Text('Tap the star as fast as you can!', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('SCORE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('$score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('BEST', style: TextStyle(fontSize: 10, color: Color(0xFFFFB74D))),
                Text('$highScore', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Time\'s Up!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Final Score: $score', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Text('Play Again', style: TextStyle(fontSize: 16))),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('Time Left: ${timeLeft}s', style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 24),
          Icon(Icons.star, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          const Text('Tap the glowing star!', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

// ============================================================================
// SHAPE MATCHER GAME (White Background)
// ============================================================================

class ShapeMatcherScreen extends StatefulWidget {
  final SoundService sound;
  const ShapeMatcherScreen({Key? key, required this.sound}) : super(key: key);

  @override
  State<ShapeMatcherScreen> createState() => _ShapeMatcherScreenState();
}

class _ShapeMatcherScreenState extends State<ShapeMatcherScreen> with TickerProviderStateMixin {
  final List<ShapeItem> shapes = [
    ShapeItem('🔴', 'Red Circle', Colors.red),
    ShapeItem('🔵', 'Blue Square', Colors.blue),
    ShapeItem('🟢', 'Green Triangle', Colors.green),
    ShapeItem('🟡', 'Yellow Star', Colors.yellow.shade700),
    ShapeItem('🟣', 'Purple Heart', Colors.purple),
    ShapeItem('🟠', 'Orange Diamond', Colors.orange),
  ];
  
  ShapeItem? currentShape;
  int score = 0;
  int highScore = 0;
  int timeLeft = 20;
  int level = 1;
  bool isPlaying = false;
  bool isGameOver = false;
  Timer? _timer;
  late AnimationController _correctCtrl;
  late AnimationController _levelUpCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _correctCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _levelUpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _startGame();
  }

  void _startGame() {
    setState(() {
      score = 0;
      timeLeft = 20;
      level = 1;
      isPlaying = true;
      isGameOver = false;
      _nextQuestion();
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && timeLeft > 0) {
        setState(() => timeLeft--);
        if (timeLeft == 0) _endGame();
      }
    });
  }

  void _nextQuestion() {
    final random = Random();
    final shape = shapes[random.nextInt(shapes.length)];
    setState(() => currentShape = shape);
  }

  void _checkAnswer(ShapeItem selectedShape) {
    if (!isPlaying || isGameOver) return;
    
    if (currentShape != null && selectedShape.emoji == currentShape!.emoji) {
      widget.sound.playCorrect();
      _correctCtrl.forward().then((_) => _correctCtrl.reset());
      setState(() {
        score += 10 * level;
        if (score > highScore) highScore = score;
        timeLeft += 2;
        if (timeLeft > 30) timeLeft = 30;
      });
      
      if (score >= level * 50) {
        _levelUp();
      } else {
        _nextQuestion();
      }
    } else {
      widget.sound.playWrong();
      setState(() {
        if (score > 5) score -= 5;
      });
    }
  }

  void _levelUp() {
    setState(() {
      level++;
    });
    widget.sound.playLevelUp();
    _levelUpCtrl.forward().then((_) {
      _levelUpCtrl.reset();
      _nextQuestion();
    });
  }

  void _endGame() {
    _timer?.cancel();
    setState(() {
      isPlaying = false;
      isGameOver = true;
    });
    widget.sound.playWin();
  }

  void _resetGame() {
    _startGame();
  }

  void _goBack() {
    _timer?.cancel();
    Navigator.pop(context, score);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _correctCtrl.dispose();
    _levelUpCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (isPlaying && currentShape != null) ...[
                Expanded(
                  flex: 2,
                  child: AnimatedBuilder(
                    animation: _correctCtrl,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _correctCtrl.isAnimating ? 1.1 : 1.0,
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 20)],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentShape!.emoji,
                                  style: const TextStyle(fontSize: 100),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Find the ${currentShape!.name}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4ECDC4)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: shapes.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _checkAnswer(shapes[index]),
                          child: AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [shapes[index].color, shapes[index].color.withOpacity(0.8)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: shapes[index].color.withOpacity(0.5),
                                      blurRadius: 8 + _pulseCtrl.value * 4,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    shapes[index].emoji,
                                    style: const TextStyle(fontSize: 40),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              if (isGameOver) _buildGameOverOverlay(),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF4ECDC4)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Shape Matcher', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4ECDC4))),
                const Text('Match the shapes!', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4ECDC4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('LEVEL', style: TextStyle(fontSize: 10, color: Color(0xFF4ECDC4))),
                Text('$level', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4ECDC4))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('SCORE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('$score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4ECDC4))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('BEST', style: TextStyle(fontSize: 10, color: Color(0xFFFFB74D))),
                Text('$highScore', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Time\'s Up!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Final Score: $score', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ECDC4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Text('Play Again', style: TextStyle(fontSize: 16))),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('Time Left: ${timeLeft}s', style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 24),
          Icon(Icons.category, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          const Text('Tap the matching shape!', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class ShapeItem {
  final String emoji;
  final String name;
  final Color color;
  ShapeItem(this.emoji, this.name, this.color);
}

// ============================================================================
// PATTERN REPEAT GAME (White Background)
// ============================================================================

class PatternRepeatScreen extends StatefulWidget {
  final SoundService sound;
  const PatternRepeatScreen({Key? key, required this.sound}) : super(key: key);

  @override
  State<PatternRepeatScreen> createState() => _PatternRepeatScreenState();
}

class _PatternRepeatScreenState extends State<PatternRepeatScreen> with TickerProviderStateMixin {
  final List<Color> patternColors = [
    Colors.red, Colors.blue, Colors.green, Colors.yellow.shade700, Colors.purple, Colors.orange
  ];
  final List<String> patternNames = ['Red', 'Blue', 'Green', 'Yellow', 'Purple', 'Orange'];
  
  List<int> sequence = [];
  List<int> userInput = [];
  int level = 1;
  int score = 0;
  int highScore = 0;
  bool isShowingPattern = false;
  bool isGameOver = false;
  int currentHighlightIndex = -1;
  late AnimationController _blinkCtrl;
  late AnimationController _levelUpCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _blinkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _levelUpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _startNewRound();
  }

  void _startNewRound() {
    setState(() {
      userInput.clear();
      sequence.add(Random().nextInt(6));
      isShowingPattern = true;
    });
    _showPattern();
  }

  void _showPattern() async {
    for (int i = 0; i < sequence.length; i++) {
      setState(() {
        currentHighlightIndex = sequence[i];
      });
      widget.sound.playPop();
      _blinkCtrl.forward().then((_) => _blinkCtrl.reset());
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        currentHighlightIndex = -1;
      });
      await Future.delayed(const Duration(milliseconds: 300));
    }
    setState(() {
      isShowingPattern = false;
    });
  }

  void _onColorTap(int index) {
    if (isShowingPattern || isGameOver) return;
    
    setState(() {
      userInput.add(index);
      currentHighlightIndex = index;
    });
    widget.sound.playPop();
    _blinkCtrl.forward().then((_) => _blinkCtrl.reset());
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          currentHighlightIndex = -1;
        });
      }
    });
    
    if (userInput.last != sequence[userInput.length - 1]) {
      _gameOver();
      return;
    }
    
    if (userInput.length == sequence.length) {
      setState(() {
        score += 10 * level;
        if (score > highScore) highScore = score;
        level++;
      });
      widget.sound.playCorrect();
      _levelUpCtrl.forward().then((_) {
        _levelUpCtrl.reset();
        _startNewRound();
      });
    }
  }

  void _gameOver() {
    setState(() {
      isGameOver = true;
    });
    widget.sound.playWin();
  }

  void _resetGame() {
    setState(() {
      sequence.clear();
      userInput.clear();
      level = 1;
      score = 0;
      isGameOver = false;
    });
    _startNewRound();
  }

  void _goBack() {
    Navigator.pop(context, score);
  }

  @override
  void dispose() {
    _blinkCtrl.dispose();
    _levelUpCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFE8ECF1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _levelUpCtrl,
                        builder: (context, child) {
                          if (_levelUpCtrl.isAnimating) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10)],
                              ),
                              child: Text(
                                'Level $level!',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D)),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      Text(
                        isShowingPattern ? 'Watch the pattern...' : 'Repeat the pattern!',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1a1a2e)),
                      ),
                      const SizedBox(height: 40),
                      GridView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          return AnimatedBuilder(
                            animation: _blinkCtrl,
                            builder: (context, child) {
                              return GestureDetector(
                                onTap: isShowingPattern || isGameOver ? null : () => _onColorTap(index),
                                child: AnimatedBuilder(
                                  animation: _pulseCtrl,
                                  builder: (context, child) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: currentHighlightIndex == index 
                                              ? [patternColors[index], patternColors[index].withOpacity(0.8)]
                                              : [patternColors[index].withOpacity(0.6), patternColors[index].withOpacity(0.4)],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: currentHighlightIndex == index 
                                                ? patternColors[index].withOpacity(0.8) 
                                                : Colors.grey.withOpacity(0.3),
                                            blurRadius: currentHighlightIndex == index ? 20 + _pulseCtrl.value * 4 : 8,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          patternNames[index],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [Shadow(color: Colors.black38, offset: Offset(1, 1))],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (isGameOver) _buildGameOverOverlay(),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFFFFB74D)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pattern Repeat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
                const Text('Remember and repeat!', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('LEVEL', style: TextStyle(fontSize: 10, color: Color(0xFFFFB74D))),
                Text('$level', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('SCORE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('$score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('BEST', style: TextStyle(fontSize: 10, color: Color(0xFFFFB74D))),
                Text('$highScore', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFB74D))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sentiment_dissatisfied, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Game Over!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Final Score: $score', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB74D), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Text('Play Again', style: TextStyle(fontSize: 16))),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.visibility, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('Watch then repeat the pattern!', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}