import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/table_tier.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'waiting_screen.dart';

/// اختيار عدد اللاعبين ومستوى الطاولة، مثل يلا لودو.
class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  int _playerCount = 7;
  TableTier _tier = tableTiers[0];
  bool _busy = false;

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
      MaterialPageRoute(builder: (_) => WaitingScreen(tier: tier, playerCount: _playerCount, code: code)),
    );
  }

  Future<void> _joinByCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔑 ادخل كود الروم'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 5,
          textCapitalization: TextCapitalization.characters,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 6, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('دخول')),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    await _enter(() => Backend.instance.joinRoom(code));
  }

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      appBar: AppBar(title: const Text('🕵️ مجلس الخونة', style: TextStyle(fontWeight: FontWeight.w800))),
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
                        for (final n in playerCounts)
                          ButtonSegment(value: n, label: Text('${arabicNumber(n)} لاعبين')),
                      ],
                      selected: {_playerCount},
                      onSelectionChanged: (s) => setState(() => _playerCount = s.first),
                    ),
                    const Spacer(),
                    GameButton(
                      label: _busy ? 'لحظة…' : '▶ العب الحين',
                      semantics: 'العب الحين',
                      onPressed: _busy
                          ? null
                          : () => _enter(
                                () => Backend.instance.quickMatch(maxPlayers: _playerCount, tierId: _tier.id),
                                tier: _tier,
                              ),
                    ),
                    const SizedBox(height: 10),
                    GameButton(
                      label: '➕ روم خاص',
                      semantics: 'أنشئ روم خاص',
                      tone: ButtonTone.purple,
                      height: 46,
                      fontSize: 16,
                      onPressed: _busy
                          ? null
                          : () => _enter(
                                Backend.instance.isReady
                                    ? () => Backend.instance.createRoom(maxPlayers: _playerCount)
                                    : null,
                              ),
                    ),
                    const SizedBox(height: 10),
                    GameButton(
                      label: '🔑 ادخل بكود',
                      semantics: 'ادخل بكود صديق',
                      tone: ButtonTone.ghost,
                      height: 46,
                      fontSize: 16,
                      onPressed: _busy || !Backend.instance.isReady ? null : _joinByCode,
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
                    final poor = profile.coins < t.entryFee;
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tier.emoji} ${tier.name}${locked ? ' 🔒' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    if (hint != null) Text(hint, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('🪙 ${arabicNumber(tier.entryFee)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(
                    '🏆 ${arabicNumber(tier.pot(players))}',
                    style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
