import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'fx.dart';
import 'venues.dart';

/// رسمات المجلس: الجدار بأقواسه، والفوانيس، والمبخرة، والدلة، والمساند. كلها ترسم بالكود
/// وتتمدد على أي مقاس، والحركة (رمشة الفوانيس والدخان) على ساعة الحركات، فتوقف في الوضع الخفيف.

double _frac(double x) => x - x.floorToDouble();

/// رمشة الفانوس (١ ثابت، وأقل كل ما زادت [amount]).
double lanternFlicker(double t, int i, double amount) =>
    1 - amount * (.5 + .25 * math.sin(t * 9.1 + i * 2.3) + .25 * math.sin(t * 23.7 + i * 1.1));

/// يطفي الألوان بقد [k] (٠ ملون، ١ رمادي).
List<double> greyMatrix(double k) {
  const lr = .2126, lg = .7152, lb = .0722;
  final i = 1 - k;
  return [
    i + k * lr, k * lg, k * lb, 0, 0, //
    k * lr, i + k * lg, k * lb, 0, 0,
    k * lr, k * lg, i + k * lb, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

/// غرفة المجلس ورا الطاولة: جدار بأقواس وشباك فيه هلال، وأرضية، وفوانيس معلقة ترمش.
/// [venue] يغيّر المكان كامل حسب مستوى الطاولة (بيت شعر، مدينة، قصر…).
/// [tension] (٠–١) تحمّر الفوانيس وتخليها ترمش أكثر.
class MajlisRoom extends StatelessWidget {
  const MajlisRoom({super.key, this.tension = 0, this.venue = Venue.majlis});

  final double tension;
  final Venue venue;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      // الرسمة الثابتة: تنرسم مرة وتنحفظ.
      Positioned.fill(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: venue == Venue.majlis ? const _RoomPainter() : venueBackdrop(venue),
            isComplex: true,
          ),
        ),
      ),
      // التوتر يحمّر الغرفة.
      if (tension > 0)
        Positioned.fill(
          child: ColoredBox(color: const Color(0xFF7F1D1D).withValues(alpha: .32 * tension)),
        ),
      Positioned.fill(
        child: RepaintBoundary(
          child: FxClock(
            builder: (context, time) => CustomPaint(
              painter: venue == Venue.majlis ? _RoomLights(time, tension) : venueLights(venue, time, tension),
            ),
          ),
        ),
      ),
    ],
  );
}

/// مكان الأقواس (نفسه للجدار والفوانيس).
({int count, double step, double floorY}) _roomLayout(Size size) {
  final count = math.max(4, (size.width / 170).round());
  return (count: count, step: size.width / count, floorY: size.height * .6);
}

class _RoomPainter extends CustomPainter {
  const _RoomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final (:count, :step, :floorY) = _roomLayout(size);
    final wall = Rect.fromLTWH(0, 0, w, floorY + 4);
    canvas.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A100B), Color(0xFF3A2416)],
        ).createShader(wall),
    );
    // النقشة فوق
    final gold = Paint()..color = AppColors.gold.withValues(alpha: .3);
    for (var x = 6.0; x < w; x += 20) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 13)
          ..lineTo(x + 6, 7)
          ..lineTo(x + 12, 13)
          ..lineTo(x + 6, 19)
          ..close(),
        gold,
      );
    }
    final line = Paint()
      ..color = AppColors.gold.withValues(alpha: .3)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(0, 3), Offset(w, 3), line);
    canvas.drawLine(const Offset(0, 23), Offset(w, 23), line);
    // الأقواس
    final archW = step * .74;
    final top = h * .12, spring = h * .3;
    for (var i = 0; i < count; i++) {
      final cx = step * (i + .5);
      final arch = Path()
        ..moveTo(cx - archW / 2, floorY)
        ..lineTo(cx - archW / 2, spring)
        ..quadraticBezierTo(cx - archW / 2 + 2, top + (spring - top) * .35, cx, top)
        ..quadraticBezierTo(cx + archW / 2 - 2, top + (spring - top) * .35, cx + archW / 2, spring)
        ..lineTo(cx + archW / 2, floorY)
        ..close();
      final box = Rect.fromLTWH(cx - archW / 2, top, archW, floorY - top);
      canvas.drawPath(
        arch,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: .45), Colors.black.withValues(alpha: .12)],
          ).createShader(box),
      );
      if (i == count ~/ 2 - (count.isEven ? 1 : 0) || i == count ~/ 2) _window(canvas, arch, box, i);
      canvas.drawPath(
        arch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.gold.withValues(alpha: .4),
      );
    }
    // الأرضية: خشب غامق بألواح
    final floor = Rect.fromLTWH(0, floorY, w, h - floorY);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B1A10), Color(0xFF110905)],
        ).createShader(floor),
    );
    final plank = Paint()
      ..color = Colors.black.withValues(alpha: .25)
      ..strokeWidth = 1;
    for (var y = floorY + 16; y < h; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(w, y), plank);
    }
    canvas.drawRect(Rect.fromLTWH(0, floorY - 3, w, 6), Paint()..color = const Color(0xFF5A3A1E));
  }

  /// شباك: سما ونجوم وهلال.
  void _window(Canvas canvas, Path arch, Rect box, int i) {
    canvas.save();
    canvas.clipPath(arch);
    canvas.drawRect(
      box,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1030), Color(0xFF2B1F4A)],
        ).createShader(box),
    );
    for (var k = 0; k < 12; k++) {
      canvas.drawCircle(
        Offset(box.left + rnd(k + i * 20, 1) * box.width, box.top + rnd(k + i * 20, 2) * box.height * .7),
        .8 + rnd(k + i * 20, 3),
        Paint()..color = Colors.white.withValues(alpha: .4 + .5 * rnd(k + i * 20, 4)),
      );
    }
    if (i.isEven) {
      final r = box.width * .13;
      final moon = Offset(box.center.dx + box.width * .12, box.top + box.height * .22);
      canvas.drawCircle(moon, r * 2.2, Paint()..color = const Color(0xFFFDE68A).withValues(alpha: .1));
      canvas.drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addOval(Rect.fromCircle(center: moon, radius: r)),
          Path()..addOval(Rect.fromCircle(center: moon + Offset(r * .45, -r * .25), radius: r * .85)),
        ),
        Paint()..color = const Color(0xFFFDE68A),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoomPainter old) => false;
}

/// الفوانيس المعلقة بين الأقواس: تتمرجح وترمش، وتحمر مع التوتر.
class _RoomLights extends CustomPainter {
  _RoomLights(this.time, this.tension) : super(repaint: time);

  final ValueListenable<double> time;
  final double tension;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final (:count, :step, floorY: _) = _roomLayout(size);
    final s = (size.height / 400).clamp(.75, 1.4);
    final warm = Color.lerp(const Color(0xFFFFC857), const Color(0xFFFF3B3B), tension)!;
    for (var i = 1; i < count; i += 2) {
      final x = step * i;
      final light = lanternFlicker(t, i, .1 + .55 * tension);
      canvas.save();
      canvas.translate(x, 0);
      canvas.scale(s);
      canvas.rotate(.04 * math.sin(t * 1.3 + i));
      canvas.drawLine(
        Offset.zero,
        const Offset(0, 30),
        Paint()
          ..color = const Color(0xFF8A6A2A)
          ..strokeWidth = 1.4,
      );
      canvas.drawCircle(
        const Offset(0, 56),
        80,
        Paint()
          ..shader = RadialGradient(
            colors: [
              warm.withValues(alpha: .34 * light),
              warm.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: const Offset(0, 56), radius: 80)),
      );
      final frame = Paint()..color = const Color(0xFFC9A227);
      canvas.drawPath(
        Path()
          ..moveTo(-7, 38)
          ..lineTo(0, 29)
          ..lineTo(7, 38)
          ..close(),
        frame,
      );
      const glass = Rect.fromLTWH(-10, 38, 20, 30);
      canvas.drawRRect(
        RRect.fromRectAndRadius(glass, const Radius.circular(4)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(warm, Colors.white, .5)!.withValues(alpha: light),
              warm.withValues(alpha: light),
            ],
          ).createShader(glass),
      );
      final bars = Paint()
        ..color = const Color(0xFFC9A227)
        ..strokeWidth = 1.1;
      canvas.drawLine(const Offset(-3.5, 38), const Offset(-3.5, 68), bars);
      canvas.drawLine(const Offset(3.5, 38), const Offset(3.5, 68), bars);
      canvas.drawRect(const Rect.fromLTWH(-12, 67, 24, 4), frame);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RoomLights old) => old.tension != tension;
}

/// يغمّق الأطراف ويحمّرها مع التوتر، ونبض قلب لما يقرب الخطر (فوق ٠٫٧٥).
class TensionOverlay extends StatelessWidget {
  const TensionOverlay({super.key, required this.tension});

  final double tension;

  @override
  Widget build(BuildContext context) {
    if (tension <= 0) return const SizedBox.shrink();
    // نبض القلب بس لما يقرب الخطر، وقبله الطبقة ثابتة ما تنرسم كل فريم.
    if (tension <= .75) return IgnorePointer(child: _layer(0));
    return IgnorePointer(
      child: RepaintBoundary(
        child: FxClock(
          builder: (context, time) => ValueListenableBuilder<double>(
            valueListenable: time,
            builder: (context, t, _) => _layer(_beat(t) * (tension - .75) / .25),
          ),
        ),
      ),
    );
  }

  /// لون أحمر خفيف على الكل، وفوقه الأطراف تغمق (وتنبض مع [beat]).
  Widget _layer(double beat) => Stack(
    children: [
      Positioned.fill(
        child: ColoredBox(color: const Color(0xFF7F1D1D).withValues(alpha: .14 * tension)),
      ),
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.05 - .12 * beat,
              colors: [
                Colors.transparent,
                const Color(0xFF450A0A).withValues(alpha: .2 + .45 * tension + .2 * beat),
              ],
              stops: const [.6, 1],
            ),
          ),
        ),
      ),
    ],
  );

  /// دقتين ورا بعض كل ٠٫٩ ثانية.
  static double _beat(double t) {
    final q = _frac(t / .9);
    double hump(double c) => math.max(0, 1 - ((q - c) / .06).abs());
    return math.max(hump(.08), hump(.26) * .7);
  }
}

/// مسند أحمر بحافة ذهبية وشراريب (ورا اللاعب). يرمّد لما [dead] تقرب من ١.
class Cushion extends StatelessWidget {
  const Cushion({super.key, this.dead = 0, this.width = 80, this.height = 56});

  final double dead, width, height;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(width, height), painter: _CushionPainter(dead));
}

class _CushionPainter extends CustomPainter {
  _CushionPainter(this.dead);

  final double dead;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 80;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 8 * s, size.width, size.height - 8 * s),
      Radius.circular(14 * s),
    );
    final c1 = Color.lerp(const Color(0xFF9F1239), const Color(0xFF3F3F46), dead)!;
    final c2 = Color.lerp(const Color(0xFF4C0519), const Color(0xFF18181B), dead)!;
    canvas.drawRRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c1, c2],
        ).createShader(r.outerRect),
    );
    canvas.drawRRect(
      r.deflate(4 * s),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * s
        ..color = AppColors.gold.withValues(alpha: .7 * (1 - dead * .7)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(4 * s, 0, size.width - 8 * s, 16 * s), Radius.circular(8 * s)),
      Paint()..color = Color.lerp(c1, Colors.white, .12)!,
    );
    final tassel = Paint()
      ..color = AppColors.gold.withValues(alpha: 1 - dead * .6)
      ..strokeWidth = 2 * s;
    for (final x in [6 * s, size.width - 6 * s]) {
      canvas.drawLine(Offset(x, 10 * s), Offset(x, 22 * s), tassel);
      canvas.drawCircle(Offset(x, 23 * s), 2.4 * s, tassel);
    }
  }

  @override
  bool shouldRepaint(_CushionPainter old) => old.dead != dead;
}

/// فانوس صغير على الأرض جنب اللاعب: ينطفي لما [on] تنزل للصفر. [flicker] يخليه يرمش (مشهد الطرد)،
/// وإلا ضوه ثابت (اللي جنب الكراسي، عشان ما تنرسم عشرة فوانيس كل فريم).
class FloorLantern extends StatelessWidget {
  const FloorLantern({super.key, this.on = 1, this.width = 16, this.seed = 0, this.flicker = false});

  final double on, width;
  final int seed;
  final bool flicker;

  @override
  Widget build(BuildContext context) {
    final size = Size(width, width * 1.9);
    if (on <= 0 || !flicker) return CustomPaint(size: size, painter: _FloorLanternPainter(null, on, seed));
    return RepaintBoundary(
      child: FxClock(
        builder: (context, time) => CustomPaint(size: size, painter: _FloorLanternPainter(time, on, seed)),
      ),
    );
  }
}

class _FloorLanternPainter extends CustomPainter {
  _FloorLanternPainter(this.time, this.on, this.seed) : super(repaint: time);

  final ValueListenable<double>? time;
  final double on;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 16);
    const c = Offset(8, 17);
    final t = time?.value ?? 0;
    final light = on * lanternFlicker(t, seed, .15);
    if (light > 0) {
      canvas.drawCircle(
        c,
        20,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFC857).withValues(alpha: .45 * light),
              const Color(0x00FFC857),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: 20)),
      );
    }
    final glass = Rect.fromCenter(center: c, width: 10, height: 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glass, const Radius.circular(3)),
      Paint()..color = Color.lerp(const Color(0xFF3B2A1A), const Color(0xFFFFD27A), light)!,
    );
    final frame = Paint()..color = const Color(0xFFC9A227);
    canvas.drawRect(Rect.fromLTWH(c.dx - 6, c.dy - 9, 12, 2.4), frame);
    canvas.drawRect(Rect.fromLTWH(c.dx - 6, c.dy + 7, 12, 2.4), frame);
    canvas.drawLine(Offset(c.dx, c.dy - 9), Offset(c.dx, c.dy - 13), frame..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(_FloorLanternPainter old) => old.on != on || old.time != time;
}

/// غطا رمادي يطيح من فوق على مسند المطرود ([k] ٠–١ قد إيش نزل).
class SeatCloth extends StatelessWidget {
  const SeatCloth({super.key, required this.k, this.width = 88, this.height = 80});

  final double k, width, height;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(size: Size(width, height), painter: _ClothPainter(k)),
  );
}

class _ClothPainter extends CustomPainter {
  _ClothPainter(this.k);

  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    final e = Curves.easeOutCubic.transform(k.clamp(0.0, 1.0));
    final a = (k * 4).clamp(0.0, 1.0);
    final w = size.width, h = size.height;
    canvas.translate(0, -h * .55 * (1 - e));
    final sway = math.sin(k * math.pi) * 4;
    final sheet = Path()
      ..moveTo(w * .5, 4)
      ..cubicTo(w * .8, 4, w * .84, h * .3, w * .86 + sway, h * .55)
      ..quadraticBezierTo(w * .98, h * .8, w, h * .96)
      ..quadraticBezierTo(w * .86, h * .9, w * .74, h * .98)
      ..quadraticBezierTo(w * .62, h * .9, w * .5, h)
      ..quadraticBezierTo(w * .38, h * .9, w * .26, h * .98)
      ..quadraticBezierTo(w * .14, h * .9, 0, h * .96)
      ..quadraticBezierTo(w * .02, h * .8, w * .14 - sway, h * .55)
      ..cubicTo(w * .16, h * .3, w * .2, 4, w * .5, 4)
      ..close();
    canvas.drawPath(
      sheet,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF3F3F46).withValues(alpha: a),
            const Color(0xFF8A8A94).withValues(alpha: a),
            const Color(0xFF5B5B64).withValues(alpha: a),
            const Color(0xFF34343B).withValues(alpha: a),
          ],
          stops: const [0, .38, .62, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    final fold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Colors.black.withValues(alpha: .28 * a);
    for (final x in [.28, .42, .58, .72]) {
      canvas.drawLine(Offset(w * (.5 + (x - .5) * .4), h * .3), Offset(w * x, h * .93), fold);
    }
    canvas.drawOval(
      Rect.fromLTWH(w * .3, 9, w * .26, h * .16),
      Paint()..color = Colors.white.withValues(alpha: .14 * a),
    );
  }

  @override
  bool shouldRepaint(_ClothPainter old) => old.k != k;
}

/// دلة وفناجيل وصحن تمر (على السجادة).
class CoffeeSet extends StatelessWidget {
  const CoffeeSet({super.key, this.width = 90});

  final double width;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FxClock(
      builder: (context, time) => CustomPaint(size: Size(width, width * .62), painter: _CoffeePainter(time)),
    ),
  );
}

class _CoffeePainter extends CustomPainter {
  _CoffeePainter(this.time) : super(repaint: time);

  final ValueListenable<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    canvas.scale(size.width / 90);
    const brass = [Color(0xFFFDE68A), Color(0xFFD4A017), Color(0xFF8A5A00)];
    canvas.drawOval(const Rect.fromLTWH(4, 44, 82, 10), Paint()..color = Colors.black.withValues(alpha: .3));
    const d = Offset(26, 30);
    final body = Path()
      ..moveTo(d.dx - 14, d.dy + 20)
      ..quadraticBezierTo(d.dx - 20, d.dy + 4, d.dx - 9, d.dy - 8)
      ..lineTo(d.dx - 7, d.dy - 16)
      ..lineTo(d.dx + 7, d.dy - 16)
      ..lineTo(d.dx + 9, d.dy - 8)
      ..quadraticBezierTo(d.dx + 20, d.dy + 4, d.dx + 14, d.dy + 20)
      ..close();
    canvas.drawPath(
      body,
      Paint()..shader = const LinearGradient(colors: brass).createShader(Rect.fromLTWH(d.dx - 20, d.dy - 18, 40, 40)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(d.dx + 8, d.dy - 9)
        ..quadraticBezierTo(d.dx + 21, d.dy - 15, d.dx + 28, d.dy - 27)
        ..lineTo(d.dx + 24, d.dy - 28)
        ..quadraticBezierTo(d.dx + 17, d.dy - 18, d.dx + 6, d.dy - 5)
        ..close(),
      Paint()..color = brass[1],
    );
    canvas.drawPath(
      Path()
        ..moveTo(d.dx - 8, d.dy - 16)
        ..quadraticBezierTo(d.dx, d.dy - 31, d.dx + 8, d.dy - 16)
        ..close(),
      Paint()..color = brass[0],
    );
    canvas.drawCircle(Offset(d.dx, d.dy - 28), 2.4, Paint()..color = brass[1]);
    canvas.drawPath(
      Path()
        ..moveTo(d.dx - 9, d.dy - 11)
        ..quadraticBezierTo(d.dx - 25, d.dy - 7, d.dx - 13, d.dy + 13),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = brass[2],
    );
    for (var k = 0; k < 2; k++) {
      final q = _frac(t * .5 + k * .5);
      canvas.drawCircle(
        Offset(d.dx + 29 + q * 5, d.dy - 31 - q * 18),
        2.6 + q * 3.5,
        Paint()..color = Colors.white.withValues(alpha: .22 * (1 - q)),
      );
    }
    for (final (i, p) in const [Offset(56, 42), Offset(70, 36), Offset(80, 45)].indexed) {
      canvas.drawPath(
        Path()
          ..moveTo(p.dx - 6, p.dy - 5)
          ..lineTo(p.dx + 6, p.dy - 5)
          ..lineTo(p.dx + 4.5, p.dy + 3.5)
          ..quadraticBezierTo(p.dx, p.dy + 6, p.dx - 4.5, p.dy + 3.5)
          ..close(),
        Paint()..color = const Color(0xFFFFFBF0),
      );
      canvas.drawLine(
        Offset(p.dx - 5, p.dy - 2.5),
        Offset(p.dx + 5, p.dy - 2.5),
        Paint()
          ..color = i.isEven ? const Color(0xFF16A34A) : const Color(0xFFB91C1C)
          ..strokeWidth = 1.4,
      );
    }
    canvas.drawOval(Rect.fromCenter(center: const Offset(62, 52), width: 30, height: 9), Paint()..color = brass[1]);
    for (var k = 0; k < 4; k++) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(54 + k * 5.5, 50 - (k % 2) * 1.6), width: 6, height: 4),
        Paint()..color = const Color(0xFF5A2E0E),
      );
    }
  }

  @override
  bool shouldRepaint(_CoffeePainter old) => old.time != time;
}

/// مبخرة يطلع منها دخان بخور.
class Censer extends StatelessWidget {
  const Censer({super.key, this.width = 36});

  final double width;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FxClock(
      builder: (context, time) => CustomPaint(size: Size(width, width * 3), painter: _CenserPainter(time)),
    ),
  );
}

class _CenserPainter extends CustomPainter {
  _CenserPainter(this.time) : super(repaint: time);

  final ValueListenable<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    canvas.scale(size.width / 36);
    const base = Offset(18, 106);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - 14, base.dy)
        ..lineTo(base.dx + 14, base.dy)
        ..lineTo(base.dx + 8, base.dy - 12)
        ..lineTo(base.dx + 14, base.dy - 26)
        ..lineTo(base.dx - 14, base.dy - 26)
        ..lineTo(base.dx - 8, base.dy - 12)
        ..close(),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFB45309)])
            .createShader(Rect.fromLTWH(base.dx - 14, base.dy - 26, 28, 26)),
    );
    canvas.drawCircle(base + const Offset(0, -28), 5, Paint()..color = const Color(0xFFFF7A1A).withValues(alpha: .8));
    for (var k = 0; k < 3; k++) {
      final q = _frac(t * .28 + k / 3);
      final path = Path()..moveTo(base.dx, base.dy - 30);
      for (var j = 1; j <= 5; j++) {
        path.lineTo(base.dx + math.sin(j * 1.2 + t * 1.5 + k * 2) * (3 + j * 1.6), base.dy - 30 - j * 14 * (.4 + q));
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .16 * (1 - q))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_CenserPainter old) => old.time != time;
}
