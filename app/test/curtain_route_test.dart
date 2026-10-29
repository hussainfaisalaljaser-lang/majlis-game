import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/services/sounds.dart';
import 'package:majlis/widgets/curtain_route.dart';

double _pageOpacity(WidgetTester tester) => tester
    .widget<Opacity>(find.ancestor(of: find.text('الصفحة الجديدة'), matching: find.byType(Opacity)).first)
    .opacity;

void main() {
  setUp(() => Sounds.silent = true);

  testWidgets('الستارة: الصفحة الجديدة تبان بعد ما تنسدل الستارة، وبالرجوع العكس', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const Scaffold(body: Text('الصفحة القديمة'));
          },
        ),
      ),
    );
    Navigator.of(ctx).push(curtainRoute<void>((_) => const Scaffold(body: Text('الصفحة الجديدة'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(_pageOpacity(tester), 0, reason: 'قبل نص الحركة الستارة تنسدل على القديمة');
    expect(find.text('الصفحة القديمة'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_pageOpacity(tester), 1, reason: 'بعد نص الحركة الجديدة تبان والستارة تنفتح');
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);

    Navigator.of(ctx).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_pageOpacity(tester), 1);
    await tester.pump(const Duration(milliseconds: 400));
    expect(_pageOpacity(tester), 0, reason: 'وقت الرجوع الستارة تنسدل على الجديدة ثم تفتح على القديمة');
    await tester.pumpAndSettle();
    expect(find.text('الصفحة الجديدة'), findsNothing);
    expect(find.text('الصفحة القديمة'), findsOneWidget);
  });
}
