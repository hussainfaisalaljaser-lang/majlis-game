import 'package:flutter/material.dart';

import '../models/game_view.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/bubble.dart';
import '../widgets/common.dart';
import '../widgets/game/policy_card.dart';
import '../widgets/item_preview.dart';
import '../widgets/majlis.dart';
import '../widgets/ui.dart';
import 'shop_screen.dart';

/// أقسام غرفة التبديل، ورقم تبويبها في المتجر (للخانة الأخيرة «المتجر»).
const _tabs = [
  (name: 'الشخصيات', slot: ShopSlot.avatar, shop: ShopScreen.avatarsTab),
  (name: 'الإطارات', slot: ShopSlot.frame, shop: 0),
  (name: 'الطاولات', slot: ShopSlot.table, shop: 4),
  (name: 'الكروت', slot: ShopSlot.cards, shop: 5),
  (name: 'الفقاعات', slot: ShopSlot.bubble, shop: 2),
  (name: 'الملصقات', slot: ShopSlot.reactions, shop: ShopScreen.stickersTab),
];

/// غرفة التبديل: كل اللي تملكه بمكان واحد (الشخصيات، الإطارات، الطاولات، الكروت، الفقاعات، الملصقات)،
/// ومعاينة شكلك على اليسار تتغير على طول لما تلبس شي.
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  int _tab = 0;

  /// الغرض اللي ننتظر السيرفر يلبسه.
  String? _busy;

  Future<void> _wear(String id, Future<void> Function() call) async {
    if (_busy != null || !Backend.instance.isReady) return;
    setState(() => _busy = id);
    try {
      await call();
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _openShop(int tab) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShopScreen(initialTab: tab)));

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Gfx('cat_frame', size: 30), SizedBox(width: 8), Text('غرفة التبديل')],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ValueListenableBuilder(
          valueListenable: Backend.instance.profile,
          builder: (context, p, _) => Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // اللي تملكه
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                    decoration: BoxDecoration(
                      color: AppColors.panel.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold.withValues(alpha: .35), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 34,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final (i, t) in _tabs.indexed)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(end: 6),
                                  child: _TabChip(
                                    label: t.name,
                                    selected: i == _tab,
                                    onTap: () => setState(() => _tab = i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _tabs[_tab].slot == ShopSlot.reactions
                              ? _StickersTab(profile: p, onShop: () => _openShop(_tabs[_tab].shop))
                              : _grid(p),
                        ),
                        Text(
                          _tabs[_tab].slot == ShopSlot.reactions
                              ? 'اضغط مطوّل على ملصق تحطه بالمفضلة، وتطلع لك جنب زر التفاعل في اللعب'
                              : 'كل اللي تملكه هنا، اضغطه وتلبسه على طول',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted, fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(width: 280, child: _Preview(profile: p)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _grid(Profile p) {
    final tab = _tabs[_tab];
    final cells = <Widget>[];
    if (tab.slot == ShopSlot.avatar) {
      final mine = [
        ...freeAvatars,
        for (final i in catalog)
          if (i.slot == ShopSlot.avatar && p.owns(i.id)) i.avatar!,
      ];
      for (final a in mine) {
        cells.add(
          _Cell(
            on: p.avatar == a,
            busy: _busy == 'avatar_$a',
            label: avatarItem(a)?.name,
            onTap: () => _wear('avatar_$a', () => Backend.instance.updateProfile(name: p.name, avatar: a)),
            child: PlayerAvatar(avatar: a, size: 58, animate: false),
          ),
        );
      }
    } else {
      for (final item in catalog) {
        if (item.slot != tab.slot || !p.owns(item.id)) continue;
        final equipped = switch (tab.slot) {
          ShopSlot.frame => p.frame == item.id,
          ShopSlot.cards => p.cards == item.id,
          ShopSlot.table => p.table == item.id,
          _ => p.bubble == item.id,
        };
        cells.add(
          _Cell(
            on: equipped,
            busy: _busy == item.id,
            label: item.name,
            onTap: () => _wear(item.id, () => Backend.instance.equipItem(item.id)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ItemPreview(item: item, profile: p),
            ),
          ),
        );
      }
    }
    cells.add(_ShopCell(onTap: () => _openShop(tab.shop)));
    final wide = tab.slot == ShopSlot.table || tab.slot == ShopSlot.bubble;
    return GridView.extent(
      maxCrossAxisExtent: wide ? 190 : 118,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: wide ? 1.45 : .9,
      children: cells,
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.gold.withValues(alpha: .2) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.gold : AppColors.line, width: selected ? 1.6 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: selected ? AppColors.goldLight : AppColors.muted,
          ),
        ),
      ),
    ),
  );
}

/// خانة غرض: اللي لابسه عليه علامة خضرا، وتنضغط تلبسه.
class _Cell extends StatelessWidget {
  const _Cell({required this.on, required this.busy, required this.onTap, required this.child, this.label});

  final bool on;
  final bool busy;
  final VoidCallback onTap;
  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: on,
    label: label ?? 'غرض',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: on ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: on ? .08 : .04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? AppColors.green : AppColors.line, width: on ? 2.4 : 1),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: Center(child: child)),
            if (on) const PositionedDirectional(top: -12, end: -10, child: Gfx('check', size: 24)),
            if (busy)
              const Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.gold),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// آخر خانة: المزيد من المتجر.
class _ShopCell extends StatelessWidget {
  const _ShopCell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'المزيد من المتجر',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gold.withValues(alpha: .45)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Gfx('shop', size: 34),
            SizedBox(height: 4),
            Text(
              'المزيد من المتجر',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.goldLight),
            ),
          ],
        ),
      ),
    ),
  );
}

/// الملصقات: مفضلتك فوق (بالترتيب)، وتحتها كل باقة تملكها. ضغطة مطوّلة تضيف للمفضلة أو تشيل منها.
class _StickersTab extends StatefulWidget {
  const _StickersTab({required this.profile, required this.onShop});

  final Profile profile;
  final VoidCallback onShop;

  @override
  State<_StickersTab> createState() => _StickersTabState();
}

class _StickersTabState extends State<_StickersTab> {
  /// المفضلة هنا تتغير على طول، والسيرفر يحفظها ورا.
  late List<String> _favorites = [...widget.profile.favorites];
  String? _note;

  @override
  void didUpdateWidget(_StickersTab old) {
    super.didUpdateWidget(old);
    if (old.profile.favorites != widget.profile.favorites) _favorites = [...widget.profile.favorites];
  }

  Future<void> _toggle(String id) async {
    final before = [..._favorites];
    setState(() {
      if (_favorites.remove(id)) {
        _note = 'شلته من المفضلة';
      } else if (_favorites.length >= Profile.maxFavorites) {
        _note = 'المفضلة مليانة (${arabicNumber(Profile.maxFavorites)})، شيل واحد أول';
      } else {
        _favorites.add(id);
        _note = 'انضاف للمفضلة (${arabicNumber(_favorites.length)} من ${arabicNumber(Profile.maxFavorites)})';
      }
    });
    if (_favorites.length == before.length && _favorites.every(before.contains)) return;
    try {
      await Backend.instance.setFavorites(_favorites);
    } on BackendException catch (e) {
      if (!mounted) return;
      setState(() => _favorites = before);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _sticker(String id, {double size = 54}) => Semantics(
    button: true,
    label: 'ملصق $id',
    excludeSemantics: true,
    child: GestureDetector(
      onLongPress: () => _toggle(id),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: StickerView(sticker: stickerById(id)!, size: size, pop: false),
            ),
            if (_favorites.contains(id))
              const PositionedDirectional(
                top: -4,
                end: -2,
                child: Icon(
                  Icons.star_rounded,
                  color: AppColors.gold,
                  size: 20,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final packs = [
      for (final i in catalog)
        if (i.stickers != null && p.owns(i.id)) i,
    ];
    return ListView(
      children: [
        // المفضلة
        Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withValues(alpha: .4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'مفضلتك (${arabicNumber(_favorites.length)} من ${arabicNumber(Profile.maxFavorites)})',
                    style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  if (_note != null)
                    Flexible(
                      child: Text(
                        _note!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.goldLight, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 58,
                child: _favorites.isEmpty
                    ? const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          'ما عندك مفضلة للحين: اضغط مطوّل على أي ملصق تحت',
                          style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                        ),
                      )
                    : Row(
                        children: [
                          for (final id in _favorites)
                            if (stickerById(id) != null)
                              Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: _sticker(id, size: 56)),
                        ],
                      ),
              ),
            ],
          ),
        ),
        for (final pack in packs) ...[
          const SizedBox(height: 10),
          Text(
            pack.name,
            style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final id in pack.stickers!) _sticker(id)]),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: widget.onShop,
            icon: const Gfx('shop', size: 22),
            label: const Text('باقات ملصقات أكثر في المتجر'),
          ),
        ),
      ],
    );
  }
}

/// معاينة شكلك: فقاعتك فوق، وشخصيتك بإطارها على مسندك، وتحتها طاولتك وكروتك.
class _Preview extends StatelessWidget {
  const _Preview({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          const Positioned.fill(child: MajlisRoom()),
          Positioned.fill(child: ColoredBox(color: Colors.black.withValues(alpha: .25))),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, c) {
                final avatar = (c.maxHeight * .34).clamp(70.0, 112.0);
                return Column(
                  children: [
                    const SizedBox(height: 10),
                    ChatBubble(style: bubbleStyle(p.bubble), text: 'هلا والله بالربع!', fontSize: 13, maxWidth: 220),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: avatar * 1.45,
                      height: avatar * 1.12,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned(
                            top: avatar * .02,
                            child: Cushion(width: avatar * 1.45, height: avatar),
                          ),
                          Positioned(
                            top: avatar * .14,
                            child: PlayerAvatar(avatar: p.avatar, style: frameStyle(p.frame), size: avatar),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontFamily: kufi,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldLight,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: TablePreview(skin: tableSkin(p.table))),
                          const SizedBox(width: 8),
                          PolicyCard(policy: Policy.traitor, skin: cardSkin(p.cards), width: 44),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
