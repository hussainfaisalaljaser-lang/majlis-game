// Mouths: smile, smirk, grin, clenched teeth, worried open, neutral, frown, "o".
import 'dart:math' as math;
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';

enum MouthKind { neutral, smile, smirk, grin, clenched, open, frown, pout, oh, laugh }

class MouthSpec {
  const MouthSpec({
    this.kind = MouthKind.neutral,
    this.w = 12.0,
    this.y = 40.0,
    this.amount = 1.0,
    this.side = 1,
    this.lips = true,
    this.lineW = 1.0,
    this.x = 0.0,
  });

  final MouthKind kind;

  /// Half width and vertical position (local).
  final double w, y;

  /// Strength of the expression (smile depth, mouth opening), ~0..1.5.
  final double amount;

  /// Which side the smirk is raised on (+1 = viewer's right).
  final int side;
  final bool lips;
  final double lineW;
  final double x;

  MouthSpec copyWith({MouthKind? kind, double? w, double? y, double? amount, int? side, bool? lips, double? lineW, double? x}) => MouthSpec(
    kind: kind ?? this.kind,
    w: w ?? this.w,
    y: y ?? this.y,
    amount: amount ?? this.amount,
    side: side ?? this.side,
    lips: lips ?? this.lips,
    lineW: lineW ?? this.lineW,
    x: x ?? this.x,
  );
}

const _mouthDark = Color(0xFF5A1D27);
const _tongue = Color(0xFFD0606A);
const _teeth = Color(0xFFFFFFFF);
const _teethShade = Color(0xFFD7D3E6);

void drawMouth(Pen pen, Head h, MouthSpec m, Skin skin) {
  final sc = h.scale;
  final w = m.w, y = m.y, k = m.amount, x0 = m.x;
  Path P(String d) => h.path(svg(d), lift: 1.2);
  final inkW = Style.lineThin * m.lineW * sc;
  final lip = skin.lip;

  switch (m.kind) {
    case MouthKind.neutral:
      final d = 'M${x0 - w} $y C${x0 - w * .4} ${y + 1.2} ${x0 + w * .4} ${y + 1.2} ${x0 + w} $y';
      if (m.lips) {
        final low = P('M${x0 - w * .62} ${y + 1.6} C${x0 - w * .25} ${y + 5.5} ${x0 + w * .25} ${y + 5.5} ${x0 + w * .62} ${y + 1.6}');
        pen.line(low, w: inkW * .6, color: withA(lip, .9));
      }
      pen.line(P(d), w: inkW, color: Style.ink);
    case MouthKind.smile:
      final dp = 7.0 * k;
      final line = P('M${x0 - w} ${y - 3 * k} C${x0 - w * .5} ${y + dp * .9} ${x0 + w * .5} ${y + dp * .9} ${x0 + w} ${y - 3 * k}');
      pen.line(line, w: inkW * 1.15, color: Style.ink);
      pen.line(P('M${x0 - w - 0.5} ${y - 3 * k - 2.2} Q${x0 - w - 2} ${y - 3 * k} ${x0 - w + 1.5} ${y - 3 * k + 0.6}'), w: inkW * .7, color: withA(Style.ink, .8));
      pen.line(P('M${x0 + w + 0.5} ${y - 3 * k - 2.2} Q${x0 + w + 2} ${y - 3 * k} ${x0 + w - 1.5} ${y - 3 * k + 0.6}'), w: inkW * .7, color: withA(Style.ink, .8));
      if (m.lips) {
        pen.line(P('M${x0 - w * .5} ${y + dp * .9 + 2.2} Q${x0} ${y + dp * .9 + 4.5} ${x0 + w * .5} ${y + dp * .9 + 2.2}'), w: inkW * .6, color: withA(lip, .9));
      }
    case MouthKind.smirk:
      final s = m.side;
      Offset q(double a, double b) => Offset(x0 + s * a, b);
      // s = +1 : right corner raised
      final c0 = q(-w, y + 1.5), c1 = q(w, y - 4.5 * k);
      final ctrl1 = q(-w * .1, y + 5.5 * k), ctrl2 = q(w * .55, y + 3.2 * k);
      final line = Path()
        ..moveTo(c0.dx, c0.dy)
        ..cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, c1.dx, c1.dy);
      pen.line(h.path(line, lift: 1.2), w: inkW * 1.2, color: Style.ink);
      // dimple at the raised corner
      final d0 = q(w + 1.6, y - 4.5 * k - 2.2), d1 = q(w + 0.4, y - 4.5 * k + 2.6);
      final dim = Path()
        ..moveTo(d0.dx, d0.dy)
        ..quadraticBezierTo(q(w + 3.6, y - 4.5 * k + 0.2).dx, q(w + 3.6, y - 4.5 * k).dy, d1.dx, d1.dy);
      pen.line(h.path(dim, lift: 1.2), w: inkW * .7, color: withA(Style.ink, .8));
      if (m.lips) {
        final l0 = q(-w * .35, y + 5.2 * k + 2.6), l1 = q(w * .45, y + 3.4 * k + 2.4);
        final lowLip = Path()
          ..moveTo(l0.dx, l0.dy)
          ..quadraticBezierTo(q(w * .05, y + 5.6 * k + 4.2).dx, y + 5.6 * k + 4.2, l1.dx, l1.dy);
        pen.line(h.path(lowLip, lift: 1.2), w: inkW * .6, color: withA(lip, .9));
      }
    case MouthKind.grin:
      final dp = 9.0 * k;
      final up = P('M${x0 - w} ${y - 2} C${x0 - w * .5} ${y + 1} ${x0 + w * .5} ${y + 1} ${x0 + w} ${y - 2}');
      final mouth = P('M${x0 - w} ${y - 2} C${x0 - w * .5} ${y + 1} ${x0 + w * .5} ${y + 1} ${x0 + w} ${y - 2} C${x0 + w * .75} ${y + dp * 1.6} ${x0 - w * .75} ${y + dp * 1.6} ${x0 - w} ${y - 2} Z');
      pen.fill(mouth, _mouthDark);
      pen.inside(mouth, (p) {
        // teeth strip
        final teeth = P('M${x0 - w - 1} ${y - 4} L${x0 + w + 1} ${y - 4} L${x0 + w + 1} ${y + 1 + 3.4 * k} C${x0 + w * .5} ${y + 3 + 3 * k} ${x0 - w * .5} ${y + 3 + 3 * k} ${x0 - w - 1} ${y + 1 + 3.4 * k} Z');
        p.fill(teeth, _teeth);
        p.crescent(teeth, _teethShade, depth: 1.2 * sc, dir: const Offset(0, -1));
        final tongue = P('M${x0 - w * .5} ${y + dp * 1.5 + 2} C${x0 - w * .3} ${y + dp * .9 + 1} ${x0 + w * .3} ${y + dp * .9 + 1} ${x0 + w * .5} ${y + dp * 1.5 + 2} Z');
        p.fill(tongue, _tongue);
      });
      pen.line(mouth, w: inkW * 1.15, color: Style.ink);
      pen.line(up, w: inkW * .5, color: withA(Style.ink, .5));
    case MouthKind.laugh:
      final mouth = P('M${x0 - w} ${y - 3} C${x0 - w * .6} ${y + 1} ${x0 + w * .6} ${y + 1} ${x0 + w} ${y - 3} C${x0 + w * .8} ${y + 14 * k} ${x0 - w * .8} ${y + 14 * k} ${x0 - w} ${y - 3} Z');
      pen.fill(mouth, _mouthDark);
      pen.inside(mouth, (p) {
        final teeth = P('M${x0 - w - 1} ${y - 5} L${x0 + w + 1} ${y - 5} L${x0 + w + 1} ${y + 3} Q${x0} ${y + 7} ${x0 - w - 1} ${y + 3} Z');
        p.fill(teeth, _teeth);
        p.fill(P('M${x0 - w * .6} ${y + 14 * k + 1} C${x0 - w * .4} ${y + 7 * k + 2} ${x0 + w * .4} ${y + 7 * k + 2} ${x0 + w * .6} ${y + 14 * k + 1} Z'), _tongue);
      });
      pen.line(mouth, w: inkW * 1.2, color: Style.ink);
    case MouthKind.clenched:
      // bared clenched teeth (angry): wide rounded rectangle, upper + lower row
      final hw = w * 1.05, hh = 5.4 * k;
      final mouth = P(
        'M${x0 - hw} ${y - 1} C${x0 - hw - 2} ${y - hh - 3} ${x0 - hw * .4} ${y - hh - 4.5} ${x0} ${y - hh - 3.2}'
        ' C${x0 + hw * .4} ${y - hh - 4.5} ${x0 + hw + 2} ${y - hh - 3} ${x0 + hw} ${y - 1}'
        ' C${x0 + hw + 1} ${y + hh + 3} ${x0 + hw * .4} ${y + hh + 4.5} ${x0} ${y + hh + 3.4}'
        ' C${x0 - hw * .4} ${y + hh + 4.5} ${x0 - hw - 1} ${y + hh + 3} ${x0 - hw} ${y - 1} Z',
      );
      pen.fill(mouth, _mouthDark);
      pen.inside(mouth, (p) {
        final upper = P('M${x0 - hw - 3} ${y - hh - 6} L${x0 + hw + 3} ${y - hh - 6} L${x0 + hw + 3} ${y - 0.8} L${x0 - hw - 3} ${y - 0.8} Z');
        final lower = P('M${x0 - hw - 3} ${y + 1.2} L${x0 + hw + 3} ${y + 1.2} L${x0 + hw + 3} ${y + hh + 6} L${x0 - hw - 3} ${y + hh + 6} Z');
        p.fill(upper, _teeth);
        p.fill(lower, _teeth);
        p.crescent(upper, _teethShade, depth: 1.6 * sc, dir: const Offset(0, -1));
        // teeth seams
        for (var i = -3; i <= 3; i++) {
          final tx = x0 + i * hw * 0.27;
          p.line(P('M$tx ${y - hh - 4} L${tx + i * .2} ${y - 1}'), w: 0.8 * sc, color: withA(Style.ink, .75));
          p.line(P('M${tx + hw * .13} ${y + 1.2} L${tx + hw * .13} ${y + hh + 4}'), w: 0.8 * sc, color: withA(Style.ink, .75));
        }
        p.line(P('M${x0 - hw - 2} ${y + 0.2} L${x0 + hw + 2} ${y + 0.2}'), w: 1.3 * sc, color: Style.ink);
      });
      pen.line(mouth, w: inkW * 1.3, color: Style.ink);
    case MouthKind.open:
      // small worried / surprised open mouth
      final hw = w * 0.55, hh = 3.6 * k;
      final mouth = P(
        'M${x0 - hw} ${y} C${x0 - hw * .5} ${y - hh * .9} ${x0 + hw * .5} ${y - hh * .9} ${x0 + hw} ${y}'
        ' C${x0 + hw * .8} ${y + hh * 2} ${x0 - hw * .8} ${y + hh * 2} ${x0 - hw} ${y} Z',
      );
      pen.fill(mouth, _mouthDark);
      pen.inside(mouth, (p) {
        final t = P('M${x0 - hw} ${y - 2} L${x0 + hw} ${y - 2} L${x0 + hw} ${y + hh * .5} L${x0 - hw} ${y + hh * .5} Z');
        p.fill(t, _teeth);
        p.fill(P('M${x0 - hw * .5} ${y + hh * 2} Q${x0} ${y + hh * .4} ${x0 + hw * .5} ${y + hh * 2} Z'), _tongue);
      });
      pen.line(mouth, w: inkW * 1.1, color: Style.ink);
    case MouthKind.oh:
      final r = w * 0.4 * k;
      final mouth = h.path(ellipse(x0, y + 1, r, r * 1.2), lift: 1.2);
      pen.fill(mouth, _mouthDark);
      pen.fill(h.path(ellipse(x0, y + 1 + r * .55, r * .6, r * .5), lift: 1.2), _tongue);
      pen.line(mouth, w: inkW * 1.2, color: Style.ink);
    case MouthKind.frown:
      final line = P('M${x0 - w} ${y + 1.5} C${x0 - w * .5} ${y - 5 * k} ${x0 + w * .5} ${y - 5 * k} ${x0 + w} ${y + 1.5}');
      pen.line(line, w: inkW * 1.15, color: Style.ink);
      if (m.lips) pen.line(P('M${x0 - w * .5} ${y + 3.6} Q${x0} ${y + 2.4} ${x0 + w * .5} ${y + 3.6}'), w: inkW * .55, color: withA(lip, .9));
    case MouthKind.pout:
      final upper = P('M${x0 - w * .55} ${y} C${x0 - w * .2} ${y - 3} ${x0 + w * .2} ${y - 3} ${x0 + w * .55} ${y}');
      final lower = P('M${x0 - w * .55} ${y} C${x0 - w * .3} ${y + 5} ${x0 + w * .3} ${y + 5} ${x0 + w * .55} ${y}');
      pen.fill(lower, withA(lip, .85));
      pen.line(lower, w: inkW * .9, color: Style.ink);
      pen.line(upper, w: inkW * .9, color: Style.ink);
  }
  // keep math import used
  assert(math.pi > 3);
}
