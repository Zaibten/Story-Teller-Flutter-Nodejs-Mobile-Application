// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors, camel_case_types

import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:pictureai/constants/global_variables.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/bottombar.dart';
import '../../../providers/user_provider.dart';
import '../../auth/screens/auth_screen.dart';

class SplashScreen extends StatelessWidget {
  final bool isLoggedIn = true; // Replace with your login check logic

  const SplashScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: GlobalVariables.Companyname,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AnimatedSplashScreen(
        splash: Image.asset(
          'assets/images/logonew.png',
          fit: BoxFit.cover, // This makes the image cover the entire screen
          width: double.infinity,
          height: double.infinity,
        ),
        splashIconSize: double.infinity, // Make splash take full screen
        duration: 3000, // Fixed the extremely long duration
        splashTransition: SplashTransition.scaleTransition,
        backgroundColor: Colors.white,
        nextScreen: AuthScreen(),
        // Remove the Center widget wrapper
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}