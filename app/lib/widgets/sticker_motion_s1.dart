// حركات ملصقات الباقات: الأساسي، صدمة، ضحك، القهوة، الزعل، التوتر، المحقق (٤٢ ملصق).
// جزء من sticker_motion.dart (يشارك أدواته الخاصة: _Motion، _P، _sparkles، _steam …). خفيفة للعادي والنادر:
// الحركة من التعبير نفسه (الضحك ينط والدموع تتطاير، الصدمة ترجّ، القهوة بخار، الغضب بخار ورجفة، التوتر عرق
// وارتجاف، المحقق عدسة تلمع). المواقع نسبة من حجم الملصق، و[_s1A] تحوّل إحداثيات الرسمة (٠–٢٠٠) لنسبة.
part of 'sticker_motion.dart';

/// إحداثيات الرسمة (٢٠٠×٢٠٠ + هامش ٨) إلى نسبة من حجم الملصق.
Offset _s1A(double x, double y) => Offset((x + 8) / 216, (y + 8) / 216);

double _s1Fr(double x) => x - x.floorToDouble();

/// ضحكة: نطّات سريعة متتابعة (٠–١).
double _s1Laugh(double t, [double hz = 3.4]) => math.sin(_s1Fr(t * hz) * math.pi).abs();

/// قطرة صغيرة (دمعة أو عرق) بحد غامق خفيف.
void _s1Drop(Canvas c, Offset p, double r, double a, {Color color = const Color(0xFF7ED3FF)}) {
  if (a <= 0) return;
  final path = Path()
    ..moveTo(p.dx, p.dy - r * 1.5)
    ..cubicTo(p.dx + r * .3, p.dy - r * .7, p.dx + r, p.dy - r * .1, p.dx + r, p.dy + r * .4)
    ..cubicTo(p.dx + r, p.dy + r * 1.05, p.dx - r, p.dy + r * 1.05, p.dx - r, p.dy + r * .4)
    ..cubicTo(p.dx - r, p.dy - r * .1, p.dx - r * .3, p.dy - r * .7, p.dx, p.dy - r * 1.5)
    ..close();
  c.drawPath(path, Paint()..color = color.withValues(alpha: a.clamp(0.0, 1.0)));
  c.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .3
      ..color = const Color(0xFF2A1520).withValues(alpha: .75 * a.clamp(0.0, 1.0)),
  );
}

/// دموع تتطاير من الأعين للجنبين وتطيح (ضحك أو بكا). [spread] قوة الرش.
void _s1Tears(Canvas c, Size s, double t, List<Offset> eyes, {double spread = 1, double hz = 1.5, double r = .02}) {
  for (final (i, o) in eyes.indexed) {
    final side = o.dx < .5 ? -1.0 : 1.0;
    for (var k = 0; k < 2; k++) {
      final q = _s1Fr(t * hz + i * .37 + k * .5);
      final p = Offset(o.dx + side * .16 * spread * q, o.dy - .05 * q + .34 * q * q);
      _s1Drop(c, Offset(p.dx * s.width, p.dy * s.height), r * s.width, q > .78 ? (1 - q) / .22 : 1);
    }
  }
}

/// قطرة عرق تنزل من نقطة وتختفي.
void _s1Sweat(Canvas c, Size s, double t, List<Offset> from, {double hz = .7, double r = .018, double drop = .16}) {
  for (final (i, o) in from.indexed) {
    final q = _s1Fr(t * hz + i * .43);
    final a = q < .15 ? q / .15 : (q > .75 ? (1 - q) / .25 : 1.0);
    _s1Drop(c, Offset(o.dx * s.width, (o.dy + drop * q) * s.height), r * s.width, a);
  }
}

/// خطوط هز بيضاء حول نقطة (صدمة / رجفة). [a] قوتها (٠–١).
void _s1Jolt(Canvas c, Size s, Offset at, double a, {double r = .12}) {
  if (a <= 0) return;
  final paint = Paint()
    ..color = Colors.white.withValues(alpha: .95 * a)
    ..strokeWidth = s.width * .016
    ..strokeCap = StrokeCap.round;
  final edge = Paint()
    ..color = const Color(0xFF2A1520).withValues(alpha: .6 * a)
    ..strokeWidth = s.width * .03
    ..strokeCap = StrokeCap.round;
  final o = Offset(at.dx * s.width, at.dy * s.height);
  for (var j = 0; j < 3; j++) {
    final ang = -math.pi / 2 + (j - 1) * .5;
    final d = Offset(math.cos(ang), math.sin(ang));
    final p0 = o + d * s.width * r * 1.0, p1 = o + d * s.width * r * (1.3 + .15 * a);
    c.drawLine(p0, p1, edge);
    c.drawLine(p0, p1, paint);
  }
}

/// غيمات بخار بيضاء تطلع وتكبر وتتلاشى (الغضب والتنهيدة).
void _s1Puffs(Canvas c, Size s, double t, List<Offset> from, {double hz = .6, double r = .045, double rise = .13}) {
  for (final (i, o) in from.indexed) {
    final q = _s1Fr(t * hz + i * .37);
    final rr = s.width * r * (.55 + .65 * q);
    final p = Offset((o.dx + .015 * math.sin(t * 3 + i)) * s.width, (o.dy - rise * q) * s.height);
    final a = math.sin(q * math.pi);
    c.drawCircle(p, rr, Paint()..color = Colors.white.withValues(alpha: .9 * a));
    c.drawCircle(
      p,
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * .008
        ..color = const Color(0xFF2A1520).withValues(alpha: .55 * a),
    );
  }
}

/// بخار قهوة ملتف (أبيض بحد) يطلع من فنجان.
void _s1Steam(Canvas c, Size s, double t, Offset at, {int n = 3, double h = .2}) {
  for (var i = 0; i < n; i++) {
    final q = _s1Fr(t * .55 + i / n);
    final base = Offset((at.dx + (i - (n - 1) / 2) * .045) * s.width, at.dy * s.height);
    final path = Path()..moveTo(base.dx, base.dy - q * s.height * .05);
    for (var k = 1; k <= 5; k++) {
      path.lineTo(base.dx + math.sin(k * 1.4 + t * 2.6 + i * 2) * s.width * .02, base.dy - (q * .05 + k * h / 5) * s.height);
    }
    final a = math.sin(q * math.pi);
    for (final (w, col) in [(.024, const Color(0xFF2A1520)), (.012, Colors.white)]) {
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * w
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = col.withValues(alpha: .8 * a),
      );
    }
  }
}

/// قلوب صغيرة تطلع من نقطة.
void _s1Hearts(Canvas c, Size s, double t, Offset from, {int n = 3, Color color = const Color(0xFFFF4D6D)}) {
  for (var i = 0; i < n; i++) {
    final q = _s1Fr(t * .5 + i / n);
    final p = Offset((from.dx + .05 * math.sin(q * 6 + i * 2)) * s.width, (from.dy - .22 * q) * s.height);
    final r = s.width * (.014 + .012 * math.sin(q * math.pi));
    final a = math.sin(q * math.pi);
    final path = Path()
      ..moveTo(p.dx, p.dy + r * .95)
      ..cubicTo(p.dx - r * 1.7, p.dy - r * .2, p.dx - r * .8, p.dy - r * 1.35, p.dx, p.dy - r * .45)
      ..cubicTo(p.dx + r * .8, p.dy - r * 1.35, p.dx + r * 1.7, p.dy - r * .2, p.dx, p.dy + r * .95)
      ..close();
    c.drawPath(path, Paint()..color = color.withValues(alpha: a));
  }
}

/// نجمة صفراء بحد (للدوخة).
void _s1StarY(Canvas c, Offset p, double r, double a) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final rr = i.isEven ? r : r * .46;
    final ang = -math.pi / 2 + i * math.pi / 5;
    final q = p + Offset(math.cos(ang) * rr, math.sin(ang) * rr);
    i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
  }
  path.close();
  c.drawPath(path, Paint()..color = const Color(0xFFFFD43B).withValues(alpha: a));
  c.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .22
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF2A1520).withValues(alpha: .8 * a),
  );
}

/// نجوم تدور حول الراس (دوّخوني).
void _s1Dizzy(Canvas c, Size s, double t, Offset center, {double rx = .3, double ry = .055}) {
  for (var i = 0; i < 3; i++) {
    final a = t * 2.4 + i * 2 * math.pi / 3;
    final p = Offset((center.dx + math.cos(a) * rx) * s.width, (center.dy + math.sin(a) * ry) * s.height);
    _s1StarY(c, p, s.width * (.032 + .012 * math.sin(a)), .55 + .45 * math.sin(a).clamp(0.0, 1.0));
  }
}

/// لمعة تدور على حافة عدسة (محقق / منظار).
void _s1Lens(Canvas c, Size s, double t, Offset center, double r, {double speed = 1.6}) {
  final a = t * speed;
  final p = Offset((center.dx + math.cos(a) * r * .6) * s.width, (center.dy - r * .45 + math.sin(a) * r * .2) * s.height);
  StickerMotion._star(c, s, Offset(p.dx / s.width, p.dy / s.height), .04, .55 + .45 * math.sin(t * 3.5));
}

/// حلقة نبض صغيرة تطلع من القلب مع كل دقة.
void _s1Beat(Canvas c, Size s, double t, Offset at, Color color) {
  final q = _s1Fr(t * 1.7);
  if (q > .6) return;
  final k = q / .6;
  c.drawCircle(
    Offset(at.dx * s.width, at.dy * s.height),
    s.width * (.07 + .09 * k),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * .014
      ..color = color.withValues(alpha: .7 * (1 - k)),
  );
}

/// موجة سلام: ثلاثة أقواس تومض جنب اليد.
void _s1Wave(Canvas c, Size s, double t, Offset at, int side) {
  for (var i = 0; i < 3; i++) {
    final a = StickerMotion._pulse(t - i * .12, 1.1, .35);
    if (a <= 0) continue;
    final o = Offset(at.dx * s.width, at.dy * s.height);
    final path = Path()
      ..moveTo(o.dx + side * s.width * (.02 + i * .03), o.dy - s.height * .05)
      ..quadraticBezierTo(o.dx + side * s.width * (.05 + i * .03), o.dy, o.dx + side * s.width * (.02 + i * .03), o.dy + s.height * .05);
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * .016
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .9 * a),
    );
  }
}

final Map<String, _Motion> _s1Motions = {
  // ═════════ الأساسي ═════════
  'b_laugh': _Motion(
    (t) => _P(dy: -.022 * _s1Laugh(t), rot: .028 * math.sin(t * 24), sy: 1 + .02 * _s1Laugh(t), py: .92),
    front: (c, s, t) => _s1Tears(c, s, t, [_s1A(70, 100), _s1A(130, 100)]),
  ),
  'b_think': _Motion(
    (t) => _P(rot: .03 * math.sin(t * 1.3), dy: .006 * math.sin(t * 2.6), py: .92),
    front: (c, s, t) => StickerMotion._dots(c, s, t, _s1A(150, 20)),
  ),
  'b_eyes': _Motion(
    (t) {
      // تلتفت للجنب وترجع (نظرة شك)
      final q = _s1Fr(t / 3.6);
      final k = q < .2 ? Curves.easeInOut.transform(q / .2) : (q < .6 ? 1.0 : (q < .75 ? 1 - Curves.easeInOut.transform((q - .6) / .15) : 0.0));
      return _P(dx: .02 * k, rot: .035 * k, py: .92);
    },
    front: (c, s, t) => StickerMotion._sparkles(c, s, t, [_s1A(170, 56), _s1A(150, 30)]),
  ),
  'b_shh': _Motion(
    (t) => _P(sx: 1 + .012 * math.sin(t * 2), sy: 1 - .012 * math.sin(t * 2), rot: .02 * math.sin(t * 1.1), py: .92),
    front: (c, s, t) => StickerMotion._sparkles(c, s, t, [_s1A(166, 70), _s1A(36, 56)]),
  ),
  'b_smirk': _Motion(
    (t) => _P(rot: .03 * math.sin(t * 1.2), dy: -.008 * math.sin(t * 2.4), py: .92),
    front: (c, s, t) {
      StickerMotion._star(c, s, _s1A(172, 44), .06, StickerMotion._pulse(t, 2.4, .5));
      StickerMotion._star(c, s, _s1A(160, 62), .04, StickerMotion._pulse(t + .8, 2.4, .5));
    },
  ),
  'b_angry': _Motion(
    (t) {
      final jab = StickerMotion._beat(t, 1.5, .3);
      return _P(dx: .012 * jab, rot: -.03 * jab + .006 * math.sin(t * 38), sx: 1 + .03 * jab, sy: 1 + .03 * jab, py: .95);
    },
    back: (c, s, t) => StickerMotion._glowAt(c, s, _s1A(168, 38), .14, const Color(0xFFFF3B30), .25 + .35 * StickerMotion._pulse(t, 1.5, .4)),
  ),

  // ═════════ صدمة ═════════
  'shock_jaw': _Motion(
    (t) {
      final pop = StickerMotion._beat(t, .8, .3);
      return _P(sx: 1 + .07 * pop, sy: 1 + .09 * pop, dy: -.025 * pop, dx: .005 * math.sin(t * 46) * pop, py: .95);
    },
    front: (c, s, t) {
      final a = StickerMotion._beat(t, .8, .45);
      _s1Jolt(c, s, _s1A(30, 40), a, r: .1);
      _s1Jolt(c, s, _s1A(176, 46), a, r: .1);
    },
  ),
  'shock_hands': _Motion(
    (t) {
      final pop = StickerMotion._beat(t, 1.0, .25);
      return _P(dx: .007 * math.sin(t * 42) * (.3 + pop), sx: 1 + .04 * pop, sy: 1 + .04 * pop, py: .95);
    },
    front: (c, s, t) => _s1Jolt(c, s, _s1A(100, 12), StickerMotion._beat(t, 1.0, .4), r: .13),
  ),
  'shock_what': _Motion(
    (t) => _P(rot: .045 * math.sin(t * 2.6), dx: .01 * math.sin(t * 2.6), py: .95),
    front: (c, s, t) => StickerMotion._sparkles(c, s, t, [_s1A(30, 40), _s1A(176, 38)]),
  ),
  'shock_no': _Motion(
    (t) => _P(rot: .055 * math.sin(t * 9), dx: .008 * math.sin(t * 9), py: .95),
    front: (c, s, t) => _s1Sweat(c, s, t, [_s1A(50, 72), _s1A(46, 92)]),
  ),
  'shock_dizzy': _Motion(
    (t) => _P(rot: .09 * math.sin(t * 2.2), dx: .012 * math.sin(t * 1.1), py: .95),
    front: (c, s, t) => _s1Dizzy(c, s, t, _s1A(100, 26)),
  ),
  'shock_faint': _Motion(
    (t) {
      // يميل ويرجع ببطء (يكاد يغمى)
      final k = .5 + .5 * math.sin(t * 1.3);
      return _P(rot: .07 * k, dy: .012 * k, py: .95);
    },
    front: (c, s, t) => StickerMotion._dots(c, s, t, _s1A(30, 60)),
  ),

  // ═════════ ضحك ═════════
  'laugh_tears': _Motion(
    (t) => _P(dy: -.03 * _s1Laugh(t, 3.8), rot: .04 * math.sin(t * 26), sx: 1 + .015 * _s1Laugh(t, 3.8), sy: 1 + .03 * _s1Laugh(t, 3.8), py: .92),
    front: (c, s, t) => _s1Tears(c, s, t, [_s1A(70, 102), _s1A(130, 102)], spread: 1.4, hz: 1.8, r: .022),
  ),
  'laugh_roll': _Motion(
    (t) => _P(rot: .1 * math.sin(t * 8), dy: -.012 * _s1Laugh(t, 2.4), dx: .014 * math.sin(t * 4), py: .95),
    front: (c, s, t) => _s1Tears(c, s, t, [_s1A(68, 100), _s1A(128, 100)], spread: 1.3, hz: 1.6),
  ),
  'laugh_clap': _Motion(
    (t) {
      final clap = StickerMotion._beat(t, 3, .3);
      return _P(sx: 1 - .03 * clap, sy: 1 + .035 * clap, dy: -.012 * clap, py: .95);
    },
    front: (c, s, t) => StickerMotion._bursts(c, s, StickerMotion._beat(t, 3, .45), [_s1A(60, 150), _s1A(140, 150)], const Color(0xFFFFD43B)),
  ),
  'laugh_point': _Motion(
    (t) => _P(dy: -.02 * _s1Laugh(t, 3.2), rot: .03 * math.sin(t * 22), dx: .006 * math.sin(t * 6), py: .92),
    front: (c, s, t) => _s1Tears(c, s, t, [_s1A(66, 100), _s1A(122, 100)]),
  ),
  'laugh_grin': _Motion(
    (t) => _P(rot: .045 * math.sin(t * 7), dy: -.012 * _s1Laugh(t, 1.8), py: .92),
    front: (c, s, t) => StickerMotion._sparkles(c, s, t, [_s1A(168, 46), _s1A(34, 56), _s1A(176, 90)]),
  ),
  'laugh_wink': _Motion(
    (t) {
      final w = StickerMotion._beat(t, .7, .2);
      return _P(rot: -.02 + .035 * math.sin(t * 1.6) - .03 * w, dy: -.008 * w, py: .92);
    },
    front: (c, s, t) => StickerMotion._star(c, s, _s1A(118, 78), .07, StickerMotion._pulse(t, 1.4, .35)),
  ),

  // ═════════ القهوة ═════════
  'cof_cup': _Motion(
    (t) {
      // رشفة: يميل ويرجع
      final sip = StickerMotion._beat(t, .35, .35);
      return _P(rot: -.03 * sip, dy: .008 * math.sin(t * 2), py: .95);
    },
    front: (c, s, t) => _s1Steam(c, s, t, _s1A(150, 90)),
  ),
  'cof_pour': _Motion(
    (t) => _P(dy: .006 * math.sin(t * 2.4), rot: .015 * math.sin(t * 1.4), py: .95),
    front: (c, s, t) {
      // لمعة تنزل مع خط القهوة وشرارات عند الفنجان
      final q = _s1Fr(t * 1.4);
      final p = Offset(_s1A(150, 0).dx, _s1A(0, 58 + 58 * q).dy);
      c.drawCircle(Offset(p.dx * s.width, p.dy * s.height), s.width * .012, Paint()..color = const Color(0xFFFFE0B0).withValues(alpha: .9 * math.sin(q * math.pi)));
      _s1Steam(c, s, t, _s1A(150, 112), n: 2, h: .14);
    },
  ),
  'cof_welcome': _Motion(
    (t) => _P(rot: .035 * math.sin(t * 5), py: .95, px: .35),
    front: (c, s, t) => _s1Wave(c, s, t, _s1A(180, 92), 1),
  ),
  'cof_cold': _Motion(
    (t) => _P(dx: .004 * math.sin(t * 34), rot: .012 * math.sin(t * 29), py: .95),
    front: (c, s, t) {
      StickerMotion._sparkles(c, s, t, [_s1A(166, 96), _s1A(134, 100), _s1A(150, 118)]);
      _s1Sweat(c, s, t, [_s1A(136, 62)], drop: .12);
    },
  ),
  'cof_dates': _Motion(
    (t) => _P(dy: -.01 * _s1Laugh(t, 1.2), rot: .02 * math.sin(t * 2), py: .95),
    front: (c, s, t) {
      _s1Steam(c, s, t, _s1A(40, 100));
      StickerMotion._sparkles(c, s, t, [_s1A(158, 120), _s1A(176, 132)]);
    },
  ),
  'cof_enough': _Motion(
    (t) => _P(rot: .035 * math.sin(t * 8), dx: .006 * math.sin(t * 8), py: .95),
    front: (c, s, t) => StickerMotion._lines(c, s, _s1A(190, 130), .5 + .5 * math.sin(t * 8).abs()),
  ),

  // ═════════ الزعل ═════════
  'ang_steam': _Motion(
    (t) => _P(dx: .007 * math.sin(t * 40), sy: 1 + .012 * math.sin(t * 17), py: .95),
    back: (c, s, t) => StickerMotion._glowAt(c, s, const Offset(.5, .42), .5, const Color(0xFFFF3B30), .16 + .12 * math.sin(t * 3)),
    front: (c, s, t) => _s1Puffs(c, s, t, [_s1A(30, 46), _s1A(172, 40), _s1A(18, 70)], hz: .8),
  ),
  'ang_never': _Motion(
    (t) => _P(sx: 1 + .018 * math.sin(t * 1.8), sy: 1 + .018 * math.sin(t * 1.8), py: .95),
    back: (c, s, t) => StickerMotion._glowAt(c, s, _s1A(170, 44), .16, const Color(0xFFFF3B30), .3 + .3 * StickerMotion._pulse(t, 1.6, .5)),
  ),
  'ang_upset': _Motion(
    (t) => _P(dy: .012 * StickerMotion._beat(t, 1.1, .4), rot: .015 * math.sin(t * 2.2), py: .95),
    front: (c, s, t) => _s1Sweat(c, s, t, [_s1A(118, 100), _s1A(70, 108)], hz: .6, drop: .2),
  ),
  'ang_bored': _Motion(
    (t) {
      final sigh = .5 + .5 * math.sin(t * 1.2);
      return _P(sx: 1 + .012 * sigh, sy: 1 - .012 * sigh, rot: .018 * math.sin(t * .8), py: .95);
    },
    front: (c, s, t) => _s1Puffs(c, s, t, [_s1A(30, 50), _s1A(18, 36)], hz: .35, r: .035),
  ),
  'ang_ugh': _Motion(
    (t) {
      final nod = StickerMotion._beat(t, .5, .4);
      return _P(rot: .04 * nod, dy: .012 * nod, py: .95);
    },
    front: (c, s, t) => _s1Puffs(c, s, t, [_s1A(40, 60)], hz: .45, r: .04),
  ),
  'ang_fist': _Motion(
    (t) {
      final pump = StickerMotion._beat(t, 1.6, .3);
      return _P(dx: .01 * pump, dy: -.015 * pump, rot: -.03 * pump, sx: 1 + .04 * pump, sy: 1 + .04 * pump, py: .95);
    },
    back: (c, s, t) => StickerMotion._glowAt(c, s, _s1A(170, 46), .14, const Color(0xFFFF3B30), .25 + .35 * StickerMotion._pulse(t, 1.6, .35)),
  ),

  // ═════════ التوتر ═════════
  'nerv_sweat': _Motion(
    (t) => _P(dx: .006 * math.sin(t * 34), rot: .012 * math.sin(t * 27), py: .95),
    front: (c, s, t) => _s1Sweat(c, s, t, [_s1A(146, 62), _s1A(150, 86)], hz: .9, r: .02),
  ),
  'nerv_cover': _Motion(
    (t) => _P(rot: .04 * math.sin(t * 2.6), dy: .006 * math.sin(t * 5), py: .95),
    front: (c, s, t) => _s1Hearts(c, s, t, _s1A(100, 70), n: 2, color: const Color(0xFFFF8FA3)),
  ),
  'nerv_heart': _Motion(
    (t) {
      final b = StickerMotion._beat(t, 1.7, .2) + .6 * StickerMotion._beat(t + .16, 1.7, .2);
      return _P(sx: 1 + .03 * b, sy: 1 + .03 * b, dx: .004 * math.sin(t * 36), py: .95);
    },
    back: (c, s, t) => StickerMotion._glowAt(c, s, _s1A(160, 132), .2, const Color(0xFFFF3B5C), .2 + .5 * StickerMotion._beat(t, 1.7, .25)),
    front: (c, s, t) => _s1Beat(c, s, t, _s1A(160, 132), const Color(0xFFFF4D6D)),
  ),
  'nerv_luck': _Motion(
    (t) {
      final sag = .5 + .5 * math.sin(t * 1.1);
      return _P(dy: .012 * sag, sy: 1 - .012 * sag, rot: .012 * math.sin(t * .9), py: .95);
    },
    front: (c, s, t) => _s1Tears(c, s, t, [_s1A(76, 104)], spread: .3, hz: 1.0),
  ),
  'nerv_notme': _Motion(
    (t) => _P(rot: .05 * math.sin(t * 6), dx: .01 * math.sin(t * 6), py: .95),
    front: (c, s, t) => _s1Sweat(c, s, t, [_s1A(54, 66)], hz: .8, drop: .14),
  ),
  'nerv_bite': _Motion(
    (t) => _P(dx: .008 * math.sin(t * 48), rot: .01 * math.sin(t * 31), py: .95),
    front: (c, s, t) => _s1Sweat(c, s, t, [_s1A(52, 70), _s1A(150, 92)], hz: 1.0),
  ),

  // ═════════ المحقق ═════════
  'det_who': _Motion(
    (t) => _P(rot: .03 * math.sin(t * 1.5), dx: .01 * math.sin(t * 1.5), py: .95),
    front: (c, s, t) {
      _s1Lens(c, s, t, _s1A(112, 92), .12);
      StickerMotion._sparkles(c, s, t, [_s1A(176, 34), _s1A(22, 40)]);
    },
  ),
  'det_clue': _Motion(
    (t) => _P(dy: -.012 * _s1Laugh(t, 1.4), rot: .022 * math.sin(t * 2.2), py: .95),
    front: (c, s, t) => StickerMotion._sparkles(c, s, t, [_s1A(172, 100), _s1A(148, 96)]),
    glint: 3.6,
  ),
  'det_watch': _Motion(
    (t) => _P(dx: .02 * math.sin(t * 1.4), rot: .03 * math.sin(t * 1.4), py: .95),
    front: (c, s, t) {
      StickerMotion._star(c, s, _s1A(78, 80), .05, StickerMotion._pulse(t, 2.2, .45));
      StickerMotion._star(c, s, _s1A(116, 80), .05, StickerMotion._pulse(t + 1.0, 2.2, .45));
    },
  ),
  'det_obvious': _Motion(
    (t) {
      final poke = StickerMotion._beat(t, 1.2, .25);
      return _P(dx: -.012 * poke, sx: 1 + .03 * poke, sy: 1 + .03 * poke, rot: .01 * math.sin(t * 1.5), py: .95);
    },
  ),
  'det_solved': _Motion(
    (t) {
      final b = StickerMotion._beat(t, 1.4, .3);
      return _P(dy: -.03 * b, sx: 1 + .03 * b, sy: 1 + .03 * b, py: .95);
    },
    back: (c, s, t) => StickerMotion._glowAt(c, s, _s1A(166, 34), .22, const Color(0xFFFDE047), .3 + .6 * StickerMotion._pulse(t, 1.4, .5)),
    front: (c, s, t) => StickerMotion._sparkles(c, s, t, [_s1A(140, 26), _s1A(186, 50), _s1A(80, 80)]),
  ),
  'det_hmm': _Motion(
    (t) => _P(rot: .03 * math.sin(t * 1.3), dy: .006 * math.sin(t * 2.6), py: .95),
    front: (c, s, t) => StickerMotion._dots(c, s, t, _s1A(150, 20)),
  ),
};
