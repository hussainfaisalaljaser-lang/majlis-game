import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/backend.dart';
import '../theme.dart';
import 'common.dart';

/// نافذة الهدية اليومية: ٧ أيام، واليوم السابع فيه جواهر.
Future<void> showDailyReward(BuildContext context) {
  return showDialog<void>(context: context, builder: (_) => const _DailyRewardDialog());
}

class _DailyRewardDialog extends StatefulWidget {
  const _DailyRewardDialog();

  @override
  State<_DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<_DailyRewardDialog> {
  bool _claiming = false;
  ({int coins, int diamonds, int streak})? _claimed;
  String? _error;

  Future<void> _claim() async {
    setState(() => _claiming = true);
    try {
      final r = await Backend.instance.claimDaily();
      setState(() => _claimed = r);
    } on BackendException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Backend.instance.profile.value;
    final available = p.dailyAvailable && _claimed == null && Backend.instance.isReady;
    final today = _claimed?.streak ?? p.nextDailyDay;
    final claimedThrough = available ? today - 1 : today;

    return AlertDialog(
      backgroundColor: AppColors.panel,
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Gfx('gift', size: 34), SizedBox(width: 8), Text('الهدية اليومية')],
      ),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ادخل كل يوم وتكبر الهدية!', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final (i, r) in dailyRewards.indexed)
                  _DayTile(
                    day: i + 1,
                    coins: r.coins,
                    diamonds: r.diamonds,
                    done: i + 1 <= claimedThrough,
                    current: i + 1 == today && available,
                  ),
              ],
            ),
            if (_claimed != null) ...[
              const SizedBox(height: 14),
              Text(
                '+${arabicNumber(_claimed!.coins)} ذهب${_claimed!.diamonds > 0 ? '  +${arabicNumber(_claimed!.diamonds)} جوهرة' : ''}',
                style: const TextStyle(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.traitor)),
            ],
          ],
        ),
      ),
      actions: [
        if (available)
          FilledButton(onPressed: _claiming ? null : _claim, child: Text(_claiming ? 'لحظة…' : 'استلم'))
        else
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(_claimed != null ? 'تمام' : 'تعال بكرة')),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.coins,
    required this.diamonds,
    required this.done,
    required this.current,
  });

  final int day;
  final int coins;
  final int diamonds;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: day == 7 ? 100 : 66,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: done ? const Color(0xFF163D26) : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: current ? AppColors.gold : AppColors.line, width: current ? 2 : 1),
      ),
      child: Column(
        children: [
          Text('يوم ${arabicNumber(day)}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          done ? const Gfx('check', size: 26) : Gfx(diamonds > 0 ? 'gem' : 'coin', size: 26),
          Text(
            diamonds > 0 ? '${arabicNumber(coins)} + ${arabicNumber(diamonds)}' : arabicNumber(coins),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
