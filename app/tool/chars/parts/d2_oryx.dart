// champ1 / champ2 / champ3: the weekly champions — an Arabian oryx with long ringed horns, a laurel wreath
// and a numbered medal, in gold / silver / bronze. One design, three metal variants.
// Rig layers: body (wreath + chest), ear_l, ear_r, head (horns + face), blink, mouth (laugh), medal (ribbon + medal).
import 'dart:math' as math;
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';
import 'brows.dart';
import 'd2_animal.dart';
import 'd2_digits.dart';
import 'eyes.dart';

/// Colours that change between gold / silver / bronze.
class OryxMetal {
  const OryxMetal({required this.n, required this.horn, required this.leaf, required this.leafAlt, required this.medal, required this.medalFace, required this.digit, required this.ring});

  /// 1, 2 or 3 (the number on the medal).
  final int n;
  final Tones horn;
  final Tones leaf;
  final Tones leafAlt;
  final Tones medal;
  final Tones medalFace;
  final Color digit;

  /// Darker line colour of the horn rings.
  final Color ring;
}

const oryxGold = OryxMetal(
  n: 1,
  horn: Tones(Color(0xFFF7C93E), Color(0xFFC98A12), Color(0xFFFFEB9E)),
  leaf: Tones(Color(0xFFF7C93E), Color(0xFFC98A12), Color(0xFFFFEB9E)),
  leafAlt: Tones(Color(0xFFE9A92A), Color(0xFFB8740C), Color(0xFFFFDB78)),
  medal: Tones(Color(0xFFF2B72E), Color(0xFFB87A0A), Color(0xFFFFE27A)),
  medalFace: Tones(Color(0xFFFFE07A), Color(0xFFE8B23A), Color(0xFFFFF3B8)),
  digit: Color(0xFF7A4A00),
  ring: Color(0xFF9A6408),
);

const oryxSilver = OryxMetal(
  n: 2,
  horn: Tones(Color(0xFFD9E0EA), Color(0xFF8C99AD), Color(0xFFF8FBFF)),
  leaf: Tones(Color(0xFFD9E0EA), Color(0xFF8C99AD), Color(0xFFF8FBFF)),
  leafAlt: Tones(Color(0xFFBFC9D8), Color(0xFF7A879D), Color(0xFFEAF0F8)),
  medal: Tones(Color(0xFFC9D3E0), Color(0xFF7D8BA1), Color(0xFFF3F7FC)),
  medalFace: Tones(Color(0xFFEAF0F7), Color(0xFFB5C1D1), Color(0xFFFFFFFF)),
  digit: Color(0xFF3E4C62),
  ring: Color(0xFF66748A),
);

const oryxBronze = OryxMetal(
  n: 3,
  horn: Tones(Color(0xFFDD9054), Color(0xFF9C5228), Color(0xFFF7BE8E)),
  leaf: Tones(Color(0xFFDD9054), Color(0xFF9C5228), Color(0xFFF7BE8E)),
  leafAlt: Tones(Color(0xFFC77B42), Color(0xFF86441E), Color(0xFFEBA672)),
  medal: Tones(Color(0xFFD38548), Color(0xFF8E4A22), Color(0xFFF2B27F)),
  medalFace: Tones(Color(0xFFF0B07A), Color(0xFFC77E46), Color(0xFFFFD2AA)),
  digit: Color(0xFF5E300F),
  ring: Color(0xFF7E421C),
);

const _face = Tones(Color(0xFFFFFAF1), Color(0xFFDAD0DE), Color(0xFFFFFFFF));
const _mark = Tones(Color(0xFF46332B), Color(0xFF2A1C16), Color(0xFF745A4C));
const _earIn = Tones(Color(0xFFF4BFB6), Color(0xFFD98F8C), Color(0xFFFFDDD6));
const _chest = Tones(Color(0xFF5A3F31), Color(0xFF38251C), Color(0xFF7E5E4C));
const _fur = Tones(Color(0xFFFFF6EA), Color(0xFFD7CCDC), Color(0xFFFFFFFF));
const _ribbon = Tones(Color(0xFFE2343B), Color(0xFF9B1822), Color(0xFFFF7078));
const _stem = Tones(Color(0xFF7A4E2A), Color(0xFF4E2F18), Color(0xFFA67444));

const _eyes = EyeSpec(
  ew: 12.4,
  eh: 14,
  gap: 21.5,
  lookX: 0.3,
  lookY: -0.3,
  iris: Color(0xFF4A2A14),
  irisR: 0.7,
  pupilR: 0.56,
  lidTop: 0.0,
  lidSlant: -0.1,
  lidBottom: 0.1,
  lid: 3.6,
);

const _brows = BrowSpec(
  lift: 8.5,
  inner: -2,
  outer: 1.6,
  arch: 4.2,
  thick: 5.6,
  taper: 0.5,
  color: HairColor(Color(0xFF46332B), Color(0xFF2A1C16), Color(0xFF745A4C)),
);

final Head _eh = d2EyeHead(100, 97);

final Path _headShape = d2Sym(
  'M100 62 C118 62 131 71 132 90 C133 106 129 120 123 133 C119 143 116 154 110 160 C106 164 103 165 100 165 Z',
);

/// One laurel leaf: pointed ellipse with its tip at [at] + [ang] direction.
Path _leaf(Offset base, double ang, double len, double wid) {
  final p = svg('M0 0 C${wid * .95} ${-len * .28} ${wid * .8} ${-len * .78} 0 ${-len} C${-wid * .8} ${-len * .78} ${-wid * .95} ${-len * .28} 0 0 Z');
  final a = ang + math.pi / 2;
  final cs = math.cos(a), sn = math.sin(a);
  return p.transform(affine(cs, sn, -sn, cs, base.dx, base.dy));
}

void _laurel(Pen pen, OryxMetal v) {
  const c = Offset(100, 120);
  const r = 76.0;
  for (final side in [-1, 1]) {
    Offset pt(double th) {
      final a = side < 0 ? th : math.pi - th;
      return c + Offset(math.cos(a), math.sin(a)) * r;
    }

    double tangent(double th) {
      // direction of growth (towards the top of the wreath)
      final a = side < 0 ? th : math.pi - th;
      final d = Offset(-math.sin(a), math.cos(a)) * (side < 0 ? 1 : -1);
      return math.atan2(d.dy, d.dx);
    }

    const t0 = 1.62, t1 = 3.78; // radians (from just past the bottom to the upper side)
    final pts = <Offset>[for (var i = 0; i <= 12; i++) pt(t0 + (t1 - t0) * i / 12)];
    final stem = spline(pts);
    pen.line(stem, w: 5.6, color: Style.ink);
    pen.line(stem, w: 3, color: _stem.base);
    const steps = 9;
    for (var pass = 0; pass < 2; pass++) {
      for (var i = 0; i < steps; i++) {
        final th = t0 + 0.1 + (t1 - t0 - 0.1) * i / (steps - 1);
        final p = pt(th);
        final grow = tangent(th);
        final size = 1 - 0.25 * i / steps;
        for (final k in [-1, 1]) {
          final isOuter = k < 0;
          if ((pass == 0) != !isOuter) continue;
          final ang = grow + k * 0.62;
          final tones = (i + (isOuter ? 1 : 0)).isEven ? v.leaf : v.leafAlt;
          final lf = _leaf(p, ang, 17 * size, 7.4 * size);
          pen.solid(lf, tones, shade: 1.7, hi: 0.9, w: 2.2);
          // centre vein
          final tip = p + Offset(math.cos(ang), math.sin(ang)) * 12.5 * size;
          pen.line(Path()..moveTo(p.dx, p.dy)..lineTo(tip.dx, tip.dy), w: 0.9, color: withA(tones.shade, .9));
        }
      }
    }
    // leaf at the tip
    final tip = pt(t1);
    final lf = _leaf(tip, tangent(t1), 15, 6.4);
    pen.solid(lf, v.leaf, shade: 1.5, hi: 0.8, w: 2.2);
  }
}

void oryxBody(Pen pen, OryxMetal v) {
  final silhouette = d2Sym('M100 112 L134 112 C140 132 146 146 160 156 C172 164 179 186 183 230 L100 230 Z');
  pen.solid(silhouette, _chest, shade: 6, hi: 2);
  // white chest fur V
  final bib = d2Sym('M100 146 C112 148 122 154 128 168 C132 182 130 206 126 232 L100 232 Z');
  pen.inside(silhouette, (q) {
    q.fill(bib, _fur.base);
    q.crescent(bib, _fur.shade, depth: 4);
    q.rim(bib, _fur.hi, depth: 1.5);
    q.line(bib, w: Style.lineThin, color: withA(_chest.shade, .9));
  });
  d2Strands(pen, silhouette, ['M150 170 C158 180 162 196 164 216', 'M50 170 C42 180 38 196 36 216', 'M138 152 C144 158 148 164 154 168'], withA(_chest.hi, .8), w0: 2.8, w1: .2);
  d2Strands(pen, bib, ['M108 170 C112 184 112 200 110 218', 'M118 164 C122 176 122 192 120 210'], withA(_fur.shade, .9), w0: 2.4, w1: .2);
  pen.line(silhouette, w: Style.line);
  _laurel(pen, v);
}

Path _horn(int side) {
  Path m(Path p) => side > 0 ? p : d2Mir(p);
  return m(svg('M110 76 C108 52 114 30 134 6 C136 6 137 8 136 10 C126 32 124 54 126 76 C120 80 114 80 110 76 Z'));
}

Path _hornCenter(int side) {
  Path m(Path p) => side > 0 ? p : d2Mir(p);
  return m(svg('M118 76 C116 54 122 32 135 8'));
}

void oryxHead(Pen pen, OryxMetal v) {
  for (final s in [-1, 1]) {
    final h = _horn(s);
    pen.fill(h, v.horn.base);
    pen.crescent(h, v.horn.shade, depth: 3.2);
    pen.rim(h, v.horn.hi, depth: 1.5);
    d2HornRings(pen, h, _hornCenter(s), n: 9, t0: .05, t1: .9, w: 1.8, color: withA(v.ring, .9), bow: 4.5);
    pen.line(h, w: Style.line);
  }

  pen.fill(_headShape, _face.base);
  pen.crescent(_headShape, _face.shade, depth: 5);
  pen.rim(_headShape, _face.hi, depth: 2);

  // dark marks: central stripe widening into the muzzle, and the two cheek bands round the eyes
  final centre = d2Sym('M100 64 C105 64 108 74 107 86 C106 96 105 102 108 112 C112 120 116 128 116 136 C116 145 110 152 100 153 Z');
  pen.inside(_headShape, (q) {
    q.fill(centre, _mark.base);
    q.crescent(centre, _mark.shade, depth: 3);
    q.rim(centre, _mark.hi, depth: 1.2);
    for (final s in [1, -1]) {
      Path m(Path p) => s > 0 ? p : d2Mir(p);
      final band = m(svg('M122 66 C132 74 135 92 133 108 C131 120 128 128 124 134 C122 130 122 124 123 116 C125 104 125 92 120 80 C119 74 120 70 122 66 Z'));
      q.fill(band, _mark.base);
      q.crescent(band, _mark.shade, depth: 2.4);
      q.rim(band, _mark.hi, depth: 1);
    }
  });
  pen.line(_headShape, w: Style.line);

  drawEyes(pen, _eh, _eyes, d2Skin(_face));
  drawBrows(pen, _eh, _brows, _eyes);

  // nose: wet nostrils on the dark muzzle, then a happy closed smile on the white chin
  for (final s in [1, -1]) {
    Path m(Path p) => s > 0 ? p : d2Mir(p);
    pen.fill(m(svg('M104 140 C108 137 113 139 112 144 C111 148 106 148 104 145 Z')), const Color(0xFF140C08));
  }
  pen.glow(const Offset(97, 133), 5, 2.6, const Color(0xFFFFFFFF), alpha: .35);
  pen.line(svg('M91 152 C95 160 105 160 109 152'), w: 2.3);
}

void oryxEar(Pen pen, int side) {
  Path m(Path p) => side > 0 ? p : d2Mir(p);
  final outer = m(svg('M120 86 C132 70 154 62 176 64 C174 80 160 96 142 100 C132 102 124 96 120 86 Z'));
  pen.solid(outer, _face, shade: 4, hi: 1.6);
  final inner = m(svg('M128 86 C138 76 154 70 168 70 C165 80 154 92 142 94 C134 95 130 91 128 86 Z'));
  pen.solid(inner, _earIn, shade: 3, hi: 0, w: Style.lineThin);
  d2Strands(pen, outer, ['M122 90 C130 80 140 74 152 70'], withA(_mark.base, .55), w0: 2, w1: .2);
}

void oryxBlink(Pen pen) {
  drawEyelids(pen, _eh, _eyes, d2Skin(_face));
}

/// Open laughing mouth (shown over the closed smile while the champion laughs).
void oryxMouth(Pen pen) {
  final mouth = svg('M87 150 C90 172 110 172 113 150 C106 154 94 154 87 150 Z');
  pen.fill(mouth, const Color(0xFF5C1A18));
  pen.inside(mouth, (q) {
    q.fill(ellipse(100, 168, 10, 6.5), const Color(0xFFE8767A));
    // upper teeth
    q.fill(svg('M90 150 C96 155 104 155 110 150 L110 155 C104 159 96 159 90 155 Z'), const Color(0xFFFFFFFF));
  });
  pen.line(mouth, w: Style.lineThin * 1.3);
  pen.line(svg('M92 156 C96 159 104 159 108 156'), w: .9, color: withA(Style.ink, .35));
}

/// Ribbon + numbered medal, swinging from the neck in the rig.
void oryxMedal(Pen pen, OryxMetal v) {
  // ribbon (two bands meeting at the medal)
  for (final s in [1, -1]) {
    Path m(Path p) => s > 0 ? p : d2Mir(p);
    final band = m(svg('M121 122 L139 131 L113 178 L100 176 Z'));
    pen.solid(band, _ribbon, shade: 2.8, hi: 1.2);
    pen.line(m(svg('M127 128 L108 171')), w: 1.0, color: withA(const Color(0xFFFFFFFF), .55));
  }
  // medal disc
  final disc = circle(100, 182, 15.5);
  pen.solid(disc, v.medal, shade: 3, hi: 1.4, w: 2.6);
  final face = circle(100, 182, 11.2);
  pen.fill(face, v.medalFace.base);
  pen.crescent(face, v.medalFace.shade, depth: 2.2);
  pen.line(face, w: 1.3, color: withA(v.medal.shade, .95));
  // number
  final d = xform(d2Digit(v.n), sx: 13, tx: 100, ty: 182.4);
  pen.line(d, w: 2.6, color: const Color(0xFFFFFFFF));
  pen.fill(d, v.digit);
  pen.glow(const Offset(94, 175), 3.4, 2.2, const Color(0xFFFFFFFF), alpha: .7);
}
