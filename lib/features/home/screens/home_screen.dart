import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = '/home_screen';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int? _selectedCharacterIndex;
  String? _selectedStoryWorld;
  String? _selectedMood;
  Character? _selectedCharacterData;
  StoryWorld? _selectedWorldData;
  
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

  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Character> characters = [
    Character(name: "Cat", gifPath: "assets/images/cat.gif", soundPath: "sounds/cat.mp3", emoji: "🐱", color: const Color(0xFFFF9A9E), lightColor: const Color(0xFFFFF0F0)),
    Character(name: "Lion", gifPath: "assets/images/lion.gif", soundPath: "sounds/lion.mp3", emoji: "🦁", color: const Color(0xFFFECF6E), lightColor: const Color(0xFFFFF8E8)),
    Character(name: "Elephant", gifPath: "assets/images/elephant.gif", soundPath: "sounds/elephant.mp3", emoji: "🐘", color: const Color(0xFFA18CD1), lightColor: const Color(0xFFF3EEFF)),
    Character(name: "Mouse", gifPath: "assets/images/mouse.gif", soundPath: "sounds/mouse.mp3", emoji: "🐭", color: const Color(0xFF6EE7B7), lightColor: const Color(0xFFEEFFFA)),
    Character(name: "Monkey", gifPath: "assets/images/monkey.gif", soundPath: "sounds/monkey.mp3", emoji: "🐒", color: const Color(0xFFFFB347), lightColor: const Color(0xFFFFF5E8)),
    Character(name: "Crocodile", gifPath: "assets/images/crocodile.gif", soundPath: "sounds/crocodile.mp3", emoji: "🐊", color: const Color(0xFF6DBE45), lightColor: const Color(0xFFF0FFE8)),
  ];

  final List<StoryWorld> storyWorlds = [
    StoryWorld(name: "Forest", gifPath: "assets/images/forest.gif", emoji: "🌳", color: const Color(0xFF4CAF50), lightColor: const Color(0xFFE8F5E9), description: "Magical forest adventure", bgColor: const Color(0xFF2E7D32)),
    StoryWorld(name: "Space", gifPath: "assets/images/space.gif", emoji: "🚀", color: const Color(0xFF9C27B0), lightColor: const Color(0xFFF3E5F5), description: "Outer space exploration", bgColor: const Color(0xFF6A1B9A)),
    StoryWorld(name: "Castle", gifPath: "assets/images/castle.gif", emoji: "🏰", color: const Color(0xFFE91E63), lightColor: const Color(0xFFFCE4EC), description: "Enchanted castle tales", bgColor: const Color(0xFFAD1457)),
    StoryWorld(name: "City", gifPath: "assets/images/city.gif", emoji: "🌆", color: const Color(0xFF2196F3), lightColor: const Color(0xFFE3F2FD), description: "Busy city adventures", bgColor: const Color(0xFF0D47A1)),
  ];

  final List<Mood> moods = [
    Mood(name: "Happy", emoji: "😊", icon: Icons.emoji_emotions, color: const Color(0xFFFFD54F), description: "", bgColor: const Color(0xFFF9A825)),
    Mood(name: "Funny", emoji: "😂", icon: Icons.emoji_emotions, color: const Color(0xFFFF8A65), description: "", bgColor: const Color(0xFFE64A19)),
    Mood(name: "Adventure", emoji: "⚔️", icon: Icons.explore, color: const Color(0xFFEF5350), description: "", bgColor: const Color(0xFFC62828)),
    Mood(name: "Bedtime", emoji: "🌙", icon: Icons.nightlight_round, color: const Color(0xFF7986CB), description: "", bgColor: const Color(0xFF283593)),
  ];

  @override
  void initState() {
    super.initState();
    
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(_glowController);
    
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -5, end: 5).animate(_floatController);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _sparkleController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _sparkleController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _modalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _modalScaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _modalController, curve: Curves.elasticOut),
    );
    _modalFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _modalController, curve: Curves.easeOut),
    );
    
    _moodController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _moodScaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _moodController, curve: Curves.elasticOut),
    );
    _moodFadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _moodController, curve: Curves.easeOut),
    );
    
    _moodCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _moodCardScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _moodCardController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
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
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playCharacterSound(String soundPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(soundPath));
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  void _showStoryWorldModal() {
    if (_selectedCharacterIndex != null) {
      _selectedCharacterData = characters[_selectedCharacterIndex!];
    }
    _modalController.forward(from: 0);
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AnimatedBuilder(
          animation: _modalController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _modalFadeAnimation,
              child: ScaleTransition(
                scale: _modalScaleAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    child: _buildStoryWorldModalContent(),
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _selectedStoryWorld = null;
      });
    });
  }

  Widget _buildStoryWorldModalContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _sparkleController1,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _sparkleController1.value * 3.14,
                          child: const Text("✨", style: TextStyle(fontSize: 32)),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Choose Your World",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedBuilder(
                      animation: _sparkleController2,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: -_sparkleController2.value * 3.14,
                          child: const Text("🌍", style: TextStyle(fontSize: 32)),
                        );
                      },
                    ),
                  ],
                ),
                if (_selectedCharacterData != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedCharacterData!.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedCharacterData!.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          "Adventure with ${_selectedCharacterData!.name}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedCharacterData!.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // World Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: storyWorlds.map((world) {
                final isSelected = _selectedStoryWorld == world.name;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedStoryWorld = world.name;
                      _selectedWorldData = world;
                    });
                    _modalController.reset();
                    Navigator.pop(context);
                    _showMoodSelectionModal();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? world.color : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isSelected ? world.color : Colors.grey.shade200,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? world.color.withOpacity(0.4) : Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : world.lightColor,
                            shape: BoxShape.circle,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.asset(
                              world.gifPath,
                              height: 80,
                              width: 80,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(world.emoji, style: const TextStyle(fontSize: 50));
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          world.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : world.color,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 4),
                          const Icon(Icons.check_circle, color: Colors.white, size: 16),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Close Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Close", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoodSelectionModal() {
    _moodController.forward(from: 0);
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AnimatedBuilder(
          animation: _moodController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _moodFadeAnimation,
              child: ScaleTransition(
                scale: _moodScaleAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    child: _buildMoodSelectionModalContent(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

Widget _buildMoodSelectionModalContent() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(48),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 30,
          spreadRadius: 5,
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated Header (slightly smaller)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(48),
              topRight: Radius.circular(48),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _sparkleController2,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _sparkleController2.value * 3.14,
                        child: const Text("🎭", style: TextStyle(fontSize: 32)),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "How do you feel?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _sparkleController1,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: -_sparkleController1.value * 3.14,
                        child: const Text("🎪", style: TextStyle(fontSize: 32)),
                      );
                    },
                  ),
                ],
              ),
              if (_selectedWorldData != null && _selectedCharacterData != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_selectedWorldData!.color.withOpacity(0.15), _selectedWorldData!.color.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "${_selectedCharacterData!.emoji} ${_selectedCharacterData!.name} in ${_selectedWorldData!.emoji} ${_selectedWorldData!.name}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _selectedWorldData!.color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Mood Grid - Smaller and tighter
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85, // Makes cards more square and compact
            children: moods.asMap().entries.map((entry) {
              final index = entry.key;
              final mood = entry.value;
              final isSelected = _selectedMood == mood.name;
              return TweenAnimationBuilder(
                duration: Duration(milliseconds: 250 + index * 80),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.85 + (value * 0.15),
                    child: Opacity(
                      opacity: value,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMood = mood.name;
                          });
                          _moodCardController.forward(from: 0);
                          Future.delayed(const Duration(milliseconds: 200), () {
                            _moodController.reset();
                            Navigator.pop(context);
                            _showStoryGenerationDialog();
                          });
                        },
                        child: AnimatedBuilder(
                          animation: _moodCardController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isSelected ? _moodCardScaleAnimation.value : 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [mood.color, mood.color.withOpacity(0.8)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : const LinearGradient(
                                          colors: [Colors.white, Color(0xFFFFF5E6)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: isSelected ? mood.color : Colors.grey.shade200,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected ? mood.color.withOpacity(0.4) : Colors.grey.withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: isSelected ? 1.0 + (_pulseController.value * 0.08) : 1.0,
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isSelected ? Colors.white : mood.color.withOpacity(0.2),
                                              shape: BoxShape.circle,
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.white.withOpacity(0.5),
                                                        blurRadius: 8,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Text(
                                              mood.emoji,
                                              style: TextStyle(
                                                fontSize: isSelected ? 44 : 38,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      mood.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : mood.color,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(height: 6),
                                      AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: 1.0 + (_pulseController.value * 0.15),
                                            child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
        
        // Only Back button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                _moodController.reset();
                Navigator.pop(context);
                _showStoryWorldModal();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              child: const Text("← Back to Worlds"),
            ),
          ),
        ),
      ],
    ),
  );
}
  void _showStoryGenerationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(48)),
          child: Container(
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, (_selectedWorldData?.color ?? const Color(0xFF6C63FF)).withOpacity(0.15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(48),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.1),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: (_selectedWorldData?.color ?? const Color(0xFF6C63FF)).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _selectedMood == "Happy" ? "😊" :
                          _selectedMood == "Funny" ? "😂" :
                          _selectedMood == "Adventure" ? "⚔️" : "🌙",
                          style: const TextStyle(fontSize: 64),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  "✨ Creating Your Magic Story ✨",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _selectedWorldData?.color ?? const Color(0xFF6C63FF),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  "${_selectedCharacterData?.emoji} ${_selectedCharacterData?.name} • ${_selectedWorldData?.emoji} ${_selectedWorldData?.name}",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_selectedMood != null ? moods.firstWhere((m) => m.name == _selectedMood).color : const Color(0xFF6C63FF)).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    "$_selectedMood Mood",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _selectedMood != null ? moods.firstWhere((m) => m.name == _selectedMood).color : const Color(0xFF6C63FF),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  "Weaving a magical tale just for you... 🎨",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: _selectedWorldData?.color ?? const Color(0xFF6C63FF), fontSize: 15)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 3 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          children: [
            // Animated Header (unchanged)
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
                Positioned(
                  top: -20,
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
                                            child: const Text("✨", style: TextStyle(fontSize: 20)),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
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
                                            color: Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
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
                                    AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        return Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.person, color: Color(0xFF667EEA), size: 12),
                                        );
                                      },
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
                                    AnimatedBuilder(
                                      animation: _sparkleController2,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: 0.8 + (_sparkleController2.value * 0.4),
                                          child: const Icon(Icons.verified, color: Colors.yellow, size: 10),
                                        );
                                      },
                                    ),
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
                            AnimatedBuilder(
                              animation: _sparkleController1,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _sparkleController1.value * 3.14,
                                  child: const Icon(Icons.auto_awesome, color: Colors.yellow, size: 14),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedCharacterIndex != null
                                    ? "✨ Ready with ${characters[_selectedCharacterIndex!].name}! ✨"
                                    : "🌸 Tap any character to begin! 🌸",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
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

            const SizedBox(height: 12),

            // Character Grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: screenWidth * 0.03,
                    mainAxisSpacing: screenWidth * 0.03,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    final isSelected = _selectedCharacterIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCharacterIndex = index;
                        });
                        _bounceController.forward(from: 0);
                        _playCharacterSound(character.soundPath);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [character.color, character.color.withOpacity(0.7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [Colors.white, Color(0xFFFFF5E6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(color: character.color, width: 3)
                              : Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? character.color.withOpacity(0.4)
                                  : Colors.grey.withOpacity(0.2),
                              blurRadius: isSelected ? 12 : 6,
                              offset: Offset(0, isSelected ? 6 : 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.asset(
                                  character.gifPath,
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: character.lightColor,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Center(
                                        child: Text(character.emoji, style: const TextStyle(fontSize: 40)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : character.color,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                character.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? character.color : Colors.white,
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 6),
                              const Icon(Icons.star, color: Colors.white, size: 14),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Generate Button
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ElevatedButton(
                onPressed: _selectedCharacterIndex != null
                    ? () {
                        _showStoryWorldModal();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedCharacterIndex != null
                      ? characters[_selectedCharacterIndex!].color
                      : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_stories, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCharacterIndex != null
                          ? "Generate ${characters[_selectedCharacterIndex!].name}'s Story"
                          : "Select a Character First",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Character {
  final String name;
  final String gifPath;
  final String soundPath;
  final String emoji;
  final Color color;
  final Color lightColor;

  Character({
    required this.name,
    required this.gifPath,
    required this.soundPath,
    required this.emoji,
    required this.color,
    required this.lightColor,
  });
}

class StoryWorld {
  final String name;
  final String gifPath;
  final String emoji;
  final Color color;
  final Color lightColor;
  final String description;
  final Color bgColor;

  StoryWorld({
    required this.name,
    required this.gifPath,
    required this.emoji,
    required this.color,
    required this.lightColor,
    required this.description,
    required this.bgColor,
  });
}

class Mood {
  final String name;
  final String emoji;
  final IconData icon;
  final Color color;
  final String description;
  final Color bgColor;

  Mood({
    required this.name,
    required this.emoji,
    required this.icon,
    required this.color,
    required this.description,
    required this.bgColor,
  });
}