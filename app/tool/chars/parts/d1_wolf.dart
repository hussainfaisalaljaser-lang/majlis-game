// wolf: grey wolf bust, yellow eyes, fur-collar jacket. Rig layers (anim_rigs.dart `_wolf`):
// body, ear_l, ear_r (pivots (66,74) / (134,74)), head, blink (closed eyes, also shown while howling), howl (open mouth).
import '../kit.dart';
import 'd1_animal.dart';

const _fur = Tones(Color(0xFF8F9CB8), Color(0xFF6B7797), Color(0xFFB6C1DA));
const _furDark = Tones(Color(0xFF5B6684), Color(0xFF424C69), Color(0xFF7D88A8));
const _furLight = Tones(Color(0xFFE9EEF8), Color(0xFFBBC4DE), Color(0xFFFFFFFF));
const _ruffLight = Tones(Color(0xFFCDD5E8), Color(0xFFA2ACC9), Color(0xFFEEF2FA));
const _jacket = Tones(Color(0xFF34436B), Color(0xFF232F52), Color(0xFF52659A));
const _patch = Color(0xFF414B67);
const _eyeY = 90.0;
const _eyeDx = 26.0;

final Path _head = d1Sym(
  svg(
    'M100 42 C84 42 66 48 57 64 C51 74 49 85 50 93 '
    'Q40 96 33 108 Q45 107 51 111 Q42 117 36 130 Q48 127 57 127 Q52 135 49 146 Q62 142 71 138 '
    'Q82 150 100 157 L100 42 Z',
  ),
);

final Path _ruffBase = svg('M48 146 C46 166 68 180 100 180 C132 180 154 166 152 146 C146 134 124 130 100 130 C76 130 54 134 48 146 Z');
final Path _muzzle = svg('M71 118 C71 103 85 98 100 98 C115 98 129 103 129 118 C131 135 119 151 100 153 C81 151 69 135 71 118 Z');

final Path _earOuterL = svg('M56 98 C44 74 42 44 52 18 C68 28 90 50 98 84 Z');
final Path _earInnerL = svg('M60 90 C53 72 51 50 55 32 C68 42 82 60 90 82 Z');

void _wolfBody(Pen pen, Head h) {
  final shoulders = svg('M8 228 C10 188 34 160 74 150 L126 150 C166 160 190 188 192 228 Z');
  pen.solid(shoulders, _jacket, shade: 6, hi: 2);
  pen.inside(shoulders, (p) {
    p.taper(svg('M52 214 C54 192 62 176 76 164'), w0: 3, w1: .4, color: withA(Style.ink, .5));
    p.taper(svg('M148 214 C146 192 138 176 124 164'), w0: 3, w1: .4, color: withA(Style.ink, .5));
    p.taper(svg('M22 200 C26 186 36 174 50 166'), w0: 2.2, w1: .3, color: _jacket.hi);
    p.taper(svg('M178 200 C174 186 164 174 150 166'), w0: 1.8, w1: .3, color: _jacket.hi);
    // zip
    p.line(svg('M100 160 L100 228'), w: 2.2, color: withA(Style.ink, .7));
  });
  // fur ruff round the neck: dark under-layer, light fur on top
  final ruffBack = d1Fur(_ruffBase, amp: 8, step: 12, sweep: .45, seed: 3);
  pen.solid(ruffBack, _fur, shade: 4, hi: 0, w: Style.line);
  final ruffFrontBase = svg('M62 148 C62 164 80 174 100 174 C120 174 138 164 138 148 C134 140 120 138 100 138 C80 138 66 140 62 148 Z');
  final ruffFront = d1Fur(ruffFrontBase, amp: 6.5, step: 11.5, sweep: -.45, seed: 8);
  pen.solid(ruffFront, _ruffLight, shade: 3.4, hi: 0, w: Style.lineThin + .6);
  pen.inside(ruffFront, (p) {
    for (final (a, b, bend) in [(const Offset(68, 156), const Offset(74, 170), 2.0), (const Offset(84, 162), const Offset(88, 178), 1.5), (const Offset(116, 162), const Offset(112, 178), -1.5), (const Offset(132, 156), const Offset(126, 170), -2.0)]) {
      d1Strand(p, a, b, bend: bend, w0: 2, w1: .2, color: withA(_ruffLight.shade, .9));
    }
  });
}

void _ear(Pen pen, int side) {
  Path m(Path p) => side < 0 ? p : mirrorX(p);
  final outer = m(_earOuterL);
  final inner = m(_earInnerL);
  pen.solid(outer, _furDark, shade: 3.5, hi: 1.4, w: Style.line);
  pen.shape(inner, const Color(0xFFC98399), w: 0);
  pen.crescent(inner, const Color(0xFF9C5D78), depth: 3);
  pen.line(inner, w: Style.lineFine + .3, color: withA(Style.ink, .55));
  // fluffy tufts inside the ear
  pen.inside(inner, (p) {
    for (final (a, b) in [(const Offset(66, 88), const Offset(62, 66)), (const Offset(74, 88), const Offset(68, 62)), (const Offset(82, 86), const Offset(74, 66))]) {
      final aa = side < 0 ? a : Offset(200 - a.dx, a.dy);
      final bb = side < 0 ? b : Offset(200 - b.dx, b.dy);
      d1Strand(p, aa, bb, bend: 1.5 * (side < 0 ? 1 : -1), w0: 2.6, w1: .2, color: _furLight.base);
    }
  });
  pen.inside(outer, (p) {
    final a = side < 0 ? const Offset(50, 24) : const Offset(150, 24);
    final b = side < 0 ? const Offset(48, 70) : const Offset(152, 70);
    d1Strand(p, a, b, bend: side < 0 ? -2 : 2, w0: 1.6, w1: .2, color: _furDark.hi);
  });
}

void _wolfHead(Pen pen, Head h) {
  // cast shadow of the chin onto the fur ruff
  pen.inside(_ruffBase, (p) => p.fill(_head.shift(const Offset(2, 5)), withA(const Color(0xFF1B2347), .38)));
  pen.fill(_head, _fur.base);
  // dark skull cap with a widow's peak between the eyes
  final cap = d1Sym(svg('M100 30 L100 99 C94 90 90 80 82 75 C70 70 58 74 44 84 L30 84 L30 30 Z'));
  pen.inside(_head, (p) {
    p.fill(cap, _furDark.base);
    // light lower face and cheeks
    final low = d1Sym(svg('M100 98 C93 99 89 107 79 110 C66 112 57 103 30 100 L30 190 L100 190 Z'));
    p.fill(low, _furLight.base);
    // fur boundary tufts between the dark cap and the lighter cheeks
    p.taper(svg('M52 90 C60 92 68 96 74 104'), w0: 2.4, w1: .2, color: _fur.base);
    p.taper(svg('M148 90 C140 92 132 96 126 104'), w0: 2.4, w1: .2, color: _fur.base);
    // soft shadow on the right / under side
    p.crescent(_head, withA(const Color(0xFF3B2D6A), .2), depth: 5);
    p.rim(_head, withA(const Color(0xFFFFFFFF), .35), depth: 1.8);
    // fur strands on the forehead
    for (final (a, b, bend) in [(const Offset(86, 46), const Offset(82, 62), 1.5), (const Offset(98, 44), const Offset(98, 64), 0.0), (const Offset(112, 46), const Offset(116, 62), -1.5), (const Offset(72, 54), const Offset(66, 66), 1.2), (const Offset(128, 54), const Offset(134, 66), -1.2)]) {
      d1Strand(p, a, b, bend: bend, w0: 2.2, w1: .2, color: _furDark.hi);
    }
    for (final (a, b, bend) in [(const Offset(54, 112), const Offset(70, 120), 2.0), (const Offset(52, 126), const Offset(68, 130), 2.0), (const Offset(146, 112), const Offset(130, 120), -2.0), (const Offset(148, 126), const Offset(132, 130), -2.0)]) {
      d1Strand(p, a, b, bend: bend, w0: 2.4, w1: .2, color: _furLight.shade);
    }
  });

  // dark eye patches with a tail towards the cheeks
  for (final side in const [-1, 1]) {
    final cx = 100 + side * _eyeDx;
    pen.fill(ellipse(cx + side * 1.5, _eyeY + 1, 17.5, 13.5, rot: side * -.2), _patch);
    d1Strand(pen, Offset(cx + side * 13, _eyeY + 3), Offset(cx + side * 27, _eyeY + 11), bend: side * -2.5, w0: 5.5, w1: .4, color: _patch);
  }
  // eyes: amber-yellow, narrowed, glancing to the right
  for (final side in const [-1, 1]) {
    d1Eye(
      pen,
      Offset(100 + side * _eyeDx, _eyeY),
      rx: 13.4,
      ry: 11.4,
      rot: -side * .2,
      side: side,
      lookX: .65,
      lookY: .05,
      iris: const Color(0xFFF4C51C),
      irisR: .78,
      pupilR: .5,
      lidTop: side > 0 ? .2 : .26,
      lidSlant: side > 0 ? .4 : .55,
      lid: 3.6,
      line: 2.1,
    );
  }
  // brows: left angry, right cocked
  d1Brow(pen, const Offset(91, 70), const Offset(57, 64), arch: 1.5, thick: 8.2, color: const Color(0xFF2B3047));
  d1Brow(pen, const Offset(110, 67), const Offset(143, 56), arch: 4, thick: 8.2, color: const Color(0xFF2B3047));

  // muzzle
  pen.fill(_muzzle, _furLight.base);
  pen.crescent(_muzzle, _furLight.shade, depth: 4.2);
  pen.rim(_muzzle, _furLight.hi, depth: 1.4);
  pen.inside(_muzzle, (p) {
    for (final (a, b, bend) in [(const Offset(80, 136), const Offset(86, 148), 1.5), (const Offset(120, 136), const Offset(114, 148), -1.5)]) {
      d1Strand(p, a, b, bend: bend, w0: 1.8, w1: .2, color: withA(_furLight.shade, .9));
    }
  });
  pen.line(_muzzle, w: Style.lineThin + .2);
  // nose
  d1Nose(pen, const Offset(100, 108), w: 23, h: 14.5);
  // mouth: smirk on the viewer's right, one fang out on the left
  pen.line(svg('M100 116 L100 128'), w: 2.3, color: d1Dark);
  pen.line(svg('M100 128 C95 136 87 137 80 131'), w: 2.5, color: d1Dark);
  pen.line(svg('M100 128 C106 135 115 135 122 124'), w: 2.5, color: d1Dark);
  final fang = svg('M84 133 L87.5 143 L92 135 Z');
  pen.shape(fang, d1Cream, w: Style.lineThin);
  // whisker dots
  for (final (x, y) in const [(82, 119), (88, 122), (112, 122), (118, 119)]) {
    pen.fill(circle(x.toDouble(), y.toDouble(), 1.3), withA(d1Dark, .55));
  }
  pen.line(_head, w: Style.line);
}

void _wolfBlink(Pen pen, Head h) {
  for (final side in const [-1, 1]) {
    d1EyeClosed(pen, Offset(100 + side * _eyeDx, _eyeY), rx: 13.4, ry: 10.5, rot: -side * .2, fur: _patch, w: 3.4, bend: .6);
  }
}

void _wolfHowl(Pen pen, Head h) {
  // dropped lower jaw (covers the closed mouth + chin) with a dark open mouth above it
  final jaw = svg('M76 126 C74 146 84 164 100 168 C116 164 126 146 124 126 Z');
  pen.fill(jaw, _furLight.base);
  pen.crescent(jaw, _furLight.shade, depth: 4);
  pen.line(jaw, w: Style.lineThin + .5);
  final mouth = svg('M78 124 C80 118 90 118 100 124 C110 118 120 118 122 124 C124 142 114 154 100 156 C86 154 76 142 78 124 Z');
  pen.fill(mouth, const Color(0xFF4B1426));
  pen.inside(mouth, (p) {
    p.fill(ellipse(100, 154, 15, 11), const Color(0xFFE5667B));
    p.crescent(ellipse(100, 154, 15, 11), const Color(0xFFB8445D), depth: 3);
    p.crescent(mouth, withA(const Color(0xFF000000), .25), depth: 4, dir: const Offset(0, 1));
  });
  pen.line(mouth, w: Style.lineThin + .5);
  // upper fangs
  pen.shape(svg('M82 123 L86 134 L91 122 Z'), d1Cream, w: Style.lineThin);
  pen.shape(svg('M118 123 L114 134 L109 122 Z'), d1Cream, w: Style.lineThin);
  // lower fangs
  pen.shape(svg('M86 152 L89 144 L93 153 Z'), d1Cream, w: Style.lineFine + .2);
  pen.shape(svg('M114 152 L111 144 L107 153 Z'), d1Cream, w: Style.lineFine + .2);
  // keep the nose + muzzle top on top of the overlay
  pen.shape(svg('M72 112 C72 104 84 99 100 99 C116 99 128 104 128 112 L126 118 C118 114 108 120 100 124 C92 120 82 114 74 118 Z'), _furLight.base, w: 0);
  pen.crescent(svg('M72 112 C72 104 84 99 100 99 C116 99 128 104 128 112 L126 118 C118 114 108 120 100 124 C92 120 82 114 74 118 Z'), _furLight.shade, depth: 2.4);
  d1Nose(pen, const Offset(100, 108), w: 23, h: 14.5);
}

final Map<String, PropPainter> wolfLayers = {
  'body': _wolfBody,
  'ear_l': (pen, h) => _ear(pen, -1),
  'ear_r': (pen, h) => _ear(pen, 1),
  'head': _wolfHead,
  'blink': _wolfBlink,
  'howl': _wolfHowl,
};

CharSpec wolfSpec() => d1Spec('wolf', wolfLayers, const ['body', 'ear_l', 'ear_r', 'head']);
