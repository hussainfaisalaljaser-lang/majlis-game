// Eyes: big expressive cartoon eyes (white sclera, coloured iris, black pupil,
// two highlights, thick upper lid line). One [EyeSpec] describes both eyes; per
// eye overrides are possible through [EyeSpec.left] / [EyeSpec.right].
import 'dart:math' as math;
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';

class EyeSpec {
  const EyeSpec({
    this.ew = 11.0,
    this.eh = 9.5,
    this.gap = 20.0,
    this.y = 0.0,
    this.lookX = 0.0,
    this.lookY = 0.0,
    this.iris = const Color(0xFF6A4326),
    this.irisR = 0.54,
    this.pupilR = 0.56,
    this.lidTop = 0.0,
    this.lidSlant = 0.0,
    this.lidCurve = 0.25,
    this.lidBottom = 0.0,
    this.lashes = false,
    this.crease = false,
    this.sclera = const Color(0xFFFFFFFF),
    this.lid = 3.0,
    this.left,
    this.right,
    this.open = 1.0,
  });

  /// Half width / half height of one eye (local units).
  final double ew, eh;

  /// Distance of each eye centre from the centre line, and the eye-line y.
  final double gap, y;

  /// Where the iris looks, -1..1 (x: viewer's left..right, y: up..down).
  final double lookX, lookY;
  final Color iris;

  /// Iris radius as a fraction of the eye height; pupil as a fraction of the iris.
  final double irisR, pupilR;

  /// Upper lid coverage 0..1 (0 = fully open, .5 = half closed).
  final double lidTop;

  /// Lid tilt: + = inner corner lower (angry), - = outer corner lower (worried/sad).
  final double lidSlant;
  final double lidCurve;

  /// Lower lid raised 0..1 (smug / happy squint).
  final double lidBottom;
  final bool lashes;

  /// Thin fold line above the eye (older / tired / smug).
  final bool crease;
  final Color sclera;

  /// Thickness of the upper lid line.
  final double lid;

  /// Optional overrides for the viewer's left / right eye only.
  final EyeSpec? left, right;

  /// 0..1: eye openness for blinking (1 = open; 0 = closed line).
  final double open;

  EyeSpec copyWith({
    double? ew,
    double? eh,
    double? gap,
    double? y,
    double? lookX,
    double? lookY,
    Color? iris,
    double? irisR,
    double? pupilR,
    double? lidTop,
    double? lidSlant,
    double? lidCurve,
    double? lidBottom,
    bool? lashes,
    bool? crease,
    Color? sclera,
    double? lid,
    EyeSpec? left,
    EyeSpec? right,
    double? open,
  }) => EyeSpec(
    ew: ew ?? this.ew,
    eh: eh ?? this.eh,
    gap: gap ?? this.gap,
    y: y ?? this.y,
    lookX: lookX ?? this.lookX,
    lookY: lookY ?? this.lookY,
    iris: iris ?? this.iris,
    irisR: irisR ?? this.irisR,
    pupilR: pupilR ?? this.pupilR,
    lidTop: lidTop ?? this.lidTop,
    lidSlant: lidSlant ?? this.lidSlant,
    lidCurve: lidCurve ?? this.lidCurve,
    lidBottom: lidBottom ?? this.lidBottom,
    lashes: lashes ?? this.lashes,
    crease: crease ?? this.crease,
    sclera: sclera ?? this.sclera,
    lid: lid ?? this.lid,
    left: left ?? this.left,
    right: right ?? this.right,
    open: open ?? this.open,
  );

  EyeSpec _for(int side) => (side < 0 ? left : right) ?? this;
}

/// Unit eye contour: u = -1 inner corner .. +1 outer corner, v = -1 top .. +1 bottom.
final Path _unitEye = svg(
  'M-1 0.12 C-1 -0.6 -0.55 -1 0.05 -1 C0.65 -1 1 -0.5 1 0.02 C1 0.62 0.55 1 -0.02 1 C-0.6 1 -1 0.66 -1 0.12 Z',
);

Path _toLocal(Path unit, double cx, double cy, double sx, double sy) {
  return xform(unit, sx: sx, sy: sy, tx: cx, ty: cy);
}

/// Everything needed to draw (or blink-cover) one eye.
class _EyeGeom {
  _EyeGeom(this.h, this.s, this.side, this.skin);

  final Head h;
  final EyeSpec s;
  final int side; // -1 viewer-left eye, +1 viewer-right eye
  final Skin skin;

  double get cx => side * s.gap;
  double get cy => s.y;
  static const _lift = 1.2;

  /// Full eye contour (no lid), local coordinates.
  Path get contourLocal => _toLocal(_unitEye, cx, cy, side * s.ew, s.eh);

  Path get contour => h.path(contourLocal, lift: _lift);

  /// Lid line v at u (unit coordinates).
  double lidV(double u) {
    final v0 = -1 + 2 * s.lidTop * s.open.clamp(0.0, 1.0) + (1 - s.open) * 0.0;
    return v0 + s.lidSlant * u * -1 * 0.9;
  }

  /// Region of the eye that is NOT covered by the upper lid (local), as a path.
  Path get visibleLocal {
    final lid = _lidCoverLocal();
    final low = _lowerCoverLocal();
    var p = contourLocal;
    p = Path.combine(PathOperation.difference, p, lid);
    if (low != null) p = Path.combine(PathOperation.difference, p, low);
    return p;
  }

  Path _lidCoverLocal() {
    // polygon above the lid curve, in unit coordinates, then to local
    final u0 = -1.3, u1 = 1.3;
    final vTop = -2.2;
    final curve = s.lidCurve;
    final p = Path()
      ..moveTo(u0, vTop)
      ..lineTo(u0, lidV(u0))
      ..quadraticBezierTo(0, (lidV(u0) + lidV(u1)) / 2 + curve * 2, u1, lidV(u1))
      ..lineTo(u1, vTop)
      ..close();
    return _toLocal(p, cx, cy, side * s.ew, s.eh);
  }

  Path? _lowerCoverLocal() {
    if (s.lidBottom <= 0) return null;
    final vb = 1 - 2 * s.lidBottom * 0.7;
    final p = Path()
      ..moveTo(-1.3, 2.2)
      ..lineTo(-1.3, vb + .1)
      ..quadraticBezierTo(0, vb - 0.55, 1.3, vb + .2)
      ..lineTo(1.3, 2.2)
      ..close();
    return _toLocal(p, cx, cy, side * s.ew, s.eh);
  }

  /// The upper lid line as a polyline (local), used for the thick lid stroke.
  Path lidLineLocal() {
    final u0 = -1.18, u1 = 1.18;
    final open = s.open.clamp(0.0, 1.0);
    if (s.lidTop <= 0.001 && open >= .999) {
      // follow the contour's top arc
      final p = Path()
        ..moveTo(-1, 0.12)
        ..cubicTo(-1, -0.6, -0.55, -1, 0.05, -1)
        ..cubicTo(0.65, -1, 1, -0.5, 1.12, 0.0);
      return _toLocal(p, cx, cy, side * s.ew, s.eh);
    }
    final p = Path()
      ..moveTo(u0, lidV(u0))
      ..quadraticBezierTo(0, (lidV(u0) + lidV(u1)) / 2 + s.lidCurve * 2, u1, lidV(u1));
    return _toLocal(p, cx, cy, side * s.ew, s.eh);
  }
}

void drawEyes(Pen pen, Head h, EyeSpec spec, Skin skin, {Color? lidInk}) {
  for (final side in const [-1, 1]) {
    final s = spec._for(side);
    _drawEye(pen, _EyeGeom(h, s, side, skin), lidInk ?? Style.ink);
  }
}

void _drawEye(Pen pen, _EyeGeom g, Color ink) {
  final s = g.s;
  final h = g.h;
  final vis = h.path(g.visibleLocal, lift: _EyeGeom._lift);
  if (vis.getBounds().isEmpty) return;
  final scale = h.scale;

  // sclera
  pen.fill(vis, s.sclera);
  pen.crescent(vis, const Color(0xFFD9D4E4), depth: 2.2 * scale, dir: const Offset(0, 1));
  pen.crescent(vis, const Color(0xFFEDE9F2), depth: 1.5 * scale, dir: const Offset(0, -1));

  // iris + pupil, clipped to the visible eye
  final lookX = clampD(s.lookX, -1, 1), lookY = clampD(s.lookY, -1, 1);
  final ir = s.irisR * s.eh;
  final maxX = s.ew - ir * 0.62; // keep iris inside the sclera horizontally
  final icx = g.cx + g.side * 0 + lookX * math.max(0.0, maxX) * 0.95;
  final icy = g.cy + lookY * (s.eh - ir) * 0.55 + 0.4;
  final irisLocal = circle(icx, icy, ir);
  final iris = h.path(irisLocal, lift: _EyeGeom._lift + 0.3);
  pen.inside(vis, (p) {
    p.fill(iris, s.iris);
    // top shadow (lid) and bottom light
    p.crescent(iris, shadeOf(s.iris, .42), depth: ir * 0.55 * scale, dir: const Offset(0, 1));
    p.rim(iris, lightOf(s.iris, .35), depth: ir * 0.35 * scale, dir: const Offset(0, -1));
    p.line(iris, w: 0.9 * scale, color: shadeOf(s.iris, .55));
    final pr = ir * s.pupilR;
    final pupil = h.path(circle(icx + lookX * 0.4, icy + lookY * 0.3, pr), lift: _EyeGeom._lift + 0.5);
    p.fill(pupil, const Color(0xFF16101A));
    // highlights
    final hl1 = h.path(circle(icx - ir * 0.32, icy - ir * 0.34, ir * 0.30), lift: _EyeGeom._lift + 1);
    p.fill(hl1, const Color(0xFFFFFFFF));
    final hl2 = h.path(circle(icx + ir * 0.30, icy + ir * 0.36, ir * 0.13), lift: _EyeGeom._lift + 1);
    p.fill(hl2, withA(const Color(0xFFFFFFFF), .85));
  });

  // contour outline: thin all round, thick on the upper lid
  final contour = h.path(g.visibleLocal, lift: _EyeGeom._lift);
  pen.line(contour, w: Style.lineFine * 1.15 * scale, color: ink);
  final lidLine = h.path(g.lidLineLocal(), lift: _EyeGeom._lift);
  final contourGrown = h.path(g.contourLocal, lift: _EyeGeom._lift);
  pen.inside(_grow(contourGrown, 1.6 * scale), (p) {
    p.line(lidLine, w: s.lid * scale, color: ink);
  });

  // lashes
  if (s.lashes) {
    final o = g.side;
    final top = g.cy - s.eh * 0.2 + s.eh * (g.lidV(1.0) + 1) * 0.0;
    for (var i = 0; i < 3; i++) {
      final a = (-0.25 + i * 0.32);
      final p0 = Offset(g.cx + o * s.ew * (0.78 + i * 0.12), top + s.eh * (0.0 + i * 0.1) - s.eh * 0.6 * (1 - s.lidTop * 0.2));
      final p1 = Offset(p0.dx + o * (3.0 + i * 0.4), p0.dy - 3.4 + a * 2);
      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..lineTo(p1.dx, p1.dy);
      pen.line(h.path(path, lift: _EyeGeom._lift + 0.4), w: 1.7 * scale, color: ink);
    }
  }

  // crease above the lid
  if (s.crease) {
    final c = Path()
      ..moveTo(g.cx - g.side * s.ew * 0.9, g.cy - s.eh * 1.35)
      ..quadraticBezierTo(g.cx, g.cy - s.eh * 1.85, g.cx + g.side * s.ew * 1.05, g.cy - s.eh * 1.25);
    pen.line(h.path(c, lift: 1), w: Style.lineFine * scale, color: withA(ink, .55));
  }
}

/// Inflate a path slightly by drawing a stroke of itself (used as a clip region).
Path _grow(Path p, double by) {
  // approximate by scaling about its centre
  final b = p.getBounds();
  if (b.isEmpty) return p;
  final sx = (b.width + by * 2) / b.width, sy = (b.height + by * 2) / b.height;
  return scaledAbout(p, b.center, sx, sy);
}

/// Eyelids closed over the eyes (for blink layers): skin coloured lid + curved lash line.
void drawEyelids(Pen pen, Head h, EyeSpec spec, Skin skin, {Color? ink}) {
  for (final side in const [-1, 1]) {
    final s = spec._for(side);
    final g = _EyeGeom(h, s, side, skin);
    final lidShape = h.path(g.contourLocal, lift: _EyeGeom._lift + 0.2);
    final grown = _grow(lidShape, 1.2 * h.scale);
    pen.fill(grown, skin.base);
    // closed lid curve (smile-shaped) with lashes flicks
    final c = Path()
      ..moveTo(g.cx - side * s.ew * 0.95, g.cy + s.eh * 0.05)
      ..quadraticBezierTo(g.cx, g.cy + s.eh * 0.75, g.cx + side * s.ew * 1.05, g.cy + s.eh * 0.0);
    pen.line(h.path(c, lift: _EyeGeom._lift + .3), w: s.lid * 0.9 * h.scale, color: ink ?? Style.ink);
  }
}
