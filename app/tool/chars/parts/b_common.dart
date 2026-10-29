// Worker B helpers: cut-out clip, small shared drawing bits.
import '../kit.dart';

/// Cut-out busts are cropped by the avatar circle like the old art (the app clips them with
/// a circle anyway). Call [bClipOpen] in `CharSpec.behind` and [bClipClose] first thing in
/// `CharSpec.front`: everything drawn in between is cropped by the circle, anything drawn
/// after [bClipClose] (props that leave the circle) is not.
void bClipOpen(Pen pen) {
  pen.c.save();
  pen.c.clipPath(circle(100, 100, 100));
}

void bClipClose(Pen pen) => pen.c.restore();

/// Soft white glint: a small tapered streak + dot (glossy look for glass, pearls, metal).
void bGlint(Pen pen, Offset a, Offset b, {double w = 2.2, double alpha = .85}) {
  pen.taper(Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy), w0: w, w1: w * .15, color: withA(const Color(0xFFFFFFFF), alpha));
}

/// A rope / cord stroke with twist marks.
void bRope(Pen pen, Path path, {double w = 3.6, Color base = const Color(0xFFB98A55), Color dark = const Color(0xFF7C5530)}) {
  pen.line(path, w: w + 2.2, color: Style.ink);
  pen.line(path, w: w, color: base);
  for (final m in path.computeMetrics()) {
    for (var d = 1.0; d < m.length; d += 3.4) {
      final t = m.getTangentForOffset(d);
      if (t == null) continue;
      final n = Offset(-t.vector.dy, t.vector.dx);
      final p = t.position;
      pen.line(Path()..moveTo((p - n * (w * .42) - t.vector * .6).dx, (p - n * (w * .42) - t.vector * .6).dy)..lineTo((p + n * (w * .42) + t.vector * .6).dx, (p + n * (w * .42) + t.vector * .6).dy), w: .8, color: dark);
    }
  }
}
