// s1b: the moon gazelle — lyre horns with a gold crescent between them, striped face, big soulful eyes,
// beaded collar with a crescent pendant. Rig layers: body, ear_l, ear_r, head, blink.
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';
import 'brows.dart';
import 'd2_animal.dart';
import 'eyes.dart';

const _fur = Tones(Color(0xFFDFA564), Color(0xFFB87A42), Color(0xFFF4C78C));
const _cream = Tones(Color(0xFFFFF5E4), Color(0xFFE2CEB2), Color(0xFFFFFCF4));
const _brown = Color(0xFF5E3A1C);
const _horn = Tones(Color(0xFF4B3424), Color(0xFF2B1B12), Color(0xFF86624A));
const _earIn = Tones(Color(0xFFF6C6B8), Color(0xFFDB9C92), Color(0xFFFFE2D8));
const _gold = Tones(Color(0xFFF7C93E), Color(0xFFC98A12), Color(0xFFFFE996));
const _bead = Tones(Color(0xFF5648E8), Color(0xFF3329A8), Color(0xFF8F86FF));

const _eyes = EyeSpec(
  ew: 12.2,
  eh: 13.4,
  gap: 23,
  y: 0,
  lookX: 0.35,
  lookY: -0.55,
  iris: Color(0xFF3D2414),
  irisR: 0.78,
  pupilR: 0.62,
  lidTop: 0.02,
  lidSlant: -0.18,
  lashes: true,
  lid: 3.6,
);

const _brows = BrowSpec(
  lift: 5.5,
  inner: -3,
  outer: 1.4,
  arch: 2.6,
  thick: 5.6,
  taper: 0.5,
  color: HairColor(Color(0xFF7A4A26), Color(0xFF5E3A1C), Color(0xFFA9754A)),
);

final Head _eh = d2EyeHead(100, 96);

final Path _headShape = d2Sym(
  'M100 61 C121 61 136 71 138 92 C139 106 135 118 129 127 C125 135 123 146 116 153 C112 157 105 159 100 159 Z',
);

void gazelleBody(Pen pen) {
  // neck + shoulders
  final silhouette = d2Sym('M100 112 L126 112 C130 134 134 146 154 154 C168 160 176 184 180 228 L100 228 Z');
  pen.solid(silhouette, _fur, shade: 5, hi: 2);
  // cream chest bib
  final bib = d2Sym('M100 140 C112 142 122 148 127 162 L124 228 L100 228 Z');
  pen.inside(silhouette, (q) {
    q.fill(bib, _cream.base);
    q.crescent(bib, _cream.shade, depth: 4);
    q.rim(bib, _cream.hi, depth: 1.5);
    q.line(bib, w: Style.lineThin, color: withA(_fur.shade, .9));
  });
  d2Strands(pen, silhouette, ['M150 166 C158 176 162 190 164 212', 'M50 166 C42 176 38 190 36 212', 'M142 150 C146 156 150 160 156 162'], withA(_fur.shade, .85), w0: 2.6, w1: .2);
  pen.line(silhouette, w: Style.line);
  // beaded collar
  final collar = svg('M64 142 C70 164 84 174 100 174 C116 174 130 164 136 142');
  pen.line(collar, w: 9.5, color: Style.ink);
  pen.line(collar, w: 6.4, color: _bead.shade);
  const n = 13;
  final m = collar.computeMetrics().first;
  for (var i = 0; i < n; i++) {
    final t = m.getTangentForOffset(m.length * (i + 0.5) / n)!.position;
    pen.solid(circle(t.dx, t.dy, 3.7), i.isEven ? _bead : _gold, shade: 1.6, hi: .9, w: 1.4);
  }
  // crescent pendant
  pen.line(svg('M96 173 C97 176 98 177 99 177 C100 177 101 176 102 173'), w: 1.6, color: Style.ink);
  final c = d2Crescent(const Offset(99, 184), 12.5, open: 1, thick: 0.46);
  pen.solid(c, _gold, shade: 2.4, hi: 1.3);
}

void gazelleEar(Pen pen, int side) {
  Path m(Path p) => side > 0 ? p : d2Mir(p);
  final outer = m(svg('M114 90 C124 76 146 64 172 60 C171 76 160 92 142 100 C132 103 120 99 114 90 Z'));
  pen.solid(outer, _fur, shade: 4, hi: 1.6);
  final inner = m(svg('M123 90 C132 80 148 72 164 68 C161 80 152 92 140 95 C132 96 126 94 123 90 Z'));
  pen.solid(inner, _earIn, shade: 3, hi: 0, w: Style.lineThin);
  d2Strands(pen, inner, ['M128 92 C140 86 150 80 160 74'], withA(_cream.hi, .9), w0: 2.2, w1: .2);
}

Path _hornShape(int side) {
  Path m(Path p) => side > 0 ? p : d2Mir(p);
  return m(svg('M110 70 C124 66 140 62 145 44 C148 30 142 18 133 9 C134 18 135 26 133 34 C131 48 122 58 114 62 Z'));
}

Path _hornCenter(int side) {
  Path m(Path p) => side > 0 ? p : d2Mir(p);
  return m(svg('M116 68 C128 62 142 54 140 40 C139 28 136 18 133 11'));
}

void gazelleHorn(Pen pen, int side) {
  final h = _hornShape(side);
  pen.fill(h, _horn.base);
  pen.crescent(h, _horn.shade, depth: 3);
  pen.rim(h, _horn.hi, depth: 1.5);
  d2HornRings(pen, h, _hornCenter(side), n: 9, t0: .06, t1: .9, w: 1.5, color: withA(const Color(0xFFC49B72), .9), bow: 4);
  pen.line(h, w: Style.line);
}

void gazelleHead(Pen pen) {
  gazelleHorn(pen, -1);
  gazelleHorn(pen, 1);
  // the gold crescent floating between the horns
  final moon = d2Crescent(const Offset(100, 40), 19, open: 1, thick: 0.44);
  pen.solid(moon, _gold, shade: 3, hi: 1.6);
  pen.glow(const Offset(91, 33), 3.6, 3.6, const Color(0xFFFFFFFF), alpha: .55);

  pen.fill(_headShape, _fur.base);
  pen.crescent(_headShape, _fur.shade, depth: 5);
  pen.rim(_headShape, _fur.hi, depth: 2);

  // cream muzzle + the two white face stripes
  final muzzle = d2Sym('M100 120 C108 118 120 122 125 131 C129 140 127 153 119 160 C113 165 106 166 100 166 Z');
  final stripe = d2Sym('M100 63 C106 63 110 74 110 90 C110 104 113 114 119 124 L100 128 Z');
  pen.inside(_headShape, (q) {
    for (final p in [stripe, muzzle]) {
      q.fill(p, _cream.base);
      q.crescent(p, _cream.shade, depth: 3);
      q.rim(p, _cream.hi, depth: 1.3);
    }
    // dark line along the outer edge of each stripe
    for (final s in [1, -1]) {
      Path m(Path p) => s > 0 ? p : d2Mir(p);
      q.taper(m(svg('M113 106 C114 116 118 124 124 130')), w0: 3.6, w1: .8, color: _brown);
      q.taper(m(svg('M104 140 C110 136 118 134 126 136')), w0: 2.0, w1: 0.3, color: withA(_fur.shade, .8));
    }
  });
  pen.line(_headShape, w: Style.line);

  // blush
  for (final s in [1, -1]) {
    pen.glow(Offset(100 + s * 27, 119), 8, 5.5, const Color(0xFFF0707A), alpha: .38);
  }
  drawEyes(pen, _eh, _eyes, d2Skin(_fur));
  drawBrows(pen, _eh, _brows, _eyes);

  // big wet nose + small smile
  final nose = d2Sym('M100 132 C108 131 115 135 114 140 C113 146 107 148 100 148 Z');
  pen.solid(nose, const Tones(Color(0xFF3A2A2C), Color(0xFF211618), Color(0xFF6A5256)), shade: 2.5, hi: 0, w: Style.lineThin * 1.2);
  pen.glow(const Offset(94, 136), 4, 2.4, const Color(0xFFFFFFFF), alpha: .8);
  for (final s in [1, -1]) {
    pen.fill(ellipse(100 + s * 5.4, 141.5, 1.6, 2.2, rot: s * 0.5), const Color(0xFF0E0809));
  }
  pen.line(svg('M100 148 L100 152'), w: 1.8);
  pen.line(svg('M90 152 C94 159 106 159 110 152'), w: 2.3);
}

void gazelleBlink(Pen pen) {
  drawEyelids(pen, _eh, _eyes, d2Skin(_fur));
}
