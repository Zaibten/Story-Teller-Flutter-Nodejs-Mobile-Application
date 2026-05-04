import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../providers/user_provider.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════
//  HOME SCREEN  –  Fully responsive with animated backgrounds
// ═══════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  static const String routeName = '/home_screen';
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {

  // ── DATA ────────────────────────────────────────────────────────
  Map<String, dynamic> linkData = {};
  String? _currentStory;
  String? _currentStoryTitle;
  String? _currentVideoUrl;
  final Random _random = Random();
  bool _isSpeaking = false;
  bool _isGenerating = false;
  final FlutterTts _tts = FlutterTts();

  // ── SELECTIONS ──────────────────────────────────────────────────
  int?        _selectedCharIdx;
  String?     _selectedWorldName;
  String?     _selectedMood;
  Character?  _selectedChar;
  StoryWorld? _selectedWorld;

  // ── ANIMATION CONTROLLERS ────────────────────────────────────────
  late AnimationController _waveCtrl;
  late AnimationController _floatCtrl;     
  late AnimationController _pulseCtrl;
  late AnimationController _sparkCtrl1;
  late AnimationController _sparkCtrl2;
  late AnimationController _glowCtrl;
  late AnimationController _bounceCtrl;
  late AnimationController _modalCtrl;
  late AnimationController _moodCtrl;
  late AnimationController _moodCardCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _cardFloatCtrl;
  late AnimationController _starCtrl;
  late AnimationController _headerFloatCtrl;
  late AnimationController _fairyFloatCtrl;
  late AnimationController _charEntranceCtrl;
  late AnimationController _bubbleCtrl1;
  late AnimationController _bubbleCtrl2;
  late AnimationController _bubbleCtrl3;

  late Animation<double> _waveAnim;
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _modalScale;
  late Animation<double> _modalFade;
  late Animation<double> _moodScale;
  late Animation<double> _moodFade;
  late Animation<double> _moodCardScale;
  late Animation<double> _shimmerAnim;
  late Animation<double> _cardFloatAnim;
  late Animation<double> _starAnim;
  late Animation<double> _headerFloatAnim;
  late Animation<double> _fairyFloatAnim;
  late Animation<double> _charEntranceAnim;
  late Animation<double> _bubbleAnim1;
  late Animation<double> _bubbleAnim2;
  late Animation<double> _bubbleAnim3;

  final AudioPlayer _audio = AudioPlayer();
  final List<_Particle> _particles = [];
  final String _baseUrl = 'http://192.168.100.177:9000';

  // Responsive variables
  late double _sw, _sh;
  late double _paddingHorizontal;
  late double _gridSpacing;

  // ══════════════════════════════════════════════════════════════════
  //  CARD BACKGROUND COLORS (per character as requested)
  // ══════════════════════════════════════════════════════════════════
  static const List<Color> _cardBg = [
    Color(0xFFFF9BD2), // Pink - Cat
    Color(0xFFCBA6F7), // Purple - Lion
    Color(0xFF8ED6FF), // Blue - Elephant
    Color(0xFFFFE66D), // Yellow - Mouse
    Color(0xFFFF9BD2), // Pink - Monkey
    Color(0xFF8ED6FF), // Blue - Crocodile
  ];

  // ── CHARACTER DATA ───────────────────────────────────────────────
  final List<Character> characters = [
    Character(name: "Cat",       gif: "assets/images/cat.gif",       sound: "sounds/cat.mp3",       emoji: "🐱", color: const Color(0xFFFF4D8D), light: const Color(0xFFFFECF5)),
    Character(name: "Lion",      gif: "assets/images/lion.gif",      sound: "sounds/lion.mp3",      emoji: "🦁", color: const Color(0xFFFF9500), light: const Color(0xFFFFF5E0)),
    Character(name: "Elephant",  gif: "assets/images/elephant.gif",  sound: "sounds/elephant.mp3",  emoji: "🐘", color: const Color(0xFF8B5CF6), light: const Color(0xFFF3EEFF)),
    Character(name: "Mouse",     gif: "assets/images/mouse.gif",     sound: "sounds/mouse.mp3",     emoji: "🐭", color: const Color(0xFF00BFA5), light: const Color(0xFFDFFFF9)),
    Character(name: "Monkey",    gif: "assets/images/monkey.gif",    sound: "sounds/monkey.mp3",    emoji: "🐒", color: const Color(0xFFFF5722), light: const Color(0xFFFFF0EC)),
    Character(name: "Crocodile", gif: "assets/images/crocodile.gif", sound: "sounds/crocodile.mp3", emoji: "🐊", color: const Color(0xFF2E7D32), light: const Color(0xFFE8F5E9)),
  ];

  final List<StoryWorld> storyWorlds = [
    StoryWorld(name: "Forest", gif: "assets/images/forest.gif", emoji: "🌳", color: const Color(0xFF1B8C3E), light: const Color(0xFFE8F5E9), desc: "Magical forest", bg: const Color(0xFF0A5C25)),
    StoryWorld(name: "Space",  gif: "assets/images/space.gif",  emoji: "🚀", color: const Color(0xFF6C3FC0), light: const Color(0xFFF0E8FF), desc: "Outer space",   bg: const Color(0xFF3A1080)),
    StoryWorld(name: "Castle", gif: "assets/images/castle.gif", emoji: "🏰", color: const Color(0xFFB71C1C), light: const Color(0xFFFFEBEE), desc: "Magic castle",  bg: const Color(0xFF7A0000)),
    StoryWorld(name: "City",   gif: "assets/images/city.gif",   emoji: "🌆", color: const Color(0xFF1565C0), light: const Color(0xFFE3F2FD), desc: "City life",     bg: const Color(0xFF003580)),
  ];

  final List<Mood> moods = [
    Mood(name: "Happy",     emoji: "🌟", color: const Color(0xFFFFD000), bg: const Color(0xFFE65100)),
    Mood(name: "Funny",     emoji: "🎪", color: const Color(0xFFFF5500), bg: const Color(0xFFBF360C)),
    Mood(name: "Adventure", emoji: "⚡", color: const Color(0xFFCC0000), bg: const Color(0xFF7F0000)),
    Mood(name: "Bedtime",   emoji: "🌙", color: const Color(0xFF5360C4), bg: const Color(0xFF1A237E)),
  ];

  // ── INIT ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadLinksAsset();
    _spawnParticles();
    _setupTts();
    _setupAnimations();
    // Start character entrance animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _charEntranceCtrl.forward();
    });
  }

  Future<void> _loadLinksAsset() async {
    try {
      final raw = await rootBundle.loadString('assets/data/links.json');
      setState(() => linkData = json.decode(raw));
    } catch (e) { debugPrint('Links load error: $e'); }
  }

  void _spawnParticles() {
    final emojis = ['⭐','✨','💫','🌟','⚡','🎈','🎀','🌈','🦋','🌸','🎆','💥'];
    for (int i = 0; i < 26; i++) {
      _particles.add(_Particle(
        x:     _random.nextDouble(),
        y:     _random.nextDouble(),
        size:  5 + _random.nextDouble() * 12,
        speed: 0.15 + _random.nextDouble() * 0.5,
        emoji: emojis[_random.nextInt(emojis.length)],
        delay: _random.nextDouble(),
        drift: (_random.nextDouble() - 0.5) * 0.04,
      ));
    }
  }

  void _setupTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.44);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.1);
    _tts.setCompletionHandler(() { if (mounted) setState(() => _isSpeaking = false); });
    _tts.setErrorHandler((_)    { if (mounted) setState(() => _isSpeaking = false); });
  }

  void _setupAnimations() {
    _waveCtrl     = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _floatCtrl    = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _pulseCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _sparkCtrl1   = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _sparkCtrl2   = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..repeat(reverse: true);
    _glowCtrl     = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _bounceCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _modalCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _moodCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _moodCardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _shimmerCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _cardFloatCtrl= AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _starCtrl     = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _headerFloatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _fairyFloatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _charEntranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    
    // Bubble animations for background
    _bubbleCtrl1 = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _bubbleCtrl2 = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _bubbleCtrl3 = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    _waveAnim      = Tween<double>(begin: 0, end: 1).animate(_waveCtrl);
    _floatAnim     = Tween<double>(begin: -12, end: 12).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _pulseAnim     = Tween<double>(begin: 0.97, end: 1.03).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _glowAnim      = Tween<double>(begin: 0.5, end: 1.0).animate(_glowCtrl);
    _modalScale    = Tween<double>(begin: 0.78, end: 1.0).animate(CurvedAnimation(parent: _modalCtrl, curve: Curves.easeOutBack));
    _modalFade     = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _modalCtrl, curve: Curves.easeIn));
    _moodScale     = Tween<double>(begin: 0.78, end: 1.0).animate(CurvedAnimation(parent: _moodCtrl, curve: Curves.easeOutBack));
    _moodFade      = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _moodCtrl, curve: Curves.easeIn));
    _moodCardScale = Tween<double>(begin: 0.88, end: 1.06).animate(CurvedAnimation(parent: _moodCardCtrl, curve: Curves.easeOutBack));
    _shimmerAnim   = Tween<double>(begin: -1.0, end: 2.0).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
    _cardFloatAnim = Tween<double>(begin: -7, end: 7).animate(CurvedAnimation(parent: _cardFloatCtrl, curve: Curves.easeInOut));
    _starAnim      = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _starCtrl, curve: Curves.easeInOut));
    _headerFloatAnim = Tween<double>(begin: -3, end: 3).animate(CurvedAnimation(parent: _headerFloatCtrl, curve: Curves.easeInOut));
    _fairyFloatAnim = Tween<double>(begin: -18, end: 18).animate(CurvedAnimation(parent: _fairyFloatCtrl, curve: Curves.easeInOut));
    _charEntranceAnim = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _charEntranceCtrl, curve: Curves.easeOutBack));
    
    _bubbleAnim1 = Tween<double>(begin: 0, end: 20).animate(CurvedAnimation(parent: _bubbleCtrl1, curve: Curves.easeInOut));
    _bubbleAnim2 = Tween<double>(begin: 0, end: 15).animate(CurvedAnimation(parent: _bubbleCtrl2, curve: Curves.easeInOut));
    _bubbleAnim3 = Tween<double>(begin: 0, end: 25).animate(CurvedAnimation(parent: _bubbleCtrl3, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    for (final c in [_waveCtrl,_floatCtrl,_pulseCtrl,_sparkCtrl1,_sparkCtrl2,
                     _glowCtrl,_bounceCtrl,_modalCtrl,_moodCtrl,_moodCardCtrl,
                     _particleCtrl,_shimmerCtrl,_cardFloatCtrl,_starCtrl,
                     _headerFloatCtrl,_fairyFloatCtrl,_charEntranceCtrl,
                     _bubbleCtrl1,_bubbleCtrl2,_bubbleCtrl3]) {
      c.dispose();
    }
    _audio.dispose();
    _tts.stop();
    super.dispose();
  }

  // ── API ──
  Future<Map<String, dynamic>?> _generateStoryFromAPI() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/generate-story-text'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'character': _selectedChar?.name,
          'world': _selectedWorld?.name,
          'mood': _selectedMood,
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) return {'story': data['story'], 'title': data['title']};
      }
      return null;
    } catch (e) { debugPrint('Story API Error: $e'); return null; }
  }

  Future<String?> _generateVideoWithComic(String storyText) async {
    try {
      final prompt =
          "In English only: A ${_selectedChar?.name ?? 'character'} "
          "in ${_selectedWorld?.name ?? 'a magical place'} "
          "with ${_selectedMood?.toLowerCase() ?? 'adventurous'} mood. "
          "Story: ${storyText.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim().substring(0, storyText.length > 100 ? 100 : storyText.length)}";
      final response = await http.get(Uri.parse('$_baseUrl/generate-story-comic-stream?prompt=${Uri.encodeComponent(prompt)}'));
      if (response.statusCode == 200) {
        for (var line in response.body.split('\n')) {
          if (line.startsWith('data: ')) {
            final data = json.decode(line.substring(6));
            if (data['videoUrl'] != null && data['videoUrl'].isNotEmpty) return data['videoUrl'];
          }
        }
      }
      return null;
    } catch (e) { debugPrint('Video API Error: $e'); return null; }
  }

  Future<Map<String, dynamic>?> _generateStoryAndVideo() async {
    try {
      final storyResult = await _generateStoryFromAPI();
      if (storyResult == null) return null;
      final videoUrl = await _generateVideoWithComic(storyResult['story']);
      return {'story': storyResult['story'], 'title': storyResult['title'], 'videoUrl': videoUrl};
    } catch (e) { debugPrint('Combined Error: $e'); return null; }
  }

  String? _getVideoUrl() {
    if (_selectedChar == null || _selectedWorld == null || _selectedMood == null || linkData.isEmpty) return null;
    try { return linkData[_selectedChar!.name]?[_selectedWorld!.name]?[_selectedMood!] as String?; }
    catch (_) { return null; }
  }

  Future<void> _playSound(String path) async {
    try { await _audio.stop(); await _audio.play(AssetSource(path)); } catch (_) {}
  }

  // ── FLOW ────────────────────────────────────────────────────────
  void _openWorldModal() {
    if (_selectedCharIdx != null) _selectedChar = characters[_selectedCharIdx!];
    _modalCtrl.forward(from: 0);
    showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: "",
      transitionDuration: const Duration(milliseconds: 480),
      pageBuilder: (_, __, ___) => AnimatedBuilder(
        animation: _modalCtrl,
        builder: (_, __) => FadeTransition(opacity: _modalFade,
          child: ScaleTransition(scale: _modalScale,
            child: Center(child: SingleChildScrollView(child: _worldModalContent())))),
      ),
    ).then((_) => setState(() => _selectedWorldName = null));
  }

  void _openMoodModal() {
    _moodCtrl.forward(from: 0);
    showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: "",
      transitionDuration: const Duration(milliseconds: 480),
      pageBuilder: (_, __, ___) => AnimatedBuilder(
        animation: _moodCtrl,
        builder: (_, __) => FadeTransition(opacity: _moodFade,
          child: ScaleTransition(scale: _moodScale,
            child: Center(child: SingleChildScrollView(child: _moodModalContent())))),
      ),
    );
  }

  void _showLoaderThenStory() async {
    showDialog(context: context, barrierDismissible: false, barrierColor: Colors.black87,
      builder: (_) => const _LoadingDialog());
    setState(() => _isGenerating = true);
    final result = await _generateStoryAndVideo();
    setState(() => _isGenerating = false);
    if (!mounted) return;
    Navigator.pop(context);
    if (result != null) {
      _currentStory = result['story'];
      _currentStoryTitle = result['title'];
      _currentVideoUrl = result['videoUrl'] ?? _getVideoUrl();
      if (mounted) {
        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.82),
          builder: (_) => _StoryDialog(
            story: _currentStory!, storyTitle: _currentStoryTitle,
            videoUrl: _currentVideoUrl, char: _selectedChar!, world: _selectedWorld!, mood: _selectedMood!,
            tts: _tts,
            onClose: () async { await _tts.stop(); if (mounted) setState(() => _isSpeaking = false); },
            onNewStory: () async {
              final nr = await _generateStoryFromAPI();
              if (nr != null && mounted) {
                _currentStory = nr['story']; _currentStoryTitle = nr['title'];
                final nv = await _generateVideoWithComic(nr['story']);
                _currentVideoUrl = nv ?? _getVideoUrl();
                return _currentStory!;
              }
              return _currentStory ?? 'Could not generate a new story.';
            },
          ),
        );
      }
    } else {
      if (mounted) {
        showDialog(context: context, builder: (_) => AlertDialog(
          title: const Text('Oops!'),
          content: const Text('Failed to generate story. Please check your internet connection.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ));
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD - Fully Responsive
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    _sw = MediaQuery.of(context).size.width;
    _sh = MediaQuery.of(context).size.height;
    _paddingHorizontal = _sw * 0.04;
    _gridSpacing = _sw * 0.025;

    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: const Color(0xFFEDE8FF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(children: [
            // Floating particles layer
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => RepaintBoundary(child: CustomPaint(
                painter: _ParticlePainter(_particles, _particleCtrl.value),
                size: Size(_sw, _sh),
              )),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Header with floating animation
                  AnimatedBuilder(
                    animation: _headerFloatCtrl,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(0, _headerFloatAnim.value),
                      child: _buildHeader(user),
                    ),
                  ),

                  SizedBox(height: _sh * 0.01),

                  // "Choose Your Hero!" row
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: _paddingHorizontal),
                    child: Row(children: [
                      AnimatedBuilder(animation: _sparkCtrl1, builder: (_, __) =>
                        Transform.scale(scale: 0.88 + _sparkCtrl1.value * 0.24,
                          child: const Text('🎭', style: TextStyle(fontSize: 24)))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Choose Your Hero!',
                          style: TextStyle(
                            fontSize: _sw * 0.045,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF3B1FA8),
                            letterSpacing: 0.1,
                          ),
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD5CFFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${characters.length} heroes',
                          style: TextStyle(
                            fontSize: _sw * 0.028,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF5240B8),
                          )),
                      ),
                    ]),
                  ),

                  SizedBox(height: _sh * 0.008),

                  // CHARACTER GRID - with animated backgrounds
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: _gridSpacing),
                      child: AnimatedBuilder(
                        animation: _charEntranceCtrl,
                        builder: (_, __) => GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(bottom: _sh * 0.02),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: _gridSpacing,
                            mainAxisSpacing: _gridSpacing,
                            childAspectRatio: 0.60,
                          ),
                          itemCount: characters.length,
                          itemBuilder: (_, i) => Transform.scale(
                            scale: _charEntranceAnim.value,
                            child: _charCard(i),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: _sh * 0.008),

                  // Generate button
                  _buildGenerateBtn(),
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  HEADER
  // ══════════════════════════════════════════════════════════════════
Widget _buildHeader(dynamic user) {
  return SizedBox(
    height: 170,
    width: double.infinity,
    child: Stack(
      children: [

        // BACKGROUND
        Positioned.fill(
          child: Image.asset(
            "assets/images/castle_bg.png",
            fit: BoxFit.cover,
          ),
        ),

        // FAIRY
        Positioned(
          right: 0,
          bottom: 0,
          child: Image.asset(
            "assets/images/fairy.png",
            height: 140,
            fit: BoxFit.contain,
          ),
        ),

        // USER (TOP RIGHT)
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

        // LOGO + TITLE
        Positioned(
          top: 16,
          left: 16,
          right: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/logo.png",
                height: 50,
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

        // HINT (BOTTOM)
        Positioned(
          bottom: 12,
          left: 16,
          right: 16,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("👆", style: TextStyle(fontSize: 14)),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Tap a character to start your magical story!",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  // ══════════════════════════════════════════════════════════════════
  //  CHARACTER CARD - With Animated Background (Bubbles, Stars, Shapes)
  // ══════════════════════════════════════════════════════════════════
  Widget _charCard(int index) {
    final ch = characters[index];
    final bgCol = _cardBg[index % _cardBg.length];
    final sel = _selectedCharIdx == index;

    final imageSize = _sw * 0.48;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCharIdx = index);
        _bounceCtrl.forward(from: 0);
        _playSound(ch.sound);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseCtrl, _cardFloatCtrl, _bubbleCtrl1, _bubbleCtrl2, _bubbleCtrl3, _starCtrl]),
        builder: (_, __) {
          final floatY = sel ? _cardFloatAnim.value : 0.0;
          final scale = sel ? _pulseAnim.value : 1.0;
          
          final bubbleOffset1 = Offset(sin(_bubbleCtrl1.value * 2 * pi) * 8, _bubbleAnim1.value - 10);
          final bubbleOffset2 = Offset(cos(_bubbleCtrl2.value * 2 * pi) * 6, _bubbleAnim2.value - 15);
          final bubbleOffset3 = Offset(sin(_bubbleCtrl3.value * 2 * pi + 2) * 10, _bubbleAnim3.value - 8);

          return Transform.translate(
            offset: Offset(0, floatY),
            child: Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  color: bgCol,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: sel ? Colors.white : Colors.white.withOpacity(0.80),
                    width: sel ? 3.5 : 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: sel ? ch.color.withOpacity(0.55) : bgCol.withOpacity(0.65),
                      blurRadius: sel ? 24 : 14,
                      spreadRadius: sel ? 3 : 1,
                      offset: Offset(0, sel ? 10 : 6),
                    ),
                    if (sel)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: -2,
                        offset: const Offset(0, 0),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      // Animated Background - Bubbles and floating shapes
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _AnimatedBgPainter(
                            bubbleOffset1: bubbleOffset1,
                            bubbleOffset2: bubbleOffset2,
                            bubbleOffset3: bubbleOffset3,
                            starProgress: _starAnim.value,
                            selected: sel,
                            baseColor: bgCol,
                          ),
                        ),
                      ),
                      
                      // Sparkle stars on background
                      Positioned(
                        top: 5,
                        left: 5,
                        child: AnimatedBuilder(
                          animation: _starCtrl,
                          builder: (_, __) => Transform.scale(
                            scale: 0.5 + _starAnim.value * 0.5,
                            child: Text(sel ? "✨" : "⭐", style: TextStyle(fontSize: sel ? 20 : 14, shadows: [
                              Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 4)
                            ])),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: AnimatedBuilder(
                          animation: _sparkCtrl1,
                          builder: (_, __) => Transform.rotate(
                            angle: _sparkCtrl1.value * pi,
                            child: Text("🌟", style: TextStyle(fontSize: sel ? 18 : 12)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 15,
                        right: 15,
                        child: AnimatedBuilder(
                          animation: _sparkCtrl2,
                          builder: (_, __) => Transform.scale(
                            scale: 0.7 + _sparkCtrl2.value * 0.5,
                            child: Text("💫", style: TextStyle(fontSize: sel ? 16 : 12)),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 12,
                        child: AnimatedBuilder(
                          animation: _bubbleCtrl1,
                          builder: (_, __) => Transform.translate(
                            offset: Offset(0, sin(_bubbleCtrl1.value * 3 * pi) * 5),
                            child: Text("🌸", style: TextStyle(fontSize: sel ? 18 : 12)),
                          ),
                        ),
                      ),
                      
                      // Animated gradient overlay when selected
                      if (sel)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: AnimatedBuilder(
                              animation: _shimmerCtrl,
                              builder: (_, __) => ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.transparent, Colors.white.withOpacity(0.25), Colors.transparent],
                                  stops: [
                                    (_shimmerAnim.value - 0.5).clamp(0, 1),
                                    _shimmerAnim.value.clamp(0, 1),
                                    (_shimmerAnim.value + 0.5).clamp(0, 1),
                                  ],
                                ).createShader(bounds),
                                child: Container(color: Colors.white),
                              ),
                            ),
                          ),
                        ),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: _sh * 0.015),

                          // Character Image
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, __) => Transform.scale(
                              scale: sel ? 1.0 + _pulseCtrl.value * 0.04 : 1.0,
                              child: Container(
                                height: imageSize,
                                width: imageSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: sel
                                      ? [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.5),
                                            blurRadius: 18,
                                            spreadRadius: 5,
                                          )
                                        ]
                                      : null,
                                ),
                                child: Image.asset(
                                  ch.gif,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(ch.emoji, style: TextStyle(fontSize: imageSize * 0.5))),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: _sh * 0.012),

                          // Name pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [ch.color, ch.color.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: ch.color.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              ch.name,
                              style: TextStyle(
                                fontSize: _sw * 0.038,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          SizedBox(height: _sh * 0.008),

                          // Selection indicator
                          if (sel)
                            Padding(
                              padding: EdgeInsets.only(bottom: _sh * 0.008),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _sparkCtrl1,
                                    builder: (_, __) => Transform.rotate(
                                      angle: _sparkCtrl1.value * 0.5,
                                      child: const Icon(Icons.star_rounded, color: Colors.yellow, size: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Selected!',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      shadows: [Shadow(color: Colors.black26, blurRadius: 3)],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  AnimatedBuilder(
                                    animation: _sparkCtrl2,
                                    builder: (_, __) => Transform.rotate(
                                      angle: -_sparkCtrl2.value * 0.5,
                                      child: const Icon(Icons.star_rounded, color: Colors.yellow, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: EdgeInsets.only(bottom: _sh * 0.008),
                              child: Text(ch.emoji, style: TextStyle(fontSize: _sw * 0.065)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  GENERATE BUTTON
  // ══════════════════════════════════════════════════════════════════
Widget _buildGenerateBtn() {
  final enabled = _selectedCharIdx != null;
  final ch = enabled ? characters[_selectedCharIdx!] : null;

  return Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(
      _paddingHorizontal,
      12,
      _paddingHorizontal,
      _sh * 0.025,
    ),
    decoration: const BoxDecoration(
      color: Color(0xFFFFF9EC), // soft background for neumorphism base
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(32),
        topRight: Radius.circular(32),
      ),
    ),

    child: AnimatedBuilder(
      animation: Listenable.merge([
        _pulseCtrl,
        _sparkCtrl1,
        _sparkCtrl2,
      ]),
      builder: (_, __) {
        return Transform.scale(
          scale: enabled ? (1.0 + _pulseCtrl.value * 0.015) : 1.0,
          child: GestureDetector(
            onTap: enabled ? _openWorldModal : null,

            child: Stack(
              clipBehavior: Clip.none,
              children: [

                // ⭐ TOP RIGHT STAR
                Positioned(
                  top: -8,
                  right: -8,
                  child: Transform.rotate(
                    angle: _sparkCtrl1.value * 2,
                    child: const Text("⭐", style: TextStyle(fontSize: 24)),
                  ),
                ),

                // ⭐ BOTTOM LEFT STAR
                Positioned(
                  bottom: -8,
                  left: -8,
                  child: Transform.scale(
                    scale: 0.8 + _sparkCtrl2.value * 0.4,
                    child: const Text("⭐", style: TextStyle(fontSize: 22)),
                  ),
                ),

                // NEUMORPHISM BUTTON
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(vertical: _sh * 0.018),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0C7), // baby skin base

                    borderRadius: BorderRadius.circular(36),

                    // 🌟 NEUMORPHISM EFFECT
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.9),
                        offset: const Offset(-6, -6),
                        blurRadius: 12,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        offset: const Offset(6, 6),
                        blurRadius: 12,
                      ),
                    ],
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      // 📖 ICON
                      Transform.rotate(
                        angle: enabled ? _sparkCtrl1.value * 0.4 : 0,
                        child: const Text(
                          '📖',
                          style: TextStyle(fontSize: 26),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // TEXT
                      Flexible(
                        child: Text(
                          enabled
                              ? "✨ Create ${ch!.name}'s Story!"
                              : "Pick a Character First 👆",
                          style: TextStyle(
                            fontSize: _sw * 0.04,
                            fontWeight: FontWeight.w900,

                            // 💙 BLUE WHEN DISABLED
                            color: enabled
                                ? const Color(0xFF5C3800)
                                : const Color(0xFF1E6BFF),

                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ✨ SPARKLE
                      AnimatedBuilder(
                        animation: _sparkCtrl2,
                        builder: (_, __) {
                          return Transform.scale(
                            scale: enabled
                                ? (0.8 + _sparkCtrl2.value * 0.4)
                                : 0.8,
                            child: const Text(
                              '✨',
                              style: TextStyle(fontSize: 20),
                            ),
                          );
                        },
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
  );
}  // ── MODAL CONTENT ────────────────────────────────────────────────
  Widget _worldModalContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4776E6), Color(0xFF8E54E9)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(38),
        boxShadow: [BoxShadow(color: const Color(0xFF8E54E9).withOpacity(0.45), blurRadius: 32, spreadRadius: 4)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(38), topRight: Radius.circular(38))),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              AnimatedBuilder(animation: _sparkCtrl1, builder: (_, __) =>
                Transform.rotate(angle: _sparkCtrl1.value * pi,
                  child: const Text('🌍', style: TextStyle(fontSize: 32)))),
              const SizedBox(width: 10),
              const Text('Choose Your World!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4776E6))),
              const SizedBox(width: 10),
              AnimatedBuilder(animation: _sparkCtrl2, builder: (_, __) =>
                Transform.rotate(angle: -_sparkCtrl2.value * pi,
                  child: const Text('🗺️', style: TextStyle(fontSize: 32)))),
            ]),
            if (_selectedChar != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: _selectedChar!.color.withOpacity(0.12), borderRadius: BorderRadius.circular(30)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_selectedChar!.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text('Adventure with ${_selectedChar!.name}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _selectedChar!.color)),
                ]),
              ),
            ],
          ]),
        ),
        Padding(padding: const EdgeInsets.all(14),
          child: GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.88,
            children: storyWorlds.map((w) {
              final sel = _selectedWorldName == w.name;
              return GestureDetector(
                onTap: () {
                  setState(() { _selectedWorldName = w.name; _selectedWorld = w; });
                  _modalCtrl.reset(); Navigator.pop(context); _openMoodModal();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    gradient: sel
                        ? LinearGradient(colors: [w.color, w.color.withOpacity(0.72)])
                        : const LinearGradient(colors: [Colors.white, Color(0xFFF4F6FF)]),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: sel ? Colors.white.withOpacity(0.5) : Colors.grey.shade200, width: 2),
                    boxShadow: [BoxShadow(color: sel ? w.color.withOpacity(0.45) : Colors.grey.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 5))]),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: sel ? Colors.white.withOpacity(0.28) : w.light, shape: BoxShape.circle),
                      child: ClipRRect(borderRadius: BorderRadius.circular(50),
                        child: Image.asset(w.gif, height: 70, width: 70, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Text(w.emoji, style: const TextStyle(fontSize: 42)))),
                    ),
                    const SizedBox(height: 8),
                    Text(w.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: sel ? Colors.white : w.color)),
                    Text(w.desc, style: TextStyle(fontSize: 10, color: sel ? Colors.white70 : Colors.grey.shade500)),
                    if (sel) ...[const SizedBox(height: 4), const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16)],
                  ]),
                ),
              );
            }).toList(),
          )),
        Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: _modalBtn('✕  Close', () => Navigator.pop(context))),
      ]),
    );
  }

  Widget _moodModalContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(38),
        boxShadow: [BoxShadow(color: const Color(0xFFFF416C).withOpacity(0.45), blurRadius: 32, spreadRadius: 4)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(38), topRight: Radius.circular(38))),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              AnimatedBuilder(animation: _sparkCtrl2, builder: (_, __) =>
                Transform.rotate(angle: _sparkCtrl2.value * pi,
                  child: const Text('🎭', style: TextStyle(fontSize: 32)))),
              const SizedBox(width: 10),
              const Text('Pick the Mood!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFFF416C))),
              const SizedBox(width: 10),
              AnimatedBuilder(animation: _sparkCtrl1, builder: (_, __) =>
                Transform.rotate(angle: -_sparkCtrl1.value * pi,
                  child: const Text('🎨', style: TextStyle(fontSize: 32)))),
            ]),
            if (_selectedWorld != null && _selectedChar != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: _selectedWorld!.color.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
                child: Text(
                  '${_selectedChar!.emoji} ${_selectedChar!.name}  ➜  ${_selectedWorld!.emoji} ${_selectedWorld!.name}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _selectedWorld!.color)),
              ),
            ],
          ]),
        ),
        Padding(padding: const EdgeInsets.all(14),
          child: GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.84,
            children: moods.asMap().entries.map((e) {
              final i = e.key; final m = e.value;
              final sel = _selectedMood == m.name;
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 240 + i * 75),
                builder: (_, v, __) => Transform.scale(scale: 0.84 + v * 0.16,
                  child: Opacity(opacity: v,
                    child: GestureDetector(
                      onTap: () async {
                        setState(() => _selectedMood = m.name);
                        _moodCardCtrl.forward(from: 0);
                        await Future.delayed(const Duration(milliseconds: 210));
                        if (mounted) { _moodCtrl.reset(); Navigator.pop(context); _showLoaderThenStory(); }
                      },
                      child: AnimatedBuilder(animation: _moodCardCtrl, builder: (_, __) =>
                        Transform.scale(scale: sel ? _moodCardScale.value : 1.0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            decoration: BoxDecoration(
                              gradient: sel
                                  ? LinearGradient(colors: [m.color, m.color.withOpacity(0.8)])
                                  : const LinearGradient(colors: [Colors.white, Color(0xFFFFF5F0)]),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(color: sel ? Colors.white.withOpacity(0.5) : Colors.grey.shade200, width: 2.5),
                              boxShadow: [BoxShadow(color: sel ? m.color.withOpacity(0.45) : Colors.grey.withOpacity(0.1), blurRadius: 14, offset: const Offset(0, 5))]),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) =>
                                Transform.scale(scale: sel ? 1.0 + _pulseCtrl.value * 0.09 : 1.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: sel ? Colors.white.withOpacity(0.28) : m.color.withOpacity(0.14),
                                      shape: BoxShape.circle),
                                    child: Text(m.emoji, style: TextStyle(fontSize: sel ? 44 : 38))))),
                              const SizedBox(height: 8),
                              Text(m.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: sel ? Colors.white : m.color)),
                              if (sel) ...[const SizedBox(height: 5), const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18)],
                            ]),
                          ))),
                    ),
                  )),
              );
            }).toList(),
          )),
        Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: _modalBtn('← Back to Worlds', () {
            _moodCtrl.reset(); Navigator.pop(context); _openWorldModal();
          })),
      ]),
    );
  }

  Widget _modalBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)),
      child: Text(label, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  ANIMATED BACKGROUND PAINTER - Creates bubbles and floating shapes
// ═══════════════════════════════════════════════════════════════════
class _AnimatedBgPainter extends CustomPainter {
  final Offset bubbleOffset1;
  final Offset bubbleOffset2;
  final Offset bubbleOffset3;
  final double starProgress;
  final bool selected;
  final Color baseColor;

  _AnimatedBgPainter({
    required this.bubbleOffset1,
    required this.bubbleOffset2,
    required this.bubbleOffset3,
    required this.starProgress,
    required this.selected,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw bubbles with different opacities
    paint.color = Colors.white.withOpacity(selected ? 0.25 : 0.15);
    
    // Bubble 1
    canvas.drawCircle(
      Offset(size.width * 0.2 + bubbleOffset1.dx, size.height * 0.3 + bubbleOffset1.dy),
      15 + (selected ? 5 : 0),
      paint,
    );
    
    // Bubble 2
    paint.color = Colors.white.withOpacity(selected ? 0.2 : 0.12);
    canvas.drawCircle(
      Offset(size.width * 0.75 + bubbleOffset2.dx, size.height * 0.6 + bubbleOffset2.dy),
      12 + (selected ? 4 : 0),
      paint,
    );
    
    // Bubble 3
    paint.color = Colors.white.withOpacity(selected ? 0.22 : 0.14);
    canvas.drawCircle(
      Offset(size.width * 0.85 + bubbleOffset3.dx, size.height * 0.2 + bubbleOffset3.dy),
      10 + (selected ? 3 : 0),
      paint,
    );
    
    // Bubble 4 (small)
    paint.color = Colors.white.withOpacity(0.1);
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.7),
      8,
      paint,
    );
    
    // Draw floating hearts/stars in background
    final starPaint = Paint()
      ..color = Colors.white.withOpacity(0.2 + starProgress * 0.1)
      ..style = PaintingStyle.fill;
    
    // Star decorations
    for (int i = 0; i < 6; i++) {
      final angle = i * 60 * pi / 180;
      final radius = size.width * 0.08;
      final x = size.width * 0.85 + cos(angle) * radius * starProgress;
      final y = size.height * 0.85 + sin(angle) * radius * starProgress;
      
      final path = Path();
      final outerRadius = 5.0;
      final innerRadius = 2.5;
      final points = 5;
      for (int j = 0; j < points * 2; j++) {
        final r = j.isEven ? outerRadius : innerRadius;
        final rad = (j * pi / points) - pi / 2;
        final dx = x + r * cos(rad);
        final dy = y + r * sin(rad);
        if (j == 0) path.moveTo(dx, dy);
        else path.lineTo(dx, dy);
      }
      path.close();
      canvas.drawPath(path, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedBgPainter oldDelegate) {
    return oldDelegate.bubbleOffset1 != bubbleOffset1 ||
           oldDelegate.bubbleOffset2 != bubbleOffset2 ||
           oldDelegate.bubbleOffset3 != bubbleOffset3 ||
           oldDelegate.starProgress != starProgress ||
           oldDelegate.selected != selected;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  FAIRY FALLBACK
// ═══════════════════════════════════════════════════════════════════
class _FairyFallback extends StatelessWidget {
  final double size;
  const _FairyFallback({required this.size});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 0.7, height: size,
    child: CustomPaint(painter: _FairyPainter()),
  );
}

class _FairyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width; final h = s.height;
    final p = Paint()..style = PaintingStyle.fill;

    p.color = const Color(0xFFE1BEE7).withOpacity(0.70);
    canvas.drawOval(Rect.fromLTWH(-w*0.18, h*0.28, w*0.48, h*0.22), p);
    canvas.drawOval(Rect.fromLTWH(w*0.68, h*0.28, w*0.48, h*0.22), p);

    p.color = const Color(0xFFFFB74D);
    canvas.drawOval(Rect.fromLTWH(w*0.28, h*0.46, w*0.44, h*0.34), p);

    p.color = const Color(0xFFFFCC80);
    canvas.drawCircle(Offset(w*0.50, h*0.30), w*0.22, p);

    p.color = const Color(0xFFFF8F00);
    canvas.drawOval(Rect.fromLTWH(w*0.22, h*0.12, w*0.56, h*0.22), p);

    p.color = const Color(0xFFCE93D8).withOpacity(0.80);
    canvas.drawCircle(Offset(w*0.50, h*0.58), w*0.10, p);

    final wand = Paint()..color = const Color(0xFFFFD700)..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w*0.76, h*0.40), Offset(w*0.90, h*0.20), wand);
    p.color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset(w*0.90, h*0.18), 5, p);
  }
  @override bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  CASTLE PAINTER
// ═══════════════════════════════════════════════════════════════════
class _CastlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = Colors.white.withOpacity(0.45)..style = PaintingStyle.fill;
    final w = s.width; final h = s.height;
    canvas.drawRect(Rect.fromLTWH(0, h*0.22, w*0.24, h*0.78), p);
    for (int i = 0; i < 3; i++) canvas.drawRect(Rect.fromLTWH(w*0.02+i*w*0.07, h*0.10, w*0.05, h*0.13), p);
    canvas.drawRect(Rect.fromLTWH(w*0.18, h*0.40, w*0.64, h*0.60), p);
    canvas.drawRect(Rect.fromLTWH(w*0.76, h*0.22, w*0.24, h*0.78), p);
    for (int i = 0; i < 3; i++) canvas.drawRect(Rect.fromLTWH(w*0.78+i*w*0.07, h*0.10, w*0.05, h*0.13), p);
    final gate = Paint()..color = Colors.white.withOpacity(0.20)..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(w*0.38, h)
      ..lineTo(w*0.38, h*0.64)
      ..arcToPoint(Offset(w*0.62, h*0.64), radius: Radius.circular(w*0.12))
      ..lineTo(w*0.62, h)
      ..close();
    canvas.drawPath(path, gate);
  }
  @override bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════════
//  LOADING DIALOG
// ═══════════════════════════════════════════════════════════════════
class _LoadingDialog extends StatefulWidget {
  const _LoadingDialog();
  @override State<_LoadingDialog> createState() => _LoadingDialogState();
}
class _LoadingDialogState extends State<_LoadingDialog> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _scale = Tween<double>(begin: 0.8, end: 1.1).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        builder: (_, v, __) => Transform.scale(scale: v,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A0533), Color(0xFF0D1B4B)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 36)]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(animation: _c, builder: (_, __) =>
                Transform.scale(scale: _scale.value,
                  child: Text(_c.value < 0.33 ? '📖' : _c.value < 0.66 ? '✨' : '🌟',
                    style: const TextStyle(fontSize: 64)))),
              const SizedBox(height: 20),
              const Text('✨ Weaving Your Magic Story...', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 22),
              AnimatedBuilder(animation: _c, builder: (_, __) =>
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final phase = ((_c.value * 5 - i) % 5) / 5;
                    final y = -sin(phase * pi * 2) * 8;
                    return Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Transform.translate(offset: Offset(0, y),
                        child: Text(['⭐','🌟','✨','💫','⭐'][i], style: const TextStyle(fontSize: 22))));
                  }),
                )),
            ]),
          )),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STORY DIALOG (condensed but functional)
// ═══════════════════════════════════════════════════════════════════
class _StoryDialog extends StatefulWidget {
  final String story;
  final String? storyTitle;
  final String? videoUrl;
  final Character char;
  final StoryWorld world;
  final String mood;
  final FlutterTts tts;
  final VoidCallback onClose;
  final Future<String> Function() onNewStory;
  const _StoryDialog({required this.story, this.storyTitle, required this.videoUrl,
    required this.char, required this.world, required this.mood,
    required this.tts, required this.onClose, required this.onNewStory});
  @override State<_StoryDialog> createState() => _StoryDialogState();
}
class _StoryDialogState extends State<_StoryDialog> with SingleTickerProviderStateMixin {
  late String _story; String? _storyTitle;
  bool _speaking = false; bool _urduReading = false; bool _isLoadingNew = false;
  late AnimationController _textCtrl;
  late Animation<double> _textFade, _textSlide;
  int _highlightStart = 0; int _highlightEnd = 0; String _plainStory = '';

  @override
  void initState() {
    super.initState();
    _story = widget.story; _storyTitle = widget.storyTitle;
    _plainStory = _story.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim();
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textFade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    _textSlide = Tween<double>(begin: 28, end: 0).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textCtrl.forward();
    widget.tts.setCompletionHandler(() {
      if (mounted) setState(() { _speaking = false; _urduReading = false; _highlightStart = 0; _highlightEnd = 0; });
      widget.tts.setLanguage('en-US'); widget.tts.setSpeechRate(0.44); widget.tts.setPitch(1.1);
    });
    widget.tts.setErrorHandler((_) {
      if (mounted) setState(() { _speaking = false; _urduReading = false; _highlightStart = 0; _highlightEnd = 0; });
      widget.tts.setLanguage('en-US'); widget.tts.setSpeechRate(0.44); widget.tts.setPitch(1.1);
    });
    widget.tts.setProgressHandler((String text, int start, int end, String word) {
      if (mounted && _speaking) setState(() { _highlightStart = start; _highlightEnd = end; });
    });
  }
  @override void dispose() { _textCtrl.dispose(); super.dispose(); }

  Future<void> _toggleTts() async {
    if (_speaking) { await widget.tts.stop(); setState(() { _speaking = false; _highlightStart = 0; _highlightEnd = 0; }); return; }
    if (_urduReading) { await widget.tts.stop(); await Future.delayed(const Duration(milliseconds: 150)); setState(() => _urduReading = false); }
    await widget.tts.setLanguage('en-US'); await widget.tts.setSpeechRate(0.44); await widget.tts.setPitch(1.1);
    setState(() => _speaking = true);
    final clean = _story.replaceAll(RegExp(r'[^\x00-\x7F]+'), '').trim();
    await widget.tts.speak(clean.isEmpty ? _story : clean);
  }

  Future<void> _startUrduRead() async {
    if (_urduReading) {
      await widget.tts.stop();
      if (mounted) setState(() => _urduReading = false);
      await widget.tts.setLanguage('en-US'); await widget.tts.setSpeechRate(0.44); await widget.tts.setPitch(1.1);
      return;
    }
    await widget.tts.stop(); await Future.delayed(const Duration(milliseconds: 150));
    setState(() { _speaking = false; _highlightStart = 0; _highlightEnd = 0; });
    final dynamic langs = await widget.tts.getLanguages;
    final List<String> available = (langs as List).map((e) => e.toString().toLowerCase()).toList();
    if (!available.any((l) => l.contains('ur'))) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('🇵🇰 Urdu TTS not installed.\nSettings → Accessibility → TTS Output → Install Urdu',
          style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16), duration: const Duration(seconds: 4)));
      return;
    }
    await widget.tts.setLanguage('ur-PK'); await widget.tts.setSpeechRate(0.36); await widget.tts.setPitch(1.05);
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() => _urduReading = true);
    await widget.tts.speak(_story);
  }

  Future<void> _newStory() async {
    if (_isLoadingNew) return;
    setState(() => _isLoadingNew = true);
    await widget.tts.stop();
    setState(() { _speaking = false; _urduReading = false; _highlightStart = 0; _highlightEnd = 0; });
    final ns = await widget.onNewStory();
    if (mounted) {
      setState(() { _story = ns; _plainStory = ns.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim(); _isLoadingNew = false; });
      _textCtrl.reset(); _textCtrl.forward();
    }
  }

  void _openVideoModal() {
    if (widget.videoUrl == null) return;
    showDialog(context: context, builder: (_) => _VideoDialog(url: widget.videoUrl!, char: widget.char, world: widget.world, mood: widget.mood));
  }

  Color get _moodColor => {'Happy': const Color(0xFFFFCC00), 'Funny': const Color(0xFFFF5500), 'Adventure': const Color(0xFFCC0000), 'Bedtime': const Color(0xFF4C5FC4)}[widget.mood] ?? const Color(0xFF6C63FF);
  String get _moodEmoji => {'Happy':'🌟','Funny':'🎪','Adventure':'⚡','Bedtime':'🌙'}[widget.mood] ?? '✨';

  Widget _buildHighlightedStory() {
    if (_plainStory.isEmpty) return Text(_story, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.9, wordSpacing: 2.5));
    final List<String> tokens = []; final List<int> tokenStarts = [];
    int i = 0; final int len = _plainStory.length;
    while (i < len) {
      final char = _plainStory[i]; final bool isWordChar = _isWordChar(char);
      if (char == ' ') { tokens.add(' '); tokenStarts.add(i); i++; }
      else if (isWordChar) { final s = i; while (i < len && _isWordChar(_plainStory[i])) i++; tokens.add(_plainStory.substring(s, i)); tokenStarts.add(s); }
      else { tokens.add(char); tokenStarts.add(i); i++; }
    }
    final List<TextSpan> spans = [];
    for (int idx = 0; idx < tokens.length; idx++) {
      final token = tokens[idx]; final ts = tokenStarts[idx]; final te = ts + token.length;
      final bool hl = (ts >= _highlightStart && ts < _highlightEnd) || (te > _highlightStart && te <= _highlightEnd);
      spans.add(TextSpan(text: token, style: TextStyle(
        color: Colors.white, backgroundColor: hl ? Colors.amber.shade700 : Colors.transparent,
        fontWeight: hl ? FontWeight.w800 : FontWeight.w500, fontSize: 14, height: 1.8, wordSpacing: 2.0,
        shadows: hl ? const [Shadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))] : null)));
    }
    return RichText(text: TextSpan(children: spans));
  }
  bool _isWordChar(String c) { final code = c.codeUnitAt(0); return (code>=65&&code<=90)||(code>=97&&code<=122)||code==39||(code>=48&&code<=57); }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.80, end: 1.0),
        duration: const Duration(milliseconds: 660), curve: Curves.easeOutBack,
        builder: (_, scale, __) => Transform.scale(scale: scale,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF150D2E), Color(0xFF0B1845), Color(0xFF081630)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(38),
              border: Border.all(color: Colors.white.withOpacity(0.13), width: 1.5),
              boxShadow: [BoxShadow(color: _moodColor.withOpacity(0.32), blurRadius: 44, spreadRadius: 5),
                          BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 22)]),
            child: ClipRRect(borderRadius: BorderRadius.circular(38),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(gradient: LinearGradient(
                    colors: [_moodColor.withOpacity(0.30), Colors.transparent],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  child: Row(children: [
                    _AvatarRing(gif: widget.char.gif, emoji: widget.char.emoji, color: widget.char.color, size: 50),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_storyTitle ?? '${widget.char.name}\'s Story',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                      const SizedBox(height: 5),
                      Row(children: [
                        _Tag(label: '${widget.world.emoji} ${widget.world.name}', color: Colors.white.withOpacity(0.18)),
                        const SizedBox(width: 6),
                        _Tag(label: '$_moodEmoji ${widget.mood}', color: _moodColor.withOpacity(0.34)),
                      ]),
                    ])),
                    _AvatarRing(gif: widget.world.gif, emoji: widget.world.emoji, color: widget.world.color, size: 45),
                  ]),
                ),
                Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 18), color: Colors.white.withOpacity(0.1)),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                    child: AnimatedBuilder(animation: _textCtrl, builder: (_, __) =>
                      Opacity(opacity: _textFade.value,
                        child: Transform.translate(offset: Offset(0, _textSlide.value),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withOpacity(0.1))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: const [Text('📖', style: TextStyle(fontSize: 16)), SizedBox(width: 8),
                                Text('Your Magical Story', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5))]),
                              const SizedBox(height: 12),
                              _buildHighlightedStory(),
                            ]),
                          )))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                  child: Column(children: [
                    GestureDetector(onTap: _toggleTts,
                      child: AnimatedContainer(duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: _speaking
                              ? const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFC62828)])
                              : LinearGradient(colors: [_moodColor, _moodColor.withOpacity(0.78)]),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: (_speaking ? const Color(0xFFE53935) : _moodColor).withOpacity(0.44), blurRadius: 14, offset: const Offset(0, 5))]),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          AnimatedSwitcher(duration: const Duration(milliseconds: 280),
                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: RotationTransition(turns: Tween(begin: 0.0, end: 0.5).animate(anim), child: child)),
                            child: Icon(_speaking ? Icons.stop_circle_rounded : Icons.record_voice_over_rounded, key: ValueKey(_speaking), color: Colors.white, size: 24)),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(duration: const Duration(milliseconds: 240),
                            child: Text(_speaking ? 'Stop' : 'Read Aloud', key: ValueKey(_speaking),
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800))),
                        ]))),
                    const SizedBox(height: 8),
                    GestureDetector(onTap: _startUrduRead,
                      child: AnimatedContainer(duration: const Duration(milliseconds: 280),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          gradient: _urduReading
                              ? const LinearGradient(colors: [Color(0xFF6A0DAD), Color(0xFF4A0080)])
                              : const LinearGradient(colors: [Color(0xFF1C1C3A), Color(0xFF2A2A50)]),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: _urduReading ? const Color(0xFFAA00FF) : Colors.white.withOpacity(0.18), width: _urduReading ? 1.5 : 1.0),
                          boxShadow: _urduReading ? [BoxShadow(color: const Color(0xFF6A0DAD).withOpacity(0.5), blurRadius: 14, offset: const Offset(0, 5))] : []),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(_urduReading ? '🔊' : '🇵🇰', style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(duration: const Duration(milliseconds: 240),
                            child: Text(_urduReading ? 'اردو میں پڑھ رہا ہے...' : 'اردو میں سنیں', key: ValueKey(_urduReading),
                              style: TextStyle(color: _urduReading ? Colors.white : Colors.white70, fontSize: 14, fontWeight: FontWeight.w800))),
                          if (_urduReading) ...[const SizedBox(width: 8), const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))],
                        ]))),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: _BottomBtn(label: _isLoadingNew ? 'Generating...' : 'New Story', onTap: _isLoadingNew ? null : _newStory, highlight: true, color: _moodColor)),
                      const SizedBox(width: 8),
                      Expanded(child: _BottomBtn(label: 'Watch Video', onTap: widget.videoUrl != null ? _openVideoModal : null, highlight: true, color: const Color(0xFFFF6D00))),
                      const SizedBox(width: 8),
                      Expanded(child: _BottomBtn(label: 'Close', onTap: () { widget.onClose(); Navigator.pop(context); })),
                    ]),
                  ]),
                ),
              ]),
            ),
          )),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  VIDEO DIALOG
// ═══════════════════════════════════════════════════════════════════
class _VideoDialog extends StatefulWidget {
  final String url; final Character char; final StoryWorld world; final String mood;
  const _VideoDialog({required this.url, required this.char, required this.world, required this.mood});
  @override State<_VideoDialog> createState() => _VideoDialogState();
}
class _VideoDialogState extends State<_VideoDialog> with SingleTickerProviderStateMixin {
  late AnimationController _c; late WebViewController _webCtrl; bool _loading = true;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) => setState(() => _loading = false)))
      ..loadRequest(Uri.parse(widget.url));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  String get _moodEmoji => {'Happy':'🌟','Funny':'🎪','Adventure':'⚡','Bedtime':'🌙'}[widget.mood] ?? '✨';
  Color get _moodColor => {'Happy': const Color(0xFFFFCC00), 'Funny': const Color(0xFFFF5500), 'Adventure': const Color(0xFFCC0000), 'Bedtime': const Color(0xFF4C5FC4)}[widget.mood] ?? const Color(0xFF6C63FF);
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 28),
      child: ScaleTransition(scale: CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: _c,
          child: Container(
            width: sw * 0.9,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D0020), Color(0xFF0A1840)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
              boxShadow: [BoxShadow(color: _moodColor.withOpacity(0.3), blurRadius: 40, spreadRadius: 4)]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_moodColor.withOpacity(0.28), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(36), topRight: Radius.circular(36))),
                child: Row(children: [
                  _AvatarRing(gif: widget.char.gif, emoji: widget.char.emoji, color: widget.char.color, size: 40),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${widget.char.name}\'s Movie', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Row(children: [
                      _Tag(label: '${widget.world.emoji} ${widget.world.name}', color: Colors.white.withOpacity(0.16)),
                      const SizedBox(width: 5),
                      _Tag(label: '$_moodEmoji ${widget.mood}', color: _moodColor.withOpacity(0.32)),
                    ]),
                  ])),
                  GestureDetector(onTap: () => Navigator.pop(context),
                    child: Container(padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 16))),
                ]),
              ),
              Container(height: 200, margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.12)), color: Colors.black),
                child: ClipRRect(borderRadius: BorderRadius.circular(20),
                  child: Stack(children: [
                    WebViewWidget(controller: _webCtrl),
                    if (_loading) Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const CircularProgressIndicator(color: Colors.white), const SizedBox(height: 8),
                      Text('Loading video...', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                    ])),
                  ]))),
              Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                child: Row(children: [
                  Expanded(child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.5), size: 12), const SizedBox(width: 4),
                      Text('Tap video to play', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w600)),
                    ]))),
                  const SizedBox(width: 8),
                  GestureDetector(onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [_moodColor, _moodColor.withOpacity(0.75)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: _moodColor.withOpacity(0.4), blurRadius: 10)]),
                      child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)))),
                ])),
            ]),
          ))),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════
class _AvatarRing extends StatelessWidget {
  final String gif, emoji; final Color color; final double size;
  const _AvatarRing({required this.gif, required this.emoji, required this.color, required this.size});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(shape: BoxShape.circle,
      gradient: LinearGradient(colors: [color, color.withOpacity(0.55)]),
      boxShadow: [BoxShadow(color: color.withOpacity(0.42), blurRadius: 12)]),
    child: ClipRRect(borderRadius: BorderRadius.circular(size),
      child: Image.asset(gif, height: size, width: size, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text(emoji, style: TextStyle(fontSize: size * 0.55)))));
}

class _Tag extends StatelessWidget {
  final String label; final Color color;
  const _Tag({required this.label, required this.color});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)));
}

class _BottomBtn extends StatelessWidget {
  final String label; final VoidCallback? onTap; final bool highlight; final Color? color;
  const _BottomBtn({required this.label, required this.onTap, this.highlight = false, this.color});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: highlight && color != null && onTap != null ? LinearGradient(colors: [color!, color!.withOpacity(0.75)]) : null,
        color: highlight && color != null && onTap != null ? null : Colors.white.withOpacity(onTap != null ? 0.11 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(onTap != null ? 0.18 : 0.07)),
        boxShadow: highlight && onTap != null ? [BoxShadow(color: color!.withOpacity(0.35), blurRadius: 8)] : []),
      child: Text(label, textAlign: TextAlign.center,
        style: TextStyle(color: onTap != null ? Colors.white : Colors.white38, fontSize: 11, fontWeight: FontWeight.w700))));
}

// ═══════════════════════════════════════════════════════════════════
//  FLOATING PARTICLE SYSTEM
// ═══════════════════════════════════════════════════════════════════
class _Particle {
  final double x, y, size, speed, delay, drift; final String emoji;
  const _Particle({required this.x, required this.y, required this.size,
    required this.speed, required this.emoji, required this.delay, required this.drift});
}
class _ParticlePainter extends CustomPainter {
  final List<_Particle> ps; final double t;
  _ParticlePainter(this.ps, this.t);
  @override void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final p in ps) {
      final phase = (t * p.speed + p.delay) % 1.0;
      final y = size.height * (1.0 - phase);
      final x = size.width * p.x + sin(phase * pi * 2 + p.delay * pi) * size.width * 0.06 + p.drift * size.width * phase;
      final opa = phase < 0.12 ? phase / 0.12 : (phase > 0.88 ? (1 - phase) / 0.12 : 1.0);
      tp.text = TextSpan(text: p.emoji, style: TextStyle(fontSize: p.size, color: Colors.white.withOpacity(opa * 0.3)));
      tp.layout(); tp.paint(canvas, Offset(x, y));
    }
  }
  @override bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}

// ═══════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════════
class Character {
  final String name, gif, sound, emoji; final Color color, light;
  const Character({required this.name, required this.gif, required this.sound,
    required this.emoji, required this.color, required this.light});
}
class StoryWorld {
  final String name, gif, emoji, desc; final Color color, light, bg;
  const StoryWorld({required this.name, required this.gif, required this.emoji,
    required this.color, required this.light, required this.desc, required this.bg});
}
class Mood {
  final String name, emoji; final Color color, bg;
  const Mood({required this.name, required this.emoji, required this.color, required this.bg});
}