// falcon_bird: brown hawk/falcon with an owl-like face, yellow hooked beak. Rig layers (anim_rigs.dart `_falconBird`):
// body, head (rotated round the neck (100,150)), blink (closed eyes), beak (open-beak overlay while it screams).
import 'dart:math' as math;

import '../kit.dart';
import 'd1_animal.dart';

const _brown = Tones(Color(0xFF9B6B3E), Color(0xFF744929), Color(0xFFC08E5B));
const _bodyBrown = Tones(Color(0xFF8D5E34), Color(0xFF643D1E), Color(0xFFB07D4C));
const _mask = Color(0xFF583820);
const _cream = Tones(Color(0xFFF5E6C6), Color(0xFFD8BF96), Color(0xFFFFF7E2));
const _beak = Tones(Color(0xFFF6BC3E), Color(0xFFC98A1E), Color(0xFFFFE590));
const _eyeY = 88.0;
const _eyeDx = 28.0;

final Path _head = d1Sym(
  svg(
    'M100 40 C82 40 64 46 55 62 C48 74 46 86 47 98 '
    'Q38 106 36 118 Q46 115 52 120 Q46 130 48 143 Q58 139 66 141 '
    'Q80 154 100 160 L100 40 Z',
  ),
);

Path _upperBeak() => svg('M88 99 C90 93 110 93 112 99 C115 108 113 120 108 130 C106 138 103 146 99 150 C97 147 95 144 93 140 C89 132 86 120 86 108 C86 104 87 101 88 99 Z');
Path _lowerBeak() => svg('M91 124 C91 134 94 140 99 142 C105 141 109 135 109 124 Z');

void _drawUpperBeak(Pen pen, {bool open = false}) {
  var b = _upperBeak();
  if (open) b = scaledAbout(b, const Offset(100, 96), 1.04, .86).shift(const Offset(0, -2));
  pen.solid(b, _beak, shade: 3.8, hi: 1.4, w: Style.line);
  pen.inside(b, (p) {
    // small cere (top) with nostril slits, ridge highlight, hooked tip shade
    p.fill(svg('M80 90 L120 90 L120 103 C112 106 106 104 100 105 C94 104 88 106 80 103 Z'), const Color(0xFFFFCF55));
    p.line(svg('M80 103 C88 106 94 104 100 105 C106 104 112 106 120 103'), w: Style.lineFine + .2, color: withA(Style.ink, .5));
    p.fill(ellipse(94.5, 98.5, 1.4, 2.6, rot: .45), const Color(0xFF5A3410));
    p.fill(ellipse(105.5, 98.5, 1.4, 2.6, rot: -.45), const Color(0xFF5A3410));
    d1Strand(p, const Offset(94.5, 108), const Offset(97, 132), bend: -1.5, w0: 2.4, w1: .2, color: withA(const Color(0xFFFFFFFF), .8));
    if (!open) p.crescent(svg('M92 128 L108 128 L100 152 Z'), _beak.shade, depth: 2.5, dir: const Offset(0, -1));
  });
  pen.line(b, w: Style.line);
}

void _falconBody(Pen pen, Head h) {
  final shoulders = svg('M6 228 C12 190 40 158 80 144 L120 144 C160 158 188 190 194 228 Z');
  pen.solid(shoulders, _bodyBrown, shade: 6, hi: 2);
  pen.inside(shoulders, (p) {
    // scapular feather scallops
    for (var r = 0; r < 4; r++) {
      for (var i = 0; i < 4 - (r ~/ 2); i++) {
        final x = 18.0 + i * 13 + r * 5 + (r.isOdd ? 6 : 0);
        final y = 178.0 + r * 11 + i * 2;
        for (final side in const [-1, 1]) {
          final xx = side < 0 ? x : 200 - x;
          p.line(svg('M${xx - 6} $y Q$xx ${y + 8} ${xx + 6} $y'), w: 1.7, color: withA(_bodyBrown.shade, .9));
        }
      }
    }
  });
  // cream breast with brown chevrons (flows out of the throat)
  final breast = svg('M64 146 C62 190 80 222 100 234 C120 222 138 190 136 146 Z');
  pen.solid(breast, _cream, shade: 4, hi: 0, w: Style.line);
  pen.inside(breast, (p) {
    for (var r = 0; r < 5; r++) {
      final y = 174.0 + r * 10;
      for (final x in const [84.0, 100.0, 116.0]) {
        p.line(svg('M${x - 6.5} ${y - 3} Q$x ${y + 5} ${x + 6.5} ${y - 3}'), w: 1.9, color: const Color(0xFF8D5E34));
      }
    }
  });
}

void _falconHeadPose(Pen pen, {required bool open}) {
  // swept-back crown feathers behind the head
  for (final (a, len, w, curl, bx) in const [(-34.0, 30.0, 11.0, -1, 76.0), (-8.0, 40.0, 13.0, -1, 94.0), (18.0, 30.0, 11.0, -1, 114.0)]) {
    d1Flame(pen, Offset(bx, 58), len, w, a * math.pi / 180, curl: curl, outer: _brown, mid: _brown.hi, core: _cream.base, outline: Style.line);
  }
  // cast shadow on the breast
  pen.fill(_head, _brown.base);
  pen.inside(_head, (p) {
    // cream cheeks / throat
    final low = d1Sym(svg('M100 108 C92 110 86 114 76 116 C64 118 54 112 30 108 L30 190 L100 190 Z'));
    p.fill(low, _cream.base);
    // feather scallops on the crown
    for (var r = 0; r < 3; r++) {
      for (var i = 0; i < 6; i++) {
        final x = 62.0 + i * 15.2 + (r.isOdd ? 7 : 0);
        final y = 52.0 + r * 10;
        p.line(svg('M${x - 5} $y Q$x ${y + 6} ${x + 5} $y'), w: 1.6, color: withA(_brown.shade, .75));
      }
    }
    p.crescent(_head, withA(const Color(0xFF3B2D6A), .2), depth: 5);
    p.rim(_head, withA(const Color(0xFFFFFFFF), .3), depth: 1.8);
    // cream cheek feather flecks
    for (final (a, b, bend) in [(const Offset(52, 124), const Offset(66, 132), 1.5), (const Offset(148, 124), const Offset(134, 132), -1.5), (const Offset(60, 138), const Offset(72, 146), 1.5), (const Offset(140, 138), const Offset(128, 146), -1.5)]) {
      d1Strand(p, a, b, bend: bend, w0: 2.4, w1: .2, color: _cream.shade);
    }
  });
  // dark facial mask round the eyes with a tear-mark stripe down the cheek
  for (final side in const [-1, 1]) {
    final cx = 100 + side * _eyeDx;
    pen.fill(ellipse(cx + side * 1, _eyeY, 18, 16, rot: side * .1), _mask);
    d1Strand(pen, Offset(cx - side * 4, _eyeY + 12), Offset(cx - side * 1, _eyeY + 40), bend: side * 3, w0: 8.5, w1: 1, color: _mask);
  }
  for (final side in const [-1, 1]) {
    d1Eye(
      pen,
      Offset(100 + side * _eyeDx, _eyeY),
      rx: 12.8,
      ry: 12.6,
      side: side,
      lookX: -.7,
      lookY: -.05,
      iris: const Color(0xFFFFC61C),
      irisR: .82,
      pupilR: .55,
      sclera: const Color(0xFFFFF3CB),
      lidTop: open ? .26 : .12,
      lidSlant: side > 0 ? .5 : .6,
      lid: 3.6,
      line: 2.1,
    );
  }
  // heavy brow ridges
  d1Brow(pen, Offset(90, open ? 74 : 71), Offset(54, open ? 66 : 63), arch: 2, thick: 9, color: const Color(0xFF3A2314));
  d1Brow(pen, Offset(110, open ? 75 : 72), Offset(146, open ? 62 : 58), arch: 3, thick: 9, color: const Color(0xFF3A2314));
  if (open) {
    // screaming: dark mouth, dropped lower mandible, raised shortened upper beak
    final mouth = svg('M87 118 C88 136 94 150 100 156 C106 150 112 136 113 118 Z');
    pen.fill(mouth, const Color(0xFF4B1426));
    pen.inside(mouth, (p) => p.fill(ellipse(100, 150, 8, 5.5), const Color(0xFFE5667B)));
    pen.line(mouth, w: Style.lineThin + .3);
    final jaw = svg('M89 134 C90 152 95 162 100 165 C105 162 110 152 111 134 C106 138 94 138 89 134 Z');
    pen.solid(jaw, _beak.darker(.12), shade: 3, hi: 0, w: Style.line);
    _drawUpperBeak(pen, open: true);
  } else {
    // beak: lower mandible tucked under the hooked upper beak
    final low = _lowerBeak();
    pen.solid(low, _beak.darker(.15), shade: 2.4, hi: 0, w: Style.lineThin + .4);
    _drawUpperBeak(pen);
    pen.line(svg('M88 124 C94 129 106 129 112 124'), w: 2.2, color: d1Dark);
  }
  pen.line(_head, w: Style.line);
}

void _falconBlink(Pen pen, Head h) {
  for (final side in const [-1, 1]) {
    d1EyeClosed(pen, Offset(100 + side * _eyeDx, _eyeY), rx: 12.8, ry: 11.8, fur: _mask, w: 3.4, bend: .5, pad: 2.6);
  }
}

void _falconHead(Pen pen, Head h) => _falconHeadPose(pen, open: false);

/// The screaming pose is a FULL head redraw (same coordinates) laid over the closed head, so the upper beak
/// can lift and the squinting eyes / brows can change together with the open mouth.
void _falconScream(Pen pen, Head h) => _falconHeadPose(pen, open: true);

final Map<String, PropPainter> falconLayers = {
  'body': _falconBody,
  'head': _falconHead,
  'blink': _falconBlink,
  'beak': _falconScream,
};

CharSpec falconBirdSpec() => d1Spec('falcon_bird', falconLayers, const ['body', 'head']);
