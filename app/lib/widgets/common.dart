import 'package:flutter/material.dart';

import '../models/shop.dart';
import '../theme.dart';

/// يحول الأرقام للأرقام العربية مع فاصل الآلاف: 12500 ← ١٢٬٥٠٠
String arabicNumber(int n) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  final raw = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buf.write('٬');
    buf.write(digits[raw.codeUnitAt(i) - 48]);
  }
  return buf.toString();
}

class CurrencyPill extends StatelessWidget {
  const CurrencyPill({super.key, required this.icon, required this.amount, this.onAdd});

  final String icon;
  final int amount;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon),
          const SizedBox(width: 4),
          Text(arabicNumber(amount), style: const TextStyle(fontWeight: FontWeight.w700)),
          if (onAdd != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onAdd,
              child: const CircleAvatar(
                radius: 9,
                backgroundColor: AppColors.green,
                child: Icon(Icons.add, size: 14, color: Color(0xFF062210)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// صورة اللاعب. [frame] لون للتمييز (مثل الرئيس أو المختار)، و[style] إطار من المتجر.
/// لو الاثنين موجودين، لون التمييز يغلب.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.emoji, this.frame, this.style, this.size = 52});

  final String emoji;
  final Color? frame;
  final FrameStyle? style;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = this.style;
    if (frame == null && style != null) {
      final ring = size * .07;
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(ring),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: [...style.colors, style.colors.first]),
          boxShadow: style.glow == null ? null : [BoxShadow(color: style.glow!.withValues(alpha: .6), blurRadius: 14)],
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
          child: Text(emoji, style: TextStyle(fontSize: size * .48)),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        shape: BoxShape.circle,
        border: Border.all(color: frame ?? AppColors.line, width: frame == null ? 2 : 3),
        boxShadow: frame == null ? null : [BoxShadow(color: frame!.withValues(alpha: .5), blurRadius: 12)],
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * .5)),
    );
  }
}
