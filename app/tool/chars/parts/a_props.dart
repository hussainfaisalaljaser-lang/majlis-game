// Worker A: hands (thumbs-up, finger raised, coin pinch), bead strings, pins and
// age lines used by pack1. Hands are drawn in their own frame (origin = top-centre
// of the fist, +y down, forearm going down) and placed in 200-space.
import 'dart:math' as math;
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';
import 'body.dart' show rel;
import 'eyes.dart' show EyeSpec;

enum FistPose { thumbsUp, pointUp, coinPinch }

Path _tx(Path p, Offset at, double rot, double s, bool mirror) {
  final cs = math.cos(rot) * s, sn = math.sin(rot) * s;
  final mx = mirror ? -1.0 : 1.0;
  return p.transform(affine(cs * mx, sn * mx, -sn, cs, at.dx, at.dy));
}

/// A finger bar: left end fully round, right end flush (disappears into the hand).
Path _bar(double x0, double x1, double y0, double y1) {
  final r = (y1 - y0) / 2, cy = (y0 + y1) / 2;
  const k = 0.5523;
  return Path()
    ..moveTo(x0 + r, y0)
    ..lineTo(x1, y0)
    ..lineTo(x1, y1)
    ..lineTo(x0 + r, y1)
    ..cubicTo(x0 + r - k * r, y1, x0, cy + k * r, x0, cy)
    ..cubicTo(x0, cy - k * r, x0 + r - k * r, y0, x0 + r, y0)
    ..close();
}

/// A fist coming up from the bottom of the picture. [at] = top-centre of the fist
/// (200-space); [rot] radians; [mirror] flips left/right.
void drawFist(
  Pen pen,
  Skin skin,
  FistPose pose, {
  required Offset at,
  double rot = 0,
  double size = 1,
  bool mirror = false,
  Tones sleeve = Cloth.white,
  Color? cuffTrim,
}) {
  final s = size;
  Path P(String d) => _tx(svg(d), at, rot, s, mirror);
  Path T(Path p) => _tx(p, at, rot, s, mirror);
  final lw = Style.line * 0.85 * s;
  final fine = Style.lineThin * 0.85 * s;
  final nail = Tones(mix(skin.hi, const Color(0xFFFFFFFF), .35), skin.base, const Color(0xFFFFFFFF));

  // forearm + sleeve (flares towards the bottom of the picture)
  final arm = P('M-21 38 C-25 68 -30 100 -35 150 L40 150 C35 100 31 68 26 38 Z');
  pen.fill(arm, sleeve.base);
  pen.crescent(arm, sleeve.shade, depth: 7 * s, dir: const Offset(-0.9, -0.3));
  pen.inside(arm, (p) {
    p.line(P('M-6 52 C-8 80 -10 108 -12 146'), w: fine, color: withA(sleeve.shade, .95));
    p.line(P('M12 52 C14 80 16 108 18 146'), w: fine * .9, color: withA(sleeve.shade, .8));
  });
  pen.line(arm, w: lw);

  // fist body (back of the hand)
  final body = P('M-25 8 C-25 -3 -17 -5 -8 -5 L16 -5 C25 -5 29 2 29 12 L29 36 C29 46 21 50 12 50 L-10 50 C-20 50 -26 44 -26 33 Z');
  pen.solid(body, skin.tones, shade: 4 * s, hi: 1.2 * s, w: lw);

  void bars(List<double> ys, double xl) {
    for (var i = 0; i + 1 < ys.length; i++) {
      final b = T(_bar(xl + i * 0.8, 25, ys[i], ys[i + 1]));
      pen.fill(b, skin.base);
      pen.inside(b, (p) {
        p.crescent(b, skin.shade, depth: 2.4 * s, dir: const Offset(0.3, 1));
        p.rim(b, skin.hi, depth: 1.0 * s, dir: const Offset(0.2, -1));
      });
      pen.line(b, w: fine * 1.1);
    }
  }

  switch (pose) {
    case FistPose.thumbsUp:
      bars(const [4, 15.5, 27, 38.5, 50], -26);
      final thumb = P('M-17 9 C-21 -2 -21 -16 -17 -25 C-14 -33 -5 -36 -1 -29 C2 -23 1 -12 6 -4 C8 0 9 5 8 9 Z');
      pen.solid(thumb, skin.tones, shade: 3 * s, hi: 1.0 * s, w: lw * .95);
      final n = T(ellipse(-8.5, -26, 4.2, 5.2, rot: -0.15));
      pen.fill(n, nail.base);
      pen.line(n, w: fine * .8, color: withA(Style.ink, .75));
      pen.line(P('M-15 4 C-12 6 -6 7 0 5'), w: fine * .8, color: withA(Style.ink, .6));
    case FistPose.pointUp:
      bars(const [10, 21, 32, 43], -26);
      final finger = P('M-17 14 C-18 -4 -17 -22 -15 -36 C-14 -44 -1 -44 0 -36 C2 -22 3 -4 5 14 Z');
      pen.solid(finger, skin.tones, shade: 3 * s, hi: 1.0 * s, w: lw * .95);
      final n = T(ellipse(-7.5, -37, 3.9, 4.6));
      pen.fill(n, nail.base);
      pen.line(n, w: fine * .8, color: withA(Style.ink, .75));
      pen.line(P('M-16 -14 C-12 -13 -7 -13 -1 -14'), w: fine * .7, color: withA(skin.deep, .8));
      // thumb folded across the front
      final thumb = P('M26 12 C26 3 14 1 4 6 C-2 10 -2 17 4 18 C12 19 21 26 26 24 Z');
      pen.solid(thumb, skin.tones, shade: 2.4 * s, hi: 0.9 * s, w: lw * .9);
    case FistPose.coinPinch:
      bars(const [10, 21, 32, 43], -26);
      // coin (behind the fingertips)
      final coin = T(circle(2, -27, 13.5));
      pen.fill(coin, const Color(0xFFE3B341));
      pen.inside(coin, (p) {
        p.crescent(coin, const Color(0xFFB07A1F), depth: 3.2 * s, dir: const Offset(-0.7, -0.7));
        p.rim(coin, const Color(0xFFFFE9A0), depth: 1.3 * s, dir: const Offset(-0.7, -0.7));
      });
      final inner = T(circle(2, -27, 9));
      pen.line(inner, w: fine * .9, color: withA(const Color(0xFF8A5A12), .9));
      pen.line(P('M-1.5 -27 L5.5 -27 M2 -30.5 L2 -23.5'), w: fine * 1.1, color: withA(const Color(0xFF8A5A12), .9));
      pen.line(coin, w: lw);
      final idx = P('M-21 14 C-25 2 -24 -12 -16 -22 C-11 -26 -5 -22 -9 -16 C-13 -10 -12 0 -10 14 Z');
      pen.solid(idx, skin.tones, shade: 2.4 * s, hi: 0.9 * s, w: lw * .9);
      final thb = P('M25 14 C31 4 29 -8 21 -16 C16 -20 10 -15 14 -10 C18 -5 16 3 12 14 Z');
      pen.solid(thb, skin.tones, shade: 2.4 * s, hi: 0.9 * s, w: lw * .9);
  }
}

// ───────────────────────────── beads / pins ─────────────────────────────

/// Beads strung along [curve] (200-space): [n] beads of radius [r] with outline and a shine dot.
void drawBeads(Pen pen, Path curve, int n, double r, Tones t, {Color? string, double rEnd = 1.0}) {
  final m = curve.computeMetrics().first;
  if (string != null) pen.line(curve, w: 1.0, color: string);
  for (var i = 0; i < n; i++) {
    final u = n == 1 ? .5 : i / (n - 1);
    // largest bead in the middle (like a graduated strand)
    final rr = r * lerpD(rEnd, 1.0, math.sin(u * math.pi));
    final p = m.getTangentForOffset(m.length * u)!.position;
    final c = circle(p.dx, p.dy, rr);
    pen.fill(c, t.base);
    pen.inside(c, (q) {
      q.crescent(c, t.shade, depth: rr * 0.7, dir: const Offset(0.5, 0.8));
    });
    pen.line(c, w: Style.lineThin * 0.7, color: Style.ink);
    pen.glow(Offset(p.dx - rr * .32, p.dy - rr * .36), rr * .34, rr * .26, const Color(0xFFFFFFFF), alpha: .95);
  }
}

/// Gold crescent moon (+ optional small star) pin at [at].
void drawMoonPin(Pen pen, Offset at, double r, {double rot = -0.5}) {
  final gold = const Tones(Color(0xFFF0C14B), Color(0xFFB8841E), Color(0xFFFFE9A0));
  final outer = circle(0, 0, r);
  final bite = circle(r * .42, -r * .12, r * .82);
  final moon = Path.combine(PathOperation.difference, outer, bite).transform(affine(math.cos(rot), math.sin(rot), -math.sin(rot), math.cos(rot), at.dx, at.dy));
  pen.solid(moon, gold, shade: r * .22, hi: r * .1, w: Style.lineThin * 0.9);
  // star
  final sc = Offset(at.dx + r * .55, at.dy - r * .1);
  final star = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rr = i.isEven ? r * .34 : r * .15;
    final p = Offset(sc.dx + rr * math.cos(a), sc.dy + rr * math.sin(a));
    i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
  }
  star.close();
  pen.solid(star, gold, shade: 0, hi: 0, w: Style.lineThin * 0.7);
}

/// Round brooch with a gem at [at].
void drawGemPin(Pen pen, Offset at, double r, Tones gem, {Color rim = const Color(0xFFE3B341)}) {
  final o = circle(at.dx, at.dy, r);
  pen.fill(o, rim);
  pen.inside(o, (q) => q.crescent(o, const Color(0xFFB07A1F), depth: r * .35, dir: const Offset(0.6, 0.8)));
  pen.line(o, w: Style.lineThin * 0.9);
  final g = circle(at.dx, at.dy, r * .62);
  pen.solid(g, gem, shade: r * .35, hi: r * .15, w: Style.lineThin * 0.6);
  pen.glow(Offset(at.dx - r * .22, at.dy - r * .25), r * .22, r * .18, const Color(0xFFFFFFFF), alpha: .95);
}

// ───────────────────────────── face lines (age, laughter) ─────────────────────────────

/// Fine taper lines in head-local coordinates: crow's feet, nasolabial folds, forehead lines.
void agingLines(Pen pen, Head h, Skin skin, {double gap = 19.5, double ew = 11, double eyeY = 0, double mouthY = 42, bool forehead = false, double k = 1}) {
  final sc = h.scale;
  final c = withA(skin.deep, .75 * k.clamp(0, 1.2));
  Path P(String d) => h.path(svg(d), lift: 1.4);
  for (final s in const [-1, 1]) {
    final x = s * (gap + ew + 1.5);
    // crow's feet fanning from the outer corner
    pen.taper(P('M$x ${eyeY - 1} C${x + s * 3} ${eyeY - 4} ${x + s * 5} ${eyeY - 6} ${x + s * 6.5} ${eyeY - 8}'), w0: 1.5 * sc, w1: .1, color: c);
    pen.taper(P('M$x ${eyeY + 1.5} C${x + s * 3.5} ${eyeY + 1.5} ${x + s * 6} ${eyeY + 1} ${x + s * 7.5} $eyeY'), w0: 1.5 * sc, w1: .1, color: c);
    pen.taper(P('M$x ${eyeY + 4} C${x + s * 3} ${eyeY + 5.5} ${x + s * 5} ${eyeY + 7.5} ${x + s * 6} ${eyeY + 9.5}'), w0: 1.4 * sc, w1: .1, color: c);
    // under-eye bag
    pen.taper(P('M${s * (gap - ew * .6)} ${eyeY + 12} C${s * gap} ${eyeY + 15} ${s * (gap + ew * .7)} ${eyeY + 14} ${s * (gap + ew + 1)} ${eyeY + 11}'), w0: 1.2 * sc, w1: .1, color: withA(skin.deep, .5 * k.clamp(0, 1.2)));
    // nasolabial fold
    pen.taper(P('M${s * 11} 26 C${s * 16} 32 ${s * 17} ${mouthY - 4} ${s * 14} ${mouthY + 4}'), w0: 1.9 * sc, w1: .2, color: c);
  }
  if (forehead) {
    for (final dy in const [0.0, 5.0]) {
      pen.taper(P('M-22 ${-26 + dy} C-10 ${-29 + dy} 8 ${-29 + dy} 24 ${-25 + dy}'), w0: 1.1 * sc, w1: .1, color: withA(skin.deep, .5 * k.clamp(0, 1.2)));
    }
  }
}

/// A necklace-style arc relative to the neck base (units of head scale): [dy] = depth of the sag.
Path necklaceArc(Head h, {double half = 34, double top = -10, double dy = 26}) {
  return rel(h, 'M${-half} $top C${-half * .6} ${top + dy} ${half * .6} ${top + dy} $half $top');
}

// ───────────────────────────── laughing eyes / sparkles ─────────────────────────────

/// Eyes squeezed shut with laughter: thick upward arcs (use EyeSpec(open: 0) so the
/// kit draws no eye) plus a small cheek fold under each arc.
void drawLaughEyes(Pen pen, Head h, EyeSpec e, {double thick = 4.2, double arch = 0.62}) {
  final sc = h.scale;
  for (final s in const [-1, 1]) {
    final x0 = s * (e.gap - e.ew * 0.88), x1 = s * (e.gap + e.ew * 0.92);
    final xm = s * e.gap;
    final y = e.y;
    final curve = h.path(svg('M$x0 ${y + e.eh * 0.5} C${x0 + s * 1.2} ${y - e.eh * arch * 1.5} ${x1 - s * 1.2} ${y - e.eh * arch * 1.45} $x1 ${y + e.eh * 0.42}'), lift: 1.4);
    pen.taper(curve, w0: thick * sc, w1: thick * 0.7 * sc, bulge: 0.45);
    // lower cheek fold (cheeks pushed up by the laugh)
    final fold = h.path(svg('M${xm - s * e.ew * .45} ${y + e.eh * 1.05} C$xm ${y + e.eh * 1.4} ${xm + s * e.ew * .5} ${y + e.eh * 1.3} ${xm + s * e.ew * 0.75} ${y + e.eh * 0.95}'), lift: 1.4);
    pen.taper(fold, w0: 1.2 * sc, w1: 0.2 * sc, color: withA(Style.ink, .3));
  }
}

/// Four-point sparkle.
void drawSparkle(Pen pen, Offset c, double r, {Color color = const Color(0xFFFFFFFF), double alpha = 0.9}) {
  final p = Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx + r * .12, c.dy - r * .12, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx + r * .12, c.dy + r * .12, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - r * .12, c.dy + r * .12, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx - r * .12, c.dy - r * .12, c.dx, c.dy - r)
    ..close();
  pen.fill(p, withA(color, alpha));
}
