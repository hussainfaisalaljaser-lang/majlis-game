// أدوات تصوير الشاشات (يستخدمها كل ملف اختبار في هذا المجلد).
// المخرجات تنحفظ في مجلد SHOT_DIR (أو build/shots).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/services/sounds.dart';
import 'package:majlis/theme.dart';

final _outDir = Platform.environment['SHOT_DIR'] ?? 'build/shots';

/// الخطوط ما تنحمل تلقائياً في الاختبار، فنحملها من مجلد الخطوط.
Future<void> loadFonts() async {
  Sounds.silent = true;
  final fonts = <String, List<String>>{
    'ReadexPro': ['ReadexPro-Regular', 'ReadexPro-Medium', 'ReadexPro-Bold'],
    'ElMessiri': ['ElMessiri-Regular', 'ElMessiri-Bold'],
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
Future<void> shot(
  WidgetTester tester,
  String name,
  Widget screen, {
  Size size = const Size(960, 540),
  Future<void> Function(WidgetTester tester)? act,
}) async {
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
  // حركة قبل التصوير (مثل ضغطة تفتح قائمة)
  if (act != null) {
    await act(tester);
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pump(const Duration(milliseconds: 250));
    }
  }
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    Directory(_outDir).createSync(recursive: true);
    File('$_outDir/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
  });
}
