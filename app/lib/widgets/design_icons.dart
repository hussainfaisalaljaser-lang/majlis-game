import 'dart:math' as math;

import 'package:flutter/material.dart';

/// أيقونات التصميم الجديد، مرسومة بالكود بنفس أسلوب الفيديو (حد بني غامق سميك، تدرجات دافية، لمعة خفيفة)،
/// عشان تبقى حادة بأي حجم وما نحتاج صور.

const _ink = Color(0xFF3A2412);
const _gold = [Color(0xFFFFE9A0), Color(0xFFF2B93F), Color(0xFFB9791A)];

Paint _fill(Rect r, List<Color> colors) => Paint()
  ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors).createShader(r);

Paint _line(double w, [Color c = _ink]) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..color = c;

/// يرسم على مربع ١٠٠×١٠٠ ويكبّره لحجم الأيقونة.
class _Icon extends StatelessWidget {
  const _Icon({required this.size, required this.painter});

  final double size;
  final void Function(Canvas canvas) painter;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _IconPainter(painter)),
  );
}

class _IconPainter extends CustomPainter {
  const _IconPainter(this.draw);

  final void Function(Canvas canvas) draw;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) => false;
}

/// درع أزرق بحد ذهبي وسيفين متقاطعين (الديوان).
class ShieldSwordsIcon extends StatelessWidget {
  const ShieldSwordsIcon({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) => _Icon(size: size, painter: _paint);

  static Path _shield(double inset) {
    final k = 1 - inset / 100 * 2;
    Offset p(double x, double y) => Offset(50 + (x - 50) * k, 52 + (y - 52) * k);
    final a = p(9, 12), b = p(91, 12), c = p(91, 54), d = p(50, 96), e = p(9, 54);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(p(50, 3).dx, p(50, 3).dy, b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..cubicTo(p(91, 76).dx, p(91, 76).dy, p(70, 90).dx, p(70, 90).dy, d.dx, d.dy)
      ..cubicTo(p(30, 90).dx, p(30, 90).dy, p(9, 76).dx, p(9, 76).dy, e.dx, e.dy)
      ..close();
  }

  static void _sword(Canvas canvas, double angle) {
    canvas.save();
    canvas.translate(50, 52);
    canvas.rotate(angle);
    final blade = Path()
      ..moveTo(0, -27)
      ..lineTo(4.2, -20)
      ..lineTo(3.6, 8)
      ..lineTo(-3.6, 8)
      ..lineTo(-4.2, -20)
      ..close();
    canvas.drawPath(
      blade,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFC9D2DB), Color(0xFF8F9BA8)],
          stops: [0, .5, 1],
        ).createShader(const Rect.fromLTWH(-5, -27, 10, 35)),
    );
    canvas.drawPath(blade, _line(2.6));
    final guard = RRect.fromRectAndRadius(const Rect.fromLTWH(-10, 8, 20, 5.5), const Radius.circular(2.5));
    canvas.drawRRect(guard, _fill(guard.outerRect, _gold));
    canvas.drawRRect(guard, _line(2.4));
    final grip = RRect.fromRectAndRadius(const Rect.fromLTWH(-2.6, 13.5, 5.2, 9), const Radius.circular(2));
    canvas.drawRRect(grip, Paint()..color = const Color(0xFF7A4520));
    canvas.drawRRect(grip, _line(2));
    canvas.drawCircle(const Offset(0, 25.5), 3.8, _fill(const Rect.fromLTWH(-4, 21.5, 8, 8), _gold));
    canvas.drawCircle(const Offset(0, 25.5), 3.8, _line(2.2));
    canvas.restore();
  }

  static void _paint(Canvas canvas) {
    final outer = _shield(0);
    canvas.drawPath(outer.shift(const Offset(0, 2.5)), Paint()..color = const Color(0x40000000));
    canvas.drawPath(outer, _fill(const Rect.fromLTWH(9, 3, 82, 93), _gold));
    canvas.drawPath(outer, _line(3.4));
    final inner = _shield(6.5);
    canvas.drawPath(inner, _fill(const Rect.fromLTWH(14, 12, 72, 80), const [Color(0xFF6FA6F0), Color(0xFF3B78D8), Color(0xFF2556B0)]));
    canvas.drawPath(inner, _line(2.4));
    // لمعة على فوق اليسار
    final gloss = Path()
      ..moveTo(20, 24)
      ..quadraticBezierTo(30, 17, 48, 18)
      ..quadraticBezierTo(33, 24, 22, 40)
      ..close();
    canvas.drawPath(gloss, Paint()..color = const Color(0x66FFFFFF));
    _sword(canvas, -math.pi / 4.6);
    _sword(canvas, math.pi / 4.6);
  }
}

/// صندوق خشب بأحزمة وقفل ذهبي (الموسم). [gems]: جواهر تطلع منه.
class ChestIcon extends StatelessWidget {
  const ChestIcon({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) => _Icon(size: size, painter: _paint);

  static void _paint(Canvas canvas) {
    canvas.drawOval(const Rect.fromLTWH(10, 82, 80, 12), Paint()..color = const Color(0x33000000));
    // الجسم
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(13, 47, 74, 40), const Radius.circular(5));
    canvas.drawRRect(body, _fill(body.outerRect, const [Color(0xFFA65F30), Color(0xFF6F3B1B)]));
    for (final x in [31.0, 49.0, 67.0]) {
      canvas.drawLine(Offset(x, 49), Offset(x, 85), _line(1.4, const Color(0x66301608)));
    }
    canvas.drawRRect(body, _line(3.2));
    // الغطا
    final lid = Path()
      ..moveTo(13, 49)
      ..cubicTo(13, 18, 87, 18, 87, 49)
      ..close();
    canvas.drawPath(lid, _fill(const Rect.fromLTWH(13, 24, 74, 26), const [Color(0xFFC27A42), Color(0xFF8A4D26)]));
    canvas.drawPath(lid, _line(3.2));
    // لمعة على الغطا (تحت الحافة بمسافة، ما تلمس الإطار)
    canvas.drawPath(
      Path()
        ..moveTo(19, 44)
        ..cubicTo(21, 37, 33, 32.5, 46, 32),
      _line(2.6, const Color(0x55FFFFFF)),
    );
    // أحزمة ذهبية: تنقص على شكل الصندوق (تتبع انحناء الغطا)، وبعدها نعيد إطاره فوقها
    final shape = Path()
      ..addRRect(body)
      ..addPath(lid, Offset.zero);
    canvas.save();
    canvas.clipPath(shape);
    for (final x in [24.0, 76.0]) {
      final band = RRect.fromRectAndRadius(Rect.fromLTWH(x - 5.5, 20, 11, 66), const Radius.circular(2));
      canvas.drawRRect(band, _fill(band.outerRect, _gold));
      canvas.drawRRect(band, _line(2.2));
    }
    canvas.restore();
    canvas.drawPath(lid, _line(3.2));
    canvas.drawRRect(body, _line(3.2));
    canvas.drawLine(const Offset(13, 49), const Offset(87, 49), _line(2.6));
    // القفل
    final plate = RRect.fromRectAndRadius(const Rect.fromLTWH(40, 41, 20, 22), const Radius.circular(5));
    canvas.drawRRect(plate, _fill(plate.outerRect, _gold));
    canvas.drawRRect(plate, _line(2.8));
    canvas.drawCircle(const Offset(50, 50.5), 3.4, Paint()..color = _ink);
    canvas.drawPath(
      Path()
        ..moveTo(48.6, 51)
        ..lineTo(51.4, 51)
        ..lineTo(52.4, 58.5)
        ..lineTo(47.6, 58.5)
        ..close(),
      Paint()..color = _ink,
    );
  }
}

/// بسطة سوق: مظلة حمرا بشرائط وطاولة خشب عليها ذهب (المتجر).
class StallIcon extends StatelessWidget {
  const StallIcon({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) => _Icon(size: size, painter: _paint);

  static void _paint(Canvas canvas) {
    canvas.drawOval(const Rect.fromLTWH(8, 84, 84, 11), Paint()..color = const Color(0x33000000));
    // الأعمدة
    for (final x in [16.0, 78.0]) {
      final pole = RRect.fromRectAndRadius(Rect.fromLTWH(x, 30, 6, 56), const Radius.circular(2));
      canvas.drawRRect(pole, Paint()..color = const Color(0xFF7A4520));
      canvas.drawRRect(pole, _line(2));
    }
    // الطاولة
    final table = RRect.fromRectAndRadius(const Rect.fromLTWH(12, 56, 76, 30), const Radius.circular(4));
    canvas.drawRRect(table, _fill(table.outerRect, const [Color(0xFFA9652F), Color(0xFF6F3B1B)]));
    for (final x in [31.0, 50.0, 69.0]) {
      canvas.drawLine(Offset(x, 58), Offset(x, 84), _line(1.4, const Color(0x66301608)));
    }
    canvas.drawRRect(table, _line(3));
    // ذهب على الطاولة
    for (final (x, w) in [(24.0, 15.0), (45.0, 18.0), (68.0, 14.0)]) {
      final heap = Path()
        ..moveTo(x - w / 2, 56)
        ..quadraticBezierTo(x, 56 - w * 1.1, x + w / 2, 56)
        ..close();
      canvas.drawPath(heap, _fill(Rect.fromLTWH(x - w / 2, 56 - w, w, w), _gold));
      canvas.drawPath(heap, _line(2));
    }
    // المظلة
    const l = 6.0, r = 94.0, top = 12.0, bottom = 38.0;
    final awning = Path()
      ..moveTo(l + 6, top)
      ..lineTo(r - 6, top)
      ..lineTo(r, bottom)
      ..lineTo(l, bottom)
      ..close();
    canvas.save();
    canvas.clipPath(awning);
    const n = 6;
    final w = (r - l) / n;
    for (var i = 0; i < n; i++) {
      final stripe = Rect.fromLTWH(l + w * i, top, w, bottom - top + 2);
      canvas.drawRect(
        stripe,
        i.isEven ? _fill(stripe, const [Color(0xFFE8503A), Color(0xFFB8281A)]) : _fill(stripe, const [Color(0xFFFFF4DA), Color(0xFFE7D2A4)]),
      );
    }
    canvas.restore();
    canvas.drawPath(awning, _line(3));
    // حافة مسننة تحت المظلة
    for (var i = 0; i < n; i++) {
      final scallop = Path()
        ..moveTo(l + w * i, bottom - .5)
        ..quadraticBezierTo(l + w * (i + .5), bottom + 12, l + w * (i + 1), bottom - .5)
        ..close();
      final red = i.isEven;
      canvas.drawPath(
        scallop,
        Paint()..color = red ? const Color(0xFFC5301F) : const Color(0xFFF0DDB2),
      );
      canvas.drawPath(scallop, _line(2.4));
    }
  }
}

/// رق ملفوف بختم أحمر (المهام والبريد).
class ScrollIcon extends StatelessWidget {
  const ScrollIcon({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) => _Icon(size: size, painter: _paint);

  static void _paint(Canvas canvas) {
    canvas.drawOval(const Rect.fromLTWH(14, 84, 72, 9), Paint()..color = const Color(0x33000000));
    final sheet = RRect.fromRectAndRadius(const Rect.fromLTWH(22, 14, 56, 66), const Radius.circular(5));
    canvas.drawRRect(sheet, _fill(sheet.outerRect, const [Color(0xFFFFF1CC), Color(0xFFE6C78C)]));
    canvas.drawRRect(sheet, _line(3));
    for (final y in [32.0, 44.0, 56.0]) {
      canvas.drawLine(Offset(32, y), Offset(68, y), _line(2.4, const Color(0x883A2412)));
    }
    // لفّة فوق وتحت
    for (final y in [12.0, 78.0]) {
      final roll = RRect.fromRectAndRadius(Rect.fromLTWH(15, y - 6, 70, 12), const Radius.circular(6));
      canvas.drawRRect(roll, _fill(roll.outerRect, const [Color(0xFFF7DFA6), Color(0xFFC79A55)]));
      canvas.drawRRect(roll, _line(3));
    }
    // ختم أحمر
    final c = const Offset(62, 66);
    canvas.drawCircle(c, 11, _fill(Rect.fromCircle(center: c, radius: 11), const [Color(0xFFE8503A), Color(0xFF9E2214)]));
    canvas.drawCircle(c, 11, _line(2.8));
    canvas.drawCircle(c, 5, _line(2, const Color(0x88FFD2B0)));
  }
}
