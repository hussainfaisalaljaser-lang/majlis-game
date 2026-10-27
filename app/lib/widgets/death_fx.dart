import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/shop.dart';
import 'common.dart';
import 'fx.dart';
import 'majlis.dart';

// افكتات الموت (DeathFx في models/shop.dart): كل افكت كيف تتغير صورة اللاعب ([deathLook]) وإيش ينرسم فوقها
// ([DeathPainter]) حسب الوقت من بداية الطرد. الافتراضي الغطا الرمادي (SeatCloth).

/// الحزن والرمادي أول (مثل الافتراضي)، وبعدها يبدأ الافكت.
const deathFxStart = 1.0;

/// طول الافكت؛ بعده تثبت آخر لقطة (اللي يتبقى على مكانه) لين تخلص اللعبة.
const deathFxLength = 2.6;

/// كيف تبان صورة اللاعب: شفافيتها، وفلتر لونها، وكم تنزل أو تطلع.
typedef DeathLook = ({double opacity, List<double>? matrix, double dy});

/// تقدم بين [a] و[b] (٠–١).
double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

List<double> _mix(List<double> to, double k) {
  const id = <double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
  return [for (var i = 0; i < 20; i++) id[i] + (to[i] - id[i]) * k];
}

/// رمادي.
const _grey = <double>[
  .33, .59, .11, 0, 0, //
  .33, .59, .11, 0, 0,
  .33, .59, .11, 0, 0,
  0, 0, 0, 1, 0,
];

/// ذهب: الإضاءة تصير ذهبية.
const _gold = <double>[
  .55, .45, .1, 0, 40, //
  .42, .38, .08, 0, 18,
  .12, .1, .05, 0, -10,
  0, 0, 0, 1, 0,
];

/// جليد: أزرق فاتح.
const _ice = <double>[
  .5, .3, .2, 0, 30, //
  .4, .5, .3, 0, 50,
  .4, .5, .5, 0, 90,
  0, 0, 0, 1, 0,
];

/// متفحم.
const _char = <double>[
  .18, .18, .1, 0, -10, //
  .14, .14, .08, 0, -14,
  .1, .1, .06, 0, -16,
  0, 0, 0, 1, 0,
];

/// [t] الوقت من بداية الطرد (ثواني).
DeathLook deathLook(DeathFx fx, double t) {
  final s = t - deathFxStart;
  final grey = _seg(t, 0, .9) * .8;
  if (s <= 0 || fx == DeathFx.cloth) return (opacity: 1, matrix: _mix(_grey, grey), dy: 0);
  return switch (fx) {
    DeathFx.smoke => (opacity: 1 - _seg(s, .5, 1.7) * .92, matrix: _mix(_grey, .8), dy: 0),
    DeathFx.sand => (opacity: 1 - _seg(s, .2, 1.5), matrix: _mix(_grey, .8 - _seg(s, 0, .4) * .5), dy: 0),
    DeathFx.ice => (opacity: 1, matrix: _mix(_ice, .4 + _seg(s, 0, 1) * .6), dy: 0),
    DeathFx.fire => (opacity: 1 - _seg(s, .9, 1.7), matrix: _mix(_char, _seg(s, .1, 1)), dy: 0),
    DeathFx.lightning => (opacity: 1, matrix: _mix(_char, _seg(s, .15, .35) * .85), dy: 0),
    DeathFx.ghost => (opacity: .55, matrix: _mix(_grey, .9), dy: 0),
    DeathFx.gold => (opacity: 1, matrix: _mix(_gold, .2 + _seg(s, 0, 1.3) * .8), dy: 0),
    DeathFx.petals => (opacity: 1 - _seg(s, .3, 1.5), matrix: _mix(_grey, .5), dy: 0),
    DeathFx.bats => (opacity: 1 - _seg(s, .15, .9), matrix: _mix(_char, .8), dy: 0),
    DeathFx.cloth => (opacity: 1, matrix: null, dy: 0),
  };
}

/// اللي ينرسم فوق صورة اللاعب ([size] = مكان الصورة نفسها؛ الرسمة تطلع برا شوي).
class DeathPainter extends CustomPainter {
  DeathPainter(this.fx, this.t);

  final DeathFx fx;

  /// الوقت من بداية الطرد.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = t - deathFxStart;
    if (s <= 0) return;
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    switch (fx) {
      case DeathFx.cloth:
        break;
      case DeathFx.smoke:
        _smoke(canvas, c, r, s);
      case DeathFx.sand:
        _sand(canvas, c, r, s);
      case DeathFx.ice:
        _ice(canvas, c, r, s);
      case DeathFx.fire:
        _fire(canvas, c, r, s);
      case DeathFx.lightning:
        _lightning(canvas, c, r, s);
      case DeathFx.ghost:
        _ghost(canvas, c, r, s);
      case DeathFx.gold:
        _goldFx(canvas, c, r, s);
      case DeathFx.petals:
        _petals(canvas, c, r, s);
      case DeathFx.bats:
        _bats(canvas, c, r, s);
    }
  }

  // دخان بنفسجي يلف اللاعب ويختفي، ويبقى منه خيوط خفيفة.
  void _smoke(Canvas canvas, Offset c, double r, double s) {
    final p = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (var i = 0; i < 14; i++) {
      final a = rnd(i, 1) * math.pi * 2;
      final grow = _seg(s, rnd(i, 2) * .4, 1.2 + rnd(i, 3) * .6);
      final fade = 1 - _seg(s, 1.4 + rnd(i, 4) * .5, 2.6);
      final d = r * (.2 + grow * (.6 + rnd(i, 5) * .5));
      final pos = c + Offset(math.cos(a) * d, math.sin(a) * d * .8 - grow * r * .5);
      p.color = Color.lerp(const Color(0xFF6B5B95), const Color(0xFFB8B0D0), rnd(i, 6))!.withValues(alpha: .7 * fade);
      canvas.drawCircle(pos, r * (.25 + grow * .35), p);
    }
    // خيوط تبقى.
    final wisp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB8B0D0).withValues(alpha: .45 * _seg(s, 1.6, 2.4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (var i = 0; i < 3; i++) {
      final x = c.dx + (i - 1) * r * .45;
      canvas.drawPath(
        Path()
          ..moveTo(x, c.dy + r * .5)
          ..quadraticBezierTo(x - r * .25, c.dy, x + r * .1, c.dy - r * .5)
          ..quadraticBezierTo(x + r * .3, c.dy - r * .8, x, c.dy - r),
        wisp,
      );
    }
  }

  // اللاعب يتفتت رمل ويطير مع الهوا، ويبقى كومة رمل.
  void _sand(Canvas canvas, Offset c, double r, double s) {
    final p = Paint();
    for (var i = 0; i < 70; i++) {
      final start = .1 + rnd(i, 1) * 1.1;
      final k = _seg(s, start, start + .9 + rnd(i, 2) * .5);
      if (k <= 0 || k >= 1) continue;
      final from = c + Offset((rnd(i, 3) - .5) * r * 1.6, (rnd(i, 4) - .5) * r * 1.6);
      final pos = from + Offset(k * r * (1.6 + rnd(i, 5)), -k * r * (.6 + rnd(i, 6)) + math.sin(k * 6 + i) * 3);
      p.color = Color.lerp(const Color(0xFFE9C46A), const Color(0xFFB8864B), rnd(i, 7))!.withValues(alpha: 1 - k);
      canvas.drawCircle(pos, 1.2 + rnd(i, 8) * 1.6, p);
    }
    // الكومة تكبر تحت.
    final pile = _seg(s, .4, 1.6);
    if (pile > 0) {
      final rect = Rect.fromCenter(center: c + Offset(0, r * .75), width: r * 1.5 * pile, height: r * .6 * pile);
      canvas.drawOval(
        rect,
        Paint()..shader = const RadialGradient(colors: [Color(0xFFE9C46A), Color(0xFF9C6B30)]).createShader(rect),
      );
      for (var i = 0; i < 8; i++) {
        canvas.drawCircle(
          rect.center + Offset((rnd(i, 9) - .5) * rect.width * .7, (rnd(i, 10) - .5) * rect.height * .4),
          1.2,
          Paint()..color = const Color(0xFFFFE8A3).withValues(alpha: .8 * pile),
        );
      }
    }
  }

  // ثلج يكسيه، وبعدين قالب جليد من تحت لفوق.
  void _ice(Canvas canvas, Offset c, double r, double s) {
    final grow = _seg(s, .2, 1.3);
    final block = Rect.fromCenter(center: c, width: r * 2.35, height: r * 2.4);
    if (grow > 0) {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(block.left - 4, block.bottom - block.height * grow, block.right + 4, block.bottom + 4),
      );
      final rr = RRect.fromRectAndRadius(block, Radius.circular(r * .25));
      canvas.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xCCE0F7FF), const Color(0x8873C8F0), const Color(0xAAB3E5FC)],
          ).createShader(block),
      );
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = Colors.white.withValues(alpha: .85),
      );
      // لمعة وتشققات.
      final shine = Paint()
        ..color = Colors.white.withValues(alpha: .6)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(block.topLeft + Offset(r * .3, r * .35), block.topLeft + Offset(r * .3, r * 1.1), shine);
      canvas.drawLine(block.topLeft + Offset(r * .55, r * .3), block.topLeft + Offset(r * .55, r * .6), shine);
      final crack = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: .7);
      canvas.drawPath(
        Path()
          ..moveTo(block.right - r * .3, block.top + r * .2)
          ..lineTo(block.right - r * .55, block.top + r * .65)
          ..lineTo(block.right - r * .35, block.top + r * .9)
          ..lineTo(block.right - r * .6, block.top + r * 1.3),
        crack,
      );
      canvas.restore();
    }
    // لمعات ثلج.
    final sp = Paint()..color = Colors.white.withValues(alpha: .9 * (1 - _seg(s, 1.4, 2.4) * .6));
    for (var i = 0; i < 7; i++) {
      final k = _seg(s, rnd(i, 1) * .8, 1.6);
      if (k <= 0) continue;
      canvas.drawPath(
        star4(c + Offset((rnd(i, 2) - .5) * r * 2.4, (rnd(i, 3) - .5) * r * 2.4), 2 + 4 * math.sin(k * math.pi)),
        sp,
      );
    }
  }

  // لهب يطلع من تحت ويلفه، والصورة تتفحم وتختفي، ويبقى رماد وجمر.
  void _fire(Canvas canvas, Offset c, double r, double s) {
    final strength = _seg(s, 0, .5) * (1 - _seg(s, 1.5, 2.3));
    if (strength > 0) {
      for (var i = 0; i < 12; i++) {
        final x = c.dx + (rnd(i, 1) - .5) * r * 1.9;
        final h = r * (1 + rnd(i, 2) * 1.2) * strength * (.8 + .2 * math.sin(t * 14 + i));
        final base = Offset(x, c.dy + r * .9);
        final w = r * (.28 + rnd(i, 3) * .2);
        final path = Path()
          ..moveTo(base.dx - w, base.dy)
          ..quadraticBezierTo(base.dx - w * 1.1, base.dy - h * .5, base.dx + math.sin(t * 9 + i) * w * .4, base.dy - h)
          ..quadraticBezierTo(base.dx + w * 1.1, base.dy - h * .5, base.dx + w, base.dy)
          ..close();
        final rect = Rect.fromLTRB(base.dx - w, base.dy - h, base.dx + w, base.dy);
        canvas.drawPath(
          path,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFFFFE082), Color(0xFFFF8A3D), Color(0x00E0314B)],
            ).createShader(rect),
        );
      }
    }
    final ash = _seg(s, 1.2, 2.2);
    if (ash > 0) {
      final rect = Rect.fromCenter(center: c + Offset(0, r * .78), width: r * 1.4 * ash, height: r * .5 * ash);
      canvas.drawOval(
        rect,
        Paint()..shader = const RadialGradient(colors: [Color(0xFF5A5450), Color(0xFF2A2624)]).createShader(rect),
      );
      final ember = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      for (var i = 0; i < 4; i++) {
        ember.color = Color.lerp(const Color(0xFFFF8A3D), const Color(0xFFFFD166), rnd(i, 4))!.withValues(alpha: ash);
        canvas.drawCircle(
          rect.center + Offset((rnd(i, 5) - .5) * rect.width * .6, (rnd(i, 6) - .5) * rect.height * .3),
          1.8,
          ember,
        );
      }
    }
  }

  // صاعقة من فوق، ووميض، وشرار، وبعدين دخان خفيف على صورة متفحمة.
  void _lightning(Canvas canvas, Offset c, double r, double s) {
    final strike = 1 - _seg(s, .1, .45);
    if (s < .45) {
      final top = Offset(c.dx + r * .3, c.dy - r * 4);
      final path = Path()..moveTo(top.dx, top.dy);
      var p = top;
      for (var i = 1; i <= 6; i++) {
        p = Offset(c.dx + (i.isOdd ? -1 : 1) * r * .35 * rnd(i, 7), top.dy + (c.dy - top.dy) * i / 6);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..color = const Color(0xFF9AD8FF).withValues(alpha: .6 * strike)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..color = Colors.white.withValues(alpha: strike),
      );
      canvas.drawCircle(c, r * 1.6, Paint()..color = Colors.white.withValues(alpha: .35 * strike));
    }
    final sp = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final k = _seg(s, .2, .9 + rnd(i, 1) * .5);
      if (k <= 0 || k >= 1) continue;
      final a = rnd(i, 2) * math.pi * 2;
      final from = c + Offset(math.cos(a), math.sin(a)) * r * (.4 + k * 1.3);
      sp
        ..strokeWidth = 2
        ..color = const Color(0xFFFFE066).withValues(alpha: 1 - k);
      canvas.drawLine(from, from + Offset(math.cos(a), math.sin(a)) * 5, sp);
    }
    final smoke = _seg(s, .6, 2.0);
    if (smoke > 0) {
      final p = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      for (var i = 0; i < 4; i++) {
        p.color = const Color(0xFF8E8A99).withValues(alpha: .35 * smoke);
        canvas.drawCircle(c + Offset((i - 1.5) * r * .3, -r * (.6 + smoke * .5 + i * .15)), r * (.25 + i * .05), p);
      }
    }
  }

  // روحه تطلع من الصورة وتطفو فوقها شبح أبيض شفاف.
  void _ghost(Canvas canvas, Offset c, double r, double s) {
    final rise = _seg(s, 0, 1.8);
    final alpha = .2 + .5 * _seg(s, 0, .6);
    final center = c + Offset(math.sin(s * 2) * 3 * rise, -r * 1.1 * rise);
    final w = r * 1.2, h = r * 1.5;
    final body = Path()
      ..moveTo(center.dx - w / 2, center.dy + h / 2)
      ..lineTo(center.dx - w / 2, center.dy - h * .1)
      ..arcToPoint(Offset(center.dx + w / 2, center.dy - h * .1), radius: Radius.circular(w / 2))
      ..lineTo(center.dx + w / 2, center.dy + h / 2);
    for (var i = 0; i < 4; i++) {
      final x0 = center.dx + w / 2 - w * i / 4;
      body.quadraticBezierTo(x0 - w / 8, center.dy + h / 2 - 8, x0 - w / 4, center.dy + h / 2);
    }
    body.close();
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha * .5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(body, Paint()..color = Colors.white.withValues(alpha: alpha * .8));
    final eye = Paint()..color = const Color(0xFF3B2F6B).withValues(alpha: alpha + .2);
    canvas.drawOval(Rect.fromCenter(center: center + Offset(-w * .17, -h * .12), width: 6, height: 8), eye);
    canvas.drawOval(Rect.fromCenter(center: center + Offset(w * .17, -h * .12), width: 6, height: 8), eye);
  }

  // يتحول تمثال ذهب: لمعة تمر عليه ونجوم.
  void _goldFx(Canvas canvas, Offset c, double r, double s) {
    final sweep = _seg(s, 1.2, 1.9);
    if (sweep > 0 && sweep < 1) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
      final x = c.dx - r * 1.4 + sweep * r * 2.8;
      canvas.drawRect(
        Rect.fromLTRB(x - r * .35, c.dy - r, x + r * .35, c.dy + r),
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: .75),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTRB(x - r * .35, 0, x + r * .35, 1)),
      );
      canvas.restore();
    }
    final sp = Paint()..color = const Color(0xFFFFE082);
    for (var i = 0; i < 6; i++) {
      final k = _seg(s, .3 + rnd(i, 1) * 1.2, 1.2 + rnd(i, 2) * 1.2);
      if (k <= 0 || k >= 1) continue;
      canvas.drawPath(
        star4(c + Offset((rnd(i, 3) - .5) * r * 2.2, (rnd(i, 4) - .5) * r * 2.2), 3 + 5 * math.sin(k * math.pi)),
        sp,
      );
    }
    // قاعدة التمثال.
    final base = _seg(s, .6, 1.4);
    if (base > 0) {
      final rect = Rect.fromCenter(center: c + Offset(0, r * 1.05), width: r * 1.6, height: r * .32 * base);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFFFE082), Color(0xFFB8860B)]).createShader(rect),
      );
    }
  }

  // ورد يتطاير منه، ويبقى كم ورقة.
  void _petals(Canvas canvas, Offset c, double r, double s) {
    for (var i = 0; i < 26; i++) {
      final k = _seg(s, rnd(i, 1) * .6, 1.6 + rnd(i, 2) * .6);
      if (k <= 0 || k >= 1) continue;
      final a = -math.pi / 2 + (rnd(i, 3) - .5) * math.pi * 1.6;
      final d = r * (.3 + k * (1.4 + rnd(i, 4)));
      final pos = c + Offset(math.cos(a) * d, math.sin(a) * d + k * k * r * 1.2);
      _petal(
        canvas,
        pos,
        5 + rnd(i, 5) * 3,
        k * 6 + i,
        Color.lerp(const Color(0xFFFF6B8A), const Color(0xFFE0314B), rnd(i, 6))!,
        1 - k * k,
      );
    }
    final rest = _seg(s, 1.0, 1.8);
    for (var i = 0; i < 5; i++) {
      _petal(
        canvas,
        c + Offset((rnd(i, 7) - .5) * r * 1.6, r * (.75 + rnd(i, 8) * .2)),
        6,
        rnd(i, 9) * 6,
        const Color(0xFFE85A7A),
        rest,
      );
    }
  }

  void _petal(Canvas canvas, Offset pos, double size, double angle, Color color, double alpha) {
    if (alpha <= 0) return;
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size, height: size * 1.6),
      Paint()..color = color.withValues(alpha: alpha),
    );
    canvas.restore();
  }

  // سرب خفافيش يطلع منه ويطير بعيد.
  void _bats(Canvas canvas, Offset c, double r, double s) {
    final p = Paint()..color = const Color(0xFF1A1026);
    for (var i = 0; i < 12; i++) {
      final k = _seg(s, rnd(i, 1) * .5, 1.5 + rnd(i, 2) * .6);
      if (k <= 0 || k >= 1) continue;
      final a = -math.pi / 2 + (rnd(i, 3) - .5) * math.pi * 1.5;
      final pos = c + Offset(math.cos(a), math.sin(a)) * r * (.2 + k * (2 + rnd(i, 4)));
      final flap = math.sin(t * 22 + i) * .5 + .5;
      final w = 6 + rnd(i, 5) * 5;
      p.color = const Color(0xFF1A1026).withValues(alpha: 1 - k * .7);
      canvas.drawPath(
        Path()
          ..moveTo(pos.dx, pos.dy)
          ..quadraticBezierTo(pos.dx - w * .6, pos.dy - w * (.2 + flap * .6), pos.dx - w, pos.dy - w * .1)
          ..quadraticBezierTo(pos.dx - w * .6, pos.dy + w * .1, pos.dx, pos.dy + w * .25)
          ..quadraticBezierTo(pos.dx + w * .6, pos.dy + w * .1, pos.dx + w, pos.dy - w * .1)
          ..quadraticBezierTo(pos.dx + w * .6, pos.dy - w * (.2 + flap * .6), pos.dx, pos.dy)
          ..close(),
        p,
      );
    }
    final mist = _seg(s, .6, 1.8);
    if (mist > 0) {
      canvas.drawOval(
        Rect.fromCenter(center: c + Offset(0, r * .7), width: r * 1.8, height: r * .6),
        Paint()
          ..color = const Color(0xFF6B3FA0).withValues(alpha: .35 * mist)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(DeathPainter old) => old.t != t || old.fx != fx;
}

/// لما ينتهي الافكت: هل الصورة نفسها ما عادت تبان (عشان ما نرسم إطارها)؟
bool deathHidesAvatar(DeathFx fx, double t) =>
    t > deathFxStart + 1.8 &&
    (fx == DeathFx.sand || fx == DeathFx.fire || fx == DeathFx.petals || fx == DeathFx.bats || fx == DeathFx.smoke);

/// اللي يختفي (رمل، نار، دخان…) تطلع مكانه جمجمة صغيرة، عشان الكل يعرف إنه انطرد مو إن مكانه فاضي.
class DeathMark extends StatelessWidget {
  const DeathMark({super.key, required this.fx, required this.t, this.size = 26});

  final DeathFx fx;
  final double t;
  final double size;

  @override
  Widget build(BuildContext context) {
    final k = deathHidesAvatar(fx, t) ? _seg(t, deathFxStart + 2.0, deathFxStart + 2.5) : 0.0;
    if (k == 0) return const SizedBox.shrink();
    return Center(
      child: Opacity(
        opacity: k * .9,
        child: Transform.scale(
          scale: .7 + .3 * k,
          child: Gfx('skull', size: size),
        ),
      ),
    );
  }
}

/// معاينة الافكت (المتجر وغرفة التبديل): صورتك على مسندها والافكت يعيد نفسه.
class DeathPreview extends StatelessWidget {
  const DeathPreview({super.key, required this.fx, required this.avatar, this.frame, this.size = 62});

  final DeathFx fx;
  final String avatar;
  final String? frame;
  final double size;

  /// كل دورة: الافكت كامل، ووقفة على اللي يتبقى، ويرجع من البداية.
  static const _loop = 5.4;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 1.7,
    height: size * 1.7,
    child: FxClock(
      builder: (context, time) => AnimatedBuilder(
        animation: time,
        builder: (context, _) {
          final t = FxClock.lite.value ? deathFxStart + deathFxLength : time.value % _loop;
          final look = deathLook(fx, t);
          final cloth = fx == DeathFx.cloth ? ((t - 1.6) / 1.2).clamp(0.0, 1.0) : 0.0;
          Widget avatarView = PlayerAvatar(avatar: avatar, style: frameStyle(frame), size: size, animate: false);
          if (look.matrix != null) {
            avatarView = ColorFiltered(colorFilter: ColorFilter.matrix(look.matrix!), child: avatarView);
          }
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: size * .45,
                child: Cushion(width: size * 1.35, height: size * .93),
              ),
              if (!deathHidesAvatar(fx, t) && cloth < 1)
                Transform.translate(
                  offset: Offset(0, look.dy),
                  child: Opacity(opacity: look.opacity.clamp(0.0, 1.0), child: avatarView),
                ),
              if (cloth > 0) SeatCloth(k: cloth, width: size * 1.42, height: size * 1.32),
              CustomPaint(size: Size(size, size), painter: DeathPainter(fx, t)),
              DeathMark(fx: fx, t: t, size: size * .42),
            ],
          );
        },
      ),
    ),
  );
}
