import 'dart:math' as math;

/// Pure Dart sound engine using SystemSound + haptic feedback
/// No external packages — generates audio tones via platform channels
/// For real device sound, uses Flutter's built-in SystemSound
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _muted = false;
  bool get isMuted => _muted;

  void toggleMute() => _muted = !_muted;

  Future<void> playPop() async {
    if (_muted) return;
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.lightImpact();
  }

  Future<void> playSuccess() async {
    if (_muted) return;
    await HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.click);
    await Future.delayed(const Duration(milliseconds: 80));
    await SystemSound.play(SystemSoundType.click);
    await Future.delayed(const Duration(milliseconds: 80));
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playError() async {
    if (_muted) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> playWin() async {
    if (_muted) return;
    for (int i = 0; i < 5; i++) {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  Future<void> playFlip() async {
    if (_muted) return;
    await HapticFeedback.selectionClick();
  }

  Future<void> playTick() async {
    if (_muted) return;
    await SystemSound.play(SystemSoundType.click);
  }
}
