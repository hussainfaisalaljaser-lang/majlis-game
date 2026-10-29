import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/backend.dart';
import '../theme.dart';
import 'common.dart';
import 'design.dart';
import 'design_social.dart';

/// نافذة الهدية اليومية: ٧ أيام، واليوم السابع فيه جواهر.
Future<void> showDailyReward(BuildContext context) {
  return showSocDialog<void>(
    context,
    title: 'الهدية اليومية',
    width: 620,
    builder: (_) => const _DailyRewardBody(),
  );
}

class _DailyRewardBody extends StatefulWidget {
  const _DailyRewardBody();

  @override
  State<_DailyRewardBody> createState() => _DailyRewardBodyState();
}

class _DailyRewardBodyState extends State<_DailyRewardBody> {
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
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        const Center(child: Gfx('gift', size: 52)),
        const SocPopupText('ادخل كل يوم وتكبر الهدية!', muted: true),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final (i, r) in dailyRewards.indexed)
              DailyDayTile(
                day: i + 1,
                coins: r.coins,
                diamonds: r.diamonds,
                done: i + 1 <= claimedThrough,
                current: i + 1 == today && available,
              ),
          ],
        ),
        if (_claimed != null) ...[
          const SizedBox(height: 12),
          Center(
            child: OutlinedText(
              '+${arabicNumber(_claimed!.coins)} ذهب${_claimed!.diamonds > 0 ? '  +${arabicNumber(_claimed!.diamonds)} جوهرة' : ''}',
              size: 26,
              gradient: goldTitleColors,
              stroke: const Color(0xFF3A1606),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB3261E), fontFamily: kufi, fontWeight: FontWeight.w800),
          ),
        ],
        const SizedBox(height: 14),
        Center(
          child: available
              ? SocButton(
                  label: _claiming ? 'لحظة…' : 'استلم',
                  tone: SocTone.green,
                  height: 50,
                  fontSize: 21,
                  width: 240,
                  onPressed: _claiming ? null : _claim,
                )
              : SocButton(
                  label: _claimed != null ? 'تمام' : 'تعال بكرة',
                  tone: _claimed != null ? SocTone.green : SocTone.orange,
                  height: 50,
                  fontSize: 21,
                  width: 240,
                  onPressed: () => Navigator.pop(context),
                ),
        ),
      ],
      ),
    );
  }
}

/// بطاقة يوم من أيام الهدية: يومه وأيقونة الهدية وكميتها. المستلم بعلامة صح، واليوم الحالي بحد ذهبي.
class DailyDayTile extends StatelessWidget {
  const DailyDayTile({
    super.key,
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
    final big = day == 7;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: big ? 100 : 66,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: done
                  ? const [Color(0xFFD9E5B0), Color(0xFFB9CF8A)]
                  : big
                  ? const [Color(0xFFFFE9A8), Color(0xFFEBC066)]
                  : const [Color(0xFFEBD6A8), Color(0xFFD6B97E)],
            ),
            border: Border.all(
              color: current ? const Color(0xFFE08A12) : (done ? const Color(0xFF5E8A2E) : const Color(0xFF7A5230)),
              width: current ? 3.2 : 2,
            ),
            boxShadow: [
              if (current) BoxShadow(color: const Color(0xFFFFB02E).withValues(alpha: .75), blurRadius: 14, spreadRadius: 1),
              BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 3, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Text(
                'يوم ${arabicNumber(day)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A5A3A), fontFamily: kufi, fontWeight: FontWeight.w800),
              ),
              Gfx(diamonds > 0 ? 'gem' : 'coin', size: big ? 38 : 30),
              Text(
                diamonds > 0 ? '${arabicNumber(coins)} + ${arabicNumber(diamonds)}' : arabicNumber(coins),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: socInk, fontFamily: kufi, height: 1.2),
              ),
            ],
          ),
        ),
        if (done)
          const PositionedDirectional(top: -8, end: -6, child: SocCheck(size: 22)),
      ],
    );
  }
}
