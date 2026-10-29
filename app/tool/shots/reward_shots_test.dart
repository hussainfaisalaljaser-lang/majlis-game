// لقطات حركة المكافأة في الرئيسية (العملات تطير للرصيد، الخبرة، الترقية).
// التشغيل:  SHOT_DIR=<مجلد> flutter test tool/shots/reward_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/profile.dart';
import 'package:majlis/screens/home_screen.dart';
import 'package:majlis/services/backend.dart';
import 'package:majlis/theme.dart';
import 'package:majlis/widgets/curtain_route.dart';
import 'package:majlis/widgets/fx.dart';
import 'package:majlis/widgets/reward_fly.dart';

import 'shot_helper.dart';

final _outDir = Platform.environment['SHOT_DIR'] ?? 'build/shots';

Profile _p(int coins, int xp, int level) => Profile.fromJson({
  'name': 'أنا',
  'avatar': 'emir',
  'coins': coins,
  'diamonds': 5,
  'xp': xp,
  'level': level,
  'gamesPlayed': 10,
  'gamesWon': 5,
  'dailyStreak': 1,
});

void main() {
  setUpAll(loadFonts);

  for (final size in const [Size(960, 540), Size(800, 360)]) {
    testWidgets('reward fly ${size.width.toInt()}', (tester) async {
      FxClock.manual.value = 3.0;
      addTearDown(() => FxClock.manual.value = null);
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      RewardFx.release();
      Backend.instance.profile.value = _p(1000, 60, 1);
      RewardFx.begin(Backend.instance.profile.value);
      Backend.instance.profile.value = _p(1600, 180, 2);
      RewardFx.grant('R${size.width}', coins: 600, xp: 120);

      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      var t = 0.0;
      Future<void> at(double target, String name) async {
        while (t < target) {
          await tester.pump(const Duration(milliseconds: 50));
          t += .05;
        }
        await tester.runAsync(() async {
          final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await b.toImage(pixelRatio: 2);
          final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
          Directory(_outDir).createSync(recursive: true);
          File('$_outDir/reward_${size.width.toInt()}_$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
        });
      }

      await at(.3, 'a_chips');
      await at(1.3, 'b_burst');
      await at(2.2, 'c_flying');
      await at(3.2, 'd_xp');
      await at(3.8, 'e_level');
      await at(6.5, 'f_end');
      expect(RewardFx.pending, isFalse);
    });
  }

  // انتقال الستارة بين الرئيسية وصفحة ثانية، في ثلاث لحظات
  testWidgets('curtain', (tester) async {
    FxClock.manual.value = 3.0;
    addTearDown(() => FxClock.manual.value = null);
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    RewardFx.release();
    Backend.instance.profile.value = _p(1000, 60, 1);
    final key = GlobalKey();
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          navigatorKey: nav,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    nav.currentState!.push(
      curtainRoute<void>(
        (_) => const Scaffold(
          backgroundColor: Color(0xFF123456),
          body: Center(child: Text('الصفحة الجديدة')),
        ),
      ),
    );
    var t = 0.0;
    Future<void> at(double target, String name) async {
      while (t < target) {
        await tester.pump(const Duration(milliseconds: 50));
        t += .05;
      }
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        Directory(_outDir).createSync(recursive: true);
        File('$_outDir/curtain_$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
      });
    }

    await tester.pump();
    await at(.25, 'a_closing');
    await at(.45, 'b_closed');
    await at(.7, 'c_opening');
  });
}
