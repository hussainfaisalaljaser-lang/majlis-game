import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

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
