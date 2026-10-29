// s1c: the noble Arabian horse — long white blaze, teal ornamental bridle with a gold crescent jewel,
// wind-swept mane. Rig layers: body, mane, head, blink.
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';
import 'brows.dart';
import 'd2_animal.dart';
import 'eyes.dart';

const _coat = Tones(Color(0xFF714634), Color(0xFF482A20), Color(0xFF96664C));
const _blaze = Tones(Color(0xFFFFF7EC), Color(0xFFD8C8C6), Color(0xFFFFFFFF));
const _muzzle = Tones(Color(0xFFA27A64), Color(0xFF72503F), Color(0xFFC09A82));
const _hair = Tones(Color(0xFF2E2C45), Color(0xFF181726), Color(0xFF6A6890));
const _teal = Tones(Color(0xFF15897F), Color(0xFF0B5956), Color(0xFF3CB3A5));
const _gold = Tones(Color(0xFFF7C93E), Color(0xFFC98A12), Color(0xFFFFE996));
const _earIn = Tones(Color(0xFFC98A78), Color(0xFF9C5E52), Color(0xFFE8B09C));

const _eyes = EyeSpec(
  ew: 11.6,
  eh: 12.8,
  gap: 25,
  lookX: 0.75,
  lookY: -0.25,
  iris: Color(0xFF2E1A0E),
  irisR: 0.72,
  pupilR: 0.56,
  lidTop: 0.0,
  lidSlant: -0.04,
  lid: 3.6,
);

const _brows = BrowSpec(
  lift: 6,
  inner: -1,
  outer: 2,
  arch: 3.2,
  thick: 6,
  taper: 0.5,
  color: HairColor(Color(0xFF301D15), Color(0xFF1B0F0A), Color(0xFF5C3C2C)),
);

final Head _eh = d2EyeHead(100, 100);

final Path _headShape = d2Sym(
  'M100 52 C121 52 135 64 136 86 C137 100 130 110 121 118 C117 124 116 132 117 140 C121 146 122 158 117 165 C112 170 106 172 100 172 Z',
);

void horseBody(Pen pen) {
  final silhouette = d2Sym('M100 96 L130 96 C132 124 138 140 156 150 C171 158 180 184 182 228 L100 228 Z');
  pen.solid(silhouette, _coat, shade: 6, hi: 2);
  d2Strands(pen, silhouette, ['M60 150 C54 164 52 182 52 204', 'M150 156 C158 168 162 186 164 208', 'M70 112 C66 124 66 136 70 146'], withA(_coat.shade, .9), w0: 3, w1: .3);
  // teal caparison with a gold crescent medallion
  final cap = d2Sym('M100 172 C124 172 148 176 160 188 C168 196 172 210 174 232 L100 232 Z');
  pen.solid(cap, _teal, shade: 5, hi: 2);
  d2Strands(pen, cap, ['M70 190 C66 204 64 216 62 228', 'M130 190 C134 204 136 216 138 228'], withA(_teal.hi, .55), w0: 3, w1: .3);
  final edge = svg('M40 202 C46 190 64 178 100 176 C136 178 154 190 160 202');
  pen.line(edge, w: 6.6, color: Style.ink);
  pen.line(edge, w: 4, color: _gold.base);
  pen.line(edge.shift(const Offset(-.5, -.7)), w: 1.1, color: _gold.hi);
  final m = edge.computeMetrics().first;
  for (var i = 0; i < 9; i++) {
    final t = m.getTangentForOffset(m.length * (i + .5) / 9)!.position;
    pen.shape(circle(t.dx, t.dy, 2.1), _gold.hi, w: 1.2);
  }
  pen.shape(circle(100, 192, 9.5), _gold.base, w: 2.2);
  pen.fill(d2Crescent(const Offset(100, 192), 6.4, open: 1, thick: .45), _teal.shade);
}

Path _maneShape() => svg(
  'M110 40 C134 42 152 60 156 88 C160 114 160 136 176 158 C178 164 170 168 162 164 C164 170 156 176 148 170 C142 164 138 156 138 146 C134 126 132 104 128 86 C124 66 118 54 110 40 Z',
);

void horseMane(Pen pen) {
  final p = _maneShape();
  pen.fill(p, _hair.base);
  pen.crescent(p, _hair.shade, depth: 4.5);
  pen.rim(p, _hair.hi, depth: 1.8);
  d2Strands(pen, p, [
    'M120 52 C138 66 146 90 148 116',
    'M128 54 C146 72 152 98 156 124',
    'M132 108 C136 124 140 140 150 156',
    'M150 120 C152 134 158 148 168 160',
  ], withA(_hair.hi, .85), w0: 2.4, w1: .2);
  pen.line(p, w: Style.line);
}

void _ear(Pen pen, int side, {double rot = 0}) {
  Path m(Path p) => side > 0 ? p : d2Mir(p);
  final base = side > 0 ? const Offset(120, 60) : const Offset(80, 60);
  var outer = m(svg('M108 62 C110 44 118 28 128 16 C135 30 139 48 136 66 Z'));
  var inner = m(svg('M115 60 C117 46 122 34 128 26 C132 38 133 50 131 62 Z'));
  if (rot != 0) {
    outer = rotatedAbout(outer, base, rot);
    inner = rotatedAbout(inner, base, rot);
  }
  pen.solid(outer, _coat, shade: 3.5, hi: 1.4);
  pen.solid(inner, _earIn, shade: 2.4, hi: 0, w: Style.lineThin);
}

void horseHead(Pen pen) {
  _ear(pen, -1, rot: -0.12);
  _ear(pen, 1, rot: 0.1);
  pen.fill(_headShape, _coat.base);
  pen.crescent(_headShape, _coat.shade, depth: 5.5);
  pen.rim(_headShape, _coat.hi, depth: 2);
  d2Strands(pen, _headShape, [
    'M70 78 C74 70 82 64 92 62',
    'M130 78 C126 70 118 64 108 62',
    'M64 112 C68 118 74 122 80 124',
    'M136 112 C132 118 126 122 120 124',
  ], withA(_coat.hi, .9), w0: 2.4, w1: .2);
  // white blaze + lighter muzzle
  final blaze = d2Sym('M100 62 C104 62 106 76 106 96 C106 110 109 122 112 134 C113 140 111 146 100 147 Z');
  final muz = d2Sym('M100 134 C110 134 119 140 122 150 C125 162 119 173 100 175 Z');
  pen.inside(_headShape, (q) {
    q.fill(muz, _muzzle.base);
    q.crescent(muz, _muzzle.shade, depth: 3.5);
    q.rim(muz, _muzzle.hi, depth: 1.4);
    q.fill(blaze, _blaze.base);
    q.crescent(blaze, _blaze.shade, depth: 2.6);
    q.rim(blaze, _blaze.hi, depth: 1.2);
    q.line(blaze, w: Style.lineFine, color: withA(_coat.shade, .9));
  });
  pen.line(_headShape, w: Style.line);

  // eyes + brows
  drawEyes(pen, _eh, _eyes, d2Skin(_coat));
  drawBrows(pen, _eh, _brows, _eyes);

  // flared nostrils + a proud little smile
  for (final s in [1, -1]) {
    Path m(Path p) => s > 0 ? p : d2Mir(p);
    final nos = m(svg('M107 150 C110 147 114 149 114 153 C113 157 109 158 107 155 C106 153 106 152 107 150 Z'));
    pen.fill(nos, const Color(0xFF2A1812));
    pen.glow(Offset(100 + s * 11, 150), 2.2, 1.3, const Color(0xFFFFFFFF), alpha: .35);
    pen.line(nos, w: 1.2, color: Style.ink);
  }
  pen.line(svg('M89 166 C95 171 105 171 111 166'), w: 2.3);
  pen.line(svg('M111 166 C113 165 114 163 113.5 161.5'), w: 1.8);

  // teal ornamental bridle: brow band, cheek straps, nose band
  final brow = svg('M64 76 C78 70 90 69 100 69 C110 69 122 70 136 76');
  final cheekL = svg('M64 76 C58 92 58 108 67 126');
  final cheekR = d2Mir(cheekL);
  final nose = svg('M71 130 C82 136 118 136 129 130');
  for (final p in [cheekL, cheekR, brow, nose]) {
    pen.line(p, w: 7.2, color: Style.ink);
  }
  for (final p in [cheekL, cheekR, brow, nose]) {
    pen.line(p, w: 4.4, color: _teal.base);
    pen.line(p.shift(const Offset(-.6, -.8)), w: 1.5, color: _teal.hi);
  }
  for (final p in [cheekL, cheekR, brow, nose]) {
    pen.line(p, w: 1.1, color: withA(_gold.base, .95));
  }
  // forelock swept to the left
  final fore = svg('M82 46 C70 54 72 74 82 86 C80 76 86 64 92 60 C96 70 96 80 94 94 C102 82 106 66 104 50 C98 42 90 42 82 46 Z');
  pen.fill(fore, _hair.base);
  pen.crescent(fore, _hair.shade, depth: 3.4);
  pen.rim(fore, _hair.hi, depth: 1.4);
  d2Strands(pen, fore, ['M86 54 C80 64 82 76 86 84', 'M98 54 C100 66 98 78 96 88'], withA(_hair.hi, .85), w0: 2, w1: .2);
  pen.line(fore, w: Style.line);
  // crescent jewel on the brow band
  final jewel = circle(100, 78, 10);
  pen.solid(jewel, _gold, shade: 2.6, hi: 1.1, w: 2.4);
  pen.shape(circle(100, 78, 6.8), _teal.base, w: 1.4);
  pen.fill(d2Crescent(const Offset(100, 78), 5, open: 1, thick: .44), _gold.hi);
  // gold rings at the nose band ends
  for (final s in [1, -1]) {
    pen.solid(circle(100 + s * 28.5, 131, 4.2), _gold, shade: 1.4, hi: .7, w: 1.8);
  }
}

void horseBlink(Pen pen) {
  drawEyelids(pen, _eh, _eyes, d2Skin(_coat));
}
