import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/widgets/page_transition.dart';

/// صفحة فيها ألوان وأشكال ونص، عشان أي فرق بمكانها أو شفافيتها يبان بالمقارنة.
class _Page extends StatelessWidget {
  const _Page(this.hue, this.label);

  final double hue;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [HSVColor.fromAHSV(1, hue, .7, .9).toColor(), HSVColor.fromAHSV(1, (hue + 60) % 360, .8, .4).toColor()],
      ),
    ),
    child: Stack(
      children: [
        for (var i = 0; i < 6; i++)
          Positioned(
            left: 40.0 + i * 110,
            top: 30.0 + (i % 3) * 90,
            child: Container(width: 70, height: 50, color: HSVColor.fromAHSV(1, (hue + i * 50) % 360, 1, 1).toColor()),
          ),
        Center(
          child: Text(label, style: const TextStyle(fontSize: 60, color: Colors.white)),
        ),
      ],
    ),
  );
}

/// يصوّر الشاشة كلها في أوقات معينة من حركة التنقل (دخول صفحة، ورجوع، ورجوع بنص الدخول).
Future<List<ByteData>> _record(WidgetTester tester, PageTransitionsBuilder builder) async {
  final shot = GlobalKey();
  final nav = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    RepaintBoundary(
      key: shot,
      child: MaterialApp(
        navigatorKey: nav,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          platform: TargetPlatform.android,
          colorScheme: const ColorScheme.dark(surface: Color(0xFF2A3550)),
          pageTransitionsTheme: PageTransitionsTheme(builders: {TargetPlatform.android: builder}),
        ),
        home: const _Page(20, 'A'),
      ),
    ),
  );
  final shots = <ByteData>[];
  Future<void> take() async {
    final boundary = shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final data = await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData();
      image.dispose();
      return bytes!;
    });
    shots.add(data!);
  }

  Future<void> steps(List<int> ms) async {
    for (final d in ms) {
      await tester.pump(Duration(milliseconds: d));
      await take();
    }
  }

  // دخول (كل ٥٠ms على طول الحركة)
  nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => const _Page(200, 'B')));
  await steps([0, 25, 25, 50, 50, 50, 50, 50, 50, 50, 50]);
  await tester.pumpAndSettle();
  await take();
  // رجوع
  nav.currentState!.pop();
  await steps([0, 25, 25, 50, 50, 50, 50, 50, 50, 50, 50]);
  await tester.pumpAndSettle();
  await take();
  // رجوع بنص الدخول (الحركة تنعكس بنصها)
  nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => const _Page(120, 'C')));
  await steps([0, 60, 60, 60]);
  nav.currentState!.pop();
  await steps([0, 30, 30, 60, 60]);
  await tester.pumpAndSettle();
  await take();
  return shots;
}

void main() {
  testWidgets('التنقل بالصور شكله نفس حركة أندرويد الأصلية بكل لحظة', (tester) async {
    final original = await _record(tester, const FadeForwardsPageTransitionsBuilder());
    final smooth = await _record(tester, const SmoothPageTransitionsBuilder());
    expect(smooth.length, original.length);
    for (var i = 0; i < original.length; i++) {
      final a = original[i].buffer.asUint8List(), b = smooth[i].buffer.asUint8List();
      expect(b.length, a.length);
      var sum = 0, off = 0;
      for (var j = 0; j < a.length; j++) {
        final d = (a[j] - b[j]).abs();
        sum += d;
        if (d > 24) off++;
      }
      final mean = sum / a.length;
      // الفرق الوحيد المسموح: حواف الصفحة على بكسل الشاشة (الأصل يرسمها بين بكسلين)، وتقريب الشفافية
      // (بمحرك Impeller، مثل الجوال، يوصل ١٫٥ من ٢٥٥).
      expect(mean, lessThan(2), reason: 'لقطة $i: متوسط الفرق $mean');
      expect(off / a.length, lessThan(.002), reason: 'لقطة $i: بكسلات مختلفة ${off / a.length}');
    }
  });
}
