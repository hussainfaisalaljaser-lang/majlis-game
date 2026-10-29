// Worker C: helper that turns an ordinary [CharSpec] into a "rigged" one, so the still
// (`<id>.webp`) and every animation layer (`anim/<id>/<layer>.webp`) are produced from ONE
// set of painters and always match what `anim_rigs.dart` stacks.
//
//   rigged(CharSpec(...), layers: {'necklace': ..., 'wink': ...}, still: ['body', 'head', 'necklace'])
//
// Standard layers (same content as scene.dart): body, head, blink, mouth. Extra layers are
// painted on the same 240x240 (-20..220) transparent canvas. The `still` list says which layers
// make the composite and in which order (it mirrors the rig's stacking order).
import '../kit.dart';

/// Headwear made of closures (feathers, jewels, trims added to a stack).
class CustomWear extends Headwear {
  const CustomWear({this.onBack, this.onFront});

  final void Function(Pen pen, Head h, Skin skin)? onBack;
  final void Function(Pen pen, Head h, Skin skin)? onFront;

  @override
  void back(Pen pen, Head h, Skin skin) => onBack?.call(pen, h, skin);

  @override
  void front(Pen pen, Head h, Skin skin) => onFront?.call(pen, h, skin);
}

void _hair(Pen pen, Head h, HairSpec hs) {
  final sc = h.scale;
  final c = hs.color;
  for (final side in const [-1, 1]) {
    final len = hs.sideburn;
    final p = h.path(
      svg('M${side * 41} -34 C${side * 47} -24 ${side * 47} -10 ${side * 45} ${-6 + len} L${side * 41} ${-6 + len} C${side * 40} -14 ${side * 40} -22 ${side * 36} -30 Z'),
      lift: 1.5,
    );
    pen.fill(p, c.base);
    pen.crescent(p, c.shade, depth: 1.6 * sc);
    pen.line(p, w: Style.lineThin * sc, color: Style.ink);
  }
  if (hs.cap) {
    final cap = h.path(svg('M-46 -22 C-52 -62 -26 -86 0 -86 C26 -86 52 -62 46 -22 C40 -34 30 -40 0 -38 C-30 -40 -40 -34 -46 -22 Z'), lift: 3);
    pen.fill(cap, c.base);
    pen.crescent(cap, c.shade, depth: 5 * sc);
    pen.rim(cap, c.hi, depth: 2 * sc);
    pen.line(cap, w: Style.line * sc, color: Style.ink);
  }
}

/// The face + everything on it (same order as scene.dart `_drawHead`).
void drawFigureHead(Pen pen, CharSpec s, Head h) {
  final e = s.resolvedExpr;
  drawEars(pen, h, s.skin, s.ears, front: false);
  drawFaceSkin(pen, h, s.skin, blush: s.blush);
  drawEars(pen, h, s.skin, s.ears, front: true);
  if (s.hair != null) _hair(pen, h, s.hair!);
  drawEyes(pen, h, e.eyes, s.skin);
  drawBrows(pen, h, e.brows, e.eyes);
  drawNose(pen, h, s.nose, s.skin);
  final b = s.beard;
  if (b != null) drawBeardBody(pen, h, b, s.skin);
  drawMouth(pen, h, e.mouth, s.skin);
  if (b != null && hasMustache(b)) drawMustache(pen, h, b);
  if (s.glasses != null) drawGlasses(pen, h, s.glasses!, e.eyes);
  s.headwear?.front(pen, h, s.skin);
}

/// Standard layers of [s]: body / head / blink / mouth.
Map<String, PropPainter> standardLayers(CharSpec s) => {
  'body': (pen, h) {
    s.behind?.call(pen, h);
    s.body.draw(pen, h, s.skin);
  },
  'head': (pen, h) {
    s.headwear?.back(pen, h, s.skin);
    drawNeck(pen, h, s.skin, width: s.neckWidth);
    s.body.drawFront(pen, h, s.skin);
    drawFigureHead(pen, s, h);
  },
  'blink': (pen, h) => drawEyelids(pen, h, s.resolvedExpr.eyes, s.skin),
  'mouth': (pen, h) => drawMouth(pen, h, s.mouthOpen ?? MouthSpec(kind: MouthKind.laugh, w: s.resolvedExpr.mouth.w, y: s.resolvedExpr.mouth.y, amount: .6), s.skin),
};

/// Build the rigged spec. [layers] adds (or replaces) layers; [still] = composite order;
/// [export] limits which layers are exported (default: every standard + extra layer).
CharSpec rigged(CharSpec s, {Map<String, PropPainter> layers = const {}, List<String> still = const ['body', 'head'], List<String>? export}) {
  final all = {...standardLayers(s), ...layers};
  final out = export == null ? all : {for (final k in export) k: all[k]!};
  return CharSpec(
    id: s.id,
    bg: s.bg,
    cutout: true,
    skin: s.skin,
    head: s.head,
    custom: (pen, h) {
      for (final name in still) {
        all[name]!(pen, h);
      }
    },
    extraLayers: out,
  );
}

/// Closed eyelid of ONE eye (the viewer's [side] -1 left / +1 right) drawn as a happy "^" arc: a wink.
/// Same geometry as the kit's eyelids so it fits the eye exactly.
void drawWink(Pen pen, Head h, EyeSpec eyes, Skin skin, {required int side}) {
  final s = (side < 0 ? eyes.left : eyes.right) ?? eyes;
  final cx = side * s.gap, cy = s.y;
  final contour = xform(
    svg('M-1 0.12 C-1 -0.6 -0.55 -1 0.05 -1 C0.65 -1 1 -0.5 1 0.02 C1 0.62 0.55 1 -0.02 1 C-0.6 1 -1 0.66 -1 0.12 Z'),
    sx: side * s.ew,
    sy: s.eh,
    tx: cx,
    ty: cy,
  );
  final lid = h.path(contour, lift: 1.4);
  final b = lid.getBounds();
  final grown = scaledAbout(lid, b.center, (b.width + 2.6 * h.scale) / b.width, (b.height + 2.6 * h.scale) / b.height);
  pen.fill(grown, skin.base);
  final arc = Path()
    ..moveTo(cx - side * s.ew * 0.95, cy + s.eh * 0.35)
    ..quadraticBezierTo(cx, cy - s.eh * 0.85, cx + side * s.ew * 1.05, cy + s.eh * 0.3);
  pen.line(h.path(arc, lift: 1.7), w: s.lid * 0.95 * h.scale, color: Style.ink);
  if (s.lashes) {
    for (var i = 0; i < 3; i++) {
      final x0 = cx + side * s.ew * (0.55 + i * 0.28);
      final y0 = cy - s.eh * (0.35 - i * 0.2);
      final p = Path()
        ..moveTo(x0, y0)
        ..lineTo(x0 + side * 2.6, y0 - 2.8 + i * 0.6);
      pen.line(h.path(p, lift: 1.7), w: 1.5 * h.scale, color: Style.ink);
    }
  }
}

/// A small faceted gem: outlined round stone with a light facet and a white glint.
void gem(Pen pen, Offset c, double r, Tones t, {Color ring = const Color(0xFFE3B341), double lw = 1.0}) {
  pen.fill(circle(c.dx, c.dy, r * 1.32), ring);
  pen.crescent(circle(c.dx, c.dy, r * 1.32), shadeOf(ring, .3), depth: r * .35);
  pen.line(circle(c.dx, c.dy, r * 1.32), w: Style.lineThin * lw, color: Style.ink);
  pen.fill(circle(c.dx, c.dy, r), t.base);
  pen.crescent(circle(c.dx, c.dy, r), t.shade, depth: r * .6);
  pen.line(circle(c.dx, c.dy, r), w: Style.lineFine * lw, color: withA(Style.ink, .8));
  pen.fill(circle(c.dx - r * .32, c.dy - r * .34, r * .3), const Color(0xFFFFFFFF));
}

/// A soft "glow" disc (not outlined) for glowing eyes and magic effects.
void softGlow(Pen pen, Offset c, double rx, double ry, Color col, {double alpha = .5}) {
  pen.glow(c, rx, ry, col, alpha: alpha);
}
