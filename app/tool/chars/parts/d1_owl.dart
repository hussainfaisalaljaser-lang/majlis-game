// lv20: the wise owl with big round gold glasses, reading a book held in its wing.
// Rig layers (anim_rigs.dart `_owl`): body, head, blink, glasses (over head + blink), book (+ wing tips, body frame).
// The rig draws a page-flip leaf over the book: spine at (146,172) rotated -12deg, pages 26 wide x 17 high.
import 'dart:math' as math;
import 'dart:ui' show PathOperation;

import '../kit.dart';
import 'd1_animal.dart';

const _brown = Tones(Color(0xFF8E6D49), Color(0xFF68492B), Color(0xFFB4906A));
const _darkBrown = Tones(Color(0xFF64452A), Color(0xFF47301C), Color(0xFF86623F));
const _cream = Tones(Color(0xFFF6E9CD), Color(0xFFD9C3A0), Color(0xFFFFF9E8));
const _beak = Tones(Color(0xFFF59E2E), Color(0xFFC56C14), Color(0xFFFFCB70));
const _eyeY = 97.0;
const _eyeDx = 24.0;
const _rimR = 21.0;

const bookCenter = Offset(131, 167);
const bookTilt = -12 * math.pi / 180;

final Path _head = d1Sym(
  svg('M100 45 C78 45 58 54 51 74 C46 90 47 110 55 126 C65 142 82 149 100 149 L100 45 Z'),
);

void _owlBody(Pen pen, Head h) {
  final shoulders = svg('M4 228 C8 190 34 158 70 142 L130 142 C166 158 192 190 196 228 Z');
  pen.solid(shoulders, _brown, shade: 6, hi: 2);
  pen.inside(shoulders, (p) {
    for (var r = 0; r < 4; r++) {
      for (var i = 0; i < 3; i++) {
        final x = 16.0 + i * 12 + r * 4 + (r.isOdd ? 6 : 0);
        final y = 184.0 + r * 11 + i * 2;
        p.line(svg('M${x - 6} $y Q$x ${y + 8} ${x + 6} $y'), w: 1.7, color: withA(_brown.shade, .95));
      }
    }
  });
  // cream breast with brown chevrons
  final breast = svg('M62 156 C60 196 76 224 100 234 C124 224 140 196 138 156 C122 168 78 168 62 156 Z');
  pen.solid(breast, _cream, shade: 4, hi: 0, w: Style.lineThin + .5);
  pen.inside(breast, (p) {
    for (var r = 0; r < 5; r++) {
      final y = 180.0 + r * 11;
      for (final x in const [80.0, 94.0, 108.0, 122.0]) {
        if ((r.isOdd && x == 122) || (r.isOdd && x == 80)) continue;
        p.line(svg('M${x - 6.5} ${y - 3} Q$x ${y + 6} ${x + 6.5} ${y - 3}'), w: 1.9, color: const Color(0xFF9E7A52));
      }
    }
  });
  // the wing that holds the book (right side)
  final wing = svg('M128 150 C158 148 182 170 184 206 L184 232 L96 232 C96 214 106 200 118 192 C130 182 138 166 128 150 Z');
  pen.solid(wing, _darkBrown, shade: 5, hi: 1.6);
  pen.inside(wing, (p) {
    for (final (a, b, bend) in [(const Offset(148, 158), const Offset(160, 196), 2.0), (const Offset(162, 166), const Offset(172, 204), 2.0), (const Offset(136, 168), const Offset(146, 200), 2.0)]) {
      d1Strand(p, a, b, bend: bend, w0: 2.2, w1: .2, color: _darkBrown.hi);
    }
  });
}

void _owlHead(Pen pen, Head h) {
  // ear tufts
  for (final side in const [-1, 1]) {
    Path m(Path p) => side < 0 ? p : mirrorX(p);
    final tuft = m(svg('M60 70 C50 56 44 40 44 20 C60 24 78 36 88 56 Z'));
    pen.solid(tuft, _darkBrown, shade: 3, hi: 1.2, w: Style.line);
    pen.inside(tuft, (p) => d1Strand(p, Offset(side < 0 ? 52.0 : 148.0, 30), Offset(side < 0 ? 66.0 : 134.0, 60), bend: side * 2.0, w0: 2.4, w1: .2, color: _darkBrown.hi));
  }
  pen.fill(_head, _brown.base);
  pen.inside(_head, (p) {
    // feather scallops on the crown and cheeks
    for (var r = 0; r < 2; r++) {
      for (var i = 0; i < 7; i++) {
        final x = 56.0 + i * 14.7 + (r.isOdd ? 7 : 0);
        final y = 54.0 + r * 9;
        p.line(svg('M${x - 5} $y Q$x ${y + 6} ${x + 5} $y'), w: 1.6, color: withA(_brown.shade, .8));
      }
    }
    p.crescent(_head, withA(const Color(0xFF3B2D6A), .2), depth: 5);
    p.rim(_head, withA(const Color(0xFFFFFFFF), .3), depth: 1.8);
  });
  // cream facial discs round the eyes
  final discs = Path.combine(
    PathOperation.union,
    circle(100 - _eyeDx, _eyeY, 28),
    circle(100 + _eyeDx, _eyeY, 28),
  );
  final disc = Path.combine(PathOperation.union, discs, ellipse(100, 112, 16, 18));
  pen.fill(disc, _cream.base);
  pen.inside(disc, (p) {
    p.crescent(disc, _cream.shade, depth: 4);
    p.rim(disc, _cream.hi, depth: 1.5);
  });
  pen.line(disc, w: Style.lineThin, color: withA(Style.ink, .55));
  // eyes: huge, amber, looking down-right at the book
  for (final side in const [-1, 1]) {
    d1Eye(
      pen,
      Offset(100 + side * _eyeDx, _eyeY),
      rx: 16,
      ry: 16,
      side: side,
      lookX: .62,
      lookY: .38,
      iris: const Color(0xFFF2A020),
      irisR: .78,
      pupilR: .56,
      sclera: const Color(0xFFFFFDF4),
      lid: 3.4,
      line: 2.1,
    );
  }
  // thick feathered brows: left stern, right raised
  d1Brow(pen, const Offset(94, 70), const Offset(52, 72), arch: 6, thick: 8.5, color: _darkBrown.base);
  d1Brow(pen, const Offset(106, 66), const Offset(150, 58), arch: 5, thick: 8.5, color: _darkBrown.base);
  // beak
  final beak = svg('M91 108 C95 103 105 103 109 108 C109 116 105 124 100 129 C95 124 91 116 91 108 Z');
  pen.solid(beak, _beak, shade: 3, hi: 1.2, w: Style.lineThin + .6);
  d1Strand(pen, const Offset(96, 109), const Offset(97.5, 118), bend: -.8, w0: 1.8, w1: .2, color: withA(const Color(0xFFFFFFFF), .75));
  pen.line(_head, w: Style.line);
}

void _owlBlink(Pen pen, Head h) {
  for (final side in const [-1, 1]) {
    d1EyeClosed(pen, Offset(100 + side * _eyeDx, _eyeY), rx: 16, ry: 15, fur: _cream.base, w: 3.4, bend: .55, pad: 3.2);
  }
}

void _owlGlasses(Pen pen, Head h) {
  for (final side in const [-1, 1]) {
    final c = Offset(100 + side * _eyeDx, _eyeY);
    // faint blue lens tint + glints
    pen.fill(circle(c.dx, c.dy, _rimR), withA(const Color(0xFFBFE3FF), .16));
    final ring = Path.combine(PathOperation.difference, circle(c.dx, c.dy, _rimR + 2.1), circle(c.dx, c.dy, _rimR - 2.1));
    pen.solid(ring, d1Gold, shade: 1.6, hi: .9, w: Style.lineThin + .3);
    d1Strand(pen, Offset(c.dx - 14, c.dy - 6), Offset(c.dx - 7, c.dy - 15), bend: -1.5, w0: 3, w1: 1, color: withA(const Color(0xFFFFFFFF), .85));
    pen.fill(circle(c.dx - 15.5, c.dy - 1, 1.3), withA(const Color(0xFFFFFFFF), .85));
  }
  // bridge + temple arms
  pen.line(svg('M${100 - _eyeDx + _rimR - 1} ${_eyeY - 6} Q100 ${_eyeY - 13} ${100 + _eyeDx - _rimR + 1} ${_eyeY - 6}'), w: 5.2, color: Style.ink);
  pen.line(svg('M${100 - _eyeDx + _rimR - 1} ${_eyeY - 6} Q100 ${_eyeY - 13} ${100 + _eyeDx - _rimR + 1} ${_eyeY - 6}'), w: 2.6, color: d1Gold.base);
  for (final side in const [-1, 1]) {
    final x0 = 100 + side * (_eyeDx + _rimR + 1);
    pen.line(Path()
      ..moveTo(x0, _eyeY - 2)
      ..lineTo(x0 + side * 3.5, _eyeY - 5), w: 5.2, color: Style.ink);
    pen.line(Path()
      ..moveTo(x0, _eyeY - 2)
      ..lineTo(x0 + side * 3.5, _eyeY - 5), w: 2.6, color: d1Gold.base);
  }
}

void _owlBook(Pen pen, Head h) {
  final cv = pen.c;
  cv.save();
  cv.translate(bookCenter.dx, bookCenter.dy);
  cv.rotate(bookTilt);
  final cover = svg('M-31 -21 L31 -21 L31 21 L-31 21 Z');
  pen.solid(cover, const Tones(Color(0xFF9A3B20), Color(0xFF6E2410), Color(0xFFC0562F)), shade: 3, hi: 0, w: Style.line);
  final pageL = svg('M-1.4 -17.5 C-8 -20 -20 -20 -27.5 -17 L-27.5 17 C-20 14.5 -8 14.5 -1.4 17.5 Z');
  final pageR = svg('M1.4 -17.5 C8 -20 20 -20 27.5 -17 L27.5 17 C20 14.5 8 14.5 1.4 17.5 Z');
  for (final pg in [pageL, pageR]) {
    pen.fill(pg, const Color(0xFFFFF7E2));
    pen.line(pg, w: Style.lineFine + .3, color: withA(Style.ink, .7));
  }
  pen.inside(pageL, (p) => p.crescent(pageL, const Color(0xFFE6D2A8), depth: 3.2, dir: const Offset(-1, 0)));
  pen.inside(pageR, (p) => p.crescent(pageR, const Color(0xFFE6D2A8), depth: 3.2, dir: const Offset(1, 0)));
  for (final side in const [-1, 1]) {
    for (var i = 0; i < 4; i++) {
      final y = -10.0 + i * 6.2;
      final x0 = side * 5.5, x1 = side * (i == 3 ? 17.0 : 23.0);
      pen.line(Path()
        ..moveTo(x0, y)
        ..lineTo(x1, y), w: 1.5, color: const Color(0xFF9E7A52));
    }
  }
  // spine shadow + gold corners + ribbon
  pen.line(svg('M0 -17.5 L0 17.5'), w: 1.8, color: withA(Style.ink, .75));
  for (final (x, y) in const [(-31.0, -21.0), (31.0, -21.0), (-31.0, 21.0), (31.0, 21.0)]) {
    final sx = x.sign, sy = y.sign;
    pen.solid(poly([Offset(x, y), Offset(x - sx * 8, y), Offset(x, y - sy * 8)]), d1Gold, shade: 1.4, hi: 0, w: Style.lineThin);
  }
  pen.solid(svg('M-2.5 19 L2.5 19 L2.5 29 L0 26.5 L-2.5 29 Z'), const Tones(Color(0xFFD7263D), Color(0xFF9C1428), Color(0xFFFF6B7D)), shade: 1, hi: 0, w: Style.lineThin);
  cv.restore();
  // wing tips curling over the lower-left corner of the book
  for (final (dx, dy, rot, len) in const [(108.0, 190.0, -.55, 24.0), (115.0, 195.0, -.35, 22.0), (123.0, 198.0, -.12, 20.0)]) {
    cv.save();
    cv.translate(dx, dy);
    cv.rotate(rot);
    final f = svg('M-6 0 C-6 -${len * .6} -3 -$len 0 -$len C3 -$len 6 -${len * .6} 6 0 C6 6 -6 6 -6 0 Z');
    pen.solid(f, _darkBrown, shade: 2.6, hi: 1, w: Style.lineThin + .5);
    d1Strand(pen, Offset(0, -len + 4), Offset(0, -3), bend: 0, w0: 1.4, w1: .2, color: _darkBrown.hi);
    cv.restore();
  }
}

final Map<String, PropPainter> owlLayers = {
  'body': _owlBody,
  'head': _owlHead,
  'blink': _owlBlink,
  'glasses': _owlGlasses,
  'book': _owlBook,
};

CharSpec owlSpec() => d1Spec('lv20', owlLayers, const ['body', 'head', 'glasses', 'book']);
