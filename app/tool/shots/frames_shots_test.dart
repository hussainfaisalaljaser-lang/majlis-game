// تصوير معرض الإطارات كلها (٣٠ إطار) بأحجام وأوقات حركة مختلفة، عشان نقارنها بالفيديو.
// التشغيل:  flutter test tool/shots/frames_shots_test.dart   (والصور تنحفظ في مجلد SHOT_DIR)
// متغيرات اختيارية: ONLY=fire,ice (إطارات معينة بالمعرض الكبير)، TIMES=1.0,1.3 (أوقات الحركة)، AV=cool (الشخصية).
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/shop.dart';
import 'package:majlis/widgets/common.dart';
import 'package:majlis/widgets/fx.dart';

import 'shot_helper.dart';

final _avatar = Platform.environment['AV'] ?? 'sheikh';
final _only = Platform.environment['ONLY']?.split(',').toSet();
final _times = (Platform.environment['TIMES'] ?? '0.45,0.9,2.3').split(',').map(double.parse).toList();
final _bg = switch (Platform.environment['BG']) {
  'parch' => const Color(0xFFD9BC86),
  'maroon' => const Color(0xFF4A1620),
  'night' => const Color(0xFF16203A),
  _ => const Color(0xFF4A3426),
};
final _size = double.tryParse(Platform.environment['SIZE'] ?? '');

/// كل الإطارات بترتيب المتجر (أو اللي في ONLY).
List<ShopItem> get _items {
  final only = _only;
  return [
    for (final item in catalog)
      if (item.frame != null && (only == null || only.contains(item.frame!.sig))) item,
  ];
}

/// شبكة إطارات على خلفية خشب داكنة مع اسم كل واحد.
Widget _grid(List<ShopItem> items, double size, {int cols = 5, Color? bg}) {
  return Scaffold(
    backgroundColor: bg ?? _bg,
    body: Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 6,
          children: [
            for (final item in items)
              SizedBox(
                width: 960 / cols,
                height: size * 1.5 + 22,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PlayerAvatar(avatar: _avatar, style: item.frame, size: size, momentKey: item.frame!.sig),
                    const SizedBox(height: 2),
                    Text(
                      item.frame!.sig,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadFonts);

  /// صفحة معرض بوقت حركة ثابت [t].
  Future<void> sheet(WidgetTester tester, String name, List<ShopItem> items, double t, double size, int cols) async {
    FxClock.manual.value = t;
    addTearDown(() => FxClock.manual.value = null);
    await shot(tester, name, _grid(items, size, cols: cols));
  }

  // المعرض الكبير: كل الإطارات بحجم المعاينة (١٢٠) على صفحتين، لكل وقت.
  for (final t in _times) {
    final tag = t.toString().replaceAll('.', '_');
    testWidgets('big t=$t', (tester) async {
      final items = _items;
      final per = _only == null ? 15 : items.length;
      for (var i = 0; i * per < items.length; i++) {
        final part = items.sublist(i * per, (i + 1) * per > items.length ? items.length : (i + 1) * per);
        final big = _size ?? (_only == null ? 100.0 : (items.length <= 4 ? 150.0 : 110.0));
        await sheet(tester, 'big${i}_t$tag', part, t, big, _only == null ? 5 : math.min(4, items.length));
      }
    });
  }

  // حجم الطاولة (٦٢) والقوائم (٤٠) — كل الإطارات بصفحة وحدة.
  testWidgets('small', (tester) async {
    final items = _items;
    await sheet(tester, 'small64', items, _times.first, 64, 10);
    await sheet(tester, 'small40', items, _times.first, 40, 10);
  });
}
