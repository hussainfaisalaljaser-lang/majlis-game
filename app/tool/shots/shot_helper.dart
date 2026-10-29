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

/// فحص محاذاة الكلام: كل نص بسطر واحد جوا مربع بخلفية (زر، شريط، كبسولة) لازم يكون بنصه عمودياً.
/// يطبع سطر «ALIGN» لكل نص ينحرف أكثر من ١٫٣ بكسل عن نص مربعه (بالوحدات المنطقية).
void auditAlign(String screen) {
  final seen = <String>{};
  void check(RenderParagraph p, String text) {
    final fs = p.text.style?.fontSize;
    if (fs == null || p.size.height >= fs * 1.9 || p.size.height < 8) return;
    final textCenter = p.localToGlobal(p.size.center(Offset.zero));
    RenderObject? a = p.parent;
    while (a != null) {
      if (a is RenderDecoratedBox && a.hasSize) {
        final d = a.decoration;
        final painted = d is BoxDecoration && (d.color != null || d.gradient != null || d.image != null);
        if (painted &&
            a.position == DecorationPosition.background &&
            a.size.height > p.size.height * 1.12 &&
            a.size.height < p.size.height * 3.2 &&
            a.size.width >= p.size.width) {
          final boxCenter = a.localToGlobal(a.size.center(Offset.zero));
          final dy = textCenter.dy - boxCenter.dy;
          if (dy.abs() > 1.3) {
            final key = '$text@${textCenter.dx.round()},${textCenter.dy.round()}';
            if (seen.add(key)) {
              // ignore: avoid_print
              print('ALIGN|$screen|$text|dy=${dy.toStringAsFixed(1)}|box=${a.size.height.toStringAsFixed(0)}|text=${p.size.height.toStringAsFixed(0)}');
            }
          }
          return;
        }
      }
      a = a.parent;
    }
  }

  void walk(Element e) {
    final ro = e.renderObject;
    if (ro is RenderParagraph && ro.attached && ro.hasSize) {
      final text = ro.text.toPlainText().trim();
      if (text.isNotEmpty) check(ro, text);
    }
    e.visitChildren(walk);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(walk);
}

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
  auditAlign(name);
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    Directory(_outDir).createSync(recursive: true);
    File('$_outDir/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
  });
}
