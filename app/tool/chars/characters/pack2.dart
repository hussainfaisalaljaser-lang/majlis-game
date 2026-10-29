// Character pack 2 (worker B): detective, spy, doctor, diver, poet, falconer, camel, lv10.
// All are cut-out busts (the shop draws the animated coloured background behind them).
import 'dart:math' as math;

import '../kit.dart';
import '../parts/b_animals.dart';
import '../parts/b_bodies.dart';
import '../parts/b_common.dart';
import '../parts/b_falcon.dart';
import '../parts/b_props.dart';

const Skin _leather = Skin(
  base: Color(0xFFA9703F),
  shade: Color(0xFF7A4B27),
  hi: Color(0xFFC98F58),
  blush: Color(0xFFA9703F),
  lip: Color(0xFF7A4B27),
  deep: Color(0xFF5A3416),
);

final List<CharSpec> pack2 = [
  // ── detective: white ghutra, thick mustache, one huge eye behind a magnifier ──
  CharSpec(
    id: 'detective',
    cutout: true,
    skin: Skin.brown,
    head: const HeadSpec(x: 94, y: 86, scale: 0.88, yaw: 0.6, roll: -0.04, shape: FaceShape.square),
    expr: const Expr(
      eyes: EyeSpec(
        ew: 11.5, eh: 10, gap: 20, lookX: 0.9, lookY: 0.0, irisR: 0.5, pupilR: 0.62, lidTop: 0.12, lidSlant: 0.3, lidBottom: 0.15, iris: Color(0xFF3B2A1C),
      ),
      brows: BrowSpec(
        lift: 6, inner: 3, outer: -1.5, arch: 1.6, thick: 7,
        left: BrowSpec(lift: 4.5, inner: 5, outer: -1, arch: 1.4, thick: 7.2),
        right: BrowSpec(lift: 12, inner: -3, outer: 0, arch: 3.4, thick: 7),
      ),
      mouth: MouthSpec(kind: MouthKind.smirk, side: 1, w: 9, y: 46, amount: 0.9),
    ),
    nose: const NoseSpec(len: 25, proj: 15, width: 9, bulb: 0.95),
    beard: const BeardSpec(style: BeardStyle.mustache, color: HairColor.inkBlack, mustacheSize: 1.1),
    headwear: const Ghutra(hem: -35, agalTilt: -0.05, agalSag: 6, width: 0.95),
    body: const BCoat(
      coat: Tones(Color(0xFF59607D), Color(0xFF383E58), Color(0xFF7F88AC)),
      inner: Cloth.white,
      trim: Color(0xFF9AA3C4),
      tie: Color(0xFFC4392F),
      shirtCollar: Cloth.white,
    ),
    behind: (pen, h) => bClipOpen(pen),
    front: (pen, h) {
      bClipClose(pen);
      final lc = h.pt(20, 0, lift: 1.2) + const Offset(2, 1);
      const ang = 1.0;
      bMagnifier(
        pen, h,
        lc: lc, lr: 23, ang: ang, handle: 50,
        eyes: const EyeSpec(ew: 11.5, eh: 11, gap: 20, lookX: 0.35, lookY: -0.05, irisR: 0.5, pupilR: 0.55, lidTop: 0.0, lidSlant: 0.1, iris: Color(0xFF3B2A1C)),
        brows: const BrowSpec(lift: 6.5, inner: -3.5, outer: 0, arch: 3.4, thick: 7),
        skin: Skin.brown,
      );
      final hp = lc + Offset(math.cos(ang), math.sin(ang)) * (23 + 40);
      bGripHand(pen, hp, ang - math.pi / 2, 0.95, Skin.brown, sleeve: const Tones(Color(0xFF59607D), Color(0xFF383E58), Color(0xFF7F88AC)));
    },
  ),

  // ── spy: black hood, tinted wayfarers, earpiece, sly smirk ──
  CharSpec(
    id: 'spy',
    cutout: true,
    skin: Skin.fair,
    head: const HeadSpec(x: 99, y: 88, scale: 0.88, yaw: -0.65, pitch: 0, roll: 0.09, shape: FaceShape.pointed),
    expr: const Expr(
      eyes: EyeSpec(ew: 11.5, eh: 10.5, gap: 19.5, lookX: -0.95, lookY: 0.0, irisR: 0.5, pupilR: 0.62, lidTop: 0.1, lidBottom: 0.1, iris: Color(0xFF3A2416)),
      brows: BrowSpec(
        lift: 8.5, inner: -0.5, outer: 1.2, arch: 3.2, thick: 5.6,
        left: BrowSpec(lift: 10, inner: -3.0, outer: -0.5, arch: 3.6, thick: 5.8),
        right: BrowSpec(lift: 6, inner: 1.5, outer: 1.8, arch: 2.2, thick: 5.6),
      ),
      mouth: MouthSpec(kind: MouthKind.smirk, side: -1, w: 11, y: 44, amount: 1.0),
    ),
    nose: const NoseSpec(len: 21, proj: 12, width: 7, bulb: 0.75, bridge: 2.8),
    headwear: const Hijab(
      cloth: Tones(Color(0xFF2B2833), Color(0xFF14121A), Color(0xFF5A546C)),
      flap: true,
      width: 1.15,
      length: 0.95,
      hem: -40,
    ),
    body: const Garment(color: Tones(Color(0xFF2B2833), Color(0xFF14121A), Color(0xFF5A546C))),
    behind: (pen, h) => bClipOpen(pen),
    front: (pen, h) {
      bSunglasses(pen, h, const EyeSpec(ew: 11.5, eh: 10.5, gap: 19.5));
      // earpiece on the hood + coiled cord down into the collar
      final e = h.pt(47, 4, lift: 9);
      final n = h.neckBase;
      final cord = Path()
        ..moveTo(e.dx, e.dy)
        ..cubicTo(e.dx + 7, e.dy + 14, e.dx - 3, e.dy + 34, n.dx + 26, n.dy + 8);
      bCoil(pen, cord, w: 3.2);
      bEarbud(pen, e, 3.8);
      bClipClose(pen);
    },
  ),

  // ── diver: white cap + goggles, huge grin, a pearl pinched in his fingers ──
  CharSpec(
    id: 'diver',
    cutout: true,
    skin: Skin.deepTone,
    head: const HeadSpec(x: 88, y: 88, scale: 0.86, yaw: 0.55, roll: 0.05, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 12.5, eh: 12, gap: 20, lookX: 0.95, lookY: -0.15, irisR: 0.5, pupilR: 0.62, iris: Color(0xFF3A2416)),
      brows: BrowSpec(lift: 8, inner: -1.5, outer: -0.5, arch: 4.0, thick: 6.6),
      mouth: MouthSpec(kind: MouthKind.grin, w: 14, y: 45, amount: 1.1),
    ),
    nose: const NoseSpec(len: 22, proj: 13, width: 8.5, bulb: 0.95),
    headwear: const HeadwearStack([
      Cap(cloth: Cloth.white, hem: -43, top: -77),
      BGoggles(y: -57, gap: 17.5, r: 10.2),
    ]),
    body: const BareShoulders(),
    neckWidth: 25,
    behind: (pen, h) => bClipOpen(pen),
    front: (pen, h) {
      final n = h.neckBase;
      // rope sling across the chest
      bRope(pen, Path()..moveTo(n.dx - 44 * h.scale, n.dy + 6 * h.scale)..quadraticBezierTo(n.dx - 8 * h.scale, n.dy + 30 * h.scale, n.dx + 40 * h.scale, n.dy + 34 * h.scale), w: 4.4 * h.scale);
      // droplets
      bDrop(pen, h.pt(-28, 30, lift: 3), 2.6);
      bDrop(pen, h.pt(24, -30, lift: 6), 2.2, rot: 0.2);
      bDrop(pen, Offset(n.dx - 34 * h.scale, n.dy + 20 * h.scale), 2.4, rot: -0.2);
      bDrop(pen, Offset(n.dx + 38 * h.scale, n.dy + 14 * h.scale), 2.0);
      const at = Offset(152, 130);
      const rot = 0.12;
      const sz = 0.95;
      final tip = bHandPoint(at, rot, sz, const Offset(0, -29));
      bPearl(pen, tip + const Offset(0, -2), 8.4);
      bPinchHand(pen, at, rot, sz, Skin.deepTone);
      bClipClose(pen);
      bBubble(pen, const Offset(176, 60), 6);
      bBubble(pen, const Offset(166, 40), 3.6);
    },
  ),

  // ── poet: red shemagh, grey beard, round glasses, gazing up for a rhyme, quill raised ──
  CharSpec(
    id: 'poet',
    cutout: true,
    skin: Skin.fair,
    head: const HeadSpec(x: 94, y: 88, scale: 0.86, yaw: 0.4, pitch: -0.5, roll: -0.05, shape: FaceShape.lean),
    expr: Expr(
      eyes: const EyeSpec(ew: 11.5, eh: 10.5, gap: 20, lookX: 0.55, lookY: -0.75, irisR: 0.5, pupilR: 0.6, lidBottom: 0.1, crease: true, iris: Color(0xFF4A6A78)),
      brows: const BrowSpec(lift: 8, inner: -2.5, outer: 0.5, arch: 3.6, thick: 6.4, color: HairColor.grey),
      mouth: const MouthSpec(kind: MouthKind.smile, w: 9, y: 45, amount: 0.55),
    ),
    nose: const NoseSpec(len: 23, proj: 13, width: 8.5, bulb: 1.05),
    beard: const BeardSpec(style: BeardStyle.full, color: HairColor.grey, mouthY: 45, mouthW: 8, mouthH: 3.2, length: 4),
    glasses: const GlassesSpec(kind: GlassesKind.round, thick: 3.0),
    headwear: const Ghutra(check: Color(0xFFC8262E), hem: -35, agalTilt: -0.06, agalSag: 6, width: 0.95, dropY: 84),
    body: const Bisht(
      cloak: Tones(Color(0xFF6B4A33), Color(0xFF45301F), Color(0xFF946A48)),
      inner: Cloth.cream,
    ),
    behind: (pen, h) => bClipOpen(pen),
    front: (pen, h) {
      const at = Offset(152, 166);
      const rot = -0.08;
      const sz = 0.95;
      bQuill(pen, at, rot, sz);
      bGripHand(pen, at, rot, sz, Skin.fair, sleeve: const Tones(Color(0xFF6B4A33), Color(0xFF45301F), Color(0xFF946A48)));
      bClipClose(pen);
    },
  ),

  // ── falconer: red shemagh, proud grin at the falcon on his gloved fist ──
  CharSpec(
    id: 'falconer',
    cutout: true,
    skin: Skin.tan,
    head: const HeadSpec(x: 80, y: 90, scale: 0.86, yaw: 0.55, roll: 0.04, shape: FaceShape.square),
    expr: const Expr(
      eyes: EyeSpec(ew: 11.5, eh: 10.5, gap: 20, lookX: 0.95, lookY: -0.3, irisR: 0.5, pupilR: 0.58, lidTop: 0.03, lidBottom: 0.22, iris: Color(0xFF3B2A1C)),
      brows: BrowSpec(lift: 7, inner: -1.0, outer: 0.0, arch: 3.6, thick: 7),
      mouth: MouthSpec(kind: MouthKind.grin, w: 11, y: 47, amount: 0.5),
    ),
    nose: const NoseSpec(len: 24, proj: 14, width: 9, bulb: 1.0),
    beard: const BeardSpec(style: BeardStyle.full, color: HairColor.inkBlack, mouthY: 47, mouthW: 11, mouthH: 4.5, length: 1),
    headwear: const Ghutra(check: Color(0xFFC8262E), hem: -35, agalTilt: 0, agalSag: 6, width: 0.95, dropY: 84),
    body: const Thobe(color: Cloth.cream),
    behind: (pen, h) => bClipOpen(pen),
    front: (pen, h) {
      const at = Offset(158, 170);
      const rot = 0.04;
      const sz = 1.0;
      final perch = bHandPoint(at, rot, sz, const Offset(0, -14));
      bFalconTail(pen, perch, 1.0);
      bGripHand(pen, at, rot, sz, _leather, sleeve: Cloth.cream);
      bFalcon(pen, perch, 1.0);
      bClipClose(pen);
    },
  ),

  // ── camel: cheeky camel, half-lidded eyes, buck teeth, red-gold headband ──
  CharSpec(
    id: 'camel',
    cutout: true,
    skin: Skin.light,
    head: const HeadSpec(x: 100, y: 76, scale: 0.84, roll: -0.06),
    custom: (pen, h) {
      bClipOpen(pen);
      bCamel(pen, h);
      const eyes = EyeSpec(
        ew: 10.8, eh: 12.6, gap: 18.5, y: -3, lookX: -0.85, lookY: 0.05, irisR: 0.62, pupilR: 0.6, lidTop: 0.14, lidSlant: 0.05, lidBottom: 0.08, lashes: true, iris: Color(0xFF4A2E1B),
      );
      drawEyes(pen, h, eyes, Skin.light);
      drawBrows(
        pen, h,
        const BrowSpec(
          lift: 4, inner: 0, outer: 1, arch: 2.6, thick: 6, color: HairColor.darkBrown,
          left: BrowSpec(lift: 3, inner: 1.5, outer: 0.5, arch: 1.6, thick: 6, color: HairColor.darkBrown),
          right: BrowSpec(lift: 8, inner: -2.5, outer: 0.5, arch: 3.6, thick: 6, color: HairColor.darkBrown),
        ),
        eyes,
      );
      bClipClose(pen);
    },
  ),

  // ── lv10: the majlis guard, a saluki with a star badge ──
  CharSpec(
    id: 'lv10',
    cutout: true,
    skin: Skin.light,
    head: const HeadSpec(x: 100, y: 74, scale: 0.84, roll: 0.05),
    custom: (pen, h) {
      bClipOpen(pen);
      bSaluki(pen, h);
      const eyes = EyeSpec(ew: 9.2, eh: 10.2, gap: 12.8, y: -4, lookX: 0.85, lookY: 0.0, irisR: 0.66, pupilR: 0.58, lidTop: 0.04, iris: Color(0xFF3A2314));
      drawEyes(pen, h, eyes, Skin.light);
      drawBrows(pen, h, const BrowSpec(lift: 5, inner: 3.5, outer: -2.5, arch: 1.4, thick: 5.4, color: HairColor.brown), eyes);
      bClipClose(pen);
    },
  ),

  // ── doctor: kind, white hijab, stethoscope ──
  CharSpec(
    id: 'doctor',
    cutout: true,
    skin: Skin.fair,
    head: const HeadSpec(x: 101, y: 77, scale: 0.88, yaw: 0.35, roll: -0.05, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 12.5, eh: 11.5, gap: 19, lookX: 0.75, lookY: -0.1, irisR: 0.55, pupilR: 0.7, lidBottom: 0.18, lashes: true, iris: Color(0xFF2F6F66)),
      brows: BrowSpec(lift: 7, inner: -1.5, outer: 1.5, arch: 2.6, thick: 5.4),
      mouth: MouthSpec(kind: MouthKind.smile, w: 11, y: 42, amount: 0.75),
    ),
    nose: const NoseSpec(len: 19, proj: 9, width: 6, bulb: 0.6, bridge: 2.4),
    headwear: const Hijab(
      cloth: Tones(Color(0xFFFAF7F6), Color(0xFFB9B8D6), Color(0xFFFFFFFF)),
      flap: true,
      width: 1.15,
      length: 0.9,
    ),
    body: const BCoat(
      coat: Cloth.white,
      inner: Tones(Color(0xFF3FB7A4), Color(0xFF2A8A7E), Color(0xFF7ADCCB)),
    ),
    behind: (pen, h) => bClipOpen(pen),
    front: (pen, h) {
      bClipClose(pen);
      bStethoscope(pen, h, dx: Body.turn(h), top: -20, drop: 22, lean: 9, width: 33);
      final n = h.neckBase;
      bCrossPin(pen, Offset(n.dx - 52 * h.scale, n.dy + 24 * h.scale), 5.2);
    },
  ),
];
