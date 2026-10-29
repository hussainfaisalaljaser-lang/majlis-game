// Declarative character description + expression presets.
import 'dart:ui';

import 'core/head.dart';
import 'core/palette.dart';
import 'core/pen.dart';
import 'parts/beard.dart';
import 'parts/body.dart';
import 'parts/brows.dart';
import 'parts/eyes.dart';
import 'parts/face_base.dart';
import 'parts/glasses.dart';
import 'parts/headwear.dart';
import 'parts/mouth.dart';
import 'parts/nose.dart';

/// Eyes + brows + mouth that together make one expression.
class Expr {
  const Expr({this.eyes = const EyeSpec(), this.brows = const BrowSpec(), this.mouth = const MouthSpec()});

  final EyeSpec eyes;
  final BrowSpec brows;
  final MouthSpec mouth;

  Expr copyWith({EyeSpec? eyes, BrowSpec? brows, MouthSpec? mouth}) => Expr(eyes: eyes ?? this.eyes, brows: brows ?? this.brows, mouth: mouth ?? this.mouth);

  /// Calm, friendly.
  factory Expr.neutral({double lookX = 0, double lookY = 0, bool lashes = false}) => Expr(
    eyes: EyeSpec(lookX: lookX, lookY: lookY, lashes: lashes),
    brows: const BrowSpec(inner: 0.5, outer: 1.0),
    mouth: const MouthSpec(kind: MouthKind.neutral),
  );

  factory Expr.happy({double lookX = 0, double lookY = 0, bool lashes = false}) => Expr(
    eyes: EyeSpec(lookX: lookX, lookY: lookY, lidBottom: 0.35, lashes: lashes),
    brows: const BrowSpec(inner: 0, outer: 1.2, arch: 3.4),
    mouth: const MouthSpec(kind: MouthKind.grin, amount: 0.8),
  );

  /// Angry: heavy lowered brows, narrowed round eyes, bared teeth.
  factory Expr.angry({double lookX = 0, double lookY = 0, MouthKind mouth = MouthKind.clenched}) => Expr(
    eyes: EyeSpec(lookX: lookX, lookY: lookY, ew: 10.5, eh: 9.4, lidTop: 0.2, lidSlant: 0.55, irisR: 0.5, pupilR: 0.62, lid: 3.2),
    brows: const BrowSpec(lift: 4.6, inner: 6.5, outer: -3.2, arch: 0.6, thick: 6.6, taper: .7),
    mouth: MouthSpec(kind: mouth, amount: 1.0, w: 13),
  );

  /// Worried / anxious: raised inner brows, big pupils, small open mouth.
  factory Expr.worried({double lookX = 0, double lookY = 0, bool lashes = false}) => Expr(
    eyes: EyeSpec(lookX: lookX, lookY: lookY, lidSlant: -0.35, lidTop: 0.04, irisR: 0.64, pupilR: 0.5, lashes: lashes),
    brows: const BrowSpec(lift: 7, inner: -6.0, outer: 2.2, arch: 1.6, thick: 5.2),
    mouth: const MouthSpec(kind: MouthKind.open, w: 11, amount: 1.0),
  );

  /// Smug: half-lidded, one brow cocked, smirk.
  factory Expr.smug({double lookX = 0, double lookY = 0, int side = 1}) => Expr(
    eyes: EyeSpec(lookX: lookX, lookY: lookY, lidTop: 0.22, lidBottom: 0.2, lidSlant: 0.1, irisR: 0.6, pupilR: 0.56),
    brows: BrowSpec(
      lift: 7,
      inner: -0.5,
      outer: 1.5,
      arch: 3.5,
      thick: 5.6,
      left: BrowSpec(lift: side > 0 ? 6.2 : 9.5, inner: side > 0 ? 1.2 : -3.0, outer: side > 0 ? 1.4 : 0, arch: 3.8, thick: 5.6),
      right: BrowSpec(lift: side > 0 ? 9.5 : 6.2, inner: side > 0 ? -3.0 : 1.2, outer: side > 0 ? 0 : 1.4, arch: 3.8, thick: 5.6),
    ),
    mouth: MouthSpec(kind: MouthKind.smirk, side: side),
  );

  factory Expr.surprised({double lookX = 0, double lookY = 0}) => Expr(
    eyes: EyeSpec(lookX: lookX, lookY: lookY, eh: 10.5, irisR: 0.42, pupilR: 0.55),
    brows: const BrowSpec(lift: 10, inner: -2, outer: -2, arch: 4.5),
    mouth: const MouthSpec(kind: MouthKind.oh, amount: 1.0),
  );

  factory Expr.sleepy({double lookX = 0, double lookY = 0}) => Expr(
    eyes: EyeSpec(lookX: lookX, lookY: lookY, lidTop: 0.5, lidSlant: -0.12, irisR: 0.6),
    brows: const BrowSpec(lift: 6, inner: 1.0, outer: 2.4, arch: 1.5),
    mouth: const MouthSpec(kind: MouthKind.neutral),
  );

  /// Thoughtful squint: one eyebrow lowered, mouth flat.
  factory Expr.thinking({double lookX = 0, double lookY = 0, int side = 1}) => Expr(
    eyes: EyeSpec(lookX: lookX, lookY: lookY, lidTop: 0.16, lidSlant: 0.25, lidBottom: 0.12, ew: 10, eh: 8.8),
    brows: BrowSpec(
      lift: 6,
      inner: 3,
      outer: -1,
      arch: 1.2,
      thick: 6,
      left: BrowSpec(lift: side > 0 ? 5 : 8, inner: side > 0 ? 4 : -1, outer: side > 0 ? -1.4 : 0, arch: 1.6, thick: 6),
      right: BrowSpec(lift: side > 0 ? 8 : 5, inner: side > 0 ? -1 : 4, outer: side > 0 ? 0 : -1.4, arch: 1.6, thick: 6),
    ),
    mouth: const MouthSpec(kind: MouthKind.neutral, w: 10),
  );
}

/// Head placement and turn.
class HeadSpec {
  const HeadSpec({
    this.x = 100,
    this.y = 92,
    this.scale = 1.0,
    this.yaw = 0,
    this.pitch = 0,
    this.roll = 0,
    this.shape = FaceShape.oval,
  });

  /// Global position of the eye-line centre (200-space).
  final double x, y;
  final double scale;

  /// -1..1 (negative = turned to viewer's left).
  final double yaw, pitch;

  /// Radians.
  final double roll;
  final FaceShape shape;

  Head build() => Head(pos: Offset(x, y), scale: scale, yaw: yaw, pitch: pitch, roll: roll, shape: shape);
}

typedef PropPainter = void Function(Pen pen, Head head);

/// Which part of a character to paint.
///
/// - [composite]: background + whole figure (the static `<id>.webp`).
/// - [body]: shoulders/clothes (+ `behind` props), transparent, 240x240 canvas.
/// - [head]: headwear back, neck, collar, face, features, beard, glasses, headwear front
///   (the rig rotates it around the neck at (100,150)).
/// - [blink]: closed eyelids only, same coordinates as [head] (laid over it).
/// - [mouth]: open-mouth overlay only, same coordinates as [head].
/// - [props]: the `front` custom painter only.
enum CharLayer { composite, body, head, blink, mouth, props }

/// A character, as data.
class CharSpec {
  const CharSpec({
    required this.id,
    this.bg = BgStyle.orange,
    this.cutout = false,
    this.skin = Skin.light,
    this.head = const HeadSpec(),
    this.expr = const Expr(),
    this.nose = const NoseSpec(),
    this.ears = const EarSpec(),
    this.beard,
    this.glasses,
    this.headwear,
    this.body = const Thobe(),
    this.irisColor,
    this.blush = 1.0,
    this.hair,
    this.behind,
    this.front,
    this.mouthOpen,
    this.neckWidth = 20,
    this.custom,
    this.extraLayers = const {},
  });

  final String id;

  /// Background gradient. With [cutout] = true no background circle is drawn and
  /// nothing is clipped (for ids whose old art is a cut-out bust).
  final BgStyle bg;
  final bool cutout;
  final Skin skin;
  final HeadSpec head;
  final Expr expr;
  final NoseSpec nose;
  final EarSpec ears;
  final BeardSpec? beard;
  final GlassesSpec? glasses;
  final Headwear? headwear;
  final Body body;

  /// Overrides the iris colour of [expr].
  final Color? irisColor;
  final double blush;

  /// Optional hair drawn on the skull (under headwear).
  final HairSpec? hair;

  /// Custom painting behind everything (after the background).
  final PropPainter? behind;

  /// Custom painting on top of everything (props, hands, hats...).
  final PropPainter? front;

  /// Mouth used for the animated "mouth" layer (open mouth); null = a generic open mouth.
  final MouthSpec? mouthOpen;
  final double neckWidth;

  /// Paints the WHOLE figure yourself (animals, mascots, ghosts...). When set, the body /
  /// head / face parts above are ignored and only [custom] (after the background) is drawn.
  final PropPainter? custom;

  /// Extra named rig layers (wing, tail, crest, ear_l...). Each painter draws on the same
  /// 240x240 (-20..220) transparent canvas as the standard layers; exported as `<name>.webp`.
  final Map<String, PropPainter> extraLayers;

  Expr get resolvedExpr {
    if (irisColor == null) return expr;
    return expr.copyWith(eyes: expr.eyes.copyWith(iris: irisColor));
  }
}

/// Simple visible hair: sideburns / a hairline cap that peeks out under headwear.
class HairSpec {
  const HairSpec({this.color = HairColor.black, this.sideburn = 10.0, this.cap = false});

  final HairColor color;

  /// Length of the sideburns down the face edge.
  final double sideburn;

  /// Draw a full hair cap over the skull (bareheaded characters).
  final bool cap;
}
