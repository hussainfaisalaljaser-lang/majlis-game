// تصوير الرئيسية والافتتاح للمقارنة مع الفيديو.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/screens/home_screen.dart';
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

  testWidgets('splash', (tester) async {
    await shot(tester, 'splash', const SplashView());
  });
}
