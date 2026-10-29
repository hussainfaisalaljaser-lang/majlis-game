// The "head model": a tiny 3D ellipsoid head that every face part is projected
// through, so ONE front-view authored drawing works for frontal and 3/4 turned
// heads (yaw), looking up/down (pitch) and head tilt (roll).
//
// Local head coordinates (front view, units = 200-space units at scale 1):
//   origin (0,0) = between the eyes, on the eye line
//   +x = viewer's right, +y = down
//   brows ~ -14, hairline ~ -36, skull top ~ -70, nose tip ~ +22,
//   mouth ~ +40, chin ~ +68, ears ~ -4..+26, neck base ~ +90.
import 'dart:math' as math;
import 'dart:ui';


import 'pen.dart';

/// Half-width [w] and depth [d] (distance of the face surface from the vertical
/// rotation axis) of the head ellipsoid, sampled at [ys].
class FaceShape {
  const FaceShape(this.w, this.d);

  static const ys = <double>[-70, -62, -50, -34, -16, 0, 16, 30, 44, 55, 63, 68];

  final List<double> w;
  final List<double> d;

  static const oval = FaceShape(
    [14, 26, 37, 40, 41, 41, 40, 37, 32, 25, 17, 9],
    [20, 31, 39, 42, 44, 45, 46, 44, 40, 35, 28, 20],
  );

  /// Strong jaw, flat chin (hero / bearded men).
  static const square = FaceShape(
    [14, 27, 38, 42, 43, 43, 43, 41, 38, 32, 24, 16],
    [20, 32, 40, 43, 45, 46, 47, 46, 42, 36, 29, 22],
  );

  /// Soft, round (girls, children): cheeks tapering to a small round chin.
  static const round = FaceShape(
    [14, 27, 39, 42, 43, 43, 42, 38, 33, 26, 18, 10],
    [20, 33, 41, 44, 46, 47, 47, 45, 41, 35, 27, 19],
  );

  /// Long narrow face with a pointed chin (the smug youth).
  static const pointed = FaceShape(
    [14, 26, 37, 41, 42, 42, 41, 37, 30, 23, 15, 9],
    [20, 31, 39, 43, 45, 46, 47, 45, 40, 33, 25, 17],
  );

  /// Narrow older face.
  static const lean = FaceShape(
    [14, 26, 36, 40, 41, 41, 40, 37, 31, 24, 16, 8],
    [20, 31, 39, 42, 44, 45, 46, 44, 39, 32, 24, 14],
  );

  double _at(List<double> t, double y) {
    if (y <= ys.first) return t.first;
    if (y >= ys.last) return t.last;
    for (var i = 0; i < ys.length - 1; i++) {
      if (y <= ys[i + 1]) {
        final k = (y - ys[i]) / (ys[i + 1] - ys[i]);
        // smooth between samples
        final s = k * k * (3 - 2 * k);
        return t[i] + (t[i + 1] - t[i]) * (0.5 * k + 0.5 * s);
      }
    }
    return t.last;
  }

  double wAt(double y) => _at(w, y);
  double dAt(double y) => _at(d, y);
}

class Head {
  Head({
    required this.pos,
    this.scale = 1.0,
    this.yaw = 0.0,
    this.pitch = 0.0,
    this.roll = 0.0,
    this.shape = FaceShape.oval,
    double maxYaw = 0.38,
  }) : _a = yaw * maxYaw,
       _p = pitch * 0.35 {
    _ca = math.cos(_a);
    _sa = math.sin(_a);
    _cp = math.cos(_p);
    _sp = math.sin(_p);
    _cr = math.cos(roll);
    _sr = math.sin(roll);
  }

  /// Global position of the local origin (eye line centre) in 200-space.
  final Offset pos;
  final double scale;

  /// -1..1; negative = face turns towards the viewer's LEFT, positive = RIGHT.
  final double yaw;

  /// -1..1; positive = looking down.
  final double pitch;

  /// Radians; clockwise tilt of the whole head around the neck.
  final double roll;
  final FaceShape shape;

  final double _a, _p;
  late final double _ca, _sa, _cp, _sp, _cr, _sr;

  /// +1 when the nose points to the viewer's right, -1 left, 0 frontal.
  int get side => yaw > 0.05 ? 1 : (yaw < -0.05 ? -1 : 0);
  double get absYaw => yaw.abs().clamp(0.0, 1.5);

  /// Pivot of the head's roll (local coordinates): the base of the neck.
  static const neckPivot = Offset(0, 80);

  bool get isIdentity => _a == 0 && _p == 0 && roll == 0;

  /// Surface depth (distance from the rotation axis) at local (x, y).
  double surfaceZ(double x, double y) {
    final w = shape.wAt(y), d = shape.dAt(y);
    final u = x / w;
    return u.abs() < 1 ? d * math.sqrt(1 - u * u) : 0;
  }

  Offset _final(double xr, double yr) {
    var x = xr, y = yr;
    if (roll != 0) {
      final px = neckPivot.dx, py = neckPivot.dy;
      final dx = x - px, dy = y - py;
      x = px + dx * _cr - dy * _sr;
      y = py + dx * _sr + dy * _cr;
    }
    return Offset(pos.dx + x * scale, pos.dy + y * scale);
  }

  /// Project local point (x, y) lying on (or [lift] units above) the head surface.
  /// Pass [z] to give an explicit depth (for ears, protruding parts).
  Offset pt(double x, double y, {double lift = 0, double? z}) {
    final zs = z ?? (surfaceZ(x, y) + lift);
    final xr = x * _ca + zs * _sa;
    final zr = -x * _sa + zs * _ca;
    final yr = y * _cp + zr * _sp;
    return _final(xr, yr);
  }

  /// Depth towards the viewer after rotation (> 0 = visible side).
  double depthOf(double x, double y, {double lift = 0, double? z}) {
    final zs = z ?? (surfaceZ(x, y) + lift);
    return -x * _sa + zs * _ca;
  }

  Offset ptO(Offset o, {double lift = 0, double? z}) => pt(o.dx, o.dy, lift: lift, z: z);

  /// Warp a path authored in local front-view coordinates onto the head.
  Path path(Path local, {double lift = 0, double? z}) {
    if (isIdentity) {
      return xform(local, sx: scale, tx: pos.dx, ty: pos.dy);
    }
    return warpPath(local, (o) => pt(o.dx, o.dy, lift: lift, z: z), step: 0.8 / scale.clamp(0.5, 2));
  }

  /// Convenience: author with an SVG string in local coordinates.
  Path sp(String d, {double lift = 0, double? z}) => path(svg(d), lift: lift, z: z);

  /// Mirrored copy (about the head centre line x=0) of a local path.
  static Path mirror(Path p) => mirrorX(p, 0);

  /// Scale a local length to global units.
  double len(double v) => v * scale;

  /// Global position of the neck base (unaffected by yaw/pitch).
  Offset get neckBase => _final(0, 90);

  /// Global chin point.
  Offset get chin => pt(0, 68);

  /// The face (skin) silhouette: limb of the head ellipsoid, as a smooth closed path.
  Path outline({double grow = 0}) {
    final r = <Offset>[], l = <Offset>[];
    for (final y in FaceShape.ys) {
      final w = shape.wAt(y) + grow, d = shape.dAt(y) + grow;
      final lim = math.sqrt(w * w * _ca * _ca + d * d * _sa * _sa);
      // right and left extreme points of the rotated ellipse
      final sr = w * _ca / lim, cr = d * _sa / lim;
      final xR = w * sr, zR = d * cr;
      final xrR = xR * _ca + zR * _sa;
      final zrR = -xR * _sa + zR * _ca;
      final xrL = -xR * _ca + (-zR) * _sa;
      final zrL = xR * _sa + (-zR) * _ca;
      r.add(_final(xrR, y * _cp + zrR * _sp));
      l.add(_final(xrL, y * _cp + zrL * _sp));
    }
    final yb = FaceShape.ys.last;
    final bottom = pt(0, yb + 2.5 + grow, z: shape.dAt(yb) + grow * .5);
    final pts = <Offset>[...r, bottom, ...l.reversed];
    return spline(pts, closed: true);
  }

  /// Local-space convenience for drawing straight in global space.
  Offset g(double x, double y) => pt(x, y);
}
