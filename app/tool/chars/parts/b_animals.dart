// Worker B: the two mascots (camel, saluki) drawn with the Pen in the video's style:
// thick outline, big glossy eyes with highlights, 2-tone cel shading.
// Every head part is authored in head-local coordinates (origin = head centre, +y down) and
// warped through [Head.path] so the roll of the HeadSpec tilts the whole head.
import 'dart:math' as math;
import '../kit.dart';
import 'b_common.dart';

Path _m(String d) => Head.mirror(svg(d));

// ───────────────────────────── camel ─────────────────────────────

const _camel = Tones(Color(0xFFDDB07C), Color(0xFFB4824F), Color(0xFFF1D1A2));
const _camelMuzzle = Tones(Color(0xFFF4DDB8), Color(0xFFD9B488), Color(0xFFFFF2DC));
const _camelDark = Color(0xFF6B4226);
const _red = Tones(Color(0xFFD63A4A), Color(0xFF98202F), Color(0xFFF26F7B));
const _gold = Tones(Color(0xFFF2C233), Color(0xFFC08A14), Color(0xFFFFE690));

void bCamel(Pen pen, Head h) {
  final sc = h.scale;
  final lw = Style.line * sc;
  Path P(String d) => h.path(svg(d));
  Path pMirror(String d) => h.path(_m(d));

  // ── shoulders + neck (not tilted) ──
  final neck = svg('M74 126 C72 150 62 166 38 178 C20 186 8 196 2 210 L198 210 C192 196 180 186 162 178 C138 166 128 150 126 126 Z');
  pen.fill(neck, _camel.base);
  pen.crescent(neck, _camel.shade, depth: 7, dir: const Offset(-0.9, -0.3));
  pen.rim(neck, _camel.hi, depth: 2.2, dir: const Offset(-0.9, -0.4));
  pen.inside(neck, (q) {
    q.taper(svg('M70 150 C74 170 70 186 62 200'), w0: 2.4, w1: .3, color: withA(_camel.shade, .95));
    q.taper(svg('M132 148 C128 168 134 184 140 198'), w0: 2.4, w1: .3, color: withA(_camel.shade, .95));
    q.taper(svg('M30 190 C46 186 60 190 70 198'), w0: 2.0, w1: .3, color: withA(_camel.shade, .8));
  });
  pen.line(neck, w: Style.line);
  // collar with a bell
  final collar = svg('M62 156 C84 172 116 172 138 156 L142 170 C118 188 82 188 58 170 Z');
  pen.solid(collar, _red, shade: 3.2, hi: 1.2, w: Style.line * .95);
  pen.inside(collar, (q) {
    q.line(svg('M62 162 C84 178 116 178 138 162'), w: 1.4, color: _gold.base);
    q.line(svg('M60 168 C84 184 116 184 140 168'), w: 1.4, color: _gold.base);
    for (var i = 0; i < 7; i++) {
      final x = 70 + i * 10.0;
      final y = 169 + 7 * math.sin((x - 70) / 60 * math.pi);
      q.fill(circle(x, y - 1, 1.5), _gold.hi);
    }
  });
  final bell = circle(100, 187, 7.6);
  pen.solid(bell, _gold, shade: 2.6, hi: 1.2, w: Style.line * .95);
  pen.line(svg('M93 188 L107 188'), w: Style.lineThin, color: Style.ink);
  pen.fill(circle(100, 191, 1.3), Style.ink);
  bGlint(pen, const Offset(96, 182.5), const Offset(99, 181.2), w: 1.8);

  // ── throat tufts + ears (behind the head) ──
  for (final left in const [true, false]) {
    const t = 'M-33 64 C-41 72 -44 82 -41 92 C-37 84 -34 78 -30 74 Z';
    final tp = left ? P(t) : pMirror(t);
    pen.solid(tp, const Tones(Color(0xFF9A6A3E), Color(0xFF6B4226), Color(0xFFC09062)), shade: 2.6 * sc, hi: 1 * sc, w: lw * .9);
    const eo = 'M-24 -44 C-27 -58 -37 -68 -46 -65 C-54 -60 -52 -46 -44 -36 C-40 -30 -31 -29 -27 -33 Z';
    const ei = 'M-29 -43 C-31 -53 -38 -60 -44 -58 C-49 -54 -47 -45 -42 -38 C-38 -34 -33 -34 -30 -36 Z';
    final outer = left ? P(eo) : pMirror(eo);
    pen.solid(outer, _camel, shade: 3.4 * sc, hi: 1.2 * sc, w: lw);
    final inner = left ? P(ei) : pMirror(ei);
    pen.fill(inner, const Color(0xFFC98E76));
    pen.crescent(inner, const Color(0xFF9B5C4A), depth: 3 * sc, dir: const Offset(0.6, 0.7));
    pen.line(inner, w: Style.lineThin * sc, color: withA(Style.ink, .8));
    final tip = left ? P('M-40 -68 C-45 -70 -50 -65 -49 -60 C-46 -62 -43 -64 -40 -62 Z') : pMirror('M-40 -68 C-45 -70 -50 -65 -49 -60 C-46 -62 -43 -64 -40 -62 Z');
    pen.shape(tip, _camelDark, w: Style.lineThin * sc);
  }

  // ── head: long skull, a waist at the eyes, a bulbous muzzle ──
  final head = P('M0 -54 C18 -54 33 -42 35 -22 C36 -6 30 6 28 18 C33 26 35 40 34 56 C33 74 22 86 0 86 C-22 86 -33 74 -34 56 C-35 40 -33 26 -28 18 C-30 6 -36 -6 -35 -22 C-33 -42 -18 -54 0 -54 Z');
  pen.fill(head, _camel.base);
  pen.crescent(head, _camel.shade, depth: 6.5 * sc, dir: const Offset(-0.95, -0.35));
  pen.rim(head, _camel.hi, depth: 2.2 * sc, dir: const Offset(-0.85, -0.5));
  pen.inside(head, (q) {
    // lighter muzzle
    final muzzle = P('M-30 24 C-28 10 -16 5 0 5 C16 5 28 10 30 24 C36 44 36 74 20 92 L-20 92 C-36 74 -36 44 -30 24 Z');
    q.fill(muzzle, _camelMuzzle.base);
    q.crescent(muzzle, _camelMuzzle.shade, depth: 5 * sc, dir: const Offset(-0.95, -0.3));
    q.rim(muzzle, _camelMuzzle.hi, depth: 1.6 * sc, dir: const Offset(-0.8, -0.6));
    q.line(muzzle, w: Style.lineThin * .8 * sc, color: withA(_camel.shade, .8));
    for (final s in const [-1, 1]) {
      q.glow(h.pt(s * 28, 26), 7 * sc, 5 * sc, const Color(0xFFE5806E), alpha: .32);
      q.taper(h.path(svg('M${s * 33} -8 C${s * 35} 2 ${s * 32} 10 ${s * 29} 16')), w0: 2.0 * sc, w1: .3 * sc, color: withA(_camel.shade, .9));
    }
  });
  pen.line(head, w: lw);

  // nostrils (tall slits on the nose pad), split upper lip, droopy lower lip
  for (final s in const [-1, 1]) {
    final n = h.path(svg('M${s * 13} 17 C${s * 12} 12 ${s * 7} 11 ${s * 5} 14 C${s * 6} 19 ${s * 9} 22 ${s * 13} 17 Z'));
    pen.fill(n, const Color(0xFF5A3322));
    pen.line(n, w: Style.lineFine * sc, color: Style.ink);
    pen.fill(h.path(ellipse(s * 9.6, 14.8, 1.5, .8, rot: s * 0.5)), withA(const Color(0xFFFFFFFF), .5));
  }
  pen.line(h.path(svg('M0 21 L0 46')), w: Style.lineThin * sc, color: withA(Style.ink, .85));
  final lower = P('M-17 56 C-13 74 13 74 17 56 C10 62 -10 62 -17 56 Z');
  pen.fill(lower, const Color(0xFFE9C79A));
  pen.crescent(lower, const Color(0xFFC9A070), depth: 2.4 * sc, dir: const Offset(-0.4, -0.9));
  pen.line(lower, w: Style.lineThin * sc, color: withA(Style.ink, .9));
  pen.line(h.path(svg('M-26 50 C-19 60 -7 57 0 47 C7 57 19 60 26 50')), w: Style.lineThin * 1.3 * sc, color: Style.ink);
  pen.line(h.path(svg('M-28 47 C-29 49 -28 52 -26 52')), w: Style.lineFine * sc, color: withA(Style.ink, .8));
  pen.line(h.path(svg('M28 47 C29 49 28 52 26 52')), w: Style.lineFine * sc, color: withA(Style.ink, .8));

  // tuft of hair on the crown
  final tuftHair = P('M-14 -48 C-17 -64 -8 -76 0 -66 C5 -78 16 -68 13 -48 C6 -54 -6 -54 -14 -48 Z');
  pen.solid(tuftHair, const Tones(Color(0xFF8A5A34), Color(0xFF5F3A20), Color(0xFFB58257)), shade: 3 * sc, hi: 1 * sc, w: lw * .95);
  pen.taper(h.path(svg('M-4 -50 C-6 -58 -4 -63 0 -66')), w0: 1.6 * sc, w1: .2 * sc, color: withA(Style.ink, .6));
  pen.taper(h.path(svg('M6 -50 C7 -57 9 -62 11 -64')), w0: 1.6 * sc, w1: .2 * sc, color: withA(Style.ink, .6));

  // red headband with gold trim and a medallion
  final band = P('M-36 -34 C-20 -46 20 -46 36 -34 L35 -22 C20 -34 -20 -34 -35 -22 Z');
  pen.solid(band, _red, shade: 3.2 * sc, hi: 1.2 * sc, w: lw);
  pen.inside(band, (q) {
    q.line(h.path(svg('M-36 -31 C-20 -43 20 -43 36 -31')), w: 1.5 * sc, color: _gold.base);
    q.line(h.path(svg('M-35 -25 C-20 -37 20 -37 35 -25')), w: 1.5 * sc, color: _gold.base);
  });
  final med = h.path(circle(0, -34, 6.2));
  pen.solid(med, _gold, shade: 2 * sc, hi: 1 * sc, w: Style.lineThin * 1.2 * sc);
  pen.fill(h.path(circle(0, -34, 2.6)), _red.base);
  pen.line(h.path(circle(0, -34, 2.6)), w: Style.lineFine * sc, color: Style.ink);
  bGlint(pen, h.pt(-2.6, -37), h.pt(-.6, -38), w: 1.6);
  // band edge tassels
  for (final s in const [-1, 1]) {
    final tas = h.path(svg('M${s * 35} -31 C${s * 40} -27 ${s * 41} -17 ${s * 38} -9 C${s * 35} -15 ${s * 35} -23 ${s * 35} -31 Z'));
    pen.solid(tas, _red, shade: 2 * sc, hi: .8 * sc, w: Style.lineThin * 1.1 * sc);
  }
}

// ───────────────────────────── saluki (lv10) ─────────────────────────────

const _fur = Tones(Color(0xFFF3E2C6), Color(0xFFD3B38C), Color(0xFFFFF4DE));
const _earFur = Tones(Color(0xFFC48C5C), Color(0xFF93612F), Color(0xFFE3B284));

void bSaluki(Pen pen, Head h) {
  final sc = h.scale;
  final lw = Style.line * sc;
  Path P(String d) => h.path(svg(d));
  Path pMirror(String d) => h.path(_m(d));
  _drawSalukiBody(pen, h);
  // ears
  for (final left in const [true, false]) {
    const d = 'M-22 -38 C-40 -36 -53 -18 -56 6 C-58 8 -61 12 -59 19 C-57 22 -60 28 -58 34 C-56 38 -60 46 -56 54 C-54 62 -50 72 -44 80 C-40 70 -42 64 -36 62 C-34 70 -30 72 -28 70 C-28 58 -26 36 -26 20 C-26 6 -24 -10 -22 -38 Z';
    final ear = left ? P(d) : pMirror(d);
    pen.fill(ear, _earFur.base);
    pen.crescent(ear, _earFur.shade, depth: 5 * sc, dir: left ? const Offset(0.9, -0.3) : const Offset(-0.9, -0.3));
    pen.rim(ear, _earFur.hi, depth: 1.8 * sc, dir: left ? const Offset(-0.9, -0.4) : const Offset(0.9, -0.4));
    pen.inside(ear, (q) {
      final s = left ? -1 : 1;
      q.taper(h.path(svg('M${s * 44} -22 C${s * 50} 4 ${s * 50} 34 ${s * 42} 66')), w0: 2.4 * sc, w1: .3 * sc, color: withA(_earFur.shade, .95));
      q.taper(h.path(svg('M${s * 36} -26 C${s * 42} 0 ${s * 42} 30 ${s * 36} 58')), w0: 2.0 * sc, w1: .3 * sc, color: withA(_earFur.hi, .8));
      q.taper(h.path(svg('M${s * 30} -10 C${s * 33} 10 ${s * 34} 30 ${s * 31} 56')), w0: 1.6 * sc, w1: .3 * sc, color: withA(_earFur.shade, .8));
    });
    pen.line(ear, w: lw);
  }
  // head
  final head = P('M0 -48 C15 -48 27 -38 28 -22 C29 -8 26 4 23 16 C21 30 18 46 15 60 C13 70 8 76 0 76 C-8 76 -13 70 -15 60 C-18 46 -21 30 -23 16 C-26 4 -29 -8 -28 -22 C-27 -38 -15 -48 0 -48 Z');
  pen.fill(head, _fur.base);
  pen.crescent(head, _fur.shade, depth: 5 * sc, dir: const Offset(-0.95, -0.3));
  pen.rim(head, _fur.hi, depth: 2 * sc, dir: const Offset(-0.85, -0.5));
  pen.inside(head, (q) {
    // tan sides of the skull + cheeks
    for (final s in const [-1, 1]) {
      q.fill(h.path(svg('M${s * 30} -50 C${s * 30} -26 ${s * 26} -6 ${s * 22} 12 C${s * 19} 26 ${s * 17} 44 ${s * 15} 62 C${s * 22} 40 ${s * 34} 10 ${s * 34} -50 Z')), withA(_earFur.base, .55));
    }
    // pale blaze down the middle
    q.fill(h.path(svg('M0 -50 C6 -36 6 -14 5 6 C5 24 6 44 5 70 L-5 70 C-6 44 -5 24 -5 6 C-6 -14 -6 -36 0 -50 Z')), withA(_fur.hi, .95));
  });
  pen.line(head, w: lw);
  // nose
  final nose = P('M-10 66 C-13 74 -7 82 0 82 C7 82 13 74 10 66 C6 62 -6 62 -10 66 Z');
  pen.fill(nose, const Color(0xFF2B1B1F));
  pen.inside(nose, (q) => q.rim(nose, const Color(0xFF55404A), depth: 2.4 * sc, dir: const Offset(-0.5, -0.9)));
  pen.line(nose, w: lw * .95);
  pen.fill(h.path(ellipse(-3.6, 67.5, 3.2, 1.6, rot: -0.3)), withA(const Color(0xFFFFFFFF), .85));
  pen.line(h.path(svg('M-5 76 C-4 78 -2.6 78 -2 77 M5 76 C4 78 2.6 78 2 77')), w: Style.lineFine * sc, color: const Color(0xFF6B5560));
  // mouth
  pen.line(h.path(svg('M0 82 L0 88')), w: Style.lineThin * sc, color: Style.ink);
  pen.line(h.path(svg('M-10 87 C-6 92 -2 91 0 88 C2 91 6 92 10 87')), w: Style.lineThin * 1.2 * sc, color: Style.ink);
  // cheek blush
  for (final s in const [-1, 1]) {
    pen.inside(head, (q) => q.glow(h.pt(s * 19, 34), 6 * sc, 4 * sc, const Color(0xFFE5806E), alpha: .25));
  }
}

void _drawSalukiBody(Pen pen, Head h) {
  pen.c.save();
  pen.c.translate(0, -5);
  // neck + chest in cream, red collar, star badge
  final neck = svg('M80 96 C79 124 72 150 62 158 C52 166 44 170 40 172 C22 180 10 192 4 210 L196 210 C190 192 178 180 160 172 C156 170 148 166 138 158 C128 150 121 124 120 96 Z');
  pen.fill(neck, _fur.base);
  pen.crescent(neck, _fur.shade, depth: 7, dir: const Offset(-0.9, -0.3));
  pen.rim(neck, _fur.hi, depth: 2.2, dir: const Offset(-0.9, -0.4));
  pen.inside(neck, (q) {
    q.taper(svg('M72 150 C76 170 72 186 64 200'), w0: 2.4, w1: .3, color: withA(_fur.shade, .95));
    q.taper(svg('M128 148 C124 168 130 184 136 198'), w0: 2.4, w1: .3, color: withA(_fur.shade, .95));
  });
  pen.line(neck, w: Style.line);
  final collar = svg('M66 146 C86 160 114 160 134 146 L138 160 C116 176 84 176 62 160 Z');
  pen.solid(collar, _red, shade: 3.2, hi: 1.2, w: Style.line * .95);
  pen.inside(collar, (q) {
    q.line(svg('M65 151 C86 165 114 165 135 151'), w: 1.3, color: _gold.base);
    q.line(svg('M62 157 C86 171 114 171 138 157'), w: 1.3, color: _gold.base);
  });
  // star shield badge
  final shield = svg('M84 168 C93 174 107 174 116 168 L116 186 C116 196 108 203 100 207 C92 203 84 196 84 186 Z');
  pen.solid(shield, const Tones(Color(0xFFD9722A), Color(0xFFA3481A), Color(0xFFF59A52)), shade: 3, hi: 1.2, w: Style.line);
  pen.line(svg('M87 172 C94 177 106 177 113 172 L113 186 C113 194 107 200 100 203 C93 200 87 194 87 186 Z'), w: 1.4, color: const Color(0xFF6E2A10));
  final star = _star(const Offset(100, 188), 10.5, 4.6);
  pen.solid(star, _gold, shade: 1.6, hi: .8, w: Style.lineThin * 1.1);
  pen.c.restore();
}

Path _star(Offset c, double ro, double ri) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final r = i.isEven ? ro : ri;
    final o = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
    i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
  }
  return p..close();
}
