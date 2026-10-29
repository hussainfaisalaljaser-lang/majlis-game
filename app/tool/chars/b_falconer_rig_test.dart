// Renders the layers of the animated falconer (assets/avatars/anim/falconer/*) from the new art.
// Layer names and canvas (240 units = -20..220, 1200 px here, exported at 600) are the ones
// lib/widgets/anim_avatar.dart expects: man, man_blink, tail, glove, bird, wing, head, head_blink, pop_wing.
//
//   cd app && CHAR_OUT=/tmp/charout flutter test tool/chars/b_falconer_rig_test.dart
//   python -I tool/chars/export_webp.py --src /tmp/charout --layers --ids falconer
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'characters/pack2.dart';
import 'kit.dart';
import 'parts/b_falcon.dart';

Future<void> _layer(String path, int px, void Function(Canvas c) draw) async {
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec, ui.Rect.fromLTWH(0, 0, px.toDouble(), px.toDouble()));
  draw(canvas);
  final img = await rec.endRecording().toImage(px, px);
  final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!;
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render falconer rig layers', () async {
    final out = Platform.environment['CHAR_OUT'] ?? 'build/chars';
    const px = 1200;
    final dir = '$out/layers/falconer';
    void scene(Canvas c, void Function(Pen pen) f) {
      c.save();
      c.scale(px / 240);
      c.translate(20, 20);
      f(Pen(c));
      c.restore();
    }

    await _layer('$dir/man.png', px, (c) {
      paintChar(c, falconerManSpec, px: px.toDouble(), layer: CharLayer.body);
      paintChar(c, falconerManSpec, px: px.toDouble(), layer: CharLayer.head);
    });
    await _layer('$dir/man_blink.png', px, (c) => paintChar(c, falconerManSpec, px: px.toDouble(), layer: CharLayer.blink));
    await _layer('$dir/tail.png', px, (c) => scene(c, bFalconerTail));
    await _layer('$dir/glove.png', px, (c) => scene(c, bFalconerGlove));
    await _layer('$dir/bird.png', px, (c) => scene(c, (p) => bFalconerBird(p, BFalconPart.body)));
    await _layer('$dir/wing.png', px, (c) => scene(c, (p) => bFalconerBird(p, BFalconPart.wing)));
    await _layer('$dir/head.png', px, (c) => scene(c, (p) => bFalconerBird(p, BFalconPart.head)));
    await _layer('$dir/head_blink.png', px, (c) => scene(c, (p) => bFalconerBird(p, BFalconPart.headBlink)));
    await _layer('$dir/pop_wing.png', px, (c) => scene(c, bFalconerOpenWing));
    final hp = bFalconerHeadPivot, wp = bFalconerWingPivot;
    print('head pivot ${hp.dx.toStringAsFixed(1)},${hp.dy.toStringAsFixed(1)}  wing pivot ${wp.dx.toStringAsFixed(1)},${wp.dy.toStringAsFixed(1)}');
  });
}
