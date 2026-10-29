// Shared helpers of the d2 animal busts (caracal, gazelle, horse, oryx): symmetric shapes,
// fur strokes, a Skin built from a fur palette, an eye frame, and the 3-layer cutout scaffolding.
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';

/// A full symmetric shape from its RIGHT half, authored from the top centre to the bottom centre
/// (the path may end anywhere on the centre line; it is closed automatically).
Path d2Sym(String half) {
  final p = svg(half);
  return Path.combine(PathOperation.union, p, mirrorX(p));
}

/// Mirror a path about the avatar centre line.
Path d2Mir(Path p) => mirrorX(p);

/// Identity head used only to place the kit's eyes/brows (origin = eye-line centre).
Head d2EyeHead(double x, double y, {double scale = 1}) => Head(pos: Offset(x, y), scale: scale);

/// A [Skin] made of a fur palette (for the kit's eyelid blink + eye shading helpers).
Skin d2Skin(Tones t) => Skin(base: t.base, shade: t.shade, hi: t.hi, blush: t.base, lip: t.shade, deep: t.shade);

/// Tapered strand lines (fur) clipped inside [clip].
void d2Strands(Pen pen, Path clip, List<String> strands, Color color, {double w0 = 2.0, double w1 = 0.2}) {
  pen.inside(clip, (q) {
    for (final s in strands) {
      q.taper(svg(s), w0: w0, w1: w1, color: color);
    }
  });
}

/// Rotate everything drawn by [draw] about [pivot].
void d2Tilt(Pen pen, double rad, Offset pivot, void Function() draw) {
  if (rad == 0) {
    draw();
    return;
  }
  pen.c.save();
  pen.c.translate(pivot.dx, pivot.dy);
  pen.c.rotate(rad);
  pen.c.translate(-pivot.dx, -pivot.dy);
  draw();
  pen.c.restore();
}

/// Clip to the avatar circle (the still composite crops the shoulders like the old art did).
void d2Circle(Pen pen, void Function() draw) {
  pen.c.save();
  pen.c.clipPath(circle(100, 100, 100));
  draw();
  pen.c.restore();
}

/// Crescent moon (opening towards [open]: +1 right, -1 left) centred at [c] with outer radius [r].
Path d2Crescent(Offset c, double r, {int open = 1, double thick = 0.42}) {
  final outer = circle(c.dx, c.dy, r);
  final inner = circle(c.dx + open * r * thick * 1.15, c.dy - r * 0.1, r * 0.82);
  return Path.combine(PathOperation.difference, outer, inner);
}

/// A 4-point star glint path.
Path d2Star(Offset c, double r) {
  final p = Path();
  const k = 0.26;
  p.moveTo(c.dx, c.dy - r);
  p.quadraticBezierTo(c.dx + r * k, c.dy - r * k, c.dx + r, c.dy);
  p.quadraticBezierTo(c.dx + r * k, c.dy + r * k, c.dx, c.dy + r);
  p.quadraticBezierTo(c.dx - r * k, c.dy + r * k, c.dx - r, c.dy);
  p.quadraticBezierTo(c.dx - r * k, c.dy - r * k, c.dx, c.dy - r);
  p.close();
  return p;
}

/// Ridge rings across a horn: short bowed lines crossing [horn] along its [center] line
/// ([n] rings between [t0] and [t1] of the length), clipped inside the horn.
void d2HornRings(Pen pen, Path horn, Path center, {int n = 8, double t0 = 0.1, double t1 = 0.93, double w = 1.7, Color color = Style.ink, double bow = 1.6, double reach = 20}) {
  final ms = center.computeMetrics().toList();
  if (ms.isEmpty) return;
  final m = ms.first;
  pen.inside(horn, (q) {
    for (var i = 0; i < n; i++) {
      final t = t0 + (t1 - t0) * i / (n - 1);
      final tan = m.getTangentForOffset(m.length * t);
      if (tan == null) continue;
      final v = tan.vector;
      final nrm = Offset(-v.dy, v.dx);
      final a = tan.position - nrm * reach, b = tan.position + nrm * reach;
      final ctrl = tan.position + v * bow;
      final r = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      q.line(r, w: w, color: color);
    }
  });
}
