// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/global_variables.dart';
import '../../../providers/user_provider.dart';
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
late Animation<double> _floatAnimation;
late Animation<double> _waveAnimation;
late AnimationController _waveController;
  final List<_Bubble> bubbles = List.generate(
    18,
    (i) => _Bubble(
      x: Random().nextDouble(),
      y: Random().nextDouble(),
      size: Random().nextDouble() * 25 + 10,
      speed: Random().nextDouble() * 0.002 + 0.001,
    ),
  );

 @override
void initState() {
  super.initState();

  _bgController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  // FLOAT
  _floatController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  _floatAnimation = Tween<double>(begin: -6, end: 6).animate(
    CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
  );

  // PULSE (IMPORTANT FIX)
  _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  // WAVE
  _waveController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  _waveAnimation = CurvedAnimation(
    parent: _waveController,
    curve: Curves.easeInOut,
  );

  _bgController.addListener(() {
    for (var b in bubbles) {
      b.y -= b.speed;
      if (b.y < 0) b.y = 1;
    }
    setState(() {});
  });
}

  // @override
  // void dispose() {
  //   _bgController.dispose();
  //   _floatController.dispose();
  //   super.dispose();
  // }
@override
void dispose() {
  _bgController.dispose();
  _floatController.dispose();
  _pulseController.dispose();
  _waveController.dispose();
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

  // ================= BACKGROUND =================
  Widget _background() {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          ...bubbles.map((b) {
            return Positioned(
              left: b.x * MediaQuery.of(context).size.width,
              top: b.y * MediaQuery.of(context).size.height,
              child: Container(
                width: b.size,
                height: b.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.06),
                ),
              ),
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
    height: 200,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.purple.shade200,
          Colors.blue.shade200,
          Colors.pink.shade100,
        ],
      ),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(35),
        bottomRight: Radius.circular(35),
      ),
    ),
    child: Stack(
      children: [

        // 🌊 Animated glow bubble
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120 + (_pulseController.value * 30),
                height: 120 + (_pulseController.value * 30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            );
          },
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.asset(
                                  "assets/images/logo.png",
                                  width: 32,
                                  height: 32,
                                ),
                              ),

                              const SizedBox(width: 10),

                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "MAGIC STORY",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    "Adventure Awaits ✨",
                                    style: TextStyle(
                                      fontSize: 10,
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

                    // USER CHIP
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            user.name.split(" ")[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // BIG ANIMATED TITLE
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: 1 + (_pulseController.value * 0.04),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Center(
                          child: Text(
                            "Magic Setting ✨",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
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
  
  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _background(),
          Column(
            children: [
              header(user),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
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