import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fx.dart';

/// الشخصيات الملحمية والأسطورية (غير الصقّار): طبقات من نفس الرسمة (tools/art/anim_avatars.py → RIGS)
/// بلوحة أكبر من الصورة بـ ٢٠٪، و٢٠٠ وحدة = قطر الصورة. كلهم يتنفسون ويرمشون ويحركون روسهم،
/// ولكل واحد حركة خاصة (يغمز، يعوي، يطفو، تطيح حوله عملات…).
class AvatarRig {
  AvatarRig(this.id, this.size, this.t) : k = size / 200;

  final String id;
  final double size;
  final double t;
  final double k;

  /// الشخصيات اللي لها طبقات.
  static const ids = {
    'lady_gold', 'pilot', 'seer', 'knight', 'ghost', 'assassin', 'wolf', 'falcon_bird', 'tycoon', 'emir', 'sultana', //
    'queen', 'astronaut', 'lv20', 'lv30', 'lv40', 'lv50', 's1a', 's1b', 's1c', 'champ1', 'champ2', 'champ3',
  };

  static const _neck = Offset(100, 150);

  late final int _seed = id.codeUnits.fold(7, (a, c) => (a * 31 + c) & 0xffff);
  late final _Pose _p = _Pose(t, _seed);

  Widget build() => Stack(
    clipBehavior: Clip.none,
    children: switch (id) {
      'lady_gold' => _ladyGold(),
      'pilot' => _pilot(),
      'seer' => _seer(),
      'knight' => _knight(plume: const Offset(106, 46)),
      'ghost' => _ghost(),
      'assassin' => _assassin(),
      'wolf' => _wolf(),
      'falcon_bird' => _falconBird(),
      'tycoon' => _tycoon(),
      'emir' => _emir(),
      'sultana' => _sultana(),
      'queen' => _queen(),
      'astronaut' => _astronaut(),
      'lv20' => _owl(),
      'lv30' => _leopard(),
      'lv40' => _lion(),
      'lv50' => _phoenix(),
      's1a' => _caracal(),
      's1b' => _gazelle(),
      's1c' => _horse(),
      _ => _oryx(),
    },
  );

  // ───────────── أدوات ─────────────

  /// تحويل بوحدات الرسمة: دوران حول [pivot] وتكبير، ثم إزاحة [shift].
  Matrix4 _xf({
    double rot = 0,
    Offset pivot = const Offset(100, 100),
    Offset shift = Offset.zero,
    double sx = 1,
    double sy = 1,
  }) {
    final px = (pivot.dx + 20) * k, py = (pivot.dy + 20) * k;
    return Matrix4.identity()
      ..translateByDouble(shift.dx * k + px, shift.dy * k + py, 0, 1)
      ..rotateZ(rot)
      ..scaleByDouble(sx, sy, 1, 1)
      ..translateByDouble(-px, -py, 0, 1);
  }

  /// الجسم يتنفس (يكبر شوي من تحت).
  late final Matrix4 _body = _xf(pivot: const Offset(100, 200), sy: 1 + _p.breath * .005);

  /// الراس يلف حول الرقبة ويتحرك مع النفس.
  Matrix4 _head({double rot = 0, Offset shift = Offset.zero}) =>
      _xf(rot: _p.head + rot, pivot: _neck, shift: _p.body + shift);

  Widget _img(String name, Matrix4 m, {double opacity = 1}) => Positioned(
    left: -size * .1,
    top: -size * .1,
    width: size * 1.2,
    height: size * 1.2,
    child: Transform(
      transform: m,
      child: Image.asset(
        'assets/avatars/anim/$id/$name.webp',
        width: size * 1.2,
        height: size * 1.2,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        opacity: opacity >= 1 ? null : AlwaysStoppedAnimation(opacity.clamp(0.0, 1.0)),
      ),
    ),
  );

  /// رسم بوحدات الرسمة (لمعات، عملات، ضو…) بنفس تحويل الطبقة.
  Widget _fx(Matrix4 m, void Function(Canvas c) draw) => Positioned(
    left: -size * .1,
    top: -size * .1,
    width: size * 1.2,
    height: size * 1.2,
    child: Transform(
      transform: m,
      child: CustomPaint(painter: _Draw(draw, k)),
    ),
  );

  /// تقدم حركة تتكرر كل [period] ثانية وتطول [dur] (٠–١)، أو null لو مو وقتها.
  double? _phase(double period, double dur, [double offset = 0]) {
    final s = _frac((t + offset + _seed * .013) / period) * period;
    return s < dur ? s / dur : null;
  }

  /// نفس [_phase] بس كموجة (٠ → ١ → ٠).
  double _pulse(double period, double dur, [double offset = 0]) {
    final p = _phase(period, dur, offset);
    return p == null ? 0 : math.sin(p * math.pi);
  }

  /// يطلع ويثبت وينزل (للحركات اللي تطول شوي، مثل العواء).
  double _hold(double period, double dur, [double offset = 0, double ramp = .2]) {
    final p = _phase(period, dur, offset);
    if (p == null) return 0;
    final r = ramp.clamp(.01, .5);
    return Curves.easeInOut.transform(p < r ? p / r : (p > 1 - r ? (1 - p) / r : 1));
  }

  static double _frac(double x) => x - x.floorToDouble();

  static void _sparkle(Canvas c, Offset at, double r, double a, {Color glow = Colors.white}) {
    if (a <= 0) return;
    c.drawCircle(
      at,
      r * 1.5,
      Paint()
        ..color = glow.withValues(alpha: .3 * a)
        ..blendMode = BlendMode.plus,
    );
    c.drawPath(star4(at, r), Paint()..color = Colors.white.withValues(alpha: a));
  }

  static void _glow(Canvas c, Offset at, double r, Color color, double a) {
    if (a <= 0) return;
    c.drawCircle(
      at,
      r,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: a),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
  }

  /// الشخصية العادية: الجسم، وأغراض ورا الراس، والراس، والرمشة، والفم، وأغراض فوق.
  List<Widget> _human({
    double rot = 0,
    Offset shift = Offset.zero,
    bool blink = true,
    bool mouth = false,
    List<Widget> under = const [],
    List<Widget> Function(Matrix4 head)? over,
  }) {
    final head = _head(rot: rot, shift: shift);
    return [
      _img('body', _body),
      ...under,
      _img('head', head),
      if (blink && _p.blink) _img('blink', head),
      if (mouth) _img('mouth', head),
      ...?over?.call(head),
    ];
  }

  // ───────────── الشخصيات ─────────────

  /// الأميرة: ترمش، وكل شوي تغمز وتميل راسها، وجواهر تاجها تلمع.
  List<Widget> _ladyGold() {
    final w = _pulse(6.4, .45);
    final head = _head(rot: -.07 * w);
    return [
      _img('body', _body),
      _img('head', head),
      if (w > .15) _img('wink', head) else if (_p.blink) _img('blink', head),
      _img('necklace', _body),
      _fx(head, (c) {
        for (final (i, at) in const [Offset(100, 58), Offset(92, 62), Offset(108, 62)].indexed) {
          _sparkle(c, at, 3.2, _pulse(2.6, .5, i * .85), glow: const Color(0xFFFFE08A));
        }
        _sparkle(c, const Offset(76, 92), 4, w);
      }),
    ];
  }

  /// الطيّار: كل شوي ينزّل نظارة الطيران على عيونه ويرفع راسه، ويرجعها.
  List<Widget> _pilot() {
    final s = _frac((t + _seed * .013) / 7.2) * 7.2;
    final down = s < .45
        ? Curves.easeOutBack.transform(s / .45)
        : s < 2.3
        ? 1.0
        : s < 2.75
        ? 1 - Curves.easeIn.transform((s - 2.3) / .45)
        : 0.0;
    final head = _head(rot: -.04 * down);
    return [
      _img('body', _body),
      _img('head', head),
      if (down < .4 && _p.blink) _img('blink', head),
      _img('goggles', head.multiplied(_xf(shift: Offset(0, 29 * down)))),
      _fx(head, (c) => _sparkle(c, const Offset(122, 98), 4, down > .95 ? _pulse(7.2, 1.2, -1.0) : 0)),
    ];
  }

  /// العرّاف: كرته البلورية تضوي وتدور فيها الغيوم، وكل شوي تومض ويطالع فيها وعيونه تشع.
  List<Widget> _seer() {
    final f = _pulse(5.5, 1.3);
    final head = _head(shift: Offset(0, 1.6 * f));
    return [
      _img('body', _body),
      _img('head', head),
      if (f < .3 && _p.blink) _img('blink', head),
      if (f > 0) _img('eyes', head, opacity: f),
      _img('ball', _body),
      _img('ball_glow', _body, opacity: .3 + .3 * (.5 + .5 * math.sin(t * 2.6)) + .4 * f),
      _fx(_body, (c) {
        const ball = Offset(100, 172);
        for (var i = 0; i < 2; i++) {
          final a = t * (1.6 + i * .7) + i * 2.4;
          c.drawArc(
            Rect.fromCircle(center: ball, radius: 6.0 + i * 5),
            a,
            1.9,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..strokeCap = StrokeCap.round
              ..blendMode = BlendMode.plus
              ..color = const Color(0xFFF5D0FE).withValues(alpha: .55 + .4 * f),
          );
        }
        _sparkle(c, ball + Offset(math.cos(t * 2.1) * 9, math.sin(t * 2.1) * 6), 2.4, .5 + .5 * f);
      }),
    ];
  }

  /// الفارس: ريشة خوذته تتمايل، وكل شوي يحني راسه تحية وتلمع خوذته.
  List<Widget> _knight({required Offset plume}) {
    final bow = _pulse(6.8, 1.1);
    final head = _head(shift: Offset(0, 2.4 * bow), rot: .03 * bow);
    final sway = .14 * math.sin(t * 2.1) + .05 * math.sin(t * 5.3);
    return [
      _img('body', _body),
      _img('plume', head.multiplied(_xf(rot: sway, pivot: plume))),
      _img('head', head),
      if (_p.blink) _img('blink', head),
      _fx(head, (c) => _sparkle(c, const Offset(124, 62), 4.5, bow)),
    ];
  }

  /// الشبح: يطفو ويتمايل، وكل شوي يختفي ويرجع، وأحياناً يفتح فمه ويخرّعك.
  List<Widget> _ghost() {
    final boo = _phase(10, 1.2, 4);
    final b = boo == null ? 0.0 : math.sin(boo * math.pi);
    final m = _xf(
      rot: .05 * math.sin(t * 1.05),
      pivot: const Offset(100, 120),
      shift: Offset(0, 3 * math.sin(t * 1.5) - 1 - 4 * b),
      sx: 1 + .05 * b,
      sy: 1 + .05 * b,
    );
    final fade = 1 - .65 * _pulse(8.5, 1.8, 1);
    final blink = _pulse(3.3, .16) > 0;
    final eyes = m.multiplied(_xf(pivot: const Offset(100, 106), sy: blink ? .12 : 1 + .35 * b, sx: 1 + .1 * b));
    return [
      _img('cloak', m, opacity: fade),
      _img('eyes', eyes, opacity: fade * (.8 + .2 * math.sin(t * 3))),
      if (b > 0)
        _img(
          'mouth',
          m.multiplied(_xf(pivot: const Offset(100, 134), sx: .3 + .7 * b, sy: .3 + .7 * b)),
          opacity: fade,
        ),
    ];
  }

  /// الملثّم: يتلفت حوله، عيونه الحمرا تضيق، وكل شوي يقلّب خنجره ويلمع.
  List<Widget> _assassin() {
    final p = _Pose(t, _seed, look: .09, period: 2.2);
    final head = _xf(rot: p.head, pivot: _neck, shift: p.body);
    final squint = _pulse(4.4, .6);
    final flip = _phase(7, .55, 2);
    final spin = flip == null ? 0.0 : Curves.easeInOut.transform(flip) * 2 * math.pi;
    final dagger = _body.multiplied(_xf(rot: .05 * math.sin(t * 1.7) + spin, pivot: const Offset(150, 176)));
    return [
      _img('body', _body),
      _img('head', head),
      _img(
        'eyes',
        head.multiplied(_xf(pivot: const Offset(100, 103), sy: 1 - .7 * squint)),
        opacity: .75 + .25 * math.sin(t * 2.4),
      ),
      _img('dagger', dagger),
      _fx(dagger, (c) => _sparkle(c, const Offset(127, 137), 4, _pulse(3, .45, 1))),
    ];
  }

  /// الذئب: يحرك أذونه، وكل شوي يرفع راسه ويعوي.
  List<Widget> _wolf() {
    final howl = _hold(8.5, 2.3, 3, .18);
    final head = _head(rot: -.08 * howl, shift: Offset(0, -6 * howl));
    final twitchL = -.28 * _pulse(2.7, .2) - .3 * howl;
    final twitchR = .28 * _pulse(3.3, .2, 1.2) + .3 * howl;
    return [
      _img('body', _body),
      _img('ear_l', head.multiplied(_xf(rot: twitchL, pivot: const Offset(66, 74)))),
      _img('ear_r', head.multiplied(_xf(rot: twitchR, pivot: const Offset(134, 74)))),
      _img('head', head),
      if (howl > .25 || _p.blink) _img('blink', head),
      if (howl > .25) _img('howl', head),
      if (howl > .25)
        _fx(_xf(shift: Offset(0, -6 * howl)), (c) {
          for (var i = 0; i < 3; i++) {
            final q = _frac(t * 1.1 + i / 3);
            c.drawArc(
              Rect.fromCircle(center: const Offset(100, 56), radius: 36 + 34 * q),
              -math.pi * .78,
              math.pi * .56,
              false,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3
                ..strokeCap = StrokeCap.round
                ..color = Colors.white.withValues(alpha: .7 * (1 - q) * howl),
            );
          }
        }),
    ];
  }

  /// الصقر: يلف راسه بحركات سريعة مثل الطيور، ويرمش، وكل شوي يفتح منقاره ويصرخ وينتفش.
  List<Widget> _falconBird() {
    final step = (t / 1.25).floor();
    final into = Curves.easeOut.transform((_frac(t / 1.25) * 1.25 / .09).clamp(0.0, 1.0));
    double at(int s) => (rnd(s, _seed) - .5) * .3;
    final scream = _hold(7.5, .85, 2, .25);
    final rot = at(step - 1) + (at(step) - at(step - 1)) * into + .05 * math.sin(t * 42) * scream;
    final head = _xf(rot: rot, pivot: _neck, shift: _p.body + Offset(0, -2 * scream));
    final puff = 1 + .035 * scream;
    return [
      _img('body', _xf(pivot: const Offset(100, 200), sx: puff, sy: puff * (1 + _p.breath * .005))),
      _img('head', head),
      if (scream < .3 && _pulse(2.8, .17) > 0) _img('blink', head),
      if (scream > .2) _img('beak', head),
    ];
  }

  /// تاجر الذهب: سلسلته تتمرجح، ونظارته تلمع، وتطيح حوله عملات ذهب تقلّب.
  List<Widget> _tycoon() {
    final nod = _pulse(5, 1);
    final head = _head(shift: Offset(0, 1.6 * nod));
    return [
      _img('body', _body),
      _img('chain', _body.multiplied(_xf(rot: .08 * math.sin(t * 2.4), pivot: _neck))),
      _img('head', head),
      _fx(head, (c) => _sparkle(c, const Offset(81, 101), 4.2, _pulse(4, .5, 1))),
      _fx(Matrix4.identity(), _coins),
    ];
  }

  void _coins(Canvas c) {
    for (var i = 0; i < 3; i++) {
      final cyc = _frac(t / 3.2 + i / 3);
      if (cyc > .62) continue;
      final q = cyc / .62;
      final x0 = const [46.0, 154.0, 100.0][i];
      final pos = Offset(x0 + (i == 2 ? 0 : (i == 0 ? 10 : -10)) * q, 214 - 600 * q * (1 - q));
      final turn = math.cos(t * 9 + i * 2);
      final fade = q > .85 ? (1 - q) / .15 : 1.0;
      final rect = Rect.fromCenter(center: pos, width: 15 * turn.abs() + 2, height: 15);
      c.drawOval(rect, Paint()..color = const Color(0xFFB45309).withValues(alpha: fade));
      c.drawOval(
        rect.deflate(1.6),
        Paint()..color = (turn > 0 ? const Color(0xFFFCD34D) : const Color(0xFFF59E0B)).withValues(alpha: fade),
      );
      if (turn > .3) _sparkle(c, pos + const Offset(-2, -3), 2.6, fade * turn);
    }
  }

  /// الأمير: يهز راسه بهيبة، وبشته يمشي على طرفه لمعان.
  List<Widget> _emir() {
    final nod = _pulse(6, 1.2);
    return _human(
      shift: Offset(0, 2 * nod),
      over: (head) => [
        _fx(_body, (c) {
          final q = _phase(3.2, 1.9);
          if (q == null) return;
          for (final (a, b) in const [(Offset(66, 146), Offset(88, 200)), (Offset(134, 146), Offset(112, 200))]) {
            final p = Offset.lerp(a, b, q)!;
            _glow(c, p, 7, const Color(0xFFFFF3C4), .8 * math.sin(q * math.pi));
            _sparkle(c, p, 3, math.sin(q * math.pi));
          }
        }),
      ],
    );
  }

  /// السلطانة: ترمش، وطرحتها تتمايل، وجوهرة جبينها تلمع.
  List<Widget> _sultana() {
    final head = _head();
    return [
      _img('body', _body),
      _img('head', head),
      if (_p.blink) _img('blink', head),
      _img('veil', head.multiplied(_xf(rot: .035 * math.sin(t * 1.6), pivot: const Offset(100, 112)))),
      _fx(head, (c) => _sparkle(c, const Offset(100, 88), 4, _pulse(3.4, .55), glow: const Color(0xFFFF6B6B))),
    ];
  }

  /// الملكة: ترمش، وجواهر تاجها تلمع وحدة ورا الثانية، ولمعة تمشي على عقدها.
  List<Widget> _queen() {
    final head = _head();
    return [
      _img('body', _body),
      _img('head', head),
      if (_p.blink) _img('blink', head),
      _img('necklace', _body),
      _fx(head, (c) {
        for (final (i, at) in const [Offset(60, 32), Offset(100, 20), Offset(140, 32), Offset(100, 60)].indexed) {
          _sparkle(c, at, 4, _pulse(3.2, .5, i * .8), glow: const Color(0xFFFFE08A));
        }
      }),
      _fx(_body, _pearlGlint),
    ];
  }

  void _pearlGlint(Canvas c) {
    final q = _phase(2.8, 1.4);
    if (q == null) return;
    final x = -24 + 48 * q;
    _sparkle(c, Offset(100 + x, 156 + x * x / 90 - 1.5), 2.6, math.sin(q * math.pi));
  }

  /// رائد الفضاء: يسبح ويتمايل، وضو يمر على خوذته، ويرمش.
  List<Widget> _astronaut() {
    final float = _xf(
      rot: .04 * math.sin(t * .8),
      pivot: const Offset(100, 140),
      shift: Offset(0, 2.6 * math.sin(t * 1.25)),
    );
    final body = float.multiplied(_body);
    final head = float.multiplied(_head());
    return [
      _img('body', body),
      _img('head', head),
      if (_p.blink) _img('blink', head),
      _img('visor', head),
      _fx(head, (c) {
        final q = _phase(4.2, 1.1);
        if (q == null) return;
        c.save();
        c.clipPath(Path()..addOval(Rect.fromCircle(center: const Offset(100, 104), radius: 50)));
        c.translate(40 + 120 * q, 104);
        c.rotate(.6);
        c.drawRect(
          const Rect.fromLTWH(-7, -70, 14, 140),
          Paint()
            ..color = Colors.white.withValues(alpha: .32 * math.sin(q * math.pi))
            ..blendMode = BlendMode.plus,
        );
        c.restore();
      }),
    ];
  }

  // ───────────── حيوانات الجوائز (تناسب الكل) ─────────────

  /// البومة الحكيمة: تقرأ في كتابها وتقلّب صفحة، وكل شوي تلف راسها مثل البوم، ونظارتها تلمع.
  List<Widget> _owl() {
    final read = _hold(6, 2.6, 0, .2);
    final page = _phase(6, 1.8);
    final turn = _hold(9, 1.6, 4, .25);
    final head = _head(rot: .07 * read + .22 * turn, shift: Offset(1.5 * read, 2 * read));
    return [
      _img('body', _body),
      _img('head', head),
      if (_p.blink && turn < .2) _img('blink', head),
      _img('glasses', head),
      _fx(head, (c) => _sparkle(c, const Offset(64, 86), 3.4, _pulse(3.4, .45, 1))),
      _img('book', _body),
      _fx(_body, (c) {
        if (page == null || page < .3) return;
        final q = Curves.easeInOut.transform(((page - .3) / .45).clamp(0.0, 1.0));
        if (q >= 1) return;
        c.save();
        c.translate(131, 167);
        c.rotate(-12 * math.pi / 180);
        final x = 26 * math.cos(math.pi * q);
        final lift = 4 * math.sin(math.pi * q);
        final leaf = Path()
          ..moveTo(0, -17.5)
          ..lineTo(x, -17.5 - lift)
          ..lineTo(x, 17.5 - lift)
          ..lineTo(0, 17.5)
          ..close();
        c.drawPath(leaf, Paint()..color = const Color(0xFFFFF7E2));
        c.drawPath(
          leaf,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFF2A1520),
        );
        c.drawLine(Offset(x * .2, -11 - lift * .8), Offset(x * .8, -11 - lift * .8), Paint()..color = const Color(0xFF9E7A52)..strokeWidth = 1.2);
        c.drawLine(Offset(x * .2, -4 - lift * .8), Offset(x * .8, -4 - lift * .8), Paint()..color = const Color(0xFF9E7A52)..strokeWidth = 1.2);
        c.drawLine(Offset(x * .2, 3 - lift * .8), Offset(x * .8, 3 - lift * .8), Paint()..color = const Color(0xFF9E7A52)..strokeWidth = 1.2);
        c.restore();
      }),
    ];
  }

  /// النمر الذهبي: سلسلته الذهب تتمرجح، وفروه يلمع، ويهز راسه.
  List<Widget> _leopard() {
    final nod = _pulse(5.6, 1.1);
    final head = _head(shift: Offset(0, 1.8 * nod));
    return [
      _img('body', _body),
      _img('chain', _body.multiplied(_xf(rot: .08 * math.sin(t * 2.3), pivot: _neck))),
      _img('head', head),
      if (_p.blink) _img('blink', head),
      _fx(head, (c) {
        _sparkle(c, const Offset(131, 74), 4.2, _pulse(2.4, .5));
        _sparkle(c, const Offset(62, 112), 3.6, _pulse(2.4, .5, 1.2));
      }),
    ];
  }

  /// أسد الياقوت: لبدته تتمايل، وياقوتته تتوهج، وكل شوي يزأر وتنتفش لبدته.
  List<Widget> _lion() {
    final roar = _hold(7.5, 1.2, 2, .2);
    final head = _head(rot: .04 * math.sin(t * 30) * roar, shift: Offset(0, -1.6 * roar));
    final puff = 1 + .05 * roar;
    return [
      _img('body', _body),
      _img('mane', head.multiplied(_xf(rot: .03 * math.sin(t * 1.9), sx: puff, sy: puff))),
      _img('head', head),
      if (_p.blink && roar < .3) _img('blink', head),
      if (roar > .2) _img('mouth', head),
      _fx(
        head,
        (c) => _glow(
          c,
          const Offset(100, 64),
          12 * (1 + .25 * math.sin(t * 3)) + 8 * roar,
          const Color(0xFFF43F5E),
          .55 + .3 * roar,
        ),
      ),
    ];
  }

  /// العنقاء: عرفها يتراقص مثل النار، وجناحينها يرفرفون، وكل شوي يتطاير حولها شرار.
  List<Widget> _phoenix() {
    final head = _head();
    final burst = _pulse(6, 1.2, 1);
    final flap = .5 + .5 * math.sin(t * 2.6);
    final crest = head.multiplied(
      _xf(rot: .05 * math.sin(t * 5.2), pivot: const Offset(100, 72), sy: 1 + .06 * math.sin(t * 7.3)),
    );
    return [
      _img('wings', _xf(pivot: const Offset(100, 200), sx: 1 + .07 * flap, sy: 1 + .03 * flap)),
      _img('body', _body),
      _img('crest', crest),
      _img('head', head),
      if (_p.blink) _img('blink', head),
      _fx(crest, (c) {
        for (final (i, at) in const [Offset(74, 26), Offset(104, 14), Offset(126, 26)].indexed) {
          _sparkle(c, at, 4, _pulse(3, .5, i * .7), glow: const Color(0xFFFDE68A));
        }
      }),
      if (burst > 0)
        _fx(head, (c) {
          for (var i = 0; i < 6; i++) {
            final a = i * math.pi / 3 + t * .5;
            _sparkle(
              c,
              const Offset(100, 100) + Offset(math.cos(a), math.sin(a)) * (40 + 22 * burst),
              3.4,
              burst,
              glow: const Color(0xFFFB923C),
            );
          }
        }),
    ];
  }

  /// وشق الليل: يتلفت يمين ويسار، ويحرك أذونه بخصلها، وهلاله يلمع.
  List<Widget> _caracal() {
    final p = _Pose(t, _seed, look: .1, period: 2.3);
    final head = _xf(rot: p.head, pivot: _neck, shift: p.body);
    return [
      _img('body', _body),
      _img('ear_l', head.multiplied(_xf(rot: -.22 * _pulse(3.1, .22), pivot: const Offset(72, 84)))),
      _img('ear_r', head.multiplied(_xf(rot: .22 * _pulse(3.7, .22, 1.4), pivot: const Offset(128, 84)))),
      _img('head', head),
      if (p.blink) _img('blink', head),
      _fx(_body, (c) => _sparkle(c, const Offset(95, 181), 4, _pulse(3.6, .55), glow: const Color(0xFFFDE68A))),
    ];
  }

  /// غزال القمر: هلاله يضوي بين قرونه وينطفي بهدوء، ويحرك أذونه، ويرمش.
  List<Widget> _gazelle() {
    final head = _head();
    return [
      _img('body', _body),
      _img('ear_l', head.multiplied(_xf(rot: .3 * _pulse(4.2, .25), pivot: const Offset(80, 92)))),
      _img('ear_r', head.multiplied(_xf(rot: -.3 * _pulse(5.1, .25, 2), pivot: const Offset(120, 92)))),
      _img('head', head),
      if (_p.blink) _img('blink', head),
      _fx(
        head,
        (c) => _glow(c, const Offset(100, 40), 20, const Color(0xFFFDE68A), .35 + .3 * (.5 + .5 * math.sin(t * 1.8))),
      ),
      _fx(_body, (c) => _sparkle(c, const Offset(96, 181), 3.4, _pulse(3.2, .5, .8), glow: const Color(0xFFFDE68A))),
    ];
  }

  /// أصيل الموسم الأول: يهز راسه وعرفه يتطاير، وهلاله يضوي.
  List<Widget> _horse() {
    final nod = _pulse(5.8, 1.1);
    final head = _head(shift: Offset(0, 1.8 * nod));
    return [
      _img('body', _body),
      _img('mane', head.multiplied(_xf(rot: .045 * math.sin(t * 2.2) + .03 * nod, pivot: const Offset(112, 50)))),
      _img('head', head),
      if (_p.blink) _img('blink', head),
      _fx(head, (c) {
        _glow(c, const Offset(100, 78), 14, const Color(0xFFFDE68A), .3 + .25 * math.sin(t * 2));
        _sparkle(c, const Offset(71, 130), 3.2, _pulse(3, .5, 1));
      }),
    ];
  }

  /// أبطال الأسبوع (المها): الميدالية تتمرجح وتلمع، وترفع راسها بفخر، وكل شوي تضحك وتهز أذونها فرحانة.
  List<Widget> _oryx() {
    final laugh = _hold(9, 1.3, 3, .15);
    final proud = _pulse(6, 1.2);
    final head = _head(shift: Offset(0, -1.5 * proud + 1.2 * math.sin(t * 25) * laugh));
    final wiggle = .25 * math.sin(t * 18) * laugh;
    final medal = _body.multiplied(_xf(rot: .1 * math.sin(t * 2.2), pivot: _neck));
    return [
      _img('body', _body),
      // الميدالية خلف الراس: شريطها يطلع من ورا الفك
      _img('medal', medal),
      _img('ear_l', head.multiplied(_xf(rot: -.08 * proud + wiggle, pivot: const Offset(82, 88)))),
      _img('ear_r', head.multiplied(_xf(rot: .08 * proud - wiggle, pivot: const Offset(118, 88)))),
      _img('head', head),
      if (_p.blink && laugh < .2) _img('blink', head),
      if (laugh > .2) _img('mouth', head),
      _fx(medal, (c) => _sparkle(c, const Offset(94, 175), 3.4, _pulse(2.5, .5))),
    ];
  }
}

/// وين يطالع الراس والتنفس والرمشة في لحظة. كل شخصية بإيقاع مختلف شوي ([seed]).
class _Pose {
  _Pose(double t, int seed, {double look = .055, double period = 2.9}) {
    final s = seed * .37;
    breath = math.sin(t * math.pi * 2 / 3.8 + s);
    body = Offset(0, breath * .6);
    final p = period + (seed % 5) * .17;
    final x = (t + s) / p;
    final step = x.floor();
    final into = Curves.easeInOut.transform(((x - step) * p / .7).clamp(0.0, 1.0));
    double at(int k) => (rnd(k, seed) - .5) * 2 * look;
    head = at(step - 1) + (at(step) - at(step - 1)) * into + .012 * math.sin(t * 1.3 + s);
    blink = _blinkAt(t + s, 3.6 + (seed % 7) * .23) || _blinkAt(t + s + 1.9, 9.7);
  }

  late final double breath;
  late final Offset body;
  late final double head;
  late final bool blink;

  static bool _blinkAt(double t, double period) {
    final p = (t / period) - (t / period).floorToDouble();
    return p < .15 / period;
  }
}

class _Draw extends CustomPainter {
  _Draw(this.draw, this.k);

  final void Function(Canvas c) draw;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(20 * k, 20 * k);
    canvas.scale(k);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Draw old) => true;
}
