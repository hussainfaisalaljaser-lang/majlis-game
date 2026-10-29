// Renders the S2 stickers (figure + caption banner, no die-cut yet) to PNG.
//   S2_IDS=inn_me,inn_cry   (default: every id of pack7)
//   S2_OUT=<dir>            (default: build/s2)
//   S2_PX=1024
//
//   cd app && flutter test tool/chars/s2_sticker_test.dart
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/catalog.dart' show stickers;

import '../shots/shot_helper.dart' show loadFonts;
import 'characters/pack7.dart';
import 'parts/s2_sticker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render s2 stickers', () async {
    await loadFonts();
    final env = Platform.environment;
    final out = env['S2_OUT'] ?? 'build/s2';
    final px = int.tryParse(env['S2_PX'] ?? '') ?? 1024;
    final want = (env['S2_IDS'] ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    final info = {for (final s in stickers) s.id: s};
    for (final spec in pack7) {
      if (want.isNotEmpty && !want.contains(spec.id)) continue;
      final st = info[spec.id]!;
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec, ui.Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()));
      paintSticker(canvas, spec, caption: st.caption, pack: st.pack, px: px.toDouble());
      final img = await rec.endRecording().toImage(px, px);
      final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!;
      File('$out/${spec.id}.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes.buffer.asUint8List());
      print('rendered ${spec.id}');
    }
  });
}
