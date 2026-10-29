// Character pack 7 = worker S2's stickers (42): packs innocent / party / traitor / vip / hype / s1 / legend.
// Every spec is a cut-out figure in AVATAR space (head ~ (100,96), scale ~1); tool/chars/parts/s2_sticker.dart
// shrinks it into the sticker frame and adds the caption banner. See parts/s2_cast.dart for the cast,
// parts/s2_props.dart / s2_hands.dart / s2_eyes.dart for props, hands and special eyes.
import 'dart:math' as math;

import '../kit.dart';
import '../parts/s2_cast.dart';
import '../parts/s2_eyes.dart';
import '../parts/s2_hands.dart';
import '../parts/s2_props.dart';

// ── shared bits ──
const _ghutraRed = Ghutra(check: Color(0xFFC8262E), hem: -34, agalSag: 6);
const _ghutraWhite = Ghutra(hem: -34, agalSag: 6);

/// Sleeve from below the picture up to a wrist, then the hand.
void _hand(Pen pen, Skin skin, S2Pose pose, Offset wrist, {double rot = 0, double size = 1, bool mirror = false, Offset? from, Tones sleeve = Cloth.white, double armW = 26, bool arm = true}) {
  if (arm) s2Arm(pen, from ?? Offset(wrist.dx + (wrist.dx < 100 ? -34 : 34), 262), wrist, w: armW * size, cloth: sleeve);
  s2Hand(pen, skin, pose, wrist, rot: rot, size: size, mirror: mirror);
}

final List<CharSpec> pack7 = [
  // ═══════════════ البريء (innocent) ═══════════════
  // inn_me: "who, me?" - wide puppy eyes, little 'o', both palms out
  s2Char(
    'inn_me',
    s2Youth,
    head: s2Head(s2Youth, yaw: -0.2, roll: -0.05),
    expr: const Expr(
      eyes: EyeSpec(ew: 13, eh: 13, gap: 21, lookX: 0.25, lookY: -0.5, irisR: 0.6, pupilR: 0.55, lidSlant: -0.1),
      brows: BrowSpec(lift: 8, inner: -6.0, outer: 2.0, arch: 2.0, thick: 6.4),
      mouth: MouthSpec(kind: MouthKind.open, w: 10, y: 44, amount: 0.8),
    ),
    front: (pen, h) {
      _hand(pen, Skin.tan, S2Pose.open, const Offset(26, 176), rot: -0.5, size: 1.1, from: const Offset(-20, 250));
      _hand(pen, Skin.tan, S2Pose.open, const Offset(174, 176), rot: 0.5, size: 1.1, mirror: true, from: const Offset(220, 250));
      s2Drop(pen, const Offset(146, 66), s: 1.2);
    },
  ),
  // inn_cry: wronged - tears streaming, closed sad eyes
  s2Char(
    'inn_cry',
    s2HijabPink,
    head: s2Head(s2HijabPink, yaw: 0.1, roll: 0.05, pitch: 0.2),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12.5, eh: 12, gap: 18.5),
      brows: BrowSpec(lift: 7, inner: -7.0, outer: 2.6, arch: 1.6, thick: 5.4),
      mouth: MouthSpec(kind: MouthKind.frown, w: 11, y: 43, amount: 1.1),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.down, gap: 18.5, size: 1.05);
      s2Tears(pen, h, gap: 18.5, y: 8, len: 42, w: 6.6);
    },
  ),
  // inn_trust: elder, hand raised "trust me", heart
  s2Char(
    'inn_trust',
    s2Elder,
    head: s2Head(s2Elder, yaw: -0.3, roll: -0.03),
    expr: const Expr(
      eyes: EyeSpec(ew: 11.5, eh: 10.5, gap: 20.5, lookX: -0.4, lookY: -0.1, irisR: 0.52, lidBottom: 0.12, lidTop: 0.05),
      brows: BrowSpec(lift: 7.5, inner: -4.0, outer: 1.5, arch: 2.6, thick: 6.4, color: HairColor.grey),
      mouth: MouthSpec(kind: MouthKind.smile, w: 11, y: 44, amount: 0.9),
    ),
    front: (pen, h) {
      _hand(pen, Skin.fair, S2Pose.open, const Offset(164, 178), rot: 0.22, size: 1.15, mirror: true, from: const Offset(200, 256));
      s2Heart(pen, const Offset(38, 150), s: 1.15, rot: -0.2);
      s2Sparkle(pen, const Offset(26, 118), 6);
    },
  ),
  // inn_halo: angel - halo, happy closed eyes, blush
  s2Char(
    'inn_halo',
    s2HijabBlack,
    head: s2Head(s2HijabBlack, roll: 0.03),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11, gap: 18.5),
      brows: BrowSpec(lift: 8, inner: -2.0, outer: 1.5, arch: 3.0, thick: 5.0),
      mouth: MouthSpec(kind: MouthKind.smile, w: 10, y: 43, amount: 1.0),
    ),
    behind: (pen, h) => s2Halo(pen, const Offset(100, 12), rx: 32, ry: 8.5),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.happy, gap: 18.5, size: 1.05);
      for (final s in const [-1, 1]) {
        pen.glow(h.pt(s * 30.0, 24), 11 * h.scale, 7 * h.scale, const Color(0xFFFF6F8F), alpha: .45);
      }
      s2Sparkle(pen, const Offset(160, 30), 7);
      s2Sparkle(pen, const Offset(44, 42), 5);
    },
  ),
  // inn_hands: "I did nothing" - both palms up beside the head, sweat
  s2Char(
    'inn_hands',
    s2Deep,
    headwear: _ghutraWhite,
    head: s2Head(s2Deep, yaw: 0.15, roll: 0.03),
    expr: const Expr(
      eyes: EyeSpec(ew: 12.5, eh: 12.5, gap: 21, lookX: -0.7, lookY: -0.25, irisR: 0.5, pupilR: 0.55, lidSlant: -0.25, iris: Color(0xFF2E1D14)),
      brows: BrowSpec(lift: 8, inner: -6.0, outer: 2.2, arch: 1.8, thick: 6.8),
      mouth: MouthSpec(kind: MouthKind.open, w: 12, y: 44, amount: 0.7),
    ),
    front: (pen, h) {
      _hand(pen, Skin.deepTone, S2Pose.open, const Offset(8, 150), rot: -0.12, size: 1.2, from: const Offset(-20, 260));
      _hand(pen, Skin.deepTone, S2Pose.open, const Offset(192, 150), rot: 0.12, size: 1.2, mirror: true, from: const Offset(220, 260));
      s2Drop(pen, const Offset(150, 70), s: 1.25);
    },
  ),
  // inn_pls: "believe me" - praying hands, glossy eyes
  s2Char(
    'inn_pls',
    s2HijabTeal,
    head: s2Head(s2HijabTeal, yaw: -0.1, roll: 0.04),
    expr: const Expr(
      eyes: EyeSpec(ew: 11, eh: 10.4, gap: 19.5, lookX: 0.1, lookY: -0.35, irisR: 0.64, pupilR: 0.5, lidSlant: -0.3, iris: Color(0xFF34506B)),
      brows: BrowSpec(lift: 9, inner: -6.5, outer: 2.2, arch: 1.4, thick: 5.0),
      mouth: MouthSpec(kind: MouthKind.pout, w: 10, y: 42, amount: 1.0),
    ),
    front: (pen, h) {
      s2Hand(pen, Skin.brown, S2Pose.pray, const Offset(100, 222), size: 1.25);
      s2Drop(pen, const Offset(58, 112), s: .8, rot: .1);
      s2Drop(pen, const Offset(142, 112), s: .8, rot: -.1);
    },
  ),

  // ═══════════════ الاحتفال (party) ═══════════════
  // par_kafu: thumbs up, big grin
  s2Char(
    'par_kafu',
    s2Youth,
    head: s2Head(s2Youth, yaw: 0.2, roll: 0.05),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 8, inner: -1.0, outer: 1.5, arch: 3.6, thick: 6.4),
      mouth: MouthSpec(kind: MouthKind.grin, w: 15, y: 43, amount: 1.1),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.happy, size: 1.1);
      _hand(pen, Skin.tan, S2Pose.thumbUp, const Offset(158, 188), rot: 0.12, size: 1.35, mirror: true, from: const Offset(200, 262));
      s2Sparkle(pen, const Offset(30, 64), 8);
      s2Sparkle(pen, const Offset(176, 70), 6);
    },
  ),
  // par_won: trophy + star eyes
  s2Char(
    'par_won',
    s2Goatee,
    head: s2Head(s2Goatee, yaw: -0.15, roll: -0.04),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 8.5, inner: -1.5, outer: 1.0, arch: 3.6, thick: 6.8),
      mouth: MouthSpec(kind: MouthKind.laugh, w: 14, y: 43, amount: 0.85),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.stars, size: 1.05);
      s2Trophy(pen, const Offset(158, 200), s: 1.25);
      s2Confetti(pen, const [
        [30, 60, .5, 0], [172, 40, 1.2, 1], [18, 110, .2, 2], [60, 20, 2.0, 3], [150, 22, .8, 4], [184, 96, 1.6, 0], [42, 150, 1, 1],
      ]);
    },
  ),
  // par_clap: clapping hands, happy eyes
  s2Char(
    'par_clap',
    s2HijabPink,
    head: s2Head(s2HijabPink, yaw: -0.1, roll: -0.05),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 18.5),
      brows: BrowSpec(lift: 9, inner: -1.0, outer: 1.5, arch: 3.4, thick: 5.0),
      mouth: MouthSpec(kind: MouthKind.grin, w: 12, y: 42, amount: 1.0),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.happy, gap: 18.5, size: 1.1);
      s2Hand(pen, Skin.tan, S2Pose.open, const Offset(88, 210), rot: 0.1, size: 1.2);
      s2Hand(pen, Skin.tan, S2Pose.open, const Offset(112, 210), rot: -0.1, size: 1.2, mirror: true);
      s2Pop(pen, const Offset(64, 176), r0: 12, r1: 22, n: 3, a0: -3.1, a1: -2.0);
      s2Pop(pen, const Offset(136, 176), r0: 12, r1: 22, n: 3, a0: -1.14, a1: 0.0);
    },
  ),
  // par_fireworks: star eyes + bursts behind
  s2Char(
    'par_fireworks',
    s2Elder,
    head: s2Head(s2Elder, yaw: 0.1, roll: 0.03),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 9, inner: -3.0, outer: 1.0, arch: 3.8, thick: 6.8, color: HairColor.grey),
      mouth: MouthSpec(kind: MouthKind.laugh, w: 13, y: 44, amount: 0.8),
    ),
    behind: (pen, h) {
      s2Burst(pen, const Offset(26, 42), 30, const Color(0xFFFF5D73), rot: .2);
      s2Burst(pen, const Offset(176, 38), 28, const Color(0xFFFFD84D), rot: .4);
      s2Burst(pen, const Offset(184, 152), 22, const Color(0xFF4CC9F0), rot: .1);
    },
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.stars, size: 1.05);
      s2Sparkle(pen, const Offset(50, 150), 6);
    },
  ),
  // par_dance: arms up, eyes squeezed, laughing
  s2Char(
    'par_dance',
    s2Deep,
    headwear: _ghutraRed,
    head: s2Head(s2Deep, yaw: -0.5, roll: 0.12),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 8, inner: -2.0, outer: 1.5, arch: 3.6, thick: 6.8),
      mouth: MouthSpec(kind: MouthKind.laugh, w: 14, y: 44, amount: 0.9),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.squint, size: 1.05);
      _hand(pen, Skin.deepTone, S2Pose.open, const Offset(14, 92), rot: -0.35, size: 1.2, from: const Offset(-10, 262), sleeve: Cloth.white);
      _hand(pen, Skin.deepTone, S2Pose.open, const Offset(186, 160), rot: 0.8, size: 1.2, mirror: true, from: const Offset(230, 262));
      s2Confetti(pen, const [[170, 44, .4, 1], [40, 30, 1.5, 0], [180, 112, .9, 3], [28, 168, 2.2, 4]]);
    },
  ),
  // par_best: sunglasses, smirk, star
  s2Char(
    'par_best',
    s2Must,
    head: s2Head(s2Must, yaw: -0.25, roll: -0.04),
    glasses: const GlassesSpec(kind: GlassesKind.sun, thick: 3.2),
    expr: const Expr(
      eyes: EyeSpec(ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 9, inner: -1.0, outer: 1.0, arch: 3.0, thick: 6.8),
      mouth: MouthSpec(kind: MouthKind.smirk, w: 13, y: 45, side: 1),
    ),
    front: (pen, h) {
      s2StarProp(pen, const Offset(160, 168), 25, rot: -math.pi / 2 + .2);
      s2Sparkle(pen, const Offset(30, 70), 7);
      s2Sparkle(pen, const Offset(176, 78), 5);
    },
  ),

  // ═══════════════ الخاين (traitor) ═══════════════
  // tr_evil: masked, glowing red eyes
  s2Char(
    'tr_evil',
    s2Masked,
    head: s2Head(s2Masked, yaw: 0.25, pitch: 0.1),
    expr: Expr.angry(lookX: 0.5).copyWith(
      eyes: Expr.angry(lookX: 0.5).eyes.copyWith(iris: const Color(0xFFE02222), pupilR: 0.5, lidSlant: 0.6),
    ),
    front: (pen, h) {
      for (final s in const [-1, 1]) {
        pen.glow(h.pt(s * 21.0, 1), 17 * h.scale, 13 * h.scale, const Color(0xFFFF3030), alpha: .5);
      }
      s2Sparkle(pen, const Offset(26, 70), 8, color: const Color(0xFFFF6B6B));
      s2Sparkle(pen, const Offset(176, 56), 6, color: const Color(0xFFFF6B6B));
      s2Sparkle(pen, const Offset(166, 108), 4, color: const Color(0xFFFF6B6B));
    },
  ),
  // tr_dagger: evil grin, dagger raised
  s2Char(
    'tr_dagger',
    s2Deep,
    headwear: _ghutraRed,
    head: s2Head(s2Deep, yaw: -0.3, roll: -0.05),
    expr: Expr.angry(lookX: 0.6, mouth: MouthKind.grin).copyWith(
      eyes: Expr.angry(lookX: 0.6).eyes.copyWith(iris: const Color(0xFFE02222), pupilR: 0.5, lidSlant: 0.5),
      mouth: const MouthSpec(kind: MouthKind.grin, w: 14, y: 44, amount: 0.9),
    ),
    front: (pen, h) {
      _hand(pen, Skin.deepTone, S2Pose.fist, const Offset(166, 188), rot: 0.1, size: 1.2, from: const Offset(206, 262));
      s2Dagger(pen, const Offset(166, 160), rot: math.pi + .12, s: 1.25);
      s2Sparkle(pen, const Offset(180, 78), 7, color: const Color(0xFFFFFFFF));
    },
  ),
  // tr_poker: deadpan
  s2Char(
    'tr_poker',
    s2Goatee,
    head: s2Head(s2Goatee, yaw: 0.35, roll: 0.0),
    expr: const Expr(
      eyes: EyeSpec(ew: 11, eh: 9, gap: 21, lookX: 0.9, lookY: 0.05, lidTop: 0.38, lidBottom: 0.1, irisR: 0.55),
      brows: BrowSpec(lift: 6, inner: 0.5, outer: 0.5, arch: 0.6, thick: 6.8),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 9, y: 44),
    ),
  ),
  // tr_plan: masked, steepled fingers, sly red eyes
  s2Char(
    'tr_plan',
    s2Masked,
    head: s2Head(s2Masked, yaw: -0.3, roll: -0.04, pitch: 0.15),
    expr: Expr.angry(lookX: -0.7).copyWith(
      eyes: Expr.angry(lookX: -0.7).eyes.copyWith(iris: const Color(0xFFE02222), pupilR: 0.5, lidTop: 0.3, lidSlant: 0.42),
    ),
    front: (pen, h) {
      s2Hand(pen, Skin.tan, S2Pose.pray, const Offset(100, 212), size: 1.25, rot: 0.04);
      for (final s in const [-1, 1]) {
        pen.glow(h.pt(s * 21.0, 1), 15 * h.scale, 11 * h.scale, const Color(0xFFFF3030), alpha: .4);
      }
    },
  ),
  // tr_mask: "who am I?" - sly smirk, mask on a stick
  s2Char(
    'tr_mask',
    s2Youth,
    head: s2Head(s2Youth, yaw: 0.45, roll: 0.05),
    expr: Expr.smug(lookX: 0.9, lookY: -0.1, side: 1),
    front: (pen, h) {
      s2Mask(pen, const Offset(150, 138), s: 1.2, rot: -0.2);
      _hand(pen, Skin.tan, S2Pose.fist, const Offset(180, 200), rot: 0.4, size: 1.2, mirror: true, from: const Offset(220, 262));
    },
  ),
  // tr_laugh: evil laughter, flames behind
  s2Char(
    'tr_laugh',
    s2Black,
    head: s2Head(s2Black, yaw: 0.1, roll: -0.06),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 6, inner: 6.0, outer: -3.0, arch: 0.8, thick: 7.0),
      mouth: MouthSpec(kind: MouthKind.laugh, w: 15, y: 44, amount: 1.0),
    ),
    behind: (pen, h) {
      s2Flame(pen, const Offset(30, 212), s: 1.5, flip: true);
      s2Flame(pen, const Offset(170, 212), s: 1.5);
    },
    front: (pen, h) => s2Eyes(pen, h, S2Eye.squint, size: 1.05),
  ),

  // ═══════════════ الفخامة (vip) ═══════════════
  // vip_falcon: elder in a bisht with a falcon on his glove
  s2Char(
    'vip_falcon',
    s2Elder,
    body: const Bisht(),
    head: s2Head(s2Elder, yaw: 0.3, roll: 0.02),
    expr: const Expr(
      eyes: EyeSpec(ew: 11.5, eh: 10.5, gap: 20.5, lookX: 0.8, lookY: 0.0, irisR: 0.52, lidBottom: 0.1, lidTop: 0.08),
      brows: BrowSpec(lift: 7.5, inner: -1.0, outer: 1.5, arch: 2.6, thick: 6.4, color: HairColor.grey),
      mouth: MouthSpec(kind: MouthKind.smile, w: 11, y: 44, amount: 0.8),
    ),
    front: (pen, h) {
      s2Falcon(pen, const Offset(160, 150), s: 1.12, rot: 0.04);
      s2Chain(pen, h.neckBase, s: 1.1);
    },
  ),
  // vip_bisht: prestige - eyes closed, chin up
  s2Char(
    'vip_bisht',
    s2Must,
    body: const Bisht(),
    head: s2Head(s2Must, yaw: -0.15, pitch: -0.25),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11, gap: 21),
      brows: BrowSpec(lift: 8, inner: 0.5, outer: 1.5, arch: 3.0, thick: 7.0),
      mouth: MouthSpec(kind: MouthKind.smirk, w: 11, y: 45, side: 1, amount: 0.7),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.down, size: 1.05);
      s2Chain(pen, h.neckBase, s: 1.1);
      s2Sparkle(pen, const Offset(30, 90), 6);
    },
  ),
  // vip_gg: thumbs up + wink
  s2Char(
    'vip_gg',
    s2Goatee,
    head: s2Head(s2Goatee, yaw: -0.2, roll: -0.06),
    expr: const Expr(
      eyes: EyeSpec(ew: 12, eh: 11.5, gap: 21, lookX: 0.2, right: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 21)),
      brows: BrowSpec(lift: 8.5, inner: -1.0, outer: 1.0, arch: 3.6, thick: 6.8),
      mouth: MouthSpec(kind: MouthKind.grin, w: 14, y: 43, amount: 1.0),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.happy, side: 1, size: 1.05);
      _hand(pen, Skin.brown, S2Pose.thumbUp, const Offset(160, 190), rot: -0.1, size: 1.35, mirror: true, from: const Offset(204, 262));
      s2Sparkle(pen, const Offset(28, 66), 8);
      s2Sparkle(pen, const Offset(40, 130), 5);
      s2Sparkle(pen, const Offset(178, 74), 6);
    },
  ),
  // vip_crown: crown + hand on the head
  s2Char(
    'vip_crown',
    s2Youth,
    head: s2Head(s2Youth, yaw: -0.15, roll: 0.04),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 8.5, inner: -1.0, outer: 1.2, arch: 3.4, thick: 6.4),
      mouth: MouthSpec(kind: MouthKind.smile, w: 13, y: 43, amount: 1.0),
    ),
    front: (pen, h) {
      s2Crown(pen, const Offset(100, 34), s: 1.15, rot: 0.04);
      s2Eyes(pen, h, S2Eye.happy, size: 1.1);
      _hand(pen, Skin.tan, S2Pose.open, const Offset(30, 118), rot: 1.0, size: 1.1, from: const Offset(-20, 250));
      s2Sparkle(pen, const Offset(160, 24), 7);
      s2Sparkle(pen, const Offset(176, 70), 5);
    },
  ),
  // vip_gold: money eyes + gold bars
  s2Char(
    'vip_gold',
    s2Deep,
    headwear: _ghutraWhite,
    head: s2Head(s2Deep, yaw: 0.1, roll: 0.04),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 9, inner: -2.0, outer: 1.0, arch: 3.8, thick: 7.0),
      mouth: MouthSpec(kind: MouthKind.grin, w: 15, y: 44, amount: 1.0),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.money, size: 1.05);
      s2GoldBars(pen, const Offset(152, 202), s: 1.1);
      s2Sparkle(pen, const Offset(176, 92), 7);
      s2Sparkle(pen, const Offset(30, 76), 6);
    },
  ),
  // vip_cool: sunglasses, chin up
  s2Char(
    'vip_cool',
    s2Bearded,
    head: s2Head(s2Bearded, yaw: -0.3, pitch: -0.12, roll: -0.04),
    glasses: const GlassesSpec(kind: GlassesKind.sun, thick: 3.2),
    expr: const Expr(
      eyes: EyeSpec(ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 9, inner: 0.5, outer: 0.5, arch: 2.4, thick: 6.8),
      mouth: MouthSpec(kind: MouthKind.smirk, w: 12, y: 45, side: 1, amount: 0.9),
    ),
    front: (pen, h) {
      s2Sparkle(pen, const Offset(30, 70), 8);
      s2Sparkle(pen, const Offset(174, 62), 6);
      s2Sparkle(pen, const Offset(168, 130), 5);
    },
  ),

  // ═══════════════ الحماس (hype) ═══════════════
  // hype_fire: flames behind, star eyes
  s2Char(
    'hype_fire',
    s2Black,
    head: s2Head(s2Black, yaw: 0.1, roll: 0.03),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 6, inner: 4.0, outer: -2.0, arch: 1.4, thick: 6.8),
      mouth: MouthSpec(kind: MouthKind.grin, w: 15, y: 44, amount: 1.0),
    ),
    behind: (pen, h) {
      s2Flame(pen, const Offset(30, 212), s: 1.5, flip: true);
      s2Flame(pen, const Offset(170, 212), s: 1.5);
    },
    front: (pen, h) => s2Eyes(pen, h, S2Eye.stars, size: 1.05),
  ),
  // hype_go: fist up, shouting
  s2Char(
    'hype_go',
    s2HijabPink,
    head: s2Head(s2HijabPink, yaw: -0.15, roll: -0.05),
    expr: const Expr(
      eyes: EyeSpec(ew: 11, eh: 10, gap: 18.5, lookX: 0.0, lidTop: 0.12, lidSlant: 0.35, irisR: 0.56, iris: Color(0xFF2E1D14)),
      brows: BrowSpec(lift: 7, inner: 4.5, outer: -2.0, arch: 1.2, thick: 5.8),
      mouth: MouthSpec(kind: MouthKind.laugh, w: 12, y: 42, amount: 0.9),
    ),
    front: (pen, h) {
      _hand(pen, Skin.tan, S2Pose.fist, const Offset(166, 150), rot: 0.1, size: 1.4, mirror: true, from: const Offset(210, 262));
      s2Pop(pen, const Offset(166, 108), r0: 18, r1: 28, n: 3, a0: -2.2, a1: -0.9);
    },
  ),
  // hype_strong: double-biceps flex, growl
  s2Char(
    'hype_strong',
    s2Deep,
    headwear: _ghutraRed,
    head: s2Head(s2Deep, yaw: 0.15, roll: 0.03),
    expr: Expr.angry(lookX: -0.2, mouth: MouthKind.clenched).copyWith(
      mouth: const MouthSpec(kind: MouthKind.clenched, w: 14, y: 44, amount: 1.0),
    ),
    front: (pen, h) {
      final skin = Skin.deepTone;
      for (final g in const [-1.0, 1.0]) {
        final x = 100 + g * 76;
        // bare forearm (tapered, slightly bowed) coming out of a rolled white sleeve
        final arm = svg('M${x - g * 19} 206 C${x - g * 18} 184 ${x - g * 15} 164 ${x - g * 11} 146 L${x + g * 10} 146 C${x + g * 15} 164 ${x + g * 19} 184 ${x + g * 21} 206 Z');
        pen.solid(arm, skin.tones, shade: 5, hi: 1.4, w: Style.line * .9, dir: Offset(-g * .9, -.3));
        pen.taper(svg('M${x - g * 4} 150 C${x - g * 7} 166 ${x - g * 8} 180 ${x - g * 10} 196'), w0: 2.6, w1: .3, color: withA(skin.hi, .9));
        s2Arm(pen, Offset(x + g * 10, 266), Offset(x + g * 1, 196), w: 46, cloth: Cloth.white);
        s2Hand(pen, skin, S2Pose.fist, Offset(x, 148), size: 1.3, mirror: g > 0);
        s2Pop(pen, Offset(100 + g * 82, 100), r0: 14, r1: 24, n: 3, a0: g < 0 ? -2.5 : -2.0, a1: g < 0 ? -1.14 : -0.64, color: const Color(0xFFFFD166));
      }
    },
  ),
  // hype_100: star eyes + 100 badge
  s2Char(
    'hype_100',
    s2Goatee,
    head: s2Head(s2Goatee, yaw: -0.2, roll: -0.05),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 9, inner: -2.0, outer: 1.0, arch: 3.8, thick: 6.8),
      mouth: MouthSpec(kind: MouthKind.grin, w: 14, y: 43, amount: 1.0),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.stars, size: 1.05);
      s2Badge100(pen, const Offset(158, 176), s: 1.4, rot: -0.2);
      s2Sparkle(pen, const Offset(30, 74), 7);
      s2Sparkle(pen, const Offset(178, 90), 5);
    },
  ),
  // hype_rocket: star eyes, rocket
  s2Char(
    'hype_rocket',
    s2Must,
    head: s2Head(s2Must, yaw: 0.2, roll: 0.05),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 9, inner: -2.0, outer: 1.0, arch: 3.8, thick: 6.8),
      mouth: MouthSpec(kind: MouthKind.laugh, w: 14, y: 44, amount: 0.8),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.stars, size: 1.05);
      s2Rocket(pen, const Offset(172, 58), s: 0.98, rot: 0.8);
      s2Sparkle(pen, const Offset(30, 76), 6);
    },
  ),
  // hype_eyes: "I'm watching you" - two fingers to the eyes
  s2Char(
    'hype_eyes',
    s2HijabTeal,
    head: s2Head(s2HijabTeal, yaw: 0.3, roll: -0.03),
    expr: const Expr(
      eyes: EyeSpec(ew: 10.5, eh: 9.4, gap: 19.5, lookX: 0.9, lidTop: 0.15, lidSlant: 0.4, irisR: 0.55, iris: Color(0xFF34506B)),
      brows: BrowSpec(lift: 8, inner: 5.0, outer: -2.0, arch: 1.0, thick: 5.0),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 9, y: 42),
    ),
    front: (pen, h) {
      _hand(pen, Skin.brown, S2Pose.vee, const Offset(162, 142), rot: -0.8, size: 1.2, mirror: true, from: const Offset(214, 262));
    },
  ),

  // ═══════════════ الموسم الأول (s1) ═══════════════
  // s1_night: moon + stars, happy
  s2Char(
    's1_night',
    s2Youth,
    head: s2Head(s2Youth, yaw: -0.2, roll: -0.05),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 8.5, inner: -1.0, outer: 1.2, arch: 3.4, thick: 6.4),
      mouth: MouthSpec(kind: MouthKind.grin, w: 14, y: 43, amount: 1.0),
    ),
    behind: (pen, h) => s2Moon(pen, const Offset(168, 58), s: 1.5, rot: 0.3),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.happy, size: 1.1);
      s2StarProp(pen, const Offset(34, 62), 11, rot: -math.pi / 2 + .3);
      s2Sparkle(pen, const Offset(24, 112), 6);
      s2Sparkle(pen, const Offset(140, 20), 6);
    },
  ),
  // s1_champ: season champion - trophy held high, star eyes
  s2Char(
    's1_champ',
    s2Goatee,
    head: s2Head(s2Goatee, yaw: 0.15, roll: 0.04),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 9, inner: -2.0, outer: 1.0, arch: 3.8, thick: 6.8),
      mouth: MouthSpec(kind: MouthKind.laugh, w: 14, y: 43, amount: 0.85),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.stars, size: 1.05);
      s2Arm(pen, const Offset(214, 262), const Offset(160, 168), w: 24);
      s2Hand(pen, Skin.brown, S2Pose.fist, const Offset(160, 168), size: 1.1);
      s2Trophy(pen, const Offset(160, 150), s: 1.25);
      s2Sparkle(pen, const Offset(26, 70), 8);
      s2Sparkle(pen, const Offset(178, 56), 6);
    },
  ),
  // s1_tea: a glass of tea, content
  s2Char(
    's1_tea',
    s2HijabPink,
    head: s2Head(s2HijabPink, yaw: -0.15, roll: -0.04),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11, gap: 18.5),
      brows: BrowSpec(lift: 9, inner: -1.0, outer: 1.5, arch: 3.0, thick: 5.0),
      mouth: MouthSpec(kind: MouthKind.smile, w: 11, y: 42, amount: 1.0),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.down, gap: 18.5, size: 1.1);
      for (final s in const [-1, 1]) {
        pen.glow(h.pt(s * 29.0, 24), 10 * h.scale, 6.5 * h.scale, const Color(0xFFFF6F8F), alpha: .45);
      }
      s2Arm(pen, const Offset(206, 262), const Offset(152, 200), w: 24, cloth: const Tones(Color(0xFF8E3558), Color(0xFF5E2039), Color(0xFFB4567C)));
      s2Hand(pen, Skin.tan, S2Pose.fist, const Offset(152, 200), rot: 0.0, size: 1.15, mirror: true);
      s2TeaGlass(pen, const Offset(150, 198), s: 1.5);
    },
  ),
  // s1_lantern: fanous
  s2Char(
    's1_lantern',
    s2Elder,
    head: s2Head(s2Elder, yaw: 0.25, roll: 0.03),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 11.5, eh: 10.5, gap: 20.5),
      brows: BrowSpec(lift: 8, inner: -2.0, outer: 1.5, arch: 3.0, thick: 6.4, color: HairColor.grey),
      mouth: MouthSpec(kind: MouthKind.smile, w: 12, y: 44, amount: 1.0),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.happy, gap: 20.5, size: 1.05);
      s2Arm(pen, const Offset(214, 262), const Offset(160, 204), w: 24);
      s2Lantern(pen, const Offset(160, 148), s: 1.3);
      s2Hand(pen, Skin.fair, S2Pose.fist, const Offset(160, 206), size: 1.1, mirror: true);
    },
  ),
  // s1_sleep: night cap, yawn, zzz
  s2Char(
    's1_sleep',
    s2Deep,
    headwear: _ghutraRed,
    head: s2Head(s2Deep, yaw: -0.15, roll: 0.1),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11, gap: 21),
      brows: BrowSpec(lift: 8, inner: -3.0, outer: 2.5, arch: 1.4, thick: 6.8),
      mouth: MouthSpec(kind: MouthKind.oh, w: 14, y: 45, amount: 1.1),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.down, size: 1.05);
      s2NightCap(pen, const Offset(92, 30), s: .95);
      s2Zed(pen, const Offset(168, 64), 1.3, rot: .2);
      s2Zed(pen, const Offset(182, 36), 1.0, rot: .15);
    },
  ),
  // s1_star: star eyes, big star
  s2Char(
    's1_star',
    s2HijabBlack,
    head: s2Head(s2HijabBlack, yaw: 0.1, roll: 0.04),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11, gap: 18.5),
      brows: BrowSpec(lift: 9, inner: -2.0, outer: 1.0, arch: 3.4, thick: 5.0),
      mouth: MouthSpec(kind: MouthKind.grin, w: 12, y: 42, amount: 1.0),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.stars, gap: 18.5, size: 1.1);
      s2StarProp(pen, const Offset(160, 168), 28, rot: -math.pi / 2 + .15);
      s2Sparkle(pen, const Offset(28, 70), 7);
      s2Sparkle(pen, const Offset(176, 76), 5);
    },
  ),

  // ═══════════════ الأساطير (legend) ═══════════════
  // leg_king: crown + bisht, eyes closed, smug
  s2Char(
    'leg_king',
    s2Elder,
    body: const Bisht(),
    head: s2Head(s2Elder, yaw: -0.2, pitch: -0.2),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 11.5, eh: 10.5, gap: 20.5),
      brows: BrowSpec(lift: 8.5, inner: 0.5, outer: 1.5, arch: 3.0, thick: 6.8, color: HairColor.grey),
      mouth: MouthSpec(kind: MouthKind.smirk, w: 11, y: 44, side: -1, amount: 0.8),
    ),
    front: (pen, h) {
      s2Crown(pen, const Offset(100, 32), s: 1.2);
      s2Eyes(pen, h, S2Eye.down, gap: 20.5, size: 1.05);
      s2Chain(pen, h.neckBase, s: 1.1);
      s2Sparkle(pen, const Offset(26, 70), 7);
    },
  ),
  // leg_genius: star eyes + bulb
  s2Char(
    'leg_genius',
    s2Youth,
    head: s2Head(s2Youth, yaw: -0.25, roll: -0.05),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 9.5, inner: -2.0, outer: 0.5, arch: 4.0, thick: 6.4),
      mouth: MouthSpec(kind: MouthKind.grin, w: 14, y: 43, amount: 1.0),
    ),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.stars, size: 1.05);
      s2Bulb(pen, const Offset(160, 50), s: 1.2, rot: 0.2);
      s2Sparkle(pen, const Offset(30, 70), 7);
      s2Sparkle(pen, const Offset(34, 130), 5);
    },
  ),
  // leg_ghost: the ghost itself
  CharSpec(
    id: 'leg_ghost',
    cutout: true,
    custom: (pen, h) => s2Ghost(pen),
  ),
  // leg_mind: glowing eyes, fingers to the temples, waves
  s2Char(
    'leg_mind',
    s2HijabTeal,
    head: s2Head(s2HijabTeal, roll: 0.02),
    expr: const Expr(
      eyes: EyeSpec(open: 0, ew: 11, eh: 10, gap: 19.5),
      brows: BrowSpec(lift: 9, inner: -1.0, outer: 1.5, arch: 2.6, thick: 5.0),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 8, y: 42),
    ),
    behind: (pen, h) => s2MindWaves(pen, const Offset(100, 58)),
    front: (pen, h) {
      s2Eyes(pen, h, S2Eye.glow, gap: 19.5, size: 1.0);
      _hand(pen, Skin.brown, S2Pose.point, const Offset(32, 128), rot: 0.5, size: 1.3, from: const Offset(-10, 262));
      _hand(pen, Skin.brown, S2Pose.point, const Offset(168, 128), rot: -0.5, size: 1.3, mirror: true, from: const Offset(210, 262));
    },
  ),
  // leg_storm: lightning, clenched teeth
  s2Char(
    'leg_storm',
    s2Deep,
    headwear: _ghutraRed,
    head: s2Head(s2Deep, roll: 0.0, pitch: 0.1),
    expr: Expr.angry().copyWith(
      mouth: const MouthSpec(kind: MouthKind.clenched, w: 14, y: 44, amount: 1.0),
    ),
    behind: (pen, h) {
      s2Bolt(pen, const Offset(28, 66), s: 1.5, rot: -0.2);
      s2Bolt(pen, const Offset(174, 70), s: 1.5, rot: 0.2);
    },
    front: (pen, h) {
      s2Bolt(pen, const Offset(20, 140), s: .9, rot: -.3);
      s2Bolt(pen, const Offset(182, 140), s: .9, rot: .3);
    },
  ),
  // leg_legend: crown + sunglasses
  s2Char(
    'leg_legend',
    s2Bearded,
    head: s2Head(s2Bearded, yaw: 0.2, pitch: -0.12, roll: 0.03),
    glasses: const GlassesSpec(kind: GlassesKind.sun, thick: 3.2),
    expr: const Expr(
      eyes: EyeSpec(ew: 12, eh: 11.5, gap: 21),
      brows: BrowSpec(lift: 9, inner: 0.5, outer: 0.5, arch: 2.4, thick: 6.8),
      mouth: MouthSpec(kind: MouthKind.smirk, w: 12, y: 45, side: -1, amount: 0.9),
    ),
    front: (pen, h) {
      s2Crown(pen, const Offset(100, 32), s: 1.2);
      s2Sparkle(pen, const Offset(28, 70), 8);
      s2Sparkle(pen, const Offset(176, 76), 6);
      s2Sparkle(pen, const Offset(168, 140), 5);
    },
  ),
];
