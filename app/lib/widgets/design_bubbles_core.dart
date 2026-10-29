import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fx.dart' show star4;

/// أدوات رسم الفقاعات المصورة (بالتصميم الجديد): سياق الرسم، قالب الفقاعة، وأشكال وأدوات مشتركة.
/// كل مقاسات الرسم بوحدة [BubbleCtx.u] (= حجم خط الكلام) عشان الزخارف تكبر وتصغر مع الفقاعة.

/// سياق رسمة وحدة: الكانفس، جسم الفقاعة (بدون الذيل والزخارف)، الوحدة، والوقت.
class BubbleCtx {
  const BubbleCtx({
    required this.canvas,
    required this.body,
    required this.u,
    required this.t,
    required this.tail,
    required this.tailX,
  });

  final Canvas canvas;

  /// جسم الفقاعة (المستطيل اللي فيه الكلام).
  final Rect body;

  /// وحدة المقاس = حجم الخط.
  final double u;

  /// الوقت بالثواني (من FxClock).
  final double t;

  /// طول الذيل تحت الجسم.
  final double tail;

  /// مكان رأس الذيل أفقياً.
  final double tailX;

  /// سماكة الحافة الغامقة.
  double get ow => math.max(1.5, u * .15);

  double get w => body.width;
  double get h => body.height;
}

/// قالب فقاعة: ألوانها وشكلها وزخارفها (خلف الجسم، داخله، وفوقه).
abstract class BubbleArtSpec {
  const BubbleArtSpec();

  /// تدرج الجسم من فوق لتحت.
  List<Color> get fill;

  /// لون الحافة الغامقة.
  Color get ink;

  /// لون حد الكلام الأبيض.
  Color get textInk => ink;

  /// هوامش الزخارف اللي تطلع برا الجسم (يمين ويسار متساويين عشان الذيل يبقى بالنص).
  EdgeInsets get pad;

  /// حشوة الكلام داخل الجسم (أفقي وعمودي).
  double get tx => .95;
  double get ty => .36;

  /// وحدها الرق ثابتة.
  bool get animated => true;

  /// حافة فاتحة داخل الجسم (تلمّع الحد).
  Color? get rim => null;

  /// شكل الجسم (بدون الذيل).
  Path shape(BubbleCtx c) => bbPill(c.body, c.u);

  /// خلف الجسم (لهب، توهج...).
  void back(BubbleCtx c, Path body) {}

  /// داخل الجسم (مقصوص عليه).
  void inner(BubbleCtx c, Path body) {}

  /// فوق الجسم والحافة (بلورات، ثلج، قمر...).
  void front(BubbleCtx c, Path body) {}
}

// ───────────────────────── أقلام ودهانات ─────────────────────────

Paint bbFill(Color c) => Paint()..color = c;

Paint bbLine(double w, Color c) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..color = c;

/// تدرج خطي على مستطيل (الافتراضي من فوق لتحت).
Paint bbGrad(
  Rect r,
  List<Color> cs, {
  Alignment a = Alignment.topCenter,
  Alignment b = Alignment.bottomCenter,
  List<double>? stops,
}) => Paint()..shader = LinearGradient(begin: a, end: b, colors: cs, stops: stops).createShader(r);

/// دائرة بتدرج شعاعي (توهج رخيص بدون blur).
Paint bbGlow(Offset c, double r, Color col) =>
    Paint()..shader = RadialGradient(colors: [col, col.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: c, radius: r));

/// وميض (٠–١) يتبدل بنعومة؛ [i] يخلي كل عنصر بطور غير.
double bbTw(double t, double speed, int i) => (math.sin(t * speed + i * 1.9) + 1) / 2;

double bbFr(double x) => x - x.floorToDouble();

double bbClamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

double bbLerp(double a, double b, double k) => a + (b - a) * k;

// ───────────────────────── أشكال ─────────────────────────

/// حبة مدوّرة (الشكل الافتراضي).
Path bbPill(Rect b, double u, {double? r}) =>
    Path()..addRRect(RRect.fromRectAndRadius(b, Radius.circular(r ?? math.min(b.height * .46, u * 1.25))));

/// مثمن بزوايا مقطوعة (فضي، زمرد، ألماس...).
Path bbChamfer(Rect b, double c) => Path()
  ..moveTo(b.left + c, b.top)
  ..lineTo(b.right - c, b.top)
  ..lineTo(b.right, b.top + c)
  ..lineTo(b.right, b.bottom - c)
  ..lineTo(b.right - c, b.bottom)
  ..lineTo(b.left + c, b.bottom)
  ..lineTo(b.left, b.bottom - c)
  ..lineTo(b.left, b.top + c)
  ..close();

/// حافة بروزات: [round] تقوّس (سحابة وأمواج)، وإلا مدببة (النجمة الذهبية).
Path bbSerrated(Rect b, double r, {required double pitch, required double amp, bool round = false}) {
  final base = Path()..addRRect(RRect.fromRectAndRadius(b, Radius.circular(r)));
  final m = base.computeMetrics().first;
  final n = math.max(8, (m.length / pitch).round());
  final step = m.length / n;
  Offset at(double d) => m.getTangentForOffset(d % m.length)!.position;
  Offset out(double d) {
    final v = m.getTangentForOffset(d % m.length)!.vector;
    final l = v.distance == 0 ? 1.0 : v.distance;
    return Offset(v.dy / l, -v.dx / l);
  }

  final p = Path()..moveTo(at(0).dx, at(0).dy);
  // نصف قطر القوس اللي ارتفاعه amp على وتر طوله step
  final rad = (step * step / 4 + amp * amp) / (2 * amp);
  for (var i = 0; i < n; i++) {
    final mid = i * step + step / 2;
    final end = at((i + 1) * step);
    if (round) {
      p.arcToPoint(end, radius: Radius.circular(rad), clockwise: true);
    } else {
      final tip = at(mid) + out(mid) * amp;
      p.lineTo(tip.dx, tip.dy);
      p.lineTo(end.dx, end.dy);
    }
  }
  return p..close();
}

/// حافة متموجة (ماء، سلايم).
Path bbWavy(Rect b, double r, {required double pitch, required double amp, double phase = 0}) {
  final base = Path()..addRRect(RRect.fromRectAndRadius(b, Radius.circular(r)));
  final m = base.computeMetrics().first;
  final waves = math.max(4, (m.length / pitch).round());
  final n = waves * 8;
  final p = Path();
  for (var i = 0; i <= n; i++) {
    final d = m.length * i / n;
    final tg = m.getTangentForOffset(d % m.length)!;
    final v = tg.vector;
    final l = v.distance == 0 ? 1.0 : v.distance;
    final o = Offset(v.dy / l, -v.dx / l) * (amp * math.sin(2 * math.pi * waves * i / n + phase));
    final pt = tg.position + o;
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// الذيل: مثلث بحافة مقوّسة قليل، رأسه تحت.
Path bbTail(Rect body, double tail, double x, double u) {
  final b = body.bottom;
  final hw = u * .55;
  return Path()
    ..moveTo(x - hw, b - u * .15)
    ..quadraticBezierTo(x - hw * .25, b + tail * .35, x + u * .06, b + tail)
    ..quadraticBezierTo(x + hw * .35, b + tail * .3, x + hw, b - u * .15)
    ..close();
}

Path bbHeart(Offset c, double s) {
  // قلب عرضه ~2s وطوله ~1.9s، مركزه c
  final top = c.dy - s * .55;
  return Path()
    ..moveTo(c.dx, c.dy + s * .95)
    ..cubicTo(c.dx - s * 1.5, c.dy + s * .1, c.dx - s * 1.15, top - s * .55, c.dx, top + s * .25)
    ..cubicTo(c.dx + s * 1.15, top - s * .55, c.dx + s * 1.5, c.dy + s * .1, c.dx, c.dy + s * .95)
    ..close();
}

Path bbStar5(Offset c, double r, {double inner = .45, double rot = -math.pi / 2}) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final rr = i.isEven ? r : r * inner;
    final a = rot + i * math.pi / 5;
    final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// لسان لهب يطلع من [base] لفوق، ارتفاعه [hgt] وعرض قاعدته [bw]، ورأسه ينحرف [sway].
Path bbTongue(Offset base, double bw, double hgt, double sway) => Path()
  ..moveTo(base.dx - bw, base.dy)
  ..cubicTo(base.dx - bw * 1.35, base.dy - hgt * .38, base.dx - bw * .55 + sway * .3, base.dy - hgt * .58, base.dx + sway, base.dy - hgt)
  ..cubicTo(base.dx + bw * .15 + sway * .6, base.dy - hgt * .6, base.dx + bw * 1.35, base.dy - hgt * .42, base.dx + bw, base.dy)
  ..close();

/// هلال: دائرة مطروح منها دائرة مزاحة.
Path bbCrescent(Offset c, double r, {double cut = .78, double shift = .42, double rot = 0}) {
  final a = Path()..addOval(Rect.fromCircle(center: c, radius: r));
  final d = Offset(math.cos(rot), math.sin(rot)) * r * shift;
  final b = Path()..addOval(Rect.fromCircle(center: c + d, radius: r * cut));
  return Path.combine(PathOperation.difference, a, b);
}

// ───────────────────────── لمعات وأدوات رسم ─────────────────────────

/// لمعة نجمية بأربع رؤوس.
void bbSpark(Canvas canvas, Offset p, double r, [Color col = Colors.white]) {
  if (r <= .2) return;
  canvas.drawPath(star4(p, r), bbFill(col));
}

/// لمعة الزجاج فوق الجسم (شريط مدوّر فاتح + نقطة).
void bbGloss(BubbleCtx c, {double alpha = .3}) {
  final b = c.body;
  final r = RRect.fromLTRBR(b.left + c.u * .4, b.top + c.u * .1, b.right - c.u * .4, b.top + c.h * .4, Radius.circular(c.h * .2));
  c.canvas.drawRRect(r, bbGrad(r.outerRect, [Colors.white.withValues(alpha: alpha), Colors.white.withValues(alpha: alpha * .25)]));
  c.canvas.drawCircle(Offset(b.left + c.u * .5, b.top + c.h * .52), c.u * .1, bbFill(Colors.white.withValues(alpha: alpha * 1.4)));
}

/// شريط ضو مايل يمر على الجسم؛ يمشي بأول [active] من الدورة وبعدها يرتاح.
void bbShine(BubbleCtx c, {double period = 3.4, double active = .5, double width = 1.4, double alpha = .6, double offset = 0}) {
  final k = bbFr(c.t / period + offset);
  if (k > active) return;
  final p = k / active;
  final b = c.body;
  final bw = c.u * width;
  final x = bbLerp(b.left - bw, b.right + bw, p);
  final band = Rect.fromLTRB(x - bw, b.top - c.u * .3, x + bw, b.bottom + c.u * .3);
  c.canvas.save();
  c.canvas.translate(band.center.dx, band.center.dy);
  c.canvas.transform(Matrix4.skewX(-.4).storage);
  c.canvas.translate(-band.center.dx, -band.center.dy);
  c.canvas.drawRect(
    band,
    Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: alpha), Colors.white.withValues(alpha: 0)],
      ).createShader(band),
  );
  c.canvas.restore();
}
