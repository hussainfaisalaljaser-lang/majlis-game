import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/clan.dart';

void main() {
  test('رموز الشعار في التطبيق نفس اللي يقبلها السيرفر', () {
    final ts = File('../functions/src/clan_emblems.ts').readAsStringSync();
    final body = RegExp(r'CLAN_SYMBOLS = \[(.*?)\];', dotAll: true).firstMatch(ts)![1]!;
    final server = [for (final m in RegExp(r"'([a-z_]+)'").allMatches(body)) m[1]!];
    expect(clanSymbols, server);
    // كل رمز له أيقونة في اللعبة
    for (final s in clanSymbols) {
      expect(File('assets/icons/gfx_$s.png').existsSync(), isTrue, reason: 'ما فيه أيقونة للرمز $s');
    }
  });

  test('اسم الرمز من الشعار', () {
    expect(clanSymbolOf('sym:crown'), 'crown');
    expect(clanSymbolOf('falcon'), isNull);
  });
}
