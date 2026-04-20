import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

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
  static const _base = 'http://10.40.23.221:9000';


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

  // app state
  String _story = ''; List _panels = []; double _pct = 0;
  bool _loading = false; String _genTime = ''; bool _showComic = false;

  // story word reading
  bool _reading = false, _paused = false; int _cw = -1;
  List<String> _words = []; List<int> _starts = [];

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

  @override
  void initState() {
    super.initState();
    // 🔥 ADD THIS
_waveController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 4),
)..repeat();

_waveAnimation = CurvedAnimation(
  parent: _waveController,
  curve: Curves.easeInOut,
);

_pulseController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 2),
)..repeat(reverse: true);

_floatController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 3),
)..repeat(reverse: true);

_floatAnimation = Tween<double>(begin: -3, end: 3).animate(
  CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
);

_glowController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 2),
)..repeat(reverse: true);

_glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
  CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
);

_sparkleController1 = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 2),
)..repeat(reverse: true);

_sparkleController2 = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 2),
)..repeat(reverse: true);

// Optional (since you declared them)
_modalController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 400),
);

_moodController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 400),
);

_moodCardController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 400),
);
    _setupTts();
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

    _ctrl.dispose(); _pageCtrl.dispose();
    _stopRead(reset: true); _stopComicRead(); _tts.stop();
    for (final c in [_acBounce, _acPulse, _acBg, _acConf, _acReveal, _acTitle, _acLoad, _acWiggle]) c.dispose();
    for (final c in _panelACs) c.dispose();
    super.dispose();

    super.dispose();
  }

  // @override void dispose() {
  //   _ctrl.dispose(); _pageCtrl.dispose();
  //   _stopRead(reset: true); _stopComicRead(); _tts.stop();
  //   for (final c in [_acBounce, _acPulse, _acBg, _acConf, _acReveal, _acTitle, _acLoad, _acWiggle]) c.dispose();
  //   for (final c in _panelACs) c.dispose();
  //   super.dispose();
  // }

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
    setState(() { _reading = true; _paused = false; });
    _tts.setProgressHandler((_, start, __, ___) {
      if (!_reading || _paused) return;
      final idx = _wordAt(start);
      if (idx != -1 && idx != _cw) { setState(() => _cw = idx); _acBounce..reset()..forward(); }
    });
    _tts.setCompletionHandler(() { if (!_paused) _stopRead(reset: true); });
    await _tts.speak(_story.substring(_starts[_cw]));
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
      _reading = false; _paused = false;
      if (reset) { _cw = -1; _words = []; _starts = []; }
    });
  }

  // ── Comic storytelling (panel by panel) ──
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

  // ── Panel entrance animations ──
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

  // ── Generate ──
  Future<void> _generate() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty) { _snack('✏️ Type a story idea first!', K.orange); return; }
    _stopRead(reset: true); _stopComicRead();
    setState(() { _loading = true; _story = ''; _panels = []; _pct = 0; _genTime = ''; _showComic = false; _seeds = []; });
    _acReveal.reset();
    try {
      final req = http.Request('GET', Uri.parse('$_base/generate-story-comic-stream?prompt=$prompt'));
      final res = await req.send();
      res.stream.transform(utf8.decoder).listen((chunk) {
        for (final line in chunk.split('\n')) {
          if (!line.startsWith('data:')) continue;
          final js = line.replaceFirst('data:', '').trim();
          if (js.isEmpty) continue;
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
                _panels[idx]['image'] = data['image'];
                precacheImage(CachedNetworkImageProvider(data['image']), context);
              }
            }
            if (data['step'] == 'done') { _loading = false; _genTime = data['generationTime'] ?? ''; _burst(); }
          });
        }
      });
    } catch (_) { setState(() => _loading = false); _snack('❌ Oops! Something went wrong.', K.red); }
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
  final user = Provider.of<UserProvider>(context).user;

  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  return Scaffold(
    backgroundColor: K.bg,
    resizeToAvoidBottomInset: false,

    body: Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _HalftonePainter(K.ink.withOpacity(.033)),
          ),
        ),

        if (_doodles.isNotEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: _DoodlePainter(_doodles, _doodleT),
            ),
          ),

        SafeArea(
          child: Column(
            children: [

              // ✅ NEW ANIMATED HEADER
              Stack(
                children: [
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return Container(
                        height: screenHeight * 0.19,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(const Color(0xFF667EEA), const Color(0xFF764BA2), _waveAnimation.value)!,
                              Color.lerp(const Color(0xFF764BA2), const Color(0xFFF093FB), _waveAnimation.value)!,
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(35),
                            bottomRight: Radius.circular(35),
                          ),
                        ),
                      );
                    },
                  ),

                  Positioned(
                    top: -20,
                    right: -20,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 80 + _pulseController.value * 15,
                          height: 80 + _pulseController.value * 15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.015,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            // LEFT SIDE
                            AnimatedBuilder(
                              animation: _floatController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatAnimation.value),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: AnimatedBuilder(
  animation: _sparkleController1,
  builder: (context, child) {
    return Transform.scale(
      scale: 0.9 + (_sparkleController1.value * 0.2),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.6),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ],
        ),
        child: Image.asset(
          "assets/images/logo.png",
          width: 30,
          height: 30,
        ),
      ),
    );
  },
),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            "MAGIC STORY",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            "Adventure Awaits!",
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // RIGHT SIDE USER
                            AnimatedBuilder(
                              animation: _glowAnimation,
                              builder: (context, child) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.person, color: Color(0xFF667EEA), size: 12),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        user.name.split(" ")[0],
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified, color: Colors.yellow, size: 10),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.yellow, size: 14),
                              const SizedBox(width: 8),
                              
                              const SizedBox(width: 8),
                            Expanded(
                              child: Text("Create Magic Story",
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),







              // ✅ REST OF YOUR CONTENT (UNCHANGED)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // const SizedBox(height: 14),
        Text('__________________________', style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18,),),
        const SizedBox(height: 14),
                      _inputCard(),
                      const SizedBox(height: 14),
                      _genBtn(),

                      if (_loading) ...[
                        const SizedBox(height: 14),
                        _progressCard(),
                      ],

                      if (_story.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        _storySection(),
                      ],

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
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfPainter(_pieces),
                size: MediaQuery.of(context).size,
              ),
            ),
          ),
      ],
    ),
  );
}
  
  
  // ════════════════════════════════════════════════════════
  //  APP BAR  –  Logo · Name · User Chip
  // ════════════════════════════════════════════════════════
  Widget _appBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: K.surface,
        border: Border(bottom: BorderSide(color: K.ink.withOpacity(.08), width: 2)),
        boxShadow: [BoxShadow(color: K.ink.withOpacity(.07), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // ── Logo mark ──
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [K.purple, K.pink], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: K.ink, width: 2.5),
            boxShadow: const [BoxShadow(color: K.ink, offset: Offset(3, 3), blurRadius: 0)],
          ),
          child: const Center(child: Text('✨', style: TextStyle(fontSize: 24))),
        ),
        const SizedBox(width: 10),
        // ── App name (gently bobbing) ──
        AnimatedBuilder(
          animation: _aTitle,
          builder: (_, child) => Transform.translate(offset: Offset(0, _aTitle.value * .35), child: child),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(colors: [K.purple, K.pink, K.orange]).createShader(b),
              child: Text('Story Magic', style: ts(22, K.white, fw: FontWeight.w900)),
            ),
            Text('Comic Maker', style: tb(11, K.purple, fw: FontWeight.w700)),
          ]),
        ),
        const Spacer(),
        // ── User chip ──
        _userChip(),
      ]),
    );
  }

  Widget _userChip() {
    final initials = widget.userName.trim().split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').take(2).join();
    return GestureDetector(
      onTap: () => _snack('👋 Hi, ${widget.userName}!', K.purple),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [K.cyan, K.blue]),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: K.ink, width: 2.5),
          boxShadow: const [BoxShadow(color: K.ink, offset: Offset(3, 3), blurRadius: 0)],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: K.white, shape: BoxShape.circle, border: Border.all(color: K.ink, width: 2)),
            child: Center(child: Text(initials, style: ts(11, K.blue, fw: FontWeight.w900))),
          ),
          const SizedBox(width: 7),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Hi!', style: ts(9, K.white, fw: FontWeight.w900)),
            Text(widget.userName.split(' ').first, style: tb(10, K.white, fw: FontWeight.w700)),
          ]),
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
        border: Border.all(color: K.ink, width: 3.5),
        boxShadow: const [BoxShadow(color: K.ink, offset: Offset(5, 5), blurRadius: 0)],
      ),
      child: Row(children: [

        const Padding(padding: EdgeInsets.only(left: 14), child: Text('🌈', style: TextStyle(fontSize: 26))),
        const SizedBox(width: 8),
        Expanded(child: TextField(
          controller: _ctrl, style: tb(16, K.ink, fw: FontWeight.w600),
          decoration: InputDecoration(
            hintText: "What's your story about?",
            hintStyle: tb(15, Colors.grey.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        )),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: AnimatedBuilder(
            animation: _aWiggle,
            builder: (_, __) => Transform.rotate(angle: _aWiggle.value * .06,
                child: const Text('🎨', style: TextStyle(fontSize: 22))),
          ),
        ),
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
            style: ts(20, K.white, fw: FontWeight.w900, sh: [const Shadow(color: Colors.black26, offset: Offset(1, 2), blurRadius: 4)]),
          )),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  PROGRESS CARD
  // ════════════════════════════════════════════════════════
  Widget _progressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: K.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: K.cyan, width: 3.5),
        boxShadow: const [BoxShadow(color: K.ink, offset: Offset(5, 5), blurRadius: 0)],
      ),
      child: Column(children: [
        AnimatedBuilder(
          animation: _acLoad,
          builder: (_, __) {
            final dots = '●' * ((_acLoad.value * 3).floor().clamp(1, 3));
            return Text('✨  ${_pct.toInt()}%  $dots', style: ts(19, K.cyan, fw: FontWeight.w900));
          },
        ),
        const SizedBox(height: 12),
        _RainbowBar(_pct / 100),
        const SizedBox(height: 10),
        Text('Brewing your comic adventure...', style: tb(13, K.purple, fw: FontWeight.w600)),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════
  //  STORY SECTION  (animated word highlight + TTS)
  // ════════════════════════════════════════════════════════
  Widget _storySection() {
    final words = _story.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [K.lime, K.cyan], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: K.ink, width: 3.5),
          boxShadow: const [BoxShadow(color: K.ink, offset: Offset(5, 5), blurRadius: 0)],
        ),
        child: Row(children: [
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
      ),
      const SizedBox(height: 12),
      // Word tokens
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
              child: Text(w, style: tb(
                active ? 22 : 17,
                active ? const Color(0xFF5E2000) : K.ink,
                fw: active ? FontWeight.w800 : FontWeight.w600,
              )),
            );
            if (active) {
              chip = AnimatedBuilder(
                animation: _aBounce,
                builder: (_, child) => Transform.scale(scale: _aBounce.value, child: child),
                child: chip,
              );
            }
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
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 200), opacity: fn == null ? .28 : 1.0,
      child: Icon(icon, color: c, size: 34),
    ),
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
          Text(
            _showComic ? '🙈  HIDE COMIC' : '🎉  SHOW MY COMIC!',
            style: ts(18, K.white, fw: FontWeight.w900, sh: [const Shadow(color: Colors.black26, offset: Offset(1, 2), blurRadius: 4)]),
          ),
          const SizedBox(width: 10),
          AnimatedRotation(turns: _showComic ? .5 : 0, duration: const Duration(milliseconds: 380), curve: Curves.easeInOut,
            child: const Icon(Icons.expand_more_rounded, color: K.white, size: 30)),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  COMIC SECTION  (PageView + storytelling + nav)
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
        // PageView
        SizedBox(
          height: 500,
          child: PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (idx) => setState(() => _comicPanel = idx),
            itemCount: _panels.length,
            itemBuilder: (_, idx) => _buildPanel(idx),
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
          Text(
            _comicReading ? 'Reading panel ${_comicPanel + 1} of ${_panels.length}...' : 'Tap ▶ to hear the full story!',
            style: tb(11, K.white.withOpacity(.88), fw: FontWeight.w600),
          ),
        ])),
        const SizedBox(width: 10),
        _ctrlBtn(Icons.play_circle_filled_rounded, K.lime, _comicReading ? null : _startComicRead),
        const SizedBox(width: 8),
        _ctrlBtn(Icons.stop_circle_rounded, K.red, _comicReading ? _stopComicRead : null),
      ]),
    );
  }

  Widget _ctrlBtn(IconData icon, Color c, VoidCallback? fn) {
    return GestureDetector(
      onTap: fn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: fn == null ? K.white.withOpacity(.2) : K.white,
          shape: BoxShape.circle,
          border: Border.all(color: K.ink, width: 2.5),
          boxShadow: fn == null ? [] : const [BoxShadow(color: K.ink, offset: Offset(2, 2), blurRadius: 0)],
        ),
        child: Icon(icon, color: fn == null ? K.white.withOpacity(.4) : c, size: 26),
      ),
    );
  }

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
            border: active ? Border.all(color: K.ink, width: 2) : null,
          ),
        );
      }),
    );
  }

  Widget _panelNav() {
    return Row(children: [
      _navBtn('◀  PREV', K.blue, _comicPanel > 0 ? () {
        _pageCtrl.previousPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
      } : null),
      const SizedBox(width: 12),
      _navBtn('NEXT  ▶', K.red, _comicPanel < _panels.length - 1 ? () {
        _pageCtrl.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
      } : null),
    ]);
  }

  Widget _navBtn(String label, Color c, VoidCallback? fn) {
    return Expanded(child: GestureDetector(
      onTap: fn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: fn == null ? Colors.grey.shade300 : c,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: K.ink, width: 3),
          boxShadow: fn == null ? [] : const [BoxShadow(color: K.ink, offset: Offset(4, 4), blurRadius: 0)],
        ),
        child: Center(child: Text(label, style: ts(15, fn == null ? Colors.grey.shade500 : K.white))),
      ),
    ));
  }

  // ════════════════════════════════════════════════════════
  //  SINGLE COMIC PANEL
  // ════════════════════════════════════════════════════════
  Widget _buildPanel(int idx) {
    final panel   = _panels[idx];
    final palette = K.panels[idx % K.panels.length];
    final bg      = palette[0] as Color;
    final bc      = palette[1] as Color;
    final seed    = idx < _seeds.length ? _seeds[idx] : idx * 137 + 7;
    final active  = idx == _comicPanel && _comicReading;

    Widget card = Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Stack(children: [
        // Hard ink shadow
        Positioned(left: 7, top: 7, right: 0, bottom: 0, child: Container(
          decoration: BoxDecoration(color: K.ink, borderRadius: BorderRadius.circular(26)),
        )),
        // Card body
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(26),
            border: Border.all(color: active ? bc : bg, width: 4),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Image + overlays
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: Stack(children: [
                  _panelImg(panel['image'] ?? ''),
                  Positioned.fill(child: CustomPaint(painter: _HalftonePainter(K.ink.withOpacity(.033)))),
                ]),
              ),
              // Panel badge
              Positioned(top: 12, left: 12, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: bc, borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: K.white, width: 2.5),
                  boxShadow: const [BoxShadow(color: K.ink, offset: Offset(2, 3), blurRadius: 0)],
                ),
                child: Text('Panel ${idx + 1}', style: ts(12, K.white)),
              )),
              // ZAP sticker
              Positioned(top: 10, right: 10, child: Transform.rotate(angle: .22,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: K.zapCols[idx % K.zapCols.length],
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: K.ink, width: 2.5),
                    boxShadow: const [BoxShadow(color: K.ink, offset: Offset(2, 2), blurRadius: 0)],
                  ),
                  child: Text(K.zapLabels[idx % K.zapLabels.length], style: ts(12, K.white)),
                ),
              )),
              // Active-reading glow overlay
              if (active) Positioned.fill(child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: AnimatedBuilder(
                  animation: _aPulse,
                  builder: (_, __) => Container(color: bc.withOpacity(_aPulse.value * .13)),
                ),
              )),
            ]),
            // Speech bubble title
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 2),
              child: CustomPaint(
                painter: _BubblePainter(fill: K.white, stroke: bc),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 13, 16, 30),
                  child: Text(panel['title'] ?? '', style: ts(15, bc, fw: FontWeight.w900)),
                ),
              ),
            ),
            // Description
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
              child: Text(panel['description'] ?? '',
                  style: tb(13, K.ink.withOpacity(.8), fw: FontWeight.w600)),
            ),
          ]),
        ),
        // Wobbly ink border
        Positioned.fill(child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: CustomPaint(painter: _WobblePainter(bc, 4.4, seed)),
        )),
      ]),
    );

    // Entrance animation
    if (idx < _panelSc.length) {
      card = AnimatedBuilder(
        animation: Listenable.merge([_panelSc[idx], _panelOp[idx]]),
        builder: (_, child) => Opacity(
          opacity: _panelOp[idx].value,
          child: Transform.scale(scale: _panelSc[idx].value, child: child),
        ),
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
      fadeInDuration: Duration.zero,
    );
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
      ]),
    );
  }
}