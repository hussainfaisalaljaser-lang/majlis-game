// Headwear: ghutra + agal, shemagh, hijab (+ under-cap), turban, taqiyah cap,
// face veil (niqab / shemagh mask). Every headwear has a BACK part (drawn behind
// the face: cloth mass + drapes) and a FRONT part (drawn over the face: forehead
// hem, agal, hijab edge, veil). Combine several with [HeadwearStack].
//
// All shapes are authored in the head's local front-view coordinates and warped
// through [Head.path], so they follow yaw. Use [Head.absYaw] / [Head.side] to
// adapt volumes (e.g. a turned head shows more cloth on the back side and the
// drape on the face side hides behind the cheek).
import 'dart:math' as math;
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';

abstract class Headwear {
  const Headwear();

  /// Behind the face (cloth mass, drapes). Drawn after the body.
  void back(Pen pen, Head h, Skin skin);

  /// Over the face (forehead hem, agal, edges, veils).
  void front(Pen pen, Head h, Skin skin);
}

/// Several headwear pieces drawn in order (e.g. a face veil, then a turban on top).
class HeadwearStack extends Headwear {
  const HeadwearStack(this.parts);

  final List<Headwear> parts;

  @override
  void back(Pen pen, Head h, Skin skin) {
    for (final p in parts) {
      p.back(pen, h, skin);
    }
  }

  @override
  void front(Pen pen, Head h, Skin skin) {
    for (final p in parts) {
      p.front(pen, h, skin);
    }
  }
}

// ───────────────────────────── shared helpers ─────────────────────────────

/// Red/white check pattern (shemagh) painted inside [clip].
void checkPattern(Pen pen, Path clip, {Color color = const Color(0xFFC8262E), double cell = 6.5, double rot = 0.7854, double alpha = .95}) {
  pen.inside(clip, (p) {
    final b = clip.getBounds();
    final c = b.center;
    final r = math.max(b.width, b.height) * .8;
    p.c.save();
    p.c.translate(c.dx, c.dy);
    p.c.rotate(rot);
    final n = (r / cell).ceil();
    for (var i = -n; i <= n; i++) {
      for (var j = -n; j <= n; j++) {
        if ((i + j) % 2 == 0) {
          p.c.drawRect(Rect.fromLTWH(i * cell, j * cell, cell, cell), Paint()..color = withA(color, alpha));
        }
      }
    }
    p.c.restore();
  });
}

/// A band that wraps the head at height [y0] on a horizontal circle of radius [r]
/// (true 3D: it follows yaw). [sag] lifts the front of the ring (seen from slightly
/// below, like the video's agal); [tilt] rolls the ring (radians); [span] is the
/// visible half-angle in degrees.
Path ring3D(Head h, double y0, double r, double thick, {double sag = 5, double tilt = 0, double span = 76, double lift = 0}) {
  final top = <Offset>[], bot = <Offset>[];
  const n = 18;
  for (var i = 0; i <= n; i++) {
    final th = (-span + 2 * span * i / n) * math.pi / 180;
    final x = r * math.sin(th);
    final z = r * math.cos(th);
    final zn = math.cos(th);
    final taper = i == 0 || i == n ? 0.55 : (i == 1 || i == n - 1 ? 0.85 : 1.0);
    final yy = y0 - sag * zn + tilt * x * 0.9;
    top.add(h.pt(x, yy, z: z + lift));
    bot.add(h.pt(x, yy + thick * taper, z: z + lift));
  }
  return spline([...top, ...bot.reversed], closed: true, tension: .9);
}

/// Region above an open curve (local coordinates), closed upwards.
Path regionAbove(Head h, Path curveLocal, {double lift = 0, double up = 70}) {
  final warped = h.path(curveLocal, lift: lift);
  final m = warped.computeMetrics().first;
  final a = m.getTangentForOffset(0)!.position;
  final b = m.getTangentForOffset(m.length)!.position;
  return Path.from(warped)
    ..lineTo(b.dx + 6 * h.scale, b.dy - up * h.scale)
    ..lineTo(a.dx - 6 * h.scale, a.dy - up * h.scale)
    ..close();
}

/// Region below an open curve (local coordinates), closed downwards.
Path regionBelow(Head h, Path curveLocal, {double lift = 0, double down = 120}) {
  final warped = h.path(curveLocal, lift: lift);
  final m = warped.computeMetrics().first;
  final a = m.getTangentForOffset(0)!.position;
  final b = m.getTangentForOffset(m.length)!.position;
  return Path.from(warped)
    ..lineTo(b.dx + 6 * h.scale, b.dy + down * h.scale)
    ..lineTo(a.dx - 6 * h.scale, a.dy + down * h.scale)
    ..close();
}

/// Cloth paint job shared by every headwear: fill, shadow crescent, rim, check, outline.
void paintCloth(Pen pen, Path p, Tones t, double sc, {double shade = 6.5, double hi = 2.2, bool outline = true, Color? check, Offset dir = const Offset(-0.9, -0.4)}) {
  pen.fill(p, t.base);
  pen.crescent(p, t.shade, depth: shade * sc, dir: dir);
  pen.rim(p, t.hi, depth: hi * sc, dir: dir);
  if (check != null) checkPattern(pen, p, color: check, cell: 6 * sc);
  if (outline) pen.line(p, w: Style.line * sc, color: Style.ink);
}

// ───────────────────────────── ghutra + agal ─────────────────────────────

class Ghutra extends Headwear {
  const Ghutra({
    this.cloth = Cloth.white,
    this.agal = true,
    this.agalTones = Cloth.agal,
    this.check,
    this.hem = -34.0,
    this.hemTilt = 0.0,
    this.drape = 1.0,
    this.agalY = -50.0,
    this.agalSag = 6.0,
    this.agalRings = 2,
    this.agalTilt = 0.0,
    this.top = -76.0,
    this.width = 1.0,
    this.dropY = 88.0,
    this.swept = false,
  });

  final Tones cloth;
  final bool agal;
  final Tones agalTones;

  /// Red check colour for a shemagh (null = plain ghutra).
  final Color? check;

  /// y of the cloth hem across the forehead (local) and its tilt (radians).
  final double hem, hemTilt;

  /// Length multiplier of the drape over the shoulders (1 = normal).
  final double drape;
  final double agalY, agalSag;
  final int agalRings;

  /// Radians; tilts the agal ring (swept / cocky ghutra style).
  final double agalTilt;

  /// y of the top of the dome and a width multiplier.
  final double top, width;

  /// y (local) where the drapes end on the shoulders.
  final double dropY;

  /// Cocky swept style for turned heads: the cloth is pulled back over the far side.
  final bool swept;

  static const double _lift = 6.5;

  /// Right-half outline points (top centre -> hem corner -> behind the neck).
  List<Offset> _half() => [
    Offset(0, top),
    Offset(24, top + 5),
    Offset(41, top + 19),
    Offset(50, top + 40),
    Offset(54, top + 63),
    Offset(56, 14),
    Offset(59, 40),
    Offset(65, 64),
    Offset(70, dropY - 8),
    Offset(70, dropY + 2),
    Offset(58, dropY + 8),
    Offset(38, dropY + 6),
    Offset(18, dropY + 3),
    Offset(0, dropY),
  ];

  /// Swept outline (back of the head = +x); mirrored when the head turns the other way.
  List<Offset> _sweptPts() => [
    const Offset(-50, -22),
    Offset(-55, top + 38),
    Offset(-47, top + 20),
    Offset(-26, top + 9),
    Offset(2, top + 2),
    Offset(30, top - 6),
    Offset(54, top - 4),
    Offset(72, top + 12),
    Offset(81, top + 38),
    const Offset(82, -2),
    const Offset(81, 28),
    Offset(78, dropY - 28),
    Offset(72, dropY - 6),
    Offset(60, dropY + 10),
    Offset(50, dropY + 6),
    Offset(46, dropY - 6),
    const Offset(36, 56),
    const Offset(10, 72),
    const Offset(-20, 62),
    const Offset(-42, 34),
    const Offset(-50, 6),
  ];

  Path _outer(Head h) {
    final ay = h.absYaw.clamp(0.0, 1.0);
    final lead = h.side;
    if (swept && lead != 0) {
      final k = lead > 0 ? -1.0 : 1.0; // back of the head is opposite to the turn
      final pts = [for (final p in _sweptPts()) Offset(p.dx * k * (1 + 0.0 * ay), p.dy)];
      return h.path(spline(pts, closed: true, tension: .95), lift: _lift);
    }
    final half = _half();
    double f(int sgn, double y) {
      final t = smoothstep(-40, 20, y);
      final leadF = lerpD(1.0, 1 - 0.46 * ay, t);
      final backF = lerpD(1 + 0.10 * ay, 1 + 0.26 * ay, t);
      if (lead == 0) return 1;
      return sgn == lead ? leadF : backF;
    }

    final right = <Offset>[for (final p in half) Offset(p.dx * width * f(1, p.dy), p.dy)];
    final left = <Offset>[for (final p in half) Offset(-p.dx * width * f(-1, p.dy), p.dy)];
    final all = <Offset>[...right, ...left.reversed.skip(1).take(left.length - 2)];
    return h.path(spline(all, closed: true, tension: .95), lift: _lift);
  }

  @override
  void back(Pen pen, Head h, Skin skin) {
    final outer = _outer(h);
    final sc = h.scale;
    pen.fill(outer, cloth.base);
    pen.crescent(outer, cloth.shade, depth: 7 * sc, dir: const Offset(-0.9, -0.4));
    pen.rim(outer, cloth.hi, depth: 2.2 * sc, dir: const Offset(-0.9, -0.4));
    if (check != null) checkPattern(pen, outer, color: check!, cell: 6 * sc);
    pen.inside(outer, (p) {
      // the cloth right next to the face / neck is in shadow
      p.line(h.outline(grow: 3), w: 15 * sc, color: withA(cloth.shade, .55));
      final w = Style.lineThin * 0.95 * sc;
      final c = withA(cloth.shade, .95);
      final ay = h.absYaw.clamp(0.0, 1.0);
      for (final s in const [-1, 1]) {
        final lead = h.side == s;
        final k = lead ? 1 - 0.46 * ay : 1 + 0.2 * ay;
        p.line(h.path(svg('M${s * 50 * k} 4 C${s * 54 * k} 30 ${s * 58 * k} 52 ${s * 63 * k} ${dropY - 12}'), lift: _lift), w: w, color: c);
        p.line(h.path(svg('M${s * 41 * k} 30 C${s * 44 * k} 48 ${s * 49 * k} 66 ${s * 52 * k} ${dropY - 4}'), lift: _lift), w: w, color: c);
      }
    });
    pen.line(outer, w: Style.line * sc, color: Style.ink);
  }

  Path _hemLocal() {
    Offset r(double x, double y) => Offset(x, y + hemTilt * x);
    return spline([r(-52, hem + 8), r(-26, hem + 2), r(0, hem), r(26, hem + 2), r(52, hem + 8)], tension: .9);
  }

  @override
  void front(Pen pen, Head h, Skin skin) {
    final sc = h.scale;
    final outer = _outer(h);
    final hemP = h.path(_hemLocal(), lift: _lift);
    final cover = Path.combine(PathOperation.intersect, outer, regionAbove(h, _hemLocal(), lift: _lift, up: 90));
    pen.inside(h.outline(), (p) {
      p.line(hemP.shift(Offset(0, 3.4 * sc)), w: 6.5 * sc, color: withA(skin.shade, .9));
    });
    paintCloth(pen, cover, cloth, sc, shade: 6, check: check, outline: false);
    pen.inside(cover, (p) {
      p.line(h.path(svg('M-26 ${top + 8} C-18 ${top + 26} -18 ${hem - 10} -26 $hem'), lift: _lift), w: Style.lineFine * sc, color: withA(cloth.shade, .9));
      p.line(h.path(svg('M28 ${top + 8} C22 ${top + 26} 24 ${hem - 12} 32 ${hem + 2}'), lift: _lift), w: Style.lineFine * sc, color: withA(cloth.shade, .9));
    });
    pen.inside(regionAbove(h, _hemLocal(), lift: _lift, up: 90), (p) => p.line(outer, w: Style.line * sc, color: Style.ink));
    pen.line(hemP, w: Style.line * sc, color: Style.ink);
    if (agal) _drawAgal(pen, h);
  }

  void _drawAgal(Pen pen, Head h) {
    final sc = h.scale;
    for (var i = 0; i < agalRings; i++) {
      final y = agalY + i * 8.6;
      final r = 44.5 + (i * 0.8);
      final path = ring3D(h, y, r, 7.4, sag: agalSag, tilt: agalTilt, lift: _lift - 4.0);
      pen.fill(path, agalTones.base);
      pen.rim(path, agalTones.hi, depth: 1.5 * sc, dir: const Offset(-0.3, -1));
      pen.crescent(path, agalTones.shade, depth: 2.0 * sc, dir: const Offset(0.2, -1));
      pen.line(path, w: Style.line * 0.85 * sc, color: Style.ink);
    }
  }
}

// ───────────────────────────── hijab ─────────────────────────────

class Hijab extends Headwear {
  const Hijab({
    this.cloth = const Tones(Color(0xFF5E2F70), Color(0xFF3F1C52), Color(0xFF7D4C92)),
    this.underCap,
    this.capEdge = -20.0,
    this.hem = -34.0,
    this.top = -78.0,
    this.width = 1.0,
    this.length = 1.0,
    this.trim,
    this.flap = false,
  });

  final Tones cloth;

  /// Colour of the cap/scarf visible at the forehead under the hijab (null = none).
  final Tones? underCap;

  /// y where the under-cap ends on the forehead; and the y of the hijab edge.
  final double capEdge, hem;
  final double top, width, length;

  /// Optional trim colour along the face opening.
  final Color? trim;

  /// Draw a draped scarf end across the chest.
  final bool flap;

  static const double _lift = 6.0;

  Path _outer(Head h) {
    final ay = h.absYaw.clamp(0.0, 1.0);
    final lead = h.side;
    double f(int sgn, double y) {
      final t = smoothstep(-30, 30, y);
      if (lead == 0) return 1;
      return sgn == lead ? lerpD(1.0, 1 - 0.28 * ay, t) : lerpD(1 + 0.06 * ay, 1 + 0.22 * ay, t);
    }

    final bot = 104.0 * length;
    final half = <Offset>[
      Offset(0, top),
      Offset(27, top + 3),
      Offset(45, top + 17),
      Offset(55, top + 40),
      Offset(60, top + 68),
      const Offset(59, 8),
      const Offset(54, 32),
      const Offset(55, 54),
      Offset(70, 74 * length),
      Offset(90, 94 * length),
      Offset(86, bot),
      Offset(60, bot + 12),
      Offset(30, bot + 14),
      Offset(0, bot + 14),
    ];
    final right = <Offset>[for (final p in half) Offset(p.dx * width * f(1, p.dy), p.dy)];
    final left = <Offset>[for (final p in half) Offset(-p.dx * width * f(-1, p.dy), p.dy)];
    final all = <Offset>[...right, ...left.reversed.skip(1).take(left.length - 2)];
    return h.path(spline(all, closed: true, tension: .95), lift: _lift);
  }

  Path _hemLocal() => spline([const Offset(-48, 14), Offset(-43, hem + 20), Offset(-30, hem + 8), Offset(-12, hem + 1), Offset(0, hem - 1), Offset(12, hem + 1), Offset(30, hem + 8), Offset(43, hem + 20), const Offset(48, 14)], tension: .9);

  Path _capLocal() => spline([const Offset(-46, 16), Offset(-42, capEdge + 16), Offset(-26, capEdge + 5), Offset(0, capEdge - 3), Offset(26, capEdge + 5), Offset(42, capEdge + 16), const Offset(46, 16)], tension: .9);

  void _folds(Pen p, Head h, double sc) {
    final w = Style.lineThin * 1.15 * sc;
    final dark = withA(cloth.shade, .95);
    final ink = withA(Style.ink, .6);
    final hi = withA(cloth.hi, .8);
    final len = length;
    for (final s in const [-1, 1]) {
      // bold fold valleys running from the head down over the shoulders
      final valley = h.path(svg('M${s * 52} -44 C${s * 66} -6 ${s * 64} 40 ${s * 78} ${88 * len} L${s * 66} ${94 * len} C${s * 56} 48 ${s * 56} 2 ${s * 44} -36 Z'), lift: _lift);
      p.fill(valley, withA(cloth.shade, s == 1 ? .85 : .55));
      p.line(h.path(svg('M${s * 52} -44 C${s * 66} -6 ${s * 64} 40 ${s * 78} ${88 * len}'), lift: _lift), w: w * 1.2, color: ink);
      // light ridge next to it
      p.line(h.path(svg('M${s * 40} -42 C${s * 51} -2 ${s * 52} 48 ${s * 60} ${100 * len}'), lift: _lift), w: w * 1.1, color: hi);
      // swoop across the chest
      p.line(h.path(svg('M${s * 34} 54 C${s * 48} 70 ${s * 60} 80 ${s * 78} ${92 * len}'), lift: _lift), w: w * 1.2, color: ink);
    }
    p.line(h.path(svg('M-16 -76 C-3 -64 -3 -50 -11 -38'), lift: _lift), w: w * .9, color: dark);
    p.line(h.path(svg('M20 -75 C10 -62 12 -48 21 -38'), lift: _lift), w: w * .9, color: dark);
    // gathers at the forehead corners
    for (final s in const [-1, 1]) {
      p.fill(h.path(svg('M${s * 46} -34 C${s * 40} -46 ${s * 30} -56 ${s * 26} -62 C${s * 34} -50 ${s * 38} -42 ${s * 36} -32 Z'), lift: _lift), withA(cloth.shade, .8));
    }
  }

  @override
  void back(Pen pen, Head h, Skin skin) {
    final outer = _outer(h);
    final sc = h.scale;
    paintCloth(pen, outer, cloth, sc, shade: 8, hi: 2.4, dir: const Offset(-0.9, -0.35));
    pen.inside(outer, (p) => _folds(p, h, sc));
  }

  @override
  void front(Pen pen, Head h, Skin skin) {
    final sc = h.scale;
    final outer = _outer(h);
    final face = h.outline(grow: 0.6);
    // visible face region: face outline below the hijab edge
    final opening = Path.combine(PathOperation.intersect, face, regionBelow(h, _hemLocal(), lift: _lift - 1));
    if (underCap != null) {
      final capArea = Path.combine(PathOperation.intersect, opening, regionAbove(h, _capLocal(), lift: _lift - 2, up: 90));
      paintCloth(pen, capArea, underCap!, sc, shade: 3, hi: 1.2, outline: false);
      pen.line(h.path(_capLocal(), lift: _lift - 2), w: Style.line * 0.9 * sc, color: Style.ink);
    }
    // shadow cast by the hijab on the face
    pen.inside(opening, (p) {
      p.crescent(opening, withA(skin.shade, .85), depth: 5.5 * sc, dir: const Offset(0.1, 1));
    });
    final ring = Path.combine(PathOperation.difference, outer, opening);
    paintCloth(pen, ring, cloth, sc, shade: 8, hi: 2.4, outline: false, dir: const Offset(-0.9, -0.35));
    pen.inside(ring, (p) {
      // thick darker band where the cloth rolls around the face
      p.line(opening, w: 9 * sc, color: withA(cloth.shade, .9));
      p.line(opening, w: 3.2 * sc, color: withA(cloth.base, .0));
      _folds(p, h, sc);
      final w = Style.lineThin * 1.05 * sc;
      final c = withA(cloth.shade, .95);
      p.line(h.path(svg('M-34 56 C-14 74 14 74 34 56'), lift: _lift), w: w, color: c);
      p.line(h.path(svg('M-26 76 C-10 90 10 90 26 76'), lift: _lift), w: w * .9, color: withA(cloth.shade, .8));
    });
    if (trim != null) pen.line(opening, w: 1.4 * sc, color: trim!);
    pen.line(opening, w: Style.line * sc, color: Style.ink);
    pen.line(outer, w: Style.line * sc, color: Style.ink);
    if (flap) _drawFlap(pen, h, sc);
  }

  /// The loose end of the scarf draped diagonally across the chest.
  void _drawFlap(Pen pen, Head h, double sc) {
    final s = h.side == 0 ? 1 : -h.side;
    final f = h.path(
      svg('M${-44.0 * s} 50 C${-20.0 * s} 72 ${26.0 * s} 80 ${64.0 * s} 62 C${80.0 * s} 74 ${88.0 * s} 90 ${92.0 * s} ${118 * length} L${-80.0 * s} ${118 * length} C${-76.0 * s} 92 ${-62.0 * s} 66 ${-44.0 * s} 50 Z'),
      lift: _lift + 2,
    );
    final clip = Path.combine(PathOperation.intersect, f, _outer(h));
    paintCloth(pen, clip, cloth, sc, shade: 9, hi: 2.6, outline: false, dir: const Offset(-0.7, -0.7));
    pen.inside(clip, (p) {
      p.line(h.path(svg('M${-30.0 * s} 62 C${-8.0 * s} 80 ${30.0 * s} 84 ${52.0 * s} 74'), lift: _lift + 2), w: 1.8 * sc, color: withA(cloth.shade, .95));
      p.line(h.path(svg('M${-50.0 * s} 78 C${-30.0 * s} 94 ${10.0 * s} 100 ${44.0 * s} 94'), lift: _lift + 2), w: 1.6 * sc, color: withA(cloth.shade, .9));
    });
    pen.line(h.path(svg('M${-44.0 * s} 50 C${-20.0 * s} 72 ${26.0 * s} 80 ${64.0 * s} 62'), lift: _lift + 2), w: Style.line * sc, color: Style.ink);
  }
}

// ───────────────────────────── turban ─────────────────────────────

class Turban extends Headwear {
  const Turban({
    this.cloth = Cloth.cream,
    this.hem = -32.0,
    this.top = -84.0,
    this.jewel,
    this.jewelRing = const Color(0xFFE3B341),
    this.width = 1.0,
  });

  final Tones cloth;
  final double hem, top, width;

  /// Jewel colour on the front (null = none).
  final Color? jewel;
  final Color jewelRing;

  static const double _lift = 7.0;

  Path _mass(Head h) {
    final w = width;
    final ay = h.absYaw.clamp(0.0, 1.0);
    final back = h.side == 0 ? 0 : -h.side;
    final pts = <Offset>[
      Offset(0, top),
      Offset(28 * w, top + 5),
      Offset(50 * w, top + 22),
      Offset(60 * w, top + 42),
      Offset(61 * w, hem - 6),
      Offset(57 * w, hem + 6),
      Offset(30 * w, hem + 8),
      Offset(0, hem + 10),
      Offset(-30 * w, hem + 8),
      Offset(-57 * w, hem + 6),
      Offset(-61 * w, hem - 6),
      Offset(-60 * w, top + 42),
      Offset(-50 * w, top + 22),
      Offset(-28 * w, top + 5),
    ].map((o) => Offset(o.dx + back * 5 * ay * (o.dy < hem ? 1 : 0), o.dy)).toList();
    return h.path(spline(pts, closed: true, tension: .95), lift: _lift);
  }

  @override
  void back(Pen pen, Head h, Skin skin) {}

  @override
  void front(Pen pen, Head h, Skin skin) {
    final sc = h.scale;
    final mass = _mass(h);
    paintCloth(pen, mass, cloth, sc, shade: 7);
    pen.inside(mass, (p) {
      final w = Style.lineThin * 1.1 * sc;
      final c = withA(cloth.shade, .95);
      final hi = withA(cloth.hi, .9);
      final bands = [
        'M-62 ${hem - 4} C-40 ${top + 40} -4 ${top + 26} 62 ${top + 50}',
        'M-62 ${hem + 6} C-36 ${top + 56} 8 ${top + 44} 62 ${hem - 8}',
        'M-56 ${top + 36} C-30 ${top + 14} 14 ${top + 8} 52 ${top + 30}',
        'M-34 ${top + 16} C-10 ${top + 2} 20 ${top + 4} 40 ${top + 16}',
      ];
      for (final (i, b) in bands.indexed) {
        final path = h.path(svg(b), lift: _lift);
        p.line(path, w: w * (i == 1 ? 1.6 : 1.2), color: c);
        p.line(path.shift(Offset(-0.5 * sc, -2.2 * sc)), w: w * .8, color: hi);
      }
    });
    pen.line(mass, w: Style.line * sc, color: Style.ink);
    if (jewel != null) {
      final c = h.pt(0, hem - 6, lift: _lift + 2);
      pen.fill(circle(c.dx, c.dy, 3.6 * sc), jewelRing);
      pen.fill(circle(c.dx, c.dy, 2.4 * sc), jewel!);
      pen.line(circle(c.dx, c.dy, 3.6 * sc), w: 1.0 * sc, color: Style.ink);
    }
  }
}

// ───────────────────────────── cap (taqiyah) ─────────────────────────────

class Cap extends Headwear {
  const Cap({this.cloth = Cloth.white, this.hem = -36.0, this.top = -72.0, this.ribs = true});

  final Tones cloth;
  final double hem, top;
  final bool ribs;

  @override
  void back(Pen pen, Head h, Skin skin) {}

  @override
  void front(Pen pen, Head h, Skin skin) {
    final sc = h.scale;
    final p = h.path(
      spline([
        Offset(0, top),
        Offset(28, top + 6),
        Offset(46, top + 22),
        Offset(50, hem - 8),
        Offset(47, hem + 2),
        Offset(24, hem + 7),
        Offset(0, hem + 8),
        Offset(-24, hem + 7),
        Offset(-47, hem + 2),
        Offset(-50, hem - 8),
        Offset(-46, top + 22),
        Offset(-28, top + 6),
      ], closed: true, tension: .95),
      lift: 5.5,
    );
    paintCloth(pen, p, cloth, sc, shade: 5);
    if (ribs) {
      pen.inside(p, (q) {
        for (final x in const [-30.0, -15.0, 0.0, 15.0, 30.0]) {
          q.line(h.path(svg('M${x * .4} ${top + 2} C${x * 1.2} ${top + 20} ${x * 1.25} ${hem - 8} ${x * 1.1} $hem'), lift: 5.5), w: Style.lineFine * sc, color: withA(cloth.shade, .9));
        }
      });
    }
    pen.line(h.path(svg('M-48 ${hem - 4} C-30 ${hem + 4} 30 ${hem + 4} 48 ${hem - 4}'), lift: 5.5), w: Style.lineThin * sc, color: withA(cloth.shade, .95));
    pen.line(p, w: Style.line * sc, color: Style.ink);
  }
}

// ───────────────────────────── face veil (niqab / shemagh mask) ─────────────────────────────

/// Covers the lower face from [eyeBottom] down (nose and mouth hidden), with the
/// cloth wrapping the jaw and neck. The eyes stay visible: a niqab / ninja mask look.
/// Pair it with a [Turban] or [Ghutra] through [HeadwearStack] (veil FIRST).
class FaceVeil extends Headwear {
  const FaceVeil({
    this.cloth = const Tones(Color(0xFF8E6A76), Color(0xFF6B4A58), Color(0xFFB08E98)),
    this.eyeBottom = 9.0,
    this.check,
  });

  final Tones cloth;

  /// y (local) of the veil's top edge (just under the eyes).
  final double eyeBottom;

  /// Optional check pattern colour (shemagh style).
  final Color? check;

  static const double _lift = 5.0;

  @override
  void back(Pen pen, Head h, Skin skin) {
    final sc = h.scale;
    final hood = h.path(
      spline(const [
        Offset(0, -64),
        Offset(30, -60),
        Offset(50, -32),
        Offset(55, 0),
        Offset(56, 36),
        Offset(62, 66),
        Offset(70, 90),
        Offset(40, 100),
        Offset(0, 102),
        Offset(-40, 100),
        Offset(-70, 90),
        Offset(-62, 66),
        Offset(-56, 36),
        Offset(-55, 0),
        Offset(-50, -32),
        Offset(-30, -60),
      ], closed: true, tension: .95),
      lift: _lift,
    );
    paintCloth(pen, hood, cloth, sc, shade: 7, check: check);
  }

  @override
  void front(Pen pen, Head h, Skin skin) {
    final sc = h.scale;
    final topCurve = spline([Offset(-52, eyeBottom + 6), Offset(-30, eyeBottom + 3), const Offset(-12, 13), const Offset(0, 15), const Offset(12, 13), Offset(30, eyeBottom + 3), Offset(52, eyeBottom + 6)], tension: .9);
    final below = regionBelow(h, topCurve, lift: _lift, down: 140);
    var cover = Path.combine(PathOperation.intersect, h.outline(grow: 2.8), below);
    final neck = h.path(svg('M-28 36 C-29 62 -32 78 -38 90 Q0 104 38 90 C32 78 29 62 28 36 Z'), lift: _lift);
    cover = Path.combine(PathOperation.union, cover, Path.combine(PathOperation.intersect, neck, below));
    paintCloth(pen, cover, cloth, sc, shade: 6.5, outline: false, check: check);
    pen.inside(cover, (p) {
      final w = Style.lineThin * sc;
      final c = withA(check != null ? Style.ink : cloth.shade, check != null ? .45 : .95);
      p.line(h.path(svg('M-36 18 C-26 40 -26 62 -34 88'), lift: _lift), w: w, color: c);
      p.line(h.path(svg('M36 18 C26 40 26 62 34 88'), lift: _lift), w: w, color: c);
      p.line(h.path(svg('M-14 30 C-8 40 8 40 14 30'), lift: _lift), w: w * .8, color: c);
      p.line(h.path(svg('M-6 18 C-4 26 -2 30 0 34 C2 30 4 26 6 18'), lift: _lift + 3), w: w * .8, color: c);
    });
    pen.line(cover, w: Style.line * sc, color: Style.ink);
  }
}
