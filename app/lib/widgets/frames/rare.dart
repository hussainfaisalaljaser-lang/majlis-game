import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'kit.dart';

// الإطارات النادرة (بأسلوب رسمات الفيديو: حد غامق، ظل بدرجتين، لمعة): رسمة ثابتة، وكل كم ثانية
// نبضة قصيرة (Beat) تتحرك فيها: لمعة تمر، ونجوم تلمع، وحركة خاصة بكل إطار.

// ═════════════ لؤلؤ ═════════════

/// لؤلؤ: حلقة برونز بخرز صغير، وفوقها عقد حبات لؤلؤ بيضاء مجسمة. النبضة: لمعة تمشي من حبة لحبة.
class PearlFrame extends RareFrame {
  PearlFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _edge = Color(0xFF3B2414);
  static const _pearlEdge = Color(0xFF5A4646);

  @override
  bool get sheens => false;

  @override
  (double, double) get twinkleRange => (1.3, 1.75);

  @override
  void art(Canvas canvas, Offset c, Beat b) {
    const n = 24;
    final cr = r + ring * 1.5;
    final pr = ring * 1.05;
    band(
      canvas,
      c,
      r,
      r + ring * 1.75,
      lin(c + Offset(-r * .5, -r), c + Offset(r * .5, r), const [Color(0xFFC59C70), Color(0xFF86593A), Color(0xFF4F3120)]),
      edge: _edge,
      w: lw * 1.2,
    );
    gloss(canvas, c, r + ring * .55, ring * .22, from: -2.6, span: 1.0, alpha: .5);
    // خرز صغير بين الحبات
    for (var i = 0; i < n; i++) {
      final p = at(c, (i + .5) * math.pi * 2 / n - math.pi / 2, r + ring * .55);
      canvas.drawCircle(p, ring * .2, Paint()..color = const Color(0xFFE9C99B));
    }
    final lit = b.active ? ease(b.win(0, .9)) * n : -9.0;
    for (var i = 0; i < n; i++) {
      final a = i * math.pi * 2 / n - math.pi / 2;
      final p = at(c, a, cr);
      var d = (i - lit).abs();
      if (d > n / 2) d = n - d;
      final boost = b.active ? math.exp(-d * d / 3) * hump(b.win(0, 1)) : 0.0;
      final rad = pr * (1 + .1 * boost);
      ball(
        canvas,
        p,
        rad,
        Color.lerp(Colors.white, const Color(0xFFFFF6D8), boost)!,
        Color.lerp(const Color(0xFFF0EAEE), Colors.white, boost * .8)!,
        const Color(0xFFB4A6BC),
        edge: _pearlEdge,
        w: lw * 1.05,
      );
      // لمعة خفيفة مزرقة تحت يمين (لون اللؤلؤ المتقزح)
      canvas.drawCircle(p + Offset(rad * .38, rad * .4), rad * .22, Paint()..color = const Color(0xFFBFE3FF).withValues(alpha: .5));
      if (boost > .05) {
        canvas.drawCircle(
          p,
          rad * 1.5,
          Paint()
            ..color = Colors.white.withValues(alpha: .35 * boost)
            ..blendMode = BlendMode.plus,
        );
      }
    }
  }
}

// ═════════════ واحة ═════════════

/// واحة: حلقة ذهب لامعة، ونخلتين على الجنبين بجذع محزّز وسعف أخضر، وكثبان صغيرة تحتهم.
/// النبضة: السعف يتمايل ولمعة تمر على الحلقة.
class OasisFrame extends RareFrame {
  OasisFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _leafEdge = Color(0xFF16360F);

  /// النخلة: قاعدتها، وراسها، ونقطة انحناء الجذع (بالنسبة لنصف قطر الصورة).
  List<(Offset, Offset, Offset)> _palms(Offset c) => [
    (c + Offset(-r * .93, r * 1.0), c + Offset(-r * 1.17, -r * .42), c + Offset(-r * 1.3, r * .4)),
    (c + Offset(r * .9, r * 1.0), c + Offset(r * 1.14, -r * .5), c + Offset(r * 1.28, r * .35)),
  ];

  @override
  void artBack(Canvas canvas, Offset c, Beat b) {
    for (final (i, (base, top, ctrl)) in _palms(c).indexed) {
      _dune(canvas, base);
      _trunk(canvas, base, top, ctrl, i);
    }
  }

  @override
  void art(Canvas canvas, Offset c, Beat b) {
    final palms = _palms(c);
    // الحلقة
    final out = r + ring * 1.35;
    band(canvas, c, r, out, goldShader(c, out));
    canvas.drawCircle(c, r + lw * .9, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lw * 1.3
      ..color = const Color(0xFF8A4E10).withValues(alpha: .55));
    gloss(canvas, c, r + ring * .85, ring * .28, from: -2.75, span: 1.25, alpha: .75);
    gloss(canvas, c, r + ring * .85, ring * .22, from: .55, span: .5, alpha: .4);
    for (final (i, (_, top, _)) in palms.indexed) {
      _crown(canvas, top, i, b);
    }
  }

  void _dune(Canvas canvas, Offset base) {
    final w = ring * 2.4;
    final p = Path()
      ..moveTo(base.dx - w, base.dy + ring * .9)
      ..quadraticBezierTo(base.dx - w * .35, base.dy + ring * .5, base.dx - w * .05, base.dy - ring * .35)
      ..quadraticBezierTo(base.dx + w * .4, base.dy + ring * .3, base.dx + w * 1.1, base.dy + ring * .9)
      ..close();
    inked(
      canvas,
      p,
      shader: lin(base + Offset(0, -ring * .4), base + Offset(0, ring), const [Color(0xFFFBE3A0), Color(0xFFE2B15C)]),
    );
  }

  void _trunk(Canvas canvas, Offset base, Offset top, Offset ctrl, int side) {
    const m = 12;
    final left = <Offset>[], right = <Offset>[];
    for (var i = 0; i <= m; i++) {
      final s = i / m;
      final q = 1 - s;
      final p = base * (q * q) + ctrl * (2 * q * s) + top * (s * s);
      final tan = unit((ctrl - base) * (2 * q) + (top - ctrl) * (2 * s));
      final n = perp(tan);
      final w = ring * lerpD(1.15, .75, s);
      left.add(p + n * w);
      right.add(p - n * w);
    }
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (final p in left.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in right.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    inked(canvas, path, shader: lin(base + Offset(-ring, 0), base + Offset(ring, 0), const [Color(0xFFD59A58), Color(0xFF8E5528)]));
    // حزوز الجذع
    final mark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.8, hair * 1.3)
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5B3515).withValues(alpha: .9);
    for (var k = 1; k < 11; k++) {
      final i = (k * m / 11).floor().clamp(1, m - 1);
      final a = left[i], z = right[i];
      final mid = (a + z) / 2 + Offset(0, ring * .22);
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, z.dx, z.dy),
        mark,
      );
    }
  }

  void _crown(Canvas canvas, Offset top, int side, Beat b) {
        // العذوق (التمر) تحت الراس
    for (var k = 0; k < 3; k++) {
      canvas.drawCircle(
        top + Offset((k - 1) * ring * .5, ring * (.55 + .25 * (k % 2))),
        ring * .4,
        Paint()..color = const Color(0xFF8B4A1F),
      );
    }
    // السعف: كل واحدة (زاوية، طول، انحناء لتحت)، والواقفة أول (أغمق)
    const fronds = [(-1.55, .62, .1), (-2.1, .9, .55), (-1.0, .9, .55), (-2.75, 1.0, .95), (-.35, 1.0, .95), (-3.3, .8, 1.3), (.15, .8, 1.3)];
    for (final (k, (ang, ln, dp)) in fronds.indexed) {
      final sway = .06 * math.sin(math.pi * 2 * b.p + k * .8 + side * 1.7);
      final a = ang + sway;
      final len = r * ln * .8;
      final wid = ring * .8;
      final path = frond(top, a, len, wid, droop: dp, teeth: 6, notch: .62);
      inked(
        canvas,
        path,
        shader: lin(top, top + dir(a) * len, const [Color(0xFF2F8A2A), Color(0xFF5DBB38), Color(0xFF9BE05A)]),
        edge: _leafEdge,
      );
      canvas.drawPath(
        frond(top, a, len * .92, wid * .2, droop: dp, teeth: 1),
        Paint()..color = const Color(0xFFD5F59A).withValues(alpha: .55),
      );
    }
  }
}

// ═════════════ جليد ═════════════

/// جليد: حلقة جليد شفافة بحافة مسننة وأصابع جليد معلقة، ورقائق ثلج مفصّلة تدور حولها.
/// النبضة: الرقائق تدور خطوة وتلمع، ولمعات على البلور.
class IceFrame extends RareFrame {
  IceFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _edge = Color(0xFF1B4F86);
  static const _deep = Color(0xFF3E9AD6);
  static const _mid = Color(0xFF8CD3F5);
  static const _pale = Color(0xFFE6F8FF);

  /// أحجام الرقائق (طول الذراع بالنسبة لـr) وزواياها الأولى.
  static const _flakes = [
    (-1.75, .3, 0.0),
    (-.62, .2, .5),
    (.12, .3, 1.0),
    (2.72, .24, .2),
    (2.25, .2, .8),
    (1.55, .23, .4),
  ];

  @override
  void artBack(Canvas canvas, Offset c, Beat b) {
    halo(canvas, c, r * 1.6, [_mid.withValues(alpha: .35), _mid.withValues(alpha: .12), Colors.transparent], stops: const [.55, .8, 1]);
  }

  @override
  void art(Canvas canvas, Offset c, Beat b) {
    final out = r + ring * 1.7;
    // الحلقة: حافة برانية مسننة شوي مثل شظايا الجليد
    final n = small ? 18 : 26;
    final outer = Path();
    for (var i = 0; i < n * 2; i++) {
      final a = i * math.pi / n;
      final spike = i.isEven ? 1 + .12 * rnd(i, 3) : 1 - .08 * rnd(i, 4);
      final p = at(c, a, r + (out - r) * spike);
      i == 0 ? outer.moveTo(p.dx, p.dy) : outer.lineTo(p.dx, p.dy);
    }
    outer.close();
    final shape = Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(outer, Offset.zero)
      ..addOval(Rect.fromCircle(center: c, radius: r));
    canvas.drawPath(
      shape,
      Paint()..shader = lin(c + Offset(-r * .4, -r), c + Offset(r * .4, r), const [Color(0xFFF4FCFF), Color(0xFFB4E4FB), Color(0xFF6FBDEC)], const [0, .55, 1]),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lw
        ..strokeJoin = StrokeJoin.round
        ..color = _edge,
    );
    canvas.drawCircle(c, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lw * 1.2
      ..color = _edge);
    // انعكاسات بيضاء على البلور
    gloss(canvas, c, r + ring * .72, ring * .26, from: -2.9, span: 1.5, alpha: .85);
    gloss(canvas, c, r + ring * .4, ring * .14, from: .2, span: .9, alpha: .55);
    gloss(canvas, c, r + ring * .8, ring * .16, from: 2.4, span: .6, alpha: .5);
    // شقوق وحبات صقيع على البلور
    final crack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, hair)
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .8);
    for (var i = 0; i < (small ? 6 : 12); i++) {
      final a = rnd(i, 9) * math.pi * 2;
      final p0 = at(c, a, r + ring * (.5 + .7 * rnd(i, 10)));
      canvas.drawLine(p0, p0 + dir(a + 1.0 + rnd(i, 11)) * ring * (.5 + .6 * rnd(i, 12)), crack);
      canvas.drawCircle(at(c, a + .25, r + ring * (.4 + .9 * rnd(i, 13))), math.max(.6, hair) * 1.2, Paint()..color = Colors.white);
    }
    // أصابع الجليد
    for (final (i, a) in [.45, .8, 1.15, 1.5, 1.85, 2.2, 2.55, -.25].indexed) {
      final len = ring * (1.3 + 1.2 * rnd(i, 5));
      final base = at(c, a, r + ring * .95);
      final up = unit(at(Offset.zero, a, 1) * .45 + const Offset(0, .75));
      final nn = perp(up) * ring * .5;
      final tip = base + up * len;
      final spike = Path()
        ..moveTo((base - nn).dx, (base - nn).dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo((base + nn).dx, (base + nn).dy)
        ..close();
      inked(canvas, spike, shader: lin(base, tip, const [_pale, _mid, _deep]), edge: _edge);
    }
    // الرقائق
    final orbit = b.u * .52;
    for (final (i, (a, sz, ph)) in _flakes.indexed) {
      final glow = b.active ? hump(b.win(i * .08, i * .08 + .45)) : 0.0;
      _flake(canvas, at(c, a + orbit, r + ring * .7), r * sz * (1 + .12 * glow), a * 2 + orbit * 1.2 + ph, glow);
    }
  }

  /// رقاقة ثلج بست أذرع وتفرعات، بحد أزرق وقلب أبيض.
  void _flake(Canvas canvas, Offset p, double len, double turn, double glow) {
    final armW = math.max(1.1, len * .17);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = armW + lw * 1.5
      ..color = _edge;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = armW
      ..color = Color.lerp(_pale, Colors.white, .5 + glow * .5)!;
    final arms = Path();
    for (var k = 0; k < 6; k++) {
      final a = turn + k * math.pi / 3;
      final d = dir(a);
      final tip = p + d * len;
      arms.moveTo(p.dx, p.dy);
      arms.lineTo(tip.dx, tip.dy);
      for (final (f, l) in const [(.48, .36), (.74, .24)]) {
        final q = p + d * len * f;
        for (final s in const [-1.0, 1.0]) {
          final e = q + rot(d, s * .95) * len * l;
          arms.moveTo(q.dx, q.dy);
          arms.lineTo(e.dx, e.dy);
        }
      }
    }
    canvas.drawPath(arms, edge);
    canvas.drawPath(arms, fill);
    canvas.drawCircle(p, armW * .9, Paint()..color = Colors.white);
    if (glow > .05) {
      canvas.drawCircle(
        p,
        len * 1.15,
        Paint()
          ..color = Colors.white.withValues(alpha: .3 * glow)
          ..blendMode = BlendMode.plus,
      );
    }
  }
}

// ═════════════ رمل ═════════════

/// رمل: حلقة ذهب، وكثيبين رمل ذهبي بحد غامق تحتها، وحبّات رمل مدوّرة حواليها. النبضة: الحبّات تتحرك ولمعة تمر.
class SandFrame extends RareFrame {
  SandFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _sand = Color(0xFFC79A54);

  /// حبات الرمل: زاوية، بعد (بنصف القطر)، حجم (بالحلقة).
  static const _grains = [
    (-2.35, 1.2, .26),
    (-2.6, 1.14, .2),
    (-2.2, 1.28, .17),
    (-.65, 1.2, .2),
    (-.4, 1.12, .26),
    (2.9, 1.24, .22),
    (3.15, 1.14, .26),
    (2.7, 1.16, .17),
    (.35, 1.2, .24),
    (.15, 1.27, .18),
    (.5, 1.14, .2),
    (2.45, 1.35, .2),
    (.75, 1.3, .2),
    (-1.0, 1.25, .17),
  ];

  @override
  Color get shine => const Color(0xFFFFF4D2);

  @override
  void artBack(Canvas canvas, Offset c, Beat b) {
    _dune(canvas, c, -1);
    _dune(canvas, c, 1);
  }

  @override
  void art(Canvas canvas, Offset c, Beat b) {
    final out = r + ring * 1.5;
    band(canvas, c, r, out, goldShader(c, out));
    canvas.drawCircle(c, r + lw * .9, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lw * 1.3
      ..color = const Color(0xFF8A4E10).withValues(alpha: .55));
    gloss(canvas, c, r + ring * .95, ring * .3, from: -2.75, span: 1.25, alpha: .75);
    gloss(canvas, c, r + ring * .95, ring * .24, from: .4, span: .6, alpha: .45);
    // حبات الرمل
    for (final (i, (a, d, s)) in _grains.indexed) {
      final w = math.pi * 2 * b.p;
      final p = at(c, a, r * d) + Offset(math.sin(w + i) * ring * .5, math.cos(w * 1.0 + i * 1.7) * ring * .5) * (b.active ? 1 : 0) +
          Offset(math.sin(i * 1.7) * ring * .5, math.cos(i * 2.3) * ring * .5);
      final rad = ring * s * 1.7;
      canvas.drawCircle(p, rad, Paint()..color = _sand);
      canvas.drawCircle(p, rad, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, lw * .8)
        ..color = const Color(0xFF6A431C));
      canvas.drawCircle(p + Offset(-rad * .25, -rad * .25), rad * .3, Paint()..color = const Color(0xFFF3D9A0));
    }
  }

  /// كثيب: جهة اليسار [side] = ‎-١‎ أو اليمين ‎١‎؛ ظهره لطيف وحافته الثانية حادة، وخطوط ريح.
  void _dune(Canvas canvas, Offset c, int side) {
    final x = side.toDouble();
    Offset q(double dx, double dy) => c + Offset(x * r * dx, r * dy);
    final p = Path()
      ..moveTo(q(1.3, 1.06).dx, q(1.3, 1.06).dy)
      ..cubicTo(q(1.1, .98).dx, q(1.1, .98).dy, q(.86, .74).dx, q(.86, .74).dy, q(.6, .66).dx, q(.6, .66).dy)
      ..cubicTo(q(.48, .72).dx, q(.48, .72).dy, q(.3, .92).dx, q(.3, .92).dy, q(.0, 1.02).dx, q(.0, 1.02).dy)
      ..cubicTo(q(.3, 1.12).dx, q(.3, 1.12).dy, q(.9, 1.14).dx, q(.9, 1.14).dy, q(1.3, 1.06).dx, q(1.3, 1.06).dy)
      ..close();
    inked(
      canvas,
      p,
      shader: lin(q(.6, .7), q(.6, 1.1), const [Color(0xFFFFE27A), Color(0xFFF5B93C), Color(0xFFD08E2C)], const [0, .55, 1]),
    );
    final wind = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.7, hair)
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB57A22).withValues(alpha: .7);
    canvas.drawPath(
      Path()
        ..moveTo(q(1.0, .98).dx, q(1.0, .98).dy)
        ..quadraticBezierTo(q(.8, .9).dx, q(.8, .9).dy, q(.6, .86).dx, q(.6, .86).dy),
      wind,
    );
    canvas.drawPath(
      Path()
        ..moveTo(q(.4, .98).dx, q(.4, .98).dy)
        ..quadraticBezierTo(q(.3, .96).dx, q(.3, .96).dy, q(.18, 1.0).dx, q(.18, 1.0).dy),
      wind,
    );
  }
}

// ═════════════ ليل نجد ═════════════

/// ليل نجد: حلقة كحلي بنجوم وهلال مطبوعة وحد فضي رفيع، ونجوم بيضاء صغيرة معلقة فوقها بقوس.
/// النبضة: النجوم ترمش واحدة واحدة، ونجمة شهاب تعبر، ولمعات.
class NightFrame extends RareFrame {
  NightFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _edge = Color(0xFF0B0E22);
  static const _star = Color(0xFFF6F2E4);

  @override
  Color get shine => const Color(0xFFEAF0FF);

  @override
  (double, double) get twinkleRange => (1.15, 1.6);

  @override
  void art(Canvas canvas, Offset c, Beat b) {
    final out = r + ring * 1.6;
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(-r * .5, -r), c + Offset(r * .5, r), const [Color(0xFF55629A), Color(0xFF2D3562), Color(0xFF171C3C)]),
      edge: _edge,
    );
    // حد فضي رفيع داخلي وبراني
    line(canvas, c, r + lw * 1.3, const Color(0xFFD6DCEE), width: math.max(.8, lw * .7));
    line(canvas, c, out - lw * 1.2, const Color(0xFF6E7AA6), width: math.max(.7, lw * .5));
    gloss(canvas, c, r + ring * .85, ring * .2, from: -2.6, span: 1.2, alpha: .35);
    // نقوش مطبوعة: نجوم وهلال ونقاط
    final m = small ? 7 : 11;
    for (var i = 0; i < m; i++) {
      final a = -math.pi / 2 + (i + .5) * math.pi * 2 / m;
      final p = at(c, a, r + ring * .85);
      if (i % 4 == 2) {
        _crescent(canvas, p, ring * .42, a);
      } else if (i.isEven) {
        canvas.drawPath(star5(p, ring * .38, turn: a), Paint()..color = _star);
      } else {
        canvas.drawCircle(p, ring * .09, Paint()..color = _star.withValues(alpha: .8));
      }
    }
    // النجوم المعلقة فوق (قوس)
    const k = 7;
    for (var i = 0; i < k; i++) {
      final f = i / (k - 1);
      final a = lerpD(-2.75, -.4, f);
      final d = r + ring * (2.5 + .9 * math.sin(f * math.pi * 3 + .5) * .5) + ring * .4 * (1 - hump(f));
      final tw = b.active ? hump(b.win(f * .55, f * .55 + .4)) : 0.0;
      final s = ring * (.78 + .1 * rnd(i, 6)) * (1 + .3 * tw);
      final p = at(c, a, d);
      final path = star5(p, s, turn: -math.pi / 2 + (rnd(i, 7) - .5) * .5);
      inked(canvas, path, fill: Color.lerp(const Color(0xFFE9E5D6), Colors.white, tw)!, edge: const Color(0xFF3A3F5E), w: math.max(.8, lw * .85));
    }
    // نجمة شهاب
    final s = b.win(.05, .6);
    if (b.active && s > 0 && s < 1) {
      final head = c + Offset(-r * 1.0, -r * 1.35) + Offset(r * .55, r * .3) * s * 2.2;
      final tail = head - Offset(r * .5, r * .22);
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..strokeWidth = lw * 1.4
          ..strokeCap = StrokeCap.round
          ..shader = lin(tail, head, [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: .95 * hump(s))]),
      );
    }
  }

  void _crescent(Canvas canvas, Offset p, double s, double a) {
    final path = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: p, radius: s)),
      Path()..addOval(Rect.fromCircle(center: p + dir(a - 1.2) * s * .5, radius: s * .82)),
    );
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFE9A6));
  }
}

// ═════════════ فارس المجلس ═════════════

/// فارس المجلس: حلقة برونز بمسامير، وشارة درع صغيرة تحت الصورة. النبضة: لمعة معدن تمر.
class KnightFrame extends RareFrame {
  KnightFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _edge = Color(0xFF2E1A0C);

  @override
  Color get shine => const Color(0xFFFFE8C4);

  @override
  void art(Canvas canvas, Offset c, Beat b) {
    final out = r + ring * 1.2;
    band(
      canvas,
      c,
      r,
      out,
      lin(c + Offset(-r * .4, -r), c + Offset(r * .4, r), const [Color(0xFFF0BE84), Color(0xFFC07B3C), Color(0xFF7A4520)]),
      edge: _edge,
    );
    gloss(canvas, c, r + ring * .65, ring * .24, from: -2.75, span: 1.3, alpha: .7);
    // أخدود محفور بنص الحلقة، ومسامير أكبر على الاتجاهات الأربعة وأصغر بينها
    line(canvas, c, r + ring * .62, const Color(0xFF6B3A18), width: math.max(.8, lw * .8));
    line(canvas, c, r + ring * .62 + lw, const Color(0xFFFFD9A0).withValues(alpha: .5), width: math.max(.6, lw * .5));
    for (var i = 0; i < 12; i++) {
      final big = i % 3 == 0;
      ball(canvas, at(c, -math.pi / 2 + i * math.pi / 6, r + ring * .62), ring * (big ? .3 : .17), const Color(0xFFFFE3B8), const Color(0xFFC98D4C), const Color(0xFF6B3A18), edge: _edge, w: lw * .7);
    }
    // شارة الدرع تحت
    final p = c + Offset(0, r + ring * 1.35);
    final s = ring * 1.9;
    final shield = Path()
      ..moveTo(p.dx - s, p.dy - s * .75)
      ..lineTo(p.dx + s, p.dy - s * .75)
      ..lineTo(p.dx + s, p.dy + s * .1)
      ..quadraticBezierTo(p.dx + s * .9, p.dy + s * .85, p.dx, p.dy + s * 1.2)
      ..quadraticBezierTo(p.dx - s * .9, p.dy + s * .85, p.dx - s, p.dy + s * .1)
      ..close();
    inked(canvas, shield, shader: lin(p - Offset(s, s), p + Offset(s, s), const [Color(0xFFF0BE84), Color(0xFFC07B3C), Color(0xFF7A4520)]), edge: _edge);
    final inner = Path()
      ..moveTo(p.dx - s * .65, p.dy - s * .5)
      ..lineTo(p.dx + s * .65, p.dy - s * .5)
      ..lineTo(p.dx + s * .65, p.dy + s * .08)
      ..quadraticBezierTo(p.dx + s * .55, p.dy + s * .55, p.dx, p.dy + s * .8)
      ..quadraticBezierTo(p.dx - s * .55, p.dy + s * .55, p.dx - s * .65, p.dy + s * .08)
      ..close();
    canvas.drawPath(inner, Paint()..color = const Color(0xFF8E2B1E));
    canvas.drawPath(star5(p + Offset(0, s * .08), s * .42), Paint()..color = const Color(0xFFFFE08A));
  }
}

// ═════════════ هلال الموسم ═════════════

/// هلال الموسم: هلال ذهب يحضن الصورة من تحت وجنب، وثلاث نجوم ذهب فوق، على حلقة ذهب رفيعة.
/// النبضة: النجوم تلمع ولمعة تمر على الهلال.
class CrescentFrame extends RareFrame {
  CrescentFrame(super.time, {required super.avatar, required super.layer, super.moment});

  @override
  Color get shine => const Color(0xFFFFF3C4);

  @override
  void art(Canvas canvas, Offset c, Beat b) {
    final out = r + ring * .75;
    band(canvas, c, r, out, goldShader(c, out));
    gloss(canvas, c, r + ring * .4, ring * .16, from: -2.7, span: 1.2, alpha: .7);
    // الهلال: دائرة كبيرة ناقص دائرة مزاحة
    final big = r * 1.5;
    final centre = c + Offset(0, r * .1);
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: centre, radius: big)),
      Path()..addOval(Rect.fromCircle(center: c + Offset(0, -r * .26), radius: r * 1.27)),
    );
    inked(canvas, crescent, shader: goldShader(centre, big));
    // نجوم ذهب فوق
    for (final (i, (a, d, s)) in const [(-1.15, 1.42, .55), (-.68, 1.48, .42), (-.28, 1.32, .5)].indexed) {
      final tw = b.active ? hump(b.win(i * .2, i * .2 + .45)) : 0.0;
      inked(
        canvas,
        star5(at(c, a, r * d), ring * s * 1.7 * (1 + .25 * tw)),
        shader: lin(at(c, a, r * d) - Offset(0, ring), at(c, a, r * d) + Offset(0, ring), const [Color(0xFFFFEF9C), Color(0xFFF2B53A)]),
        w: math.max(.8, lw * .9),
      );
    }
  }
}
