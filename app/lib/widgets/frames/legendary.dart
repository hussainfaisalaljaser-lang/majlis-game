import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../common.dart' show arabicNumber;
import 'epic.dart';
import 'kit.dart';

// الإطارات الأسطورية: حركة من أكثر من طبقة، وأفخم شي في اللعبة، ولكل واحد لحظة خاصة (burst).

Color _hue(Color c, double deg) {
  final hsv = HSVColor.fromColor(c);
  return hsv.withHue((hsv.hue + deg) % 360).toColor();
}

/// شرار يطير لبرا من المركز وقت اللحظة الخاصة.
void sparks(
  Canvas canvas,
  Offset c,
  double r,
  double m,
  List<Color> colors, {
  int n = 20,
  double from = 1,
  double size = 1.5,
}) {
  final ease = Curves.easeOutCubic.transform(m);
  final fade = 1 - m;
  for (var i = 0; i < n; i++) {
    final a = i * math.pi * 2 / n + rnd(i, 31) * .4;
    final dist = r * (from + ease * (.55 + rnd(i, 32) * .7));
    final pos = c + dir(a) * dist;
    final col = colors[i % colors.length];
    canvas.drawLine(
      pos,
      c + dir(a) * (dist - r * .18 * fade),
      Paint()
        ..color = col.withValues(alpha: .5 * fade)
        ..strokeWidth = size * .6
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.plus,
    );
    canvas.drawCircle(
      pos,
      size * (1.4 - ease),
      Paint()
        ..color = col.withValues(alpha: fade)
        ..blendMode = BlendMode.plus,
    );
  }
}

// ═════════════ الشمس ═════════════

/// الشمس: هالة وأشعة طويلة وقصيرة تدور بعكس بعض وترجف من الحرارة، وحلقة ذهب ذايب تغلي،
/// وكل كم ثانية تطلع منها شعلة مقوّسة. اللحظة: انفجار شمسي (ومضة وموجة نار وأشعة تطول).
class SunFrame extends FrameArt {
  SunFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _gold = Color(0xFFFFB300);
  static const _orange = Color(0xFFFF6F00);
  static const _pale = Color(0xFFFFF59D);
  static const _white = Color(0xFFFFFDE7);
  static const _red = Color(0xFFE65100);

  @override
  void back(Canvas canvas, Offset c, double t) {
    final b = burst(t);
    final swell = hump(b ?? 0);
    halo(
      canvas,
      c,
      r * (1.75 + .08 * math.sin(t * 1.3) + .5 * swell),
      [
        _pale.withValues(alpha: .55),
        _gold.withValues(alpha: .4 + .3 * swell),
        _orange.withValues(alpha: .16),
        _orange.withValues(alpha: 0),
      ],
      stops: const [.5, .62, .8, 1],
    );
    final n = small ? 10 : 14;
    for (final (set, speed, reach) in [(0, .12, 1.58), (1, -.2, 1.32)]) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final a = t * speed + (i + set * .5) * 2 * math.pi / n;
        final len = r * (reach + .16 * noise(t * 1.5, i + set * 20) + (set == 0 ? .65 : .3) * swell);
        final half = set == 0 ? .085 : .06;
        final tip = c + dir(a + .025 * math.sin(t * 6 + i)) * len;
        path.addPolygon([c + dir(a - half) * r * 1.02, tip, c + dir(a + half) * r * 1.02], true);
      }
      canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            colors: [_white, _pale.withValues(alpha: .85), _gold.withValues(alpha: .25), _gold.withValues(alpha: 0)],
            stops: const [.55, .65, .82, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r * 2.2)),
      );
    }
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    sweepRing(canvas, c, const [_orange, _gold, _pale, _gold, _orange, _red, _orange], turn: t * .5);
    for (var i = 0; i < (small ? 8 : 14); i++) {
      final tw = math.pow((math.sin(t * 3.1 + i * 2.3) + 1) / 2, 3).toDouble();
      dot(canvas, c + dir(i * 2 * math.pi / (small ? 8 : 14) + rnd(i, 2)) * mid, ring * .14, _pale, tw);
    }
    line(canvas, c, r, _white.withValues(alpha: .6));
    line(canvas, c, r + ring, _red.withValues(alpha: .5));
    // الشعلة المقوّسة
    final cycle = (t / 3.6).floor();
    final q = (t % 3.6) / 1.5;
    if (q < 1) {
      final a = rnd(cycle, 3) * 2 * math.pi;
      final f0 = c + dir(a - .22) * (r + ring), f1 = c + dir(a + .22) * (r + ring);
      final apex = c + dir(a) * r * (1.18 + .38 * hump(q));
      final arc = Path()
        ..moveTo(f0.dx, f0.dy)
        ..quadraticBezierTo(apex.dx, apex.dy, f1.dx, f1.dy);
      final fade = 1 - q;
      canvas.drawPath(
        arc,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring * .55
          ..color = _orange.withValues(alpha: .8 * fade)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring * .3),
      );
      canvas.drawPath(
        arc,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = hair * 1.2
          ..color = _pale.withValues(alpha: fade),
      );
    }
    final b = burst(t);
    if (b != null) {
      halo(canvas, c, r * 1.15, [
        _white.withValues(alpha: .8 * (1 - b) * (1 - b)),
        _pale.withValues(alpha: .3 * (1 - b)),
        Colors.transparent,
      ]);
      final k = Curves.easeOutCubic.transform(b);
      canvas.drawCircle(
        c,
        r * (1 + 1.1 * k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring * 1.4 * (1 - b)
          ..color = _orange.withValues(alpha: .7 * (1 - b))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring * .6),
      );
      sparks(canvas, c, r, b, const [_pale, _gold, _orange, _white], size: math.max(1, avatar * .016));
    }
  }
}

// ═════════════ نقوش ═════════════

/// نقوش: زخرفة إسلامية (نجمتين متداخلتين بـ١٦ راس ونجوم ثمانية) ترسم نفسها بخط ذهب حول الصورة،
/// وإذا كملت تتوهج وتختفي وترجع ترسم. الحلقة مينا فيروزية بخطوط ذهب.
/// اللحظة: الزخرفة كلها تومض، ونجوم ثمانية تطير لبرا.
class ArabesqueFrame extends FrameArt {
  ArabesqueFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _teal = Color(0xFF0E7490);
  static const _deep = Color(0xFF155E75);
  static const _gold = Color(0xFFFCD34D);
  static const _pale = Color(0xFFFFF1B8);

  Path _star(Offset c, double outer, double inner, double turn) {
    const n = 16;
    return poly([for (var i = 0; i < n * 2; i++) c + dir(turn + i * math.pi / n) * (i.isEven ? outer : inner)]);
  }

  @override
  void back(Canvas canvas, Offset c, double t) {
    halo(
      canvas,
      c,
      r * 1.55,
      [_deep.withValues(alpha: .65), _deep.withValues(alpha: .35), _deep.withValues(alpha: 0)],
      stops: const [.7, .86, 1],
    );
    final q = frac(t / 7);
    final drawn = math.min(1.0, q / .5);
    final glow = q > .5 && q < .85 ? hump((q - .5) / .35) : 0.0;
    final alpha = q > .85 ? 1 - (q - .85) / .15 : 1.0;
    final b = burst(t);
    final flash = b == null ? 0.0 : 1 - b;
    final stars = [
      _star(c, r * 1.44, r * 1.12, -math.pi / 2),
      _star(c, r * 1.4, r * 1.15, -math.pi / 2 + math.pi / 16),
    ];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair * 1.5
      ..strokeJoin = StrokeJoin.round
      ..color = Color.lerp(_gold, _pale, flash)!.withValues(alpha: math.max(alpha, flash));
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ring * .7
      ..color = _gold.withValues(alpha: .35 * math.max(glow, flash))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring * .45);
    for (final s in stars) {
      final full = flash > 0 || drawn >= 1;
      final part = full ? s : _partial(s, drawn);
      if (glow > 0 || flash > 0) canvas.drawPath(part, glowPaint);
      canvas.drawPath(part, paint);
    }
    // نجوم ثمانية في الفراغات، تطلع لما يوصلها الرسم
    for (var k = 0; k < 8; k++) {
      final show = flash > 0 ? 1.0 : ((drawn - k / 8) * 8).clamp(0.0, 1.0) * alpha;
      if (show <= 0) continue;
      final p = c + dir(-math.pi / 2 + k * math.pi / 4) * r * 1.29;
      canvas.drawPath(star8(p, ring * .62), Paint()..color = _gold.withValues(alpha: show));
      canvas.drawCircle(p, ring * .22, Paint()..color = _teal.withValues(alpha: show));
    }
  }

  /// أول [f] من طول المسار.
  Path _partial(Path path, double f) {
    final out = Path();
    for (final m in path.computeMetrics()) {
      out.addPath(m.extractPath(0, m.length * f), Offset.zero);
    }
    return out;
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    sweepRing(canvas, c, const [_deep, _teal, Color(0xFF0891B2), _teal], turn: .2);
    line(canvas, c, r + ring * .18, _gold, width: hair * 1.2);
    line(canvas, c, r + ring * .82, _gold, width: hair * 1.2);
    for (var k = 0; k < 16; k++) {
      canvas.drawCircle(c + dir(k * math.pi / 8) * mid, hair * 1.1, Paint()..color = _pale);
    }
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: mid),
      t * .4,
      .5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring * .6
        ..color = Colors.white.withValues(alpha: .25)
        ..blendMode = BlendMode.plus,
    );
    final b = burst(t);
    if (b != null) {
      final k = Curves.easeOutCubic.transform(b);
      for (var i = 0; i < 8; i++) {
        final p = c + dir(-math.pi / 2 + i * math.pi / 4 + math.pi / 8) * r * (1.3 + .6 * k);
        canvas.drawPath(
          star8(p, ring * .7 * (1 - b * .4), turn: b * 2),
          Paint()..color = _pale.withValues(alpha: 1 - b),
        );
      }
    }
  }
}

// ═════════════ الطاووس ═════════════

/// الطاووس: ذيل طاووس منفرد ورا الصورة (ريش أخضر فيروزي وعيونه تتلون مثل الحرير)، يتمايل بهدوء،
/// وحلقة ذهب عليها أحجار ياقوت أزرق. اللحظة: الذيل ينفرد أكثر وتمر لمعة على العيون وتطير منه لمعات.
class PeacockFrame extends FrameArt {
  PeacockFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _teal = Color(0xFF14B8A6);
  static const _green = Color(0xFF15803D);
  static const _blue = Color(0xFF1D4ED8);
  static const _navy = Color(0xFF0B1A5C);
  static const _gold = Color(0xFFFFC94D);
  static const _bronze = Color(0xFFB8860B);
  static const _sapphire = Color(0xFF2747D6);

  int get _n => small ? 11 : 15;

  /// زاوية الريشة رقم [i] وطولها.
  (double, double) _feather(int i, double t, double open) {
    final s = i / (_n - 1);
    var a = -math.pi - .28 + s * (math.pi + .56);
    a = -math.pi / 2 + (a + math.pi / 2) * (1 + .12 * open);
    a += .045 * math.sin(t * 1.3 + i * .55);
    final len = r * ((small ? 1.5 : 1.6) + .08 * math.sin(t * .9 + i) + .25 * open);
    return (a, len);
  }

  @override
  void back(Canvas canvas, Offset c, double t) {
    final b = burst(t);
    final open = hump(b ?? 0);
    for (var i = 0; i < _n; i++) {
      final (a, len) = _feather(i, t, open);
      final d = dir(a), side = perp(d);
      final base = c + d * r * .85, tip = c + d * len;
      final w = r * .17;
      // الريشة: شكل ورقة طويلة تعرض قرب الطرف
      final vane = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          (base + d * (len - r) * .6 + side * w).dx,
          (base + d * (len - r) * .6 + side * w).dy,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          (base + d * (len - r) * .6 - side * w).dx,
          (base + d * (len - r) * .6 - side * w).dy,
          base.dx,
          base.dy,
        )
        ..close();
      canvas.drawPath(
        vane,
        Paint()..shader = ui.Gradient.linear(base, tip, [_green.withValues(alpha: .9), _teal.withValues(alpha: .85)]),
      );
      canvas.drawLine(
        base,
        tip,
        Paint()
          ..color = _gold.withValues(alpha: .55)
          ..strokeWidth = hair * .8,
      );
      // العين: حلقات تتلون
      final eye = c + d * (len - r * .2);
      final shift = 18 * math.sin(t * 1.5 - i * .5) + 40 * open * math.sin(b == null ? 0 : b * math.pi * 3 - i * .4);
      final ew = r * .2, eh = r * .26;
      for (final (k, col) in [
        (1.0, _hue(_gold, shift * .3)),
        (.82, _hue(_green, shift)),
        (.64, _hue(_teal, shift)),
        (.44, _hue(_blue, shift)),
        (.26, _navy),
      ]) {
        canvas.save();
        canvas.translate(eye.dx, eye.dy);
        canvas.rotate(a + math.pi / 2);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: ew * k * 2, height: eh * k * 2),
          Paint()..color = col,
        );
        canvas.restore();
      }
      final shimmer = math.pow((math.sin(t * 2 - i * .4) + 1) / 2, 4).toDouble();
      canvas.drawCircle(
        eye + side * ew * .25 - d * eh * .2,
        ew * .18,
        Paint()..color = Colors.white.withValues(alpha: .35 + .5 * shimmer),
      );
    }
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    sweepRing(canvas, c, const [_bronze, _gold, Color(0xFFFFF1C1), _gold, _bronze], turn: .4);
    line(canvas, c, r + ring, _bronze);
    line(canvas, c, r, _teal.withValues(alpha: .75));
    for (var k = 0; k < 6; k++) {
      final p = c + dir(k * math.pi / 3 + math.pi / 6) * mid;
      canvas.drawCircle(
        p,
        ring * .36,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.35, -.4),
            colors: const [Color(0xFFBFD3FF), _sapphire, _navy],
          ).createShader(Rect.fromCircle(center: p, radius: ring * .36)),
      );
    }
    final b = burst(t);
    if (b != null) {
      for (var i = 0; i < _n; i += 2) {
        final (a, len) = _feather(i, t, hump(b));
        sparkle(canvas, c + dir(a) * len * (1 + .25 * b), ring * .6, _gold, 1 - b);
      }
    }
  }
}

// ═════════════ مجرة ═════════════

/// مجرة: سديم ملوّن وأذرع مجرة حلزونية من نجوم تدور ورا الصورة، وكوكبين يلفون حولها (يمرون
/// قدامها وورها)، ونجوم تلمع. اللحظة: انفجار نجمي (ومضة وموجة تنتشر وشرار يطير).
class GalaxyFrame extends FrameArt {
  GalaxyFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _violet = Color(0xFF7C4DFF);
  static const _pink = Color(0xFFFF4081);
  static const _cyan = Color(0xFF18FFFF);
  static const _ice = Color(0xFFE0F7FF);

  @override
  double get ring => math.max(2.5, avatar * .07);

  @override
  void back(Canvas canvas, Offset c, double t) {
    final swell = hump(burst(t) ?? 0);
    for (final (col, phase, alpha) in [(_violet, 0.0, .5), (_pink, 2.1, .38), (_cyan, 4.2, .3)]) {
      final pos = c + dir(t * .18 + phase) * r * .32;
      halo(canvas, pos, r * (1.55 + .12 * math.sin(t * .7 + phase) + swell * .35), [
        col.withValues(alpha: alpha * (1 + swell * .6)),
        col.withValues(alpha: 0),
      ]);
    }
    _arms(canvas, c, t, swell);
    _planets(canvas, c, t, front: false);
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final b = burst(t);
    final swell = hump(b ?? 0);
    glowRing(
      canvas,
      c,
      _violet.withValues(alpha: .35 + swell * .4),
      width: ring * 1.9,
      blur: ring * (1 + swell),
    );
    sweepRing(canvas, c, const [Color(0xFF1A0B3D), _violet, _pink, Color(0xFF1A0B3D), _cyan, _violet], turn: t * .6);
    final p = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 10; i++) {
      final tw = math.pow((math.sin(t * 4 + i * 2.7) + 1) / 2, 3).toDouble();
      p.color = Colors.white.withValues(alpha: .25 + .75 * tw);
      canvas.drawCircle(c + dir(i * math.pi * 2 / 10 + t * .6) * mid, math.max(.6, ring * (.16 + tw * .2)), p);
    }
    line(canvas, c, r + math.max(.5, ring * .1), _ice.withValues(alpha: .55), width: math.max(.8, ring * .18));
    _planets(canvas, c, t, front: true);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi * 2 / 6 + .4 + rnd(i, 21) * .5;
      final tw = math.pow((math.sin(t * 2.1 + i * 1.9) + 1) / 2, 2).toDouble();
      sparkle(canvas, c + dir(a) * r * (1.28 + rnd(i, 22) * .3), avatar * (.03 + tw * .045), _ice, .35 + .65 * tw);
    }
    if (b != null) _supernova(canvas, c, b);
  }

  void _arms(Canvas canvas, Offset c, double t, double swell) {
    const arms = 3, steps = 26;
    final stars = small ? 7 : 12;
    final p = Paint()..blendMode = BlendMode.plus;
    for (var k = 0; k < arms; k++) {
      Offset at(double f) => c + dir(k * math.pi * 2 / arms + f * 2.5 + t * .22) * r * (.97 + f * (.62 + swell * .32));
      final path = Path();
      for (var j = 0; j <= steps; j++) {
        final q = at(j / steps);
        j == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
      }
      final from = at(0), to = at(1);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * (.2 + swell * .1)
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(
            from,
            to,
            [_violet.withValues(alpha: .45 + swell * .3), _pink.withValues(alpha: .25), _pink.withValues(alpha: 0)],
            [0, .5, 1],
          )
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .08)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, r * .045)
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(
            from,
            to,
            [
              _ice.withValues(alpha: .95),
              _cyan.withValues(alpha: .7),
              _violet.withValues(alpha: .45),
              _pink.withValues(alpha: 0),
            ],
            [0, .25, .6, 1],
          )
          ..blendMode = BlendMode.plus,
      );
      for (var j = 0; j < stars; j++) {
        final f = (j + rnd(j, k + 3) * .6) / stars;
        final tw = math.pow((math.sin(t * 3.2 + j * 2.3 + k * 1.1) + 1) / 2, 2).toDouble();
        p.color = Colors.white.withValues(alpha: (.35 + .65 * tw) * (1 - f * .5));
        canvas.drawCircle(
          at(f) + dir(rnd(j, k + 7) * math.pi * 2) * r * .05,
          math.max(.7, avatar * .012) * (1.3 - f * .6) * (.7 + tw * .6),
          p,
        );
      }
    }
    for (var i = 0; i < (small ? 12 : 22); i++) {
      final tw = (math.sin(t * 2.4 + i * 1.3) + 1) / 2;
      p.color = _ice.withValues(alpha: .2 + .5 * tw);
      canvas.drawCircle(
        c + dir(rnd(i, 11) * math.pi * 2 + t * (.1 + rnd(i, 12) * .08)) * r * (1.04 + rnd(i, 13) * .55),
        math.max(.5, avatar * .006),
        p,
      );
    }
  }

  (Offset, double, bool) _orbit(Offset c, double a, double rx, double ry, double tilt) {
    final x = math.cos(a) * r * rx, y = math.sin(a) * r * ry;
    return (
      c + Offset(x * math.cos(tilt) - y * math.sin(tilt), x * math.sin(tilt) + y * math.cos(tilt)),
      math.sin(a),
      math.sin(a) > 0,
    );
  }

  void _planets(Canvas canvas, Offset c, double t, {required bool front}) {
    final (p1, d1, f1) = _orbit(c, t * .5, 1.36, .66, -.28);
    if (f1 == front) _giant(canvas, p1, avatar * .075 * (1 + .18 * d1));
    final (p2, d2, f2) = _orbit(c, -t * .85 + 2.2, 1.24, .6, .32);
    if (f2 == front) {
      final s = avatar * .035 * (1 + .2 * d2);
      canvas.drawCircle(
        p2,
        s,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.4, -.5),
            colors: [Colors.white, _cyan, Color(0xFF006064)],
          ).createShader(Rect.fromCircle(center: p2, radius: s)),
      );
      canvas.drawCircle(
        p2,
        s * 2.6,
        Paint()
          ..color = _cyan.withValues(alpha: .18)
          ..blendMode = BlendMode.plus,
      );
    }
  }

  void _giant(Canvas canvas, Offset p, double s) {
    final ringRect = Rect.fromCenter(center: p, width: s * 4.2, height: s * 1.25);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.7, s * .32)
      ..color = const Color(0xFFFFE0B2).withValues(alpha: .85);
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(-.35);
    canvas.translate(-p.dx, -p.dy);
    canvas.drawArc(ringRect, math.pi, math.pi, false, ringPaint);
    canvas.drawCircle(
      p,
      s,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.45),
          colors: [Color(0xFFFFE0F0), _pink, Color(0xFF6A1B9A)],
          stops: [0, .5, 1],
        ).createShader(Rect.fromCircle(center: p, radius: s)),
    );
    canvas.drawArc(
      Rect.fromCircle(center: p, radius: s * .8),
      .3,
      2.4,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, s * .18)
        ..color = Colors.white.withValues(alpha: .18),
    );
    canvas.drawArc(ringRect, 0, math.pi, false, ringPaint);
    canvas.restore();
  }

  void _supernova(Canvas canvas, Offset c, double m) {
    final fade = 1 - m;
    canvas.drawCircle(
      c,
      r * 1.1,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: .85 * fade * fade),
            _cyan.withValues(alpha: .35 * fade),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.1))
        ..blendMode = BlendMode.plus,
    );
    for (final (delay, col) in [(0.0, _cyan), (.14, _pink)]) {
      final k = ((m - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final rad = r * (1 + Curves.easeOutCubic.transform(k) * 1.05);
      final width = math.max(.8, ring * .55 * (1 - k));
      canvas.drawCircle(
        c,
        rad,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 4
          ..color = col.withValues(alpha: .35 * (1 - k))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 2)
          ..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        c,
        rad,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = Color.lerp(_ice, col, k)!.withValues(alpha: (1 - k) * .9)
          ..blendMode = BlendMode.plus,
      );
    }
    sparks(
      canvas,
      c,
      r,
      m,
      const [_cyan, _pink, _violet, Colors.white],
      n: small ? 14 : 26,
      size: math.max(.8, avatar * .014),
    );
  }
}

// ═════════════ الياقوت (مستوى ٤٠) ═════════════

/// الياقوت: بلورات ياقوت تطلع من الحلقة بمجموعات، شفافة وداخلها نار ترجف، وأطرافها تلمع.
/// اللحظة: البلورات تكبر وتشتعل، وشظايا تطير لبرا.
class RubyFrame extends FrameArt {
  RubyFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _ruby = Color(0xFFE11D48);
  static const _deep = Color(0xFF9F1239);
  static const _pink = Color(0xFFFDA4AF);
  static const _dark = Color(0xFF4C0519);
  static const _fire = Color(0xFFFFB347);

  @override
  void back(Canvas canvas, Offset c, double t) {
    final swell = hump(burst(t) ?? 0);
    halo(
      canvas,
      c,
      r * 1.55,
      [
        _ruby.withValues(alpha: 0),
        _ruby.withValues(alpha: .22 + .1 * math.sin(t * 2) + .4 * swell),
        _ruby.withValues(alpha: 0),
      ],
      stops: const [.6, .78, 1],
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final b = burst(t);
    final swell = hump(b ?? 0);
    // الحلقة: أوجه ياقوت
    final n = small ? 14 : 18;
    for (var i = 0; i < n; i++) {
      final a0 = i * 2 * math.pi / n, a1 = (i + 1) * 2 * math.pi / n;
      canvas.drawPath(
        poly([c + dir(a0) * r, c + dir(a0) * (r + ring), c + dir(a1) * (r + ring), c + dir(a1) * r]),
        Paint()..color = [_ruby, _deep, const Color(0xFFF43F5E)][i % 3],
      );
    }
    line(canvas, c, r + ring, _dark);
    line(canvas, c, r, _pink.withValues(alpha: .6));
    // مجموعات البلور
    for (var g = 0; g < 6; g++) {
      final a = g * math.pi / 3 + .52;
      for (final (k, (off, len, w, tilt)) in [
        (-.17, .3, 1.0, -.12),
        (0.0, .46, 1.25, 0.0),
        (.18, .34, .95, .12),
      ].indexed) {
        _crystal(canvas, c, a + off, r * len * (1 + .25 * swell), ring * w, tilt, t, g * 3 + k, swell);
      }
    }
    if (b != null) {
      final ease = Curves.easeOutCubic.transform(b);
      for (var i = 0; i < (small ? 10 : 16); i++) {
        final ang = i * 2 * math.pi / (small ? 10 : 16) + rnd(i, 5);
        final pos = c + dir(ang) * r * (1.2 + .8 * ease);
        final s = ring * .5 * (1 - b * .5);
        final d = dir(ang + b * 6);
        canvas.drawPath(
          poly([pos + d * s, pos + perp(d) * s * .5, pos - d * s * .6]),
          Paint()..color = _pink.withValues(alpha: 1 - b),
        );
      }
    }
  }

  void _crystal(Canvas canvas, Offset c, double a, double len, double w, double tilt, double t, int i, double swell) {
    final base = c + dir(a) * (r + ring * .7), d = dir(a + tilt), s = perp(d) * w / 2;
    final tip = base + d * len;
    final shoulder = base + d * len * .74;
    final left = poly([base - s, shoulder - s, tip, base]);
    final right = poly([base, tip, shoulder + s, base + s]);
    canvas.drawPath(left, Paint()..color = _deep.withValues(alpha: .92));
    canvas.drawPath(right, Paint()..color = _ruby.withValues(alpha: .9));
    // النار جوا
    final whole = poly([base - s, shoulder - s, tip, shoulder + s, base + s]);
    final fl = .6 + .4 * noise(t * 3 + i, i) + .4 * swell;
    canvas.save();
    canvas.clipPath(whole);
    final core = base + d * len * .45;
    halo(canvas, core, len * .62, [
      _fire.withValues(alpha: (.55 * fl).clamp(0.0, 1.0)),
      _ruby.withValues(alpha: .3 * fl.clamp(0.0, 1.0)),
      Colors.transparent,
    ]);
    canvas.restore();
    canvas.drawPath(
      whole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair * .8
        ..color = Colors.white.withValues(alpha: .35),
    );
    canvas.drawLine(
      base,
      tip,
      Paint()
        ..color = _pink.withValues(alpha: .6)
        ..strokeWidth = hair * .7,
    );
    sparkle(canvas, tip, ring * .45, _pink, math.pow(math.max(0, math.sin(t * 1.7 + i * 2.3)), 16).toDouble());
  }
}

// ═════════════ أسطورة المجلس (مستوى ٥٠) ═════════════

/// أسطورة المجلس: عنقاء من نار ملوّنة (ذهبي ووردي وبنفسجي): كل كم ثانية ينفرد جناحينها حول الصورة
/// ويرفرفون ويرجعون ينطوون، وذيل نار تحت، والحلقة نار ملوّنة يطير منها شرار.
/// اللحظة: الجناحين ينفردون على آخرهم وتطير ريش نار لبرا.
class PhoenixFrame extends FrameArt {
  PhoenixFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _gold = Color(0xFFFFD54F);
  static const _pink = Color(0xFFFF4081);
  static const _violet = Color(0xFF7C4DFF);
  static const _cyan = Color(0xFF18FFFF);
  static const _white = Color(0xFFFFF8E1);

  double _open(double t) {
    final p = frac(t / 6);
    var open = 0.0;
    if (p < .18) {
      open = Curves.easeOutBack.transform(p / .18);
    } else if (p < .6) {
      open = 1;
    } else if (p < .8) {
      open = 1 - Curves.easeInOut.transform((p - .6) / .2);
    }
    final b = burst(t);
    return b == null ? open : math.max(open, hump(b) * 1.15);
  }

  @override
  void back(Canvas canvas, Offset c, double t) {
    final open = _open(t);
    final shader = RadialGradient(
      colors: [_white, _gold, _pink, _violet.withValues(alpha: .7), _violet.withValues(alpha: 0)],
      stops: const [.3, .45, .62, .82, 1],
    ).createShader(Rect.fromCircle(center: c, radius: r * 2.1));
    if (open > .02) {
      final m = small ? 6 : 8;
      for (final side in const [-1, 1]) {
        final anchor = c + Offset(side * r * .45, -r * .12);
        final path = Path();
        for (var k = 0; k < m; k++) {
          final s = k / (m - 1);
          final base = -.12 + -1.25 * s + .06 * math.sin(t * 5 + k) * open;
          final a = side == 1 ? base : math.pi - base;
          final len = r * (1.0 + .6 * (1 - (s - .4).abs())) * open;
          if (len < r * .05) continue;
          FireFrame.tongue(
            path,
            anchor + dir(a) * r * .45,
            dir(a),
            len,
            r * .24 * (1 - s * .3),
            math.sin(t * 4 + k) * len * .08,
          );
        }
        canvas.drawPath(
          path,
          Paint()
            ..shader = shader
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, math.max(.5, r * .02)),
        );
      }
    }
    // ذيل النار تحت
    final tail = Path();
    for (var k = 0; k < 3; k++) {
      final a = math.pi / 2 + (k - 1) * .28;
      FireFrame.tongue(
        tail,
        c + dir(a) * r * .95,
        dir(a),
        r * (.42 + .08 * math.sin(t * 3 + k)),
        r * .2,
        math.sin(t * 2.6 + k * 2) * r * .06,
      );
    }
    canvas.drawPath(
      tail,
      Paint()
        ..shader = RadialGradient(
          colors: [_cyan, _violet.withValues(alpha: .75), _violet.withValues(alpha: 0)],
          stops: const [.55, .75, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.5))
        ..blendMode = BlendMode.plus,
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final open = _open(t);
    glowRing(canvas, c, _pink.withValues(alpha: .25 + .3 * open));
    sweepRing(canvas, c, const [_violet, _pink, _gold, _white, _gold, _pink, _violet, _cyan], turn: t * .6);
    line(canvas, c, r, _white.withValues(alpha: .55));
    for (var i = 0; i < (small ? 9 : 15); i++) {
      final life = frac(t * (.4 + rnd(i, 2) * .3) + rnd(i, 1));
      final a = -math.pi / 2 + (rnd(i, 3) - .5) * math.pi * 1.6;
      final pos = c + dir(a) * r * 1.08 + Offset(math.sin(life * 5 + i) * r * .06, -life * r * .7);
      dot(
        canvas,
        pos,
        math.max(.8, avatar * .014) * (1.1 - life * .6),
        [_gold, _pink, _cyan][i % 3],
        life < .15 ? life / .15 : 1 - life,
      );
    }
    final b = burst(t);
    if (b != null) {
      final path = Path();
      final ease = Curves.easeOutCubic.transform(b);
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6 + .2;
        FireFrame.tongue(path, c + dir(a) * r * (1.1 + ease * .7), dir(a), r * .28 * (1 - b), r * .12 * (1 - b), 0);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = _gold.withValues(alpha: 1 - b)
          ..blendMode = BlendMode.plus,
      );
    }
  }
}

// ═════════════ عاصفة الموسم ═════════════

/// عاصفة الموسم: غيوم داكنة تلف حول الصورة مثل الدوامة، والبرق يومض جواها ويضويها، ومطر ينزل،
/// وريح بيضا تمشي معها. اللحظة: صاعقة كبيرة تنزل من فوق على الحلقة، والغيوم تضوي والدوامة تسرع.
class StormFrame extends FrameArt {
  StormFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _sky = Color(0xFF0EA5E9);
  static const _night = Color(0xFF1E1B4B);
  static const _ice = Color(0xFFE0F2FE);
  static const _cloud = Color(0xFF2B3550);
  static const _cloudL = Color(0xFF8391AA);

  /// كل كم ثانية يومض البرق.
  static const _every = 1.7;

  /// الدوامة تسرع وقت اللحظة.
  double _spin(double t) {
    final b = burst(t);
    return t + (b == null ? 0 : Curves.easeOut.transform(b) * 2.5);
  }

  /// قوة ومضة البرق الحين (تومض مرتين ورا بعض).
  double _flash(double t) {
    final q = t % _every;
    if (q < .12) return 1 - q / .12;
    if (q > .18 && q < .34) return .7 * (1 - (q - .18) / .16);
    return 0;
  }

  /// وين البرق هالمرة (زاوية).
  double _flashAt(double t) => rnd((t / _every).floor(), 4) * 2 * math.pi;

  @override
  void back(Canvas canvas, Offset c, double t) {
    // مطر مايل ينزل
    final rain = Paint()
      ..strokeWidth = hair
      ..strokeCap = StrokeCap.round
      ..color = _ice.withValues(alpha: .35);
    for (var i = 0; i < (small ? 8 : 16); i++) {
      final x = c.dx + (rnd(i, 9) - .5) * r * 2.6;
      final y = c.dy + r * (-.2 + frac(t * 1.5 + rnd(i, 10)) * 1.8);
      canvas.drawLine(Offset(x, y), Offset(x - ring * .35, y + ring * 1.1), rain);
    }
    _clouds(canvas, c, t, front: false);
    // برق بين الغيوم
    final flash = _flash(t);
    if (flash > 0) {
      final a = _flashAt(t), seg = (t / _every).floor();
      bolt(
        canvas,
        [
          for (var q = 0; q <= 5; q++)
            c + dir(a + q * .09) * r * (1.5 - q * .06) + dir(rnd(seg * 7 + q, 6) * 6.3) * ring * .5,
        ],
        hair * 1.4,
        _sky,
        flash,
      );
    }
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final s = _spin(t);
    final flash = _flash(t);
    sweepRing(canvas, c, const [_night, Color(0xFF1E3A8A), _night, Color(0xFF0C4A6E)], turn: -s * .5);
    line(canvas, c, r + ring, _sky.withValues(alpha: .55 + .45 * flash));
    line(canvas, c, r, _ice.withValues(alpha: .5));
    _clouds(canvas, c, t, front: true);
    // الريح
    final wind = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair
      ..strokeCap = StrokeCap.round
      ..color = _ice.withValues(alpha: .5);
    for (var i = 0; i < (small ? 4 : 7); i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * (1.25 + .3 * rnd(i, 7))),
        s * 1.6 + i * .9 + rnd(i, 8),
        .35,
        false,
        wind,
      );
    }
    final b = burst(t);
    if (b != null && b < .45) {
      final k = 1 - b / .45;
      final seed = (moment?.value ?? 0).floor();
      final from = c + Offset(r * .25, -r * 2.1), to = c + Offset(0, -(r + ring));
      bolt(
        canvas,
        [
          for (var q = 0; q <= 7; q++)
            Offset.lerp(from, to, q / 7)! +
                (q == 0 || q == 7 ? Offset.zero : Offset((rnd(seed + q, 3) - .5) * r * .35, 0)),
        ],
        hair * 2.2,
        _sky,
        k,
      );
      halo(canvas, c, r * 1.4, [_ice.withValues(alpha: .5 * k), _ice.withValues(alpha: 0)]);
    }
  }

  /// كتلة غيوم حول الحلقة: كرات منفوخة تلف، بعضها قدام الصورة وأغلبها وراها. اللي جنب البرق تضوي.
  void _clouds(Canvas canvas, Offset c, double t, {required bool front}) {
    final s = _spin(t);
    final flash = _flash(t), at = _flashAt(t);
    final b = burst(t);
    final lit = b == null ? 0.0 : math.pow(1 - b, 2).toDouble();
    // صفين متداخلين (برا ثم جوا) عشان تطلع كتلة غيم منفوشة، مو كرات.
    final n = small ? 10 : 18;
    for (final row in const [1, 0]) {
      for (var i = 0; i < n; i++) {
        if ((row == 0 && i % 3 == 1) != front) continue;
        final ang = (i + row * .5) * 2 * math.pi / n + s * .35 + (rnd(i, 1 + row) - .5) * .25;
        final pos = c + dir(ang) * r * (1.17 + .17 * row + .04 * rnd(i, 2) + .03 * math.sin(s * 1.1 + i));
        final rad = r * (.17 + .1 * rnd(i, 3 + row)) * (front ? .85 : 1);
        final d = (ang - at) % (2 * math.pi);
        final close = math.max(0.0, 1 - math.min(d, 2 * math.pi - d) / 1.3);
        final glow = math.max(flash * close, lit);
        final shade = row == 1 ? .8 : 1.0;
        canvas.drawCircle(
          pos,
          rad,
          Paint()
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, rad * .12)
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(Color.lerp(_cloud, _cloudL, shade)!, _ice, glow * .75)!,
                Color.lerp(_cloud, _cloudL, glow * .7)!,
              ],
            ).createShader(Rect.fromCircle(center: pos, radius: rad)),
        );
      }
    }
  }
}

// ═════════════ احتفال الموسم الأول ═════════════

/// احتفال الموسم الأول: ألعاب نارية تنطلق من حول الصورة وتنفجر بألوان الموسم (ذهبي وفيروزي وبنفسجي)،
/// كل وحدة بوقت. اللحظة: ثلاث انفجارات كبيرة مع بعض ومطر لمعات ذهب.
class FireworksFrame extends FrameArt {
  FireworksFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _gold = Color(0xFFFCD34D);
  static const _teal = Color(0xFF0F766E);
  static const _mint = Color(0xFF5EEAD4);
  static const _violet = Color(0xFFA78BFA);
  static const _colors = [_gold, _mint, Colors.white, _violet];

  static const _slots = [(-2.4, 2.9, .0), (-1.15, 3.3, .45), (.15, 2.7, .2), (2.85, 3.1, .7)];

  @override
  void back(Canvas canvas, Offset c, double t) {
    halo(
      canvas,
      c,
      r * 1.6,
      [Colors.transparent, _violet.withValues(alpha: .12), _teal.withValues(alpha: .14), Colors.transparent],
      stops: const [.6, .72, .86, 1],
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    sweepRing(canvas, c, const [_teal, Color(0xFF134E4A), _teal, Color(0xFF115E59)]);
    line(canvas, c, r + ring, _gold, width: hair * 1.2);
    line(canvas, c, r, _gold.withValues(alpha: .7));
    for (var k = 0; k < 5; k++) {
      canvas.drawPath(star5(c + dir(k * 2 * math.pi / 5 + .3) * mid, ring * .42), Paint()..color = _gold);
    }
    for (final (i, (a, period, phase)) in _slots.indexed) {
      if (small && i == 3) continue;
      // كل إطلاق بلون ومكان مختلف شوي
      final cycle = (t / period + phase).floor();
      final p = frac(t / period + phase);
      final color = _colors[(i + cycle) % _colors.length];
      final at = a + (rnd(cycle, i + 20) - .5) * .5;
      if (p > .22 && p < .5) {
        // الحلقة تنور بلون الانفجار اللي جنبها
        final k = 1 - (p - .22) / .28;
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: mid),
          at - .5,
          1.0,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = ring * 1.2
            ..blendMode = BlendMode.plus
            ..shader = SweepGradient(
              startAngle: at - .5,
              endAngle: at + .5,
              colors: [
                color.withValues(alpha: 0),
                color.withValues(alpha: .6 * k),
                color.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: c, radius: mid)),
        );
      }
      _firework(canvas, c, at, p, color, i * 7 + cycle, r * .55);
    }
    final b = burst(t);
    if (b != null) {
      for (final (i, a) in const [-2.6, -.5, 1.9].indexed) {
        _firework(canvas, c, a, .22 + b * .78, _colors[(i + 1) % _colors.length], i + 7, r * .6);
      }
      // مطر لمعات ذهب
      for (var i = 0; i < (small ? 12 : 22); i++) {
        final x = (rnd(i, 41) - .5) * r * 3;
        final y = -r * 1.5 + (rnd(i, 42) * .4 + b) * r * 2.8;
        final tw = math.pow((math.sin(t * 9 + i * 2) + 1) / 2, 2).toDouble();
        dot(canvas, c + Offset(x, y), hair * 1.2, _gold, (1 - b) * (.4 + .6 * tw));
      }
    }
  }

  /// صاروخ يطلع ([p] < ٠٫٢٢) وبعدين ينفجر كرة شرار تنزل شوي وتختفي.
  void _firework(Canvas canvas, Offset c, double a, double p, Color color, int i, double size) {
    final launch = c + dir(a) * r * 1.05, center = c + dir(a) * r * 1.42;
    if (p < .22) {
      final q = Curves.easeOut.transform(p / .22);
      final pos = Offset.lerp(launch, center, q)!;
      canvas.drawLine(
        Offset.lerp(launch, center, math.max(0, q - .25))!,
        pos,
        Paint()
          ..color = _gold.withValues(alpha: .6)
          ..strokeWidth = hair
          ..strokeCap = StrokeCap.round,
      );
      dot(canvas, pos, hair * 1.3, _gold, 1);
      return;
    }
    final b = (p - .22) / .78;
    final ease = Curves.easeOutCubic.transform(b);
    final alpha = math.pow(1 - b, 1.3).toDouble();
    if (b < .15) {
      halo(canvas, center, size * .9, [
        Colors.white.withValues(alpha: .75 * (1 - b / .15)),
        color.withValues(alpha: 0),
      ]);
    }
    final m = small ? 12 : 18;
    final spark = small ? ring * .2 : hair * 1.7;
    final fall = Offset(0, size * .45 * b * b);
    for (var j = 0; j < m; j++) {
      final ang = j * 2 * math.pi / m + rnd(i, j) * .3;
      final pos = center + dir(ang) * size * (.15 + .85 * ease) + fall;
      canvas.drawLine(
        center + dir(ang) * size * (.15 + .6 * ease) + fall * .8,
        pos,
        Paint()
          ..color = color.withValues(alpha: .6 * alpha)
          ..strokeWidth = spark * .8
          ..strokeCap = StrokeCap.round
          ..blendMode = BlendMode.plus,
      );
      dot(
        canvas,
        pos,
        spark * (1 - b * .4),
        color,
        alpha * (b > .65 && rnd(i * 31 + j, (p * 40).floor()) < .4 ? .3 : 1),
      );
    }
  }
}

// ═════════════ أبطال الأسبوع ═════════════

/// أبطال الأسبوع: إكليل غار (ذهبي أو فضي أو برونزي) يحضن الصورة من تحت ومفتوح من فوق، وشريطة
/// وميدالية فيها المركز تتمرجح وتلمع، وحولها قصاصات احتفال (الأول) أو لمعات صقيع (الثاني) أو جمر (الثالث).
/// اللحظة: الميدالية تومض وينفجر حولها نفس النوع.
class ChampionFrame extends FrameArt {
  ChampionFrame(super.time, {required super.avatar, required super.layer, super.moment, required this.rank});

  final int rank;

  static const _metals = {
    1: [Color(0xFF8A6100), Color(0xFFFFD700), Color(0xFFFFF59D)],
    2: [Color(0xFF475569), Color(0xFFCBD5E1), Color(0xFFFFFFFF)],
    3: [Color(0xFF6D3C14), Color(0xFFE0A060), Color(0xFFFFD7A8)],
  };
  static const _ribbons = {1: Color(0xFFD32F2F), 2: Color(0xFF1E40AF), 3: Color(0xFF2E7D32)};

  List<Color> get _m => _metals[rank]!;

  static final _digits = <String, TextPainter>{};

  @override
  void back(Canvas canvas, Offset c, double t) {
    halo(
      canvas,
      c,
      r * 1.5,
      [_m[1].withValues(alpha: 0), _m[1].withValues(alpha: .22), _m[1].withValues(alpha: 0)],
      stops: const [.62, .8, 1],
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final m = _m;
    sweepRing(canvas, c, [m[0], m[1], m[2], m[1], m[0], m[1]], turn: t * .2);
    line(canvas, c, r + ring, m[0]);
    line(canvas, c, r, m[2].withValues(alpha: .7));
    _particles(canvas, c, t);
    for (final side in const [-1, 1]) {
      _branch(canvas, c, t, side);
    }
    _medal(canvas, c, t);
    final b = burst(t);
    if (b != null) {
      final colors = switch (rank) {
        1 => [m[1], _ribbons[1]!, Colors.white, m[2]],
        2 => [Colors.white, const Color(0xFFBAE6FD), m[1]],
        _ => [const Color(0xFFFFB74D), const Color(0xFFFF7043), m[2]],
      };
      sparks(canvas, c, r, b, colors, n: small ? 14 : 24, size: math.max(1, avatar * .016));
    }
  }

  /// غصن غار: من تحت ويلف على جنب الصورة لين قبل فوق بشوي، وعليه أوراق أزواج.
  void _branch(Canvas canvas, Offset c, double t, int side) {
    final m = _m;
    final rad = r * 1.24;
    const span = 2.17;
    final stem = Path();
    for (var j = 0; j <= 24; j++) {
      final a = math.pi / 2 - side * (.15 + j / 24 * span);
      final q = c + dir(a) * rad;
      j == 0 ? stem.moveTo(q.dx, q.dy) : stem.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair * 1.3
        ..color = m[0],
    );
    final n = small ? 7 : 10;
    for (var k = 0; k < n; k++) {
      final s = (k + .5) / n;
      final a = math.pi / 2 - side * (.15 + s * span);
      final p = c + dir(a) * rad;
      final along = dir(a - side * math.pi / 2);
      final len = ring * 1.55 * (1 - s * .35);
      final sway = .06 * math.sin(t * 1.5 + k * .6);
      for (final out in const [1, -1]) {
        final d = rot(along, out * side * -.6 + sway);
        _leaf(canvas, p, d, len, m);
      }
    }
  }

  void _leaf(Canvas canvas, Offset base, Offset d, double len, List<Color> m) {
    final tip = base + d * len, side = perp(d) * len * .3;
    final mid = base + d * len * .5;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo((mid + side).dx, (mid + side).dy, tip.dx, tip.dy)
        ..quadraticBezierTo((mid - side).dx, (mid - side).dy, base.dx, base.dy)
        ..close(),
      Paint()..shader = ui.Gradient.linear(base + side, tip - side, [m[2], m[1], m[0]], [0, .5, 1]),
    );
    canvas.drawLine(
      base,
      tip,
      Paint()
        ..color = m[0].withValues(alpha: .6)
        ..strokeWidth = hair * .6,
    );
  }

  /// الشريطة والميدالية تحت.
  void _medal(Canvas canvas, Offset c, double t) {
    final m = _m;
    final knot = c + Offset(0, r + ring * .55);
    final ribbon = Paint()..color = _ribbons[rank]!;
    for (final side in const [-1, 1]) {
      canvas.drawPath(
        poly([knot, knot + Offset(side * ring * 1.3, -ring * .55), knot + Offset(side * ring * 1.3, ring * .55)]),
        ribbon,
      );
    }
    final swing = .08 * math.sin(t * 1.8);
    canvas.save();
    canvas.translate(knot.dx, knot.dy);
    canvas.rotate(swing);
    final cr = ring * 1.05;
    final center = Offset(0, ring * .45 + cr);
    canvas.drawRect(Rect.fromLTRB(-ring * .35, 0, ring * .35, center.dy - cr * .6), ribbon);
    canvas.drawCircle(center + Offset(cr * .08, cr * .12), cr, Paint()..color = Colors.black.withValues(alpha: .3));
    canvas.drawCircle(
      center,
      cr,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.4),
          colors: [m[2], m[1], m[0]],
        ).createShader(Rect.fromCircle(center: center, radius: cr)),
    );
    canvas.drawCircle(
      center,
      cr * .8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = m[0].withValues(alpha: .7),
    );
    final digit = _digits.putIfAbsent('$rank:${cr.toStringAsFixed(1)}', () {
      return TextPainter(
        text: TextSpan(
          text: arabicNumber(rank),
          style: TextStyle(fontFamily: kufi, fontSize: cr * 1.25, fontWeight: FontWeight.w700, color: m[0], height: 1),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
    });
    digit.paint(canvas, center - Offset(digit.width / 2, digit.height / 2));
    // لمعة تمر على الميدالية كل شوي
    final g = (t % 2.6) / .7;
    final b = burst(t);
    if (g < 1 || b != null) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: cr)));
      if (g < 1) {
        final x = center.dx - cr * 1.5 + g * cr * 3;
        canvas.drawPath(
          poly([
            Offset(x, center.dy - cr),
            Offset(x + cr * .5, center.dy - cr),
            Offset(x - cr * .2, center.dy + cr),
            Offset(x - cr * .7, center.dy + cr),
          ]),
          Paint()..color = Colors.white.withValues(alpha: .55),
        );
      }
      if (b != null) canvas.drawCircle(center, cr, Paint()..color = Colors.white.withValues(alpha: .8 * (1 - b)));
      canvas.restore();
    }
    canvas.restore();
  }

  void _particles(Canvas canvas, Offset c, double t) {
    final n = small ? 9 : 15;
    for (var i = 0; i < n; i++) {
      switch (rank) {
        case 1:
          // قصاصات تنزل وتتقلب
          final life = frac(t * (.18 + rnd(i, 1) * .12) + rnd(i, 2));
          final x = (rnd(i, 3) - .5) * r * 3.1 + math.sin(t * 1.5 + i) * r * .1;
          final y = -r * 1.6 + life * r * 3.1;
          if (Offset(x, y).distance < r * 1.15) continue;
          final col = [_m[1], _ribbons[1]!, Colors.white, _m[2]][i % 4];
          canvas.save();
          canvas.translate(c.dx + x, c.dy + y);
          canvas.rotate(t * (2 + rnd(i, 4) * 3) + i);
          canvas.scale(math.cos(t * 4 + i).abs() * .8 + .2, 1);
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: ring * .55, height: ring * .32),
            Paint()..color = col.withValues(alpha: .9 * hump(life)),
          );
          canvas.restore();
        case 2:
          // لمعات صقيع تلمع وتتلاشى
          final tw = math.pow((math.sin(t * 2.2 + i * 2.1) + 1) / 2, 3).toDouble();
          final a = rnd(i, 5) * 2 * math.pi + t * .05;
          sparkle(
            canvas,
            c + dir(a) * r * (1.25 + .3 * rnd(i, 6)),
            ring * (.25 + .4 * tw),
            const Color(0xFFBAE6FD),
            tw,
          );
        default:
          // جمر يطلع لفوق
          final life = frac(t * (.3 + rnd(i, 7) * .25) + rnd(i, 8));
          final a = math.pi / 2 + (rnd(i, 9) - .5) * math.pi * 1.8;
          final pos = c + dir(a) * r * 1.2 + Offset(math.sin(life * 5 + i) * r * .06, -life * r * .8);
          dot(
            canvas,
            pos,
            math.max(.8, avatar * .013),
            Color.lerp(const Color(0xFFFFB74D), const Color(0xFFFF7043), life)!,
            life < .2 ? life / .2 : 1 - life,
          );
      }
    }
  }

  @override
  bool shouldRepaint(ChampionFrame old) => super.shouldRepaint(old) || old.rank != rank;
}
