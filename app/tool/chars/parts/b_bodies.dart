// Worker B bodies: tailored coat with lapels (detective trench / doctor's white coat),
// bare shoulders (pearl diver).
import '../kit.dart';

/// A coat with a V opening, two notch lapels and a shirt (or scrub) showing in the V.
/// Coordinates are relative to the neck base (see body.dart).
class BCoat extends Body {
  const BCoat({
    required this.coat,
    required this.inner,
    this.lapel,
    this.trim,
    this.tie,
    this.tieKnot = true,
    this.shirtCollar,
    this.open = 1.0,
    this.vTip = 58.0,
    this.belt = false,
  });

  final Tones coat;
  final Tones inner;

  /// Lapel colour (defaults to [coat]).
  final Tones? lapel;

  /// Thin piping colour along the lapel edge.
  final Color? trim;
  final Color? tie;
  final bool tieKnot;

  /// Colour of the shirt collar flaps at the neck (null = none).
  final Tones? shirtCollar;
  final double open;
  final double vTip;
  final bool belt;

  String get _v => 'M-25 -13 L0 $vTip L25 -13 Z';

  Path _lapel(Head h, int s, double dx) {
    final o = open;
    return rel(h, 'M${s * 25.0} -13 L${s * (50.0 + 4 * o)} 6 L${s * (37.0 + 2 * o)} 17 L${s * (50.0 + 6 * o)} 35 L${s * 3.0} ${vTip + 4} Z', dx: dx);
  }

  @override
  void draw(Pen pen, Head h, Skin skin) {
    final dx = Body.turn(h);
    final sc = h.scale;
    final base = rel(h, shoulderPath, dx: dx);
    pen.solid(base, coat, shade: 8 * sc, hi: 2.4 * sc, dir: const Offset(-0.95, -0.35));
    pen.inside(base, (q) {
      q.taper(rel(h, 'M-58 22 C-52 52 -50 84 -54 118', dx: dx), w0: 2.6 * sc, w1: 0.3 * sc, color: withA(coat.shade, .95));
      q.taper(rel(h, 'M60 20 C54 52 56 84 52 118', dx: dx), w0: 2.6 * sc, w1: 0.3 * sc, color: withA(coat.shade, .95));
    });
    pen.line(base, w: Style.line * sc);
    // shirt / scrub in the V
    final v = rel(h, _v, dx: dx);
    pen.fill(v, inner.base);
    pen.inside(v, (q) {
      q.crescent(v, inner.shade, depth: 5 * sc, dir: const Offset(-0.9, -0.4));
    });
    pen.line(v, w: Style.lineThin * 1.2 * sc);
    if (tie != null) {
      final t = Tones.auto(tie!);
      final tp = rel(h, 'M-5 4 L5 4 L8 22 L0 52 L-8 22 Z', dx: dx);
      pen.solid(tp, t, shade: 2.6 * sc, hi: .9 * sc, w: Style.lineThin * 1.2 * sc);
    }
    for (final s in const [-1, 1]) {
      final l = _lapel(h, s, dx);
      final t = lapel ?? coat;
      pen.fill(l, t.base);
      pen.crescent(l, t.shade, depth: 4.5 * sc, dir: const Offset(-0.5, -0.8));
      pen.rim(l, t.hi, depth: 1.6 * sc, dir: const Offset(-0.7, -0.7));
      if (trim != null) {
        pen.line(l, w: 3.0 * sc, color: trim!);
      }
      pen.line(l, w: Style.line * .95 * sc);
      // crease where the lapel folds over
      pen.line(rel(h, 'M${s * 37.0} 17 L${s * 26.0} -6', dx: dx), w: Style.lineFine * sc, color: withA(Style.ink, .7));
    }
    if (belt) {
      pen.line(rel(h, 'M-100 112 L100 112', dx: dx), w: 6 * sc, color: Style.ink);
    }
  }

  @override
  void drawFront(Pen pen, Head h, Skin skin) {
    final dx = Body.turn(h);
    final sc = h.scale;
    if (shirtCollar != null) {
      final c = shirtCollar!;
      for (final s in const [-1, 1]) {
        final f = rel(h, 'M${s * 24.0} -19 C${s * 20.0} -10 ${s * 12.0} -4 ${s * 2.0} -3 L${s * 6.0} 7 L${s * 19.0} 15 C${s * 22.0} 8 ${s * 25.0} -4 ${s * 24.0} -19 Z', dx: dx);
        pen.solid(f, c, shade: 2.4 * sc, hi: 1.0 * sc, w: Style.lineThin * 1.25 * sc, dir: const Offset(-0.4, -0.9));
      }
    }
    if (tie != null && tieKnot) {
      final t = Tones.auto(tie!);
      pen.solid(rel(h, 'M-6 -4 C-6 -8 6 -8 6 -4 L5.5 6 C2 9 -2 9 -5.5 6 Z', dx: dx), t, shade: 2 * sc, hi: .8 * sc, w: Style.lineThin * 1.2 * sc);
    }
  }
}

/// Bare shoulders (skin) with a collar-bone line: the pearl diver.
class BareShoulders extends Body {
  const BareShoulders({this.shorts});

  final Tones? shorts;

  @override
  void draw(Pen pen, Head h, Skin skin) {
    final dx = Body.turn(h);
    final sc = h.scale;
    final p = rel(h, shoulderPath, dx: dx);
    pen.solid(p, skin.tones, shade: 8 * sc, hi: 2.4 * sc, dir: const Offset(-0.95, -0.35));
    pen.inside(p, (q) {
      // collar bones + chest line
      q.line(rel(h, 'M-4 6 C-16 2 -30 6 -42 14', dx: dx), w: Style.lineThin * sc, color: withA(skin.deep, .85));
      q.line(rel(h, 'M4 6 C16 2 30 6 42 14', dx: dx), w: Style.lineThin * sc, color: withA(skin.deep, .85));
      q.line(rel(h, 'M0 12 C-1 28 0 40 0 52', dx: dx), w: Style.lineFine * sc, color: withA(skin.deep, .6));
      q.taper(rel(h, 'M-30 38 C-20 48 -8 50 0 46', dx: dx), w0: 2.0 * sc, w1: 0.3 * sc, color: withA(skin.deep, .7));
      q.taper(rel(h, 'M30 38 C20 48 8 50 0 46', dx: dx), w0: 2.0 * sc, w1: 0.3 * sc, color: withA(skin.deep, .7));
    });
    pen.line(p, w: Style.line * sc);
  }
}
