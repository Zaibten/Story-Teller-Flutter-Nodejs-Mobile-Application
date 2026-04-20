import 'package:flutter/material.dart';

enum GameId { numberPop, colorMatch, memoryFlip }

enum GameDifficulty { easy, medium, hard }

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

class GameScore {
  final GameId gameId;
  final int score;
  final int stars; // 1-3
  final DateTime playedAt;
  final GameDifficulty difficulty;

  const GameScore({
    required this.gameId,
    required this.score,
    required this.stars,
    required this.playedAt,
    required this.difficulty,
  });
}

const List<GameModel> kGames = [
  GameModel(
    id: GameId.numberPop,
    title: 'Number Pop!',
    description: 'Pop the balloons in the right number order!',
    emoji: '🎈',
    primaryColor: Color(0xFFFF6B6B),
    secondaryColor: Color(0xFFFFE66D),
    minAge: 3,
    maxAge: 7,
  ),
  GameModel(
    id: GameId.colorMatch,
    title: 'Color Match',
    description: 'Match the falling drops to the right color bucket!',
    emoji: '🎨',
    primaryColor: Color(0xFF4ECDC4),
    secondaryColor: Color(0xFF44CF6C),
    minAge: 4,
    maxAge: 8,
  ),
  GameModel(
    id: GameId.memoryFlip,
    title: 'Memory Flip',
    description: 'Flip the cards and find all the matching pairs!',
    emoji: '🃏',
    primaryColor: Color(0xFF7C6FFF),
    secondaryColor: Color(0xFFC77DFF),
    minAge: 4,
    maxAge: 10,
  ),
];
