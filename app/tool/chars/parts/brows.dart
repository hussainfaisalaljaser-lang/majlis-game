// Eyebrows: thick tapered shapes. Expression comes from the inner/outer end
// offsets (angry = inner down, worried = inner up, smug = one brow raised).
import 'dart:math' as math;
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';
import 'eyes.dart';

class BrowSpec {
  const BrowSpec({
    this.lift = 7.0,
    this.inner = 0.0,
    this.outer = 0.0,
    this.arch = 2.5,
    this.thick = 5.0,
    this.len = 1.0,
    this.taper = 0.5,
    this.shiftX = 0.0,
    this.color = HairColor.black,
    this.left,
    this.right,
  });

  /// Distance between the top of the eye and the brow centre line.
  final double lift;

  /// Vertical offset of the inner / outer end relative to the middle (negative = up).
  final double inner, outer;

  /// Upward bulge of the middle.
  final double arch;
  final double thick;

  /// Length multiplier and how thin the outer end gets (1 = same thickness).
  final double len, taper;

  /// Horizontal shift towards the outside (+) or the centre (-).
  final double shiftX;
  final HairColor color;
  final BrowSpec? left, right;

  BrowSpec copyWith({
    double? lift,
    double? inner,
    double? outer,
    double? arch,
    double? thick,
    double? len,
    double? taper,
    double? shiftX,
    HairColor? color,
    BrowSpec? left,
    BrowSpec? right,
  }) => BrowSpec(
    lift: lift ?? this.lift,
    inner: inner ?? this.inner,
    outer: outer ?? this.outer,
    arch: arch ?? this.arch,
    thick: thick ?? this.thick,
    len: len ?? this.len,
    taper: taper ?? this.taper,
    shiftX: shiftX ?? this.shiftX,
    color: color ?? this.color,
    left: left ?? this.left,
    right: right ?? this.right,
  );
}

void drawBrows(Pen pen, Head h, BrowSpec spec, EyeSpec eyes) {
  for (final side in const [-1, 1]) {
    final b = (side < 0 ? spec.left : spec.right) ?? spec;
    final e = eyes.left == null && eyes.right == null ? eyes : (side < 0 ? eyes.left : eyes.right) ?? eyes;
    final base = e.y - e.eh - b.lift;
    final xi = e.gap - e.ew * 0.85 * b.len + b.shiftX * -1; // inner end (towards centre)
    final xo = e.gap + e.ew * 1.2 * b.len + b.shiftX; // outer end
    final p0 = Offset(xi, base + b.inner);
    final p2 = Offset(xo, base + b.outer);
    final mid = Offset((xi + xo) / 2, base - b.arch * 2 + (b.inner + b.outer) / 2);
    final top = <Offset>[], bot = <Offset>[];
    const n = 14;
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      // quadratic point + derivative
      final pt = Offset(
        (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * mid.dx + t * t * p2.dx,
        (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * mid.dy + t * t * p2.dy,
      );
      final dv = Offset(2 * (1 - t) * (mid.dx - p0.dx) + 2 * t * (p2.dx - mid.dx), 2 * (1 - t) * (mid.dy - p0.dy) + 2 * t * (p2.dy - mid.dy));
      final len = math.max(0.001, dv.distance);
      final nrm = Offset(-dv.dy / len, dv.dx / len); // points downward-ish
      final th = b.thick * (t < .35 ? lerpD(.82, 1.0, t / .35) : lerpD(1.0, b.taper, math.pow((t - .35) / .65, 1.2).toDouble()));
      top.add(pt - nrm * (th * 0.55));
      bot.add(pt + nrm * (th * 0.45));
    }
    // mirror x for the viewer-left brow
    Offset fx(Offset o) => Offset(o.dx * side, o.dy);
    final pts = <Offset>[...top.map(fx), ...bot.reversed.map(fx)];
    final local = spline(pts, closed: true, tension: .9);
    final path = h.path(local, lift: 3.0);
    pen.fill(path, b.color.base);
    pen.line(path, w: 0.9 * h.scale, color: withA(Style.ink, .85));
    // soft highlight on the top edge
    final hiLine = spline(top.map(fx).toList().sublist(2, n - 3));
    pen.line(h.path(hiLine, lift: 3.0), w: 0.7 * h.scale, color: withA(b.color.hi, .55));
  }
}
