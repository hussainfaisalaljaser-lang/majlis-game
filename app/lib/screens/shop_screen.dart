import 'package:flutter/material.dart';

import '../models/game_view.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import '../widgets/game/policy_card.dart';

/// المتجر: إطارات وشخصيات وطاولات وكروت وردود، وباقات الجواهر.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, this.initialTab = 0});

  final int initialTab;

  static const avatarsTab = 1;
  static const diamondsTab = 5;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      initialIndex: initialTab,
      child: NightScaffold(
        appBar: AppBar(
          title: const Text('🛒 المتجر'),
          actions: [
            ValueListenableBuilder(
              valueListenable: Backend.instance.profile,
              builder: (context, p, _) => Row(
                children: [
                  CurrencyPill(icon: 'coin', amount: p.coins, infinite: p.dev),
                  const SizedBox(width: 6),
                  CurrencyPill(icon: 'gem', amount: p.diamonds, infinite: p.dev),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.muted,
            tabs: [
              Tab(text: '🖼️ الإطارات'),
              Tab(text: '👤 الشخصيات'),
              Tab(text: '🟫 الطاولات'),
              Tab(text: '🃏 الكروت'),
              Tab(text: '💬 الردود'),
              Tab(text: '💎 الجواهر'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ItemsGrid(slot: ShopSlot.frame),
            _ItemsGrid(slot: ShopSlot.avatar),
            _ItemsGrid(slot: ShopSlot.table),
            _ItemsGrid(slot: ShopSlot.cards),
            _ItemsGrid(slot: ShopSlot.reactions),
            _DiamondPacks(),
          ],
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
    final price = Backend.instance.profile.value.dev
        ? 'ببلاش لأنك مطور'
        : item.coins != null
        ? 'بـ ${arabicNumber(item.coins!)} ذهب'
        : 'بـ ${arabicNumber(item.diamonds!)} جوهرة';
    final after = switch (item.slot) {
      ShopSlot.avatar => 'وبتصير صورتك على طول',
      ShopSlot.reactions => 'وتقدر تستخدم ردودها في كل لعبة',
      ShopSlot.table => 'وبتشوفها في كل لعبة',
      _ => 'وبتلبسه على طول',
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text('تشتري "${item.name}"؟'),
        content: Text('$price، $after'),
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
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: widget.slot == ShopSlot.table ? 260 : 190,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 196,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          final equipped = switch (widget.slot) {
            ShopSlot.frame => p.frame == item.id,
            ShopSlot.cards => p.cards == item.id,
            ShopSlot.table => p.table == item.id,
            ShopSlot.avatar => p.avatar == item.avatar,
            ShopSlot.reactions => false,
          };
          final owned = item.isDefault || p.owned.contains(item.id);
          return _ItemCard(
            item: item,
            profile: p,
            equipped: equipped,
            owned: owned,
            busy: _busy == item.id,
            onBuy: Backend.instance.isReady ? () => _buy(item) : null,
            onEquip: !Backend.instance.isReady
                ? null
                : item.slot == ShopSlot.avatar
                ? () => _run(
                    item.id,
                    () => Backend.instance.updateProfile(name: p.name, avatar: item.avatar!),
                    '✅ صارت صورتك "${item.name}"',
                  )
                : () => _run(item.id, () => Backend.instance.equipItem(item.id), '✅ لبست "${item.name}"'),
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
    final affordable =
        profile.dev || (item.coins != null ? profile.coins >= item.coins! : profile.diamonds >= (item.diamonds ?? 0));
    final Widget action;
    if (owned && item.slot == ShopSlot.reactions) {
      action = const OutlinedButton(onPressed: null, child: Text('✅ عندك'));
    } else if (equipped) {
      action = OutlinedButton(onPressed: null, child: Text(item.slot == ShopSlot.avatar ? '✅ صورتك' : '✅ لابسه'));
    } else if (owned) {
      action = OutlinedButton(
        onPressed: busy ? null : onEquip,
        child: Text(item.slot == ShopSlot.avatar ? 'استخدمها' : 'البس'),
      );
    } else {
      action = FilledButton(
        onPressed: busy || !affordable ? null : onBuy,
        child: Amount(
          item.coins != null ? 'coin' : 'gem',
          arabicNumber(item.coins ?? item.diamonds!),
          size: 18,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
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
              child: Text(
                item.rarity.label,
                style: TextStyle(color: item.rarity.color, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: switch (item.slot) {
                ShopSlot.frame => PlayerAvatar(avatar: profile.avatar, style: item.frame, size: 72),
                ShopSlot.avatar => PlayerAvatar(avatar: item.avatar!, style: frameStyle(profile.frame), size: 80),
                ShopSlot.table => _TablePreview(skin: item.table!),
                ShopSlot.reactions => Text(
                  item.preview!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.5),
                ),
                ShopSlot.cards => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PolicyCard(policy: Policy.loyal, skin: item.cards, width: 50),
                    const SizedBox(width: 6),
                    PolicyCard(policy: Policy.traitor, skin: item.cards, width: 50),
                  ],
                ),
              },
            ),
          ),
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Semantics(label: 'غرض ${item.id}', child: action),
          ),
        ],
      ),
    );
  }
}

/// السجادة والصينية مصغرة، مثل ما تطلع في اللعبة.
class _TablePreview extends StatelessWidget {
  const _TablePreview({required this.skin});

  final TableSkin skin;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final w = c.maxWidth;
      final h = w / 2.1;
      return SizedBox(
        width: w,
        height: h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(skin.carpet, width: w, height: h, fit: BoxFit.fill),
            Image.asset(skin.tray, width: w * .46, height: h * .56, fit: BoxFit.fill),
          ],
        ),
      );
    },
  );
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
            'للحين تقدر تجمع جواهر من الهدية اليومية (اليوم السابع: ١٠ جواهر).',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFC9BFFF), height: 1.6),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 4.2,
          children: [
            for (final pack in diamondPacks)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Gfx('gem', size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${arabicNumber(pack.diamonds)} جوهرة',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                          ),
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
        ),
      ],
    );
  }
}
