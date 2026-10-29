import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'kit.dart';

// الإطارات الملحمية (الجزء الثاني): حركة مستمرة، ولكل إطار فكرة وحركة ما تتكرر في غيره.

/// قطرة سايلة تنزل من نقطة على الحلقة: تتجمع وتطول، وبعدين تنفصل وتطيح وتختفي.
void drip(Canvas canvas, Offset base, double p, double ring, double r, Color color, {Color? shine}) {
  final paint = Paint()..color = color;
  if (p < .58) {
    final q = p / .58;
    final len = ring * (.35 + 2.1 * q * q);
    final w = ring * (.42 + .1 * q);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - w * .55, base.dy)
        ..quadraticBezierTo(base.dx - w * .5, base.dy + len * .6, base.dx - w, base.dy + len)
        ..arcToPoint(Offset(base.dx + w, base.dy + len), radius: Radius.circular(w))
        ..quadraticBezierTo(base.dx + w * .5, base.dy + len * .6, base.dx + w * .55, base.dy)
        ..close(),
      paint,
    );
    if (shine != null) canvas.drawCircle(base + Offset(-w * .35, len * .9), w * .3, Paint()..color = shine);
    return;
  }
  final q = (p - .58) / .42;
  final pos = base + Offset(0, ring * 2.5 + q * r * .4 + q * q * r * .3);
  final s = ring * .48 * (1 - q * .35);
  canvas.drawCircle(pos, s, Paint()..color = color.withValues(alpha: 1 - q));
  if (shine != null) {
    canvas.drawCircle(pos + Offset(-s * .35, -s * .3), s * .3, Paint()..color = shine.withValues(alpha: 1 - q));
  }
  // بقايا صغيرة في مكانها
  canvas.drawCircle(base + Offset(0, ring * .3), ring * .35 * (1 - q), paint);
}

/// برق متكسر بين نقاط: توهج عريض وقلب أبيض.
void bolt(Canvas canvas, List<Offset> pts, double width, Color glow, double alpha) {
  if (alpha <= 0 || pts.length < 2) return;
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final q in pts.skip(1)) {
    path.lineTo(q.dx, q.dy);
  }
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 4
      ..strokeJoin = StrokeJoin.round
      ..color = glow.withValues(alpha: .4 * alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 2)
      ..blendMode = BlendMode.plus,
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: alpha),
  );
}

// ═════════════ نيون ═════════════

/// نيون: أنبوبين نيون (فيروزي برا ووردي جوا) على مسامير تثبيت، يطنّون ويرمشون مثل لوحات المحلات،
/// وكل كم ثانية تجيهم دفعة كهربا ويضوون أكثر.
class NeonFrame extends FrameArt {
  NeonFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _cyan = Color(0xFF00F5FF);
  static const _pink = Color(0xFFFF00E5);
  static const _clip = Color(0xFF1F2937);

  @override
  void back(Canvas canvas, Offset c, double t) {
    halo(
      canvas,
      c,
      r * 1.6,
      [Colors.transparent, _cyan.withValues(alpha: .12), _pink.withValues(alpha: .1), Colors.transparent],
      stops: const [.55, .7, .85, 1],
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final step = (t * 14).floor();
    final surge = t % 4 < .25 ? hump((t % 4) / .25) : 0.0;
    final buzz = .88 + .12 * math.sin(t * 47);
    canvas.drawCircle(
      c,
      mid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring * 1.6
        ..color = const Color(0xFF0B0B14),
    );
    const gap = .16;
    for (final (j, (radius, color, segs, offset)) in [
      (r + ring * 1.0, _cyan, 4, .3),
      (r + ring * .2, _pink, 3, 1.1),
    ].indexed) {
      final rect = Rect.fromCircle(center: c, radius: radius);
      for (var k = 0; k < segs; k++) {
        final start = offset + k * 2 * math.pi / segs + gap / 2;
        final sweep = 2 * math.pi / segs - gap;
        // قطعة وحدة "تعبانة" ترمش أكثر من الباقي
        final odds = k == 1 && j == 0 ? .2 : .035;
        final on = rnd(step, j * 10 + k) > odds;
        final a = on ? buzz * (1 + .45 * surge) : .12;
        for (final (w, alpha, blur) in [(ring * 1.5, .32, ring * .9), (ring * .55, .85, ring * .2)]) {
          canvas.drawArc(
            rect,
            start,
            sweep,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = w
              ..strokeCap = StrokeCap.round
              ..color = color.withValues(alpha: (alpha * a).clamp(0.0, 1.0))
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur)
              ..blendMode = BlendMode.plus,
          );
        }
        canvas.drawArc(
          rect,
          start,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = ring * .18
            ..strokeCap = StrokeCap.round
            ..color = Color.lerp(color, Colors.white, .75)!.withValues(alpha: (.95 * a).clamp(0.0, 1.0)),
        );
        // مسمار التثبيت عند الفراغ
        final pos = c + dir(start - gap / 2) * radius;
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(start - gap / 2 + math.pi / 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: ring * .5, height: ring * .7),
            Radius.circular(ring * .12),
          ),
          Paint()..color = _clip,
        );
        canvas.restore();
      }
    }
  }
}

// ═════════════ قوس قزح (صبغ) ═════════════

/// قوس قزح: صبغ ملوّن يسيل حول الصورة بحافة متموجة ولمعة مبلولة، ويقطّر من تحت قطرات بألوانه.
class RainbowFrame extends FrameArt {
  RainbowFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _cols = [Color(0xFFFF1744), Color(0xFFFFEA00), Color(0xFF00E676), Color(0xFF00B0FF), Color(0xFFD500F9)];

  Color _colorAt(double a, double t) {
    final x = frac(a / (2 * math.pi) * 2 + t * .12) * _cols.length;
    final i = x.floor();
    return Color.lerp(_cols[i % _cols.length], _cols[(i + 1) % _cols.length], x - i)!;
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    const steps = 90;
    final outer = <Offset>[], inner = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final a = i * 2 * math.pi / steps;
      outer.add(c + dir(a) * (r + ring * (1.05 + .28 * math.sin(5 * a + t * 1.6) + .12 * math.sin(9 * a - t * 2.3))));
      inner.add(c + dir(a) * r);
    }
    final band = poly([...outer, ...inner.reversed]);
    final rect = Rect.fromCircle(center: c, radius: r + ring * 1.5);
    canvas.drawPath(
      band,
      Paint()
        ..shader = SweepGradient(
          colors: [..._cols, ..._cols, _cols.first],
          transform: GradientRotation(-t * .75),
        ).createShader(rect),
    );
    // طبقة ثانية تمشي عكسها، عشان يبان مثل الرخام السايل
    canvas.drawPath(
      band,
      Paint()
        ..shader = SweepGradient(
          colors: [..._cols.reversed, _cols.last].map((e) => e.withValues(alpha: .4)).toList(),
          transform: GradientRotation(t * .5),
        ).createShader(rect)
        ..blendMode = BlendMode.screen,
    );
    line(canvas, c, r, Colors.white.withValues(alpha: .55));
    // لمعة مبلولة
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: mid),
      -2.65,
      .95,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring * .26
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .6),
    );
    // القطرات
    for (final (i, a) in const [-.55, .05, .62].indexed) {
      final ang = math.pi / 2 + a;
      final p = frac(t / (2.6 + .5 * rnd(i, 2)) + rnd(i, 3));
      drip(
        canvas,
        c + dir(ang) * (r + ring * 1.0),
        p,
        ring,
        r,
        _colorAt(ang, t),
        shine: Colors.white.withValues(alpha: .7),
      );
    }
  }
}

// ═════════════ زمرد ═════════════

/// زمرد: حلقة ذهب مركّب عليها ٨ أحجار زمرد مقطّعة، والضو ينتقل من حجر لحجر ويلمع.
class EmeraldFrame extends FrameArt {
  EmeraldFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _g1 = Color(0xFF00C853);
  static const _g2 = Color(0xFF69F0AE);
  static const _g3 = Color(0xFF00695C);
  static const _gold = Color(0xFFE6B84A);
  static const _goldD = Color(0xFF8A6418);
  static const _goldL = Color(0xFFFFE7A3);

  @override
  void front(Canvas canvas, Offset c, double t) {
    glowRing(canvas, c, _g1.withValues(alpha: .22 + .08 * math.sin(t)));
    sweepRing(canvas, c, const [_goldD, _gold, _goldL, _gold, _goldD, _gold], turn: .3);
    line(canvas, c, r + ring, _goldD);
    line(canvas, c, r, _goldL.withValues(alpha: .7));
    const n = 8;
    final light = (t * 1.4) % n;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n - math.pi / 2 + math.pi / n;
      var d = (i - light).abs();
      d = math.min(d, n - d);
      _gem(canvas, c + dir(a) * mid, a, math.exp(-d * d * 1.6));
    }
  }

  /// حجر مقطّع (مستطيل مقصوص الزوايا) باتجاه الحلقة.
  void _gem(Canvas canvas, Offset p, double a, double b) {
    final w = ring * 1.8, h = ring * 1.3, k = h * .3;
    final along = dir(a + math.pi / 2), out = dir(a);
    Offset at(double x, double y) => p + along * x + out * y;
    final outline = [
      at(-w / 2 + k, -h / 2),
      at(w / 2 - k, -h / 2),
      at(w / 2, -h / 2 + k),
      at(w / 2, h / 2 - k),
      at(w / 2 - k, h / 2),
      at(-w / 2 + k, h / 2),
      at(-w / 2, h / 2 - k),
      at(-w / 2, -h / 2 + k),
    ];
    if (b > .05) halo(canvas, p, ring * 1.9, [_g2.withValues(alpha: .55 * b), _g2.withValues(alpha: 0)]);
    canvas.drawPath(
      poly(outline),
      Paint()
        ..shader = ui.Gradient.linear(
          at(-w / 2, -h / 2),
          at(w / 2, h / 2),
          [Color.lerp(_g2, Colors.white, b * .4)!, Color.lerp(_g1, _g2, b * .5)!, _g3],
          [0, .45, 1],
        ),
    );
    final innerPts = [for (final q in outline) p + (q - p) * .55];
    final facet = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair * .8
      ..color = Colors.white.withValues(alpha: .3 + .3 * b);
    canvas.drawPath(poly(innerPts), facet);
    for (var j = 0; j < 8; j += 2) {
      canvas.drawLine(innerPts[j], outline[j], facet);
    }
    // مخالب الذهب
    final prong = Paint()..color = _goldL;
    for (final q in [outline[0], outline[3], outline[4], outline[7]]) {
      canvas.drawCircle(q, hair * 1.1, prong);
    }
    if (b > .3) sparkle(canvas, at(-w * .2, -h * .15), ring * .75 * b, _g2, b);
  }
}

// ═════════════ دم الخونة ═════════════

/// دم الخونة: الحلقة تنبض نبضة قلب (دقتين)، وعروقها تضوي مع كل دقة، وقطرات دم تتجمع وتنزل من تحت.
class BloodFrame extends FrameArt {
  BloodFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _crimson = Color(0xFFB71C1C);
  static const _black = Color(0xFF1A0000);
  static const _red = Color(0xFFFF1744);
  static const _vein = Color(0xFFFF5252);

  static double beat(double t) {
    final p = frac(t / 1.2);
    return math.max(math.exp(-math.pow((p - .1) / .05, 2)), .8 * math.exp(-math.pow((p - .3) / .05, 2))).toDouble();
  }

  @override
  void back(Canvas canvas, Offset c, double t) {
    final b = beat(t);
    halo(
      canvas,
      c,
      r * (1.45 + .12 * b),
      [_red.withValues(alpha: 0), _red.withValues(alpha: .16 + .4 * b), _red.withValues(alpha: 0)],
      stops: const [.62, .78, 1],
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final b = beat(t);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1 + .03 * b);
    canvas.translate(-c.dx, -c.dy);
    sweepRing(canvas, c, const [_black, _crimson, _black, Color(0xFF7F0000)], turn: .5);
    // العروق
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair * 1.1
      ..color = _vein.withValues(alpha: .25 + .6 * b);
    for (var k = 0; k < 4; k++) {
      final path = Path();
      const steps = 40;
      final a0 = k * math.pi / 2 + .3;
      for (var j = 0; j <= steps; j++) {
        final a = a0 + j / steps * 1.3;
        final q = c + dir(a) * (mid + ring * .32 * math.sin(a * 7 + k * 1.7));
        j == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(path, vein);
    }
    line(canvas, c, r, Colors.black.withValues(alpha: .5));
    line(canvas, c, r + ring, _red.withValues(alpha: .35 + .4 * b));
    canvas.restore();
    // قطرات الدم
    for (final (i, a) in const [-.9, -.3, .35, .85].indexed) {
      final ang = math.pi / 2 + a;
      final p = frac(t / (2.3 + .8 * rnd(i, 1)) + rnd(i, 2));
      drip(canvas, c + dir(ang) * (r + ring * .95), p, ring * .9, r, _crimson, shine: _vein.withValues(alpha: .8));
    }
  }
}

// ═════════════ الذهب الأسود ═════════════

/// الذهب الأسود: حجر أسود عليه لمعة زيت ملوّنة، وعروق ذهب ذايب تمشي فيه وتتوهج، وقطرة ذهب تدور.
class BlackGoldFrame extends FrameArt {
  BlackGoldFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _black = Color(0xFF111111);
  static const _gold = Color(0xFFFFD54F);
  static const _amber = Color(0xFFFFB300);
  static const _brown = Color(0xFF3E2723);
  static const _pale = Color(0xFFFFF3C4);

  @override
  void back(Canvas canvas, Offset c, double t) {
    glowRing(
      canvas,
      c,
      _amber.withValues(alpha: .2 + .06 * math.sin(t * 1.6)),
      width: ring * 2.4,
      blur: ring * 1.2,
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    sweepRing(canvas, c, const [_black, Color(0xFF2A2A2A), _black, Color(0xFF1C1C1C)], width: ring * 1.15);
    // لمعة الزيت
    canvas.drawCircle(
      c,
      mid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring
        ..blendMode = BlendMode.plus
        ..shader = SweepGradient(
          colors: const [Color(0x002A9D8F), Color(0x332A9D8F), Color(0x33E879F9), Color(0x00E879F9), Color(0x002A9D8F)],
          transform: GradientRotation(t * .3),
        ).createShader(Rect.fromCircle(center: c, radius: mid)),
    );
    // العروق
    final rect = Rect.fromCircle(center: c, radius: r * 1.3);
    final molten = SweepGradient(
      colors: const [_brown, _amber, _pale, _amber, _brown, _amber, _gold, _brown],
      transform: GradientRotation(t * .9),
    ).createShader(rect);
    for (var k = 0; k < 3; k++) {
      final path = Path();
      const steps = 44;
      final a0 = k * 2.1 + .4;
      for (var j = 0; j <= steps; j++) {
        final a = a0 + j / steps * 2.3;
        final q = c + dir(a) * (mid + ring * .38 * math.sin(a * 9 + k * 2.1) * (.6 + .4 * math.sin(a * 3 + k)));
        j == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring * .55
          ..color = _amber.withValues(alpha: .38 + .2 * math.sin(t * 2 + k))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring * .35),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = hair * 1.6
          ..strokeCap = StrokeCap.round
          ..shader = molten,
      );
    }
    // حواف ذهب
    for (final (radius, width) in [(r + ring * 1.08, hair * 1.8), (r - ring * .08, hair * 1.3)]) {
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..shader = SweepGradient(
            colors: const [_amber, _pale, _gold, _brown, _amber],
            transform: GradientRotation(-t * .4),
          ).createShader(Rect.fromCircle(center: c, radius: radius)),
      );
    }
    // قطرة ذهب تدور وتخلي وراها خط
    final a = t * .8;
    for (var k = 6; k >= 1; k--) {
      dot(canvas, c + dir(a - k * .06) * mid, ring * .18 * (1 - k / 8), _gold, .5 * (1 - k / 7));
    }
    dot(canvas, c + dir(a) * mid, ring * .28, _gold, 1);
  }
}

// ═════════════ النخبة (مستوى ٢٠) ═════════════

/// النخبة: فضة مصقولة ينعكس عليها الضو وهي تدور، ونقش محفور، ولمعة تمشي حولها، ونجوم فضة صغيرة حولها.
class EliteFrame extends FrameArt {
  EliteFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _s1 = Color(0xFFE5E7EB);
  static const _s2 = Color(0xFF9CA3AF);
  static const _s3 = Color(0xFF4B5563);

  @override
  void front(Canvas canvas, Offset c, double t) {
    sweepRing(canvas, c, const [_s3, _s1, Colors.white, _s2, _s3, _s1, _s2, Colors.white], turn: t * .25);
    // النقش: خطوط S صغيرة على الحلقة
    final engr = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair * .8
      ..color = _s3.withValues(alpha: .6);
    for (var k = 0; k < (small ? 10 : 16); k++) {
      final a = k * 2 * math.pi / (small ? 10 : 16);
      final p = c + dir(a) * mid;
      final along = dir(a + math.pi / 2);
      canvas.drawArc(Rect.fromCircle(center: p - along * ring * .2, radius: ring * .2), a, math.pi, false, engr);
      canvas.drawArc(
        Rect.fromCircle(center: p + along * ring * .2, radius: ring * .2),
        a + math.pi,
        math.pi,
        false,
        engr,
      );
    }
    line(canvas, c, r + ring, _s3);
    line(canvas, c, r + ring * .9, Colors.white.withValues(alpha: .6));
    line(canvas, c, r, _s3.withValues(alpha: .8));
    // لمعة تمشي حول الحلقة
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: mid),
      t * .9,
      .38,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring * .55
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .75)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring * .3)
        ..blendMode = BlendMode.plus,
    );
    // نجوم فضة صغيرة تلمع حولها
    for (var i = 0; i < (small ? 4 : 7); i++) {
      final a = rnd(i, 1) * 2 * math.pi + t * .08;
      final tw = math.pow((math.sin(t * 2.6 + i * 2) + 1) / 2, 3).toDouble();
      sparkle(canvas, c + dir(a) * r * (1.2 + .25 * rnd(i, 2)), ring * (.25 + .4 * tw), _s1, tw);
    }
  }
}

// ═════════════ الذهبي (مستوى ٣٠) ═════════════

/// الذهبي: عقد جنيهات ذهب على سلسلة يدور ببطء، وكل جنيه ينقلب ويلمع لما يواجهك.
class GoldenFrame extends FrameArt {
  GoldenFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _g = Color(0xFFFFB300);
  static const _gl = Color(0xFFFFE082);
  static const _gp = Color(0xFFFFF8E1);
  static const _gd = Color(0xFF9A6A00);

  @override
  void front(Canvas canvas, Offset c, double t) {
    glowRing(canvas, c, _g.withValues(alpha: .28));
    line(canvas, c, mid, _gd, width: ring * .4);
    canvas.drawCircle(
      c,
      mid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring * .22
        ..color = _gl.withValues(alpha: .8),
    );
    final n = small ? 10 : 14;
    final cr = ring * (small ? 1.1 : 1.0);
    for (var i = 0; i < n; i++) {
      final a = t * .18 + i * 2 * math.pi / n;
      final p = c + dir(a) * mid;
      final flip = math.cos(t * 2.1 + i * .9);
      final sx = math.max(.12, flip.abs());
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a + math.pi / 2);
      canvas.scale(sx, 1);
      canvas.drawCircle(Offset.zero, cr, Paint()..color = _gd);
      canvas.drawCircle(
        Offset.zero,
        cr * .92,
        Paint()
          ..shader = RadialGradient(
            center: Alignment(flip > 0 ? -.3 : .3, -.35),
            colors: const [_gp, _gl, _g, _gd],
            stops: const [0, .35, .75, 1],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: cr)),
      );
      canvas.drawCircle(
        Offset.zero,
        cr * .74,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = hair * .9
          ..color = _gd.withValues(alpha: .6),
      );
      if (sx > .4) canvas.drawPath(star5(Offset.zero, cr * .42), Paint()..color = _gd.withValues(alpha: .55));
      final flash = math.pow(sx, 14).toDouble();
      if (flash > .05) {
        canvas.drawCircle(Offset.zero, cr, Paint()..color = Colors.white.withValues(alpha: .55 * flash));
      }
      canvas.restore();
    }
  }
}

// ═════════════ ليالي المجلس ═════════════

/// ليالي المجلس: حلقة كحلية بزخرفة ذهب، وزينة أضواء رمضان تلمع بالدور فوق الصورة،
/// وفانوسين معلقين على الجنبين يتمرجحون وشمعتهم ترجف.
class LanternsFrame extends FrameArt {
  LanternsFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _indigo = Color(0xFF1E1B4B);
  static const _gold = Color(0xFFFCD34D);
  static const _teal = Color(0xFF0F766E);
  static const _mint = Color(0xFF5EEAD4);
  static const _flame = Color(0xFFFFB74D);

  static const _hooks = [-2.45, -.69];

  @override
  void front(Canvas canvas, Offset c, double t) {
    sweepRing(canvas, c, const [_indigo, Color(0xFF312E81), _indigo, Color(0xFF1E1B4B)]);
    line(canvas, c, r + ring, _gold, width: hair * 1.3);
    line(canvas, c, r, _gold.withValues(alpha: .75));
    // زخرفة: معينات ذهب ونقاط فيروزية بالتناوب
    for (var k = 0; k < 16; k++) {
      final a = k * math.pi / 8;
      final p = c + dir(a) * mid;
      if (k.isEven) {
        final along = dir(a + math.pi / 2) * ring * .32, out = dir(a) * ring * .3;
        canvas.drawPath(poly([p + along, p + out, p - along, p - out]), Paint()..color = _gold);
      } else {
        canvas.drawCircle(p, ring * .14, Paint()..color = _mint);
      }
    }
    _garland(canvas, c, t);
    for (final (i, a) in _hooks.indexed) {
      _lantern(canvas, c + dir(a) * r * 1.22, t, i);
    }
  }

  /// زينة: خيط مقوّس فوق الصورة بين الفانوسين، متدلي شوي بين كل نقطتين، وعليه لمبات تولّع بالدور.
  void _garland(Canvas canvas, Offset c, double t) {
    final a0 = _hooks[0], a1 = _hooks[1];
    const steps = 40;
    final path = Path();
    Offset at(double s) {
      final a = a0 + (a1 - a0) * s;
      final sag = (1 - math.cos(s * 3 * 2 * math.pi)) / 2;
      return c + dir(a) * (r * 1.22 - r * .07 * sag);
    }

    for (var j = 0; j <= steps; j++) {
      final q = at(j / steps);
      j == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair
        ..color = const Color(0xFF8A7A4A),
    );
    final n = small ? 7 : 11;
    final chase = (t * 4).floor();
    for (var i = 0; i < n; i++) {
      final s = (i + .5) / n;
      final on = (i + chase) % 3 == 0;
      final col = [_gold, _mint, Colors.white][i % 3];
      dot(canvas, at(s) + Offset(0, ring * .25), ring * .2, col, on ? 1 : .35);
    }
  }

  /// فانوس معلق من [hook]: سلسلة، وغطا، وزجاج ملوّن، وشمعة.
  void _lantern(Canvas canvas, Offset hook, double t, int i) {
    final swing = .14 * math.sin(t * 1.6 + i * 1.3);
    final chain = r * .2, h = r * .42, w = r * .22;
    canvas.save();
    canvas.translate(hook.dx, hook.dy);
    canvas.rotate(swing);
    final flick = .7 + .3 * noise(t * 4 + i * 3, i);
    halo(canvas, Offset(0, chain + h * .55), r * .38, [
      _flame.withValues(alpha: .35 * flick),
      _flame.withValues(alpha: 0),
    ]);
    canvas.drawLine(
      Offset.zero,
      Offset(0, chain),
      Paint()
        ..color = _gold
        ..strokeWidth = hair,
    );
    final top = chain;
    // الغطا
    canvas.drawPath(
      poly([Offset(-w * .7, top + h * .22), Offset(0, top), Offset(w * .7, top + h * .22)]),
      Paint()..color = _gold,
    );
    // الزجاج: سداسي ملوّن ومن داخله الضو
    final body = poly([
      Offset(-w * .7, top + h * .22),
      Offset(w * .7, top + h * .22),
      Offset(w, top + h * .5),
      Offset(w * .7, top + h * .8),
      Offset(-w * .7, top + h * .8),
      Offset(-w, top + h * .5),
    ]);
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          colors: [Color.lerp(_flame, Colors.white, .5 * flick)!, _flame.withValues(alpha: .9), _teal],
          stops: const [0, .45, 1],
        ).createShader(Rect.fromCircle(center: Offset(0, top + h * .5), radius: w)),
    );
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair
      ..color = _gold;
    canvas.drawPath(body, frame);
    canvas.drawLine(Offset(0, top + h * .22), Offset(0, top + h * .8), frame);
    // القاعدة
    canvas.drawPath(
      poly([Offset(-w * .7, top + h * .8), Offset(w * .7, top + h * .8), Offset(0, top + h)]),
      Paint()..color = _gold,
    );
    canvas.restore();
  }
}
