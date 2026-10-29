import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'kit.dart';

// الإطارات الملحمية (الجزء الثاني) بأسلوب رسمات الفيديو: حد غامق، ظل بدرجتين، لمعة بيضا، وهالات بتدرج.
// حركة مستمرة، ولكل إطار فكرة وحركة ما تتكرر في غيره.

/// قطرة سايلة تنزل من نقطة على الحلقة: تتجمع وتطول (بحد غامق ولمعة وبصلة بالطرف)، وبعدين تنفصل
/// وتطيح (دمعة) وتختفي.
void drip(Canvas canvas, Offset base, double p, double ring, double r, Color color, {Color? shine, Color edge = ink}) {
  final lw = math.max(1.0, r * .034);
  final paint = Paint()..color = color;
  Paint outline([double alpha = 1]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = lw
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = edge.withValues(alpha: alpha);
  if (p < .58) {
    final q = p / .58;
    final len = ring * (.55 + 2.4 * q * q);
    final w = ring * (.5 + .12 * q);
    // الجنبين والبصلة بس (بدون خط فوق عشان تلتحم القطرة بالحلقة)
    final open = Path()
      ..moveTo(base.dx - w * .62, base.dy)
      ..cubicTo(base.dx - w * .5, base.dy + len * .45, base.dx - w * .95, base.dy + len * .5, base.dx - w * .9, base.dy + len * .8)
      ..arcToPoint(Offset(base.dx + w * .9, base.dy + len * .8), radius: Radius.circular(w * .9), clockwise: false)
      ..cubicTo(base.dx + w * .95, base.dy + len * .5, base.dx + w * .5, base.dy + len * .45, base.dx + w * .62, base.dy);
    canvas.drawPath(Path.from(open)..close(), paint);
    canvas.drawPath(open, outline());
    if (shine != null) canvas.drawCircle(base + Offset(-w * .4, len * .78), w * .26, Paint()..color = shine);
    return;
  }
  final q = (p - .58) / .42;
  final pos = base + Offset(0, ring * 2.7 + q * r * .3 + q * q * r * .2);
  final s = ring * .5 * (1 - q * .35);
  final drop = Path()
    ..moveTo(pos.dx, pos.dy - s * 1.8)
    ..cubicTo(pos.dx + s * .2, pos.dy - s * .9, pos.dx + s, pos.dy - s * .5, pos.dx + s, pos.dy + s * .1)
    ..arcToPoint(Offset(pos.dx - s, pos.dy + s * .1), radius: Radius.circular(s))
    ..cubicTo(pos.dx - s, pos.dy - s * .5, pos.dx - s * .2, pos.dy - s * .9, pos.dx, pos.dy - s * 1.8)
    ..close();
  canvas.drawPath(drop, Paint()..color = color.withValues(alpha: 1 - q));
  canvas.drawPath(drop, outline(1 - q));
  if (shine != null) {
    canvas.drawCircle(pos + Offset(-s * .4, s * -.1), s * .28, Paint()..color = shine.withValues(alpha: 1 - q));
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

/// نيون: لوحة داكنة مدوّرة بحد غامق تحمل أنبوبين نيون زجاجيين (فيروزي برا ووردي جوا) على مسامير فضة،
/// يطنّون ويرمشون، وقطعة تعبانة ترمش أكثر، وكل ٤ ثواني دفعة كهربا تضوّيهم أكثر وتطلع منها شراره عند الفراغات.
class NeonFrame extends FrameArt {
  NeonFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _cyan = Color(0xFF19E6FF);
  static const _pink = Color(0xFFFF35D8);
  static const _line = Color(0xFF0B0616);

  double _surge(double t) => t % 4 < .25 ? hump((t % 4) / .25) : 0.0;

  @override
  void back(Canvas canvas, Offset c, double t) {
    final s = _surge(t);
    halo(
      canvas,
      c,
      r * 1.75,
      [
        Colors.transparent,
        _cyan.withValues(alpha: .2 + .18 * s),
        _pink.withValues(alpha: .18 + .16 * s),
        Colors.transparent,
      ],
      stops: const [.55, .72, .86, 1],
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final step = (t * 14).floor();
    final surge = _surge(t);
    final buzz = .9 + .1 * math.sin(t * 47);
    final out = r + ring * (small ? 2.0 : 2.3);
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(-r * .4, -r), c + Offset(r * .4, r), const [Color(0xFF3A2660), Color(0xFF1C1133), Color(0xFF0E0820)]),
      edge: _line,
    );
    // لمعة خفيفة على حافة اللوحة
    gloss(canvas, c, out - ring * .25, ring * .14, from: -2.8, span: 1.0, alpha: .3);
    final tw = ring * (small ? .6 : .66);
    for (final (j, (radius, color, segs, offset)) in [
      (r + ring * (small ? 1.45 : 1.6), _cyan, 4, .3),
      (r + ring * (small ? .62 : .66), _pink, 3, 1.1),
    ].indexed) {
      final rect = Rect.fromCircle(center: c, radius: radius);
      const gap = .17;
      for (var k = 0; k < segs; k++) {
        final start = offset + k * 2 * math.pi / segs + gap / 2;
        final sweepA = 2 * math.pi / segs - gap;
        // قطعة وحدة "تعبانة" ترمش أكثر من الباقي
        final odds = k == 1 && j == 0 ? .2 : .035;
        final on = rnd(step, j * 10 + k) > odds;
        final a = on ? (buzz * (1 + .3 * surge)).clamp(0.0, 1.3) : 0.0;
        // الحد الغامق للأنبوب
        canvas.drawArc(
          rect,
          start,
          sweepA,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = tw + lw * 1.7
            ..strokeCap = StrokeCap.round
            ..color = _line,
        );
        // الجسم (مطفي: لون باهت)
        final body = Color.lerp(Color.lerp(color, Colors.black, .72)!, color, a.clamp(0.0, 1.0))!;
        canvas.drawArc(
          rect,
          start,
          sweepA,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = tw
            ..strokeCap = StrokeCap.round
            ..color = body,
        );
        if (a > 0) {
          // توهج حول الأنبوب (خط أعرض شفاف بدل البلور)
          canvas.drawArc(
            rect,
            start,
            sweepA,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = tw * 2.3
              ..strokeCap = StrokeCap.round
              ..color = color.withValues(alpha: (.2 * a).clamp(0.0, 1.0))
              ..blendMode = BlendMode.plus,
          );
          // قلب أبيض حار
          canvas.drawArc(
            rect,
            start,
            sweepA,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = tw * .36
              ..strokeCap = StrokeCap.round
              ..color = Color.lerp(color, Colors.white, .82)!.withValues(alpha: (.95 * a).clamp(0.0, 1.0)),
          );
        }
        // لمعة الزجاج
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: radius + tw * .22),
          start + sweepA * .08,
          sweepA * .35,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(.8, tw * .13)
            ..strokeCap = StrokeCap.round
            ..color = Colors.white.withValues(alpha: .45),
        );
        // مسمار التثبيت عند الفراغ
        final ang = start - gap / 2;
        final pos = at(c, ang, radius);
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(ang + math.pi / 2);
        final clip = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: ring * .72, height: ring * 1.0),
          Radius.circular(ring * .16),
        );
        canvas.drawRRect(clip, Paint()..shader = lin(Offset(0, -ring * .5), Offset(0, ring * .5), const [Color(0xFFE8ECF4), Color(0xFF7C86A0)]));
        canvas.drawRRect(
          clip,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(.8, lw * .8)
            ..color = _line,
        );
        canvas.restore();
        // شراره كهربا عند الفراغ وقت الدفعة
        if (surge > .3 && !small) {
          final seed = step * 7 + k + j * 5;
          final from = at(c, ang, radius);
          final to = at(c, ang + (rnd(seed, 3) - .5) * .5, radius + ring * (.9 + .8 * rnd(seed, 4)) * (j == 0 ? 1 : -.6));
          canvas.drawPath(
            zigzag(from, to, 3, ring * .25, seed),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(.8, lw * .9)
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = Color.lerp(color, Colors.white, .8)!.withValues(alpha: surge),
          );
        }
      }
    }
  }
}

// ═════════════ قوس قزح (صبغ) ═════════════

/// قوس قزح: صبغ كرتوني ملوّن لماع يسيل حول الصورة بحافة متموجة بحد غامق، والألوان تمشي وتلف،
/// ولمعة مبلولة بيضا، ويقطّر من تحت قطرات بألوانه.
class RainbowFrame extends FrameArt {
  RainbowFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _cols = [
    Color(0xFFFF3B4E),
    Color(0xFFFF9A2E),
    Color(0xFFFFE53B),
    Color(0xFF3FD66B),
    Color(0xFF2FA8FF),
    Color(0xFFB24BF3),
  ];

  Color _colorAt(double a, double t) {
    final x = frac(a / (2 * math.pi) - t * .12) * _cols.length;
    final i = x.floor();
    return Color.lerp(_cols[i % _cols.length], _cols[(i + 1) % _cols.length], x - i)!;
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    const steps = 96;
    final outer = <Offset>[];
    for (var i = 0; i < steps; i++) {
      final a = i * 2 * math.pi / steps;
      outer.add(at(c, a, r + ring * (1.45 + .26 * math.sin(5 * a + t * 1.6) + .12 * math.sin(9 * a - t * 2.3))));
    }
    final shape = Path()
      ..fillType = PathFillType.evenOdd
      ..addPolygon(outer, true)
      ..addOval(Rect.fromCircle(center: c, radius: r));
    final out = r + ring * 1.9;
    // الألوان تلف حول الحلقة
    canvas.drawPath(shape, Paint()..shader = sweep(c, [..._cols, ..._cols], turn: -t * .75));
    // ظل أسفل (درجة ثانية) عشان يبان مجسم
    canvas.drawPath(
      shape,
      Paint()..shader = lin(c + Offset(0, -out), c + Offset(0, out), [Colors.transparent, Colors.black.withValues(alpha: .1), Colors.black.withValues(alpha: .34)], const [.35, .65, 1]),
    );
    canvas.drawPath(
      Path()..addPolygon(outer, true),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw * 1.15
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF2A1040),
    );
    line(canvas, c, r, const Color(0xFF2A1040), width: lw * 1.2);
    // لمعة مبلولة
    gloss(canvas, c, r + ring * .95, ring * .32, from: -2.8, span: 1.15, alpha: .78);
    gloss(canvas, c, r + ring * .95, ring * .2, from: -1.35, span: .22, alpha: .6);
    gloss(canvas, c, r + ring * .55, ring * .12, from: .5, span: .7, alpha: .4);
    // القطرات
    for (final (i, a) in const [-.55, .05, .62].indexed) {
      final ang = math.pi / 2 + a;
      final p = frac(t / (2.6 + .5 * rnd(i, 2)) + rnd(i, 3));
      drip(
        canvas,
        at(c, ang, r + ring * 1.15),
        p,
        ring,
        r,
        _colorAt(ang, t),
        shine: Colors.white.withValues(alpha: .75),
        edge: const Color(0xFF2A1040),
      );
    }
    if (!small) twinkles(canvas, c, t, n: 3, rIn: 1.25, rOut: 1.5, speed: .6, salt: 5);
  }
}

// ═════════════ زمرد ═════════════

/// زمرد: حلقة ذهب مركّب عليها ٨ أحجار زمرد مقطّعة بحد غامق ومخالب ذهب، والضو ينتقل من حجر لحجر ويلمع،
/// وهالة خضرا ناعمة تنبض ورا الحلقة.
class EmeraldFrame extends FrameArt {
  EmeraldFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _edge = Color(0xFF3A2406);
  static const _gemEdge = Color(0xFF053B22);

  @override
  void back(Canvas canvas, Offset c, double t) {
    halo(
      canvas,
      c,
      r * 1.7,
      [Colors.transparent, const Color(0xFF16D470).withValues(alpha: .26 + .1 * math.sin(t)), Colors.transparent],
      stops: const [.58, .78, 1],
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final out = r + ring * 1.3;
    band(canvas, c, r, out, goldShader(c, out), edge: _edge);
    gloss(canvas, c, r + ring * .55, ring * .17, from: -2.7, span: 1.2, alpha: .65);
    line(canvas, c, r + lw * .9, const Color(0xFF8A4E10), width: lw * 1.1);
    const n = 8;
    final light = (t * 1.4) % n;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n - math.pi / 2 + math.pi / n;
      var d = (i - light).abs();
      d = math.min(d, n - d);
      _gem(canvas, at(c, a, r + ring * .66), a, math.exp(-d * d * 1.6));
    }
  }

  /// حجر مقطّع (مستطيل مقصوص الزوايا) باتجاه الحلقة، داخل إطار ذهب بحد غامق.
  void _gem(Canvas canvas, Offset p, double a, double b) {
    final w = ring * 2.25, h = ring * 1.65, k = h * .32;
    final along = dir(a + math.pi / 2), outD = dir(a);
    Offset pt(double x, double y) => p + along * x + outD * y;
    List<Offset> octa(double sx, double sy) => [
      pt(-sx / 2 + k, -sy / 2),
      pt(sx / 2 - k, -sy / 2),
      pt(sx / 2, -sy / 2 + k),
      pt(sx / 2, sy / 2 - k),
      pt(sx / 2 - k, sy / 2),
      pt(-sx / 2 + k, sy / 2),
      pt(-sx / 2, sy / 2 - k),
      pt(-sx / 2, -sy / 2 + k),
    ];
    if (b > .05) {
      halo(canvas, p, ring * 2.3, [const Color(0xFF7BFFB2).withValues(alpha: .55 * b), const Color(0xFF7BFFB2).withValues(alpha: 0)]);
    }
    // إطار الذهب (بيزل)
    final bezel = octa(w * 1.28, h * 1.34);
    inked(canvas, poly(bezel), shader: goldShader(p, ring * 1.6), edge: _edge, w: math.max(.8, lw * .9));
    // الحجر
    final gem = octa(w, h);
    final lit = Color.lerp(const Color(0xFF8FFFC4), Colors.white, b * .5)!;
    inked(
      canvas,
      poly(gem),
      shader: lin(pt(-w / 2, -h / 2), pt(w / 2, h / 2), [lit, Color.lerp(const Color(0xFF1FCB6E), const Color(0xFF6BF0A4), b * .6)!, const Color(0xFF087048)], const [0, .5, 1]),
      edge: _gemEdge,
      w: math.max(.7, lw * .75),
    );
    if (!small) {
      // الأوجه
      final innerPts = [for (final q in gem) p + (q - p) * .55];
      final facet = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, hair * .9)
        ..color = Colors.white.withValues(alpha: .28 + .3 * b);
      canvas.drawPath(poly(innerPts), facet);
      for (var j = 0; j < 8; j += 2) {
        canvas.drawLine(innerPts[j], gem[j], facet);
      }
    }
    // انعكاس أبيض فوق اليسار
    canvas.drawPath(
      poly([pt(-w * .38, -h * .3), pt(-w * .08, -h * .3), pt(-w * .3, h * .05)]),
      Paint()..color = Colors.white.withValues(alpha: .4 + .3 * b),
    );
    if (b > .3) sparkle(canvas, pt(-w * .2, -h * .15), ring * .8 * b, const Color(0xFF7BFFB2), b);
  }
}

// ═════════════ دم الخونة ═════════════

/// دم الخونة: حلقة قرمزية لامعة (مبلولة) تنبض نبضة قلب (دقتين) وتطلع منها موجة، وعروقها تضوي مع كل دقة،
/// وقطرات دم بحد غامق تتجمع وتنزل من تحت.
class BloodFrame extends FrameArt {
  BloodFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _crimson = Color(0xFFB71C1C);
  static const _red = Color(0xFFFF1744);
  static const _edge = Color(0xFF2A0508);

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
      r * (1.55 + .12 * b),
      [_red.withValues(alpha: 0), _red.withValues(alpha: .2 + .4 * b), _red.withValues(alpha: 0)],
      stops: const [.6, .78, 1],
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final b = beat(t);
    final out = r + ring * 1.8;
    // موجة تطلع مع الدقة
    final p = frac(t / 1.2);
    if (p < .5) {
      final k = p / .5;
      canvas.drawCircle(
        c,
        out * (1.02 + .22 * k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring * .5 * (1 - k)
          ..color = _red.withValues(alpha: .4 * (1 - k)),
      );
    }
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1 + .035 * b);
    canvas.translate(-c.dx, -c.dy);
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(-r * .3, -out), c + Offset(r * .3, out), [Color.lerp(const Color(0xFFE0283A), const Color(0xFFFF4A5A), b)!, const Color(0xFFA5121F), const Color(0xFF5B0712)], const [0, .55, 1]),
      edge: _edge,
    );
    // العروق: داكنة وفوقها وردية تضوي مع الدقة
    for (var k = 0; k < 4; k++) {
      final path = Path();
      const steps = 40;
      final a0 = k * math.pi / 2 + .3;
      for (var j = 0; j <= steps; j++) {
        final a = a0 + j / steps * 1.3;
        final q = at(c, a, r + ring * .9 + ring * .36 * math.sin(a * 7 + k * 1.7));
        j == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, lw * 1.5)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF3A0509).withValues(alpha: .85),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.7, lw * .65)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFFF8A96).withValues(alpha: .3 + .6 * b),
      );
    }
    // لمعة مبلولة
    gloss(canvas, c, r + ring * 1.2, ring * .3, from: -2.7, span: 1.1, alpha: .6);
    gloss(canvas, c, r + ring * 1.2, ring * .16, from: -1.4, span: .2, alpha: .5);
    line(canvas, c, r + lw * .9, const Color(0xFF1A0204), width: lw * 1.2);
    canvas.restore();
    // قطرات الدم
    for (final (i, a) in (small ? const [-.8, .1, .75] : const [-1.05, -.6, -.2, .25, .65, 1.0]).indexed) {
      final ang = math.pi / 2 + a;
      final pp = frac(t / (2.3 + .8 * rnd(i, 1)) + rnd(i, 2));
      drip(canvas, at(c, ang, r + ring * 1.6), pp, ring * .9, r, _crimson, shine: const Color(0xFFFF8A96).withValues(alpha: .9), edge: _edge);
    }
  }
}

// ═════════════ الذهب الأسود ═════════════

/// الذهب الأسود: حجر أسود لامع بحد غامق وفيه شقوق وعروق ذهب ذايب تمشي وتتوهج، وحافات ذهب،
/// وقطرة ذهب تدور وتخلي وراها خط، وهالة كهرمانية تنبض.
class BlackGoldFrame extends FrameArt {
  BlackGoldFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _gold = Color(0xFFFFD54F);
  static const _amber = Color(0xFFFFB300);
  static const _brown = Color(0xFF5A3A0A);
  static const _pale = Color(0xFFFFF3C4);

  @override
  void back(Canvas canvas, Offset c, double t) {
    final pulse = .85 + .15 * math.sin(t * 1.6);
    halo(
      canvas,
      c,
      r * 1.65,
      [Colors.transparent, _amber.withValues(alpha: .3 * pulse), Colors.transparent],
      stops: const [.6, .78, 1],
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final out = r + ring * 1.7;
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(-r * .5, -r), c + Offset(r * .5, r), const [Color(0xFF7C7C90), Color(0xFF3B3B48), Color(0xFF16161B)], const [0, .5, 1]),
    );
    // لمعات الحجر الصقيل
    gloss(canvas, c, r + ring * 1.2, ring * .18, from: -2.75, span: 1.0, alpha: .45);
    gloss(canvas, c, r + ring * 1.2, ring * .12, from: -1.5, span: .3, alpha: .3);
    gloss(canvas, c, r + ring * .5, ring * .1, from: .3, span: .7, alpha: .22);
    gloss(canvas, c, r + ring * 1.3, ring * .1, from: 2.2, span: .5, alpha: .22);
    // شقوق قصيرة تنبض بالذهب
    final cracks = small ? 6 : 12;
    for (var k = 0; k < cracks; k++) {
      final a = k * 2 * math.pi / cracks + .2;
      final glow = .45 + .45 * math.sin(t * 2 + k * 1.7);
      canvas.drawPath(
        zigzag(at(c, a, r + ring * .25), at(c, a + .05, out - ring * .25), 3, ring * .25, k * 5 + 1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, lw * .85)
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = _amber.withValues(alpha: glow),
      );
    }
    // العروق: خط داكن تحت، وذهب ذايب يمشي، وقلب فاتح
    final molten = sweep(c, const [_brown, _amber, _pale, _amber, _brown, _amber, _gold], turn: t * .9);
    for (var k = 0; k < 3; k++) {
      final path = Path();
      const steps = 44;
      final a0 = k * 2.1 + .4;
      for (var j = 0; j <= steps; j++) {
        final a = a0 + j / steps * 2.0;
        final q = at(c, a, r + ring * .85 + ring * .4 * math.sin(a * 9 + k * 2.1) * (.6 + .4 * math.sin(a * 3 + k)));
        j == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring * .5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = ink.withValues(alpha: .85),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring * .3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = molten,
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring * .08
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = _pale.withValues(alpha: .5 + .4 * math.sin(t * 2 + k)),
      );
    }
    // حافات الذهب
    for (final (radius, w) in [(out - lw * .9, lw * 1.2), (r + lw * .9, lw * 1.1)]) {
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..shader = sweep(c, const [_amber, _pale, _gold, _brown], turn: -t * .4),
      );
    }
    // قطرة ذهب تدور وتخلي وراها خط
    final a = t * .8;
    final orbit = r + ring * .85;
    for (var k = 6; k >= 1; k--) {
      dot(canvas, at(c, a - k * .06, orbit), ring * .2 * (1 - k / 8), _gold, .5 * (1 - k / 7));
    }
    ball(canvas, at(c, a, orbit), ring * .32, _pale, _gold, const Color(0xFFC77700), edge: ink, w: math.max(.8, lw * .8));
  }
}

// ═════════════ النخبة (مستوى ٢٠) ═════════════

/// النخبة: لوحة كحلية بثمان رؤوس وحد ذهبي منقوط ورا الصورة، وحلقة زرقا فضية مصقولة بياقوت أزرق يتوهج بالتناوب،
/// ولمعة بيضا تمشي حولها، ولمعات نجوم صغيرة.
class EliteFrame extends FrameArt {
  EliteFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _navyEdge = Color(0xFF070A20);
  static const _goldDot = Color(0xFFF2C14E);

  /// زوايا اللوحة (مركزها نقطة الأصل): مربع مقصوص الزوايا وبأربع رؤوس بارزة.
  late final List<Offset> _plate = () {
    final h = r * 1.18, k = r * .3, tip = r * .14, n = r * .16;
    return <Offset>[
      Offset(-h + k, -h),
      Offset(-n, -h),
      Offset(0, -h - tip),
      Offset(n, -h),
      Offset(h - k, -h),
      Offset(h, -h + k),
      Offset(h, -n),
      Offset(h + tip, 0),
      Offset(h, n),
      Offset(h, h - k),
      Offset(h - k, h),
      Offset(n, h),
      Offset(0, h + tip),
      Offset(-n, h),
      Offset(-h + k, h),
      Offset(-h, h - k),
      Offset(-h, n),
      Offset(-h - tip, 0),
      Offset(-h, -n),
      Offset(-h, -h + k),
    ];
  }();

  /// حبات الحد الذهبي: نقاط موزعة على ضلع اللوحة (مصغّرة شوي للداخل).
  late final List<Offset> _beads = () {
    final pts = <Offset>[];
    final inner = [for (final p in _plate) p * .93];
    final spacing = math.max(2.6, avatar * .052);
    for (var i = 0; i < inner.length; i++) {
      final a = inner[i], b = inner[(i + 1) % inner.length];
      final len = (b - a).distance;
      final cnt = math.max(1, (len / spacing).round());
      for (var j = 0; j < cnt; j++) {
        pts.add(Offset.lerp(a, b, j / cnt)!);
      }
    }
    return pts;
  }();

  @override
  void back(Canvas canvas, Offset c, double t) {
    final pulse = .85 + .15 * math.sin(t * 1.4);
    halo(
      canvas,
      c,
      r * 1.75,
      [Colors.transparent, const Color(0xFF3E7BFF).withValues(alpha: .35 * pulse), Colors.transparent],
      stops: const [.6, .8, 1],
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    final plate = poly(_plate);
    inked(
      canvas,
      plate,
      shader: lin(Offset(-r, -r), Offset(r, r), const [Color(0xFF34479A), Color(0xFF18245F), Color(0xFF0B1038)]),
      edge: _navyEdge,
      w: lw * 1.2,
    );
    // حد ذهبي: خط رفيع على الطرف وبعده حبات منقوطة
    canvas.drawPath(
      poly([for (final q in _plate) q * .975]),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, lw * .9)
        ..strokeJoin = StrokeJoin.round
        ..color = _goldDot.withValues(alpha: .85),
    );
    final dotSize = math.max(1.4, avatar * .03);
    canvas.drawPoints(
      ui.PointMode.points,
      _beads,
      Paint()
        ..strokeWidth = dotSize + lw * .9
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3A2406),
    );
    canvas.drawPoints(
      ui.PointMode.points,
      _beads,
      Paint()
        ..strokeWidth = dotSize
        ..strokeCap = StrokeCap.round
        ..color = _goldDot,
    );
    // انعكاس خفيف على اللوحة
    canvas.drawLine(
      Offset(-r * .95, -r * 1.05),
      Offset(-r * .2, -r * 1.05),
      Paint()
        ..strokeWidth = lw * 1.6
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .16),
    );
    canvas.restore();
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final out = r + ring * 1.25;
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(-r * .4, -r), c + Offset(r * .4, r), const [Color(0xFF8DB0FF), Color(0xFF3A63DE), Color(0xFF15308C)], const [0, .5, 1]),
      edge: _navyEdge,
    );
    // حدود فضية مصقولة
    line(canvas, c, r + lw * 1.2, const Color(0xFFE3EAFF), width: math.max(.8, lw * .8));
    line(canvas, c, out - lw * 1.2, const Color(0xFFBFD0FF).withValues(alpha: .7), width: math.max(.7, lw * .6));
    gloss(canvas, c, r + ring * .62, ring * .16, from: -2.7, span: 1.1, alpha: .5);
    // ياقوت أزرق يتوهج بالتناوب
    const n = 8;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n - math.pi / 2;
      final p = at(c, a, r + ring * .62);
      final pulse = .5 + .5 * math.sin(t * 2.2 + i * .8);
      halo(canvas, p, ring * 1.5, [const Color(0xFF58C8FF).withValues(alpha: .55 * pulse), const Color(0xFF58C8FF).withValues(alpha: 0)]);
      ball(
        canvas,
        p,
        ring * (small ? .3 : .34),
        Color.lerp(const Color(0xFFB8EEFF), Colors.white, pulse * .6)!,
        const Color(0xFF2FB7FF),
        const Color(0xFF1B5FD0),
        edge: _navyEdge,
        w: math.max(.7, lw * .7),
      );
    }
    // لمعة بيضا تمشي حول الحلقة
    sheen(canvas, c, t * 1.1, .8, radius: r + ring * .75, width: ring * .5, span: 1.0);
    sheen(canvas, c, t * 1.1 + math.pi, .35, radius: r + ring * .75, width: ring * .35, span: .6);
    twinkles(canvas, c, t, n: small ? 3 : 5, rIn: 1.2, rOut: 1.55, speed: .8, color: const Color(0xFFDCE8FF), salt: 3);
  }
}

// ═════════════ الذهبي (مستوى ٣٠) ═════════════

/// الذهبي: عقد جنيهات ذهب مجسمة بحد غامق على سلسلة ذهب يدور ببطء، وكل جنيه ينقلب (يبان وجهه وظهره وحافته)
/// ويلمع لما يواجهك.
class GoldenFrame extends FrameArt {
  GoldenFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _g = Color(0xFFFFB300);
  static const _gl = Color(0xFFFFE082);
  static const _gp = Color(0xFFFFF8E1);
  static const _gd = Color(0xFFA06A00);
  static const _edge = Color(0xFF3A2406);

  @override
  void back(Canvas canvas, Offset c, double t) {
    halo(
      canvas,
      c,
      r * 1.6,
      [Colors.transparent, _g.withValues(alpha: .3 + .06 * math.sin(t * 1.5)), Colors.transparent],
      stops: const [.6, .78, 1],
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    // السلسلة اللي عليها الجنيهات
    band(canvas, c, r + ring * .3, r + ring * .95, goldShader(c, r + ring), edge: _edge, w: math.max(.8, lw * .85));
    final n = small ? 13 : 18;
    final cr = ring * (small ? 1.25 : 1.32);
    final mid = r + ring * .62;
    for (var i = 0; i < n; i++) {
      final a = t * .18 + i * 2 * math.pi / n;
      final p = at(c, a, mid);
      final flip = math.cos(t * 2.1 + i * .9);
      final sx = math.max(.16, flip.abs());
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a + math.pi / 2);
      canvas.scale(sx, 1);
      // الحافة (سماكة الجنيه)
      canvas.drawCircle(Offset(0, 0), cr, Paint()..color = _gd);
      canvas.drawCircle(
        Offset.zero,
        cr * .93,
        Paint()
          ..shader = radial(
            Offset.zero,
            cr,
            const [_gp, _gl, _g, _gd],
            stops: const [0, .35, .75, 1],
            focal: Offset(flip > 0 ? -cr * .3 : cr * .3, -cr * .35),
          ),
      );
      canvas.drawCircle(
        Offset.zero,
        cr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, lw * .85)
          ..color = _edge,
      );
      canvas.drawCircle(
        Offset.zero,
        cr * .72,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.6, hair * .9)
          ..color = _gd.withValues(alpha: .7),
      );
      if (sx > .4) {
        if (flip > 0) {
          canvas.drawPath(star5(Offset.zero, cr * .46), Paint()..color = _gd.withValues(alpha: .7));
        } else {
          // ظهر الجنيه: هلال
          canvas.drawPath(
            Path.combine(
              PathOperation.difference,
              Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: cr * .4)),
              Path()..addOval(Rect.fromCircle(center: Offset(cr * .16, 0), radius: cr * .34)),
            ),
            Paint()..color = _gd.withValues(alpha: .7),
          );
        }
      }
      final flash = flip > 0 ? math.pow(sx, 22).toDouble() : 0.0;
      if (flash > .05) {
        canvas.drawCircle(Offset.zero, cr * .8, Paint()..color = Colors.white.withValues(alpha: .3 * flash));
      }
      canvas.restore();
      if (flash > .5) sparkle(canvas, p + Offset(-cr * .3, -cr * .3), ring * .85, _gp, flash);
    }
  }
}

// ═════════════ ليالي المجلس ═════════════

/// ليالي المجلس: حلقة نيلية بحد غامق وزخرفة ذهب، وزينة لمبات ملوّنة تلمع بالدور فوق الصورة،
/// وفانوسين رمضانيين معلقين على الجنبين يتمرجحون وشمعتهم ترجف.
class LanternsFrame extends FrameArt {
  LanternsFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _gold = Color(0xFFFCD34D);
  static const _goldD = Color(0xFFB7791F);
  static const _mint = Color(0xFF5EEAD4);
  static const _flame = Color(0xFFFFB74D);
  static const _edge = Color(0xFF0A0826);
  static const _bar = Color(0xFF3A2406);

  static const _hooks = [-2.45, -.69];

  double get _hookR => r * 1.3;

  @override
  void front(Canvas canvas, Offset c, double t) {
    final out = r + ring * 1.5;
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(-r * .4, -r), c + Offset(r * .4, r), const [Color(0xFF4A47B0), Color(0xFF28247A), Color(0xFF14123F)], const [0, .5, 1]),
      edge: _edge,
    );
    gloss(canvas, c, r + ring * .85, ring * .14, from: -2.7, span: 1.0, alpha: .4);
    line(canvas, c, r + lw * 1.2, _gold, width: math.max(.8, lw * .9));
    line(canvas, c, out - lw * 1.2, _goldD, width: math.max(.8, lw * .8));
    // زخرفة: معينات ذهب ونقاط فيروزية بالتناوب
    final m = small ? 12 : 16;
    for (var k = 0; k < m; k++) {
      final a = k * 2 * math.pi / m;
      final p = at(c, a, r + ring * .75);
      if (k.isEven) {
        final along = dir(a + math.pi / 2) * ring * .34, o = dir(a) * ring * .34;
        inked(canvas, poly([p + along, p + o, p - along, p - o]), fill: _gold, edge: _edge, w: math.max(.6, lw * .55));
      } else {
        canvas.drawCircle(p, ring * .13, Paint()..color = _mint);
      }
    }
    _garland(canvas, c, t);
    for (final (i, a) in _hooks.indexed) {
      _lantern(canvas, at(c, a, _hookR), t, i);
    }
  }

  /// زينة: خيط مقوّس فوق الصورة بين الفانوسين، متدلي شوي بين كل نقطتين، وعليه لمبات ملوّنة تولّع بالدور.
  void _garland(Canvas canvas, Offset c, double t) {
    final a0 = _hooks[0], a1 = _hooks[1];
    const steps = 40;
    final path = Path();
    Offset pointAt(double s) {
      final a = a0 + (a1 - a0) * s;
      final sag = (1 - math.cos(s * 3 * 2 * math.pi)) / 2;
      return at(c, a, _hookR - r * .07 * sag);
    }

    for (var j = 0; j <= steps; j++) {
      final q = pointAt(j / steps);
      j == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, lw * 1.2)
        ..strokeCap = StrokeCap.round
        ..color = _edge,
    );
    final n = small ? 7 : 11;
    final chase = (t * 4).floor();
    const cols = [Color(0xFFFFD34D), Color(0xFF5EEAD4), Color(0xFFFF8FB1)];
    for (var i = 0; i < n; i++) {
      final s = (i + .5) / n;
      final on = (i + chase) % 3 == 0;
      final col = cols[i % 3];
      final p = pointAt(s) + Offset(0, ring * .3);
      if (on) halo(canvas, p, ring * 1.3, [col.withValues(alpha: .55), col.withValues(alpha: 0)]);
      ball(
        canvas,
        p,
        ring * .34,
        Color.lerp(Colors.white, col, on ? .2 : .6)!,
        on ? col : Color.lerp(col, Colors.black, .45)!,
        Color.lerp(col, Colors.black, on ? .35 : .7)!,
        edge: _edge,
        w: math.max(.6, lw * .6),
        shine: on ? .9 : .5,
      );
    }
  }

  /// فانوس معلق من [hook]: سلسلة، وغطا بتاج، وزجاج ملوّن مضيّ بشمعة، وقاعدة، بحد غامق.
  void _lantern(Canvas canvas, Offset hook, double t, int i) {
    final swing = .14 * math.sin(t * 1.6 + i * 1.3);
    final chain = r * .2, h = r * .66, w = r * .3;
    final top = chain;
    final flick = .7 + .3 * noise(t * 4 + i * 3, i);
    canvas.save();
    canvas.translate(hook.dx, hook.dy);
    canvas.rotate(swing);
    // توهج الشمعة
    halo(canvas, Offset(0, top + h * .5), r * .5, [_flame.withValues(alpha: .45 * flick), _flame.withValues(alpha: 0)]);
    // السلسلة
    final chainLine = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.0, lw * 1.5)
      ..color = _edge;
    canvas.drawLine(Offset.zero, Offset(0, chain), chainLine);
    canvas.drawLine(
      Offset.zero,
      Offset(0, chain),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.6, lw * .6)
        ..color = _gold,
    );
    canvas.drawCircle(Offset(0, top - h * .02), ring * .26, Paint()..color = _gold);
    // الغطا (قبة)
    final cap = Path()
      ..moveTo(-w * .78, top + h * .22)
      ..quadraticBezierTo(-w * .6, top + h * .02, 0, top - h * .04)
      ..quadraticBezierTo(w * .6, top + h * .02, w * .78, top + h * .22)
      ..close();
    inked(canvas, cap, shader: lin(Offset(0, top), Offset(0, top + h * .22), const [Color(0xFFFFE9A0), Color(0xFFE3A52D)]), edge: _edge, w: math.max(.7, lw * .8));
    // الزجاج: سداسي مضيّ
    final body = poly([
      Offset(-w * .74, top + h * .22),
      Offset(w * .74, top + h * .22),
      Offset(w, top + h * .5),
      Offset(w * .74, top + h * .8),
      Offset(-w * .74, top + h * .8),
      Offset(-w, top + h * .5),
    ]);
    inked(
      canvas,
      body,
      shader: radial(
        Offset(0, top + h * .5),
        w * 1.1,
        [Color.lerp(_flame, Colors.white, .6 * flick)!, _flame.withValues(alpha: .95), i.isEven ? const Color(0xFF0F766E) : const Color(0xFFC2410C)],
        stops: const [0, .5, 1],
      ),
      edge: _bar,
      w: math.max(.8, lw * .9),
    );
    // قضبان الإطار
    final bars = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(.8, lw * .85)
      ..color = _bar;
    canvas.drawLine(Offset(0, top + h * .22), Offset(0, top + h * .8), bars);
    if (!small) {
      canvas.drawLine(Offset(-w * .5, top + h * .22), Offset(-w * .62, top + h * .8), bars);
      canvas.drawLine(Offset(w * .5, top + h * .22), Offset(w * .62, top + h * .8), bars);
    }
    // لمعة زجاج
    canvas.drawLine(
      Offset(-w * .55, top + h * .32),
      Offset(-w * .55, top + h * .55),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(.7, lw * .7)
        ..color = Colors.white.withValues(alpha: .5),
    );
    // القاعدة
    final base = poly([
      Offset(-w * .74, top + h * .8),
      Offset(w * .74, top + h * .8),
      Offset(w * .3, top + h * .98),
      Offset(-w * .3, top + h * .98),
    ]);
    inked(canvas, base, shader: lin(Offset(0, top + h * .8), Offset(0, top + h), const [Color(0xFFFFE08A), Color(0xFFC98A1C)]), edge: _edge, w: math.max(.7, lw * .8));
    canvas.drawCircle(Offset(0, top + h * 1.02), ring * .2, Paint()..color = _gold);
    canvas.restore();
  }
}
