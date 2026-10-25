import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/shop.dart';

/// ساعة الحركات: تعيد الرسم كل فريم بدون ما تبني الواجهة من جديد (الرسامين يسمعون [time] مباشرة).
class FxClock extends StatefulWidget {
  const FxClock({super.key, required this.builder});

  final Widget Function(BuildContext context, ValueListenable<double> time) builder;

  @override
  State<FxClock> createState() => _FxClockState();
}

class _FxClockState extends State<FxClock> with SingleTickerProviderStateMixin {
  // كل حركة تبدأ من نقطة مختلفة عشان الإطارات المتشابهة ما تتحرك سوا.
  late final double _offset = math.Random().nextDouble() * 100;
  late final ValueNotifier<double> _time = ValueNotifier(_offset);
  late final Ticker _ticker = createTicker((d) => _time.value = _offset + d.inMicroseconds / 1e6)..start();

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _time);
}

/// رقم شبه عشوائي ثابت (نفس المدخل = نفس الرقم) بين ٠ و١.
double rnd(int i, [int salt = 0]) {
  var x = (i * 374761393 + salt * 668265263 + 1013904223) & 0x7fffffff;
  x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff;
  x = x ^ (x >> 16);
  return (x & 0xffff) / 0xffff;
}

double _frac(double x) => x - x.floorToDouble();

/// نجمة بأربع رؤوس (لمعة).
Path star4(Offset c, double r) {
  final s = r * .28;
  return Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx + s * .35, c.dy - s * .35, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx + s * .35, c.dy + s * .35, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - s * .35, c.dy + s * .35, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx - s * .35, c.dy - s * .35, c.dx, c.dy - r)
    ..close();
}

/// تاج صغير مرسوم (فوق إطارات الملوك والأبطال).
void paintCrown(Canvas canvas, Offset bottomCenter, double width, {Color gold = const Color(0xFFFFC93C)}) {
  final w = width, h = width * .62;
  final x = bottomCenter.dx - w / 2, y = bottomCenter.dy - h;
  final path = Path()
    ..moveTo(x, y + h)
    ..lineTo(x + w * .02, y + h * .28)
    ..lineTo(x + w * .26, y + h * .56)
    ..lineTo(x + w * .5, y)
    ..lineTo(x + w * .74, y + h * .56)
    ..lineTo(x + w * .98, y + h * .28)
    ..lineTo(x + w, y + h)
    ..close();
  canvas.drawPath(
    path.shift(Offset(0, h * .08)),
    Paint()
      ..color = Colors.black.withValues(alpha: .35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .04),
  );
  canvas.drawPath(
    path,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(gold, Colors.white, .55)!, gold, Color.lerp(gold, Colors.black, .35)!],
      ).createShader(Rect.fromLTWH(x, y, w, h)),
  );
  canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .045
      ..color = Color.lerp(gold, Colors.black, .55)!,
  );
  final ball = Paint()..color = Color.lerp(gold, Colors.white, .4)!;
  for (final p in [Offset(x + w * .02, y + h * .28), Offset(x + w * .5, y), Offset(x + w * .98, y + h * .28)]) {
    canvas.drawCircle(p, w * .07, ball);
  }
  canvas.drawRect(Rect.fromLTWH(x, y + h * .78, w, h * .22), Paint()..color = Color.lerp(gold, Colors.black, .2)!);
  canvas.drawCircle(Offset(x + w * .5, y + h * .89), w * .075, Paint()..color = const Color(0xFFE53935));
  canvas.drawCircle(Offset(x + w * .24, y + h * .89), w * .055, Paint()..color = const Color(0xFF1E88E5));
  canvas.drawCircle(Offset(x + w * .76, y + h * .89), w * .055, Paint()..color = const Color(0xFF1E88E5));
}

Color _hueShift(Color c, double deg) {
  final hsv = HSVColor.fromColor(c);
  return hsv.withHue((hsv.hue + deg) % 360).toColor();
}

/// ورقة شجر.
Path _leaf(Offset c, double len, double angle) {
  final dx = math.cos(angle), dy = math.sin(angle);
  final nx = -dy, ny = dx;
  final tip = c + Offset(dx, dy) * len / 2, tail = c - Offset(dx, dy) * len / 2;
  return Path()
    ..moveTo(tail.dx, tail.dy)
    ..quadraticBezierTo(c.dx + nx * len * .35, c.dy + ny * len * .35, tip.dx, tip.dy)
    ..quadraticBezierTo(c.dx - nx * len * .35, c.dy - ny * len * .35, tail.dx, tail.dy)
    ..close();
}

/// لهب صغير يطلع باتجاه [angle].
Path _flame(Offset base, double size, double angle) {
  final dx = math.cos(angle), dy = math.sin(angle);
  final nx = -dy, ny = dx;
  final tip = base + Offset(dx, dy) * size * 1.6;
  return Path()
    ..moveTo(base.dx + nx * size * .45, base.dy + ny * size * .45)
    ..quadraticBezierTo(
      base.dx + dx * size * .9 + nx * size * .5,
      base.dy + dy * size * .9 + ny * size * .5,
      tip.dx,
      tip.dy,
    )
    ..quadraticBezierTo(
      base.dx + dx * size * .9 - nx * size * .5,
      base.dy + dy * size * .9 - ny * size * .5,
      base.dx - nx * size * .45,
      base.dy - ny * size * .45,
    )
    ..arcToPoint(Offset(base.dx + nx * size * .45, base.dy + ny * size * .45), radius: Radius.circular(size * .45))
    ..close();
}

/// رسام الإطار: حلقة ملونة وفوقها الحركات (لمعات، نار، برق، مدارات…).
class FramePainter extends CustomPainter {
  FramePainter(this.style, this.time, {required this.ring}) : super(repaint: time);

  final FrameStyle style;
  final ValueListenable<double> time;

  /// سماكة الحلقة.
  final double ring;

  bool has(FrameFx f) => style.fx.contains(f);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final c = size.center(Offset.zero);
    final w = ring;
    final outer = size.shortestSide / 2;
    final mid = outer - w / 2;
    final accent = style.accent ?? Colors.white;
    final glow = style.glow ?? style.colors.first;

    var beat = .5;
    if (has(FrameFx.pulse)) beat = (math.sin(t * math.pi * 2 / 1.5) + 1) / 2;
    if (has(FrameFx.heartbeat)) {
      final p = _frac(t / 1.2);
      beat = math.max(math.exp(-math.pow((p - .1) / .05, 2)), .8 * math.exp(-math.pow((p - .3) / .05, 2))).toDouble();
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(1 + .045 * beat);
      canvas.translate(-c.dx, -c.dy);
    }

    // التوهج
    canvas.drawCircle(
      c,
      mid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 1.6
        ..color = glow.withValues(alpha: .28 + beat * .45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * (1.2 + beat * 1.6)),
    );

    // أشعة الشمس ورا الحلقة
    if (has(FrameFx.rays)) {
      final rays = Paint()..color = accent.withValues(alpha: .55);
      const n = 14;
      for (var i = 0; i < n; i++) {
        final a = t * .35 + i * math.pi * 2 / n;
        final long = i.isEven ? 1.0 : .7;
        final p1 = c + Offset(math.cos(a - .09), math.sin(a - .09)) * (outer - w * .2);
        final p2 = c + Offset(math.cos(a + .09), math.sin(a + .09)) * (outer - w * .2);
        final tip = c + Offset(math.cos(a), math.sin(a)) * (outer + w * (1.4 + long * 1.6));
        canvas.drawPath(
          Path()
            ..moveTo(p1.dx, p1.dy)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(p2.dx, p2.dy)
            ..close(),
          rays,
        );
      }
    }

    // الدخان حول الإطار
    if (has(FrameFx.smoke)) {
      for (var i = 0; i < 7; i++) {
        final a = t * (.25 + rnd(i) * .2) + i * math.pi * 2 / 7;
        final r = outer + w * (.2 + .5 * math.sin(t * .8 + i));
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * r,
          w * (1.3 + rnd(i, 3) * .9),
          Paint()
            ..color = Color.lerp(style.colors.first, accent, rnd(i, 5))!.withValues(alpha: .45)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 1.1),
        );
      }
    }

    // الحلقة نفسها
    final rect = Rect.fromCircle(center: c, radius: outer);
    var colors = style.colors;
    if (has(FrameFx.wave)) colors = [for (final col in colors) _hueShift(col, t * 70)];
    final spin = has(FrameFx.spin) ? t * .9 : 0.0;
    canvas.drawCircle(
      c,
      mid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..shader = SweepGradient(
          colors: [...colors, colors.first],
          transform: GradientRotation(spin),
        ).createShader(rect),
    );
    // حواف تعطيها عمق
    canvas.drawCircle(
      c,
      outer - w,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.8, w * .14)
        ..color = Colors.black.withValues(alpha: .35),
    );
    canvas.drawCircle(
      c,
      outer - w * .12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, w * .12)
        ..color = Colors.white.withValues(alpha: .35),
    );

    // لمعة تمر على الحلقة
    if (has(FrameFx.shine)) {
      final a = _frac(t / 2.6) * math.pi * 2 * 1.4;
      if (a < math.pi * 2) {
        canvas.drawCircle(
          c,
          mid,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 1.05
            ..shader = SweepGradient(
              colors: const [Color(0x00FFFFFF), Color(0xEEFFFFFF), Color(0x00FFFFFF)],
              stops: const [0, .06, .12],
              transform: GradientRotation(a),
            ).createShader(rect),
        );
      }
    }

    // حلقتين تدوران عكس بعض
    if (has(FrameFx.dual)) {
      void dashes(double r, double rot, Color col, double width, int n) {
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..color = col;
        final sweep = math.pi * 2 / n;
        for (var i = 0; i < n; i++) {
          canvas.drawArc(Rect.fromCircle(center: c, radius: r), rot + i * sweep, sweep * .55, false, p);
        }
      }

      dashes(outer + w * .55, t * 1.1, accent.withValues(alpha: .9), math.max(1, w * .3), 10);
      dashes(mid, -t * 1.4, Colors.white.withValues(alpha: .55), math.max(.8, w * .22), 14);
    }

    // نقوش (معينات صغيرة على الحلقة)
    if (has(FrameFx.ornament)) {
      const n = 12;
      final p = Paint()..color = accent;
      final dark = Paint()..color = Colors.black.withValues(alpha: .35);
      for (var i = 0; i < n; i++) {
        final a = t * .3 + i * math.pi * 2 / n;
        final pos = c + Offset(math.cos(a), math.sin(a)) * mid;
        final s = w * .62;
        final d = Path()
          ..moveTo(pos.dx, pos.dy - s)
          ..lineTo(pos.dx + s * .62, pos.dy)
          ..lineTo(pos.dx, pos.dy + s)
          ..lineTo(pos.dx - s * .62, pos.dy)
          ..close();
        canvas.drawPath(d.shift(Offset(0, s * .15)), dark);
        canvas.drawPath(d, p);
        final b = c + Offset(math.cos(a + math.pi / n), math.sin(a + math.pi / n)) * mid;
        canvas.drawCircle(b, w * .16, p);
      }
    }

    // شهاب يلف
    if (has(FrameFx.comet)) {
      final a = t * 2.4;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: mid),
        a - 2.2,
        2.2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 1.15
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            colors: [accent.withValues(alpha: 0), accent.withValues(alpha: .9), Colors.white],
            stops: const [0, .85, 1],
            transform: GradientRotation(a - 2.2),
          ).createShader(rect),
      );
      final head = c + Offset(math.cos(a), math.sin(a)) * mid;
      canvas.drawCircle(
        head,
        w * 1.2,
        Paint()
          ..color = accent.withValues(alpha: .5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w),
      );
      canvas.drawCircle(head, w * .62, Paint()..color = Colors.white);
    }

    // جواهر تدور
    if (has(FrameFx.orbit)) {
      const n = 4;
      for (var i = 0; i < n; i++) {
        final a = t * (.9 + i * .18) + i * math.pi * 2 / n;
        final pos = c + Offset(math.cos(a), math.sin(a)) * mid;
        canvas.drawCircle(
          pos,
          w * 1.05,
          Paint()
            ..color = accent.withValues(alpha: .45)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .7),
        );
        canvas.drawCircle(
          pos,
          w * .62,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-.4, -.4),
              colors: [Colors.white, accent, Color.lerp(accent, Colors.black, .35)!],
            ).createShader(Rect.fromCircle(center: pos, radius: w * .62)),
        );
      }
    }

    // رمل يلف
    if (has(FrameFx.sand)) {
      for (var i = 0; i < 18; i++) {
        final a = t * (1 + rnd(i) * .6) + rnd(i, 1) * math.pi * 2;
        final r = mid + (rnd(i, 2) - .5) * w * 2.4;
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * r,
          math.max(.7, w * (.18 + rnd(i, 3) * .2)),
          Paint()..color = accent.withValues(alpha: .5 + rnd(i, 4) * .5),
        );
      }
    }

    // لهب
    if (has(FrameFx.flame)) {
      const n = 18;
      for (var i = 0; i < n; i++) {
        final life = _frac(t * .95 + rnd(i));
        final a = i * math.pi * 2 / n + math.sin(t * 3 + i) * .08;
        final base = c + Offset(math.cos(a), math.sin(a)) * (outer - w * .3 + life * w * 1.4);
        final col = Color.lerp(const Color(0xFFFFF176), style.colors.first, life)!;
        canvas.drawPath(
          _flame(base, w * (1.25 - life * .9), a),
          Paint()..color = col.withValues(alpha: (1 - life) * .95),
        );
      }
    }

    // برق
    if (has(FrameFx.electric)) {
      final bucket = (t / .11).floor();
      final bolt = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, w * .32)
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white;
      final aura = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, w * .9)
        ..color = accent.withValues(alpha: .55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .7);
      for (var k = 0; k < 3; k++) {
        if (rnd(bucket, k + 40) < .3) continue;
        final start = rnd(bucket, k) * math.pi * 2;
        final path = Path();
        const steps = 7;
        for (var s = 0; s <= steps; s++) {
          final a = start + s * .07;
          final r = mid + (rnd(bucket * 13 + s, k + 7) - .5) * w * 2.4;
          final p = c + Offset(math.cos(a), math.sin(a)) * r;
          s == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, aura);
        canvas.drawPath(path, bolt);
      }
    }

    // نجوم تلمع حول الإطار
    if (has(FrameFx.stars)) {
      const n = 9;
      for (var i = 0; i < n; i++) {
        final a = i * math.pi * 2 / n + .3;
        final tw = (math.sin(t * 2.2 + i * 1.7) + 1) / 2;
        final pos = c + Offset(math.cos(a), math.sin(a)) * (outer + w * .9);
        canvas.drawPath(star4(pos, w * (.5 + tw * .7)), Paint()..color = accent.withValues(alpha: .25 + tw * .75));
      }
    }

    // ثلج
    if (has(FrameFx.snow)) {
      final flake = Paint()
        ..color = Colors.white.withValues(alpha: .9)
        ..strokeWidth = math.max(.7, w * .14)
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 9; i++) {
        final a = t * .3 + rnd(i) * math.pi * 2;
        final r = outer + w * (.1 + rnd(i, 1) * 1.1) + math.sin(t * 1.3 + i) * w * .4;
        final pos = c + Offset(math.cos(a), math.sin(a)) * r;
        final s = w * (.35 + rnd(i, 2) * .3);
        for (var k = 0; k < 3; k++) {
          final ang = k * math.pi / 3 + t;
          final d = Offset(math.cos(ang), math.sin(ang)) * s;
          canvas.drawLine(pos - d, pos + d, flake);
        }
      }
    }

    // أوراق تطير
    if (has(FrameFx.leaves)) {
      for (var i = 0; i < 6; i++) {
        final a = t * .5 + i * math.pi * 2 / 6;
        final r = outer + w * (.3 + .4 * math.sin(t * 1.5 + i));
        final pos = c + Offset(math.cos(a), math.sin(a)) * r;
        final col = Color.lerp(accent, style.colors.first, rnd(i))!;
        canvas.drawPath(_leaf(pos, w * 1.6, a + t * 2 + i), Paint()..color = col);
      }
    }

    // لمعات تدور
    if (has(FrameFx.sparkle)) {
      for (var i = 0; i < 3; i++) {
        final a = t * .8 + i * math.pi * 2 / 3;
        final tw = math.sin(t * 3 + i * 2).abs();
        final pos = c + Offset(math.cos(a), math.sin(a)) * (outer + w * .1);
        final col = Color.lerp(accent, Colors.white, .5)!;
        canvas.drawPath(
          star4(pos, w * (1 + tw * 1.1)),
          Paint()
            ..color = col.withValues(alpha: .4)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .5),
        );
        canvas.drawPath(star4(pos, w * (.8 + tw * .9)), Paint()..color = col);
      }
    }

    if (has(FrameFx.crown)) paintCrown(canvas, Offset(c.dx, c.dy - outer + w * .8), outer * .78);

    if (has(FrameFx.heartbeat)) canvas.restore();
  }

  @override
  bool shouldRepaint(FramePainter old) => old.style != style || old.ring != ring;
}

/// خلفية الشخصيات المميزة: ألوان تضوي وتتحرك ورا الشخصية.
class AvatarBgPainter extends CustomPainter {
  AvatarBgPainter(this.art, this.time) : super(repaint: time);

  final AvatarArt art;
  final ValueListenable<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final rect = Offset.zero & size;
    final a = art.colors.first, b = art.colors.last;
    final light = Color.lerp(a, Colors.white, .45)!;
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawRect(
      rect,
      Paint()..shader = RadialGradient(center: const Alignment(0, -.25), radius: .9, colors: [a, b]).createShader(rect),
    );
    switch (art.fx) {
      case AvatarFx.aurora:
        for (var i = 0; i < 3; i++) {
          final ang = t * (.5 + i * .2) + i * 2.1;
          canvas.drawCircle(
            c + Offset(math.cos(ang), math.sin(ang)) * r * .45,
            r * .55,
            Paint()
              ..color = _hueShift(light, i * 50.0).withValues(alpha: .55)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .35),
          );
        }
      case AvatarFx.rays:
        final p = Paint()..color = Colors.white.withValues(alpha: .13);
        const n = 12;
        for (var i = 0; i < n; i++) {
          final ang = t * .4 + i * math.pi * 2 / n;
          final p1 = c + Offset(math.cos(ang - .12), math.sin(ang - .12)) * r * 1.5;
          final p2 = c + Offset(math.cos(ang + .12), math.sin(ang + .12)) * r * 1.5;
          canvas.drawPath(
            Path()
              ..moveTo(c.dx, c.dy)
              ..lineTo(p1.dx, p1.dy)
              ..lineTo(p2.dx, p2.dy)
              ..close(),
            p,
          );
        }
        canvas.drawCircle(
          c,
          r * .5,
          Paint()
            ..color = light.withValues(alpha: .35)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .3),
        );
      case AvatarFx.sparkle:
        for (var i = 0; i < 8; i++) {
          final tw = (math.sin(t * 2.5 + i * 1.9) + 1) / 2;
          final pos = Offset(rnd(i, 11) * size.width, rnd(i, 12) * size.height * .8);
          canvas.drawPath(
            star4(pos, r * (.04 + tw * .07)),
            Paint()..color = Colors.white.withValues(alpha: .2 + tw * .8),
          );
        }
      case AvatarFx.embers:
        for (var i = 0; i < 14; i++) {
          final life = _frac(t * (.25 + rnd(i) * .2) + rnd(i, 1));
          final pos = Offset(rnd(i, 2) * size.width + math.sin(t * 2 + i) * r * .05, size.height * (1.05 - life * 1.1));
          canvas.drawCircle(
            pos,
            r * (.025 + rnd(i, 3) * .03),
            Paint()..color = light.withValues(alpha: (1 - life) * .95),
          );
        }
      case AvatarFx.pulse:
        final beat = (math.sin(t * math.pi * 2 / 1.8) + 1) / 2;
        canvas.drawCircle(
          c,
          r * (.45 + beat * .25),
          Paint()
            ..color = light.withValues(alpha: .25 + beat * .35)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .35),
        );
      case AvatarFx.smoke:
        for (var i = 0; i < 5; i++) {
          final ang = t * (.2 + rnd(i) * .2) + i * 1.3;
          canvas.drawCircle(
            c + Offset(math.cos(ang) * r * .6, math.sin(ang * 1.3) * r * .5),
            r * (.35 + rnd(i, 4) * .2),
            Paint()
              ..color = light.withValues(alpha: .28)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .25),
          );
        }
      case AvatarFx.stars:
        for (var i = 0; i < 22; i++) {
          final tw = (math.sin(t * 1.8 + i * 2.3) + 1) / 2;
          canvas.drawCircle(
            Offset(rnd(i, 21) * size.width, rnd(i, 22) * size.height * .85),
            r * (.012 + rnd(i, 23) * .02),
            Paint()..color = Colors.white.withValues(alpha: .2 + tw * .8),
          );
        }
        final tw = (math.sin(t * 1.3) + 1) / 2;
        canvas.drawPath(
          star4(Offset(size.width * .2, size.height * .22), r * (.06 + tw * .04)),
          Paint()..color = Colors.white,
        );
      case AvatarFx.bubbles:
        final ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(.8, r * .02)
          ..color = Colors.white.withValues(alpha: .6);
        for (var i = 0; i < 9; i++) {
          final life = _frac(t * (.18 + rnd(i) * .15) + rnd(i, 1));
          final pos = Offset(rnd(i, 2) * size.width + math.sin(t * 2 + i) * r * .06, size.height * (1.1 - life * 1.2));
          canvas.drawCircle(pos, r * (.04 + rnd(i, 3) * .06), ring);
        }
    }
    // ظل خفيف تحت عشان الشخصية تبان
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .6, size.width, size.height * .4),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: .25)],
        ).createShader(Rect.fromLTWH(0, size.height * .6, size.width, size.height * .4)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(AvatarBgPainter old) => old.art != art;
}

/// شكل فقاعة الكلام: مستطيل مدوّر وتحته ذيل صغير.
Path bubblePath(Size size, {double tail = 7}) {
  final body = Rect.fromLTWH(0, 0, size.width, size.height - tail);
  final r = math.min(body.height / 2, 16.0);
  final cx = size.width / 2;
  return Path()
    ..addRRect(RRect.fromRectAndRadius(body, Radius.circular(r)))
    ..moveTo(cx - tail, body.bottom - 1)
    ..lineTo(cx, size.height)
    ..lineTo(cx + tail, body.bottom - 1)
    ..close();
}

/// رسام فقاعة الكلام بحركاتها (لمعة، نار، ثلج، نيون…).
class BubblePainter extends CustomPainter {
  BubblePainter(this.style, this.time, {this.tail = 7}) : super(repaint: time);

  final BubbleStyle style;
  final ValueListenable<double> time;
  final double tail;

  bool has(BubbleFx f) => style.fx.contains(f);

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final path = bubblePath(size, tail: tail);
    final body = Rect.fromLTWH(0, 0, size.width, size.height - tail);
    final h = body.height;
    final accent = style.border;

    // توهج حول الفقاعة
    if (has(BubbleFx.glow) || has(BubbleFx.neon)) {
      final beat = has(BubbleFx.neon)
          ? (rnd((t / .09).floor(), 3) < .12 ? .2 : 1.0)
          : (math.sin(t * math.pi * 2 / 1.6) + 1) / 2;
      canvas.drawPath(
        path,
        Paint()
          ..color = accent.withValues(alpha: .25 + beat * .45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 + beat * 6),
      );
    } else {
      canvas.drawPath(
        path.shift(const Offset(0, 3)),
        Paint()
          ..color = Colors.black.withValues(alpha: .4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // بخار فوق (القهوة)
    if (has(BubbleFx.steam)) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .55);
      for (var i = 0; i < 3; i++) {
        final life = _frac(t * .6 + i / 3);
        final x = size.width * (.3 + i * .2);
        final y0 = -life * h * .9;
        final s = Path()..moveTo(x, y0 + 2);
        for (var k = 1; k <= 4; k++) {
          s.lineTo(x + math.sin(t * 3 + k + i) * 3, y0 - k * 3.2);
        }
        canvas.drawPath(s, p..color = Colors.white.withValues(alpha: (1 - life) * .6));
      }
    }

    // نار فوق الفقاعة
    if (has(BubbleFx.flame)) {
      final n = (size.width / 11).floor().clamp(4, 14);
      for (var i = 0; i < n; i++) {
        final life = _frac(t * 1.2 + rnd(i));
        final x = 6 + (size.width - 12) * (i + .5) / n;
        final col = Color.lerp(const Color(0xFFFFF59D), const Color(0xFFFF6D00), life)!;
        canvas.drawPath(
          _flame(Offset(x, 3 - life * 4), 5.5 * (1.2 - life * .8), -math.pi / 2),
          Paint()..color = col.withValues(alpha: (1 - life)),
        );
      }
    }

    // الخلفية
    final bg = style.bg;
    final Shader shader = has(BubbleFx.spin)
        ? SweepGradient(
            colors: [...bg, bg.first],
            transform: GradientRotation(t * .9),
          ).createShader(Rect.fromCircle(center: body.center, radius: body.width))
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bg.length > 1 ? bg : [bg.first, bg.first],
          ).createShader(body);
    canvas.drawPath(path, Paint()..shader = shader);

    canvas.save();
    canvas.clipPath(path);
    // لمعة خفيفة فوق
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, h * .45), Paint()..color = Colors.white.withValues(alpha: .12));
    if (has(BubbleFx.shimmer)) {
      // شريط ضو مايل يمر على الفقاعة كل شوي.
      final x = _frac(t / 2.2) * (size.width + 90) - 45;
      final band = Rect.fromLTWH(x - 22, -4, 44, h + 8);
      canvas.save();
      canvas.translate(band.center.dx, band.center.dy);
      canvas.transform(Matrix4.skewX(-.35).storage);
      canvas.translate(-band.center.dx, -band.center.dy);
      canvas.drawRect(
        band,
        Paint()
          ..shader = const LinearGradient(colors: [Color(0x00FFFFFF), Color(0x99FFFFFF), Color(0x00FFFFFF)])
              .createShader(band),
      );
      canvas.restore();
    }
    if (has(BubbleFx.stars) || has(BubbleFx.sparkle)) {
      final n = has(BubbleFx.stars) ? 10 : 4;
      for (var i = 0; i < n; i++) {
        final tw = (math.sin(t * 2.4 + i * 1.7) + 1) / 2;
        final pos = Offset(rnd(i, 31) * size.width, rnd(i, 32) * h);
        if (has(BubbleFx.sparkle)) {
          canvas.drawPath(star4(pos, 2 + tw * 3), Paint()..color = Colors.white.withValues(alpha: .3 + tw * .7));
        } else {
          canvas.drawCircle(pos, .8 + tw * .9, Paint()..color = Colors.white.withValues(alpha: .25 + tw * .75));
        }
      }
    }
    if (has(BubbleFx.snow)) {
      for (var i = 0; i < 9; i++) {
        final y = _frac(t * (.25 + rnd(i) * .2) + rnd(i, 1)) * (h + 6) - 3;
        final x = rnd(i, 2) * size.width + math.sin(t * 1.5 + i) * 4;
        canvas.drawCircle(Offset(x, y), 1.2 + rnd(i, 3) * 1.2, Paint()..color = Colors.white.withValues(alpha: .9));
      }
    }
    if (has(BubbleFx.bubbles)) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .7);
      for (var i = 0; i < 7; i++) {
        final y = h + 4 - _frac(t * (.3 + rnd(i) * .3) + rnd(i, 1)) * (h + 8);
        final x = rnd(i, 2) * size.width + math.sin(t * 2 + i) * 3;
        canvas.drawCircle(Offset(x, y), 1.5 + rnd(i, 3) * 2, ring);
      }
    }
    if (has(BubbleFx.sand)) {
      for (var i = 0; i < 14; i++) {
        final x = _frac(t * (.12 + rnd(i) * .1) + rnd(i, 1)) * (size.width + 10) - 5;
        final y = rnd(i, 2) * h + math.sin(t * 2 + i) * 2;
        canvas.drawCircle(Offset(x, y), .8 + rnd(i, 3), Paint()..color = const Color(0xFFFFF3D6).withValues(alpha: .8));
      }
    }
    if (has(BubbleFx.leaves)) {
      for (var i = 0; i < 4; i++) {
        final x = _frac(t * (.1 + rnd(i) * .08) + rnd(i, 1)) * (size.width + 16) - 8;
        final y = h * (.2 + rnd(i, 2) * .6) + math.sin(t * 1.6 + i) * 3;
        canvas.drawPath(
          _leaf(Offset(x, y), 7, t * 2 + i),
          Paint()..color = const Color(0xFFA7F3D0).withValues(alpha: .75),
        );
      }
    }
    if (has(BubbleFx.smoke)) {
      for (var i = 0; i < 4; i++) {
        final x = _frac(t * .08 + rnd(i)) * (size.width + 30) - 15;
        canvas.drawCircle(
          Offset(x, h * (.3 + rnd(i, 2) * .5)),
          h * .45,
          Paint()
            ..color = Colors.black.withValues(alpha: .25)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .3),
        );
      }
    }
    canvas.restore();

    // الحافة
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = has(BubbleFx.rainbow) ? 2.6 : 1.6;
    if (has(BubbleFx.rainbow)) {
      border.shader = SweepGradient(
        colors: const [
          Color(0xFFFF1744),
          Color(0xFFFFEA00),
          Color(0xFF00E676),
          Color(0xFF00B0FF),
          Color(0xFFD500F9),
          Color(0xFFFF1744),
        ],
        transform: GradientRotation(t * 1.6),
      ).createShader(Rect.fromCircle(center: body.center, radius: body.width / 2));
    } else if (has(BubbleFx.neon)) {
      final flick = rnd((t / .09).floor(), 3) < .12 ? .25 : 1.0;
      border
        ..color = accent.withValues(alpha: flick)
        ..strokeWidth = 2;
    } else {
      border.color = accent;
    }
    canvas.drawPath(path, border);

    // برق على الحواف
    if (has(BubbleFx.electric)) {
      final bucket = (t / .12).floor();
      if (rnd(bucket, 9) > .25) {
        final edge = rnd(bucket, 1) < .5 ? 0.0 : h;
        final x0 = rnd(bucket, 2) * size.width * .7;
        final bolt = Path()..moveTo(x0, edge);
        for (var k = 1; k <= 6; k++) {
          bolt.lineTo(x0 + k * 6.0, edge + (rnd(bucket * 7 + k, 4) - .5) * 8);
        }
        canvas.drawPath(
          bolt,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = accent.withValues(alpha: .6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        canvas.drawPath(
          bolt,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BubblePainter old) => old.style != style;
}
