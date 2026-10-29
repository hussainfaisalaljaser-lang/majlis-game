// D1 helpers: shared drawing parts for the animated animal / mascot avatars
// (wolf, falcon_bird, lv20 owl, lv30 leopard, lv40 lion, lv50 phoenix).
//
// Everything is authored in the 200-unit avatar space (rig layers use the same
// numbers; the 240-unit layer canvas is -20..220). The look follows the kit:
// thick aubergine outline, big glossy eyes, 2-tone cel shading, tapered fur lines.
import 'dart:math' as math;
import 'dart:ui';

import '../kit.dart';

/// Cel-shaded gold for chains, circlets, glasses rims and trim.
const d1Gold = Tones(Color(0xFFF7C948), Color(0xFFC8861A), Color(0xFFFFE9A0));

/// The video's near-black used for pupils, nostrils, mouth lines.
const d1Dark = Color(0xFF2A1520);

/// Warm white (teeth, claws, page paper).
const d1Cream = Color(0xFFFFF6E4);

/// Mirror a half silhouette (authored on the left of x = 100, closed along x = 100) into a full one.
Path d1Sym(Path left) => Path.combine(PathOperation.union, left, mirrorX(left));

double _hash(int n) {
  var x = (n * 374761393 + 668265263) & 0x7fffffff;
  x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff;
  return ((x ^ (x >> 16)) & 0xffff) / 65535.0;
}

List<Offset> _sample(Path p, double step) {
  final out = <Offset>[];
  for (final m in p.computeMetrics()) {
    final n = math.max(3, (m.length / step).round());
    for (var i = 0; i < n; i++) {
      final t = m.getTangentForOffset(m.length * i / n);
      if (t != null) out.add(t.position);
    }
    break;
  }
  return out;
}

double _area(List<Offset> p) {
  var a = 0.0;
  for (var i = 0; i < p.length; i++) {
    final q = p[(i + 1) % p.length];
    a += p[i].dx * q.dy - q.dx * p[i].dy;
  }
  return a / 2;
}

/// Spiky fur tufts all round a closed contour [base]. [amp] = tuft height, [step] = spacing,
/// [sweep] leans every tuft along the path direction (0 = symmetric spikes), [vary] randomises heights.
Path d1Fur(Path base, {double amp = 6, double step = 9, double sweep = .4, double vary = .3, int seed = 1, double bevel = .55}) {
  final pts = _sample(base, step);
  final n = pts.length;
  if (n < 3) return base;
  final cw = _area(pts) > 0;
  final out = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (var i = 0; i < n; i++) {
    final a = pts[i], b = pts[(i + 1) % n];
    final d = b - a;
    final len = d.distance;
    if (len < .001) continue;
    final t = d / len;
    final nrm = cw ? Offset(t.dy, -t.dx) : Offset(-t.dy, t.dx);
    final h = amp * (1 + vary * (_hash(seed * 131 + i) - .5) * 2);
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final peak = mid + nrm * h + t * (len * sweep);
    final c1 = a + nrm * (h * bevel) + t * (len * .1);
    final c2 = b + nrm * (h * .12) - t * (len * .05);
    out.quadraticBezierTo(c1.dx, c1.dy, peak.dx, peak.dy);
    out.quadraticBezierTo(c2.dx, c2.dy, b.dx, b.dy);
  }
  out.close();
  return out;
}

/// Same idea for an OPEN curve (a collar edge, a mane lock line): tufts on the side [out] (+1 = left of travel).
Path d1FurLine(Path curve, {double amp = 6, double step = 9, double sweep = .4, double vary = .3, int seed = 1, int out = 1}) {
  final pts = <Offset>[];
  for (final m in curve.computeMetrics()) {
    final n = math.max(2, (m.length / step).round());
    for (var i = 0; i <= n; i++) {
      final t = m.getTangentForOffset(m.length * i / n);
      if (t != null) pts.add(t.position);
    }
    break;
  }
  final res = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (var i = 0; i < pts.length - 1; i++) {
    final a = pts[i], b = pts[i + 1];
    final d = b - a;
    final len = d.distance;
    if (len < .001) continue;
    final t = d / len;
    final nrm = out > 0 ? Offset(t.dy, -t.dx) : Offset(-t.dy, t.dx);
    final h = amp * (1 + vary * (_hash(seed * 97 + i) - .5) * 2);
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final peak = mid + nrm * h + t * (len * sweep);
    final c1 = a + nrm * (h * .55) + t * (len * .1);
    final c2 = b + nrm * (h * .12) - t * (len * .05);
    res.quadraticBezierTo(c1.dx, c1.dy, peak.dx, peak.dy);
    res.quadraticBezierTo(c2.dx, c2.dy, b.dx, b.dy);
  }
  return res;
}

/// Tapered stroke from [a] to [b] with a bend (fur strand, fold, whisker).
void d1Strand(Pen pen, Offset a, Offset b, {double bend = 0, double w0 = 2.0, double w1 = .2, Color color = Style.ink, double bulge = 0}) {
  final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
  final d = b - a;
  final nrm = d.distance < .001 ? Offset.zero : Offset(-d.dy, d.dx) / d.distance;
  final c = mid + nrm * bend;
  pen.taper(Path()
    ..moveTo(a.dx, a.dy)
    ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy), w0: w0, w1: w1, color: color, bulge: bulge);
}

/// Thick tapered brow from [inner] to [outer].
void d1Brow(Pen pen, Offset inner, Offset outer, {double arch = 3, double thick = 6.2, double taper = .3, Color color = Style.ink}) {
  final mid = Offset((inner.dx + outer.dx) / 2, (inner.dy + outer.dy) / 2 - arch);
  final p = Path()
    ..moveTo(inner.dx, inner.dy)
    ..quadraticBezierTo(mid.dx, mid.dy, outer.dx, outer.dy);
  pen.taper(p, w0: thick, w1: thick * taper, bulge: thick * .22, color: color);
  // round the thick end
  pen.fill(circle(inner.dx, inner.dy, thick * .42), color);
}

Path _lidCover(double rx, double ry, int side, double lidTop, double slant, double curve) {
  double yAt(double x) => -ry + 2 * ry * lidTop - slant * ry * .9 * (side * x / rx);
  final x0 = -rx * 1.4, x1 = rx * 1.4;
  return Path()
    ..moveTo(x0, -ry * 2.4)
    ..lineTo(x0, yAt(x0))
    ..quadraticBezierTo(0, (yAt(x0) + yAt(x1)) / 2 + curve * 2 * ry, x1, yAt(x1))
    ..lineTo(x1, -ry * 2.4)
    ..close();
}

/// A big glossy cartoon eye: white sclera, iris, pupil, two highlights, thick upper lid.
/// [side] +1 = the viewer's right eye (for [lidSlant]: + = inner corner lower = angry).
/// [lookX]/[lookY] -1..1. [irisR] is a fraction of [ry]; [pupilR] a fraction of the iris.
void d1Eye(
  Pen pen,
  Offset c, {
  double rx = 11,
  double ry = 11,
  double rot = 0,
  int side = 1,
  double lookX = 0,
  double lookY = 0,
  Color iris = const Color(0xFF8A5A2B),
  double irisR = .62,
  double pupilR = .52,
  bool slit = false,
  Color sclera = const Color(0xFFFFFFFF),
  Color shade = const Color(0xFFD6D2E6),
  double lidTop = 0,
  double lidSlant = 0,
  double lid = 3.3,
  double line = 2.0,
  double lidCurve = .25,
  double glint = 1,
}) {
  final cv = pen.c;
  cv.save();
  cv.translate(c.dx, c.dy);
  cv.rotate(rot);
  final contour = ellipse(0, 0, rx, ry);
  final covered = lidTop > 0 || lidSlant != 0;
  final visible = covered ? Path.combine(PathOperation.difference, contour, _lidCover(rx, ry, side, lidTop, lidSlant, lidCurve)) : contour;
  pen.fill(visible, sclera);
  pen.crescent(visible, shade, depth: ry * .3, dir: const Offset(0, 1));
  final ir = irisR * ry;
  final ix = lookX * math.max(0.0, rx - ir * .55);
  final iy = lookY * (ry - ir * .6) * .6 + ry * .04;
  pen.inside(visible, (p) {
    final irisP = circle(ix, iy, ir);
    p.fill(irisP, iris);
    p.crescent(irisP, shadeOf(iris, .45), depth: ir * .55, dir: const Offset(0, 1));
    p.rim(irisP, lightOf(iris, .4), depth: ir * .34, dir: const Offset(0, -1));
    p.line(irisP, w: .9, color: shadeOf(iris, .6));
    final pupil = slit ? ellipse(ix + lookX * .5, iy, ir * pupilR * .55, ir * .9) : circle(ix + lookX * .5, iy + lookY * .3, ir * pupilR);
    p.fill(pupil, const Color(0xFF16101A));
    if (glint > 0) {
      p.fill(circle(ix - ir * .32, iy - ir * .36, ir * .3 * glint), const Color(0xFFFFFFFF));
      p.fill(circle(ix + ir * .34, iy + ir * .4, ir * .14 * glint), withA(const Color(0xFFFFFFFF), .9));
    }
  });
  // outline: thin all round, thick on the upper lid
  pen.line(visible, w: line, color: Style.ink);
  final Path lidLine;
  if (!covered) {
    lidLine = Path()..addArc(Rect.fromCenter(center: Offset.zero, width: rx * 2.0, height: ry * 2.0), math.pi * 1.04, math.pi * .98);
  } else {
    double yAt(double x) => -ry + 2 * ry * lidTop - lidSlant * ry * .9 * (side * x / rx);
    final x0 = -rx * 1.1, x1 = rx * 1.1;
    lidLine = Path()
      ..moveTo(x0, yAt(x0))
      ..quadraticBezierTo(0, (yAt(x0) + yAt(x1)) / 2 + lidCurve * 2 * ry, x1, yAt(x1));
  }
  pen.inside(ellipse(0, 0, rx + 1.6, ry + 1.6), (p) => p.line(lidLine, w: lid, color: Style.ink));
  cv.restore();
}

/// Closed eye (blink layer): a patch of the fur colour over the open eye + a curved lid line.
/// [bend] > 0 = smiling bowl (contented / howling), < 0 = tired droop.
void d1EyeClosed(
  Pen pen,
  Offset c, {
  double rx = 11,
  double ry = 11,
  double rot = 0,
  required Color fur,
  double w = 3.2,
  double bend = .75,
  double pad = 2.2,
}) {
  final cv = pen.c;
  cv.save();
  cv.translate(c.dx, c.dy);
  cv.rotate(rot);
  pen.fill(ellipse(0, 0, rx + pad, ry + pad), fur);
  final p = Path()
    ..moveTo(-rx * .98, -ry * .05)
    ..quadraticBezierTo(0, ry * bend * 1.5, rx * .98, -ry * .05);
  pen.line(p, w: w, color: Style.ink);
  cv.restore();
}

/// Glossy animal nose (rounded triangle) with a highlight.
void d1Nose(Pen pen, Offset c, {double w = 16, double h = 11, Color color = const Color(0xFF2B2030), double tilt = 0}) {
  final cv = pen.c;
  cv.save();
  cv.translate(c.dx, c.dy);
  cv.rotate(tilt);
  final hw = w / 2, hh = h / 2;
  final p = svg('M${-hw} ${-hh * .55} C${-hw * .6} ${-hh * 1.25} ${hw * .6} ${-hh * 1.25} $hw ${-hh * .55} C${hw * 1.02} ${hh * .1} ${hw * .35} ${hh * .95} 0 $hh C${-hw * .35} ${hh * .95} ${-hw * 1.02} ${hh * .1} ${-hw} ${-hh * .55} Z');
  pen.fill(p, color);
  pen.crescent(p, shadeOf(color, .4), depth: 1.8);
  pen.line(p, w: Style.lineThin + .5, color: Style.ink);
  pen.fill(ellipse(-hw * .38, -hh * .42, hw * .34, hh * .2, rot: -.35), withA(const Color(0xFFFFFFFF), .85));
  cv.restore();
}

/// A whisker: thin tapered line.
void d1Whisker(Pen pen, Offset a, Offset b, {double bend = 2, double w = 1.5, Color color = const Color(0xFFFFFFFF), Color? edge}) {
  if (edge != null) d1Strand(pen, a, b, bend: bend, w0: w + 1.3, w1: .5, color: edge);
  d1Strand(pen, a, b, bend: bend, w0: w, w1: .15, color: color);
}

/// A faceted gem (round-cut) with an outline and glints.
void d1Gem(Pen pen, Offset c, double r, Color color, {bool diamond = false}) {
  final p = diamond
      ? poly([Offset(c.dx, c.dy - r * 1.15), Offset(c.dx + r * .95, c.dy), Offset(c.dx, c.dy + r * 1.15), Offset(c.dx - r * .95, c.dy)])
      : circle(c.dx, c.dy, r);
  final t = Tones.auto(color, shade: .3, hi: .3);
  pen.solid(p, t, shade: r * .5, hi: r * .22, w: Style.lineThin + .3);
  pen.fill(
    diamond
        ? poly([Offset(c.dx - r * .1, c.dy - r * .75), Offset(c.dx + r * .45, c.dy - r * .05), Offset(c.dx - r * .12, c.dy - r * .05)])
        : circle(c.dx - r * .3, c.dy - r * .32, r * .3),
    withA(const Color(0xFFFFFFFF), .85),
  );
}

/// Soft cel highlight blob (white, hard-ish) used on fur / metal.
void d1Shine(Pen pen, Offset c, double rx, double ry, {double rot = -.4, double a = .8}) {
  pen.fill(ellipse(c.dx, c.dy, rx, ry, rot: rot), withA(const Color(0xFFFFFFFF), a));
}

/// Build a [CharSpec] for a cut-out rig character from named layer painters.
/// [still] lists the layers (bottom to top) that make up the static `<id>.webp`; the still is clipped to
/// the avatar circle like the old art. Every entry of [layers] is also exported as a rig layer.
CharSpec d1Spec(String id, Map<String, PropPainter> layers, List<String> still) => CharSpec(
  id: id,
  cutout: true,
  custom: (pen, h) {
    pen.c.save();
    pen.c.clipPath(circle(100, 100, 100));
    for (final n in still) {
      layers[n]!(pen, h);
    }
    pen.c.restore();
  },
  extraLayers: layers,
);

/// Local outline of a flame feather: base at the origin, tip at (0, -len), curling to one side ([curl] +1 / -1).
Path d1FlameLocal(double len, double w, {int curl = 1}) {
  final s = curl.toDouble();
  final x = <double>[-w, -w * .85, -w * .25, -w * .1, w * .15, w * .35, w * .5, w * .9, w * .8, w * .7, w * .3];
  String c(double v) => (v * s).toStringAsFixed(2);
  String y(double v) => (v * len).toStringAsFixed(2);
  return svg(
    'M0 0 C${c(x[0])} ${y(-.2)} ${c(x[1])} ${y(-.6)} ${c(x[2])} ${y(-.85)} '
    'C${c(x[3])} ${y(-.93)} ${c(x[4])} ${y(-.97)} ${c(x[5])} ${y(-1)} '
    'C${c(x[6])} ${y(-.7)} ${c(x[7])} ${y(-.5)} ${c(x[8])} ${y(-.28)} '
    'C${c(x[9])} ${y(-.1)} ${c(x[10])} ${y(-.02)} 0 0 Z',
  );
}

/// A three-tone flame feather (outer outlined, mid and core flat) with its base at [base],
/// pointing [angle] radians clockwise from straight up.
void d1Flame(
  Pen pen,
  Offset base,
  double len,
  double w,
  double angle, {
  int curl = 1,
  required Tones outer,
  required Color mid,
  required Color core,
  double outline = Style.line,
}) {
  final cs = math.cos(angle), sn = math.sin(angle);
  Path place(Path p) => p.transform(affine(cs, sn, -sn, cs, base.dx, base.dy));
  final o = place(d1FlameLocal(len, w, curl: curl));
  pen.solid(o, outer, shade: 3, hi: 0, w: outline);
  final m = place(xform(d1FlameLocal(len, w, curl: curl), sx: .66, sy: .8));
  pen.fill(m, mid);
  final c = place(xform(d1FlameLocal(len, w, curl: curl), sx: .34, sy: .58));
  pen.fill(c, core);
}
