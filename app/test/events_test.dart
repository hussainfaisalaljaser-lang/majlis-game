import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/events.dart';

void main() {
  // نفس اختبار functions/test/economy.test.ts → نهاية الأسبوع. ٢٠٢٦/١٠/٢٩ خميس.
  DateTime at(String iso) => DateTime.parse(iso);

  test('الذهب مضاعف من الخميس ٦ المغرب لين نهاية السبت بتوقيت الخليج', () {
    expect(Weekend.at(at('2026-10-29T14:59:00Z')).on, isFalse);
    expect(Weekend.at(at('2026-10-29T15:00:00Z')).on, isTrue);
    expect(Weekend.at(at('2026-10-30T12:00:00Z')).boost, 2);
    expect(Weekend.at(at('2026-10-31T20:59:00Z')).on, isTrue);
    expect(Weekend.at(at('2026-10-31T21:00:00Z')).on, isFalse);
    expect(Weekend.at(at('2026-11-02T12:00:00Z')).boost, 1);
  });

  test('وقت البداية والنهاية', () {
    final during = Weekend.at(at('2026-10-30T12:00:00Z'));
    expect(during.starts, DateTime.utc(2026, 10, 29, 15));
    expect(during.ends, DateTime.utc(2026, 10, 31, 21));
    // بعد ما يخلص: الجاي بعد أسبوع.
    final after = Weekend.at(at('2026-11-01T08:00:00Z'));
    expect(after.starts, DateTime.utc(2026, 11, 5, 15));
    expect(after.ends, DateTime.utc(2026, 11, 7, 21));
  });
}
