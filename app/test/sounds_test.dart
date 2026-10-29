import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/services/sounds.dart';

/// كل صوت مكتوب في كود المشاهد لازم يكون له ملف في assets/sfx (وإلا يسكت اللحظة بدون ما نعرف).
void main() {
  test('every sound named in the table moments has a file', () {
    final files = {
      for (final f in Directory('assets/sfx').listSync())
        if (f.path.endsWith('.wav')) f.uri.pathSegments.last.replaceAll('.wav', ''),
    };
    expect(files, isNotEmpty);
    expect(Sounds.all.toSet(), files, reason: 'Sounds.all لازم يطابق ملفات assets/sfx');
    final src = File('lib/widgets/game/scenes.dart').readAsStringSync();
    final names = <String>{
      for (final cue in RegExp(r'SceneCue\(([^()]*)\)').allMatches(src))
        for (final q in RegExp(r"'([a-z_0-9]+)'").allMatches(cue[1]!)) q[1]!,
      // صوت كل افكت موت
      for (final m in RegExp(r"DeathFx\.[\w.| ]+=> '([a-z_0-9]+)'").allMatches(src)) m[1]!,
      ...['sting_loyal', 'sting_traitor', 'sting_leader', 'flip'],
    };
    expect(names.length, greaterThan(15));
    expect(files.containsAll(names), isTrue, reason: 'missing files: ${names.difference(files)}');
    // ولا ملف صوت ضايع بدون استخدام
    expect(names.containsAll(files), isTrue, reason: 'unused files: ${files.difference(names)}');
  });
}
