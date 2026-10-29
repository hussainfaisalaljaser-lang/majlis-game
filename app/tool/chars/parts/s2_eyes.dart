// Special eyes + face effects for stickers (worker S2): things the kit's plain eyes can't show.
// Give the kit's own eyes `open: 0` (they then draw nothing) and call [s2Eyes] from the `front`
// painter; shapes are projected through the head so they follow its turn.
import 'dart:math' as math;
import 'dart:ui';

import '../core/head.dart';
import '../core/pen.dart';

enum S2Eye { happy, squint, down, stars, money, dizzy, hearts, glow, wink }

const _gold = Tones(Color(0xFFFFCB2E), Color(0xFFE59A12), Color(0xFFFFE680));

/// 5-point star path centred at (cx, cy).
Path s2Star(double cx, double cy, double r, {double inner = 0.46, double rot = -math.pi / 2}) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = rot + i * math.pi / 5;
    final rr = i.isEven ? r : r * inner;
    final x = cx + math.cos(a) * rr, y = cy + math.sin(a) * rr;
    if (i == 0) {
      p.moveTo(x, y);
    } else {
      p.lineTo(x, y);
    }
  }
  return p..close();
}

/// Replace both eyes by [kind]. [gap]/[y] = the eye centres in head coordinates, [size] scales the shape.
/// [side] (-1/+1) draws one eye only (used for a wink).
void s2Eyes(Pen pen, Head h, S2Eye kind, {double gap = 21, double y = 0, double size = 1, Color? color, int? side}) {
  final sc = h.scale;
  final thick = 3.6 * sc * size.clamp(.8, 1.3);
  for (final s in const [-1, 1]) {
    if (side != null && s != side) continue;
    var k = kind;
    if (kind == S2Eye.wink) k = s == 1 ? S2Eye.happy : S2Eye.glow;
    final cx = s * gap;
    // canonical shapes are authored for the viewer-LEFT eye; mirror for the right one
    Path at(Path p) => h.path(p.transform(affine(-s.toDouble() * size, 0, 0, size, cx, y)), lift: 1.8);
    Path atRound(Path p) => h.path(p.transform(affine(size, 0, 0, size, cx, y)), lift: 1.8);
    switch (k) {
      case S2Eye.happy:
        pen.line(at(svg('M-9.5 3 C-6 -7 6 -7 9.5 3')), w: thick, color: Style.ink);
      case S2Eye.down:
        pen.line(at(svg('M-9.5 -1 C-6 8 6 8 9.5 -1')), w: thick, color: Style.ink);
        pen.line(at(svg('M-10 -1.5 L-12.5 -4')), w: thick * .55, color: Style.ink);
      case S2Eye.squint:
        pen.line(at(svg('M-9 -7 L7 0 L-9 7')), w: thick * 1.05, color: Style.ink);
      case S2Eye.stars:
        final st = atRound(s2Star(0, 0, 12.5));
        pen.solid(st, _gold, shade: 2.2 * sc, hi: 1.0 * sc, w: Style.lineThin * 1.1 * sc);
        pen.fill(h.path(circle(cx - 3 * size, y - 3.5 * size, 1.9 * size), lift: 2.2), const Color(0xFFFFFFFF));
      case S2Eye.money:
        final coin = atRound(circle(0, 0, 11.5));
        pen.solid(coin, _gold, shade: 2.6 * sc, hi: 1.1 * sc, w: Style.lineThin * 1.15 * sc);
        pen.line(atRound(circle(0, 0, 7.6)), w: Style.lineFine * sc, color: const Color(0xFFB87408));
        pen.line(atRound(svg('M0 -4.6 L0 4.6')), w: 2.0 * sc, color: const Color(0xFFB87408));
        pen.line(atRound(svg('M-2.8 -2.6 C0 -4.6 2.8 -3.6 2.8 -1.4 C2.8 1 -2.8 -1 -2.8 2 C-2.8 4.4 0 4.6 2.8 2.6')), w: 1.5 * sc, color: const Color(0xFFB87408));
        pen.fill(h.path(circle(cx - 4.4 * size, y - 4.6 * size, 1.5 * size), lift: 2.4), const Color(0xFFFFF6CC));
      case S2Eye.dizzy:
        final sp = Path();
        for (var i = 0; i <= 44; i++) {
          final t = i / 44, a = t * 2.3 * 2 * math.pi, r = 1.2 + t * 9.4;
          final x = math.cos(a) * r, yy = math.sin(a) * r;
          if (i == 0) {
            sp.moveTo(x, yy);
          } else {
            sp.lineTo(x, yy);
          }
        }
        pen.line(atRound(sp), w: 2.0 * sc, color: Style.ink);
      case S2Eye.hearts:
        final hp = atRound(svg('M0 9 C-14 -2 -11 -12 -5 -11 C-2 -10 0 -7 0 -7 C0 -7 2 -10 5 -11 C11 -12 14 -2 0 9 Z'));
        pen.solid(hp, const Tones(Color(0xFFFF4D6A), Color(0xFFC21E45), Color(0xFFFF9AAE)), shade: 2.2 * sc, hi: 1.0 * sc, w: Style.lineThin * sc);
        pen.fill(h.path(circle(cx - 4.4 * size, y - 6.6 * size, 1.5 * size), lift: 2.4), const Color(0xFFFFFFFF));
      case S2Eye.glow:
        final col = color ?? const Color(0xFFD8A8FF);
        pen.glow(h.pt(cx, y, lift: 2), 17 * sc, 14 * sc, col, alpha: .8);
        final eye = atRound(svg('M-12 0.5 C-12 -7 -5 -10 0 -10 C6 -10 12 -7 12 0.5 C12 7 6 10 0 10 C-5 10 -12 7 -12 0.5 Z'));
        pen.fill(eye, const Color(0xFFF7ECFF));
        pen.line(eye, w: Style.lineThin * 1.25 * sc, color: Style.ink);
        pen.fill(h.path(circle(cx + .5, y + .6, 5.4 * size), lift: 2.2), col);
        pen.fill(h.path(circle(cx + .5, y + .6, 2.6 * size), lift: 2.4), const Color(0xFFFFFFFF));
      case S2Eye.wink:
        break;
    }
  }
}

/// Tear streams running down both cheeks from the eyes (head coordinates).
void s2Tears(Pen pen, Head h, {double gap = 21, double y = 8, double len = 36, double w = 6.4, double fall = 4}) {
  final sc = h.scale;
  for (final s in const [-1, 1]) {
    final x0 = s * (gap + 1), y0 = y;
    final curve = svg('M$x0 $y0 C${x0 + s * fall * .2} ${y0 + len * .4} ${x0 + s * fall} ${y0 + len * .7} ${x0 + s * fall * 1.5} ${y0 + len}');
    final ribbon = taperedStroke(h.path(curve, lift: 2.6), w0: w * sc, w1: w * .55 * sc, bulge: w * .2 * sc);
    pen.fill(ribbon, const Color(0xFF8FD8FF));
    pen.line(ribbon, w: Style.lineThin * .9 * sc, color: Style.ink);
    pen.taper(h.path(svg('M${x0 - s * 1.2} ${y0 + 3} C${x0 - s * .6} ${y0 + len * .35} ${x0 + s * fall * .5} ${y0 + len * .55} ${x0 + s * fall * .9} ${y0 + len * .75}'), lift: 2.8), w0: 1.6 * sc, w1: .2 * sc, color: const Color(0xFFE8F8FF));
  }
}

/// A single tear drop (sweat / tear) at a global avatar-space point.
void s2Drop(Pen pen, Offset at, {double s = 1, double rot = 0, Color fill = const Color(0xFF8FD8FF)}) {
  final c = pen.c;
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(rot);
  c.scale(s, s);
  final d = svg('M0 -11 C4 -4 8 0 8 5 C8 10 4 13 0 13 C-4 13 -8 10 -8 5 C-8 0 -4 -4 0 -11 Z');
  pen.fill(d, fill);
  pen.crescent(d, shadeOf(fill, .2), depth: 2.6, dir: const Offset(0.6, 0.5));
  pen.line(d, w: Style.lineThin * 1.2, color: Style.ink);
  pen.fill(svg('M-3.6 2 C-4 5 -3 7.4 -1 8.6 C-1.8 6 -2 4 -1.4 1.6 Z'), const Color(0xFFFFFFFF));
  c.restore();
}
