// تصوير ملصقات S1 (٤٢): شبكة بحجم ١٢٨ عند كل لحظة من الحركة، والتجميع (شرائط الحركة) يتم بـ s1_filmstrip.py.
// التشغيل:  SHOT_DIR=<dir> flutter test tool/shots/s1_stickers_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/shop.dart';
import 'package:majlis/widgets/bubble.dart';
import 'package:majlis/widgets/fx.dart';

import 'shot_helper.dart';

const _packs = ['stk_basic', 'stk_shock', 'stk_laugh', 'stk_coffee', 'stk_angry', 'stk_nervous', 'stk_detective'];

List<Sticker> _mine() => [for (final p in _packs) ...stickers.where((s) => s.pack == p)];

class _Grid extends StatelessWidget {
  const _Grid({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final list = _mine();
    return Scaffold(
      backgroundColor: const Color(0xFFE2C48E),
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          children: [
            for (final s in list)
              SizedBox(
                width: size,
                height: size,
                child: Center(child: StickerView(sticker: s, size: size, pop: false)),
              ),
          ],
        ),
      ),
    );
  }
}

void main() {
  setUpAll(loadFonts);
  tearDown(() => FxClock.manual.value = null);

  // ٨ لحظات تغطي ثانية تقريباً
  testWidgets('sticker frames', (tester) async {
    for (var i = 0; i < 8; i++) {
      FxClock.manual.value = 0.05 + i * 0.19;
      await shot(tester, 'frame_$i', const _Grid(size: 128), size: const Size(128 * 6, 128 * 7));
    }
  });

  // تحقق أن الوضع الخفيف (بدون حركة) يعرض الرسمة الثابتة بدون أخطاء
  testWidgets('sticker lite', (tester) async {
    FxClock.lite.value = true;
    addTearDown(() => FxClock.lite.value = false);
    await shot(tester, 'lite_grid', const _Grid(size: 96), size: const Size(96 * 7, 96 * 6));
  });
}
