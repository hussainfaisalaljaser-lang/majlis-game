// lv50: the phoenix: orange firebird with a flame crest and flame wings. Rig layers (anim_rigs.dart `_phoenix`):
// wings (behind, scaled about (100,200) while flapping), body, crest (flame fan behind the head, flickers about
// (100,70)), head, blink. The rig sparkles at `phoenixTips` (crest frame).
import 'dart:math' as math;

import '../kit.dart';
import 'd1_animal.dart';

const _orange = Tones(Color(0xFFFA8A24), Color(0xFFD85C10), Color(0xFFFFB552));
const _cream = Tones(Color(0xFFFFF1D6), Color(0xFFF0CFA0), Color(0xFFFFFFFF));
const _beak = Tones(Color(0xFFFFCB3B), Color(0xFFD9901A), Color(0xFFFFEC9A));
const _flameOut = Tones(Color(0xFFE23220), Color(0xFFB11E16), Color(0xFFFF6F50));
const _flameMid = Color(0xFFFF8C1F);
const _flameCore = Color(0xFFFFD83F);
const _eyeY = 97.0;
const _eyeDx = 22.0;

/// Where the crest flames end (head frame) for the sparkle.
const phoenixTips = [Offset(100, 8), Offset(124, 15), Offset(76, 15), Offset(142, 33), Offset(58, 33)];

final Path _head = d1Sym(
  svg(
    'M100 53 C76 53 58 65 52 86 C48 102 50 118 60 130 '
    'Q52 134 50 144 Q60 141 66 142 Q78 152 100 154 L100 53 Z',
  ),
);

void _phoenixWings(Pen pen, Head h) {
  for (final side in const [-1, 1]) {
    final bx = 100 + side * 34.0;
    // outermost / longest feathers first, then inwards
    for (final (a, len, w) in const [(66.0, 58.0, 21.0), (50.0, 70.0, 22.0), (34.0, 78.0, 22.0), (19.0, 74.0, 20.0)]) {
      d1Flame(pen, Offset(bx, 172), len, w, side * a * math.pi / 180, curl: side, outer: _flameOut, mid: _flameMid, core: _flameCore);
    }
  }
}

void _phoenixBody(Pen pen, Head h) {
  final shoulders = svg('M10 228 C14 192 40 162 78 152 L122 152 C160 162 186 192 190 228 Z');
  pen.solid(shoulders, _orange, shade: 6, hi: 2);
  pen.inside(shoulders, (p) {
    for (var r = 0; r < 3; r++) {
      for (var i = 0; i < 3; i++) {
        final x = 22.0 + i * 13 + r * 5;
        final y = 186.0 + r * 12 + i * 2;
        for (final side in const [-1, 1]) {
          final xx = side < 0 ? x : 200 - x;
          p.line(svg('M${xx - 6} $y Q$xx ${y + 8} ${xx + 6} $y'), w: 1.7, color: withA(_orange.shade, .95));
        }
      }
    }
  });
  // breast feathers
  final breast = svg('M72 168 C72 200 84 222 100 232 C116 222 128 200 128 168 C116 178 84 178 72 168 Z');
  pen.solid(breast, const Tones(Color(0xFFFFD9A6), Color(0xFFEBB77C), Color(0xFFFFF0D2)), shade: 3.6, hi: 0, w: Style.lineThin + .5);
  pen.inside(breast, (p) {
    for (var r = 0; r < 4; r++) {
      final y = 186.0 + r * 11;
      for (final x in const [86.0, 100.0, 114.0]) {
        p.line(svg('M${x - 6} ${y - 3} Q$x ${y + 5} ${x + 6} ${y - 3}'), w: 1.9, color: _orange.base);
      }
    }
  });
  // flame-feather collar round the neck (outer row red, inner row yellow), over the breast
  for (final (dist, len, w, tones, mid, core) in [
    (50.0, 32.0, 15.0, _flameOut, _flameMid, _flameCore),
    (36.0, 24.0, 12.0, const Tones(Color(0xFFFF9B22), Color(0xFFD9680E), Color(0xFFFFC25A)), const Color(0xFFFFC93A), const Color(0xFFFFEB8F)),
  ]) {
    final order = [for (var k = -3; k <= 3; k++) k]..sort((x, y) => y.abs().compareTo(x.abs()));
    for (final k in order) {
      final psi = k * 0.40;
      final base = Offset(100 + dist * math.sin(psi), 140 + (dist * .55) * math.cos(psi));
      d1Flame(pen, base, len, w, math.pi - psi, curl: k >= 0 ? 1 : -1, outer: tones, mid: mid, core: core, outline: Style.lineThin + .8);
    }
  }
}

void _phoenixCrest(Pen pen, Head h) {
  const base = Offset(100, 72);
  // outer feathers first
  for (final (a, len, w, curl) in const [(-48.0, 50.0, 16.0, -1), (48.0, 50.0, 16.0, 1), (-25.0, 58.0, 17.0, -1), (25.0, 58.0, 17.0, 1), (0.0, 64.0, 18.0, 1)]) {
    d1Flame(pen, base, len, w, a * math.pi / 180, curl: curl, outer: _flameOut, mid: _flameMid, core: _flameCore);
  }
}

void _phoenixHead(Pen pen, Head h) {
  pen.fill(_head, _orange.base);
  pen.inside(_head, (p) {
    // cream face mask
    final mask = d1Sym(svg('M100 78 C90 72 76 76 68 86 C60 98 62 116 74 128 C82 136 92 140 100 140 Z'));
    p.fill(mask, _cream.base);
    p.crescent(mask, _cream.shade, depth: 3.2);
    p.crescent(_head, withA(const Color(0xFF7A1E3C), .22), depth: 5);
    p.rim(_head, withA(const Color(0xFFFFFFFF), .35), depth: 1.8);
    // feather flecks on the cheeks and crown
    for (final (a, b, bend) in [(const Offset(56, 112), const Offset(66, 124), 1.5), (const Offset(144, 112), const Offset(134, 124), -1.5), (const Offset(62, 128), const Offset(72, 138), 1.5), (const Offset(138, 128), const Offset(128, 138), -1.5), (const Offset(78, 62), const Offset(82, 72), 1.0), (const Offset(122, 62), const Offset(118, 72), -1.0), (const Offset(100, 58), const Offset(100, 70), 0.0)]) {
      d1Strand(p, a, b, bend: bend, w0: 2.4, w1: .2, color: _orange.shade);
    }
  });
  // blush
  pen.glow(const Offset(72, 118), 8, 5, const Color(0xFFFF7A6A), alpha: .35);
  pen.glow(const Offset(128, 118), 8, 5, const Color(0xFFFF7A6A), alpha: .35);
  // eyes: proud, glancing up to the right
  for (final side in const [-1, 1]) {
    d1Eye(
      pen,
      Offset(100 + side * _eyeDx, _eyeY),
      rx: 12.8,
      ry: 13,
      side: side,
      lookX: .7,
      lookY: -.2,
      iris: const Color(0xFFB4510C),
      irisR: .76,
      pupilR: .52,
      lidTop: .06,
      lidSlant: 0,
      lid: 3.5,
      line: 2.1,
    );
  }
  // flame brows
  d1Brow(pen, const Offset(90, 76), const Offset(60, 74), arch: 6, thick: 6.4, color: const Color(0xFF8E2A0C));
  d1Brow(pen, const Offset(110, 74), const Offset(142, 68), arch: 7, thick: 6.4, color: const Color(0xFF8E2A0C));
  // beak
  final beak = svg('M90 108 C94 102 106 102 110 108 C111 118 106 128 101 134 C99 135 97 133 96 131 C92 125 89 117 90 108 Z');
  pen.solid(beak, _beak, shade: 3.2, hi: 1.2, w: Style.lineThin + .7);
  pen.line(svg('M92 117 C97 121 103 121 108 117'), w: 1.7, color: d1Dark);
  d1Strand(pen, const Offset(96, 108), const Offset(97, 118), bend: -.8, w0: 2, w1: .2, color: withA(const Color(0xFFFFFFFF), .8));
  pen.fill(ellipse(96, 110.5, 1.2, 1.8), const Color(0xFF8A560C));
  pen.fill(ellipse(104, 110.5, 1.2, 1.8), const Color(0xFF8A560C));
  pen.line(_head, w: Style.line);
}

void _phoenixBlink(Pen pen, Head h) {
  for (final side in const [-1, 1]) {
    d1EyeClosed(pen, Offset(100 + side * _eyeDx, _eyeY), rx: 12.8, ry: 11.8, fur: _cream.base, w: 3.4, bend: .55, pad: 2.6);
  }
}

final Map<String, PropPainter> phoenixLayers = {
  'wings': _phoenixWings,
  'body': _phoenixBody,
  'crest': _phoenixCrest,
  'head': _phoenixHead,
  'blink': _phoenixBlink,
};

CharSpec phoenixSpec() => d1Spec('lv50', phoenixLayers, const ['wings', 'body', 'crest', 'head']);
