// أيادي الملصقات (S1): كف مفتوحة، قبضة، إصبع يشاور، كم الثوب. كل يد مرسومة بقطع سميكة
// (تُرسم كلها بحد غامق ثم ظل ثم لون) فيطلع الحد واحد حول الشكل كله مثل رسم الفيديو.
//
// إطار اليد: المعصم عند (0,0)، والأصابع لفوق (-y)، والإبهام عن اليسار. `at` = موقع المعصم في فضاء
// ٢٠٠ وحدة، `rot` = دوران باتجاه عقارب الساعة (٠ = الأصابع لفوق)، `mirror` = يد معكوسة.
import 'dart:math' as math;
import 'dart:ui';

import '../core/palette.dart';
import '../core/pen.dart';

enum S1Thumb { out, up, tuck }

class S1HandPose {
  const S1HandPose({this.curl = const [0, 0, 0, 0], this.thumb = S1Thumb.out, this.spread = 0.10, this.fist = false, this.lens = const [1, 1, 1, 1]});

  /// تكوّر كل إصبع (السبابة..الخنصر): ٠ = ممدود، ١ = مثني.
  final List<double> curl;
  final S1Thumb thumb;

  /// انفراج الأصابع (راديان لكل إصبع).
  final double spread;
  final bool fist;
  final List<double> lens;

  static const open = S1HandPose();
  static const stop = S1HandPose(spread: 0.05);
  static const wide = S1HandPose(spread: 0.2);
  static const point = S1HandPose(curl: [0, 1, 1, 1], thumb: S1Thumb.tuck, spread: 0.0);
  static const fistPose = S1HandPose(fist: true);
  static const shh = S1HandPose(curl: [0, 1, 1, 1], thumb: S1Thumb.tuck, spread: 0.0);
  static const flat = S1HandPose(spread: 0.0, thumb: S1Thumb.tuck);
}

/// قطع سميكة بحد واحد حول مجموعها: حد، ثم ظل، ثم اللون الأساسي مزاح ناحية الضوء.
void s1Blob(Pen pen, List<(Offset, Offset, double)> segs, Tones t, {double outline = Style.line, double shade = 1.8, Color ink = Style.ink}) {
  final c = pen.c;
  Paint stroke(Color col, double w) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true
    ..strokeWidth = w
    ..color = col;
  for (final s in segs) {
    c.drawLine(s.$1, s.$2, stroke(ink, s.$3 + outline * 2));
  }
  for (final s in segs) {
    c.drawLine(s.$1, s.$2, stroke(t.shade, s.$3));
  }
  final n = Offset(Style.light.dx, Style.light.dy) / Style.light.distance;
  final off = n * (shade / 2);
  for (final s in segs) {
    c.drawLine(s.$1 + off, s.$2 + off, stroke(t.base, math.max(0.5, s.$3 - shade)));
  }
}

/// يد كاملة. [sleeve] + [arm] = كم الثوب الطالع من المعصم (طول [arm] بوحدات اليد).
void s1Hand(
  Pen pen,
  Skin skin,
  S1HandPose pose, {
  required Offset at,
  double rot = 0,
  double scale = 1.4,
  bool mirror = false,
  Tones? sleeve = Cloth.white,
  double arm = 0,
  double armRot = 0,
}) {
  final cs = math.cos(rot), sn = math.sin(rot);
  Offset tx(double x, double y) {
    final mx = mirror ? -x : x;
    return Offset(at.dx + (mx * cs - y * sn) * scale, at.dy + (mx * sn + y * cs) * scale);
  }

  Offset dir(double ang) {
    // اتجاه (زاوية عن العمودي لفوق، موجبة = يمين اليد قبل العكس)
    final mx = mirror ? -math.sin(ang) : math.sin(ang);
    final x = mx, y = -math.cos(ang);
    return Offset(x * cs - y * sn, x * sn + y * cs);
  }

  final lw = Style.line * 0.85;
  final fine = Style.lineThin * 0.85;
  final t = skin.tones;
  final segs = <(Offset, Offset, double)>[];
  final lines = <(Offset, Offset)>[];
  final bumps = <(Offset, double)>[];

  // الساعد (كم) ورا اليد
  if (sleeve != null && arm > 0) {
    final a0 = tx(0, 6);
    final ang = armRot;
    final a1 = tx(math.sin(ang) * arm, 6 + math.cos(ang) * arm);
    s1Blob(pen, [(a0, a1, 25 * scale)], sleeve, outline: lw, shade: 3.4 * scale / 1.4);
    // خطوط طيّات خفيفة
    final v = a1 - a0;
    final nrm = Offset(-v.dy, v.dx) / v.distance;
    pen.line(
      Path()
        ..moveTo((a0 + v * .35 + nrm * 6 * scale).dx, (a0 + v * .35 + nrm * 6 * scale).dy)
        ..lineTo((a0 + v * .85 + nrm * 7 * scale).dx, (a0 + v * .85 + nrm * 7 * scale).dy),
      w: fine * .8,
      color: withA(sleeve.shade, .9),
    );
  }

  if (pose.fist) {
    // قبضة: كتلة الكف + أربع مفاصل مدورة فوق + إبهام عبر القبضة
    s1Blob(pen, [(tx(-3, -3), tx(3, -3), 25 * scale)], t, outline: lw, shade: 3.2 * scale / 1.4);
    for (final x in const [-10.5, -3.5, 3.5, 10.5]) {
      final p = Path()..addOval(Rect.fromCircle(center: tx(x, -12), radius: 6.6 * scale));
      pen.solid(p, t, shade: 2.0 * scale / 1.4, hi: .9, w: fine * 1.05);
    }
    s1Blob(pen, [(tx(-12, 3), tx(5, 4.5), 9 * scale)], t, outline: fine, shade: 2.0 * scale / 1.4);
    pen.line(Path()..moveTo(tx(-12, -15).dx, tx(-12, -15).dy)..quadraticBezierTo(tx(-6, -19).dx, tx(-6, -19).dy, tx(-2, -17.5).dx, tx(-2, -17.5).dy), w: fine * .8, color: withA(skin.hi, .95));
    _cuff(pen, sleeve, tx, scale, lw, arm);
    return;
  }

  // الكف
  segs.add((tx(0, -4), tx(0, -13), 24 * scale));
  // الأصابع
  const baseX = [-8.6, -2.9, 2.8, 8.4];
  const lens = [17.0, 19.5, 17.5, 13.5];
  const widths = [6.4, 6.6, 6.2, 5.4];
  for (var i = 0; i < 4; i++) {
    final ang = (i - 1.5) * pose.spread;
    final base = tx(baseX[i], -21);
    final c = pose.curl[i];
    if (c >= 0.7) {
      bumps.add((tx(baseX[i] * 0.85 + 1, -10.5 + i * 0.5), 5.2 * scale));
      continue;
    }
    final len = lens[i] * pose.lens[i] * (1 - 0.7 * c);
    final tip = base + dir(ang) * (len * scale);
    segs.add((base, tip, widths[i] * scale));
    if (i < 3 && pose.curl[i + 1] < 0.7) {
      final gx = (baseX[i] + baseX[i + 1]) / 2;
      final shorter = math.min(lens[i] * (1 - 0.7 * c), lens[i + 1] * (1 - 0.7 * pose.curl[i + 1]));
      lines.add((tx(gx + ang * 3, -21 - shorter * 0.78), tx(gx, -19)));
    }
  }
  // الإبهام
  switch (pose.thumb) {
    case S1Thumb.out:
      final b = tx(-10, -7);
      segs.add((b, b + dir(-0.95) * (15 * scale), 7 * scale));
    case S1Thumb.up:
      final b = tx(-10.5, -8);
      segs.add((b, b + dir(-0.28) * (17 * scale), 7 * scale));
    case S1Thumb.tuck:
      bumps.add((tx(-8.5, -4), 5.6 * scale));
  }
  s1Blob(pen, segs, t, outline: lw, shade: 3.2 * scale / 1.4);
  for (final l in lines) {
    pen.line(Path()..moveTo(l.$1.dx, l.$1.dy)..lineTo(l.$2.dx, l.$2.dy), w: fine * .85, color: withA(Style.ink, .8));
  }
  // أصابع مثنية (مدورة، فوق الكف)
  for (final b in bumps) {
    final p = Path()..addOval(Rect.fromCircle(center: b.$1, radius: b.$2));
    pen.solid(p, t, shade: 2.0 * scale / 1.4, hi: 0.9, w: fine * 1.05);
  }
  // خط الكف
  if (pose.curl.every((c) => c < 0.7)) {
    final p0 = tx(-6, -3), p1 = tx(4, 0);
    pen.line(Path()..moveTo(p0.dx, p0.dy)..quadraticBezierTo(tx(-1, 2).dx, tx(-1, 2).dy, p1.dx, p1.dy), w: fine * .7, color: withA(skin.deep, .55));
  }
  _cuff(pen, sleeve, tx, scale, lw, arm);
}

void _cuff(Pen pen, Tones? sleeve, Offset Function(double, double) tx, double scale, double lw, double arm) {
  if (sleeve == null || arm <= 0) return;
  s1Blob(pen, [(tx(-3, 10), tx(3, 10), 25 * scale)], sleeve, outline: lw * .9, shade: 3.0 * scale / 1.4);
}
