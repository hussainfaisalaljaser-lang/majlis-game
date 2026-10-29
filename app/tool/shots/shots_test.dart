// أداة تصوير الشاشات: تشغّل الشاشات بملف لاعب تجريبي وتحفظها صور PNG (بدون جوال ولا سيرفر)،
// عشان نقارن التصميم باللقطات. التشغيل:  flutter test tool/shots/shots_test.dart
// المخرجات تنحفظ في مجلد SHOT_DIR (أو build/shots).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/screens/home_screen.dart';
import 'package:majlis/screens/shop_screen.dart';
import 'package:majlis/screens/pass_screen.dart';
import 'package:majlis/screens/wardrobe_screen.dart';
import 'package:majlis/screens/missions_screen.dart';
import 'package:majlis/screens/leaderboard_screen.dart';
import 'package:majlis/screens/profile_screen.dart';
import 'package:majlis/screens/tournament_screen.dart';
import 'package:majlis/screens/welcome_screen.dart';
import 'package:majlis/screens/how_to_play_screen.dart';
import 'package:majlis/screens/history_screen.dart';
import 'package:majlis/screens/clans_screen.dart';
import 'package:majlis/screens/friends_screen.dart';
import 'package:majlis/screens/tables_screen.dart';
import 'package:majlis/widgets/mode_theme.dart';
import 'package:majlis/theme.dart';

final _outDir = Platform.environment['SHOT_DIR'] ?? 'build/shots';

/// الخطوط ما تنحمل تلقائياً في الاختبار، فنحملها من مجلد الخطوط.
Future<void> _loadFonts() async {
  final fonts = <String, List<String>>{
    'Tajawal': ['Tajawal-Regular', 'Tajawal-Medium', 'Tajawal-Bold', 'Tajawal-ExtraBold'],
    'Marhey': ['Marhey-Bold'],
    'Baloo': ['BalooBhaijaan2-Bold', 'BalooBhaijaan2-ExtraBold'],
  };
  for (final e in fonts.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      final file = File('assets/fonts/$f.ttf');
      if (file.existsSync()) loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }
}

/// شاشة بحجم جوال بالعرض (٩٦٠×٥٤٠) وكثافة ٢، فتطلع الصورة ١٩٢٠×١٠٨٠ مثل الفيديو.
Future<void> shot(WidgetTester tester, String name, Widget screen, {Size size = const Size(960, 540)}) async {
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
  // نخلي الصور تنفك (تحتاج وقت حقيقي) ثم نحرك الرسوم شوي.
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump(const Duration(milliseconds: 250));
  }
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    Directory(_outDir).createSync(recursive: true);
    File('$_outDir/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('home', (tester) async {
    await shot(tester, 'home', const HomeScreen());
  });

  testWidgets('shop', (tester) async {
    await shot(tester, 'shop', const ShopScreen());
  });

  testWidgets('pass', (tester) async {
    await shot(tester, 'pass', const PassScreen());
  });

  testWidgets('wardrobe', (tester) async {
    await shot(tester, 'wardrobe', const WardrobeScreen());
  });

  testWidgets('missions', (tester) async {
    await shot(tester, 'missions', const MissionsScreen());
  });

  testWidgets('leaderboard', (tester) async {
    await shot(tester, 'leaderboard', const LeaderboardScreen());
  });

  testWidgets('profile', (tester) async {
    await shot(tester, 'profile', const ProfileScreen());
  });

  testWidgets('tournament', (tester) async {
    await shot(tester, 'tournament', const TournamentScreen());
  });

  testWidgets('welcome', (tester) async {
    await shot(tester, 'welcome', const WelcomeScreen());
  });

  testWidgets('howto', (tester) async {
    await shot(tester, 'howto', const HowToPlayScreen());
  });

  testWidgets('history', (tester) async {
    await shot(tester, 'history', const HistoryScreen());
  });

  testWidgets('clans', (tester) async {
    await shot(tester, 'clans', const ClansScreen());
  });

  testWidgets('friends', (tester) async {
    await shot(tester, 'friends', const FriendsScreen());
  });

  testWidgets('tables', (tester) async {
    await shot(tester, 'tables', const TablesScreen(mode: ModeTheme.classic));
  });

}
