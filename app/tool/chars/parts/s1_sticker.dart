// ملصقات المجلس: تركيب الملصق (الشخصية + شريط الكلام). القص الأبيض (die-cut) يتم في بايثون
// (s1_sticker_export.py) على ألفا الصورة المرسومة هنا.
//
// الإحداثيات: لوحة الملصق ٢١٦ وحدة = ٢٠٠ وحدة الشخصية + هامش ٨ من كل جهة (مكان الحافة البيضاء).
import 'dart:ui';

import 'package:flutter/painting.dart' show TextAlign, TextDirection, TextPainter, TextSpan, TextStyle, FontWeight;

import '../core/pen.dart';
import '../scene.dart';
import '../spec.dart';

const double kStickerFrame = 216;
const double kStickerMargin = 8;

/// لون كلام الشريط لكل باقة (نفس ألوان الملصقات القديمة).
const Map<String, Color> s1CaptionColor = {
  'stk_basic': Color(0xFFFFF4DA),
  'stk_shock': Color(0xFFFFDA4A),
  'stk_laugh': Color(0xFFFFC93C),
  'stk_coffee': Color(0xFFFFF4DA),
  'stk_angry': Color(0xFFFF8A80),
  'stk_nervous': Color(0xFF9EDBFF),
  'stk_detective': Color(0xFFFFE27A),
};

/// يرسم الملصق كامل (شخصية مقصوصة من تحت + شريط الكلام) على لوحة [px]×[px] شفافة.
void paintSticker(Canvas canvas, CharSpec spec, String caption, Color captionColor, {double px = 1024}) {
  canvas.save();
  canvas.scale(px / kStickerFrame);
  canvas.translate(kStickerMargin, kStickerMargin);

  // الشخصية: مقصوصة عند الكتفين (زوايا تحت مدورة).
  final clip = Path()..addRRect(RRect.fromLTRBAndCorners(-8, -8, 208, 184, bottomLeft: const Radius.circular(16), bottomRight: const Radius.circular(16)));
  canvas.save();
  canvas.clipPath(clip);
  paintChar(canvas, spec, px: 200);
  canvas.restore();

  _paintBanner(canvas, caption, captionColor);
  canvas.restore();
}

void _paintBanner(Canvas c, String text, Color fill) {
  TextPainter mk(Paint? stroke, Color color) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Baloo',
        fontWeight: FontWeight.w800,
        fontSize: 21,
        height: 1.0,
        color: stroke == null ? color : null,
        foreground: stroke,
      ),
    ),
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.center,
  )..layout();

  final strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.2
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = Style.ink;
  final back = mk(strokePaint, Style.ink);
  final front = mk(null, fill);

  const maxText = 150.0;
  final k = front.width > maxText ? maxText / front.width : 1.0;
  final tw = front.width * k;
  final w = (tw + 30).clamp(78.0, 178.0);
  const h = 31.0;
  const cy = 177.0;
  final rect = Rect.fromCenter(center: const Offset(100, cy), width: w, height: h);
  final rr = RRect.fromRectAndRadius(rect, const Radius.circular(10));

  // ظل الشريط على الجسم
  c.save();
  c.clipPath(Path()..addRect(const Rect.fromLTRB(-8, -8, 208, 184)));
  c.drawRRect(rr.shift(const Offset(0, 2.6)), Paint()..color = withA(Style.ink, .35));
  c.restore();

  const wood = Color(0xFF6E2336);
  const woodDark = Color(0xFF451424);
  c.drawRRect(
    rr,
    Paint()..shader = Gradient.linear(Offset(0, rect.top), Offset(0, rect.bottom), [const Color(0xFF8A2E44), wood, woodDark], [0, .45, 1]),
  );
  // لمعة فوق
  c.save();
  c.clipRRect(rr);
  c.drawRect(Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + 4.6), Paint()..color = withA(const Color(0xFFFFFFFF), .13));
  c.restore();
  // خط ذهب داخلي
  c.drawRRect(rr.deflate(2.6), Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.1
    ..color = withA(const Color(0xFFE9B84A), .85));
  // الحد
  c.drawRRect(rr, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = Style.line
    ..strokeJoin = StrokeJoin.round
    ..color = Style.ink);

  // النص (حد داكن ثم تعبئة)
  c.save();
  c.translate(100 - tw / 2, cy - front.height * k / 2 + 0.6);
  c.scale(k);
  back.paint(c, Offset.zero);
  front.paint(c, Offset.zero);
  c.restore();
}
