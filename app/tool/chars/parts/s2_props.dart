// Props for the stickers (worker S2): crown, halo, trophy, dagger, mask, rocket, lantern, tea glass,
// moon, stars, night cap, bulb, "100" badge, heart, flames, lightning, bursts, gold bars, falcon,
// ghost, mind waves, zzz, confetti. Everything is drawn with the kit's Pen (thick ink outline, cel
// shading) in AVATAR space. Each prop has a local frame (documented on it) placed with [at] / [rot] / [s].
import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:flutter/painting.dart' show FontWeight, TextDirection, TextPainter, TextSpan, TextStyle;

import '../core/pen.dart';
import 's2_eyes.dart' show s2Star;

const s2Gold = Tones(Color(0xFFF6C744), Color(0xFFC98B14), Color(0xFFFFE9A0));
const s2Silver = Tones(Color(0xFFDCDDE8), Color(0xFF9C9EB6), Color(0xFFFFFFFF));
const s2Red = Tones(Color(0xFFE5453A), Color(0xFF9E2420), Color(0xFFFF8C7A));
const s2Blue = Tones(Color(0xFF4D86E8), Color(0xFF2A4FA6), Color(0xFF9DC0FF));
const s2Purple = Tones(Color(0xFF8E52D6), Color(0xFF5B2E96), Color(0xFFBE92F2));
const s2Brown = Tones(Color(0xFF8A5A34), Color(0xFF5B3820), Color(0xFFB98456));
const s2Orange = Tones(Color(0xFFFF8A1F), Color(0xFFD8520A), Color(0xFFFFB866));
const s2Yellow = Tones(Color(0xFFFFD84D), Color(0xFFE5A116), Color(0xFFFFF0A0));

void _tf(Pen pen, Offset at, double rot, double s, void Function() draw) {
  pen.c.save();
  pen.c.translate(at.dx, at.dy);
  pen.c.rotate(rot);
  pen.c.scale(s, s);
  draw();
  pen.c.restore();
}

/// Round outlined text (fill + dark stroke) centred on [at]; the font is the app's Baloo.
void s2Text(Pen pen, String text, Offset at, double fontSize, Color fill, {double stroke = 3.2, double rot = 0}) {
  TextPainter mk(Paint? fg, Color? color) => TextPainter(
    textDirection: TextDirection.rtl,
    text: TextSpan(text: text, style: TextStyle(fontFamily: 'Baloo', fontWeight: FontWeight.w800, fontSize: fontSize, height: 1.0, color: fg == null ? color : null, foreground: fg)),
  )..layout();
  final f = mk(null, fill);
  final st = mk(
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..color = Style.ink,
    null,
  );
  pen.c.save();
  pen.c.translate(at.dx, at.dy);
  pen.c.rotate(rot);
  final o = Offset(-f.width / 2, -f.height / 2);
  st.paint(pen.c, o);
  f.paint(pen.c, o);
  pen.c.restore();
}

/// 4-point sparkle (glint).
void s2Sparkle(Pen pen, Offset at, double r, {Color color = const Color(0xFFFFE066), bool ink = true}) {
  final s = r * .26;
  final p = Path()
    ..moveTo(at.dx, at.dy - r)
    ..quadraticBezierTo(at.dx + s * .35, at.dy - s * .35, at.dx + r, at.dy)
    ..quadraticBezierTo(at.dx + s * .35, at.dy + s * .35, at.dx, at.dy + r)
    ..quadraticBezierTo(at.dx - s * .35, at.dy + s * .35, at.dx - r, at.dy)
    ..quadraticBezierTo(at.dx - s * .35, at.dy - s * .35, at.dx, at.dy - r)
    ..close();
  pen.fill(p, color);
  if (ink) pen.line(p, w: math.max(1.1, r * .16), color: Style.ink);
  pen.fill(circle(at.dx - r * .08, at.dy - r * .08, r * .13), const Color(0xFFFFFFFF));
}

/// 5-point star with outline (gold by default). Centre [at], outer radius [r].
void s2StarProp(Pen pen, Offset at, double r, {Tones tones = s2Yellow, double rot = -math.pi / 2}) {
  final p = s2Star(at.dx, at.dy, r, inner: .5, rot: rot);
  pen.solid(p, tones, shade: r * .18, hi: r * .1, w: math.max(1.4, r * .16));
  pen.fill(circle(at.dx - r * .22, at.dy - r * .28, r * .13), const Color(0xFFFFFFFF));
}

/// Crown. Frame: origin = bottom centre, 68 wide, 46 tall.
void s2Crown(Pen pen, Offset at, {double s = 1, double rot = 0}) => _tf(pen, at, rot, s, () {
  final body = svg('M-30 0 L-35 -33 L-17 -19 L0 -45 L17 -19 L35 -33 L30 0 Z');
  pen.solid(body, s2Gold, shade: 4, hi: 1.5);
  pen.line(svg('M-29.4 -10 L29.4 -10'), w: Style.lineThin, color: Style.ink);
  for (final p in const [Offset(-35, -34), Offset(0, -46), Offset(35, -34)]) {
    pen.solid(circle(p.dx, p.dy, 4.4), s2Gold, shade: 1.4, hi: .8, w: Style.lineThin * 1.2);
  }
  pen.shape(circle(0, -5, 3.6), const Color(0xFFE5453A), w: Style.lineThin);
  for (final x in const [-17.0, 17.0]) {
    pen.shape(circle(x, -5, 2.8), const Color(0xFF4D86E8), w: Style.lineThin);
  }
  pen.fill(circle(-1, -6.2, 1.0), const Color(0xFFFFFFFF));
  pen.taper(svg('M-24 -4 C-26 -14 -26 -22 -29 -28'), w0: 2.0, w1: .3, color: withA(const Color(0xFFFFFFFF), .8));
});

/// Golden halo ring. Frame: origin = ring centre.
void s2Halo(Pen pen, Offset at, {double rx = 30, double ry = 8}) {
  pen.glow(at, rx * 1.2, ry * 2.4, s2Gold.base, alpha: .3);
  final e = ellipse(at.dx, at.dy, rx, ry);
  pen.line(e, w: 9.6, color: Style.ink);
  pen.line(e, w: 5.6, color: s2Gold.base);
  final arc = Path()..addArc(Rect.fromCenter(center: at.translate(0, -.6), width: rx * 2 - 1, height: ry * 2 - 1), math.pi * 1.08, math.pi * .62);
  pen.line(arc, w: 1.8, color: s2Gold.hi);
}

/// Trophy cup. Frame: origin = bottom centre, 52 wide, 56 tall.
void s2Trophy(Pen pen, Offset at, {double s = 1, double rot = 0}) => _tf(pen, at, rot, s, () {
  for (final g in const [-1.0, 1.0]) {
    final h = svg('M${g * 17} -49 C${g * 34} -51 ${g * 34} -27 ${g * 12} -25');
    pen.line(h, w: 9, color: Style.ink);
    pen.line(h, w: 4.6, color: s2Gold.base);
  }
  final cup = svg('M-20 -55 L20 -55 C20 -33 14 -23 5 -19.5 L5 -13 L-5 -13 L-5 -19.5 C-14 -23 -20 -33 -20 -55 Z');
  pen.solid(cup, s2Gold, shade: 5, hi: 1.6);
  pen.shape(ellipse(0, -55, 20, 4.2), s2Gold.shade, w: Style.lineThin);
  pen.fill(ellipse(0, -55.4, 17, 2.6), const Color(0xFF8A5A14));
  final base = svg('M-15 -13 L15 -13 L18 0 L-18 0 Z');
  pen.solid(base, Tones(s2Gold.shade, shadeOf(s2Gold.shade, .25), s2Gold.base), shade: 3, hi: 1.2);
  pen.solid(svg('M-9 -13 L9 -13 L9 -17 L-9 -17 Z'), s2Gold, shade: 1.2, hi: .8, w: Style.lineThin);
  pen.solid(s2Star(0, -37, 7.4, inner: .5), s2Red, shade: 1.2, hi: .6, w: Style.lineThin);
  pen.taper(svg('M-13 -50 C-14 -40 -11 -32 -7 -27'), w0: 3.0, w1: .3, color: withA(const Color(0xFFFFFFFF), .85));
});

/// Dagger pointing DOWN. Frame: origin = guard centre; blade to +y (56), handle to -y (26).
void s2Dagger(Pen pen, Offset at, {double s = 1, double rot = 0}) => _tf(pen, at, rot, s, () {
  final blade = svg('M-6 0 L6 0 L5 38 C4 46 2 52 0 58 C-2 52 -4 46 -5 38 Z');
  pen.solid(blade, s2Silver, shade: 3, hi: 1.2);
  pen.line(svg('M0 3 L0 50'), w: Style.lineFine, color: withA(s2Silver.shade, .9));
  final handle = svg('M-3.8 -3 L3.8 -3 L3.2 -22 L-3.2 -22 Z');
  pen.solid(handle, s2Brown, shade: 2, hi: .8);
  for (final y in const [-8.0, -13.0, -18.0]) {
    pen.line(svg('M-3.4 $y L3.4 ${y + 1.4}'), w: Style.lineFine, color: withA(Style.ink, .7));
  }
  pen.solid(circle(0, -25.5, 4.6), s2Gold, shade: 1.4, hi: .8, w: Style.lineThin * 1.2);
  final guard = svg('M-15 -4 C-15 -9 15 -9 15 -4 L15 1.6 C15 5 -15 5 -15 1.6 Z');
  pen.solid(guard, s2Gold, shade: 2, hi: 1);
  pen.taper(svg('M-3 6 L-2.4 34'), w0: 1.6, w1: .3, color: withA(const Color(0xFFFFFFFF), .9));
});

/// Venetian mask on a stick. Frame: origin = mask centre, 56 wide; stick goes down-right.
void s2Mask(Pen pen, Offset at, {double s = 1, double rot = 0}) => _tf(pen, at, rot, s, () {
  final stick = svg('M26 4 L46 40');
  pen.line(stick, w: 6.4, color: Style.ink);
  pen.line(stick, w: 3.2, color: s2Gold.base);
  final m = svg('M-29 -4 C-29 -15 -14 -18 -4 -12 C-2 -10.5 2 -10.5 4 -12 C14 -18 29 -15 29 -4 C29 7 16 13 7 7 C3 4 -3 4 -7 7 C-16 13 -29 7 -29 -4 Z');
  pen.solid(m, s2Purple, shade: 4, hi: 1.4);
  for (final g in const [-1.0, 1.0]) {
    pen.shape(ellipse(g * 15, -3.6, 7.6, 4.8, rot: g * .22), const Color(0xFF1C1424), w: Style.lineThin);
    pen.line(svg('M${g * 7} -12 C${g * 16} -16 ${g * 25} -13 ${g * 28} -6'), w: 1.8, color: s2Gold.base);
  }
  pen.line(svg('M-9 5 C-4 8 4 8 9 5'), w: 1.4, color: s2Gold.base);
  pen.solid(s2Star(0, -6.5, 4.6, inner: .5), s2Gold, shade: .8, hi: .5, w: Style.lineFine);
  pen.taper(svg('M-24 -10 C-20 -14 -15 -15 -10 -14'), w0: 2.0, w1: .3, color: withA(const Color(0xFFFFFFFF), .75));
});

/// Rocket pointing up. Frame: origin = centre of the body; 70 tall.
void s2Rocket(Pen pen, Offset at, {double s = 1, double rot = 0}) => _tf(pen, at, rot, s, () {
  final flame = svg('M-7 14 C-9 26 -2 38 0 44 C2 38 9 26 7 14 Z');
  pen.solid(flame, s2Orange, shade: 2, hi: 1.2);
  pen.fill(svg('M-3.6 16 C-4 24 -1 30 0 34 C1 30 4 24 3.6 16 Z'), s2Yellow.base);
  for (final g in const [-1.0, 1.0]) {
    pen.solid(svg('M${g * 11} -2 C${g * 20} 8 ${g * 24} 18 ${g * 24} 26 L${g * 10} 14 Z'), s2Red, shade: 2.4, hi: 1.0, w: Style.line * .85);
  }
  final body = svg('M0 -42 C15 -28 15 -4 12 15 L-12 15 C-15 -4 -15 -28 0 -42 Z');
  pen.solid(body, const Tones(Color(0xFFF7F4FA), Color(0xFFC3C0DC), Color(0xFFFFFFFF)), shade: 4, hi: 1.4);
  final nose = svg('M0 -42 C8 -35 11 -28 12.4 -21 L-12.4 -21 C-11 -28 -8 -35 0 -42 Z');
  pen.solid(nose, s2Red, shade: 3, hi: 1.2);
  pen.shape(circle(0, -6, 7.2), const Color(0xFF8FC6FF), w: Style.line * .9);
  pen.fill(circle(-2, -8, 2), const Color(0xFFFFFFFF));
  pen.solid(svg('M-12 11 L12 11 L10 17 L-10 17 Z'), Tones(s2Red.base, s2Red.shade, s2Red.hi), shade: 1.6, hi: .8, w: Style.lineThin * 1.2);
});

/// Fanous lantern. Frame: origin = centre of the glass; 38 wide, 66 tall, a hanging ring on top.
void s2Lantern(Pen pen, Offset at, {double s = 1, double rot = 0}) => _tf(pen, at, rot, s, () {
  pen.glow(const Offset(0, 0), 26, 30, const Color(0xFFFFC857), alpha: .45);
  pen.line(circle(0, -36, 4.2), w: Style.lineThin * 1.4, color: Style.ink);
  pen.line(svg('M0 -32 L0 -26'), w: 2.4, color: Style.ink);
  pen.solid(svg('M-8 -26 L8 -26 L15 -17 L-15 -17 Z'), s2Gold, shade: 2.4, hi: 1.0);
  final glass = svg('M-15 -17 L15 -17 C22 -5 20 8 13 19 L-13 19 C-20 8 -22 -5 -15 -17 Z');
  const glow = Tones(Color(0xFFFFE9A0), Color(0xFFF2B84A), Color(0xFFFFF8DC));
  pen.solid(glass, glow, shade: 4.4, hi: 1.6);
  pen.inside(glass, (q) {
    for (final x in const [-8.0, 0.0, 8.0]) {
      q.line(svg('M${x * .8} -17 C${x * 1.5} -4 ${x * 1.5} 8 ${x * .9} 19'), w: 1.5, color: s2Gold.shade);
    }
    q.line(svg('M-19 0 C-8 4 8 4 19 0'), w: 1.3, color: s2Gold.shade);
  });
  pen.line(glass, w: Style.line * .95, color: Style.ink);
  pen.solid(svg('M-14 19 L14 19 L10 27 L-10 27 Z'), s2Gold, shade: 2.2, hi: 1.0);
  pen.solid(circle(0, 30, 3.4), s2Gold, shade: 1, hi: .6, w: Style.lineThin * 1.2);
});

/// Small tea glass (istikana) on a saucer. Frame: origin = bottom centre of the glass; 34 wide, 36 tall.
void s2TeaGlass(Pen pen, Offset at, {double s = 1, double rot = 0}) => _tf(pen, at, rot, s, () {
  final saucer = ellipse(0, 3, 18, 5);
  pen.solid(saucer, const Tones(Color(0xFFFFF5E8), Color(0xFFD9C6B4), Color(0xFFFFFFFF)), shade: 1.6, hi: .8, w: Style.line * .85, dir: const Offset(0, -1));
  pen.line(ellipse(0, 2.4, 11, 2.8), w: Style.lineFine, color: withA(Style.ink, .5));
  final glass = svg('M-10 -31 C-8.4 -22 -5.6 -17 -5.6 -11 C-5.6 -6 -8.6 -4 -8.6 1 L8.6 1 C8.6 -4 5.6 -6 5.6 -11 C5.6 -17 8.4 -22 10 -31 Z');
  pen.fill(glass, withA(const Color(0xFFF6EEF0), .9));
  final tea = svg('M-9 -24 L9 -24 C8 -18 5.6 -15 5.6 -11 C5.6 -6 8.6 -4 8.6 1 L-8.6 1 C-8.6 -4 -5.6 -6 -5.6 -11 C-5.6 -15 -8 -18 -9 -24 Z');
  pen.inside(glass, (q) {
    q.fill(tea, const Color(0xFFD2551C));
    q.crescent(tea, const Color(0xFF9D3A0E), depth: 3, dir: const Offset(-0.8, 0));
    q.fill(ellipse(0, -24, 9.4, 2.2), const Color(0xFFF08A3C));
  });
  pen.line(glass, w: Style.line * .85, color: Style.ink);
  pen.line(ellipse(0, -31, 10, 2.2), w: Style.lineThin, color: Style.ink);
  pen.line(svg('M-6.6 -28 C-6 -22 -4.4 -18 -4 -14'), w: 1.6, color: withA(const Color(0xFFFFFFFF), .9));
  pen.line(svg('M-8 -29 L8 -29'), w: 1.4, color: s2Gold.base);
});

/// Crescent moon. Frame: origin = centre, 40 tall.
void s2Moon(Pen pen, Offset at, {double s = 1, double rot = 0}) => _tf(pen, at, rot, s, () {
  final m = svg('M8 -22 C-12 -22 -24 -6 -20 10 C-16 26 4 30 18 20 C2 22 -6 8 -2 -6 C0 -13 3 -19 8 -22 Z');
  pen.solid(m, s2Yellow, shade: 3.4, hi: 1.2);
  pen.fill(circle(-12, 4, 1.4), withA(s2Yellow.shade, .9));
});

/// Droopy night cap sitting on the head. Frame: origin = top-centre of the head dome (local y 0 = dome top).
void s2NightCap(Pen pen, Offset at, {double s = 1}) => _tf(pen, at, 0, s, () {
  const blue = Tones(Color(0xFF4A63E0), Color(0xFF2B3AA0), Color(0xFF8CA0FF));
  final cap = svg('M-46 22 C-44 -10 -10 -34 26 -24 C52 -16 66 8 82 36 C72 34 62 28 52 22 C36 14 -24 14 -46 22 Z');
  pen.solid(cap, blue, shade: 5, hi: 1.6);
  pen.inside(cap, (q) {
    q.line(svg('M-30 8 C-8 -8 24 -8 46 12'), w: 3.4, color: withA(const Color(0xFFFFFFFF), .55));
    q.line(svg('M-36 15 C-10 1 22 1 52 20'), w: 2.4, color: withA(const Color(0xFFFFFFFF), .4));
  });
  final band = svg('M-50 20 C-30 10 36 10 56 22 L54 34 C34 24 -30 24 -52 33 Z');
  pen.solid(band, const Tones(Color(0xFFFFFFFF), Color(0xFFD0D0E8), Color(0xFFFFFFFF)), shade: 3, hi: 1);
  pen.solid(circle(84, 38, 9.4), const Tones(Color(0xFFFFFFFF), Color(0xFFD0D0E8), Color(0xFFFFFFFF)), shade: 2, hi: 1);
});

/// Light bulb. Frame: origin = centre of the glass.
void s2Bulb(Pen pen, Offset at, {double s = 1, double rot = 0}) => _tf(pen, at, rot, s, () {
  pen.glow(Offset.zero, 24, 24, const Color(0xFFFFE066), alpha: .5);
  for (var i = 0; i < 5; i++) {
    final a = -math.pi / 2 + (i - 2) * 0.62;
    final p0 = Offset(math.cos(a) * 22, math.sin(a) * 22), p1 = Offset(math.cos(a) * 30, math.sin(a) * 30);
    pen.line(Path()..moveTo(p0.dx, p0.dy)..lineTo(p1.dx, p1.dy), w: 5.6, color: Style.ink);
    pen.line(Path()..moveTo(p0.dx, p0.dy)..lineTo(p1.dx, p1.dy), w: 2.8, color: s2Yellow.base);
  }
  pen.solid(svg('M-7.4 13 L7.4 13 L6.4 23 L-6.4 23 Z'), s2Silver, shade: 2.2, hi: 1, w: Style.line * .85);
  pen.line(svg('M-6.8 17 L6.8 17'), w: Style.lineFine, color: withA(Style.ink, .6));
  pen.solid(svg('M-4.6 23 L4.6 23 L3 28 L-3 28 Z'), s2Silver, shade: 1, hi: .5, w: Style.lineThin);
  final glass = svg('M-7.4 13 C-8 7 -17 4 -17 -6 C-17 -15 -9 -20 0 -20 C9 -20 17 -15 17 -6 C17 4 8 7 7.4 13 Z');
  pen.solid(glass, s2Yellow, shade: 4, hi: 1.4);
  pen.line(svg('M-3 12 L-3 3 C-6 -2 -3 -6 0 -4 C3 -6 6 -2 3 3 L3 12'), w: 1.5, color: const Color(0xFFE58A12));
  pen.taper(svg('M-12 -12 C-13 -8 -12 -4 -9 0'), w0: 2.4, w1: .3, color: withA(const Color(0xFFFFFFFF), .9));
});

/// Red "100" badge. Frame: origin = centre, 64 x 38.
void s2Badge100(Pen pen, Offset at, {double s = 1, double rot = 0}) {
  _tf(pen, at, rot, s, () {
    final b = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 64, height: 38), const Radius.circular(11)));
    pen.solid(b, s2Red, shade: 5, hi: 1.6, w: Style.line);
    pen.line(Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 56, height: 30), const Radius.circular(8))), w: 1.1, color: withA(const Color(0xFFFFFFFF), .5));
  });
  final c = pen.c;
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(rot);
  c.scale(s, s);
  s2Text(pen, '١٠٠', const Offset(0, 1), 27, const Color(0xFFFFFFFF), stroke: 4);
  c.restore();
}

/// Heart. Frame: origin = centre, 36 wide.
void s2Heart(Pen pen, Offset at, {double s = 1, double rot = 0}) => _tf(pen, at, rot, s, () {
  final h = svg('M0 12 C-22 -4 -17 -18 -8 -17 C-3 -16 0 -11 0 -11 C0 -11 3 -16 8 -17 C17 -18 22 -4 0 12 Z');
  pen.solid(h, const Tones(Color(0xFFFF4D6A), Color(0xFFC21E45), Color(0xFFFF9AAE)), shade: 3.4, hi: 1.2);
  pen.fill(circle(-8, -9, 2.2), const Color(0xFFFFFFFF));
});

/// Flame tongue. Frame: origin = base centre, 84 tall; [flip] mirrors it.
void s2Flame(Pen pen, Offset at, {double s = 1, bool flip = false, double rot = 0}) => _tf(pen, at, rot, s, () {
  if (flip) pen.c.scale(-1, 1);
  final outer = svg('M-20 2 C-36 -14 -28 -32 -14 -50 C-12 -40 -6 -36 -2 -42 C0 -58 10 -68 14 -86 C24 -64 42 -52 38 -24 C36 -10 40 -4 30 2 C16 10 -6 10 -20 2 Z');
  pen.solid(outer, s2Orange, shade: 5, hi: 1.6, dir: const Offset(-0.7, 0.6));
  final mid = svg('M-8 2 C-20 -10 -12 -24 -4 -36 C-2 -28 4 -24 6 -30 C8 -42 14 -46 16 -56 C22 -40 30 -32 26 -14 C24 -4 22 0 14 3 C6 6 -2 6 -8 2 Z');
  pen.fill(mid, s2Yellow.base);
  pen.fill(svg('M2 2 C-6 -4 -2 -14 3 -20 C6 -14 12 -12 12 -4 C12 2 6 5 2 2 Z'), const Color(0xFFFFF6CC));
});

/// Lightning bolt. Frame: origin = centre, 52 tall.
void s2Bolt(Pen pen, Offset at, {double s = 1, double rot = 0}) => _tf(pen, at, rot, s, () {
  pen.solid(svg('M8 -28 L-14 4 L-3 4 L-10 30 L16 -6 L4 -6 Z'), s2Yellow, shade: 3, hi: 1.2, w: Style.line * .95);
});

/// Firework burst: [rays] tapered rays in [color] with ink under-strokes.
void s2Burst(Pen pen, Offset at, double r, Color color, {int rays = 10, double rot = 0}) {
  for (var i = 0; i < rays; i++) {
    final a = rot + i * 2 * math.pi / rays;
    final rr = i.isEven ? r : r * .72;
    final d = Offset(math.cos(a), math.sin(a));
    final p0 = at + d * (r * .34), p1 = at + d * rr;
    final path = Path()..moveTo(p0.dx, p0.dy)..lineTo(p1.dx, p1.dy);
    pen.line(path, w: 6.2, color: Style.ink);
    pen.line(path, w: 3.2, color: color);
  }
  pen.fill(circle(at.dx, at.dy, r * .16), color);
  pen.line(circle(at.dx, at.dy, r * .16), w: 1.6, color: Style.ink);
}

/// Stack of three gold bars. Frame: origin = bottom centre, 70 wide, 34 tall.
void s2GoldBars(Pen pen, Offset at, {double s = 1, double rot = 0}) => _tf(pen, at, rot, s, () {
  void bar(double cx, double cy) {
    final b = svg('M${cx - 17} $cy L${cx + 17} $cy L${cx + 22} ${cy + 15} L${cx - 22} ${cy + 15} Z');
    pen.solid(b, s2Gold, shade: 3, hi: 1.0, w: Style.line * .9);
    pen.fill(svg('M${cx - 14} ${cy + 2} L${cx + 14} ${cy + 2} L${cx + 16} ${cy + 6.4} L${cx - 16} ${cy + 6.4} Z'), withA(s2Gold.hi, .85));
  }
  bar(-22, -15);
  bar(22, -15);
  bar(0, -31);
});

/// Falcon perched on a leather-gloved fist, facing left. Frame: origin = top of the glove (where the
/// claws grip); the bird is 56 wide / 52 tall above it, the gauntlet 46 tall below.
void s2Falcon(Pen pen, Offset at, {double s = 1, double rot = 0}) => _tf(pen, at, rot, s, () {
  const feather = Tones(Color(0xFF8A6542), Color(0xFF5B4029), Color(0xFFB48B5E));
  const cream = Tones(Color(0xFFF3E6CC), Color(0xFFCDB890), Color(0xFFFFF8EA));
  const leather = Tones(Color(0xFFA9703C), Color(0xFF6E4222), Color(0xFFD29A5E));
  // gauntlet cuff (flared) + fist
  final cuff = svg('M-16 18 L18 18 L26 52 L-24 52 Z');
  pen.solid(cuff, leather, shade: 5, hi: 1.4, w: Style.line * .9);
  pen.line(svg('M-19 34 C-6 38 8 38 21 34'), w: Style.lineThin, color: withA(Style.ink, .7));
  for (final x in const [-12.0, -4.0, 4.0, 12.0]) {
    pen.line(svg('M$x 38.6 L$x 41.4'), w: 1.4, color: withA(s2Gold.hi, .9));
  }
  final fist = svg('M-17 20 C-21 6 -14 -3 -3 -3 L10 -3 C21 -3 25 6 22 20 Z');
  pen.solid(fist, leather, shade: 4, hi: 1.4, w: Style.line * .9);
  for (final x in const [-9.0, -1.0, 7.0, 15.0]) {
    pen.line(svg('M$x 0 C${x + 1} 6 ${x + 1} 12 $x 17'), w: Style.lineFine, color: withA(Style.ink, .55));
  }
  // tail hanging behind the fist
  final tail = svg('M4 -4 C10 8 12 18 8 28 L-2 27 C-3 16 -1 6 -4 -4 Z');
  pen.solid(tail, feather, shade: 3, hi: 1);
  for (final x in const [0.0, 4.6]) {
    pen.line(svg('M$x 6 L${x + 1} 22'), w: Style.lineFine, color: withA(Style.ink, .6));
  }
  // body
  final body = svg('M-12 -38 C-24 -30 -24 -10 -12 -5 C0 -1 14 -5 16 -20 C18 -34 4 -46 -12 -38 Z');
  pen.solid(body, feather, shade: 5, hi: 1.6);
  final chest = svg('M-17 -32 C-23 -22 -20 -10 -12 -6 C-14 -17 -13 -25 -9 -33 Z');
  pen.fill(chest, cream.base);
  for (final p in const [Offset(-17, -24), Offset(-14, -18), Offset(-15, -12)]) {
    pen.line(svg('M${p.dx} ${p.dy} L${p.dx + 3.4} ${p.dy + 1.4}'), w: Style.lineFine, color: withA(feather.shade, .9));
  }
  final wing = svg('M-2 -38 C12 -36 20 -22 12 -8 C4 -12 -4 -22 -2 -38 Z');
  pen.solid(wing, Tones(feather.shade, shadeOf(feather.shade, .3), feather.base), shade: 2, hi: .8);
  final head = circle(-13, -43, 10.5);
  pen.solid(head, feather, shade: 3, hi: 1.2);
  pen.fill(svg('M-21 -41 C-22 -35 -17 -33 -12 -37 C-16 -37 -19 -39 -21 -41 Z'), cream.base);
  final beak = svg('M-21 -45 C-30 -45 -31 -37 -25 -32 C-26 -37 -23 -39 -19 -38 Z');
  pen.solid(beak, s2Yellow, shade: 1.2, hi: .6, w: Style.lineThin * 1.1);
  pen.shape(circle(-14.5, -45.4, 3.6), const Color(0xFFFFFFFF), w: Style.lineThin);
  pen.fill(circle(-15.2, -45.4, 1.9), const Color(0xFF1C1118));
  pen.line(svg('M-14 -41 C-13 -37 -11 -35 -9 -34'), w: 2.2, color: Style.ink);
  for (final x in const [-6.0, 2.0]) {
    pen.line(svg('M$x -5 L$x -1'), w: 3.2, color: Style.ink);
    pen.line(svg('M$x -5 L$x -1'), w: 1.6, color: s2Yellow.base);
  }
});

/// Whole ghost figure (a `custom` painter): a sheet with big eyes. Centre of the face ≈ (100, 100).
void s2Ghost(Pen pen) {
  final body = svg(
    'M40 156 C34 96 44 46 100 36 C156 46 166 96 160 156 L160 196 C152 184 146 182 138 196 C130 184 122 184 114 196 C106 182 98 182 88 196 C80 184 72 184 64 196 C56 184 48 184 40 196 Z',
  );
  const sheet = Tones(Color(0xFFFFFFFF), Color(0xFFCFCBE6), Color(0xFFFFFFFF));
  // arms raised ("boo")
  for (final g in const [-1.0, 1.0]) {
    final arm = svg('M${100 + g * 56} 120 C${100 + g * 74} 112 ${100 + g * 84} 98 ${100 + g * 80} 80 C${100 + g * 70} 86 ${100 + g * 64} 96 ${100 + g * 50} 104 Z');
    pen.solid(arm, sheet, shade: 4, hi: 1.2, dir: Offset(-g * .7, -.4));
  }
  pen.solid(body, sheet, shade: 9, hi: 2.4, dir: const Offset(-0.9, -0.3));
  pen.inside(body, (q) {
    q.taper(svg('M70 60 C62 90 62 130 66 170'), w0: 2.6, w1: .3, color: withA(sheet.shade, .9));
    q.taper(svg('M132 70 C140 100 140 136 134 176'), w0: 2.2, w1: .3, color: withA(sheet.shade, .9));
  });
  pen.line(body, w: Style.line, color: Style.ink);
  for (final g in const [-1.0, 1.0]) {
    final e = ellipse(100 + g * 22, 94, 11, 16);
    pen.fill(e, const Color(0xFF241A28));
    pen.fill(circle(100 + g * 22 - 3.4, 87, 3.8), const Color(0xFFFFFFFF));
    pen.fill(circle(100 + g * 22 + 3.6, 100, 1.9), withA(const Color(0xFFFFFFFF), .9));
    pen.glow(Offset(100 + g * 38, 118), 10, 6, const Color(0xFFFF8FA8), alpha: .5);
  }
  final mouth = ellipse(100, 128, 8.6, 12);
  pen.fill(mouth, const Color(0xFF241A28));
  pen.fill(ellipse(100, 134, 5, 4.4), const Color(0xFF8A3A55));
  pen.line(svg('M70 70 C74 62 82 58 90 58'), w: 2.4, color: withA(const Color(0xFFFFFFFF), .0));
  // dissolving puffs under the hem
  pen.fill(circle(56, 202, 5), withA(const Color(0xFFFFFFFF), .7));
  pen.fill(circle(146, 204, 4), withA(const Color(0xFFFFFFFF), .6));
}

/// Mind-reading waves: three arcs above [at]. Frame: global.
void s2MindWaves(Pen pen, Offset at) {
  for (var i = 0; i < 3; i++) {
    final r = 40.0 + i * 15;
    final a = withA(const Color(0xFFD7A6FF), 1 - i * .22);
    final arc = Path()..addArc(Rect.fromCircle(center: at, radius: r), math.pi * 1.16, math.pi * .68);
    pen.line(arc, w: 7.4 - i * 1.4, color: Style.ink);
    pen.line(arc, w: 4.2 - i * .9, color: a);
  }
}

/// A little "Z" for sleeping. Frame: origin = centre, 18 wide.
void s2Zed(Pen pen, Offset at, double s, {double rot = 0}) => _tf(pen, at, rot, s, () {
  final z = svg('M-8 -8 L8 -8 L-8 8 L8 8');
  pen.line(z, w: 8.4, color: Style.ink);
  pen.line(z, w: 4.4, color: const Color(0xFFB9DEFF));
});

/// Confetti bits scattered at [spots] (x, y, rotation, colour index).
void s2Confetti(Pen pen, List<List<double>> spots) {
  const cols = [Color(0xFFFF5D73), Color(0xFFFFD84D), Color(0xFF38D6A5), Color(0xFF4CC9F0), Color(0xFFB794F4)];
  for (final sp in spots) {
    _tf(pen, Offset(sp[0], sp[1]), sp[2], 1, () {
      final c = cols[sp[3].toInt() % cols.length];
      if (sp[3].toInt() % 3 == 2) {
        pen.shape(circle(0, 0, 3.2), c, w: 1.4);
      } else {
        pen.shape(Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4.6, -2.4, 9.2, 4.8), const Radius.circular(1.2))), c, w: 1.4);
      }
    });
  }
}

/// Short "impact" lines radiating from [at] (clapping, pop).
void s2Pop(Pen pen, Offset at, {double r0 = 14, double r1 = 24, int n = 5, double a0 = -2.2, double a1 = -0.94, Color color = const Color(0xFFFFE066)}) {
  for (var i = 0; i < n; i++) {
    final a = a0 + (a1 - a0) * i / (n - 1);
    final d = Offset(math.cos(a), math.sin(a));
    final p = Path()..moveTo(at.dx + d.dx * r0, at.dy + d.dy * r0)..lineTo(at.dx + d.dx * r1, at.dy + d.dy * r1);
    pen.line(p, w: 6.2, color: Style.ink);
    pen.line(p, w: 3.0, color: color);
  }
}

/// Golden necklace with a medallion. Frame: relative to a neck base [n] (global point), width ±24.
void s2Chain(Pen pen, Offset n, {double s = 1}) => _tf(pen, n, 0, s, () {
  final c = svg('M-23 -8 C-23 18 -12 34 0 40 C12 34 23 18 23 -8');
  pen.line(c, w: 5.6, color: Style.ink);
  pen.line(c, w: 3.0, color: s2Gold.base);
  pen.line(c, w: 1.0, color: s2Gold.hi);
  pen.solid(circle(0, 44, 7.4), s2Gold, shade: 2, hi: 1.0, w: Style.lineThin * 1.2);
  pen.solid(s2Star(0, 44, 4.4, inner: .5), s2Red, shade: .6, hi: .4, w: Style.lineFine);
});
