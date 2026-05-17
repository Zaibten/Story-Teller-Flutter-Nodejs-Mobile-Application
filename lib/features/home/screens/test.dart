import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../common/widgets/header.dart';
import '../../../providers/user_provider.dart';
// ═══════════════════════════════════════════════════════════════════
//  PREMIUM KIDS MAGICAL DESIGN SYSTEM
//  Professional, playful, and child-optimized
// ═══════════════════════════════════════════════════════════════════
class K {
  K._();
  
  // Core colors - vibrant and child-friendly
  static const bg = Color(0xFFFEF5E7);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2D1B4E);
  static const red = Color(0xFFFF6B6B);
  static const orange = Color(0xFFFFA559);
  static const yellow = Color(0xFFFFE66D);
  static const lime = Color(0xFF5D9B4B);
  static const cyan = Color(0xFF4ECDC4);
  static const blue = Color(0xFF45B7D1);
  static const purple = Color(0xFF9B59B6);
  static const pink = Color(0xFFFF6B8D);
  static const mint = Color(0xFF2DCD9F);
  static const white = Color(0xFFFFFFFF);
  static const gold = Color(0xFFFFD700);
  static const silver = Color(0xFFC0C0C0);

  // Magical gradients for special moments
  static const rainbowGradient = LinearGradient(
    colors: [red, orange, yellow, lime, cyan, blue, purple],
    stops: [0, 0.16, 0.33, 0.5, 0.66, 0.83, 1],
  );
  
  static const sunsetGradient = LinearGradient(
    colors: [purple, pink, orange, yellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const oceanGradient = LinearGradient(
    colors: [cyan, blue, purple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const rainbow = [red, orange, yellow, lime, cyan, blue, purple, pink];
  static const pastel = [Color(0xFFFFF0F0), Color(0xFFFFF4E6), Color(0xFFFFFFE0), Color(0xFFE8F5E9), Color(0xFFE3F2FD)];
  static const rainbowLabels = ['⭐ EXTRAORDINARY!', '💫 MAGICAL!', '🌟 SPECTACULAR!', '🔥 AMAZING!', '✨ WONDERFUL!', '💎 MARVELOUS!'];

  static Color panelAccent(int i) => rainbow[i % rainbow.length];
}

// Typography optimized for children - slightly larger, highly readable
TextStyle ts(double sz, Color c, {FontWeight fw = FontWeight.w800, double h = 1.4, List<Shadow>? sh}) =>
    TextStyle(fontFamily: 'Poppins', fontSize: sz, color: c, fontWeight: fw, height: h, shadows: sh, letterSpacing: -0.3);

TextStyle tb(double sz, Color c, {FontWeight fw = FontWeight.w600, double h = 1.5}) =>
    TextStyle(fontFamily: 'Poppins', fontSize: sz, color: c, fontWeight: fw, height: h, letterSpacing: -0.2);

// ═══════════════════════════════════════════════════════════════════
//  MAGICAL BACKGROUND - Floating Stars & Sparkles Animation
// ═══════════════════════════════════════════════════════════════════
class _MagicSparkle {
  double x, y, size, speed, angle, rotationSpeed;
  Color color;
  int type;
  _MagicSparkle(Random rng, double w, double h)
      : x = rng.nextDouble() * w,
        y = rng.nextDouble() * h,
        size = rng.nextDouble() * 12 + 4,
        speed = rng.nextDouble() * 0.8 + 0.3,
        angle = rng.nextDouble() * pi * 2,
        rotationSpeed = (rng.nextDouble() - 0.5) * 0.05,
        color = K.rainbow[rng.nextInt(K.rainbow.length)].withOpacity(0.45),
        type = rng.nextInt(3);
}

class _MagicSparklePainter extends CustomPainter {
  final List<_MagicSparkle> particles;
  final double time;
  _MagicSparklePainter(this.particles, this.time);

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final outerRadius = radius;
    final innerRadius = radius * 0.4;
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * pi / 180;
      final outerX = center.dx + cos(angle) * outerRadius;
      final outerY = center.dy + sin(angle) * outerRadius;
      final innerAngle = angle + 36 * pi / 180;
      final innerX = center.dx + cos(innerAngle) * innerRadius;
      final innerY = center.dy + sin(innerAngle) * innerRadius;
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDiamond(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final alpha = (sin(time * p.speed + p.x * 0.5) * 0.4 + 0.5).clamp(0.3, 0.85);
      final paint = Paint()..color = p.color.withOpacity(alpha);
      final x = p.x + cos(time * 0.3 + p.angle) * 4;
      final y = p.y + sin(time * 0.5 + p.angle) * 4;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(time * p.rotationSpeed);
      
      if (p.type == 0) {
        _drawStar(canvas, Offset.zero, p.size * 0.6, paint);
      } else if (p.type == 1) {
        canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
      } else {
        _drawDiamond(canvas, Offset.zero, p.size * 0.4, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_MagicSparklePainter old) => old.time != time;
}

// ═══════════════════════════════════════════════════════════════════
//  RAINBOW GRADIENT PROGRESS BAR - For generation feedback
// ═══════════════════════════════════════════════════════════════════
class _RainbowProgressBar extends StatelessWidget {
  final double value;
  final String label;
  const _RainbowProgressBar(this.value, {this.label = ''});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: ts(13, K.purple, fw: FontWeight.w600)),
          const SizedBox(height: 8),
        ],
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: K.ink, width: 3),
            boxShadow: const [BoxShadow(color: K.ink, offset: Offset(3, 3), blurRadius: 0)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              children: [
                Container(color: Colors.grey.shade100),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0, 1),
                  child: Container(decoration: const BoxDecoration(gradient: K.rainbowGradient)),
                ),
                Center(
                  child: Text(
                    '${(value * 100).toInt()}%',
                    style: ts(14, value > 0.5 ? K.white : K.ink, fw: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PREMIUM PULSING BUTTON - Attracts children's attention
// ═══════════════════════════════════════════════════════════════════
class _PremiumPulseButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isActive;
  final Color? pulseColor;
  const _PremiumPulseButton({required this.child, this.onTap, this.isActive = true, this.pulseColor});

  @override
  State<_PremiumPulseButton> createState() => _PremiumPulseButtonState();
}

class _PremiumPulseButtonState extends State<_PremiumPulseButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          if (!widget.isActive) return child!;
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: (widget.pulseColor ?? K.purple).withOpacity(0.35 * _glow.value),
                  blurRadius: 18 * _glow.value,
                  spreadRadius: 2 * _glow.value,
                ),
              ],
            ),
            child: Transform.scale(scale: _scale.value, child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FLOATING CHARACTER ANIMATION - Adds whimsy and delight
// ═══════════════════════════════════════════════════════════════════
class _FloatingCharacter extends StatefulWidget {
  final String emoji;
  final double duration;
  const _FloatingCharacter(this.emoji, {this.duration = 3.0});

  @override
  State<_FloatingCharacter> createState() => _FloatingCharacterState();
}

class _FloatingCharacterState extends State<_FloatingCharacter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _float;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: widget.duration.toInt()))..repeat(reverse: true);
    _float = Tween<double>(begin: -10, end: 10).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _rotate = Tween<double>(begin: -0.1, end: 0.1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _float.value),
        child: Transform.rotate(angle: _rotate.value, child: Text(widget.emoji, style: const TextStyle(fontSize: 28))),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MAIN PAGE - Professionally Enhanced for Children
// ═══════════════════════════════════════════════════════════════════
class NewPage extends StatefulWidget {
  static const routeName = '/new-page';
  final String userName;
  const NewPage({Key? key, this.userName = 'Super Reader'}) : super(key: key);
  
  @override
  State<NewPage> createState() => _NewPageState();
}

class _NewPageState extends State<NewPage> with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _tts = FlutterTts();
  final _rng = Random();
  bool _isSaving = false;
bool _isDownloading = false;
  static const _base = 'http://10.255.212.221:9000';

  String _selectedLanguage = 'english';
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  // Professional Animation Controllers for rich animations
  late AnimationController _waveController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late AnimationController _glowController;
  late AnimationController _shimmerController;
  late AnimationController _bounceController;
  late AnimationController _rotateController;
  late AnimationController _slideController;
  
  late Animation<double> _waveAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _slideAnimation;

  // Background magic sparkles
  List<_MagicSparkle> _magicSparkles = [];
  double _sparkleTime = 0;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitialized = false;
  bool _videoError = false;

  String _story = '';
  List _panels = [];
  double _pct = 0;
  bool _loading = false;
  String _genTime = '';
  bool _showComic = false;
  String _videoState = 'idle';
  String? _videoUrl;

  bool _reading = false, _paused = false;
  int _cw = -1;
  List<String> _words = [];
  List<int> _starts = [];
  bool _urduReading = false;
  bool _comicReading = false;
  int _comicPanel = 0;

  List<int> _seeds = [];
  List<AnimationController> _panelACs = [];
  List<Animation<double>> _panelSc = [], _panelOp = [];

  late PageController _pageCtrl;
  bool _showVideoOverlay = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupTts();
    _initSpeech();
    _pageCtrl = PageController();
    
    _bounceController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));
    
    _rotateController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));
    
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initBackgroundSparkles();
  }

  void _initAnimations() {
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _waveAnimation = CurvedAnimation(parent: _waveController, curve: Curves.easeInOut);

    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6, end: 6).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulseAnimation = _pulseController;

    _sparkleController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _sparkleAnimation = _sparkleController;

    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 2.5).animate(CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut));
  }

  void _initBackgroundSparkles() {
    final size = MediaQuery.of(context).size;
    _magicSparkles = List.generate(50, (_) => _MagicSparkle(_rng, size.width, size.height));
    _sparkleTime = 0;
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() => _sparkleTime += 0.03);
        return true;
      }
      return false;
    });
  }

  Future<void> _saveStoryToDatabase() async {
  final user = Provider.of<UserProvider>(context, listen: false).user;
  
  if (user.id == null) {
    _showSnackbar('Please login to save stories', K.red);
    return;
  }
  
  setState(() => _isSaving = true);
  
  try {
    final response = await http.post(
      Uri.parse('$_base/api/save-story'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': user.id,
        'title': _story.substring(0, _story.length > 50 ? 50 : _story.length),
        'storyText': _story,
        'videoUrl': _videoUrl ?? '',
        'character': '',
        'world': '',
        'mood': '',
        'panels': _panels,
        'language': _selectedLanguage
      }),
    );
    
    final data = json.decode(response.body);
    if (data['success'] == true) {
      _showSnackbar('📚 Story saved to library!', K.mint);
    } else {
      _showSnackbar('Failed to save: ${data['error']}', K.red);
    }
  } catch (e) {
    _showSnackbar('Failed to save: $e', K.red);
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}

Future<void> _downloadVideoToDevice() async {
  if (_videoUrl == null || _videoUrl!.isEmpty) {
    _showSnackbar('No video available to share', K.orange);
    return;
  }

  setState(() => _isDownloading = true);

  try {
    final Dio dio = Dio();
    final dir = await getTemporaryDirectory();
    final filename = 'story_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final filePath = '${dir.path}/$filename';

    _showSnackbar('🔄 Preparing video...', K.blue);

    await dio.download(_videoUrl!, filePath, onReceiveProgress: (received, total) {
      if (total > 0) {
        final progress = (received / total * 100).toInt();
        if (mounted && progress % 25 == 0) {
          _showSnackbar('Downloading: $progress%', K.blue);
        }
      }
    });

    if (mounted) {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: '🌟 Check out my magical story! ✨ #MagicStory',
      );
    }
  } catch (e) {
    if (mounted) {
      _showSnackbar('Share failed: $e', K.red);
    }
  } finally {
    if (mounted) setState(() => _isDownloading = false);
  }
}

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) => setState(() => _isListening = (status == 'listening')),
        onError: (_) => setState(() => _isListening = false),
      );
    } catch (_) {
      _speechAvailable = false;
    }
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    if (!_speechAvailable) {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) => setState(() => _isListening = (status == 'listening')),
        onError: (_) => setState(() => _isListening = false),
      );
    }
    if (!_speechAvailable) {
      _showSnackbar('🎙️ Microphone permission needed!', K.red);
      return;
    }
    setState(() => _isListening = true);
    final started = await _speech.listen(
      onResult: (result) => setState(() {
        _ctrl.text = result.recognizedWords;
        _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
      }),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    );
    if (!started && mounted) {
      setState(() => _isListening = false);
      _showSnackbar('🎙️ Could not start listening', K.orange);
    }
  }

  void _disposeVideo() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
    _videoInitialized = false;
    _videoError = false;
  }

  Future<void> _initVideoPlayer(String url) async {
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoController = ctrl;
      await ctrl.initialize();
      final ar = ctrl.value.aspectRatio > 0 ? ctrl.value.aspectRatio : 16 / 9;
      _chewieController = ChewieController(
        videoPlayerController: ctrl,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        aspectRatio: ar,
        materialProgressColors: ChewieProgressColors(
          playedColor: K.yellow,
          handleColor: K.orange,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white.withOpacity(0.35),
        ),
        placeholder: Container(
          color: const Color(0xFF2D1B4E),
          child: const Center(child: CircularProgressIndicator(color: K.yellow, strokeWidth: 4)),
        ),
      );
      setState(() {
        _videoInitialized = true;
        _videoError = false;
      });
    } catch (_) {
      setState(() {
        _videoError = true;
        _videoInitialized = false;
      });
    }
  }

  void _setupTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.15);
  }

  void _prepareWords() {
    _words = _story.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    _starts = [];
    int pos = 0;
    for (int i = 0; i < _words.length; i++) {
      _starts.add(pos);
      pos += _words[i].length + (i < _words.length - 1 ? 1 : 0);
    }
  }

  void _startReading() async {
    if (_story.isEmpty || (_reading && !_paused)) return;
    if (_words.isEmpty) _prepareWords();
    if (_cw < 0 || !_paused) _cw = 0;
    setState(() {
      _reading = true;
      _paused = false;
      _urduReading = false;
    });
    await _tts.setLanguage('en-US');
    _tts.setProgressHandler((_, start, __, ___) {
      if (!_reading || _paused) return;
      final idx = _findWordAt(start);
      if (idx != -1 && idx != _cw) setState(() => _cw = idx);
    });
    _tts.setCompletionHandler(() {
      if (!_paused) _stopReading(reset: true);
    });
    await _tts.speak(_story.substring(_starts[_cw]));
  }

  Future<void> _startUrduReading() async {
    if (_story.isEmpty) return;
    if (_urduReading) {
      await _tts.stop();
      setState(() => _urduReading = false);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.15);
      return;
    }
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 150));
    _stopReading(reset: true);
    final langs = await _tts.getLanguages;
    final available = (langs as List).map((e) => e.toString().toLowerCase()).toList();
    if (!available.any((l) => l.contains('ur'))) {
      _showSnackbar('🇵🇰 Urdu TTS not installed', K.orange);
      return;
    }
    await _tts.setLanguage('ur-PK');
    await _tts.setSpeechRate(0.38);
    await _tts.setPitch(1.08);
    await Future.delayed(const Duration(milliseconds: 250));
    setState(() => _urduReading = true);
    _tts.setCompletionHandler(() async {
      setState(() => _urduReading = false);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.15);
    });
    await _tts.speak(_story);
  }

  int _findWordAt(int pos) {
    for (int i = 0; i < _starts.length; i++) {
      final end = i < _starts.length - 1 ? _starts[i + 1] - 1 : _story.length;
      if (pos >= _starts[i] && pos <= end) return i;
    }
    return -1;
  }

  void _pauseReading() {
    if (!_reading || _paused) return;
    _tts.stop();
    setState(() {
      _paused = true;
      _reading = false;
    });
  }

  void _stopReading({bool reset = false}) {
    _tts.stop();
    setState(() {
      _reading = false;
      _paused = false;
      _urduReading = false;
      if (reset) {
        _cw = -1;
        _words = [];
        _starts = [];
      }
    });
  }

  void _startComicReading() async {
    if (_panels.isEmpty) return;
    setState(() {
      _comicReading = true;
      _comicPanel = 0;
    });
    if (_pageCtrl.hasClients) {
      await _pageCtrl.animateToPage(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
    _readComicPanel(0);
  }

  void _readComicPanel(int idx) async {
    if (!_comicReading || idx >= _panels.length) {
      _stopComicReading();
      return;
    }
    setState(() => _comicPanel = idx);
    if (_pageCtrl.hasClients) {
      await _pageCtrl.animateToPage(idx, duration: const Duration(milliseconds: 650), curve: Curves.easeInOutCubic);
    }
    final panel = _panels[idx];
    final text = '${panel['title'] ?? ''}. ${panel['description'] ?? ''}';
    _tts.setCompletionHandler(() {
      if (_comicReading) _readComicPanel(idx + 1);
    });
    await _tts.speak(text);
  }

  void _stopComicReading() {
    _tts.stop();
    setState(() => _comicReading = false);
  }

  void _celebrateWithConfetti() {
    _showCelebration();
  }

  void _showCelebration() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _CelebrationOverlay(),
    );
  }

  void _setupPanelAnimations(int n) {
    for (final c in _panelACs) c.dispose();
    _panelACs = List.generate(n, (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 500)));
    _panelSc = _panelACs.map((c) => Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.elasticOut))).toList();
    _panelOp = _panelACs.map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeIn))).toList();
  }

  void _animatePanels() async {
    for (int i = 0; i < _panelACs.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 100));
      if (mounted) _panelACs[i].forward();
    }
  }

  void _toggleComic() {
    setState(() => _showComic = !_showComic);
    if (_showComic) {
      _animatePanels();
      _slideController.forward();
    } else {
      _stopComicReading();
    }
  }

  Future<void> _generateStory() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty) {
      _showSnackbar('✏️ Type a magical story idea first!', K.orange);
      return;
    }
    _stopReading(reset: true);
    _stopComicReading();
    _disposeVideo();
    setState(() {
      _loading = true;
      _story = '';
      _panels = [];
      _pct = 0;
      _genTime = '';
      _showComic = false;
      _seeds = [];
      _videoState = 'generating';
      _videoUrl = null;
      _showVideoOverlay = false;
    });

    try {
      final url = '$_base/generate-story-comic-stream?prompt=${Uri.encodeComponent(prompt)}&language=$_selectedLanguage';
      final req = http.Request('GET', Uri.parse(url));
      final res = await req.send();
      res.stream.transform(utf8.decoder).listen((chunk) {
        for (final line in chunk.split('\n')) {
          if (!line.startsWith('data:')) continue;
          final js = line.replaceFirst('data:', '').trim();
          if (js.isEmpty) continue;
          try {
            final data = jsonDecode(js);
            setState(() {
              _pct = (data['progress'] ?? _pct).toDouble();
              if (data['story'] != null) {
                _story = data['story'];
                _words = [];
                _starts = [];
                _cw = -1;
              }
              if (data['panels'] != null) {
                _panels = List.from(data['panels']);
                _seeds = List.generate(_panels.length, (i) => i * 137 + 91);
                _setupPanelAnimations(_panels.length);
              }
              if (data['panelIndex'] != null && data['image'] != null) {
                final idx = data['panelIndex'] as int;
                if (idx < _panels.length) {
                  _panels[idx] = Map<String, dynamic>.from(_panels[idx])..['image'] = data['image'];
                  precacheImage(CachedNetworkImageProvider(data['image'] as String), context);
                }
              }
              if (data['step'] == 'done') {
                _loading = false;
                _genTime = data['generationTime'] ?? '';
                final vUrl = data['videoUrl'];
                if (vUrl != null && (vUrl as String).isNotEmpty) {
                  _videoUrl = vUrl;
                  _videoState = 'ready';
                  _initVideoPlayer(vUrl);
                } else {
                  _videoState = 'idle';
                }
                _celebrateWithConfetti();
              }
            });
          } catch (_) {}
        }
      }, onError: (_) {
        setState(() {
          _loading = false;
          _videoState = 'error';
        });
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _videoState = 'idle';
      });
      _showSnackbar('❌ Oops! Something went wrong.', K.red);
    }
  }

  void _showSnackbar(String msg, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.star, color: K.yellow, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: ts(14, K.white))),
        ],
      ),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: K.bg,
      body: Stack(
        children: [
          // Premium Animated Background
          if (_magicSparkles.isNotEmpty)
            AnimatedBuilder(
              animation: _sparkleController,
              builder: (_, __) => CustomPaint(
                painter: _MagicSparklePainter(_magicSparkles, _sparkleTime),
                size: MediaQuery.of(context).size,
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                // Premium Header
                MagicHeader(
                  waveAnimation: _waveAnimation,
                  floatAnimation: _floatAnimation,
                  pulseAnimation: _pulseAnimation,
                  sparkleAnimation1: _sparkleAnimation,
                  sparkleAnimation2: _sparkleAnimation,
                  glowAnimation: _glowAnimation,
                  shimmerAnimation: _shimmerAnimation,
                  selectedCharacterName: null,
                  hasSelectedCharacter: false,
                  height: 160,
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPremiumInputCard(),
                        const SizedBox(height: 18),
                        _buildProfessionalLanguageToggle(),
                        const SizedBox(height: 18),
                        _buildPremiumGenerateButton(),
                        const SizedBox(height: 18),
                        if (_loading) _buildPremiumProgressCard(),
                        if (_videoState == 'ready' && _videoUrl != null) ...[
                          const SizedBox(height: 18),
                          _buildPremiumVideoCard(),
                        ],
                        if (_story.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _buildPremiumStorySection(),
                        ],
                        if (_panels.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _buildProfessionalToggleButton(),
                          const SizedBox(height: 16),
                          _buildPremiumComicSection(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_showVideoOverlay && _videoUrl != null) _buildPremiumVideoOverlay(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PREMIUM INPUT CARD - Glassmorphism Style
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPremiumInputCard() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: _isListening 
              ? const LinearGradient(colors: [K.red, K.orange, K.yellow])
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [K.surface, K.surface.withOpacity(0.95)],
                ),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: _isListening ? K.white : K.purple, width: 3),
          boxShadow: [
            BoxShadow(
              color: (_isListening ? K.red : K.purple).withOpacity(0.3),
              blurRadius: _isListening ? 24 : 14,
              offset: Offset(0, _isListening ? 0 : 6),
              spreadRadius: _isListening ? 2 : 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            if (!_isListening)
              ClipRRect(
                borderRadius: BorderRadius.circular(37),
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    colors: [Colors.transparent, Colors.white, Colors.transparent],
                    stops: [0, 0.5, 1],
                  ).createShader(rect),
                  child: Container(color: Colors.white.withOpacity(0.1)),
                ),
              ),
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 18),
                  child: _FloatingCharacter('🌈', duration: 2.5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: tb(16, _isListening ? K.white : K.ink),
                    decoration: InputDecoration(
                      hintText: _isListening ? '🎙️ Listening to your magical idea...' : "✨ What's your story about? ✨",
                      hintStyle: tb(14, _isListening ? K.white.withOpacity(0.9) : Colors.grey.shade500),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                _PremiumPulseButton(
                  isActive: !_isListening,
                  onTap: _toggleListening,
                  pulseColor: K.purple,
                  child: Container(
                    margin: const EdgeInsets.only(right: 14),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: _isListening 
                          ? const LinearGradient(colors: [K.white, K.yellow])
                          : LinearGradient(colors: [K.purple.withOpacity(0.15), K.purple.withOpacity(0.05)]),
                      shape: BoxShape.circle,
                      border: Border.all(color: _isListening ? K.purple : K.purple, width: 2.5),
                      boxShadow: _isListening ? [BoxShadow(color: K.yellow.withOpacity(0.5), blurRadius: 14)] : [],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none_rounded,
                      color: _isListening ? K.purple : K.purple,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PROFESSIONAL LANGUAGE TOGGLE - Child-friendly interaction
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildProfessionalLanguageToggle() {
    final isEnglish = _selectedLanguage == 'english';
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: K.surface,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: K.ink, width: 3),
        boxShadow: const [BoxShadow(color: K.ink, offset: Offset(5, 5), blurRadius: 0)],
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _loading ? null : () => setState(() => _selectedLanguage = 'english'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(vertical: screenWidth < 380 ? 12 : 14),
                decoration: BoxDecoration(
                  gradient: isEnglish ? const LinearGradient(colors: [K.blue, K.cyan]) : null,
                  color: isEnglish ? null : Colors.white,
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: isEnglish ? K.white : K.purple.withOpacity(0.25), width: isEnglish ? 2.5 : 1.5),
                  boxShadow: isEnglish ? const [BoxShadow(color: K.ink, offset: Offset(3, 3), blurRadius: 0)] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (_, __) => Transform.scale(
                        scale: isEnglish ? _bounceAnimation.value : 1.0,
                        child: Text('🇺🇸', style: TextStyle(fontSize: screenWidth < 380 ? 22 : (isEnglish ? 28 : 24))),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'English',
                          style: ts(screenWidth < 380 ? 12 : 14, isEnglish ? K.white : K.ink.withOpacity(0.6),
                              fw: isEnglish ? FontWeight.w900 : FontWeight.w600),
                        ),
                      ),
                    ),
                    if (isEnglish) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth < 380 ? 5 : 8, vertical: screenWidth < 380 ? 3 : 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [K.yellow, K.orange]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FittedBox(
                          child: Text('ACTIVE', style: ts(screenWidth < 380 ? 8 : 10, K.ink, fw: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: _loading ? null : () => setState(() => _selectedLanguage = 'urdu'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(vertical: screenWidth < 380 ? 12 : 14),
                decoration: BoxDecoration(
                  gradient: !isEnglish ? const LinearGradient(colors: [K.purple, K.pink]) : null,
                  color: !isEnglish ? null : Colors.white,
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: !isEnglish ? K.white : K.purple.withOpacity(0.25), width: !isEnglish ? 2.5 : 1.5),
                  boxShadow: !isEnglish ? const [BoxShadow(color: K.ink, offset: Offset(3, 3), blurRadius: 0)] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (_, __) => Transform.scale(
                        scale: !isEnglish ? _bounceAnimation.value : 1.0,
                        child: Text('🇵🇰', style: TextStyle(fontSize: screenWidth < 380 ? 22 : (!isEnglish ? 28 : 24))),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'اردو',
                          style: ts(screenWidth < 380 ? 12 : 14, !isEnglish ? K.white : K.ink.withOpacity(0.6),
                              fw: !isEnglish ? FontWeight.w900 : FontWeight.w600),
                        ),
                      ),
                    ),
                    if (!isEnglish) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth < 380 ? 5 : 8, vertical: screenWidth < 380 ? 3 : 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [K.yellow, K.orange]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FittedBox(
                          child: Text('ACTIVE', style: ts(screenWidth < 380 ? 8 : 10, K.ink, fw: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PREMIUM GENERATE BUTTON - Eye-catching for children
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPremiumGenerateButton() {
    final screenWidth = MediaQuery.of(context).size.width;

    return _PremiumPulseButton(
      isActive: !_loading,
      onTap: _loading ? null : _generateStory,
      pulseColor: K.orange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: screenWidth < 360 ? 16 : 18, horizontal: 12),
        decoration: BoxDecoration(
          gradient: _loading ? const LinearGradient(colors: [Colors.grey, Colors.grey]) : K.rainbowGradient,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: K.ink, width: 4),
          boxShadow: _loading ? [] : const [BoxShadow(color: K.ink, offset: Offset(6, 6), blurRadius: 0)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (_, __) => Transform.rotate(
                angle: _rotateAnimation.value,
                child: Text('🚀', style: TextStyle(fontSize: screenWidth < 360 ? 26 : 32)),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _loading ? '✨ Creating MAGIC... ✨' : '⚡ CREATE MY COMIC! ⚡',
                  textAlign: TextAlign.center,
                  style: ts(screenWidth < 360 ? 15 : 18, K.white, fw: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _sparkleAnimation,
              builder: (_, __) => Opacity(
                opacity: 0.6 + _sparkleAnimation.value * 0.4,
                child: Text('✨', style: TextStyle(fontSize: screenWidth < 360 ? 22 : 28)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PREMIUM PROGRESS CARD - Shows generation status
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPremiumProgressCard() {
    final isUrdu = _selectedLanguage == 'urdu';
    final pastelIndex = _pct.toInt().clamp(0, K.pastel.length - 1);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [K.surface, K.pastel[pastelIndex]],
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: K.cyan, width: 4),
        boxShadow: const [BoxShadow(color: K.ink, offset: Offset(6, 6), blurRadius: 0)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FloatingCharacter('🎨', duration: 2),
              const SizedBox(width: 10),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Text('${_pct.toInt()}', style: ts(52, K.cyan, fw: FontWeight.w900)),
              ),
              Text('%', style: ts(26, K.cyan, fw: FontWeight.w700)),
              const SizedBox(width: 10),
              _FloatingCharacter('✨', duration: 2.5),
            ],
          ),
          const SizedBox(height: 16),
          _RainbowProgressBar(_pct / 100, label: 'Brewing Magic...'),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _sparkleAnimation,
            builder: (_, __) => Text(
              _pct > 85
                  ? (isUrdu ? '🇵🇰 Creating Urdu masterpiece... 🎬' : '🇺🇸 Creating English masterpiece... 🎬')
                  : '🌈 Crafting your extraordinary comic adventure... 🌈',
              style: tb(12, K.purple),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FloatingCharacter('⭐', duration: 1.5),
              const SizedBox(width: 6),
              _FloatingCharacter('💫', duration: 1.8),
              const SizedBox(width: 6),
              _FloatingCharacter('🌟', duration: 2.2),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PREMIUM VIDEO CARD - Pro presentation for video content
  // ═══════════════════════════════════════════════════════════════════
Widget _buildPremiumVideoCard() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF2D1B4E),
      borderRadius: BorderRadius.circular(36),
      border: Border.all(color: K.yellow, width: 4),
      boxShadow: const [BoxShadow(color: K.ink, offset: Offset(6, 6), blurRadius: 0)],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [K.purple, K.pink])),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _rotateAnimation,
                builder: (_, __) => Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: const Text('🎬', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎉 YOUR MAGIC VIDEO IS READY! 🎉', style: ts(13, K.white, fw: FontWeight.w900)),
                    Text(
                      _videoInitialized
                          ? (_selectedLanguage == 'urdu' ? '🇵🇰 Urdu Voiceover' : '🇺🇸 English Voiceover')
                          : 'Loading your video...',
                      style: tb(11, K.white.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [K.yellow, K.orange]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: K.ink, width: 2.5),
                ),
                child: Text('✨ PREMIUM ✨', style: ts(10, K.ink, fw: FontWeight.w900)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: _videoInitialized && _chewieController != null
              ? Chewie(controller: _chewieController!)
              : Container(
                  color: const Color(0xFF1A0A3E),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: K.yellow, strokeWidth: 4),
                        const SizedBox(height: 12),
                        Text('Preparing your video...', style: ts(13, K.white)),
                      ],
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Row 1: Watch Full Screen
              _PremiumPulseButton(
                onTap: () => setState(() => _showVideoOverlay = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [K.yellow, K.orange]),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: K.ink, width: 3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.fullscreen_rounded, color: K.ink, size: 24),
                      SizedBox(width: 10),
                      Text('WATCH FULL SCREEN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: K.ink)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, color: K.ink, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Row 2: Save Story and Download Video
              Row(
                children: [
                  Expanded(
                    child: _PremiumPulseButton(
                      onTap: _isSaving ? null : _saveStoryToDatabase,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: _isSaving 
                              ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                              : const LinearGradient(colors: [K.mint, K.cyan]),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: K.ink, width: 2.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isSaving ? Icons.hourglass_empty : Icons.bookmark_add_rounded, 
                                color: K.ink, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _isSaving ? 'SAVING...' : 'SAVE STORY',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: K.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PremiumPulseButton(
                      onTap: _isDownloading ? null : _downloadVideoToDevice,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: _isDownloading 
                              ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                              : const LinearGradient(colors: [K.blue, K.purple]),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: K.ink, width: 2.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isDownloading ? Icons.downloading : Icons.share_rounded, 
                                color: K.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _isDownloading ? 'SHARING...' : 'SHARE VIDEO',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: K.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  // ═══════════════════════════════════════════════════════════════════
  //  PREMIUM VIDEO OVERLAY - Fullscreen immersive experience
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPremiumVideoOverlay() {
    return Material(
      color: Colors.black.withOpacity(0.98),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showVideoOverlay = false),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [K.purple, K.pink]),
                        shape: BoxShape.circle,
                        border: Border.all(color: K.yellow, width: 2),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_selectedLanguage == 'urdu' ? K.purple : K.blue, _selectedLanguage == 'urdu' ? K.pink : K.cyan],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: K.yellow),
                    ),
                    child: Text(
                      _selectedLanguage == 'urdu' ? '🇵🇰 Roman Urdu' : '🇺🇸 English',
                      style: ts(12, K.white, fw: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: K.yellow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: K.ink),
                    ),
                    child: Text('HD', style: ts(10, K.ink, fw: FontWeight.w900)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: K.yellow, width: 4),
                    boxShadow: const [BoxShadow(color: K.yellow, blurRadius: 16, spreadRadius: 2)],
                  ),
                  child: _videoInitialized && _chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : const Center(child: CircularProgressIndicator(color: K.yellow, strokeWidth: 5)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: _PremiumPulseButton(
                onTap: () => setState(() => _showVideoOverlay = false),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [K.purple, K.pink]),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: K.yellow, width: 3),
                    boxShadow: const [BoxShadow(color: K.ink, offset: Offset(5, 5), blurRadius: 0)],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle_outline_rounded, color: K.yellow, size: 24),
                        SizedBox(width: 12),
                        Text('Done Watching', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: K.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PREMIUM STORY SECTION - With word-by-word highlighting
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPremiumStorySection() {
    final words = _story.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [K.lime, K.cyan]),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: K.ink, width: 4),
            boxShadow: const [BoxShadow(color: K.ink, offset: Offset(6, 6), blurRadius: 0)],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _FloatingCharacter('📖', duration: 2),
                  const SizedBox(width: 12),
                  Text('STORY TIME!', style: ts(20, K.ink, fw: FontWeight.w900)),
                  const Spacer(),
                  _buildPremiumTtsButton(Icons.play_circle_filled, K.ink, (_reading && !_paused) ? null : _startReading),
                  const SizedBox(width: 6),
                  _buildPremiumTtsButton(Icons.pause_circle_filled, K.orange, (_reading && !_paused) ? _pauseReading : null),
                  const SizedBox(width: 6),
                  _buildPremiumTtsButton(Icons.stop_circle, K.red, () => _stopReading(reset: true)),
                ],
              ),
              const SizedBox(height: 14),
              _PremiumPulseButton(
                isActive: !_urduReading,
                onTap: _startUrduReading,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: _urduReading 
                        ? const LinearGradient(colors: [K.purple, K.pink])
                        : null,
                    color: _urduReading ? null : K.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _urduReading ? K.white : K.ink, width: 2.5),
                    boxShadow: _urduReading 
                        ? [BoxShadow(color: K.purple.withOpacity(0.35), blurRadius: 14)] 
                        : const [BoxShadow(color: K.ink, offset: Offset(4, 4), blurRadius: 0)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_urduReading ? '🔊' : '🇵🇰', style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(
                        _urduReading ? 'اردو میں پڑھ رہا ہے...' : '🇵🇰 اردو میں سنیں',
                        style: ts(14, _urduReading ? K.white : K.ink),
                      ),
                      if (_urduReading) ...[
                        const SizedBox(width: 12),
                        const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: K.yellow, strokeWidth: 2.5)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E7),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: K.yellow, width: 4),
            boxShadow: const [BoxShadow(color: K.ink, offset: Offset(5, 5), blurRadius: 0)],
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: words.asMap().entries.map((e) {
              final i = e.key, w = e.value;
              final active = (_reading || _paused) && i == _cw;
              return GestureDetector(
                onTap: () {
                  if (_reading || _paused) {
                    setState(() => _cw = i);
                    _stopReading(reset: false);
                    _startReading();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: active ? 16 : 10, vertical: active ? 12 : 8),
                  decoration: BoxDecoration(
                    gradient: active ? const LinearGradient(colors: [K.yellow, K.orange]) : null,
                    color: active ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: active ? Border.all(color: K.ink, width: 2) : null,
                    boxShadow: active ? [BoxShadow(color: K.orange.withOpacity(0.4), blurRadius: 12, spreadRadius: 1)] : null,
                  ),
                  child: AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (_, __) => Transform.scale(
                      scale: active ? _bounceAnimation.value : 1.0,
                      child: Text(
                        w,
                        style: tb(active ? 24 : 18, active ? K.ink : K.ink.withOpacity(0.8),
                            fw: active ? FontWeight.w900 : FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTtsButton(IconData icon, Color c, VoidCallback? fn) {
    return GestureDetector(
      onTap: fn,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: fn == null ? 0.4 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: fn != null ? [BoxShadow(color: c.withOpacity(0.25), blurRadius: 6)] : null,
          ),
          child: Icon(icon, color: c, size: 44),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PROFESSIONAL TOGGLE COMIC BUTTON - Shows/hides comic section
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildProfessionalToggleButton() {
    return _PremiumPulseButton(
      isActive: true,
      onTap: _toggleComic,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _showComic ? K.oceanGradient : K.sunsetGradient,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: K.ink, width: 4),
          boxShadow: const [BoxShadow(color: K.ink, offset: Offset(6, 6), blurRadius: 0)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_showComic ? '🙈 HIDE COMIC' : '🎉 SHOW MY COMIC! 🎉', 
                style: ts(18, K.white, fw: FontWeight.w900)),
            const SizedBox(width: 12),
            AnimatedRotation(
              turns: _showComic ? 0.5 : 0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              child: const Icon(Icons.expand_more_rounded, color: K.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PREMIUM COMIC SECTION - Professional comic panel display
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPremiumComicSection() {
    if (_panels.isEmpty) return const SizedBox();
    return FadeTransition(
      opacity: AlwaysStoppedAnimation(_slideAnimation.value),
      child: Column(
        children: [
          _buildPremiumComicHeader(),
          const SizedBox(height: 18),
          _buildPremiumComicControls(),
          const SizedBox(height: 16),
          _buildPremiumPanelDots(),
          const SizedBox(height: 14),
          SizedBox(
            height: 540,
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (idx) => setState(() => _comicPanel = idx),
              itemCount: _panels.length,
              itemBuilder: (_, idx) => _buildPremiumComicPanel(idx, _panels[idx]),
            ),
          ),
          const SizedBox(height: 18),
          _buildPremiumPanelNav(),
          if (_genTime.isNotEmpty) ...[const SizedBox(height: 18), _buildPremiumTimeBadge()],
        ],
      ),
    );
  }

  Widget _buildPremiumComicHeader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 130,
          decoration: BoxDecoration(
            gradient: K.rainbowGradient,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: K.ink, width: 4),
          ),
        ),
        Column(
          children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [K.purple, K.pink, K.blue]).createShader(b),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FloatingCharacter('💥', duration: 1.5),
                  const SizedBox(width: 6),
                  Text(' SPECTACULAR! ', style: ts(20, K.white, fw: FontWeight.w900)),
                  _FloatingCharacter('🦸', duration: 2),
                  const SizedBox(width: 6),
                  Text(' AMAZING! ', style: ts(20, K.white, fw: FontWeight.w900)),
                  _FloatingCharacter('💫', duration: 1.8),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text('YOUR COMIC MASTERPIECE', style: ts(12, K.ink, fw: FontWeight.w900)),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumComicControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [K.pink, K.purple]),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: K.ink, width: 3),
        boxShadow: const [BoxShadow(color: K.ink, offset: Offset(5, 5), blurRadius: 0)],
      ),
      child: Row(
        children: [
          _FloatingCharacter('🎙️', duration: 1.8),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COMIC STORY MODE', style: ts(13, K.white, fw: FontWeight.w900)),
                Text(
                  _comicReading ? 'Reading panel ${_comicPanel + 1} of ${_panels.length}...' : 'Tap ▶ to hear the epic story!',
                  style: tb(11, K.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
          _buildPremiumComicControlButton(Icons.play_circle_filled_rounded, K.lime, _comicReading ? null : _startComicReading),
          const SizedBox(width: 12),
          _buildPremiumComicControlButton(Icons.stop_circle_rounded, K.red, _comicReading ? _stopComicReading : null),
        ],
      ),
    );
  }

  Widget _buildPremiumComicControlButton(IconData icon, Color c, VoidCallback? fn) {
    return GestureDetector(
      onTap: fn,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: fn == null ? null : LinearGradient(colors: [c, c.withOpacity(0.7)]),
          color: fn == null ? Colors.white.withOpacity(0.2) : null,
          shape: BoxShape.circle,
          border: Border.all(color: K.ink, width: 2.5),
          boxShadow: fn == null ? [] : const [BoxShadow(color: K.ink, offset: Offset(3, 3), blurRadius: 0)],
        ),
        child: Icon(icon, color: fn == null ? Colors.white.withOpacity(0.4) : K.white, size: 34),
      ),
    );
  }

  Widget _buildPremiumPanelDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_panels.length, (i) {
        final active = i == _comicPanel;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: active ? 36 : 12,
          height: 12,
          decoration: BoxDecoration(
            gradient: active ? LinearGradient(colors: [K.panelAccent(i), K.panelAccent(i).withOpacity(0.7)]) : null,
            color: active ? null : K.ink.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: active ? Border.all(color: K.ink, width: 2) : null,
          ),
        );
      }),
    );
  }

  Widget _buildPremiumPanelNav() {
    return // Row 2: Save Story and Download Video
Row(
  children: [
    Expanded(
      child: _PremiumPulseButton(
        onTap: _isSaving ? null : _saveStoryToDatabase,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: _isSaving 
                ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                : const LinearGradient(colors: [K.mint, K.cyan]),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: K.ink, width: 2.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_isSaving ? Icons.hourglass_empty : Icons.bookmark_add_rounded, 
                  color: K.ink, size: 20),
              const SizedBox(width: 8),
              Text(
                _isSaving ? 'SAVING...' : 'SAVE STORY',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: K.ink),
              ),
            ],
          ),
        ),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(
      child: _PremiumPulseButton(
        onTap: _isDownloading ? null : _downloadVideoToDevice,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: _isDownloading 
                ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                : const LinearGradient(colors: [K.blue, K.purple]),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: K.ink, width: 2.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_isDownloading ? Icons.downloading : Icons.download_for_offline_rounded, 
                  color: K.white, size: 20),
              const SizedBox(width: 8),
              Text(
                _isDownloading ? 'DOWNLOADING...' : 'DOWNLOAD VIDEO',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: K.white),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
);
  }

  Widget _buildPremiumComicPanel(int idx, Map<String, dynamic> panel) {
    final bg = K.pastel[idx % K.pastel.length];
    final bc = K.rainbow[idx % K.rainbow.length];
    final seed = idx < _seeds.length ? _seeds[idx] : idx * 137 + 7;
    final active = idx == _comicPanel && _comicReading;
    final imgUrl = panel['image'] as String? ?? '';

    Widget card = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Stack(
        children: [
          Positioned(
            left: 10, 
            top: 10, 
            right: 0, 
            bottom: 0, 
            child: Container(decoration: BoxDecoration(color: K.ink, borderRadius: BorderRadius.circular(32))),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bg, bg.withOpacity(0.95)],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: active ? bc : bg, width: 5),
              boxShadow: active ? [BoxShadow(color: bc.withOpacity(0.4), blurRadius: 18, spreadRadius: 2)] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(27)),
                      child: _buildPremiumPanelImage(imgUrl),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [bc, bc.withOpacity(0.8)]),
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(color: K.white, width: 2.5),
                          boxShadow: const [BoxShadow(color: K.ink, offset: Offset(3, 3), blurRadius: 0)],
                        ),
                        child: Text('PANEL ${idx + 1}', style: ts(13, K.white, fw: FontWeight.w900)),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Transform.rotate(
                        angle: 0.3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [K.rainbow[idx % K.rainbow.length], K.rainbow[(idx + 1) % K.rainbow.length]]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: K.ink, width: 2),
                            boxShadow: const [BoxShadow(color: K.ink, offset: Offset(2, 2), blurRadius: 0)],
                          ),
                          child: Text(K.rainbowLabels[idx % K.rainbowLabels.length], style: ts(11, K.white, fw: FontWeight.w900)),
                        ),
                      ),
                    ),
                    if (active)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(27)),
                          child: Container(color: bc.withOpacity(0.12)),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 6),
                  child: CustomPaint(
                    painter: _PremiumBubblePainter(fill: K.white, stroke: bc),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Text(panel['title'] ?? '', style: ts(16, bc, fw: FontWeight.w800)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
                  child: Text(panel['description'] ?? '', style: tb(14, K.ink.withOpacity(0.8), h: 1.4)),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: CustomPaint(painter: _PremiumWobblePainter(bc, 5.0, seed)),
            ),
          ),
        ],
      ),
    );

    if (idx < _panelSc.length) {
      card = AnimatedBuilder(
        animation: Listenable.merge([_panelSc[idx], _panelOp[idx]]),
        builder: (_, child) => Opacity(opacity: _panelOp[idx].value, child: Transform.scale(scale: _panelSc[idx].value, child: child)),
        child: card,
      );
    }
    return card;
  }

  Widget _buildPremiumPanelImage(String url) {
    if (url.isEmpty) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [K.blue.withOpacity(0.25), K.purple.withOpacity(0.25)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 4, valueColor: AlwaysStoppedAnimation<Color>(K.blue)),
              const SizedBox(height: 12),
              Text('Generating artwork...', style: ts(12, K.purple)),
            ],
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: 240,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        height: 240,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [K.blue.withOpacity(0.25), K.purple.withOpacity(0.25)],
          ),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 4, valueColor: AlwaysStoppedAnimation<Color>(K.blue))),
      ),
      errorWidget: (_, __, ___) => Container(
        height: 240,
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.broken_image, size: 56, color: Colors.grey)),
      ),
      fadeInDuration: Duration.zero,
    );
  }

  Widget _buildPremiumTimeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [K.mint, K.cyan]),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: K.ink, width: 4),
        boxShadow: const [BoxShadow(color: K.ink, offset: Offset(6, 6), blurRadius: 0)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FloatingCharacter('⚡', duration: 1.5),
          const SizedBox(width: 12),
          Text('Created in $_genTime', style: ts(15, K.ink, fw: FontWeight.w800)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: K.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: K.ink, width: 2),
            ),
            child: Text(_selectedLanguage == 'urdu' ? '🇵🇰 Roman Urdu' : '🇺🇸 English', style: ts(11, K.purple, fw: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CELEBRATION OVERLAY - Magical completion animation
// ═══════════════════════════════════════════════════════════════════
class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay();

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [K.yellow, K.orange]),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: K.white, width: 4),
                boxShadow: const [
                  BoxShadow(color: K.ink, offset: Offset(6, 6), blurRadius: 0),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('🎉', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 12),
                  Text('MAGIC COMPLETE!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: K.ink)),
                  SizedBox(height: 6),
                  Text('Your comic is ready!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: K.ink)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PREMIUM CUSTOM PAINTERS - Professional decorative elements
// ═══════════════════════════════════════════════════════════════════

class _PremiumBubblePainter extends CustomPainter {
  final Color fill, stroke;
  _PremiumBubblePainter({required this.fill, required this.stroke});
  
  @override
  void paint(Canvas canvas, Size sz) {
    const r = 22.0, tail = 28.0, tw = 30.0;
    final W = sz.width, H = sz.height;
    final path = Path()
      ..moveTo(r, 0)
      ..lineTo(W - r, 0)
      ..quadraticBezierTo(W, 0, W, r)
      ..lineTo(W, H - tail - r)
      ..quadraticBezierTo(W, H - tail, W - r, H - tail)
      ..lineTo(r + tw + 16, H - tail)
      ..lineTo(r + 8, H)
      ..lineTo(r + tw - 8, H - tail)
      ..lineTo(r, H - tail)
      ..quadraticBezierTo(0, H - tail, 0, H - tail - r)
      ..lineTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(path, Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = 3.5);
  }
  
  @override
  bool shouldRepaint(_PremiumBubblePainter o) => false;
}

class _PremiumWobblePainter extends CustomPainter {
  final Color color;
  final double sw;
  final Random _rng;
  _PremiumWobblePainter(this.color, this.sw, int seed) : _rng = Random(seed);
  
  @override
  void paint(Canvas canvas, Size sz) {
    final paint = Paint()..color = color..strokeWidth = sw..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    const int seg = 70;
    const double pad = 12.0;
    const double w2 = 4.0;
    final double W = sz.width;
    final double H = sz.height;
    final path = Path();
    path.moveTo(pad, _rng.nextDouble() * w2);
    for (int i = 1; i <= seg; i++) {
      path.lineTo(pad + (W - pad * 2) * i / seg, _rng.nextDouble() * w2);
    }
    for (int i = 1; i <= seg; i++) {
      path.lineTo(W - _rng.nextDouble() * w2, pad + (H - pad * 2) * i / seg);
    }
    for (int i = seg; i >= 0; i--) {
      path.lineTo(pad + (W - pad * 2) * i / seg, H - _rng.nextDouble() * w2);
    }
    for (int i = seg; i >= 0; i--) {
      path.lineTo(_rng.nextDouble() * w2, pad + (H - pad * 2) * i / seg);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(_PremiumWobblePainter o) => false;
}