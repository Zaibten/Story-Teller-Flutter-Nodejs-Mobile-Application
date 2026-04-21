import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../providers/user_provider.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════
//  HOME SCREEN
// ═══════════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  static const String routeName = '/home_screen';
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {

  // ── DATA ────────────────────────────────────────────────────────
  Map<String, dynamic> storyData = {};
  Map<String, dynamic> linkData  = {};
  String? _currentStory;
  String? _currentVideoUrl;
  final Random _random = Random();
  bool _isSpeaking = false;
  final FlutterTts _tts = FlutterTts();

  // ── SELECTIONS ──────────────────────────────────────────────────
  int?       _selectedCharIdx;
  String?    _selectedWorldName;
  String?    _selectedMood;
  Character? _selectedChar;
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

  final AudioPlayer _audio = AudioPlayer();
  final List<_Particle> _particles = [];

  // ── CHARACTER / WORLD / MOOD DATA ─────────────────────────────────
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
    _loadAssets();
    _spawnParticles();
    _setupTts();
    _setupAnimations();
  }

  Future<void> _loadAssets() async {
    try {
      final sRaw = await rootBundle.loadString('assets/data/story.json');
      final lRaw = await rootBundle.loadString('assets/data/links.json');
      setState(() {
        storyData = json.decode(sRaw);
        linkData  = json.decode(lRaw);
      });
    } catch (e) { debugPrint('Asset load error: $e'); }
  }

  void _spawnParticles() {
    final emojis = ['⭐','✨','💫','🌟','⚡','🎈','🎀','🌈','🦋','🌸','🎆','💥'];
    for (int i = 0; i < 22; i++) {
      _particles.add(_Particle(
        x:     _random.nextDouble(),
        y:     _random.nextDouble(),
        size:  5 + _random.nextDouble() * 12,
        speed: 0.25 + _random.nextDouble() * 0.55,
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
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
    _shimmerCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _cardFloatCtrl= AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    _waveAnim       = Tween<double>(begin: 0, end: 1).animate(_waveCtrl);
    _floatAnim      = Tween<double>(begin: -7, end: 7).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _pulseAnim      = Tween<double>(begin: 0.97, end: 1.03).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _glowAnim       = Tween<double>(begin: 0.5, end: 1.0).animate(_glowCtrl);
    _modalScale     = Tween<double>(begin: 0.78, end: 1.0).animate(CurvedAnimation(parent: _modalCtrl, curve: Curves.easeOutBack));
    _modalFade      = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _modalCtrl, curve: Curves.easeIn));
    _moodScale      = Tween<double>(begin: 0.78, end: 1.0).animate(CurvedAnimation(parent: _moodCtrl, curve: Curves.easeOutBack));
    _moodFade       = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _moodCtrl, curve: Curves.easeIn));
    _moodCardScale  = Tween<double>(begin: 0.88, end: 1.06).animate(CurvedAnimation(parent: _moodCardCtrl, curve: Curves.easeOutBack));
    _shimmerAnim    = Tween<double>(begin: -1.0, end: 2.0).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
    _cardFloatAnim  = Tween<double>(begin: -4, end: 4).animate(CurvedAnimation(parent: _cardFloatCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    for (final c in [_waveCtrl,_floatCtrl,_pulseCtrl,_sparkCtrl1,_sparkCtrl2,
                     _glowCtrl,_bounceCtrl,_modalCtrl,_moodCtrl,_moodCardCtrl,
                     _particleCtrl,_shimmerCtrl,_cardFloatCtrl]) { c.dispose(); }
    _audio.dispose();
    _tts.stop();
    super.dispose();
  }

  // ── HELPERS ─────────────────────────────────────────────────────
  String? _pickRandomStory() {
    if (_selectedChar == null || _selectedWorld == null || _selectedMood == null || storyData.isEmpty) return null;
    try {
      final pool = storyData[_selectedChar!.name]?[_selectedWorld!.name]?[_selectedMood!];
      if (pool is List && pool.isNotEmpty) return pool[_random.nextInt(pool.length)] as String;
    } catch (_) {}
    return null;
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
      context: context,
      barrierDismissible: true,
      barrierLabel: "",
      transitionDuration: const Duration(milliseconds: 480),
      pageBuilder: (_, __, ___) => AnimatedBuilder(
        animation: _modalCtrl,
        builder: (_, __) => FadeTransition(
          opacity: _modalFade,
          child: ScaleTransition(scale: _modalScale,
            child: Center(child: SingleChildScrollView(child: _worldModalContent()))),
        ),
      ),
    ).then((_) => setState(() => _selectedWorldName = null));
  }

  void _openMoodModal() {
    _moodCtrl.forward(from: 0);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "",
      transitionDuration: const Duration(milliseconds: 480),
      pageBuilder: (_, __, ___) => AnimatedBuilder(
        animation: _moodCtrl,
        builder: (_, __) => FadeTransition(
          opacity: _moodFade,
          child: ScaleTransition(scale: _moodScale,
            child: Center(child: SingleChildScrollView(child: _moodModalContent()))),
        ),
      ),
    );
  }

  void _showLoaderThenStory() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => _LoadingDialog(),
    );
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      Navigator.pop(context);
      _currentStory    = _pickRandomStory();
      _currentVideoUrl = _getVideoUrl();
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.82),
        builder: (_) => _StoryDialog(
          story:    _currentStory ?? 'No story found. Try a different combination!',
          videoUrl: _currentVideoUrl,
          char:     _selectedChar!,
          world:    _selectedWorld!,
          mood:     _selectedMood!,
          tts:      _tts,
          onClose:  () async { await _tts.stop(); if (mounted) setState(() => _isSpeaking = false); },
          onNewStory: () {
            final s = _pickRandomStory();
            if (s != null) { _currentStory = s; return s; }
            return _currentStory ?? '';
          },
        ),
      );
    });
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final sw   = MediaQuery.of(context).size.width;
    final sh   = MediaQuery.of(context).size.height;
    final cols = sw > 600 ? 3 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF1FF),
      body: Stack(children: [

        // ── ANIMATED PARTICLE BACKGROUND ──────────────────────────
        AnimatedBuilder(
          animation: _particleCtrl,
          builder: (_, __) => RepaintBoundary(child: CustomPaint(
            painter: _ParticlePainter(_particles, _particleCtrl.value),
            size: Size(sw, sh),
          )),
        ),

        // ── BACKGROUND GRADIENT BLOBS ─────────────────────────────
        AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, __) {
            final t = _waveAnim.value;
            return Stack(children: [
              Positioned(top: -60, left: -40,
                child: Container(width: 220, height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Color.lerp(const Color(0xFF7C3AED), const Color(0xFF2563EB), t)!.withOpacity(0.18),
                      Colors.transparent,
                    ]),
                  ))),
              Positioned(bottom: 100, right: -50,
                child: Container(width: 260, height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Color.lerp(const Color(0xFFEC4899), const Color(0xFFF97316), t)!.withOpacity(0.14),
                      Colors.transparent,
                    ]),
                  ))),
            ]);
          },
        ),

        SafeArea(child: Column(children: [

          // ── HEADER (unchanged gradient appbar) ───────────────────
          _buildHeader(user, sw, sh),

          const SizedBox(height: 10),

          // ── SECTION LABEL ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(children: [
              AnimatedBuilder(animation: _sparkCtrl1, builder: (_, __) =>
                Transform.scale(scale: 0.9 + _sparkCtrl1.value * 0.2,
                  child: const Text('🎭', style: TextStyle(fontSize: 20)))),
              const SizedBox(width: 8),
              const Text('Choose Your Hero!',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900,
                  color: Color(0xFF3B1FA8), letterSpacing: 0.2)),
              const Spacer(),
              AnimatedBuilder(animation: _shimmerCtrl, builder: (_, __) =>
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                    colors: const [Color(0xFF6C63FF), Color(0xFFFF6B9D), Color(0xFF6C63FF)],
                    stops: [(_shimmerAnim.value - 1).clamp(0, 1), _shimmerAnim.value.clamp(0, 1), (_shimmerAnim.value + 1).clamp(0, 1)],
                  ).createShader(bounds),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                    ),
                    child: Text('${characters.length} heroes',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6C63FF), fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 8),

          // ── CHARACTER GRID ────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.028),
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: sw * 0.025,
                  mainAxisSpacing: sw * 0.025,
                  childAspectRatio: 0.85,
                ),
                itemCount: characters.length,
                itemBuilder: (_, i) => _charCard(i),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── GENERATE BUTTON ───────────────────────────────────────
          _buildGenerateBtn(sw),
        ])),
      ]),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────
  Widget _buildHeader(dynamic user, double sw, double sh) {
    return Stack(children: [
      // Gradient bg
      AnimatedBuilder(animation: _waveCtrl, builder: (_, __) => Container(
        height: sh * 0.195,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xFF667EEA), const Color(0xFF764BA2), _waveAnim.value)!,
              Color.lerp(const Color(0xFF764BA2), const Color(0xFFF093FB), _waveAnim.value)!,
            ],
          ),
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
          boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withOpacity(0.45), blurRadius: 22, offset: const Offset(0, 10))],
        ),
      )),

      // Decorative circles
      Positioned(top: -22, right: -22,
        child: AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) => Container(
          width: 88 + _pulseCtrl.value * 18, height: 88 + _pulseCtrl.value * 18,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.08))))),
      Positioned(bottom: 5, left: -15,
        child: Container(width: 55, height: 55,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)))),
      Positioned(top: 30, right: 80,
        child: AnimatedBuilder(animation: _sparkCtrl2, builder: (_, __) => Opacity(
          opacity: 0.3 + _sparkCtrl2.value * 0.4,
          child: Container(width: 20, height: 20,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white))))),

      Padding(
        padding: EdgeInsets.symmetric(horizontal: sw * 0.042, vertical: sh * 0.016),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

            // Logo + title
            AnimatedBuilder(animation: _floatCtrl, builder: (_, __) =>
              Transform.translate(offset: Offset(0, _floatAnim.value * 0.7),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 12)],
                    ),
                    child: AnimatedBuilder(animation: _sparkCtrl1, builder: (_, __) =>
                      Transform.scale(scale: 0.88 + _sparkCtrl1.value * 0.22,
                        child: Image.asset("assets/images/logo.png", width: 30, height: 30))),
                  ),
                  const SizedBox(width: 9),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('MAGIC STORY',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900,
                        letterSpacing: 1.4, color: Colors.white)),
                    Text('Adventure Awaits! ✨',
                      style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.85))),
                  ]),
                ]))),

            // User badge
            AnimatedBuilder(animation: _glowCtrl, builder: (_, __) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.3 + _glowAnim.value * 0.2)),
                ),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF667EEA), size: 12)),
                  const SizedBox(width: 6),
                  Text(user.name.split(" ")[0],
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(width: 4),
                  AnimatedBuilder(animation: _sparkCtrl2, builder: (_, __) =>
                    Transform.scale(scale: 0.8 + _sparkCtrl2.value * 0.4,
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.yellow, size: 11))),
                ]),
              )),
          ]),

          const SizedBox(height: 11),

          // Status strip
          AnimatedBuilder(animation: _shimmerCtrl, builder: (_, __) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedBuilder(animation: _sparkCtrl1, builder: (_, __) =>
                  Transform.rotate(angle: _sparkCtrl1.value * pi * 2,
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.yellow, size: 15))),
                const SizedBox(width: 9),
                Expanded(child: Text(
                  _selectedCharIdx != null
                      ? '✨ ${characters[_selectedCharIdx!].name} is ready! Choose a world next!'
                      : '🌸 Tap a character to start your magical story!',
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                )),
              ]),
            )),
        ]),
      ),
    ]);
  }

  // ── CHARACTER CARD ──────────────────────────────────────────────
  Widget _charCard(int index) {
    final ch  = characters[index];
    final sel = _selectedCharIdx == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCharIdx = index);
        _bounceCtrl.forward(from: 0);
        _playSound(ch.sound);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseCtrl, _cardFloatCtrl]),
        builder: (_, __) {
          final floatY = sel ? _cardFloatAnim.value : 0.0;
          final scale  = sel ? _pulseAnim.value : 1.0;
          return Transform.translate(
            offset: Offset(0, floatY),
            child: Transform.scale(scale: scale,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                decoration: BoxDecoration(
                  gradient: sel
                      ? LinearGradient(colors: [ch.color, ch.color.withOpacity(0.72), ch.color.withOpacity(0.5)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : const LinearGradient(colors: [Colors.white, Color(0xFFF4F6FF)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: sel ? Colors.white.withOpacity(0.6) : Colors.white,
                    width: sel ? 2.5 : 1.5),
                  boxShadow: [BoxShadow(
                    color: sel ? ch.color.withOpacity(0.5) : Colors.grey.withOpacity(0.15),
                    blurRadius: sel ? 20 : 6,
                    spreadRadius: sel ? 2 : 0,
                    offset: Offset(0, sel ? 8 : 3),
                  )],
                ),
                child: Stack(children: [

                  // Shimmer overlay when selected
                  if (sel) Positioned.fill(child: AnimatedBuilder(
                    animation: _shimmerCtrl,
                    builder: (_, __) => ClipRRect(borderRadius: BorderRadius.circular(24),
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [Colors.transparent, Colors.white.withOpacity(0.08), Colors.transparent],
                          stops: [(_shimmerAnim.value - 0.5).clamp(0,1), _shimmerAnim.value.clamp(0,1), (_shimmerAnim.value + 0.5).clamp(0,1)],
                        ).createShader(bounds),
                        child: Container(color: Colors.white),
                      )),
                  )),

                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                    // Character image
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: sel ? Border.all(color: Colors.white, width: 3) : null,
                        boxShadow: sel ? [BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 14)] : null,
                      ),
                      child: ClipRRect(borderRadius: BorderRadius.circular(50),
                        child: Image.asset(ch.gif, height: 78, width: 78, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            height: 78, width: 78,
                            decoration: BoxDecoration(color: ch.light, shape: BoxShape.circle),
                            child: Center(child: Text(ch.emoji, style: const TextStyle(fontSize: 38)))))),
                    ),

                    const SizedBox(height: 8),

                    // Name badge
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: sel ? Colors.white : ch.color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: (sel ? Colors.white : ch.color).withOpacity(0.35), blurRadius: 8)],
                      ),
                      child: Text(ch.name, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: sel ? ch.color : Colors.white)),
                    ),

                    const SizedBox(height: 5),

                    // State indicator
                    if (sel)
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                        Icon(Icons.star_rounded, color: Colors.yellow, size: 13),
                        SizedBox(width: 2),
                        Text('Selected!', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                        SizedBox(width: 2),
                        Icon(Icons.star_rounded, color: Colors.yellow, size: 13),
                      ])
                    else
                      Text(ch.emoji, style: const TextStyle(fontSize: 22)),
                  ]),
                ]),
              )),
          );
        },
      ),
    );
  }

  // ── GENERATE BUTTON ─────────────────────────────────────────────
  Widget _buildGenerateBtn(double sw) {
    final enabled = _selectedCharIdx != null;
    final ch = enabled ? characters[_selectedCharIdx!] : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(sw * 0.04, 12, sw * 0.04, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) =>
        Transform.scale(scale: enabled ? (1.0 + _pulseCtrl.value * 0.012) : 1.0,
          child: GestureDetector(
            onTap: enabled ? _openWorldModal : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: enabled
                    ? LinearGradient(colors: [ch!.color, ch.color.withOpacity(0.75), const Color(0xFF6C63FF).withOpacity(0.8)],
                        begin: Alignment.centerLeft, end: Alignment.centerRight)
                    : const LinearGradient(colors: [Color(0xFFD0D0D0), Color(0xFFBDBDBD)]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: enabled ? [BoxShadow(color: ch!.color.withOpacity(0.52), blurRadius: 18, offset: const Offset(0, 8))] : [],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedBuilder(animation: _sparkCtrl1, builder: (_, __) =>
                  Transform.rotate(angle: enabled ? _sparkCtrl1.value * pi * 2 : 0,
                    child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22))),
                const SizedBox(width: 10),
                Text(
                  enabled ? '✨ Create ${ch!.name}\'s Story!' : 'Pick a Character First 👆',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
              ]),
            ),
          )),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  WORLD MODAL
  // ══════════════════════════════════════════════════════════════════
  Widget _worldModalContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4776E6), Color(0xFF8E54E9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(38),
        boxShadow: [BoxShadow(color: const Color(0xFF8E54E9).withOpacity(0.45), blurRadius: 32, spreadRadius: 4)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Header
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

        // World grid
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
                    boxShadow: [BoxShadow(color: sel ? w.color.withOpacity(0.45) : Colors.grey.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 5))],
                  ),
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

  // ══════════════════════════════════════════════════════════════════
  //  MOOD MODAL
  // ══════════════════════════════════════════════════════════════════
  Widget _moodModalContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(38),
        boxShadow: [BoxShadow(color: const Color(0xFFFF416C).withOpacity(0.45), blurRadius: 32, spreadRadius: 4)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [

        // Header
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

        // Mood grid
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
                      onTap: () {
                        setState(() => _selectedMood = m.name);
                        _moodCardCtrl.forward(from: 0);
                        Future.delayed(const Duration(milliseconds: 210), () {
                          _moodCtrl.reset(); Navigator.pop(context); _showLoaderThenStory();
                        });
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
                              boxShadow: [BoxShadow(color: sel ? m.color.withOpacity(0.45) : Colors.grey.withOpacity(0.1), blurRadius: 14, offset: const Offset(0, 5))],
                            ),
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
//  LOADING DIALOG
// ═══════════════════════════════════════════════════════════════════
class _LoadingDialog extends StatefulWidget {
  @override State<_LoadingDialog> createState() => _LoadingDialogState();
}
class _LoadingDialogState extends State<_LoadingDialog> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _rot, _scale;

  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _rot   = Tween<double>(begin: 0, end: 2 * pi).animate(CurvedAnimation(parent: _c, curve: Curves.linear));
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
              gradient: const LinearGradient(colors: [Color(0xFF1A0533), Color(0xFF0D1B4B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.4), blurRadius: 36)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(animation: _c, builder: (_, __) =>
                Transform.scale(scale: _scale.value,
                  child: Text(_c.value < 0.33 ? '📖' : _c.value < 0.66 ? '✨' : '🌟',
                    style: const TextStyle(fontSize: 64)))),
              const SizedBox(height: 20),
              const Text('✨ Weaving Your Magic Story...', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 22),
              AnimatedBuilder(animation: _rot, builder: (_, __) {
                return Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final phase = ((_c.value * 5 - i) % 5) / 5;
                    final y = -sin(phase * pi * 2) * 8;
                    return Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Transform.translate(offset: Offset(0, y),
                        child: Text(['⭐','🌟','✨','💫','⭐'][i], style: const TextStyle(fontSize: 22))));
                  }),
                );
              }),
            ]),
          )),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STORY DIALOG  (full-screen panel, no prev/next)
// ═══════════════════════════════════════════════════════════════════
class _StoryDialog extends StatefulWidget {
  final String story;
  final String? videoUrl;
  final Character char;
  final StoryWorld world;
  final String mood;
  final FlutterTts tts;
  final VoidCallback onClose;
  final String Function() onNewStory;

  const _StoryDialog({
    required this.story, required this.videoUrl, required this.char, required this.world,
    required this.mood, required this.tts, required this.onClose, required this.onNewStory,
  });

  @override State<_StoryDialog> createState() => _StoryDialogState();
}

class _StoryDialogState extends State<_StoryDialog> with SingleTickerProviderStateMixin {
  late String _story;
  bool _speaking = false;
  late AnimationController _textCtrl;
  late Animation<double> _textFade, _textSlide;
    // NEW: for highlighting the spoken portion
  int _highlightStart = 0;
  int _highlightEnd   = 0;
  String _plainStory   = '';

  @override
  void initState() {
    super.initState();
    _story = widget.story;

    // strip emojis / non-ASCII for clean character‑accurate highlighting
  _plainStory = _story.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim();

  _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  _textFade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
  _textSlide = Tween<double>(begin: 28, end: 0).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
  _textCtrl.forward();

  widget.tts.setCompletionHandler(() {
    if (mounted) setState(() {
      _speaking = false;
      _highlightStart = 0;
      _highlightEnd   = 0;
    });
  });
  widget.tts.setErrorHandler((_) {
    if (mounted) setState(() {
      _speaking = false;
      _highlightStart = 0;
      _highlightEnd   = 0;
    });
  });

  // ✨ NEW: listen to progress (character indices)
  widget.tts.setProgressHandler((String text, int start, int end, String word) {
    if (mounted) {
      setState(() {
        _highlightStart = start;
        _highlightEnd   = end;
      });
    }
  });


    // _textCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    // _textFade  = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    // _textSlide = Tween<double>(begin: 28, end: 0).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    // _textCtrl.forward();
    // widget.tts.setCompletionHandler(() { if (mounted) setState(() => _speaking = false); });
    // widget.tts.setErrorHandler((_)    { if (mounted) setState(() => _speaking = false); });
  }

  @override void dispose() { _textCtrl.dispose(); super.dispose(); }

  Future<void> _toggleTts() async {
    if (_speaking) {
      await widget.tts.stop();
      setState(() => _speaking = false);
    } else {
      setState(() => _speaking = true);
      final clean = _story.replaceAll(RegExp(r'[^\x00-\x7F]+'), '').trim();
      await widget.tts.speak(clean.isEmpty ? _story : clean);
    }
  }



Widget _buildHighlightedStory() {
  if (_plainStory.isEmpty) {
    return Text(
      _story,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        height: 1.9,
        wordSpacing: 2.5,
      ),
    );
  }

  final List<TextSpan> spans = [];
  // Split while keeping spaces and words
  final RegExp splitPattern = RegExp(r'(\w+\'?\w*|\s+|[^\w\s])');
  final tokens = _plainStory.split(splitPattern).where((t) => t.isNotEmpty).toList();

  int currentPos = 0;
  for (final token in tokens) {
    final tokenStart = currentPos;
    final tokenEnd = currentPos + token.length;

    final isHighlighted = (tokenStart >= _highlightStart && tokenStart < _highlightEnd) ||
                          (tokenEnd > _highlightStart && tokenEnd <= _highlightEnd);

    spans.add(TextSpan(
      text: token,
      style: TextStyle(
        color: Colors.white,
        backgroundColor: isHighlighted ? Colors.amber.shade700 : Colors.transparent,
        fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w500,
        fontSize: 15,
        height: 1.9,
        wordSpacing: 2.5,
        // subtle shadow for highlighted words
        shadows: isHighlighted
            ? [const Shadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))]
            : null,
      ),
    ));
    currentPos += token.length;
  }

  // Wrap with AnimatedSwitcher to get a fade+scale animation when the highlight changes
  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 180),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, animation) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
          child: child,
        ),
      );
    },
    child: RichText(
      key: ValueKey('$_highlightStart-$_highlightEnd'), // forces rebuild when highlight changes
      text: TextSpan(children: spans),
    ),
  );
}



  void _newStory() async {
    await widget.tts.stop();
    setState(() => _speaking = false);
    _textCtrl.reset();
    final s = widget.onNewStory();
    setState(() => _story = s);
    _textCtrl.forward();
  }

  void _openVideoModal() {
    if (widget.videoUrl == null) return;
    showDialog(context: context, builder: (_) => _VideoDialog(url: widget.videoUrl!, char: widget.char, world: widget.world, mood: widget.mood));
  }

  // Mood visuals
  Color get _moodColor => {
    'Happy': const Color(0xFFFFCC00), 'Funny': const Color(0xFFFF5500),
    'Adventure': const Color(0xFFCC0000), 'Bedtime': const Color(0xFF4C5FC4),
  }[widget.mood] ?? const Color(0xFF6C63FF);

  String get _moodEmoji => {'Happy':'🌟','Funny':'🎪','Adventure':'⚡','Bedtime':'🌙'}[widget.mood] ?? '✨';

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
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF150D2E), Color(0xFF0B1845), Color(0xFF081630)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(38),
              border: Border.all(color: Colors.white.withOpacity(0.13), width: 1.5),
              boxShadow: [
                BoxShadow(color: _moodColor.withOpacity(0.32), blurRadius: 44, spreadRadius: 5),
                BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 22),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: Column(mainAxisSize: MainAxisSize.min, children: [

                // ── HEADER ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_moodColor.withOpacity(0.30), Colors.transparent],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  child: Row(children: [
                    _AvatarRing(gif: widget.char.gif, emoji: widget.char.emoji, color: widget.char.color, size: 60),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${widget.char.name}\'s Story',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                      const SizedBox(height: 5),
                      Row(children: [
                        _Tag(label: '${widget.world.emoji} ${widget.world.name}', color: Colors.white.withOpacity(0.18)),
                        const SizedBox(width: 6),
                        _Tag(label: '$_moodEmoji ${widget.mood}', color: _moodColor.withOpacity(0.34)),
                      ]),
                    ])),
                    _AvatarRing(gif: widget.world.gif, emoji: widget.world.emoji, color: widget.world.color, size: 52),
                  ]),
                ),

                Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 18), color: Colors.white.withOpacity(0.1)),

                // ── STORY TEXT ────────────────────────────────────────
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.38),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                    child: AnimatedBuilder(animation: _textCtrl, builder: (_, __) =>
                      Opacity(opacity: _textFade.value,
                        child: Transform.translate(offset: Offset(0, _textSlide.value),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withOpacity(0.1))),
                            // child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            //   Row(children: const [
                            //     Text('📖', style: TextStyle(fontSize: 17)),
                            //     SizedBox(width: 8),
                            //     Text('Your Magical Story',
                            //       style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                            //   ]),
                            //   const SizedBox(height: 12),
                            //   Text(_story, style: const TextStyle(
                            //     color: Colors.white, fontSize: 15, height: 1.82,
                            //     fontWeight: FontWeight.w400, letterSpacing: 0.15)),
                            // ]),

                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  Row(children: const [
    Text('📖', style: TextStyle(fontSize: 17)),
    SizedBox(width: 8),
    Text('Your Magical Story',
      style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
  ]),
  const SizedBox(height: 12),
  _buildHighlightedStory(),
]),
                          )))),
                  ),
                ),

                // ── CONTROLS ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                  child: Column(children: [

                    // TTS button
                    GestureDetector(
                      onTap: _toggleTts,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: _speaking
                              ? const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFC62828)])
                              : LinearGradient(colors: [_moodColor, _moodColor.withOpacity(0.78)]),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(
                            color: (_speaking ? const Color(0xFFE53935) : _moodColor).withOpacity(0.44),
                            blurRadius: 16, offset: const Offset(0, 7))]),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: RotationTransition(turns: Tween(begin: 0.0, end: 0.5).animate(anim), child: child)),
                            child: Icon(
                              _speaking ? Icons.stop_circle_rounded : Icons.record_voice_over_rounded,
                              key: ValueKey(_speaking), color: Colors.white, size: 26)),
                          const SizedBox(width: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            child: Text(
                              _speaking ? '⏹  Stop Reading' : '🔊  Read Story Aloud',
                              key: ValueKey(_speaking),
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800))),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Bottom row
                    Row(children: [
                      // Expanded(child: _BottomBtn(label: '🎲 New Story',    onTap: _newStory)),
                      // const SizedBox(width: 8),
                      Expanded(child: _BottomBtn(label: '🎬 Watch Video',  onTap: widget.videoUrl != null ? _openVideoModal : null, highlight: true, color: const Color(0xFFFF6D00))),
                      const SizedBox(width: 8),
                      Expanded(child: _BottomBtn(label: '✕  Close',        onTap: () { widget.onClose(); Navigator.pop(context); })),
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
  final String url;
  final Character char;
  final StoryWorld world;
  final String mood;
  const _VideoDialog({required this.url, required this.char, required this.world, required this.mood});
  @override State<_VideoDialog> createState() => _VideoDialogState();
}
class _VideoDialogState extends State<_VideoDialog> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late WebViewController _webCtrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) => setState(() => _loading = false)))
      ..loadRequest(Uri.parse(widget.url));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  String get _moodEmoji => {'Happy':'🌟','Funny':'🎪','Adventure':'⚡','Bedtime':'🌙'}[widget.mood] ?? '✨';

  Color get _moodColor => {
    'Happy': const Color(0xFFFFCC00), 'Funny': const Color(0xFFFF5500),
    'Adventure': const Color(0xFFCC0000), 'Bedtime': const Color(0xFF4C5FC4),
  }[widget.mood] ?? const Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 28),
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
        child: FadeTransition(
          opacity: _c,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0D0020), Color(0xFF0A1840)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
              boxShadow: [BoxShadow(color: _moodColor.withOpacity(0.3), blurRadius: 40, spreadRadius: 4)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              // Title bar
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_moodColor.withOpacity(0.28), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(36), topRight: Radius.circular(36))),
                child: Row(children: [
                  _AvatarRing(gif: widget.char.gif, emoji: widget.char.emoji, color: widget.char.color, size: 44),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('🎬 ${widget.char.name}\'s Story Movie',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Row(children: [
                      _Tag(label: '${widget.world.emoji} ${widget.world.name}', color: Colors.white.withOpacity(0.16)),
                      const SizedBox(width: 5),
                      _Tag(label: '$_moodEmoji ${widget.mood}', color: _moodColor.withOpacity(0.32)),
                    ]),
                  ])),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 18))),
                ]),
              ),

              // Video player
              Container(
                height: 240,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(children: [
                    WebViewWidget(controller: _webCtrl),
                    if (_loading) Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 12),
                      Text('Loading video...', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                    ])),
                  ]),
                ),
              ),

              // Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                child: Row(children: [
                  Expanded(child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.5), size: 14),
                      const SizedBox(width: 6),
                      Text('Tap video to play / pause',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  )),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_moodColor, _moodColor.withOpacity(0.75)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: _moodColor.withOpacity(0.4), blurRadius: 12)],
                      ),
                      child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13))),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════
class _AvatarRing extends StatelessWidget {
  final String gif, emoji; final Color color; final double size;
  const _AvatarRing({required this.gif, required this.emoji, required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(shape: BoxShape.circle,
      gradient: LinearGradient(colors: [color, color.withOpacity(0.55)]),
      boxShadow: [BoxShadow(color: color.withOpacity(0.42), blurRadius: 11)]),
    child: ClipRRect(borderRadius: BorderRadius.circular(size),
      child: Image.asset(gif, height: size, width: size, fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text(emoji, style: TextStyle(fontSize: size * 0.55)))),
  );
}

class _Tag extends StatelessWidget {
  final String label; final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}

class _BottomBtn extends StatelessWidget {
  final String label; final VoidCallback? onTap;
  final bool highlight; final Color? color;
  const _BottomBtn({required this.label, required this.onTap, this.highlight = false, this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: highlight && color != null && onTap != null
            ? LinearGradient(colors: [color!, color!.withOpacity(0.75)])
            : null,
        color: highlight && color != null && onTap != null ? null : Colors.white.withOpacity(onTap != null ? 0.11 : 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(onTap != null ? 0.18 : 0.07)),
        boxShadow: highlight && onTap != null ? [BoxShadow(color: color!.withOpacity(0.35), blurRadius: 10)] : [],
      ),
      child: Text(label, textAlign: TextAlign.center,
        style: TextStyle(color: onTap != null ? Colors.white : Colors.white38,
          fontSize: 12, fontWeight: FontWeight.w700)),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════
//  FLOATING PARTICLE SYSTEM
// ═══════════════════════════════════════════════════════════════════
class _Particle {
  final double x, y, size, speed, delay, drift;
  final String emoji;
  const _Particle({required this.x, required this.y, required this.size,
    required this.speed, required this.emoji, required this.delay, required this.drift});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> ps; final double t;
  _ParticlePainter(this.ps, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final p in ps) {
      final phase = (t * p.speed + p.delay) % 1.0;
      final y   = size.height * (1.0 - phase);
      final x   = size.width  * p.x + sin(phase * pi * 2 + p.delay * pi) * size.width * 0.06 + p.drift * size.width * phase;
      final opa = phase < 0.12 ? phase / 0.12 : (phase > 0.88 ? (1 - phase) / 0.12 : 1.0);
      tp.text = TextSpan(text: p.emoji, style: TextStyle(fontSize: p.size, color: Colors.white.withOpacity(opa * 0.28)));
      tp.layout();
      tp.paint(canvas, Offset(x, y));
    }
  }

  @override bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}

// ═══════════════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════════════
class Character {
  final String name, gif, sound, emoji;
  final Color color, light;
  const Character({required this.name, required this.gif, required this.sound,
    required this.emoji, required this.color, required this.light});
}

class StoryWorld {
  final String name, gif, emoji, desc;
  final Color color, light, bg;
  const StoryWorld({required this.name, required this.gif, required this.emoji,
    required this.color, required this.light, required this.desc, required this.bg});
}

class Mood {
  final String name, emoji;
  final Color color, bg;
  const Mood({required this.name, required this.emoji, required this.color, required this.bg});
}