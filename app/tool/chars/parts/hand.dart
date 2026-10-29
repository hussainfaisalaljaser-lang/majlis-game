// Hands for props / poses. A hand is drawn in its own frame (units = 200-space
// units) and then placed with a head-relative anchor, rotation and scale.
import 'dart:math' as math;
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';

Path _tx(Path p, Offset at, double rot, double s, bool mirror) {
  final cs = math.cos(rot) * s, sn = math.sin(rot) * s;
  final mx = mirror ? -1.0 : 1.0;
  // x' = (mx*x)*cs - y*sn + at.x ; y' = (mx*x)*sn + y*cs + at.y
  return p.transform(affine(cs * mx, sn * mx, -sn, cs, at.dx, at.dy));
}

/// "Thinking" pose: a fist under the chin with the index finger along the cheek,
/// the forearm (in a sleeve) coming up from the bottom of the picture.
///
/// [at] is a HEAD-LOCAL position of the knuckles (front-view coordinates).
/// [mirror] = true puts the hand on the viewer's left side.
void drawChinHand(
  Pen pen,
  Head h,
  Skin skin, {
  Offset at = const Offset(14, 60),
  double rot = -0.12,
  double size = 1.0,
  bool mirror = false,
  Tones sleeve = Cloth.white,
  double z = 36,
}) {
  final anchor = h.pt(at.dx, at.dy, z: z);
  final s = h.scale * size;
  Path P(String d) => _tx(svg(d), anchor, rot, s, mirror);
  final lw = Style.line * 0.85 * s;
  final fine = Style.lineThin * 0.9 * s;

  // forearm + sleeve
  final arm = P('M10 14 C22 8 40 22 52 46 L84 130 L4 130 C2 86 -4 46 10 14 Z');
  pen.fill(arm, sleeve.base);
  pen.crescent(arm, sleeve.shade, depth: 6 * s, dir: const Offset(-0.9, -0.3));
  pen.inside(arm, (p) {
    p.line(P('M24 40 C30 66 36 92 38 124'), w: fine, color: withA(sleeve.shade, .95));
    p.line(P('M12 52 C14 78 14 100 12 126'), w: fine * .9, color: withA(sleeve.shade, .8));
  });
  pen.line(arm, w: lw, color: Style.ink);

  // thumb tucked under the chin
  final thumb = P('M-12 6 C-20 4 -27 9 -25 16 C-22 23 -13 22 -8 17 Z');
  pen.solid(thumb, skin.tones, shade: 2 * s, hi: 0.8 * s, w: lw * .9);

  // index finger lying along the cheek
  final index = P('M8 -8 C12 -18 20 -26 30 -31 C35 -33 38 -28 34 -24 C28 -18 25 -12 22 -6 Z');
  pen.solid(index, skin.tones, shade: 2.4 * s, hi: 0.8 * s, w: lw * .9);
  pen.line(P('M17 -19 C21 -22 25 -23 29 -25'), w: fine * .7, color: withA(skin.deep, .8));

  // fist
  final fist = P('M-14 -4 C-14 -13 -3 -16 7 -15 C17 -14 23 -6 23 3 C23 14 16 21 5 21 C-6 21 -14 13 -14 -4 Z');
  pen.solid(fist, skin.tones, shade: 4 * s, hi: 1.2 * s, w: lw);
  pen.inside(fist, (p) {
    // curled finger separations
    p.line(P('M-5 -14 C-3 -8 -3 -2 -5 3'), w: fine, color: withA(Style.ink, .85));
    p.line(P('M4 -15 C6 -9 6 -3 4 2'), w: fine, color: withA(Style.ink, .85));
    p.line(P('M13 -12 C15 -7 15 -2 13 3'), w: fine, color: withA(Style.ink, .85));
    // knuckle highlight
    p.line(P('M-9 -10 C-6 -13 0 -14 4 -13'), w: fine * .8, color: withA(skin.hi, .9));
  });
  pen.line(P('M-6 10 C-2 14 6 15 12 11'), w: fine * .8, color: withA(Style.ink, .6));
  // cuff
  final cuff = P('M6 18 C14 24 26 22 32 12 L46 40 C38 52 24 56 10 46 Z');
  pen.solid(cuff, sleeve, shade: 3 * s, hi: 1 * s, w: lw * .9);
}
