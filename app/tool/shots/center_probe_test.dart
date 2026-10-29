// قياس بالبكسل: وين يقع حبر الكلام بالنسبة لنص سطره (للتأكد إن الكلام بالوسط فعلاً).
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/theme.dart';

import 'shot_helper.dart';

/// يرجع (نص الحبر عمودياً − نص السطر) بالنسبة لحجم الخط (بوحدات em).
Future<double> probe(WidgetTester tester, String text, String family, FontWeight weight) async {
  final key = GlobalKey();
  const size = 100.0;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: Colors.white,
            child: Text(
              text,
              style: TextStyle(fontFamily: family, fontWeight: weight, fontSize: size, color: Colors.black),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  late double result;
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final width = image.width, height = image.height;
    var top = height, bottom = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        if (data.getUint8(i) < 90) {
          if (y < top) top = y;
          if (y > bottom) bottom = y;
        }
      }
    }
    result = ((top + bottom) / 2 - height / 2) / size;
  });
  return result;
}

void main() {
  setUpAll(loadFonts);

  testWidgets('ink centering', (tester) async {
    const words = ['الجولة ٦', 'البس', 'تمام', 'الهدية اليومية', 'العب الآن', 'مجلس الخونة', 'ضيف', 'الأصدقاء', '٣٢٠', 'اشتر', 'عندك', 'الديوان', 'المتجر', 'فهمت'];
    for (final (family, weight) in [(kufi, FontWeight.w800), ('ReadexPro', FontWeight.w700)]) {
      var sum = 0.0;
      final lines = <String>[];
      for (final w in words) {
        final d = await probe(tester, w, family, weight);
        sum += d;
        lines.add('${d.toStringAsFixed(3)} $w');
      }
      // ignore: avoid_print
      print('PROBE $family mean ink offset (+ = ink lower than line centre): ${(sum / words.length).toStringAsFixed(3)} em | ${lines.join(' | ')}');
    }
  });
}
