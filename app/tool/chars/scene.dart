// Scene compositor: draws a [CharSpec] either as one composite avatar
// (background circle + figure, 200x200 units) or as separate rig layers
// (240x240 units, -20..220, transparent, no background) for the animated avatars.
import 'dart:math' as math;
import 'dart:ui';

import 'core/head.dart';
import 'core/palette.dart';
import 'core/pen.dart';
import 'parts/beard.dart';
import 'parts/brows.dart';
import 'parts/eyes.dart';
import 'parts/face_base.dart';
import 'parts/glasses.dart';
import 'parts/mouth.dart';
import 'parts/nose.dart';
import 'spec.dart';

/// Which part of a character to paint.
///
/// - [composite]: background + whole figure (the static `<id>.webp`).
/// - [body]: shoulders/clothes (+ `behind` props), transparent, 240x240 canvas.
/// - [head]: neck, headwear, face, features, beard, glasses (rotates around the neck at (100,150)).
/// - [blink]: closed eyelids only, same coordinates as [head] (laid over it).
/// - [mouth]: open-mouth overlay only, same coordinates as [head].
/// - [props]: the `front` custom painter only.
enum CharLayer { composite, body, head, blink, mouth, props }

/// Paint [s] into [canvas] covering a [px] x [px] area at the origin.
void paintChar(Canvas canvas, CharSpec s, {double px = 1024, CharLayer layer = CharLayer.composite}) {
  canvas.save();
  if (layer == CharLayer.composite) {
    canvas.scale(px / 200);
  } else {
    canvas.scale(px / 240);
    canvas.translate(20, 20);
  }
  final pen = Pen(canvas);
  final h = s.head.build();

  if (layer == CharLayer.composite) {
    if (!s.cutout) {
      _drawBg(pen, s.bg);
      canvas.clipPath(circle(100, 100, 100));
      _drawBgGlow(pen, s.bg, h);
    }
    s.behind?.call(pen, h);
    _drawBody(pen, s, h);
    _drawHead(pen, s, h);
    s.front?.call(pen, h);
  } else {
    switch (layer) {
      case CharLayer.body:
        s.behind?.call(pen, h);
        s.body.draw(pen, h, s.skin);
      case CharLayer.head:
        s.headwear?.back(pen, h, s.skin);
        _drawNeck(pen, s, h);
        s.body.drawFront(pen, h, s.skin);
        _drawHead(pen, s, h);
      case CharLayer.blink:
        drawEyelids(pen, h, s.resolvedExpr.eyes, s.skin);
      case CharLayer.mouth:
        drawMouth(pen, h, s.mouthOpen ?? MouthSpec(kind: MouthKind.laugh, w: s.resolvedExpr.mouth.w, y: s.resolvedExpr.mouth.y, amount: .6), s.skin);
      case CharLayer.props:
        s.front?.call(pen, h);
      case CharLayer.composite:
        break;
    }
  }
  canvas.restore();
}

void _drawBg(Pen pen, BgStyle bg) {
  final disc = circle(100, 100, 100);
  pen.fillShader(
    disc,
    Gradient.radial(const Offset(100, 78), 118, [bg.inner, mix(bg.inner, bg.outer, .55), bg.outer], [0, .55, 1]),
  );
  // vignette
  pen.fillShader(
    disc,
    Gradient.radial(const Offset(100, 100), 100, [const Color(0x00000000), const Color(0x00000000), withA(const Color(0xFF000000), bg.vignette)], [0, .62, 1]),
  );
}

void _drawBgGlow(Pen pen, BgStyle bg, Head h) {
  if (bg.glow.a <= 0) return;
  pen.glow(Offset(h.pos.dx, h.pos.dy - 6), 78, 78, bg.glow, alpha: bg.glow.a * 1.4);
}

void _drawBody(Pen pen, CharSpec s, Head h) {
  s.body.draw(pen, h, s.skin);
  // cloth hanging behind the neck (ghutra / hijab drapes) goes UNDER the neck and collar
  s.headwear?.back(pen, h, s.skin);
  _drawNeck(pen, s, h);
  s.body.drawFront(pen, h, s.skin);
}

void _drawNeck(Pen pen, CharSpec s, Head h) {
  drawNeck(pen, h, s.skin, width: s.neckWidth);
}

void _drawHead(Pen pen, CharSpec s, Head h) {
  final e = s.resolvedExpr;
  final hw = s.headwear;
  drawEars(pen, h, s.skin, s.ears, front: false);
  drawFaceSkin(pen, h, s.skin, blush: s.blush);
  drawEars(pen, h, s.skin, s.ears, front: true);
  if (s.hair != null) _drawHair(pen, h, s.hair!);
  drawEyes(pen, h, e.eyes, s.skin);
  drawBrows(pen, h, e.brows, e.eyes);
  drawNose(pen, h, s.nose, s.skin);
  final b = s.beard;
  if (b != null) drawBeardBody(pen, h, b, s.skin);
  drawMouth(pen, h, e.mouth, s.skin);
  if (b != null && hasMustache(b)) drawMustache(pen, h, b);
  if (s.glasses != null) drawGlasses(pen, h, s.glasses!, e.eyes);
  hw?.front(pen, h, s.skin);
}

void _drawHair(Pen pen, Head h, HairSpec hs) {
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

// ignore: unused_element
double _unusedMath() => math.pi;
