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
        padding: const EdgeInsets.fromLTRB(4, 2, 12, 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD9701E), Color(0xFF8E3A10)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8B54E), width: 2),
          boxShadow: [
            const BoxShadow(color: Color(0xFF3A1606), offset: Offset(0, 2)),
            BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: .4), blurRadius: 10),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF0B8), Color(0xFFE8A22B)],
                ),
                border: Border.all(color: const Color(0xFF4A2406), width: 1.5),
              ),
              child: const Text(
                '×٢',
                style: TextStyle(
                  fontFamily: kufi,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldInk,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                compact ? 'ذهب مضاعف' : 'ذهب مضاعف · باقي ${timeLeft(w.ends.difference(now))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: kufi,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFF0D2),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
