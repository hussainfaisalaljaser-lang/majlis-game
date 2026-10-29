// لقطات ملصقات S2 (البريء، الاحتفال، الخاين، الفخامة، الحماس، الموسم الأول، الأساطير):
//   1) شبكة الملصقات الثابتة بحجم ١٢٨ و٢٥٦
//   2) إطارات الحركة (الشبكة كاملة بوقت ثابت لكل إطار) لتركيب شرائط الحركة بعدها
// تشغيل:  SHOT_DIR=<مجلد> flutter test tool/shots/s2_stickers_shots_test.dart
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/catalog.dart' show stickers;
import 'package:majlis/models/shop.dart' show Sticker;
import 'package:majlis/widgets/fx.dart' show FxClock;
import 'package:majlis/widgets/sticker_motion.dart';

final _outDir = Platform.environment['SHOT_DIR'] ?? 'build/shots';

const _packs = ['stk_innocent', 'stk_party', 'stk_traitor', 'stk_vip', 'stk_hype', 'stk_s1', 'stk_legend'];

List<Sticker> get _mine => [for (final p in _packs) ...stickers.where((s) => s.pack == p)];

Widget _grid(double cell, Widget Function(Sticker s) build) {
  final all = _mine;
  return ColoredBox(
    color: const Color(0xFF2A1A10),
    child: Column(
      children: [
        for (var r = 0; r < all.length / 6; r++)
          Row(
            children: [
              for (final s in all.skip(r * 6).take(6))
                SizedBox(
                  width: cell,
                  height: cell,
                  child: Center(child: build(s)),
                ),
            ],
          ),
      ],
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name, double ratio) async {
  await tester.runAsync(() async {
    final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: ratio);
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!;
    Directory(_outDir).createSync(recursive: true);
    File('$_outDir/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final cell in const [128.0, 256.0]) {
    testWidgets('s2 contact sheet ${cell.toInt()}', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = Size(cell * 6, cell * 7);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: _grid(cell, (s) => Image.asset(s.asset, width: cell, height: cell, filterQuality: FilterQuality.medium)),
          ),
        ),
      );
      await _settle(tester);
      await _capture(tester, key, 's2_contact_${cell.toInt()}', 1);
    });
  }

  testWidgets('s2 motion frames', (tester) async {
    const cell = 160.0;
    final key = GlobalKey();
    tester.view.physicalSize = const Size(cell * 6, cell * 7);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    FxClock.manual.value = 0;
    addTearDown(() => FxClock.manual.value = null);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: _grid(cell, (s) => StickerMotion.has(s) ? StickerMotion.build(s, cell * .8) : Image.asset(s.asset, width: cell * .8)),
        ),
      ),
    );
    await _settle(tester);
    final missing = _mine.where((s) => !StickerMotion.has(s)).map((s) => s.id).toList();
    expect(missing, isEmpty, reason: 'every S2 sticker must have a motion');
    const steps = 12;
    for (var i = 0; i < steps; i++) {
      FxClock.manual.value = 1.0 + i * 0.3;
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 20));
      await _capture(tester, key, 's2_motion_${i.toString().padLeft(2, '0')}', 1);
    }
  });
}
