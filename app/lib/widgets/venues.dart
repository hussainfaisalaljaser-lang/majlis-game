import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'fx.dart';
import 'majlis.dart' show lanternFlicker;

/// المكان اللي تنلعب فيه الطاولة: كل مستوى له طابعه، والروم الخاص والتدريب بالمجلس العادي.
/// كل مكان رسمتين: ثابتة تنرسم مرة (الجدران والسما والأرضية)، وطبقة حركة خفيفة (نار، أضواء، غبار ذهب).
/// الطاولة تغطي النص، فالطابع يبان فوق وعلى الجنبين.
enum Venue { majlis, desert, city, palace, kings, vip }

/// مكان الطاولة حسب مستواها (models/table_tier.dart).
Venue venueOf(String? tierId) => switch (tierId) {
  'starter' => Venue.desert,
  'city' => Venue.city,
  'palace' => Venue.palace,
  'kings' => Venue.kings,
  'vip' => Venue.vip,
  _ => Venue.majlis,
};

/// الرسمة الثابتة للمكان (ما عدا المجلس العادي).
CustomPainter venueBackdrop(Venue v) => switch (v) {
  Venue.desert => const _DesertBackdrop(),
  Venue.city => const _CityBackdrop(),
  Venue.palace => const _PalaceBackdrop(),
  Venue.kings => const _KingsBackdrop(),
  Venue.vip || Venue.majlis => const _VipBackdrop(),
};

/// طبقة الحركة للمكان. [tension] تحمّر النار والأضواء الدافية.
CustomPainter venueLights(Venue v, ValueListenable<double> time, double tension) => switch (v) {
  Venue.desert => _DesertLights(time, tension),
  Venue.city => _CityLights(time, tension),
  Venue.palace => _PalaceLights(time, tension),
  Venue.kings => _KingsLights(time, tension),
  Venue.vip || Venue.majlis => _VipLights(time, tension),
};

double _frac(double x) => x - x.floorToDouble();

Paint _fill(Color c) => Paint()..color = c;

Paint _grad(Rect r, List<Color> colors, {List<double>? stops, bool vertical = true}) =>
    Paint()
      ..shader = LinearGradient(
        begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
        end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
        colors: colors,
        stops: stops,
      ).createShader(r);

/// هالة ضو دايرية.
void _glow(Canvas canvas, Offset c, double r, Color color, double alpha) {
  if (alpha <= 0) return;
  canvas.drawCircle(
    c,
    r,
    Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r)),
  );
}

/// هلال.
void _crescent(Canvas canvas, Offset c, double r, Color color) {
  canvas.drawPath(
    Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()..addOval(Rect.fromCircle(center: c + Offset(r * .45, -r * .25), radius: r * .85)),
    ),
    _fill(color),
  );
}

/// لهب نار يتمايل: [h] طوله، و[t] الوقت.
void _flame(Canvas canvas, Offset base, double w, double h, double t, int seed, Color hot, Color cool) {
  final sway = math.sin(t * 7 + seed) * w * .25;
  final tall = h * (.85 + .15 * math.sin(t * 11 + seed * 2));
  final path = Path()
    ..moveTo(base.dx - w / 2, base.dy)
    ..quadraticBezierTo(base.dx - w * .55, base.dy - tall * .5, base.dx + sway, base.dy - tall)
    ..quadraticBezierTo(base.dx + w * .55, base.dy - tall * .5, base.dx + w / 2, base.dy)
    ..close();
  canvas.drawPath(path, _grad(Rect.fromLTWH(base.dx - w, base.dy - tall, w * 2, tall), [cool, hot]));
}

/// شعلة: هالة ولهبين.
void _torchFire(Canvas canvas, Offset base, double s, double t, int seed, double tension) {
  final hot = Color.lerp(const Color(0xFFFFE08A), const Color(0xFFFF8A8A), tension)!;
  final cool = Color.lerp(const Color(0xFFFF5A1F), const Color(0xFFB91C1C), tension)!;
  _glow(canvas, base - Offset(0, 10 * s), 60 * s, cool, .32 * lanternFlicker(t, seed, .25));
  _flame(canvas, base, 14 * s, 30 * s, t, seed, cool, cool.withValues(alpha: .9));
  _flame(canvas, base + Offset(0, -2 * s), 8 * s, 20 * s, t * 1.3, seed + 3, hot, cool);
}

// ───────── مبتدئ: بيت شعر في البر

class _DesertBackdrop extends CustomPainter {
  const _DesertBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final horizon = h * .6;
    // سما الليل
    final sky = Rect.fromLTWH(0, 0, w, horizon);
    canvas.drawRect(
      sky,
      _grad(sky, const [Color(0xFF060A20), Color(0xFF17163C), Color(0xFF3A2647)], stops: const [0, .6, 1]),
    );
    for (var k = 0; k < 110; k++) {
      canvas.drawCircle(
        Offset(rnd(k, 1) * w, rnd(k, 2) * horizon * .88),
        .5 + rnd(k, 3) * 1.1,
        _fill(Colors.white.withValues(alpha: .25 + .6 * rnd(k, 4))),
      );
    }
    final moon = Offset(w * .74, h * .2);
    _glow(canvas, moon, h * .16, const Color(0xFFFDE68A), .14);
    _crescent(canvas, moon, h * .045, const Color(0xFFFDE68A));
    // كثبان بعيدة
    final far = Path()..moveTo(0, horizon - h * .06);
    for (var i = 0; i < 4; i++) {
      final x0 = w * i / 4, x1 = w * (i + 1) / 4;
      far.cubicTo(
        x0 + w * .08,
        horizon - h * (.13 + .04 * (i % 2)),
        x1 - w * .1,
        horizon - h * .02,
        x1,
        horizon - h * .06,
      );
    }
    far
      ..lineTo(w, horizon)
      ..lineTo(0, horizon)
      ..close();
    canvas.drawPath(far, _fill(const Color(0xFF2A1F3E)));
    final near = Path()..moveTo(0, horizon - h * .02);
    near
      ..cubicTo(w * .2, horizon - h * .09, w * .35, horizon + h * .01, w * .55, horizon - h * .04)
      ..cubicTo(w * .7, horizon - h * .08, w * .85, horizon, w, horizon - h * .03)
      ..lineTo(w, horizon + 2)
      ..lineTo(0, horizon + 2)
      ..close();
    canvas.drawPath(near, _fill(const Color(0xFF4A3024)));
    // نخل بعيد
    for (final (x, s) in [(w * .2, 1.0), (w * .26, .75), (w * .8, .9)]) {
      _palm(canvas, Offset(x, horizon - h * .03), h * .2 * s);
    }
    // الرمل
    final sand = Rect.fromLTWH(0, horizon, w, h - horizon);
    canvas.drawRect(sand, _grad(sand, const [Color(0xFF7A5532), Color(0xFF4E321B), Color(0xFF2A1A0E)]));
    final ripple = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.black.withValues(alpha: .14);
    for (var y = horizon + 12; y < h; y += 15) {
      final p = Path()..moveTo(0, y);
      for (var x = 0.0; x < w; x += 60) {
        p.quadraticBezierTo(x + 30, y + 4, x + 60, y);
      }
      canvas.drawPath(p, ripple);
    }
    // بيت الشعر: السقف المنسوج
    final roofEdge = h * .16;
    final roof = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, roofEdge);
    const sags = 4;
    for (var i = sags; i > 0; i--) {
      final x0 = w * i / sags, x1 = w * (i - 1) / sags;
      roof.quadraticBezierTo((x0 + x1) / 2, roofEdge * 1.45, x1, roofEdge);
    }
    roof.close();
    canvas.drawPath(roof, _fill(const Color(0xFF16100C)));
    canvas.save();
    canvas.clipPath(roof);
    final weave = Paint()
      ..color = const Color(0xFF2B2018)
      ..strokeWidth = 1.4;
    for (var y = 3.0; y < roofEdge * 1.5; y += 5) {
      canvas.drawLine(Offset(0, y), Offset(w, y), weave);
    }
    canvas.restore();
    // حافة السقف بنقش السدو
    _saduAlong(canvas, roof, w, roofEdge);
    // الجدران الجانبية (ستاير السدو)
    final side = w * .09;
    for (final left in [true, false]) {
      final r = Rect.fromLTWH(left ? 0 : w - side, 0, side, horizon + h * .06);
      canvas.drawRect(r, _fill(const Color(0xFF1A120D)));
      _saduColumn(canvas, Rect.fromLTWH(left ? side - 18 : w - side + 4, roofEdge * .6, 14, r.height - roofEdge * .6));
      _saduColumn(canvas, Rect.fromLTWH(left ? 6 : w - 20, roofEdge * .6, 14, r.height - roofEdge * .6));
    }
    // أعمدة الخيمة على الجنبين
    for (final x in [w * .13, w * .87]) {
      final pole = Rect.fromLTWH(x - 3.5, roofEdge * .9, 7, horizon + h * .1 - roofEdge * .9);
      canvas.drawRect(pole, _grad(pole, const [Color(0xFF8A5A2B), Color(0xFF4A2E14)], vertical: false));
    }
    // مساند على الأطراف
    for (final left in [true, false]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(left ? side - 6 : w - side - 62, horizon + h * .04, 68, h * .1),
        const Radius.circular(10),
      );
      canvas.drawRRect(r, _grad(r.outerRect, const [Color(0xFF9F1239), Color(0xFF4C0519)]));
      canvas.drawRRect(
        r.deflate(4),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = AppColors.gold.withValues(alpha: .6),
      );
    }
  }

  void _palm(Canvas canvas, Offset base, double hgt) {
    final dark = Paint()
      ..color = const Color(0xFF150F22)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final top = base + Offset(hgt * .12, -hgt);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(base.dx + hgt * .02, base.dy - hgt * .5, top.dx, top.dy),
      dark..strokeWidth = hgt * .05,
    );
    for (var k = 0; k < 7; k++) {
      final a = -math.pi / 2 + (k - 3) * .5;
      final end = top + Offset(math.cos(a), math.sin(a) + .6) * hgt * .38;
      canvas.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(top.dx + math.cos(a) * hgt * .25, top.dy - hgt * .12, end.dx, end.dy),
        dark..strokeWidth = hgt * .025,
      );
    }
  }

  /// شريط سدو (مثلثات أحمر وأبيض وأسود) على طرف السقف.
  void _saduAlong(Canvas canvas, Path roof, double w, double edge) {
    canvas.save();
    canvas.clipPath(roof);
    final y = edge - 2;
    canvas.drawRect(Rect.fromLTWH(0, y - 10, w, 13), _fill(const Color(0xFF8E1B1B)));
    for (var x = 0.0; x < w; x += 12) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + 2)
          ..lineTo(x + 6, y - 8)
          ..lineTo(x + 12, y + 2)
          ..close(),
        _fill(((x / 12).round()).isEven ? const Color(0xFFF2E6D0) : const Color(0xFF111111)),
      );
    }
    canvas.restore();
  }

  /// عمود سدو بالطول: معينات ملونة.
  void _saduColumn(Canvas canvas, Rect r) {
    canvas.drawRect(r, _fill(const Color(0xFF7A1515)));
    const colors = [Color(0xFFF2E6D0), Color(0xFF111111), Color(0xFFE8A33D)];
    var k = 0;
    for (var y = r.top + 4; y < r.bottom - 8; y += 14) {
      canvas.drawPath(
        Path()
          ..moveTo(r.center.dx, y)
          ..lineTo(r.right - 2, y + 7)
          ..lineTo(r.center.dx, y + 14)
          ..lineTo(r.left + 2, y + 7)
          ..close(),
        _fill(colors[k++ % colors.length]),
      );
    }
  }

  @override
  bool shouldRepaint(_DesertBackdrop old) => false;
}

class _DesertLights extends CustomPainter {
  _DesertLights(this.time, this.tension) : super(repaint: time);

  final ValueListenable<double> time;
  final double tension;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final w = size.width, h = size.height;
    final s = (h / 400).clamp(.75, 1.4);
    // نجوم ترمش
    for (var k = 0; k < 12; k++) {
      final tw = .5 + .5 * math.sin(t * 2.2 + k * 1.7);
      canvas.drawPath(
        star4(Offset(rnd(k, 31) * w, rnd(k, 32) * h * .5), (1.5 + 2 * tw) * s),
        _fill(Colors.white.withValues(alpha: .3 + .6 * tw)),
      );
    }
    // فانوس على كل عمود
    final warm = Color.lerp(const Color(0xFFFFC857), const Color(0xFFFF3B3B), tension)!;
    for (final (i, x) in [w * .13, w * .87].indexed) {
      final light = lanternFlicker(t, i + 4, .12 + .5 * tension);
      final c = Offset(x, h * .3);
      _glow(canvas, c, 70 * s, warm, .34 * light);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.scale(s);
      canvas.rotate(.05 * math.sin(t * 1.4 + i));
      canvas.drawLine(
        const Offset(0, -24),
        const Offset(0, -14),
        Paint()
          ..color = const Color(0xFF6B4A2B)
          ..strokeWidth = 1.5,
      );
      canvas.drawArc(
        Rect.fromCenter(center: const Offset(0, -10), width: 18, height: 12),
        math.pi,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFF8A6A2A),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 16, height: 20),
        _fill(Color.lerp(const Color(0xFF3B2A1A), Color.lerp(warm, Colors.white, .4)!, light)!),
      );
      canvas.drawRect(
        Rect.fromCenter(center: const Offset(0, -10), width: 14, height: 3),
        _fill(const Color(0xFF8A6A2A)),
      );
      canvas.drawRect(
        Rect.fromCenter(center: const Offset(0, 11), width: 16, height: 3),
        _fill(const Color(0xFF8A6A2A)),
      );
      canvas.restore();
    }
    // نار المخيم
    final fire = Offset(w * .055, h * .7);
    canvas.drawOval(
      Rect.fromCenter(center: fire + Offset(0, 4 * s), width: 46 * s, height: 12 * s),
      _fill(const Color(0xFF2A1A10)),
    );
    final log = Paint()
      ..color = const Color(0xFF5A3A1E)
      ..strokeWidth = 5 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(fire + Offset(-16 * s, 4 * s), fire + Offset(14 * s, -4 * s), log);
    canvas.drawLine(fire + Offset(16 * s, 4 * s), fire + Offset(-14 * s, -4 * s), log);
    _glow(
      canvas,
      fire + Offset(0, -12 * s),
      85 * s,
      Color.lerp(const Color(0xFFFF7A1A), const Color(0xFFFF2A2A), tension)!,
      .35 * lanternFlicker(t, 9, .3),
    );
    for (var k = 0; k < 3; k++) {
      _flame(
        canvas,
        fire + Offset((k - 1) * 7 * s, 0),
        12 * s,
        (26 + 8 * (1 - (k - 1).abs())) * s,
        t,
        k,
        const Color(0xFFFFE08A),
        Color.lerp(const Color(0xFFFF5A1F), const Color(0xFFB91C1C), tension)!,
      );
    }
    for (var k = 0; k < 8; k++) {
      final q = _frac(t * .45 + k / 8);
      canvas.drawCircle(
        fire + Offset(math.sin(q * 7 + k) * 10 * s, -10 * s - q * 70 * s),
        1.4 * s,
        _fill(const Color(0xFFFFC857).withValues(alpha: 1 - q)),
      );
    }
  }

  @override
  bool shouldRepaint(_DesertLights old) => old.tension != tension || old.time != time;
}

// ───────── المدينة: مجلس حديث يطل على الأبراج

/// أبراج المدينة (نفسها للرسمة الثابتة وأضواء الشبابيك).
List<Rect> _towers(Size size) {
  final w = size.width, h = size.height;
  final ground = h * .6;
  final out = <Rect>[];
  var x = w * .02;
  var k = 0;
  while (x < w * .98) {
    final tw = w * (.03 + rnd(k, 41) * .045);
    final th = h * (.12 + rnd(k, 42) * .3);
    out.add(Rect.fromLTWH(x, ground - th, tw, th));
    x += tw + w * (.004 + rnd(k, 43) * .01);
    k++;
  }
  return out;
}

class _CityBackdrop extends CustomPainter {
  const _CityBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final ground = h * .6;
    // سما المدينة بالليل
    final sky = Rect.fromLTWH(0, 0, w, ground);
    canvas.drawRect(
      sky,
      _grad(sky, const [Color(0xFF0B0F2A), Color(0xFF26215A), Color(0xFF5A2E6E)], stops: const [0, .55, 1]),
    );
    for (var k = 0; k < 30; k++) {
      canvas.drawCircle(
        Offset(rnd(k, 51) * w, rnd(k, 52) * h * .3),
        .6 + rnd(k, 53),
        _fill(Colors.white.withValues(alpha: .35)),
      );
    }
    // برج طويل (معلم) بالنص
    final spire = Path()
      ..moveTo(w * .545, ground)
      ..lineTo(w * .552, h * .14)
      ..lineTo(w * .555, h * .02)
      ..lineTo(w * .558, h * .14)
      ..lineTo(w * .565, ground)
      ..close();
    canvas.drawPath(
      spire,
      _grad(Rect.fromLTWH(w * .54, 0, w * .03, ground), const [Color(0xFF2A2F5A), Color(0xFF12152E)], vertical: false),
    );
    // الأبراج وشبابيكها
    for (final (i, r) in _towers(size).indexed) {
      canvas.drawRect(r, _grad(r, [const Color(0xFF1B2045), const Color(0xFF0E1128)]));
      if (rnd(i, 44) > .6) {
        canvas.drawPath(
          Path()
            ..moveTo(r.left, r.top)
            ..lineTo(r.center.dx, r.top - r.width * .5)
            ..lineTo(r.right, r.top)
            ..close(),
          _fill(const Color(0xFF1B2045)),
        );
      }
      final lit = Paint()..color = const Color(0xFFFFD98A).withValues(alpha: .55);
      for (var y = r.top + 5; y < r.bottom - 4; y += 7) {
        for (var x = r.left + 3; x < r.right - 3; x += 6) {
          if (rnd((x * 7 + y * 13).round() + i * 1000, 45) > .62) canvas.drawRect(Rect.fromLTWH(x, y, 2.5, 3), lit);
        }
      }
    }
    // جدار المجلس: سقف بإضاءة مخفية، وإطارات الشبابيك الكبيرة
    final ceiling = Rect.fromLTWH(0, 0, w, h * .07);
    canvas.drawRect(ceiling, _grad(ceiling, const [Color(0xFF0A0C16), Color(0xFF151827)]));
    for (var x = w * .08; x < w; x += w * .14) {
      _glow(canvas, Offset(x, h * .07), 26, const Color(0xFFFFE6B0), .35);
      canvas.drawCircle(Offset(x, h * .065), 2.4, _fill(const Color(0xFFFFF4D6)));
    }
    final frame = _fill(const Color(0xFF0B0D16));
    for (var x = 0.0; x <= w; x += w / 7) {
      canvas.drawRect(Rect.fromLTWH(x - 3, h * .07, 6, ground - h * .07), frame);
    }
    canvas.drawRect(Rect.fromLTWH(0, h * .07, w, 4), frame);
    // انعكاس على الزجاج
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, h * .07, w, ground - h * .07));
    final shine = Paint()..color = Colors.white.withValues(alpha: .05);
    for (var x = -w * .2; x < w; x += w * .28) {
      canvas.drawPath(
        Path()
          ..moveTo(x, ground)
          ..lineTo(x + w * .06, ground)
          ..lineTo(x + w * .22, h * .07)
          ..lineTo(x + w * .16, h * .07)
          ..close(),
        shine,
      );
    }
    canvas.restore();
    // أرضية رخام لامع
    final floor = Rect.fromLTWH(0, ground, w, h - ground);
    canvas.drawRect(floor, _grad(floor, const [Color(0xFF1C1F2E), Color(0xFF0A0B12)]));
    for (final (i, r) in _towers(size).indexed) {
      if (i.isEven) continue;
      canvas.drawRect(
        Rect.fromLTWH(r.left, ground, r.width, (h - ground) * .7),
        _grad(Rect.fromLTWH(r.left, ground, r.width, (h - ground) * .7), [
          const Color(0xFFFFD98A).withValues(alpha: .08),
          const Color(0x00FFD98A),
        ]),
      );
    }
    canvas.drawRect(Rect.fromLTWH(0, ground - 2, w, 4), _fill(const Color(0xFF2E3350)));
    // نبتة طويلة بكل زاوية
    for (final x in [w * .04, w * .96]) {
      final pot = Rect.fromCenter(center: Offset(x, ground + h * .08), width: 26, height: 22);
      canvas.drawRRect(RRect.fromRectAndRadius(pot, const Radius.circular(4)), _fill(const Color(0xFF2A2E44)));
      for (var k = 0; k < 7; k++) {
        final a = -math.pi / 2 + (k - 3) * .28;
        canvas.drawPath(
          Path()
            ..moveTo(x, pot.top)
            ..quadraticBezierTo(
              x + math.cos(a) * 30,
              pot.top - 40,
              x + math.cos(a) * 36,
              pot.top - 70 - (3 - (k - 3).abs()) * 8,
            ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF1F4D35),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CityBackdrop old) => false;
}

class _CityLights extends CustomPainter {
  _CityLights(this.time, this.tension) : super(repaint: time);

  final ValueListenable<double> time;
  final double tension;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final w = size.width, h = size.height;
    // شبابيك تنطفي وتشتغل
    final towers = _towers(size);
    for (var k = 0; k < 40; k++) {
      final r = towers[(rnd(k, 61) * towers.length).floor() % towers.length];
      final on = rnd(k + (t / 1.5).floor() * 97, 62) > .5;
      if (!on) continue;
      canvas.drawRect(
        Rect.fromLTWH(r.left + 3 + rnd(k, 63) * (r.width - 8), r.top + 5 + rnd(k, 64) * (r.height - 12), 2.5, 3),
        _fill(const Color(0xFFFFF0C2)),
      );
    }
    // ضو أحمر فوق الأبراج الطويلة
    final blink = (math.sin(t * 3) + 1) / 2;
    _glow(canvas, Offset(w * .555, h * .02), 12, const Color(0xFFFF3B3B), .8 * blink);
    canvas.drawCircle(Offset(w * .555, h * .025), 2, _fill(const Color(0xFFFF6B6B).withValues(alpha: .4 + .6 * blink)));
    for (final r in towers.where((r) => r.height > h * .36)) {
      canvas.drawCircle(
        r.topCenter + const Offset(0, -2),
        1.6,
        _fill(const Color(0xFFFF5A5A).withValues(alpha: blink)),
      );
    }
    // طيارة بعيدة تمر
    final q = _frac(t / 24);
    final plane = Offset(w * (1.05 - q * 1.1), h * (.12 + .03 * math.sin(q * 6)));
    canvas.drawCircle(plane, 1.8, _fill(Colors.white.withValues(alpha: (math.sin(t * 8) > 0 ? .9 : .3))));
  }

  @override
  bool shouldRepaint(_CityLights old) => old.time != time;
}

// ───────── القصر: قاعة رخام وأعمدة وثريات

class _PalaceBackdrop extends CustomPainter {
  const _PalaceBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final floorY = h * .6;
    // جدار عاجي ونقش ذهبي
    final wall = Rect.fromLTWH(0, 0, w, floorY);
    canvas.drawRect(
      wall,
      _grad(wall, const [Color(0xFF6E5A3E), Color(0xFFB79C72), Color(0xFF8C7450)], stops: const [0, .45, 1]),
    );
    final lace = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFFFE7A3).withValues(alpha: .2);
    for (var y = h * .12; y < floorY; y += 28) {
      for (var x = ((y / 28).round().isEven ? 0.0 : 14.0); x < w; x += 28) {
        canvas.drawPath(
          Path()
            ..moveTo(x, y - 10)
            ..quadraticBezierTo(x + 10, y, x, y + 10)
            ..quadraticBezierTo(x - 10, y, x, y - 10),
          lace,
        );
      }
    }
    // أقواس بين الأعمدة (شبابيك ليل)
    final cols = [.07, .25, .43, .57, .75, .93];
    for (var i = 0; i < cols.length - 1; i++) {
      final l = w * cols[i] + 16, r = w * cols[i + 1] - 16;
      if (r - l < 20) continue;
      final top = h * .14, spring = h * .3;
      final arch = Path()
        ..moveTo(l, floorY - 6)
        ..lineTo(l, spring)
        ..quadraticBezierTo(l, top, (l + r) / 2, top - h * .02)
        ..quadraticBezierTo(r, top, r, spring)
        ..lineTo(r, floorY - 6)
        ..close();
      canvas.drawPath(
        arch,
        _grad(Rect.fromLTWH(l, top, r - l, floorY - top), const [Color(0xFF0F2244), Color(0xFF1F3B66)]),
      );
      canvas.drawPath(
        arch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFE9C46A),
      );
    }
    // الأعمدة
    for (final c in cols) {
      final x = w * c;
      final shaft = Rect.fromLTWH(x - 13, h * .1, 26, floorY - h * .1);
      canvas.drawRect(
        shaft,
        _grad(shaft, const [Color(0xFFB8B0A2), Color(0xFFF6F1E7), Color(0xFFC9C0AF)], vertical: false),
      );
      final flute = Paint()
        ..color = Colors.black.withValues(alpha: .08)
        ..strokeWidth = 1.2;
      for (var k = -2; k <= 2; k++) {
        canvas.drawLine(Offset(x + k * 4.5, shaft.top + 10), Offset(x + k * 4.5, shaft.bottom - 10), flute);
      }
      final gold = _grad(Rect.fromLTWH(x - 18, 0, 36, h), const [
        Color(0xFFFDE68A),
        Color(0xFFB87A12),
      ], vertical: false);
      canvas.drawRect(Rect.fromLTWH(x - 18, h * .085, 36, 10), gold);
      canvas.drawRect(Rect.fromLTWH(x - 18, floorY - 12, 36, 12), gold);
    }
    // الكورنيش الذهبي فوق
    final cornice = Rect.fromLTWH(0, 0, w, h * .085);
    canvas.drawRect(cornice, _grad(cornice, const [Color(0xFF4A3618), Color(0xFF8A6A2A)]));
    for (var x = 0.0; x < w; x += 12) {
      canvas.drawRect(Rect.fromLTWH(x, h * .06, 6, h * .022), _fill(const Color(0xFFE9C46A).withValues(alpha: .8)));
    }
    // ستاير حمرا مربوطة على الطرفين
    for (final left in [true, false]) {
      final edge = left ? 0.0 : w;
      final dir = left ? 1.0 : -1.0;
      final curtain = Path()
        ..moveTo(edge, 0)
        ..lineTo(edge + dir * w * .1, 0)
        ..quadraticBezierTo(edge + dir * w * .05, h * .3, edge + dir * w * .045, h * .42)
        ..quadraticBezierTo(edge + dir * w * .07, h * .55, edge + dir * w * .06, floorY + h * .1)
        ..lineTo(edge, floorY + h * .1)
        ..close();
      canvas.drawPath(
        curtain,
        _grad(Rect.fromLTWH(left ? 0 : w - w * .1, 0, w * .1, h), const [
          Color(0xFF5C0A16),
          Color(0xFFA3172D),
          Color(0xFF5C0A16),
        ], vertical: false),
      );
      final fold = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.black.withValues(alpha: .25);
      for (var k = 1; k <= 3; k++) {
        canvas.drawLine(Offset(edge + dir * w * .022 * k, 0), Offset(edge + dir * w * .016 * k, floorY), fold);
      }
      canvas.drawCircle(Offset(edge + dir * w * .05, h * .42), 6, _fill(const Color(0xFFE9C46A)));
    }
    // أرضية رخام مربعات
    final floor = Rect.fromLTWH(0, floorY, w, h - floorY);
    canvas.drawRect(floor, _fill(const Color(0xFFE8DFCB)));
    final tile = (h - floorY) / 4;
    for (var row = 0; row < 5; row++) {
      for (var col = -1; col < w / tile + 1; col++) {
        if ((row + col).isOdd) continue;
        canvas.drawRect(
          Rect.fromLTWH(col * tile + (row.isOdd ? tile / 2 : 0) - tile / 2, floorY + row * tile, tile, tile),
          _fill(const Color(0xFF1F3B33)),
        );
      }
    }
    canvas.drawRect(floor, _grad(floor, [Colors.black.withValues(alpha: .1), Colors.black.withValues(alpha: .55)]));
    canvas.drawRect(Rect.fromLTWH(0, floorY - 3, w, 6), _fill(const Color(0xFFE9C46A)));
    // الثريا بالنص (الكريستال يلمع بطبقة الحركة)
    _chandelier(canvas, Offset(w * .5, 0), (h / 400).clamp(.8, 1.4));
  }

  void _chandelier(Canvas canvas, Offset top, double s) {
    final gold = Paint()
      ..color = const Color(0xFFE9C46A)
      ..strokeWidth = 2 * s
      ..style = PaintingStyle.stroke;
    canvas.drawLine(top, top + Offset(0, 26 * s), gold);
    final c = top + Offset(0, 38 * s);
    canvas.drawOval(Rect.fromCenter(center: c, width: 120 * s, height: 22 * s), gold);
    canvas.drawOval(Rect.fromCenter(center: c + Offset(0, 14 * s), width: 80 * s, height: 14 * s), gold);
    for (var k = 0; k < 9; k++) {
      final x = c.dx + (k - 4) * 13 * s;
      final drop = 10 + (4 - (k - 4).abs()) * 5.0;
      canvas.drawLine(
        Offset(x, c.dy + 6 * s),
        Offset(x, c.dy + drop * s),
        Paint()
          ..color = Colors.white.withValues(alpha: .7)
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(Offset(x, c.dy + drop * s + 3 * s), 2.6 * s, _fill(const Color(0xFFE0F2FE)));
    }
  }

  @override
  bool shouldRepaint(_PalaceBackdrop old) => false;
}

class _PalaceLights extends CustomPainter {
  _PalaceLights(this.time, this.tension) : super(repaint: time);

  final ValueListenable<double> time;
  final double tension;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final w = size.width, h = size.height;
    final s = (h / 400).clamp(.8, 1.4);
    final c = Offset(w * .5, 38 * s);
    final warm = Color.lerp(const Color(0xFFFFE6B0), const Color(0xFFFF6B6B), tension)!;
    _glow(canvas, c + Offset(0, 10 * s), 120 * s, warm, .32 * lanternFlicker(t, 2, .08 + .3 * tension));
    // الكريستال يلمع
    for (var k = 0; k < 9; k++) {
      final tw = math.max(0.0, math.sin(t * 2.6 + k * 1.9));
      final x = c.dx + (k - 4) * 13 * s;
      final drop = 10 + (4 - (k - 4).abs()) * 5.0;
      canvas.drawPath(
        star4(Offset(x, c.dy + drop * s + 3 * s), (2 + 5 * tw) * s),
        _fill(Colors.white.withValues(alpha: .9 * tw)),
      );
    }
    // شموع على الأعمدة
    for (final (i, x) in [w * .07, w * .93, w * .25, w * .75].indexed) {
      final base = Offset(x, h * .34);
      canvas.drawRect(
        Rect.fromCenter(center: base + Offset(0, 8 * s), width: 18 * s, height: 4 * s),
        _fill(const Color(0xFFE9C46A)),
      );
      canvas.drawRect(Rect.fromLTWH(base.dx - 2.5 * s, base.dy - 2 * s, 5 * s, 10 * s), _fill(const Color(0xFFFFF7E6)));
      _glow(canvas, base - Offset(0, 8 * s), 34 * s, warm, .35 * lanternFlicker(t, i + 6, .15 + .4 * tension));
      _flame(canvas, base - Offset(0, 2 * s), 5 * s, 11 * s, t, i, const Color(0xFFFFF4C2), const Color(0xFFFF9A3C));
    }
  }

  @override
  bool shouldRepaint(_PalaceLights old) => old.tension != tension || old.time != time;
}

// ───────── الملوك: قاعة ملكية برايات ومشاعل

class _KingsBackdrop extends CustomPainter {
  const _KingsBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final floorY = h * .6;
    // جدار عنابي بنقش ذهبي
    final wall = Rect.fromLTWH(0, 0, w, floorY);
    canvas.drawRect(
      wall,
      _grad(wall, const [Color(0xFF1E0618), Color(0xFF3E0C26), Color(0xFF2A0819)], stops: const [0, .55, 1]),
    );
    final damask = Paint()..color = const Color(0xFFE9C46A).withValues(alpha: .1);
    for (var y = 20.0; y < floorY; y += 34) {
      for (var x = ((y / 34).round().isEven ? 0.0 : 17.0); x < w; x += 34) {
        canvas.drawPath(
          Path()
            ..moveTo(x, y - 8)
            ..lineTo(x + 6, y)
            ..lineTo(x, y + 8)
            ..lineTo(x - 6, y)
            ..close(),
          damask,
        );
      }
    }
    // قوس ذهبي كبير بالنص وشعار فوقه
    final cx = w / 2, top = h * .05;
    for (final (inset, alpha) in [(0.0, 1.0), (12.0, .6)]) {
      final r = w * .28 - inset;
      final arch = Path()
        ..moveTo(cx - r, floorY)
        ..lineTo(cx - r, h * .32)
        ..quadraticBezierTo(cx - r, top + inset, cx, top + inset - h * .03)
        ..quadraticBezierTo(cx + r, top + inset, cx + r, h * .32)
        ..lineTo(cx + r, floorY);
      canvas.drawPath(
        arch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = inset == 0 ? 7 : 3
          ..color = const Color(0xFFE9C46A).withValues(alpha: alpha),
      );
    }
    _emblem(canvas, Offset(cx, h * .085), (h / 400).clamp(.8, 1.3));
    // أعمدة ذهبية على الأطراف
    for (final x in [w * .025, w * .975]) {
      final col = Rect.fromLTWH(x - 10, 0, 20, floorY);
      canvas.drawRect(
        col,
        _grad(col, const [Color(0xFF8A5A00), Color(0xFFFDE68A), Color(0xFF8A5A00)], vertical: false),
      );
    }
    // مساكة الرايات (الرايات تتحرك بطبقة الحركة)
    for (final x in [w * .1, w * .2, w * .8, w * .9]) {
      canvas.drawRect(Rect.fromCenter(center: Offset(x, h * .1), width: 52, height: 5), _fill(const Color(0xFFE9C46A)));
      canvas.drawCircle(Offset(x - 26, h * .1), 4, _fill(const Color(0xFFE9C46A)));
      canvas.drawCircle(Offset(x + 26, h * .1), 4, _fill(const Color(0xFFE9C46A)));
    }
    // حوامل المشاعل
    for (final x in [w * .15, w * .85]) {
      final base = Offset(x, h * .5);
      canvas.drawPath(
        Path()
          ..moveTo(base.dx - 9, base.dy - 18)
          ..lineTo(base.dx + 9, base.dy - 18)
          ..lineTo(base.dx + 4, base.dy)
          ..lineTo(base.dx - 4, base.dy)
          ..close(),
        _fill(const Color(0xFFC9A227)),
      );
      canvas.drawRect(
        Rect.fromCenter(center: base + const Offset(0, 6), width: 6, height: 14),
        _fill(const Color(0xFF8A5A00)),
      );
    }
    // أرضية حجر غامق بخطوط ذهب
    final floor = Rect.fromLTWH(0, floorY, w, h - floorY);
    canvas.drawRect(floor, _grad(floor, const [Color(0xFF221018), Color(0xFF0C0508)]));
    final inlay = Paint()
      ..color = const Color(0xFFE9C46A).withValues(alpha: .35)
      ..strokeWidth = 1.5;
    for (var k = -6; k <= 6; k++) {
      canvas.drawLine(Offset(w / 2 + k * w * .02, floorY), Offset(w / 2 + k * w * .16, h), inlay);
    }
    canvas.drawLine(Offset(0, floorY + (h - floorY) * .45), Offset(w, floorY + (h - floorY) * .45), inlay);
    canvas.drawRect(Rect.fromLTWH(0, floorY - 4, w, 8), _fill(const Color(0xFFC9A227)));
  }

  /// شعار الملوك: سيفين متقاطعين ونخلة (بدون تاج، التاج للرئيس).
  void _emblem(Canvas canvas, Offset c, double s) {
    final gold = Paint()
      ..color = const Color(0xFFFDE68A)
      ..strokeWidth = 4 * s
      ..strokeCap = StrokeCap.round;
    for (final dir in [-1.0, 1.0]) {
      canvas.drawLine(c + Offset(-26 * dir * s, 18 * s), c + Offset(26 * dir * s, -18 * s), gold);
      canvas.drawLine(c + Offset(-20 * dir * s, 10 * s), c + Offset(-14 * dir * s, 18 * s), gold..strokeWidth = 3 * s);
      gold.strokeWidth = 4 * s;
    }
    canvas.drawLine(c + Offset(0, 16 * s), c + Offset(0, -6 * s), gold..strokeWidth = 3 * s);
    for (var k = 0; k < 5; k++) {
      final a = -math.pi / 2 + (k - 2) * .55;
      canvas.drawLine(
        c + Offset(0, -6 * s),
        c + Offset(math.cos(a), math.sin(a) + .4) * 16 * s + Offset(0, -6 * s),
        gold..strokeWidth = 2.5 * s,
      );
    }
  }

  @override
  bool shouldRepaint(_KingsBackdrop old) => false;
}

class _KingsLights extends CustomPainter {
  _KingsLights(this.time, this.tension) : super(repaint: time);

  final ValueListenable<double> time;
  final double tension;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final w = size.width, h = size.height;
    final s = (h / 400).clamp(.8, 1.4);
    // الرايات تتمايل
    for (final (i, x) in [w * .1, w * .2, w * .8, w * .9].indexed) {
      final top = h * .1 + 3;
      final len = h * .36;
      final sway = math.sin(t * 1.6 + i) * 5;
      final flag = Path()
        ..moveTo(x - 22, top)
        ..lineTo(x + 22, top)
        ..quadraticBezierTo(x + 24 + sway, top + len * .5, x + 22 + sway * 1.4, top + len)
        ..lineTo(x + sway * 1.4, top + len - 16)
        ..lineTo(x - 22 + sway * 1.4, top + len)
        ..quadraticBezierTo(x - 24 + sway, top + len * .5, x - 22, top)
        ..close();
      canvas.drawPath(
        flag,
        _grad(
          Rect.fromLTWH(x - 24, top, 48, len),
          i.isEven ? const [Color(0xFF7A0F2B), Color(0xFF4A0818)] : const [Color(0xFF3B1466), Color(0xFF22093D)],
        ),
      );
      canvas.drawPath(
        flag,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFE9C46A),
      );
      // شعار صغير على الراية
      final c = Offset(x + sway * .7, top + len * .4);
      canvas.drawCircle(
        c,
        9 * s,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFDE68A),
      );
      canvas.drawPath(star4(c, 6 * s), _fill(const Color(0xFFFDE68A)));
    }
    // المشاعل
    for (final (i, x) in [w * .15, w * .85].indexed) {
      _torchFire(canvas, Offset(x, h * .5 - 18), s, t, i + 11, tension);
    }
    // لمعة تمشي على القوس
    final q = _frac(t / 4);
    final a = math.pi * (1 - q);
    final r = w * .28;
    final p = Offset(w / 2 + math.cos(a) * r, h * .32 - math.sin(a) * h * .28);
    canvas.drawPath(star4(p, 7 * s), _fill(Colors.white.withValues(alpha: .85)));
  }

  @override
  bool shouldRepaint(_KingsLights old) => old.tension != tension || old.time != time;
}

// ───────── نخبة VIP: صالة سودا وذهبي

class _VipBackdrop extends CustomPainter {
  const _VipBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final floorY = h * .6;
    final wall = Rect.fromLTWH(0, 0, w, floorY);
    canvas.drawRect(wall, _grad(wall, const [Color(0xFF050506), Color(0xFF15121A)]));
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFE9C46A).withValues(alpha: .55);
    // مروحة آرت ديكو بالنص
    final fan = Offset(w / 2, floorY * .62);
    for (var k = 0; k <= 12; k++) {
      final a = math.pi + k / 12 * math.pi;
      canvas.drawLine(fan, fan + Offset(math.cos(a), math.sin(a)) * h * .45, gold);
    }
    for (final r in [h * .18, h * .3, h * .42]) {
      canvas.drawArc(Rect.fromCircle(center: fan, radius: r), math.pi, math.pi, false, gold);
    }
    // ألواح بإطار ذهبي على الجنبين
    for (var i = 0; i < 4; i++) {
      for (final left in [true, false]) {
        final x = left ? w * (.02 + i * .07) : w * (.98 - i * .07) - w * .055;
        final panel = Rect.fromLTWH(x, h * .12, w * .055, floorY - h * .16);
        canvas.drawRect(panel, _fill(const Color(0xFF0D0B10)));
        canvas.drawRect(panel, gold);
        canvas.drawRect(panel.deflate(5), gold..strokeWidth = .8);
        gold.strokeWidth = 1.4;
      }
    }
    // كورنيش متعرج فوق
    final zig = Path()..moveTo(0, h * .07);
    for (var x = 0.0; x < w; x += 16) {
      zig
        ..lineTo(x + 8, h * .045)
        ..lineTo(x + 16, h * .07);
    }
    canvas.drawPath(zig, gold..strokeWidth = 2);
    canvas.drawLine(Offset(0, h * .085), Offset(w, h * .085), gold..strokeWidth = 1.4);
    // ألماسة VIP فوق النص
    final d = Offset(w / 2, h * .05);
    final dp = Path()
      ..moveTo(d.dx - 18, d.dy - 6)
      ..lineTo(d.dx + 18, d.dy - 6)
      ..lineTo(d.dx + 26, d.dy + 2)
      ..lineTo(d.dx, d.dy + 26)
      ..lineTo(d.dx - 26, d.dy + 2)
      ..close();
    _glow(canvas, d + const Offset(0, 8), 60, const Color(0xFFE9C46A), .25);
    canvas.drawPath(dp, _grad(dp.getBounds(), const [Color(0xFFFDE68A), Color(0xFFB87A12)]));
    canvas.drawLine(
      d + const Offset(-26, 2),
      d + const Offset(26, 2),
      Paint()
        ..color = const Color(0xFF7A4E00)
        ..strokeWidth = 1.2,
    );
    // أرضية رخام أسود بعروق ذهب
    final floor = Rect.fromLTWH(0, floorY, w, h - floorY);
    canvas.drawRect(floor, _grad(floor, const [Color(0xFF141217), Color(0xFF040405)]));
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFE9C46A).withValues(alpha: .25);
    for (var k = 0; k < 9; k++) {
      final y0 = floorY + rnd(k, 71) * (h - floorY);
      final p = Path()..moveTo(-10, y0);
      for (var x = 0.0; x < w + 60; x += 60) {
        p.quadraticBezierTo(
          x + 30,
          y0 + (rnd(k * 5 + (x / 60).round(), 72) - .5) * 30,
          x + 60,
          y0 + (rnd(k, 73) - .5) * 20,
        );
      }
      canvas.drawPath(p, vein);
    }
    canvas.drawRect(Rect.fromLTWH(0, floorY - 2, w, 4), _fill(const Color(0xFFE9C46A).withValues(alpha: .8)));
  }

  @override
  bool shouldRepaint(_VipBackdrop old) => false;
}

class _VipLights extends CustomPainter {
  _VipLights(this.time, this.tension) : super(repaint: time);

  final ValueListenable<double> time;
  final double tension;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final w = size.width, h = size.height;
    // دواير ضو ناعمة (بوكيه)
    for (var k = 0; k < 9; k++) {
      final pulse = .5 + .5 * math.sin(t * .8 + k * 1.3);
      final c = Offset(rnd(k, 81) * w, h * (.12 + rnd(k, 82) * .4));
      _glow(canvas, c, 18 + rnd(k, 83) * 26, k.isEven ? const Color(0xFFE9C46A) : const Color(0xFF8B5CF6), .12 * pulse);
    }
    // غبار ذهب يطلع
    for (var k = 0; k < 40; k++) {
      final q = _frac(t * (.05 + rnd(k, 84) * .06) + rnd(k, 85));
      final p = Offset(rnd(k, 86) * w + math.sin(t + k) * 8, h * (1 - q));
      canvas.drawCircle(
        p,
        .8 + rnd(k, 87) * 1.4,
        _fill(const Color(0xFFFDE68A).withValues(alpha: .7 * math.sin(q * math.pi))),
      );
    }
    // ضو يمسح الجدار كل شوي
    final sweep = _frac(t / 7);
    if (sweep < .35) {
      final x = -w * .2 + sweep / .35 * w * 1.4;
      final beam = Path()
        ..moveTo(x, 0)
        ..lineTo(x + w * .08, 0)
        ..lineTo(x - w * .05, h * .6)
        ..lineTo(x - w * .13, h * .6)
        ..close();
      canvas.drawPath(beam, _fill(const Color(0xFFFDE68A).withValues(alpha: .07)));
    }
    // لمعة على الألماسة
    final tw = math.max(0.0, math.sin(t * 1.7));
    canvas.drawPath(star4(Offset(w / 2 + 10, h * .05), 3 + 7 * tw), _fill(Colors.white.withValues(alpha: .9 * tw)));
  }

  @override
  bool shouldRepaint(_VipLights old) => old.time != time;
}
