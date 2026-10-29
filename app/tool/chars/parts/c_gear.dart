// Worker C: jewellery and regalia shared by the animated figures: crown, tiara, pearl
// necklace, gold chain with coin, forehead jewel. Everything is authored in head-local /
// neck-relative coordinates like the rest of the kit.
import 'dart:math' as math;
import '../kit.dart';
import 'c_rig.dart';

const goldT = Tones(Color(0xFFE3B341), Color(0xFFB07F1E), Color(0xFFF8DA82));
const rubyT = Tones(Color(0xFFD62F4B), Color(0xFF8E1630), Color(0xFFFF8A9A));
const sapphireT = Tones(Color(0xFF3F6FD6), Color(0xFF1F3F96), Color(0xFF8DB4FF));
const turquoiseT = Tones(Color(0xFF2FB9A6), Color(0xFF127A6E), Color(0xFF8CF0DC));
const pearlT = Tones(Color(0xFFFAF4EC), Color(0xFFC9BFD0), Color(0xFFFFFFFF));

/// A pearl: round, shaded, with a glint. [c] global centre, [r] radius.
void pearl(Pen pen, Offset c, double r, {Tones t = pearlT, double lw = 1.0}) {
  final p = circle(c.dx, c.dy, r);
  pen.fill(p, t.base);
  pen.crescent(p, t.shade, depth: r * .5, dir: const Offset(-0.5, -0.8));
  pen.line(p, w: Style.lineThin * .85 * lw, color: Style.ink);
  pen.fill(circle(c.dx - r * .32, c.dy - r * .36, r * .26), const Color(0xFFFFFFFF));
}

/// Points along a sagging chain between neck-relative x = -[half] .. [half]:
/// y = [top] at the ends and [top] + [sag] in the middle.
List<Offset> chainPoints(Head h, {double half = 34, double top = -2, double sag = 26, int n = 9, double dx = 0}) {
  final nb = h.neckBase;
  final out = <Offset>[];
  for (var i = 0; i <= n; i++) {
    final u = -1 + 2 * i / n;
    final x = u * half;
    final y = top + sag * (1 - u * u);
    out.add(Offset(nb.dx + dx + x * h.scale, nb.dy + y * h.scale));
  }
  return out;
}

/// Pearl necklace with a hanging drop pearl in a gold cap.
void drawPearlNecklace(Pen pen, Head h, {double half = 36, double top = 2, double sag = 24, int n = 9, double pr = 3.3, bool drop = true}) {
  final sc = h.scale;
  final pts = chainPoints(h, half: half, top: top, sag: sag, n: n);
  // thread
  pen.line(spline(pts), w: 1.1 * sc, color: Style.ink);
  for (final p in pts) {
    pearl(pen, p, pr * sc);
  }
  if (drop) {
    final c = pts[pts.length ~/ 2];
    final cap = poly([Offset(c.dx - 2.6 * sc, c.dy + pr * sc), Offset(c.dx + 2.6 * sc, c.dy + pr * sc), Offset(c.dx, c.dy + (pr + 4.2) * sc)]);
    pen.solid(cap, goldT, shade: 1, hi: .6, w: Style.lineThin * .85 * sc);
    pearl(pen, Offset(c.dx, c.dy + (pr + 8.4) * sc), 4.6 * sc);
  }
}

/// Heavy gold chain (alternating links) with a round coin pendant.
void drawGoldChain(Pen pen, Head h, {double half = 38, double top = -4, double sag = 30, int n = 14, double dx = 0, double coin = 9.5}) {
  final sc = h.scale;
  final pts = chainPoints(h, half: half, top: top, sag: sag, n: n, dx: dx);
  for (var i = 0; i < pts.length; i++) {
    final p = pts[i];
    final prev = pts[math.max(0, i - 1)], next = pts[math.min(pts.length - 1, i + 1)];
    final ang = math.atan2(next.dy - prev.dy, next.dx - prev.dx);
    final flat = i.isEven;
    final link = ellipse(p.dx, p.dy, (flat ? 5.6 : 3.6) * sc, (flat ? 3.5 : 4.4) * sc, rot: ang);
    pen.solid(link, goldT, shade: 1.3 * sc, hi: .8 * sc, w: Style.lineThin * 1.1 * sc);
    if (flat) pen.line(ellipse(p.dx, p.dy, 2.6 * sc, 1.3 * sc, rot: ang), w: Style.lineFine * .8 * sc, color: withA(Style.ink, .7));
  }
  final c = pts[pts.length ~/ 2];
  final cc = Offset(c.dx, c.dy + (coin + 1.5) * sc);
  final r = coin * sc;
  final disc = circle(cc.dx, cc.dy, r);
  pen.solid(disc, goldT, shade: 3 * sc, hi: 1.2 * sc, w: Style.line * .9 * sc);
  pen.line(circle(cc.dx, cc.dy, r * .72), w: Style.lineThin * .9 * sc, color: withA(Style.ink, .75));
  // embossed star
  final star = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rr = i.isEven ? r * .5 : r * .22;
    final q = Offset(cc.dx + rr * math.cos(a), cc.dy + rr * math.sin(a));
    if (i == 0) {
      star.moveTo(q.dx, q.dy);
    } else {
      star.lineTo(q.dx, q.dy);
    }
  }
  star.close();
  pen.fill(star, goldT.hi);
  pen.line(star, w: Style.lineFine * .8 * sc, color: withA(Style.ink, .8));
}

/// A crown worn over a hijab / turban: [peaks] points, gems on the band, pearls on the tips.
class Crown extends Headwear {
  const Crown({this.tones = goldT, this.top = -104, this.base = -48, this.width = 1.0, this.center = rubyT, this.side = sapphireT});

  final Tones tones;

  /// y (local) of the tallest tip, and of the band bottom at the centre.
  final double top, base;
  final double width;
  final Tones center, side;

  @override
  void back(Pen pen, Head h, Skin skin) {}

  @override
  void front(Pen pen, Head h, Skin skin) {
    final sc = h.scale;
    final w = width;
    final t = top, b = base;
    final h1 = t + 10; // inner tips
    final h2 = t + 20; // outer tips
    final v1 = t + 32; // valleys
    final path = h.path(
      svg(
        'M${-46 * w} ${b - 3} L${-48 * w} $h2 L${-35 * w} ${v1 + 2} L${-23 * w} $h1 L${-12 * w} $v1 L0 $t L${12 * w} $v1 L${23 * w} $h1 L${35 * w} ${v1 + 2} L${48 * w} $h2 L${46 * w} ${b - 3} '
        'C${30 * w} ${b + 4} ${-30 * w} ${b + 4} ${-46 * w} ${b - 3} Z',
      ),
      lift: 9,
    );
    pen.fill(path, tones.base);
    pen.crescent(path, tones.shade, depth: 6 * sc, dir: const Offset(-0.9, -0.3));
    pen.rim(path, tones.hi, depth: 2 * sc, dir: const Offset(-0.9, -0.4));
    // band: a darker strip along the bottom with a double line
    pen.inside(path, (p) {
      p.line(h.path(svg('M${-50 * w} ${b - 12} C${-30 * w} ${b - 5} ${30 * w} ${b - 5} ${50 * w} ${b - 12}'), lift: 9), w: Style.lineThin * sc, color: withA(Style.ink, .85));
      p.fill(h.path(svg('M${-50 * w} ${b - 12} C${-30 * w} ${b - 5} ${30 * w} ${b - 5} ${50 * w} ${b - 12} L${50 * w} ${b + 6} L${-50 * w} ${b + 6} Z'), lift: 9), withA(tones.shade, .5));
      // engraved scrolls on the points
      for (final s in const [-1, 1]) {
        p.line(h.path(svg('M${s * 23 * w} ${h1 + 8} C${s * 20 * w} ${v1 - 2} ${s * 24 * w} ${b - 18} ${s * 30 * w} ${b - 16}'), lift: 9), w: Style.lineFine * sc, color: withA(Style.ink, .55));
      }
      p.line(h.path(svg('M0 ${t + 10} C-3 ${v1 + 4} 3 ${b - 20} 0 ${b - 14}'), lift: 9), w: Style.lineFine * sc, color: withA(Style.ink, .55));
    });
    pen.line(path, w: Style.line * sc, color: Style.ink);
    // pearls on the tips
    for (final (x, y, r) in [(0.0, t - 1.0, 3.6), (-23.0 * w, h1 - 1.0, 3.2), (23.0 * w, h1 - 1.0, 3.2), (-48.0 * w, h2 - 1.0, 3.0), (48.0 * w, h2 - 1.0, 3.0)]) {
      pearl(pen, h.pt(x, y, z: 9), r * sc);
    }
    // gems on the band
    gem(pen, h.pt(0, b - 7, z: 11), 4.4 * sc, center, lw: sc);
    for (final s in const [-1, 1]) {
      gem(pen, h.pt(s * 22 * w, b - 6, z: 11), 3.3 * sc, side, lw: sc);
      pearl(pen, h.pt(s * 36 * w, b - 4, z: 10), 2.0 * sc);
    }
  }
}

/// A small tiara over a hijab: a thin arched band with three pointed gems.
class Tiara extends Headwear {
  const Tiara({this.tones = goldT, this.y = -52, this.width = 1.0});

  final Tones tones;

  /// y (local) of the band bottom at the centre.
  final double y;
  final double width;

  @override
  void back(Pen pen, Head h, Skin skin) {}

  @override
  void front(Pen pen, Head h, Skin skin) {
    final sc = h.scale;
    final w = width, b = y;
    final path = h.path(
      svg(
        'M${-30 * w} ${b + 1} C${-30 * w} ${b - 6} ${-27 * w} ${b - 12} ${-22 * w} ${b - 14} L${-14 * w} ${b - 24} L${-8 * w} ${b - 15} L0 ${b - 30} L${8 * w} ${b - 15} L${14 * w} ${b - 24} L${22 * w} ${b - 14} '
        'C${27 * w} ${b - 12} ${30 * w} ${b - 6} ${30 * w} ${b + 1} C${18 * w} ${b + 5} ${-18 * w} ${b + 5} ${-30 * w} ${b + 1} Z',
      ),
      lift: 9,
    );
    pen.fill(path, tones.base);
    pen.crescent(path, tones.shade, depth: 3.5 * sc, dir: const Offset(-0.9, -0.3));
    pen.rim(path, tones.hi, depth: 1.5 * sc, dir: const Offset(-0.9, -0.4));
    pen.line(path, w: Style.line * .95 * sc, color: Style.ink);
    pen.line(h.path(svg('M${-29 * w} ${b - 3} C${-16 * w} ${b + 1} ${16 * w} ${b + 1} ${29 * w} ${b - 3}'), lift: 9), w: Style.lineFine * sc, color: withA(Style.ink, .7));
    gem(pen, h.pt(0, b - 13, z: 11), 3.8 * sc, rubyT, lw: sc);
    for (final s in const [-1, 1]) {
      gem(pen, h.pt(s * 15 * w, b - 7, z: 11), 2.7 * sc, turquoiseT, lw: sc);
      pearl(pen, h.pt(s * 14 * w, b - 25, z: 9), 1.9 * sc);
    }
    pearl(pen, h.pt(0, b - 32, z: 9), 2.2 * sc);
  }
}

/// Gold embroidery for the emir's ghutra: a gold edging along the forehead hem, a small jewelled
/// brooch on the agal, and a thin gold line down each drape. Authored for `Ghutra(hem: -35)`.
void drawOrnateGhutra(Pen pen, Head h, Skin skin) {
  final sc = h.scale;
  const hem = -35.0;
  final hemCurve = spline(const [Offset(-52, hem + 8), Offset(-26, hem + 2), Offset(0, hem), Offset(26, hem + 2), Offset(52, hem + 8)], tension: .9);
  final p = h.path(hemCurve.shift(const Offset(0, 2.8)), lift: 6.5);
  pen.line(p, w: 3.2 * sc, color: Style.ink);
  pen.line(p, w: 1.7 * sc, color: goldT.base);
  // tiny gold studs on the edging
  for (final x in const [-40.0, -27.0, -14.0, 0.0, 14.0, 27.0, 40.0]) {
    final y = hem + 2.8 + (x.abs() < 26 ? 2 * (x.abs() / 26) : 2 + 6 * ((x.abs() - 26) / 26));
    final c = h.pt(x, y + 3.6, lift: 6.5);
    pen.fill(circle(c.dx, c.dy, 1.1 * sc), goldT.base);
  }
  gem(pen, h.pt(0, -43.5, lift: 8), 3.8 * sc, rubyT, lw: sc);
}
