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

import '../../../providers/user_provider.dart';

// ──────────────────────────────────────────────────────────────
//  COLOUR PALETTE
// ──────────────────────────────────────────────────────────────
class K {
  K._();
  static const bg      = Color(0xFFFFF7ED);
  static const surface = Color(0xFFFFFFFF);
  static const ink     = Color(0xFF12072A);
  static const red     = Color(0xFFFF2D55);
  static const orange  = Color(0xFFFF8000);
  static const yellow  = Color(0xFFFFCC00);
  static const lime    = Color(0xFF2DEB6F);
  static const cyan    = Color(0xFF00CFFF);
  static const blue    = Color(0xFF1B6FFF);
  static const purple  = Color(0xFF8B2FFF);
  static const pink    = Color(0xFFFF3DA6);
  static const mint    = Color(0xFF00E5C3);
  static const white   = Color(0xFFFFFFFF);

  static const rainbow = [red, orange, yellow, lime, cyan, blue, purple, pink];

  static const panels = <List<Color>>[
    [Color(0xFFFFFADD), yellow],
    [Color(0xFFFFE8F2), pink],
    [Color(0xFFE3F0FF), blue],
    [Color(0xFFE6FFF2), lime],
    [Color(0xFFF3E8FF), purple],
    [Color(0xFFFFEFE0), orange],
  ];

  static const zapLabels = ['⚡ ZAP!','💥 POW!','🌟 WOW!','🔥 HOT!','✨ BAM!','💫 YAY!'];
  static const zapCols   = [yellow, red, cyan, orange, purple, lime];

  static Color panelAccent(int i) => panels[i % panels.length][1] as Color;
}

// ──────────────────────────────────────────────────────────────
//  TEXT STYLES
// ──────────────────────────────────────────────────────────────
TextStyle ts(double sz, Color c,
    {FontWeight fw = FontWeight.w700, double h = 1.35, List<Shadow>? sh}) =>
    TextStyle(fontFamily: 'Comic Sans MS', fontSize: sz, color: c,
        fontWeight: fw, height: h, shadows: sh);

TextStyle tb(double sz, Color c,
    {FontWeight fw = FontWeight.w500, double h = 1.5}) =>
    TextStyle(fontFamily: 'Comic Sans MS', fontSize: sz, color: c,
        fontWeight: fw, height: h);

// ──────────────────────────────────────────────────────────────
//  CONFETTI
// ──────────────────────────────────────────────────────────────
class _Piece {
  double x, y, vx, vy, r, rot, rotV, life;
  Color color;
  int shape;
  _Piece(Random rng, double w)
      : x = rng.nextDouble() * w, y = -16,
        vx = (rng.nextDouble() - .5) * 10,
        vy = rng.nextDouble() * 5 + 2,
        r  = rng.nextDouble() * 9 + 4,
        rot  = rng.nextDouble() * pi * 2,
        rotV = (rng.nextDouble() - .5) * .24,
        life  = 1.0,
        color = K.rainbow[rng.nextInt(K.rainbow.length)],
        shape = rng.nextInt(4);
  void tick() { x += vx; y += vy; vy += .26; rot += rotV; life -= .007; }
}

class _ConfPainter extends CustomPainter {
  final List<_Piece> ps;
  _ConfPainter(this.ps);
  @override void paint(Canvas c, Size s) {
    for (final d in ps) {
      if (d.life <= 0) continue;
      final pt = Paint()..color = d.color.withOpacity(d.life.clamp(0, 1));
      c.save(); c.translate(d.x, d.y); c.rotate(d.rot);
      switch (d.shape) {
        case 0: c.drawCircle(Offset.zero, d.r, pt); break;
        case 1: c.drawRect(Rect.fromCenter(center: Offset.zero, width: d.r * 2, height: d.r * 1.2), pt); break;
        case 2: _star(c, pt, d.r); break;
        case 3: c.drawPath(Path()..moveTo(0, -d.r)..lineTo(d.r * .87, d.r * .5)..lineTo(-d.r * .87, d.r * .5)..close(), pt); break;
      }
      c.restore();
    }
  }
  static void _star(Canvas c, Paint p, double r) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final a = i * pi / 5 - pi / 2, rad = i.isEven ? r : r * .38;
      i == 0 ? path.moveTo(cos(a) * rad, sin(a) * rad) : path.lineTo(cos(a) * rad, sin(a) * rad);
    }
    path.close(); c.drawPath(path, p);
  }
  @override bool shouldRepaint(_ConfPainter o) => true;
}

// ──────────────────────────────────────────────────────────────
//  FLOATING DOODLES
// ──────────────────────────────────────────────────────────────
class _Doodle {
  double x, y, size, speed, angle, phase; Color color; int type;
  _Doodle(Random rng, double w, double h)
      : x = rng.nextDouble() * w, y = rng.nextDouble() * h,
        size  = rng.nextDouble() * 18 + 8,
        speed = rng.nextDouble() * .55 + .15,
        angle = rng.nextDouble() * pi * 2,
        phase = rng.nextDouble() * pi * 2,
        color = K.rainbow[rng.nextInt(K.rainbow.length)].withOpacity(.13),
        type  = rng.nextInt(5);
}

class _DoodlePainter extends CustomPainter {
  final List<_Doodle> ds; final double t;
  _DoodlePainter(this.ds, this.t);
  @override void paint(Canvas canvas, Size size) {
    for (final d in ds) {
      final ox = sin(t * .9 + d.phase) * 7;
      canvas.save(); canvas.translate(d.x + ox, d.y); canvas.rotate(d.angle + t * .22);
      final fp = Paint()..color = d.color..style = PaintingStyle.fill;
      final sp = Paint()..color = d.color..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round;
      switch (d.type) {
        case 0: _star(canvas, fp, d.size / 2); break;
        case 1: _heart(canvas, fp, d.size / 2); break;
        case 2: canvas.drawCircle(Offset.zero, d.size / 2, sp); break;
        case 3: _zz(canvas, sp, d.size); break;
        case 4: _spark(canvas, sp, d.size / 2); break;
      }
      canvas.restore();
    }
  }
  static void _star(Canvas c, Paint p, double r) { final path = Path(); for (int i = 0; i < 10; i++) { final a = i * pi / 5 - pi / 2, rad = i.isEven ? r : r * .4; i == 0 ? path.moveTo(cos(a) * rad, sin(a) * rad) : path.lineTo(cos(a) * rad, sin(a) * rad); } path.close(); c.drawPath(path, p); }
  static void _heart(Canvas c, Paint p, double r) { c.drawPath(Path()..moveTo(0, r * .3)..cubicTo(-r, -r * .4, -r * 1.6, r * .5, 0, r * 1.2)..cubicTo(r * 1.6, r * .5, r, -r * .4, 0, r * .3)..close(), p); }
  static void _zz(Canvas c, Paint sp, double s) { final path = Path()..moveTo(-s / 2, 0); for (int i = 0; i <= 4; i++) path.lineTo(-s / 2 + s * i / 4, i.isEven ? -s / 3 : s / 3); c.drawPath(path, sp); }
  static void _spark(Canvas c, Paint sp, double r) { for (int i = 0; i < 6; i++) { final a = i * pi / 3; c.drawLine(Offset.zero, Offset(cos(a) * r, sin(a) * r), sp); } }
  @override bool shouldRepaint(_DoodlePainter o) => true;
}

// ──────────────────────────────────────────────────────────────
//  HALFTONE TEXTURE
// ──────────────────────────────────────────────────────────────
class _HalftonePainter extends CustomPainter {
  final Color color; final double spacing;
  _HalftonePainter(this.color, {this.spacing = 18});
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final cols = (size.width / spacing).ceil() + 1, rows = (size.height / spacing).ceil() + 1;
    for (int r = 0; r < rows; r++) for (int c = 0; c < cols; c++) {
      final ox = r.isOdd ? spacing / 2 : 0.0;
      canvas.drawCircle(Offset(c * spacing + ox, r * spacing), spacing * .16, p);
    }
  }
  @override bool shouldRepaint(_HalftonePainter o) => false;
}

// ──────────────────────────────────────────────────────────────
//  WOBBLY INK BORDER
// ──────────────────────────────────────────────────────────────
class _WobblePainter extends CustomPainter {
  final Color color; final double sw; final Random _rng;
  _WobblePainter(this.color, this.sw, int seed) : _rng = Random(seed);
  @override void paint(Canvas canvas, Size sz) {
    final paint = Paint()..color = color..strokeWidth = sw..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    const seg = 50, pad = 10.0, w2 = 3.5; final W = sz.width, H = sz.height;
    final path = Path();
    path.moveTo(pad, _rng.nextDouble() * w2);
    for (int i = 1; i <= seg; i++) path.lineTo(pad + (W - pad * 2) * i / seg, _rng.nextDouble() * w2);
    for (int i = 1; i <= seg; i++) path.lineTo(W - _rng.nextDouble() * w2, pad + (H - pad * 2) * i / seg);
    for (int i = seg; i >= 0; i--) path.lineTo(pad + (W - pad * 2) * i / seg, H - _rng.nextDouble() * w2);
    for (int i = seg; i >= 0; i--) path.lineTo(_rng.nextDouble() * w2, pad + (H - pad * 2) * i / seg);
    path.close(); canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(_WobblePainter o) => false;
}

// ──────────────────────────────────────────────────────────────
//  SPEECH BUBBLE
// ──────────────────────────────────────────────────────────────
class _BubblePainter extends CustomPainter {
  final Color fill, stroke;
  _BubblePainter({required this.fill, required this.stroke});
  @override void paint(Canvas canvas, Size sz) {
    const r = 18.0, tail = 22.0, tw = 24.0; final W = sz.width, H = sz.height;
    final bg = Paint()..color = fill;
    final sp = Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = 3.0..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(r, 0)..lineTo(W - r, 0)..quadraticBezierTo(W, 0, W, r)
      ..lineTo(W, H - tail - r)..quadraticBezierTo(W, H - tail, W - r, H - tail)
      ..lineTo(r + tw + 14, H - tail)..lineTo(r + 5, H)..lineTo(r + tw - 5, H - tail)
      ..lineTo(r, H - tail)..quadraticBezierTo(0, H - tail, 0, H - tail - r)
      ..lineTo(0, r)..quadraticBezierTo(0, 0, r, 0)..close();
    canvas.drawPath(path, bg); canvas.drawPath(path, sp);
  }
  @override bool shouldRepaint(_BubblePainter o) => false;
}

// ──────────────────────────────────────────────────────────────
//  BURST / STARBURST
// ──────────────────────────────────────────────────────────────
class _BurstPainter extends CustomPainter {
  final Color fill, stroke; final int spikes;
  _BurstPainter({required this.fill, required this.stroke, this.spikes = 14});
  @override void paint(Canvas canvas, Size sz) {
    final cx = sz.width / 2, cy = sz.height / 2, r = min(cx, cy) * .94, ri = r * .60;
    final bg = Paint()..color = fill;
    final sp = Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = 3.5..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (int i = 0; i < spikes * 2; i++) {
      final a = i * pi / spikes - pi / 2, rad = i.isEven ? r : ri;
      final o = Offset(cx + cos(a) * rad, cy + sin(a) * rad);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    path.close(); canvas.drawPath(path, bg); canvas.drawPath(path, sp);
  }
  @override bool shouldRepaint(_BurstPainter o) => false;
}

// ──────────────────────────────────────────────────────────────
//  RAINBOW PROGRESS BAR
// ──────────────────────────────────────────────────────────────
class _RainbowBar extends StatelessWidget {
  final double value;
  const _RainbowBar(this.value);
  @override Widget build(BuildContext context) {
    return Container(
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: K.ink, width: 2.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft, widthFactor: value.clamp(0, 1),
          child: Container(decoration: const BoxDecoration(gradient: LinearGradient(
              colors: [K.red, K.orange, K.yellow, K.lime, K.cyan, K.blue, K.purple]))),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  MAIN PAGE
// ══════════════════════════════════════════════════════════════
class NewPage extends StatefulWidget {
  static const routeName = '/new-page';
  final String userName;
  const NewPage({Key? key, this.userName = 'Super Reader'}) : super(key: key);
  @override State<NewPage> createState() => _NewPageState();
}

class _NewPageState extends State<NewPage> with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _tts  = FlutterTts();
  final _rng  = Random();
  static const _base = 'http://192.168.100.177:9000';

  // ── Language toggle: 'english' | 'urdu' ──
  String _selectedLanguage = 'english';

  // ── Speech-to-text ──
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening     = false;

  // ── existing controllers ──
  late AnimationController _bounceController;
  late AnimationController _waveController;
  late AnimationController _glowController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController1;
  late AnimationController _sparkleController2;
  late AnimationController _modalController;
  late AnimationController _moodController;
  late AnimationController _moodCardController;

  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _modalScaleAnimation;
  late Animation<double> _modalFadeAnimation;
  late Animation<double> _moodScaleAnimation;
  late Animation<double> _moodFadeAnimation;
  late Animation<double> _moodCardScaleAnimation;

  // ── video button controllers ──
  late AnimationController _videoBtnShineCtrl;
  late AnimationController _videoBtnPulseCtrl;
  late AnimationController _videoBtnStarCtrl;
  late AnimationController _videoBtnLoadingCtrl;
  late AnimationController _videoBtnReadyCtrl;
  late Animation<double>   _videoBtnShineAnim;
  late Animation<double>   _videoBtnPulseAnim;
  late Animation<double>   _videoBtnStarAnim;
  late Animation<double>   _videoBtnLoadingAnim;
  late Animation<double>   _videoBtnReadyAnim;

  // ── video player ──
  VideoPlayerController? _videoController;
  ChewieController?      _chewieController;
  bool _videoInitialized = false;
  bool _videoError       = false;

  // app state
  String _story = ''; List _panels = []; double _pct = 0;
  bool _loading = false; String _genTime = ''; bool _showComic = false;

  // video state: 'idle' | 'generating' | 'ready' | 'error'
  String _videoState = 'idle';
  String? _videoUrl;

  // story word reading
  bool _reading = false, _paused = false; int _cw = -1;
  List<String> _words = []; List<int> _starts = [];

  // ── Urdu TTS state ──
  bool _urduReading = false;

  // comic panel storytelling
  bool _comicReading = false; int _comicPanel = 0;

  // confetti
  List<_Piece> _pieces = []; bool _confOn = false;

  // doodles
  List<_Doodle> _doodles = []; double _doodleT = 0;

  // wobble seeds per panel
  List<int> _seeds = [];

  // animations
  late AnimationController _acBounce, _acPulse, _acBg, _acConf,
      _acReveal, _acTitle, _acLoad, _acWiggle;
  late Animation<double> _aBounce, _aPulse, _aReveal, _aTitle, _aWiggle;
  List<AnimationController> _panelACs = [];
  List<Animation<double>>   _panelSc  = [], _panelOp = [];

  late PageController _pageCtrl;

  bool _showVideoOverlay = false;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _waveAnimation  = CurvedAnimation(parent: _waveController, curve: Curves.easeInOut);

    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _floatAnimation  = Tween<double>(begin: -3, end: 3).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnimation  = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _sparkleController1 = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _sparkleController2 = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    _modalController    = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _moodController     = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _moodCardController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _bounceController   = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _modalScaleAnimation = Tween<double>(begin: 0, end: 1).animate(_modalController);
    _modalFadeAnimation  = Tween<double>(begin: 0, end: 1).animate(_modalController);
    _moodScaleAnimation  = Tween<double>(begin: 0, end: 1).animate(_moodController);
    _moodFadeAnimation   = Tween<double>(begin: 0, end: 1).animate(_moodController);
    _moodCardScaleAnimation = Tween<double>(begin: 0, end: 1).animate(_moodCardController);

    _videoBtnShineCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _videoBtnShineAnim = CurvedAnimation(parent: _videoBtnShineCtrl, curve: Curves.easeInOut);

    _videoBtnPulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 850))..repeat(reverse: true);
    _videoBtnPulseAnim = Tween<double>(begin: 1.0, end: 1.07).animate(CurvedAnimation(parent: _videoBtnPulseCtrl, curve: Curves.easeInOut));

    _videoBtnStarCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _videoBtnStarAnim  = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _videoBtnStarCtrl, curve: Curves.easeInOut));

    _videoBtnLoadingCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _videoBtnLoadingAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _videoBtnLoadingCtrl, curve: Curves.linear));

    _videoBtnReadyCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _videoBtnReadyAnim = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _videoBtnReadyCtrl, curve: Curves.elasticOut));

    _setupTts();
    _initSpeech();
    _pageCtrl = PageController();

    _acBounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 430));
    _aBounce  = Tween(begin: 1.0, end: 1.32).animate(CurvedAnimation(parent: _acBounce, curve: Curves.elasticOut));

    _acPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _aPulse  = Tween(begin: 1.0, end: 1.065).animate(CurvedAnimation(parent: _acPulse, curve: Curves.easeInOut));

    _acWiggle = AnimationController(vsync: this, duration: const Duration(milliseconds: 380))..repeat(reverse: true);
    _aWiggle  = Tween(begin: -1.8, end: 1.8).animate(CurvedAnimation(parent: _acWiggle, curve: Curves.easeInOut));

    _acBg = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _acBg.addListener(() {
      _doodleT = _acBg.value * pi * 2;
      for (final d in _doodles) { d.y -= d.speed; d.angle += .007; if (d.y < -40) d.y = MediaQuery.of(context).size.height + 20; }
      if (mounted) setState(() {});
    });

    _acConf = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _acConf.addListener(() { for (final p in _pieces) p.tick(); if (mounted) setState(() {}); });
    _acConf.addStatusListener((s) { if (s == AnimationStatus.completed) setState(() => _confOn = false); });

    _acReveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _aReveal  = CurvedAnimation(parent: _acReveal, curve: Curves.easeOutBack);

    _acTitle = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _aTitle  = Tween(begin: -5.0, end: 5.0).animate(CurvedAnimation(parent: _acTitle, curve: Curves.easeInOut));

    _acLoad = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = MediaQuery.of(context).size;
      setState(() { _doodles = List.generate(26, (_) => _Doodle(_rng, s.width, s.height)); });
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _sparkleController1.dispose();
    _sparkleController2.dispose();
    _modalController.dispose();
    _moodController.dispose();
    _moodCardController.dispose();
    _videoBtnShineCtrl.dispose();
    _videoBtnPulseCtrl.dispose();
    _videoBtnStarCtrl.dispose();
    _videoBtnLoadingCtrl.dispose();
    _videoBtnReadyCtrl.dispose();
    _disposeVideo();
    _ctrl.dispose(); _pageCtrl.dispose();
    _stopRead(reset: true); _stopComicRead(); _tts.stop();
    for (final c in [_acBounce, _acPulse, _acBg, _acConf, _acReveal, _acTitle, _acLoad, _acWiggle]) c.dispose();
    for (final c in _panelACs) c.dispose();
    super.dispose();
  }

  // ── Speech-to-text init ────────────────────────────────────
  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (mounted) setState(() { _isListening = (status == 'listening'); });
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
            if (error.errorMsg != 'error_speech_timeout') {
              _snack('🎙️ ${error.errorMsg}', K.orange);
            }
          }
        },
        debugLogging: false,
      );
    } catch (e) { _speechAvailable = false; }
    if (mounted) setState(() {});
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    if (!_speechAvailable) {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) { if (mounted) setState(() => _isListening = (status == 'listening')); },
        onError: (error) { if (mounted) setState(() => _isListening = false); },
      );
    }
    if (!_speechAvailable) {
      _snack('🎙️ Microphone permission denied.\nGo to App Settings → Permissions → Microphone → Allow.', K.red);
      return;
    }
    setState(() => _isListening = true);
    final bool started = await _speech.listen(
      onResult: (result) {
        if (mounted) setState(() {
          _ctrl.text = result.recognizedWords;
          _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: _ctrl.text.length));
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      cancelOnError: false,
    );
    if (!started && mounted) {
      setState(() => _isListening = false);
      _snack('🎙️ Could not start listening. Try again.', K.orange);
    }
  }

  // ── Video player lifecycle ──────────────────────────────────
  void _disposeVideo() {
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController  = null;
    _videoInitialized = false;
    _videoError       = false;
  }

  Future<void> _initVideoPlayer(String url) async {
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      _videoController = ctrl;
      await ctrl.initialize();
      final double ar = ctrl.value.aspectRatio > 0 ? ctrl.value.aspectRatio : 16 / 9;
      _chewieController = ChewieController(
        videoPlayerController: ctrl,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        aspectRatio: ar,
        materialProgressColors: ChewieProgressColors(
          playedColor:     K.yellow,
          handleColor:     K.orange,
          backgroundColor: Colors.white24,
          bufferedColor:   K.white.withOpacity(.35),
        ),
        placeholder: Container(
          color: const Color(0xFF12005E),
          child: const Center(child: CircularProgressIndicator(color: K.yellow, strokeWidth: 3)),
        ),
        errorBuilder: (_, msg) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, color: K.red, size: 40),
          const SizedBox(height: 8),
          Text(msg, style: ts(12, K.red), textAlign: TextAlign.center),
        ])),
      );
      if (mounted) setState(() { _videoInitialized = true; _videoError = false; });
    } catch (e) {
      if (mounted) setState(() { _videoError = true; _videoInitialized = false; });
    }
  }

  // ── TTS ──
  void _setupTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(.42);
    await _tts.setPitch(1.25);
  }

  // ── Story word reading ──
  void _prepWords() {
    _words = _story.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    _starts = []; int pos = 0;
    for (int i = 0; i < _words.length; i++) { _starts.add(pos); pos += _words[i].length + (i < _words.length - 1 ? 1 : 0); }
  }

  void _startRead() async {
    if (_story.isEmpty || (_reading && !_paused)) return;
    if (_words.isEmpty) _prepWords();
    if (_cw < 0 || !_paused) _cw = 0;
    if (_cw >= _words.length) _cw = 0;
    setState(() { _reading = true; _paused = false; _urduReading = false; });
    await _tts.setLanguage('en-US');
    _tts.setProgressHandler((_, start, __, ___) {
      if (!_reading || _paused) return;
      final idx = _wordAt(start);
      if (idx != -1 && idx != _cw) { setState(() => _cw = idx); _acBounce..reset()..forward(); }
    });
    _tts.setCompletionHandler(() { if (!_paused) _stopRead(reset: true); });
    await _tts.speak(_story.substring(_starts[_cw]));
  }

  // ── Urdu TTS ──
  Future<void> _startUrduRead() async {
    if (_story.isEmpty) return;
    if (_urduReading) {
      await _tts.stop();
      if (mounted) setState(() => _urduReading = false);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(.42);
      await _tts.setPitch(1.25);
      return;
    }
    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 150));
    _stopRead(reset: true);
    final dynamic langs = await _tts.getLanguages;
    final List<String> available = (langs as List).map((e) => e.toString().toLowerCase()).toList();
    final bool urduOk = available.any((l) => l.contains('ur'));
    if (!urduOk) {
      _snack('🇵🇰 Urdu TTS not found.\nGo to: Settings → Accessibility → TTS Output → Install Urdu', K.orange);
      return;
    }
    await _tts.setLanguage('ur-PK');
    await _tts.setSpeechRate(.36);
    await _tts.setPitch(1.05);
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() => _urduReading = true);
    _tts.setCompletionHandler(() async {
      if (mounted) setState(() => _urduReading = false);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(.42);
      await _tts.setPitch(1.25);
    });
    _tts.setErrorHandler((msg) async {
      if (mounted) setState(() => _urduReading = false);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(.42);
      await _tts.setPitch(1.25);
      _snack('🎙️ TTS error: $msg', K.red);
    });
    await _tts.speak(_story);
  }

  int _wordAt(int pos) {
    for (int i = 0; i < _starts.length; i++) {
      final end = i < _starts.length - 1 ? _starts[i + 1] - 1 : _story.length;
      if (pos >= _starts[i] && pos <= end) return i;
    }
    return -1;
  }

  void _pauseRead() { if (!_reading || _paused) return; _tts.stop(); setState(() { _paused = true; _reading = false; }); }
  void _stopRead({bool reset = false}) {
    _tts.stop(); setState(() {
      _reading = false; _paused = false; _urduReading = false;
      if (reset) { _cw = -1; _words = []; _starts = []; }
    });
  }

  // ── Comic storytelling ──
  void _startComicRead() async {
    if (_panels.isEmpty) return;
    setState(() { _comicReading = true; _comicPanel = 0; });
    if (_pageCtrl.hasClients) await _pageCtrl.animateToPage(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    _readPanel(0);
  }

  void _readPanel(int idx) async {
    if (!_comicReading || idx >= _panels.length) { _stopComicRead(); return; }
    setState(() => _comicPanel = idx);
    if (_pageCtrl.hasClients) {
      await _pageCtrl.animateToPage(idx, duration: const Duration(milliseconds: 650), curve: Curves.easeInOutCubic);
    }
    final panel = _panels[idx];
    final text  = '${panel['title'] ?? ''}. ${panel['description'] ?? ''}';
    _tts.setCompletionHandler(() { if (_comicReading) _readPanel(idx + 1); });
    await _tts.speak(text);
  }

  void _stopComicRead() { _tts.stop(); setState(() => _comicReading = false); }

  // ── Confetti ──
  void _burst() {
    final w = MediaQuery.of(context).size.width;
    _pieces = List.generate(130, (_) => _Piece(_rng, w));
    setState(() => _confOn = true);
    _acConf..reset()..forward();
  }

  // ── Panel animations ──
  void _setupPanelAnims(int n) {
    for (final c in _panelACs) c.dispose();
    _panelACs = List.generate(n, (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 620)));
    _panelSc  = _panelACs.map((c) => Tween(begin: .4, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.elasticOut))).toList();
    _panelOp  = _panelACs.map((c) => Tween(begin: .0, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeIn))).toList();
  }

  void _animPanels() async {
    for (int i = 0; i < _panelACs.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 200));
      if (mounted) _panelACs[i].forward(from: 0);
    }
  }

  void _toggle() {
    setState(() => _showComic = !_showComic);
    if (_showComic) { _acReveal.forward(from: 0); Future.delayed(const Duration(milliseconds: 300), _animPanels); }
    else { _acReveal.reverse(); _stopComicRead(); }
  }

  // ── GENERATE ──
  Future<void> _generate() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty) { _snack('✏️ Type a story idea first!', K.orange); return; }
    _stopRead(reset: true); _stopComicRead();
    _disposeVideo();
    setState(() {
      _loading = true; _story = ''; _panels = []; _pct = 0; _genTime = '';
      _showComic = false; _seeds = [];
      _videoState = 'generating';
      _videoUrl   = null;
      _showVideoOverlay = false;
    });
    _acReveal.reset();

    try {
      // ── Pass language param to the server ──
      final url = '$_base/generate-story-comic-stream'
          '?prompt=${Uri.encodeComponent(prompt)}'
          '&language=$_selectedLanguage';

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
              if (data['story'] != null) { _story = data['story']; _words = []; _starts = []; _cw = -1; }
              if (data['panels'] != null) {
                _panels = List.from(data['panels']);
                _seeds  = List.generate(_panels.length, (i) => i * 137 + 91);
                _setupPanelAnims(_panels.length);
              }
              if (data['panelIndex'] != null && data['image'] != null) {
                final idx = data['panelIndex'] as int;
                if (idx < _panels.length) {
                  _panels[idx] = Map<String, dynamic>.from(_panels[idx])..['image'] = data['image'];
                  precacheImage(CachedNetworkImageProvider(data['image'] as String), context);
                }
              }
              if (data['step'] == 'done') {
                _loading  = false;
                _genTime  = data['generationTime'] ?? '';
                final vUrl = data['videoUrl'];
                if (vUrl != null && (vUrl as String).isNotEmpty) {
                  _videoUrl   = vUrl;
                  _videoState = 'ready';
                  _videoBtnReadyCtrl.forward(from: 0);
                  _initVideoPlayer(vUrl);
                } else {
                  _videoState = 'idle';
                }
                _burst();
              }
            });
          } catch (_) {}
        }
      }, onError: (_) {
        setState(() { _loading = false; _videoState = 'error'; });
      });
    } catch (_) {
      setState(() { _loading = false; _videoState = 'idle'; });
      _snack('❌ Oops! Something went wrong.', K.red);
    }
  }

  void _snack(String msg, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: ts(15, K.white)),
      backgroundColor: c, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final user         = Provider.of<UserProvider>(context).user;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth  = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: K.bg,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _HalftonePainter(K.ink.withOpacity(.033)))),
          if (_doodles.isNotEmpty)
            Positioned.fill(child: CustomPaint(painter: _DoodlePainter(_doodles, _doodleT))),

          SafeArea(
            child: Column(
              children: [
                // ── ANIMATED HEADER ──
                Stack(children: [
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) => Container(
                      height: screenHeight * 0.19,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(const Color(0xFF667EEA), const Color(0xFF764BA2), _waveAnimation.value)!,
                            Color.lerp(const Color(0xFF764BA2), const Color(0xFFF093FB), _waveAnimation.value)!,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
                      ),
                    ),
                  ),
                  Positioned(top: -20, right: -20,
                    child: AnimatedBuilder(animation: _pulseController, builder: (context, child) =>
                      Container(
                        width: 80 + _pulseController.value * 15,
                        height: 80 + _pulseController.value * 15,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                      ))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        AnimatedBuilder(animation: _floatController, builder: (context, child) =>
                          Transform.translate(offset: Offset(0, _floatAnimation.value),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                child: AnimatedBuilder(animation: _sparkleController1, builder: (context, child) =>
                                  Transform.scale(scale: 0.9 + (_sparkleController1.value * 0.2),
                                    child: Container(
                                      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 10, spreadRadius: 1)]),
                                      child: Image.asset("assets/images/logo.png", width: 30, height: 30),
                                    ))),
                              ),
                              const SizedBox(width: 8),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                                Text("MAGIC STORY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white)),
                                Text("Adventure Awaits!", style: TextStyle(fontSize: 9, color: Colors.white70)),
                              ]),
                            ]))),
                        AnimatedBuilder(animation: _glowAnimation, builder: (context, child) =>
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                            child: Row(children: [
                              Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.person, color: Color(0xFF667EEA), size: 12)),
                              const SizedBox(width: 6),
                              Text(user.name.split(" ")[0], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Colors.yellow, size: 10),
                            ]),
                          )),
                      ]),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(25)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.auto_awesome, color: Colors.yellow, size: 14),
                          const SizedBox(width: 8),
                          Expanded(child: Text("Create Magic Story",
                            style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center)),
                        ]),
                      ),
                    ]),
                  ),
                ]),

                // ── SCROLLABLE BODY ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 14),
                        _inputCard(),
                        const SizedBox(height: 14),
                        // ── LANGUAGE TOGGLE ──
                        _languageToggle(),
                        const SizedBox(height: 14),
                        _genBtn(),
                        const SizedBox(height: 14),
                        _videoBtn(),

                        if (_loading) ...[const SizedBox(height: 14), _progressCard()],

                        if (_videoState == 'ready' && _videoUrl != null) ...[
                          const SizedBox(height: 18),
                          _videoCard(),
                        ],

                        if (_story.isNotEmpty) ...[const SizedBox(height: 18), _storySection()],

                        if (_panels.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _toggleBtn(),
                          _comicSection(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_confOn)
            Positioned.fill(child: IgnorePointer(
              child: CustomPaint(painter: _ConfPainter(_pieces), size: MediaQuery.of(context).size),
            )),

          if (_showVideoOverlay && _videoUrl != null)
            _videoOverlay(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  🌐  LANGUAGE TOGGLE BUTTON
  // ════════════════════════════════════════════════════════
  Widget _languageToggle() {
    final bool isEnglish = _selectedLanguage == 'english';

    return Container(
      decoration: BoxDecoration(
        color: K.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: K.ink, width: 3.5),
        boxShadow: const [BoxShadow(color: K.ink, offset: Offset(5, 5), blurRadius: 0)],
      ),
      padding: const EdgeInsets.all(5),
      child: Row(children: [
        // ── English Option ──
        Expanded(
          child: GestureDetector(
            onTap: _loading ? null : () => setState(() => _selectedLanguage = 'english'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: isEnglish ? K.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(17),
                border: isEnglish ? Border.all(color: K.ink, width: 2.5) : null,
                boxShadow: isEnglish
                    ? const [BoxShadow(color: K.ink, offset: Offset(3, 3), blurRadius: 0)]
                    : null,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('🇺🇸', style: TextStyle(fontSize: isEnglish ? 22 : 18)),
                const SizedBox(width: 8),
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('English',
                    style: ts(14, isEnglish ? K.white : K.ink.withOpacity(.55),
                      fw: isEnglish ? FontWeight.w900 : FontWeight.w600)),
                  Text('Video in English',
                    style: tb(9, isEnglish ? K.white.withOpacity(.8) : K.ink.withOpacity(.35),
                      fw: FontWeight.w500)),
                ]),
                if (isEnglish) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: K.white.withOpacity(.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('ON', style: ts(9, K.yellow)),
                  ),
                ],
              ]),
            ),
          ),
        ),
        const SizedBox(width: 5),
        // ── Urdu Option ──
        Expanded(
          child: GestureDetector(
            onTap: _loading ? null : () => setState(() => _selectedLanguage = 'urdu'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: !isEnglish ? K.purple : Colors.transparent,
                borderRadius: BorderRadius.circular(17),
                border: !isEnglish ? Border.all(color: K.ink, width: 2.5) : null,
                boxShadow: !isEnglish
                    ? const [BoxShadow(color: K.ink, offset: Offset(3, 3), blurRadius: 0)]
                    : null,
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('🇵🇰', style: TextStyle(fontSize: !isEnglish ? 22 : 18)),
                const SizedBox(width: 8),
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('اردو',
                    style: ts(14, !isEnglish ? K.white : K.ink.withOpacity(.55),
                      fw: !isEnglish ? FontWeight.w900 : FontWeight.w600)),
                  Text('Roman Urdu voice',
                    style: tb(9, !isEnglish ? K.white.withOpacity(.8) : K.ink.withOpacity(.35),
                      fw: FontWeight.w500)),
                ]),
                if (!isEnglish) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: K.white.withOpacity(.22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('ON', style: ts(9, K.yellow)),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════
  //  🎬  VIDEO BUTTON
  // ════════════════════════════════════════════════════════
  Widget _videoBtn() {
    final bool isReady      = _videoState == 'ready';
    final bool isGenerating = _videoState == 'generating';
    final bool isUrdu       = _selectedLanguage == 'urdu';

    return AnimatedBuilder(
      animation: Listenable.merge([
        _videoBtnPulseAnim, _videoBtnShineAnim,
        _videoBtnStarAnim,  _videoBtnLoadingAnim,
        _videoBtnReadyAnim,
      ]),
      builder: (context, child) {
        double scale = isReady ? _videoBtnPulseAnim.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: isReady ? () => setState(() => _showVideoOverlay = true) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 72,
              decoration: BoxDecoration(
                gradient: isReady
                    ? const LinearGradient(
                        colors: [Color(0xFF6200EA), Color(0xFFAA00FF), Color(0xFFFFD600)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : isGenerating
                        ? const LinearGradient(colors: [Color(0xFF2D0060), Color(0xFF4A0080)])
                        : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isReady ? K.ink : isGenerating ? const Color(0xFF7B00FF) : Colors.grey.shade400,
                  width: 3.5,
                ),
                boxShadow: isReady
                    ? const [
                        BoxShadow(color: K.ink, offset: Offset(5, 5), blurRadius: 0),
                        BoxShadow(color: Color(0x55AA00FF), blurRadius: 22, offset: Offset(0, 8)),
                      ]
                    : isGenerating
                        ? [BoxShadow(color: const Color(0xFF7B00FF).withOpacity(.35), blurRadius: 16)]
                        : [],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(alignment: Alignment.center, children: [
                if (isReady)
                  Positioned.fill(child: Container(
                    decoration: BoxDecoration(gradient: LinearGradient(
                      begin: Alignment(_videoBtnShineAnim.value * 2 - 1, -0.5),
                      end:   Alignment(_videoBtnShineAnim.value * 2,      0.5),
                      colors: [Colors.transparent, Colors.white.withOpacity(0.18), Colors.transparent],
                    )),
                  )),
                if (isReady)
                  Positioned(left: 16, child: Transform.scale(
                    scale: _videoBtnStarAnim.value,
                    child: const Text('⭐', style: TextStyle(fontSize: 20)),
                  )),
                if (isReady)
                  Positioned(right: 16, child: Transform.scale(
                    scale: 1.0 - (_videoBtnStarAnim.value - 0.7),
                    child: const Text('🌟', style: TextStyle(fontSize: 20)),
                  )),
                if (isGenerating)
                  Positioned(left: 16, child: Transform.rotate(
                    angle: _videoBtnLoadingAnim.value * 2 * pi,
                    child: const Text('🎬', style: TextStyle(fontSize: 26)),
                  )),
                if (isGenerating)
                  Positioned(right: 14, child: AnimatedBuilder(
                    animation: _acLoad,
                    builder: (_, __) {
                      final dots = '●' * ((_acLoad.value * 3).floor().clamp(1, 3));
                      return Text(dots, style: ts(14, Colors.white.withOpacity(.6)));
                    },
                  )),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (!isGenerating)
                    Text(isReady ? '' : '🎞️', style: const TextStyle(fontSize: 30)),
                  if (!isGenerating) const SizedBox(width: 10),
                  if (isGenerating) const SizedBox(width: 48),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      isReady ? '  WATCH MY Magic Story!'
                          : isGenerating
                              ? (isUrdu ? 'Creating Urdu video...' : 'Creating English video...')
                              : 'MAKE A VIDEO!',
                      style: ts(isGenerating ? 16 : 19, K.white, fw: FontWeight.w900,
                          sh: [const Shadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 4)]),
                    ),
                    Text(
                      isReady
                          ? 'Tap to watch your Magic Story! 🍿'
                          : isGenerating
                              ? (isUrdu ? '🇵🇰 Roman Urdu voiceover magic ✨' : '🇺🇸 English voiceover magic ✨')
                              : 'Create a comic first!',
                      style: tb(11, isReady ? K.white.withOpacity(.88) : Colors.white54),
                    ),
                  ]),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════
  //  📺  VIDEO CARD
  // ════════════════════════════════════════════════════════
  Widget _videoCard() {
    return LayoutBuilder(builder: (context, constraints) {
      final double videoH = constraints.maxWidth * 9 / 16;

      return AnimatedBuilder(
        animation: _videoBtnReadyAnim,
        builder: (_, child) => Transform.scale(scale: _videoBtnReadyAnim.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D003D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: K.ink, width: 3.5),
            boxShadow: const [
              BoxShadow(color: K.ink, offset: Offset(6, 6), blurRadius: 0),
              BoxShadow(color: Color(0x55AA00FF), blurRadius: 24, offset: Offset(0, 10)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6200EA), Color(0xFFAA00FF), Color(0xFFFFD600)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Row(children: [
                AnimatedBuilder(
                  animation: _videoBtnLoadingAnim,
                  builder: (_, __) => Transform.rotate(
                    angle: _videoInitialized ? 0 : _videoBtnLoadingAnim.value * 2 * pi,
                    child: const Text('🎬', style: TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('YOUR MAGIC VIDEO IS READY!', style: ts(13, K.white, fw: FontWeight.w900)),
                  Text(
                    _videoInitialized
                        ? (_selectedLanguage == 'urdu'
                            ? '🇵🇰 Roman Urdu voiceover • Tap play! 🍿'
                            : '🇺🇸 English voiceover • Tap play! 🍿')
                        : _videoError ? '⚠️ Could not load video'
                        : 'Loading video player...',
                    style: tb(10, K.white.withOpacity(.88)),
                  ),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: K.white.withOpacity(.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: K.white, width: 1.5),
                  ),
                  child: Text('✨ NEW', style: ts(9, K.yellow)),
                ),
              ]),
            ),
            SizedBox(
              height: videoH,
              child: _videoInitialized && _chewieController != null
                  ? Chewie(controller: _chewieController!)
                  : Stack(alignment: Alignment.center, children: [
                      Positioned.fill(child: Container(decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF12005E), Color(0xFF4A0080)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                      ))),
                      _FilmStrip(top: 8),
                      _FilmStrip(bottom: 8),
                      _videoError
                          ? Column(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.error_outline_rounded, color: K.red, size: 48),
                              const SizedBox(height: 10),
                              Text('Could not play video', style: ts(14, K.red)),
                              const SizedBox(height: 6),
                              Text('Check your connection', style: tb(11, Colors.white54)),
                            ])
                          : Column(mainAxisSize: MainAxisSize.min, children: [
                              AnimatedBuilder(
                                animation: _videoBtnLoadingAnim,
                                builder: (_, __) => Transform.rotate(
                                  angle: _videoBtnLoadingAnim.value * 2 * pi,
                                  child: const Text('🎞️', style: TextStyle(fontSize: 60, color: Colors.white24)),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const SizedBox(
                                width: 36, height: 36,
                                child: CircularProgressIndicator(color: K.yellow, strokeWidth: 3),
                              ),
                              const SizedBox(height: 12),
                              Text('Preparing your movie...', style: ts(13, K.yellow)),
                            ]),
                    ]),
            ),
            Container(
              color: const Color(0xFF1A0035),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showVideoOverlay = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6200EA), Color(0xFFAA00FF)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: K.yellow, width: 2),
                        boxShadow: const [BoxShadow(color: K.ink, offset: Offset(3, 3), blurRadius: 0)],
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.fullscreen_rounded, color: K.yellow, size: 20),
                        const SizedBox(width: 6),
                        Text('Full Screen', style: ts(13, K.yellow)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _videoInitialized ? () async {
                    await _videoController?.seekTo(Duration.zero);
                    _chewieController?.play();
                  } : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _videoInitialized ? 1.0 : 0.35,
                    child: Container(
                      width: 50, height: 48,
                      decoration: BoxDecoration(
                        color: K.yellow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: K.ink, width: 2.5),
                        boxShadow: const [BoxShadow(color: K.ink, offset: Offset(3, 3), blurRadius: 0)],
                      ),
                      child: const Icon(Icons.replay_rounded, color: K.ink, size: 26),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      );
    });
  }

  // ════════════════════════════════════════════════════════
  //  📽️  FULL-SCREEN VIDEO OVERLAY
  // ════════════════════════════════════════════════════════
  Widget _videoOverlay() {
    return Material(
      color: Colors.black.withOpacity(.96),
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(children: [
              GestureDetector(
                onTap: () => setState(() => _showVideoOverlay = false),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 1.5),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('🎬  Your Magic Video', style: ts(17, K.yellow))),
              // Language badge in overlay
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedLanguage == 'urdu' ? K.purple.withOpacity(.3) : K.blue.withOpacity(.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedLanguage == 'urdu' ? K.purple : K.blue,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _selectedLanguage == 'urdu' ? '🇵🇰 Roman Urdu' : '🇺🇸 English',
                  style: ts(10, K.white),
                ),
              ),
              if (_videoInitialized) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await _videoController?.seekTo(Duration.zero);
                    _chewieController?.play();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: K.yellow.withOpacity(.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: K.yellow, width: 1.5),
                    ),
                    child: const Icon(Icons.replay_rounded, color: K.yellow, size: 22),
                  ),
                ),
              ],
            ]),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: LayoutBuilder(builder: (context, constraints) {
                  final double ar = _videoInitialized && _videoController != null
                      ? _videoController!.value.aspectRatio
                      : 16 / 9;
                  final double maxW = constraints.maxWidth;
                  final double maxH = constraints.maxHeight;
                  double w = maxW;
                  double h = w / ar;
                  if (h > maxH) { h = maxH; w = h * ar; }
                  return Container(
                    width: w, height: h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: K.yellow, width: 3),
                      boxShadow: [BoxShadow(color: K.yellow.withOpacity(.3), blurRadius: 28, spreadRadius: 4)],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _videoInitialized && _chewieController != null
                        ? Chewie(controller: _chewieController!)
                        : Stack(alignment: Alignment.center, children: [
                            Container(decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0D003D), Color(0xFF3D0080)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                            )),
                            _videoError
                                ? Column(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.error_outline_rounded, color: K.red, size: 56),
                                    const SizedBox(height: 14),
                                    Text('Video failed to load', style: ts(16, K.red)),
                                    const SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(.07),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white24),
                                        ),
                                        child: Text(_videoUrl ?? '', style: tb(10, Colors.white54),
                                          maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                      ),
                                    ),
                                  ])
                                : Column(mainAxisSize: MainAxisSize.min, children: [
                                    AnimatedBuilder(
                                      animation: _videoBtnLoadingAnim,
                                      builder: (_, __) => Transform.rotate(
                                        angle: _videoBtnLoadingAnim.value * 2 * pi,
                                        child: const Text('🎞️',
                                            style: TextStyle(fontSize: 80, color: Colors.white24)),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const SizedBox(
                                      width: 40, height: 40,
                                      child: CircularProgressIndicator(color: K.yellow, strokeWidth: 3.5),
                                    ),
                                    const SizedBox(height: 14),
                                    Text('Loading your movie...', style: ts(15, K.yellow)),
                                  ]),
                          ]),
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: GestureDetector(
              onTap: () => setState(() => _showVideoOverlay = false),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6200EA), Color(0xFFAA00FF)]),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: K.yellow, width: 2.5),
                  boxShadow: const [BoxShadow(color: K.ink, offset: Offset(4, 4), blurRadius: 0)],
                ),
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle_outline_rounded, color: K.yellow, size: 22),
                  const SizedBox(width: 8),
                  Text('Done Watching', style: ts(15, K.white)),
                ])),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  INPUT CARD
  // ════════════════════════════════════════════════════════
  Widget _inputCard() {
    return Container(
      decoration: BoxDecoration(
        color: K.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isListening ? K.red : K.ink,
          width: _isListening ? 4.0 : 3.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isListening ? K.red.withOpacity(.35) : K.ink,
            offset: _isListening ? Offset.zero : const Offset(5, 5),
            blurRadius: _isListening ? 18 : 0,
            spreadRadius: _isListening ? 2 : 0,
          ),
        ],
      ),
      child: Row(children: [
        const Padding(padding: EdgeInsets.only(left: 14), child: Text('🌈', style: TextStyle(fontSize: 26))),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          controller: _ctrl, style: tb(16, K.ink, fw: FontWeight.w600),
          decoration: InputDecoration(
            hintText: _isListening ? '🎙️ Listening...' : "What's your story about?",
            hintStyle: tb(15, _isListening ? K.red : Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        )),
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _isListening ? K.red : K.purple.withOpacity(.12),
                shape: BoxShape.circle,
                border: Border.all(color: _isListening ? K.red : K.purple, width: 2.5),
                boxShadow: _isListening
                    ? [BoxShadow(color: K.red.withOpacity(.5), blurRadius: 12, spreadRadius: 2)]
                    : [],
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none_rounded,
                color: _isListening ? K.white : K.purple,
                size: 22,
              ),
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.only(right: 12),
          child: AnimatedBuilder(animation: _aWiggle, builder: (_, __) =>
            Transform.rotate(angle: _aWiggle.value * .06, child: const Text('🎨', style: TextStyle(fontSize: 22))))),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════
  //  GENERATE BUTTON
  // ════════════════════════════════════════════════════════
  Widget _genBtn() {
    return AnimatedBuilder(
      animation: _aPulse,
      builder: (_, child) => Transform.scale(scale: _loading ? 1.0 : _aPulse.value, child: child),
      child: GestureDetector(
        onTap: _loading ? null : _generate,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: _loading ? Colors.grey.shade400 : K.red,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: K.ink, width: 3.5),
            boxShadow: _loading ? [] : const [BoxShadow(color: K.ink, offset: Offset(6, 6), blurRadius: 0)],
          ),
          child: Center(child: Text(
            _loading ? '🎨  Making Magic...' : '🚀  CREATE MY COMIC!',
            style: ts(20, K.white, fw: FontWeight.w900,
                sh: [const Shadow(color: Colors.black26, offset: Offset(1, 2), blurRadius: 4)]),
          )),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  PROGRESS CARD
  // ════════════════════════════════════════════════════════
  Widget _progressCard() {
    final bool isUrdu = _selectedLanguage == 'urdu';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: K.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: K.cyan, width: 3.5),
        boxShadow: const [BoxShadow(color: K.ink, offset: Offset(5, 5), blurRadius: 0)],
      ),
      child: Column(children: [
        AnimatedBuilder(animation: _acLoad, builder: (_, __) {
          final dots = '●' * ((_acLoad.value * 3).floor().clamp(1, 3));
          return Text('✨  ${_pct.toInt()}%  $dots', style: ts(19, K.cyan, fw: FontWeight.w900));
        }),
        const SizedBox(height: 12),
        _RainbowBar(_pct / 100),
        const SizedBox(height: 10),
        Text(
          _pct > 84
              ? (isUrdu ? '🇵🇰 Creating Roman Urdu video...' : '🇺🇸 Creating English video...')
              : 'Brewing your comic adventure...',
          style: tb(13, K.purple, fw: FontWeight.w600),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════
  //  STORY SECTION
  // ════════════════════════════════════════════════════════
  Widget _storySection() {
    final words = _story.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [K.lime, K.cyan], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: K.ink, width: 3.5),
          boxShadow: const [BoxShadow(color: K.ink, offset: Offset(5, 5), blurRadius: 0)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('📖', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Text('STORY TIME!', style: ts(18, K.ink, fw: FontWeight.w900)),
            const Spacer(),
            _ttsBtn(Icons.play_circle_filled, K.ink, (_reading && !_paused) ? null : _startRead),
            const SizedBox(width: 4),
            _ttsBtn(Icons.pause_circle_filled, K.orange, (_reading && !_paused) ? _pauseRead : null),
            const SizedBox(width: 4),
            _ttsBtn(Icons.stop_circle, K.red, () => _stopRead(reset: true)),
          ]),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _startUrduRead,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _urduReading ? K.purple : K.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _urduReading ? K.purple : K.ink, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: _urduReading ? K.purple.withOpacity(.4) : K.ink,
                    offset: _urduReading ? Offset.zero : const Offset(3, 3),
                    blurRadius: _urduReading ? 12 : 0,
                  ),
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_urduReading ? '🔊' : '🇵🇰', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  _urduReading ? 'اردو میں پڑھ رہا ہے...' : 'اردو میں سنیں',
                  style: ts(13, _urduReading ? K.white : K.ink, fw: FontWeight.w800),
                ),
                if (_urduReading) ...[
                  const SizedBox(width: 8),
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: K.yellow, strokeWidth: 2)),
                ],
              ]),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBE8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: K.yellow, width: 3.5),
          boxShadow: const [BoxShadow(color: K.ink, offset: Offset(4, 4), blurRadius: 0)],
        ),
        child: Wrap(spacing: 8, runSpacing: 10,
          children: words.asMap().entries.map((e) {
            final i = e.key, w = e.value;
            final active = (_reading || _paused) && i == _cw;
            Widget chip = AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: active ? 12 : 6, vertical: 6),
              decoration: BoxDecoration(
                color: active ? K.yellow : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: active ? Border.all(color: K.orange, width: 2.5) : null,
                boxShadow: active ? [BoxShadow(color: K.orange.withOpacity(.45), blurRadius: 12, spreadRadius: 1)] : null,
              ),
              child: Text(w, style: tb(active ? 22 : 17, active ? const Color(0xFF5E2000) : K.ink,
                  fw: active ? FontWeight.w800 : FontWeight.w600)),
            );
            if (active) chip = AnimatedBuilder(animation: _aBounce,
              builder: (_, child) => Transform.scale(scale: _aBounce.value, child: child), child: chip);
            return GestureDetector(
              onTap: () { if (_reading || _paused) { setState(() => _cw = i); _stopRead(reset: false); _startRead(); } },
              child: chip,
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _ttsBtn(IconData icon, Color c, VoidCallback? fn) => GestureDetector(
    onTap: fn,
    child: AnimatedOpacity(duration: const Duration(milliseconds: 200), opacity: fn == null ? .28 : 1.0,
      child: Icon(icon, color: c, size: 34)),
  );

  // ════════════════════════════════════════════════════════
  //  TOGGLE COMIC BUTTON
  // ════════════════════════════════════════════════════════
  Widget _toggleBtn() {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _showComic ? K.blue : K.purple,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: K.ink, width: 3.5),
          boxShadow: const [BoxShadow(color: K.ink, offset: Offset(6, 6), blurRadius: 0)],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_showComic ? '🙈  HIDE COMIC' : '🎉  SHOW MY COMIC!',
            style: ts(18, K.white, fw: FontWeight.w900,
                sh: [const Shadow(color: Colors.black26, offset: Offset(1, 2), blurRadius: 4)])),
          const SizedBox(width: 10),
          AnimatedRotation(turns: _showComic ? .5 : 0, duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOut, child: const Icon(Icons.expand_more_rounded, color: K.white, size: 30)),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  COMIC SECTION
  // ════════════════════════════════════════════════════════
  Widget _comicSection() {
    return SizeTransition(
      sizeFactor: _aReveal, axisAlignment: -1,
      child: Column(children: [
        const SizedBox(height: 18),
        _comicHeader(),
        const SizedBox(height: 14),
        _comicControls(),
        const SizedBox(height: 14),
        _panelDots(),
        const SizedBox(height: 10),
        SizedBox(
          height: 500,
          child: PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (idx) => setState(() => _comicPanel = idx),
            itemCount: _panels.length,
            itemBuilder: (_, idx) {
              final panel = Map<String, dynamic>.from(_panels[idx]);
              return _buildPanel(idx, panel);
            },
          ),
        ),
        const SizedBox(height: 14),
        _panelNav(),
        if (_genTime.isNotEmpty) ...[const SizedBox(height: 14), _timeBadge()],
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _comicHeader() {
    return Stack(alignment: Alignment.center, children: [
      SizedBox(height: 110, child: CustomPaint(
        painter: _BurstPainter(fill: K.yellow, stroke: K.ink, spikes: 14),
        size: const Size(double.infinity, 110),
      )),
      Column(children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(colors: [K.red, K.purple]).createShader(b),
          child: Text('💥 POW!  🦸  BAM! 💫', style: ts(23, K.white, fw: FontWeight.w900)),
        ),
        const SizedBox(height: 3),
        Text('YOUR COMIC ADVENTURE!', style: ts(13, K.orange, fw: FontWeight.w900)),
      ]),
    ]);
  }

  Widget _comicControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [K.pink, K.purple], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: K.ink, width: 3),
        boxShadow: const [BoxShadow(color: K.ink, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Row(children: [
        const Text('🎙️', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('COMIC STORY MODE', style: ts(13, K.white, fw: FontWeight.w900)),
          Text(_comicReading ? 'Reading panel ${_comicPanel + 1} of ${_panels.length}...' : 'Tap ▶ to hear the full story!',
            style: tb(11, K.white.withOpacity(.88), fw: FontWeight.w600)),
        ])),
        const SizedBox(width: 10),
        _ctrlBtn(Icons.play_circle_filled_rounded, K.lime, _comicReading ? null : _startComicRead),
        const SizedBox(width: 8),
        _ctrlBtn(Icons.stop_circle_rounded, K.red, _comicReading ? _stopComicRead : null),
      ]),
    );
  }

  Widget _ctrlBtn(IconData icon, Color c, VoidCallback? fn) => GestureDetector(
    onTap: fn,
    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: fn == null ? K.white.withOpacity(.2) : K.white,
        shape: BoxShape.circle,
        border: Border.all(color: K.ink, width: 2.5),
        boxShadow: fn == null ? [] : const [BoxShadow(color: K.ink, offset: Offset(2, 2), blurRadius: 0)],
      ),
      child: Icon(icon, color: fn == null ? K.white.withOpacity(.4) : c, size: 26)),
  );

  Widget _panelDots() {
    return Row(mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_panels.length, (i) {
        final active = i == _comicPanel;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 10, height: 10,
          decoration: BoxDecoration(
            color: active ? K.panelAccent(i) : K.ink.withOpacity(.2),
            borderRadius: BorderRadius.circular(6),
            border: active ? Border.all(color: K.ink, width: 2) : null));
      }));
  }

  Widget _panelNav() {
    return Row(children: [
      _navBtn('◀  PREV', K.blue, _comicPanel > 0 ? () =>
        _pageCtrl.previousPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic) : null),
      const SizedBox(width: 12),
      _navBtn('NEXT  ▶', K.red, _comicPanel < _panels.length - 1 ? () =>
        _pageCtrl.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic) : null),
    ]);
  }

  Widget _navBtn(String label, Color c, VoidCallback? fn) {
    return Expanded(child: GestureDetector(
      onTap: fn,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: fn == null ? Colors.grey.shade300 : c,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: K.ink, width: 3),
          boxShadow: fn == null ? [] : const [BoxShadow(color: K.ink, offset: Offset(4, 4), blurRadius: 0)],
        ),
        child: Center(child: Text(label, style: ts(15, fn == null ? Colors.grey.shade500 : K.white))))));
  }

  // ════════════════════════════════════════════════════════
  //  SINGLE COMIC PANEL
  // ════════════════════════════════════════════════════════
  Widget _buildPanel(int idx, Map<String, dynamic> panel) {
    final palette = K.panels[idx % K.panels.length];
    final bg      = palette[0] as Color;
    final bc      = palette[1] as Color;
    final seed    = idx < _seeds.length ? _seeds[idx] : idx * 137 + 7;
    final active  = idx == _comicPanel && _comicReading;
    final imgUrl  = panel['image'] as String? ?? '';

    Widget card = Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Stack(children: [
        Positioned(left: 7, top: 7, right: 0, bottom: 0, child: Container(
          decoration: BoxDecoration(color: K.ink, borderRadius: BorderRadius.circular(26)))),
        AnimatedContainer(duration: const Duration(milliseconds: 350),
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(26),
            border: Border.all(color: active ? bc : bg, width: 4)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: Stack(children: [
                  _panelImg(imgUrl),
                  Positioned.fill(child: CustomPaint(painter: _HalftonePainter(K.ink.withOpacity(.033)))),
                ]),
              ),
              Positioned(top: 12, left: 12, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: bc, borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: K.white, width: 2.5),
                  boxShadow: const [BoxShadow(color: K.ink, offset: Offset(2, 3), blurRadius: 0)]),
                child: Text('Panel ${idx + 1}', style: ts(12, K.white)))),
              Positioned(top: 10, right: 10, child: Transform.rotate(angle: .22,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(color: K.zapCols[idx % K.zapCols.length],
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: K.ink, width: 2.5),
                    boxShadow: const [BoxShadow(color: K.ink, offset: Offset(2, 2), blurRadius: 0)]),
                  child: Text(K.zapLabels[idx % K.zapLabels.length], style: ts(12, K.white))))),
              if (active) Positioned.fill(child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: AnimatedBuilder(animation: _aPulse,
                  builder: (_, __) => Container(color: bc.withOpacity(_aPulse.value * .13))))),
            ]),
            Padding(padding: const EdgeInsets.fromLTRB(14, 16, 14, 2),
              child: CustomPaint(painter: _BubblePainter(fill: K.white, stroke: bc),
                child: Padding(padding: const EdgeInsets.fromLTRB(16, 13, 16, 30),
                  child: Text(panel['title'] ?? '', style: ts(15, bc, fw: FontWeight.w900))))),
            Padding(padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
              child: Text(panel['description'] ?? '', style: tb(13, K.ink.withOpacity(.8), fw: FontWeight.w600))),
          ])),
        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(26),
          child: CustomPaint(painter: _WobblePainter(bc, 4.4, seed)))),
      ]),
    );

    if (idx < _panelSc.length) {
      card = AnimatedBuilder(
        animation: Listenable.merge([_panelSc[idx], _panelOp[idx]]),
        builder: (_, child) => Opacity(opacity: _panelOp[idx].value,
          child: Transform.scale(scale: _panelSc[idx].value, child: child)),
        child: card,
      );
    }
    return card;
  }

  Widget _panelImg(String url) {
    if (url.isEmpty) return Container(height: 220, color: const Color(0xFFE3EEFF),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(K.blue))));
    return CachedNetworkImage(imageUrl: url, height: 220, width: double.infinity, fit: BoxFit.cover,
      placeholder: (_, __) => Container(height: 220, color: const Color(0xFFE3EEFF),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(K.blue)))),
      errorWidget: (_, __, ___) => Container(height: 220, color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.broken_image, size: 44, color: Colors.grey))),
      fadeInDuration: Duration.zero);
  }

  Widget _timeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: K.surface, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: K.mint, width: 3),
        boxShadow: const [BoxShadow(color: K.ink, offset: Offset(4, 4), blurRadius: 0)],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('⚡', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Text('Done in $_genTime', style: ts(14, K.mint)),
        const SizedBox(width: 10),
        Text(
          _selectedLanguage == 'urdu' ? '🇵🇰 Roman Urdu' : '🇺🇸 English',
          style: ts(12, K.purple),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HELPER WIDGET – reusable film strip rows
// ══════════════════════════════════════════════════════════════
class _FilmStrip extends StatelessWidget {
  final double? top;
  final double? bottom;
  const _FilmStrip({this.top, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(10, (_) => Container(
          width: 24, height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.15),
            borderRadius: BorderRadius.circular(3),
          ),
        )),
      ),
    );
  }
}