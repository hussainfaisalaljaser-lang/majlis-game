import 'package:flutter/material.dart';

import '../models/table_tier.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'waiting_screen.dart';

/// اختيار عدد اللاعبين ومستوى الطاولة، مثل يلا لودو.
class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  // لين نربط الحسابات بـ Firebase، بيانات اللاعب ثابتة.
  static const _playerLevel = 1;
  static const _isVip = false;

  // لين نسوي شاشة الملف الشخصي.
  static const _name = 'ضيف';
  static const _avatar = '😎';

  int _playerCount = 7;
  TableTier _tier = tableTiers[1];
  bool _busy = false;

  bool _locked(TableTier t) => t.requiredLevel > _playerLevel || (t.vipOnly && !_isVip);

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
    await _enter(() => Backend.instance.joinRoom(code, name: _name, avatar: _avatar));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🕵️ مجلس الخونة', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: [
                  for (final n in playerCounts)
                    ButtonSegment(value: n, label: Text('${arabicNumber(n)} لاعبين')),
                ],
                selected: {_playerCount},
                onSelectionChanged: (s) => setState(() => _playerCount = s.first),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: tableTiers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (context, i) {
                    final t = tableTiers[i];
                    final locked = _locked(t);
                    return _TierTile(
                      tier: t,
                      locked: locked,
                      selected: t == _tier,
                      onTap: locked ? null : () => setState(() => _tier = t),
                    );
                  },
                ),
              ),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _enter(
                          () => Backend.instance.quickMatch(
                            name: _name,
                            avatar: _avatar,
                            maxPlayers: _playerCount,
                            tierId: _tier.id,
                          ),
                          tier: _tier,
                        ),
                child: Text(_busy ? 'لحظة…' : '▶ العب الحين'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _enter(
                          Backend.instance.isReady
                              ? () => Backend.instance.createRoom(name: _name, avatar: _avatar, maxPlayers: _playerCount)
                              : null,
                        ),
                child: const Text('➕ أنشئ روم خاص (بكود)'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy || !Backend.instance.isReady ? null : _joinByCode,
                child: const Text('🔑 ادخل بكود صديق'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierTile extends StatelessWidget {
  const _TierTile({required this.tier, required this.locked, required this.selected, this.onTap});

  final TableTier tier;
  final bool locked;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hint = tier.vipOnly
        ? 'لأعضاء VIP فقط'
        : tier.requiredLevel > 0
            ? 'يفتح في مستوى ${arabicNumber(tier.requiredLevel)}'
            : null;
    return Opacity(
      opacity: locked ? .45 : 1,
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
                    'الفوز: +${arabicNumber(tier.reward)}',
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
