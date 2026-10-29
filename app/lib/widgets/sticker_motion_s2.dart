// حركات ملصقات الأسبوع الثاني (البريء، الاحتفال، الخاين، الفخامة، الحماس، الموسم الأول، الأساطير).
// جزء من sticker_motion.dart: يستخدم نفس الأدوات (_P، _Motion، _bounce، _beat…) والمواقع نسبة من حجم الملصق (٠–١).
// الحركة مبنية على تعبير كل ملصق: البريء خفيف (نادر)، والباقي أغنى (ملحمي وأسطوري). كل الرسم رخيص ويوقف مع الوضع الخفيف.
part of 'sticker_motion.dart';

/// أدوات رسم إضافية خاصة بهذي الحركات (قطرات، قلوب، شرار، ذيل صاروخ…).
abstract final class _S2 {
  static double _f(double x) => x - x.floorToDouble();

  static double beat(double t, double hz, double dur) => StickerMotion._beat(t, hz, dur);
  static double bounce(double t, double hz) => StickerMotion._bounce(t, hz);
  static double pulse(double t, double period, double dur) => StickerMotion._pulse(t, period, dur);

  /// قطرة (دمعة أو عرق) بحجم [r] عند [p].
  static void drop(Canvas c, Offset p, double r, Color color, double a) {
    if (a <= 0) return;
    final path = Path()
      ..moveTo(p.dx, p.dy - r * 1.9)
      ..cubicTo(p.dx + r * .5, p.dy - r * .9, p.dx + r, p.dy - r * .3, p.dx + r, p.dy + r * .4)
      ..cubicTo(p.dx + r, p.dy + r * 1.1, p.dx + r * .5, p.dy + r * 1.5, p.dx, p.dy + r * 1.5)
      ..cubicTo(p.dx - r * .5, p.dy + r * 1.5, p.dx - r, p.dy + r * 1.1, p.dx - r, p.dy + r * .4)
      ..cubicTo(p.dx - r, p.dy - r * .3, p.dx - r * .5, p.dy - r * .9, p.dx, p.dy - r * 1.9)
      ..close();
    c.drawPath(path, Paint()..color = color.withValues(alpha: a));
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .34
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF2A1520).withValues(alpha: .85 * a),
    );
    c.drawCircle(Offset(p.dx - r * .36, p.dy + r * .1), r * .24, Paint()..color = Colors.white.withValues(alpha: .9 * a));
  }

  /// قطرات تنزل من النقاط [from] وتتلاشى.
  static void drops(Canvas c, Size s, double t, List<Offset> from, {double period = 1.6, double fall = .18, double size = .026, Color color = const Color(0xFF8FD8FF)}) {
    for (final (i, o) in from.indexed) {
      final q = _f(t / period + i * .41);
      final a = q < .15 ? q / .15 : (q > .78 ? (1 - q) / .22 : 1.0);
      final p = Offset(o.dx * s.width, (o.dy + fall * Curves.easeIn.transform(q)) * s.height);
      drop(c, p, size * s.width, color, a.clamp(0.0, 1.0));
    }
  }

  /// قلوب صغيرة تطلع وتتلاشى.
  static void hearts(Canvas c, Size s, double t, Offset at, {int n = 3}) {
    for (var i = 0; i < n; i++) {
      final q = _f(t * .55 + i / n);
      final x = (at.dx + math.sin(q * 5 + i) * .03) * s.width;
      final y = (at.dy - q * .2) * s.height;
      final r = s.width * (.02 + .018 * math.sin(q * math.pi));
      final p = Path()
        ..moveTo(x, y + r * 1.5)
        ..cubicTo(x - r * 2.2, y - r * .2, x - r * 1.5, y - r * 1.6, x, y - r * .8)
        ..cubicTo(x + r * 1.5, y - r * 1.6, x + r * 2.2, y - r * .2, x, y + r * 1.5)
        ..close();
      final a = math.sin(q * math.pi);
      c.drawPath(p, Paint()..color = const Color(0xFFFF4D6A).withValues(alpha: a));
      c.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .36
          ..color = const Color(0xFF2A1520).withValues(alpha: .8 * a),
      );
    }
  }

  /// شرار ينفجر من نقطة كل [period] ثانية (ألعاب نارية).
  static void spark(Canvas c, Size s, double t, Offset at, Color color, {double period = 1.9, double phase = 0, double radius = .13, int n = 10}) {
    final q = _f(t / period + phase);
    if (q > .62) return;
    final b = q / .62;
    final o = Offset(at.dx * s.width, at.dy * s.height);
    for (var j = 0; j < n; j++) {
      final a = j * 2 * math.pi / n + phase * 7;
      final r = s.width * radius * Curves.easeOut.transform(b);
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * r, s.width * .014 * (1 - b * .5), Paint()..color = color.withValues(alpha: 1 - b));
    }
  }

  /// لمعة تدور حول هالة الملاك.
  static void haloSpin(Canvas c, Size s, double t, Offset at, double rx, double ry) {
    final a = t * 2.2;
    final p = Offset(at.dx + math.cos(a) * rx, at.dy + math.sin(a) * ry);
    StickerMotion._star(c, s, p, .045, .6 + .4 * math.sin(t * 6));
  }

  /// ذيل نار الصاروخ: جزيئات تطلع من [at] باتجاه [dir].
  static void trail(Canvas c, Size s, double t, Offset at, Offset dir, {double length = .24}) {
    for (var i = 0; i < 8; i++) {
      final q = _f(t * 1.9 + i / 8);
      final p = Offset((at.dx + dir.dx * q * length) * s.width + (rnd(i, 3) - .5) * s.width * .03 * q, (at.dy + dir.dy * q * length) * s.height);
      final r = s.width * (.034 * (1 - q) + .008);
      c.drawCircle(p, r, Paint()..color = Color.lerp(const Color(0xFFFFE08A), const Color(0xFFFF7A18), q)!.withValues(alpha: .9 * (1 - q)));
    }
  }

  /// يراعات صغيرة تدور حول الفانوس.
  static void fireflies(Canvas c, Size s, double t, Offset at) {
    for (var i = 0; i < 6; i++) {
      final a = t * (.7 + rnd(i, 2) * .8) + i * 1.9;
      final r = .07 + rnd(i, 5) * .09;
      final p = Offset((at.dx + math.cos(a) * r) * s.width, (at.dy + math.sin(a * 1.3) * r * 1.2) * s.height);
      final al = .35 + .65 * (.5 + .5 * math.sin(t * 4 + i * 2));
      c.drawCircle(
        p,
        s.width * .012,
        Paint()
          ..color = const Color(0xFFFFE08A).withValues(alpha: al)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  /// وميض عشوائي للنار والشموع (٠٫٧–١).
  static double flicker(double t, [int seed = 0]) => .85 + .15 * math.sin(t * 13 + seed) * math.sin(t * 7.3 + seed * 2);
}

final Map<String, _Motion> _s2Motions = {
  // ───────────── البريء (نادر: حركة خفيفة) ─────────────
  'inn_me': _Motion(
    (t) {
      // يرفع كتوفه "أنا؟" كل شوي
      final shrug = _S2.beat(t, .38, .3);
      return _P(dy: -.012 * shrug, sy: 1 - .012 * shrug, sx: 1 + .008 * shrug, py: .92);
    },
    front: (c, s, t) => _S2.drops(c, s, t, [Offset(0.655, 0.285)], period: 2.6, fall: .2, size: .028),
  ),
  'inn_cry': _Motion(
    (t) {
      // نشيج: ارتجافة سريعة وبعدها هدوء
      final sob = _S2.beat(t, .75, .5);
      return _P(dy: .008 * math.sin(t * 24) * sob + .004 * math.sin(t * 1.5), rot: .012 * math.sin(t * 21) * sob, py: .95);
    },
    front: (c, s, t) => _S2.drops(c, s, t, [Offset(0.451, 0.414), Offset(0.575, 0.414)], period: 1.25, fall: .2, size: .03),
  ),
  'inn_trust': _Motion(
    (t) => _P(rot: .022 * math.sin(t * 1.6), dy: -.008 * math.sin(t * 3.2), py: .95),
    front: (c, s, t) => _S2.hearts(c, s, t, Offset(0.249, 0.516)),
  ),
  'inn_halo': _Motion(
    (t) => _P(dy: -.018 * math.sin(t * 1.7), rot: .012 * math.sin(t * 1.1)),
    back: (c, s, t) => StickerMotion._glowAt(c, s, Offset(0.502, 0.134), .2, const Color(0xFFFFE08A), .3 + .2 * math.sin(t * 2.4)),
    front: (c, s, t) {
      _S2.haloSpin(c, s, t, Offset(0.502, 0.134), 0.118, 0.031);
      StickerMotion._sparkles(c, s, t, [Offset(0.710, 0.197), Offset(0.307, 0.238)]);
    },
  ),
  'inn_hands': _Motion(
    (t) {
      // توتر: يرتجف أكثر ثم يهدأ شوي
      final k = .55 + .45 * math.sin(t * 1.7);
      return _P(dx: .004 * math.sin(t * 47) * k, rot: .008 * math.sin(t * 39) * k, py: .95);
    },
    front: (c, s, t) => _S2.drops(c, s, t, [Offset(0.669, 0.297), Offset(0.379, 0.263)], period: 1.5, fall: .2, size: .028),
  ),
  'inn_pls': _Motion(
    (t) => _P(sy: 1 + .018 * math.sin(t * 2.2), sx: 1 - .006 * math.sin(t * 2.2), py: .95),
    front: (c, s, t) {
      // لمعة دموع في العيون
      StickerMotion._star(c, s, Offset(0.433, 0.346), .035, StickerMotion._pulse(t, 1.8, .6));
      StickerMotion._star(c, s, Offset(0.572, 0.346), .035, StickerMotion._pulse(t + .9, 1.8, .6));
      _S2.drops(c, s, t, [Offset(0.332, 0.431), Offset(0.657, 0.431)], period: 2.2, fall: .14, size: .02);
    },
  ),

  // ───────────── الاحتفال (ملحمي) ─────────────
  'par_kafu': _Motion(
    (t) {
      // رفع الإبهام: ضغطة سريعة مع ميلة
      final pump = _S2.beat(t, 1.4, .32);
      return _P(sx: 1 + .05 * pump, sy: 1 + .05 * pump, rot: -.03 * pump, dy: -.03 * pump - .01 * _S2.bounce(t, 2.8), py: .95);
    },
    front: (c, s, t) {
      StickerMotion._bursts(c, s, _S2.beat(t, 1.4, .45), [Offset(0.705, 0.493)], const Color(0xFFFFE08A));
      StickerMotion._sparkles(c, s, t, [Offset(0.211, 0.246), Offset(0.775, 0.269)]);
    },
  ),
  'par_won': _Motion(
    (t) => _P(dy: -.07 * _S2.bounce(t, 1.8), sx: 1 + .03 * _S2.bounce(t, 1.8), py: .95),
    front: (c, s, t) {
      StickerMotion._confetti(c, s, t);
      StickerMotion._star(c, s, Offset(0.685, 0.498), .06, _S2.pulse(t, 1.4, .5));
    },
  ),
  'par_clap': _Motion(
    (t) {
      final clap = _S2.beat(t, 3, .3);
      return _P(sx: 1 - .05 * clap, sy: 1 + .03 * clap, dy: -.01 * clap, py: .95);
    },
    front: (c, s, t) => StickerMotion._bursts(c, s, _S2.beat(t, 3, .45), [Offset(0.350, 0.655), Offset(0.628, 0.655)], const Color(0xFFFFE08A)),
  ),
  'par_fireworks': _Motion(
    (t) => _P(rot: .04 * math.sin(t * 5), dy: -.015 * _S2.bounce(t, 2), py: .95),
    back: (c, s, t) {
      _S2.spark(c, s, t, Offset(0.218, 0.194), const Color(0xFFFF5D73), period: 1.8, phase: 0);
      _S2.spark(c, s, t, Offset(0.773, 0.179), const Color(0xFFFFD84D), period: 1.8, phase: .33);
      _S2.spark(c, s, t, Offset(0.802, 0.601), const Color(0xFF4CC9F0), period: 1.8, phase: .66, radius: .1);
    },
    front: (c, s, t) => StickerMotion._sparkles(c, s, t, [Offset(0.306, 0.593)]),
  ),
  'par_dance': _Motion(
    (t) => _P(rot: .13 * math.sin(t * math.pi * 1.6), dy: -.04 * _S2.bounce(t, 3.2), py: .95),
    front: (c, s, t) => StickerMotion._notes(c, s, t),
  ),
  'par_best': _Motion(
    (t) => _P(dy: -.02 * math.sin(t * 2.4), sx: 1 + .014 * math.sin(t * 2.4)),
    glint: 3,
    front: (c, s, t) {
      StickerMotion._star(c, s, Offset(0.737, 0.578), .06, .5 + .5 * _S2.pulse(t, 1.6, .5));
      StickerMotion._star(c, s, Offset(0.428, 0.362), .04, _S2.pulse(t, 2.4, .5));
      StickerMotion._sparkles(c, s, t, [Offset(0.235, 0.270), Offset(0.799, 0.301)]);
    },
  ),

  // ───────────── الخاين (ملحمي) ─────────────
  'tr_evil': _Motion(
    (t) => _P(sx: 1 + .02 * math.sin(t * 1.8), sy: 1 + .02 * math.sin(t * 1.8), rot: .025 * math.sin(t * 1.2), py: .95),
    back: (c, s, t) => StickerMotion._aura(c, s, t, const Color(0xFF7F1D1D)),
    front: (c, s, t) => StickerMotion._eyes(c, s, t, [Offset(0.417, 0.379), Offset(0.580, 0.379)], const Color(0xFFFF2B2B)),
  ),
  'tr_dagger': _Motion(
    (t) {
      final q = StickerMotion._frac(t / 1.6);
      final lunge = q < .12 ? Curves.easeOut.transform(q / .12) : (q < .35 ? 1 - Curves.easeIn.transform((q - .12) / .23) : 0.0);
      return _P(dx: .05 * lunge, sx: 1 + .07 * lunge, sy: 1 + .07 * lunge, rot: .07 * lunge, py: .9);
    },
    front: (c, s, t) {
      final q = StickerMotion._frac(t / 1.6);
      StickerMotion._star(c, s, Offset(0.767, 0.354), .075, q > .08 && q < .3 ? math.sin((q - .08) / .22 * math.pi) : 0);
      StickerMotion._lines(c, s, Offset(0.168, 0.385), q < .2 ? 1 - q / .2 : 0);
    },
  ),
  'tr_poker': _Motion(
    (t) {
      // وجه بوكر: يطالع جنب بدون أي تعبير ويرجع
      final q = StickerMotion._frac(t / 4);
      final x = q < .15 ? Curves.easeInOut.transform(q / .15) : (q < .5 ? 1.0 : (q < .65 ? 1 - Curves.easeInOut.transform((q - .5) / .15) : 0.0));
      return _P(dx: .035 * x, rot: -.025 * x);
    },
    front: (c, s, t) => StickerMotion._dots(c, s, t, Offset(0.685, 0.154)),
  ),
  'tr_plan': _Motion(
    (t) {
      // يفرك أصابعه: ضغطات صغيرة وميلة بطيئة
      final tap = _S2.beat(t, 2.2, .22);
      return _P(dy: .007 * tap, sy: 1 - .008 * tap, rot: .022 * math.sin(t * 1.4), py: .95);
    },
    front: (c, s, t) => StickerMotion._eyes(c, s, t, [Offset(0.428, 0.376), Offset(0.583, 0.376)], const Color(0xFFFF2B2B)),
  ),
  'tr_mask': _Motion(
    (t) => _P(rot: .07 * math.sin(t * 2.2), sx: 1 + .02 * math.sin(t * 4.4), px: .35, py: .9),
    front: (c, s, t) => StickerMotion._sparkles(c, s, t, [Offset(0.639, 0.494), Offset(0.570, 0.570)]),
  ),
  'tr_laugh': _Motion(
    (t) => _P(rot: .05 * math.sin(t * 28), dy: -.02 * _S2.bounce(t, 2.5), sy: 1 + .03 * _S2.bounce(t, 2.5), py: .95),
    back: (c, s, t) {
      StickerMotion._glowAt(c, s, Offset(0.264, 0.568), .22, const Color(0xFFFF8A1F), .5 * _S2.flicker(t, 1));
      StickerMotion._glowAt(c, s, Offset(0.736, 0.568), .22, const Color(0xFFFF8A1F), .5 * _S2.flicker(t, 4));
      StickerMotion._embers(c, s, t, [.1, .9]);
    },
  ),

  // ───────────── الفخامة (أسطوري: أغنى حركة) ─────────────
  'vip_falcon': _Motion(
    (t) => _P(dy: -.02 * math.sin(t * 1.8), rot: .01 * math.sin(t * 1.2)),
    glint: 3.2,
    front: (c, s, t) {
      StickerMotion._star(c, s, Offset(0.671, 0.385), .04, _S2.pulse(t, 2.2, .5));
      StickerMotion._sparkles(c, s, t, [Offset(0.787, 0.486), Offset(0.224, 0.347)]);
    },
  ),
  'vip_bisht': _Motion(
    (t) => _P(dy: .012 * math.sin(t * 1.3), sx: 1 + .012 * math.sin(t * 1.3), sy: 1 + .012 * math.sin(t * 1.3), py: .95),
    glint: 2.8,
    front: (c, s, t) => StickerMotion._sparkles(c, s, t, [Offset(0.236, 0.352), Offset(0.427, 0.758), Offset(0.580, 0.758)]),
  ),
  'vip_gg': _Motion(
    (t) {
      final pump = _S2.beat(t, 1.8, .28);
      return _P(dy: -.03 * pump - .008 * _S2.bounce(t, 3.6), rot: -.04 * pump, sx: 1 + .03 * pump, sy: 1 + .03 * pump, py: .95);
    },
    front: (c, s, t) {
      StickerMotion._sparkles(c, s, t, [Offset(0.199, 0.253), Offset(0.245, 0.500), Offset(0.778, 0.284)]);
      StickerMotion._star(c, s, Offset(0.554, 0.377), .045, _S2.pulse(t, 1.8, .4));
    },
  ),
  'vip_crown': _Motion(
    (t) => _P(rot: .04 * math.sin(t * 2), dy: .02 * _S2.bounce(t, 1), py: .9),
    glint: 3,
    front: (c, s, t) {
      StickerMotion._sparkles(c, s, t, [Offset(0.434, 0.148), Offset(0.559, 0.102), Offset(0.684, 0.148)]);
      StickerMotion._star(c, s, Offset(0.559, 0.254), .04, _S2.pulse(t, 2, .4));
    },
  ),
  'vip_gold': _Motion(
    (t) => _P(dy: -.02 * _S2.bounce(t, 2), sx: 1 + .02 * _S2.bounce(t, 2), py: .95),
    front: (c, s, t) {
      StickerMotion._coins(c, s, t);
      StickerMotion._sparkles(c, s, t, [Offset(0.686, 0.717), Offset(0.786, 0.355), Offset(0.223, 0.293)]);
      StickerMotion._star(c, s, Offset(0.416, 0.362), .04, _S2.pulse(t, 1.7, .4));
      StickerMotion._star(c, s, Offset(0.578, 0.362), .04, _S2.pulse(t + .5, 1.7, .4));
    },
  ),
  'vip_cool': _Motion(
    (t) => _P(dy: .025 * _S2.bounce(t, 1.1), rot: .03 * math.sin(t * math.pi * 1.1), py: .9),
    front: (c, s, t) {
      StickerMotion._star(c, s, Offset(0.436, 0.372), .05, _S2.pulse(t, 2.5, .45));
      StickerMotion._sparkles(c, s, t, [Offset(0.236, 0.272), Offset(0.790, 0.242)]);
    },
  ),

  // ───────────── الحماس (ملحمي) ─────────────
  'hype_fire': _Motion(
    (t) => _P(sx: 1 + .02 * math.sin(t * 13), sy: 1 + .035 * math.sin(t * 11), rot: .02 * math.sin(t * 17), py: .95),
    back: (c, s, t) {
      StickerMotion._glowAt(c, s, Offset(0.264, 0.569), .24, const Color(0xFFFF8A1F), .55 * _S2.flicker(t, 2));
      StickerMotion._glowAt(c, s, Offset(0.736, 0.569), .24, const Color(0xFFFF8A1F), .55 * _S2.flicker(t, 5));
      StickerMotion._embers(c, s, t, [.1, .9, .5]);
    },
  ),
  'hype_go': _Motion(
    (t) {
      final pump = _S2.beat(t, 2, .3);
      return _P(sx: 1 + .08 * pump, sy: 1 + .08 * pump, rot: -.05 * pump, dy: -.02 * pump, py: .95);
    },
    front: (c, s, t) => StickerMotion._lines(c, s, Offset(0.775, 0.378), _S2.beat(t, 2, .3)),
  ),
  'hype_strong': _Motion(
    (t) {
      final flex = _S2.beat(t, 1.4, .35);
      return _P(sx: 1 + .07 * flex, sy: 1 + .05 * flex, rot: .03 * math.sin(t * 30) * flex, py: .95);
    },
    front: (c, s, t) => StickerMotion._bursts(c, s, _S2.beat(t, 1.4, .45), [Offset(0.199, 0.409), Offset(0.802, 0.409)], const Color(0xFFFFD166)),
  ),
  'hype_100': _Motion(
    (t) {
      final pop = _S2.beat(t, 1.5, .3);
      return _P(sx: 1 + .07 * pop, sy: 1 + .07 * pop, rot: .04 * math.sin(t * 26) * pop, py: .95);
    },
    front: (c, s, t) {
      StickerMotion._sparkles(c, s, t, [Offset(0.215, 0.284), Offset(0.787, 0.346)]);
      StickerMotion._star(c, s, Offset(0.764, 0.640), .05, _S2.pulse(t, 1.5, .35));
    },
  ),
  'hype_rocket': _Motion(
    (t) => _P(dy: -.04 - .025 * math.sin(t * 2.4), dx: .005 * math.sin(t * 40), py: .9),
    front: (c, s, t) {
      _S2.trail(c, s, t, Offset(0.691, 0.308), const Offset(-.7, .7), length: .13);
      StickerMotion._sparkles(c, s, t, [Offset(0.219, 0.292), Offset(0.822, 0.578)]);
    },
  ),
  'hype_eyes': _Motion(
    (t) {
      // تركيز: يقرب شوي ويرجع
      final z = _S2.pulse(t, 1.6, .9);
      return _P(sx: 1 + .04 * z, sy: 1 + .04 * z, dy: -.01 * z);
    },
    back: (c, s, t) => StickerMotion._rings(c, s, t, Offset(0.501, 0.383), const Color(0xFF5EEAD4)),
  ),

  // ───────────── الموسم الأول (ملحمي) ─────────────
  's1_night': _Motion(
    (t) => _P(rot: .04 * math.sin(t * 1.4), py: .9),
    back: (c, s, t) => StickerMotion._glowAt(c, s, Offset(0.757, 0.246), .2, const Color(0xFFFDE68A), .4 + .3 * math.sin(t * 2)),
    front: (c, s, t) => StickerMotion._sparkles(c, s, t, [Offset(0.257, 0.261), Offset(0.219, 0.448), Offset(0.653, 0.104)]),
  ),
  's1_champ': _Motion(
    (t) => _P(dy: -.06 * _S2.bounce(t, 1.6), py: .95),
    front: (c, s, t) {
      StickerMotion._sparkles(c, s, t, [Offset(0.182, 0.269), Offset(0.767, 0.215)]);
      StickerMotion._star(c, s, Offset(0.674, 0.453), .055, _S2.pulse(t, 1.6, .5));
      StickerMotion._confetti(c, s, t, count: 7);
    },
  ),
  's1_tea': _Motion(
    (t) => _P(rot: .03 * math.sin(t * 1.6), py: .9),
    front: (c, s, t) => StickerMotion._steam(c, s, t, Offset(0.697, 0.578)),
  ),
  's1_lantern': _Motion(
    (t) => _P(rot: .05 * math.sin(t * 2.0), px: .8, py: .85),
    back: (c, s, t) => StickerMotion._glowAt(c, s, Offset(0.710, 0.563), .24, const Color(0xFFFFC857), .5 * _S2.flicker(t, 3)),
    front: (c, s, t) => _S2.fireflies(c, s, t, Offset(0.710, 0.563)),
  ),
  's1_sleep': _Motion(
    (t) => _P(sx: 1 + .02 * math.sin(t * 1.5), sy: 1 + .028 * math.sin(t * 1.5), rot: .025 * math.sin(t * 1.2), py: .95),
    front: (c, s, t) => StickerMotion._zzz(c, s, t, Offset(0.752, 0.281)),
  ),
  's1_star': _Motion(
    (t) => _P(rot: .04 * math.sin(t * 2), dy: -.02 * math.sin(t * 2), py: .9),
    front: (c, s, t) {
      StickerMotion._star(c, s, Offset(0.742, 0.645), .09, .4 + .6 * _S2.pulse(t, 1.4, .5));
      StickerMotion._sparkles(c, s, t, [Offset(0.234, 0.268), Offset(0.804, 0.291), Offset(0.442, 0.353)]);
    },
  ),

  // ───────────── الأساطير (أسطوري: أغنى حركة) ─────────────
  'leg_king': _Motion(
    (t) => _P(dy: -.02 * math.sin(t * 1.6), rot: .02 * math.sin(t * 1.1)),
    glint: 3.4,
    back: (c, s, t) => StickerMotion._aura(c, s, t, const Color(0xFFFCD34D)),
    front: (c, s, t) => StickerMotion._sparkles(c, s, t, [Offset(0.379, 0.148), Offset(0.504, 0.095), Offset(0.630, 0.148), Offset(0.260, 0.392)]),
  ),
  'leg_genius': _Motion(
    (t) {
      // "جتني فكرة": نطة صغيرة مع كل ومضة
      return _P(dy: .03 * _S2.beat(t, .7, .25), py: .9);
    },
    back: (c, s, t) => StickerMotion._glowAt(c, s, Offset(0.723, 0.222), .2, const Color(0xFFFDE047), .3 + .7 * _S2.pulse(t, 1.43, .4)),
    front: (c, s, t) => StickerMotion._sparkles(c, s, t, [Offset(0.434, 0.385), Offset(0.575, 0.385), Offset(0.241, 0.296)]),
  ),
  'leg_ghost': _Motion(
    (t) => _P(dy: -.04 + .04 * math.sin(t * 2), dx: .012 * math.sin(t * 1.1), rot: .05 * math.sin(t * 1.4), alpha: .45 + .55 * (.5 + .5 * math.cos(t * 1.3))),
  ),
  'leg_mind': _Motion(
    (t) => _P(dx: .004 * math.sin(t * 50), sx: 1 + .01 * math.sin(t * 4)),
    back: (c, s, t) => StickerMotion._rings(c, s, t, Offset(0.500, 0.232), const Color(0xFFC084FC)),
    front: (c, s, t) => StickerMotion._eyes(c, s, t, [Offset(0.435, 0.422), Offset(0.566, 0.422)], const Color(0xFFC084FC)),
  ),
  'leg_storm': _Motion(
    (t) {
      final hit = _S2.pulse(t, 1.7, .25);
      return _P(dx: .02 * math.sin(t * 60) * hit, rot: .02 * math.sin(t * 7));
    },
    back: (c, s, t) => StickerMotion._glowAt(c, s, Offset(0.494, 0.386), .55, const Color(0xFFE0F2FE), .7 * _S2.pulse(t, 1.7, .2)),
    front: (c, s, t) {
      StickerMotion._star(c, s, Offset(0.217, 0.255), .08, _S2.pulse(t, 1.7, .3));
      StickerMotion._star(c, s, Offset(0.780, 0.270), .08, _S2.pulse(t + .2, 1.7, .3));
    },
  ),
  'leg_legend': _Motion(
    (t) => _P(dy: -.025 * math.sin(t * 2), sx: 1 + .02 * math.sin(t * 2)),
    glint: 3,
    back: (c, s, t) => StickerMotion._aura(c, s, t, const Color(0xFFFDE68A)),
    front: (c, s, t) => StickerMotion._orbit(c, s, t),
  ),
};
