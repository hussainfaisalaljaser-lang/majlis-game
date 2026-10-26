import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../fx.dart';

export '../fx.dart' show glintAt, rnd, star4;

/// كل إطار له رسمتين: ورا الصورة وقدامها.
enum SigLayer { back, front }

/// اللحظات الخاصة للإطارات الأسطورية: حركة قصيرة لما يصير شي (يقعد على الطاولة، يصير رئيس، يفوز،
/// أو يفتح المعاينة في المتجر). المفتاح غالباً رقم اللاعب.
abstract final class Moments {
  static final events = ValueNotifier<(String, int)?>(null);

  static void trigger(String key) => events.value = (key, DateTime.now().microsecondsSinceEpoch);
}

/// كم تطول اللحظة الخاصة (ثواني).
const momentSeconds = 1.8;

double frac(double x) => x - x.floorToDouble();

/// ضجيج ناعم (مجموع موجات) بين ٠ و١: للهب والوميض.
double noise(double x, int i) =>
    .5 + .25 * math.sin(x * 1.7 + i * 2.1) + .15 * math.sin(x * 3.3 + i * 1.3) + .1 * math.sin(x * 7.1 + i * .7);

Offset dir(double a) => Offset(math.cos(a), math.sin(a));

/// من ٠ لـ١ ويرجع ٠ (نص موجة).
double hump(double p) => p <= 0 || p >= 1 ? 0 : math.sin(p * math.pi);

/// مضلع مقفل من نقاط.
Path poly(List<Offset> pts) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final q in pts.skip(1)) {
    p.lineTo(q.dx, q.dy);
  }
  return p..close();
}

/// نجمة خماسية.
Path star5(Offset c, double size, {double inner = .45, double turn = -math.pi / 2}) =>
    poly([for (var i = 0; i < 10; i++) c + dir(turn + i * math.pi / 5) * (i.isEven ? size : size * inner)]);

/// نجمة ثمانية (مربعين فوق بعض).
Path star8(Offset c, double size, {double turn = 0}) =>
    poly([for (var i = 0; i < 16; i++) c + dir(turn + i * math.pi / 8) * (i.isEven ? size : size * .72)]);

/// عمودي على الاتجاه (لليسار).
Offset perp(Offset d) => Offset(-d.dy, d.dx);

/// اتجاه بطول ١.
Offset unit(Offset d) => d / d.distance;

/// يلف اتجاه بزاوية (مع عقارب الساعة على الشاشة).
Offset rot(Offset v, double a) =>
    Offset(v.dx * math.cos(a) - v.dy * math.sin(a), v.dx * math.sin(a) + v.dy * math.cos(a));

/// رسام إطار: طبقة ورا الصورة وطبقة قدامها، على لوحة بحجم الصورة مع حلقتها (ويقدر يطلع برا شوي).
abstract class FrameArt extends CustomPainter {
  FrameArt(this.time, {required this.avatar, required this.layer, this.moment})
    : super(repaint: moment == null ? time : Listenable.merge([time, moment]));

  final ValueListenable<double> time;

  /// قطر الصورة.
  final double avatar;
  final SigLayer layer;

  /// وقت بداية اللحظة الخاصة (بنفس ساعة [time])، أو null.
  final ValueListenable<double?>? moment;

  double get r => avatar / 2;

  /// سماكة الحلقة.
  double get ring => math.max(2.5, avatar * .075);

  /// نص الحلقة (من المركز).
  double get mid => r + ring / 2;

  /// صغيرة (على الطاولة): تفاصيل أقل.
  bool get small => avatar < 80;

  /// أرفع خط يبان على هالحجم.
  double get hair => math.max(.6, avatar * .008);

  /// تقدم اللحظة الخاصة بين ٠ و١، أو null لو ما فيه لحظة.
  double? burst(double t) {
    final m = moment?.value;
    if (m == null) return null;
    final p = (t - m) / momentSeconds;
    return p >= 0 && p <= 1 ? p : null;
  }

  void back(Canvas canvas, Offset c, double t) {}

  void front(Canvas canvas, Offset c, double t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    if (layer == SigLayer.back) {
      back(canvas, c, time.value);
    } else {
      front(canvas, c, time.value);
    }
  }

  @override
  bool shouldRepaint(FrameArt old) =>
      old.runtimeType != runtimeType ||
      old.avatar != avatar ||
      old.layer != layer ||
      old.time != time ||
      old.moment != moment;

  // ───── أدوات رسم مشتركة ─────

  /// حلقة بتدرج يلف حوالين الدائرة.
  void sweepRing(Canvas canvas, Offset c, List<Color> colors, {double turn = 0, double? width, double? radius}) {
    final rad = radius ?? mid;
    canvas.drawCircle(
      c,
      rad,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width ?? ring
        ..shader = SweepGradient(
          colors: [...colors, colors.first],
          transform: GradientRotation(turn),
        ).createShader(Rect.fromCircle(center: c, radius: rad + ring)),
    );
  }

  /// خط رفيع حول الدائرة (حواف الحلقة).
  void line(Canvas canvas, Offset c, double radius, Color color, {double? width}) {
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width ?? hair
        ..color = color,
    );
  }

  /// توهج ناعم على شكل حلقة.
  void glowRing(Canvas canvas, Offset c, Color color, {double radius = 0, double width = 0, double blur = 0}) {
    canvas.drawCircle(
      c,
      radius == 0 ? mid : radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width == 0 ? ring * 1.8 : width
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur == 0 ? ring : blur),
    );
  }

  /// هالة دائرية بتدرج (أرخص من البلور).
  void halo(Canvas canvas, Offset c, double radius, List<Color> colors, {List<double>? stops}) {
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: colors,
          stops: stops,
        ).createShader(Rect.fromCircle(center: c, radius: radius)),
    );
  }

  /// لمعة نجمة بأربع رؤوس مع توهجها.
  void sparkle(Canvas canvas, Offset p, double size, Color color, double alpha) {
    if (alpha <= 0) return;
    canvas.drawPath(
      star4(p, size * 1.9),
      Paint()
        ..color = color.withValues(alpha: .3 * alpha)
        ..blendMode = BlendMode.plus,
    );
    canvas.drawPath(star4(p, size), Paint()..color = Colors.white.withValues(alpha: alpha));
  }

  /// نقطة ضو (قلب أبيض وهالة ملونة).
  void dot(Canvas canvas, Offset p, double size, Color color, double alpha) {
    if (alpha <= 0) return;
    final paint = Paint()..blendMode = BlendMode.plus;
    paint.color = color.withValues(alpha: .35 * alpha);
    canvas.drawCircle(p, size * 2.4, paint);
    paint.color = Color.lerp(Colors.white, color, .35)!.withValues(alpha: alpha);
    canvas.drawCircle(p, size, paint);
  }
}

/// الإطارات النادرة: رسمة ثابتة، ولمعة خفيفة تمر عليها كل كم ثانية ([glintAt]).
abstract class RareFrame extends FrameArt {
  RareFrame(super.time, {required super.avatar, required super.layer, super.moment});

  /// لون اللمعة.
  Color get shine => Colors.white;

  /// وين تطلع النجمة آخر اللمعة.
  Offset sparkleAt(Offset c) => c + dir(-math.pi / 4) * mid;

  void art(Canvas canvas, Offset c);

  void artBack(Canvas canvas, Offset c) {}

  @override
  void back(Canvas canvas, Offset c, double t) => artBack(canvas, c);

  @override
  void front(Canvas canvas, Offset c, double t) {
    art(canvas, c);
    final p = glintAt(t);
    if (p != null) glint(canvas, c, p);
  }

  /// شريط ضو مايل يمر على الحلقة، وبعده نجمة تلمع.
  void glint(Canvas canvas, Offset c, double p) {
    final outer = r + ring;
    final s = p * 1.5 - .25;
    canvas.drawCircle(
      c,
      mid,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring * 1.2
        ..blendMode = BlendMode.plus
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [shine.withValues(alpha: 0), shine.withValues(alpha: .85), shine.withValues(alpha: 0)],
          stops: [(s - .14).clamp(0.0, 1.0), s.clamp(0.0, 1.0), (s + .14).clamp(0.0, 1.0)],
        ).createShader(Rect.fromCircle(center: c, radius: outer)),
    );
    sparkle(canvas, sparkleAt(c), ring * .9, shine, hump((p - .4) / .6));
  }
}
