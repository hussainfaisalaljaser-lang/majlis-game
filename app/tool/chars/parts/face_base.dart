// Face base: neck, ears, skin fill with cel shading, cheek blush.
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';

class EarSpec {
  const EarSpec({this.size = 1.0, this.flare = 6.5, this.y = 5.0, this.show = true});

  /// Size multiplier, how far the ear sticks out sideways, vertical centre.
  final double size, flare, y;
  final bool show;
}

/// Neck from under the jaw to the collar, with the shadow the chin casts on it.
void drawNeck(Pen pen, Head h, Skin skin, {double width = 20, double bottom = 100}) {
  final yb = bottom;
  final path = h.path(
    svg('M${-width} 30 C${-width - 1} 55 ${-width - 2} 80 ${-width - 6} $yb L${width + 6} $yb C${width + 2} 80 ${width + 1} 55 $width 30 Z'),
    z: 6,
  );
  pen.fill(path, skin.base);
  // shadow under the chin
  final outline = h.outline();
  pen.inside(path, (p) {
    p.fill(outline.shift(Offset(-0.5 * h.scale, 11 * h.scale)), skin.shade);
    p.fill(outline.shift(Offset(-0.5 * h.scale, 11 * h.scale)).shift(Offset(0, 4 * h.scale)), withA(skin.deep, .35));
  });
  // right side shade
  pen.crescent(path, withA(skin.shade, .7), depth: 5 * h.scale, dir: Style.light);
  pen.line(path, w: Style.line * h.scale, color: Style.ink);
}

Path _earShape(Head h, int s, EarSpec e, {bool inner = false}) {
  // profile of the ear: u = 0 attach .. 1 back; y vertical
  final k = e.size * (inner ? 0.55 : 1.0);
  final y0 = e.y;
  final pts = <List<double>>[
    [0.00, -9], [0.35, -11.5], [0.85, -8], [1.0, -1], [0.92, 7], [0.62, 14.5], [0.28, 16.5], [0.0, 12.5],
  ];
  final out = <Offset>[];
  for (final p in pts) {
    final u = p[0] * (inner ? 0.62 : 1.0) + (inner ? 0.12 : 0);
    final y = y0 + (p[1] * k + (inner ? 1.0 : 0));
    final w = h.shape.wAt(y);
    final x = s * (w + 0.5 + e.flare * u);
    final z = 3.0 - 22.0 * u * e.size;
    out.add(h.pt(x, y, z: z));
  }
  return spline(out, closed: true, tension: 0.9);
}

/// Ears. [front] true = draw the ears that face the viewer (on top of the face),
/// false = the ears hidden behind the head (drawn before the face).
void drawEars(Pen pen, Head h, Skin skin, EarSpec e, {required bool front}) {
  if (!e.show) return;
  for (final s in const [-1, 1]) {
    final yc = e.y;
    final visibleDepth = h.depthOf(s * (h.shape.wAt(yc) + 2), yc, z: -4);
    final isFront = visibleDepth > 4 && h.absYaw > 0.12;
    if (isFront != front) continue;
    final ear = _earShape(h, s, e);
    pen.fill(ear, skin.base);
    pen.crescent(ear, skin.shade, depth: 2.2 * h.scale);
    pen.line(ear, w: Style.lineThin * 1.25 * h.scale, color: Style.ink);
    final inner = _earShape(h, s, e, inner: true);
    pen.fill(inner, withA(skin.deep, .55));
    pen.line(inner, w: Style.lineFine * h.scale, color: withA(Style.ink, .6));
  }
}

/// Face skin with shading: shadow side, light rim, soft blush.
void drawFaceSkin(Pen pen, Head h, Skin skin, {double blush = 1.0, bool outline = true}) {
  final out = h.outline();
  pen.fill(out, skin.base);
  // shadow side (away from the light, upper-left) + a soft darker jaw shadow
  pen.crescent(out, skin.shade, depth: 7.5 * h.scale, dir: const Offset(-0.95, -0.35));
  pen.rim(out, skin.hi, depth: 2.4 * h.scale, dir: const Offset(-0.85, -0.5));
  if (blush > 0) {
    for (final s in const [-1, 1]) {
      final c = h.pt(s * 29.0, 24);
      pen.inside(out, (p) => p.glow(c, 8 * h.scale, 5.5 * h.scale, skin.blush, alpha: .28 * blush));
    }
  }
  if (outline) pen.line(out, w: Style.line * h.scale, color: Style.ink);
}
