import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';

// ═══════════════════════════════════════════════════════════════════
//  MAGIC HEADER – Exact copy of homepage header (with castle bg & fairy)
// ═══════════════════════════════════════════════════════════════════
class MagicHeader extends StatelessWidget {
  final Animation<double>? waveAnimation;
  final Animation<double>? floatAnimation;
  final Animation<double>? pulseAnimation;
  final Animation<double>? sparkleAnimation1;
  final Animation<double>? sparkleAnimation2;
  final Animation<double>? glowAnimation;
  final Animation<double>? shimmerAnimation;
  final String? selectedCharacterName;
  final bool hasSelectedCharacter;
  final double height;
  final VoidCallback? onCreateMagicStory;

  const MagicHeader({
    Key? key,
    this.waveAnimation,
    this.floatAnimation,
    this.pulseAnimation,
    this.sparkleAnimation1,
    this.sparkleAnimation2,
    this.glowAnimation,
    this.shimmerAnimation,
    this.selectedCharacterName,
    this.hasSelectedCharacter = false,
    this.height = 170,
    this.onCreateMagicStory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        children: [
          // ✅ BACKGROUND (Castle image - same as homepage)
          Positioned.fill(
            child: Image.asset(
              "assets/images/castle_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          // 🧚 FAIRY (same as homepage)
          Positioned(
            right: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: floatAnimation ?? const AlwaysStoppedAnimation(0.0),
              builder: (_, __) => Transform.translate(
                offset: Offset(
                  (floatAnimation?.value ?? 0) * 0.3,
                  (floatAnimation?.value ?? 0) * 0.5,
                ),
                child: Image.asset(
                  "assets/images/fairy.png",
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // 🔥 USER (TOP RIGHT - same as homepage)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person,
                        size: 14, color: Color(0xFF8F5CFF)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.name.split(" ")[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔥 LOGO + TITLE (LEFT SIDE - same as homepage)
          Positioned(
            top: 16,
            left: 16,
            right: 100,
            child: AnimatedBuilder(
              animation: floatAnimation ?? const AlwaysStoppedAnimation(0.0),
              builder: (_, __) => Transform.translate(
                offset: Offset(0, (floatAnimation?.value ?? 0) * 0.7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: sparkleAnimation1 ??
                          const AlwaysStoppedAnimation(0.0),
                      builder: (_, __) => Transform.scale(
                        scale: 0.88 + (sparkleAnimation1?.value ?? 0) * 0.22,
                        child: Image.asset(
                          "assets/images/logo.png",
                          height: 50,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "MAGIC STORY",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Adventure Awaits! ✨",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🔥 CREATE MAGIC STORY BUTTON (BOTTOM - same position as hint)
          Positioned(
            bottom: 12,
            left: 16,
            right: 16,
            child: Center(
              child: AnimatedBuilder(
                animation: shimmerAnimation ?? const AlwaysStoppedAnimation(0.0),
                builder: (_, __) => GestureDetector(
                  onTap: onCreateMagicStory,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade600,
                          Colors.pink.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: sparkleAnimation1 ??
                              const AlwaysStoppedAnimation(0.0),
                          builder: (_, __) => Transform.rotate(
                            angle: (sparkleAnimation1?.value ?? 0) * 3.14159 * 2,
                            child: const Text("✨", style: TextStyle(fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'CREATE MAGIC STORY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}