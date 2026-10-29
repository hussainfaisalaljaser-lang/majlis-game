// Glasses: round frames, sunglasses, aviators. Positioned from the EyeSpec.
import 'dart:ui';

import '../core/head.dart';
import '../core/pen.dart';
import 'eyes.dart';

enum GlassesKind { round, sun, aviator, square }

class GlassesSpec {
  const GlassesSpec({
    this.kind = GlassesKind.round,
    this.frame = const Color(0xFF241A20),
    this.lens = const Color(0xFFBFD8E8),
    this.lensAlpha = 0.16,
    this.thick = 3.6,
    this.size = 1.0,
  });

  final GlassesKind kind;
  final Color frame;
  final Color lens;
  final double lensAlpha;
  final double thick;
  final double size;
}

void drawGlasses(Pen pen, Head h, GlassesSpec g, EyeSpec eyes) {
  final sc = h.scale;
  const lift = 5.5;
  final lensPaths = <Path>[];
  for (final side in const [-1, 1]) {
    final e = (side < 0 ? eyes.left : eyes.right) ?? eyes;
    final cx = side * e.gap, cy = e.y;
    Path p;
    switch (g.kind) {
      case GlassesKind.round:
        final r = (e.ew + 5.4) * g.size;
        p = circle(cx, cy, r);
      case GlassesKind.square:
        p = svg('M${cx - 15 * g.size} ${cy - 10 * g.size} L${cx + 15 * g.size} ${cy - 10 * g.size} L${cx + 15 * g.size} ${cy + 8 * g.size} Q${cx} ${cy + 13 * g.size} ${cx - 15 * g.size} ${cy + 8 * g.size} Z');
      case GlassesKind.sun:
        final w = (e.ew + 6) * g.size;
        p = svg('M${cx - w} ${cy - 8 * g.size} Q${cx} ${cy - 11 * g.size} ${cx + w} ${cy - 8 * g.size} L${cx + w - 1} ${cy + 4 * g.size} Q${cx + w - 3} ${cy + 12 * g.size} ${cx} ${cy + 12 * g.size} Q${cx - w + 3} ${cy + 12 * g.size} ${cx - w + 1} ${cy + 4 * g.size} Z');
      case GlassesKind.aviator:
        final w = (e.ew + 6) * g.size;
        p = svg('M${cx - w} ${cy - 8 * g.size} Q${cx} ${cy - 11 * g.size} ${cx + w} ${cy - 8 * g.size} Q${cx + w + 1} ${cy + 8 * g.size} ${cx + 2} ${cy + 13 * g.size} Q${cx - w - 1} ${cy + 8 * g.size} ${cx - w} ${cy - 8 * g.size} Z');
    }
    lensPaths.add(h.path(p, lift: lift));
  }
  final dark = g.kind == GlassesKind.sun || g.kind == GlassesKind.aviator;
  final fw = g.thick * sc;
  // temples (arms) towards the ears + bridge
  final bridge = h.path(svg('M-6 -2 Q0 -6 6 -2'), lift: lift);
  pen.line(bridge, w: fw * 0.85, color: g.frame);
  for (final s in const [-1, 1]) {
    final e = (s < 0 ? eyes.left : eyes.right) ?? eyes;
    final x0 = s * (e.gap + e.ew + 4.6);
    final arm = Path()
      ..moveTo(x0, e.y - 1)
      ..lineTo(s * (h.shape.wAt(e.y) + 1), e.y + 1);
    final vis = h.depthOf(s * (h.shape.wAt(e.y) + 1), e.y, z: -2) > 0;
    if (vis || h.absYaw < 0.12) pen.line(h.path(arm, lift: lift - 1.2), w: fw * 0.8, color: g.frame);
  }
  for (final lp in lensPaths) {
    pen.fill(lp, dark ? withA(g.frame, .92) : withA(g.lens, g.lensAlpha));
    if (!dark) {
      pen.inside(lp, (q) {
        final b = lp.getBounds();
        final streak = Path()
          ..moveTo(b.left + b.width * .22, b.top + b.height * .78)
          ..lineTo(b.left + b.width * .52, b.top + b.height * .18);
        q.line(streak, w: 2.3 * sc, color: withA(const Color(0xFFFFFFFF), .55));
        final streak2 = Path()
          ..moveTo(b.left + b.width * .6, b.top + b.height * .82)
          ..lineTo(b.left + b.width * .74, b.top + b.height * .5);
        q.line(streak2, w: 1.3 * sc, color: withA(const Color(0xFFFFFFFF), .4));
      });
    } else {
      pen.inside(lp, (q) {
        final b = lp.getBounds();
        q.line(
          Path()
            ..moveTo(b.left + b.width * .18, b.top + b.height * .62)
            ..lineTo(b.left + b.width * .46, b.top + b.height * .2),
          w: 2.6 * sc,
          color: withA(const Color(0xFFFFFFFF), .42),
        );
      });
    }
    pen.line(lp, w: fw, color: g.frame);
  }
}
