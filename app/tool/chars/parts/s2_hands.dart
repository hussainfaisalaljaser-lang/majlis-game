// Hands + sleeves for the stickers (worker S2): open palm, fist, thumbs-up, pointing, praying.
// A hand is authored in its own frame (origin = wrist centre, fingers point UP, about 46 units tall)
// and placed with [at], [rot] (radians, clockwise) and [size]; [mirror] flips it left-right.
import 'dart:math' as math;
import 'dart:ui';

import '../core/palette.dart';
import '../core/pen.dart';

enum S2Pose { open, fist, thumbUp, point, vee, pray, flat }

/// A capsule whose base centre is (x,y) and that points up by [len] (rotated by [rot] about the base).
Path s2Capsule(double x, double y, double len, double w, double rot) {
  final p = Path()..addRRect(RRect.fromLTRBR(-w / 2, -len, w / 2, w * 0.5, Radius.circular(w / 2)));
  final cs = math.cos(rot), sn = math.sin(rot);
  return p.transform(affine(cs, sn, -sn, cs, x, y));
}

Path _union(List<Path> ps) {
  var out = ps.first;
  for (final p in ps.skip(1)) {
    out = Path.combine(PathOperation.union, out, p);
  }
  return out;
}

/// Light direction in the hand's own frame (so the shading stays upper-left on screen).
Offset _localLight(double rot, bool mirror) {
  const g = Style.light;
  final cs = math.cos(-rot), sn = math.sin(-rot);
  var x = g.dx * cs - g.dy * sn, y = g.dx * sn + g.dy * cs;
  if (mirror) x = -x;
  return Offset(x, y);
}

/// Draw a hand. [skin] gives the tones; [at] is the wrist centre in avatar space.
void s2Hand(Pen pen, Skin skin, S2Pose pose, Offset at, {double rot = 0, double size = 1, bool mirror = false}) {
  final c = pen.c;
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(rot);
  c.scale(mirror ? -size : size, size);
  final dir = _localLight(rot, mirror);
  final lw = Style.line * 0.82;
  final fine = Style.lineFine * 0.9;
  final crease = withA(skin.deep, .85);
  void solid(Path p, {double shade = 2.4, double w = -1}) => pen.solid(p, skin.tones, shade: shade, hi: 0.9, w: w < 0 ? lw : w, dir: dir);

  switch (pose) {
    case S2Pose.open:
    case S2Pose.flat:
      final palm = svg('M-10.5 8 C-12.5 -4 -13 -14 -11.5 -23 L11.5 -23 C13 -14 12.5 -4 10.5 8 Z');
      final fingers = [
        s2Capsule(-8.4, -20, 17, 5.6, -0.2),
        s2Capsule(-2.8, -22, 20.5, 5.6, -0.06),
        s2Capsule(2.9, -22, 18.5, 5.6, 0.07),
        s2Capsule(8.4, -20, 14.5, 5.4, 0.22),
        s2Capsule(-9, -6, 15.5, 6.6, -0.95),
      ];
      final hand = _union([palm, ...fingers]);
      solid(hand);
      pen.inside(hand, (q) {
        for (final x in const [-5.6, 0.0, 5.6]) {
          q.line(svg('M${x * 1.05} -26 L${x * .9} -17'), w: fine, color: crease);
        }
        q.line(svg('M-8.5 -9 C-4 -8 -2 -3 -3 4'), w: fine, color: crease);
      });
    case S2Pose.fist:
      final thumb = svg('M-12.5 -4 C-14 -10 -7 -12 3 -11 C8 -10 9 -5 5 -2 C0 1.5 -9 2 -12.5 -4 Z');
      final blob = svg('M-12.5 -1 C-14.5 -13 -9 -23 1 -23 C11 -23 15 -14 13.5 -3 C12.5 6 -9 8 -12.5 -1 Z');
      solid(blob);
      pen.inside(blob, (q) {
        for (final x in const [-6.0, 0.0, 6.4]) {
          q.line(svg('M$x -22 C${x + 1} -17 ${x + 1} -13 $x -9'), w: fine, color: crease);
        }
      });
      solid(thumb, shade: 1.6, w: lw * .9);
    case S2Pose.thumbUp:
      final tb = svg('M-10 -12 C-12.5 -22 -12.5 -33 -9 -41 C-6.5 -46 0 -46 1.5 -40 C3 -33 1 -26 4 -19 Z');
      solid(tb, shade: 2.0);
      pen.line(svg('M-9 -37 C-6 -39 -3 -39 -1 -37'), w: fine, color: crease);
      final blob = svg('M-13 -2 C-15 -11 -11 -20 0 -20 C11 -20 15.5 -13 14 -3 C13 6 -10 8 -13 -2 Z');
      solid(blob);
      pen.inside(blob, (q) {
        for (final x in const [-4.0, 2.4, 8.0]) {
          q.line(svg('M$x -19 C${x + 1} -14 ${x + 1} -10 $x -6'), w: fine, color: crease);
        }
      });
    case S2Pose.point:
      final idx = s2Capsule(3.4, -14, 29, 6.2, 0.04);
      solid(idx, shade: 2.0);
      pen.line(svg('M1.5 -36 C3.5 -37.5 5.5 -37.5 7 -36'), w: fine, color: crease);
      final blob = svg('M-12 -1 C-14 -9 -10 -16 -1 -16 C9 -16 14 -11 13.5 -3 C12.5 6 -9 8 -12 -1 Z');
      solid(blob);
      pen.inside(blob, (q) {
        for (final x in const [-5.0, 0.0]) {
          q.line(svg('M$x -15 C${x + 1} -11 ${x + 1} -8 $x -5'), w: fine, color: crease);
        }
      });
      final thumb = svg('M-12 -5 C-13 -9 -7 -10 0 -9 C4 -8 5 -4 2 -2 C-3 1 -10 1 -12 -5 Z');
      solid(thumb, shade: 1.4, w: lw * .9);
    case S2Pose.vee:
      final i1 = s2Capsule(-3.8, -14, 30, 5.8, -0.1);
      final i2 = s2Capsule(3.6, -14, 28, 5.8, 0.12);
      solid(_union([i1, i2]), shade: 2.0);
      pen.line(svg('M0 -16 L0 -9'), w: fine, color: crease);
      final blob = svg('M-12 -1 C-14 -9 -10 -16 -1 -16 C9 -16 14 -11 13.5 -3 C12.5 6 -9 8 -12 -1 Z');
      solid(blob);
      pen.inside(blob, (q) {
        q.line(svg('M5 -15 C6 -11 6 -8 5 -5'), w: fine, color: crease);
        q.line(svg('M9.6 -13 C10.6 -10 10.6 -7 9.6 -4'), w: fine, color: crease);
      });
      final thumb = svg('M-12 -5 C-13 -9 -7 -10 0 -9 C4 -8 5 -4 2 -2 C-3 1 -10 1 -12 -5 Z');
      solid(thumb, shade: 1.4, w: lw * .9);
    case S2Pose.pray:
      final back = svg('M2 8 C-10 5 -13 -12 -6 -26 C-3 -33 -1 -39 1 -44 C3 -39 6 -33 9 -26 C16 -12 13 4 2 8 Z');
      final front = svg('M-2 8 C-14 5 -17 -12 -10 -26 C-7 -33 -4 -39 -2 -44 C0 -39 3 -33 6 -26 C13 -12 10 4 -2 8 Z');
      solid(back, shade: 3.2);
      solid(front, shade: 1.6);
      pen.line(svg('M-2 -43 C-2.6 -30 -2.6 -12 -2 6'), w: lw * .8, color: withA(Style.ink, .9));
      pen.line(svg('M-8 -27 C-6 -28 -4 -28 -2.4 -27'), w: fine, color: crease);
      pen.line(svg('M-9 -19 C-6 -20 -4 -20 -2.4 -19'), w: fine, color: crease);
  }
  c.restore();
}

/// A sleeve (thobe arm) running from [from] (usually off-canvas below) to the wrist at [to], with a cuff.
void s2Arm(Pen pen, Offset from, Offset to, {double w = 24, Tones cloth = Cloth.white, bool cuff = true}) {
  final dir = to - from;
  final len = dir.distance;
  if (len < 1) return;
  final u = dir / len;
  final n = Offset(-u.dy, u.dx);
  final body = poly([from + n * (w / 2 + 3), to + n * (w / 2 - 1), to - n * (w / 2 - 1), from - n * (w / 2 + 3)]);
  pen.solid(body, cloth, shade: 4.6, hi: 1.4, w: Style.line * .85, dir: const Offset(-0.9, -0.2));
  pen.inside(body, (q) {
    q.taper(Path()..moveTo(from.dx + n.dx * 3, from.dy + n.dy * 3)..lineTo(to.dx + n.dx * 2.6 - u.dx * 8, to.dy + n.dy * 2.6 - u.dy * 8), w0: 2.2, w1: 0.2, color: withA(cloth.shade, .95));
  });
  if (!cuff) return;
  final a = to + n * (w / 2 - 1), b = to - n * (w / 2 - 1);
  pen.line(Path()..moveTo(a.dx - u.dx * 6, a.dy - u.dy * 6)..lineTo(b.dx - u.dx * 6, b.dy - u.dy * 6), w: Style.lineThin * .9, color: withA(cloth.shade, .95));
}
