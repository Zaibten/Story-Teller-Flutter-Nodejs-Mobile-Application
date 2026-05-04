// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/global_variables.dart';
import '../../../providers/user_provider.dart';
import '../../common/widgets/header.dart';
import '../auth/screens/auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _sparkleController;
  late AnimationController _rotateController;

  late Animation<double> _floatAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _rotateAnimation;

  final List<_Bubble> bubbles = List.generate(
    18,
    (i) => _Bubble(
      x: Random().nextDouble(),
      y: Random().nextDouble(),
      size: Random().nextDouble() * 25 + 10,
      speed: Random().nextDouble() * 0.002 + 0.001,
    ),
  );

  final List<_Sparkle> sparkles = List.generate(
    12,
    (i) => _Sparkle(
      x: Random().nextDouble(),
      y: Random().nextDouble(),
      size: Random().nextDouble() * 4 + 2,
      speed: Random().nextDouble() * 0.003 + 0.001,
    ),
  );

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _waveAnimation = CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _sparkleAnimation = CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _rotateAnimation = CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    );

    _bgController.addListener(() {
      for (var b in bubbles) {
        b.y -= b.speed;
        if (b.y < 0) b.y = 1;
      }
      for (var s in sparkles) {
        s.y -= s.speed;
        if (s.y < 0) {
          s.y = 1;
          s.x = Random().nextDouble();
        }
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _sparkleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  // ================= PROFILE =================
  Future<void> showProfileDialog(BuildContext context, String email) async {
    try {
      final response = await http.post(
        Uri.parse('https://code-sync-server-kappa.vercel.app/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final user = data['user'];

        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.purple.shade100,
                    child: const Icon(Icons.person,
                        size: 40, color: Colors.purple),
                  ),
                  const SizedBox(height: 10),
                  Text(user['name'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(user['email']),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  )
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {}
  }

  // ================= LOGOUT =================
  Future<void> showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, color: Colors.red, size: 40),
              const SizedBox(height: 10),
              const Text("Logout?", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();

                      Provider.of<UserProvider>(context, listen: false)
                          .clearUser();

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AuthScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text("Logout"),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // ================= TILE =================
  Widget tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (_, __) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text(subtitle,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ================= MAGIC MOMENTS SECTION =================
  Widget _magicMomentsSection() {
    return AnimatedBuilder(
      animation: _sparkleAnimation,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.only(top: 8, bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade50,
                Colors.grey.shade100,
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.purple.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with animated sparkle
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _rotateAnimation,
                    builder: (context, _) {
                      return Transform.rotate(
                        angle: _rotateAnimation.value * 2 * pi,
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.purple.shade400,
                          size: 24,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "✨ Magic Moments ✨",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Animated rotating tips
              SizedBox(
                height: 60,
                child: AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, _) {
                    final tipIndex = (_waveAnimation.value * 10).toInt() % _magicTips.length;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Row(
                        key: ValueKey(tipIndex),
                        children: [
                          Icon(
                            _magicIcons[tipIndex % _magicIcons.length],
                            color: Colors.orange.shade400,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _magicTips[tipIndex],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Story progress with animated bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.book,
                      color: Colors.purple,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your Story Journey",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _storyProgress,
                              backgroundColor: Colors.white,
                              color: Colors.purple.shade400,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        "${(_storyProgress * 100).toInt()}%",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Fun fact row
              Row(
                children: [
                  Icon(
                    Icons.celebration,
                    color: Colors.pink.shade300,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "🎉 You've created ${(_storyProgress * 100).toInt()} magical stories!",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Magic tips data
  final List<String> _magicTips = [
    "📖 Create your own fairy tale adventure",
    "🎨 Add magical characters to your story",
    "✨ Every story has a happy ending",
    "🌈 Let your imagination soar high",
    "🦄 Unicorns love magical stories",
    "⭐ Rate stories to earn magic points",
    "🔮 New magical worlds await you",
  ];

  final List<IconData> _magicIcons = [
    Icons.auto_stories,
    Icons.brush,
    Icons.star,
    Icons.psychology,
    Icons.favorite,
    Icons.emoji_emotions,
    Icons.castle,
  ];

  double get _storyProgress {
    // Simulate progress based on time of day or random but consistent
    final now = DateTime.now();
    final minute = now.minute;
    return 0.3 + (minute % 70) / 100;
  }

  // ================= ANIMATED BACKGROUND =================
  Widget _background() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Colors.purple.shade50,
            Colors.blue.shade50,
            Colors.pink.shade50,
            Colors.white,
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Animated gradient overlay
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      -0.3 + _waveAnimation.value * 0.6,
                      -0.2 + _waveAnimation.value * 0.4,
                    ),
                    radius: 1.2,
                    colors: [
                      Colors.purple.withOpacity(0.15),
                      Colors.blue.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating bubbles
          ...bubbles.map((b) {
            return AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) {
                return Positioned(
                  left: b.x * MediaQuery.of(context).size.width,
                  top: b.y * MediaQuery.of(context).size.height,
                  child: Container(
                    width: b.size,
                    height: b.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.purple.withOpacity(0.2),
                          Colors.blue.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Twinkling sparkles
          ...sparkles.map((s) {
            return AnimatedBuilder(
              animation: _sparkleAnimation,
              builder: (context, _) {
                final opacity = 0.3 + _sparkleAnimation.value * 0.7;
                return Positioned(
                  left: s.x * MediaQuery.of(context).size.width,
                  top: s.y * MediaQuery.of(context).size.height,
                  child: Container(
                    width: s.size,
                    height: s.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.yellow.withOpacity(opacity * 0.5),
                    ),
                  ),
                );
              },
            );
          }),

          // Rotating stars
          ...List.generate(5, (i) {
            final angle = (i * 72) * (pi / 180);
            return AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, _) {
                final rotAngle = angle + _rotateAnimation.value * 2 * pi;
                final x = 0.5 + cos(rotAngle) * 0.4;
                final y = 0.5 + sin(rotAngle) * 0.3;
                return Positioned(
                  left: x * MediaQuery.of(context).size.width - 12,
                  top: y * MediaQuery.of(context).size.height - 12,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, _) {
                      return Transform.scale(
                        scale: 0.8 + _pulseAnimation.value * 0.4,
                        child: Icon(
                          Icons.star,
                          color: Colors.yellow.withOpacity(0.3),
                          size: 18,
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget header(user) {
    final size = MediaQuery.of(context).size;

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade400,
            Colors.pink.shade300,
            Colors.blue.shade300,
            Colors.purple.shade400,
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(45),
          bottomRight: Radius.circular(45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated wave overlay
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, _) {
              return Positioned.fill(
                child: CustomPaint(
                  painter: WavePainter(_waveAnimation.value),
                ),
              );
            },
          ),

          // Pulsing glow orb
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 160 + (_pulseController.value * 50),
                  height: 160 + (_pulseController.value * 50),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.3),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating sparkles in header
          ...List.generate(8, (i) {
            return AnimatedBuilder(
              animation: _sparkleAnimation,
              builder: (context, _) {
                return Positioned(
                  left: 20 + (i * 40.0) + (_sparkleAnimation.value * 10),
                  top: 30 + (i % 3 * 20) + (_sparkleAnimation.value * 5),
                  child: Icon(
                    Icons.star,
                    color: Colors.white.withOpacity(0.6),
                    size: 8 + (i % 3),
                  ),
                );
              },
            );
          }),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // TOP ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // LEFT (LOGO + FLOAT)
                      AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, _) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnimation.value),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    "assets/images/logo.png",
                                    width: 34,
                                    height: 34,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "MAGIC STORY",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    Text(
                                      "Adventure Awaits ✨",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // USER CHIP with pulse
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, _) {
                          return Transform.scale(
                            scale: 1 + (_pulseAnimation.value * 0.05),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person,
                                      color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    user.name.split(" ")[0],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // BIG ANIMATED TITLE
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Transform.scale(
                        scale: 1 + (_pulseController.value * 0.05),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _rotateAnimation,
                                builder: (context, _) {
                                  return Transform.rotate(
                                    angle: _rotateAnimation.value * 2 * pi,
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Magic Settings ✨",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Magical quote
                  AnimatedBuilder(
                    animation: _sparkleAnimation,
                    builder: (context, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getMagicalQuote(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMagicalQuote() {
    const quotes = [
      "✨ Where imagination takes flight ✨",
      "🔮 Every story is a new adventure 🔮",
      "⭐ Believe in the magic within you ⭐",
      "🌈 Dream big, shine bright 🌈",
      "🦄 Unicorns and rainbows await 🦄",
    ];
    final index = (_floatController.value * 100).toInt() % quotes.length;
    return quotes[index];
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _background(),
          Column(
            children: [
              MagicHeader(
      height: 170,

      // pass animations so it looks SAME as homepage
      floatAnimation: _floatAnimation,
      waveAnimation: _waveAnimation,
      pulseAnimation: _pulseAnimation,
      sparkleAnimation1: _sparkleAnimation,
      sparkleAnimation2: _sparkleAnimation,
      shimmerAnimation: _waveAnimation,
      glowAnimation: _pulseAnimation,

      // optional (you can keep false if not used)
      hasSelectedCharacter: false,
      selectedCharacterName: null,
    ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    tile(
                      icon: Icons.person,
                      title: "Profile",
                      subtitle: "See your magical info",
                      color: Colors.purple,
                      onTap: () => showProfileDialog(context, user.email),
                    ),
                    tile(
                      icon: Icons.lock,
                      title: "Password",
                      subtitle: "Change secret password",
                      color: Colors.blue,
                    ),
                    tile(
                      icon: Icons.info,
                      title: "About App",
                      subtitle: "Magic world ✨",
                      color: Colors.orange,
                    ),
                    tile(
                      icon: Icons.logout,
                      title: "Logout",
                      subtitle: "Leave magical world",
                      color: Colors.red,
                      onTap: () => showLogoutDialog(context),
                    ),
                    // NEW: Magic Moments Section below the tiles
                    _magicMomentsSection(),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

// ================= BUBBLE =================
class _Bubble {
  double x;
  double y;
  double size;
  double speed;

  _Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

// ================= SPARKLE =================
class _Sparkle {
  double x;
  double y;
  double size;
  double speed;

  _Sparkle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

// ================= WAVE PAINTER =================
class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 20.0;
    final waveLength = size.width;

    path.moveTo(0, size.height - 30);

    for (double x = 0; x <= waveLength; x += 10) {
      final y = size.height - 30 +
          sin((x / waveLength * 2 * pi) + (animationValue * 2 * pi)) *
              waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}