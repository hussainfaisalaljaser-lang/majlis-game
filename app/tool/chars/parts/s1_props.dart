// أغراض الملصقات (S1): فنجان قهوة، دلة، صحن تمر، عدسة محقق، ورقة، منظار، لمبة، بخار.
// كلها بإحداثيات فضاء ٢٠٠ وحدة (مركز، حجم، دوران)، وبنفس الحد والتظليل.
import 'dart:math' as math;
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';
import 's1_faces.dart';

Path _place(Path p, Offset c, double s, double rot) {
  final cs = math.cos(rot) * s, sn = math.sin(rot) * s;
  return p.transform(affine(cs, sn, -sn, cs, c.dx, c.dy));
}

Path _sp(String d, Offset c, double s, double rot) => _place(svg(d), c, s, rot);

const _gold = Tones(Color(0xFFE9B63B), Color(0xFFB8801C), Color(0xFFFFE08A));
const _coffee = Color(0xFF4B2A1A);

/// فنجان قهوة عربي (بدون يد): الحافة تحت [c] بشوي. [steam] = بخار بسيط ثابت.
void s1Cup(Pen pen, Offset c, {double s = 1, double rot = 0, bool steam = false, bool cold = false, bool coffee = true}) {
  Path P(String d) => _sp(d, c, s, rot);
  // قاعدة
  final foot = P('M-6.5 11 L-8 16 C-4 18 4 18 8 16 L6.5 11 Z');
  pen.solid(foot, _gold, shade: 1.6, hi: .8, w: Style.lineThin * 1.1);
  // الكاس
  final bowl = P('M-14 -13 C-14 3 -8 12 0 12.5 C8 12 14 3 14 -13 Z');
  pen.solid(bowl, Cloth.white, shade: 4, hi: 1.4, w: Style.line * .9);
  pen.inside(bowl, (p) {
    // شريط زخرفة زرقاء + ذهبي
    final band = P('M-15 -5 C-6 -2 6 -2 15 -5 L15 1 C6 4 -6 4 -15 1 Z');
    p.fill(band, const Color(0xFF3F74B8));
    p.line(P('M-15 -5 C-6 -2 6 -2 15 -5'), w: 1.0, color: _gold.base);
    p.line(P('M-15 1 C-6 4 6 4 15 1'), w: 1.0, color: _gold.base);
    for (var i = -2; i <= 2; i++) {
      p.fill(_place(circle(0, 0, .9), c + Offset(i * 5.2 * s, (-1.2 + (i * i) * .18) * s), 1, 0), Cloth.white.base);
    }
  });
  pen.line(bowl, w: Style.line * .9);
  // الحافة + القهوة
  final rim = P('M-14 -13 C-14 -17 14 -17 14 -13 C14 -9 -14 -9 -14 -13 Z');
  pen.fill(rim, coffee ? (cold ? const Color(0xFF3B2A22) : _coffee) : Cloth.white.shade);
  pen.line(rim, w: Style.lineThin * 1.1);
  if (coffee) pen.fill(_place(ellipse(-5, -0, 3.6, 1.1), c + Offset(-1 * s, -13.6 * s), 1, rot), withA(const Color(0xFFFFFFFF), cold ? .0 : .35));
  if (steam && !cold) {
    for (var i = -1; i <= 1; i++) {
      final x = i * 7.0;
      final d = 'M$x -18 C${x - 5} -24 ${x + 5} -28 $x -35 C${x - 4} -40 ${x + 4} -44 $x -50';
      pen.line(P(d), w: 4.0 * s, color: Style.ink);
    }
    for (var i = -1; i <= 1; i++) {
      final x = i * 7.0;
      final d = 'M$x -18 C${x - 5} -24 ${x + 5} -28 $x -35 C${x - 4} -40 ${x + 4} -44 $x -50';
      pen.line(P(d), w: 2.0 * s, color: const Color(0xFFFFFFFF));
    }
  }
}

/// دلة قهوة ذهبية: القاعدة عند [c]، والمنقار يمين فوق (قلّبها بـ [flip] ودوّرها للصب).
void s1Dallah(Pen pen, Offset c, {double s = 1, double rot = 0, bool flip = false}) {
  final f = flip ? -1 : 1;
  Path P(String d) => _sp(d, c, s, rot);
  String m(String d) => flip ? _mirror(d) : d;
  // المقبض
  final handle = P(m('M16 -8 C34 -16 36 14 18 16'));
  pen.line(handle, w: 6.4 * s, color: Style.ink);
  pen.line(handle, w: 3.6 * s, color: _gold.base);
  // المنقار (طويل ومنحني)
  final spout = P(m('M-10 -10 C-18 -26 -26 -34 -36 -50 L-30 -54 C-18 -42 -6 -28 6 -22 Z'));
  pen.solid(spout, _gold, shade: 2.4, hi: 1, w: Style.line * .9);
  // البدن
  final body = P(m('M-18 16 C-26 -4 -16 -18 -8 -24 L10 -24 C18 -18 28 -4 18 16 C8 20 -8 20 -18 16 Z'));
  pen.solid(body, _gold, shade: 5, hi: 1.6, w: Style.line);
  pen.inside(body, (p) {
    p.line(P(m('M-20 2 C-8 7 8 7 20 2')), w: 1.4, color: withA(_gold.shade, .95));
    p.line(P(m('M-12 -12 C-4 -9 4 -9 12 -12')), w: 1.2, color: withA(_gold.shade, .9));
    for (var i = -1; i <= 1; i++) {
      p.fill(_place(circle(0, 0, 1.2), c, 1, 0).shift(Offset(i * 6.0 * s * f, 6 * s)), const Color(0xFFC2410C));
    }
  });
  // غطاء
  final lid = P(m('M-8 -24 C-8 -32 8 -32 8 -24 Z'));
  pen.solid(lid, _gold, shade: 1.6, hi: .8, w: Style.lineThin * 1.2);
  pen.fill(_place(circle(0, 0, 2.4), c + Offset(0, -33 * s), 1, 0), _gold.hi);
  pen.line(_place(circle(0, 0, 2.4), c + Offset(0, -33 * s), 1, 0), w: Style.lineThin);
}

String _mirror(String d) {
  // يعكس إحداثيات x في مسار مكتوب بأوامر مطلقة (M C L Z)
  final tok = RegExp(r'[MLCZ]|-?\d+\.?\d*').allMatches(d).map((m) => m.group(0)!).toList();
  final out = StringBuffer();
  var isX = true;
  for (final t in tok) {
    if (RegExp(r'[A-Z]').hasMatch(t)) {
      out.write('$t ');
      isX = true;
    } else {
      final v = double.parse(t);
      out.write('${isX ? -v : v} ');
      isX = !isX;
    }
  }
  return out.toString();
}

/// صحن تمر: بيضاوي مع هرم تمرات.
void s1Dates(Pen pen, Offset c, {double s = 1, double rot = 0}) {
  Path P(String d) => _sp(d, c, s, rot);
  final plate = P('M-26 0 C-26 -7 26 -7 26 0 C26 9 14 12 0 12 C-14 12 -26 9 -26 0 Z');
  pen.solid(plate, Cloth.white, shade: 3, hi: 1, w: Style.line * .9);
  pen.fill(P('M-21 -1 C-21 -5 21 -5 21 -1 C21 4 10 7 0 7 C-10 7 -21 4 -21 -1 Z'), const Color(0xFFE7E2F2));
  const date = Tones(Color(0xFF7A3F1D), Color(0xFF4F2410), Color(0xFFA9622D));
  void d(double x, double y, double r) {
    final p = _place(ellipse(0, 0, 6.4, 4.2, rot: r), c + Offset(x * s, y * s), s, rot);
    pen.solid(p, date, shade: 1.6, hi: .9, w: Style.lineThin * 1.05);
    pen.fill(_place(ellipse(0, 0, 2.4, .9, rot: r - .2), c + Offset((x - 1.8) * s, (y - 1.6) * s), s, rot), withA(const Color(0xFFFFE0B0), .7));
  }

  d(-11, -3, .15);
  d(0, -2, -.1);
  d(11, -3, .2);
  d(-5, -8.5, -.2);
  d(6, -8.5, .1);
  d(0, -14, .05);
}

/// عدسة محقق: حلقة ذهبية وزجاج وإيد خشب.
void s1Magnifier(Pen pen, Offset c, {double s = 1, double rot = 0}) {
  Path P(String d) => _sp(d, c, s, rot);
  final handle = P('M10 12 L34 36');
  pen.line(handle, w: 9 * s, color: Style.ink);
  pen.line(handle, w: 6 * s, color: const Color(0xFF7A4A26));
  pen.line(P('M8.5 10.5 L16 18'), w: 8.4 * s, color: Style.ink);
  pen.line(P('M8.5 10.5 L16 18'), w: 5.6 * s, color: _gold.base);
  // الحلقة والزجاج
  final glass = _place(circle(0, 0, 18), c, s, rot);
  pen.fill(glass, withA(const Color(0xFFBFE6FF), .55));
  pen.fill(P('M-12 -6 C-9 -13 -3 -15 3 -15 C-6 -12 -10 -7 -12 -2 Z'), withA(const Color(0xFFFFFFFF), .75));
  pen.line(glass, w: 7.6 * s, color: Style.ink);
  pen.line(glass, w: 4.6 * s, color: _gold.base);
  pen.line(_place(circle(-1.2, -1.2, 18), c, s, rot), w: 1.2 * s, color: _gold.hi);
}

/// ورقة دليل: ورقة مائلة بسطور وختم أحمر.
void s1Paper(Pen pen, Offset c, {double s = 1, double rot = 0}) {
  Path P(String d) => _sp(d, c, s, rot);
  final sheet = P('M-17 -22 L15 -22 C17 -22 18 -21 18 -19 L18 21 C18 23 17 24 15 24 L-15 24 C-17 24 -18 23 -18 21 L-18 -19 C-18 -21 -17 -22 -15 -22 Z');
  pen.solid(sheet, const Tones(Color(0xFFFBF3DE), Color(0xFFD9C9A6), Color(0xFFFFFFFF)), shade: 3.2, hi: 1, w: Style.line * .95);
  for (var i = 0; i < 4; i++) {
    pen.line(P('M-11 ${-13 + i * 6.2} L${i == 3 ? 3 : 11} ${-13 + i * 6.2}'), w: 1.7 * s, color: withA(Style.ink, .55));
  }
  final seal = _place(circle(0, 0, 6), c + Offset(7 * s, 14 * s), 1, 0);
  pen.solid(seal, const Tones(Color(0xFFD7263D), Color(0xFF9C1428), Color(0xFFFF6B7D)), shade: 1.4, hi: .6, w: Style.lineThin * 1.1);
  pen.fill(_place(circle(0, 0, 2.2), c + Offset(7 * s, 14 * s), 1, 0), const Color(0xFFFFB3BC));
}

/// منظار (عدستين زرق) فوق العينين: [eyeL] و[eyeR] مراكز العينين في فضاء ٢٠٠.
void s1Binoculars(Pen pen, Offset eyeL, Offset eyeR, {double r = 15}) {
  const rim = Tones(Color(0xFF3B4150), Color(0xFF232733), Color(0xFF6C7488));
  final mid = Offset((eyeL.dx + eyeR.dx) / 2, (eyeL.dy + eyeR.dy) / 2);
  // الجسر
  final bridge = Path()
    ..moveTo(eyeL.dx + r * .5, eyeL.dy)
    ..lineTo(eyeR.dx - r * .5, eyeR.dy);
  pen.line(bridge, w: r * .55 + 3.4, color: Style.ink);
  pen.line(bridge, w: r * .55, color: rim.base);
  for (final e in [eyeL, eyeR]) {
    final outer = circle(e.dx, e.dy, r);
    pen.solid(outer, rim, shade: 3.4, hi: 1.2, w: Style.line);
    final lens = circle(e.dx, e.dy, r * .74);
    pen.fillShader(lens, Gradient.radial(e + Offset(-r * .25, -r * .3), r, [const Color(0xFF9EDCFF), const Color(0xFF3F8FE0), const Color(0xFF1D4F9C)], [0, .55, 1]));
    pen.line(lens, w: 1.6, color: Style.ink);
    pen.fill(Path()..addOval(Rect.fromCenter(center: e + Offset(-r * .28, -r * .3), width: r * .5, height: r * .3)), withA(const Color(0xFFFFFFFF), .85));
    pen.fill(circle(e.dx + r * .3, e.dy + r * .32, r * .09), withA(const Color(0xFFFFFFFF), .7));
  }
  pen.fill(circle(mid.dx, mid.dy, r * .24), rim.hi);
  pen.line(circle(mid.dx, mid.dy, r * .24), w: Style.lineThin);
}

/// لمبة فكرة (أصفر) مع إشعاع.
void s1Bulb(Pen pen, Offset c, double r) {
  for (var i = -2; i <= 2; i++) {
    final a = -math.pi / 2 + i * .62;
    final p0 = c + Offset(math.cos(a), math.sin(a)) * (r * 1.4);
    final p1 = c + Offset(math.cos(a), math.sin(a)) * (r * 1.9);
    final l = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy);
    pen.line(l, w: 4.6, color: Style.ink);
    pen.line(l, w: 2.4, color: const Color(0xFFFFE066));
  }
  final glass = Path()
    ..moveTo(c.dx - r * .55, c.dy + r * .75)
    ..cubicTo(c.dx - r * .55, c.dy + r * .3, c.dx - r * 1.05, c.dy + r * .1, c.dx - r * 1.05, c.dy - r * .45)
    ..cubicTo(c.dx - r * 1.05, c.dy - r * 1.2, c.dx + r * 1.05, c.dy - r * 1.2, c.dx + r * 1.05, c.dy - r * .45)
    ..cubicTo(c.dx + r * 1.05, c.dy + r * .1, c.dx + r * .55, c.dy + r * .3, c.dx + r * .55, c.dy + r * .75)
    ..close();
  pen.solid(glass, const Tones(Color(0xFFFFE066), Color(0xFFF2B01E), Color(0xFFFFF4B0)), shade: r * .3, hi: r * .12, w: Style.line * .95);
  final base = RRect.fromRectAndRadius(Rect.fromCenter(center: c + Offset(0, r * 1.02), width: r * 1.2, height: r * .46), Radius.circular(r * .16));
  final bp = Path()..addRRect(base);
  pen.solid(bp, const Tones(Color(0xFFB8BCCB), Color(0xFF858A9D), Color(0xFFE6E8F0)), shade: 1.4, hi: .7, w: Style.lineThin * 1.1);
  pen.line(Path()..moveTo(c.dx - r * .3, c.dy + r * .3)..lineTo(c.dx, c.dy - r * .2)..lineTo(c.dx + r * .3, c.dy + r * .3), w: 1.2, color: const Color(0xFFB8770B));
  pen.fill(Path()..addOval(Rect.fromCenter(center: c + Offset(-r * .5, -r * .5), width: r * .3, height: r * .55)), withA(const Color(0xFFFFFFFF), .75));
}

/// خطوط بخار ملتفة (سميكة بحد) بدءاً من [c] لفوق.
void s1Steam(Pen pen, Offset c, {double s = 1, int n = 3, double gap = 8}) {
  for (var i = 0; i < n; i++) {
    final x = (i - (n - 1) / 2) * gap * s;
    final d = Path()
      ..moveTo(c.dx + x, c.dy)
      ..cubicTo(c.dx + x - 5 * s, c.dy - 7 * s, c.dx + x + 5 * s, c.dy - 11 * s, c.dx + x, c.dy - 18 * s)
      ..cubicTo(c.dx + x - 4 * s, c.dy - 23 * s, c.dx + x + 4 * s, c.dy - 27 * s, c.dx + x, c.dy - 33 * s);
    pen.line(d, w: 4.4 * s, color: Style.ink);
    pen.line(d, w: 2.3 * s, color: const Color(0xFFFFFFFF));
  }
}

/// قلب ينبض مع هالة (للتوتر): قلب كبير + خطوط نبض.
void s1HeartBeat(Pen pen, Offset c, double r) {
  for (var i = 0; i < 3; i++) {
    final a = -math.pi / 2 + (i - 1) * .55 + .0;
    final p0 = c + Offset(math.cos(a), math.sin(a)) * (r * 1.35);
    final p1 = c + Offset(math.cos(a), math.sin(a)) * (r * 1.75);
    final l = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy);
    pen.line(l, w: 4.2, color: Style.ink);
    pen.line(l, w: 2.0, color: const Color(0xFFFFFFFF));
  }
  s1Heart(pen, c, r);
}

/// موقع نقطة على الوجه في فضاء ٢٠٠ (اختصار).
Offset s1At(Head h, double x, double y, {double lift = 0}) => h.pt(x, y, lift: lift);
