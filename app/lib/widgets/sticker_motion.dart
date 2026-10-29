import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/shop.dart';
import 'fx.dart';

part 'sticker_motion_s2.dart';

/// الملصقات الملحمية والأسطورية تتحرك حسب تعبيرها: اللي يضحك يهتز، واللي يرقص يتمايل، والنعسان تطلع منه
/// ززز، والشاي يطلع منه بخار… الصورة نفسها تتحرك، ومعها رسم بسيط (لمعات، قصاصات، شرار…).
/// المواقع كلها نسبة من حجم الملصق (٠–١).
abstract final class StickerMotion {
  static bool has(Sticker s) => _motions.containsKey(s.id);

  /// الملصق يتحرك (FxClock يوقف لو الحركات خفيفة).
  static Widget build(Sticker s, double size) {
    final m = _motions[s.id]!;
    final img = Image.asset(s.asset, width: size, height: size, filterQuality: FilterQuality.medium);
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: FxClock(
          builder: (context, time) => AnimatedBuilder(
            animation: time,
            child: img,
            builder: (context, child) {
              final t = time.value;
              final p = m.pose(t);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  if (m.back != null) Positioned.fill(child: CustomPaint(painter: _Fx(m.back!, t))),
                  Positioned.fill(
                    child: Opacity(
                      opacity: p.alpha.clamp(0.0, 1.0),
                      child: Transform(
                        alignment: FractionalOffset(p.px, p.py),
                        transform: Matrix4.identity()
                          ..translateByDouble(p.dx * size, p.dy * size, 0, 1)
                          ..rotateZ(p.rot)
                          ..scaleByDouble(p.sx, p.sy, 1, 1),
                        child: m.glint == null ? child : _glint(child!, t, m.glint!),
                      ),
                    ),
                  ),
                  if (m.front != null) Positioned.fill(child: CustomPaint(painter: _Fx(m.front!, t))),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ───────────── الحركات ─────────────

  static final Map<String, _Motion> _motions = {
    // الاحتفال
    'par_kafu': _Motion(
      (t) => _P(dy: -.03 * _bounce(t, 1.6), rot: .06 * math.sin(t * 10) * _beat(t, 1.6, .25), py: .9),
      front: (c, s, t) => _sparkles(c, s, t, const [Offset(.84, .44), Offset(.72, .3)]),
    ),
    'par_won': _Motion(
      (t) => _P(dy: -.07 * _bounce(t, 1.8), sx: 1 + .03 * _bounce(t, 1.8), py: .95),
      front: (c, s, t) {
        _confetti(c, s, t);
        _sparkles(c, s, t, const [Offset(.74, .34)]);
      },
    ),
    'par_clap': _Motion(
      (t) {
        final clap = _beat(t, 3, .3);
        return _P(sx: 1 - .05 * clap, sy: 1 + .03 * clap, dy: -.01 * clap);
      },
      front: (c, s, t) =>
          _bursts(c, s, _beat(t, 3, .45), const [Offset(.28, .6), Offset(.72, .6)], const Color(0xFFFFE08A)),
    ),
    'par_fireworks': _Motion(
      (t) => _P(rot: .05 * math.sin(t * 6), dy: -.02 * _bounce(t, 2), py: .9),
      back: (c, s, t) => _fireworks(c, s, t),
    ),
    'par_dance': _Motion(
      (t) => _P(rot: .13 * math.sin(t * math.pi * 1.6), dy: -.04 * _bounce(t, 3.2), py: .95),
      front: (c, s, t) => _notes(c, s, t),
    ),
    'par_best': _Motion(
      (t) => _P(dy: -.025 * math.sin(t * 2.4), sx: 1 + .02 * math.sin(t * 2.4)),
      front: (c, s, t) => _sparkles(c, s, t, const [Offset(.86, .62), Offset(.14, .3), Offset(.86, .24)]),
      glint: 3,
    ),
    // الخاين
    'tr_evil': _Motion(
      (t) => _P(sx: 1 + .02 * math.sin(t * 2), sy: 1 + .02 * math.sin(t * 2), rot: .03 * math.sin(t * 1.3)),
      back: (c, s, t) => _aura(c, s, t, const Color(0xFF7F1D1D)),
      front: (c, s, t) => _eyes(c, s, t, const [Offset(.4, .37), Offset(.6, .37)], const Color(0xFFFF2B2B)),
    ),
    'tr_dagger': _Motion(
      (t) {
        final q = _frac(t / 1.6);
        final lunge = q < .12
            ? Curves.easeOut.transform(q / .12)
            : (q < .35 ? 1 - Curves.easeIn.transform((q - .12) / .23) : 0.0);
        return _P(dx: .06 * lunge, sx: 1 + .08 * lunge, sy: 1 + .08 * lunge, rot: .08 * lunge);
      },
      front: (c, s, t) {
        final q = _frac(t / 1.6);
        _star(c, s, const Offset(.86, .52), .07, q > .08 && q < .3 ? math.sin((q - .08) / .22 * math.pi) : 0);
        _lines(c, s, const Offset(.08, .5), q < .2 ? 1 - q / .2 : 0);
      },
    ),
    'tr_poker': _Motion((t) {
      // يطالع جنب بدون أي تعبير: يزحف شوي ويوقف، ويرجع
      final q = _frac(t / 4);
      final x = q < .15
          ? Curves.easeInOut.transform(q / .15)
          : (q < .5 ? 1.0 : (q < .65 ? 1 - Curves.easeInOut.transform((q - .5) / .15) : 0.0));
      return _P(dx: .035 * x, rot: -.025 * x);
    }, front: (c, s, t) => _dots(c, s, t, const Offset(.82, .2))),
    'tr_plan': _Motion(
      (t) => _P(dy: .015 * math.sin(t * 3), sx: 1 + .015 * math.sin(t * 9), rot: .02 * math.sin(t * 1.5)),
      front: (c, s, t) => _eyes(c, s, t, const [Offset(.4, .36), Offset(.6, .36)], const Color(0xFFFF2B2B)),
    ),
    'tr_mask': _Motion(
      (t) => _P(rot: .1 * math.sin(t * 2.2), sx: 1 + .03 * math.sin(t * 4.4), py: .9),
      front: (c, s, t) => _sparkles(c, s, t, const [Offset(.78, .5), Offset(.66, .44)]),
    ),
    'tr_laugh': _Motion(
      (t) => _P(rot: .05 * math.sin(t * 28), dy: -.02 * _bounce(t, 2.5), sy: 1 + .03 * _bounce(t, 2.5)),
      back: (c, s, t) => _embers(c, s, t, const [.12, .88]),
    ),
    // الفخامة
    'vip_falcon': _Motion(
      (t) => _P(dy: -.02 * math.sin(t * 1.8)),
      front: (c, s, t) => _sparkles(c, s, t, const [Offset(.78, .5), Offset(.2, .3)]),
      glint: 3.2,
    ),
    'vip_bisht': _Motion((t) => _P(dy: .015 * math.sin(t * 1.2), rot: .02 * math.sin(t * .9)), glint: 2.8),
    'vip_gg': _Motion(
      (t) => _P(dy: -.03 * _bounce(t, 1.8), rot: .05 * math.sin(t * 9) * _beat(t, 1.8, .25), py: .9),
      front: (c, s, t) => _sparkles(c, s, t, const [Offset(.84, .5), Offset(.2, .28), Offset(.86, .2)]),
    ),
    'vip_crown': _Motion(
      (t) => _P(rot: .05 * math.sin(t * 2), dy: .02 * _bounce(t, 1), py: .9),
      front: (c, s, t) => _sparkles(c, s, t, const [Offset(.62, .1), Offset(.42, .14), Offset(.78, .16)]),
    ),
    'vip_gold': _Motion(
      (t) => _P(dy: -.02 * _bounce(t, 2), sx: 1 + .02 * _bounce(t, 2)),
      front: (c, s, t) {
        _coins(c, s, t);
        _sparkles(c, s, t, const [Offset(.74, .62), Offset(.38, .38), Offset(.6, .38)]);
      },
    ),
    'vip_cool': _Motion(
      (t) => _P(dy: .025 * _bounce(t, 1.1), rot: .03 * math.sin(t * math.pi * 1.1), py: .9),
      front: (c, s, t) => _star(c, s, const Offset(.4, .38), .06, _pulse(t, 2.5, .4)),
    ),
    // الحماس
    'hype_fire': _Motion(
      (t) => _P(sx: 1 + .02 * math.sin(t * 13), sy: 1 + .035 * math.sin(t * 11), rot: .02 * math.sin(t * 17), py: .95),
      back: (c, s, t) => _embers(c, s, t, const [.1, .9, .5]),
    ),
    'hype_go': _Motion((t) {
      final pump = _beat(t, 2, .3);
      return _P(sx: 1 + .08 * pump, sy: 1 + .08 * pump, rot: -.05 * pump, dy: -.02 * pump);
    }, front: (c, s, t) => _lines(c, s, const Offset(.92, .2), _beat(t, 2, .3))),
    'hype_strong': _Motion((t) {
      final flex = _beat(t, 1.4, .35);
      return _P(sx: 1 + .07 * flex, sy: 1 + .05 * flex, rot: .03 * math.sin(t * 30) * flex);
    }, front: (c, s, t) => _bursts(c, s, _beat(t, 1.4, .45), const [Offset(.84, .52)], const Color(0xFFFFD166))),
    'hype_100': _Motion((t) {
      final pop = _beat(t, 1.5, .3);
      return _P(sx: 1 + .07 * pop, sy: 1 + .07 * pop, rot: .04 * math.sin(t * 26) * pop);
    }, front: (c, s, t) => _sparkles(c, s, t, const [Offset(.86, .58), Offset(.66, .74)])),
    'hype_rocket': _Motion(
      (t) => _P(dy: -.05 - .03 * math.sin(t * 2.4), dx: .006 * math.sin(t * 40), py: .9),
      back: (c, s, t) => _exhaust(c, s, t),
      front: (c, s, t) => _sparkles(c, s, t, const [Offset(.9, .1), Offset(.12, .22)]),
    ),
    'hype_eyes': _Motion(
      (t) => _P(sx: 1 + .06 * _bounce(t, .8), sy: 1 + .06 * _bounce(t, .8), dy: -.02 * _bounce(t, .8)),
      back: (c, s, t) => _rings(c, s, t, const Offset(.5, .38), const Color(0xFF5EEAD4)),
    ),
    // الموسم الأول
    's1_night': _Motion(
      (t) => _P(rot: .04 * math.sin(t * 1.4), py: .9),
      back: (c, s, t) => _glowAt(c, s, const Offset(.78, .22), .14, const Color(0xFFFDE68A), .4 + .3 * math.sin(t * 2)),
      front: (c, s, t) => _sparkles(c, s, t, const [Offset(.14, .24), Offset(.88, .08), Offset(.08, .5)]),
    ),
    's1_champ': _Motion(
      (t) => _P(dy: -.06 * _bounce(t, 1.6), py: .95),
      front: (c, s, t) {
        _sparkles(c, s, t, const [Offset(.76, .4), Offset(.18, .24), Offset(.86, .3)]);
        _confetti(c, s, t, count: 7);
      },
    ),
    's1_tea': _Motion(
      (t) => _P(rot: .035 * math.sin(t * 1.6), py: .9),
      front: (c, s, t) => _steam(c, s, t, const Offset(.82, .6)),
    ),
    's1_lantern': _Motion(
      (t) => _P(rot: .08 * math.sin(t * 2.2), px: .5, py: .1),
      back: (c, s, t) =>
          _glowAt(c, s, const Offset(.78, .56), .22, const Color(0xFFFFC857), .45 + .25 * math.sin(t * 5)),
    ),
    's1_sleep': _Motion(
      (t) => _P(sx: 1 + .025 * math.sin(t * 1.5), sy: 1 + .03 * math.sin(t * 1.5), py: .95),
      front: (c, s, t) => _zzz(c, s, t, const Offset(.78, .14)),
    ),
    's1_star': _Motion(
      (t) => _P(rot: .05 * math.sin(t * 2), dy: -.02 * math.sin(t * 2), py: .9),
      front: (c, s, t) {
        _star(c, s, const Offset(.78, .66), .1, .4 + .6 * _pulse(t, 1.4, .5));
        _sparkles(c, s, t, const [Offset(.12, .2), Offset(.9, .22)]);
      },
    ),
    // الأساطير
    'leg_king': _Motion(
      glint: 3.4,
      (t) => _P(dy: -.02 * math.sin(t * 1.6), rot: .02 * math.sin(t * 1.1)),
      back: (c, s, t) => _aura(c, s, t, const Color(0xFFFCD34D)),
      front: (c, s, t) => _sparkles(c, s, t, const [Offset(.5, .06), Offset(.32, .12), Offset(.68, .12)]),
    ),
    'leg_genius': _Motion(
      (t) => _P(dy: .03 * _beat(t, .7, .25), py: .9),
      back: (c, s, t) =>
          _glowAt(c, s, const Offset(.64, .1), .18, const Color(0xFFFDE047), .3 + .7 * _pulse(t, 1.43, .4)),
      front: (c, s, t) => _sparkles(c, s, t, const [Offset(.4, .38), Offset(.58, .38)]),
    ),
    'leg_ghost': _Motion(
      (t) => _P(
        dy: -.04 + .04 * math.sin(t * 2),
        rot: .05 * math.sin(t * 1.4),
        alpha: .45 + .55 * (.5 + .5 * math.cos(t * 1.3)),
      ),
    ),
    'leg_mind': _Motion(
      (t) => _P(dx: .004 * math.sin(t * 50), sx: 1 + .01 * math.sin(t * 4)),
      back: (c, s, t) => _rings(c, s, t, const Offset(.5, .12), const Color(0xFFC084FC)),
    ),
    'leg_storm': _Motion(
      (t) {
        final hit = _pulse(t, 1.7, .25);
        return _P(dx: .02 * math.sin(t * 60) * hit, rot: .02 * math.sin(t * 7));
      },
      back: (c, s, t) => _glowAt(c, s, const Offset(.5, .45), .55, const Color(0xFFE0F2FE), .7 * _pulse(t, 1.7, .2)),
      front: (c, s, t) {
        _star(c, s, const Offset(.14, .06), .08, _pulse(t, 1.7, .3));
        _star(c, s, const Offset(.86, .06), .08, _pulse(t + .2, 1.7, .3));
      },
    ),
    'leg_legend': _Motion(
      (t) => _P(dy: -.025 * math.sin(t * 2), sx: 1 + .02 * math.sin(t * 2)),
      back: (c, s, t) => _aura(c, s, t, const Color(0xFFFDE68A)),
      front: (c, s, t) => _orbit(c, s, t),
    ),
    ..._s2Motions, // حركات ملصقات الرسم الجديد (sticker_motion_s2.dart): تغلب على القديم فوق
  };

  // ───────────── أدوات ─────────────

  static double _frac(double x) => x - x.floorToDouble();

  /// نطة تتكرر [hz] مرة بالثانية (٠–١).
  static double _bounce(double t, double hz) => math.sin(_frac(t * hz) * math.pi).abs();

  /// ضربة سريعة في أول كل دورة ([dur] من الدورة) وبعدها هدوء.
  static double _beat(double t, double hz, double dur) {
    final q = _frac(t * hz);
    return q < dur ? math.sin(q / dur * math.pi) : 0;
  }

  /// ومضة كل [period] ثانية تطول [dur] ثانية.
  static double _pulse(double t, double period, double dur) {
    final s = _frac(t / period) * period;
    return s < dur ? math.sin(s / dur * math.pi) : 0;
  }

  static void _star(Canvas c, Size s, Offset at, double r, double a) {
    if (a <= 0) return;
    final p = Offset(at.dx * s.width, at.dy * s.height);
    final rr = r * s.width;
    c.drawCircle(
      p,
      rr * 1.4,
      Paint()
        ..color = Colors.white.withValues(alpha: .3 * a)
        ..blendMode = BlendMode.plus,
    );
    c.drawPath(star4(p, rr), Paint()..color = Colors.white.withValues(alpha: a));
  }

  /// لمعات تومض بالدور.
  static void _sparkles(Canvas c, Size s, double t, List<Offset> at) {
    for (final (i, p) in at.indexed) {
      _star(c, s, p, .055, _pulse(t + i * .53, 1.6, .5));
    }
  }

  static void _glowAt(Canvas c, Size s, Offset at, double r, Color color, double a) {
    if (a <= 0) return;
    final p = Offset(at.dx * s.width, at.dy * s.height);
    final rr = r * s.width;
    c.drawCircle(
      p,
      rr,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: a.clamp(0.0, 1.0)),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: p, radius: rr)),
    );
  }

  /// هالة تنبض ورا الملصق.
  static void _aura(Canvas c, Size s, double t, Color color) =>
      _glowAt(c, s, const Offset(.5, .45), .62 + .05 * math.sin(t * 2.4), color, .35 + .2 * math.sin(t * 2.4));

  /// عيون تشع وتومض.
  static void _eyes(Canvas c, Size s, double t, List<Offset> at, Color color) {
    final a = .45 + .35 * (.5 + .5 * math.sin(t * 5)) + .3 * _pulse(t, 2.2, .3);
    for (final p in at) {
      _glowAt(c, s, p, .07, color, a);
    }
  }

  /// شريط ضو مايل يمر على الملصق (على رسمته بس، مو على الفراغ اللي حوله).
  static Widget _glint(Widget child, double t, double period) {
    final q = _frac(t / period);
    if (q > .4) return child;
    final x = q / .4 * 1.6 - .3;
    final a = .55 * math.sin(q / .4 * math.pi);
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: a),
          Colors.white.withValues(alpha: 0),
        ],
        stops: [(x - .1).clamp(0.0, 1.0), x.clamp(0.0, 1.0), (x + .1).clamp(0.0, 1.0)],
      ).createShader(rect),
      child: child,
    );
  }

  /// قصاصات ملونة تنزل.
  static void _confetti(Canvas c, Size s, double t, {int count = 12}) {
    const colors = [Color(0xFFFF6B6B), Color(0xFFFFD166), Color(0xFF06D6A0), Color(0xFF4CC9F0), Color(0xFFB794F4)];
    for (var i = 0; i < count; i++) {
      final q = _frac(t * (.45 + rnd(i, 1) * .25) + rnd(i, 2));
      final x = (rnd(i, 3) + .08 * math.sin(t * 3 + i)) * s.width;
      final y = (-.1 + q * 1.1) * s.height;
      c.save();
      c.translate(x, y);
      c.rotate(t * (3 + i % 3) + i);
      c.drawRect(
        Rect.fromCenter(center: Offset.zero, width: s.width * .04, height: s.width * .02),
        Paint()..color = colors[i % colors.length].withValues(alpha: q > .85 ? (1 - q) / .15 : 1),
      );
      c.restore();
    }
  }

  /// انفجارات ألعاب نارية حول الملصق.
  static void _fireworks(Canvas c, Size s, double t) {
    const spots = [
      (Offset(.16, .14), Color(0xFFFF6B6B)),
      (Offset(.84, .16), Color(0xFFFFD166)),
      (Offset(.9, .5), Color(0xFF4CC9F0)),
    ];
    for (final (i, (at, color)) in spots.indexed) {
      final q = _frac(t / 1.8 + i / 3);
      if (q > .7) continue;
      final b = q / .7;
      final center = Offset(at.dx * s.width, at.dy * s.height);
      for (var j = 0; j < 10; j++) {
        final a = j * math.pi / 5 + i;
        final r = s.width * (.02 + .13 * Curves.easeOut.transform(b));
        c.drawCircle(
          center + Offset(math.cos(a), math.sin(a)) * r,
          s.width * .014,
          Paint()..color = color.withValues(alpha: 1 - b),
        );
      }
    }
  }

  /// خطوط تصفيق أو ضربة تطلع من نقاط.
  static void _bursts(Canvas c, Size s, double a, List<Offset> at, Color color) {
    if (a <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: a)
      ..strokeWidth = s.width * .022
      ..strokeCap = StrokeCap.round;
    for (final p in at) {
      final o = Offset(p.dx * s.width, p.dy * s.height);
      for (var j = 0; j < 5; j++) {
        final ang = -math.pi / 2 + (j - 2) * .55;
        final d = Offset(math.cos(ang), math.sin(ang));
        c.drawLine(o + d * s.width * (.1 + .04 * a), o + d * s.width * (.15 + .06 * a), paint);
      }
    }
  }

  /// خطوط سرعة.
  static void _lines(Canvas c, Size s, Offset at, double a) {
    if (a <= 0) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .85 * a)
      ..strokeWidth = s.width * .018
      ..strokeCap = StrokeCap.round;
    final o = Offset(at.dx * s.width, at.dy * s.height);
    for (var j = 0; j < 3; j++) {
      final y = (j - 1) * s.height * .06;
      c.drawLine(o + Offset(0, y), o + Offset(s.width * .08, y), paint);
    }
  }

  /// نوتات موسيقى تطلع وتتمايل.
  static void _notes(Canvas c, Size s, double t) {
    for (var i = 0; i < 2; i++) {
      final q = _frac(t * .6 + i * .5);
      final x = (i == 0 ? .1 : .86) * s.width + math.sin(q * 6) * s.width * .03;
      final y = (.5 - q * .45) * s.height;
      final paint = Paint()..color = const Color(0xFFFFD166).withValues(alpha: math.sin(q * math.pi));
      c.drawCircle(Offset(x, y), s.width * .03, paint);
      c.drawLine(
        Offset(x + s.width * .027, y),
        Offset(x + s.width * .027, y - s.height * .09),
        paint..strokeWidth = s.width * .014,
      );
    }
  }

  /// نقاط تفكير.
  static void _dots(Canvas c, Size s, double t, Offset at) {
    for (var i = 0; i < 3; i++) {
      final a = _pulse(t - i * .25, 1.8, .9);
      c.drawCircle(
        Offset((at.dx + i * .05) * s.width, at.dy * s.height),
        s.width * .022,
        Paint()..color = Colors.white.withValues(alpha: .25 + .75 * a),
      );
    }
  }

  /// جمر يطلع لفوق من الجنبين.
  static void _embers(Canvas c, Size s, double t, List<double> xs) {
    for (var i = 0; i < 9; i++) {
      final q = _frac(t * (.7 + rnd(i, 4) * .4) + rnd(i, 5));
      final x0 = xs[i % xs.length];
      final x = (x0 + (rnd(i, 6) - .5) * .12 + .03 * math.sin(t * 4 + i)) * s.width;
      final y = (.85 - q * .8) * s.height;
      final color = Color.lerp(const Color(0xFFFFD166), const Color(0xFFFF5722), q)!;
      c.drawCircle(
        Offset(x, y),
        s.width * (.022 - .012 * q),
        Paint()
          ..color = color.withValues(alpha: 1 - q)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  /// دخان الصاروخ تحت.
  static void _exhaust(Canvas c, Size s, double t) {
    for (var i = 0; i < 8; i++) {
      final q = _frac(t * 1.6 + i / 8);
      final x = (.5 + (rnd(i, 7) - .5) * .4 * q) * s.width;
      final y = (.95 + q * .12) * s.height;
      c.drawCircle(
        Offset(x, y),
        s.width * (.03 + .05 * q),
        Paint()
          ..color = Color.lerp(const Color(0xFFFFB703), const Color(0xFFCBD5E1), q)!.withValues(alpha: .8 * (1 - q)),
      );
    }
  }

  /// حلقات تطلع من نقطة (تركيز أو قراءة أفكار).
  static void _rings(Canvas c, Size s, double t, Offset at, Color color) {
    final o = Offset(at.dx * s.width, at.dy * s.height);
    for (var i = 0; i < 3; i++) {
      final q = _frac(t * .8 + i / 3);
      c.drawCircle(
        o,
        s.width * (.08 + .4 * q),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * .02
          ..color = color.withValues(alpha: .6 * (1 - q)),
      );
    }
  }

  /// بخار الشاي.
  static void _steam(Canvas c, Size s, double t, Offset at) {
    for (var i = 0; i < 3; i++) {
      final q = _frac(t * .5 + i / 3);
      final base = Offset((at.dx + (i - 1) * .04) * s.width, at.dy * s.height);
      final path = Path()..moveTo(base.dx, base.dy - q * s.height * .2);
      for (var k = 1; k <= 4; k++) {
        path.lineTo(base.dx + math.sin(k * 1.5 + t * 3 + i) * s.width * .025, base.dy - (q * .2 + k * .04) * s.height);
      }
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * .018
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .7 * math.sin(q * math.pi)),
      );
    }
  }

  /// حروف ز تطلع من النعسان.
  static void _zzz(Canvas c, Size s, double t, Offset at) {
    for (var i = 0; i < 3; i++) {
      final q = _frac(t * .45 + i / 3);
      final size = s.width * (.035 + .04 * q);
      final o = Offset((at.dx + q * .1) * s.width, (at.dy - q * .14) * s.height + i * 0);
      c.drawPath(
        Path()
          ..moveTo(o.dx - size, o.dy - size)
          ..lineTo(o.dx + size, o.dy - size)
          ..lineTo(o.dx - size, o.dy + size)
          ..lineTo(o.dx + size, o.dy + size),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.width * .016
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white.withValues(alpha: math.sin(q * math.pi)),
      );
    }
  }

  /// عملات ذهب تطيح.
  static void _coins(Canvas c, Size s, double t) {
    for (var i = 0; i < 4; i++) {
      final q = _frac(t * .55 + i / 4);
      final x = (.1 + rnd(i, 8) * .8) * s.width;
      final y = (-.06 + q * 1.05) * s.height;
      final turn = math.cos(t * 7 + i * 2);
      final rect = Rect.fromCenter(center: Offset(x, y), width: s.width * .07 * turn.abs() + 1, height: s.width * .07);
      final fade = q > .85 ? (1 - q) / .15 : 1.0;
      c.drawOval(rect, Paint()..color = const Color(0xFFB45309).withValues(alpha: fade));
      c.drawOval(rect.deflate(s.width * .008), Paint()..color = const Color(0xFFFCD34D).withValues(alpha: fade));
    }
  }

  /// لمعات تدور حول الملصق.
  static void _orbit(Canvas c, Size s, double t) {
    for (var i = 0; i < 5; i++) {
      final a = t * 1.2 + i * 2 * math.pi / 5;
      final p = Offset(.5 + math.cos(a) * .46, .46 + math.sin(a) * .44);
      _star(c, s, p, .04 + .015 * math.sin(t * 4 + i), .6 + .4 * math.sin(t * 3 + i));
    }
  }
}

/// وضعية الصورة: إزاحة (نسبة من الحجم)، ودوران، وتكبير حول ([px], [py])، وشفافية.
class _P {
  const _P({
    this.dx = 0,
    this.dy = 0,
    this.rot = 0,
    this.sx = 1,
    this.sy = 1,
    this.px = .5,
    this.py = .5,
    this.alpha = 1,
  });

  final double dx, dy, rot, sx, sy, px, py, alpha;
}

class _Motion {
  const _Motion(this.pose, {this.back, this.front, this.glint});

  final _P Function(double t) pose;

  /// شريط ضو يمر على الملصق نفسه كل كم ثانية.
  final double? glint;

  /// رسم ورا الصورة وقدامها.
  final void Function(Canvas c, Size s, double t)? back;
  final void Function(Canvas c, Size s, double t)? front;
}

class _Fx extends CustomPainter {
  _Fx(this.draw, this.t);

  final void Function(Canvas c, Size s, double t) draw;
  final double t;

  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size, t);

  @override
  bool shouldRepaint(_Fx old) => old.t != t;
}
