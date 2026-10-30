import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// يرسم الـ[Text] اللي تحته، وفوقه نفس الكلام بنفس مكانه معبّى بتدرج عمودي (من فوق مربع الكلام لتحته).
///
/// بدال ShaderMask: ذاك يرسم الكلام بصورة جانبية مؤقتة ويلوّنها، وبعض الجوالات تومّض فيها أو تطلع فيها بقايا
/// قديمة. هنا الحروف نفسها تنرسم بفرشاة متدرجة، والشكل نفسه.
///
/// الـ[child] لازم يكون [Text] (ما بينهم شي يحرّكه أو يغير مقاسه). تبي التدرج بس بدون الكلام الأصلي؟ خل لونه شفاف.
class GradientFill extends SingleChildRenderObjectWidget {
  const GradientFill({super.key, required this.colors, required Widget super.child});

  /// ألوان التدرج من فوق لتحت.
  final List<Color> colors;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderGradientFill(colors);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderGradientFill).colors = colors;
}

class _RenderGradientFill extends RenderProxyBox {
  _RenderGradientFill(this._colors);

  List<Color> _colors;
  set colors(List<Color> value) {
    if (listEquals(value, _colors)) return;
    _colors = value;
    _laidOut = null;
    markNeedsPaint();
  }

  /// نفس كلام الـ[Text] بالتدرج.
  final _fill = TextPainter();

  /// على وش انقاس [_fill] آخر مرة (كلام الـ[Text] وإعداداته ومقاسه): ما يعيده إلا لو تغير شي.
  Object? _laidOut;
  bool _clip = false;

  /// الـ[Text] نفسه (لو بينّا صناديق بنفس مكانه ومقاسه، مثل منطقة الماوس وقت التحديد، نتعداها).
  RenderParagraph? get _paragraph {
    var box = child;
    while (box is RenderProxyBox) {
      box = box.child;
    }
    return box is RenderParagraph ? box : null;
  }

  void _sync(RenderParagraph text) {
    final key = (
      text.text,
      text.textAlign,
      text.textDirection,
      text.softWrap,
      text.overflow,
      text.textScaler,
      text.maxLines,
      text.locale,
      text.strutStyle,
      text.textWidthBasis,
      text.textHeightBehavior,
      text.constraints,
      size,
    );
    if (key == _laidOut) return;
    _laidOut = key;
    // التدرج على مربع الكلام كله (مثل ShaderMask). الفرشاة تمشي مع الرسم، فالرسم يبدأ من زاوية الكلام (شوف paint).
    final brush = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _colors,
      ).createShader(Offset.zero & size);
    _fill
      ..text = _restyle(text.text, brush)
      ..textAlign = text.textAlign
      ..textDirection = text.textDirection
      ..textScaler = text.textScaler
      ..maxLines = text.maxLines
      ..ellipsis = text.overflow == TextOverflow.ellipsis ? '…' : null
      ..locale = text.locale
      ..strutStyle = text.strutStyle
      ..textWidthBasis = text.textWidthBasis
      ..textHeightBehavior = text.textHeightBehavior;
    // نفس قياس RenderParagraph بالضبط، فالحروف تطابق حروف الـ[Text] حرف بحرف.
    final c = text.constraints;
    final widthMatters = text.softWrap || text.overflow == TextOverflow.ellipsis;
    _fill.layout(minWidth: c.minWidth, maxWidth: widthMatters ? c.maxWidth : double.infinity);
    final overflowed = size.width < _fill.width || size.height < _fill.height || _fill.didExceedMaxLines;
    _clip = overflowed && text.overflow != TextOverflow.visible;
  }

  /// نفس الكلام بستايلاته، بس الحروف بالتدرج وبدون ظل (الظل تحت مع الكلام الأصلي).
  static InlineSpan _restyle(InlineSpan span, Paint brush) => switch (span) {
    TextSpan() => TextSpan(
      text: span.text,
      style: (span.style ?? const TextStyle()).copyWith(foreground: brush, shadows: const []),
      children: span.children?.map((child) => _restyle(child, brush)).toList(),
      locale: span.locale,
      spellOut: span.spellOut,
    ),
    _ => span,
  };

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final text = _paragraph;
    if (text == null || size.isEmpty) return;
    _sync(text);
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    if (_clip) canvas.clipRect(Offset.zero & size);
    _fill.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }
}
