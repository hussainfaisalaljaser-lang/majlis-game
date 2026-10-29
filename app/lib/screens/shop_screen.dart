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
import '../widgets/fx.dart';
import '../widgets/fx_sig.dart';
import '../widgets/item_preview.dart';
import '../widgets/pid.dart';
import '../widgets/ui.dart';
import 'wardrobe_screen.dart';

/// أقسام المتجر: الأيقونة والاسم ونوع الأغراض.
const _sections = [
  (icon: 'frame', name: 'الإطارات', slot: ShopSlot.frame),
  (icon: 'avatar', name: 'الشخصيات', slot: ShopSlot.avatar),
  (icon: 'bubble', name: 'الفقاعات', slot: ShopSlot.bubble),
  (icon: 'sticker', name: 'الملصقات', slot: ShopSlot.reactions),
  (icon: 'table', name: 'الطاولات', slot: ShopSlot.table),
  (icon: 'cards', name: 'الكروت', slot: ShopSlot.cards),
  (icon: 'death', name: 'تأثير الموت', slot: ShopSlot.death),
  (icon: 'ids', name: 'الرموز', slot: null),
  (icon: 'gems', name: 'الجواهر', slot: null),
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

/// المتجر: قائمة الأقسام على اليمين، والأغراض بشبكة كروت رق، وعرض اليوم على اليسار،
/// وكل غرض تقدر تشوفه كبير قبل ما تشتريه.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.initialTab = 0, this.featuredDiscount, this.featuredItem});

  final int initialTab;

  /// نسبة خصم تطلع على عرض اليوم (للعرض بس: المتجر ما فيه خصومات حقيقية للحين).
  final int? featuredDiscount;

  /// غرض عرض اليوم بدال اللي يختاره اليوم (للعرض بس).
  final ShopItem? featuredItem;

  static const avatarsTab = 1;
  static const stickersTab = 3;
  static const deathsTab = 6;
  static const idsTab = 7;
  static const diamondsTab = 8;

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
                    child: LayoutBuilder(
                      builder: (context, box) {
                        // عرض اليوم يصغر مع ارتفاع الشاشة بنفس نسبة التصميم
                        final panelW = math.min(
                          box.maxWidth * .46,
                          math.min(400.0, (box.maxHeight - 18) * 400 / shopPanelH),
                        );
                        // المعاينة مفتوحة: الأغراض اللي ورها (والعرض) توقف حركتها
                        return ValueListenableBuilder(
                          valueListenable: _previewOpen,
                          builder: (context, open, child) => TickerMode(enabled: !open, child: child!),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: _tab == ShopScreen.idsTab
                                      ? const _PremiumIdsSection(key: ValueKey('ids'))
                                      : section.slot == null
                                      ? const _DiamondPacks(key: ValueKey('gems'))
                                      : _ItemsGrid(
                                          key: ValueKey(section.slot),
                                          slot: section.slot!,
                                          busy: _busy,
                                          onAct: _act,
                                        ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(0, 9, 10, 9),
                                child: SizedBox(
                                  width: panelW,
                                  child: _DailyOffer(
                                    busy: _busy,
                                    onAct: _act,
                                    discount: widget.featuredDiscount,
                                    only: widget.featuredItem,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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
  return ShopItemCard(
    key: ValueKey(item.id),
    semantics: 'غرض ${item.id}',
    art: shopCardArt(item, p),
    rarity: item.rarity,
    name: item.name,
    dark: shopDarkCard(item),
    selected: st == ShopItemState.equipped,
    dim: st == ShopItemState.locked,
    wide: item.slot == ShopSlot.table || item.slot == ShopSlot.reactions,
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
        passive: item.slot == ShopSlot.reactions ? 'عندك' : null,
      ),
    ),
  );
}

class _ItemsGrid extends StatelessWidget {
  const _ItemsGrid({super.key, required this.slot, required this.busy, required this.onAct});

  final ShopSlot slot;
  final String? busy;
  final Future<void> Function(ShopItem item, Profile p) onAct;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final i in catalog)
        if (i.slot == slot) i,
    ];
    // اللي ينشرى أول، وبعده هدايا المستويات والموسم والأبطال.
    items.sort((a, b) => (a.buyable || a.isDefault ? 0 : 1).compareTo(b.buyable || b.isDefault ? 0 : 1));
    final wide = slot == ShopSlot.table || slot == ShopSlot.reactions;
    return ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) => LayoutBuilder(
        builder: (context, box) {
          final cols = math.max(2, ((box.maxWidth - 8) / (wide ? 190 : 124)).floor());
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: wide ? math.max(1, cols) : cols,
              mainAxisSpacing: 11,
              crossAxisSpacing: 11,
              childAspectRatio: (wide ? shopCardWideW : shopCardW) / shopCardH,
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

/// عرض اليوم: غرض من الملحمي والأسطوري يتغير كل يوم (بتوقيت الخليج)، وعداد لين يتبدل.
class _DailyOffer extends StatefulWidget {
  const _DailyOffer({required this.busy, required this.onAct, this.discount, this.only});

  final String? busy;
  final Future<void> Function(ShopItem item, Profile p) onAct;
  final int? discount;
  final ShopItem? only;

  @override
  State<_DailyOffer> createState() => _DailyOfferState();
}

class _DailyOfferState extends State<_DailyOffer> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // (بالتصوير الوقت ثابت)
    if (FxClock.manual.value == null) _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  /// غرض اليوم: نفس الغرض للكل طول اليوم، ويتبدل عند منتصف الليل بتوقيت الخليج.
  static ShopItem? offerFor(DateTime now) {
    final pool = [
      for (final i in catalog)
        if (i.buyable && (i.rarity == Rarity.epic || i.rarity == Rarity.legendary)) i,
    ];
    if (pool.isEmpty) return null;
    final gulf = now.toUtc().add(const Duration(hours: 3));
    final day = DateTime.utc(gulf.year, gulf.month, gulf.day).difference(DateTime.utc(2024)).inDays;
    return pool[day % pool.length];
  }

  /// كم باقي على منتصف الليل بتوقيت الخليج.
  static Duration untilMidnight(DateTime now) {
    final gulf = now.toUtc().add(const Duration(hours: 3));
    return DateTime.utc(gulf.year, gulf.month, gulf.day + 1).difference(gulf);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final item = widget.only ?? offerFor(now);
    if (item == null) return const SizedBox.shrink();
    return ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) {
        final st = shopStateOf(item, p);
        final coins = item.coins != null;
        final base = item.coins ?? item.diamonds ?? 0;
        final off = widget.discount;
        return ShopFeaturedPanel(
          rarity: item.rarity,
          art: ItemPreview(item: item, profile: p, scale: item.slot == ShopSlot.frame ? 1.28 : 1.15),
          name: item.name,
          title: shopItemPhrase(item),
          description: item.desc,
          dark: shopDarkCard(item),
          priceIcon: coins ? 'coin' : 'gem',
          // السعر قبل الخصم يطلع مشطوب (لو فيه خصم يعرضه المتجر)
          price: st == ShopItemState.buy ? (off == null ? base : (base * (100 - off) / 100).round()) : null,
          oldPrice: off == null ? null : base,
          discount: off,
          remaining: untilMidnight(now),
          state: st,
          busy: widget.busy == item.id,
          passive: item.slot == ShopSlot.reactions ? 'عندك' : null,
          ownedLabel: item.slot == ShopSlot.avatar ? 'استخدمها' : 'البس',
          equippedLabel: item.slot == ShopSlot.avatar ? 'صورتك' : 'لابسه',
          onPressed: () => widget.onAct(item, p),
          onPreview: () => showItemPreview(context, item),
        );
      },
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
              pile: Gfx(const ['gem', 'gems', 'gem_chest'][i % 3], size: 52.0 + i * 5),
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
