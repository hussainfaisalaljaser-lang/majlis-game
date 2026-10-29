// Nose: a 3D-positioned cartoon nose (bridge line, round tip ball, nostril wing).
// The tip and bridge are projected through the head so the nose sticks out of the
// face outline when the head turns; the drawing itself is screen-space circles
// and splines, so it stays round and clean like the video's noses.
import 'dart:math' as math;
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
    this.bulb = 0.8,
    this.hook = 0.0,
    this.top = -5.0,
    this.leadSide,
    this.nostrils = true,
    this.line = 1.0,
  });

  /// y of the tip centre, half-width of the nostril wings, bridge half-width.
  final double len, width, bridge;

  /// How far the tip sticks out of the face (units).
  final double proj;

  /// Tip ball size multiplier; hook = how far the tip droops/hooks downward.
  final double bulb, hook;

  /// y where the bridge starts (between the eyes).
  final double top;

  /// Which side the bridge outline is drawn on when the head is frontal (+1 right, -1 left).
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
  final turned = smoothstep(0.0, 0.7, h.absYaw);
  Offset p3(double x, double y, double extra) => h.pt(x, y, z: h.surfaceZ(x, y) * 0.96 + extra);

  final ty = n.len + n.hook * 0.5;
  final r = 4.9 * n.bulb * sc;
  final c = p3(0, ty, n.proj);
  final top = p3(0, n.top, 0.6);
  final mid = p3(lead * n.bridge * (0.6 + 0.4 * turned), n.top + (n.len - n.top) * 0.55, n.proj * 0.6);
  final midTrail = p3(-lead * n.bridge, n.top + (n.len - n.top) * 0.55, n.proj * 0.5);

  Offset cp(double deg, {double k = 1.0}) {
    final a = deg * math.pi / 180;
    return Offset(c.dx + lead * r * k * math.cos(a), c.dy + r * k * math.sin(a));
  }

  // wing (ala) on the trailing side
  final wingW = n.width / 8.5;
  final wing = <Offset>[
    cp(96, k: 1.02),
    Offset(c.dx - lead * r * (0.9 + 0.5 * wingW), c.dy + r * 0.98),
    Offset(c.dx - lead * r * (1.75 + 0.55 * wingW), c.dy + r * 0.55),
    Offset(c.dx - lead * r * (2.15 + 0.6 * wingW), c.dy - r * 0.25),
    Offset(c.dx - lead * r * (1.7 + 0.5 * wingW), c.dy - r * 1.1),
  ];

  // lead outline: bridge down to the tip ball, round the ball
  final leadLine = spline([top, mid, cp(-128), cp(-70), cp(-15), cp(40), cp(96)], tension: .95);
  // volume fill
  final fillPts = <Offset>[top, mid, cp(-128), cp(-70), cp(-15), cp(40), ...wing, midTrail];
  final volume = spline(fillPts, closed: true, tension: .95);
  pen.fill(volume, skin.base);

  // shade on the trailing side of the nose and under the tip
  pen.inside(volume, (p) {
    final shade = spline([top, midTrail, wing.last, wing[2], wing.first, cp(90), cp(30, k: .2)], closed: true, tension: .9);
    p.fill(shade, withA(skin.shade, .78));
  });
  // light dot on the tip
  pen.glow(cp(-70, k: .45), 2.9 * sc * n.bulb, 2.2 * sc * n.bulb, skin.hi, alpha: .95);

  final w1 = Style.lineThin * 1.3 * n.line * sc;
  final w2 = Style.lineThin * 1.05 * n.line * sc;
  // bridge (thin at the top) + ball
  final up = spline([top, mid, cp(-128)], tension: .95);
  pen.line(up, w: w1 * 0.7, color: withA(Style.ink, 0.35 + 0.6 * turned));
  pen.line(spline([cp(-128), cp(-70), cp(-15), cp(40), cp(96)], tension: .95), w: w1, color: Style.ink);
  // wing + underside
  pen.line(spline(wing, tension: .9), w: w2, color: Style.ink);
  // frontal view: the lead side wing as well
  if (turned < 0.9) {
    final wingL = <Offset>[
      cp(84, k: 1.02),
      Offset(c.dx + lead * r * (0.9 + 0.5 * wingW), c.dy + r * 0.98),
      Offset(c.dx + lead * r * (1.75 + 0.55 * wingW), c.dy + r * 0.55),
      Offset(c.dx + lead * r * (2.15 + 0.6 * wingW), c.dy - r * 0.25),
      Offset(c.dx + lead * r * (1.7 + 0.5 * wingW), c.dy - r * 1.1),
    ];
    pen.line(spline(wingL, tension: .9), w: w2, color: withA(Style.ink, 1 - turned));
  }
  if (n.nostrils) {
    final nc = Offset(c.dx - lead * r * 0.95, c.dy + r * 0.62);
    pen.glow(nc, 2.4 * sc, 1.6 * sc, skin.deep, alpha: 0.95);
  }
  // keep the unused leadLine referenced (kept for clarity of the outline definition)
  assert(leadLine.getBounds().width >= 0);
}
