// Character pack 1 (worker A): cool scholar desert hawk merchant pearl night amber sky shadow.
// Each one keeps the identity/colours of its old flat avatar but has its own pose,
// expression and eye direction like the video's cast.
import '../kit.dart';
import '../parts/a_niqab.dart';
import '../parts/a_props.dart';

// custom backgrounds (same family as the BgStyle presets)
const _bgNavy = BgStyle(Color(0xFF3558C4), Color(0xFF111F5C), glow: Color(0x4470A0FF));
const _bgAmber = BgStyle(Color(0xFFE79A1E), Color(0xFFA85A08), glow: Color(0x55FFD680));
const _bgDusk = BgStyle(Color(0xFF6D48B8), Color(0xFF28155E), glow: Color(0x44B89AFF));

const _pearl = Tones(Color(0xFFF8F0F2), Color(0xFFCDBBCF), Color(0xFFFFFFFF));
const _amberBead = Tones(Color(0xFFEDA220), Color(0xFFA9620C), Color(0xFFFFD27A));
const _cloakBrown = Tones(Color(0xFF4A3A33), Color(0xFF2E221E), Color(0xFF6E584E));

final List<CharSpec> pack1 = [
  // ── cool: grinning in sunglasses, chin up, thumbs-up, white ghutra, green ──
  CharSpec(
    id: 'cool',
    bg: BgStyle.green,
    skin: Skin.tan,
    head: const HeadSpec(x: 98, y: 98, scale: 0.98, yaw: 0.65, pitch: -0.18, roll: -0.05, shape: FaceShape.oval),
    expr: const Expr(
      eyes: EyeSpec(ew: 11, eh: 10, gap: 20.5, lookX: 0.5, irisR: 0.5, sclera: Color(0xFF2A2430), iris: Color(0xFF241A20)),
      brows: BrowSpec(lift: 8, inner: 1.0, outer: 0.5, arch: 3.2, thick: 6.4, left: BrowSpec(lift: 6.6, inner: 1.6, outer: 1.2, arch: 3.0, thick: 6.4), right: BrowSpec(lift: 10.5, inner: -2.5, outer: 0, arch: 3.6, thick: 6.4)),
      mouth: MouthSpec(kind: MouthKind.grin, w: 11.5, y: 45, amount: 0.65),
    ),
    nose: const NoseSpec(len: 22, proj: 17, width: 9, bulb: 1.0),
    beard: const BeardSpec(style: BeardStyle.mustache, color: HairColor.inkBlack, mouthY: 45, mouthW: 12, mouthH: 5, mustacheSize: 0.88),
    glasses: const GlassesSpec(kind: GlassesKind.sun, thick: 3.4, size: 0.93),
    headwear: const Ghutra(swept: true, hem: -34, agalTilt: 0.1, agalSag: 7),
    body: const Thobe(),
    front: (pen, h) {
      drawFist(pen, Skin.tan, FistPose.thumbsUp, at: const Offset(160, 143), rot: 0.14, size: 0.68);
      drawSparkle(pen, const Offset(124, 139), 4.6);
      drawSparkle(pen, const Offset(131, 146), 2.4);
    },
  ),

  // ── scholar: round glasses, black beard, bisht, "eureka" finger up ──
  CharSpec(
    id: 'scholar',
    bg: BgStyle.indigo,
    skin: Skin.fair,
    head: const HeadSpec(x: 96, y: 100, scale: 0.93, yaw: -0.5, roll: 0.04, shape: FaceShape.square),
    expr: const Expr(
      eyes: EyeSpec(ew: 10.5, eh: 10, gap: 20, lookX: -0.7, lookY: -0.65, irisR: 0.5, pupilR: 0.62, iris: Color(0xFF3B5A7A)),
      brows: BrowSpec(lift: 8.5, inner: -1.5, outer: 1.5, arch: 3.8, thick: 6.2, left: BrowSpec(lift: 9.5, inner: -3.2, outer: 0.5, arch: 4.0, thick: 6.2), right: BrowSpec(lift: 7.0, inner: 0.5, outer: 1.5, arch: 3.0, thick: 6.2)),
      mouth: MouthSpec(kind: MouthKind.smile, w: 8, y: 45, amount: 0.5),
    ),
    nose: const NoseSpec(len: 24, proj: 15, width: 8.5, bulb: 0.9),
    beard: const BeardSpec(style: BeardStyle.full, color: HairColor.inkBlack, mouthY: 45, mouthW: 8, mouthH: 3.4, length: 2),
    glasses: const GlassesSpec(kind: GlassesKind.round, thick: 3.2),
    headwear: const Ghutra(hem: -35, agalSag: 6),
    body: const Bisht(cloak: _cloakBrown),
    front: (pen, h) => drawFist(pen, Skin.fair, FistPose.pointUp, at: const Offset(160, 150), rot: -0.2, size: 0.7, sleeve: _cloakBrown),
  ),

  // ── desert: laughing out loud, deep tan skin, red shemagh, full beard ──
  CharSpec(
    id: 'desert',
    bg: BgStyle.orange,
    skin: Skin.deepTone,
    head: const HeadSpec(x: 100, y: 99, scale: 0.98, yaw: 0.4, pitch: -0.1, roll: 0.07, shape: FaceShape.square),
    expr: const Expr(
      eyes: EyeSpec(ew: 11.5, eh: 9.6, gap: 20.5, open: 0),
      brows: BrowSpec(lift: 9, inner: -2.5, outer: 1.4, arch: 4, thick: 7),
      mouth: MouthSpec(kind: MouthKind.laugh, w: 12, y: 45, amount: 0.95),
    ),
    nose: const NoseSpec(len: 23, proj: 15, width: 10, bulb: 1.1),
    beard: const BeardSpec(style: BeardStyle.short, color: HairColor.inkBlack, mouthY: 48, mouthW: 12, mouthH: 9, length: 3, cheek: -6),
    headwear: const Ghutra(check: Color(0xFFC8262E), hem: -34, agalTilt: -0.05, agalSag: 6),
    body: const Thobe(color: Cloth.cream),
    front: (pen, h) => drawLaughEyes(pen, h, const EyeSpec(ew: 11.5, eh: 9.6, gap: 20.5), thick: 4.4),
  ),

  // ── hawk: sharp, narrow-eyed predator look, hooked nose, thick mustache ──
  CharSpec(
    id: 'hawk',
    bg: BgStyle.red,
    skin: Skin.brown,
    head: const HeadSpec(x: 100, y: 99, scale: 0.98, yaw: -0.8, roll: -0.03, shape: FaceShape.lean),
    expr: const Expr(
      eyes: EyeSpec(ew: 11, eh: 8.6, gap: 20, lookX: -0.9, lookY: 0.05, irisR: 0.55, pupilR: 0.55, lidTop: 0.24, lidSlant: 0.5, iris: Color(0xFF5A3A12)),
      brows: BrowSpec(lift: 4.8, inner: 6.0, outer: -3.4, arch: 0.8, thick: 7.4, taper: 0.7),
      mouth: MouthSpec(kind: MouthKind.smirk, side: -1, w: 10, y: 45, amount: 0.6),
    ),
    nose: const NoseSpec(len: 20, proj: 24, width: 8.5, bulb: 1.2, hook: 3.4, bridge: 3.6),
    beard: const BeardSpec(style: BeardStyle.mustache, color: HairColor.inkBlack, mouthY: 45, mouthW: 10, mouthH: 3, mustacheSize: 0.92),
    headwear: const Ghutra(check: Color(0xFFC8262E), swept: true, hem: -33, agalTilt: -0.1, agalSag: 7),
    body: const Thobe(color: Cloth.charcoal),
  ),

  // ── merchant: big salesman grin, round glasses, grey-streaked beard, coin pinched up ──
  CharSpec(
    id: 'merchant',
    bg: BgStyle.teal,
    skin: Skin.light,
    head: const HeadSpec(x: 104, y: 99, scale: 0.94, yaw: 0.3, roll: -0.06, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 10, eh: 9.6, gap: 20.5, lookX: -0.7, lookY: -0.4, irisR: 0.55, lidBottom: 0.3, iris: Color(0xFF3A2416)),
      brows: BrowSpec(lift: 9.5, inner: -2.0, outer: 1.6, arch: 4.0, thick: 6.6, left: BrowSpec(lift: 9, inner: -2.5, outer: 1.2, arch: 4.0, thick: 6.6), right: BrowSpec(lift: 8, inner: 0.5, outer: 2.0, arch: 3.0, thick: 6.6)),
      mouth: MouthSpec(kind: MouthKind.grin, w: 12.5, y: 45, amount: 1.0),
    ),
    nose: const NoseSpec(len: 23, proj: 13, width: 10, bulb: 1.2),
    beard: const BeardSpec(style: BeardStyle.short, color: HairColor.saltPepper, mouthY: 46, mouthW: 11.5, mouthH: 7, length: 2),
    glasses: const GlassesSpec(kind: GlassesKind.round, thick: 3.0, size: 0.94),
    headwear: const Ghutra(check: Color(0xFFC8262E), hem: -34, agalSag: 6),
    body: const Thobe(color: Cloth.cream),
    front: (pen, h) => drawFist(pen, Skin.light, FistPose.coinPinch, at: const Offset(44, 150), rot: -0.1, size: 0.66, mirror: true, sleeve: Cloth.cream),
  ),

  // ── pearl: shy giggle, glance away, dark plum hijab, pearl necklace, magenta ──
  CharSpec(
    id: 'pearl',
    bg: BgStyle.magenta,
    skin: Skin.fair,
    head: const HeadSpec(x: 100, y: 95, scale: 0.92, yaw: -0.3, roll: 0.05, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 12.5, eh: 11.4, gap: 19, lookX: -0.8, lookY: 0.25, irisR: 0.56, pupilR: 0.7, lidBottom: 0.15, lashes: true, iris: Color(0xFF4B2E24)),
      brows: BrowSpec(lift: 8.0, inner: -1.8, outer: 1.6, arch: 3.0, thick: 5.2),
      mouth: MouthSpec(kind: MouthKind.smile, w: 8.5, y: 41, amount: 0.8),
    ),
    nose: const NoseSpec(len: 19, proj: 9, width: 6, bulb: 0.6, bridge: 2.4),
    blush: 1.5,
    headwear: const Hijab(cloth: Tones(Color(0xFF3F2A55), Color(0xFF26163A), Color(0xFF62467D)), trim: Color(0xFFF3E4EC), flap: true, width: 1.08, top: -80),
    body: const Garment(color: Tones(Color(0xFF2B2036), Color(0xFF1A1224), Color(0xFF47395A))),
    front: (pen, h) {
      drawBeads(pen, necklaceArc(h, half: 27, top: -9, dy: 21), 11, 3.3, _pearl, rEnd: 0.8);
    },
  ),

  // ── night: calm confident woman in sunglasses, navy hijab, moon pin ──
  CharSpec(
    id: 'night',
    bg: _bgNavy,
    skin: Skin.brown,
    head: const HeadSpec(x: 100, y: 95, scale: 0.92, yaw: 0.4, roll: 0.04, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 11, eh: 10, gap: 19, lookX: 0.6, irisR: 0.5, sclera: Color(0xFF2A2430), iris: Color(0xFF241A20)),
      brows: BrowSpec(lift: 8.5, inner: 0.5, outer: 1.0, arch: 3.2, thick: 5.4, left: BrowSpec(lift: 8, inner: 1.0, outer: 1.0, arch: 3.0, thick: 5.4), right: BrowSpec(lift: 10.2, inner: -1.5, outer: 0.5, arch: 3.6, thick: 5.4)),
      mouth: MouthSpec(kind: MouthKind.smirk, side: 1, w: 9, y: 42, amount: 0.7),
    ),
    nose: const NoseSpec(len: 20, proj: 11, width: 6.8, bulb: 0.7, bridge: 2.6),
    glasses: const GlassesSpec(kind: GlassesKind.aviator, thick: 2.8),
    headwear: const Hijab(cloth: Tones(Color(0xFF233B7A), Color(0xFF15245A), Color(0xFF3A57A0)), flap: true, width: 1.22, top: -80),
    body: const Garment(color: Tones(Color(0xFF1C2447), Color(0xFF111832), Color(0xFF323C6A))),
    front: (pen, h) {
      final n = h.neckBase;
      drawMoonPin(pen, Offset(n.dx - 28 * h.scale, n.dy - 2 * h.scale), 7.5 * h.scale);
      for (final s in const [(62.0, 56.0, 3.6), (132.0, 40.0, 2.8), (148.0, 78.0, 3.2), (52.0, 110.0, 2.6), (160.0, 118.0, 2.4)]) {
        drawSparkle(pen, Offset(s.$1, s.$2), s.$3, color: const Color(0xFFFFE9A0), alpha: .85);
      }
    },
  ),

  // ── amber: warm old woman in a brown shawl-hijab, crinkly smile, amber beads ──
  CharSpec(
    id: 'amber',
    bg: _bgAmber,
    skin: Skin.tan,
    head: const HeadSpec(x: 100, y: 96, scale: 0.93, yaw: -0.2, roll: -0.05, shape: FaceShape.lean),
    expr: const Expr(
      eyes: EyeSpec(ew: 11.5, eh: 10, gap: 19.5, lookX: 0.3, lookY: -0.25, irisR: 0.52, lidTop: 0.08, lidBottom: 0.36, crease: true, iris: Color(0xFF6B4A2A)),
      brows: BrowSpec(lift: 9, inner: -3.4, outer: 1.5, arch: 3.4, thick: 5, color: HairColor.grey),
      mouth: MouthSpec(kind: MouthKind.smile, w: 11, y: 42, amount: 0.9),
    ),
    nose: const NoseSpec(len: 22, proj: 12, width: 8, bulb: 1.0, bridge: 3),
    headwear: const Hijab(cloth: Tones(Color(0xFF9A6636), Color(0xFF6F4421), Color(0xFFBC8650)), underCap: Cloth.cream, capEdge: -31, hem: -40, flap: true, width: 1.2),
    body: const Garment(color: Tones(Color(0xFF5C3A20), Color(0xFF3B2312), Color(0xFF7F5733))),
    front: (pen, h) {
      agingLines(pen, h, Skin.tan, gap: 19.5, ew: 11, mouthY: 42, forehead: false, k: 0.75);
      drawBeads(pen, necklaceArc(h, half: 27, top: -9, dy: 21), 9, 4.0, _amberBead, rEnd: 0.8);
    },
  ),

  // ── sky: wide-eyed girl gazing up, laughing, light-teal hijab, cyan ──
  CharSpec(
    id: 'sky',
    bg: BgStyle.cyan,
    skin: Skin.light,
    head: const HeadSpec(x: 100, y: 95, scale: 0.92, yaw: 0.25, pitch: -0.15, roll: -0.04, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 13, eh: 12.4, gap: 19, lookX: 0.5, lookY: -0.85, irisR: 0.5, pupilR: 0.66, lashes: true, iris: Color(0xFF3E6E8E)),
      brows: BrowSpec(lift: 10, inner: -2.0, outer: 0.5, arch: 4.0, thick: 5),
      mouth: MouthSpec(kind: MouthKind.laugh, w: 9, y: 42, amount: 0.55),
    ),
    nose: const NoseSpec(len: 19, proj: 9, width: 6, bulb: 0.6, bridge: 2.4),
    headwear: const Hijab(cloth: Tones(Color(0xFF5BBDB8), Color(0xFF3B8F8F), Color(0xFF86D8D0)), hem: -40, flap: true, width: 1.0, top: -76),
    body: const Garment(color: Tones(Color(0xFF2F5560), Color(0xFF1D3841), Color(0xFF4A7885))),
    front: (pen, h) {
      final n = h.neckBase;
      drawGemPin(pen, Offset(n.dx + 26 * h.scale, n.dy - 8 * h.scale), 5.2 * h.scale, const Tones(Color(0xFF5AB7F0), Color(0xFF2C7FC0), Color(0xFFBFE8FF)));
    },
  ),

  // ── shadow: black niqab, only the eyes show: a sly sideways stare ──
  CharSpec(
    id: 'shadow',
    bg: _bgDusk,
    skin: Skin.light,
    head: const HeadSpec(x: 100, y: 95, scale: 0.94, yaw: -0.45, roll: 0.04, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 12, eh: 9.4, gap: 19, lookX: 0.95, irisR: 0.58, pupilR: 0.55, lidTop: 0.16, lidSlant: 0.22, lashes: true, iris: Color(0xFF3F8A62)),
      brows: BrowSpec(lift: 7, inner: 1.5, outer: 0, arch: 2.8, thick: 5.4, left: BrowSpec(lift: 6, inner: 3.0, outer: -0.5, arch: 2.2, thick: 5.4), right: BrowSpec(lift: 10, inner: -2.5, outer: 0.5, arch: 3.6, thick: 5.4)),
      mouth: MouthSpec(kind: MouthKind.neutral),
    ),
    nose: const NoseSpec(len: 20, proj: 11, width: 7, bulb: 0.7),
    headwear: const Niqab(cloth: Tones(Color(0xFF28232F), Color(0xFF15111B), Color(0xFF46404F))),
    body: const Garment(color: Tones(Color(0xFF211D29), Color(0xFF110E17), Color(0xFF3B3546))),
  ),
];
