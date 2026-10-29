// Prints the rig anchor points of worker C's characters (see pack3.dart `c3Marks`).
//   cd app && flutter test tool/chars/c_probe_test.dart
// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';

import 'characters/pack3.dart';
import 'registry.dart';

void main() {
  test('probe rig anchors', () {
    for (final e in c3Marks.entries) {
      final h = allChars[e.key]!.head.build();
      final parts = e.value.entries.map((m) {
        final o = m.value(h);
        return '${m.key}=(${o.dx.toStringAsFixed(1)}, ${o.dy.toStringAsFixed(1)})';
      });
      print('${e.key}: scale=${h.scale} ${parts.join('  ')}');
    }
  });
}
