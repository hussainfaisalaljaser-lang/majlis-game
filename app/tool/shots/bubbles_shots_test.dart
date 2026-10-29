// تصوير الفقاعات (شكل الكلام اللي يطلع فوق اللاعب): المعرض، لقطات الحركة، الأحجام الصغيرة، المتجر وغرفة التبديل.
// التشغيل:  flutter test tool/shots/bubbles_shots_test.dart   (والصور تنحفظ في مجلد SHOT_DIR)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/profile.dart';
import 'package:majlis/models/shop.dart';
import 'package:majlis/screens/shop_screen.dart';
import 'package:majlis/theme.dart';
import 'package:majlis/screens/wardrobe_screen.dart';
import 'package:majlis/services/backend.dart';
import 'package:majlis/widgets/bubble.dart';
import 'package:majlis/widgets/design_bubbles.dart';
import 'package:majlis/widgets/fx.dart';
import 'package:majlis/widgets/game/reactions_sheet.dart';

import 'shot_helper.dart';

/// كل فقاعات المتجر مرتبة مثل الكتالوج.
final _items = [
  for (final i in catalog)
    if (i.slot == ShopSlot.bubble) i,
];

/// لاعب تجريبي بفقاعة [bubble] ويملك باقة السوالف.
Profile _profile([String bubble = 'bubble_gold']) => Profile(
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
  owned: const {
    'bubble_gold',
    'bubble_fire',
    'bubble_ice',
    'bubble_night',
    'bubble_sea',
    'bubble_desert',
    'bubble_emerald',
    'bubble_coffee',
    'pack_phrases',
  },
  frame: 'frame_ice',
  bubble: bubble,
  table: 'table_sand',
  cards: 'cards_oasis',
  death: 'death_smoke',
  favorites: const ['b_laugh', 'cof_cup', 'shock_jaw'],
);

/// بطاقة تشبه كرت المتجر (ورق) فيها الفقاعة واسمها.
class _Cell extends StatelessWidget {
  const _Cell(this.item, {this.t, this.fs = 15, this.text = 'أشك فيه', this.w = 150, this.h = 112});

  final ShopItem item;
  final double? t;
  final double fs;
  final String text;
  final double w;
  final double h;

  @override
  Widget build(BuildContext context) {
    final look = item.bubble!.look!;
    return Container(
      width: w,
      height: h,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFE8CF9E),
        border: Border.all(color: item.rarity.color, width: 2.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: BubbleArt(look: look, text: text, fontSize: fs, maxWidth: w - 10, time: t == null ? null : ValueNotifier(t!)),
            ),
          ),
          Text(item.name, style: const TextStyle(fontFamily: 'Baloo', fontSize: 13, color: Color(0xFF3A2210), fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF3A2414),
    body: Padding(
      padding: const EdgeInsets.all(8),
      child: Align(alignment: Alignment.topCenter, child: Wrap(alignment: WrapAlignment.center, children: children)),
    ),
  );
}

/// مثل shot() بس نضغط على [tapText] قبل التصوير (لتبويب الكلام بلوحة الردود).
Future<void> _shotTap(WidgetTester tester, String name, Widget screen, String tapText, {required Size size}) async {
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
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(tapText));
  for (var i = 0; i < 4; i++) {
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

void main() {
  setUpAll(loadFonts);

  setUp(() {
    FxClock.manual.value = 3.2;
    Backend.instance.profile.value = _profile();
  });
  tearDown(() => FxClock.manual.value = null);

  // المعرض كامل بحجم الكرت (مثل التصميم)
  testWidgets('gallery', (tester) async {
    await shot(tester, 'gallery', _Board(children: [for (final i in _items) _Cell(i, w: 148, h: 108, fs: 15)]));
  });

  // نفس المعرض بحجم كرت الجوال الصغير
  testWidgets('gallery small', (tester) async {
    await shot(tester, 'gallery_small', _Board(children: [for (final i in _items) _Cell(i, w: 110, h: 80, fs: 11)]), size: const Size(700, 320));
  });

  // تكبير لفحص التفاصيل: ٦ بكل صورة
  for (var g = 0; g * 6 < _items.length; g++) {
    testWidgets('big $g', (tester) async {
      await shot(
        tester,
        'big_$g',
        _Board(children: [for (final i in _items.skip(g * 6).take(6)) _Cell(i, w: 300, h: 220, fs: 34)]),
      );
    });
  }

  // لقطات الحركة: ٨ لقطات بفواصل لكل فقاعة (٤ بصف)
  for (final item in _items) {
    testWidgets('film ${item.id}', (tester) async {
      await shot(
        tester,
        'film_${item.bubble!.look!.name}',
        _Board(children: [for (var k = 0; k < 8; k++) _Cell(item, t: 1.0 + k * .42, fs: 22, w: 226, h: 150)]),
      );
    });
  }

  // كلام طويل وقصير جداً
  testWidgets('text lengths', (tester) async {
    final some = [for (final id in ['bubble_classic', 'bubble_fire', 'bubble_ice', 'bubble_rainbow', 'bubble_blood']) shopItem(id)!];
    await shot(
      tester,
      'text_lengths',
      _Board(
        children: [
          for (final i in some) ...[
            _Cell(i, text: 'ك', w: 150, h: 100, fs: 16),
            _Cell(i, text: 'والله وصلني ٣ حمر!', w: 190, h: 100, fs: 16),
            _Cell(i, text: 'هذا كلام طويل جداً جداً يتجاوز العرض الأقصى للفقاعة ويلتف على سطرين أو ثلاثة', w: 260, h: 130, fs: 16),
          ],
        ],
      ),
    );
  });

  // أحجام الخط: صغير جداً، ومتوسط، وكبير
  testWidgets('font sizes', (tester) async {
    final some = [for (final id in ['bubble_gold', 'bubble_sea', 'bubble_emerald', 'bubble_ice']) shopItem(id)!];
    await shot(
      tester,
      'font_sizes',
      _Board(
        children: [
          for (final i in some) ...[
            _Cell(i, fs: 10, w: 120, h: 60),
            _Cell(i, fs: 13, w: 140, h: 80),
            _Cell(i, fs: 20, w: 180, h: 100),
            _Cell(i, fs: 28, w: 260, h: 140),
          ],
        ],
      ),
    );
  });

  // وضع الحركات الخفيفة: ثابتة بس مرسومة
  testWidgets('lite', (tester) async {
    FxClock.manual.value = null;
    FxClock.lite.value = true;
    addTearDown(() => FxClock.lite.value = false);
    await shot(tester, 'lite', _Board(children: [for (final i in _items.take(12)) _Cell(i, w: 148, h: 108)]));
  });

  // المتجر وغرفة التبديل (تبويب الفقاعات)
  testWidgets('shop bubbles', (tester) async {
    await shot(tester, 'shop_bubbles', const ShopScreen(initialTab: 2));
  });
  testWidgets('shop bubbles phone', (tester) async {
    await shot(tester, 'shop_bubbles_phone', const ShopScreen(initialTab: 2), size: const Size(700, 320));
  });
  testWidgets('wardrobe bubbles', (tester) async {
    await shot(tester, 'wardrobe_bubbles', const WardrobeScreen(initialTab: 2));
  });

  // فقاعة بالطاولة فوق لاعب (مثل اللعبة: كلام كبير شوي)
  testWidgets('in game size', (tester) async {
    await shot(
      tester,
      'ingame',
      Scaffold(
        backgroundColor: const Color(0xFF1B1030),
        body: Center(
          child: Wrap(
            spacing: 30,
            runSpacing: 30,
            children: [
              for (final id in ['bubble_classic', 'bubble_gold', 'bubble_fire', 'bubble_night', 'bubble_ice', 'bubble_royal'])
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChatBubble(style: bubbleStyle(id), text: 'أشك في سلمان!', fontSize: 20, maxWidth: 260),
                    const CircleAvatar(radius: 26, backgroundColor: Color(0xFFD4A35A)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  });

  // لوحة الردود: كل الجمل بفقاعة اللاعب (الجوال بالعرض)
  for (final id in ['bubble_fire', 'bubble_ice', 'bubble_rainbow']) {
    testWidgets('reactions $id', (tester) async {
      Backend.instance.profile.value = _profile(id);
      await _shotTap(
        tester,
        'reactions_$id',
        Scaffold(
          backgroundColor: const Color(0xFF1B1030),
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: 330,
              child: ReactionsSheet(
                profile: Backend.instance.profile.value,
                onText: (_) {},
                onSticker: (_) {},
                onFavorites: (_) {},
                onClearOpinion: () {},
              ),
            ),
          ),
        ),
        'كلام',
        size: const Size(760, 340),
      );
    });
  }
}
