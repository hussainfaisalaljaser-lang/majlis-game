import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/widgets/game/atmosphere.dart';

void main() {
  test('التلقائي: نفس الطاولة نفس الجو لكل اللاعبين، وأغلبه ليل', () {
    expect(Atmosphere.byCode('ABCD'), Atmosphere.byCode('ABCD'));
    final counts = <AtmoKind, int>{};
    for (var i = 0; i < 2000; i++) {
      final code = String.fromCharCodes([65 + i % 26, 65 + i ~/ 26 % 26, 65 + i ~/ 676 % 26, 48 + i % 10]);
      counts.update(Atmosphere.byCode(code), (n) => n + 1, ifAbsent: () => 1);
    }
    // ٥٥٪ ليل، ٢٥٪ رمل، ٢٠٪ مطر (تقريباً)
    expect(counts[AtmoKind.night]!, inInclusiveRange(900, 1300));
    expect(counts[AtmoKind.sand]!, inInclusiveRange(350, 650));
    expect(counts[AtmoKind.rain]!, inInclusiveRange(250, 550));
  });

  test('اختيار اللاعب يغلب التلقائي، وبدون يطفيه', () {
    expect(Atmosphere.kindFor('ABCD', AtmoChoice.rain), AtmoKind.rain);
    expect(Atmosphere.kindFor('ABCD', AtmoChoice.sand), AtmoKind.sand);
    expect(Atmosphere.kindFor('ABCD', AtmoChoice.night), AtmoKind.night);
    expect(Atmosphere.kindFor('ABCD', AtmoChoice.off), isNull);
    expect(Atmosphere.kindFor('ABCD', AtmoChoice.auto), Atmosphere.byCode('ABCD'));
  });
}
