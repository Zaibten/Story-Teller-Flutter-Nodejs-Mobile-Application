// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:pictureai/constants/global_variables.dart';
import '../features/game/games_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/test.dart';
import '../features/setting/setting.dart';

// 👉 Create a dummy Games screen (replace later)
// class GamesScreen extends StatelessWidget {
//   const GamesScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const Center(
//       child: Text(
//         "Games Screen 🎮",
//         style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }

class BottomBar extends StatefulWidget {
  static const String routeName = 'actual-home';
  const BottomBar({Key? key}) : super(key: key);

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar>
    with SingleTickerProviderStateMixin {
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

      // 🔥 Attractive Bottom Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: GlobalVariables.backgroundColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(0.15),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: GNav(
              selectedIndex: page,
              onTabChange: (index) {
                setState(() {
                  page = index;
                });
              },

              // 🔥 Design Improvements
              rippleColor: Colors.grey.shade300,
              hoverColor: Colors.grey.shade200,
              haptic: true,
              tabBorderRadius: 20,
              curve: Curves.easeOutExpo,
              duration: const Duration(milliseconds: 500),
              gap: 10,
              iconSize: 26,

              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),

              color: Colors.grey[600],
              activeColor: Colors.white,

              tabBackgroundColor: const Color(0xff6C63FF), // 💜 Premium color

              tabs: [
                GButton(
                  icon: Icons.home_rounded,
                  text: 'Home',
                ),
                GButton(
                  icon: Icons.auto_stories_rounded,
                  text: 'Story',
                ),
                GButton(
                  icon: Icons.sports_esports_rounded,
                  text: 'Games',
                ),
                GButton(
                  icon: Icons.settings_rounded,
                  text: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}