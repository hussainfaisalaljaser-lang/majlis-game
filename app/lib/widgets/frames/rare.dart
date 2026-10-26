import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'kit.dart';

// الإطارات النادرة: كل واحد رسمة ثابتة ما تشبه غيرها، ولمعة خفيفة تمر كل كم ثانية.

// ═════════════ جليد ═════════════

/// جليد: حلقة بلور مقطّع أوجه، ورقاقات ثلج على الجنبين، وأصابع ثلج معلقة تحت.
class IceFrame extends RareFrame {
  IceFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _ice = Color(0xFF5EE0FF);
  static const _pale = Color(0xFFB8F4FF);
  static const _deep = Color(0xFF0E7490);

  /// أصبع الثلج رقم [i] (٠–٦): زاويته وطوله.
  (double, double) _icicle(int i) {
    final k = (i - 3) / 3;
    return (math.pi / 2 + k * .95, r * (.36 - .17 * k.abs()) * (.85 + .3 * rnd(i, 4)));
  }

  /// يتدلى لتحت أكثر من ما يطلع لبرا.
  Offset _hang(double a) => unit(dir(a) * .35 + const Offset(0, .65));

  @override
  Offset sparkleAt(Offset c) {
    final (a, len) = _icicle(3);
    return c + dir(a) * (r + ring * .8) + _hang(a) * len * .8;
  }

  @override
  void art(Canvas canvas, Offset c) {
    glowRing(canvas, c, _ice.withValues(alpha: .35), blur: ring * 1.2);
    // البلور: أوجه بثلاث درجات، وحافتها البرانية مكسّرة شوي
    final n = small ? 14 : 20;
    for (var i = 0; i < n; i++) {
      final a0 = i * 2 * math.pi / n, a1 = (i + 1) * 2 * math.pi / n;
      final o0 = r + ring * (1 + (rnd(i, 1) - .5) * .35), o1 = r + ring * (1 + (rnd(i + 1, 1) - .5) * .35);
      final tone = [_pale, _ice, const Color(0xFF9BEBFF)][i % 3];
      canvas.drawPath(
        poly([c + dir(a0) * r, c + dir(a0) * o0, c + dir(a1) * o1, c + dir(a1) * r]),
        Paint()..color = Color.lerp(tone, Colors.white, rnd(i, 2) * .3)!,
      );
      canvas.drawLine(
        c + dir(a0) * r,
        c + dir(a0) * o0,
        Paint()
          ..color = Colors.white.withValues(alpha: .7)
          ..strokeWidth = hair * .8,
      );
    }
    line(canvas, c, r, _deep.withValues(alpha: .7), width: hair * 1.4);
    // أصابع الثلج
    for (var i = 0; i < 7; i++) {
      final (a, len) = _icicle(i);
      final base = c + dir(a) * (r + ring * .8);
      final d = _hang(a), side = perp(d) * ring * .5 * (len / (r * .3));
      final tip = base + d * len;
      canvas.drawPath(
        Path()
          ..moveTo((base - side).dx, (base - side).dy)
          ..quadraticBezierTo(
            (base - side * .4 + d * len * .55).dx,
            (base - side * .4 + d * len * .55).dy,
            tip.dx,
            tip.dy,
          )
          ..quadraticBezierTo(
            (base + side * .4 + d * len * .55).dx,
            (base + side * .4 + d * len * .55).dy,
            (base + side).dx,
            (base + side).dy,
          )
          ..close(),
        Paint()
          ..shader = ui.Gradient.linear(
            base,
            tip,
            [Colors.white.withValues(alpha: .95), _pale.withValues(alpha: .85), _ice.withValues(alpha: .35)],
            [0, .55, 1],
          ),
      );
      canvas.drawLine(
        base - side * .3,
        base + d * len * .7,
        Paint()
          ..color = Colors.white.withValues(alpha: .8)
          ..strokeWidth = hair * .8
          ..strokeCap = StrokeCap.round,
      );
    }
    // رقاقتين ثلج فوق
    for (final a in [-2.45, -.69]) {
      _flake(canvas, c + dir(a) * (r + ring * .55), ring * 1.25);
    }
  }

  void _flake(Canvas canvas, Offset p, double s) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = math.max(.7, s * .14)
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(p, s * 1.1, Paint()..color = _ice.withValues(alpha: .25));
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3 + math.pi / 6;
      canvas.drawLine(p, p + dir(a) * s, paint);
      final q = p + dir(a) * s * .55;
      canvas.drawLine(q, q + dir(a + .8) * s * .32, paint);
      canvas.drawLine(q, q + dir(a - .8) * s * .32, paint);
    }
  }
}

// ═════════════ رمل ═════════════

/// رمل: طبقات حجر رملي متموجة، وكثيبين رمل تحت الصورة عليهم تموجات الريح.
class SandFrame extends RareFrame {
  SandFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _light = Color(0xFFF7E2B0);
  static const _mid = Color(0xFFE8C27A);
  static const _dark = Color(0xFFB5823C);
  static const _shadow = Color(0xFF7A5222);

  @override
  Color get shine => const Color(0xFFFFF1D0);

  @override
  Offset sparkleAt(Offset c) => c + Offset(r * .62, r * .93);

  @override
  void art(Canvas canvas, Offset c) {
    sweepRing(canvas, c, const [_dark, Color(0xFFC9934A), _dark, Color(0xFFA8743A)]);
    _band(canvas, c, r + ring * .32, r + ring * .72, _mid, waves: 9, seed: 1);
    _band(canvas, c, r, r + ring * .36, _light, waves: 13, seed: 2);
    line(canvas, c, r + ring, _shadow.withValues(alpha: .8));
    line(canvas, c, r, _shadow.withValues(alpha: .6));
    _dune(canvas, c, -1.38, -.5, .4, .87, .1);
    _dune(canvas, c, -.32, .62, 1.38, .93, .5);
  }

  /// طبقة حجر بحواف متموجة.
  void _band(
    Canvas canvas,
    Offset c,
    double inner,
    double outer,
    Color color, {
    required int waves,
    required int seed,
  }) {
    const steps = 72;
    final pts = <Offset>[
      for (var i = 0; i <= steps; i++)
        c + dir(i * 2 * math.pi / steps) * (outer + ring * .08 * math.sin(waves * i * 2 * math.pi / steps + seed)),
      for (var i = steps; i >= 0; i--)
        c +
            dir(i * 2 * math.pi / steps) *
                (inner + ring * .05 * math.sin(waves * 1.3 * i * 2 * math.pi / steps + seed * 2)),
    ];
    canvas.drawPath(poly(pts), Paint()..color = color);
  }

  /// كثيب: يبدأ من [x0] ويطلع لقمته عند [peak] (ارتفاعها [top] من المركز) وينزل لـ[x1]. كله بنص قطر الصورة.
  void _dune(Canvas canvas, Offset c, double x0, double peak, double x1, double top, double light) {
    final bottom = c.dy + r * 1.27;
    Offset at(double x, double y) => Offset(c.dx + x * r, c.dy + y * r);
    final crest = Path()
      ..moveTo(at(x0, 1.22).dx, at(x0, 1.22).dy)
      ..quadraticBezierTo(
        at((x0 + peak) / 2, top - .02).dx,
        at((x0 + peak) / 2, top - .02).dy,
        at(peak, top).dx,
        at(peak, top).dy,
      )
      ..quadraticBezierTo(
        at((peak + x1) / 2, top + .06).dx,
        at((peak + x1) / 2, top + .06).dy,
        at(x1, 1.2).dx,
        at(x1, 1.2).dy,
      );
    final body = Path.from(crest)
      ..lineTo(at(x1, 1.2).dx, bottom)
      ..lineTo(at(x0, 1.22).dx, bottom)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(at(peak, top), Offset(at(peak, top).dx, bottom), [
          Color.lerp(_mid, _light, light)!,
          _dark,
        ]),
    );
    canvas.drawPath(
      crest,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair * 1.3
        ..color = _light,
    );
    // تموجات الريح تحت القمة
    final ripple = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair * .9
      ..color = _shadow.withValues(alpha: .45);
    for (var k = 1; k <= 2; k++) {
      final dy = r * .1 * k;
      canvas.drawPath(
        Path()
          ..moveTo(at((x0 + peak) / 2, top + .1).dx, at(0, top + .1).dy + dy)
          ..quadraticBezierTo(
            at(peak, top).dx,
            at(peak, top).dy + dy,
            at((peak + x1) / 2, top + .14).dx,
            at(0, top + .16).dy + dy,
          ),
        ripple,
      );
    }
  }
}

// ═════════════ واحة ═════════════

/// واحة: حلقة ماي صافي عليها تموجات، ونخلتين على الجنبين بعذوق تمر، وعشب تحت.
class OasisFrame extends RareFrame {
  OasisFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _water = Color(0xFF1ABC9C);
  static const _green = Color(0xFF2ECC71);
  static const _lime = Color(0xFFA3E635);
  static const _leaf = Color(0xFF15803D);
  static const _trunk = Color(0xFF9C7A54);
  static const _trunkDark = Color(0xFF5D4630);

  @override
  Color get shine => const Color(0xFFE0FFF6);

  /// النخلة: قاعدتها، وراسها، ونقطة الانحناء (بنص قطر الصورة)، واليسار ولا اليمين.
  List<(Offset, Offset, Offset)> _palms(Offset c) => [
    (c + Offset(-r * .78, r * 1.14), c + Offset(-r * 1.2, -r * .4), c + Offset(-r * 1.34, r * .45)),
    (c + Offset(r * .82, r * 1.14), c + Offset(r * 1.22, -r * .3), c + Offset(r * 1.36, r * .5)),
  ];

  @override
  void artBack(Canvas canvas, Offset c) {
    for (final (base, top, bend) in _palms(c)) {
      final trunk = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(bend.dx, bend.dy, top.dx, top.dy);
      canvas.drawPath(
        trunk,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring * 1.05
          ..strokeCap = StrokeCap.round
          ..shader = ui.Gradient.linear(base, top, [_trunkDark, _trunk]),
      );
      // حلقات الجذع
      final metric = trunk.computeMetrics().first;
      final mark = Paint()
        ..strokeWidth = hair
        ..color = _trunkDark.withValues(alpha: .8);
      for (var k = 1; k < 9; k++) {
        final tan = metric.getTangentForOffset(metric.length * k / 9)!;
        final n = perp(tan.vector) * ring * .5;
        canvas.drawLine(tan.position - n, tan.position + n, mark);
      }
    }
  }

  @override
  void art(Canvas canvas, Offset c) {
    sweepRing(canvas, c, const [_water, Color(0xFF0E7C66), _water, Color(0xFF5EEAD4)], turn: .6);
    line(canvas, c, r + ring, const Color(0xFF0B5D4E));
    line(canvas, c, r, const Color(0xFFCCFBF1).withValues(alpha: .8));
    // تموجات على الماي
    final ripple = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .65);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + .4;
      final rad = mid + (i.isEven ? -1 : 1) * ring * .15;
      canvas.drawArc(Rect.fromCircle(center: c, radius: rad), a, .28, false, ripple);
    }
    // سعف النخل وعذوق التمر
    for (final (i, (_, top, _)) in _palms(c).indexed) {
      final left = i == 0;
      final angles = left
          ? const [-2.75, -2.15, -1.6, -1.05, -.45, .2]
          : const [-.39, -.99, -1.54, -2.09, -2.69, -3.34];
      for (final (k, a) in angles.indexed) {
        _frond(canvas, top, a, r * (.5 + .1 * rnd(k, i + 3)));
      }
      for (var k = 0; k < 3; k++) {
        canvas.drawCircle(
          top + Offset((k - 1) * ring * .45, ring * (.5 + .2 * (k % 2))),
          ring * .3,
          Paint()..color = const Color(0xFF8B4A1F),
        );
      }
    }
    // عشب تحت
    final grass = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair * 1.4
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 7; k++) {
      final x = (k - 3) * r * .09;
      final base = c + Offset(x, r * 1.2);
      final lean = (k - 3) * .12;
      grass.color = k.isEven ? _lime : _green;
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(
            base.dx + lean * r * .2,
            base.dy - r * .12,
            base.dx + lean * r * .5,
            base.dy - r * (.18 + .05 * (k % 3)),
          ),
        grass,
      );
    }
  }

  /// سعفة: عرق ينحني لتحت، وعليه وريقات على الجنبين تقصر لين الطرف.
  void _frond(Canvas canvas, Offset from, double a, double len) {
    final end = from + dir(a) * len + Offset(0, len * .38);
    final ctrl = from + dir(a) * len * .62 - Offset(0, len * .08);
    final spine = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
    final metric = spine.computeMetrics().first;
    final leaflet = Paint()
      ..strokeWidth = ring * .3
      ..strokeCap = StrokeCap.round;
    const n = 7;
    for (var k = 1; k <= n; k++) {
      final s = k / (n + 1);
      final tan = metric.getTangentForOffset(metric.length * s)!;
      final l = len * .2 * (1 - s * .6);
      leaflet.color = Color.lerp(_green, _leaf, s)!;
      for (final sgn in const [-1, 1]) {
        canvas.drawLine(tan.position, tan.position + rot(tan.vector, sgn * .95) * l, leaflet);
      }
    }
    canvas.drawPath(
      spine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair * 1.3
        ..color = _leaf,
    );
  }
}

// ═════════════ لؤلؤ ═════════════

/// لؤلؤ: عقد حبات لؤلؤ على خيط ذهب، وحبة كبيرة معلقة تحت. اللمعة تمشي على الحبات حبة حبة.
class PearlFrame extends RareFrame {
  PearlFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _nacre = Color(0xFFE6E1F0);
  static const _lav = Color(0xFFCFC7E8);
  static const _edge = Color(0xFF7E6FA6);
  static const _gold = Color(0xFFE8C77A);

  int get _n => small ? 18 : 24;
  double get _bead => math.pi * mid / _n * 1.02;
  double _angle(int i) => math.pi / 2 + i * 2 * math.pi / _n;
  Offset _drop(Offset c) => c + Offset(0, mid + _bead + ring * 1.15);

  @override
  Offset sparkleAt(Offset c) => _drop(c) + Offset(-ring * .3, -ring * .3);

  @override
  void art(Canvas canvas, Offset c) {
    line(canvas, c, mid, _gold, width: hair * 1.2);
    for (var i = 0; i < _n; i++) {
      _pearl(canvas, c + dir(_angle(i)) * mid, _bead);
    }
    // الحبة المعلقة وغطاها الذهبي
    final drop = _drop(c);
    final capTop = c + Offset(0, mid + _bead * .85);
    canvas.drawPath(
      poly([
        capTop + Offset(-ring * .35, 0),
        capTop + Offset(ring * .35, 0),
        drop + Offset(ring * .55, -ring * .85),
        drop + Offset(-ring * .55, -ring * .85),
      ]),
      Paint()..color = _gold,
    );
    _pearl(canvas, drop, ring * 1.05);
  }

  void _pearl(Canvas canvas, Offset p, double s) {
    canvas.drawCircle(p + Offset(s * .12, s * .18), s, Paint()..color = _edge.withValues(alpha: .35));
    canvas.drawCircle(
      p,
      s,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.45),
          colors: const [Colors.white, _nacre, _lav, _edge],
          stops: const [0, .45, .8, 1],
        ).createShader(Rect.fromCircle(center: p, radius: s)),
    );
    canvas.drawArc(
      Rect.fromCircle(center: p, radius: s * .72),
      .2,
      1.3,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .16
        ..color = const Color(0xFFF8BBD0).withValues(alpha: .35),
    );
    canvas.drawCircle(p + Offset(-s * .34, -s * .38), s * .2, Paint()..color = Colors.white.withValues(alpha: .9));
  }

  @override
  void glint(Canvas canvas, Offset c, double p) {
    final front = -math.pi * .75 + p * math.pi * 2.2;
    final paint = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < _n; i++) {
      var d = (_angle(i) - front) % (2 * math.pi);
      if (d > math.pi) d -= 2 * math.pi;
      final b = math.exp(-d * d / .12);
      if (b < .02) continue;
      paint.color = Colors.white.withValues(alpha: .75 * b);
      canvas.drawCircle(c + dir(_angle(i)) * mid, _bead * .8, paint);
    }
    sparkle(canvas, sparkleAt(c), ring * .9, shine, hump((p - .55) / .45));
  }
}

// ═════════════ ليل نجد ═════════════

/// ليل نجد: حلقة ليل كحلي فيها نجوم صغيرة، وتحت الصورة بيوت طين نجدية بشرفاتها ومربعتها ونخلة،
/// ونوافذها المثلثة تضوي. وفوق نجوم تلمع.
class NightFrame extends RareFrame {
  NightFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _navy = Color(0xFF1E3A8A);
  static const _indigo = Color(0xFF312E81);
  static const _sky = Color(0xFF93C5FD);
  static const _mud = Color(0xFF1C1736);
  static const _mudLight = Color(0xFF41386E);
  static const _window = Color(0xFFFFD27A);

  @override
  Color get shine => const Color(0xFFE0E7FF);

  @override
  Offset sparkleAt(Offset c) => c + dir(-1.2) * r * 1.42;

  @override
  void art(Canvas canvas, Offset c) {
    halo(
      canvas,
      c,
      r * 1.5,
      [_sky.withValues(alpha: 0), _sky.withValues(alpha: .22), _sky.withValues(alpha: 0)],
      stops: const [.62, .78, 1],
    );
    sweepRing(canvas, c, const [_navy, _indigo, _navy, Color(0xFF1E40AF)]);
    final dots = Paint()..color = Colors.white.withValues(alpha: .7);
    for (var i = 0; i < (small ? 7 : 12); i++) {
      canvas.drawCircle(c + dir(rnd(i, 3) * 2 * math.pi) * (r + ring * (.25 + .5 * rnd(i, 4))), hair * .7, dots);
    }
    line(canvas, c, r + ring, _sky.withValues(alpha: .75));
    line(canvas, c, r, _sky.withValues(alpha: .5));
    // نجوم فوق
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + (i - 2.5) * .42 + (rnd(i, 7) - .5) * .2;
      final s = ring * (i == 1 ? .75 : .35 + .2 * rnd(i, 8));
      canvas.drawPath(
        star4(c + dir(a) * r * (1.32 + .12 * rnd(i, 9)), s),
        Paint()..color = Colors.white.withValues(alpha: .9),
      );
    }
    _village(canvas, c);
  }

  /// بيوت طين تحت الصورة كأنها على تلة: أسطح بشرفات مثلثة يضويها القمر من فوق، ومربعة أطول، ونخلة،
  /// ونوافذ مثلثة دافية. الأرض مقوسة عشان ما تطلع مثل صندوق.
  void _village(Canvas canvas, Offset c) {
    final top = c.dy + r * .7, ground = c.dy + r * 1.4;
    // التلة: كل البيوت تنقص على قوس من تحت
    final hill = Path()
      ..moveTo(c.dx - r * .95, top)
      ..lineTo(c.dx + r * .95, top)
      ..lineTo(c.dx + r * .95, c.dy + r * 1.3)
      ..quadraticBezierTo(c.dx, ground + r * .1, c.dx - r * .95, c.dy + r * 1.3)
      ..close();
    final town = Path();
    // (من، إلى، ارتفاع السطح) بنص قطر الصورة
    const houses = [(-.9, -.56, 1.0), (-.6, -.3, .9), (-.32, .1, .97), (.08, .44, .93), (.42, .84, 1.02)];
    final roofs = <(double, double, double)>[];
    for (final (x0, x1, h) in houses) {
      final left = c.dx + x0 * r, right = c.dx + x1 * r, roof = c.dy + h * r;
      town.addRect(Rect.fromLTRB(left, roof, right, ground + r * .2));
      // الشرفات النجدية على السطح
      final n = math.max(2, ((right - left) / (ring * .85)).floor());
      final step = (right - left) / n;
      for (var k = 0; k < n; k++) {
        final x = left + step * (k + .5);
        town.addPath(
          poly([Offset(x - step * .3, roof + .5), Offset(x, roof - ring * .5), Offset(x + step * .3, roof + .5)]),
          Offset.zero,
        );
      }
      roofs.add((left, right, roof));
    }
    // المربعة: برج أطول وأضيق
    final tl = c.dx - r * .5, tr = c.dx - r * .33, tt = c.dy + r * .74;
    town.addRect(Rect.fromLTRB(tl, tt, tr, ground));
    town.addPath(poly([Offset(tl, tt + .5), Offset((tl + tr) / 2, tt - ring * .65), Offset(tr, tt + .5)]), Offset.zero);
    final shape = Path.combine(PathOperation.intersect, town, hill);
    canvas.drawPath(
      shape,
      Paint()..shader = ui.Gradient.linear(Offset(c.dx, top), Offset(c.dx, ground), [_mudLight, _mud]),
    );
    // ضو القمر على حواف الأسطح
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hair
      ..color = _sky.withValues(alpha: .55);
    for (final (left, right, roof) in roofs) {
      canvas.drawLine(Offset(left, roof), Offset(right, roof), rim);
    }
    canvas.drawLine(Offset(tl, tt), Offset(tr, tt), rim);
    // نوافذ مثلثة تضوي
    final glow = Paint()..blendMode = BlendMode.plus;
    final w = ring * .28;
    void window(Offset o) {
      glow.color = _window.withValues(alpha: .16);
      canvas.drawCircle(o, w * 1.5, glow);
      canvas.drawPath(
        poly([Offset(o.dx - w, o.dy + w * .7), Offset(o.dx, o.dy - w * .8), Offset(o.dx + w, o.dy + w * .7)]),
        Paint()..color = _window,
      );
    }

    for (final (i, (left, right, roof)) in roofs.indexed) {
      final count = small ? 1 : 2;
      for (var k = 0; k < count; k++) {
        if (rnd(i * 3 + k, 11) < .25) continue;
        window(Offset(left + (right - left) * (k + 1) / (count + 1), roof + r * .17));
      }
    }
    window(Offset((tl + tr) / 2, tt + r * .1));
    // نخلة صغيرة على طرف التلة
    final pb = Offset(c.dx + r * .88, c.dy + r * 1.3), pt = Offset(c.dx + r * .98, c.dy + r * .86);
    final palm = Paint()
      ..strokeWidth = ring * .3
      ..strokeCap = StrokeCap.round
      ..color = _mud;
    canvas.drawLine(pb, pt, palm);
    palm.strokeWidth = ring * .24;
    for (final a in const [-2.8, -2.2, -1.6, -1.0, -.4]) {
      canvas.drawLine(pt, pt + dir(a) * r * .2 + Offset(0, r * .06), palm);
    }
  }
}

// ═════════════ فارس المجلس (مستوى ١٠) ═════════════

/// فارس المجلس: حلقة برونز مطروقة بمسامير وخطين محفورين، وتحتها درع صغير عليه نجمة.
class KnightFrame extends RareFrame {
  KnightFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _bronze = Color(0xFFCD7F32);
  static const _dark = Color(0xFF8B4513);
  static const _light = Color(0xFFF4A460);
  static const _deep = Color(0xFF5A2D0C);

  @override
  Color get shine => const Color(0xFFFFE0B2);

  @override
  Offset sparkleAt(Offset c) => c + Offset(-ring * .5, r + ring * 1.2);

  @override
  void art(Canvas canvas, Offset c) {
    sweepRing(canvas, c, const [_dark, _bronze, _light, _bronze, _dark, _bronze, _light, _bronze], turn: .4);
    // آثار المطرقة
    final dent = Paint()..color = _deep.withValues(alpha: .28);
    for (var i = 0; i < (small ? 16 : 30); i++) {
      canvas.drawCircle(
        c + dir(rnd(i, 1) * 2 * math.pi) * (r + ring * (.2 + .6 * rnd(i, 2))),
        ring * (.07 + .07 * rnd(i, 3)),
        dent,
      );
    }
    line(canvas, c, r + ring * .2, _deep.withValues(alpha: .7));
    line(canvas, c, r + ring * .82, _deep.withValues(alpha: .6));
    line(canvas, c, r + ring, _deep);
    // المسامير
    for (var k = 0; k < 12; k++) {
      final p = c + dir(k * math.pi / 6 + math.pi / 12) * mid;
      canvas.drawCircle(p + Offset(ring * .05, ring * .07), ring * .24, Paint()..color = _deep.withValues(alpha: .6));
      canvas.drawCircle(
        p,
        ring * .22,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.4, -.4),
            colors: const [Color(0xFFFFE0B2), _light, _dark],
          ).createShader(Rect.fromCircle(center: p, radius: ring * .22)),
      );
    }
    // الدرع تحت
    final top = c.dy + r + ring * .1, w = ring * 1.35, h = ring * 2.9, x = c.dx;
    final shield = Path()
      ..moveTo(x - w, top)
      ..quadraticBezierTo(x, top - ring * .35, x + w, top)
      ..lineTo(x + w, top + h * .45)
      ..quadraticBezierTo(x + w * .9, top + h * .85, x, top + h)
      ..quadraticBezierTo(x - w * .9, top + h * .85, x - w, top + h * .45)
      ..close();
    canvas.drawPath(shield.shift(Offset(ring * .08, ring * .12)), Paint()..color = _deep.withValues(alpha: .5));
    canvas.drawPath(
      shield,
      Paint()..shader = ui.Gradient.linear(Offset(x - w, top), Offset(x + w, top + h), [_light, _bronze, _dark]),
    );
    canvas.drawPath(
      shield,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = hair * 1.3
        ..color = _deep,
    );
    canvas.drawPath(star5(Offset(x, top + h * .45), ring * .62), Paint()..color = const Color(0xFFFFE7C2));
  }
}

// ═════════════ هلال الموسم ═════════════

/// هلال الموسم: حلقة فيروزية بحواف ذهب، وهلال ذهبي كبير يحضن الصورة من فوق، ونجوم ذهب.
class CrescentFrame extends RareFrame {
  CrescentFrame(super.time, {required super.avatar, required super.layer, super.moment});

  static const _teal = Color(0xFF0F766E);
  static const _deep = Color(0xFF134E4A);
  static const _gold = Color(0xFFFCD34D);
  static const _pale = Color(0xFFFDE68A);
  static const _mint = Color(0xFF5EEAD4);

  static const _at = -2.3;

  @override
  Color get shine => _pale;

  @override
  Offset sparkleAt(Offset c) => c + dir(_at + .55) * r * 1.22;

  @override
  void art(Canvas canvas, Offset c) {
    glowRing(canvas, c, _mint.withValues(alpha: .25));
    sweepRing(canvas, c, const [_deep, _teal, _deep, Color(0xFF14B8A6)]);
    line(canvas, c, r + ring, _gold, width: hair * 1.4);
    line(canvas, c, r, _gold.withValues(alpha: .8));
    // الهلال: دايرة ناقص دايرة أقرب للصورة
    final cc = c + dir(_at) * r * 1.02, big = r * .44;
    final cut = cc + unit(c - cc) * big * .42;
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: cc, radius: big)),
      Path()..addOval(Rect.fromCircle(center: cut, radius: big * .86)),
    );
    halo(canvas, cc, big * 1.6, [_gold.withValues(alpha: .3), _gold.withValues(alpha: 0)]);
    canvas.drawPath(
      moon,
      Paint()
        ..shader = ui.Gradient.linear(cc + Offset(-big, -big), cc + Offset(big, big), [
          _pale,
          _gold,
          const Color(0xFFD99A1E),
        ]),
    );
    // نجوم ذهب يمين فوق
    for (final (a, s) in const [(-.55, .62), (-.95, .44), (-.2, .38)]) {
      canvas.drawPath(star5(c + dir(a) * r * 1.3, ring * s), Paint()..color = _gold);
    }
  }
}
