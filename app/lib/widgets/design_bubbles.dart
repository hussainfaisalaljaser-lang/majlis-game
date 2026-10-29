import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/shop.dart';
import '../theme.dart';
import 'design_bubbles_core.dart';
import 'design_bubbles_looks.dart';
import 'fx.dart';

export 'design_bubbles_core.dart' show BubbleArtSpec, BubbleCtx;
export 'design_bubbles_looks.dart' show bubbleArtOf;

/// فقاعة الكلام المصورة (مثل تصميم متجر الفقاعات): شكلها وزخارفها وحركتها حسب [look]،
/// والكلام أبيض بحد غامق دايم، والفقاعة تكبر مع طول الكلام والزخارف تكبر معها (كلها بوحدة حجم الخط).
class BubbleArt extends StatelessWidget {
  const BubbleArt({
    super.key,
    required this.look,
    required this.text,
    this.fontSize = 12,
    this.maxWidth = 170,
    this.tailAlign = .5,
    this.time,
  });

  final BubbleLook look;
  final String text;
  final double fontSize;
  final double maxWidth;

  /// مكان رأس الذيل على عرض الفقاعة (٠ يسار ← ١ يمين)؛ النص = فوق اللاعب مباشرة.
  final double tailAlign;

  /// وقت ثابت بدال ساعة الحركات (للتصوير بس: لقطات الحركة).
  final ValueListenable<double>? time;

  /// طول الذيل بوحدة حجم الخط.
  static const tailUnits = .62;

  @override
  Widget build(BuildContext context) {
    final spec = bubbleArtOf(look);
    final u = fontSize;
    final pad = spec.pad;
    final tail = u * tailUnits;
    // لو العرض الأقصى ضيق (أزرار صغيرة) نقلل حشوة الكلام عشان ما ينقص كلامه ويبقى مكان للزخارف
    var tx = spec.tx;
    if (maxWidth.isFinite) {
      final room = maxWidth - 2 * (pad.left + tx) * u;
      if (room < u * 2.6) tx = math.max(.3, tx - (u * 2.6 - room) / (2 * u));
    }
    final inset = EdgeInsets.fromLTRB(
      (pad.left + tx) * u,
      (pad.top + spec.ty + .05) * u,
      (pad.right + tx) * u,
      (pad.bottom + spec.ty - .05) * u + tail,
    );
    Widget bubble(ValueListenable<double> t) => CustomPaint(
      painter: BubbleArtPainter(look, t, unit: u, tailAlign: tailAlign),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: inset,
          child: _BubbleText(text, size: u, ink: spec.textInk),
        ),
      ),
    );
    // الرق ثابت، والباقي يرسم نفسه كل فريم من ساعة الحركات (وتوقف بالوضع الخفيف).
    if (time case final fixed?) return bubble(fixed);
    if (!spec.animated) return bubble(const AlwaysStoppedAnimation(0));
    return RepaintBoundary(child: FxClock(builder: (context, t) => bubble(t)));
  }
}

/// الكلام: أبيض بحد غامق سميك (مثل التصميم)، سطر أو سطرين.
class _BubbleText extends StatelessWidget {
  const _BubbleText(this.text, {required this.size, required this.ink});

  final String text;
  final double size;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: size, height: 1.25);
    Text t(TextStyle s) => Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      textWidthBasis: TextWidthBasis.longestLine,
      style: s,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        ExcludeSemantics(
          child: t(
            base.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = (size * .3).clamp(2.0, 8.0)
                ..strokeJoin = StrokeJoin.round
                ..color = ink,
              shadows: [Shadow(color: Colors.black.withValues(alpha: .35), offset: Offset(0, size * .07))],
            ),
          ),
        ),
        t(base.copyWith(color: Colors.white)),
      ],
    );
  }
}

/// رسام الفقاعة المصورة: ظل، زخارف خلفية، جسم بتدرج، زخارف داخلية، حافة غامقة، زخارف فوقية.
class BubbleArtPainter extends CustomPainter {
  BubbleArtPainter(this.look, this.time, {required this.unit, this.tailAlign = .5}) : super(repaint: time);

  final BubbleLook look;
  final ValueListenable<double> time;

  /// الوحدة = حجم الخط.
  final double unit;
  final double tailAlign;

  late final BubbleArtSpec _spec = bubbleArtOf(look);

  // شكل الجسم مع الذيل ما يتغير إلا لو تغير المقاس، فنحفظه.
  Size? _size;
  Path? _path;

  @override
  void paint(Canvas canvas, Size size) {
    final u = unit, s = _spec, pad = s.pad;
    final tail = u * BubbleArt.tailUnits;
    final body = Rect.fromLTRB(pad.left * u, pad.top * u, size.width - pad.right * u, size.height - pad.bottom * u - tail);
    if (body.width < u || body.height < u) return;
    final lo = body.left + u * .9, hi = body.right - u * .9;
    final tailX = lo >= hi ? body.center.dx : (body.left + body.width * tailAlign).clamp(lo, hi);
    final c = BubbleCtx(canvas: canvas, body: body, u: u, t: time.value, tail: tail, tailX: tailX);
    if (_size != size || _path == null) {
      _size = size;
      _path = Path.combine(PathOperation.union, s.shape(c), bbTail(body, tail, tailX, u));
    }
    final path = _path!;

    // ظل خفيف تحت (بدون blur عشان يخف)
    canvas.drawPath(path.shift(Offset(0, u * .1)), bbFill(Colors.black.withValues(alpha: .3)));
    s.back(c, path);
    canvas.drawPath(path, bbGrad(Rect.fromLTRB(body.left, body.top, body.right, body.bottom + tail), s.fill));
    canvas.save();
    canvas.clipPath(path);
    s.inner(c, path);
    canvas.restore();
    canvas.drawPath(path, bbLine(c.ow * 1.7, s.ink));
    s.front(c, path);
  }

  @override
  bool shouldRepaint(BubbleArtPainter old) => old.look != look || old.unit != unit || old.tailAlign != tailAlign;
}
