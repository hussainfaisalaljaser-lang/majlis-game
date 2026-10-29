import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'kit.dart';

// الإطارات الأسطورية (بأسلوب رسمات الفيديو: حد غامق، ظل بدرجتين، لمعة): حركة من أكثر من طبقة
// (ورا الصورة وقدامها)، وأفخم شي في اللعبة، ولكل واحد لحظة خاصة (burst).

Color _hue(Color c, double deg) {
  final hsv = HSVColor.fromColor(c);
  return hsv.withHue((hsv.hue + deg) % 360).toColor();
}

// ═════════════ الشمس ═════════════

/// الشمس: شمس كرتونية بأشعة مثلثات سميكة بحد غامق (طويلة وقصيرة تدور بعكس بعض وترجف من الحرارة)،
/// وحلقة ذهب ذايب تغلي بفقاعات ولمعة تدور، وكل كم ثانية تطلع منها شعلة مقوّسة.
/// اللحظة: انفجار شمسي (ومضة وموجة نار وأشعة تطول وشرار).
class SunFrame extends FrameArt {
  SunFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _edge = Color(0xFF5A2606);
  static const _gold = Color(0xFFFFB300);
  static const _orange = Color(0xFFFF7A00);
  static const _pale = Color(0xFFFFF176);
  static const _white = Color(0xFFFFFBE0);

  double get _band => ring * 1.5;

  @override
  void back(Canvas canvas, Offset c, double t) {
    final swell = hump(burst(t) ?? 0);
    halo(
      canvas,
      c,
      r * (1.95 + .06 * math.sin(t * 1.3) + .5 * swell),
      [
        _pale.withValues(alpha: .55),
        _gold.withValues(alpha: .38 + .3 * swell),
        _orange.withValues(alpha: .16),
        _orange.withValues(alpha: 0),
      ],
      stops: const [.45, .6, .8, 1],
    );
    final n = small ? 8 : 12;
    // القصيرة أول (تحت)، ثم الطويلة فوقها
    for (final (set, speed, reach, half) in const [(1, -.2, 1.4, .125), (0, .12, 1.72, .15)]) {
      final light = Path(), dark = Path(), edge = Path();
      for (var i = 0; i < n; i++) {
        final a = t * speed + (i + set * .5) * 2 * math.pi / n;
        final len = r * (reach + .13 * noise(t * 1.5, i + set * 20) + (set == 0 ? .6 : .28) * swell);
        final tip = at(c, a + .025 * math.sin(t * 6 + i), len);
        final bl = at(c, a - half, r + ring * .4);
        final br = at(c, a + half, r + ring * .4);
        final mid = at(c, a, r + ring * .4);
        light.addPolygon([bl, tip, mid], true);
        dark.addPolygon([mid, tip, br], true);
        edge.addPolygon([bl, tip, br], true);
      }
      canvas.drawPath(light, Paint()..color = set == 0 ? const Color(0xFFFFE566) : const Color(0xFFFFEE88));
      canvas.drawPath(dark, Paint()..color = set == 0 ? const Color(0xFFFFA400) : const Color(0xFFFF8C1A));
      canvas.drawPath(
        edge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw
          ..strokeJoin = StrokeJoin.round
          ..color = _edge,
      );
    }
    // الشعلة: لسان لهب يطلع من الحلقة ويميل ويختفي كل كم ثانية
    final cycle = (t / 3.6).floor();
    final q = (t % 3.6) / 1.5;
    if (q < 1) {
      final a = rnd(cycle, 3) * 2 * math.pi;
      final k = math.sin(math.min(1.0, q * 1.6) * math.pi / 2) * (1 - q * q);
      final base = at(c, a, r + _band * .7);
      final up = dir(a + .25 * q);
      final h = r * (.12 + .5 * k);
      final w = _band * 1.5;
      final path = flameTongue(base, up, h, w, w * .8 * q, kink: w * .25 * math.sin(t * 9));
      canvas.drawPath(path, Paint()..color = _orange);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw
          ..strokeJoin = StrokeJoin.round
          ..color = _edge,
      );
      canvas.drawPath(flameTongue(base, up, h * .7, w * .6, w * .6 * q), Paint()..color = _pale);
    }
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final out = r + _band;
    // الحلقة: ذهب ذايب بتدرج حار
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(0, -out), c + Offset(0, out), const [
        Color(0xFFFFF6A8),
        Color(0xFFFFC107),
        Color(0xFFFF8F00),
        Color(0xFFE65100),
      ]),
      edge: _edge,
    );
    line(canvas, c, r + lw * 1.1, const Color(0xFFB84A00).withValues(alpha: .55), width: lw * 1.4);
    // فقاعات الذهب الذايب
    for (var i = 0; i < (small ? 5 : 8); i++) {
      final a = t * .22 + i * 2 * math.pi / (small ? 5 : 8) + rnd(i, 2);
      final pulse = .55 + .45 * math.sin(t * 2.3 + i * 1.9);
      canvas.drawCircle(
        at(c, a, r + _band * (.4 + .25 * rnd(i, 4))),
        _band * .13 * (.6 + .6 * pulse) * (.7 + rnd(i, 5) * .6),
        Paint()..color = _white.withValues(alpha: .35 + .45 * pulse),
      );
    }
    gloss(canvas, c, r + _band * .72, _band * .13, from: -2.6, span: 1.0, alpha: .6);
    sheen(canvas, c, t * .9, .5, radius: r + _band * .62, width: _band * .2, span: 1.1);
    twinkles(canvas, c, t, n: small ? 2 : 4, rIn: 1.2, rOut: 1.55, color: _pale, speed: .8, salt: 5);
    final b = burst(t);
    if (b != null) {
      halo(canvas, c, r * 1.15, [
        _white.withValues(alpha: .8 * (1 - b) * (1 - b)),
        _pale.withValues(alpha: .3 * (1 - b)),
        Colors.transparent,
      ]);
      final k = Curves.easeOutCubic.transform(b);
      final rad = r * (1 + 1.1 * k) + _band;
      final w = ring * 1.3 * (1 - b);
      for (final (ww, col, a) in [(w + lw * 2, _edge, .7), (w, _orange, .9), (w * .4, _pale, .95)]) {
        canvas.drawCircle(
          c,
          rad,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = ww
            ..color = col.withValues(alpha: a * (1 - b)),
        );
      }
      burstSparks(canvas, c, b, const [_pale, _gold, _orange, _white], n: small ? 14 : 24);
    }
  }
}

// ═════════════ نقوش ═════════════

/// نقوش: زخرفة إسلامية: حلقة مينا فيروزية بإطار ذهب ونجوم ثمانية وضفيرة، ونجمتين متداخلتين بـ١٦ راس
/// ترسم نفسها بخط ذهب غامق الحد حول الصورة، وإذا كملت تتوهج وتختفي وترجع ترسم.
/// اللحظة: الزخرفة كلها تومض، ونجوم ثمانية ذهبية تطير لبرا.
class ArabesqueFrame extends FrameArt {
  ArabesqueFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _teal = Color(0xFF14A9A8);
  static const _deep = Color(0xFF0B5F78);
  static const _edge = Color(0xFF063447);
  static const _gold = Color(0xFFFFD257);
  static const _goldDark = Color(0xFFB87A12);
  static const _pale = Color(0xFFFFF1B8);

  Path _star(Offset c, double outer, double inner, double turn) {
    const n = 16;
    return poly([for (var i = 0; i < n * 2; i++) c + dir(turn + i * math.pi / n) * (i.isEven ? outer : inner)]);
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
  void back(Canvas canvas, Offset c, double t) {
    halo(
      canvas,
      c,
      r * 1.6,
      [_deep.withValues(alpha: .6), _deep.withValues(alpha: .3), _deep.withValues(alpha: 0)],
      stops: const [.66, .84, 1],
    );
    final q = frac(t / 7);
    final drawn = math.min(1.0, q / .5);
    final glow = q > .5 && q < .85 ? hump((q - .5) / .35) : 0.0;
    final alpha = q > .85 ? 1 - (q - .85) / .15 : 1.0;
    final b = burst(t);
    final flash = b == null ? 0.0 : 1 - b;
    final full = flash > 0 || drawn >= 1;
    final vis = math.max(alpha, flash);
    final stars = [
      _star(c, r * 1.44, r * 1.12, -math.pi / 2),
      _star(c, r * 1.4, r * 1.15, -math.pi / 2 + math.pi / 16),
    ];
    // المينا: تعبية فيروزية خفيفة تحت الخطوط، تطلع مع الرسم
    final enamel = full ? 1.0 : ease((drawn - .2) / .8);
    if (enamel > 0) {
      canvas.drawPath(
        stars[0],
        Paint()
          ..shader = radial(
            c,
            r * 1.46,
            [
              _teal.withValues(alpha: 0),
              _teal.withValues(alpha: .5 * enamel * vis),
              _deep.withValues(alpha: .7 * enamel * vis),
            ],
            stops: const [.7, .84, 1],
          ),
      );
    }
    for (final s in stars) {
      final part = full ? s : _partial(s, drawn);
      if (glow > 0 || flash > 0) {
        final g = math.max(glow, flash);
        canvas.drawPath(
          part,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = ring * .9
            ..strokeJoin = StrokeJoin.round
            ..color = _gold.withValues(alpha: .18 * g),
        );
        canvas.drawPath(
          part,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = ring * .5
            ..strokeJoin = StrokeJoin.round
            ..color = _gold.withValues(alpha: .3 * g),
        );
      }
      // خط ذهب بحد غامق تحته
      canvas.drawPath(
        part,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw * 3
          ..strokeJoin = StrokeJoin.round
          ..color = _edge.withValues(alpha: vis),
      );
      canvas.drawPath(
        part,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = lw * 1.4
          ..strokeJoin = StrokeJoin.round
          ..color = Color.lerp(_gold, _pale, flash)!.withValues(alpha: vis),
      );
    }
    // نجوم ثمانية في الفراغات، تطلع لما يوصلها الرسم
    if (small) return;
    for (var k = 0; k < 8; k++) {
      final show = flash > 0 ? 1.0 : ((drawn - k / 8) * 8).clamp(0.0, 1.0) * alpha;
      if (show <= 0) continue;
      final p = at(c, -math.pi / 2 + k * math.pi / 4, r * 1.29);
      inked(
        canvas,
        star8(p, ring * .62),
        fill: _gold.withValues(alpha: show),
        edge: _edge.withValues(alpha: show),
        w: lw * .9,
      );
      canvas.drawCircle(p, ring * .2, Paint()..color = _teal.withValues(alpha: show));
    }
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final out = r + ring * 1.5;
    // الحلقة: مينا فيروزية بإطار ذهب
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(-r * .5, -out), c + Offset(r * .5, out), const [Color(0xFF3FD6C8), _teal, _deep]),
      edge: _edge,
    );
    line(canvas, c, r + lw * 1.2, _gold, width: lw * 1.5);
    line(canvas, c, out - lw * 1.2, _gold, width: lw * 1.5);
    // ضفيرة ذهب بين الحافتين ونجوم ثمانية وفصوص
    final mid = r + ring * .75;
    final wave = Path();
    const m = 80;
    for (var i = 0; i <= m; i++) {
      final a = i * math.pi * 2 / m;
      final p = at(c, a, mid + math.sin(a * 16) * ring * .22);
      i == 0 ? wave.moveTo(p.dx, p.dy) : wave.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, lw * .8)
        ..strokeJoin = StrokeJoin.round
        ..color = _gold.withValues(alpha: .9),
    );
    for (var k = 0; k < 16; k++) {
      final p = at(c, -math.pi / 2 + (k + .5) * math.pi / 8, mid);
      if (k.isEven) {
        inked(
          canvas,
          star8(p, ring * .5, turn: math.pi / 8),
          shader: lin(p - Offset(0, ring * .5), p + Offset(0, ring * .5), const [_pale, _gold, _goldDark]),
          edge: _edge,
          w: math.max(.7, lw * .75),
        );
      } else {
        final ang = -math.pi / 2 + (k + .5) * math.pi / 8 + math.pi / 2;
        canvas.drawPath(
          poly([
            for (final q in [Offset(0, -ring * .3), Offset(ring * .2, 0), Offset(0, ring * .3), Offset(-ring * .2, 0)])
              p + rot(q, ang),
          ]),
          Paint()..color = _pale.withValues(alpha: .85),
        );
      }
    }
    gloss(canvas, c, r + ring * 1.1, ring * .16, from: -2.6, span: 1.0, alpha: .5);
    sheen(canvas, c, t * .4, .3, radius: mid, width: ring * .4, span: .6);
    final b = burst(t);
    if (b != null) {
      final k = Curves.easeOutCubic.transform(b);
      for (var i = 0; i < 8; i++) {
        final p = at(c, -math.pi / 2 + i * math.pi / 4 + math.pi / 8, r * (1.3 + .6 * k));
        inked(
          canvas,
          star8(p, ring * .75 * (1 - b * .4), turn: b * 2),
          fill: _pale.withValues(alpha: 1 - b),
          edge: _edge.withValues(alpha: 1 - b),
          w: lw,
        );
      }
      burstSparks(canvas, c, b, const [_gold, _pale, Color(0xFF5CE6D8)], n: small ? 10 : 18, from: 1.1);
    }
  }
}

// ═════════════ الطاووس ═════════════

/// الطاووس: ذيل طاووس منفرد ورا الصورة (صفين ريش بحد غامق وعيون تتلون مثل الحرير)، يتمايل بموجة هادية،
/// وحلقة ذهب عليها أحجار ياقوت أزرق. اللحظة: الذيل ينفرد أكثر وتمر لمعة على العيون وتطير منه لمعات.
class PeacockFrame extends FrameArt {
  PeacockFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _edge = Color(0xFF0A3A32);
  static const _green = Color(0xFF1E9E4A);
  static const _blue = Color(0xFF1D4ED8);
  static const _navy = Color(0xFF0B1A5C);
  static const _gold = Color(0xFFFFC94D);
  static const _sapphire = Color(0xFF2747D6);

  int get _n => small ? 9 : 13;

  /// زاوية الريشة رقم [i] من [n] وطولها.
  (double, double) _feather(num i, int n, double t, double open, double lenK, double phase) {
    final s = i / (n - 1);
    var a = -math.pi - .28 + s * (math.pi + .56);
    a = -math.pi / 2 + (a + math.pi / 2) * (1 + .12 * open);
    a += .05 * math.sin(t * 1.3 + i * .55 + phase);
    final len = r * ((small ? 1.55 : 1.72) * lenK + .08 * math.sin(t * .9 + i + phase) + .25 * open);
    return (a, len);
  }

  /// ورقة الريشة: من [base] باتجاه [d] بطول [len] وعرض [w]؛ [half] = -١/١ لنص واحد، و٠ للكل.
  Path _vane(Offset base, Offset d, double len, double w, int half) {
    final side = perp(d);
    final tip = base + d * len;
    final c1 = base + d * len * .3 + side * w * 1.05, c2 = base + d * len * .8 + side * w * .8;
    final c3 = base + d * len * .8 - side * w * .8, c4 = base + d * len * .3 - side * w * 1.05;
    final p = Path()..moveTo(base.dx, base.dy);
    if (half >= 0) p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, tip.dx, tip.dy);
    if (half == 0) {
      p.cubicTo(c3.dx, c3.dy, c4.dx, c4.dy, base.dx, base.dy);
    } else if (half > 0) {
      p.lineTo(base.dx, base.dy);
    } else {
      p.lineTo(tip.dx, tip.dy);
      p.cubicTo(c3.dx, c3.dy, c4.dx, c4.dy, base.dx, base.dy);
    }
    return p..close();
  }

  @override
  void back(Canvas canvas, Offset c, double t) {
    final b = burst(t);
    final open = hump(b ?? 0);
    final n = _n;
    // الصف الخلفي: ريش أقصر وأغمق بين الريش الأمامي
    final backEdge = Path(), backFill = Path();
    for (var i = 0; i < n - 1; i++) {
      final (a, len) = _feather(i + .5, n, t, open, .8, 1.3);
      final d = dir(a);
      final base = c + d * r * .85;
      final v = _vane(base, d, len - r * .85, r * .2, 0);
      backFill.addPath(v, Offset.zero);
      backEdge.addPath(v, Offset.zero);
    }
    canvas.drawPath(backFill, Paint()..color = const Color(0xFF0E7C68));
    canvas.drawPath(
      backEdge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw
        ..strokeJoin = StrokeJoin.round
        ..color = _edge,
    );
    // الصف الأمامي: نص فاتح ونص غامق، وعرق ذهب، وعين
    final light = Path(), dark = Path(), edge = Path(), shaft = Path(), barbs = Path();
    final feathers = <(double, double, Offset, Offset)>[];
    for (var i = 0; i < n; i++) {
      final (a, len) = _feather(i, n, t, open, 1, 0);
      final d = dir(a);
      final base = c + d * r * .85;
      final l = len - r * .85;
      light.addPath(_vane(base, d, l, r * .3, 1), Offset.zero);
      dark.addPath(_vane(base, d, l, r * .3, -1), Offset.zero);
      edge.addPath(_vane(base, d, l, r * .3, 0), Offset.zero);
      // زغب الريشة: خطوط قصيرة مايلة للطرف على الجنبين
      final side = perp(d);
      for (var k = 1; k < 8; k++) {
        final sk = k / 8;
        final q = base + d * l * sk;
        final wk = r * .3 * .78 * math.sin(math.pi * math.pow(sk, .8).toDouble());
        for (final sg in const [-1.0, 1.0]) {
          final e = q + side * wk * sg + d * l * .07;
          barbs
            ..moveTo(q.dx, q.dy)
            ..lineTo(e.dx, e.dy);
        }
      }
      shaft
        ..moveTo(base.dx, base.dy)
        ..lineTo((base + d * l).dx, (base + d * l).dy);
      feathers.add((a, len, d, base));
    }
    canvas.drawPath(light, Paint()..color = const Color(0xFF36E3B9));
    canvas.drawPath(dark, Paint()..color = const Color(0xFF14907C));
    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw
        ..strokeJoin = StrokeJoin.round
        ..color = _edge,
    );
    canvas.drawPath(
      barbs,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, hair)
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF0B5C50).withValues(alpha: .6),
    );
    canvas.drawPath(
      shaft,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.7, lw * .8)
        ..strokeCap = StrokeCap.round
        ..color = _gold.withValues(alpha: .8),
    );
    // العيون: حلقات تتلون
    for (final (i, (a, len, d, _)) in feathers.indexed) {
      final eye = c + d * (len - r * .2);
      final shift = 18 * math.sin(t * 1.5 - i * .5) + 40 * open * math.sin(b == null ? 0 : b * math.pi * 3 - i * .4);
      final ew = r * .13, eh = r * .18;
      canvas.save();
      canvas.translate(eye.dx, eye.dy);
      canvas.rotate(a + math.pi / 2);
      for (final (k, col) in [
        (1.0, _hue(_gold, shift * .3)),
        (.78, _hue(_green, shift)),
        (.56, _hue(_blue, shift * .6)),
        (.3, _navy),
      ]) {
        final rect = Rect.fromCenter(center: Offset.zero, width: ew * k * 2, height: eh * k * 2);
        canvas.drawOval(rect, Paint()..color = col);
        if (k == 1.0) {
          canvas.drawOval(
            rect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(.7, lw * .8)
              ..color = _edge,
          );
        }
      }
      final shimmer = math.pow((math.sin(t * 2 - i * .4) + 1) / 2, 4).toDouble();
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-ew * .22, -eh * .3), width: ew * .5, height: eh * .35),
        Paint()..color = Colors.white.withValues(alpha: .4 + .5 * shimmer),
      );
      canvas.restore();
    }
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final out = r + ring * 1.3;
    band(canvas, c, r, out, goldShader(c, out));
    line(canvas, c, r + lw * 1.1, const Color(0xFF8A4E10).withValues(alpha: .55), width: lw * 1.3);
    gloss(canvas, c, r + ring * .8, ring * .22, from: -2.7, span: 1.2, alpha: .7);
    studs(canvas, c, r + ring * .65, 6, ring * .36, const Color(0xFFBFD3FF), _sapphire, _navy, turn: math.pi / 6);
    twinkles(canvas, c, t, n: small ? 2 : 3, rIn: 1.15, rOut: 1.5, color: _gold, speed: .7, salt: 9);
    final b = burst(t);
    if (b != null) {
      for (var i = 0; i < _n; i += 2) {
        final (a, len) = _feather(i, _n, t, hump(b), 1, 0);
        sparkle(canvas, at(c, a, len * (1 + .25 * b)), ring * .6, _gold, 1 - b);
      }
    }
  }
}

// ═════════════ مجرة ═════════════

/// مجرة: سديم ملوّن وأذرع مجرة حلزونية من نجوم تدور ورا الصورة، وحلقة نيلي بدوامة ألوان، وكوكبين كرتونيين
/// يلفون حولها (يمرون قدامها وورها)، ونجوم تلمع. اللحظة: انفجار نجمي (ومضة وموجة تنتشر وشرار يطير).
class GalaxyFrame extends FrameArt {
  GalaxyFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _edge = Color(0xFF0B0420);
  static const _violet = Color(0xFF7C4DFF);
  static const _pink = Color(0xFFFF4081);
  static const _cyan = Color(0xFF18FFFF);
  static const _ice = Color(0xFFE0F7FF);

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
    final out = r + ring * 1.4;
    // توهج بنفسجي خفيف حول الحلقة (طبقتين بدون بلور)
    for (final (w, a) in [(ring * 3.4, .1), (ring * 2.4, .16)]) {
      canvas.drawCircle(
        c,
        r + ring * .7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = _violet.withValues(alpha: a + swell * .25),
      );
    }
    // الحلقة: نيلي غامق بدوامة ألوان تدور
    band(
      canvas,
      c,
      r,
      out,
      sweep(c, const [
        Color(0xFF1A0B3D),
        Color(0xFF5B34C8),
        Color(0xFFD2459A),
        Color(0xFF1A0B3D),
        Color(0xFF1FA6C9),
        Color(0xFF5B34C8),
      ], turn: t * .6),
      edge: _edge,
    );
    line(canvas, c, r + lw * 1.2, _ice.withValues(alpha: .7), width: math.max(.7, lw * .75));
    line(canvas, c, out - lw * 1.2, const Color(0xFFB9A6FF).withValues(alpha: .6), width: math.max(.7, lw * .6));
    gloss(canvas, c, r + ring * .95, ring * .16, from: -2.6, span: 1.0, alpha: .4);
    final p = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < (small ? 7 : 11); i++) {
      final tw = math.pow((math.sin(t * 4 + i * 2.7) + 1) / 2, 3).toDouble();
      p.color = Colors.white.withValues(alpha: .3 + .7 * tw);
      canvas.drawCircle(
        at(c, i * math.pi * 2 / (small ? 7 : 11) + t * .6, r + ring * .72),
        math.max(.6, ring * (.14 + tw * .2)),
        p,
      );
    }
    _planets(canvas, c, t, front: true);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi * 2 / 6 + .4 + rnd(i, 21) * .5;
      final tw = math.pow((math.sin(t * 2.1 + i * 1.9) + 1) / 2, 2).toDouble();
      sparkle(canvas, at(c, a, r * (1.3 + rnd(i, 22) * .3)), avatar * (.03 + tw * .045), _ice, .35 + .65 * tw);
    }
    if (b != null) _supernova(canvas, c, b);
  }

  void _arms(Canvas canvas, Offset c, double t, double swell) {
    const arms = 3, steps = 22;
    final stars = small ? 6 : 11;
    final p = Paint()..blendMode = BlendMode.plus;
    for (var k = 0; k < arms; k++) {
      Offset pt(double f) => at(c, k * math.pi * 2 / arms + f * 2.5 + t * .22, r * (.97 + f * (.62 + swell * .32)));
      // شريط الذراع: عريض عند البداية ويدق للآخر
      final left = <Offset>[], right = <Offset>[];
      for (var j = 0; j <= steps; j++) {
        final f = j / steps;
        final q = pt(f), q2 = pt(math.min(1, f + .01));
        final n = perp(unit(q2 - q + const Offset(.0001, 0)));
        final w = r * (.16 + swell * .06) * math.pow(1 - f, .8).toDouble();
        left.add(q + n * w);
        right.add(q - n * w);
      }
      final ribbon = Path()..moveTo(left.first.dx, left.first.dy);
      for (final q in left.skip(1)) {
        ribbon.lineTo(q.dx, q.dy);
      }
      for (final q in right.reversed) {
        ribbon.lineTo(q.dx, q.dy);
      }
      ribbon.close();
      final from = pt(0), to = pt(1);
      canvas.drawPath(
        ribbon,
        Paint()
          ..shader = lin(from, to, [
            _violet.withValues(alpha: .5 + swell * .3),
            _pink.withValues(alpha: .28),
            _pink.withValues(alpha: 0),
          ])
          ..blendMode = BlendMode.plus,
      );
      // خط القلب: فاتح
      final core = Path();
      for (var j = 0; j <= steps; j++) {
        final q = pt(j / steps);
        j == 0 ? core.moveTo(q.dx, q.dy) : core.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(
        core,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, r * .045)
          ..strokeCap = StrokeCap.round
          ..shader = lin(
            from,
            to,
            [
              _ice.withValues(alpha: .95),
              _cyan.withValues(alpha: .7),
              _violet.withValues(alpha: .45),
              _pink.withValues(alpha: 0),
            ],
            const [0, .25, .6, 1],
          )
          ..blendMode = BlendMode.plus,
      );
      for (var j = 0; j < stars; j++) {
        final f = (j + rnd(j, k + 3) * .6) / stars;
        final tw = math.pow((math.sin(t * 3.2 + j * 2.3 + k * 1.1) + 1) / 2, 2).toDouble();
        p.color = Colors.white.withValues(alpha: (.35 + .65 * tw) * (1 - f * .5));
        canvas.drawCircle(
          pt(f) + dir(rnd(j, k + 7) * math.pi * 2) * r * .05,
          math.max(.7, avatar * .012) * (1.3 - f * .6) * (.7 + tw * .6),
          p,
        );
      }
    }
    for (var i = 0; i < (small ? 12 : 22); i++) {
      final tw = (math.sin(t * 2.4 + i * 1.3) + 1) / 2;
      p.color = _ice.withValues(alpha: .2 + .5 * tw);
      canvas.drawCircle(
        at(c, rnd(i, 11) * math.pi * 2 + t * (.1 + rnd(i, 12) * .08), r * (1.04 + rnd(i, 13) * .55)),
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
    final (p1, d1, f1) = _orbit(c, t * .5, 1.38, .66, -.28);
    if (f1 == front) _giant(canvas, p1, avatar * .075 * (1 + .18 * d1));
    final (p2, d2, f2) = _orbit(c, -t * .85 + 2.2, 1.26, .6, .32);
    if (f2 == front) {
      final s = avatar * .04 * (1 + .2 * d2);
      canvas.drawCircle(p2, s * 2.4, Paint()..color = _cyan.withValues(alpha: .16));
      ball(canvas, p2, s, Colors.white, _cyan, const Color(0xFF006064), edge: _edge, w: math.max(.7, lw * .8));
    }
  }

  /// كوكب كرتوني وردي بحلقة كريمية مايلة (بحد غامق).
  void _giant(Canvas canvas, Offset p, double s) {
    final ringRect = Rect.fromCenter(center: p, width: s * 4.2, height: s * 1.25);
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(-.35);
    canvas.translate(-p.dx, -p.dy);
    void arc(double from) {
      final w = math.max(.9, s * .3);
      canvas.drawArc(
        ringRect,
        from,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w + lw * 1.6
          ..color = _edge,
      );
      canvas.drawArc(
        ringRect,
        from,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = const Color(0xFFFFE0B2),
      );
    }

    arc(math.pi);
    ball(canvas, p, s, const Color(0xFFFFE0F0), _pink, const Color(0xFF6A1B9A), edge: _edge, w: math.max(.8, lw));
    canvas.drawArc(
      Rect.fromCircle(center: p, radius: s * .7),
      .4,
      2.2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, s * .16)
        ..color = Colors.white.withValues(alpha: .22),
    );
    arc(0);
    canvas.restore();
  }

  void _supernova(Canvas canvas, Offset c, double m) {
    final fade = 1 - m;
    halo(canvas, c, r * 1.1, [
      Colors.white.withValues(alpha: .85 * fade * fade),
      _cyan.withValues(alpha: .35 * fade),
      Colors.transparent,
    ]);
    for (final (delay, col) in [(0.0, _cyan), (.14, _pink)]) {
      final k = ((m - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final rad = r * (1 + Curves.easeOutCubic.transform(k) * 1.05) + ring * 1.4;
      final width = math.max(.8, ring * .55 * (1 - k));
      for (final (w, a, cc) in [
        (width * 3.2, .22 * (1 - k), col),
        (width * 1.6, .45 * (1 - k), col),
        (width, .9 * (1 - k), Color.lerp(_ice, col, k)!),
      ]) {
        canvas.drawCircle(
          c,
          rad,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w
            ..color = cc.withValues(alpha: a)
            ..blendMode = BlendMode.plus,
        );
      }
    }
    burstSparks(canvas, c, m, const [_cyan, _pink, _violet, Colors.white], n: small ? 14 : 26, from: 1.1);
  }
}

// ═════════════ الياقوت (مستوى ٤٠) ═════════════

/// الياقوت: بلورات ياقوت أحمر مفصّصة بحد غامق تطلع من حلقة ذهب في مجموعات (كل بلورة في طوق ذهب)،
/// وداخلها نار ترجف، وأطرافها تلمع. اللحظة: البلورات تكبر وتشتعل، وشظايا تطير لبرا.
class RubyFrame extends FrameArt {
  RubyFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _edge = Color(0xFF3A0612);
  static const _ruby = Color(0xFFE11D48);
  static const _deep = Color(0xFF9F1239);
  static const _hot = Color(0xFFFF5675);
  static const _pink = Color(0xFFFDA4AF);
  static const _fire = Color(0xFFFFB347);

  @override
  void back(Canvas canvas, Offset c, double t) {
    final swell = hump(burst(t) ?? 0);
    halo(
      canvas,
      c,
      r * 1.7,
      [
        _ruby.withValues(alpha: 0),
        _ruby.withValues(alpha: .3 + .1 * math.sin(t * 2) + .4 * swell),
        _ruby.withValues(alpha: 0),
      ],
      stops: const [.58, .76, 1],
    );
    // بلورات خلفية صغيرة بين المجموعات (عمق)
    final left = Path(), right = Path(), edge = Path();
    final n = small ? 4 : 6;
    for (var g = 0; g < n; g++) {
      final a = g * 2 * math.pi / n + math.pi / n + .52;
      final base = at(c, a, r + ring * .7);
      final d = dir(a);
      final s = perp(d) * ring * .55;
      final len = r * (.34 + .05 * math.sin(t * 1.3 + g)) * (1 + .25 * swell);
      final shoulder = base + d * len * .7;
      final tip = base + d * len;
      left.addPolygon([base - s, shoulder - s, tip, base], true);
      right.addPolygon([base, tip, shoulder + s, base + s], true);
      edge.addPolygon([base - s, shoulder - s, tip, shoulder + s, base + s], true);
    }
    canvas.drawPath(left, Paint()..color = const Color(0xFF6E0E2A));
    canvas.drawPath(right, Paint()..color = _deep);
    canvas.drawPath(
      edge,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw
        ..strokeJoin = StrokeJoin.round
        ..color = _edge,
    );
  }

  @override
  void front(Canvas canvas, Offset c, double t) {
    final b = burst(t);
    final swell = hump(b ?? 0);
    final out = r + ring * 1.15;
    // الحلقة: ذهب بأحجار ياقوت صغيرة
    band(canvas, c, r, out, goldShader(c, out), edge: _edge);
    line(canvas, c, r + lw * 1.1, const Color(0xFF8A4E10).withValues(alpha: .55), width: lw * 1.3);
    gloss(canvas, c, r + ring * .85, ring * .2, from: -2.7, span: 1.1, alpha: .65);
    studs(canvas, c, r + ring * .58, small ? 10 : 18, ring * .2, _pink, _ruby, _deep, turn: .1, edge: _edge);
    // مجموعات البلور
    final groups = small ? 4 : 6;
    final lefts = Path(), rights = Path(), caps = Path(), edges = Path(), collars = Path(), cuts = Path();
    final fires = <(Path, double)>[];
    final glints = <Offset>[];
    for (var g = 0; g < groups; g++) {
      final a = g * 2 * math.pi / groups + .52;
      for (final (k, (off, len, w, tilt)) in const [
        (-.19, .38, 1.15, -.12),
        (0.0, .58, 1.45, 0.0),
        (.2, .42, 1.1, .12),
      ].indexed) {
        if (small && k == 0) continue;
        final i = g * 3 + k;
        final base = at(c, a + off, r + ring * .8);
        final d = dir(a + off + tilt);
        final s = perp(d) * ring * w * .5;
        final l = r * len * (1 + .25 * swell);
        final shoulder = base + d * l * .72;
        final tip = base + d * l;
        lefts.addPolygon([base - s, shoulder - s * 1.08, tip, base], true);
        rights.addPolygon([base, tip, shoulder + s * 1.08, base + s], true);
        caps.addPolygon([shoulder - s * 1.08, tip, shoulder + s * 1.08], true);
        edges.addPolygon([base - s, shoulder - s * 1.08, tip, shoulder + s * 1.08, base + s], true);
        cuts
          ..moveTo(shoulder.dx - s.dx * 1.08, shoulder.dy - s.dy * 1.08)
          ..lineTo(shoulder.dx + s.dx * 1.08, shoulder.dy + s.dy * 1.08)
          ..moveTo(base.dx, base.dy)
          ..lineTo(tip.dx, tip.dy);
        // الطوق الذهبي عند القاعدة
        final cb = d * ring * .55;
        collars.addPolygon([base - s * 1.3, base + s * 1.3, base + s * 1.12 + cb, base - s * 1.12 + cb], true);
        // النار جوا: شكل أصغر بنفس البلورة
        final core = base + d * l * .45;
        final inner = Path()
          ..addPolygon([
            for (final q in [base - s, shoulder - s * 1.08, tip, shoulder + s * 1.08, base + s]) core + (q - core) * .5,
          ], true);
        final fl = (.55 + .4 * noise(t * 3 + i, i) + .4 * swell).clamp(0.0, 1.0);
        fires.add((inner, fl));
        glints.add(tip);
        // لمعة طولية على الوجه اليسار
        cuts
          ..moveTo((base - s * .55 + d * l * .12).dx, (base - s * .55 + d * l * .12).dy)
          ..lineTo((base - s * .55 + d * l * .55).dx, (base - s * .55 + d * l * .55).dy);
      }
    }
    canvas.drawPath(lefts, Paint()..color = _deep);
    canvas.drawPath(rights, Paint()..color = _ruby);
    canvas.drawPath(caps, Paint()..color = _hot);
    for (final (path, fl) in fires) {
      canvas.drawPath(path, Paint()..color = Color.lerp(_ruby, _fire, fl)!.withValues(alpha: .35 + .5 * fl));
    }
    canvas.drawPath(
      cuts,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, lw * .6)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .5),
    );
    canvas.drawPath(
      edges,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw
        ..strokeJoin = StrokeJoin.round
        ..color = _edge,
    );
    inked(canvas, collars, shader: goldShader(c, r * 1.2), edge: _edge, w: math.max(.8, lw * .9));
    for (final (i, tip) in glints.indexed) {
      sparkle(canvas, tip, ring * .45, _pink, math.pow(math.max(0, math.sin(t * 1.7 + i * 2.3)), 16).toDouble());
    }
    if (b != null) {
      final e = Curves.easeOutCubic.transform(b);
      // موجة ياقوتية
      final rad = r * (1 + .9 * e) + ring * 1.2;
      final w = ring * 1.1 * (1 - b);
      for (final (ww, col, a) in [(w + lw * 2, _edge, .6), (w, _hot, .85), (w * .35, _pink, .95)]) {
        canvas.drawCircle(
          c,
          rad,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = ww
            ..color = col.withValues(alpha: a * (1 - b)),
        );
      }
      final shards = small ? 10 : 16;
      for (var i = 0; i < shards; i++) {
        final ang = i * 2 * math.pi / shards + rnd(i, 5);
        final pos = at(c, ang, r * (1.2 + .8 * e));
        final s = ring * .55 * (1 - b * .5);
        final d = dir(ang + b * 6);
        final shard = poly([pos + d * s, pos + perp(d) * s * .5, pos - d * s * .6]);
        inked(
          canvas,
          shard,
          fill: _hot.withValues(alpha: 1 - b),
          edge: _edge.withValues(alpha: 1 - b),
          w: math.max(.7, lw * .8),
        );
      }
      burstSparks(canvas, c, b, const [_pink, _fire, Colors.white], n: small ? 8 : 14, from: 1.1);
    }
  }
}
