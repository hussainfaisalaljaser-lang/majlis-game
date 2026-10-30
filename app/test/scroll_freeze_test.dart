import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/widgets/fx.dart';
import 'package:majlis/widgets/scroll_freeze.dart';

/// كرت فيه ظل يطلع برا حدوده ورسمة تتحرك مع ساعة الحركات، ويعد كم مرة انرسم.
class _Card extends StatelessWidget {
  const _Card(this.i, this.paints);

  final int i;
  final List<double> paints;

  @override
  Widget build(BuildContext context) => FxClock(
    builder: (context, t) => DecoratedBox(
      decoration: BoxDecoration(
        color: HSVColor.fromAHSV(1, (i * 40) % 360, .6, .9).toColor(),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 7, offset: Offset(0, 4))],
      ),
      child: CustomPaint(painter: _Spin(t, paints), child: const SizedBox.expand()),
    ),
  );
}

class _Spin extends CustomPainter {
  _Spin(this.t, this.paints) : super(repaint: t);

  final ValueListenable<double> t;
  final List<double> paints;

  @override
  void paint(Canvas canvas, Size size) {
    paints.add(t.value);
    final c = size.center(Offset.zero);
    canvas.drawCircle(c + Offset.fromDirection(t.value * 2, size.width * .25), 8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_Spin old) => false;
}

Widget _list({required bool freeze, required ScrollController controller, required List<double> paints}) {
  Widget list = ListView.builder(
    controller: controller,
    padding: const EdgeInsets.all(16),
    itemCount: 30,
    itemExtent: 130,
    itemBuilder: (context, i) {
      final card = Padding(padding: const EdgeInsets.all(12), child: _Card(i, paints));
      return freeze ? Freezable(margin: 20, child: card) : card;
    },
  );
  if (freeze) list = ScrollFreeze(child: list);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ColoredBox(color: const Color(0xFFE8D5B0), child: list),
  );
}

Future<Uint8List> _pixels(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
  final data = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: tester.view.devicePixelRatio);
    final bytes = await image.toByteData();
    image.dispose();
    return bytes!;
  });
  return data!.buffer.asUint8List();
}

void main() {
  testWidgets('وقت التمرير الكروت صور ثابتة بنفس شكلها، وترجع تتحرك من نفس اللحظة', (tester) async {
    tester.view.devicePixelRatio = 2.75;
    tester.view.physicalSize = const Size(1100, 2200);
    addTearDown(tester.view.reset);
    FxClock.manual.value = null;

    final paints = <double>[];
    final controller = ScrollController();
    await tester.pumpWidget(_list(freeze: true, controller: controller, paints: paints));
    await tester.pump(const Duration(milliseconds: 100));

    // يبدأ السحب: تتجمد وتنصور
    final gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)));
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -23.3));
    await tester.pump();
    final frozenAt = paints.last;
    final count = paints.length;
    // خلال التمرير ما تنرسم ولا تتحرك
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, -11.7));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(paints.length, count, reason: 'الكروت انرسمت وهي متجمدة');
    final offset = controller.offset;
    final frozen = await _pixels(tester);

    // نفس المكان بدون تجميد، بنفس لحظة الحركة: لازم يطابق
    FxClock.manual.value = frozenAt;
    final live = <double>[];
    final c2 = ScrollController(initialScrollOffset: offset);
    await tester.pumpWidget(_list(freeze: false, controller: c2, paints: live));
    await tester.pump();
    final reference = await _pixels(tester);
    FxClock.manual.value = null;
    var sum = 0;
    for (var j = 0; j < frozen.length; j++) {
      sum += (frozen[j] - reference[j]).abs();
    }
    // الصورة تتحرك مع التمرير بين البكسلات، فالفرق بس نعومة حواف.
    expect(sum / frozen.length, lessThan(1.5), reason: 'متوسط الفرق ${sum / frozen.length}');
    await gesture.up();
    // ساعات الحركة تخلص مؤقتاتها (لو الرسم بطيء تمشي على مؤقت ٣٠ فريم).
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('السحب السريع يكمل التمرير وهو متجمد، ولما يوقف ترجع الكروت تتحرك', (tester) async {
    tester.view.devicePixelRatio = 2.75;
    tester.view.physicalSize = const Size(1100, 2200);
    addTearDown(tester.view.reset);
    final paints = <double>[];
    final controller = ScrollController();
    await tester.pumpWidget(_list(freeze: true, controller: controller, paints: paints));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.fling(find.byType(ListView), const Offset(0, -500), 2500);
    await tester.pump(const Duration(milliseconds: 50));
    final mid = controller.offset;
    // الحركات ترجع بعد التمرير وتظل شغالة، فننتظر لين يوقف التمرير بس.
    var last = -1.0;
    for (var i = 0; i < 100 && controller.offset != last; i++) {
      last = controller.offset;
      await tester.pump(const Duration(milliseconds: 50));
    }
    // التمرير كمل بعد ما ترك الأصبع (ما علق)
    expect(controller.offset, greaterThan(mid));
    // ولما وقف رجعت الكروت تنرسم وتتحرك
    final count = paints.length;
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(paints.length, greaterThan(count));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('ساعة الحركة الموقوفة تكمل من نفس اللحظة بدون قفزة', (tester) async {
    FxClock.manual.value = null;
    final enabled = ValueNotifier(true);
    final paints = <double>[];
    await tester.pumpWidget(
      ValueListenableBuilder(
        valueListenable: enabled,
        builder: (context, on, _) => TickerMode(
          enabled: on,
          child: Directionality(textDirection: TextDirection.ltr, child: _Card(0, paints)),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 16));
    final before = paints.last;
    enabled.value = false;
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800)));
    await tester.pump(const Duration(milliseconds: 16));
    enabled.value = true;
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 16));
    // ما قفزت ٠٫٨ ثانية (اللي كانت موقوفة فيها)
    expect(paints.last - before, lessThan(.4));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
