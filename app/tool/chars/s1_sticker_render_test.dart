// يرسم ملصقات S1 (باقات: الأساسي، صدمة، ضحك، القهوة، الزعل، التوتر، المحقق) إلى PNG شفاف ١٠٢٤.
//   STK_IDS=b_laugh,b_think   (الافتراضي: كل ملصقات pack6)
//   STK_OUT=<dir>             (الافتراضي: build/stk)
//   STK_PX=1024
// بعدها:  python -I tool/chars/s1_sticker_export.py --src <dir>   (قص أبيض + webp ٢٥٦)
//
//   cd app && flutter test tool/chars/s1_sticker_render_test.dart
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/shop.dart';

import 'characters/pack6.dart';
import 'parts/s1_sticker.dart';

Future<void> _loadFonts() async {
  const fonts = <String, List<String>>{
    'Baloo': ['BalooBhaijaan2-Bold', 'BalooBhaijaan2-ExtraBold'],
    'Tajawal': ['Tajawal-Bold', 'Tajawal-ExtraBold'],
  };
  for (final e in fonts.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      final file = File('assets/fonts/$f.ttf');
      if (file.existsSync()) loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render stickers', () async {
    await _loadFonts();
    final env = Platform.environment;
    final out = env['STK_OUT'] ?? 'build/stk';
    final px = int.tryParse(env['STK_PX'] ?? '') ?? 1024;
    final ids = (env['STK_IDS'] ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    for (final spec in pack6) {
      if (ids.isNotEmpty && !ids.contains(spec.id)) continue;
      final st = stickerById(spec.id);
      if (st == null) {
        print('not a sticker id: ${spec.id}');
        continue;
      }
      final rec = ui.PictureRecorder();
      final canvas = ui.Canvas(rec, ui.Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()));
      paintSticker(canvas, spec, st.caption, s1CaptionColor[st.pack] ?? const ui.Color(0xFFFFFFFF), px: px.toDouble());
      final img = await rec.endRecording().toImage(px, px);
      final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!;
      File('$out/${spec.id}.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes.buffer.asUint8List());
      print('rendered ${spec.id}');
    }
  });
}
