import 'package:flutter/material.dart';

import '../models/events.dart';
import '../models/profile.dart';
import '../models/table_tier.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/mode_picker.dart';
import '../widgets/ui.dart';
import '../widgets/venues.dart';
import '../widgets/weekend.dart';
import 'waiting_screen.dart';

/// اللعب العشوائي: تختار عدد اللاعبين ومستوى الطاولة، وندخلك مع لاعبين من كل مكان (مثل يلا لودو).
/// اللعب مع الأصحاب في «خاص» (private_screen.dart).
class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  int _playerCount = 7;
  TableTier _tier = tableTiers[0];
  bool _busy = false;

  /// الوضع السريع: نفس اللعبة بنص الوقت (حوالي ٥ دقايق).
  bool _quick = false;

  /// طور الشخصيات (بدونه الطور العادي بدون أدوار خاصة).
  bool _roles = false;

  bool _locked(Profile p, TableTier t) => t.requiredLevel > p.level || (t.vipOnly && !p.vip);

  /// ينفذ طلب للسيرفر ويفتح غرفة الانتظار. بدون سيرفر (نسخة الويب) يفتح العرض التجريبي.
  Future<void> _enter(Future<String> Function()? request, {TableTier? tier}) async {
    if (request == null || !Backend.instance.isReady) {
      _openWaiting(null, tier ?? _tier);
      return;
    }
    setState(() => _busy = true);
    try {
      _openWaiting(await request(), tier);
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openWaiting(String? code, TableTier? tier) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WaitingScreen(tier: tier, playerCount: _playerCount, code: code),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gfx('games', size: 30),
            SizedBox(width: 8),
            Text('عشوائي · مع لاعبين من كل مكان', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Row(
          children: [
            // عدد اللاعبين والأزرار
            SizedBox(
              width: 290,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      segments: [
                        for (final n in playerCounts) ButtonSegment(value: n, label: Text('${arabicNumber(n)} لاعبين')),
                      ],
                      selected: {_playerCount},
                      onSelectionChanged: (s) => setState(() => _playerCount = s.first),
                    ),
                    const SizedBox(height: 8),
                    ModePicker(roles: _roles, onChanged: (v) => setState(() => _roles = v)),
                    const SizedBox(height: 6),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      segments: const [
                        ButtonSegment(value: false, label: Text('عادي'), icon: Gfx('hourglass', size: 18)),
                        ButtonSegment(value: true, label: Text('سريع'), icon: Gfx('bolt', size: 18)),
                      ],
                      selected: {_quick},
                      onSelectionChanged: (s) => setState(() => _quick = s.first),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _quick ? 'نص الوقت لكل دور، واللعبة حوالي ٥ دقايق' : 'الوقت العادي، واللعبة حوالي ١٠ دقايق',
                      style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                    ),
                    const Spacer(),
                    const WeekendChip(),
                    const SizedBox(height: 6),
                    const Text(
                      'الطاولات العامة تحسب في تصنيفك',
                      style: TextStyle(color: AppColors.muted, fontSize: 11.5),
                    ),
                    const SizedBox(height: 4),
                    GameButton(
                      label: _busy ? 'لحظة…' : 'العب الحين',
                      icon: const Gfx('games', size: 28),
                      semantics: 'العب الحين',
                      onPressed: _busy
                          ? null
                          : () => _enter(
                              () => Backend.instance.quickMatch(
                                maxPlayers: _playerCount,
                                tierId: _tier.id,
                                quick: _quick,
                                roles: _roles,
                              ),
                              tier: _tier,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            // مستويات الطاولات
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: Backend.instance.profile,
                builder: (context, profile, _) => GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 16, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 9,
                    crossAxisSpacing: 9,
                    mainAxisExtent: 70,
                  ),
                  itemCount: tableTiers.length,
                  itemBuilder: (context, i) {
                    final t = tableTiers[i];
                    final locked = _locked(profile, t);
                    final poor = !profile.dev && profile.coins < t.entryFee;
                    return _TierTile(
                      tier: t,
                      players: _playerCount,
                      locked: locked,
                      poor: poor,
                      selected: t == _tier,
                      onTap: locked || poor ? null : () => setState(() => _tier = t),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierTile extends StatelessWidget {
  const _TierTile({
    required this.tier,
    required this.players,
    required this.locked,
    required this.poor,
    required this.selected,
    this.onTap,
  });

  final TableTier tier;
  final int players;
  final bool locked;
  final bool poor;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hint = locked
        ? (tier.vipOnly ? 'لأعضاء VIP فقط' : 'يفتح في مستوى ${arabicNumber(tier.requiredLevel)}')
        : poor
        ? 'ما عندك ذهب كافي'
        : null;
    return Opacity(
      opacity: locked || poor ? .45 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2B2A22) : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? AppColors.gold : AppColors.line, width: 1.5),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // مكان الطاولة ورا الكلام: لمحة من اللي بتشوفه لما تدخل.
              Positioned.fill(
                left: -14,
                right: -14,
                top: -12,
                bottom: -12,
                child: _VenuePeek(tier: tier, selected: selected),
              ),
              _tileRow(hint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileRow(String? hint) => Row(
    children: [
      Opacity(opacity: locked ? .5 : 1, child: Gfx(tier.icon, size: 40)),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(tier.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                if (locked) ...[const SizedBox(width: 5), const Gfx('lock', size: 18)],
              ],
            ),
            if (hint != null) Text(hint, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Amount('coin', arabicNumber(tier.entryFee), size: 16),
          Amount(
            'trophy',
            // نهاية الأسبوع: الجائزة مضاعفة.
            arabicNumber(tier.pot(players) * Weekend.at(DateTime.now()).boost),
            size: 15,
            style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ],
  );
}

/// رسمة مكان الطاولة (ثابتة) مقصوصة على البطاقة، ومغطاة بظل من جهة الكلام.
class _VenuePeek extends StatelessWidget {
  const _VenuePeek({required this.tier, required this.selected});

  final TableTier tier;
  final bool selected;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 400,
            height: 225,
            child: RepaintBoundary(child: CustomPaint(painter: venueBackdrop(venueOf(tier.id)), isComplex: true)),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [
                (selected ? const Color(0xFF2B2A22) : AppColors.card).withValues(alpha: .97),
                (selected ? const Color(0xFF2B2A22) : AppColors.card).withValues(alpha: .62),
                (selected ? const Color(0xFF2B2A22) : AppColors.card).withValues(alpha: .9),
              ],
              stops: const [.28, .62, 1],
            ),
          ),
        ),
      ],
    ),
  );
}
