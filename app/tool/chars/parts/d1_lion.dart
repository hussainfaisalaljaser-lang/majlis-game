// lv40: the ruby lion: flaming red mane, gold circlet with a ruby gem, ruby armour + cape.
// Rig layers (anim_rigs.dart `_lion`): body, mane (behind head, sways/puffs), head, blink, mouth (roar overlay).
// The rig glows the gem at `lionGem` (head frame).
import 'dart:math' as math;

import '../kit.dart';
import 'd1_animal.dart';

const lionGem = Offset(100, 63);

const _maneOut = Tones(Color(0xFF8F1431), Color(0xFF5C0A22), Color(0xFFB92649));
const _maneIn = Tones(Color(0xFFDB2E4A), Color(0xFFA81B36), Color(0xFFFF6A80));
const _fur = Tones(Color(0xFFF0BA6E), Color(0xFFD4924A), Color(0xFFFFDB9C));
const _cream = Tones(Color(0xFFFFF1D2), Color(0xFFE9CA98), Color(0xFFFFFFFF));
const _armor = Tones(Color(0xFFB81B3E), Color(0xFF7E0F2A), Color(0xFFE04565));
const _cape = Tones(Color(0xFF8A1230), Color(0xFF5A0A20), Color(0xFFB3284A));
const _eyeY = 96.0;
const _eyeDx = 22.0;

final Path _head = d1Sym(
  svg(
    'M100 50 C80 50 64 58 58 76 C54 92 55 110 62 124 '
    'Q55 128 53 138 Q62 137 67 138 Q78 148 100 150 L100 50 Z',
  ),
);

void _lionBody(Pen pen, Head h) {
  final cape = svg('M2 228 C6 188 34 158 72 148 L128 148 C166 158 194 188 198 228 Z');
  pen.solid(cape, _cape, shade: 6, hi: 2);
  // pauldrons
  for (final side in const [-1, 1]) {
    Path m(Path p) => side < 0 ? p : mirrorX(p);
    final pa = m(svg('M18 214 C16 188 32 168 58 164 C74 162 80 170 80 180 C70 196 46 208 18 214 Z'));
    pen.solid(pa, _armor, shade: 5, hi: 2);
    pen.inside(pa, (p) {
      p.line(m(svg('M24 206 C36 196 52 186 70 174')), w: 3.6, color: d1Gold.base);
      p.line(m(svg('M24 206 C36 196 52 186 70 174')), w: 1.1, color: d1Gold.hi);
    });
    pen.line(pa, w: Style.line);
    // gold rivets
    for (final (x, y) in const [(40.0, 176.0), (56.0, 172.0)]) {
      pen.solid(circle(side < 0 ? x : 200 - x, y, 2.6), d1Gold, shade: 1, hi: .6, w: Style.lineFine + .3);
    }
  }
  // chest plate with gold edge + diamond gem
  final plate = svg('M70 156 C72 190 84 218 100 232 C116 218 128 190 130 156 C116 168 84 168 70 156 Z');
  pen.solid(plate, _armor, shade: 5, hi: 0, w: Style.line);
  pen.inside(plate, (p) {
    p.line(plate, w: 5, color: d1Gold.base);
    p.line(svg('M86 172 L100 204 L114 172'), w: 1.8, color: withA(d1Gold.hi, .9));
  });
  pen.line(plate, w: Style.lineThin, color: Style.ink);
  d1Gem(pen, const Offset(100, 188), 7.2, const Color(0xFFFF3B63), diamond: true);
  // gold collar
  final collar = svg('M66 152 Q100 172 134 152 L134 160 Q100 180 66 160 Z');
  pen.solid(collar, d1Gold, shade: 2, hi: 1, w: Style.lineThin + .5);
}

void _locks(Pen pen, {required int n, required double r0, required double len, required double w, required double phase, required Tones out, required Color mid, required Color core, double cx = 100, double cy = 99}) {
  for (var i = 0; i < n; i++) {
    final a = phase + i * 2 * math.pi / n;
    final base = Offset(cx + r0 * math.sin(a), cy - r0 * math.cos(a));
    d1Flame(pen, base, len * (1 + .06 * math.sin(i * 2.1)) * (.92 + .3 * math.sin(a).abs()), w, a, curl: 1, outer: out, mid: mid, core: core, outline: Style.line);
  }
}

void _lionMane(Pen pen, Head h) {
  _locks(pen, n: 13, r0: 34, len: 44, w: 19, phase: .1, out: _maneOut, mid: const Color(0xFFB01C3C), core: const Color(0xFFD73657));
  _locks(pen, n: 13, r0: 32, len: 34, w: 17, phase: .1 + math.pi / 13, out: _maneIn, mid: const Color(0xFFF2506A), core: const Color(0xFFFF8FA0), cy: 100);
}

void _lionHead(Pen pen, Head h) {
  // mane beard under the chin (behind the face)
  for (final (bx, by, a) in const [(80.0, 140.0, -2.75), (120.0, 140.0, 2.75), (100.0, 146.0, 3.14)]) {
    d1Flame(pen, Offset(bx, by), 24, 12, a, curl: a < 0 ? -1 : 1, outer: _maneOut, mid: const Color(0xFFB01C3C), core: const Color(0xFFD73657), outline: Style.line);
  }
  // round ears peeking out of the mane
  for (final side in const [-1, 1]) {
    final cx = 100 + side * 41.0;
    final outer = circle(cx, 60, 11);
    pen.solid(outer, _fur, shade: 3, hi: 1, w: Style.line);
    final inner = circle(cx, 61, 5.8);
    pen.shape(inner, const Color(0xFFB36A4A), w: 0);
    pen.crescent(inner, const Color(0xFF8A4632), depth: 2);
  }
  pen.fill(_head, _fur.base);
  pen.inside(_head, (p) {
    p.crescent(_head, withA(const Color(0xFF7A2E5A), .18), depth: 5);
    p.rim(_head, withA(const Color(0xFFFFFFFF), .35), depth: 1.8);
    // cream muzzle + cheeks
    final muzzle = d1Sym(svg('M100 102 C88 98 73 102 69 114 C65 128 76 144 100 150 Z'));
    p.fill(muzzle, _cream.base);
    p.crescent(muzzle, _cream.shade, depth: 3.5);
    for (final (a, b, bend) in [(const Offset(58, 118), const Offset(70, 124), 1.5), (const Offset(142, 118), const Offset(130, 124), -1.5)]) {
      d1Strand(p, a, b, bend: bend, w0: 2.4, w1: .2, color: _fur.shade);
    }
  });
  // eyes: amber, narrowed, glancing right
  for (final side in const [-1, 1]) {
    d1Eye(
      pen,
      Offset(100 + side * _eyeDx, _eyeY),
      rx: 12.2,
      ry: 11.4,
      rot: -side * .07,
      side: side,
      lookX: -.62,
      lookY: .02,
      iris: const Color(0xFFE88A14),
      irisR: .72,
      pupilR: .55,
      lidTop: .12,
      lidSlant: side > 0 ? .42 : .55,
      lid: 3.6,
      line: 2.1,
    );
  }
  d1Brow(pen, const Offset(91, 84), const Offset(60, 78), arch: 1.5, thick: 8.2, color: const Color(0xFF6B2F1E));
  d1Brow(pen, const Offset(109, 82), const Offset(141, 72), arch: 3.5, thick: 8.2, color: const Color(0xFF6B2F1E));
  // nose + mouth
  d1Nose(pen, const Offset(100, 109), w: 21, h: 13.5, color: const Color(0xFF7A382B));
  pen.line(svg('M100 117 L100 126'), w: 2.3, color: d1Dark);
  pen.line(svg('M100 126 C95 135 86 135 80 128'), w: 2.5, color: d1Dark);
  pen.line(svg('M100 126 C106 134 115 134 121 124'), w: 2.5, color: d1Dark);
  for (final (x, y) in const [(82.0, 116.0), (88.0, 120.0), (118.0, 120.0), (124.0, 116.0)]) {
    pen.fill(circle(x, y, 1.3), withA(const Color(0xFF8A4632), .8));
  }
  // gold circlet with the ruby gem
  final band = svg('M60 70 Q100 50 140 70 L141 79 Q100 59 59 79 Z');
  pen.solid(band, d1Gold, shade: 2.4, hi: 1, w: Style.lineThin + .6);
  final bezel = poly([Offset(lionGem.dx, lionGem.dy - 12.5), Offset(lionGem.dx + 10.5, lionGem.dy + 1), Offset(lionGem.dx, lionGem.dy + 12.5), Offset(lionGem.dx - 10.5, lionGem.dy + 1)]);
  pen.solid(bezel, d1Gold, shade: 2.4, hi: 1, w: Style.lineThin + .6);
  d1Gem(pen, Offset(lionGem.dx, lionGem.dy + .5), 5.6, const Color(0xFFFF2F57), diamond: true);
  pen.line(_head, w: Style.line);
}

void _lionBlink(Pen pen, Head h) {
  for (final side in const [-1, 1]) {
    d1EyeClosed(pen, Offset(100 + side * _eyeDx, _eyeY), rx: 12.2, ry: 10.6, rot: -side * .07, fur: _fur.base, w: 3.4, bend: .55, pad: 2.6);
  }
}

void _lionRoar(Pen pen, Head h) {
  // dropped jaw + roaring mouth over the muzzle (the nose is repainted on top)
  final jaw = svg('M76 124 C74 146 84 162 100 166 C116 162 126 146 124 124 Z');
  pen.fill(jaw, _cream.base);
  pen.crescent(jaw, _cream.shade, depth: 4);
  pen.line(jaw, w: Style.lineThin + .5);
  final mouth = svg('M76 122 C80 114 92 116 100 120 C108 116 120 114 124 122 C128 142 114 156 100 158 C86 156 72 142 76 122 Z');
  pen.fill(mouth, const Color(0xFF4B1426));
  final tongue = ellipse(100, 155, 16, 11);
  pen.inside(mouth, (p) {
    p.fill(tongue, const Color(0xFFE5667B));
    p.crescent(tongue, const Color(0xFFB8445D), depth: 3);
    p.crescent(mouth, withA(const Color(0xFF000000), .25), depth: 4, dir: const Offset(0, 1));
  });
  pen.line(mouth, w: Style.lineThin + .5);
  pen.shape(svg('M80 121 L84.5 134 L91 120 Z'), d1Cream, w: Style.lineThin);
  pen.shape(svg('M120 121 L115.5 134 L109 120 Z'), d1Cream, w: Style.lineThin);
  pen.shape(svg('M85 154 L88.5 143 L93 155 Z'), d1Cream, w: Style.lineFine + .2);
  pen.shape(svg('M115 154 L111.5 143 L107 155 Z'), d1Cream, w: Style.lineFine + .2);
  // muzzle top + nose back on top
  final top = svg('M69 112 C72 102 86 99 100 100 C114 99 128 102 131 112 L127 120 C118 114 108 119 100 123 C92 119 82 114 73 120 Z');
  pen.fill(top, _cream.base);
  pen.crescent(top, _cream.shade, depth: 2.4);
  d1Nose(pen, const Offset(100, 109), w: 21, h: 13.5, color: const Color(0xFF7A382B));
}

final Map<String, PropPainter> lionLayers = {
  'body': _lionBody,
  'mane': _lionMane,
  'head': _lionHead,
  'blink': _lionBlink,
  'mouth': _lionRoar,
};

CharSpec lionSpec() => d1Spec('lv40', lionLayers, const ['body', 'mane', 'head']);
