import 'package:flutter/material.dart';

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

/// صورة اللاعب مع إطار (الإطارات من المتجر).
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.emoji, this.frame, this.size = 52});

  final String emoji;
  final Color? frame;
  final double size;

  @override
  Widget build(BuildContext context) {
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
