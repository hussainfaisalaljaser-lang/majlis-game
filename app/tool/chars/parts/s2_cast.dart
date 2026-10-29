// The sticker cast (worker S2): ten recognisable people (skin + headwear + beard + body) that every
// sticker of packs innocent / party / traitor / vip / hype / s1 / legend is cast from. Each sticker
// then adds its own pose, expression and props (see characters/pack7.dart).
import 'dart:ui' show Color;

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';
import '../parts/beard.dart';
import '../parts/body.dart';
import '../parts/glasses.dart';
import '../parts/headwear.dart';
import '../parts/mouth.dart';
import '../parts/nose.dart';
import '../spec.dart';

/// A person of the cast.
class S2Who {
  const S2Who(
    this.skin, {
    this.shape = FaceShape.oval,
    this.nose = const NoseSpec(),
    this.beard,
    this.headwear,
    this.body = const Thobe(),
    this.glasses,
    this.hair,
    this.scale = 1.0,
    this.browColor = HairColor.black,
    this.iris = const Color(0xFF4B3020),
    this.neckWidth = 20,
    this.blush = 1.0,
  });

  final Skin skin;
  final FaceShape shape;
  final NoseSpec nose;
  final BeardSpec? beard;
  final Headwear? headwear;
  final Body body;
  final GlassesSpec? glasses;
  final HairSpec? hair;
  final double scale;
  final HairColor browColor;
  final Color iris;
  final double neckWidth;
  final double blush;
}

const _tealHijab = Tones(Color(0xFF3F8068), Color(0xFF2A5B4B), Color(0xFF63A68A));
const _pinkHijab = Tones(Color(0xFFB5446E), Color(0xFF7F2A4E), Color(0xFFD86C93));
const _blackHijab = Tones(Color(0xFF3A3340), Color(0xFF221D29), Color(0xFF5E5568));
const _abayaBlack = Tones(Color(0xFF2E2833), Color(0xFF1B1720), Color(0xFF4D4556));
const _abayaPink = Tones(Color(0xFF8E3558), Color(0xFF5E2039), Color(0xFFB4567C));
const _abayaTeal = Tones(Color(0xFF2E5E4F), Color(0xFF1B3B31), Color(0xFF4A8470));
const _blackCheck = Color(0xFF2C2326);

/// A: young tan man, white ghutra.
const S2Who s2Youth = S2Who(
  Skin.tan,
  shape: FaceShape.pointed,
  nose: NoseSpec(len: 26, proj: 17, width: 9.5, bulb: 1.0, bridge: 3.6),
  headwear: Ghutra(hem: -35, agalSag: 6),
  hair: HairSpec(sideburn: 14),
);

/// B: brown skin, red shemagh, goatee.
const S2Who s2Goatee = S2Who(
  Skin.brown,
  shape: FaceShape.square,
  nose: NoseSpec(len: 25, proj: 16, width: 9.5, bulb: 1.0),
  beard: BeardSpec(style: BeardStyle.goatee, color: HairColor.inkBlack),
  headwear: Ghutra(check: Color(0xFFC8262E), hem: -34, agalSag: 6),
);

/// C: elderly fair man, white ghutra, full grey beard.
const S2Who s2Elder = S2Who(
  Skin.fair,
  shape: FaceShape.lean,
  nose: NoseSpec(len: 24, proj: 14, width: 9, bulb: 1.15),
  beard: BeardSpec(style: BeardStyle.full, color: HairColor.grey, length: 4),
  headwear: Ghutra(hem: -34),
  browColor: HairColor.grey,
  iris: Color(0xFF5A3C26),
);

/// D: light skin, black hijab.
const S2Who s2HijabBlack = S2Who(
  Skin.light,
  shape: FaceShape.round,
  nose: NoseSpec(len: 19, proj: 9, width: 6.2, bulb: 0.62, bridge: 2.6),
  headwear: Hijab(cloth: _blackHijab, flap: true, width: 1.2),
  body: Garment(color: _abayaBlack),
  scale: 0.92,
  iris: Color(0xFF2E1D14),
);

/// E: tan skin, magenta hijab.
const S2Who s2HijabPink = S2Who(
  Skin.tan,
  shape: FaceShape.round,
  nose: NoseSpec(len: 19, proj: 9, width: 6.2, bulb: 0.62, bridge: 2.6),
  headwear: Hijab(cloth: _pinkHijab, flap: true, width: 1.2),
  body: Garment(color: _abayaPink),
  scale: 0.92,
  iris: Color(0xFF2E1D14),
);

/// F: brown skin, teal hijab, round glasses.
const S2Who s2HijabTeal = S2Who(
  Skin.brown,
  shape: FaceShape.round,
  nose: NoseSpec(len: 18, proj: 8, width: 6, bulb: 0.58, bridge: 2.4),
  glasses: GlassesSpec(kind: GlassesKind.round, thick: 3.0),
  headwear: Hijab(cloth: _tealHijab, underCap: Cloth.white, capEdge: -18, flap: true, width: 1.2),
  body: Garment(color: _abayaTeal),
  scale: 0.92,
  iris: Color(0xFF34506B),
);

/// G: deep skin, red shemagh, stubble.
const S2Who s2Deep = S2Who(
  Skin.deepTone,
  shape: FaceShape.square,
  nose: NoseSpec(len: 25, proj: 15, width: 10, bulb: 1.0),
  beard: BeardSpec(style: BeardStyle.stubble, color: HairColor.inkBlack),
  headwear: Ghutra(check: Color(0xFFC8262E), hem: -34, agalSag: 6),
  iris: Color(0xFF2E1D14),
);

/// H: masked in a red-check ghutra (the traitor silhouette).
const S2Who s2Masked = S2Who(
  Skin.tan,
  shape: FaceShape.square,
  nose: NoseSpec(len: 23, proj: 12, width: 8),
  headwear: HeadwearStack([
    FaceVeil(cloth: Tones(Color(0xFF6B4A58), Color(0xFF4A3140), Color(0xFF8E6A76))),
    Ghutra(check: Color(0xFFC8262E), hem: -26),
  ]),
  body: Thobe(color: Cloth.charcoal),
);

/// I: fair skin, white ghutra, big moustache.
const S2Who s2Must = S2Who(
  Skin.fair,
  shape: FaceShape.oval,
  nose: NoseSpec(len: 26, proj: 17, width: 9.5, bulb: 1.1),
  beard: BeardSpec(style: BeardStyle.mustache, color: HairColor.inkBlack, mustacheSize: 1.1),
  headwear: Ghutra(hem: -35),
  iris: Color(0xFF3C4A3A),
);

/// J: light skin, white ghutra, short black beard.
const S2Who s2Bearded = S2Who(
  Skin.light,
  shape: FaceShape.square,
  nose: NoseSpec(len: 24, proj: 14, width: 8.5, bulb: 0.95),
  beard: BeardSpec(style: BeardStyle.short, color: HairColor.inkBlack),
  headwear: Ghutra(hem: -34),
);

/// K: tan skin, black-white shemagh, no beard.
const S2Who s2Black = S2Who(
  Skin.tan,
  shape: FaceShape.oval,
  nose: NoseSpec(len: 25, proj: 16, width: 9, bulb: 1.0),
  headwear: Ghutra(check: _blackCheck, hem: -34, agalSag: 6),
  hair: HairSpec(sideburn: 12),
);

/// Build a sticker character from a cast member.
///
/// [mouth] is passed through to the beard hole automatically (same x/y/width as the mouth).
CharSpec s2Char(
  String id,
  S2Who who, {
  required Expr expr,
  HeadSpec? head,
  Headwear? headwear,
  Body? body,
  GlassesSpec? glasses,
  bool noGlasses = false,
  BeardSpec? beard,
  bool noBeard = false,
  NoseSpec? nose,
  Skin? skin,
  PropPainter? behind,
  PropPainter? front,
  double beardMouthH = -1,
  HairSpec? hair,
}) {
  final m = expr.mouth;
  var b = noBeard ? null : (beard ?? who.beard);
  if (b != null) {
    final open = m.kind == MouthKind.laugh || m.kind == MouthKind.grin || m.kind == MouthKind.clenched || m.kind == MouthKind.open || m.kind == MouthKind.oh;
    b = b.copyWith(mouthY: m.y, mouthW: m.w * (open ? 1.0 : 0.85), mouthH: beardMouthH > 0 ? beardMouthH : (open ? 7.0 : 3.3));
  }
  final eyes = expr.eyes.iris == const Color(0xFF4B3020) ? expr.eyes.copyWith(iris: who.iris) : expr.eyes;
  final brows = expr.brows.color == HairColor.black ? expr.brows.copyWith(color: who.browColor) : expr.brows;
  return CharSpec(
    id: id,
    cutout: true,
    skin: skin ?? who.skin,
    head: head ?? HeadSpec(x: 100, y: who.scale < 1 ? 94 : 98, scale: who.scale, shape: who.shape),
    expr: Expr(eyes: eyes, brows: brows, mouth: m),
    nose: nose ?? who.nose,
    beard: b,
    glasses: noGlasses ? null : (glasses ?? who.glasses),
    headwear: headwear ?? who.headwear,
    body: body ?? who.body,
    hair: hair ?? who.hair,
    neckWidth: who.neckWidth,
    blush: who.blush,
    behind: behind,
    front: front,
  );
}

/// Same head placement as [s2Char] uses by default, with a pose.
HeadSpec s2Head(S2Who who, {double yaw = 0, double roll = 0, double pitch = 0, double dx = 0, double dy = 0}) =>
    HeadSpec(x: 100 + dx, y: (who.scale < 1 ? 94 : 98) + dy, scale: who.scale, yaw: yaw, roll: roll, pitch: pitch, shape: who.shape);
