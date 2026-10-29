// Facial hair: stubble, mustache, goatee, short / full / long beards.
// Authored in local front-view coordinates and warped through the head.
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';

enum BeardStyle { none, stubble, mustache, goatee, short, full, long, soulPatch }

class BeardSpec {
  const BeardSpec({
    this.style = BeardStyle.short,
    this.color = HairColor.black,
    this.mustache = true,
    this.mouthY = 41.0,
    this.mouthW = 13.0,
    this.mouthH = 6.5,
    this.length = 0.0,
    this.cheek = 0.0,
    this.mustacheSize = 1.0,
  });

  final BeardStyle style;
  final HairColor color;

  /// Draw a mustache with the beard styles that have one.
  final bool mustache;

  /// Where the mouth hole is cut out of the beard (should match the mouth).
  final double mouthY, mouthW, mouthH;

  /// Extra length below the chin (units) and how high the cheek line climbs.
  final double length, cheek;
  final double mustacheSize;

  BeardSpec copyWith({BeardStyle? style, HairColor? color, bool? mustache, double? mouthY, double? mouthW, double? mouthH, double? length, double? cheek, double? mustacheSize}) => BeardSpec(
    style: style ?? this.style,
    color: color ?? this.color,
    mustache: mustache ?? this.mustache,
    mouthY: mouthY ?? this.mouthY,
    mouthW: mouthW ?? this.mouthW,
    mouthH: mouthH ?? this.mouthH,
    length: length ?? this.length,
    cheek: cheek ?? this.cheek,
    mustacheSize: mustacheSize ?? this.mustacheSize,
  );
}

const double _lift = 2.2;

Path _bodyLocal(BeardSpec b) {
  final len = b.length;
  final ck = b.cheek; // + = higher cheek line
  switch (b.style) {
    case BeardStyle.short:
    case BeardStyle.full:
    case BeardStyle.stubble:
    case BeardStyle.long:
      final full = b.style == BeardStyle.full || b.style == BeardStyle.long;
      final grow = full ? 4.5 : 2.8;
      final chinY = 70 + len + (b.style == BeardStyle.long ? 26 : (full ? 10 : 0));
      final jawW = full ? 6.0 : 3.0;
      final sx = 43.0 + grow * 0.4;
      // right half, top sideburn -> chin
      final pts = <List<double>>[
        [sx, -4.0 - ck],
        [sx + grow * .5, 12.0],
        [sx + grow * .2, 30],
        [38 + grow, 46 + len * .1],
        [28 + grow + jawW * .3, 58 + len * .35],
        [17 + jawW, chinY - 8],
        [8, chinY - 2],
        [0, chinY],
      ];
      final inner = <List<double>>[
        [0.0, 38.0 - ck * 0.0],
        [10.0, 39.0],
        [20.0, 40.0],
        [28.0, 34.0],
        [33.0, 22.0],
        [36.5 + (full ? 1.0 : 0.0), 8.0 - ck],
        [sx - 3, -4.0 - ck],
      ];
      // clockwise: left top -> chin -> right top, then the inner boundary right -> centre -> left
      final all = <Offset>[
        for (final p in pts) Offset(-p[0], p[1]),
        for (final p in pts.reversed.skip(1)) Offset(p[0], p[1]),
        for (final p in inner.reversed) Offset(p[0], p[1]),
        for (final p in inner.skip(1)) Offset(-p[0], p[1]),
      ];
      return spline(all, closed: true, tension: .9);
    case BeardStyle.goatee:
      return svg('M-9 46 C-10 42 -5 43 0 43 C5 43 10 42 9 46 C10 58 6 69 0 72 C-6 69 -10 58 -9 46 Z');
    case BeardStyle.soulPatch:
      return svg('M-4 48 C-4 46 4 46 4 48 C5 54 2 58 0 58 C-2 58 -5 54 -4 48 Z');
    case BeardStyle.mustache:
    case BeardStyle.none:
      return Path();
  }
}

Path _mustacheLocal(BeardSpec b) {
  final k = b.mustacheSize;
  Path half(int s) => svg('M0 ${25.5} C${s * 8} ${23.5} ${s * 17 * k} ${26} ${s * 21 * k} ${34} C${s * 22.5 * k} ${38} ${s * 17 * k} ${39.5} ${s * 13 * k} ${37.4} C${s * 8} ${34.8} ${s * 4} ${33.4} 0 ${33.6} Z');
  return Path()
    ..addPath(half(-1), Offset.zero)
    ..addPath(half(1), Offset.zero);
}

/// Beard body only (no mustache): draw the mouth after it, then [drawMustache].
void drawBeardBody(Pen pen, Head h, BeardSpec b, Skin skin) {
  if (b.style == BeardStyle.none) return;
  final sc = h.scale;
  final c = b.color;
  if (b.style == BeardStyle.mustache) return;
  var body = h.path(_bodyLocal(b), lift: _lift);
  // mouth hole
  final hole = h.path(ellipse(0, b.mouthY, b.mouthW, b.mouthH), lift: _lift);
  if (b.style != BeardStyle.goatee && b.style != BeardStyle.soulPatch) {
    body = Path.combine(PathOperation.difference, body, hole);
  }
  if (b.style == BeardStyle.stubble) {
    pen.fill(body, withA(c.base, .38));
    pen.crescent(body, withA(c.shade, .35), depth: 4 * sc, dir: const Offset(-0.9, -0.3));
    if (b.mustache) pen.fill(h.path(_mustacheLocal(b), lift: _lift), withA(c.base, .55));
    return;
  }
  pen.fill(body, c.base);
  pen.crescent(body, c.shade, depth: 6.5 * sc, dir: const Offset(-0.9, -0.35));
  pen.rim(body, c.hi, depth: 1.8 * sc, dir: const Offset(-0.9, -0.4));
  // strands
  pen.inside(body, (p) {
    final cols = withA(c.shade, .85);
    final hi = withA(c.hi, .55);
    for (final s in const [-1, 1]) {
      p.line(h.path(svg('M${s * 36} 14 C${s * 38} 34 ${s * 30} 52 ${s * 16} 64'), lift: _lift), w: Style.lineFine * sc, color: cols);
      p.line(h.path(svg('M${s * 30} 22 C${s * 30} 40 ${s * 22} 56 ${s * 10} 66'), lift: _lift), w: Style.lineFine * sc, color: hi);
    }
    p.line(h.path(svg('M0 58 C-1 66 1 72 0 78'), lift: _lift), w: Style.lineFine * sc, color: cols);
  });
  pen.line(body, w: Style.line * sc, color: Style.ink);
}

/// True when the beard style has a mustache to draw over the mouth.
bool hasMustache(BeardSpec b) => b.style == BeardStyle.mustache || (b.mustache && b.style != BeardStyle.goatee && b.style != BeardStyle.soulPatch && b.style != BeardStyle.none && b.style != BeardStyle.stubble);

void drawMustache(Pen pen, Head h, BeardSpec b) {
  final sc = h.scale;
  final c = b.color;
  final m = h.path(_mustacheLocal(b), lift: _lift + 0.6);
  pen.fill(m, c.base);
  pen.crescent(m, c.shade, depth: 2.2 * sc, dir: const Offset(-0.5, -0.8));
  pen.rim(m, c.hi, depth: 1.0 * sc);
  pen.line(m, w: Style.line * 0.85 * sc, color: Style.ink);
}

/// Whole beard in one go (body, then mustache) for simple cases without a mouth in between.
void drawBeard(Pen pen, Head h, BeardSpec b, Skin skin) {
  drawBeardBody(pen, h, b, skin);
  if (hasMustache(b)) drawMustache(pen, h, b);
}
