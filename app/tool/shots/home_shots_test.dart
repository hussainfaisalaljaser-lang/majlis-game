// تصوير الرئيسية والافتتاح للمقارنة مع الفيديو.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/screens/home_screen.dart';
import 'package:majlis/screens/mode_screen.dart';
import 'package:majlis/widgets/splash.dart';

import 'shot_helper.dart';

void main() {
  setUpAll(loadFonts);

  testWidgets('home', (tester) async {
    await shot(tester, 'home', const HomeScreen());
  });

  testWidgets('home small', (tester) async {
    await shot(tester, 'home_small', const HomeScreen(), size: const Size(800, 360));
  });

  // القائمة اللي تنفتح من لوح اسمك (فيها خانة «الصوت»)، ومنها نافذة مستوى الصوت
  testWidgets('home menu', (tester) async {
    final semantics = tester.ensureSemantics();
    await shot(tester, 'home_menu', const HomeScreen(), act: (t) => t.tap(find.bySemanticsLabel(RegExp('القائمة'))));
    await shot(
      tester,
      'home_menu_small',
      const HomeScreen(),
      size: const Size(640, 360),
      act: (t) => t.tap(find.bySemanticsLabel(RegExp('القائمة'))),
    );
    semantics.dispose();
  });

  // اختيار الطور بعد «العب الآن»
  testWidgets('mode screen', (tester) async {
    await shot(tester, 'mode', const ModeScreen());
    await shot(tester, 'mode_small', const ModeScreen(), size: const Size(800, 360));
  });

  testWidgets('splash', (tester) async {
    await shot(tester, 'splash', const SplashView());
  });

  testWidgets('splash progress', (tester) async {
    await shot(tester, 'splash_progress', SplashView(progress: ValueNotifier<double>(.62)));
  });
}
