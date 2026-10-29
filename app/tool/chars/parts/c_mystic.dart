// Worker C: the mystery characters: seer (feathered turban, robe, crystal ball + hands, glowing
// eyes), ghost (hooded cloak, glowing eyes and mouth), assassin (black wraps, dagger in a
// gloved fist, red glowing eyes) and sultana (gold-trimmed hijab, forehead jewel, coin veil).
import '../kit.dart';
import 'c_gear.dart';
import 'c_rig.dart';

// ───────────────────────────────── seer ─────────────────────────────────

const seerPurple = Tones(Color(0xFF6A2FC0), Color(0xFF43198A), Color(0xFF9156E6));
const robePurple = Tones(Color(0xFF4D1F9C), Color(0xFF2F1068), Color(0xFF7440CE));
const orbT = Tones(Color(0xFFA55BF2), Color(0xFF5E27B0), Color(0xFFE2C2FF));

/// White plume on the turban, curling up and back from the jewel.
void drawTurbanFeather(Pen pen, Head h, {double x = 6, double y = -88}) {
  final sc = h.scale;
  final p = h.path(
    svg('M$x $y C${x + 1} ${y - 10} ${x + 8} ${y - 19} ${x + 20} ${y - 22} C${x + 15} ${y - 15} ${x + 17} ${y - 10} ${x + 12} ${y - 4} C${x + 9} ${y - 1} ${x + 5} 0 ${x - 2} ${y + 4} Z'),
    lift: 8,
  );
  pen.fill(p, const Color(0xFFF7F2FA));
  pen.crescent(p, const Color(0xFFC9BFDD), depth: 3 * sc, dir: const Offset(0.6, 0.8));
  pen.inside(p, (q) {
    q.taper(h.path(svg('M${x - 1} ${y + 3} C${x + 3} ${y - 6} ${x + 11} ${y - 15} ${x + 19} ${y - 21}'), lift: 8), w0: 1.2 * sc, w1: .2 * sc, color: withA(const Color(0xFF8E7FB0), .95));
    for (final d in const [(7, -4, 3), (6, -9, 4), (11, -14, 5)]) {
      q.taper(h.path(svg('M${x + d.$1 - 2} ${y + d.$2 + 4} L${x + d.$1 + 8} ${y + d.$2 - d.$3 * .5}'), lift: 8), w0: .9 * sc, w1: .1 * sc, color: withA(const Color(0xFFB8AAD0), .9));
    }
  });
  pen.line(p, w: Style.line * .9 * sc, color: Style.ink);
}

/// A hand curled around a sphere: each finger is a capsule (ink pass then skin pass) so the
/// silhouette is one clean outline. [mirror] puts the hand on the viewer's right.
void drawCupHand(Pen pen, Offset c, double k, Skin skin, {bool mirror = false, Tones sleeve = robePurple}) {
  final m = mirror ? -1.0 : 1.0;
  Offset P(double x, double y) => Offset(c.dx + m * x * k, c.dy + y * k);
  final fingers = <(Offset, Offset)>[
    (P(-23, 30), P(-12, 21)),
    (P(-26, 24), P(-15, 12)),
    (P(-28, 17), P(-17, 3)),
    (P(-28, 10), P(-18, -4)),
  ];
  final fw = 6.2 * k, ow = Style.line * .9 * k;
  Path line(Offset a, Offset b) => Path()
    ..moveTo(a.dx, a.dy)
    ..lineTo(b.dx, b.dy);
  // sleeve
  final cuff = poly([P(-44, 52), P(-34, 22), P(-22, 34), P(-22, 60)]);
  pen.solid(cuff, sleeve, shade: 3 * k, hi: 1 * k, w: ow);
  // palm
  final palm = ellipse(P(-30, 29).dx, P(-30, 29).dy, 9.5 * k, 12.5 * k, rot: m * -0.55);
  for (final f in fingers) {
    pen.line(line(f.$1, f.$2), w: fw + ow * 2, color: Style.ink);
  }
  pen.line(palm, w: ow * 2, color: Style.ink);
  for (final f in fingers) {
    pen.line(line(f.$1, f.$2), w: fw, color: skin.base);
  }
  pen.fill(palm, skin.base);
  // finger shade + knuckle lines
  for (final f in fingers) {
    pen.line(line(f.$1 + Offset(m * 1.2 * k, 1.6 * k), f.$2 + Offset(m * .6 * k, 1.8 * k)), w: 1.4 * k, color: withA(skin.shade, .9));
  }
  final lines = [fingers[0].$1, fingers[1].$1, fingers[2].$1, fingers[3].$1];
  for (final p in lines) {
    pen.line(line(p + Offset(m * 3.4 * k, -3.2 * k), p + Offset(m * 5.6 * k, -1.4 * k)), w: Style.lineFine * k, color: withA(Style.ink, .7));
  }
  // thumb along the front
  final thumb = Path()
    ..moveTo(P(-30, 36).dx, P(-30, 36).dy)
    ..lineTo(P(-18, 28).dx, P(-18, 28).dy);
  pen.line(thumb, w: 5.6 * k + ow * 2, color: Style.ink);
  pen.line(thumb, w: 5.6 * k, color: skin.base);
  pen.line(thumb.shift(Offset(0, 1.5 * k)), w: 1.2 * k, color: withA(skin.shade, .9));
}

/// The crystal ball sphere with swirling clouds, its brass cup, and two hands. [c] centre, [r] radius.
void drawCrystalBall(Pen pen, Offset c, double r, Skin skin) {
  final k = r / 19.0;
  // brass cup under the sphere
  final cup = poly([Offset(c.dx - r * .66, c.dy + r * .72), Offset(c.dx + r * .66, c.dy + r * .72), Offset(c.dx + r * .46, c.dy + r * 1.22), Offset(c.dx - r * .46, c.dy + r * 1.22)]);
  pen.solid(cup, goldT, shade: 2.4 * k, hi: 1 * k, w: Style.line * .9 * k);
  final sphere = circle(c.dx, c.dy, r);
  pen.fill(sphere, orbT.base);
  pen.inside(sphere, (p) {
    p.glow(Offset(c.dx + r * .15, c.dy + r * .2), r * .95, r * .8, const Color(0xFFF0DAFF), alpha: .55);
    p.crescent(sphere, orbT.shade, depth: r * .6, dir: const Offset(-0.6, -0.8));
    // cloud swirls
    for (final (i, rr) in const [(0, 0.52), (1, 0.3)]) {
      final path = Path()..addArc(Rect.fromCircle(center: Offset(c.dx + r * .05, c.dy + r * .08), radius: r * rr), 3.5 + i * 2.2, 3.4);
      p.line(path, w: 2.4 * k, color: withA(const Color(0xFFFFFFFF), .75));
    }
    p.line(Path()..addArc(Rect.fromCircle(center: Offset(c.dx - r * .2, c.dy + r * .3), radius: r * .32), .2, 2.6), w: 1.6 * k, color: withA(const Color(0xFFFFFFFF), .55));
  });
  pen.line(sphere, w: Style.line * k, color: Style.ink);
  // glass highlights
  pen.line(Path()..addArc(Rect.fromCircle(center: c, radius: r * .78), 3.55, 1.0), w: 2.6 * k, color: const Color(0xFFFFFFFF));
  pen.fill(circle(c.dx - r * .5, c.dy - r * .34, r * .1), const Color(0xFFFFFFFF));
  pen.line(Path()..addArc(Rect.fromCircle(center: c, radius: r * .8), 0.55, .5), w: 1.4 * k, color: withA(const Color(0xFFFFFFFF), .6));
  drawCupHand(pen, c, k, skin);
  drawCupHand(pen, c, k, skin, mirror: true);
}

/// The sphere's glow (rig layer `ball_glow`): inner light + a soft halo.
void drawBallGlow(Pen pen, Offset c, double r) {
  pen.glow(c, r * 1.85, r * 1.85, const Color(0xFFE879F9), alpha: .5);
  final sphere = circle(c.dx, c.dy, r * .98);
  pen.inside(sphere, (p) {
    p.fill(sphere, withA(const Color(0xFFF5D0FE), .55));
    p.glow(c, r, r, const Color(0xFFFFFFFF), alpha: .6);
  });
}

/// Glowing eyes overlay (rig layer `eyes`): halo + bright core over each eye of [eyes].
void drawEyeGlow(Pen pen, Head h, EyeSpec eyes, Color col, {double halo = 1.0, double core = 1.0, Color hot = const Color(0xFFFFFFFF), double tint = .9, double hotAlpha = .95}) {
  for (final side in const [-1, 1]) {
    final e = (side < 0 ? eyes.left : eyes.right) ?? eyes;
    final c = h.pt(side * e.gap, e.y, lift: 2.0);
    pen.glow(c, e.ew * 1.7 * h.scale * halo, e.eh * 1.5 * h.scale * halo, col, alpha: .55);
    final contour = h.path(
      xform(svg('M-1 0.12 C-1 -0.6 -0.55 -1 0.05 -1 C0.65 -1 1 -0.5 1 0.02 C1 0.62 0.55 1 -0.02 1 C-0.6 1 -1 0.66 -1 0.12 Z'), sx: side * e.ew * .92 * core, sy: e.eh * .86 * core, tx: side * e.gap, ty: e.y),
      lift: 2.0,
    );
    pen.fill(contour, withA(col, tint));
    pen.glow(c, e.ew * .7 * h.scale, e.eh * .6 * h.scale, hot, alpha: hotAlpha);
  }
}

// ───────────────────────────────── ghost ─────────────────────────────────

const hoodT = Tones(Color(0xFF2A1A4A), Color(0xFF150C2A), Color(0xFF4E3A7C));

Path _hoodOuter() => svg(
  'M16 214 C20 180 28 156 46 138 C42 120 40 96 44 76 C50 46 70 26 94 16 C100 12 104 10 110 12 C116 14 118 20 114 24 C108 24 106 28 110 32 '
  'C136 40 156 62 160 92 C162 112 160 128 156 140 C172 156 182 180 186 214 Z',
);

Path _hoodFace() => svg('M100 50 C124 50 138 74 138 102 C138 130 122 152 100 154 C78 152 62 130 62 102 C62 74 76 50 100 50 Z');

/// The whole hooded cloak (rig layer `cloak`): dark violet cloth, deep void inside the hood.
void drawGhostCloak(Pen pen) {
  final outer = _hoodOuter();
  pen.fill(outer, hoodT.base);
  pen.crescent(outer, hoodT.shade, depth: 12, dir: const Offset(-0.9, -0.3));
  pen.rim(outer, hoodT.hi, depth: 2.6, dir: const Offset(-0.9, -0.5));
  pen.inside(outer, (p) {
    // soft light sweeping over the hood top
    p.taper(svg('M60 70 C64 46 80 30 100 22'), w0: 4.4, w1: .4, color: withA(hoodT.hi, .85));
    p.taper(svg('M50 96 C50 80 54 66 60 54'), w0: 2.4, w1: .3, color: withA(hoodT.hi, .7));
    // deep folds of the cloak
    for (final d in const [
      'M70 150 C60 168 54 190 52 214',
      'M92 158 C90 176 90 196 92 214',
      'M116 158 C120 176 124 196 128 214',
      'M138 148 C148 166 154 190 156 214',
    ]) {
      p.taper(svg(d), w0: 3.2, w1: .4, color: withA(hoodT.shade, .95));
    }
    p.taper(svg('M40 142 C46 170 44 190 42 214'), w0: 2.2, w1: .3, color: withA(Style.ink, .5));
    // hood opening: thick cloth edge (rolled), then the void
    final face = _hoodFace();
    p.line(face, w: 13, color: withA(hoodT.shade, .9));
    p.line(face.shift(const Offset(-1, -1)), w: 3.2, color: withA(hoodT.hi, .6));
  });
  pen.line(outer, w: Style.line * 1.1, color: Style.ink);
  final face = _hoodFace();
  pen.fill(face, const Color(0xFF07030F));
  pen.inside(face, (p) {
    p.glow(const Offset(100, 126), 44, 40, const Color(0xFF5B2BA8), alpha: .22);
    p.crescent(face, const Color(0xFF03010A), depth: 8, dir: const Offset(-0.7, -0.7));
  });
  pen.line(face, w: Style.line * 1.05, color: Style.ink);
}

/// Glowing slanted eyes (rig layer `eyes`), centred around (100,[y]).
void drawGhostEyes(Pen pen, {double y = 106}) {
  for (final s in const [-1, 1]) {
    final c = Offset(100 + s * 15, y);
    pen.glow(c, 22, 15, const Color(0xFFA855F7), alpha: .5);
    final eye = svg('M-10 2 C-8 -6 4 -8 10 -3 C8 4 -2 7 -10 2 Z');
    final rotated = rotatedAbout(xform(eye, sx: s * 1.0, tx: c.dx, ty: c.dy), c, s * 0.2);
    pen.fill(rotated, const Color(0xFFC490FF));
    pen.inside(rotated, (q) {
      q.glow(Offset(c.dx + s * 1, c.dy), 8, 5, const Color(0xFFFFFFFF), alpha: .95);
    });
    pen.line(rotated, w: 1.0, color: withA(const Color(0xFFEBD8FF), .9));
  }
}

/// Open "boo" mouth (rig layer `mouth`), centred around (100,[y]).
void drawGhostMouth(Pen pen, {double y = 134}) {
  pen.glow(Offset(100, y), 17, 20, const Color(0xFFA855F7), alpha: .45);
  final m = ellipse(100, y, 7.5, 10);
  pen.fill(m, const Color(0xFFC490FF));
  pen.fill(ellipse(100, y + 1, 4.6, 7), const Color(0xFF06020D));
  pen.line(m, w: 1.0, color: withA(const Color(0xFFEBD8FF), .9));
}

// ───────────────────────────────── assassin ─────────────────────────────────

const blackT = Tones(Color(0xFF2B2833), Color(0xFF15121C), Color(0xFF55506A));
const crimsonT = Tones(Color(0xFFC21F2F), Color(0xFF7F1220), Color(0xFFF2606A));
const steelBladeT = Tones(Color(0xFFD6DCE6), Color(0xFF8E98AA), Color(0xFFFFFFFF));

/// Thin crimson band wrapped over the black turban (a splash of colour).
class HeadBand extends Headwear {
  const HeadBand({this.y = -33, this.t = crimsonT});

  final double y;
  final Tones t;

  @override
  void back(Pen pen, Head h, Skin skin) {}

  @override
  void front(Pen pen, Head h, Skin skin) {
    final sc = h.scale;
    final band = ring3D(h, y - 9, 53, 6.4, sag: 4, span: 78, lift: 5);
    pen.fill(band, t.base);
    pen.rim(band, t.hi, depth: 1.2 * sc, dir: const Offset(-0.3, -1));
    pen.crescent(band, t.shade, depth: 1.8 * sc, dir: const Offset(0.2, -1));
    pen.line(band, w: Style.line * .8 * sc, color: Style.ink);
  }
}

/// Gloved fist holding a curved dagger, centred on the grip at [c]. [angle] radians (clockwise
/// from straight up). Painted in global coordinates; the rig rotates this layer about [c].
void drawDaggerFist(Pen pen, Offset c, {double angle = 0.35, double k = 1.0}) {
  pen.c.save();
  pen.c.translate(c.dx, c.dy);
  pen.c.rotate(angle);
  pen.c.scale(k);
  // black sleeve cuff coming from the bottom
  final sleeve = svg('M-11 8 C-12 22 -13 36 -14 52 L14 52 C13 36 12 22 11 8 Z');
  pen.solid(sleeve, blackT, shade: 4, hi: 1.4, w: Style.line * .95);
  pen.line(svg('M-12 14 C-6 17 6 17 12 14'), w: Style.lineThin, color: withA(blackT.hi, .9));
  // blade (curved khanjar)
  final blade = svg('M-6.5 -7 C-9 -20 -6 -36 4 -52 C4 -36 8 -22 6.5 -7 Z');
  pen.solid(blade, steelBladeT, shade: 3, hi: 1.2, w: Style.line * .9);
  pen.inside(blade, (p) {
    p.line(svg('M-0.5 -10 C-2 -24 0 -38 3 -47'), w: 1.1, color: withA(Style.ink, .5));
    p.line(svg('M-3 -12 C-4.5 -24 -3 -34 -.5 -43'), w: 1.4, color: const Color(0xFFFFFFFF));
  });
  // crossguard
  final guard = svg('M-13 -8 C-8 -11 8 -11 13 -8 C14 -4 12 -2 9 -3 C4 -5 -4 -5 -9 -3 C-12 -2 -14 -4 -13 -8 Z');
  pen.solid(guard, goldT, shade: 1.6, hi: .8, w: Style.lineThin * 1.1);
  // pommel
  pen.solid(circle(0, 18.5, 4.2), goldT, shade: 1.4, hi: .8, w: Style.lineThin);
  pen.fill(circle(0, 18.5, 1.8), rubyT.base);
  // glove fist around the grip
  final fist = svg('M-9.5 -2 C-11 -8 -3 -10 0 -9 C5 -10 11 -8 9.5 -2 C12 4 11 12 7 15 C2 17 -4 17 -8 15 C-12 12 -12 4 -9.5 -2 Z');
  pen.solid(fist, blackT, shade: 3, hi: 1.4, w: Style.line * .95);
  pen.inside(fist, (p) {
    for (final y in const [0.5, 5.0, 9.5]) {
      p.line(svg('M-10 $y C-4 ${y + 1.4} 4 ${y + 1.4} 10 $y'), w: Style.lineThin * .9, color: withA(Style.ink, .85));
    }
    p.line(svg('M-8 -5 C-4 -7 3 -7 7 -5'), w: 1.2, color: withA(blackT.hi, .95));
  });
  pen.c.restore();
}

// ───────────────────────────────── sultana ─────────────────────────────────

const sultanaT = Tones(Color(0xFF3F1B66), Color(0xFF26103F), Color(0xFF6A3A9C));

/// Gold embroidered edge along the hijab's face opening + a maang-tikka forehead jewel.
class SultanaAdornments extends Headwear {
  const SultanaAdornments({this.hem = -34});

  final double hem;

  @override
  void back(Pen pen, Head h, Skin skin) {}

  @override
  void front(Pen pen, Head h, Skin skin) {
    final sc = h.scale;
    final edge = spline([
      const Offset(-48, 14),
      Offset(-43, hem + 20),
      Offset(-30, hem + 8),
      Offset(-12, hem + 1),
      Offset(0, hem - 1),
      Offset(12, hem + 1),
      Offset(30, hem + 8),
      Offset(43, hem + 20),
      const Offset(48, 14),
    ], tension: .9);
    final p = h.path(edge.shift(const Offset(0, 0.8)), lift: 7.5);
    pen.line(p, w: 4.4 * sc, color: Style.ink);
    pen.line(p, w: 2.6 * sc, color: goldT.base);
    pen.line(p.shift(Offset(-.3 * sc, -.7 * sc)), w: .8 * sc, color: goldT.hi);
    // tiny gold coins hanging from the edge
    for (final u in const [-30.0, -16.0, 0.0, 16.0, 30.0]) {
      final y = _edgeY(u, hem);
      final c = h.pt(u, y + 3.2, lift: 7.5);
      pen.fill(circle(c.dx, c.dy, 1.6 * sc), goldT.hi);
      pen.line(circle(c.dx, c.dy, 1.6 * sc), w: Style.lineFine * .9 * sc, color: Style.ink);
    }
    // maang tikka: a thin chain down the parting, ruby drop on the forehead
    final chain = h.path(svg('M0 ${hem - 40} C0 ${hem - 26} 0 ${hem - 12} 0 ${hem - 2}'), lift: 8);
    pen.line(chain, w: 2.4 * sc, color: Style.ink);
    pen.line(chain, w: 1.1 * sc, color: goldT.base);
    gem(pen, h.pt(0, hem + 8, lift: 9), 3.7 * sc, rubyT, lw: sc);
  }

  static double _edgeY(double x, double hem) {
    final a = x.abs();
    if (a < 12) return hem + 1 * (a / 12) - 1 * (1 - a / 12);
    if (a < 30) return hem + 1 + 7 * ((a - 12) / 18);
    return hem + 8 + 12 * ((a - 30) / 13);
  }
}

/// Coin-trimmed yashmak covering the lower face (rig layer `veil`, also part of the still).
void drawYashmak(Pen pen, Head h, Skin skin, {Tones cloth = sultanaT, double eyeBottom = 7}) {
  final sc = h.scale;
  FaceVeil(cloth: cloth, eyeBottom: eyeBottom).front(pen, h, skin);
  // gold edge + dangling coins along the top edge of the veil
  final top = spline([Offset(-52, eyeBottom + 6), Offset(-30, eyeBottom + 3), const Offset(-12, 13), const Offset(0, 15), const Offset(12, 13), Offset(30, eyeBottom + 3), Offset(52, eyeBottom + 6)], tension: .9);
  final p = h.path(top.shift(const Offset(0, 1.6)), lift: 6);
  pen.line(p, w: 4.6 * sc, color: Style.ink);
  pen.line(p, w: 2.8 * sc, color: goldT.base);
  pen.line(p.shift(Offset(-.3 * sc, -.8 * sc)), w: .8 * sc, color: goldT.hi);
  for (var i = 0; i < 9; i++) {
    final x = -40.0 + i * 10;
    final y = eyeBottom + 4 + (x.abs() < 14 ? 9 - (14 - x.abs()) * .12 : (x.abs() - 12) * -.0);
    final c = h.pt(x, y + 4.6, lift: 7);
    pen.fill(circle(c.dx, c.dy, 2.0 * sc), goldT.base);
    pen.crescent(circle(c.dx, c.dy, 2.0 * sc), goldT.shade, depth: .9 * sc);
    pen.line(circle(c.dx, c.dy, 2.0 * sc), w: Style.lineFine * sc, color: Style.ink);
  }
  // a faint gold hem line near the jaw
  final hemLine = h.path(svg('M-34 64 C-14 80 14 80 34 64'), lift: 6);
  pen.line(hemLine, w: 1.6 * sc, color: withA(goldT.base, .85));
}

/// Black robe with a high collar (covers the neck under the veil) and a crimson bandolier.
class NinjaRobe extends Body {
  const NinjaRobe({this.cloth = blackT, this.strap = crimsonT});

  final Tones cloth, strap;

  @override
  void draw(Pen pen, Head h, Skin skin) {
    final dx = Body.turn(h);
    final sc = h.scale;
    final p = rel(h, shoulderPath, dx: dx);
    pen.solid(p, cloth, shade: 8 * sc, hi: 2.4 * sc, dir: const Offset(-0.95, -0.35));
    pen.inside(p, (q) {
      q.taper(rel(h, 'M-52 20 C-44 50 -42 80 -46 112', dx: dx), w0: 2.6 * sc, w1: .3 * sc, color: withA(cloth.shade, .95));
      q.taper(rel(h, 'M-74 30 C-68 50 -68 70 -72 92', dx: dx), w0: 1.8 * sc, w1: .2 * sc, color: withA(cloth.hi, .6));
      // diagonal strap with a gold buckle
      final band = rel(h, 'M-40 -4 L-22 -12 L104 56 L104 86 Z', dx: dx);
      q.fill(band, strap.base);
      q.crescent(band, strap.shade, depth: 4 * sc, dir: const Offset(0.5, 0.8));
      q.rim(band, strap.hi, depth: 1.4 * sc, dir: const Offset(-0.5, -0.8));
      q.line(band, w: Style.line * .9 * sc, color: Style.ink);
    });
    pen.line(p, w: Style.line * sc);
  }

  @override
  void drawFront(Pen pen, Head h, Skin skin) {
    final dx = Body.turn(h);
    final sc = h.scale;
    final collar = rel(h, 'M-26 -20 C-27 -8 -25 2 -20 9 C-9 17 9 17 20 9 C25 2 27 -8 26 -20 C14 -13 -14 -13 -26 -20 Z', dx: dx);
    pen.solid(collar, cloth, shade: 3.5 * sc, hi: 1.4 * sc, w: Style.lineThin * 1.3 * sc);
    pen.line(rel(h, 'M-18 5 C-8 12 8 12 18 5', dx: dx), w: Style.lineFine * sc, color: withA(cloth.hi, .8));
  }
}
