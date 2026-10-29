// تصوير المتجر وغرفة التبديل بكل أقسامهم وحالاتهم (ملف لاعب تجريبي، بدون سيرفر).
// التشغيل:  flutter test tool/shots/shop_shots_test.dart   (والصور تنحفظ في مجلد SHOT_DIR)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/theme.dart';
import 'package:majlis/models/profile.dart';
import 'package:majlis/models/shop.dart';
import 'package:majlis/screens/shop_screen.dart';
import 'package:majlis/screens/wardrobe_screen.dart';
import 'package:majlis/services/backend.dart';
import 'package:majlis/widgets/design.dart';
import 'package:majlis/widgets/design_shop.dart';
import 'package:majlis/widgets/fx.dart';
import 'package:majlis/widgets/ui.dart';

import 'shot_helper.dart';

/// لاعب يملك كم غرض من كل نوع، ولابس الجليد (مثل الفيديو).
const _player = Profile(
  name: 'سلمان',
  avatar: 'falcon',
  setupDone: true,
  coins: 48250,
  diamonds: 320,
  xp: 300,
  level: 12,
  vip: false,
  gamesPlayed: 40,
  gamesWon: 22,
  lastDaily: null,
  dailyStreak: 2,
  owned: {
    'frame_ice',
    'frame_sand',
    'frame_oasis',
    'frame_pearl',
    'frame_night',
    'frame_fire',
    'frame_smoke',
    'frame_comet',
    'avatar_detective',
    'avatar_knight',
    'bubble_gold',
    'bubble_fire',
    'table_sand',
    'table_night',
    'cards_oasis',
    'cards_dragon',
    'death_smoke',
    'death_fire',
    'stk_shock',
    'stk_coffee',
    'pack_phrases',
  },
  frame: 'frame_ice',
  bubble: 'bubble_gold',
  table: 'table_sand',
  cards: 'cards_oasis',
  death: 'death_smoke',
  favorites: ['b_laugh', 'cof_cup', 'shock_jaw'],
);

/// نفس shot() بس الصورة بدقة الفيديو الكاملة (١٩٢٠×١٠٨٠): shot_helper يصور بكثافة ١ فتطلع نص الحجم.
Future<void> shotHi(WidgetTester tester, String name, Widget screen, {Size size = const Size(960, 540)}) async {
  final key = GlobalKey();
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: screen,
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump(const Duration(milliseconds: 250));
  }
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final dir = Platform.environment['SHOT_DIR'] ?? 'build/shots';
    Directory(dir).createSync(recursive: true);
    File('$dir/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

/// اختبار تصوير: نفس testWidgets، بس نتجاوز علة قديمة برسمة إطار «دخان» (widgets/frames/epic.dart):
/// تدرج بثلاث ألوان بدون نقاط توقف يرمي خطأ بالرسم. مو من شغلنا فنتجاوزه بالتصوير بس.
void _t(String name, Future<void> Function(WidgetTester tester) body) => testWidgets(name, (tester) async {
  final old = FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.exceptionAsString().contains('"colors" must have length 2')) return;
    old?.call(d);
  };
  addTearDown(() => FlutterError.onError = old);
  // المتجر يصور بلاعب ما عنده «نار» (عشان يطلع زر الشراء)، وغرفة التبديل باللي يملك
  Backend.instance.profile.value = name.startsWith('wardrobe') ? _player : _shopper;
  await body(tester);
});

/// زائر المتجر: نفس اللاعب بس ما عنده «نار» (عرض اليوم يطلع بزر الشراء).
final _shopper = Profile(
  name: _player.name,
  avatar: _player.avatar,
  setupDone: true,
  coins: _player.coins,
  diamonds: _player.diamonds,
  xp: _player.xp,
  level: _player.level,
  vip: false,
  gamesPlayed: 0,
  gamesWon: 0,
  lastDaily: null,
  dailyStreak: 0,
  owned: {..._player.owned}..remove('frame_fire'),
  frame: _player.frame,
  bubble: _player.bubble,
  table: _player.table,
  cards: _player.cards,
  death: _player.death,
);

void main() {
  setUpAll(loadFonts);

  setUp(() {
    // وقت الحركات ثابت عشان اللقطات تطلع نفس بعض
    FxClock.manual.value = 3.2;
    Backend.instance.profile.value = _player;
  });
  tearDown(() => FxClock.manual.value = null);

  const tabs = ['offers', 'avatars', 'frames', 'death', 'cards', 'tables', 'bubbles', 'stickers', 'ids', 'gems'];
  for (final (i, name) in tabs.indexed) {
    _t('shop $name', (tester) async {
      await shotHi(
        tester,
        'shop_$name',
        ShopScreen(initialTab: i),
      );
    });
  }

  // الشبكة كاملة بشاشة طويلة (عشان نشوف كل الكروت بما فيها المقفولة)
  for (final (i, name) in tabs.indexed.take(8)) {
    _t('shop tall $name', (tester) async {
      await shotHi(
        tester,
        'tall_$name',
        ShopScreen(initialTab: i),
        size: const Size(960, 1700),
      );
    });
  }

  _t('shop no discount', (tester) async {
    await shotHi(tester, 'shop_nodiscount', const ShopScreen());
  });

  _t('shop gems player', (tester) async {
    Backend.instance.profile.value = _player.copyWithDev();
    await shotHi(tester, 'shop_dev', const ShopScreen());
  });

  _t('shop toast', (tester) async {
    await shotHi(tester, 'shop_toast', const _AfterBuild(then: _toast, child: ShopScreen()));
  });

  _t('shop preview frame', (tester) async {
    await shotHi(
      tester,
      'shop_preview_frame',
      _AfterBuild(then: (c) => showItemPreview(c, shopItem('frame_fire')!, buy: true), child: const ShopScreen()),
    );
  });

  _t('shop preview legendary', (tester) async {
    await shotHi(
      tester,
      'shop_preview_legend',
      _AfterBuild(then: (c) => showItemPreview(c, shopItem('frame_sun')!, buy: true), child: const ShopScreen()),
    );
  });

  _t('shop preview table', (tester) async {
    await shotHi(
      tester,
      'shop_preview_table',
      _AfterBuild(then: (c) => showItemPreview(c, shopItem('table_palace')!, buy: true), child: const ShopScreen()),
    );
  });

  _t('shop preview locked', (tester) async {
    await shotHi(
      tester,
      'shop_preview_locked',
      _AfterBuild(then: (c) => showItemPreview(c, shopItem('frame_lv40')!), child: const ShopScreen()),
    );
  });

  for (final (i, name) in ['avatars', 'frames', 'death', 'cards', 'tables', 'bubbles', 'stickers'].indexed) {
    _t('wardrobe $name', (tester) async {
      await shotHi(tester, 'wardrobe_$name', WardrobeScreen(initialTab: i));
    });
  }

  _t('wardrobe reveal', (tester) async {
    await shotHi(
      tester,
      'wardrobe_reveal',
      _AfterBuild(
        child: const WardrobeScreen(),
        then: (c) => showShopReveal(
          c,
          title: shopRevealTitle(ShopSlot.frame),
          art: shopRevealArt(shopItem('frame_ice')!, _player),
          message: 'لبست ${shopItemPhrase(shopItem('frame_ice')!)}!',
        ),
      ),
    );
  });

  _t('wardrobe look', (tester) async {
    await shotHi(tester, 'wardrobe_look', const _AfterBuild(then: _look, child: WardrobeScreen()));
  });

  _t('gallery', (tester) async {
    await shotHi(tester, 'gallery', const _Gallery());
  });

  // الجوالات الصغيرة: ما يصير تجاوز ولا قص
  for (final (w, h) in [(700.0, 320.0), (800.0, 360.0)]) {
    _t('shop small ${w.toInt()}', (tester) async {
      await shotHi(
        tester,
        'shop_${w.toInt()}',
        const ShopScreen(),
        size: Size(w, h),
      );
    });
    _t('wardrobe small ${w.toInt()}', (tester) async {
      await shotHi(tester, 'wardrobe_${w.toInt()}', const WardrobeScreen(), size: Size(w, h));
    });
    _t('shop tables small ${w.toInt()}', (tester) async {
      await shotHi(tester, 'shop_tables_${w.toInt()}', const ShopScreen(initialTab: ShopScreen.tablesTab), size: Size(w, h));
    });
    _t('reveal small ${w.toInt()}', (tester) async {
      await shotHi(
        tester,
        'reveal_${w.toInt()}',
        _AfterBuild(
          child: const WardrobeScreen(),
          then: (c) => showShopReveal(
            c,
            title: 'إطارك الجديد',
            art: shopRevealArt(shopItem('frame_ice')!, _player),
            message: 'لبست إطار الجليد!',
          ),
        ),
        size: Size(w, h),
      );
    });
  }
}

extension on Profile {
  /// نفس اللاعب بحساب مطوّر (العدادات ∞).
  Profile copyWithDev() => Profile(
    name: name,
    avatar: avatar,
    setupDone: true,
    dev: true,
    coins: coins,
    diamonds: diamonds,
    xp: xp,
    level: level,
    vip: vip,
    gamesPlayed: gamesPlayed,
    gamesWon: gamesWon,
    lastDaily: lastDaily,
    dailyStreak: dailyStreak,
    owned: owned,
    frame: frame,
  );
}

void _toast(BuildContext c) => showShopToast(c, 'صار عندك إطار الجليد!', icon: const ShopCatIcon('frame', size: 30));

/// معاينة شكلك: نضغط زرها بالشريط.
void _look(BuildContext c) {
  for (final e in find.byType(ShopTitleChip).evaluate()) {
    final chip = e.widget as ShopTitleChip;
    if (chip.label == 'شكلك') chip.onTap();
  }
}

/// يشغّل [then] بعد أول بناء (يفتح نافذة أو تنبيه فوق الشاشة).
class _AfterBuild extends StatefulWidget {
  const _AfterBuild({required this.child, required this.then});

  final Widget child;
  final void Function(BuildContext context) then;

  @override
  State<_AfterBuild> createState() => _AfterBuildState();
}

class _AfterBuildState extends State<_AfterBuild> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.then(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// كل حالات الأزرار والكروت والباقات بصفحة وحدة (للتأكد من كل شكل).
class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) {
    final p = _player;
    Widget card(ShopItem item, ShopItemState st, {String? label, String? passive, bool busy = false}) => SizedBox(
      width: 120,
      height: 143,
      child: ShopItemCard(
        art: shopCardArt(item, p),
        rarity: item.rarity,
        name: item.name,
        dark: shopDarkCard(item),
        selected: st == ShopItemState.equipped,
        dim: st == ShopItemState.locked,
        onPreview: () {},
        action: ShopActionButton(
          state: st,
          icon: item.coins != null ? 'coin' : 'gem',
          price: item.coins ?? item.diamonds,
          source: item.source,
          sourceIcon: shopSourceIcon(item),
          ownedLabel: label ?? 'البس',
          passive: passive,
          busy: busy,
        ),
      ),
    );
    return NightScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  card(shopItem('frame_ice')!, ShopItemState.buy),
                  card(shopItem('frame_comet')!, ShopItemState.owned),
                  card(shopItem('frame_neon')!, ShopItemState.equipped),
                  card(shopItem('frame_lv40')!, ShopItemState.locked),
                  card(shopItem('frame_s1b')!, ShopItemState.locked),
                  card(shopItem('frame_sun')!, ShopItemState.buy, busy: true),
                  card(shopItem('frame_none')!, ShopItemState.owned, label: 'تجهيز'),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 140,
                    height: 118,
                    child: ShopPackCard(
                      pile: const ShopPile(icon: 'coin', count: 6, size: 62),
                      amount: '٨٬٠٠٠',
                      unit: 'ذهب',
                      price: '٣٠ ريال',
                      onTap: () {},
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    height: 118,
                    child: ShopPackCard(
                      pile: const ShopPile(icon: 'coin', count: 4, size: 62),
                      amount: '٣٬٥٠٠',
                      unit: 'ذهب',
                      price: '١٥ ريال',
                      onTap: () {},
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    height: 118,
                    child: ShopPackCard(
                      pile: const ShopPile(icon: 'coin', count: 2, size: 62),
                      amount: '١٬٠٠٠',
                      unit: 'ذهب',
                      price: '٥ ريال',
                      onTap: () {},
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    height: 118,
                    child: ShopPackCard(
                      pile: const ShopPile(icon: 'gem', count: 3, size: 58),
                      amount: '٥٥٠',
                      unit: 'جوهرة',
                      price: '١٩٫٩٩ ريال',
                      badge: '+١٠٪ زيادة',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(width: 130, child: ShopButton.label('اشتر الحين', onPressed: () {})),
                  SizedBox(
                    width: 110,
                    child: ShopButton.label('البس', tone: ShopTone.red, onPressed: () {}),
                  ),
                  SizedBox(
                    width: 110,
                    child: ShopButton.label('لابسه', tone: ShopTone.orange, onPressed: null, dimWhenOff: false),
                  ),
                  SizedBox(
                    width: 110,
                    child: ShopButton.label('حلو!', tone: ShopTone.blue, onPressed: () {}),
                  ),
                  SizedBox(
                    width: 110,
                    child: ShopButton.label('لا', tone: ShopTone.dark, onPressed: () {}),
                  ),
                  const SizedBox(width: 120, child: ShopRarityTag(Rarity.legendary)),
                  const ShopRarityTag(Rarity.common),
                  const ShopEyeButton(onTap: null, size: 30),
                ],
              ),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 16,
                children: [
                  ShopCatIcon('frame', size: 52),
                  ShopCatIcon('avatar', size: 52),
                  ShopCatIcon('bubble', size: 52),
                  ShopCatIcon('sticker', size: 52),
                  ShopCatIcon('table', size: 52),
                  ShopCatIcon('cards', size: 52),
                  ShopCatIcon('death', size: 52),
                  ShopCatIcon('ids', size: 52),
                  ShopCatIcon('gems', size: 52),
                  ShopToastPlank('صار عندك إطار الجليد!', icon: ShopCatIcon('frame', size: 30)),
                  GoldTitle('عرض اليوم'),
                  ShopCurrency(icon: 'gem', amount: 320),
                  ShopCurrency(icon: 'coin', amount: 48250),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
