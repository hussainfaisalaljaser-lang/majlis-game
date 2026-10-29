import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/shop.dart';
import 'fx.dart';

// رسمات افكتات الموت بأسلوب التصميم الجديد: مسند مخمل أحمر وعليه الافكت، خطوط بنية غامقة سميكة وألوان دافية.
// كل شي ينرسم على مربع تصميم ١٠٠×١٠٠ ([paintDeathScene])؛ والمعاينة (المتجر وغرفة التبديل) واللعبة يرسمون نفس الأشكال.
//
// الوقت: [s] ثواني من بداية الافكت (قبلها المسند فاضي)، وهو اللي يحرك الدخول مرة وحدة.
// [idle] ساعة الحركات المستمرة (لهب يرمش، خفافيش تدور…)، تمشي دايم حتى بعد ما ينتهي الدخول.

/// لون الخط الغامق لكل الرسمات.
const deathInk = Color(0xFF2B140C);
const _w = 2.0;

double _seg(double t, double a, double b) => b == a ? (t >= b ? 1.0 : 0.0) : ((t - a) / (b - a)).clamp(0.0, 1.0);
double _out(double x) => 1 - math.pow(1 - x, 3).toDouble();
double _back(double x) => Curves.easeOutBack.transform(x);
double _lerp(double a, double b, double k) => a + (b - a) * k;

Paint _fill(Color c) => Paint()..color = c;

Paint _line(Color c, double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..color = c;

Paint _grad(Rect r, List<Color> colors, {List<double>? stops, bool horizontal = false}) =>
    Paint()
      ..shader = LinearGradient(
        begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
        end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
        colors: colors,
        stops: stops,
      ).createShader(r);

/// شكل بتعبئة وخط بني حواليه.
void _shape(Canvas c, Path p, Paint fill, {double w = _w, Color ink = deathInk}) {
  c.drawPath(p, fill);
  c.drawPath(p, _line(ink, w));
}

void _rrect(Canvas c, Rect r, double rad, Paint fill, {double w = _w, Color ink = deathInk}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(rad));
  c.drawRRect(rr, fill);
  if (w > 0) c.drawRRect(rr, _line(ink, w));
}

/// طبقة بشفافية (الباقي يرسم عادي لو الشفافية كاملة).
void _layer(Canvas c, double alpha, void Function() draw) {
  if (alpha >= .999) return draw();
  if (alpha <= .001) return;
  c.saveLayer(const Rect.fromLTWH(-20, -20, 140, 140), Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
  draw();
  c.restore();
}

// ───────── المسند

/// مسند مخمل أحمر (كرسي بذراعين) مرسوم بالأمام. [char] يغمّقه (نار، صاعقة).
void drawDeathChair(Canvas c, {double alpha = 1, double char = 0}) => _layer(c, alpha, () {
  Color k(int v) => Color.lerp(Color(v), const Color(0xFF2A1618), char)!;
  // ظل الأرض
  c.drawOval(Rect.fromCenter(center: const Offset(50, 90), width: 80, height: 8), _fill(const Color(0x4A000000)));
  // أرجل خشب مذهّب
  for (final x in const [21.0, 71.0]) {
    _rrect(c, Rect.fromLTWH(x, 80, 8, 10), 2.5, _grad(Rect.fromLTWH(x, 80, 8, 10), [k(0xFFE9B955), k(0xFF9C6620)]));
  }
  // الظهر
  final back = Path()
    ..moveTo(28, 72)
    ..lineTo(28, 40)
    ..cubicTo(28, 29, 37, 24, 50, 24)
    ..cubicTo(63, 24, 72, 29, 72, 40)
    ..lineTo(72, 72)
    ..close();
  _shape(c, back, _grad(const Rect.fromLTWH(28, 24, 44, 48), [k(0xFFB8304A), k(0xFF7A1628)]));
  final panel = Path()
    ..moveTo(33, 68)
    ..lineTo(33, 41)
    ..cubicTo(33, 33, 40, 29, 50, 29)
    ..cubicTo(60, 29, 67, 33, 67, 41)
    ..lineTo(67, 68)
    ..close();
  c.drawPath(panel, _grad(const Rect.fromLTWH(33, 29, 34, 39), [k(0xFFC9475F), k(0xFF8E1E32)]));
  c.drawPath(panel, _line(k(0xFFF0C25A), 1.3));
  // أزرار التنجيد
  for (final p in const [Offset(42, 42), Offset(58, 42), Offset(50, 52), Offset(42, 60), Offset(58, 60)]) {
    c.drawCircle(p, 1.7, _fill(k(0xFFE8B550)));
    c.drawCircle(p, 1.7, _line(deathInk.withValues(alpha: .55), .7));
  }
  // الذراعين
  for (final left in const [true, false]) {
    final x = left ? 13.0 : 69.0;
    final r = Rect.fromLTWH(x, 50, 18, 34);
    _rrect(c, r, 9, _grad(r, [k(0xFFB8304A), k(0xFF701225)], horizontal: true));
    // لفة الذراع من فوق
    c.drawOval(Rect.fromLTWH(x + 3, 52, 12, 8), _fill(k(0xFFD8596F).withValues(alpha: .85)));
  }
  // المقعد
  const seat = Rect.fromLTWH(26, 63, 48, 20);
  _rrect(c, seat, 8, _grad(seat, [k(0xFFD0475F), k(0xFF8A1B2E)]));
  c.drawRRect(
    RRect.fromRectAndRadius(const Rect.fromLTWH(29, 65.5, 42, 5), const Radius.circular(3)),
    _fill(Colors.white.withValues(alpha: .2)),
  );
  // حبل ذهبي أسفل المقعد وشراريب صغيرة
  c.drawLine(const Offset(30, 77), const Offset(70, 77), _line(k(0xFFF0C25A), 1.4));
  for (var i = 0; i < 9; i++) {
    c.drawCircle(Offset(31 + i * 4.75, 79.6), 1.1, _fill(k(0xFFE8B550)));
  }
});

// ───────── أدوات مشتركة

/// جمجمة بيضاء بحافة بنية. [w] عرضها.
void drawDeathSkull(Canvas c, Offset at, double w, {double alpha = 1}) => _layer(c, alpha, () {
  final h = w * .95;
  final sw = math.max(1.1, w * .06);
  final jaw = Rect.fromCenter(center: at + Offset(0, h * .3), width: w * .58, height: h * .36);
  _rrect(c, jaw, w * .12, _fill(const Color(0xFFE9E0C8)), w: sw);
  final cranium = Rect.fromCenter(center: at + Offset(0, -h * .07), width: w, height: h * .8);
  c.drawOval(cranium, _grad(cranium, [const Color(0xFFFFFDF3), const Color(0xFFE2D8BE)]));
  c.drawOval(cranium, _line(deathInk, sw));
  // أسنان
  for (final dx in const [-.12, 0.0, .12]) {
    c.drawLine(
      at + Offset(w * dx, h * .21),
      at + Offset(w * dx, h * .44),
      _line(deathInk.withValues(alpha: .8), sw * .55),
    );
  }
  // عيون وأنف
  for (final dx in const [-.22, .22]) {
    c.drawOval(
      Rect.fromCenter(center: at + Offset(w * dx, -h * .04), width: w * .25, height: w * .28),
      _fill(deathInk),
    );
  }
  c.drawPath(
    Path()
      ..moveTo(at.dx, at.dy + h * .1)
      ..lineTo(at.dx - w * .06, at.dy + h * .21)
      ..lineTo(at.dx + w * .06, at.dy + h * .21)
      ..close(),
    _fill(deathInk),
  );
  // لمعة
  c.drawArc(
    Rect.fromCenter(center: at + Offset(-w * .12, -h * .1), width: w * .62, height: h * .55),
    math.pi * 1.1,
    math.pi * .42,
    false,
    _line(Colors.white.withValues(alpha: .85), sw * .8),
  );
});

/// بتلة ورد: تتدلى للأسفل وطرفها مدبب. [w]/[h] حجمها، تتدور بزاوية [rot].
void _petal(Canvas c, Offset at, double w, double h, double rot, {double alpha = 1, double ink = 1.1}) {
  if (alpha <= .01) return;
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(rot);
  final p = Path()
    ..moveTo(0, h * .5)
    ..cubicTo(-w * .75, h * .15, -w * .62, -h * .5, 0, -h * .38)
    ..cubicTo(w * .62, -h * .5, w * .75, h * .15, 0, h * .5)
    ..close();
  final rect = Rect.fromLTWH(-w * .6, -h * .5, w * 1.2, h);
  _layer(c, alpha, () {
    _shape(c, p, _grad(rect, [const Color(0xFFFF6A80), const Color(0xFFC4203C)]), w: ink, ink: const Color(0xFF5A0E1C));
    c.drawArc(
      Rect.fromCenter(center: Offset(-w * .12, -h * .12), width: w * .5, height: h * .45),
      math.pi * 1.05,
      math.pi * .6,
      false,
      _line(Colors.white.withValues(alpha: .55), ink * .8),
    );
  });
  c.restore();
}

/// ندفة ثلج سداسية بيضاء بحافة زرقاء.
void _flake(Canvas c, Offset at, double r, double rot, {double alpha = 1}) {
  if (alpha <= .01 || r <= .1) return;
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(rot);
  _layer(c, alpha, () {
    for (final (color, width) in [(const Color(0xFF3F7FB6), r * .36), (Colors.white, r * .17)]) {
      final p = _line(color, width);
      for (var i = 0; i < 6; i++) {
        c.save();
        c.rotate(i * math.pi / 3);
        c.drawLine(Offset.zero, Offset(0, -r), p);
        c.drawLine(Offset(0, -r * .55), Offset(-r * .3, -r * .8), p);
        c.drawLine(Offset(0, -r * .55), Offset(r * .3, -r * .8), p);
        c.restore();
      }
    }
  });
  c.restore();
}

/// نجمة لمعة بأربع رؤوس بحافة خفيفة.
void _spark(Canvas c, Offset at, double r, Color color, {double alpha = 1}) {
  if (alpha <= .01 || r <= .2) return;
  final p = star4(at, r);
  _layer(c, alpha, () {
    c.drawPath(p, _fill(color));
    c.drawPath(p, _line(deathInk.withValues(alpha: .6), .8));
  });
}

// ───────── الغطا

void _cloth(Canvas c, double s, double idle, double chair) {
  drawDeathChair(c, alpha: chair);
  if (s <= 0) return;
  drawDeathCloth(c, s);
}

/// الغطا الرمادي وهو يطيح ويستقر ([s] ثواني من بداية السقوط؛ بعد ~١٫٢ يثبت).
void drawDeathCloth(Canvas c, double s) {
  final fall = _seg(s, 0, .55);
  final dy = -70 * (1 - fall * fall);
  final b = s > .55 ? math.exp(-5.5 * (s - .55)) * math.sin((s - .55) * 17) : 0.0;
  final tilt = math.sin(s * 11) * .07 * (1 - fall);
  c.save();
  c.translate(50, 84);
  c.rotate(tilt);
  c.scale(1 + .07 * b + .08 * (1 - fall), 1 - .09 * b);
  c.translate(-50, -84 + dy);
  final bell = Path()
    ..moveTo(50, 15)
    ..cubicTo(62, 15, 69, 24, 73, 38)
    ..cubicTo(78, 53, 86, 65, 93, 81)
    ..quadraticBezierTo(91, 88, 82, 84)
    ..quadraticBezierTo(75, 90, 67, 84)
    ..quadraticBezierTo(59, 90, 50, 84)
    ..quadraticBezierTo(41, 90, 33, 84)
    ..quadraticBezierTo(25, 90, 18, 84)
    ..quadraticBezierTo(10, 88, 8, 81)
    ..cubicTo(14, 65, 22, 53, 27, 38)
    ..cubicTo(31, 24, 38, 15, 50, 15)
    ..close();
  const r = Rect.fromLTWH(8, 15, 84, 76);
  c.drawPath(
    bell,
    _grad(
      r,
      const [Color(0xFF4F525D), Color(0xFF9FA3AE), Color(0xFF787B87), Color(0xFF4A4D58)],
      stops: const [0, .34, .68, 1],
      horizontal: true,
    ),
  );
  c.save();
  c.clipPath(bell);
  // ثنيات القماش
  for (final (x0, x1, w) in const [
    (41.0, 33.0, 3.6),
    (50.0, 50.0, 3.2),
    (59.0, 67.0, 3.6),
    (36.0, 20.0, 2.4),
    (64.0, 80.0, 2.4),
  ]) {
    final p = Path()
      ..moveTo(x0, 30)
      ..quadraticBezierTo(_lerp(x0, x1, .35), 55, x1, 86);
    c.drawPath(p, _line(const Color(0xFF2A2C34).withValues(alpha: .38), w));
    c.drawPath(p.shift(const Offset(2.4, 0)), _line(Colors.white.withValues(alpha: .2), w * .45));
  }
  // لمعة الكتف
  c.drawOval(
    Rect.fromCenter(center: const Offset(42, 32), width: 15, height: 26),
    _fill(Colors.white.withValues(alpha: .2)),
  );
  c.restore();
  c.drawPath(bell, _line(const Color(0xFF1F2027), _w));
  c.restore();
}

// ───────── دخان

const _cloud = <(double, double, double)>[
  (50, 30, 15),
  (30, 40, 14),
  (70, 40, 14),
  (18, 58, 13),
  (82, 58, 13),
  (50, 50, 20),
  (28, 74, 13),
  (72, 74, 13),
  (50, 74, 15),
  (38, 62, 16),
  (62, 62, 16),
];

void _smoke(Canvas c, double s, double idle, double chair) {
  drawDeathChair(c, alpha: chair);
  if (s <= 0) return;
  const from = Offset(50, 68);
  // طلعة دخان سريعة تغطي المسند
  for (var i = 0; i < 9; i++) {
    final k = _seg(s, i * .03, .55 + i * .03);
    if (k <= 0 || k >= 1) continue;
    final a = i * 2.4;
    final p = from + Offset(math.cos(a) * 38 * k, math.sin(a) * 26 * k - 10 * k);
    c.drawCircle(p, 6 + 12 * k, _fill(const Color(0xFFD9DDE6).withValues(alpha: .55 * (1 - k))));
  }
  // السحابة: أولاً الحافة (اتحاد الدوائر)، وبعدين التعبئة
  final pos = <Offset>[];
  final rad = <double>[];
  for (var i = 0; i < _cloud.length; i++) {
    final (x, y, r) = _cloud[i];
    final k = _back(_seg(s, i * .045, .7 + i * .045));
    final bob = math.sin(idle * 1.7 + i * 1.9);
    pos.add(Offset(_lerp(50, x, k) + bob * .6, _lerp(68, y, k) + math.cos(idle * 1.3 + i) * 1.1));
    rad.add(r * k * (1 + .035 * bob));
  }
  for (var i = 0; i < pos.length; i++) {
    c.drawCircle(pos[i], rad[i] + _w, _fill(const Color(0xFF3A3D4C)));
  }
  for (var i = 0; i < pos.length; i++) {
    final p = pos[i], r = rad[i];
    if (r <= .1) continue;
    c.drawCircle(
      p,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.45),
          radius: 1.15,
          colors: const [Color(0xFFF4F6FA), Color(0xFFC9CEDA), Color(0xFF8F96A9)],
          stops: const [0, .55, 1],
        ).createShader(Rect.fromCircle(center: p, radius: r)),
    );
    c.drawCircle(p, r, _line(const Color(0xFF3A3D4C).withValues(alpha: .35), 1));
  }
  // خيوط دخان تطلع من فوق وتختفي
  final wisp = _seg(s, 1.2, 1.8);
  for (var i = 0; i < 3; i++) {
    final q = ((idle * .22 + i / 3) % 1);
    final p = Offset(40 + i * 10 + math.sin(q * 6 + i) * 3, 16 - q * 14);
    c.drawCircle(p, 3 + q * 4, _fill(const Color(0xFFD9DDE6).withValues(alpha: .8 * wisp * (1 - q))));
  }
  // الجمجمة تطلع وسط الدخان
  final sk = _seg(s, .9, 1.5);
  if (sk > 0) {
    final pop = _back(sk);
    drawDeathSkull(c, Offset(50, 54 + math.sin(idle * 1.5) * .8), 30 * (.55 + .45 * pop), alpha: _seg(s, .9, 1.2));
  }
}

// ───────── رمل

void _sand(Canvas c, double s, double idle, double chair) {
  drawDeathChair(c, alpha: chair);
  if (s <= 0) return;
  final grow = _out(_seg(s, .1, 1.9));
  // الرمل ينسكب من فوق
  final pour = _seg(s, 0, .15) * (1 - _seg(s, 1.7, 2.1));
  if (pour > 0) {
    final topY = _lerp(95, 24, grow);
    final w = 3.2 * pour;
    final stream = Path()
      ..moveTo(50 - w, -6)
      ..lineTo(50 + w, -6)
      ..lineTo(50 + w * 1.6, topY)
      ..lineTo(50 - w * 1.6, topY)
      ..close();
    c.drawPath(
      stream,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00EBC25E), Color(0xFFEBC25E)],
          stops: [0, .3],
        ).createShader(Rect.fromLTRB(40, -6, 60, topY)),
    );
    for (var i = 0; i < 12; i++) {
      final q = ((s * 1.9 + i * .083) % 1);
      final y = -6 + q * (topY + 6);
      c.drawCircle(
        Offset(50 + (rnd(i, 1) - .5) * 9 * pour, y),
        .9 + rnd(i, 2) * 1.2,
        _fill((rnd(i, 3) > .5 ? const Color(0xFFFFE9A6) : const Color(0xFFC48B3B)).withValues(alpha: _seg(y, -6, 14))),
      );
    }
  }
  // الكومة
  final mound = Path()
    ..moveTo(3, 88)
    ..cubicTo(4, 66, 18, 40, 36, 28)
    ..cubicTo(42, 24, 46, 20, 50, 20)
    ..cubicTo(54, 20, 58, 24, 64, 28)
    ..cubicTo(82, 40, 96, 66, 97, 88)
    ..cubicTo(82, 95, 18, 95, 3, 88)
    ..close();
  c.save();
  c.translate(50, 90);
  c.scale(_lerp(.55, 1, grow), math.max(.02, grow));
  c.translate(-50, -90);
  c.drawPath(
    mound,
    _grad(const Rect.fromLTWH(3, 28, 94, 68), const [Color(0xFFF9E08B), Color(0xFFE8B95A), Color(0xFFC08A38)]),
  );
  c.save();
  c.clipPath(mound);
  // ظل الجهة اليمين
  c.drawPath(
    Path()
      ..moveTo(54, 22)
      ..cubicTo(66, 30, 80, 46, 90, 66)
      ..cubicTo(94, 76, 98, 84, 100, 90)
      ..lineTo(100, 100)
      ..lineTo(52, 100)
      ..close(),
    _fill(const Color(0xFFB5792E).withValues(alpha: .38)),
  );
  // موجات الرمل
  for (final (y, x0, x1) in const [(46.0, 32.0, 68.0), (60.0, 20.0, 80.0), (73.0, 12.0, 88.0), (83.0, 8.0, 92.0)]) {
    c.drawPath(
      Path()
        ..moveTo(x0, y)
        ..quadraticBezierTo((x0 + x1) / 2, y - 8, x1, y),
      _line(const Color(0xFF9A6322).withValues(alpha: .5), 1.4),
    );
  }
  // لمعة اليسار
  c.drawPath(
    Path()
      ..moveTo(18, 66)
      ..quadraticBezierTo(26, 44, 40, 32),
    _line(Colors.white.withValues(alpha: .55), 2.6),
  );
  for (var i = 0; i < 16; i++) {
    c.drawCircle(
      Offset(14 + rnd(i, 4) * 72, 56 + rnd(i, 5) * 32),
      .7 + rnd(i, 6) * .7,
      _fill(rnd(i, 7) > .5 ? const Color(0xFFFFF0B8) : const Color(0xFF8E5C1F)),
    );
  }
  c.restore();
  c.drawPath(mound, _line(const Color(0xFF4A2B10), _w));
  c.restore();
  // الجمجمة تنزل فوقها
  final drop = _seg(s, 1.5, 2.0);
  if (drop > 0) {
    final bounce = drop < 1 ? 0.0 : math.exp(-9 * (s - 2.0)) * math.sin((s - 2.0) * 22) * 2.5;
    final y = _lerp(-10, 29, drop * drop) - bounce.abs();
    drawDeathSkull(c, Offset(50, y), 19);
    // غبار الارتطام
    final dust = _seg(s, 2.0, 2.6);
    if (dust > 0 && dust < 1) {
      for (var i = 0; i < 6; i++) {
        final a = -math.pi + i * math.pi / 5;
        c.drawCircle(
          Offset(50 + math.cos(a) * (6 + 12 * dust), 36 + math.sin(a) * (4 + 5 * dust)),
          1.6,
          _fill(const Color(0xFFF2D488).withValues(alpha: .9 * (1 - dust))),
        );
      }
    }
  }
  // رمل يتطاير من القمة مع الهوا
  if (s > 2.1) {
    for (var i = 0; i < 4; i++) {
      final q = ((idle * .35 + i * .27) % 1);
      c.drawCircle(
        Offset(56 + q * 30, 32 + q * 6 + math.sin(q * 9 + i) * 2),
        1.1,
        _fill(const Color(0xFFE7BC5C).withValues(alpha: .9 * (1 - q))),
      );
    }
  }
}

// ───────── ورد

const _restPetals = <(double, double, double, double)>[
  // x, y، دوران، حجم
  (36, 72, .5, 1.0),
  (60, 74, -.7, 1.0),
  (50, 68, 1.9, .9),
  (22, 86, 1.2, 1.0),
  (78, 87, -1.3, 1.0),
  (44, 90, .2, .85),
  (66, 90, 2.4, .9),
  (12, 78, -.4, .8),
  (88, 76, .9, .85),
];

void _petals(Canvas c, double s, double idle, double chair) {
  drawDeathChair(c, alpha: chair);
  if (s <= 0) return;
  // بتلات تنزل وتستقر على المسند والأرض
  for (var i = 0; i < _restPetals.length; i++) {
    final (x, y, rot, size) = _restPetals[i];
    final start = rnd(i, 1) * .7;
    final dur = 1.0 + rnd(i, 2) * .8;
    final k = _seg(s, start, start + dur);
    if (k <= 0) continue;
    final sway = math.sin(k * 9 + i) * 7 * (1 - k);
    final h0 = -14 - rnd(i, 3) * 20;
    _petal(
      c,
      Offset(x + sway, _lerp(h0, y, k * k * (3 - 2 * k) * .35 + k * .65)),
      10 * size,
      14 * size,
      rot + (1 - k) * 4.5,
    );
  }
  // بتلات تظل تنزل
  final on = _seg(s, 1.0, 1.8);
  for (var i = 0; i < 7; i++) {
    final q = ((idle * .12 + i / 7 + rnd(i, 4) * .1) % 1);
    final x = 12 + rnd(i, 5) * 76 + math.sin(q * 7 + i * 2) * 7;
    final y = -4 + q * 90;
    _petal(
      c,
      Offset(x, y),
      9 + rnd(i, 6) * 2,
      13 + rnd(i, 6) * 3,
      math.sin(q * 6 + i) * 1.2 + i,
      alpha: on * math.min(1, q * 8) * (1 - _seg(q, .86, 1)),
    );
  }
}

// ───────── جليد

void _ice(Canvas c, double s, double idle, double chair) {
  drawDeathChair(c, alpha: chair, char: 0);
  if (s <= 0) return;
  final f = _out(_seg(s, .1, 1.5));
  final front = _lerp(92, 8, f);
  c.save();
  c.clipRect(Rect.fromLTRB(-10, front, 110, 110));
  // قالب الجليد: الوجه الأمامي والوجه العلوي
  final faceR = const Rect.fromLTWH(8, 22, 84, 68);
  final top = Path()
    ..moveTo(12, 23)
    ..lineTo(24, 11)
    ..lineTo(76, 11)
    ..lineTo(88, 23)
    ..close();
  final shards = Path()
    ..moveTo(28, 12)
    ..lineTo(32, 2)
    ..lineTo(38, 11)
    ..moveTo(48, 11)
    ..lineTo(53, -1)
    ..lineTo(60, 11)
    ..moveTo(68, 11)
    ..lineTo(74, 4)
    ..lineTo(78, 12);
  const edge = Color(0xFF1F4770);
  // الجسم الأزرق الشفاف (المسند يبان من خلاله)
  _rrect(
    c,
    faceR,
    8,
    _grad(faceR, [const Color(0xB8D5F1FF), const Color(0xA88AC9F0), const Color(0xB86BB1E6)]),
    ink: edge,
    w: _w + .4,
  );
  _shape(
    c,
    top,
    _grad(const Rect.fromLTWH(12, 11, 76, 12), [const Color(0xFFF2FBFF), const Color(0xFFBFE6FA)]),
    ink: edge,
    w: _w + .4,
  );
  _shape(c, shards, _fill(const Color(0xFFE6F7FF)), ink: edge);
  // لمعات وتشققات
  c.drawLine(const Offset(17, 34), const Offset(17, 62), _line(Colors.white.withValues(alpha: .85), 3.4));
  c.drawLine(const Offset(24, 34), const Offset(24, 41), _line(Colors.white.withValues(alpha: .85), 3.4));
  c.drawPath(
    Path()
      ..moveTo(80, 28)
      ..lineTo(74, 42)
      ..lineTo(80, 52)
      ..lineTo(72, 66),
    _line(Colors.white.withValues(alpha: .7), 1.3),
  );
  c.drawPath(
    Path()
      ..moveTo(86, 74)
      ..lineTo(77, 80)
      ..lineTo(81, 86),
    _line(Colors.white.withValues(alpha: .6), 1.1),
  );
  // لمعة تمر على القالب
  final gl = (idle * .25) % 1;
  if (gl < .35 && s > 1.4) {
    final x = _lerp(-10, 110, gl / .35);
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(faceR, const Radius.circular(8)));
    c.drawPath(
      Path()
        ..moveTo(x, 10)
        ..lineTo(x + 8, 10)
        ..lineTo(x - 6, 92)
        ..lineTo(x - 14, 92)
        ..close(),
      _fill(Colors.white.withValues(alpha: .5)),
    );
    c.restore();
  }
  c.restore();
  // خط الصقيع وهو يرتفع
  if (f < 1) {
    c.drawLine(Offset(8, front), Offset(92, front), _line(Colors.white.withValues(alpha: .9 * (1 - f)), 2.6));
  }
  // شظايا تتطاير لما يكتمل التجمّد
  final burst = _seg(s, 1.3, 2.0);
  if (burst > 0 && burst < 1) {
    for (var i = 0; i < 7; i++) {
      final a = -math.pi * (.1 + .8 * rnd(i, 1));
      final d = (14 + 26 * rnd(i, 2)) * _out(burst);
      final sz = 2.2 + rnd(i, 3) * 2.2;
      c.save();
      c.translate(15 + rnd(i, 4) * 70 + math.cos(a) * d, 20 + math.sin(a) * d + burst * burst * 16);
      c.rotate(a + burst * 4);
      final tri = Path()
        ..moveTo(0, -sz)
        ..lineTo(sz * .7, sz * .8)
        ..lineTo(-sz * .7, sz * .8)
        ..close();
      _shape(
        c,
        tri,
        _fill(Colors.white.withValues(alpha: 1 - burst)),
        w: 1.1,
        ink: const Color(0xFF1F4770).withValues(alpha: 1 - burst),
      );
      c.restore();
    }
  }
  // ندف ثلج حوله
  const flakes = [(8.0, 14.0, 6.5), (93.0, 28.0, 5.5), (95.0, 78.0, 6.0), (6.0, 66.0, 5.0), (80.0, 6.0, 4.5)];
  for (var i = 0; i < flakes.length; i++) {
    final (x, y, r) = flakes[i];
    final k = _back(_seg(s, 1.0 + i * .12, 1.6 + i * .12));
    final tw = .75 + .25 * math.sin(idle * 2.2 + i * 1.6);
    _flake(
      c,
      Offset(x, y + math.sin(idle + i) * 1.2),
      r * k * (.9 + .1 * tw),
      idle * .35 + i,
      alpha: k.clamp(0.0, 1.0),
    );
  }
}

// ───────── نار

Path _flamePath(double cx, double by, double w, double h, double sway) => Path()
  ..moveTo(cx - w / 2, by)
  ..cubicTo(cx - w * .66, by - h * .3, cx - w * .3 + sway * .4, by - h * .56, cx + sway, by - h)
  ..cubicTo(cx + w * .12 + sway * .5, by - h * .62, cx + w * .68, by - h * .38, cx + w / 2, by)
  ..quadraticBezierTo(cx, by + h * .06, cx - w / 2, by)
  ..close();

/// لهبة بثلاث طبقات (أحمر برتقالي، برتقالي، أصفر).
void _flame(Canvas c, double cx, double by, double w, double h, double sway) {
  if (h < 1) return;
  final outer = _flamePath(cx, by, w, h, sway);
  _shape(
    c,
    outer,
    _grad(
      Rect.fromLTWH(cx - w / 2, by - h, w, h),
      const [Color(0xFFFFA126), Color(0xFFF2501B), Color(0xFFD72A18)],
      stops: const [0, .55, 1],
    ),
    w: 2.1,
    ink: const Color(0xFF4A1408),
  );
  final mid = _flamePath(cx, by - h * .02, w * .68, h * .72, sway * .7);
  c.drawPath(
    mid,
    _grad(Rect.fromLTWH(cx - w / 3, by - h * .74, w * .68, h * .72), const [Color(0xFFFFE15A), Color(0xFFFFA82A)]),
  );
  final inner = _flamePath(cx, by - h * .03, w * .36, h * .42, sway * .4);
  c.drawPath(inner, _fill(const Color(0xFFFFF6BC)));
}

const _fireBack = <(double, double, double, int)>[
  // x، عرض، طول، ترتيب الدخول
  (50, 46, 86, 0),
  (30, 36, 72, 1),
  (70, 36, 72, 1),
];
const _fireFront = <(double, double, double, int)>[
  (50, 26, 24, 0),
  (38, 22, 32, 1),
  (62, 22, 34, 1),
  (23, 24, 56, 2),
  (77, 24, 58, 2),
  (10, 22, 44, 3),
  (90, 22, 46, 3),
];

void _fire(Canvas c, double s, double idle, double chair) {
  final burn = _seg(s, 0, .9);
  // وهج برتقالي وراها
  if (s > 0) {
    final r = Rect.fromCircle(center: const Offset(50, 58), radius: 56);
    c.drawCircle(
      const Offset(50, 58),
      56,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF9A2E).withValues(alpha: .5 * burn),
            const Color(0x00FF9A2E),
          ],
        ).createShader(r),
    );
  }
  double flick(int i, double base) => base * (1 + .07 * math.sin(idle * 9 + i * 2.3) + .04 * math.sin(idle * 15 + i));
  void flames(List<(double, double, double, int)> list, int salt) {
    for (var i = 0; i < list.length; i++) {
      final (x, w, h, order) = list[i];
      final k = _back(_seg(s, .02 + order * .1, .7 + order * .1));
      _flame(c, x, 91, w * (.5 + .5 * k), flick(i + salt, h * k), math.sin(idle * 5.5 + i * 1.7 + salt) * 3.2);
    }
  }

  if (s > 0) flames(_fireBack, 0);
  drawDeathChair(c, alpha: chair, char: .4 * _seg(s, 0, 1.4));
  if (s <= 0) return;
  flames(_fireFront, 4);
  // شرر يطلع
  final em = _seg(s, .5, 1.2);
  for (var i = 0; i < 7; i++) {
    final q = ((idle * .45 + i * .143 + rnd(i, 1)) % 1);
    c.drawCircle(
      Offset(24 + rnd(i, 2) * 52 + math.sin(q * 8 + i) * 4, 76 - q * 62),
      1 + rnd(i, 3) * 1.2,
      _fill(Color.lerp(const Color(0xFFFFE070), const Color(0xFFFF7A22), q)!.withValues(alpha: em * (1 - q * q))),
    );
  }
}

// ───────── خفافيش

/// خفاش: [at] مكانه، [size] حجمه (١ = جناحين بعرض ٢٤ وحدة)، [flap] رفرفة الجناح (−١…١).
void _bat(Canvas c, Offset at, double size, double flap) {
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(size);
  const wing = Color(0xFF47356E);
  const body = Color(0xFF21163A);
  const ink = Color(0xFF0D0716);
  final wingPath = Path()
    ..moveTo(0, -1.5)
    ..quadraticBezierTo(5, -7.5, 12.5, -3.8)
    ..quadraticBezierTo(11, -1.2, 9.4, 1.9)
    ..quadraticBezierTo(8, .6, 6.6, 3.8)
    ..quadraticBezierTo(5, 2.2, 3.2, 5.2)
    ..quadraticBezierTo(1.6, 3, 0, 4)
    ..close();
  for (final sx in const [-1.0, 1.0]) {
    c.save();
    c.scale(sx, 1);
    c.translate(1.5, -1);
    c.rotate(-.55 + flap * .62);
    c.drawPath(wingPath, _grad(const Rect.fromLTWH(0, -8, 13, 14), [const Color(0xFF6A52A0), wing], horizontal: true));
    c.drawPath(wingPath, _line(ink, 1.15));
    // عظمة الجناح
    c.drawLine(const Offset(0.5, -1.5), const Offset(9, 1.4), _line(ink.withValues(alpha: .5), .6));
    c.restore();
  }
  // ودنين
  for (final sx in const [-1.0, 1.0]) {
    final ear = Path()
      ..moveTo(sx * 1.2, -7)
      ..lineTo(sx * 3.4, -11)
      ..lineTo(sx * 3.7, -6.4)
      ..close();
    _shape(c, ear, _fill(body), w: 1.0, ink: ink);
  }
  final bodyR = Rect.fromCenter(center: const Offset(0, -.5), width: 7.6, height: 11);
  c.drawOval(bodyR, _grad(bodyR, const [Color(0xFF3A2A5E), body]));
  c.drawOval(bodyR, _line(ink, 1.1));
  // عيون وأنياب
  for (final sx in const [-1.0, 1.0]) {
    c.drawCircle(Offset(sx * 1.9, -3.1), 1.15, _fill(const Color(0xFFFFE14D)));
    c.drawCircle(Offset(sx * 1.9, -3.1), .5, _fill(ink));
  }
  c.drawLine(const Offset(-1, 1.4), const Offset(-.7, 2.7), _line(Colors.white, .7));
  c.drawLine(const Offset(1, 1.4), const Offset(.7, 2.7), _line(Colors.white, .7));
  c.restore();
}

const _batList = <(double, double, double, double, double)>[
  // مدار: زاوية البداية، السرعة، حجم الخفاش، نصف قطر أفقي، نصف قطر عمودي
  (0.4, .55, 1.0, 32, 22),
  (1.9, -.7, .8, 34, 20),
  (3.5, .65, .9, 27, 26),
  (5.0, -.5, .75, 33, 16),
  (2.7, .8, 1.05, 26, 24),
  (4.4, -.6, .7, 35, 20),
  (0.9, .45, .6, 22, 28),
  (3.9, -.85, .65, 25, 26),
];

void _bats(Canvas c, double s, double idle, double chair) {
  drawDeathChair(c, alpha: chair, char: .25 * _seg(s, 0, 1.2));
  if (s <= 0) return;
  // ضباب بنفسجي خفيف تحت
  final mist = _seg(s, .2, 1.2);
  c.drawOval(
    Rect.fromCenter(center: const Offset(50, 88), width: 86, height: 14),
    _fill(const Color(0xFF6B3FA0).withValues(alpha: .16 * mist)),
  );
  for (var i = 0; i < _batList.length; i++) {
    final (phase, speed, size, rx, ry) = _batList[i];
    final k = _out(_seg(s, i * .07, .9 + i * .07));
    if (k <= 0) continue;
    final a = phase + idle * speed;
    final orbit = Offset(50 + math.cos(a) * rx, 36 + math.sin(a) * ry * .75 + math.sin(idle * 2.1 + i) * 2.2);
    final p = Offset.lerp(const Offset(50, 64), orbit, k)!;
    final flap = math.sin(idle * 15 + i * 1.7);
    _bat(c, p, size * (.4 + .6 * k) * 1.3, flap);
  }
}

// ───────── صاعقة

Path _bolt({double inset = 0}) => Path()
  ..moveTo(55 + inset, 0 + inset)
  ..lineTo(76 - inset, 0 + inset)
  ..lineTo(63, 25)
  ..lineTo(78 - inset * 1.4, 25)
  ..lineTo(41, 70)
  ..lineTo(50, 38)
  ..lineTo(33 + inset * 1.4, 38)
  ..close();

void _lightning(Canvas c, double s, double idle, double chair) {
  drawDeathChair(c, alpha: chair, char: .78 * _seg(s, .05, .4));
  if (s <= 0) return;
  final strike = _seg(s, 0, .1);
  // وميض الضربة + وهج
  final flash = (1 - _seg(s, .03, .4)) * strike;
  final pulse = s > 1 ? math.pow(math.max(0, math.sin(idle * 1.9)), 14).toDouble() : 0.0;
  final glow = math.max(flash, pulse * .55);
  if (glow > 0) {
    c.drawCircle(
      const Offset(50, 56),
      62,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: .85 * glow),
            const Color(0xFFFFE066).withValues(alpha: .4 * glow),
            const Color(0x00FFE066),
          ],
          stops: const [0, .35, 1],
        ).createShader(Rect.fromCircle(center: const Offset(50, 56), radius: 62)),
    );
  }
  // وميضات إعادة الضربة
  double blink = 1;
  if (s > .35 && s < 1.0) blink = (math.sin(s * 38) > -.2 ? 1 : .25);
  final alpha = blink * (s > 1.4 ? .9 + .1 * math.sin(idle * 31) : 1);
  c.save();
  c.clipRect(Rect.fromLTRB(0, -10, 100, _lerp(-10, 80, strike)));
  _layer(c, alpha, () {
    c.drawPath(_bolt(), _line(const Color(0xFFFFB300).withValues(alpha: .45), 7));
    _shape(
      c,
      _bolt(),
      _grad(const Rect.fromLTWH(33, 0, 45, 70), const [Color(0xFFFFF27A), Color(0xFFFFC61A), Color(0xFFFF9A0A)]),
      w: 2.3,
    );
    c.drawPath(
      Path()
        ..moveTo(60, 4)
        ..lineTo(68, 4)
        ..lineTo(56, 27)
        ..lineTo(60, 27)
        ..lineTo(46, 52)
        ..lineTo(51, 31)
        ..lineTo(47, 31)
        ..close(),
      _fill(Colors.white.withValues(alpha: .75)),
    );
  });
  c.restore();
  // الشرر عند نقطة الضربة
  const hit = Offset(46, 66);
  final burst = _seg(s, .08, 1.0);
  for (var i = 0; i < 10; i++) {
    final a = i * math.pi * 2 / 10 + rnd(i, 1) * .4;
    final d = 6 + _out(burst) * (14 + rnd(i, 2) * 12);
    final p = hit + Offset(math.cos(a) * d, math.sin(a) * d * .8);
    final alive = (1 - burst) * strike;
    if (alive > 0) {
      c.drawLine(
        p,
        p + Offset(math.cos(a), math.sin(a)) * 4.5,
        _line(const Color(0xFFFFE23A).withValues(alpha: alive), 2),
      );
    }
  }
  // شرارات مستمرة
  if (s > .6) {
    for (var i = 0; i < 4; i++) {
      final tw = math.max(0.0, math.sin(idle * 3.1 + i * 2.2));
      final p = hit + Offset((i - 1.5) * 14 + math.sin(i * 5) * 4, -4 - (i % 2) * 8);
      _spark(c, p, 3.4 * tw, const Color(0xFFFFE23A), alpha: tw);
    }
  }
}

// ───────── شبح

void _ghostBody(Canvas c, double idle, {double wobble = 1}) {
  final wave = math.sin(idle * 3.2) * 1.6 * wobble;
  const ink = Color(0xFF332F5B);
  // اليدين
  final armW = math.sin(idle * 3) * .22 * wobble;
  for (final sx in const [-1.0, 1.0]) {
    c.save();
    c.translate(50 + sx * 17, 41);
    c.rotate(sx * (.7 + armW * sx));
    final r = Rect.fromCenter(center: const Offset(0, 5), width: 8, height: 15);
    c.drawOval(r, _fill(const Color(0xFFF4F6FF)));
    c.drawOval(r, _line(ink, 1.8));
    c.restore();
  }
  final body = Path()
    ..moveTo(31, 60)
    ..lineTo(31, 30)
    ..cubicTo(31, 14, 40, 8, 50, 8)
    ..cubicTo(60, 8, 69, 14, 69, 30)
    ..lineTo(69, 60 + wave)
    ..quadraticBezierTo(65, 67 - wave, 59.5, 61)
    ..quadraticBezierTo(54.5, 56 + wave, 50, 62)
    ..quadraticBezierTo(45.5, 68 - wave, 40.5, 61)
    ..quadraticBezierTo(35, 56 + wave, 31, 60)
    ..close();
  const rect = Rect.fromLTWH(31, 8, 38, 60);
  c.drawPath(
    body,
    _grad(rect, const [Color(0xFFFFFFFF), Color(0xFFF1F4FF), Color(0xFFCDD6F0)], stops: const [0, .55, 1]),
  );
  c.save();
  c.clipPath(body);
  c.drawOval(
    Rect.fromCenter(center: const Offset(40, 24), width: 9, height: 20),
    _fill(Colors.white.withValues(alpha: .7)),
  );
  c.restore();
  c.drawPath(body, _line(ink, 2.1));
  // الوجه
  for (final sx in const [-1.0, 1.0]) {
    final e = Rect.fromCenter(center: Offset(50 + sx * 6.4, 33), width: 5.4, height: 7.6);
    c.drawOval(e, _fill(const Color(0xFF1B1633)));
    c.drawCircle(Offset(50 + sx * 6.4 - .9, 31), 1.2, _fill(Colors.white));
    c.drawOval(
      Rect.fromCenter(center: Offset(50 + sx * 10.5, 40), width: 5, height: 3),
      _fill(const Color(0xFFFF9FB2).withValues(alpha: .7)),
    );
  }
  c.drawPath(
    Path()
      ..moveTo(46.5, 41)
      ..quadraticBezierTo(50, 45.5, 53.5, 41),
    _line(const Color(0xFF1B1633), 1.6),
  );
  // العمامة البيضاء
  final turban = Path()
    ..moveTo(32.5, 22)
    ..cubicTo(32, 10, 41, 4, 50, 4)
    ..cubicTo(59, 4, 68, 10, 67.5, 22)
    ..quadraticBezierTo(50, 17, 32.5, 22)
    ..close();
  const tr = Rect.fromLTWH(32, 4, 36, 18);
  c.drawPath(turban, _grad(tr, const [Color(0xFFFFFFFF), Color(0xFFEFE6D2)]));
  c.drawPath(turban, _line(ink, 1.9));
  for (final (x0, y0, x1, y1) in const [(36.0, 18.0, 50.0, 7.0), (42.0, 19.0, 59.0, 7.0), (50.0, 19.5, 65.0, 10.0)]) {
    c.drawPath(
      Path()
        ..moveTo(x0, y0)
        ..quadraticBezierTo((x0 + x1) / 2 - 1, (y0 + y1) / 2 - 1, x1, y1),
      _line(const Color(0xFFB9A980).withValues(alpha: .9), 1.1),
    );
  }
  c.drawCircle(const Offset(50, 17), 2.1, _fill(const Color(0xFFE8B550)));
  c.drawCircle(const Offset(50, 17), 2.1, _line(ink, 1));
}

void _ghost(Canvas c, double s, double idle, double chair) {
  drawDeathChair(c, alpha: chair);
  if (s <= 0) return;
  final rise = _out(_seg(s, .1, 1.7));
  final a = _seg(s, .1, .8);
  // هالة ناعمة
  c.drawCircle(
    Offset(50, 38 + (1 - rise) * 24),
    32,
    Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFDDE6FF).withValues(alpha: .65 * a),
          const Color(0x00DDE6FF),
        ],
      ).createShader(Rect.fromCircle(center: Offset(50, 38 + (1 - rise) * 24), radius: 32)),
  );
  final bob = math.sin(idle * 2.1) * 2.4;
  final sway = math.sin(idle * 1.6) * .06;
  c.save();
  c.translate(50, 64);
  c.rotate(sway * (.3 + .7 * rise));
  final sc = .72 + .28 * rise;
  c.scale(sc);
  c.translate(-50, -64 + (1 - rise) * 28 + bob * rise);
  _layer(c, a, () => _ghostBody(c, idle));
  c.restore();
  // لمعات صغيرة
  final tw = _seg(s, 1.4, 2.0);
  for (var i = 0; i < 3; i++) {
    final k = math.max(0.0, math.sin(idle * 2.4 + i * 2.1));
    _spark(
      c,
      Offset(i == 0 ? 24 : (i == 1 ? 78 : 70), i == 0 ? 20 : (i == 1 ? 30 : 8)),
      3.2 * k * tw,
      Colors.white,
      alpha: k * tw,
    );
  }
}

// ───────── تمثال ذهب

const _goldHi = Color(0xFFFFF0A8);
const _goldMid = Color(0xFFF3B930);
const _goldLo = Color(0xFFB87A16);
const _goldInk = Color(0xFF4A2A08);

Paint _goldPaint(Rect r, {bool horizontal = false}) =>
    _grad(r, const [_goldHi, _goldMid, _goldLo], stops: const [0, .5, 1], horizontal: horizontal);

/// مستطيل مدور مائل حول مركزه.
Path _tilted(double cx, double cy, double w, double h, double rad, double angle) {
  final co = math.cos(angle), si = math.sin(angle);
  final m = Float64List.fromList([co, si, 0, 0, -si, co, 0, 0, 0, 0, 1, 0, cx, cy, 0, 1]);
  return (Path()..addRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), Radius.circular(rad)),
      ))
      .transform(m);
}

/// أجزاء التمثال (ذهب): بالترتيب من ورا لقدام. شيخ جالس بثوبه وعمامته ويدينه على ركبتيه.
List<Path> _statueParts() => [
  // القدمين
  Path()..addOval(Rect.fromCenter(center: const Offset(41, 88), width: 15, height: 7.5)),
  Path()..addOval(Rect.fromCenter(center: const Offset(59, 88), width: 15, height: 7.5)),
  // الثوب من الركبة للأرض
  Path()
    ..moveTo(31, 68)
    ..lineTo(69, 68)
    ..lineTo(72, 85)
    ..cubicTo(63, 90, 37, 90, 28, 85)
    ..close(),
  // الجذع والحضن
  Path()
    ..moveTo(35, 47)
    ..cubicTo(35, 41, 42, 39, 50, 39)
    ..cubicTo(58, 39, 65, 41, 65, 47)
    ..lineTo(68, 62)
    ..cubicTo(73, 64, 75, 70, 71, 75)
    ..cubicTo(60, 79, 40, 79, 29, 75)
    ..cubicTo(25, 70, 27, 64, 32, 62)
    ..close(),
  // الكمّين
  _tilted(31.5, 57, 9.5, 24, 4.5, .14),
  _tilted(68.5, 57, 9.5, 24, 4.5, -.14),
  // الكفّين على الركب
  Path()..addOval(Rect.fromCircle(center: const Offset(34, 69), radius: 4.6)),
  Path()..addOval(Rect.fromCircle(center: const Offset(66, 69), radius: 4.6)),
  // الوجه
  Path()..addOval(Rect.fromCenter(center: const Offset(50, 32), width: 18, height: 19)),
  // العمامة
  Path()
    ..moveTo(37.5, 30)
    ..cubicTo(35, 14, 43, 7, 50, 7)
    ..cubicTo(57, 7, 65, 14, 62.5, 30)
    ..cubicTo(60, 24, 40, 24, 37.5, 30)
    ..close(),
];

Path? _statueCache;

Path get _statueShape => _statueCache ??= _statueParts().reduce((a, b) => Path.combine(PathOperation.union, a, b));

void _statue(Canvas c) {
  final parts = _statueParts();
  for (var i = 0; i < parts.length; i++) {
    final p = parts[i];
    final b = p.getBounds();
    c.drawPath(p, _goldPaint(b, horizontal: i == 3 || i == 2 || i == 9));
    c.drawPath(p, _line(_goldInk, 1.9));
  }
  // تفاصيل منحوتة: ثنيات الثوب، الركب، الوجه واللحية، لفات العمامة
  final eng = _line(_goldInk.withValues(alpha: .65), 1.1);
  c.drawPath(
    Path()
      ..moveTo(50, 70)
      ..quadraticBezierTo(49, 78, 50, 88),
    eng,
  );
  c.drawPath(
    Path()
      ..moveTo(40, 72)
      ..quadraticBezierTo(38, 80, 36, 87),
    eng,
  );
  c.drawPath(
    Path()
      ..moveTo(60, 72)
      ..quadraticBezierTo(62, 80, 64, 87),
    eng,
  );
  c.drawPath(
    Path()
      ..moveTo(50, 43)
      ..lineTo(50, 61),
    eng,
  );
  c.drawPath(
    Path()
      ..moveTo(36, 66)
      ..quadraticBezierTo(50, 72, 64, 66),
    eng,
  );
  // لحية وشنب
  final beard = Path()
    ..moveTo(41.5, 32)
    ..quadraticBezierTo(41, 43, 50, 44.5)
    ..quadraticBezierTo(59, 43, 58.5, 32)
    ..quadraticBezierTo(56, 35.5, 50, 35)
    ..quadraticBezierTo(44, 35.5, 41.5, 32)
    ..close();
  c.drawPath(beard, _grad(const Rect.fromLTWH(41, 32, 18, 13), const [_goldMid, _goldLo]));
  c.drawPath(beard, _line(_goldInk, 1.2));
  for (final sx in const [-1.0, 1.0]) {
    c.drawLine(Offset(50 + sx * 5, 38), Offset(50 + sx * 4, 41.5), _line(_goldInk.withValues(alpha: .5), .8));
    c.drawLine(Offset(50 + sx * 2.4, 39.5), Offset(50 + sx * 2, 43), _line(_goldInk.withValues(alpha: .5), .8));
    c.drawCircle(Offset(50 + sx * 3.8, 30.2), 1.0, _fill(_goldInk));
  }
  c.drawPath(
    Path()
      ..moveTo(44.5, 35.6)
      ..quadraticBezierTo(50, 33.4, 55.5, 35.6),
    _line(_goldInk, 1.5),
  );
  // لفات العمامة وجوهرة
  c.drawPath(
    Path()
      ..moveTo(38, 25)
      ..quadraticBezierTo(50, 17, 62, 25),
    _line(_goldInk.withValues(alpha: .75), 1.4),
  );
  for (final (x0, y0, x1, y1) in const [(40.0, 22.0, 51.0, 9.0), (45.0, 21.5, 58.0, 10.0), (52.0, 21.0, 62.0, 16.0)]) {
    c.drawPath(
      Path()
        ..moveTo(x0, y0)
        ..quadraticBezierTo((x0 + x1) / 2 - 3, (y0 + y1) / 2 - 1, x1, y1),
      _line(_goldInk.withValues(alpha: .55), 1.1),
    );
  }
  c.drawCircle(const Offset(50, 21), 2.4, _fill(const Color(0xFFD8372F)));
  c.drawCircle(const Offset(50, 21), 2.4, _line(_goldInk, 1));
  // لمعات
  c.drawOval(
    Rect.fromCenter(center: const Offset(43.5, 14.5), width: 4.2, height: 7),
    _fill(Colors.white.withValues(alpha: .85)),
  );
  c.drawLine(const Offset(39, 49), const Offset(37.5, 58), _line(Colors.white.withValues(alpha: .7), 2.2));
  c.drawLine(const Offset(33, 72), const Offset(41, 73), _line(Colors.white.withValues(alpha: .6), 1.8));
  c.drawLine(const Offset(34, 80), const Offset(35.5, 85), _line(Colors.white.withValues(alpha: .6), 1.8));
}

void _gold(Canvas c, double s, double idle, double chair) {
  drawDeathChair(c, alpha: chair);
  if (s <= 0) return;
  final wash = _out(_seg(s, .15, 1.5));
  // وهج ذهبي
  c.drawCircle(
    const Offset(50, 54),
    52,
    Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD84A).withValues(alpha: .55 * wash),
          const Color(0x00FFD84A),
        ],
      ).createShader(Rect.fromCircle(center: const Offset(50, 54), radius: 52)),
  );
  final front = _lerp(4, 94, wash);
  c.save();
  c.clipRect(Rect.fromLTRB(0, 0, 100, front));
  _statue(c);
  // لمعة تمر على التمثال (أول مرة بعد الاكتمال، وبعدين كل فترة)
  final sweepA = _seg(s, 1.5, 2.3);
  final every = (idle * .3) % 1;
  final sw = s < 2.4 ? (sweepA > 0 && sweepA < 1 ? sweepA : -1.0) : (every < .3 ? every / .3 : -1.0);
  if (sw >= 0) {
    final x = _lerp(10, 90, sw);
    c.save();
    c.clipPath(_statueShape);
    c.drawPath(
      Path()
        ..moveTo(x, 0)
        ..lineTo(x + 9, 0)
        ..lineTo(x - 5, 95)
        ..lineTo(x - 14, 95)
        ..close(),
      _fill(Colors.white.withValues(alpha: .7)),
    );
    c.restore();
  }
  c.restore();
  // خط الذهب وهو ينزل
  if (wash < 1) {
    c.drawLine(Offset(24, front), Offset(76, front), _line(const Color(0xFFFFF6C8).withValues(alpha: 1 - wash), 2.6));
  }
  // نجوم تلمع
  final tw = _seg(s, 1.0, 1.7);
  const pts = [(18.0, 22.0, 5.0), (84.0, 30.0, 6.0), (80.0, 74.0, 4.5), (14.0, 64.0, 4.0), (70.0, 8.0, 3.6)];
  for (var i = 0; i < pts.length; i++) {
    final (x, y, r) = pts[i];
    final k = math.pow(math.max(0, math.sin(idle * 2.3 + i * 1.7)), 2).toDouble();
    _spark(c, Offset(x, y), r * (.4 + .9 * k) * tw, const Color(0xFFFFF0A8), alpha: tw * (.5 + .5 * k));
  }
}

// ───────── المدخل

/// يرسم مشهد الافكت كامل على مربع تصميم ١٠٠×١٠٠ (الـcanvas لازم يكون محول له).
/// [chair] شفافية المسند (في اللعبة يطلع بدل صورة اللاعب).
void paintDeathScene(Canvas c, DeathFx fx, {required double s, double idle = 0, double chair = 1}) {
  switch (fx) {
    case DeathFx.cloth:
      _cloth(c, s, idle, chair);
    case DeathFx.smoke:
      _smoke(c, s, idle, chair);
    case DeathFx.sand:
      _sand(c, s, idle, chair);
    case DeathFx.petals:
      _petals(c, s, idle, chair);
    case DeathFx.ice:
      _ice(c, s, idle, chair);
    case DeathFx.fire:
      _fire(c, s, idle, chair);
    case DeathFx.bats:
      _bats(c, s, idle, chair);
    case DeathFx.lightning:
      _lightning(c, s, idle, chair);
    case DeathFx.ghost:
      _ghost(c, s, idle, chair);
    case DeathFx.gold:
      _gold(c, s, idle, chair);
  }
}

/// يرسم المشهد في مربع ([size] أقصر ضلع) بوسط المساحة: للمعاينة.
void paintDeathBox(Canvas c, Size size, DeathFx fx, {required double s, double idle = 0, double chair = 1}) {
  final u = size.shortestSide / 100;
  c.save();
  c.translate((size.width - 100 * u) / 2, (size.height - 100 * u) / 2);
  c.scale(u);
  // المعاينة ما تطلع برا مربعها (الغطا وهو نازل مثلاً)
  c.clipRect(const Rect.fromLTWH(-4, -4, 108, 108));
  paintDeathScene(c, fx, s: s, idle: idle, chair: chair);
  c.restore();
}

/// يرسم المشهد مكان صورة اللاعب على الطاولة: [seat] مربع الصورة، والمسند مركزه بنص الصورة والمشهد أكبر منها شوي.
void paintDeathAtSeat(Canvas c, Size seat, DeathFx fx, {required double s, double idle = 0, double chair = 1}) {
  final u = seat.width * 1.4 / 100;
  c.save();
  c.translate(seat.width / 2 - 50 * u, seat.height / 2 - 60 * u);
  c.scale(u);
  paintDeathScene(c, fx, s: s, idle: idle, chair: chair);
  c.restore();
}
