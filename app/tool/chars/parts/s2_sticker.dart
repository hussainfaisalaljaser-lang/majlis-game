// Sticker framing (worker S2): draws a CharSpec the way the shop's stickers look, i.e. the
// figure shrunk and shifted up inside a 200x200 canvas, cut flat at the bottom, with a dark plank
// banner holding the Arabic caption over the cut. The white die-cut border + soft shadow are added
// afterwards by tool/chars/s2_export.py (it needs the alpha silhouette).
//
// The figure itself is authored in normal AVATAR space (the same numbers as characters/ref.dart:
// head about (100,96) scale ~1), so the stickers share the avatars' proportions and line widths.
import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:flutter/painting.dart' show FontWeight, TextAlign, TextDirection, TextPainter, TextSpan, TextStyle;

import '../core/pen.dart';
import '../scene.dart';
import '../spec.dart';

/// How the avatar-space figure sits inside the sticker canvas (200 units).
class S2Frame {
  const S2Frame({this.k = 0.8, this.cx = 100, this.cy = 80, this.clipY = 190, this.ax = 100, this.ay = 96});

  /// Figure scale, where the avatar point ([ax],[ay]) lands in the sticker ([cx],[cy]), and the
  /// y (sticker units) where the body is cut flat (hidden behind the banner).
  final double k, cx, cy, clipY, ax, ay;

  /// Avatar-space point -> sticker-canvas point (200 units).
  Offset toSticker(double x, double y) => Offset(cx + (x - ax) * k, cy + (y - ay) * k);
}

/// Per-id frame overrides (default [S2Frame] otherwise).
const Map<String, S2Frame> s2Frames = {
  // figures with something tall on top of the head sit lower and a little smaller
  'vip_crown': S2Frame(k: 0.76, cy: 92),
  'leg_king': S2Frame(k: 0.76, cy: 92),
  'leg_legend': S2Frame(k: 0.76, cy: 92),
  's1_sleep': S2Frame(k: 0.76, cy: 86),
};

/// Accent colour of every pack: caption text colour + banner trim.
const Map<String, Color> s2PackAccent = {
  'stk_innocent': Color(0xFF8EE9A8),
  'stk_party': Color(0xFFFFD84D),
  'stk_traitor': Color(0xFFFF7A7A),
  'stk_vip': Color(0xFFFFD36B),
  'stk_hype': Color(0xFFFFA64D),
  'stk_s1': Color(0xFF63E6BE),
  'stk_legend': Color(0xFFE6A1FF),
};

/// Paint the whole sticker art (figure + caption banner) onto [canvas] covering [px] x [px].
/// Transparent outside the art; no die-cut border yet.
void paintSticker(Canvas canvas, CharSpec spec, {required String caption, required String pack, double px = 1024}) {
  final f = s2Frames[spec.id] ?? const S2Frame();
  final u = px / 200;
  canvas.save();
  canvas.clipRect(Rect.fromLTWH(0, 0, px, f.clipY * u));
  canvas.translate((f.cx - f.ax * f.k) * u, (f.cy - f.ay * f.k) * u);
  paintChar(canvas, spec, px: px * f.k);
  canvas.restore();
  _banner(canvas, u, caption, s2PackAccent[pack] ?? const Color(0xFFFFE08A));
}

void _banner(Canvas canvas, double u, String caption, Color accent) {
  var size = 18.0;
  late TextPainter fill, stroke;
  TextPainter mk(Paint? fg, Color? color, double fs) => TextPainter(
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.center,
    text: TextSpan(
      text: caption,
      style: TextStyle(fontFamily: 'Baloo', fontWeight: FontWeight.w800, fontSize: fs, height: 1.05, color: fg == null ? color : null, foreground: fg),
    ),
  )..layout();
  Paint sp() => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.4
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = Style.ink;
  fill = mk(null, mix(accent, const Color(0xFFFFFFFF), .22), size);
  while (fill.width > 146 && size > 11) {
    size -= .5;
    fill = mk(null, mix(accent, const Color(0xFFFFFFFF), .22), size);
  }
  stroke = mk(sp(), null, size);

  final w = math.max(90.0, fill.width + 28), h = 29.0;
  canvas.save();
  canvas.scale(u);
  canvas.translate(100, 176);
  canvas.rotate(-0.045);
  final pen = Pen(canvas);
  final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), const Radius.circular(9.5));
  final plank = Path()..addRRect(r);
  const wood = Tones(Color(0xFF4C2638), Color(0xFF331827), Color(0xFF6E3B52));
  // soft drop shadow under the plank, then the plank, a gold-ish trim line and the caption
  pen.fill(plank.shift(const Offset(0, 2.2)), withA(Style.ink, .35));
  pen.solid(plank, wood, shade: 4.2, hi: 1.6, w: 2.6, dir: const Offset(0, -1));
  final inner = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 0), width: w - 5.4, height: h - 5.4), const Radius.circular(7.2)));
  pen.line(inner, w: 1.0, color: withA(accent, .85));
  // two little rivets at the ends
  for (final s in const [-1.0, 1.0]) {
    pen.fill(circle(s * (w / 2 - 5.2), 0, 1.5), withA(accent, .9));
  }
  final o = Offset(-fill.width / 2, -fill.height / 2 + .6);
  stroke.paint(canvas, o);
  fill.paint(canvas, o);
  canvas.restore();
}
