// Worker B props: stethoscope, magnifier, quill, goggles, pearl, earpiece, hands that grip.
// Everything is drawn with the Pen in 200-space; positions relative to the neck use `rel`.
import 'dart:math' as math;
import 'dart:ui';

import '../kit.dart';
import 'b_common.dart';

const _steel = Tones(Color(0xFFC4CEDC), Color(0xFF8793A8), Color(0xFFF2F6FB));

/// Stethoscope draped round the neck: a U of tubing over the chest and the chest piece hanging
/// at the bottom. Relative to the neck base N; [lean] shifts the dangling piece sideways.
void bStethoscope(Pen pen, Head h, {double dx = 0, double top = -10, double drop = 56, double lean = 8, double width = 36}) {
  final s = h.scale;
  final d = dx;
  final bot = drop;
  final w = width;
  final tube = rel(h, 'M${-w * .6} $top C${-w - 4} ${top + 16} ${-w - 2} ${bot - 22} ${-w * .5} ${bot - 6} C${-w * .22} ${bot + 2} ${lean * .4 - 4} ${bot + 1} $lean ${bot - 1} '
      'M${w * .6} $top C${w + 4} ${top + 16} ${w + 2} ${bot - 22} ${w * .5} ${bot - 6} C${w * .22} ${bot + 2} ${lean * .4 + 4} ${bot + 1} $lean ${bot - 1}', dx: d);
  pen.line(tube, w: 5.4 * s, color: Style.ink);
  pen.line(tube, w: 3.4 * s, color: const Color(0xFF5B6881));
  pen.line(tube.shift(Offset(-0.7 * s, -0.5 * s)), w: 1.0 * s, color: const Color(0xFF9FB0CC));
  // stem to the chest piece
  final stem = rel(h, 'M$lean ${bot - 2} L${lean + 3} ${bot + 12}', dx: d);
  pen.line(stem, w: 4.8 * s, color: Style.ink);
  pen.line(stem, w: 2.8 * s, color: const Color(0xFF5B6881));
  final c = h.neckBase + Offset(d + (lean + 3) * s, (bot + 18) * s);
  final disc = circle(c.dx, c.dy, 7.6 * s);
  pen.solid(disc, _steel, shade: 2.2 * s, hi: 1.0 * s, w: Style.line * .95 * s);
  pen.shape(circle(c.dx, c.dy, 4.2 * s), const Color(0xFF7D8AA3), w: Style.lineThin * s);
  bGlint(pen, c + Offset(-3.2 * s, -3.4 * s), c + Offset(-0.8 * s, -4.4 * s), w: 1.8 * s);
}

/// Small medical cross pin.
void bCrossPin(Pen pen, Offset c, double r) {
  pen.shape(circle(c.dx, c.dy, r), const Color(0xFFFFFFFF), w: Style.lineThin);
  final a = r * .62, b = r * .22;
  final cross = Path()
    ..addRect(Rect.fromLTRB(c.dx - b, c.dy - a, c.dx + b, c.dy + a))
    ..addRect(Rect.fromLTRB(c.dx - a, c.dy - b, c.dx + a, c.dy + b));
  pen.fill(cross, const Color(0xFFD9423B));
}

// ───────────────────────────── hands ─────────────────────────────

Path _fx(Path p, Offset at, double rot, double s, [bool mirror = false]) {
  final cs = math.cos(rot) * s, sn = math.sin(rot) * s;
  final mx = mirror ? -1.0 : 1.0;
  return p.transform(affine(cs * mx, sn * mx, -sn, cs, at.dx, at.dy));
}

/// A fist gripping something that runs vertically through it (local frame: shaft along y,
/// fist centred on the origin, sleeve going down +y). [at] / [rot] / [s] / [mirror] place it.
void bGripHand(Pen pen, Offset at, double rot, double s, Skin skin, {Tones sleeve = Cloth.white, double sleeveLen = 70, bool cuff = true, bool mirror = false, bool showSleeve = true}) {
  Path P(String d) => _fx(svg(d), at, rot, s, mirror);
  final lw = Style.line * .9 * s;
  final fine = Style.lineThin * .85 * s;
  if (showSleeve) {
    final arm = P('M-11 12 C-14 26 -16 ${sleeveLen * .6} -18 $sleeveLen L20 $sleeveLen C19 ${sleeveLen * .6} 16 26 12 12 Z');
    pen.fill(arm, sleeve.base);
    pen.crescent(arm, sleeve.shade, depth: 5 * s, dir: const Offset(-0.9, -0.3));
    pen.inside(arm, (q) {
      q.taper(P('M-4 22 C-5 36 -6 52 -8 ${sleeveLen - 2}'), w0: 2.2 * s, w1: .3 * s, color: withA(sleeve.shade, .95));
      q.taper(P('M7 24 C8 38 9 54 10 ${sleeveLen - 2}'), w0: 1.8 * s, w1: .3 * s, color: withA(sleeve.shade, .8));
    });
    pen.line(arm, w: lw);
    if (cuff) {
      final c = P('M-13 11 C-5 15 6 15 14 11 L16 21 C6 25 -6 25 -15 21 Z');
      pen.solid(c, sleeve, shade: 2.4 * s, hi: .9 * s, w: lw * .85);
    }
  }
  // back of the fist: four curled fingers stacked on the shaft
  final body = P('M-12.5 -8 C-12.5 -14 -6 -16 0 -16 C7 -16 12.5 -14 12.5 -8 L12.5 9 C12.5 14 7 16 0 16 C-7 16 -12.5 14 -12.5 9 Z');
  pen.fill(body, skin.base);
  pen.crescent(body, skin.shade, depth: 4 * s, dir: const Offset(-0.9, -0.3));
  pen.rim(body, skin.hi, depth: 1.3 * s);
  pen.inside(body, (q) {
    for (final y in const [-8.0, -0.5, 7.0]) {
      q.line(P('M-13 ${y + 1} C-5 ${y - 2} 5 ${y - 2} 13 ${y + 1}'), w: fine * .95, color: withA(Style.ink, .85));
    }
    q.line(P('M-9 -12.5 C-5 -14.5 3 -14.5 7 -12.5'), w: fine * .7, color: withA(skin.hi, .9));
  });
  pen.line(body, w: lw);
  // thumb over the top finger
  final thumb = P('M-14 -3 C-12 -11 -2 -15 7 -12 C11 -10 10 -6 6 -5 C0 -4 -6 1 -10 4 C-14 5 -16 0 -14 -3 Z');
  pen.solid(thumb, skin.tones, shade: 2.2 * s, hi: .8 * s, w: lw * .9);
  pen.line(P('M2 -11 C5 -10 7 -8 6 -6.4'), w: fine * .6, color: withA(skin.deep, .8));
}

/// Gold-ringed magnifying glass held up to an eye, the magnified eye drawn inside the lens.
/// [lc] lens centre, [lr] lens radius, [ang] direction of the handle (radians, 0 = right, +y down),
/// [eyeHead] a head whose eye (side [eyeSide]) is aligned with the lens centre.
void bMagnifier(Pen pen, Head h, {required Offset lc, double lr = 24, double ang = 1.0, double handle = 54, required EyeSpec eyes, required BrowSpec brows, required Skin skin, int eyeSide = 1, double zoom = 1.85}) {
  final e = (eyeSide < 0 ? eyes.left : eyes.right) ?? eyes;
  final s2 = h.scale * zoom;
  final tmp = Head(pos: Offset.zero, scale: s2, yaw: h.yaw, pitch: h.pitch, roll: h.roll, shape: h.shape);
  final off = tmp.pt(eyeSide * e.gap, e.y, lift: 1.2);
  final h2 = Head(pos: lc - off, scale: s2, yaw: h.yaw, pitch: h.pitch, roll: h.roll, shape: h.shape);
  final dir = Offset(math.cos(ang), math.sin(ang));
  final nrm = Offset(-dir.dy, dir.dx);
  // handle
  final g0 = lc + dir * (lr + 1.5);
  final g1 = lc + dir * (lr + handle);
  final hp = Path()
    ..moveTo((g0 + nrm * 3.0).dx, (g0 + nrm * 3.0).dy)
    ..lineTo((g1 + nrm * 3.8).dx, (g1 + nrm * 3.8).dy)
    ..quadraticBezierTo((g1 + dir * 4.5).dx, (g1 + dir * 4.5).dy, (g1 - nrm * 3.8).dx, (g1 - nrm * 3.8).dy)
    ..lineTo((g0 - nrm * 3.0).dx, (g0 - nrm * 3.0).dy)
    ..close();
  pen.solid(hp, const Tones(Color(0xFF7A4A2A), Color(0xFF4F2D18), Color(0xFFA86C40)), shade: 2.2, hi: 1.0, w: Style.line * .95);
  // gold ferrule
  final f0 = lc + dir * (lr + 1.0);
  final f1 = lc + dir * (lr + 9.5);
  final fp = Path()
    ..moveTo((f0 + nrm * 3.9).dx, (f0 + nrm * 3.9).dy)
    ..lineTo((f1 + nrm * 3.6).dx, (f1 + nrm * 3.6).dy)
    ..lineTo((f1 - nrm * 3.6).dx, (f1 - nrm * 3.6).dy)
    ..lineTo((f0 - nrm * 3.9).dx, (f0 - nrm * 3.9).dy)
    ..close();
  pen.solid(fp, const Tones(Color(0xFFE6B93D), Color(0xFFB4841E), Color(0xFFFBE48A)), shade: 1.6, hi: .8, w: Style.lineThin * 1.2);
  // lens glass: skin of the magnified face + the eye
  final lens = circle(lc.dx, lc.dy, lr);
  pen.fill(lens, skin.base);
  pen.inside(lens, (q) {
    q.glow(lc + const Offset(0, 6), lr * .9, lr * .7, skin.hi, alpha: .55);
    drawEyes(q, h2, eyes, skin);
    drawBrows(q, h2, brows, eyes);
    // glass tint + glints
    q.fill(lens, const Color(0x2276D4F0));
    q.crescent(lens, const Color(0x3358B4DC), depth: lr * .28, dir: const Offset(-0.5, -0.8));
  });
  bGlint(pen, lc + Offset(-lr * .62, -lr * .22), lc + Offset(-lr * .22, -lr * .66), w: 3.4, alpha: .8);
  bGlint(pen, lc + Offset(lr * .38, lr * .62), lc + Offset(lr * .64, lr * .34), w: 2.2, alpha: .6);
  // gold ring
  final ring = Path()
    ..addOval(Rect.fromCircle(center: lc, radius: lr + 3.4))
    ..addOval(Rect.fromCircle(center: lc, radius: lr - .4))
    ..fillType = PathFillType.evenOdd;
  pen.fill(ring, const Color(0xFFD9A526));
  pen.inside(ring, (q) {
    q.crescent(circle(lc.dx, lc.dy, lr + 3.4), const Color(0xFFA7761A), depth: 3.2, dir: const Offset(-0.7, -0.7));
    q.rim(circle(lc.dx, lc.dy, lr + 3.4), const Color(0xFFFBE48A), depth: 1.5, dir: const Offset(-0.7, -0.7));
  });
  pen.line(circle(lc.dx, lc.dy, lr + 3.4), w: Style.line);
  pen.line(circle(lc.dx, lc.dy, lr - .4), w: Style.lineThin * 1.1);
}

// ───────────────────────────── spy bits ─────────────────────────────

/// Wayfarer sunglasses with tinted, slightly see-through lenses (the eyes still show a little),
/// a teal reflection and a glint. Positioned from the eye spec like the kit's glasses.
void bSunglasses(Pen pen, Head h, EyeSpec eyes, {double tint = .6, Color reflect = const Color(0xFF3FD0C0), double thick = 3.4, double size = 1.0}) {
  final sc = h.scale;
  const lift = 5.5;
  final lenses = <Path>[];
  for (final side in const [-1, 1]) {
    final e = (side < 0 ? eyes.left : eyes.right) ?? eyes;
    final cx = side * e.gap, cy = e.y;
    final w = (e.ew + 6.6) * size;
    final tl = Offset(cx - side * w * 1.02, cy - 9.5 * size), tr = Offset(cx + side * w * 1.0, cy - 11.5 * size);
    final p = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(cx + side * (w - 1.2), cy + 4 * size)
      ..quadraticBezierTo(cx + side * (w - 4), cy + 13 * size, cx + side * 3, cy + 12.5 * size)
      ..quadraticBezierTo(cx - side * (w - 3), cy + 12 * size, cx - side * (w - 0.5), cy + 2 * size)
      ..close();
    lenses.add(h.path(p, lift: lift));
  }
  final fw = thick * sc;
  const frame = Color(0xFF1B171F);
  // temples (to the hijab edge) + bridge
  for (final s in const [-1, 1]) {
    final e = (s < 0 ? eyes.left : eyes.right) ?? eyes;
    final x0 = s * (e.gap + e.ew + 6.4 * size);
    final arm = Path()
      ..moveTo(x0, e.y - 8)
      ..lineTo(s * (h.shape.wAt(e.y) + 1), e.y - 6);
    final vis = h.depthOf(s * (h.shape.wAt(e.y) + 1), e.y, z: -2) > 0;
    if (vis || h.absYaw < 0.12) pen.line(h.path(arm, lift: lift - 1.2), w: fw * 0.9, color: frame);
  }
  pen.line(h.path(svg('M-7 -6 Q0 -10 7 -6'), lift: lift), w: fw * .95, color: frame);
  for (final lp in lenses) {
    pen.fill(lp, withA(const Color(0xFF0B0A10), tint));
    pen.inside(lp, (q) {
      final b = lp.getBounds();
      q.glow(Offset(b.center.dx + b.width * .15, b.bottom - b.height * .12), b.width * .5, b.height * .32, reflect, alpha: .5);
      q.line(Path()..moveTo(b.left + b.width * .16, b.top + b.height * .72)..lineTo(b.left + b.width * .44, b.top + b.height * .16), w: 3.4 * sc, color: withA(const Color(0xFFFFFFFF), .75));
      q.line(Path()..moveTo(b.left + b.width * .56, b.top + b.height * .8)..lineTo(b.left + b.width * .72, b.top + b.height * .42), w: 1.8 * sc, color: withA(const Color(0xFFFFFFFF), .55));
    });
    pen.line(lp, w: fw, color: frame);
    pen.line(lp, w: fw * .22, color: withA(const Color(0xFF8B8498), .0));
  }
}

/// Coiled earpiece cord along [path] (global): slanted loops like a telephone cord.
void bCoil(Pen pen, Path path, {double w = 3.0, Color wire = const Color(0xFF2C2832)}) {
  for (final m in path.computeMetrics()) {
    for (var d = 0.0; d < m.length; d += 3.1) {
      final t = m.getTangentForOffset(d);
      if (t == null) continue;
      final tv = t.vector;
      final n = Offset(-tv.dy, tv.dx);
      final a = t.position - n * (w * .75) - tv * 1.8;
      final b = t.position + n * (w * .75) + tv * 1.8;
      pen.line(Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy), w: 2.2, color: Style.ink);
    }
    for (var d = 1.5; d < m.length; d += 3.1) {
      final t = m.getTangentForOffset(d);
      if (t == null) continue;
      final tv = t.vector;
      final n = Offset(-tv.dy, tv.dx);
      final a = t.position - n * (w * .6) - tv * 1.2;
      final b = t.position + n * (w * .6) + tv * 1.2;
      pen.line(Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy), w: 1.0, color: const Color(0xFF8E9BB0));
    }
  }
}

/// Tiny earbud with a red light.
void bEarbud(Pen pen, Offset c, double r) {
  pen.solid(circle(c.dx, c.dy, r), const Tones(Color(0xFF3A3642), Color(0xFF1E1B24), Color(0xFF6E6A7C)), shade: r * .5, hi: r * .3, w: Style.lineThin * 1.2);
  pen.fill(circle(c.dx + r * .1, c.dy - r * .1, r * .34), const Color(0xFFFF5A4D));
}

// ───────────────────────────── diver bits ─────────────────────────────

/// Diving goggles pushed up on the forehead / cap: leather strap round the head, two brass-ringed
/// round lenses with blue glass. Use inside a [HeadwearStack] after the cap.
class BGoggles extends Headwear {
  const BGoggles({this.y = -51, this.gap = 15.5, this.r = 11.5, this.strap = const Tones(Color(0xFF7A4A2A), Color(0xFF4F2D18), Color(0xFFA86C40)), this.rim = const Tones(Color(0xFFD9A526), Color(0xFFA7761A), Color(0xFFFBE48A)), this.glass = const Color(0xFF5CC8F0)});

  final double y, gap, r;
  final Tones strap, rim;
  final Color glass;

  @override
  void back(Pen pen, Head h, Skin skin) {}

  @override
  void front(Pen pen, Head h, Skin skin) {
    final sc = h.scale;
    final band = ring3D(h, y - 1, 42.5, 7.5, sag: 3.5, lift: 2.8, span: 78);
    pen.fill(band, strap.base);
    pen.crescent(band, strap.shade, depth: 2.2 * sc, dir: const Offset(0.2, -1));
    pen.rim(band, strap.hi, depth: 1.3 * sc, dir: const Offset(-0.3, -1));
    pen.line(band, w: Style.line * .85 * sc);
    for (final s in const [-1, 1]) {
      final c = Offset(s * gap, y);
      final lensP = h.path(circle(c.dx, c.dy, r), lift: 8.5);
      final rimOut = h.path(circle(c.dx, c.dy, r + 3.2), lift: 8.2);
      pen.fill(rimOut, rim.base);
      pen.crescent(rimOut, rim.shade, depth: 2.6 * sc, dir: const Offset(-0.7, -0.7));
      pen.rim(rimOut, rim.hi, depth: 1.2 * sc, dir: const Offset(-0.7, -0.7));
      pen.line(rimOut, w: Style.line * .95 * sc);
      pen.fill(lensP, glass);
      pen.inside(lensP, (q) {
        q.crescent(lensP, shadeOf(glass, .35), depth: r * .5 * sc, dir: const Offset(0.3, -1));
        final b = lensP.getBounds();
        q.line(Path()..moveTo(b.left + b.width * .2, b.top + b.height * .66)..lineTo(b.left + b.width * .44, b.top + b.height * .24), w: 3.0 * sc, color: withA(const Color(0xFFFFFFFF), .85));
        q.line(Path()..moveTo(b.left + b.width * .6, b.top + b.height * .8)..lineTo(b.left + b.width * .74, b.top + b.height * .5), w: 1.6 * sc, color: withA(const Color(0xFFFFFFFF), .6));
      });
      pen.line(lensP, w: Style.lineThin * sc);
    }
    // bridge
    pen.shape(h.path(svg('M-4.5 ${y - 2} L4.5 ${y - 2} L4.5 ${y + 3} L-4.5 ${y + 3} Z'), lift: 8.4), rim.base, w: Style.lineThin * sc);
  }
}

/// A glossy pearl with a soft glow.
void bPearl(Pen pen, Offset c, double r, {bool glow = true}) {
  if (glow) pen.glow(c, r * 2.4, r * 2.4, const Color(0xFFFFFFFF), alpha: .5);
  final p = circle(c.dx, c.dy, r);
  pen.fill(p, const Color(0xFFFBF6EE));
  pen.inside(p, (q) {
    q.crescent(p, const Color(0xFFC9C6E4), depth: r * .55, dir: const Offset(-0.6, -0.8));
    q.glow(c + Offset(r * .2, r * .25), r * .75, r * .55, const Color(0xFFFFC9E0), alpha: .4);
    q.rim(p, const Color(0xFFFFFFFF), depth: r * .22, dir: const Offset(-0.6, -0.8));
  });
  pen.line(p, w: Style.line * .95);
  pen.fill(circle(c.dx - r * .38, c.dy - r * .4, r * .22), const Color(0xFFFFFFFF));
  pen.fill(circle(c.dx + r * .3, c.dy + r * .38, r * .1), withA(const Color(0xFFFFFFFF), .85));
}

/// A water droplet (teardrop) of size [r].
void bDrop(Pen pen, Offset c, double r, {double rot = 0}) {
  final p = _fx(svg('M0 -5 C2.2 -1.6 3.2 .8 3.2 2.4 C3.2 4.2 1.8 5.4 0 5.4 C-1.8 5.4 -3.2 4.2 -3.2 2.4 C-3.2 .8 -2.2 -1.6 0 -5 Z'), c, rot, r / 3.2);
  pen.fill(p, const Color(0xFFBDEBFA));
  pen.inside(p, (q) => q.crescent(p, const Color(0xFF66BCE0), depth: r * .5, dir: const Offset(-0.5, -0.8)));
  pen.line(p, w: Style.lineThin * .8, color: const Color(0xFF2B5C7A));
  pen.fill(circle(c.dx - r * .32, c.dy + r * .1, r * .2), const Color(0xFFFFFFFF));
}

/// A bubble: outlined translucent circle with a glint.
void bBubble(Pen pen, Offset c, double r) {
  final p = circle(c.dx, c.dy, r);
  pen.fill(p, const Color(0x40FFFFFF));
  pen.inside(p, (q) => q.rim(p, const Color(0x66FFFFFF), depth: r * .3, dir: const Offset(-0.6, -0.8)));
  pen.line(p, w: Style.lineThin * .8, color: const Color(0xCCFFFFFF));
  bGlint(pen, c + Offset(-r * .5, -r * .1), c + Offset(-r * .12, -r * .55), w: r * .35);
}

/// A point of a hand frame (local coordinates) in global space; same transform the hands use.
Offset bHandPoint(Offset at, double rot, double s, Offset local, {bool mirror = false}) {
  final cs = math.cos(rot) * s, sn = math.sin(rot) * s;
  final mx = mirror ? -1.0 : 1.0;
  final x = local.dx * mx, y = local.dy;
  return Offset(cs * x - sn * y + at.dx, sn * x + cs * y + at.dy);
}

/// A fist rising from below that pinches something between thumb and index finger (local frame:
/// forearm down +y, fingertips at y = -27). [at] = fist centre.
void bPinchHand(Pen pen, Offset at, double rot, double s, Skin skin, {Tones sleeve = Cloth.white, bool showSleeve = true, bool mirror = false}) {
  Path P(String d) => _fx(svg(d), at, rot, s, mirror);
  final lw = Style.line * .9 * s;
  final fine = Style.lineThin * .85 * s;
  if (showSleeve) {
    final arm = P('M-11 10 C-14 26 -16 50 -18 80 L20 80 C19 50 16 26 12 10 Z');
    pen.fill(arm, skin.base);
    pen.crescent(arm, skin.shade, depth: 4 * s, dir: const Offset(-0.9, -0.3));
    pen.line(arm, w: lw);
    // wet wrist band (rope)
    final band = P('M-13 13 C-5 17 6 17 14 13 L15.5 20 C6 24 -6 24 -15 20 Z');
    pen.solid(band, sleeve, shade: 2 * s, hi: .8 * s, w: lw * .8);
  }
  final index = P('M-10 -4 C-13 -14 -11 -23 -5 -28 C-2 -30 .5 -28 -1 -25 C-4 -21 -3 -13 -2 -5 Z');
  final thumb = P('M10 0 C14 -8 13 -19 7 -26 C4 -29 1.5 -26 3 -23 C6 -18 5 -10 3 -3 Z');
  final fist = P('M-12.5 -4 C-12.5 -12 -6 -15 0 -15 C7 -15 12.5 -12 12.5 -4 L12.5 8 C12.5 13 7 15 0 15 C-7 15 -12.5 13 -12.5 8 Z');
  pen.solid(index, skin.tones, shade: 2 * s, hi: .7 * s, w: lw * .85);
  pen.solid(thumb, skin.tones, shade: 2 * s, hi: .7 * s, w: lw * .85);
  pen.fill(fist, skin.base);
  pen.crescent(fist, skin.shade, depth: 3.6 * s, dir: const Offset(-0.9, -0.3));
  pen.rim(fist, skin.hi, depth: 1.2 * s);
  pen.inside(fist, (q) {
    for (final y in const [-4.0, 3.0, 10.0]) {
      q.line(P('M-13 ${y + 1} C-5 ${y - 2} 5 ${y - 2} 13 ${y + 1}'), w: fine * .95, color: withA(Style.ink, .85));
    }
  });
  pen.line(fist, w: lw);
}

// ───────────────────────────── poet bits ─────────────────────────────

/// A long quill feather. Local frame: grip point at the origin, feather along -y (tip at about
/// y = -112 * s). Draw it BEFORE the hand that holds it.
void bQuill(Pen pen, Offset at, double rot, double s, {Tones vane = const Tones(Color(0xFFF7F2EA), Color(0xFFA9B4D6), Color(0xFFFFFFFF)), Color tip = const Color(0xFF5B6FC4)}) {
  Path P(String d) => _fx(svg(d), at, rot, s);
  final lw = Style.line * .9 * s;
  final feather = P('M1 -24 C10 -38 21 -68 11 -100 C8 -107 5 -111 1.5 -116 C-2 -108 -9 -96 -11 -78 C-13 -58 -8 -38 -1.5 -24 Z');
  pen.fill(feather, vane.base);
  pen.inside(feather, (q) {
    // blue-grey shadow on the right half + coloured tip
    q.fill(P('M1.5 -116 C8 -104 16 -92 16 -70 C12 -46 5 -34 1 -26 Z'), withA(vane.shade, .8));
    q.fill(P('M1.5 -116 C5 -110 9 -106 11 -100 C13 -96 14 -92 14 -88 C8 -92 -4 -92 -11 -86 C-9 -96 -3 -108 1.5 -116 Z'), tip);
    // barbs
    for (var i = 0; i < 9; i++) {
      final y = -30.0 - i * 8.6;
      q.line(P('M0.6 $y C6 ${y - 3.4} 11 ${y - 7} ${16 - i * .5} ${y - 11}'), w: Style.lineFine * .8 * s, color: withA(vane.shade, .95));
      q.line(P('M-0.4 $y C-5 ${y - 3} -9 ${y - 6} ${-13 + i * .3} ${y - 9}'), w: Style.lineFine * .7 * s, color: withA(vane.shade, .8));
    }
    q.rim(feather, vane.hi, depth: 1.8 * s, dir: const Offset(-0.9, -0.2));
  });
  pen.line(feather, w: lw);
  // shaft
  final shaft = P('M0 18 L0 -24 C4 -46 8 -80 1.5 -115');
  pen.line(shaft, w: 2.3 * s, color: Style.ink);
  pen.line(shaft, w: 1.2 * s, color: const Color(0xFFF1D9A0));
}
