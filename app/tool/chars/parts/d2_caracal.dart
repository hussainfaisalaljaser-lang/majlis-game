// s1a: the night caracal (desert lynx) — tufted ears, amber eyes, teal cloak, gold crescent pendant.
// Rig layers (all on the 240-unit canvas): body, ear_l, ear_r, head, blink.
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';
import 'brows.dart';
import 'd2_animal.dart';
import 'eyes.dart';

const _fur = Tones(Color(0xFFDD9852), Color(0xFFB4713C), Color(0xFFF2BC7E));
const _cream = Tones(Color(0xFFFBEBD5), Color(0xFFDDC3A4), Color(0xFFFFF8EE));
const _dark = Color(0xFF34200F);
const _tuft = Tones(Color(0xFF2E1B10), Color(0xFF1B100A), Color(0xFF5A3B28));
const _earIn = Tones(Color(0xFFF2B98F), Color(0xFFD08A6A), Color(0xFFFFD6B8));
const _cloak = Tones(Color(0xFF1F7772), Color(0xFF124B4C), Color(0xFF3D9E95));
const _collar = Tones(Color(0xFF2B9288), Color(0xFF17625E), Color(0xFF58BBAD));
const _gold = Tones(Color(0xFFF5C43C), Color(0xFFC98A12), Color(0xFFFFE690));

const _eyes = EyeSpec(
  ew: 14.6,
  eh: 14,
  gap: 24.5,
  lookX: 0.85,
  lookY: -0.3,
  iris: Color(0xFFD7A02A),
  irisR: 0.66,
  pupilR: 0.52,
  lidTop: 0.06,
  lidSlant: 0.2,
  lidBottom: 0.08,
  lid: 3.4,
);

const _brows = BrowSpec(
  lift: 4,
  inner: 2.5,
  outer: -2.2,
  arch: 1.4,
  thick: 6.4,
  taper: 0.55,
  color: HairColor(_dark, Color(0xFF1B100A), Color(0xFF5A3B28)),
  left: BrowSpec(lift: 3.4, inner: 3.0, outer: -1.2, arch: 1.0, thick: 6.4, taper: 0.55, color: HairColor(_dark, Color(0xFF1B100A), Color(0xFF5A3B28))),
  right: BrowSpec(lift: 7.5, inner: -0.5, outer: 0.5, arch: 3.2, thick: 6.4, taper: 0.55, color: HairColor(_dark, Color(0xFF1B100A), Color(0xFF5A3B28))),
);

final Head _eh = d2EyeHead(100, 96);

/// The skull silhouette (with cheek-ruff tufts).
final Path _headShape = d2Sym(
  'M100 54 C120 54 142 62 152 80 C158 92 159 102 158 110 L167 117 L158 122 L165 132 L153 135 L158 145 C146 153 124 159 100 159 Z',
);

void caracalBody(Pen pen) {
  final silhouette = d2Sym('M100 130 C120 130 142 140 156 154 C168 166 174 186 178 226 L100 226 Z');
  pen.solid(silhouette, _cloak, shade: 5, hi: 2);
  d2Strands(pen, silhouette, [
    'M64 168 C58 182 56 200 54 220',
    'M136 168 C142 182 144 200 146 220',
    'M46 186 C44 198 44 210 42 222',
    'M154 186 C156 198 156 210 158 222',
  ], withA(_cloak.hi, .6), w0: 3.2, w1: .3);
  // shoulder braid
  for (final s in [1, -1]) {
    Path m(Path p) => s > 0 ? p : d2Mir(p);
    final braid = m(svg('M158 168 C166 178 171 192 174 214'));
    pen.line(braid, w: 6.5, color: Style.ink);
    pen.line(braid, w: 3.6, color: _gold.base);
    pen.line(braid.shift(const Offset(-.7, 0)), w: 1.1, color: _gold.hi);
  }
  // stand collar with a gold edge and studs
  final collar = d2Sym('M100 142 C120 148 142 146 154 134 L162 154 C146 176 122 184 100 184 Z');
  pen.solid(collar, _collar, shade: 4, hi: 1.6);
  d2Strands(pen, collar, ['M60 160 C70 170 80 176 90 180', 'M140 160 C130 170 120 176 110 180'], withA(_collar.hi, .7), w0: 2.4, w1: .2);
  final edge = svg('M44 154 C58 176 80 184 100 184 C120 184 142 176 156 154');
  pen.line(edge, w: 6.8, color: Style.ink);
  pen.line(edge, w: 4.2, color: _gold.base);
  pen.line(edge.shift(const Offset(-.5, -.7)), w: 1.1, color: _gold.hi);
  for (final (x, y) in const [(54.0, 166.0), (66.0, 177.0), (82.0, 183.0), (118.0, 183.0), (134.0, 177.0), (146.0, 166.0)]) {
    pen.shape(circle(x, y, 2.2), _gold.hi, w: 1.2);
  }
  // crescent pendant on a ring
  final c = d2Crescent(const Offset(99, 184), 14, open: 1, thick: 0.46);
  pen.shape(circle(99, 186, 3.2), _gold.base, w: 1.6);
  pen.solid(c, _gold, shade: 2.6, hi: 1.4);
  pen.glow(const Offset(92, 179), 3.2, 3.2, const Color(0xFFFFFFFF), alpha: .5);
}

void caracalEar(Pen pen, int side) {
  Path m(Path p) => side > 0 ? p : d2Mir(p);
  final outer = m(svg('M110 80 C114 58 130 42 146 28 C152 46 161 68 158 92 C144 98 122 94 110 80 Z'));
  pen.solid(outer, _fur, shade: 4, hi: 1.6);
  final inner = m(svg('M123 82 C126 66 135 52 146 42 C150 56 153 70 151 84 C142 88 132 88 123 82 Z'));
  pen.solid(inner, _earIn, shade: 3, hi: 0, w: Style.lineThin);
  d2Strands(pen, inner, [
    'M128 84 C130 72 136 62 142 54',
    'M138 86 C140 74 144 66 147 58',
    'M146 86 C148 78 150 72 150 66',
  ], withA(_cream.hi, .95), w0: 2.2, w1: .2);
  // the black tuft (lynx mark)
  final tuft = m(svg('M138 40 C137 31 139 24 143 18 C144 22 146 24 147.5 25 C148 20 149 16 151 13 C153 21 155 31 154 41 C150 44 142 44 138 40 Z'));
  pen.solid(tuft, _tuft, shade: 2, hi: 1.2);
}

void caracalHead(Pen pen) {
  pen.fill(_headShape, _fur.base);
  pen.crescent(_headShape, _fur.shade, depth: 5);
  pen.rim(_headShape, _fur.hi, depth: 2);
  // fur strands
  d2Strands(pen, _headShape, [
    'M58 98 C64 104 70 106 76 106',
    'M142 98 C136 104 130 106 124 106',
    'M62 124 C70 124 76 122 80 118',
    'M138 124 C130 124 124 122 120 118',
    'M96 62 C94 70 92 76 88 82',
    'M104 62 C106 70 108 76 112 82',
  ], withA(_fur.shade, .8), w0: 2.4, w1: .2);
  d2Strands(pen, _headShape, ['M158 114 C150 116 144 120 138 128', 'M156 130 C148 132 142 136 136 142'], withA(_fur.shade, .9), w0: 2.6, w1: .2);

  // cream mask: eye patches, muzzle and chin
  final muzzle = d2Sym('M100 110 C106 106 119 106 126 114 C133 122 132 138 123 146 C116 153 108 160 100 162 Z');
  final patches = Path()
    ..addOval(Rect.fromCenter(center: const Offset(75.5, 97), width: 46, height: 42))
    ..addOval(Rect.fromCenter(center: const Offset(124.5, 97), width: 46, height: 42));
  pen.inside(_headShape, (q) {
    for (final p in [patches, muzzle]) {
      q.fill(p, _cream.base);
      q.crescent(p, _cream.shade, depth: 3);
      q.rim(p, _cream.hi, depth: 1.4);
      q.line(p, w: Style.lineFine, color: withA(_fur.shade, .9));
    }
  });
  // dark tear lines from the inner eye corners + forehead marks
  for (final s in [1, -1]) {
    Path m(Path p) => s > 0 ? p : d2Mir(p);
    pen.taper(m(svg('M109 104 C107 112 108 118 111 123')), w0: 3.4, w1: .6, color: _dark);
    pen.taper(m(svg('M96 60 C96 68 94 76 90 82')), w0: 3.6, w1: .5, color: _dark);
    pen.taper(m(svg('M110 62 C112 69 115 75 120 79')), w0: 3.0, w1: .4, color: _dark);
    // eye-liner flick
    pen.taper(m(svg('M137 90 C143 88 148 89 153 93')), w0: 3.2, w1: .4, color: _dark);
  }
  pen.line(_headShape, w: Style.line);

  drawEyes(pen, _eh, _eyes, d2Skin(_cream));
  drawBrows(pen, _eh, _brows, _eyes);

  // nose, mouth, whisker dots
  final nose = svg('M91 113 C91 109 109 109 109 113 C109 120 104 127 100 127 C96 127 91 120 91 113 Z');
  pen.solid(nose, const Tones(Color(0xFFC25C68), Color(0xFF9B3F52), Color(0xFFE58C93)), shade: 2.4, hi: 0.8, w: Style.lineThin * 1.2);
  pen.glow(const Offset(96, 113), 3.2, 2, const Color(0xFFFFFFFF), alpha: .75);
  pen.line(svg('M100 127 L100 132'), w: 2.0);
  final mouth = svg('M85 137 C89 140 95 138 100 132 C105 138 112 140 117 134');
  pen.line(mouth, w: 2.3);
  // smirk fang
  final fang = svg('M107 136 L110 136 L108.6 142 Z');
  pen.shape(fang, const Color(0xFFFFFFFF), w: 1.1);
  for (final s in [1, -1]) {
    for (final (dx, dy) in const [(14.0, 121.0), (19.0, 126.0), (11.0, 127.0)]) {
      pen.fill(circle(100 + s * dx, dy, 1.5), _dark);
    }
    // whiskers
    for (final (a, b) in const [(Offset(126, 126), Offset(168, 120)), (Offset(126, 132), Offset(170, 134))]) {
      final w = Path()
        ..moveTo(100 + s * (a.dx - 100), a.dy)
        ..quadraticBezierTo(100 + s * (a.dx + b.dx - 200) / 2, (a.dy + b.dy) / 2 - 4, 100 + s * (b.dx - 100), b.dy);
      pen.line(w, w: 1.2, color: withA(Style.ink, .75));
    }
  }
}

void caracalBlink(Pen pen) {
  drawEyelids(pen, _eh, _eyes, d2Skin(_cream));
}
