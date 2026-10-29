// تصوير كروت باقات الملصقات (المتجر وغرفة التبديل) بلاعب تجريبي، بدون سيرفر.
// التشغيل:  flutter test tool/shots/s1_pack_cards_test.dart   (والصور تنحفظ في مجلد SHOT_DIR)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/profile.dart';
import 'package:majlis/models/shop.dart';
import 'package:majlis/screens/shop_screen.dart';
import 'package:majlis/screens/wardrobe_screen.dart';
import 'package:majlis/services/backend.dart';
import 'package:majlis/theme.dart';
import 'package:majlis/widgets/design_shop.dart';
import 'package:majlis/widgets/design_stickers.dart';
import 'package:majlis/widgets/fx.dart';

import 'shot_helper.dart';

/// لاعب يملك باقتين بس (صدمة والقهوة) فوق الأساسي المجاني.
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
  owned: {'stk_shock', 'stk_coffee'},
  favorites: ['b_laugh', 'cof_cup', 'shock_jaw'],
);

/// نفس اللاعب بس يملك كل الدرجات (عشان نشوف حدود النادر والملحمي والأسطوري وباقة السوالف).
const _rich = Profile(
  name: 'سلمان',
  avatar: 'falcon',
  setupDone: true,
  coins: 48250,
  diamonds: 320,
  xp: 300,
  level: 40,
  vip: false,
  gamesPlayed: 40,
  gamesWon: 22,
  lastDaily: null,
  dailyStreak: 2,
  owned: {'stk_shock', 'stk_coffee', 'stk_party', 'stk_vip', 'stk_legend', 'pack_phrases'},
  favorites: ['b_laugh', 'cof_cup', 'shock_jaw'],
);

/// تصوير بدقة ١٩٢٠×١٠٨٠ (pixelRatio ٢) مثل الفيديو.
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

/// اختبار تصوير: نفس testWidgets، بس نتجاوز علة قديمة برسمة إطار «دخان» (widgets/frames/epic.dart).
void _t(String name, Profile who, Future<void> Function(WidgetTester tester) body) => testWidgets(name, (tester) async {
  final old = FlutterError.onError;
  FlutterError.onError = (d) {
    if (d.exceptionAsString().contains('"colors" must have length 2')) return;
    old?.call(d);
  };
  addTearDown(() => FlutterError.onError = old);
  Backend.instance.profile.value = who;
  await body(tester);
});

void main() {
  setUpAll(loadFonts);

  setUp(() {
    // وقت الحركات ثابت عشان اللقطات تطلع نفس بعض
    FxClock.manual.value = 3.2;
  });
  tearDown(() => FxClock.manual.value = null);

  for (final (w, h) in [(960.0, 540.0), (800.0, 360.0)]) {
    final s = '${w.toInt()}';
    final size = Size(w, h);
    _t('shop stickers $s', _player, (tester) async {
      await shotHi(tester, 'shop_stickers_$s', const ShopScreen(initialTab: ShopScreen.stickersTab), size: size);
    });
    _t('wardrobe stickers $s', _player, (tester) async {
      await shotHi(tester, 'wardrobe_stickers_$s', const WardrobeScreen(initialTab: 6), size: size);
    });
  }

  // كل الباقات بشاشة طويلة (عشان نشوف كل الحالات: مملوك، سعر ذهب/جواهر، مستوى، موسم)
  _t('shop stickers tall', _player, (tester) async {
    await shotHi(
      tester,
      'shop_stickers_tall',
      const ShopScreen(initialTab: ShopScreen.stickersTab),
      size: const Size(960, 1300),
    );
  });
  _t('wardrobe stickers rich', _rich, (tester) async {
    await shotHi(tester, 'wardrobe_stickers_rich', const WardrobeScreen(initialTab: 6), size: const Size(960, 900));
  });
  _t('shop stickers rich', _rich, (tester) async {
    await shotHi(
      tester,
      'shop_stickers_rich',
      const ShopScreen(initialTab: ShopScreen.stickersTab),
      size: const Size(960, 1300),
    );
  });

  // كل الباقات وكل الدرجات بصفحة وحدة (للتأكد من كل شكل)
  _t('pack gallery', _player, (tester) async {
    await shotHi(tester, 'pack_gallery', const _Gallery(), size: const Size(960, 700));
  });
}

/// كل حالات كرت الباقة بصفحة وحدة (كل درجة، ومملوك، وسعر ذهب وجواهر، ومقفول، وباقة الكلام).
class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) {
    Widget card(String id, ShopItemState st, {bool busy = false}) {
      final item = shopItem(id)!;
      return FittedBox(
        child: StickerPackCard(
          name: item.name,
          rarity: item.rarity,
          stickers: item.stickers,
          phrases: item.phrases ? stickerPackPhrases(item.id) : null,
          dim: st == ShopItemState.locked,
          onPreview: () {},
          action: StickerPackPill(
            state: st,
            icon: item.coins != null ? 'coin' : 'gem',
            price: item.coins ?? item.diamonds,
            source: item.source,
            sourceIcon: shopSourceIcon(item),
            busy: busy,
            onTap: () {},
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2A160B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              card('stk_basic', ShopItemState.owned),
              card('stk_shock', ShopItemState.buy),
              card('stk_party', ShopItemState.buy),
              card('stk_vip', ShopItemState.buy),
              card('pack_phrases', ShopItemState.buy),
              card('pack_phrases', ShopItemState.owned),
              card('stk_hype', ShopItemState.locked),
              card('stk_s1', ShopItemState.locked),
              card('stk_legend', ShopItemState.locked),
              card('stk_coffee', ShopItemState.buy, busy: true),
            ],
          ),
        ),
      ),
    );
  }
}
