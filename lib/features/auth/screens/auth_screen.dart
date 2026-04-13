// ignore_for_file: avoid_print

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pictureai/features/auth/services/auth_service.dart';
import '../../../constants/utils.dart';

class AuthScreen extends StatefulWidget {
  static const String routeName = '/auth_screen';

  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  final AuthService authService = AuthService();

  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isSignupScreen = true;
  bool isMale = true;

  late AnimationController _cloudController;
  late AnimationController _fairyController;

  @override
  void initState() {
    super.initState();

    // ☁️ Clouds slow animation
    _cloudController =
        AnimationController(vsync: this, duration: Duration(seconds: 30))
          ..repeat();

    // 🧚 Fairy floating animation
    _fairyController =
        AnimationController(vsync: this, duration: Duration(seconds: 4))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _fairyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final random = Random();

    return Scaffold(
      body: Stack(
        children: [
          // 🌈 BACKGROUND (child-friendly gradient)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF89CFF0), // sky blue
                  Color(0xFFE0BBE4), // light purple
                  Color(0xFFFFDFD3), // peach
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ☁️ MULTIPLE MOVING CLOUDS
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _cloudController,
              builder: (context, child) {
                return Positioned(
                  left: (_cloudController.value * 300) - (index * 150),
                  top: 50.0 + index * 80,
                  child: Opacity(
                    opacity: 0.9,
                    child: Image.asset(
                      "assets/images/clouds.png",
                      height: 100 + index * 20,
                    ),
                  ),
                );
              },
            );
          }),

          // ✨ RANDOM TWINKLING STARS
          ...List.generate(40, (index) {
            double top = random.nextDouble() * 600;
            double left = random.nextDouble() * 300;

            return TweenAnimationBuilder(
              tween: Tween(begin: 0.2, end: 1.0),
              duration: Duration(milliseconds: 800 + index * 50),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Positioned(
                  top: top,
                  left: left,
                  child: Opacity(
                    opacity: value as double,
                    child: Icon(
                      Icons.star,
                      size: 8 + random.nextDouble() * 6,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            );
          }),

          // 🧚 FLOATING FAIRY
          AnimatedBuilder(
            animation: _fairyController,
            builder: (context, child) {
              return Positioned(
                right: 20,
                top: 120 + (_fairyController.value * 20),
                child: Image.asset(
                  "assets/images/fairy.png",
                  height: 120,
                ),
              );
            },
          ),

          // 🌟 LOGO WITH ANIMATION
          Align(
            alignment: Alignment.topCenter,
            child: TweenAnimationBuilder(
              duration: Duration(seconds: 2),
              tween: Tween(begin: 0.5, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value as double,
                  child: Opacity(
                    opacity: value,
                    child: Column(
                      children: [
                        SizedBox(height: 90),
                        Text(
                          "✨ Magic Story ✨",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                blurRadius: 12,
                                color: Colors.purple,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 📦 FORM BOX (more rounded + cute)
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 25),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 20)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSignupScreen)
                    buildMagicField(Icons.person, "Username",
                        userNameController),

                  if (isSignupScreen) SizedBox(height: 12),

                  buildMagicField(Icons.email, "Email", emailController),

                  SizedBox(height: 12),

                  buildMagicField(Icons.lock, "Password", passwordController,
                      isPassword: true),

                  SizedBox(height: 20),

                  // 🌈 PULSING BUTTON
                  TweenAnimationBuilder(
                    tween: Tween(begin: 0.95, end: 1.08),
                    duration: Duration(milliseconds: 900),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value as double,
                        child: GestureDetector(
                          onTap: () {
                            isSignupScreen
                                ? signupAction(context)
                                : loginAction(context);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 45),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.pinkAccent,
                                  Colors.orangeAccent
                                ],
                              ),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.5),
                                  blurRadius: 15,
                                )
                              ],
                            ),
                            child: Text(
                              isSignupScreen
                                  ? "Start Magic ✨"
                                  : "Login ✨",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 10),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        isSignupScreen = !isSignupScreen;
                      });
                    },
                    child: Text(
                      isSignupScreen
                          ? "Already have account? Login"
                          : "Create new account",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 INPUT FIELD
  Widget buildMagicField(IconData icon, String hint,
      TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ---------------- LOGIC ----------------

  void loginAction(BuildContext context) {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      showErrorDialog(context, 'Please fill all fields.');
    } else {
      authService.signInUser(
        context: context,
        email: emailController.text,
        password: passwordController.text,
      );
    }
  }

  void signupAction(BuildContext context) {
    if (userNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      showErrorDialog(context, 'Please fill all fields.');
    } else {
      authService.signUpUser(
        context: context,
        email: emailController.text,
        name: userNameController.text,
        password: passwordController.text,
        gender: isMale ? 'male' : 'female',
      );
    }
  }
}