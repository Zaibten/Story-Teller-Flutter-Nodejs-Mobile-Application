// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import '../features/game/games_screen.dart';
import '../features/home/savestory.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/test.dart';
import '../features/setting/setting.dart';

class BottomBar extends StatefulWidget {
  static const String routeName = 'actual-home';
  const BottomBar({Key? key}) : super(key: key);

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int page = 0;

  final List<Widget> pages = [
    const HomeScreen(),
    const NewPage(),
    const GamesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: pages[page],
      ),

      // 🔥 CUSTOM EXACT UI BOTTOM BAR
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE9E4FF),
                  Color(0xFFD6CCFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildTab(Icons.home_rounded, "Home", 0),
                buildTab(Icons.menu_book_rounded, "Library", 1),
                buildTab(Icons.sports_esports_rounded, "Games", 2),
                buildTab(Icons.settings_rounded, "Settings", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 TAB BUILDER (Exact UI behavior)
Widget buildTab(IconData icon, String label, int index) {
  bool isActive = page == index;

  return GestureDetector(
    onTap: () {
      setState(() {
        page = index;
      });
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [
                  Color(0xFF7B61FF),
                  Color(0xFF5A4DFF),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(30),
        border: isActive
            ? Border.all(color: Colors.white, width: 2)
            : null,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF7B61FF).withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ]
            : [],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : Colors.deepPurple,
                size: 24,
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),

          // ⭐ STAR FLOATING TOP EFFECT
        //   if (isActive)
        //     Positioned(
        //       top: -14,
        //       left: -13,
        //       right: 170,
        //       child: TweenAnimationBuilder<double>(
        //         duration: const Duration(milliseconds: 600),
        //         tween: Tween(begin: 0.5, end: 1),
        //         curve: Curves.elasticOut,
        //         builder: (context, value, child) {
        //           return Transform.scale(
        //             scale: value,
        //             child: const Text(
        //               "⭐",
        //               textAlign: TextAlign.center,
        //               style: TextStyle(fontSize: 16),
        //             ),
        //           );
        //         },
        //       ),
        //     ),
        ],
      ),
    ),
  );
}





}