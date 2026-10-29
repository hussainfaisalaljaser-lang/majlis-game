// Character pack 6 = STICKER worker S1: 42 stickers of 7 packs (الأساسي، صدمة، ضحك، القهوة، الزعل، التوتر، المحقق).
// كل ملصق = CharSpec (cutout) يُركَّب بـ parts/s1_sticker.dart ثم يُقص بالأبيض بـ s1_sticker_export.py.
import 'dart:math' as math;

import '../kit.dart';
import '../parts/s1_faces.dart';
import '../parts/s1_hands.dart';
import '../parts/s1_props.dart';


// ألوان مشتركة بين الملصقات
const _red = Color(0xFFC8262E);
const _black = Tones(Color(0xFF332F3B), Color(0xFF1E1B25), Color(0xFF534D63));
const _plum = Tones(Color(0xFFB8396F), Color(0xFF8A2350), Color(0xFFDA6A94));
const _teal = Tones(Color(0xFF3F8068), Color(0xFF2A5B4B), Color(0xFF63A68A));
const _purple = Tones(Color(0xFF5E2F72), Color(0xFF3F1C52), Color(0xFF8350A0));
const _abaya = Tones(Color(0xFF2E2A36), Color(0xFF1A1721), Color(0xFF4B4558));

/// جسم بنت (عباية) بلون الحجاب أو أغمق.
Body _girl([Tones c = _abaya]) => Garment(color: c);

/// ذراع بكم تنتهي بقبضة ماسكة (من [from] تحت لين [to] مكان اليد).
void _holder(Pen pen, Skin skin, Tones sleeve, Offset from, Offset to, {double w = 24, double fist = 10}) {
  s1Blob(pen, [(from, to, w)], sleeve, outline: Style.line * .85, shade: 3);
  if (fist > 0) {
    final p = Path()..addOval(Rect.fromCircle(center: to, radius: fist));
    pen.solid(p, skin.tones, shade: 2.2, hi: .9, w: Style.lineThin * 1.2);
  }
}

/// فنجان ماسكه بيد: ذراع من تحت، الفنجان، وأصابع ملتفة قدامه.
void _cupHeld(Pen pen, Skin skin, Tones sleeve, Offset c, double s, {bool steam = false, bool cold = false}) {
  s1Blob(pen, [(c + Offset(14 * s, 62 * s), c + Offset(2 * s, 20 * s), 22 * s)], sleeve, outline: Style.line * .85, shade: 3);
  s1Cup(pen, c, s: s, steam: steam, cold: cold);
  // الأصابع والإبهام
  for (final b in [(-11.0, 3.0, 4.2), (-6.0, 9.0, 4.6), (1.0, 12.0, 4.6), (8.0, 10.0, 4.4)]) {
    final p = Path()..addOval(Rect.fromCircle(center: c + Offset(b.$1 * s, b.$2 * s), radius: b.$3 * s));
    pen.solid(p, skin.tones, shade: 1.6, hi: .8, w: Style.lineThin * 1.1);
  }
  if (cold) {
    // صقيع خفيف على الفنجان
    s1Spark(pen, c + Offset(10 * s, -2 * s), 4 * s, color: const Color(0xFFD7F0FF), ink: false);
  }
}

final List<CharSpec> pack6 = [
  // ═════════════ stk_basic ═════════════
  // ههههه: ضحك بدموع (عيون مغمضة > <)
  CharSpec(
    id: 'b_laugh',
    cutout: true,
    skin: Skin.tan,
    head: const HeadSpec(x: 100, y: 88, scale: .9, roll: .07, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(open: 0),
      brows: BrowSpec(lift: 9, inner: -2, outer: 1.5, arch: 3.4, thick: 6.4),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 17, y: 43),
    ),
    nose: const NoseSpec(len: 21, proj: 9, width: 7, bulb: .7),
    headwear: const Ghutra(hem: -36, agalTilt: .12),
    front: (pen, h) {
      s1Mouth(pen, h, y: 41, w: 19, depth: 19, teeth: 6, top: -1.5);
      for (final s in const [-1, 1]) {
        s1EyeMark(pen, h, S1EyeMark.chevron, s, w: 10);
        s1TearStream(pen, h, s, len: 34, width: 5.5);
      }
      s1Drop(pen, const Offset(26, 64), 5, rot: -.6);
      s1Drop(pen, const Offset(176, 70), 4.4, rot: .6);
    },
  ),
  // ممم…: يفكر ويده على ذقنه
  CharSpec(
    id: 'b_think',
    cutout: true,
    skin: Skin.fair,
    head: const HeadSpec(x: 96, y: 88, scale: .9, yaw: .5, roll: -.04, shape: FaceShape.oval),
    expr: const Expr(
      eyes: EyeSpec(ew: 11, eh: 9.6, gap: 20, lookX: .85, lookY: -.85, lidTop: .1, lidSlant: .12, irisR: .52, pupilR: .6),
      brows: BrowSpec(
        lift: 6,
        inner: 1,
        outer: 0,
        thick: 6,
        left: BrowSpec(lift: 10, inner: -3, outer: -.5, arch: 3.2, thick: 6),
        right: BrowSpec(lift: 6, inner: 2.5, outer: -1, arch: 1.4, thick: 6),
      ),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 9, y: 43, x: 3),
    ),
    nose: const NoseSpec(len: 22, proj: 12, width: 8),
    headwear: const Ghutra(hem: -35, agalTilt: 0),
    front: (pen, h) {
      drawChinHand(pen, h, Skin.fair, at: const Offset(10, 64), rot: -0.55);
      s1Question(pen, const Offset(172, 40), 12, rot: .2);
    },
  ),
  // شايفك!: نظرة جانبية مشككة
  CharSpec(
    id: 'b_eyes',
    cutout: true,
    skin: Skin.fair,
    head: const HeadSpec(x: 100, y: 90, scale: .9, yaw: .35, roll: -.03, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 12, eh: 10.4, gap: 19, lookX: 1, lookY: .02, lidTop: .4, lidSlant: .1, lidBottom: .08, irisR: .6, pupilR: .6, iris: Color(0xFF2E3B2A)),
      brows: BrowSpec(
        lift: 8,
        thick: 5.4,
        left: BrowSpec(lift: 12, inner: -3.4, outer: .4, arch: 3.4, thick: 5.4),
        right: BrowSpec(lift: 5, inner: 2.4, outer: -.6, arch: 1.2, thick: 5.4),
      ),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 8, y: 44, x: 2),
    ),
    nose: const NoseSpec(len: 19, proj: 9, width: 6, bulb: .6),
    headwear: Hijab(cloth: _black, width: 1.15, flap: true),
    body: _girl(),
    front: (pen, h) {
      // نظرة "👀": خطّان صغيران يبينون التحديق
      s1Spark(pen, const Offset(170, 56), 6);
    },
  ),
  // ششش: إصبع على الشفايف
  CharSpec(
    id: 'b_shh',
    cutout: true,
    skin: Skin.light,
    head: const HeadSpec(x: 100, y: 88, scale: .9, yaw: -.3, roll: .03, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 12, eh: 10.5, gap: 19, lookX: -.9, lookY: -.05, lidTop: .12, irisR: .56, pupilR: .6, lashes: true, iris: Color(0xFF4A2E1C)),
      brows: BrowSpec(lift: 8, inner: -1.5, outer: 1.6, arch: 3, thick: 5),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 7, y: 43),
    ),
    nose: const NoseSpec(len: 19, proj: 9, width: 6, bulb: .6),
    headwear: Hijab(cloth: _plum, width: 1.15, flap: true),
    body: _girl(_plum.darker(.15)),
    front: (pen, h) {
      final m = h.pt(0, 44);
      s1Hand(pen, Skin.light, S1HandPose.shh, at: Offset(m.dx + 4, m.dy + 49), rot: .08, scale: 1.4, sleeve: _plum.darker(.15), arm: 40, armRot: .1);
    },
  ),
  // فهمتك: ابتسامة جانبية
  CharSpec(
    id: 'b_smirk',
    cutout: true,
    skin: Skin.deepTone,
    head: const HeadSpec(x: 98, y: 88, scale: .92, yaw: -.55, roll: .05, shape: FaceShape.square),
    expr: Expr.smug(lookX: -.8, side: 1).copyWith(mouth: const MouthSpec(kind: MouthKind.smirk, side: 1, w: 13, y: 43)),
    nose: const NoseSpec(len: 22, proj: 12, width: 8.5, bulb: .9),
    beard: const BeardSpec(style: BeardStyle.goatee, mouthY: 43, mouthW: 11, mouthH: 4),
    headwear: const Ghutra(check: _red, hem: -35, agalTilt: .05, swept: true, width: .95),
    front: (pen, h) {
      s1Spark(pen, const Offset(172, 44), 7);
      s1Spark(pen, const Offset(160, 62), 4);
    },
  ),
  // لا تكذب!: غضب وإصبع يشاور
  CharSpec(
    id: 'b_angry',
    cutout: true,
    skin: Skin.brown,
    head: const HeadSpec(x: 96, y: 88, scale: .92, yaw: .15, shape: FaceShape.square),
    expr: Expr.angry(lookX: .5),
    nose: const NoseSpec(len: 22, proj: 11, width: 8.5),
    beard: const BeardSpec(style: BeardStyle.goatee, mouthY: 42, mouthW: 12, mouthH: 6),
    headwear: const Ghutra(check: _red, hem: -33, agalTilt: 0),
    front: (pen, h) {
      s1Hand(pen, Skin.brown, S1HandPose.point, at: const Offset(166, 160), rot: -.45, scale: 1.4, arm: 40, armRot: .1);
      s1AngerMark(pen, const Offset(168, 38), 11);
    },
  ),

  // ═════════════ stk_shock ═════════════
  // مستحيل!: فك ساقط
  CharSpec(
    id: 'shock_jaw',
    cutout: true,
    skin: Skin.tan,
    head: const HeadSpec(x: 100, y: 90, scale: .9, roll: -.03, shape: FaceShape.oval),
    expr: const Expr(
      eyes: EyeSpec(ew: 13.5, eh: 13.5, gap: 20, lookX: .1, irisR: .32, pupilR: .6, lid: 3.2),
      brows: BrowSpec(lift: 12, inner: -3, outer: -2.5, arch: 4.2, thick: 6.4),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 10, y: 44),
    ),
    nose: const NoseSpec(len: 21, proj: 9, width: 7, bulb: .7),
    headwear: const Ghutra(hem: -37, agalTilt: -.04),
    front: (pen, h) {
      s1Mouth(pen, h, y: 36, w: 12.5, top: -3, depth: 30, teeth: 4.5, widthBottom: .82);
      s1Exclaim(pen, const Offset(30, 50), 12, rot: -.25);
      s1Exclaim(pen, const Offset(176, 56), 12, rot: .25);
    },
  ),
  // يا ساتر: يدين على الخدود
  CharSpec(
    id: 'shock_hands',
    cutout: true,
    skin: Skin.light,
    head: const HeadSpec(x: 100, y: 90, scale: .88, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 13, eh: 13, gap: 19, lookX: 0, irisR: .36, pupilR: .6, lashes: true, iris: Color(0xFF3A2416)),
      brows: BrowSpec(lift: 11, inner: -4, outer: -1, arch: 3.6, thick: 5.2),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 9, y: 44),
    ),
    nose: const NoseSpec(len: 19, proj: 8, width: 6, bulb: .6),
    headwear: Hijab(cloth: _plum, width: 1.2, flap: true),
    body: _girl(_plum.darker(.15)),
    front: (pen, h) {
      s1Mouth(pen, h, y: 38, w: 9.5, top: -2, depth: 24, teeth: 0, widthBottom: .8);
      s1Hand(pen, Skin.light, S1HandPose.stop, at: const Offset(44, 160), rot: .3, mirror: true, scale: 1.3, sleeve: _plum.darker(.15), arm: 30, armRot: -.1);
      s1Hand(pen, Skin.light, S1HandPose.stop, at: const Offset(156, 160), rot: -.3, scale: 1.3, sleeve: _plum.darker(.15), arm: 30, armRot: .1);
    },
  ),
  // وش صار؟!: يدين مفتوحتين للجنبين
  CharSpec(
    id: 'shock_what',
    cutout: true,
    skin: Skin.brown,
    head: const HeadSpec(x: 100, y: 88, scale: .88, yaw: -.15, shape: FaceShape.square),
    expr: const Expr(
      eyes: EyeSpec(ew: 12.5, eh: 12.5, gap: 20, lookX: -.4, lookY: -.1, irisR: .36, pupilR: .6),
      brows: BrowSpec(lift: 11, inner: -2, outer: -2, arch: 4, thick: 6.4),
      mouth: MouthSpec(kind: MouthKind.oh, w: 11, y: 44, amount: 1.1),
    ),
    nose: const NoseSpec(len: 22, proj: 10, width: 8.5),
    beard: const BeardSpec(style: BeardStyle.goatee, mouthY: 44, mouthW: 9, mouthH: 6),
    headwear: const Ghutra(check: _red, hem: -35),
    front: (pen, h) {
      s1Hand(pen, Skin.brown, S1HandPose.wide, at: const Offset(62, 170), rot: -.8, mirror: true, scale: 1.12, sleeve: Cloth.white, arm: 20, armRot: .1);
      s1Hand(pen, Skin.brown, S1HandPose.wide, at: const Offset(138, 170), rot: .8, scale: 1.12, sleeve: Cloth.white, arm: 20, armRot: -.1);
      s1Question(pen, const Offset(30, 40), 11, rot: -.25);
      s1Exclaim(pen, const Offset(176, 38), 11, rot: .25);
    },
  ),
  // لا لا لا: يد توقف، ووجه متضايق
  CharSpec(
    id: 'shock_no',
    cutout: true,
    skin: Skin.light,
    head: const HeadSpec(x: 96, y: 90, scale: .88, yaw: -.25, roll: -.05, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(open: 0),
      brows: BrowSpec(lift: 8, inner: -5, outer: 2, arch: 2, thick: 5),
      mouth: MouthSpec(kind: MouthKind.frown, w: 9, y: 45, amount: 1.1),
    ),
    nose: const NoseSpec(len: 19, proj: 8, width: 6, bulb: .6),
    glasses: const GlassesSpec(kind: GlassesKind.round, thick: 3.0),
    headwear: Hijab(cloth: _teal, underCap: Cloth.white, capEdge: -20, width: 1.2, flap: true),
    body: _girl(_teal.darker(.2)),
    front: (pen, h) {
      for (final s in const [-1, 1]) {
        s1EyeMark(pen, h, S1EyeMark.arcDown, s, gap: 19, w: 9, lift: 6.5);
      }
      s1Hand(pen, Skin.light, S1HandPose.stop, at: const Offset(160, 168), rot: .1, scale: 1.45, sleeve: _teal.darker(.2), arm: 30, armRot: .05);
      s1Drop(pen, h.pt(-46, -18), 5, rot: -.3);
      s1Drop(pen, h.pt(-50, 4), 3.6, rot: -.4);
    },
  ),
  // دوّخوني: عيون دوامة ونجوم
  CharSpec(
    id: 'shock_dizzy',
    cutout: true,
    skin: Skin.deepTone,
    head: const HeadSpec(x: 100, y: 92, scale: .88, roll: .1, shape: FaceShape.oval),
    expr: const Expr(
      eyes: EyeSpec(open: 0),
      brows: BrowSpec(lift: 11, inner: -3, outer: 1, arch: 3.2, thick: 6),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 10, y: 44),
    ),
    nose: const NoseSpec(len: 21, proj: 9, width: 7.5, bulb: .8),
    headwear: const Ghutra(check: _red, hem: -36, agalTilt: .1),
    front: (pen, h) {
      for (final s in const [-1, 1]) {
        s1EyeMark(pen, h, S1EyeMark.spiral, s, gap: 19, w: 11.5, lift: 6.5);
      }
      final w = h.path(svg('M-12 45 Q-8 40 -4 45 T4 45 T12 45'), lift: 3);
      pen.line(w, w: 2.2 * h.scale, color: Style.ink);
      s1Star5(pen, const Offset(40, 30), 8, rot: .2);
      s1Star5(pen, const Offset(100, 6), 7, rot: -.1);
      s1Star5(pen, const Offset(162, 30), 8, rot: .3);
    },
  ),
  // انصدمت: يد على الجبين
  CharSpec(
    id: 'shock_faint',
    cutout: true,
    skin: Skin.light,
    head: const HeadSpec(x: 98, y: 92, scale: .9, roll: -.12, shape: FaceShape.oval),
    expr: const Expr(
      eyes: EyeSpec(open: 0),
      brows: BrowSpec(lift: 9, inner: -5, outer: 2.5, arch: 2, thick: 5.6),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 10, y: 44),
    ),
    nose: const NoseSpec(len: 21, proj: 9, width: 7, bulb: .7),
    beard: const BeardSpec(style: BeardStyle.stubble, mouthY: 45, mouthW: 8, mouthH: 5),
    headwear: const Ghutra(hem: -36, agalTilt: -.1),
    front: (pen, h) {
      for (final s in const [-1, 1]) {
        s1EyeMark(pen, h, S1EyeMark.arcDown, s, w: 10, lift: 6.5);
      }
      s1Mouth(pen, h, y: 44, w: 6.5, top: -1, depth: 10, teeth: 0, widthBottom: .9);
      s1Hand(pen, Skin.light, S1HandPose.flat, at: const Offset(156, 78), rot: -1.5, scale: 1.4, sleeve: Cloth.white, arm: 14, armRot: 0);
    },
  ),

  // ═════════════ stk_laugh ═════════════
  // ميت ضحك
  CharSpec(
    id: 'laugh_tears',
    cutout: true,
    skin: Skin.deepTone,
    head: const HeadSpec(x: 100, y: 90, scale: .9, roll: -.06, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(open: 0),
      brows: BrowSpec(lift: 10, inner: -2, outer: 2, arch: 3.4, thick: 6.4),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 17, y: 43),
    ),
    nose: const NoseSpec(len: 21, proj: 9, width: 8, bulb: .8),
    headwear: const Ghutra(check: _red, hem: -36, agalTilt: -.08),
    front: (pen, h) {
      s1Mouth(pen, h, y: 41, w: 20, depth: 20, teeth: 6.5, top: -1.5);
      for (final s in const [-1, 1]) {
        s1EyeMark(pen, h, S1EyeMark.chevron, s, w: 10);
        s1TearStream(pen, h, s, len: 36, width: 5.5);
        s1ShakeLines(pen, Offset(100 + s * 82.0, 100), 18, s, w: 2.6);
      }
    },
  ),
  // هههههههه: ضحكة طايحة
  CharSpec(
    id: 'laugh_roll',
    cutout: true,
    skin: Skin.fair,
    head: const HeadSpec(x: 98, y: 90, scale: .88, roll: -.2, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(open: 0),
      brows: BrowSpec(lift: 10, inner: -2, outer: 2, arch: 3, thick: 5),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 17, y: 43),
    ),
    nose: const NoseSpec(len: 19, proj: 8, width: 6, bulb: .6),
    headwear: Hijab(cloth: _black, width: 1.2, flap: true),
    body: _girl(),
    front: (pen, h) {
      s1Mouth(pen, h, y: 41, w: 20, depth: 21, teeth: 6.5, top: -1.5);
      for (final s in const [-1, 1]) {
        s1EyeMark(pen, h, S1EyeMark.chevron, s, gap: 19, w: 9.5);
        s1TearStream(pen, h, s, gap: 19, len: 34, width: 5.5);
      }
      s1Drop(pen, const Offset(22, 60), 5, rot: -.7);
      s1Drop(pen, const Offset(178, 52), 5, rot: .7);
      s1Drop(pen, const Offset(190, 86), 3.6, rot: .9);
    },
  ),
  // قوية!: تصفيق
  CharSpec(
    id: 'laugh_clap',
    cutout: true,
    skin: Skin.light,
    head: const HeadSpec(x: 100, y: 84, scale: .88, shape: FaceShape.oval),
    expr: const Expr(
      eyes: EyeSpec(open: 0),
      brows: BrowSpec(lift: 10, inner: -1, outer: 2, arch: 3.6, thick: 6),
      mouth: MouthSpec(kind: MouthKind.grin, w: 15, y: 43, amount: 1),
    ),
    nose: const NoseSpec(len: 21, proj: 9, width: 7, bulb: .7),
    headwear: const Ghutra(hem: -35, agalTilt: .06),
    front: (pen, h) {
      for (final s in const [-1, 1]) {
        s1EyeMark(pen, h, S1EyeMark.arcUp, s, w: 10);
      }
      s1Hand(pen, Skin.light, S1HandPose.flat, at: const Offset(86, 186), rot: .32, mirror: true, scale: 1.3, sleeve: Cloth.white, arm: 20, armRot: .0);
      s1Hand(pen, Skin.light, S1HandPose.flat, at: const Offset(114, 186), rot: -.32, scale: 1.3, sleeve: Cloth.white, arm: 20, armRot: .0);
      for (final side in const [-1, 1]) {
        for (var i = 0; i < 3; i++) {
          final a = (-.35 + i * .5) * side;
          final c0 = Offset(100 + side * 36.0, 156);
          final d = Offset(math.sin(a) * side + side * .75, -math.cos(a) * .55 - .15 * i);
          final n = d / d.distance;
          final p0 = c0 + n * 8, p1 = c0 + n * 22;
          final l = Path()
            ..moveTo(p0.dx, p0.dy)
            ..lineTo(p1.dx, p1.dy);
          pen.line(l, w: 5, color: Style.ink);
          pen.line(l, w: 2.8, color: const Color(0xFFFFD43B));
        }
      }
    },
  ),
  // شوفوه!: يضحك ويشاور
  CharSpec(
    id: 'laugh_point',
    cutout: true,
    skin: Skin.brown,
    head: const HeadSpec(x: 94, y: 90, scale: .9, yaw: -.3, roll: .08, shape: FaceShape.square),
    expr: const Expr(
      eyes: EyeSpec(open: 0),
      brows: BrowSpec(lift: 10, inner: -2, outer: 2, arch: 3.4, thick: 6.4),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 17, y: 43),
    ),
    nose: const NoseSpec(len: 22, proj: 11, width: 8.5, bulb: .9),
    headwear: const Ghutra(check: _red, hem: -35, agalTilt: .1, swept: true),
    front: (pen, h) {
      s1Mouth(pen, h, y: 41, w: 19, depth: 19, teeth: 6.5, top: -1.5, tilt: 1.5);
      for (final s in const [-1, 1]) {
        s1EyeMark(pen, h, S1EyeMark.chevron, s, w: 10);
        s1TearStream(pen, h, s, len: 32, width: 5.2);
      }
      s1Hand(pen, Skin.brown, S1HandPose.point, at: const Offset(142, 168), rot: .85, scale: 1.45, sleeve: Cloth.white, arm: 30, armRot: .0);
    },
  ),
  // هيهي: ابتسامة خبيثة
  CharSpec(
    id: 'laugh_grin',
    cutout: true,
    skin: Skin.tan,
    blush: 2.2,
    head: const HeadSpec(x: 100, y: 90, scale: .88, roll: .1, yaw: .15, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(open: 0),
      brows: BrowSpec(lift: 10, inner: -1, outer: 2, arch: 3.4, thick: 5),
      mouth: MouthSpec(kind: MouthKind.grin, w: 14, y: 43, amount: .85),
    ),
    nose: const NoseSpec(len: 19, proj: 8, width: 6, bulb: .6),
    headwear: Hijab(cloth: _purple, width: 1.08, flap: true),
    body: _girl(_purple.darker(.2)),
    front: (pen, h) {
      for (final s in const [-1, 1]) {
        s1EyeMark(pen, h, S1EyeMark.arcUp, s, gap: 19, w: 9.5);
      }
      s1Spark(pen, const Offset(168, 46), 7);
      s1Spark(pen, const Offset(34, 56), 5);
    },
  ),
  // تمزح؟: غمزة ولسان
  CharSpec(
    id: 'laugh_wink',
    cutout: true,
    skin: Skin.fair,
    head: const HeadSpec(x: 98, y: 90, scale: .9, yaw: -.2, roll: .08, shape: FaceShape.oval),
    expr: const Expr(
      eyes: EyeSpec(ew: 12.5, eh: 12.5, gap: 20, lookX: -.2, irisR: .5, pupilR: .6, right: EyeSpec(open: 0)),
      brows: BrowSpec(
        lift: 8,
        thick: 6,
        left: BrowSpec(lift: 12, inner: -3, outer: 0, arch: 3.6, thick: 6),
        right: BrowSpec(lift: 6, inner: 1, outer: 1.5, arch: 2.4, thick: 6),
      ),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 14, y: 43),
    ),
    nose: const NoseSpec(len: 21, proj: 10, width: 7.5, bulb: .8),
    headwear: const Ghutra(hem: -36, agalTilt: .1, swept: true),
    front: (pen, h) {
      s1EyeMark(pen, h, S1EyeMark.arcUp, 1, w: 11, lift: 6.5);
      s1TongueOut(pen, h, y: 42, w: 14, len: 17, lean: 3);
      s1Question(pen, const Offset(172, 42), 11, rot: .2);
    },
  ),

  // ═════════════ stk_coffee ═════════════
  // تقهوى: يمسك الفنجان وعيونه مغمضة من اللذة
  CharSpec(
    id: 'cof_cup',
    cutout: true,
    skin: Skin.tan,
    head: const HeadSpec(x: 94, y: 88, scale: .9, yaw: .2, roll: -.05, shape: FaceShape.oval),
    expr: const Expr(
      eyes: EyeSpec(open: 0),
      brows: BrowSpec(lift: 9, inner: -1, outer: 2, arch: 3.4, thick: 5.8),
      mouth: MouthSpec(kind: MouthKind.smile, w: 11, y: 44, amount: .8),
    ),
    nose: const NoseSpec(len: 21, proj: 10, width: 7, bulb: .7),
    headwear: const Ghutra(hem: -35, agalTilt: -.03),
    front: (pen, h) {
      for (final s in const [-1, 1]) {
        s1EyeMark(pen, h, S1EyeMark.arcUp, s, w: 10, lift: 6.5);
      }
      _cupHeld(pen, Skin.tan, Cloth.white, const Offset(150, 132), 1.25, steam: true);
    },
  ),
  // صبّ صبّ: الدلة تصب في الفنجان
  CharSpec(
    id: 'cof_pour',
    cutout: true,
    skin: Skin.light,
    head: const HeadSpec(x: 92, y: 90, scale: .9, yaw: .55, roll: .02, shape: FaceShape.oval),
    expr: const Expr(
      eyes: EyeSpec(ew: 12, eh: 11, gap: 20, lookX: .9, lookY: .7, irisR: .5, pupilR: .6, lidTop: .05),
      brows: BrowSpec(lift: 8, inner: -2, outer: 1, arch: 3.2, thick: 6),
      mouth: MouthSpec(kind: MouthKind.smile, w: 9, y: 44, amount: .5, x: 2),
    ),
    nose: const NoseSpec(len: 22, proj: 12, width: 8),
    headwear: const Ghutra(hem: -35, agalTilt: 0),
    front: (pen, h) {
      // خط القهوة من منقار الدلة للفنجان
      final stream = Path()
        ..moveTo(150, 58)
        ..cubicTo(148, 78, 152, 96, 150, 116);
      pen.line(stream, w: 6.2, color: Style.ink);
      pen.line(stream, w: 3.4, color: const Color(0xFF6B3A1E));
      pen.line(Path()..moveTo(149, 62)..cubicTo(147, 78, 151, 92, 149, 108), w: 1.0, color: const Color(0xFFC98B52));
      _cupHeld(pen, Skin.light, Cloth.white, const Offset(150, 134), 1.2);
      s1Dallah(pen, const Offset(168, 62), s: .7, rot: -.95);
    },
  ),
  // حيّاك: ترحيب بيد مفتوحة
  CharSpec(
    id: 'cof_welcome',
    cutout: true,
    skin: Skin.fair,
    head: const HeadSpec(x: 96, y: 88, scale: .9, yaw: .1, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 12.5, eh: 11.5, gap: 20, lookX: .2, lidBottom: .3, irisR: .5, pupilR: .6),
      brows: BrowSpec(lift: 9, inner: -1, outer: 1.6, arch: 3.6, thick: 6),
      mouth: MouthSpec(kind: MouthKind.grin, w: 15, y: 43, amount: .85),
    ),
    nose: const NoseSpec(len: 21, proj: 9, width: 7, bulb: .7),
    headwear: const Ghutra(hem: -36, agalTilt: .05),
    front: (pen, h) {
      s1Hand(pen, Skin.fair, S1HandPose.open, at: const Offset(150, 166), rot: .2, scale: 1.5, sleeve: Cloth.white, arm: 24, armRot: -.1);
      for (var i = 0; i < 2; i++) {
        final p = Path()
          ..moveTo(180 + i * 5.0, 80 + i * 4.0)
          ..quadraticBezierTo(187 + i * 6, 92, 181 + i * 5, 104 - i * 2);
        pen.line(p, w: 4.4, color: Style.ink);
        pen.line(p, w: 2.2, color: const Color(0xFFFFFFFF));
      }
    },
  ),
  // بردت القهوة: فنجان بارد وحزن
  CharSpec(
    id: 'cof_cold',
    cutout: true,
    skin: Skin.deepTone,
    head: const HeadSpec(x: 96, y: 90, scale: .9, yaw: -.3, roll: .06, shape: FaceShape.square),
    expr: const Expr(
      eyes: EyeSpec(ew: 12, eh: 11, gap: 20, lookX: .6, lookY: .9, lidSlant: -.3, irisR: .55, pupilR: .6),
      brows: BrowSpec(lift: 8, inner: -5, outer: 2, arch: 2, thick: 6),
      mouth: MouthSpec(kind: MouthKind.frown, w: 10, y: 45, amount: 1),
    ),
    nose: const NoseSpec(len: 22, proj: 11, width: 8.5),
    beard: const BeardSpec(style: BeardStyle.short, color: HairColor.inkBlack, mouthY: 45, mouthW: 8, mouthH: 3.4),
    headwear: const Ghutra(check: _red, hem: -35, swept: true),
    front: (pen, h) {
      _cupHeld(pen, Skin.deepTone, Cloth.white, const Offset(148, 134), 1.25, cold: true);
      // برودة: ندفة صغيرة
      s1Spark(pen, const Offset(166, 96), 7, color: const Color(0xFFBFE6FF));
      s1Spark(pen, const Offset(134, 100), 4, color: const Color(0xFFBFE6FF));
      s1Drop(pen, h.pt(40, -26), 5, rot: .3);
    },
  ),
  // قهوة وتمر
  CharSpec(
    id: 'cof_dates',
    cutout: true,
    skin: Skin.tan,
    head: const HeadSpec(x: 100, y: 86, scale: .86, roll: .06, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(open: 0),
      brows: BrowSpec(lift: 9, inner: -1, outer: 2, arch: 3.4, thick: 5),
      mouth: MouthSpec(kind: MouthKind.smile, w: 12, y: 44, amount: 1),
    ),
    nose: const NoseSpec(len: 19, proj: 8, width: 6, bulb: .6),
    headwear: Hijab(cloth: _plum, width: 1.1, flap: true),
    body: _girl(_plum.darker(.15)),
    front: (pen, h) {
      for (final s in const [-1, 1]) {
        s1EyeMark(pen, h, S1EyeMark.arcUp, s, gap: 19, w: 9.5, lift: 6.5);
      }
      _cupHeld(pen, Skin.tan, _plum.darker(.15), const Offset(40, 134), 1.15, steam: true);
      _holder(pen, Skin.tan, _plum.darker(.15), const Offset(176, 196), const Offset(158, 156));
      s1Dates(pen, const Offset(158, 146), s: 1.0, rot: -.08);
    },
  ),
  // بس بس: يمنع بالكف
  CharSpec(
    id: 'cof_enough',
    cutout: true,
    skin: Skin.brown,
    head: const HeadSpec(x: 100, y: 90, scale: .9, yaw: -.15, roll: -.04, shape: FaceShape.square),
    expr: const Expr(
      eyes: EyeSpec(open: 0),
      brows: BrowSpec(lift: 8, inner: 1, outer: 0, arch: 2, thick: 6),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 9, y: 45),
    ),
    nose: const NoseSpec(len: 22, proj: 10, width: 8.5),
    beard: const BeardSpec(style: BeardStyle.goatee, mouthY: 45, mouthW: 9, mouthH: 4),
    headwear: const Ghutra(check: _red, hem: -35),
    front: (pen, h) {
      for (final s in const [-1, 1]) {
        s1EyeMark(pen, h, S1EyeMark.arcDown, s, w: 10, lift: 6.5);
      }
      _cupHeld(pen, Skin.brown, Cloth.white, const Offset(46, 136), 1.15);
      s1Hand(pen, Skin.brown, S1HandPose.stop, at: const Offset(156, 168), rot: .12, scale: 1.5, sleeve: Cloth.white, arm: 28, armRot: .05);
      s1Drop(pen, h.pt(46, -22), 4.4, rot: .3);
    },
  ),

  // ═════════════ stk_angry ═════════════
  // معصّب: بخار من الراس
  CharSpec(
    id: 'ang_steam',
    cutout: true,
    skin: Skin.deepTone,
    head: const HeadSpec(x: 100, y: 92, scale: .88, shape: FaceShape.square),
    expr: Expr.angry(lookX: 0),
    nose: const NoseSpec(len: 22, proj: 10, width: 8.5),
    headwear: const Ghutra(check: _red, hem: -33),
    front: (pen, h) {
      s1Puff(pen, const Offset(30, 46), 15);
      s1Puff(pen, const Offset(172, 40), 15);
      s1Puff(pen, const Offset(18, 70), 8);
      s1AngerMark(pen, const Offset(166, 76), 9);
    },
  ),
  // ما راح أسامح: برود وغضب
  CharSpec(
    id: 'ang_never',
    cutout: true,
    skin: Skin.fair,
    head: const HeadSpec(x: 100, y: 90, scale: .9, yaw: .12, shape: FaceShape.round),
    expr: Expr(
      eyes: const EyeSpec(ew: 11, eh: 9.6, gap: 19, lookX: .5, lidTop: .18, lidSlant: .55, irisR: .52, pupilR: .62, lid: 3.4),
      brows: const BrowSpec(lift: 5, inner: 6.5, outer: -3, arch: .6, thick: 6, taper: .7),
      mouth: const MouthSpec(kind: MouthKind.frown, w: 10, y: 46, amount: 1.1),
    ),
    nose: const NoseSpec(len: 19, proj: 9, width: 6, bulb: .6),
    headwear: Hijab(cloth: _black, width: 1.15, flap: true),
    body: _girl(),
    front: (pen, h) {
      s1AngerMark(pen, const Offset(170, 44), 10);
    },
  ),
  // زعلت: دمعة وزعل
  CharSpec(
    id: 'ang_upset',
    cutout: true,
    skin: Skin.light,
    head: const HeadSpec(x: 100, y: 90, scale: .9, yaw: -.15, roll: -.05, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 13, eh: 12.5, gap: 19, lookX: -.5, lookY: .5, lidSlant: -.4, irisR: .66, pupilR: .5, lashes: true, iris: Color(0xFF3A2416)),
      brows: BrowSpec(lift: 8, inner: -6, outer: 2.4, arch: 1.6, thick: 5),
      mouth: MouthSpec(kind: MouthKind.frown, w: 8, y: 46, amount: 1.3),
    ),
    nose: const NoseSpec(len: 19, proj: 8, width: 6, bulb: .6),
    headwear: Hijab(cloth: _purple, width: 1.12, flap: true),
    body: _girl(_purple.darker(.2)),
    front: (pen, h) {
      s1TearStream(pen, h, 1, gap: 19, y: 10, len: 30, width: 4.6);
      s1Drop(pen, h.pt(-34, 24), 4.4, rot: -.2);
    },
  ),
  // طفشت: ملل والخد على القبضة
  CharSpec(
    id: 'ang_bored',
    cutout: true,
    skin: Skin.light,
    head: const HeadSpec(x: 104, y: 90, scale: .9, yaw: -.45, roll: .1, shape: FaceShape.oval),
    expr: const Expr(
      eyes: EyeSpec(ew: 12, eh: 10, gap: 20, lookX: -.9, lookY: -.2, lidTop: .55, lidSlant: -.05, irisR: .56, pupilR: .6),
      brows: BrowSpec(lift: 6, inner: 1.5, outer: 1.5, arch: 1.4, thick: 5.6),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 9, y: 45, x: -2),
    ),
    nose: const NoseSpec(len: 22, proj: 12, width: 8),
    headwear: const Ghutra(hem: -34, agalTilt: .06, swept: true),
    front: (pen, h) {
      drawChinHand(pen, h, Skin.light, at: const Offset(-8, 64), rot: .5, mirror: true);
      s1Puff(pen, const Offset(30, 50), 7);
      s1Puff(pen, const Offset(18, 36), 4.5);
    },
  ),
  // أخ منكم: كف على الوجه
  CharSpec(
    id: 'ang_ugh',
    cutout: true,
    skin: Skin.tan,
    head: const HeadSpec(x: 100, y: 90, scale: .9, yaw: .1, roll: -.06, shape: FaceShape.oval),
    expr: Expr(
      eyes: const EyeSpec(ew: 11, eh: 9.4, gap: 20, lookX: .6, lidTop: .3, lidSlant: .3, irisR: .5, pupilR: .6),
      brows: const BrowSpec(lift: 6, inner: 4.5, outer: -2, arch: 1, thick: 6.2),
      mouth: const MouthSpec(kind: MouthKind.clenched, w: 10, y: 45, amount: .6),
    ),
    nose: const NoseSpec(len: 21, proj: 10, width: 7.5),
    headwear: const Ghutra(hem: -35, agalTilt: .05),
    front: (pen, h) {
      s1Hand(pen, Skin.tan, S1HandPose.wide, at: const Offset(72, 166), rot: .15, mirror: true, scale: 1.7, sleeve: Cloth.white, arm: 20, armRot: -.2);
    },
  ),
  // تعال!: قبضة مرفوعة
  CharSpec(
    id: 'ang_fist',
    cutout: true,
    skin: Skin.brown,
    head: const HeadSpec(x: 96, y: 90, scale: .9, yaw: .2, shape: FaceShape.square),
    expr: Expr.angry(lookX: .4),
    nose: const NoseSpec(len: 22, proj: 11, width: 8.5),
    beard: const BeardSpec(style: BeardStyle.goatee, mouthY: 42, mouthW: 12, mouthH: 6),
    headwear: const Ghutra(check: _red, hem: -33),
    front: (pen, h) {
      s1Hand(pen, Skin.brown, S1HandPose.fistPose, at: const Offset(158, 146), rot: -.12, scale: 1.4, sleeve: Cloth.white, arm: 40, armRot: .05);
      s1AngerMark(pen, const Offset(170, 46), 10);
    },
  ),

  // ═════════════ stk_nervous ═════════════
  // أوبس: عرق وعيون تدور
  CharSpec(
    id: 'nerv_sweat',
    cutout: true,
    skin: Skin.tan,
    head: const HeadSpec(x: 100, y: 90, scale: .9, yaw: -.2, roll: .04, shape: FaceShape.oval),
    expr: const Expr(
      eyes: EyeSpec(ew: 13, eh: 13, gap: 20, lookX: -.95, lookY: .1, irisR: .36, pupilR: .6),
      brows: BrowSpec(lift: 10, inner: -5, outer: 1, arch: 2.4, thick: 5.8),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 10, y: 45),
    ),
    nose: const NoseSpec(len: 21, proj: 10, width: 7, bulb: .7),
    headwear: const Ghutra(hem: -36, agalTilt: .04),
    front: (pen, h) {
      final w = h.path(svg('M-12 46 Q-8 40 -4 46 T4 46 T12 46'), lift: 3);
      pen.line(w, w: 2.4 * h.scale, color: Style.ink);
      s1Drop(pen, h.pt(44, -22), 6, rot: .25);
      s1Drop(pen, h.pt(50, 4), 4, rot: .35);
      s1Drop(pen, const Offset(24, 70), 4.4, rot: -.5);
    },
  ),
  // فشلة: يغطي وجهه بيديه
  CharSpec(
    id: 'nerv_cover',
    cutout: true,
    skin: Skin.light,
    blush: 2.4,
    head: const HeadSpec(x: 100, y: 90, scale: .88, roll: .03, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 12, eh: 11, gap: 19, lookX: -.8, lookY: .4, lidSlant: -.3, irisR: .55, pupilR: .6, lashes: true, iris: Color(0xFF3A2416)),
      brows: BrowSpec(lift: 8, inner: -5, outer: 2, arch: 2, thick: 5),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 6, y: 45),
    ),
    nose: const NoseSpec(len: 19, proj: 8, width: 6, bulb: .6),
    headwear: Hijab(cloth: _plum, width: 1.12, flap: true),
    body: _girl(_plum.darker(.15)),
    front: (pen, h) {
      s1Hand(pen, Skin.light, S1HandPose.stop, at: const Offset(70, 168), rot: .42, mirror: true, scale: 1.5, sleeve: _plum.darker(.15), arm: 24, armRot: -.2);
      s1Hand(pen, Skin.light, S1HandPose.stop, at: const Offset(130, 168), rot: -.42, scale: 1.5, sleeve: _plum.darker(.15), arm: 24, armRot: .2);
    },
  ),
  // قلبي يدق
  CharSpec(
    id: 'nerv_heart',
    cutout: true,
    skin: Skin.brown,
    head: const HeadSpec(x: 96, y: 88, scale: .88, yaw: -.15, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 11, eh: 11, gap: 19, lookX: .4, lookY: -.1, irisR: .42, pupilR: .6, lashes: true, iris: Color(0xFF3A2416)),
      brows: BrowSpec(lift: 10, inner: -4, outer: 1.5, arch: 2.6, thick: 5),
      mouth: MouthSpec(kind: MouthKind.oh, w: 9, y: 45, amount: 1),
    ),
    nose: const NoseSpec(len: 19, proj: 8, width: 6.4, bulb: .6),
    glasses: const GlassesSpec(kind: GlassesKind.round, thick: 3.0),
    headwear: Hijab(cloth: _teal, underCap: Cloth.white, capEdge: -20, width: 1.15, flap: true),
    body: _girl(_teal.darker(.2)),
    front: (pen, h) {
      s1HeartBeat(pen, const Offset(160, 132), 15);
      s1Heart(pen, const Offset(182, 100), 6, rot: .3);
      s1ShakeLines(pen, const Offset(18, 96), 16, -1, w: 2.4);
    },
  ),
  // يا حظي: يدين فاضيتين وحسرة
  CharSpec(
    id: 'nerv_luck',
    cutout: true,
    skin: Skin.deepTone,
    head: const HeadSpec(x: 100, y: 88, scale: .88, roll: .05, shape: FaceShape.square),
    expr: const Expr(
      eyes: EyeSpec(ew: 12, eh: 11, gap: 20, lookX: .2, lookY: .5, lidSlant: -.35, irisR: .55, pupilR: .6),
      brows: BrowSpec(lift: 8, inner: -6, outer: 2.5, arch: 2, thick: 6),
      mouth: MouthSpec(kind: MouthKind.frown, w: 10, y: 45, amount: 1.2),
    ),
    nose: const NoseSpec(len: 22, proj: 10, width: 8.5),
    headwear: const Ghutra(check: _red, hem: -34, agalTilt: .05),
    front: (pen, h) {
      s1TearStream(pen, h, -1, len: 30, width: 4.8);
      s1Hand(pen, Skin.deepTone, S1HandPose.wide, at: const Offset(56, 174), rot: -1.0, mirror: true, scale: 1.1, sleeve: Cloth.white, arm: 16, armRot: .1);
      s1Hand(pen, Skin.deepTone, S1HandPose.wide, at: const Offset(144, 174), rot: 1.0, scale: 1.1, sleeve: Cloth.white, arm: 16, armRot: -.1);
    },
  ),
  // مو أنا: يدين مرفوعتين وبراءة مزيفة
  CharSpec(
    id: 'nerv_notme',
    cutout: true,
    skin: Skin.tan,
    head: const HeadSpec(x: 100, y: 88, scale: .88, yaw: .4, shape: FaceShape.oval),
    expr: const Expr(
      eyes: EyeSpec(ew: 12, eh: 11, gap: 20, lookX: 1, lookY: .05, lidTop: .18, irisR: .5, pupilR: .6),
      brows: BrowSpec(lift: 9, inner: -3, outer: 1, arch: 2.6, thick: 6),
      mouth: MouthSpec(kind: MouthKind.smile, w: 10, y: 45, amount: .45),
    ),
    nose: const NoseSpec(len: 22, proj: 12, width: 8),
    beard: const BeardSpec(style: BeardStyle.goatee, mouthY: 45, mouthW: 9, mouthH: 4),
    headwear: const Ghutra(hem: -35, swept: true),
    front: (pen, h) {
      s1Hand(pen, Skin.tan, S1HandPose.stop, at: const Offset(44, 172), rot: -.18, mirror: true, scale: 1.25, sleeve: Cloth.white, arm: 20, armRot: .1);
      s1Hand(pen, Skin.tan, S1HandPose.stop, at: const Offset(156, 172), rot: .18, scale: 1.25, sleeve: Cloth.white, arm: 20, armRot: -.1);
      s1Drop(pen, h.pt(-44, -22), 5.2, rot: -.2);
    },
  ),
  // يا ويلي: أسنان مطبقة وهلع
  CharSpec(
    id: 'nerv_bite',
    cutout: true,
    skin: Skin.fair,
    head: const HeadSpec(x: 100, y: 90, scale: .9, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 13, eh: 13, gap: 19, lookX: -.3, irisR: .34, pupilR: .6, lashes: true, iris: Color(0xFF3A2416)),
      brows: BrowSpec(lift: 11, inner: -5, outer: 1, arch: 2.6, thick: 5.2),
      mouth: MouthSpec(kind: MouthKind.clenched, w: 11, y: 45, amount: .8),
    ),
    nose: const NoseSpec(len: 19, proj: 8, width: 6, bulb: .6),
    headwear: Hijab(cloth: _black, width: 1.15, flap: true),
    body: _girl(),
    front: (pen, h) {
      s1Drop(pen, h.pt(-48, -20), 5.2, rot: -.3);
      s1Drop(pen, h.pt(50, 0), 4.4, rot: .4);
      s1ShakeLines(pen, const Offset(18, 100), 16, -1, w: 2.4);
      s1ShakeLines(pen, const Offset(182, 100), 16, 1, w: 2.4);
    },
  ),

  // ═════════════ stk_detective ═════════════
  // مين الخاين؟: عدسة على العين
  CharSpec(
    id: 'det_who',
    cutout: true,
    skin: Skin.fair,
    head: const HeadSpec(x: 94, y: 90, scale: .9, yaw: -.2, roll: .04, shape: FaceShape.lean),
    expr: const Expr(
      eyes: EyeSpec(ew: 11.5, eh: 9.6, gap: 20, lookX: .6, lookY: -.1, lidTop: .1, lidSlant: .2, crease: true, irisR: .5, pupilR: .6, iris: Color(0xFF5A3C26)),
      brows: BrowSpec(lift: 7, inner: 1.5, outer: 0, arch: 2.4, thick: 6.4, color: HairColor.grey),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 9, y: 46),
    ),
    nose: const NoseSpec(len: 23, proj: 12, width: 9, bulb: 1.1),
    beard: const BeardSpec(style: BeardStyle.full, color: HairColor.white, mouthY: 46, mouthW: 8, mouthH: 3.2, length: 4),
    headwear: const Ghutra(hem: -35),
    front: (pen, h) {
      final e = h.pt(20, 0);
      _holder(pen, Skin.fair, Cloth.white, const Offset(190, 210), Offset(e.dx + 28, e.dy + 36), fist: 8);
      s1Magnifier(pen, e, s: 1.12, rot: 0);
      s1Question(pen, const Offset(176, 34), 12, rot: .2);
      s1Question(pen, const Offset(22, 40), 9, rot: -.25);
    },
  ),
  // عندي دليل: ورقة بيدها
  CharSpec(
    id: 'det_clue',
    cutout: true,
    skin: Skin.tan,
    head: const HeadSpec(x: 92, y: 90, scale: .88, yaw: .2, roll: -.04, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(ew: 11, eh: 11, gap: 19, lookX: .3, irisR: .5, pupilR: .6, lashes: true, lidBottom: .2, iris: Color(0xFF3A2416)),
      brows: BrowSpec(lift: 9, inner: -1, outer: 2, arch: 3.4, thick: 5),
      mouth: MouthSpec(kind: MouthKind.grin, w: 13, y: 44, amount: .8),
    ),
    nose: const NoseSpec(len: 19, proj: 9, width: 6, bulb: .6),
    glasses: const GlassesSpec(kind: GlassesKind.round, thick: 3.0),
    headwear: Hijab(cloth: _teal, underCap: Cloth.white, capEdge: -20, width: 1.1, flap: true),
    body: _girl(_teal.darker(.2)),
    front: (pen, h) {
      _holder(pen, Skin.tan, _teal.darker(.2), const Offset(176, 205), const Offset(156, 150), fist: 8);
      s1Paper(pen, const Offset(158, 118), s: 1.1, rot: .16);
    },
  ),
  // أراقبكم: منظار
  CharSpec(
    id: 'det_watch',
    cutout: true,
    skin: Skin.deepTone,
    head: const HeadSpec(x: 100, y: 90, scale: .9, shape: FaceShape.square),
    expr: const Expr(
      eyes: EyeSpec(open: 0),
      brows: BrowSpec(lift: 17, inner: 2, outer: -1, arch: 2, thick: 6.4),
      mouth: MouthSpec(kind: MouthKind.smirk, side: 1, w: 12, y: 46, amount: .8),
    ),
    nose: const NoseSpec(len: 22, proj: 10, width: 8.5),
    headwear: const Ghutra(check: _red, hem: -35),
    front: (pen, h) {
      s1Binoculars(pen, h.pt(-19, 0, lift: 8), h.pt(19, 0, lift: 8), r: 16);
    },
  ),
  // واضح مرة: يشاور على عينه
  CharSpec(
    id: 'det_obvious',
    cutout: true,
    skin: Skin.light,
    head: const HeadSpec(x: 94, y: 90, scale: .9, yaw: -.2, shape: FaceShape.oval),
    expr: const Expr(
      eyes: EyeSpec(ew: 12, eh: 10.4, gap: 20, lookX: .4, lidTop: .3, lidSlant: .05, lidBottom: .1, irisR: .5, pupilR: .6),
      brows: BrowSpec(
        lift: 8,
        thick: 6,
        left: BrowSpec(lift: 6, inner: 1, outer: 1, arch: 1.4, thick: 6),
        right: BrowSpec(lift: 12, inner: -3, outer: 0, arch: 3.4, thick: 6),
      ),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 9, y: 45),
    ),
    nose: const NoseSpec(len: 21, proj: 10, width: 7.5),
    headwear: const Ghutra(hem: -35, agalTilt: .05),
    front: (pen, h) {
      final e = h.pt(19, 8);
      s1Hand(pen, Skin.light, S1HandPose.point, at: Offset(e.dx + 30, e.dy + 40), rot: -.6, scale: 1.4, sleeve: Cloth.white, arm: 34, armRot: .15);
    },
  ),
  // انحلّت!: لمبة وعيون نجوم
  CharSpec(
    id: 'det_solved',
    cutout: true,
    skin: Skin.tan,
    head: const HeadSpec(x: 98, y: 94, scale: .86, roll: .05, shape: FaceShape.round),
    expr: const Expr(
      eyes: EyeSpec(open: 0),
      brows: BrowSpec(lift: 12, inner: -2, outer: 1, arch: 4, thick: 6),
      mouth: MouthSpec(kind: MouthKind.grin, w: 15, y: 43, amount: 1),
    ),
    nose: const NoseSpec(len: 20, proj: 9, width: 7, bulb: .7),
    headwear: const Ghutra(hem: -36, agalTilt: .05),
    front: (pen, h) {
      for (final s in const [-1, 1]) {
        s1EyeMark(pen, h, S1EyeMark.star, s, gap: 20, w: 11, lift: 6.5);
      }
      s1Bulb(pen, const Offset(166, 34), 11);
    },
  ),
  // فيه شي غلط: يفكر بشك
  CharSpec(
    id: 'det_hmm',
    cutout: true,
    skin: Skin.brown,
    head: const HeadSpec(x: 104, y: 90, scale: .9, yaw: -.5, roll: .05, shape: FaceShape.square),
    expr: const Expr(
      eyes: EyeSpec(ew: 11, eh: 9, gap: 20, lookX: -.9, lookY: -.3, lidTop: .22, lidSlant: .3, lidBottom: .12, irisR: .52, pupilR: .6),
      brows: BrowSpec(
        lift: 7,
        thick: 6.4,
        left: BrowSpec(lift: 12, inner: -3, outer: -1, arch: 3.4, thick: 6.4),
        right: BrowSpec(lift: 6, inner: 3.5, outer: -1, arch: 1.2, thick: 6.4),
      ),
      mouth: MouthSpec(kind: MouthKind.neutral, w: 9, y: 45, x: -2),
    ),
    nose: const NoseSpec(len: 22, proj: 12, width: 8.5),
    beard: const BeardSpec(style: BeardStyle.goatee, mouthY: 45, mouthW: 9, mouthH: 4),
    headwear: const Ghutra(check: _red, hem: -35, swept: true),
    front: (pen, h) {
      drawChinHand(pen, h, Skin.brown, at: const Offset(-8, 64), rot: .55, mirror: true);
      s1Question(pen, const Offset(24, 38), 12, rot: -.2);
      s1Question(pen, const Offset(174, 52), 9, rot: .25);
    },
  ),
];
