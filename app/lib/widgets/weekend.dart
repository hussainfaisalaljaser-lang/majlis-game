import 'dart:async';

import 'package:flutter/material.dart';

import '../models/events.dart';
import '../theme.dart';
import 'common.dart';

/// كم باقي على وقت: «يوم و ٤ ساعات» أو «٣ ساعات و ١٠ دقايق» أو «١٠ دقايق».
String timeLeft(Duration d) {
  if (d.isNegative) return 'دقيقة';
  final days = d.inDays, hours = d.inHours % 24, minutes = d.inMinutes % 60;
  String unit(int n, String one, String two, String many) => switch (n) {
    1 => one,
    2 => two,
    _ => '${arabicNumber(n)} $many',
  };
  if (days > 0) {
    final h = hours > 0 ? ' و ${unit(hours, 'ساعة', 'ساعتين', 'ساعات')}' : '';
    return '${unit(days, 'يوم', 'يومين', 'أيام')}$h';
  }
  if (hours > 0) {
    final m = minutes > 0 ? ' و ${unit(minutes, 'دقيقة', 'دقيقتين', 'دقايق')}' : '';
    return '${unit(hours, 'ساعة', 'ساعتين', 'ساعات')}$m';
  }
  return unit(minutes < 1 ? 1 : minutes, 'دقيقة', 'دقيقتين', 'دقايق');
}

/// يعيد البناء كل دقيقة، عشان العدادات والأحداث اللي تبدأ وتخلص بوقت.
class MinuteTicker extends StatefulWidget {
  const MinuteTicker({super.key, required this.builder});

  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<MinuteTicker> createState() => _MinuteTickerState();
}

class _MinuteTickerState extends State<MinuteTicker> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}

/// شارة نهاية الأسبوع: «ذهب مضاعف ×٢» وكم باقي. ما تطلع إلا وقت الحدث.
class WeekendChip extends StatelessWidget {
  const WeekendChip({super.key, this.compact = false});

  /// بدون العداد (للأماكن الضيقة).
  final bool compact;

  @override
  Widget build(BuildContext context) => MinuteTicker(
    builder: (context, now) {
      final w = Weekend.at(now);
      if (!w.on) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.fromLTRB(4, 2, 10, 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFB45309), Color(0xFF7C2D12)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold, width: 1.5),
          boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: .45), blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFD48B12)]),
              ),
              child: const Text(
                '×٢',
                style: TextStyle(fontFamily: kufi, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.goldInk),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              compact ? 'ذهب مضاعف' : 'ذهب مضاعف · باقي ${timeLeft(w.ends.difference(now))}',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFFFE7C2)),
            ),
          ],
        ),
      );
    },
  );
}
