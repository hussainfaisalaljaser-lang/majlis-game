// Six reference characters drawn with the kit (the quality bar for the rest).
import 'dart:ui';

import '../kit.dart';

final List<CharSpec> refChars = [
  // ── youth: smug youth in a pink-white ghutra, head turned to the left ──
  CharSpec(
    id: 'youth',
    bg: BgStyle.orange,
    skin: Skin.tan,
    head: const HeadSpec(x: 100, y: 100, scale: 1.0, yaw: -1.0, shape: FaceShape.pointed, roll: 0.06),
    expr: const Expr(
      eyes: EyeSpec(ew: 14, eh: 12.6, gap: 21.5, lookX: -0.92, irisR: 0.47, pupilR: 0.62, lidTop: 0.03, iris: Color(0xFF4A2F1C), lid: 3.2),
      brows: BrowSpec(lift: 6.2, inner: -1.5, outer: 0.5, arch: 3.6, thick: 7.6),
      mouth: MouthSpec(kind: MouthKind.smirk, side: 1, w: 16, y: 45),
    ),
    nose: const NoseSpec(len: 27, proj: 17, width: 10, bulb: 1.45, bridge: 4),
    headwear: const Ghutra(cloth: Cloth.pinkWhite, hem: -34, hemTilt: 0.05, agalTilt: -0.2, agalSag: 9, top: -80, agalY: -60, swept: true),
    body: const Thobe(color: Cloth.sand),
  ),

  // ── rose: worried hijab girl, purple ──
  CharSpec(
    id: 'rose',
    bg: BgStyle.purple,
    skin: Skin.light,
    head: const HeadSpec(x: 101, y: 92, scale: 0.97, yaw: 0.3, shape: FaceShape.round, roll: -0.04),
    expr: const Expr(
      eyes: EyeSpec(ew: 12.5, eh: 12, gap: 18.5, lookX: 0.95, lookY: -0.12, irisR: 0.66, pupilR: 0.55, lidSlant: -0.22, iris: Color(0xFF4A3020)),
      brows: BrowSpec(lift: 6.0, inner: -3.2, outer: 1.5, arch: 2.6, thick: 6.4),
      mouth: MouthSpec(kind: MouthKind.open, w: 11, y: 41, amount: 0.85),
    ),
    nose: const NoseSpec(len: 20, proj: 10, width: 6.2, bulb: 0.9, bridge: 2.6),
    headwear: const Hijab(cloth: Tones(Color(0xFF5E2F72), Color(0xFF3E1B53), Color(0xFF83509A)), flap: true),
    body: const Garment(color: Tones(Color(0xFF4A2C5E), Color(0xFF2F1840), Color(0xFF6B4382))),
  ),

  // ── jasmine: round glasses, teal hijab over a white cap, green ──
  CharSpec(
    id: 'jasmine',
    bg: BgStyle.green,
    skin: Skin.fair,
    head: const HeadSpec(x: 100, y: 92, scale: 0.97, yaw: 0.2, shape: FaceShape.round, roll: -0.03),
    expr: const Expr(
      eyes: EyeSpec(ew: 10.5, eh: 9.8, gap: 19.5, lookX: 0.8, lookY: 0.05, irisR: 0.62, pupilR: 0.5, lidSlant: -0.25, iris: Color(0xFF3C5A76)),
      brows: BrowSpec(lift: 9, inner: -5.0, outer: 2.0, arch: 1.5, thick: 5.0),
      mouth: MouthSpec(kind: MouthKind.open, w: 11, y: 41, amount: 0.8),
    ),
    nose: const NoseSpec(len: 18, proj: 8, width: 6, bulb: 0.8, bridge: 2.4),
    glasses: const GlassesSpec(kind: GlassesKind.round, thick: 3.0),
    headwear: const Hijab(
      cloth: Tones(Color(0xFF3F8068), Color(0xFF2A5B4B), Color(0xFF63A68A)),
      underCap: Cloth.white,
      capEdge: -18,
      flap: true,
    ),
    body: const Garment(color: Tones(Color(0xFF2F3D38), Color(0xFF1D2723), Color(0xFF4D5D56))),
  ),

  // ── falcon: bearded man in a white ghutra, thinking ──
  CharSpec(
    id: 'falcon',
    bg: BgStyle.blue,
    skin: Skin.light,
    head: const HeadSpec(x: 96, y: 100, scale: 0.93, yaw: 0.7, shape: FaceShape.square),
    expr: const Expr(
      eyes: EyeSpec(ew: 11.5, eh: 9.4, gap: 20, lookX: 0.8, lookY: -0.2, irisR: 0.55, pupilR: 0.55, lidTop: 0.12, lidSlant: 0.35, lidBottom: 0.1, iris: Color(0xFF4A3524)),
      brows: BrowSpec(lift: 5.5, inner: 3.0, outer: -2.0, arch: 1.8, thick: 7.0),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 10, y: 43),
    ),
    nose: const NoseSpec(len: 23, proj: 14, width: 8.5, bulb: 1.1),
    beard: const BeardSpec(style: BeardStyle.short, color: HairColor.inkBlack, mouthY: 43, mouthW: 9, mouthH: 3.2),
    headwear: const Ghutra(hem: -34, agalTilt: 0, agalSag: 6),
    body: const Thobe(),
    front: (pen, h) => drawChinHand(pen, h, Skin.light, at: const Offset(18, 62), rot: -0.1),
  ),

  // ── masked: face covered, fierce eyes ──
  CharSpec(
    id: 'masked',
    bg: BgStyle.slate,
    skin: Skin.tan,
    head: const HeadSpec(x: 100, y: 96, scale: 0.98, yaw: 0, shape: FaceShape.square),
    expr: Expr.angry(),
    nose: const NoseSpec(len: 23, proj: 12, width: 8),
    headwear: HeadwearStack([
      FaceVeil(cloth: Cloth.white, check: Color(0xFFC8262E)),
      const Ghutra(check: Color(0xFFC8262E), hem: -26, agalTilt: 0),
    ]),
    body: const Thobe(color: Cloth.charcoal),
  ),

  // ── sheikh: old, wise, warm ──
  CharSpec(
    id: 'sheikh',
    bg: BgStyle.gold,
    skin: Skin.fair,
    head: const HeadSpec(x: 100, y: 96, scale: 0.98, yaw: 0.25, shape: FaceShape.lean),
    expr: Expr(
      eyes: const EyeSpec(ew: 10.5, eh: 8.4, gap: 20, lookX: 0.2, lidTop: 0.12, lidBottom: 0.3, crease: true, iris: Color(0xFF6A4A30)),
      brows: const BrowSpec(lift: 6.5, inner: -1.5, outer: 1.5, arch: 3, thick: 6.5, color: HairColor.grey),
      mouth: const MouthSpec(kind: MouthKind.smile, w: 11, y: 44, amount: 0.7),
    ),
    nose: const NoseSpec(len: 23, proj: 13, width: 9, bulb: 1.2),
    beard: const BeardSpec(style: BeardStyle.full, color: HairColor.white, mouthY: 44, mouthW: 9, mouthH: 3.4, length: 6),
    headwear: const Ghutra(hem: -34),
    body: const Thobe(color: Cloth.cream),
  ),
];
