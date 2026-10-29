// Character pack 3 (worker C): the eleven ANIMATED human figures. Every spec goes through
// `rigged(...)` so the still and the rig layers come from the same painters
// (see parts/c_rig.dart). All are cut-outs (the app paints the animated background).
import '../kit.dart';
import '../parts/c_armor.dart';
import '../parts/c_gear.dart';
import '../parts/c_mystic.dart';
import '../parts/c_pilot.dart';
import '../parts/c_space.dart';
import '../parts/c_rig.dart';

const _emirBeard = HairColor(Color(0xFF8E8A92), Color(0xFF5F5B68), Color(0xFFC9C5CE));

final List<CharSpec> pack3 = _build();

List<CharSpec> _build() {
  final astro = CharSpec(
    id: 'astronaut',
    skin: Skin.light,
    head: const HeadSpec(x: 100, y: 101, scale: 0.72, yaw: 0.3, shape: FaceShape.round, roll: 0.0),
    expr: const Expr(
      eyes: EyeSpec(ew: 12.5, eh: 12, gap: 19.5, lookX: 0.8, lookY: -0.55, irisR: 0.5, pupilR: 0.62, iris: Color(0xFF3A5D8F)),
      brows: BrowSpec(lift: 9, inner: -2.5, outer: -0.5, arch: 3.6, thick: 5.8, color: HairColor.black),
      mouth: MouthSpec(kind: MouthKind.grin, w: 12, y: 43, amount: 0.9),
    ),
    nose: const NoseSpec(len: 21, proj: 11, width: 7, bulb: 0.8, bridge: 3),
    hair: const HairSpec(color: HairColor.black, sideburn: 12),
  );
  return [
  // ── emir: dignified ruler, ornate ghutra with gold agal, bisht with gold trim ──
  rigged(
    CharSpec(
      id: 'emir',
      skin: Skin.light,
      head: const HeadSpec(x: 102, y: 95, scale: 0.9, yaw: -0.5, shape: FaceShape.lean),
      expr: const Expr(
        eyes: EyeSpec(ew: 11.5, eh: 9.6, gap: 20, lookX: -0.6, lookY: -0.05, lidTop: 0.12, lidBottom: 0.12, crease: true, irisR: 0.48, iris: Color(0xFF4A3220)),
        brows: BrowSpec(lift: 6.5, inner: -0.5, outer: 1.5, arch: 3, thick: 6.4, color: _emirBeard),
        mouth: MouthSpec(kind: MouthKind.smile, w: 11, y: 44, amount: 0.55),
      ),
      nose: const NoseSpec(len: 24, proj: 14, width: 9, bulb: 1.0),
      beard: const BeardSpec(style: BeardStyle.full, color: _emirBeard, mouthY: 44, mouthW: 9, mouthH: 3.4, length: 0),
      headwear: HeadwearStack([
        const Ghutra(hem: -35, agalTones: goldT, agalTilt: -0.04, swept: false),
        CustomWear(onFront: drawOrnateGhutra),
      ]),
      body: const Bisht(),
    ),
  ),

  // ── tycoon: sunglasses, smug smirk, gold chain with a coin ──
  rigged(
    CharSpec(
      id: 'tycoon',
      skin: Skin.tan,
      head: const HeadSpec(x: 100, y: 92, scale: 0.9, yaw: -0.55, shape: FaceShape.square, roll: 0.03),
      expr: Expr(
        eyes: const EyeSpec(ew: 11.5, eh: 9.5, gap: 20, lookX: -0.8, lidTop: 0.2, lidBottom: 0.2),
        brows: Expr.smug(side: -1).brows,
        mouth: const MouthSpec(kind: MouthKind.smirk, side: -1, w: 15, y: 45, amount: 1.1),
      ),
      nose: const NoseSpec(len: 25, proj: 16, width: 9, bulb: 1.05),
      beard: const BeardSpec(style: BeardStyle.short, color: HairColor.inkBlack, mouthY: 45, mouthW: 12, mouthH: 4.2),
      glasses: const GlassesSpec(kind: GlassesKind.aviator, thick: 3.0),
      headwear: const Ghutra(hem: -36, agalTilt: 0.05, swept: true, width: 0.9, dropY: 80),
      body: const Bisht(cloak: Tones(Color(0xFF3A2416), Color(0xFF1F130B), Color(0xFF5C3D28)), trim: Color(0xFFF2C24A)),
    ),
    layers: {'chain': (pen, h) => drawGoldChain(pen, h)},
    still: ['body', 'chain', 'head'],
  ),

  // ── queen: crown over a royal-purple hijab, pearls ──
  rigged(
    CharSpec(
      id: 'queen',
      skin: Skin.fair,
      head: const HeadSpec(x: 100, y: 99, scale: 0.88, yaw: 0.22, shape: FaceShape.round, roll: -0.03),
      expr: const Expr(
        eyes: EyeSpec(ew: 12.5, eh: 11.5, gap: 19, lookX: 0.7, lookY: -0.05, irisR: 0.56, pupilR: 0.62, lashes: true, lidBottom: 0.2, iris: Color(0xFF3A2A44)),
        brows: BrowSpec(lift: 7, inner: -0.5, outer: 1.2, arch: 3.0, thick: 5.0),
        mouth: MouthSpec(kind: MouthKind.smile, w: 11, y: 42, amount: 0.9),
      ),
      nose: const NoseSpec(len: 20, proj: 10, width: 6.4, bulb: 0.7, bridge: 2.6),
      headwear: const HeadwearStack([
        Hijab(cloth: Tones(Color(0xFF6B35B8), Color(0xFF45207F), Color(0xFF9060D8)), width: 1.1),
        Crown(top: -98),
      ]),
      body: const Garment(color: Tones(Color(0xFF4A1A7A), Color(0xFF2E0F52), Color(0xFF6E3AA4))),
    ),
    layers: {'necklace': (pen, h) => drawPearlNecklace(pen, h)},
    still: ['body', 'head', 'necklace'],
  ),

  // ── lady_gold: ivory hijab, golden tiara, wink, pearls ──
  rigged(
    CharSpec(
      id: 'lady_gold',
      skin: Skin.fair,
      head: const HeadSpec(x: 100, y: 96, scale: 0.9, yaw: -0.25, shape: FaceShape.round, roll: 0.03),
      expr: const Expr(
        eyes: EyeSpec(ew: 12.5, eh: 11.5, gap: 19, lookX: -0.7, lookY: 0.05, irisR: 0.55, pupilR: 0.62, lashes: true, lidBottom: 0.15, iris: Color(0xFF4A3524)),
        brows: BrowSpec(lift: 7.5, inner: 0, outer: 1.5, arch: 3.4, thick: 4.8),
        mouth: MouthSpec(kind: MouthKind.smirk, side: -1, w: 11, y: 42, amount: 0.9),
      ),
      nose: const NoseSpec(len: 20, proj: 10, width: 6.2, bulb: 0.66, bridge: 2.6),
      headwear: const HeadwearStack([
        Hijab(cloth: Tones(Color(0xFFF3EADC), Color(0xFFC8B8AD), Color(0xFFFFFBF2)), width: 1.1),
        Tiara(),
      ]),
      body: const Garment(color: Tones(Color(0xFF4A2038), Color(0xFF2A1022), Color(0xFF6B3A55))),
    ),
    layers: {
      'wink': (pen, h) => drawWink(pen, h, const EyeSpec(ew: 12.5, eh: 11.5, gap: 19, lashes: true), Skin.fair, side: -1),
      'necklace': (pen, h) => drawPearlNecklace(pen, h),
    },
    still: ['body', 'head', 'necklace'],
  ),

  // ── knight: steel kettle helmet + mail coif, red plume, plate shoulders ──
  rigged(
    CharSpec(
      id: 'knight',
      skin: Skin.tan,
      head: const HeadSpec(x: 98, y: 94, scale: 0.87, yaw: 0.35, shape: FaceShape.square, roll: -0.02),
      expr: const Expr(
        eyes: EyeSpec(ew: 11, eh: 9.4, gap: 20, lookX: 0.75, lookY: -0.1, lidTop: 0.1, lidSlant: 0.25, irisR: 0.55, pupilR: 0.58, iris: Color(0xFF3F6B54)),
        brows: BrowSpec(lift: 6, inner: 2.5, outer: -1.5, arch: 1.8, thick: 6.8, color: HairColor.darkBrown),
        mouth: MouthSpec(kind: MouthKind.smirk, side: 1, w: 12, y: 44, amount: 0.8),
      ),
      nose: const NoseSpec(len: 24, proj: 15, width: 9, bulb: 1.0),
      beard: const BeardSpec(style: BeardStyle.full, color: HairColor.darkBrown, mouthY: 44, mouthW: 10, mouthH: 3.6, length: 2),
      headwear: const KnightHelm(),
      body: const KnightArmor(),
    ),
    layers: {'plume': (pen, h) => drawPlume(pen, h.pt(0, -80, lift: 7), scale: 0.86)},
    still: ['body', 'plume', 'head'],
  ),

  // ── pilot: leather flight cap, goggles on the cap (they drop onto the eyes), mustache ──
  rigged(
    CharSpec(
      id: 'pilot',
      skin: Skin.tan,
      head: const HeadSpec(x: 100, y: 94, scale: 0.87, yaw: 0.4, shape: FaceShape.oval, roll: 0.03),
      expr: const Expr(
        eyes: EyeSpec(ew: 12, eh: 10.8, gap: 19.5, lookX: 0.6, lookY: -0.3, irisR: 0.52, pupilR: 0.6, iris: Color(0xFF4A3524)),
        brows: BrowSpec(lift: 8, inner: -1.5, outer: 1.5, arch: 3.2, thick: 6.2, color: HairColor.darkBrown),
        mouth: MouthSpec(kind: MouthKind.grin, w: 12, y: 45, amount: 0.7),
      ),
      nose: const NoseSpec(len: 23, proj: 14, width: 8.5, bulb: 0.95),
      beard: const BeardSpec(style: BeardStyle.mustache, color: HairColor.darkBrown, mouthY: 45, mouthW: 10, mouthH: 3.6),
      headwear: const AviatorCap(),
      body: const PilotJacket(),
    ),
    layers: {'goggles': (pen, h) => drawGoggles(pen, h, gap: 19.5)},
    still: ['body', 'head', 'goggles'],
  ),

  // ── seer: feathered purple turban, glowing eyes, crystal ball held in both hands ──
  rigged(
    CharSpec(
      id: 'seer',
      skin: Skin.deepTone,
      head: const HeadSpec(x: 100, y: 96, scale: 0.88, yaw: 0.3, shape: FaceShape.square, roll: 0.02),
      expr: Expr(
        eyes: const EyeSpec(ew: 12.5, eh: 10.8, gap: 20, lookX: 0.45, lookY: -0.2, lidTop: 0.16, lidBottom: 0.1, crease: true, irisR: 0.52, pupilR: 0.6, iris: Color(0xFF6B3FA0)),
        brows: Expr.smug(side: 1).brows,
        mouth: const MouthSpec(kind: MouthKind.smirk, side: 1, w: 10, y: 44, amount: 0.9),
      ),
      nose: const NoseSpec(len: 25, proj: 15, width: 9.5, bulb: 1.05),
      beard: const BeardSpec(style: BeardStyle.full, color: HairColor.inkBlack, mouthY: 44, mouthW: 8.5, mouthH: 3.4, length: 3),
      headwear: HeadwearStack([
        const Turban(cloth: seerPurple, jewel: Color(0xFFE0394F), top: -84),
        CustomWear(onFront: (pen, h, skin) => drawTurbanFeather(pen, h, x: 4, y: -84)),
      ]),
      body: const Garment(
        color: robePurple,
        neckline: 'M-27 -14 C-22 8 -8 22 0 24 C8 22 22 8 27 -14 L22 -16 C17 4 4 15 0 17 C-4 15 -17 4 -22 -16 Z',
        necklineColor: goldT,
      ),
    ),
    layers: {
      'ball': (pen, h) => drawCrystalBall(pen, const Offset(100, 181), 18.5, Skin.deepTone),
      'ball_glow': (pen, h) => drawBallGlow(pen, const Offset(100, 181), 18.5),
      'ball_glow_still': (pen, h) {
        pen.c.saveLayer(const Rect.fromLTWH(-60, -60, 320, 320), Paint()..color = const Color(0x66FFFFFF));
        drawBallGlow(pen, const Offset(100, 181), 18.5);
        pen.c.restore();
      },
      'eyes': (pen, h) => drawEyeGlow(pen, h, const EyeSpec(ew: 11.5, eh: 9.6, gap: 20), const Color(0xFFE879F9)),
    },
    still: ['body', 'head', 'ball', 'ball_glow_still'],
    export: ['body', 'head', 'blink', 'mouth', 'ball', 'ball_glow', 'eyes'],
  ),

  // ── ghost: dark hooded cloak, glowing violet eyes, boo mouth ──
  rigged(
    const CharSpec(id: 'ghost'),
    layers: {
      'cloak': (pen, h) => drawGhostCloak(pen),
      'eyes': (pen, h) => drawGhostEyes(pen),
      'mouth': (pen, h) => drawGhostMouth(pen),
    },
    still: ['cloak', 'eyes'],
    export: ['cloak', 'eyes', 'mouth'],
  ),

  // ── assassin: black wraps and face veil, red glowing eyes, curved dagger in a gloved fist ──
  rigged(
    CharSpec(
      id: 'assassin',
      skin: Skin.tan,
      head: const HeadSpec(x: 100, y: 95, scale: 0.9, yaw: -0.25, shape: FaceShape.square),
      expr: const Expr(
        eyes: EyeSpec(ew: 11.5, eh: 8.6, gap: 19.5, lookX: -0.7, lookY: 0.05, lidTop: 0.3, lidSlant: 0.5, irisR: 0.55, pupilR: 0.5, iris: Color(0xFFD42A2A), lid: 3.8),
        brows: BrowSpec(lift: 4.5, inner: 6.5, outer: -3, arch: 0.6, thick: 7, taper: 0.7),
        mouth: MouthSpec(kind: MouthKind.neutral),
      ),
      nose: const NoseSpec(len: 23, proj: 12, width: 8),
      headwear: const HeadwearStack([
        FaceVeil(cloth: blackT),
        Turban(cloth: blackT, hem: -34, top: -82),
        HeadBand(),
      ]),
      body: const NinjaRobe(),
    ),
    layers: {
      'eyes': (pen, h) => drawEyeGlow(pen, h, const EyeSpec(ew: 11.5, eh: 8.6, gap: 19.5), const Color(0xFFFF2B2B), tint: 0.28, hotAlpha: 0.35, core: 0.8),
      'dagger': (pen, h) => drawDaggerFist(pen, const Offset(150, 182), angle: 0.3),
    },
    still: ['body', 'head', 'eyes', 'dagger'],
    export: ['body', 'head', 'blink', 'eyes', 'dagger'],
  ),

  // ── sultana: deep purple hijab with gold edge and a forehead jewel, coin yashmak ──
  rigged(
    CharSpec(
      id: 'sultana',
      skin: Skin.tan,
      head: const HeadSpec(x: 100, y: 95, scale: 0.97, yaw: 0.25, shape: FaceShape.round, roll: -0.03),
      expr: const Expr(
        eyes: EyeSpec(ew: 12.5, eh: 10.5, gap: 19, lookX: 0.8, lookY: 0.1, lidTop: 0.2, lidSlant: -0.1, irisR: 0.55, pupilR: 0.6, lashes: true, iris: Color(0xFF2F7F6F)),
        brows: BrowSpec(lift: 8.5, inner: 0.5, outer: -1.8, arch: 3.6, thick: 5.0),
        mouth: MouthSpec(kind: MouthKind.smile, w: 11, y: 42, amount: 0.6),
      ),
      nose: const NoseSpec(len: 20, proj: 10, width: 6.2, bulb: 0.66, bridge: 2.6),
      headwear: const HeadwearStack([
        Hijab(cloth: sultanaT, width: 1.12),
        SultanaAdornments(),
      ]),
      body: const Garment(color: Tones(Color(0xFF2A1240), Color(0xFF170826), Color(0xFF47296A))),
    ),
    layers: {'veil': (pen, h) => drawYashmak(pen, h, Skin.tan)},
    still: ['body', 'head', 'veil'],
    export: ['body', 'head', 'blink', 'mouth', 'veil'],
  ),

  // ── astronaut: glass-dome helmet, wide-eyed grin ──
  rigged(
    astro,
    layers: {
      'body': (pen, h) => drawAstronautBody(pen),
      'head': (pen, h) => drawAstronautHead(pen, astro, h),
      'visor': (pen, h) => drawAstronautVisor(pen),
    },
    still: ['body', 'head', 'visor'],
    export: ['body', 'head', 'blink', 'mouth', 'visor'],
  ),
];
}

/// Rig anchor points of worker C's characters (global 200-space units, written into
/// lib/widgets/anim_rigs.dart). Printed by tool/chars/c_probe_test.dart.
final Map<String, Map<String, Offset Function(Head)>> c3Marks = {
  'lady_gold': {
    'neck': (h) => h.neckBase,
    'tiaraRuby': (h) => h.pt(0, -65, z: 11),
    'tiaraL': (h) => h.pt(-15, -59, z: 11),
    'tiaraR': (h) => h.pt(15, -59, z: 11),
    'tiaraTop': (h) => h.pt(0, -84, z: 9),
    'winkEye': (h) => h.pt(-19, 0, lift: 2),
    'winkSpark': (h) => h.pt(-33, -9, lift: 2),
  },
  'pilot': {
    'neck': (h) => h.neckBase,
    'lensR': (h) => h.pt(19.5, 0, lift: 14),
    'lensRaisedR': (h) => h.pt(19.5, -46, lift: 14),
    'glint': (h) => h.pt(26, -6, lift: 14),
  },
  'seer': {
    'neck': (h) => h.neckBase,
    'jewel': (h) => h.pt(0, -38, lift: 9),
  },
  'knight': {
    'neck': (h) => h.neckBase,
    'socket': (h) => h.pt(0, -80, lift: 7),
    'shine': (h) => h.pt(-24, -60, lift: 7),
  },
  'assassin': {
    'neck': (h) => h.neckBase,
    'eyeL': (h) => h.pt(-19.5, 0, lift: 2),
    'eyeR': (h) => h.pt(19.5, 0, lift: 2),
  },
  'tycoon': {
    'neck': (h) => h.neckBase,
    'glint': (h) => h.pt(-27, -5, lift: 6),
    'glint2': (h) => h.pt(13, -5, lift: 6),
  },
  'emir': {
    'neck': (h) => h.neckBase,
    'brooch': (h) => h.pt(0, -43.5, lift: 8),
  },
  'sultana': {
    'neck': (h) => h.neckBase,
    'jewel': (h) => h.pt(0, -26, lift: 9),
    'veilTop': (h) => h.pt(0, 12, lift: 6),
  },
  'queen': {
    'neck': (h) => h.neckBase,
    'crownTop': (h) => h.pt(0, -99, z: 9),
    'crownL': (h) => h.pt(-23, -89, z: 9),
    'crownR': (h) => h.pt(23, -89, z: 9),
    'crownGem': (h) => h.pt(0, -55, z: 11),
  },
  'astronaut': {
    'neck': (h) => h.neckBase,
  },
};
