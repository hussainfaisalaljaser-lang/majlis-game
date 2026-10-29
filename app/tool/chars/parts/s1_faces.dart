// ملامح إضافية للملصقات (S1): عيون مغمضة، عيون نجوم ودوّخة، دموع وعرق. كلها بإحداثيات الرأس
// (نفس إحداثيات EyeSpec: المبدأ بين العينين، +x يمين، +y تحت) وتتبع دوران الرأس.
import 'dart:math' as math;
import 'dart:ui';

import '../core/head.dart';
import '../core/pen.dart';

enum S1EyeMark { chevron, arcUp, arcDown, dash, spiral, star, dot, cross, bean }

const Color s1Water = Color(0xFF7ED3FF);
const Color s1WaterDark = Color(0xFF3FA6E8);

Offset _o(double x, double y) => Offset(x, y);

/// عين مغمضة أو رمز بدل العين العادية (تُرسم فوق الوجه). [side] = -1 يسار المشاهد، +1 يمين.
void s1EyeMark(
  Pen pen,
  Head h,
  S1EyeMark kind,
  int side, {
  double gap = 21,
  double y = 0,
  double w = 11,
  double thick = 3.6,
  Color color = Style.ink,
  Color star = const Color(0xFFFFD43B),
  double lift = 4,
}) {
  final sc = h.scale;
  final cx = side * gap;
  Path P(String d) => h.path(svg(d), lift: lift);
  switch (kind) {
    case S1EyeMark.chevron:
      // > < : الرأس ناحية الأنف
      final s = -side.toDouble();
      pen.line(P('M${cx + s * w} ${y - 8} L${cx - s * w * .85} ${y + 0.5} L${cx + s * w} ${y + 9}'), w: thick * sc, color: color);
    case S1EyeMark.arcUp:
      pen.line(P('M${cx - w} ${y + 3} Q$cx ${y - 9} ${cx + w} ${y + 3}'), w: thick * sc, color: color);
    case S1EyeMark.arcDown:
      pen.line(P('M${cx - w} ${y - 2.5} Q$cx ${y + 7} ${cx + w} ${y - 2.5}'), w: thick * sc, color: color);
    case S1EyeMark.dash:
      pen.line(P('M${cx - w} $y L${cx + w} $y'), w: thick * sc, color: color);
    case S1EyeMark.cross:
      pen.line(P('M${cx - w * .7} ${y - w * .7} L${cx + w * .7} ${y + w * .7} M${cx + w * .7} ${y - w * .7} L${cx - w * .7} ${y + w * .7}'), w: thick * sc, color: color);
    case S1EyeMark.dot:
      pen.fill(h.path(circle(cx, y, w * .45), lift: lift), color);
    case S1EyeMark.bean:
      pen.fill(h.path(ellipse(cx, y, w * .5, w * .8), lift: lift), color);
    case S1EyeMark.spiral:
      final white = h.path(circle(cx, y, w + 1), lift: lift - 1);
      pen.fill(white, const Color(0xFFFFFFFF));
      pen.crescent(white, const Color(0xFFD9D4E4), depth: 2.2 * sc, dir: const Offset(0, 1));
      pen.line(white, w: Style.lineThin * 1.35 * sc);
      final pts = <Offset>[];
      for (var i = 0; i <= 36; i++) {
        final t = i / 36;
        final a = t * math.pi * 5.2 * (side < 0 ? 1 : -1) + 0.6;
        final r = 1.2 + t * (w - 2.6);
        pts.add(_o(cx + math.cos(a) * r, y + math.sin(a) * r));
      }
      pen.line(h.path(spline(pts), lift: lift), w: 1.7 * sc, color: color);
    case S1EyeMark.star:
      final white = h.path(circle(cx, y, w + .5), lift: lift - 1);
      pen.fill(white, const Color(0xFFFFFFFF));
      pen.line(white, w: Style.lineThin * 1.35 * sc);
      final st = <Offset>[];
      for (var i = 0; i < 10; i++) {
        final r = i.isEven ? w * .98 : w * .42;
        final a = -math.pi / 2 + i * math.pi / 5;
        st.add(_o(cx + math.cos(a) * r, y + 0.5 + math.sin(a) * r));
      }
      final sp = h.path(poly(st), lift: lift);
      pen.fill(sp, star);
      pen.line(sp, w: 1.5 * sc, color: const Color(0xFFB8770B));
  }
}

/// مجرى دمعة من طرف العين لتحت الخد (بحد ولمعة).
void s1TearStream(Pen pen, Head h, int side, {double gap = 21, double y = 6, double len = 30, double width = 5, double bend = 3, double lift = 5}) {
  final sc = h.scale;
  final x0 = side * (gap + 5);
  final path = svg('M$x0 $y C${x0 + side * bend} ${y + len * .3} ${x0 + side * bend * 1.6} ${y + len * .65} ${x0 + side * bend} ${y + len}');
  final p = h.path(path, lift: lift);
  pen.line(p, w: (width + 2.6) * sc, color: Style.ink);
  pen.line(p, w: width * sc, color: s1Water);
  final hi = h.path(svg('M${x0 - side * 0.8} ${y + 3} C${x0 + side * bend * .5} ${y + len * .3} ${x0 + side * bend * 1.1} ${y + len * .6} ${x0 + side * bend * .8} ${y + len * .85}'), lift: lift + 1);
  pen.line(hi, w: 1.1 * sc, color: const Color(0xFFEFFAFF));
}

/// قطرة (دمعة / عرق): رأسها لفوق، مركزها [c] وحجمها [r].
void s1Drop(Pen pen, Offset c, double r, {Color color = s1Water, double rot = 0, double ink = Style.lineThin}) {
  var p = svg('M0 ${-r * 1.55} C${r * .25} ${-r * .85} ${r * 1.0} ${-r * .25} ${r * 1.0} ${r * .35} C${r * 1.0} ${r * 1.0} ${r * .5} ${r * 1.25} 0 ${r * 1.25} C${-r * .5} ${r * 1.25} ${-r * 1.0} ${r * 1.0} ${-r * 1.0} ${r * .35} C${-r * 1.0} ${-r * .25} ${-r * .25} ${-r * .85} 0 ${-r * 1.55} Z');
  p = rotatedAbout(p, Offset.zero, rot).shift(c);
  pen.fill(p, color);
  pen.crescent(p, shadeOf(color, .25), depth: r * .4);
  pen.line(p, w: ink * 1.15);
  pen.fill(Path()..addOval(Rect.fromCenter(center: c + Offset(-r * .36, r * .12), width: r * .34, height: r * .6)), const Color(0xCCFFFFFF));
}

/// نجمة بخمس أضلاع بحد.
void s1Star5(Pen pen, Offset c, double r, {Color color = const Color(0xFFFFD43B), double rot = 0, double ink = Style.lineThin}) {
  final pts = <Offset>[];
  for (var i = 0; i < 10; i++) {
    final rr = i.isEven ? r : r * .46;
    final a = -math.pi / 2 + rot + i * math.pi / 5;
    pts.add(c + Offset(math.cos(a) * rr, math.sin(a) * rr));
  }
  final p = poly(pts);
  pen.solid(p, Tones.auto(color), shade: r * .22, hi: r * .1, w: ink * 1.2);
}

/// شرارة بأربع أطراف (بيضاء) — لمعة.
void s1Spark(Pen pen, Offset c, double r, {Color color = const Color(0xFFFFFFFF), bool ink = true}) {
  final p = Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx + r * .18, c.dy - r * .18, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx + r * .18, c.dy + r * .18, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - r * .18, c.dy + r * .18, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx - r * .18, c.dy - r * .18, c.dx, c.dy - r)
    ..close();
  pen.fill(p, color);
  if (ink) pen.line(p, w: 1.1);
}

/// قلب.
void s1Heart(Pen pen, Offset c, double r, {Color color = const Color(0xFFFF4D6D), double rot = 0}) {
  var p = svg('M0 ${r * .95} C${-r * 1.7} ${-r * .2} ${-r * .8} ${-r * 1.35} 0 ${-r * .45} C${r * .8} ${-r * 1.35} ${r * 1.7} ${-r * .2} 0 ${r * .95} Z');
  p = rotatedAbout(p, Offset.zero, rot).shift(c);
  pen.solid(p, Tones.auto(color, shade: .3, hi: .3), shade: r * .3, hi: r * .14, w: Style.line * .9);
  pen.fill(Path()..addOval(Rect.fromCenter(center: c + Offset(-r * .55, -r * .42), width: r * .42, height: r * .26)), const Color(0xBBFFFFFF));
}

/// علامة استفهام بحد (أصفر).
void s1Question(Pen pen, Offset c, double r, {double rot = 0, Color color = const Color(0xFFFFD43B)}) {
  _glyph(pen, c, r, rot, color, svg('M${-r * .6} ${-r * .55} C${-r * .6} ${-r * 1.35} ${r * .75} ${-r * 1.35} ${r * .75} ${-r * .5} C${r * .75} ${r * .1} 0 ${r * .1} 0 ${r * .75}'), dot: Offset(0, r * 1.35));
}

/// علامة تعجب بحد.
void s1Exclaim(Pen pen, Offset c, double r, {double rot = 0, Color color = const Color(0xFFFF5252)}) {
  _glyph(pen, c, r, rot, color, svg('M0 ${-r * 1.25} L0 ${r * .35}'), dot: Offset(0, r * 1.15));
}

void _glyph(Pen pen, Offset c, double r, double rot, Color color, Path stem, {required Offset dot}) {
  pen.c.save();
  pen.c.translate(c.dx, c.dy);
  pen.c.rotate(rot);
  final lw = r * .62;
  final ink = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = lw + 3.4
    ..color = Style.ink;
  final fill = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = lw
    ..color = color;
  pen.c.drawPath(stem, ink);
  pen.c.drawCircle(dot, lw * .55 + 1.7, Paint()..color = Style.ink);
  pen.c.drawPath(stem, fill);
  pen.c.drawCircle(dot, lw * .55, Paint()..color = color);
  pen.c.restore();
}

/// خطوط هز (ثلاثة أقواس) حول نقطة، على جهة [side].
void s1ShakeLines(Pen pen, Offset c, double r, int side, {Color color = Style.ink, double w = 2.2}) {
  for (var i = 0; i < 3; i++) {
    final k = 1 + i * .5;
    final p = Path()..moveTo(c.dx + side * r * .2 * k, c.dy - r * .55 * k)
      ..quadraticBezierTo(c.dx + side * r * .75 * k, c.dy, c.dx + side * r * .2 * k, c.dy + r * .55 * k);
    pen.line(p, w: w * (1 - i * .15), color: color);
  }
}

/// علامة الغضب (٤ أقواس حمراء حول مركز).
void s1AngerMark(Pen pen, Offset c, double r) {
  const red = Color(0xFFE53935);
  final lw = r * .36;
  for (var i = 0; i < 4; i++) {
    final sx = (i == 0 || i == 3) ? 1.0 : -1.0;
    final sy = (i < 2) ? 1.0 : -1.0;
    final a = c + Offset(sx * r * .28, sy * r);
    final b = c + Offset(sx * r, sy * r * .28);
    final arc = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(c.dx + sx * r * .42, c.dy + sy * r * .42, b.dx, b.dy);
    pen.line(arc, w: lw + 3.0, color: Style.ink);
  }
  for (var i = 0; i < 4; i++) {
    final sx = (i == 0 || i == 3) ? 1.0 : -1.0;
    final sy = (i < 2) ? 1.0 : -1.0;
    final a = c + Offset(sx * r * .28, sy * r);
    final b = c + Offset(sx * r, sy * r * .28);
    final arc = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(c.dx + sx * r * .42, c.dy + sy * r * .42, b.dx, b.dy);
    pen.line(arc, w: lw, color: red);
  }
}

/// غيمة بخار / دخان (دوائر متداخلة بيضاء بحد واحد).
void s1Puff(Pen pen, Offset c, double r, {Color color = const Color(0xFFFFFFFF)}) {
  final blobs = <(Offset, double)>[
    (c + Offset(-r * .55, r * .1), r * .55),
    (c + Offset(0, -r * .2), r * .7),
    (c + Offset(r * .6, r * .1), r * .52),
    (c + Offset(0, r * .28), r * .55),
  ];
  var u = Path();
  for (final b in blobs) {
    u = Path.combine(PathOperation.union, u, circle(b.$1.dx, b.$1.dy, b.$2));
  }
  pen.solid(u, Tones(color, const Color(0xFFD5D2E6), const Color(0xFFFFFFFF)), shade: r * .22, hi: 0, w: Style.lineThin * 1.2);
}

const Color _mouthDark = Color(0xFF5A1D27);
const Color _tongue = Color(0xFFD0606A);

/// فم مفتوح كبير (ضحكة / صدمة) بإحداثيات الرأس: حافة علوية منحنية، أسنان، لسان.
/// [top] = انحناء الشفة العلوية (+ لتحت)، [depth] = عمق الفم، [tilt] = ميلان (ضحكة جانبية).
void s1Mouth(
  Pen pen,
  Head h, {
  double x = 0,
  double y = 43,
  double w = 17,
  double top = 0,
  double depth = 16,
  double teeth = 5,
  bool tongue = true,
  double tilt = 0,
  double widthBottom = .92,
}) {
  final sc = h.scale;
  Path P(String d) => h.path(svg(d), lift: 2.2);
  final l = x - w, r = x + w;
  final yl = y + tilt, yr = y - tilt;
  final mouth = P('M$l $yl Q$x ${y + top * 2} $r $yr C${r - w * (1 - widthBottom)} ${y + depth * 1.25} ${l + w * (1 - widthBottom)} ${y + depth * 1.25} $l $yl Z');
  pen.fill(mouth, _mouthDark);
  pen.inside(mouth, (p) {
    if (teeth > 0) {
      final t = P('M${l - 2} ${yl - 5} L${r + 2} ${yr - 5} L${r + 2} ${yr + teeth} Q$x ${y + top * 2 + teeth + 1.5} ${l - 2} ${yl + teeth} Z');
      p.fill(t, const Color(0xFFFFFFFF));
      p.line(P('M${l - 2} ${yl + teeth} Q$x ${y + top * 2 + teeth + 1.5} ${r + 2} ${yr + teeth}'), w: .9 * sc, color: withA(Style.ink, .35));
    }
    if (tongue) {
      p.fill(P('M${x - w * .62} ${y + depth * 1.3} C${x - w * .4} ${y + depth * .62} ${x + w * .4} ${y + depth * .62} ${x + w * .62} ${y + depth * 1.3} Z'), _tongue);
      p.line(P('M$x ${y + depth * .78} L$x ${y + depth * 1.05}'), w: .9 * sc, color: withA(const Color(0xFF8E2F3B), .7));
    }
  });
  pen.line(mouth, w: Style.lineThin * 1.25 * sc);
}

/// لسان طالع من ابتسامة (غمزة / مزح).
void s1TongueOut(Pen pen, Head h, {double x = 0, double y = 42, double w = 14, double len = 15, double lean = 0}) {
  final sc = h.scale;
  Path P(String d) => h.path(svg(d), lift: 2.2);
  final mouth = P('M${x - w} ${y - 2} Q$x ${y + 3} ${x + w} ${y - 3} Q$x ${y + 9} ${x - w} ${y - 2} Z');
  pen.fill(mouth, _mouthDark);
  final tongue = P('M${x - 6 + lean} ${y + 1} C${x - 8 + lean} ${y + len * .8} ${x + 8 + lean} ${y + len * .8} ${x + 6 + lean} ${y + 1} Z');
  pen.solid(tongue, const Tones(_tongue, Color(0xFFB0444F), Color(0xFFF08A92)), shade: 1.6 * sc, hi: .6, w: Style.lineThin * 1.1 * sc);
  pen.line(P('M${x + lean} ${y + 4} L${x + lean} ${y + len * .55}'), w: .9 * sc, color: withA(const Color(0xFF8E2F3B), .8));
  pen.line(P('M${x - w} ${y - 2} Q$x ${y + 4} ${x + w} ${y - 3}'), w: Style.lineThin * 1.25 * sc);
}
