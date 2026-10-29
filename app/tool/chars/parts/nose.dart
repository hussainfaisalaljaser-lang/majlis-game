// Nose: a small 3D shape projected through the head, so it sticks out of the
// face outline when the head turns. Drawn with selective outlines like in the
// video: the lead-side edge + rounded tip + underside; shade on the trailing side.
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';

class NoseSpec {
  const NoseSpec({
    this.len = 23.0,
    this.width = 8.5,
    this.bridge = 3.4,
    this.proj = 13.0,
    this.bulb = 1.0,
    this.hook = 0.0,
    this.top = -5.0,
    this.leadSide,
    this.nostrils = true,
    this.line = 1.0,
  });

  /// y of the tip, half-width of the nostril wings, bridge half-width.
  final double len, width, bridge;

  /// How far the tip sticks out of the face (units).
  final double proj;

  /// Tip bulb size multiplier; hook = downward hooking of the tip.
  final double bulb, hook;

  /// y where the bridge starts (between the eyes).
  final double top;

  /// Which side the lead edge is drawn on when the head is frontal (+1 right, -1 left).
  final int? leadSide;
  final bool nostrils;

  /// Outline weight multiplier.
  final double line;

  NoseSpec copyWith({double? len, double? width, double? bridge, double? proj, double? bulb, double? hook, double? top, int? leadSide, bool? nostrils, double? line}) => NoseSpec(
    len: len ?? this.len,
    width: width ?? this.width,
    bridge: bridge ?? this.bridge,
    proj: proj ?? this.proj,
    bulb: bulb ?? this.bulb,
    hook: hook ?? this.hook,
    top: top ?? this.top,
    leadSide: leadSide ?? this.leadSide,
    nostrils: nostrils ?? this.nostrils,
    line: line ?? this.line,
  );
}

void drawNose(Pen pen, Head h, NoseSpec n, Skin skin) {
  final lead = h.side != 0 ? h.side : (n.leadSide ?? 1);
  final sc = h.scale;
  final turned = h.absYaw.clamp(0.0, 1.0);
  Offset p3(double x, double y, double extra) => h.pt(x, y, z: h.surfaceZ(x, y) * 0.96 + extra);

  final ty = n.len;
  final rt = 4.6 * n.bulb; // tip radius
  final w = n.width;
  final pr = n.proj;

  final top = p3(0, n.top, 0.6);
  final bridgeLead = p3(lead * n.bridge, n.top + (ty - n.top) * 0.5, pr * 0.58);
  final bridgeTrail = p3(-lead * n.bridge, n.top + (ty - n.top) * 0.5, pr * 0.52);
  final tipLead = p3(lead * rt, ty - 0.5 + n.hook * 0.2, pr);
  final tipBot = p3(lead * rt * 0.25, ty + rt * 0.95 + n.hook, pr * 0.97);
  final tipTrail = p3(-lead * rt, ty - 0.2 + n.hook * 0.2, pr * 0.95);
  final tipTop = p3(0, ty - rt * 0.9, pr * 0.92);
  final alaLead = p3(lead * w, ty - 1.8, pr * 0.38);
  final alaTrail = p3(-lead * w, ty - 2.0, pr * 0.36);
  final col = p3(0, ty + rt * 0.75, pr * 0.62);
  final baseLead = p3(lead * w * 0.75, ty + rt * 0.45, pr * 0.5);
  final baseTrail = p3(-lead * w * 0.75, ty + rt * 0.45, pr * 0.48);

  // volume of the nose (skin fill so it reads over the cheek / outline)
  final body = spline([top, bridgeLead, alaLead, baseLead, tipBot, col, baseTrail, alaTrail, bridgeTrail], closed: true, tension: .9);
  final tip = spline([tipTop, tipLead, tipBot, tipTrail], closed: true, tension: 1.0);
  pen.fill(body, skin.base);
  pen.fill(tip, skin.base);

  // shade on the trailing side + under the tip
  pen.inside(Path.combine(PathOperation.union, body, tip), (p) {
    final shadeSide = spline([top, bridgeTrail, alaTrail, baseTrail, col, tipBot, tipTrail, tipTop], closed: true, tension: .85);
    p.fill(shadeSide, withA(skin.shade, .8));
  });
  // tip highlight
  pen.glow(Offset(tipTop.dx + lead * rt * .15 * sc, tipTop.dy + 1.6 * sc), 3.0 * sc * n.bulb, 2.2 * sc * n.bulb, skin.hi, alpha: .95);

  final w1 = Style.lineThin * 1.25 * n.line * sc;
  final w2 = Style.lineThin * 1.0 * n.line * sc;

  // lead edge: thin at the top, heavier round the tip
  pen.line(spline([top, bridgeLead], tension: .9), w: w1 * 0.55, color: withA(Style.ink, turned > 0.15 ? .95 : .5));
  pen.line(spline([bridgeLead, alaLead, tipLead, tipBot], tension: .9), w: w1, color: Style.ink);
  // underside / columella and nostril wing
  pen.line(spline([tipBot, col, baseTrail, alaTrail], tension: .8), w: w2, color: Style.ink);
  if (turned < 0.5) {
    // frontal: nostril wings on both sides
    pen.line(spline([alaLead, baseLead, tipBot], tension: .8), w: w2 * 0.9, color: Style.ink);
    pen.line(spline([bridgeTrail, alaTrail], tension: .8), w: w2 * 0.6, color: withA(Style.ink, .6));
  }
  // nostril
  if (n.nostrils) {
    final nc = Offset((baseTrail.dx + col.dx) / 2, (baseTrail.dy + col.dy) / 2 - 0.4 * sc);
    pen.glow(nc, 2.2 * sc, 1.5 * sc, skin.deep, alpha: 0.95);
  }
}
