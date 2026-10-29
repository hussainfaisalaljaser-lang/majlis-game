// Worker C: astronaut. The suit and the back of the glass dome are the `body` layer, the face
// inside is the `head` layer (it sways a little inside the helmet) and the front rim + glass
// reflections are the `visor` layer (drawn on top, so the head never pokes out of the helmet).
// Everything uses fixed global coordinates: helmet centre (100, 98), glass radius 60, rim to 70.
import 'dart:math' as math;
import 'dart:ui';

import '../kit.dart';

const Offset helmetC = Offset(100, 98);
const double glassR = 60;
const double rimR = 70;

const suitT = Tones(Color(0xFFF1F2F7), Color(0xFFB4B9CE), Color(0xFFFFFFFF));
const rimT = Tones(Color(0xFFE4E7EF), Color(0xFF959BB4), Color(0xFFFFFFFF));

Path _ring() => Path.combine(PathOperation.difference, circle(helmetC.dx, helmetC.dy, rimR), circle(helmetC.dx, helmetC.dy, glassR));

/// Suit shoulders + chest panel + patches, then the back of the glass dome (tinted sky blue).
void drawAstronautBody(Pen pen) {
  // shoulders
  final suit = svg('M10 214 C14 190 30 172 58 164 L142 164 C170 172 186 190 190 214 Z');
  pen.solid(suit, suitT, shade: 8, hi: 2.4, dir: const Offset(-0.9, -0.35));
  pen.inside(suit, (p) {
    // orange shoulder stripes
    for (final s in const [-1, 1]) {
      p.taper(svg('M${100 + s * 56} 170 C${100 + s * 68} 178 ${100 + s * 76} 190 ${100 + s * 80} 208'), w0: 5, w1: 1.2, color: const Color(0xFFF2762E));
      p.line(svg('M${100 + s * 40} 176 C${100 + s * 48} 188 ${100 + s * 52} 200 ${100 + s * 54} 214'), w: Style.lineThin, color: withA(suitT.shade, .95));
    }
  });
  pen.line(suit, w: Style.line);
  // chest control box
  final box = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(84, 181, 32, 20), const Radius.circular(3.5)));
  pen.solid(box, const Tones(Color(0xFF8F96AE), Color(0xFF5E647D), Color(0xFFC2C8DC)), shade: 2.4, hi: 1, w: Style.lineThin * 1.2);
  pen.fill(circle(92, 190, 2.6), const Color(0xFFE23B4C));
  pen.line(circle(92, 190, 2.6), w: Style.lineFine, color: Style.ink);
  pen.fill(circle(100, 190, 2.6), const Color(0xFF3DD68C));
  pen.line(circle(100, 190, 2.6), w: Style.lineFine, color: Style.ink);
  pen.fill(circle(108, 190, 2.6), const Color(0xFF58A6FF));
  pen.line(circle(108, 190, 2.6), w: Style.lineFine, color: Style.ink);
  pen.line(svg('M88 196 L112 196'), w: 1.4, color: withA(Style.ink, .6));
  // neck seal ring
  final seal = ellipse(100, 164, 54, 13);
  pen.solid(seal, const Tones(Color(0xFFB9BED2), Color(0xFF7F86A0), Color(0xFFE9ECF5)), shade: 3, hi: 1.2, w: Style.line * .95);
  // back of the glass dome
  final dome = circle(helmetC.dx, helmetC.dy, glassR);
  pen.fillShader(
    dome,
    Gradient.radial(Offset(helmetC.dx - 8, helmetC.dy - 14), glassR * 1.15, const [Color(0xFFD7EEFA), Color(0xFFA3C8E0), Color(0xFF6E98B8)], const [0, .6, 1]),
  );
  pen.inside(dome, (p) => p.crescent(dome, withA(const Color(0xFF446C8E), .55), depth: 9, dir: const Offset(-0.6, -0.7)));
}

/// Neck + face + short hair of the astronaut (everything inside the helmet).
void drawAstronautHead(Pen pen, CharSpec s, Head h) {
  drawNeck(pen, h, s.skin, width: s.neckWidth, bottom: 84);
  final e = s.resolvedExpr;
  drawEars(pen, h, s.skin, s.ears, front: false);
  drawFaceSkin(pen, h, s.skin, blush: s.blush);
  drawEars(pen, h, s.skin, s.ears, front: true);
  // short hair cap + sideburns
  final sc = h.scale;
  final hc = s.hair!.color;
  final cap = h.path(svg('M-45 -20 C-52 -62 -26 -84 0 -84 C26 -84 52 -62 45 -20 C40 -34 30 -42 0 -40 C-30 -42 -40 -34 -45 -20 Z'), lift: 3);
  pen.fill(cap, hc.base);
  pen.crescent(cap, hc.shade, depth: 5 * sc);
  pen.rim(cap, hc.hi, depth: 2 * sc);
  pen.line(cap, w: Style.line * sc, color: Style.ink);
  drawEyes(pen, h, e.eyes, s.skin);
  drawBrows(pen, h, e.brows, e.eyes);
  drawNose(pen, h, s.nose, s.skin);
  drawMouth(pen, h, e.mouth, s.skin);
}

/// The glass front: tint, bright reflections and the helmet rim with its clips.
void drawAstronautVisor(Pen pen) {
  final glass = circle(helmetC.dx, helmetC.dy, glassR);
  pen.fill(glass, withA(const Color(0xFFBFE4FF), .10));
  pen.inside(glass, (p) {
    // big curved reflection on the upper left
    p.taper(svg('M52 92 C52 66 70 46 96 42'), w0: 7.5, w1: .8, color: withA(const Color(0xFFFFFFFF), .85));
    p.taper(svg('M62 100 C62 86 68 76 76 70'), w0: 3.2, w1: .6, color: withA(const Color(0xFFFFFFFF), .7));
    // soft reflection low right
    p.taper(svg('M150 118 C146 134 134 148 118 154'), w0: 4.5, w1: .6, color: withA(const Color(0xFFFFFFFF), .5));
    p.glow(const Offset(76, 62), 22, 14, const Color(0xFFFFFFFF), alpha: .28);
  });
  final ring = _ring();
  pen.fill(ring, rimT.base);
  pen.crescent(ring, rimT.shade, depth: 5, dir: const Offset(-0.8, -0.6));
  pen.rim(ring, rimT.hi, depth: 2, dir: const Offset(-0.8, -0.6));
  pen.line(circle(helmetC.dx, helmetC.dy, rimR), w: Style.line * 1.05, color: Style.ink);
  pen.line(circle(helmetC.dx, helmetC.dy, glassR), w: Style.line * .9, color: Style.ink);
  // little clips and a lamp on the rim
  for (final s in const [-1, 1]) {
    final a = (s < 0 ? 205 : -25) * math.pi / 180;
    final c = Offset(helmetC.dx + (rimR - 5) * math.cos(a), helmetC.dy + (rimR - 5) * math.sin(a));
    pen.fill(circle(c.dx, c.dy, 2.1), const Color(0xFF8F96AE));
    pen.line(circle(c.dx, c.dy, 2.1), w: Style.lineFine, color: Style.ink);
  }
  final lamp = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(134, 36, 12, 8), const Radius.circular(2.4)));
  pen.solid(lamp, const Tones(Color(0xFFFFE08A), Color(0xFFD9A93E), Color(0xFFFFF6CC)), shade: 1.2, hi: .6, w: Style.lineThin);
}
