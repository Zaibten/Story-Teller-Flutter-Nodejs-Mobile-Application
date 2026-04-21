import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _bgPlayer = AudioPlayer();
  bool _isMuted = false;
  bool _isInitialized = false;
  bool _isMusicPaused = false;
  
  bool get isMuted => _isMuted;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      await _bgPlayer.setVolume(0.5);
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _playBackgroundMusic();
      _isInitialized = true;
      print('AudioService initialized successfully');
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  Future<void> _playBackgroundMusic() async {
    if (!_isMuted && _isInitialized && !_isMusicPaused) {
      try {
        await _bgPlayer.play(AssetSource('sounds/bg.mp3'));
        print('Background music started');
      } catch (e) {
        print('Error playing background music: $e');
      }
    }
  }

  Future<void> pauseMusic() async {
    try {
      await _bgPlayer.pause();
      _isMusicPaused = true;
      print('Music paused');
    } catch (e) {
      print('Error pausing music: $e');
    }
  }

  Future<void> resumeMusic() async {
    if (!_isMuted && _isInitialized) {
      try {
        await _bgPlayer.resume();
        _isMusicPaused = false;
        print('Music resumed');
      } catch (e) {
        print('Error resuming music: $e');
        // If resume fails, try playing again
        await _playBackgroundMusic();
      }
    }
  }

  Future<void> stopMusic() async {
    try {
      await _bgPlayer.stop();
      _isMusicPaused = true;
      print('Music stopped');
    } catch (e) {
      print('Error stopping music: $e');
    }
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    print('Mute toggled: $_isMuted');
    if (_isMuted) {
      await _bgPlayer.pause();
      _isMusicPaused = true;
    } else {
      _isMusicPaused = false;
      await _playBackgroundMusic();
    }
  }

  Future<void> playPop() async {
    if (!_isMuted && _isInitialized) {
      // Add sound effects if available
    }
  }

  Future<void> playCorrect() async {
    if (!_isMuted && _isInitialized) {
      // Add sound effects if available
    }
  }

  Future<void> playWrong() async {
    if (!_isMuted && _isInitialized) {
      // Add sound effects if available
    }
  }

  Future<void> playWin() async {
    if (!_isMuted && _isInitialized) {
      // Add sound effects if available
    }
  }

  Future<void> playLevelUp() async {
    if (!_isMuted && _isInitialized) {
      // Add sound effects if available
    }
  }

  Future<void> dispose() async {
    try {
      await _bgPlayer.dispose();
    } catch (e) {
      print('Error disposing audio: $e');
    }
  }
}