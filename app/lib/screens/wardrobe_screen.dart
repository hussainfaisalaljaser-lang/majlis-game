import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_view.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/bubble.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/design_shop.dart';
import '../widgets/design_stickers.dart';
import '../widgets/game/policy_card.dart';
import '../widgets/item_preview.dart';
import '../widgets/majlis.dart';
import '../widgets/ui.dart';
import 'shop_screen.dart';

/// أقسام غرفة التبديل (بنفس ترتيب المتجر)، ورقم تبويبها في المتجر (لزر «المزيد من المتجر»).
const _tabs = [
  (icon: 'frame', name: 'الإطارات', slot: ShopSlot.frame, shop: 0),
  (icon: 'avatar', name: 'الشخصيات', slot: ShopSlot.avatar, shop: ShopScreen.avatarsTab),
  (icon: 'bubble', name: 'الفقاعات', slot: ShopSlot.bubble, shop: 2),
  (icon: 'sticker', name: 'الملصقات', slot: ShopSlot.reactions, shop: ShopScreen.stickersTab),
  (icon: 'table', name: 'الطاولات', slot: ShopSlot.table, shop: 4),
  (icon: 'cards', name: 'الكروت', slot: ShopSlot.cards, shop: 5),
  (icon: 'death', name: 'تأثير الموت', slot: ShopSlot.death, shop: ShopScreen.deathsTab),
];

/// غرفة التبديل: كل اللي تملكه بمكان واحد (الإطارات، الشخصيات، الفقاعات، الملصقات، الطاولات، الكروت، تأثير الموت)،
/// واضغط «البس» وتتغير على طول. وزر «شكلك» يفتح معاينة شكلك الحين.
class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key, this.initialTab = 0});

  /// القسم اللي يفتح عليه (للتصوير).
  final int initialTab;

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  late int _tab = widget.initialTab;

  /// الغرض اللي ننتظر السيرفر يلبسه.
  String? _busy;

  Future<void> _wear(
    String id,
    Future<void> Function() call, {
    required String title,
    required Widget art,
    required String message,
  }) async {
    if (_busy != null || !Backend.instance.isReady) return;
    setState(() => _busy = id);
    try {
      await call();
      if (mounted) await showShopReveal(context, title: title, art: art, message: message);
    } on BackendException catch (e) {
      if (mounted) showShopToast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _openShop(int tab) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShopScreen(initialTab: tab)));

  /// معاينة شكلك الحين (تتغير على طول لو لبست وهي مفتوحة).
  void _showLook() => showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'شكلك',
    barrierColor: Colors.black.withValues(alpha: .7),
    transitionDuration: const Duration(milliseconds: 260),
    transitionBuilder: (context, a, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: a, child: child),
    ),
    pageBuilder: (context, _, _) => Center(
      child: Material(
        color: Colors.transparent,
        child: ShopDialogCard(
          title: 'شكلك',
          width: 340,
          sun: false,
          child: SizedBox(
            height: 300,
            child: ValueListenableBuilder(
              valueListenable: Backend.instance.profile,
              builder: (context, p, _) => _Preview(profile: p),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: Backend.instance.profile,
          builder: (context, p, _) => Column(
            children: [
              ShopTopBar(
                title: 'المتجر',
                icon: const Gfx('shop', size: 34),
                center: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Flexible(
                      child: OutlinedText(
                        'غرفة التبديل',
                        size: 23,
                        maxLines: 1,
                        gradient: goldTitleColors,
                        stroke: Color(0xFF3A1606),
                        strokeWidth: 4.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ShopCatIcon('avatar', size: 32),
                  ],
                ),
                trailing: [
                  ShopTitleChip(label: 'شكلك', crystal: false, onTap: _showLook),
                  ShopCurrency(icon: 'coin', amount: p.coins, infinite: p.dev),
                  ShopCurrency(icon: 'gem', amount: p.diamonds, infinite: p.dev),
                ],
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShopRail(
                      items: [for (final t in _tabs) ShopCategory(t.icon, t.name)],
                      selected: _tab,
                      onSelect: (i) => setState(() => _tab = i),
                    ),
                    Expanded(
                      child: _tabs[_tab].slot == ShopSlot.reactions
                          ? _StickersTab(profile: p, onShop: () => _openShop(_tabs[_tab].shop))
                          : _grid(p),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid(Profile p) {
    final tab = _tabs[_tab];
    final cells = <Widget>[];
    final wide = tab.slot == ShopSlot.table;
    if (tab.slot == ShopSlot.avatar) {
      final mine = [
        ...freeAvatars,
        for (final i in catalog)
          if (i.slot == ShopSlot.avatar && p.owns(i.id)) i.avatar!,
      ];
      for (final a in mine) {
        final item = avatarItem(a);
        final on = p.avatar == a;
        cells.add(
          ShopItemCard(
            key: ValueKey('avatar_$a'),
            semantics: item?.name ?? 'شخصية',
            art: PlayerAvatar(avatar: a, style: frameStyle(p.frame), size: 62, animate: false),
            rarity: item?.rarity ?? Rarity.common,
            name: item?.name,
            selected: on,
            onTap: on ? null : () => _equipAvatar(p, a, item),
            onPreview: item == null ? null : () => showItemPreview(context, item),
            action: ShopActionButton(
              state: on ? ShopItemState.equipped : ShopItemState.owned,
              busy: _busy == 'avatar_$a',
              onTap: () => _equipAvatar(p, a, item),
              ownedLabel: 'استخدمها',
              equippedLabel: 'صورتك',
            ),
          ),
        );
      }
    } else {
      for (final item in catalog) {
        if (item.slot != tab.slot || !p.owns(item.id)) continue;
        final on = shopStateOf(item, p) == ShopItemState.equipped;
        cells.add(
          ShopItemCard(
            key: ValueKey(item.id),
            semantics: item.name,
            art: shopCardArt(item, p),
            rarity: item.rarity,
            name: item.name,
            dark: shopDarkCard(item),
            selected: on,
            wide: wide,
            onTap: on ? null : () => _equip(item, p),
            onPreview: () => showItemPreview(context, item),
            action: ShopActionButton(
              state: on ? ShopItemState.equipped : ShopItemState.owned,
              busy: _busy == item.id,
              onTap: () => _equip(item, p),
              ownedLabel: item.id == 'frame_none' ? 'تجهيز' : 'البس',
            ),
          ),
        );
      }
    }
    cells.add(_ShopCell(wide: wide, onTap: () => _openShop(tab.shop)));
    return LayoutBuilder(
      builder: (context, box) {
        final cols = math.max(2, ((box.maxWidth - 8) / (wide ? 215 : 150)).floor());
        return GridView.count(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
          crossAxisCount: cols,
          mainAxisSpacing: 11,
          crossAxisSpacing: 11,
          childAspectRatio: (wide ? shopCardWideW : shopCardW) / shopCardH,
          children: cells,
        );
      },
    );
  }

  void _equip(ShopItem item, Profile p) => _wear(
    item.id,
    () => Backend.instance.equipItem(item.id),
    title: shopRevealTitle(item.slot),
    art: shopRevealArt(item, p),
    message: item.id == 'frame_none' ? 'شلت الإطار!' : 'لبست ${shopItemPhrase(item)}!',
  );

  void _equipAvatar(Profile p, String a, ShopItem? item) => _wear(
    'avatar_$a',
    () => Backend.instance.updateProfile(name: p.name, avatar: a),
    title: shopRevealTitle(ShopSlot.avatar),
    art: PlayerAvatar(avatar: a, style: frameStyle(p.frame), size: 104),
    message: item == null ? 'غيّرت صورتك!' : 'صارت صورتك ${item.name}!',
  );
}

/// آخر خانة: المزيد من المتجر.
class _ShopCell extends StatelessWidget {
  const _ShopCell({required this.onTap, this.wide = false});

  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'المزيد من المتجر',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: FittedBox(
        child: SizedBox(
          width: wide ? shopCardWideW : shopCardW,
          height: shopCardH,
          child: ShopCardFrame(
            child: Stack(
              children: [
                const Positioned(left: 6, right: 6, top: 14, height: 80, child: Center(child: Gfx('shop', size: 66))),
                const Positioned(
                  left: 6,
                  right: 6,
                  top: 100,
                  height: 22,
                  child: Center(
                    child: Text(
                      'المزيد من المتجر',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: kufi,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 7,
                  right: 7,
                  top: 122,
                  height: 36,
                  child: ShopButton.label('المتجر', onPressed: onTap, height: 33, fontSize: 16),
                ),
              ],
            ),
          ),
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
      showShopToast(context, e.message);
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
            if (_favorites.contains(id)) const PositionedDirectional(top: -5, end: -3, child: ShopStar(size: 21)),
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
    final favs = [
      for (final id in _favorites)
        if (stickerById(id) != null) id,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      children: [
        // المفضلة
        PlankBar(
          gold: true,
          radius: 16,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ShopStar(size: 24),
                  const SizedBox(width: 6),
                  GoldTitle(
                    'مفضلتك (${arabicNumber(_favorites.length)} من ${arabicNumber(Profile.maxFavorites)})',
                    size: 19,
                    align: TextAlign.start,
                  ),
                  const SizedBox(width: 10),
                  if (_note != null)
                    Flexible(
                      child: Text(
                        _note!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: kufi,
                          color: Color(0xFFFFEBCB),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'اضغط مطوّل على ملصق تحطه بالمفضلة، وتطلع لك جنب زر التفاعل في اللعب',
                style: TextStyle(
                  fontFamily: kufi,
                  color: const Color(0xFFFFEBCB).withValues(alpha: .75),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < Profile.maxFavorites; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10),
                      child: Container(
                        width: 62,
                        height: 62,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B0F08).withValues(alpha: .7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: i < favs.length ? const Color(0xFFE8B54E) : const Color(0xFF5A3A22),
                            width: 2,
                          ),
                        ),
                        child: i < favs.length ? _sticker(favs[i], size: 52) : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) {
            final two = box.maxWidth >= 560;
            final w = two ? (box.maxWidth - 12) / 2 : box.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final pack in packs)
                  // نفس كرت المتجر بس بملصقات الباقة كلها (ضغطة مطوّلة على الملصق للمفضلة)
                  StickerPackCard(
                    key: ValueKey(pack.id),
                    semantics: pack.name,
                    name: pack.name,
                    rarity: pack.rarity,
                    stickers: pack.stickers,
                    width: w,
                    shown: pack.stickers!.length,
                    perRow: pack.stickers!.length,
                    onPreview: () => showItemPreview(context, pack),
                    stickerBuilder: (id, size) => _sticker(id, size: size),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Center(
          child: SizedBox(
            width: 290,
            child: ShopButton(
              height: 44,
              semantics: 'باقات ملصقات أكثر في المتجر',
              onPressed: widget.onShop,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedText(
                    'باقات ملصقات أكثر في المتجر',
                    size: 16,
                    maxLines: 1,
                    stroke: Color(0xFF143A0B),
                    strokeWidth: 3.2,
                  ),
                  SizedBox(width: 8),
                  Gfx('shop', size: 26),
                ],
              ),
            ),
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
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          const Positioned.fill(child: MajlisRoom()),
          Positioned.fill(child: ColoredBox(color: Colors.black.withValues(alpha: .25))),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, c) {
                final avatar = (c.maxHeight * .29).clamp(56.0, 112.0);
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
