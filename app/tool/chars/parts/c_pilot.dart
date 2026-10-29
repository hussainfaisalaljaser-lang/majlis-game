// Worker C: aviator gear: leather flight cap with fleece-lined ear flaps (headwear), brass
// goggles on a strap (rig layer), leather jacket with a fleece collar (body).
import 'dart:math' as math;
import 'dart:ui';

import '../kit.dart';

const leatherT = Tones(Color(0xFF93602F), Color(0xFF5E3A1C), Color(0xFFC08A52));
const jacketT = Tones(Color(0xFF7A4A26), Color(0xFF4B2B14), Color(0xFFA86F3E));
const fleeceT = Tones(Color(0xFFF1E6D2), Color(0xFFC5B39C), Color(0xFFFFFAEF));
const brassT = Tones(Color(0xFFC9962E), Color(0xFF8A5E15), Color(0xFFF0CB6C));

/// Little stitch dashes along a path.
void stitches(Pen pen, Path along, {double dash = 2.2, double gap = 2.2, Color color = const Color(0xFFE9C58C), double w = .8}) {
  for (final m in along.computeMetrics()) {
    var d = 0.0;
    while (d < m.length) {
      final seg = m.extractPath(d, math.min(m.length, d + dash));
      pen.line(seg, w: w, color: withA(color, .9));
      d += dash + gap;
    }
  }
}

/// Leather aviator cap with ear flaps (face stays open).
class AviatorCap extends Headwear {
  const AviatorCap({this.leather = leatherT, this.fleece = fleeceT});

  final Tones leather, fleece;

  static const double _lift = 6.5;

  @override
  void back(Pen pen, Head h, Skin skin) {}

  @override
  void front(Pen pen, Head h, Skin skin) {
    final sc = h.scale;
    // cap dome with the flap tongues hanging at the sides
    final cap = h.path(
      svg(
        'M-49 22 C-54 4 -52 -30 -44 -52 C-34 -72 -14 -78 0 -78 C14 -78 34 -72 44 -52 C52 -30 54 4 49 22 '
        'C46 28 38 30 33 24 C32 8 34 -12 28 -26 C16 -34 -16 -34 -28 -26 C-34 -12 -32 8 -33 24 C-38 30 -46 28 -49 22 Z',
      ),
      lift: _lift,
    );
    // soft shadow the cap casts on the forehead
    pen.inside(h.outline(), (p) => p.line(h.path(svg('M-30 -26 C-14 -34 14 -34 30 -26'), lift: _lift).shift(Offset(0, 3.4 * sc)), w: 6 * sc, color: withA(skin.shade, .9)));
    pen.fill(cap, leather.base);
    pen.crescent(cap, leather.shade, depth: 7 * sc, dir: const Offset(-0.9, -0.3));
    pen.rim(cap, leather.hi, depth: 2.2 * sc, dir: const Offset(-0.9, -0.5));
    pen.inside(cap, (p) {
      // glossy leather sheen
      p.taper(h.path(svg('M-38 -48 C-32 -62 -20 -70 -6 -73'), lift: _lift), w0: 3.4 * sc, w1: .3 * sc, color: withA(leather.hi, .95));
      // panel seams
      final seam = withA(Style.ink, .62);
      p.line(h.path(svg('M0 -78 C-2 -60 -2 -44 0 -32'), lift: _lift), w: Style.lineThin * sc, color: seam);
      p.line(h.path(svg('M-24 -74 C-34 -56 -34 -40 -28 -26'), lift: _lift), w: Style.lineThin * sc, color: seam);
      p.line(h.path(svg('M24 -74 C34 -56 34 -40 28 -26'), lift: _lift), w: Style.lineThin * sc, color: seam);
      // flap fold
      p.line(h.path(svg('M-47 -6 C-40 -4 -36 0 -33 6'), lift: _lift), w: Style.lineThin * sc, color: seam);
      p.line(h.path(svg('M47 -6 C40 -4 36 0 33 6'), lift: _lift), w: Style.lineThin * sc, color: seam);
    });
    stitches(pen, h.path(svg('M-2.6 -76 C-4.6 -60 -4.6 -44 -2.6 -34'), lift: _lift + .5));
    stitches(pen, h.path(svg('M-27 -26 C-33 -12 -31 8 -31 22'), lift: _lift + .5));
    stitches(pen, h.path(svg('M27 -26 C33 -12 31 8 31 22'), lift: _lift + .5));
    pen.line(cap, w: Style.line * sc, color: Style.ink);
    // fleece lining peeking out at the bottom of the flaps
    for (final s in const [-1, 1]) {
      final fl = h.path(
        svg('M${s * 48.5} 20 C${s * 51} 27 ${s * 47} 32 ${s * 42} 31 C${s * 41} 36 ${s * 36} 37 ${s * 34} 32 C${s * 33} 28 ${s * 33} 24 ${s * 33.5} 22 Z'),
        lift: _lift + .5,
      );
      pen.solid(fl, fleece, shade: 1.4 * sc, hi: .6 * sc, w: Style.lineThin * .95 * sc);
    }
    // strap under the chin is hidden; chin-strap buckle on the cheek
    for (final s in const [-1, 1]) {
      final b = h.pt(s * 41, 10, lift: _lift + 1);
      final buckle = Rect.fromCenter(center: b, width: 5.2 * sc, height: 4.2 * sc);
      pen.fill(Path()..addRRect(RRect.fromRectAndRadius(buckle, Radius.circular(1.2 * sc))), brassT.base);
      pen.line(Path()..addRRect(RRect.fromRectAndRadius(buckle, Radius.circular(1.2 * sc))), w: Style.lineFine * sc, color: Style.ink);
    }
  }
}

/// The rig layer `goggles`: brass goggles resting on the cap (strap round the cap), centred at
/// local y = [y]. The rig slides it down onto the eyes. [gap] = lens centre distance from the axis.
void drawGoggles(Pen pen, Head h, {double y = -46, double gap = 19, double r = 12.8, bool lensTint = true}) {
  final sc = h.scale;
  const lift = 12.0;
  // strap: a band around the head
  final strap = ring3D(h, y - 5, 49, 10, sag: 0, span: 82, lift: lift - 4);
  pen.fill(strap, leatherT.shade);
  pen.rim(strap, leatherT.base, depth: 1.8 * sc, dir: const Offset(-0.3, -1));
  pen.line(strap, w: Style.line * .85 * sc, color: Style.ink);
  // frame bridge
  final bridge = h.path(svg('M-8 ${y - 2} C-3 ${y - 5} 3 ${y - 5} 8 ${y - 2} L8 ${y + 3} C3 ${y + 1} -3 ${y + 1} -8 ${y + 3} Z'), lift: lift + 1);
  pen.solid(bridge, brassT, shade: 1, hi: .6, w: Style.lineThin * sc);
  for (final s in const [-1, 1]) {
    final c = h.pt(s * gap, y, lift: lift + 2);
    final rr = r * sc;
    // outer brass ring
    pen.fill(circle(c.dx, c.dy, rr + 3.0 * sc), brassT.base);
    pen.crescent(circle(c.dx, c.dy, rr + 3.0 * sc), brassT.shade, depth: 2.6 * sc);
    pen.rim(circle(c.dx, c.dy, rr + 3.0 * sc), brassT.hi, depth: 1.2 * sc);
    pen.line(circle(c.dx, c.dy, rr + 3.0 * sc), w: Style.line * .9 * sc, color: Style.ink);
    // lens
    final lens = circle(c.dx, c.dy, rr);
    pen.line(lens, w: 1.4 * sc, color: Style.ink);
    pen.fill(lens, const Color(0xFF8FD0F2));
    pen.inside(lens, (p) {
      p.crescent(lens, const Color(0xFF4F95C4), depth: rr * .5, dir: const Offset(-0.6, -0.8));
      p.glow(Offset(c.dx + rr * .2, c.dy + rr * .3), rr * .8, rr * .55, const Color(0xFFD8F3FF), alpha: .7);
      p.line(Path()..moveTo(c.dx - rr * .55, c.dy - rr * .15)..quadraticBezierTo(c.dx - rr * .45, c.dy - rr * .6, c.dx - rr * .05, c.dy - rr * .7), w: 2.2 * sc, color: const Color(0xFFFFFFFF));
      p.line(Path()..moveTo(c.dx + rr * .3, c.dy - rr * .55)..lineTo(c.dx + rr * .5, c.dy - rr * .35), w: 1.2 * sc, color: withA(const Color(0xFFFFFFFF), .8));
    });
    // rivets on the ring
    for (var i = 0; i < 4; i++) {
      final a = (i * 90 + 45) * math.pi / 180;
      final p = Offset(c.dx + (rr + 1.5 * sc) * math.cos(a), c.dy + (rr + 1.5 * sc) * math.sin(a));
      pen.fill(circle(p.dx, p.dy, .75 * sc), brassT.hi);
    }
  }
}

/// Leather jacket with a big fleece collar.
class PilotJacket extends Body {
  const PilotJacket({this.leather = jacketT, this.fleece = fleeceT});

  final Tones leather, fleece;

  @override
  void draw(Pen pen, Head h, Skin skin) {
    final dx = Body.turn(h);
    final sc = h.scale;
    final p = rel(h, shoulderPath, dx: dx);
    pen.solid(p, leather, shade: 8 * sc, hi: 2.4 * sc, dir: const Offset(-0.95, -0.35));
    pen.inside(p, (q) {
      q.taper(rel(h, 'M-50 20 C-44 50 -42 80 -46 112', dx: dx), w0: 2.6 * sc, w1: .3 * sc, color: withA(leather.shade, .95));
      q.taper(rel(h, 'M52 18 C46 50 48 82 44 112', dx: dx), w0: 2.6 * sc, w1: .3 * sc, color: withA(leather.shade, .95));
      q.taper(rel(h, 'M-76 34 C-70 50 -70 70 -74 92', dx: dx), w0: 1.8 * sc, w1: .2 * sc, color: withA(leather.hi, .8));
      // zipper line
      q.line(rel(h, 'M0 14 L0 120', dx: dx), w: Style.lineThin * sc, color: withA(Style.ink, .8));
      // shoulder strap + button
      q.line(rel(h, 'M-62 6 C-60 20 -58 30 -56 40', dx: dx), w: 2.6 * sc, color: leather.shade);
      q.line(rel(h, 'M62 6 C60 20 58 30 56 40', dx: dx), w: 2.6 * sc, color: leather.shade);
    });
    pen.line(p, w: Style.line * sc);
    // patch on the chest
    final patch = rel(h, 'M34 56 L58 56 L58 74 C58 80 50 84 46 86 C42 84 34 80 34 74 Z', dx: dx);
    pen.solid(patch, const Tones(Color(0xFFE3B341), Color(0xFFB07F1E), Color(0xFFF8DA82)), shade: 2 * sc, hi: 1 * sc, w: Style.lineThin * sc);
    final c = rel(h, 'M46 66 L46.01 66', dx: dx).getBounds().center;
    pen.fill(circle(c.dx, c.dy, 4.2 * sc), const Color(0xFF3C5E9E));
    pen.line(circle(c.dx, c.dy, 4.2 * sc), w: Style.lineFine * sc, color: Style.ink);
  }

  @override
  void drawFront(Pen pen, Head h, Skin skin) {
    final dx = Body.turn(h);
    final sc = h.scale;
    // fleece collar: a puffy scalloped ring around the neck
    final collar = rel(
      h,
      'M-31 -20 C-36 -10 -38 0 -32 8 C-34 14 -28 20 -22 16 C-18 22 -8 22 -4 17 C0 22 8 22 12 17 C18 22 28 20 24 14 C32 14 38 4 32 -6 C34 -12 32 -18 27 -22 C14 -12 -14 -12 -31 -20 Z',
      dx: dx,
    );
    pen.solid(collar, fleece, shade: 4 * sc, hi: 1.5 * sc, w: Style.line * .9 * sc);
    pen.inside(collar, (p) {
      for (final d in const ['M-26 -8 C-24 -2 -22 4 -20 9', 'M-12 -4 C-11 2 -10 8 -9 14', 'M6 -4 C6 2 7 8 8 14', 'M20 -6 C20 0 21 6 22 10']) {
        p.taper(rel(h, d, dx: dx), w0: 1.5 * sc, w1: .2 * sc, color: withA(fleece.shade, .95));
      }
    });
  }
}
