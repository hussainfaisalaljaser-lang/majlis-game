// Bodies: shoulders + clothes, anchored on the head's neck base. Coordinates in
// the SVG strings are RELATIVE to the neck base N (0,0), +y down, units = 200-space
// units at head scale 1. The circle crops most of the body, so shoulders only
// need to be right down to ~y+110.
import 'dart:ui';


import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';

/// Base class: [draw] paints the body (before the neck), [drawFront] paints the
/// collar/neckline overlay (after the neck, so the collar overlaps the neck).
abstract class Body {
  const Body();

  void draw(Pen pen, Head h, Skin skin);

  void drawFront(Pen pen, Head h, Skin skin) {}

  /// Sideways shift of the garment centre line when the head is turned.
  static double turn(Head h) => h.yaw * 6.0 * h.scale;
}

/// Helper available to all bodies: neck-relative SVG -> global path.
Path rel(Head h, String d, {double dx = 0}) {
  final n = h.neckBase;
  return xform(svg(d), sx: h.scale, tx: n.dx + dx, ty: n.dy);
}

Path relPath(Head h, Path p, {double dx = 0}) {
  final n = h.neckBase;
  return xform(p, sx: h.scale, tx: n.dx + dx, ty: n.dy);
}

/// Shoulder silhouette shared by most garments (relative to the neck base).
const String shoulderPath = 'M-24 -10 C-36 -4 -60 2 -78 14 C-95 26 -103 56 -106 120 L106 120 C103 56 95 26 78 14 C60 2 36 -4 24 -10 Z';

/// Plain shoulders in one colour with a few fold lines, no collar: a simple
/// base for sweaters, jackets, abayas... Extend or replace with custom paths.
class Garment extends Body {
  const Garment({
    this.color = Cloth.charcoal,
    this.path = shoulderPath,
    this.folds = true,
    this.neckline,
    this.necklineColor,
  });

  final Tones color;
  final String path;
  final bool folds;

  /// Optional extra path (relative) drawn over the top (neckline trim).
  final String? neckline;
  final Tones? necklineColor;

  @override
  void draw(Pen pen, Head h, Skin skin) {
    final dx = Body.turn(h);
    final p = rel(h, path, dx: dx);
    pen.solid(p, color, shade: 7 * h.scale, hi: 2.2 * h.scale, dir: const Offset(-0.95, -0.35));
    if (folds) {
      pen.inside(p, (q) {
        q.line(rel(h, 'M-52 24 C-44 48 -40 78 -44 110', dx: dx), w: Style.lineThin * h.scale, color: withA(color.shade, .9));
        q.line(rel(h, 'M52 22 C46 50 48 80 44 110', dx: dx), w: Style.lineThin * h.scale, color: withA(color.shade, .9));
      });
    }
    pen.line(p, w: Style.line * h.scale);
    if (neckline != null) {
      final t = necklineColor ?? Cloth.sand;
      pen.solid(rel(h, neckline!, dx: dx), t, shade: 1.6 * h.scale, hi: 0.8 * h.scale, w: Style.lineThin * 1.1 * h.scale);
    }
  }
}

/// Gulf thobe: plain shoulders with a band (mandarin) collar and a button placket.
class Thobe extends Body {
  const Thobe({this.color = Cloth.white, this.buttons = true, this.collarHi});

  final Tones color;
  final bool buttons;
  final Tones? collarHi;

  @override
  void draw(Pen pen, Head h, Skin skin) {
    final dx = Body.turn(h);
    final p = rel(h, shoulderPath, dx: dx);
    pen.solid(p, color, shade: 8 * h.scale, hi: 2.4 * h.scale, dir: const Offset(-0.95, -0.35));
    pen.inside(p, (q) {
      // chest folds
      q.line(rel(h, 'M-48 22 C-40 46 -36 74 -40 110', dx: dx), w: Style.lineThin * h.scale, color: withA(color.shade, .95));
      q.line(rel(h, 'M50 20 C42 50 46 80 42 112', dx: dx), w: Style.lineThin * h.scale, color: withA(color.shade, .95));
      q.line(rel(h, 'M-70 40 C-62 56 -62 76 -66 96', dx: dx), w: Style.lineFine * h.scale, color: withA(color.shade, .8));
    });
    pen.line(p, w: Style.line * h.scale);
  }

  @override
  void drawFront(Pen pen, Head h, Skin skin) {
    final dx = Body.turn(h);
    // band collar: a slanted ring around the neck
    final collar = rel(h, 'M-23 -17 C-24 -9 -23 -1 -21 5 C-10 12 10 12 21 5 C23 -1 24 -9 23 -17 C12 -11 -12 -11 -23 -17 Z', dx: dx);
    pen.solid(collar, color, shade: 3 * h.scale, hi: 1.2 * h.scale, w: Style.lineThin * 1.3 * h.scale);
    // placket + buttons
    pen.line(rel(h, 'M0 9 L0 52', dx: dx), w: Style.lineThin * h.scale, color: withA(Style.ink, .85));
    pen.line(rel(h, 'M-3.6 9 L-3.6 48 M3.6 9 L3.6 48', dx: dx), w: Style.lineFine * h.scale, color: withA(color.shade, .9));
    if (buttons) {
      for (final y in const [20.0, 34.0]) {
        final b = h.neckBase;
        pen.fill(circle(b.dx + dx, b.dy + y * h.scale, 1.6 * h.scale), color.shade);
      }
    }
  }
}
