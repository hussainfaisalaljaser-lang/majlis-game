import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/telemetry.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/item_preview.dart';
import '../widgets/ui.dart';

/// أقسام المتجر: الأيقونة والاسم ونوع الأغراض.
const _sections = [
  (icon: 'cat_frame', name: 'الإطارات', slot: ShopSlot.frame),
  (icon: 'cat_avatar', name: 'الشخصيات', slot: ShopSlot.avatar),
  (icon: 'cat_bubble', name: 'الفقاعات', slot: ShopSlot.bubble),
  (icon: 'cat_sticker', name: 'الملصقات', slot: ShopSlot.reactions),
  (icon: 'cat_table', name: 'الطاولات', slot: ShopSlot.table),
  (icon: 'cat_cards', name: 'الكروت', slot: ShopSlot.cards),
  (icon: 'gem', name: 'الجواهر', slot: null),
];

/// المتجر: قائمة الأقسام على الجنب، والأغراض بشبكة، وكل غرض تقدر تشوفه كبير قبل ما تشتريه.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.initialTab = 0});

  final int initialTab;

  static const avatarsTab = 1;
  static const stickersTab = 3;
  static const diamondsTab = 6;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final section = _sections[_tab];
    return NightScaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Gfx('shop', size: 30), SizedBox(width: 8), Text('المتجر')],
        ),
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
      ),
      body: SafeArea(
        top: false,
        child: Row(
          children: [
            _Rail(selected: _tab, onSelect: (i) => setState(() => _tab = i)),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: section.slot == null
                    ? const _DiamondPacks(key: ValueKey('gems'))
                    : _ItemsGrid(key: ValueKey(section.slot), slot: section.slot!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// أقسام المتجر على الجنب بأيقوناتنا.
class _Rail extends StatelessWidget {
  const _Rail({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    width: 92,
    margin: const EdgeInsetsDirectional.fromSTEB(10, 4, 4, 10),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .25),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.line),
    ),
    child: ListView(
      padding: const EdgeInsets.symmetric(vertical: 6),
      children: [
        for (final (i, s) in _sections.indexed)
          Semantics(
            button: true,
            selected: i == selected,
            label: 'قسم ${s.name}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  gradient: i == selected
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.gold.withValues(alpha: .28), AppColors.gold.withValues(alpha: .08)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: i == selected ? AppColors.gold : Colors.transparent, width: 1.4),
                ),
                child: Column(
                  children: [
                    AnimatedScale(
                      scale: i == selected ? 1.12 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Gfx(s.icon, size: 34),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.name,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: i == selected ? AppColors.gold : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// حالة الغرض عند اللاعب.
enum _State { equipped, owned, buy, locked }

_State _stateOf(ShopItem item, Profile p) {
  final owned = p.owns(item.id);
  final equipped = switch (item.slot) {
    ShopSlot.frame => p.frame == item.id,
    ShopSlot.cards => p.cards == item.id,
    ShopSlot.table => p.table == item.id,
    ShopSlot.bubble => p.bubble == item.id,
    ShopSlot.avatar => p.avatar == item.avatar,
    ShopSlot.reactions => false,
  };
  if (equipped) return _State.equipped;
  if (owned) return _State.owned;
  return item.buyable ? _State.buy : _State.locked;
}

class _ItemsGrid extends StatefulWidget {
  const _ItemsGrid({super.key, required this.slot});

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

  Future<void> _act(ShopItem item, Profile p) async {
    final b = Backend.instance;
    if (!b.isReady) return;
    switch (_stateOf(item, p)) {
      case _State.equipped || _State.locked:
        return;
      case _State.owned:
        if (item.slot == ShopSlot.avatar) {
          return _run(item.id, () => b.updateProfile(name: p.name, avatar: item.avatar!), 'صارت صورتك "${item.name}"');
        }
        if (item.equippable) return _run(item.id, () => b.equipItem(item.id), 'لبست "${item.name}"');
      case _State.buy:
        final ok = await showItemPreview(context, item, buy: true);
        if (ok == true) {
          await _run(item.id, () async {
            await b.buyItem(item.id);
            if (!p.dev) {
              Telemetry.spend(item.id, item.coins != null ? 'coins' : 'diamonds', item.coins ?? item.diamonds ?? 0);
            }
          }, 'صار عندك "${item.name}"');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final i in catalog)
        if (i.slot == widget.slot) i,
    ];
    // اللي ينشرى أول، وبعده هدايا المستويات والموسم والأبطال.
    items.sort((a, b) => (a.buyable || a.isDefault ? 0 : 1).compareTo(b.buyable || b.isDefault ? 0 : 1));
    final wide = widget.slot == ShopSlot.table || widget.slot == ShopSlot.reactions;
    return ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(8, 6, 14, 16),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: wide ? 250 : 178,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: wide ? 214 : 214,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return _ItemCard(
            item: item,
            profile: p,
            state: _stateOf(item, p),
            busy: _busy == item.id,
            onPreview: () => showItemPreview(context, item),
            onAction: () => _act(item, p),
          );
        },
      ),
    );
  }
}

/// نافذة المعاينة الكبيرة. لو [buy] تطلع بزر الشراء وترجع true لو وافق.
Future<bool?> showItemPreview(BuildContext context, ShopItem item, {bool buy = false}) {
  final p = Backend.instance.profile.value;
  final price = item.coins != null ? ('coin', item.coins!) : ('gem', item.diamonds ?? 0);
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'معاينة',
    barrierColor: Colors.black.withValues(alpha: .7),
    transitionDuration: const Duration(milliseconds: 260),
    transitionBuilder: (context, a, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: a, child: child),
    ),
    pageBuilder: (context, _, _) => Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 560,
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -.4),
              radius: 1.1,
              colors: [item.rarity.color.withValues(alpha: .35), AppColors.panel],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: item.rarity.color, width: 1.6),
            boxShadow: [BoxShadow(color: item.rarity.color.withValues(alpha: .35), blurRadius: 30)],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RarityChip(item.rarity),
                const SizedBox(height: 6),
                Text(
                  item.name,
                  style: const TextStyle(fontFamily: kufi, fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                ItemPreview(item: item, profile: p, big: true),
                const SizedBox(height: 18),
                if (buy)
                  Row(
                    children: [
                      Expanded(
                        child: GameButton(
                          label: 'لا',
                          tone: ButtonTone.ghost,
                          height: 48,
                          fontSize: 17,
                          onPressed: () => Navigator.pop(context, false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: GameButton(
                          label: p.dev ? 'اشترِ (ببلاش للمطور)' : 'اشترِ بـ ${arabicNumber(price.$2)}',
                          icon: Gfx(price.$1, size: 26),
                          height: 48,
                          fontSize: 17,
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ),
                    ],
                  )
                else if (!item.buyable && !item.isDefault)
                  _SourceNote(item: item, big: true),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _RarityChip extends StatelessWidget {
  const _RarityChip(this.rarity);

  final Rarity rarity;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
    decoration: BoxDecoration(
      color: rarity.color.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: rarity.color.withValues(alpha: .5)),
    ),
    child: Text(
      rarity.label,
      style: TextStyle(color: rarity.color, fontSize: 11.5, fontWeight: FontWeight.w800),
    ),
  );
}

/// من وين ينكسب الغرض (مستوى، موسم، بطولة).
class _SourceNote extends StatelessWidget {
  const _SourceNote({required this.item, this.big = false});

  final ShopItem item;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final icon = item.level != null ? 'xp' : (item.season != null ? 'pass' : 'trophy');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Gfx(icon, size: big ? 26 : 18),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            item.source,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.gold, fontSize: big ? 16 : 12.5, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.profile,
    required this.state,
    required this.busy,
    required this.onPreview,
    required this.onAction,
  });

  final ShopItem item;
  final Profile profile;
  final _State state;
  final bool busy;
  final VoidCallback onPreview;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final rc = item.rarity.color;
    final Widget action = switch (state) {
      _State.equipped => _Pill(
        color: AppColors.green,
        child: Text(
          item.slot == ShopSlot.avatar ? 'صورتك' : 'لابسه',
          style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800),
        ),
      ),
      _State.owned when item.slot == ShopSlot.reactions => _Pill(
        color: AppColors.green,
        child: const Text(
          'عندك',
          style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w800),
        ),
      ),
      _State.owned => _Pill(
        color: AppColors.text,
        onTap: busy ? null : onAction,
        child: Text(
          item.slot == ShopSlot.avatar ? 'استخدمها' : 'البس',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      _State.buy => _Pill(
        color: AppColors.gold,
        filled: true,
        onTap: busy ? null : onAction,
        child: Amount(
          item.coins != null ? 'coin' : 'gem',
          arabicNumber(item.coins ?? item.diamonds!),
          size: 20,
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldInk, fontSize: 15),
        ),
      ),
      _State.locked => _SourceNote(item: item),
    };

    return Semantics(
      label: 'غرض ${item.id}',
      child: GestureDetector(
        onTap: onPreview,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(AppColors.card, rc, .16)!, AppColors.card],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: state == _State.equipped ? AppColors.green : rc.withValues(alpha: .45),
              width: state == _State.equipped ? 2 : 1.2,
            ),
            boxShadow: [
              if (item.rarity == Rarity.legendary) BoxShadow(color: rc.withValues(alpha: .25), blurRadius: 14),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 26),
                  Expanded(
                    child: Center(
                      child: Opacity(
                        opacity: state == _State.locked ? .55 : 1,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ItemPreview(item: item, profile: profile),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 9),
                    child: SizedBox(
                      height: 38,
                      width: double.infinity,
                      child: Center(
                        child: Semantics(label: 'زر ${item.id}', child: action),
                      ),
                    ),
                  ),
                ],
              ),
              PositionedDirectional(top: 7, start: 7, child: _RarityChip(item.rarity)),
              if (state == _State.locked) const PositionedDirectional(top: 6, end: 7, child: Gfx('lock', size: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر صغير مدوّر داخل كرت الغرض.
class _Pill extends StatelessWidget {
  const _Pill({required this.child, required this.color, this.onTap, this.filled = false});

  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 38,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: filled ? const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFF2B53A)]) : null,
        color: filled ? null : color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: filled ? 1 : .55), width: 1.3),
      ),
      child: child,
    ),
  );
}

class _DiamondPacks extends StatelessWidget {
  const _DiamondPacks({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 6, 14, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF6D5BD0)),
          ),
          child: const Row(
            children: [
              Gfx('info', size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'شراء الجواهر بفلوس حقيقية يشتغل بعد ما نربط اللعبة بـ Google Play.\n'
                  'للحين تجمع جواهر من الهدية اليومية وهدايا المستويات والباتل باس.',
                  style: TextStyle(color: Color(0xFFC9BFFF), height: 1.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
          children: [
            for (final (i, pack) in diamondPacks.indexed)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(AppColors.card, AppColors.diamond, .18 + i * .08)!, AppColors.card],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.diamond.withValues(alpha: .5)),
                ),
                child: Column(
                  children: [
                    if (pack.bonus.isNotEmpty)
                      Text(
                        '${pack.bonus} زيادة',
                        style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w800),
                      )
                    else
                      const SizedBox(height: 16),
                    Expanded(child: Gfx(i == 0 ? 'gem' : (i == 1 ? 'gems' : 'gem_chest'), size: 64 + i * 8.0)),
                    Text(
                      '${arabicNumber(pack.diamonds)} جوهرة',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    _Pill(
                      color: AppColors.muted,
                      child: Text(
                        pack.price,
                        style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800),
                      ),
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
