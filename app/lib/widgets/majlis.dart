import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'design_game.dart';
import 'fx.dart';
import 'venues.dart';

/// رسمات المجلس: خيمة الصحراء بالليل (الخلفية)، والمسند، وفانوس الأرض، وغطا المطرود. كلها ترسم بالكود
/// وتتمدد على أي مقاس، والحركة (رمشة الفوانيس والنار) على ساعة الحركات، فتوقف في الوضع الخفيف.

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

/// خلفية المجلس ورا الطاولة: خيمة بسما وكثبان وستائر حمرا وفوانيس معلقة ونار مخيم.
/// [venue] يغيّر ألوانها وخلفيتها حسب مستوى الطاولة (مدينة، قصر…).
/// [tension] (٠–١) تحمّر الفوانيس والنار وتخليها ترمش أكثر. [safe] حواف الشاشة (النوتش) اللي يتوسط بينها المسرح.
class MajlisRoom extends StatelessWidget {
  const MajlisRoom({super.key, this.tension = 0, this.venue = Venue.majlis, this.safe = EdgeInsets.zero});

  final double tension;
  final Venue venue;
  final EdgeInsets safe;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      // الرسمة الثابتة: تنرسم مرة وتنحفظ.
      Positioned.fill(
        child: RepaintBoundary(
          child: CustomPaint(painter: venueBackdrop(venue, safe: safe), isComplex: true),
        ),
      ),
      // التوتر يحمّر الغرفة.
      if (tension > 0)
        Positioned.fill(
          child: ColoredBox(color: const Color(0xFF7F1D1D).withValues(alpha: .32 * tension)),
        ),
      Positioned.fill(
        child: RepaintBoundary(
          child: FxClock(builder: (context, time) => CustomPaint(painter: venueLights(venue, time, tension, safe: safe))),
        ),
      ),
    ],
  );
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
        22,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFC857).withValues(alpha: .55 * light),
              const Color(0x00FFC857),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: 22)),
      );
    }
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeJoin = StrokeJoin.round
      ..color = gameInk;
    final glass = Path()
      ..moveTo(c.dx - 5.2, c.dy - 7)
      ..lineTo(c.dx + 5.2, c.dy - 7)
      ..quadraticBezierTo(c.dx + 6.6, c.dy, c.dx + 5, c.dy + 7)
      ..lineTo(c.dx - 5, c.dy + 7)
      ..quadraticBezierTo(c.dx - 6.6, c.dy, c.dx - 5.2, c.dy - 7)
      ..close();
    canvas.drawPath(glass, Paint()..color = Color.lerp(const Color(0xFF4A3220), const Color(0xFFFFDE8A), light)!);
    canvas.drawPath(glass, ink);
    final frame = Paint()..color = Color.lerp(const Color(0xFF6A4A26), const Color(0xFFC9A04E), .7)!;
    final top = Path()
      ..moveTo(c.dx - 6.4, c.dy - 7)
      ..lineTo(c.dx, c.dy - 11)
      ..lineTo(c.dx + 6.4, c.dy - 7)
      ..close();
    canvas.drawPath(top, frame);
    canvas.drawPath(top, ink);
    final base = RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - 6, c.dy + 6.6, 12, 2.6), const Radius.circular(1));
    canvas.drawRRect(base, frame);
    canvas.drawRRect(base, ink);
    canvas.drawLine(Offset(c.dx, c.dy - 11), Offset(c.dx, c.dy - 14.5), ink..strokeWidth = 1.1);
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

