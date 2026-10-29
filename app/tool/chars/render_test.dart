// Renders characters offscreen to PNG.
//   CHAR_IDS=youth,rose   (default: all registered)
//   CHAR_OUT=<dir>        (default: build/chars)
//   CHAR_PX=1024          (output size of the composite)
//   CHAR_LAYERS=1         also render rig layers (body/head/blink/mouth/props) at 2x240 px
//
//   cd app && flutter test tool/chars/render_test.dart
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'registry.dart';
import 'scene.dart';

Future<void> _save(String path, CharSpec_ spec, int px, CharLayer layer) async {
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec, ui.Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()));
  paintChar(canvas, spec, px: px.toDouble(), layer: layer);
  final img = await rec.endRecording().toImage(px, px);
  final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!;
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes.buffer.asUint8List());
}

typedef CharSpec_ = dynamic;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render characters', () async {
    final env = Platform.environment;
    final out = env['CHAR_OUT'] ?? 'build/chars';
    final px = int.tryParse(env['CHAR_PX'] ?? '') ?? 1024;
    final ids = (env['CHAR_IDS'] ?? '').split(',').where((e) => e.trim().isNotEmpty).map((e) => e.trim()).toList();
    final layers = env['CHAR_LAYERS'] == '1';
    final chosen = ids.isEmpty ? allChars.keys.toList() : ids;
    for (final id in chosen) {
      final spec = allChars[id];
      if (spec == null) {
        print('unknown id: $id');
        continue;
      }
      await _save('$out/$id.png', spec, px, CharLayer.composite);
      if (layers) {
        for (final l in [CharLayer.body, CharLayer.head, CharLayer.blink, CharLayer.mouth, CharLayer.props]) {
          await _save('$out/layers/$id/${l.name}.png', spec, 1200, l);
        }
      }
      print('rendered $id');
    }
  });
}
