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
  bool _isPasswordVisible = false;

  late AnimationController _cloudController;
  late AnimationController _fairyController;
  late AnimationController _buttonController;
  late AnimationController _eyeBounceController;

  @override
  void initState() {
    super.initState();

    _cloudController =
        AnimationController(vsync: this, duration: Duration(seconds: 30))
          ..repeat();

    _fairyController =
        AnimationController(vsync: this, duration: Duration(seconds: 3))
          ..repeat(reverse: true);

    _buttonController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 900))
          ..repeat(reverse: true);

    _eyeBounceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _fairyController.dispose();
    _buttonController.dispose();
    _eyeBounceController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
    _eyeBounceController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final random = Random();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 🌈 BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF89CFF0),
                  Color(0xFFE0BBE4),
                  Color(0xFFFFDFD3),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ☁️ CLOUDS
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _cloudController,
              builder: (context, child) {
                return Positioned(
                  left: (_cloudController.value * 300) - (index * 150),
                  top: 50.0 + index * 80,
                  child: Image.asset(
                    "assets/images/clouds.png",
                    height: 100 + index * 20,
                  ),
                );
              },
            );
          }),

          // ✨ STARS
          ...List.generate(40, (index) {
            double top = random.nextDouble() * 600;
            double left = random.nextDouble() * 300;

            return Positioned(
              top: top,
              left: left,
              child: Icon(
                Icons.star,
                size: 6 + random.nextDouble() * 6,
                color: Colors.white.withOpacity(0.8),
              ),
            );
          }),

          // 🧚 FAIRY
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

          // 🌟 TITLE
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                const SizedBox(height: 90),
                const Text(
                  "✨ Magic Story ✨",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                          blurRadius: 15,
                          color: Colors.purple,
                          offset: Offset(0, 4))
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Welcome to Magic Story 🧚",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // 📦 FORM
          Positioned(
            top: 220,
            left: 25,
            right: 25,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSignupScreen)
                    buildMagicField(Icons.person, "Username",
                        userNameController),

                  if (isSignupScreen) const SizedBox(height: 12),

                  buildMagicField(Icons.email, "Email", emailController),

                  const SizedBox(height: 12),

                  buildPasswordField(),

                  const SizedBox(height: 20),

                  AnimatedBuilder(
                    animation: _buttonController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1 + (_buttonController.value * 0.1),
                        child: GestureDetector(
                          onTap: () {
                            isSignupScreen
                                ? signupAction(context)
                                : loginAction(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 50),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.pink,
                                  Colors.orange,
                                  Colors.purple
                                ],
                              ),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.6),
                                  blurRadius: 25,
                                )
                              ],
                            ),
                            child: Text(
                              isSignupScreen
                                  ? "Start Magic ✨"
                                  : "Login ✨",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

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
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),

          // 🦆 DUCK GIF
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/images/duck.gif",
              height: 180,
              fit: BoxFit.contain,
            ),
          ),

          // 🎬 BOTTOM GIF
          Positioned(
            bottom: -50,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/images/below.gif",
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMagicField(IconData icon, String hint,
      TextEditingController controller,
      {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.purple),
          hintText: hint,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  Widget buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          TextField(
            controller: passwordController,
            obscureText: !_isPasswordVisible,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock, color: Colors.purple),
              hintText: "Password",
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
          ),
          Positioned(
            right: 16,
            child: GestureDetector(
              onTap: _togglePasswordVisibility,
              child: AnimatedBuilder(
                animation: _eyeBounceController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + (_eyeBounceController.value * 0.15),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.purple.withOpacity(0.1),
                      ),
                      child: _isPasswordVisible
                          ? const Icon(
                              Icons.visibility_rounded,
                              color: Colors.purple,
                              size: 24,
                            )
                          : const Icon(
                              Icons.visibility_off_rounded,
                              color: Colors.grey,
                              size: 24,
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

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
        gender: 'male',
      );
    }
  }
}