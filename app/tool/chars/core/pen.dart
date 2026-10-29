// Core drawing primitives of the character kit: SVG-path parser, spline
// helpers, colour "tones" (base / shade / highlight) and the [Pen] that draws
// outlined, cel-shaded shapes in the 200x200 logical avatar space.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart' show HSLColor;

// ───────────────────────────── style constants ─────────────────────────────

/// Global look of the video's art. Everything is in 200-unit avatar space
/// (the background circle is centre (100,100), r = 100).
abstract final class Style {
  /// Outline colour: very dark aubergine-brown (never pure black).
  static const ink = Color(0xFF2A1520);

  /// Main silhouette outline width (units). 2.7 of 200 = 1.35% of the diameter.
  static const line = 2.7;

  /// Inner feature lines (eyelids, nose, folds) are thinner.
  static const lineThin = 1.7;
  static const lineFine = 1.1;

  /// Direction the light comes FROM (unit-ish vector, up-left).
  static const light = Offset(-0.55, -0.75);
}

// ───────────────────────────── geometry helpers ─────────────────────────────

Offset lerpO(Offset a, Offset b, double t) => Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);

double lerpD(double a, double b, double t) => a + (b - a) * t;

double clampD(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

double smoothstep(double a, double b, double x) {
  final t = clampD((x - a) / (b - a), 0, 1);
  return t * t * (3 - 2 * t);
}

/// 2D affine as a 4x4 column-major matrix: x' = a*x + c*y + e, y' = b*x + d*y + f.
Float64List affine(double a, double b, double c, double d, double e, double f) => Float64List.fromList([a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, e, f, 0, 1]);

/// Scale then translate a path.
Path xform(Path p, {double sx = 1, double? sy, double tx = 0, double ty = 0}) => p.transform(affine(sx, 0, 0, sy ?? sx, tx, ty));

/// Parse SVG path data (M L H V C S Q T Z, absolute and relative; no arcs).
/// Lets shapes be authored as familiar SVG strings: `svg('M10 10 C ...')`.
Path svg(String d) {
  final path = Path();
  final tok = RegExp(r'[MmLlHhVvCcSsQqTtZz]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?').allMatches(d).map((m) => m.group(0)!).toList();
  var i = 0;
  var cx = 0.0, cy = 0.0, sx = 0.0, sy = 0.0;
  var lcx = 0.0, lcy = 0.0; // last control point
  var cmd = 'M';
  double num() => double.parse(tok[i++]);
  bool isCmd(String s) => RegExp(r'[A-Za-z]').hasMatch(s);
  while (i < tok.length) {
    if (isCmd(tok[i])) cmd = tok[i++];
    final rel = cmd == cmd.toLowerCase();
    final c = cmd.toUpperCase();
    switch (c) {
      case 'M':
        var x = num(), y = num();
        if (rel) {
          x += cx;
          y += cy;
        }
        path.moveTo(x, y);
        cx = sx = x;
        cy = sy = y;
        lcx = cx;
        lcy = cy;
        cmd = rel ? 'l' : 'L';
      case 'L':
        var x = num(), y = num();
        if (rel) {
          x += cx;
          y += cy;
        }
        path.lineTo(x, y);
        cx = x;
        cy = y;
        lcx = cx;
        lcy = cy;
      case 'H':
        var x = num();
        if (rel) x += cx;
        path.lineTo(x, cy);
        cx = x;
        lcx = cx;
        lcy = cy;
      case 'V':
        var y = num();
        if (rel) y += cy;
        path.lineTo(cx, y);
        cy = y;
        lcx = cx;
        lcy = cy;
      case 'C':
        var x1 = num(), y1 = num(), x2 = num(), y2 = num(), x = num(), y = num();
        if (rel) {
          x1 += cx;
          y1 += cy;
          x2 += cx;
          y2 += cy;
          x += cx;
          y += cy;
        }
        path.cubicTo(x1, y1, x2, y2, x, y);
        lcx = x2;
        lcy = y2;
        cx = x;
        cy = y;
      case 'S':
        var x2 = num(), y2 = num(), x = num(), y = num();
        if (rel) {
          x2 += cx;
          y2 += cy;
          x += cx;
          y += cy;
        }
        path.cubicTo(2 * cx - lcx, 2 * cy - lcy, x2, y2, x, y);
        lcx = x2;
        lcy = y2;
        cx = x;
        cy = y;
      case 'Q':
        var x1 = num(), y1 = num(), x = num(), y = num();
        if (rel) {
          x1 += cx;
          y1 += cy;
          x += cx;
          y += cy;
        }
        path.quadraticBezierTo(x1, y1, x, y);
        lcx = x1;
        lcy = y1;
        cx = x;
        cy = y;
      case 'T':
        var x = num(), y = num();
        if (rel) {
          x += cx;
          y += cy;
        }
        final x1 = 2 * cx - lcx, y1 = 2 * cy - lcy;
        path.quadraticBezierTo(x1, y1, x, y);
        lcx = x1;
        lcy = y1;
        cx = x;
        cy = y;
      case 'Z':
        path.close();
        cx = sx;
        cy = sy;
        lcx = cx;
        lcy = cy;
    }
  }
  return path;
}

/// Catmull-Rom spline through [pts] as a cubic path (closed or open).
Path spline(List<Offset> pts, {bool closed = false, double tension = 1.0}) {
  final p = Path();
  final n = pts.length;
  if (n < 2) return p;
  p.moveTo(pts[0].dx, pts[0].dy);
  final segs = closed ? n : n - 1;
  Offset at(int i) => closed ? pts[(i % n + n) % n] : pts[i.clamp(0, n - 1)];
  for (var i = 0; i < segs; i++) {
    final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
    final c1 = p1 + (p2 - p0) * (tension / 6);
    final c2 = p2 - (p3 - p1) * (tension / 6);
    p.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  if (closed) p.close();
  return p;
}

/// Polyline through points (optionally closed).
Path poly(List<Offset> pts, {bool closed = true}) {
  final p = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (final q in pts.skip(1)) {
    p.lineTo(q.dx, q.dy);
  }
  if (closed) p.close();
  return p;
}

Path ellipse(double cx, double cy, double rx, double ry, {double rot = 0}) {
  final p = Path()..addOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2));
  final cs = math.cos(rot), sn = math.sin(rot);
  return p.transform(affine(cs, sn, -sn, cs, cx, cy));
}

Path circle(double cx, double cy, double r) => Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

Path moved(Path p, double dx, double dy) => p.shift(Offset(dx, dy));

/// Mirror around the vertical line x = [cx].
Path mirrorX(Path p, [double cx = 100]) => p.transform(affine(-1, 0, 0, 1, 2 * cx, 0));

Path scaledAbout(Path p, Offset c, double sx, [double? sy]) {
  final y = sy ?? sx;
  return p.transform(affine(sx, 0, 0, y, c.dx - sx * c.dx, c.dy - y * c.dy));
}

Path rotatedAbout(Path p, Offset c, double rad) {
  final cs = math.cos(rad), sn = math.sin(rad);
  return p.transform(affine(cs, sn, -sn, cs, c.dx - (cs * c.dx - sn * c.dy), c.dy - (sn * c.dx + cs * c.dy)));
}

/// Sample a path into a polyline (used to warp shapes through the head projection).
List<List<Offset>> flatten(Path p, {double step = 0.9}) {
  final out = <List<Offset>>[];
  for (final m in p.computeMetrics()) {
    final pts = <Offset>[];
    final n = math.max(2, (m.length / step).ceil());
    for (var i = 0; i <= n; i++) {
      final t = m.getTangentForOffset(m.length * i / n);
      if (t != null) pts.add(t.position);
    }
    // detect closed contours
    out.add(pts);
  }
  return out;
}

/// Rebuild a path after mapping every sampled point through [f].
Path warpPath(Path p, Offset Function(Offset) f, {double step = 0.9}) {
  final out = Path();
  for (final m in p.computeMetrics()) {
    final n = math.max(2, (m.length / step).ceil());
    var first = true;
    for (var i = 0; i <= n; i++) {
      final t = m.getTangentForOffset(m.length * i / n);
      if (t == null) continue;
      final q = f(t.position);
      if (first) {
        out.moveTo(q.dx, q.dy);
        first = false;
      } else {
        out.lineTo(q.dx, q.dy);
      }
    }
    if (m.isClosed) out.close();
  }
  return out;
}

// ───────────────────────────── colour helpers ─────────────────────────────

Color hex(int v) => Color(0xFF000000 | v);

Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;

Color withA(Color c, double a) => c.withValues(alpha: a);

/// Darken keeping hue, slightly shifting towards warm purple (cel-shading feel).
Color shadeOf(Color c, [double amount = 0.22]) {
  final h = HSLColor.fromColor(c);
  final s = clampD(h.saturation * 1.05 + 0.04, 0, 1);
  final l = clampD(h.lightness * (1 - amount), 0, 1);
  final hue = (h.hue - 6 * amount * 4) % 360;
  return HSLColor.fromAHSL(1, hue < 0 ? hue + 360 : hue, s, l).toColor();
}

Color lightOf(Color c, [double amount = 0.18]) {
  final h = HSLColor.fromColor(c);
  final l = clampD(h.lightness + (1 - h.lightness) * amount, 0, 1);
  final s = clampD(h.saturation * 0.95, 0, 1);
  return HSLColor.fromAHSL(1, (h.hue + 4) % 360, s, l).toColor();
}

/// A colour with its cel-shading companions.
class Tones {
  const Tones(this.base, this.shade, this.hi);

  /// Derive shade and highlight automatically from a base colour.
  factory Tones.auto(Color base, {double shade = 0.22, double hi = 0.16}) => Tones(base, shadeOf(base, shade), lightOf(base, hi));

  final Color base;
  final Color shade;
  final Color hi;

  Tones darker([double a = .25]) => Tones(shadeOf(base, a), shadeOf(shade, a), base);
  Tones lighter([double a = .2]) => Tones(lightOf(base, a), base, lightOf(hi, a));
}

// ───────────────────────────── the pen ─────────────────────────────

/// Draws onto a [Canvas] that is already scaled to the 200-unit space.
class Pen {
  Pen(this.c);

  final Canvas c;

  Paint _fill(Color col) => Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true
    ..color = col;

  Paint _stroke(Color col, double w) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true
    ..color = col;

  void fill(Path p, Color col) => c.drawPath(p, _fill(col));

  void fillShader(Path p, Shader s) => c.drawPath(
    p,
    Paint()
      ..isAntiAlias = true
      ..shader = s,
  );

  void line(Path p, {double w = Style.lineThin, Color color = Style.ink}) => c.drawPath(p, _stroke(color, w));

  /// Run [draw] with the canvas clipped to [clip].
  void clipped(Path clip, void Function() draw) {
    c.save();
    c.clipPath(clip);
    draw();
    c.restore();
  }

  /// Plain flat fill with outline.
  void shape(Path p, Color col, {double w = Style.line, Color ink = Style.ink}) {
    fill(p, col);
    if (w > 0) line(p, w: w, color: ink);
  }

  /// Shadow crescent inside [p] on the side away from the light; [depth] is its thickness.
  void crescent(Path p, Color col, {double depth = 3.5, Offset? dir}) {
    final d = (dir ?? Style.light);
    final v = Offset(d.dx, d.dy) * depth;
    final cut = Path.combine(PathOperation.difference, p, p.shift(v));
    clipped(p, () => fill(cut, col));
  }

  /// Light rim on the side facing the light.
  void rim(Path p, Color col, {double depth = 1.6, Offset? dir}) {
    final d = (dir ?? Style.light);
    final v = Offset(d.dx, d.dy) * depth;
    final cut = Path.combine(PathOperation.difference, p, p.shift(-v));
    clipped(p, () => fill(cut, col));
  }

  /// The standard cel-shaded solid: base fill, shadow side, highlight rim, outline.
  void solid(
    Path p,
    Tones t, {
    double shade = 3.5,
    double hi = 1.5,
    double w = Style.line,
    Offset? dir,
    Color ink = Style.ink,
  }) {
    fill(p, t.base);
    if (shade > 0) crescent(p, t.shade, depth: shade, dir: dir);
    if (hi > 0) rim(p, t.hi, depth: hi, dir: dir);
    if (w > 0) line(p, w: w, color: ink);
  }

  /// Paint something inside [clip] only (shadows, folds that must not leak).
  void inside(Path clip, void Function(Pen pen) draw) {
    clipped(clip, () => draw(this));
  }

  /// Soft blush / glow blob (radial, translucent).
  void glow(Offset at, double rx, double ry, Color col, {double alpha = .35}) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(1, ry / rx);
    c.drawCircle(
      Offset.zero,
      rx,
      Paint()
        ..shader = Gradient.radial(Offset.zero, rx, [withA(col, alpha), withA(col, 0)], [0, 1]),
    );
    c.restore();
  }

  /// Linear gradient fill between two colours along a direction.
  void gradient(Path p, Offset a, Offset b, List<Color> colors, [List<double>? stops]) {
    fillShader(p, Gradient.linear(a, b, colors, stops));
  }
}
