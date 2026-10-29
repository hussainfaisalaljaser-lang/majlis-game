// lv30: golden leopard cub with a chunky gold necklace. Rig layers (anim_rigs.dart `_leopard`):
// body, chain (swings round the neck (100,150), drawn UNDER the head), head, blink.
import 'dart:math' as math;

import '../kit.dart';
import 'd1_animal.dart';

const _fur = Tones(Color(0xFFF3B440), Color(0xFFD38B20), Color(0xFFFFD672));
const _spot = Color(0xFF6E3F14);
const _cream = Tones(Color(0xFFFFF3DA), Color(0xFFEBCFA4), Color(0xFFFFFFFF));
const _eyeY = 91.0;
const _eyeDx = 23.0;

final Path _head = d1Sym(
  svg(
    'M100 49 C76 49 56 60 49 80 C44 96 45 112 52 124 '
    'Q44 128 42 138 Q52 136 58 138 Q70 150 100 152 L100 49 Z',
  ),
);

/// A leopard rosette: dark broken ring with a warm centre.
void _spotAt(Pen pen, double x, double y, double s, double rot) {
  final cv = pen.c;
  cv.save();
  cv.translate(x, y);
  cv.rotate(rot);
  cv.scale(s);
  pen.fill(svg('M-5.5 0 C-5.5 -4.2 -2.5 -6 1 -5.8 C4.6 -5.6 6.6 -3 6.2 0.4 C5.8 4.2 3 5.6 -.4 5.4 C-3.6 5.2 -5.5 3.4 -5.5 0 Z'), _spot);
  pen.fill(svg('M-2.6 .1 C-2.6 -2 -1 -3 .8 -2.9 C2.6 -2.8 3.4 -1.4 3.2 .3 C3 2 1.6 2.9 -.1 2.8 C-1.7 2.7 -2.6 1.8 -2.6 .1 Z'), const Color(0xFFE79B2C));
  cv.restore();
}

void _leopardBody(Pen pen, Head h) {
  final shoulders = svg('M6 228 C10 192 36 162 76 152 L124 152 C164 162 190 192 194 228 Z');
  pen.solid(shoulders, _fur, shade: 6, hi: 2);
  pen.inside(shoulders, (p) {
    for (final (x, y, s, r) in const [(36.0, 196.0, 1.5, -.5), (22.0, 214.0, 1.4, .2), (52.0, 176.0, 1.3, -.8), (62.0, 212.0, 1.5, .5), (164.0, 196.0, 1.5, .5), (178.0, 214.0, 1.4, -.2), (148.0, 176.0, 1.3, .8), (138.0, 212.0, 1.5, -.5)]) {
      _spotAt(p, x, y, s, r);
    }
  });
  // cream chest
  final chest = svg('M78 158 C78 190 88 218 100 232 C112 218 122 190 122 158 C112 168 88 168 78 158 Z');
  pen.solid(chest, _cream, shade: 3.6, hi: 0, w: Style.lineThin + .4);
  // neck fluff
  final fluff = d1Fur(svg('M62 148 C60 164 80 174 100 174 C120 174 140 164 138 148 C132 140 116 136 100 136 C84 136 68 140 62 148 Z'), amp: 5, step: 10, sweep: .4, seed: 4);
  pen.solid(fluff, _cream, shade: 3, hi: 0, w: Style.lineThin + .5);
}

void _leopardChain(Pen pen, Head h) {
  final arc = svg('M62 148 Q100 196 138 148');
  final metrics = arc.computeMetrics().first;
  final n = 11;
  for (var i = 0; i <= n; i++) {
    final t = metrics.getTangentForOffset(metrics.length * i / n)!;
    final ang = math.atan2(t.vector.dy, t.vector.dx);
    final cv = pen.c;
    cv.save();
    cv.translate(t.position.dx, t.position.dy);
    cv.rotate(ang);
    final flat = i.isOdd;
    final link = ellipse(0, 0, flat ? 5.4 : 3.6, flat ? 3.4 : 3.8);
    pen.solid(link, d1Gold, shade: 1.4, hi: .8, w: Style.lineThin + .3);
    if (flat) pen.fill(ellipse(0, 0, 2.4, 1.1), withA(Style.ink, .85));
    cv.restore();
  }
  // pendant medallion
  const c = Offset(100, 182);
  pen.solid(svg('M96 170 L104 170 L102 175 L98 175 Z'), d1Gold, shade: 1, hi: 0, w: Style.lineThin);
  pen.solid(circle(c.dx, c.dy, 11.5), d1Gold, shade: 3.2, hi: 1.4, w: Style.line);
  pen.line(circle(c.dx, c.dy, 8.2), w: Style.lineFine + .2, color: const Color(0xFF9C5F0C));
  d1Gem(pen, c, 5.2, const Color(0xFF16A864));
  d1Shine(pen, Offset(c.dx - 6.5, c.dy - 7), 1.6, 3.2, rot: -.7, a: .9);
}

void _leopardHead(Pen pen, Head h) {
  // round ears behind the head
  for (final side in const [-1, 1]) {
    final cx = 100 + side * 41.0;
    final outer = ellipse(cx, 60, 15, 16.5, rot: side * .35);
    pen.solid(outer, const Tones(Color(0xFF7B4A1E), Color(0xFF5A3210), Color(0xFF9A6630)), shade: 3, hi: 1.2, w: Style.line);
    final inner = ellipse(cx - side * .5, 62.5, 8.2, 9.6, rot: side * .35);
    pen.shape(inner, const Color(0xFFF2A0A5), w: 0);
    pen.crescent(inner, const Color(0xFFD4707C), depth: 2.6);
    pen.line(inner, w: Style.lineFine + .2, color: withA(Style.ink, .5));
  }
  pen.fill(_head, _fur.base);
  pen.inside(_head, (p) {
    // spots: forehead, temples, cheeks
    for (final (x, y, s, r) in const [(85.0, 59.0, .9, -.4), (100.0, 56.0, .8, 0.0), (115.0, 59.0, .9, .4), (62.0, 84.0, 1.2, -1.2), (138.0, 84.0, 1.2, 1.2), (56.0, 106.0, 1.2, -1.4), (144.0, 106.0, 1.2, 1.4)]) {
      _spotAt(p, x, y, s, r);
    }
    for (final (x, y) in const [(94.0, 68.0), (106.0, 68.0), (73.0, 126.0), (127.0, 126.0)]) {
      p.fill(circle(x, y, 1.9), _spot);
    }
    p.crescent(_head, withA(const Color(0xFF7A2E5A), .2), depth: 5);
    p.rim(_head, withA(const Color(0xFFFFFFFF), .35), depth: 1.8);
    // cream cheek puffs
    final cheeks = d1Sym(svg('M100 104 C90 100 76 104 72 114 C66 124 66 138 76 144 C86 150 96 150 100 150 Z'));
    p.fill(cheeks, _cream.base);
    p.crescent(cheeks, _cream.shade, depth: 3.5);
  });
  // eyes: big green cub eyes glancing up-right
  for (final side in const [-1, 1]) {
    d1Eye(
      pen,
      Offset(100 + side * _eyeDx, _eyeY),
      rx: 14.4,
      ry: 13.8,
      side: side,
      lookX: .78,
      lookY: -.25,
      iris: const Color(0xFF2DB864),
      irisR: .74,
      pupilR: .54,
      lidTop: side > 0 ? .0 : .1,
      lidSlant: side > 0 ? .05 : .2,
      lid: 3.6,
      line: 2.1,
    );
  }
  // brows: left cocked up high (cheeky), right low
  d1Brow(pen, const Offset(88, 68), const Offset(60, 62), arch: 5, thick: 5.2, taper: .25, color: _spot);
  d1Brow(pen, const Offset(112, 72), const Offset(138, 72), arch: 1, thick: 5.2, taper: .25, color: _spot);
  // whisker pads, nose, grin
  pen.line(d1Sym(svg('M100 106 L100 114')), w: 2.2, color: d1Dark);
  d1Nose(pen, const Offset(100, 107), w: 15, h: 10.5, color: const Color(0xFFD9607A));
  final grin = svg('M82 120 C86 138 96 142 100 138 C104 142 114 138 118 120 C112 126 106 128 100 128 C94 128 88 126 82 120 Z');
  pen.fill(grin, const Color(0xFF55182A));
  pen.inside(grin, (p) => p.fill(ellipse(100, 139, 8, 5.5), const Color(0xFFFF7B8A)));
  pen.line(grin, w: Style.lineThin + .5);
  pen.shape(svg('M85 122 L88.5 129 L92 124 Z'), d1Cream, w: Style.lineFine + .3);
  pen.shape(svg('M115 122 L111.5 129 L108 124 Z'), d1Cream, w: Style.lineFine + .3);
  pen.line(svg('M100 114 C100 122 100 126 100 128'), w: 2.0, color: d1Dark);
  // whisker dots and whiskers
  for (final (x, y) in const [(80.0, 110.0), (86.0, 115.0), (80.0, 119.0), (120.0, 110.0), (114.0, 115.0), (120.0, 119.0)]) {
    pen.fill(circle(x, y, 1.15), withA(_spot, .8));
  }
  for (final side in const [-1, 1]) {
    for (final (dy, bend) in const [(-4.0, -2.0), (3.0, 0.5), (10.0, 2.5)]) {
      d1Whisker(pen, Offset(100 + side * 25.0, 118.0 + dy * .4), Offset(100 + side * 50.0, 112.0 + dy * 1.3), bend: side * bend, w: 1.6, edge: withA(Style.ink, .85));
    }
  }
  pen.line(_head, w: Style.line);
}

void _leopardBlink(Pen pen, Head h) {
  for (final side in const [-1, 1]) {
    d1EyeClosed(pen, Offset(100 + side * _eyeDx, _eyeY), rx: 14.4, ry: 13, fur: _fur.base, w: 3.4, bend: .6, pad: 2.6);
  }
}

final Map<String, PropPainter> leopardLayers = {
  'body': _leopardBody,
  'chain': _leopardChain,
  'head': _leopardHead,
  'blink': _leopardBlink,
};

CharSpec leopardSpec() => d1Spec('lv30', leopardLayers, const ['body', 'chain', 'head']);
