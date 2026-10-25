import 'package:flutter/material.dart';

import '../models/game_view.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import '../widgets/game/policy_card.dart';

/// المتجر: إطارات للصورة، وأشكال للكروت، وباقات الجواهر.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: NightScaffold(
        appBar: AppBar(
          title: const Text('🛒 المتجر'),
          actions: [
            ValueListenableBuilder(
              valueListenable: Backend.instance.profile,
              builder: (context, p, _) => Row(
                children: [
                  CurrencyPill(icon: '🪙', amount: p.coins),
                  const SizedBox(width: 6),
                  CurrencyPill(icon: '💎', amount: p.diamonds),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.muted,
            tabs: [Tab(text: '🖼️ الإطارات'), Tab(text: '🃏 الكروت'), Tab(text: '💎 الجواهر')],
          ),
        ),
        body: const TabBarView(
          children: [_ItemsGrid(slot: ShopSlot.frame), _ItemsGrid(slot: ShopSlot.cards), _DiamondPacks()],
        ),
      ),
    );
  }
}

class _ItemsGrid extends StatefulWidget {
  const _ItemsGrid({required this.slot});

  final ShopSlot slot;

  @override
  State<_ItemsGrid> createState() => _ItemsGridState();
}

class _ItemsGridState extends State<_ItemsGrid> {
  String? _busy;

  Future<void> _run(String id, Future<void> Function() action, String done) async {
    setState(() => _busy = id);
    try {
      await action();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _buy(ShopItem item) async {
    final price = item.coins != null ? '${arabicNumber(item.coins!)} 🪙' : '${arabicNumber(item.diamonds!)} 💎';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text('تشتري "${item.name}"؟'),
        content: Text('بـ $price، وبتلبسه على طول'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('اشترِ')),
        ],
      ),
    );
    if (ok == true) await _run(item.id, () => Backend.instance.buyItem(item.id), '✅ صار عندك "${item.name}"');
  }

  @override
  Widget build(BuildContext context) {
    final items = shopItems.where((i) => i.slot == widget.slot).toList();
    return ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) => GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: .72,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          final equipped = (widget.slot == ShopSlot.frame ? p.frame : p.cards) == item.id;
          final owned = item.isDefault || p.owned.contains(item.id);
          return _ItemCard(
            item: item,
            profile: p,
            equipped: equipped,
            owned: owned,
            busy: _busy == item.id,
            onBuy: Backend.instance.isReady ? () => _buy(item) : null,
            onEquip: Backend.instance.isReady
                ? () => _run(item.id, () => Backend.instance.equipItem(item.id), '✅ لبست "${item.name}"')
                : null,
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.profile,
    required this.equipped,
    required this.owned,
    required this.busy,
    this.onBuy,
    this.onEquip,
  });

  final ShopItem item;
  final Profile profile;
  final bool equipped;
  final bool owned;
  final bool busy;
  final VoidCallback? onBuy;
  final VoidCallback? onEquip;

  @override
  Widget build(BuildContext context) {
    final affordable = item.coins != null ? profile.coins >= item.coins! : profile.diamonds >= (item.diamonds ?? 0);
    final Widget action;
    if (equipped) {
      action = const OutlinedButton(onPressed: null, child: Text('✅ لابسه'));
    } else if (owned) {
      action = OutlinedButton(onPressed: busy ? null : onEquip, child: const Text('البس'));
    } else {
      action = FilledButton(
        onPressed: busy || !affordable ? null : onBuy,
        child: Text(item.coins != null ? '${arabicNumber(item.coins!)} 🪙' : '${arabicNumber(item.diamonds!)} 💎'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: equipped ? AppColors.green : AppColors.line, width: equipped ? 1.5 : 1),
      ),
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: item.rarity.color.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(item.rarity.label, style: TextStyle(color: item.rarity.color, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
          Expanded(
            child: Center(
              child: item.slot == ShopSlot.frame
                  ? PlayerAvatar(avatar: profile.avatar, style: item.frame, size: 84)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(scale: .62, child: PolicyCard(policy: Policy.loyal, skin: item.cards)),
                        Transform.scale(scale: .62, child: PolicyCard(policy: Policy.traitor, skin: item.cards)),
                      ],
                    ),
            ),
          ),
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: Semantics(label: 'غرض ${item.id}', child: action)),
        ],
      ),
    );
  }
}

class _DiamondPacks extends StatelessWidget {
  const _DiamondPacks();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6D5BD0)),
          ),
          child: const Text(
            '🚧 شراء الجواهر بفلوس حقيقية يشتغل بعد ما نربط اللعبة بـ Google Play.\n'
            'للحين تقدر تجمع جواهر من الهدية اليومية (اليوم السابع: ١٠ 💎).',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFC9BFFF), height: 1.6),
          ),
        ),
        const SizedBox(height: 14),
        for (final pack in diamondPacks)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Text('💎', style: TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${arabicNumber(pack.diamonds)} جوهرة', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      if (pack.bonus.isNotEmpty)
                        Text('${pack.bonus} زيادة', style: const TextStyle(color: AppColors.green, fontSize: 12)),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(110, 44)),
                  onPressed: null,
                  child: Text(pack.price),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
