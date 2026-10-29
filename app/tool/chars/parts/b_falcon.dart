// Worker B: a perched falcon (3/4 view, facing left) in the video's outlined cel-shaded style.
// Local frame: origin = the perch point under the feet, bird about 92 units tall, head towards -x.
import 'dart:math' as math;
import '../kit.dart';
import 'b_props.dart';

const falconBack = Tones(Color(0xFF7A5232), Color(0xFF4E321D), Color(0xFFA77A4E));
const falconCream = Tones(Color(0xFFF6EAD2), Color(0xFFD2BA98), Color(0xFFFFFAEC));
const _horn = Tones(Color(0xFF9FAEC4), Color(0xFF6B7A94), Color(0xFFD2DCEA));
const _yellow = Tones(Color(0xFFF4C53A), Color(0xFFC8921C), Color(0xFFFFE58A));

Path _t(String d, Offset at, double s, bool mirror) {
  final mx = mirror ? -1.0 : 1.0;
  return svg(d).transform(affine(s * mx, 0, 0, s, at.dx, at.dy));
}

/// Tail feathers hanging behind the perch (draw before the glove).
void bFalconTail(Pen pen, Offset at, double s, {bool mirror = false}) {
  Path P(String d) => _t(d, at, s, mirror);
  final tail = P('M-4 -14 C2 -6 8 8 10 30 C11 40 13 46 11 52 C8 56 0 55 -6 52 C-9 40 -10 20 -12 -6 Z');
  pen.solid(tail, falconBack, shade: 3.2 * s, hi: 1.2 * s, w: Style.line * .9 * s);
  pen.inside(tail, (q) {
    for (final y in const [14.0, 26.0, 38.0]) {
      q.line(P('M-12 $y C-4 ${y + 4} 4 ${y + 4} 12 $y'), w: 2.2 * s, color: const Color(0xFFD7B98A));
    }
    q.fill(P('M-8 47 C-2 50 6 50 12 46 L13 56 L-9 56 Z'), const Color(0xFFF6EAD2));
  });
  pen.line(tail, w: Style.line * .9 * s);
}

/// The bird itself (body, wing, head, beak, eye, toes). [lookAt] -1..1 nudges the pupil.
void bFalcon(Pen pen, Offset at, double s, {bool mirror = false, double lookX = -0.55, double lookY = 0.1}) {
  Path P(String d) => _t(d, at, s, mirror);
  final lw = Style.line * .9 * s;
  final fine = Style.lineThin * .85 * s;

  // silhouette of body + head
  final sil = P(
    'M-3 -90 C-11 -90 -17 -85 -19 -78 C-24 -78 -29 -75 -28 -69 C-25 -69 -22 -70 -20 -70 '
    'C-24 -60 -28 -46 -24 -30 C-21 -16 -15 -6 -9 -1 L12 -1 C22 -8 29 -28 26 -48 C24 -62 19 -75 13 -83 C9 -88 3 -90 -3 -90 Z',
  );
  pen.fill(sil, falconCream.base);
  pen.crescent(sil, falconCream.shade, depth: 4.5 * s, dir: const Offset(0.85, -0.2));
  pen.inside(sil, (q) {
    // crown / back of the head and nape (dark)
    q.fill(P('M-19 -81 C-17 -90 -4 -95 7 -90 C15 -86 18 -78 18 -70 C12 -66 8 -70 4 -76 C-4 -81 -12 -82 -19 -81 Z'), falconBack.base);
    q.fill(P('M-19 -81 C-17 -90 -4 -95 7 -90 C10 -88 12 -86 13 -84 C4 -87 -8 -86 -19 -81 Z'), falconBack.shade);
    // wing folded along the right side
    final wing = P('M2 -70 C14 -70 25 -56 27 -34 C28 -18 20 -4 10 2 C12 -14 10 -30 8 -44 C7 -56 4 -64 2 -70 Z');
    q.fill(wing, falconBack.base);
    q.crescent(wing, falconBack.shade, depth: 4 * s, dir: const Offset(0.8, -0.3));
    q.rim(wing, falconBack.hi, depth: 1.6 * s, dir: const Offset(-0.9, -0.2));
    // feather scallops on the wing
    for (var i = 0; i < 5; i++) {
      final y = -54.0 + i * 11;
      q.line(P('M${6 + i * .6} $y C${12 + i * .6} ${y + 6} ${20 - i * .8} ${y + 5} ${26 - i * .5} ${y - 1}'), w: fine * .9, color: withA(falconBack.shade, .95));
      q.line(P('M${6 + i * .6} ${y + 1.4} C${12 + i * .6} ${y + 7.4} ${20 - i * .8} ${y + 6.4} ${26 - i * .5} ${y + .4}'), w: fine * .55, color: withA(falconBack.hi, .75));
    }
    // chest streaks
    for (final st in const [
      [-20.0, -58.0, -14.0, -52.0],
      [-22.0, -48.0, -15.0, -43.0],
      [-12.0, -56.0, -8.0, -49.0],
      [-19.0, -37.0, -13.0, -33.0],
      [-10.0, -44.0, -6.0, -37.0],
      [-14.0, -27.0, -9.0, -22.0],
      [-5.0, -32.0, -2.0, -25.0],
      [-9.0, -16.0, -5.0, -11.0],
    ]) {
      q.taper(P('M${st[0]} ${st[1]} Q${(st[0] + st[2]) / 2 - 1} ${(st[1] + st[3]) / 2 + 2} ${st[2]} ${st[3]}'), w0: 2.6 * s, w1: 0.4 * s, color: const Color(0xFF8B5E3B));
    }
    // cheek: cream patch under the eye + dark malar stripe
    q.taper(P('M-12 -73 C-10 -67 -8 -62 -3 -58'), w0: 3.6 * s, w1: 0.6 * s, color: falconBack.shade);
    q.rim(sil, falconCream.hi, depth: 1.5 * s, dir: const Offset(-0.9, -0.3));
  });
  pen.line(sil, w: lw);

  // beak (horn) + yellow cere
  final beak = P('M-19 -79 C-25 -79 -30 -75 -29 -68 C-27 -70 -23 -71 -19 -70 Z');
  pen.solid(beak, _horn, shade: 1.6 * s, hi: .7 * s, w: lw * .9);
  pen.fill(P('M-19 -79 C-21 -79 -23 -78 -24.5 -76.5 L-21 -73.5 C-20 -74.5 -19.5 -75 -19 -75 Z'), _yellow.base);
  pen.line(P('M-19 -79 C-21 -79 -23 -78 -24.5 -76.5 L-21 -73.5 C-20 -74.5 -19.5 -75 -19 -75 Z'), w: fine * .8);
  pen.line(P('M-24 -71.5 L-21 -72.6'), w: fine * .7, color: withA(Style.ink, .8));

  // eye: amber iris, black pupil, highlights, heavy brow ridge
  final e = Offset(-11.5, -79.5);
  final eye = P('M${e.dx - 6} ${e.dy + .5} C${e.dx - 6} ${e.dy - 5} ${e.dx + 6} ${e.dy - 5.5} ${e.dx + 6.5} ${e.dy + .5} C${e.dx + 6} ${e.dy + 6} ${e.dx - 6} ${e.dy + 6} ${e.dx - 6} ${e.dy + .5} Z');
  pen.fill(eye, const Color(0xFFFFF6D8));
  pen.inside(eye, (q) {
    final ic = bHandPoint(at, 0, s, Offset(e.dx + lookX * 1.6, e.dy + lookY * 1.4), mirror: mirror);
    q.fill(circle(ic.dx, ic.dy, 4.0 * s), const Color(0xFFE29A1E));
    q.crescent(circle(ic.dx, ic.dy, 4.0 * s), const Color(0xFFB06A10), depth: 1.8 * s, dir: const Offset(0, 1));
    q.fill(circle(ic.dx, ic.dy, 2.2 * s), const Color(0xFF16101A));
    q.fill(circle(ic.dx - 1.2 * s, ic.dy - 1.3 * s, 1.1 * s), const Color(0xFFFFFFFF));
    q.fill(circle(ic.dx + 1.1 * s, ic.dy + 1.3 * s, .55 * s), withA(const Color(0xFFFFFFFF), .85));
    q.crescent(eye, const Color(0x40774400), depth: 1.8 * s, dir: const Offset(0, 1));
  });
  pen.line(eye, w: fine * 1.2);
  // brow ridge: a thick lid line slanting towards the beak = stern look
  pen.taper(P('M${e.dx + 8} ${e.dy - 4.6} C${e.dx + 3} ${e.dy - 8} ${e.dx - 4} ${e.dy - 7.5} ${e.dx - 8.5} ${e.dy - 1.5}'), w0: 3.4 * s, w1: 1.6 * s, color: Style.ink);

  // toes gripping the glove: three chunky toes with dark claws
  for (final x in const [-12.0, -4.0, 4.0, 11.0]) {
    final toe = P('M${x - 3} -3 C${x - 4} 2 ${x - 4.4} 6 ${x - 3.2} 9 L${x + 2.2} 9 C${x + 3} 6 ${x + 3} 2 ${x + 3} -3 Z');
    pen.solid(toe, _yellow, shade: 1.4 * s, hi: .6 * s, w: Style.lineThin * 1.15 * s);
    final claw = P('M${x - 3.4} 8.6 C${x - 3.6} 11 ${x - 2.4} 12.6 ${x - 1} 13.2 C${x - .6} 11.6 $x 10 ${x + 1.4} 8.6 Z');
    pen.shape(claw, const Color(0xFF3A2B33), w: Style.lineFine * s);
  }
  assert(math.pi > 3);
}
