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
import 'spec.dart';

Future<void> _save(String path, CharSpec spec, int px, CharLayer layer) async {
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec, ui.Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()));
  paintChar(canvas, spec, px: px.toDouble(), layer: layer);
  final img = await rec.endRecording().toImage(px, px);
  final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!;
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes.buffer.asUint8List());
}

Future<void> _saveLayer(String path, CharSpec spec, String name, int px) async {
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec, ui.Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()));
  paintLayer(canvas, spec, name, px: px.toDouble());
  final img = await rec.endRecording().toImage(px, px);
  final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!;
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes.buffer.asUint8List());
}

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
        for (final name in layerNames(spec)) {
          await _saveLayer('$out/layers/$id/$name.png', spec, name, 1200);
        }
      }
      print('rendered $id');
    }
  });
}
