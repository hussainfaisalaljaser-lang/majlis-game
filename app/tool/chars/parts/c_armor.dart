// Worker C: knight gear: steel helmet with nasal bar + mail coif (headwear) and plate armour
// shoulders with a red tabard (body). Plus the plume (a separate rig layer painter).
import 'dart:math' as math;
import '../kit.dart';
import 'c_gear.dart';

const steelT = Tones(Color(0xFF9AA5B8), Color(0xFF626E85), Color(0xFFD3DBE8));
const mailT = Tones(Color(0xFF7F8A9E), Color(0xFF4F596D), Color(0xFFB3BDCE));
const tabardT = Tones(Color(0xFFC93A3A), Color(0xFF8A1F27), Color(0xFFEA6E68));

/// Rows of small interlocking rings painted inside [clip] (mail armour).
void mailRings(Pen pen, Path clip, {double step = 3.9, double r = 1.75, Color? ink, Color? light}) {
  final b = clip.getBounds();
  pen.inside(clip, (p) {
    final dark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55
      ..color = withA(Style.ink, .42)
      ..isAntiAlias = true;
    final lite = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = withA(light ?? const Color(0xFFE6ECF6), .45)
      ..isAntiAlias = true;
    var row = 0;
    for (var y = b.top; y < b.bottom + step; y += step * .62) {
      final off = row.isOdd ? step / 2 : 0.0;
      for (var x = b.left - step + off; x < b.right + step; x += step) {
        p.c.drawArc(Rect.fromCircle(center: Offset(x, y), radius: r), math.pi * .1, math.pi * .8, false, dark);
        p.c.drawArc(Rect.fromCircle(center: Offset(x, y - .5), radius: r), math.pi * 1.1, math.pi * .7, false, lite);
      }
      row++;
    }
  });
}

/// Steel kettle helmet over a mail coif. The face stays open (nasal bar only).
class KnightHelm extends Headwear {
  const KnightHelm({this.steel = steelT, this.mail = mailT});

  final Tones steel, mail;

  static const double _lift = 7.0;

  Path _coif(Head h) => h.path(
    spline(const [
      Offset(0, -70),
      Offset(30, -66),
      Offset(52, -34),
      Offset(58, 0),
      Offset(60, 36),
      Offset(66, 64),
      Offset(80, 90),
      Offset(60, 100),
      Offset(0, 104),
      Offset(-60, 100),
      Offset(-80, 90),
      Offset(-66, 64),
      Offset(-60, 36),
      Offset(-58, 0),
      Offset(-52, -34),
      Offset(-30, -66),
    ], closed: true, tension: .95),
    lift: 4.5,
  );

  @override
  void back(Pen pen, Head h, Skin skin) {
    final sc = h.scale;
    final coif = _coif(h);
    pen.fill(coif, mail.base);
    pen.crescent(coif, mail.shade, depth: 8 * sc, dir: const Offset(-0.9, -0.35));
    pen.rim(coif, mail.hi, depth: 2 * sc, dir: const Offset(-0.9, -0.4));
    mailRings(pen, coif);
    pen.line(coif, w: Style.line * sc, color: Style.ink);
  }

  @override
  void front(Pen pen, Head h, Skin skin) {
    final sc = h.scale;
    // soft shadow of the helmet rim on the forehead
    final dome = h.path(
      svg(
        'M-50 -10 C-55 -40 -44 -66 -22 -76 C-8 -82 8 -82 22 -76 C44 -66 55 -40 50 -10 '
        'C47 -22 43 -30 36 -34 C20 -40 -20 -40 -36 -34 C-43 -30 -47 -22 -50 -10 Z',
      ),
      lift: _lift,
    );
    final brim = svg('M-48 -14 C-45 -24 -42 -30 -36 -34 C-20 -40 20 -40 36 -34 C42 -30 45 -24 48 -14');
    pen.inside(h.outline(), (p) => p.line(h.path(brim, lift: _lift).shift(Offset(0, 3.6 * sc)), w: 6 * sc, color: withA(skin.shade, .9)));
    pen.fill(dome, steel.base);
    pen.crescent(dome, steel.shade, depth: 8 * sc, dir: const Offset(-0.9, -0.3));
    pen.rim(dome, steel.hi, depth: 2.4 * sc, dir: const Offset(-0.9, -0.5));
    pen.inside(dome, (p) {
      // glossy sweep + engraved ridge lines
      p.taper(h.path(svg('M-40 -50 C-34 -62 -22 -72 -8 -76'), lift: _lift), w0: 3.2 * sc, w1: .3 * sc, color: withA(steel.hi, .95));
      p.taper(h.path(svg('M-30 -44 C-26 -52 -20 -58 -12 -62'), lift: _lift), w0: 1.6 * sc, w1: .2 * sc, color: withA(const Color(0xFFFFFFFF), .7));
      // centre ridge
      final ridge = h.path(svg('M-4.2 -80 L4.2 -80 L5 -36 L-5 -36 Z'), lift: _lift + 1.5);
      p.fill(ridge, steel.hi);
      p.crescent(ridge, steel.shade, depth: 1.8 * sc, dir: const Offset(0.9, 0));
      p.line(ridge, w: Style.lineThin * sc, color: Style.ink);
      for (final y in const [-72.0, -60.0, -48.0]) {
        final c = h.pt(0, y, lift: _lift + 2.5);
        p.fill(circle(c.dx, c.dy, 1.2 * sc), steel.shade);
      }
    });
    pen.line(dome, w: Style.line * sc, color: Style.ink);
    // rolled brim
    final rim = h.path(brim, lift: _lift + 0.5);
    pen.line(rim, w: 4.2 * sc, color: Style.ink);
    pen.line(rim, w: 2.4 * sc, color: steel.hi);
    // gold plume socket on top
    final cup = h.path(svg('M-7 -80 L7 -80 L5 -74 L-5 -74 Z'), lift: _lift + 2);
    pen.solid(cup, goldT, shade: 1.2 * sc, hi: .7 * sc, w: Style.lineThin * sc);
    // nasal bar
    final nasal = h.path(svg('M-3.6 -35 L3.6 -35 L2.8 4 C2.4 9 -2.4 9 -2.8 4 Z'), lift: 11);
    pen.fill(nasal, steel.base);
    pen.crescent(nasal, steel.shade, depth: 1.6 * sc, dir: const Offset(0.9, 0));
    pen.rim(nasal, steel.hi, depth: .9 * sc, dir: const Offset(-0.9, 0));
    pen.line(nasal, w: Style.lineThin * 1.1 * sc, color: Style.ink);
    final r = h.pt(0, -28, lift: 12.5);
    pen.fill(circle(r.dx, r.dy, 1.3 * sc), steel.shade);
  }
}

/// Plate armour: steel shoulders (pauldrons), a mail collar, and a red tabard down the chest.
class KnightArmor extends Body {
  const KnightArmor({this.steel = steelT, this.tabard = tabardT});

  final Tones steel, tabard;

  @override
  void draw(Pen pen, Head h, Skin skin) {
    final dx = Body.turn(h);
    final sc = h.scale;
    final base = rel(h, shoulderPath, dx: dx);
    pen.solid(base, mailT, shade: 8 * sc, hi: 2.4 * sc, dir: const Offset(-0.95, -0.35));
    mailRings(pen, base);
    pen.line(base, w: Style.line * sc);
    // tabard
    final tab = rel(h, 'M-30 6 C-16 14 16 14 30 6 L38 120 L-38 120 Z', dx: dx);
    pen.solid(tab, tabard, shade: 6 * sc, hi: 1.8 * sc, dir: const Offset(-0.95, -0.3));
    pen.inside(tab, (p) {
      p.taper(rel(h, 'M-12 18 C-14 50 -16 84 -18 118', dx: dx), w0: 2.2 * sc, w1: .3 * sc, color: withA(tabard.shade, .95));
      p.taper(rel(h, 'M14 18 C16 50 18 84 20 118', dx: dx), w0: 2.2 * sc, w1: .3 * sc, color: withA(tabard.shade, .95));
    });
    pen.line(rel(h, 'M-30 6 L-38 120', dx: dx), w: 3.2 * sc, color: Style.ink);
    pen.line(rel(h, 'M-30 6 L-38 120', dx: dx), w: 1.7 * sc, color: goldT.base);
    pen.line(rel(h, 'M30 6 L38 120', dx: dx), w: 3.2 * sc, color: Style.ink);
    pen.line(rel(h, 'M30 6 L38 120', dx: dx), w: 1.7 * sc, color: goldT.base);
    // pauldrons
    for (final s in const [-1, 1]) {
      final plate = rel(h, 'M${s * 30} -8 C${s * 56} -14 ${s * 90} 0 ${s * 104} 40 C${s * 108} 56 ${s * 104} 70 ${s * 100} 80 C${s * 88} 52 ${s * 60} 36 ${s * 32} 30 Z', dx: dx);
      pen.solid(plate, steel, shade: 5 * sc, hi: 2 * sc, dir: const Offset(-0.9, -0.4));
      pen.inside(plate, (p) {
        p.taper(rel(h, 'M${s * 40} -2 C${s * 62} -4 ${s * 84} 8 ${s * 96} 34', dx: dx), w0: 3 * sc, w1: .3 * sc, color: withA(steel.hi, .95));
        p.line(rel(h, 'M${s * 34} 22 C${s * 62} 28 ${s * 88} 46 ${s * 98} 72', dx: dx), w: Style.lineThin * sc, color: withA(Style.ink, .7));
      });
      for (final (x, y) in const [(58.0, 6.0), (82.0, 22.0)]) {
        final p = rel(h, 'M${s * x} $y L${s * x + .01} $y', dx: dx).getBounds().center;
        pen.fill(circle(p.dx, p.dy, 1.7 * sc), steel.hi);
        pen.line(circle(p.dx, p.dy, 1.7 * sc), w: Style.lineFine * sc, color: Style.ink);
      }
    }
  }

  @override
  void drawFront(Pen pen, Head h, Skin skin) {
    final dx = Body.turn(h);
    final sc = h.scale;
    // gorget: steel collar ring at the neck
    final ring = rel(h, 'M-27 -16 C-28 -6 -26 4 -21 11 C-9 19 9 19 21 11 C26 4 28 -6 27 -16 C14 -9 -14 -9 -27 -16 Z', dx: dx);
    pen.solid(ring, steel, shade: 3 * sc, hi: 1.4 * sc, w: Style.lineThin * 1.3 * sc);
    pen.line(rel(h, 'M-21 3 C-9 10 9 10 21 3', dx: dx), w: Style.lineFine * sc, color: withA(Style.ink, .6));
  }
}

/// The helmet plume (rig layer `plume`): a red horsehair crest rising from the socket at
/// global [base], arching backwards. Painted in global 200-space coordinates.
void drawPlume(Pen pen, Offset base, {double scale = 1.0, int dir = 1, Tones t = tabardT}) {
  Path P(String d) => xform(svg(d), sx: scale * dir, sy: scale, tx: base.dx, ty: base.dy);
  final plume = P('M-5 4 C-8 -10 -2 -24 10 -34 C20 -42 34 -42 42 -36 C34 -34 30 -30 32 -24 C36 -26 40 -24 42 -20 C34 -16 28 -10 26 -4 C28 -4 30 -2 30 0 C22 2 14 8 6 8 C2 8 -4 8 -5 4 Z');
  pen.fill(plume, t.base);
  pen.crescent(plume, t.shade, depth: 5 * scale, dir: const Offset(0.5, 0.8));
  pen.rim(plume, t.hi, depth: 1.8 * scale, dir: const Offset(-0.5, -0.8));
  pen.inside(plume, (p) {
    for (final d in const [
      'M-2 4 C-2 -8 4 -20 14 -28',
      'M4 6 C6 -6 12 -16 22 -24',
      'M10 6 C14 -4 20 -12 30 -18',
      'M16 4 C20 -2 26 -6 34 -10',
    ]) {
      p.taper(P(d), w0: 1.8 * scale, w1: .2 * scale, color: withA(t.shade, .9));
    }
    p.taper(P('M2 -2 C6 -16 16 -28 28 -34'), w0: 1.4 * scale, w1: .2 * scale, color: withA(t.hi, .9));
  });
  pen.line(plume, w: Style.line * .9 * scale, color: Style.ink);
}
