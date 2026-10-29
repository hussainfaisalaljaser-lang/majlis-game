import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/telemetry.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/design_shop.dart';
import '../widgets/design_stickers.dart';
import '../widgets/fx.dart';
import '../widgets/fx_sig.dart';
import '../widgets/item_preview.dart';
import '../widgets/pid.dart';
import '../widgets/ui.dart';
import 'wardrobe_screen.dart';

/// أقسام المتجر بالترتيب: العروض، الشخصيات، الإطارات، الطرد، الأوراق، الطاولات، الفقاعات، الملصقات، الرموز، المجوهرات.
const _sections = [
  (icon: 'offers', name: 'العروض', slot: null),
  (icon: 'avatar', name: 'الشخصيات', slot: ShopSlot.avatar),
  (icon: 'frame', name: 'الإطارات', slot: ShopSlot.frame),
  (icon: 'death', name: 'الطرد', slot: ShopSlot.death),
  (icon: 'cards', name: 'الأوراق', slot: ShopSlot.cards),
  (icon: 'table', name: 'الطاولات', slot: ShopSlot.table),
  (icon: 'bubble', name: 'الفقاعات', slot: ShopSlot.bubble),
  (icon: 'sticker', name: 'الملصقات', slot: ShopSlot.reactions),
  (icon: 'ids', name: 'الرموز', slot: null),
  (icon: 'gems', name: 'المجوهرات', slot: null),
];

/// أيقونة القسم لكل نوع غرض (للتنبيهات).
String shopSlotIcon(ShopSlot slot) => switch (slot) {
  ShopSlot.frame => 'frame',
  ShopSlot.avatar => 'avatar',
  ShopSlot.bubble => 'bubble',
  ShopSlot.reactions => 'sticker',
  ShopSlot.table => 'table',
  ShopSlot.cards => 'cards',
  ShopSlot.death => 'death',
};

/// المتجر: قائمة الأقسام على اليمين، والأغراض بشبكة كروت رق، وكل غرض تقدر تشوفه كبير قبل ما تشتريه.
/// أول قسم «العروض»: خمس باقات (شخصية مع إطار) تنشرى مرة وحدة.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.initialTab = 0});

  final int initialTab;

  static const offersTab = 0;
  static const avatarsTab = 1;
  static const framesTab = 2;
  static const deathsTab = 3;
  static const cardsTab = 4;
  static const tablesTab = 5;
  static const bubblesTab = 6;
  static const stickersTab = 7;
  static const idsTab = 8;
  static const diamondsTab = 9;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late int _tab = widget.initialTab;

  /// الغرض اللي ننتظر السيرفر يشتريه أو يلبسه.
  String? _busy;

  Future<void> _run(String id, Future<void> Function() action, {ShopItem? bought, ShopItem? worn}) async {
    setState(() => _busy = id);
    try {
      await action();
      if (!mounted) return;
      if (bought != null) {
        showShopToast(
          context,
          'صار عندك ${shopItemPhrase(bought)}!',
          icon: ShopCatIcon(shopSlotIcon(bought.slot), size: 30),
        );
      } else if (worn != null) {
        await showShopReveal(
          context,
          title: shopRevealTitle(worn.slot),
          art: shopRevealArt(worn, Backend.instance.profile.value),
          message: worn.slot == ShopSlot.avatar ? 'صارت صورتك ${worn.name}!' : 'لبست ${shopItemPhrase(worn)}!',
        );
      }
    } on BackendException catch (e) {
      if (mounted) showShopToast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _act(ShopItem item, Profile p) async {
    final b = Backend.instance;
    if (!b.isReady) return;
    switch (shopStateOf(item, p)) {
      case ShopItemState.equipped || ShopItemState.locked:
        return;
      case ShopItemState.owned:
        if (item.slot == ShopSlot.avatar) {
          return _run(
            item.id,
            () => b.updateProfile(name: p.name, avatar: item.avatar!),
            worn: item,
          );
        }
        if (item.equippable) return _run(item.id, () => b.equipItem(item.id), worn: item);
      case ShopItemState.buy:
        final ok = await showItemPreview(context, item, buy: true);
        if (ok == true) {
          await _run(item.id, () async {
            await b.buyItem(item.id);
            if (!p.dev) {
              Telemetry.spend(item.id, item.coins != null ? 'coins' : 'diamonds', item.coins ?? item.diamonds ?? 0);
            }
          }, bought: item);
        }
    }
  }

  /// يشتري العرض كامل: اللي ما تملكه من الشخصية والإطار، بنفس سعره العادي (ما فيه خصم للحين).
  Future<void> _buyOffer(_Offer offer, Profile p) async {
    final b = Backend.instance;
    if (!b.isReady) return;
    final todo = [for (final i in offer.items) if (!p.owns(i.id)) i];
    if (todo.isEmpty) return;
    final coins = todo.fold<int>(0, (n, i) => n + (i.coins ?? 0));
    final gems = todo.fold<int>(0, (n, i) => n + (i.diamonds ?? 0));
    final ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'العرض',
      barrierColor: Colors.black.withValues(alpha: .75),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (context, a, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: a, child: child),
      ),
      pageBuilder: (context, _, _) => _OfferDialog(offer: offer, profile: p, coins: coins, gems: gems),
    );
    if (ok != true || !mounted) return;
    await _run(offer.id, () async {
      for (final i in todo) {
        await b.buyItem(i.id);
        if (!p.dev) Telemetry.spend(i.id, i.coins != null ? 'coins' : 'diamonds', i.coins ?? i.diamonds ?? 0);
      }
      if (mounted) showShopToast(context, 'صار عندك ${offer.name}!', icon: const Gfx('gift', size: 30));
    });
  }

  @override
  Widget build(BuildContext context) {
    final section = _sections[_tab];
    return NightScaffold(
      body: SafeArea(
        child: Column(
          children: [
            ValueListenableBuilder(
              valueListenable: Backend.instance.profile,
              builder: (context, p, _) => ShopTopBar(
                title: 'المتجر',
                icon: const Gfx('shop', size: 34),
                trailing: [
                  // غرفة التبديل: تلبس اللي تملكه من مكان واحد.
                  ShopTitleChip(
                    label: 'غرفة التبديل',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WardrobeScreen())),
                  ),
                  ShopCurrency(icon: 'coin', amount: p.coins, infinite: p.dev),
                  ShopCurrency(icon: 'gem', amount: p.diamonds, infinite: p.dev),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ShopRail(
                    items: [for (final s in _sections) ShopCategory(s.icon, s.name)],
                    selected: _tab,
                    onSelect: (i) => setState(() => _tab = i),
                  ),
                  Expanded(
                    // المعاينة مفتوحة: الأغراض اللي ورها توقف حركتها
                    child: ValueListenableBuilder(
                      valueListenable: _previewOpen,
                      builder: (context, open, child) => TickerMode(enabled: !open, child: child!),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: switch (_tab) {
                          ShopScreen.offersTab => _OffersGrid(
                            key: const ValueKey('offers'),
                            busy: _busy,
                            onBuy: _buyOffer,
                          ),
                          ShopScreen.idsTab => const _PremiumIdsSection(key: ValueKey('ids')),
                          ShopScreen.diamondsTab => const _DiamondPacks(key: ValueKey('gems')),
                          _ => _ItemsGrid(key: ValueKey(section.slot), slot: section.slot!, busy: _busy, onAct: _act),
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// كرت غرض بالمتجر بكل حالاته.
Widget _shopCard(BuildContext context, ShopItem item, Profile p, {required String? busy, required VoidCallback onAct}) {
  final st = shopStateOf(item, p);
  final avatar = item.slot == ShopSlot.avatar;
  void preview() => showItemPreview(context, item);
  // باقات الملصقات والكلام: كرت الباقة (أربع ملصقات على رق، ولوح مخمل بالاسم، وزر عندك أو السعر)
  if (item.slot == ShopSlot.reactions) {
    return FittedBox(
      key: ValueKey(item.id),
      child: StickerPackCard(
        semantics: 'غرض ${item.id}',
        name: item.name,
        rarity: item.rarity,
        stickers: item.stickers,
        phrases: item.phrases ? stickerPackPhrases(item.id) : null,
        dim: st == ShopItemState.locked,
        onTap: preview,
        onPreview: preview,
        action: Semantics(
          label: 'زر ${item.id}',
          child: StickerPackPill(
            state: st,
            icon: item.coins != null ? 'coin' : 'gem',
            price: item.coins ?? item.diamonds,
            source: item.source,
            sourceIcon: shopSourceIcon(item),
            busy: busy == item.id,
            onTap: onAct,
          ),
        ),
      ),
    );
  }
  return ShopItemCard(
    key: ValueKey(item.id),
    semantics: 'غرض ${item.id}',
    art: shopCardArt(item, p),
    rarity: item.rarity,
    name: item.name,
    dark: shopDarkCard(item),
    selected: st == ShopItemState.equipped,
    dim: st == ShopItemState.locked,
    wide: item.slot == ShopSlot.table,
    onTap: preview,
    onPreview: preview,
    action: Semantics(
      label: 'زر ${item.id}',
      child: ShopActionButton(
        state: st,
        icon: item.coins != null ? 'coin' : 'gem',
        price: item.coins ?? item.diamonds,
        source: item.source,
        sourceIcon: shopSourceIcon(item),
        busy: busy == item.id,
        onTap: onAct,
        ownedLabel: avatar ? 'استخدمها' : 'البس',
        equippedLabel: avatar ? 'صورتك' : 'لابسه',
      ),
    ),
  );
}

/// ترتيب أغراض قسم (للمتجر وغرفة التبديل): اللي ينشرى أول (وبعده هدايا المستويات والموسم والأبطال)،
/// وفي كل مجموعة الأقل ندرة أول: عادي، نادر، ملحمي، أسطوري. وبنفس الندرة الذهب قبل الجواهر والأرخص أول.
/// باقات الملصقات تبقى بترتيبها.
List<ShopItem> shopItemsOrdered(ShopSlot slot) {
  final items = [
    for (final i in catalog)
      if (i.slot == slot) i,
  ];
  final at = {for (final (n, i) in items.indexed) i.id: n};
  int group(ShopItem i) => i.buyable || i.isDefault ? 0 : 1;
  int currency(ShopItem i) => i.coins != null ? 0 : (i.diamonds != null ? 1 : -1);
  int price(ShopItem i) => i.coins ?? i.diamonds ?? 0;
  final byRarity = slot != ShopSlot.reactions;
  items.sort((a, b) {
    var c = group(a).compareTo(group(b));
    if (c == 0 && byRarity) c = a.rarity.index.compareTo(b.rarity.index);
    if (c == 0 && byRarity) c = currency(a).compareTo(currency(b));
    if (c == 0 && byRarity) c = price(a).compareTo(price(b));
    return c != 0 ? c : at[a.id]!.compareTo(at[b.id]!);
  });
  return items;
}

class _ItemsGrid extends StatelessWidget {
  const _ItemsGrid({super.key, required this.slot, required this.busy, required this.onAct});

  final ShopSlot slot;
  final String? busy;
  final Future<void> Function(ShopItem item, Profile p) onAct;

  @override
  Widget build(BuildContext context) {
    final items = shopItemsOrdered(slot);
    final wide = slot == ShopSlot.table;
    final packs = slot == ShopSlot.reactions;
    return ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) => LayoutBuilder(
        builder: (context, box) {
          // كروت الباقات عريضة (أربع ملصقات بصف): تتوزع على قد العرض، وأقلها عمودين
          final cols = math.max(2, ((box.maxWidth - 8) / (packs ? 205 : (wide ? 190 : 124))).floor());
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: wide ? math.max(1, cols) : cols,
              mainAxisSpacing: 11,
              crossAxisSpacing: 11,
              childAspectRatio: packs
                  ? stickerPackCardW / stickerPackCardH
                  : (wide ? shopCardWideW : shopCardW) / shopCardH,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return _shopCard(context, item, p, busy: busy, onAct: () => onAct(item, p));
            },
          );
        },
      ),
    );
  }
}

/// عرض: شخصية مع إطار تنشرى مع بعض (بنفس سعرهم العادي للحين، بدون خصم).
class _Offer {
  const _Offer(this.id, this.name, this.avatarId, this.frameId);

  final String id;
  final String name;
  final String avatarId;
  final String frameId;

  ShopItem get avatar => shopItem(avatarId)!;
  ShopItem get frame => shopItem(frameId)!;
  List<ShopItem> get items => [avatar, frame];
}

/// خمس عروض بسيطة، من الأرخص للأغلى (آخرها بالجواهر).
const _offers = [
  _Offer('offer_detective', 'عرض المحقق', 'avatar_detective', 'frame_ice'),
  _Offer('offer_poet', 'عرض الشاعر', 'avatar_poet', 'frame_night'),
  _Offer('offer_falconer', 'عرض الصقّار', 'avatar_falconer', 'frame_fire'),
  _Offer('offer_seer', 'عرض العرّاف', 'avatar_seer', 'frame_neon'),
  _Offer('offer_emir', 'عرض الأمير', 'avatar_emir', 'frame_sun'),
];

/// قسم العروض: كروت عريضة، كل كرت فيه الشخصية لابسة إطارها، وزر شراء بسعر المجموع.
class _OffersGrid extends StatelessWidget {
  const _OffersGrid({super.key, required this.busy, required this.onBuy});

  final String? busy;
  final Future<void> Function(_Offer offer, Profile p) onBuy;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Backend.instance.profile,
    builder: (context, p, _) => LayoutBuilder(
      builder: (context, box) {
        final cols = math.max(1, ((box.maxWidth - 8) / 190).floor());
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 11,
            crossAxisSpacing: 11,
            childAspectRatio: shopCardWideW / shopCardH,
          ),
          itemCount: _offers.length,
          itemBuilder: (context, i) => _offerCard(context, _offers[i], p, busy: busy, onBuy: () => onBuy(_offers[i], p)),
        );
      },
    ),
  );
}

Widget _offerCard(BuildContext context, _Offer o, Profile p, {required String? busy, required VoidCallback onBuy}) {
  final todo = [for (final i in o.items) if (!p.owns(i.id)) i];
  final coins = todo.fold<int>(0, (n, i) => n + (i.coins ?? 0));
  final gems = todo.fold<int>(0, (n, i) => n + (i.diamonds ?? 0));
  final rarity = o.items.map((i) => i.rarity).reduce((a, b) => a.index >= b.index ? a : b);
  final dark = shopDarkCard(o.frame);
  return ShopItemCard(
    key: ValueKey(o.id),
    semantics: 'عرض ${o.id}',
    art: _OfferArt(offer: o, dark: dark),
    rarity: rarity,
    name: o.name,
    dark: dark,
    wide: true,
    onTap: onBuy,
    action: Semantics(
      label: 'زر ${o.id}',
      child: ShopActionButton(
        state: todo.isEmpty ? ShopItemState.owned : ShopItemState.buy,
        passive: 'عندك العرض',
        icon: coins > 0 ? 'coin' : 'gem',
        price: coins > 0 ? coins : gems,
        busy: busy == o.id,
        onTap: onBuy,
      ),
    ),
  );
}

/// رسمة العرض: الشخصية لابسة الإطار، وجنبها اسم الشخصية واسم الإطار.
class _OfferArt extends StatelessWidget {
  const _OfferArt({required this.offer, required this.dark});

  final _Offer offer;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final ink = dark ? const Color(0xFFFFEFD0) : AppColors.ink;
    final muted = dark ? const Color(0xFFD9C29A) : const Color(0xFF6A4A2A);
    Widget line(String label, String name) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w800, height: 1.1)),
        Text(
          name,
          style: TextStyle(fontFamily: kufi, color: ink, fontSize: 15, fontWeight: FontWeight.w800, height: 1.2),
        ),
      ],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerAvatar(avatar: offer.avatar.avatar!, style: offer.frame.frame, size: 62, animate: false),
        const SizedBox(width: 14),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [line('شخصية', offer.avatar.name), const SizedBox(height: 5), line('إطار', offer.frame.name)],
        ),
      ],
    );
  }
}

/// تأكيد شراء العرض: الشخصية لابسة إطارها، واللي بتشتريه، وسعره.
class _OfferDialog extends StatelessWidget {
  const _OfferDialog({required this.offer, required this.profile, required this.coins, required this.gems});

  final _Offer offer;
  final Profile profile;
  final int coins;
  final int gems;

  @override
  Widget build(BuildContext context) {
    final price = coins > 0 ? ('coin', coins) : ('gem', gems);
    final skipped = [for (final i in offer.items) if (profile.owns(i.id)) i.name];
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ShopDialogCard(
          title: offer.name,
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 150,
                child: Center(
                  child: PlayerAvatar(avatar: offer.avatar.avatar!, style: offer.frame.frame, size: 112),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${offer.avatar.name} + إطار ${offer.frame.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: kufi,
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
              if (skipped.isNotEmpty)
                Text(
                  'عندك ${skipped.join(' و')} من قبل، ما تدفع عليه',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6A4A2A), fontSize: 13, fontWeight: FontWeight.w700),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ShopButton.label(
                      'لا',
                      tone: ShopTone.dark,
                      height: 44,
                      fontSize: 18,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ShopButton(
                      height: 44,
                      semantics: 'اشتر العرض',
                      onPressed: () => Navigator.pop(context, true),
                      child: profile.dev
                          ? const OutlinedText(
                              'اشترِ (ببلاش للمطور)',
                              size: 17,
                              maxLines: 1,
                              stroke: Color(0xFF143A0B),
                              strokeWidth: 3.4,
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedText(
                                  'اشترِ بـ ${arabicNumber(price.$2)}',
                                  size: 18,
                                  maxLines: 1,
                                  stroke: const Color(0xFF143A0B),
                                  strokeWidth: 3.4,
                                ),
                                const SizedBox(width: 8),
                                Gfx(price.$1, size: 26),
                              ],
                            ),
                    ),
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

/// نافذة المعاينة الكبيرة: الحركة كاملة بحجم كبير وعلى الطاولة، عشان اللي بيشتري يعرف وش ياخذ.
/// لو [buy] تطلع بزر الشراء وترجع true لو وافق.
Future<bool?> showItemPreview(BuildContext context, ShopItem item, {bool buy = false}) async {
  _previewOpen.value = true;
  try {
    return await _showPreview(context, item, buy);
  } finally {
    _previewOpen.value = false;
  }
}

/// المعاينة مفتوحة: الأغراض اللي ورها توقف حركتها (توفّر على الجوال).
final _previewOpen = ValueNotifier(false);

Future<bool?> _showPreview(BuildContext context, ShopItem item, bool buy) => showGeneralDialog<bool>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'معاينة',
  barrierColor: Colors.black.withValues(alpha: .75),
  transitionDuration: const Duration(milliseconds: 260),
  transitionBuilder: (context, a, _, child) => ScaleTransition(
    scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
    child: FadeTransition(opacity: a, child: child),
  ),
  pageBuilder: (context, _, _) => _PreviewDialog(item: item, buy: buy),
);

class _PreviewDialog extends StatefulWidget {
  const _PreviewDialog({required this.item, required this.buy});

  final ShopItem item;
  final bool buy;

  @override
  State<_PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<_PreviewDialog> {
  Timer? _moment;

  /// الإطار الأسطوري الخاص: لحظته تشتغل أول ما تفتح المعاينة، وتتكرر كل كم ثانية.
  bool get _hasMoment => widget.item.rarity == Rarity.legendary && widget.item.frame?.sig != null;

  @override
  void initState() {
    super.initState();
    // (بالتصوير الوقت ثابت، فاللحظة تنادى من الزر)
    if (_hasMoment && FxClock.manual.value == null) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) Moments.trigger('preview');
      });
      _moment = Timer.periodic(const Duration(seconds: 6), (_) => Moments.trigger('preview'));
    }
  }

  @override
  void dispose() {
    _moment?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final p = Backend.instance.profile.value;
    final price = item.coins != null ? ('coin', item.coins!) : ('gem', item.diamonds ?? 0);
    final avatarLike = item.slot == ShopSlot.frame || item.slot == ShopSlot.avatar;
    Widget avatarAt(double size) => PlayerAvatar(
      avatar: item.slot == ShopSlot.avatar ? item.avatar! : p.avatar,
      style: item.slot == ShopSlot.frame ? item.frame : frameStyle(p.frame),
      size: size,
      momentKey: 'preview',
    );
    final Widget? actions = widget.buy
        ? Row(
            children: [
              Expanded(
                child: ShopButton.label(
                  'لا',
                  tone: ShopTone.dark,
                  height: 44,
                  fontSize: 18,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ShopButton(
                  height: 44,
                  semantics: 'اشتر',
                  onPressed: () => Navigator.pop(context, true),
                  child: p.dev
                      ? const OutlinedText(
                          'اشترِ (ببلاش للمطور)',
                          size: 17,
                          maxLines: 1,
                          stroke: Color(0xFF143A0B),
                          strokeWidth: 3.4,
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedText(
                              'اشترِ بـ ${arabicNumber(price.$2)}',
                              size: 18,
                              maxLines: 1,
                              stroke: const Color(0xFF143A0B),
                              strokeWidth: 3.4,
                            ),
                            const SizedBox(width: 8),
                            Gfx(price.$1, size: 26),
                          ],
                        ),
                ),
              ),
            ],
          )
        : !item.buyable && !item.isDefault
        ? ShopActionButton(
            state: ShopItemState.locked,
            source: item.source,
            sourceIcon: shopSourceIcon(item),
            height: 42,
          )
        : null;
    final desc = item.desc == null
        ? null
        : Text(
            item.desc!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: kufi,
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          );
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ShopDialogCard(
          title: item.name,
          width: avatarLike ? 440 : 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (avatarLike)
                // كبير: الحركة بتفاصيلها
                SizedBox(height: 168, child: Center(child: avatarAt(122)))
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ItemPreview(item: item, profile: p, big: true),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              ShopRarityTag(item.rarity, size: 13),
              if (desc != null) ...[const SizedBox(height: 5), desc],
              if (avatarLike) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    avatarAt(48),
                    const SizedBox(width: 10),
                    const Flexible(
                      child: Text(
                        'كذا يطلع على الطاولة وفي ملفك، والكل يشوفه',
                        style: TextStyle(
                          fontFamily: kufi,
                          color: Color(0xFF6A4A2A),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (_hasMoment) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: 230,
                  child: ShopButton(
                    tone: ShopTone.blue,
                    height: 38,
                    semantics: 'شوف اللحظة الخاصة',
                    onPressed: () => Moments.trigger('preview'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Gfx('bolt', size: 22),
                        SizedBox(width: 6),
                        OutlinedText(
                          'شوف اللحظة الخاصة',
                          size: 15,
                          maxLines: 1,
                          stroke: Color(0xFF0B2953),
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (actions != null) ...[const SizedBox(height: 12), actions],
            ],
          ),
        ),
      ),
    );
  }
}

/// لوحة مخمل بعنوان ذهبي للأقسام الخاصة (الرموز والجواهر).
class _SectionBox extends StatelessWidget {
  const _SectionBox({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(10, 8, 10, 16), children: children);
}

/// الرموز المميزة: أمثلة من كل درجة، والزر يفتح نافذة الاختيار والشراء.
class _PremiumIdsSection extends StatelessWidget {
  const _PremiumIdsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionBox(
      children: [
        VelvetPanel(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Gfx('idcard', size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GoldTitle('رمز مميز', size: 24, align: TextAlign.start),
                        const SizedBox(height: 2),
                        Text(
                          'رمزك يطلع في ملفك وبطاقتك للكل، والناس يضيفونك فيه. الأقصر والمكرر أندر، والملحمي والأسطوري يلمعون.',
                          style: TextStyle(
                            fontFamily: kufi,
                            color: const Color(0xFFFFEBCB).withValues(alpha: .92),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 12,
                children: [
                  for (final (pid, tier, price) in const [
                    ('4829173', 1, 60),
                    ('482917', 2, 120),
                    ('4829', 3, 500),
                    ('777', 4, 3000),
                  ])
                    Column(
                      children: [
                        PidBadge(pid: pid, tier: tier, size: 16, copy: false),
                        const SizedBox(height: 5),
                        Text(
                          '${pidTierNames[tier]} (${arabicNumber(price)})',
                          style: TextStyle(
                            fontFamily: kufi,
                            color: pidTierColor(tier),
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: SizedBox(
                  width: 270,
                  child: ShopButton(
                    height: 50,
                    radius: 14,
                    semantics: 'اختار رمزك',
                    onPressed: () => showPremiumIds(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedText('اختار رمزك', size: 21, stroke: Color(0xFF143A0B), strokeWidth: 4),
                        SizedBox(width: 10),
                        Gfx('gem', size: 28),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// باقات الذهب مثل التصميم (للعرض بس: الدفع الحقيقي ما اشتغل للحين، وتطلع نفس رسالة الجواهر).
const _coinPacks = [
  (coins: 1000, price: '٥ ريال', pile: 2),
  (coins: 3500, price: '١٥ ريال', pile: 4),
  (coins: 8000, price: '٣٠ ريال', pile: 6),
];

/// شبكة كروت الباقات (٣ بالصف مثل التصميم).
Widget _packsGrid(List<Widget> packs) => LayoutBuilder(
  builder: (context, box) => GridView.count(
    crossAxisCount: math.max(2, (box.maxWidth / 124).floor()),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 11,
    crossAxisSpacing: 11,
    childAspectRatio: shopCardW / 118,
    children: packs,
  ),
);

class _DiamondPacks extends StatelessWidget {
  const _DiamondPacks({super.key});

  static const _msg = 'شراء الجواهر بفلوس حقيقية يشتغل بعد ما نربط اللعبة بـ Google Play';

  @override
  Widget build(BuildContext context) {
    return _SectionBox(
      children: [
        PlankBar(
          gold: true,
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: const Row(
            children: [
              Gfx('info', size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$_msg\nللحين تجمع جواهر من الهدية اليومية وهدايا المستويات والباتل باس.',
                  style: TextStyle(
                    fontFamily: kufi,
                    color: Color(0xFFFFEBCB),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: 6),
            child: GoldTitle('باقات الذهب', size: 21, align: TextAlign.start),
          ),
        ),
        const SizedBox(height: 8),
        _packsGrid([
          for (final pack in _coinPacks)
            ShopPackCard(
              pile: ShopPile(icon: 'coin', count: pack.pile, size: 56),
              amount: arabicNumber(pack.coins),
              unit: 'ذهب',
              price: pack.price,
              onTap: () => showShopToast(context, _msg, icon: const Gfx('info', size: 28)),
            ),
        ]),
        const SizedBox(height: 14),
        const Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: 6),
            child: GoldTitle('باقات الجواهر', size: 21, align: TextAlign.start),
          ),
        ),
        const SizedBox(height: 8),
        _packsGrid([
          for (final (i, pack) in diamondPacks.indexed)
            ShopPackCard(
              pile: ShopPile(icon: 'gem', count: 2 + i * 2, size: 56),
              amount: arabicNumber(pack.diamonds),
              unit: 'جوهرة',
              price: pack.price,
              badge: pack.bonus.isEmpty ? null : '${pack.bonus} زيادة',
              onTap: () => showShopToast(context, _msg, icon: const Gfx('info', size: 28)),
            ),
        ]),
      ],
    );
  }
}
