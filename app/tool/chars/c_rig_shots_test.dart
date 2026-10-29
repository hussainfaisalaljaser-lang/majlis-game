// Filmstrips of the animated avatars (rig layers from assets/avatars/anim/<id>/ stacked by
// AvatarRig) at several time steps, on a coloured circle like the app draws behind them.
//   CHAR_IDS=knight,pilot   (default: worker C's eleven)
//   SHOT_DIR=<dir>          output folder (default build/rigshots)
//   TIMES=0,0.5,1,...       time steps in seconds (default 0..11.5 step 0.5)
//   SIZES=64,128,256        avatar sizes
// Writes <dir>/<id>_<size>.png (one row of frames per file, wrapped to several rows).
//   cd app && flutter test tool/chars/c_rig_shots_test.dart
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/widgets/anim_rigs.dart';

const _mine = ['lady_gold', 'pilot', 'seer', 'knight', 'ghost', 'assassin', 'tycoon', 'emir', 'sultana', 'queen', 'astronaut'];

const _bgs = <String, List<Color>>{
  'lady_gold': [Color(0xFFD9740F), Color(0xFF7A3304)],
  'pilot': [Color(0xFF3AA9C7), Color(0xFF14667E)],
  'seer': [Color(0xFF9B34AB), Color(0xFF4A1560)],
  'knight': [Color(0xFF3F6FD6), Color(0xFF1A3585)],
  'ghost': [Color(0xFF4A4A78), Color(0xFF14142A)],
  'assassin': [Color(0xFFC8392E), Color(0xFF5A100C)],
  'tycoon': [Color(0xFF3FA25B), Color(0xFF1C5D2E)],
  'emir': [Color(0xFFD9A93E), Color(0xFF86590F)],
  'sultana': [Color(0xFF20A58E), Color(0xFF0B5648)],
  'queen': [Color(0xFFD03A86), Color(0xFF7A1650)],
  'astronaut': [Color(0xFF3A3A5E), Color(0xFF14142A)],
};

Widget _cell(String id, double size, double t) {
  final c = _bgs[id] ?? const [Color(0xFF3A6EA5), Color(0xFF15304F)];
  return Padding(
    padding: const EdgeInsets.all(3),
    child: SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: RadialGradient(colors: c, radius: .9)),
              ),
            ),
            AvatarRig(id, size, t).build(),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('rig filmstrips', (tester) async {
    final env = Platform.environment;
    final out = env['SHOT_DIR'] ?? 'build/rigshots';
    final ids = (env['CHAR_IDS'] ?? '').split(',').where((e) => e.trim().isNotEmpty).toList();
    final sizes = (env['SIZES'] ?? '64,128,256').split(',').map((e) => double.parse(e.trim())).toList();
    final times = (env['TIMES'] ?? '').split(',').where((e) => e.trim().isNotEmpty).map((e) => double.parse(e.trim())).toList();
    final ts = times.isEmpty ? [for (var i = 0; i < 24; i++) i * 0.5] : times;
    Directory(out).createSync(recursive: true);
    for (final id in ids.isEmpty ? _mine : ids) {
      for (final size in sizes) {
        final cols = size >= 256 ? 6 : (size >= 128 ? 8 : 12);
        final key = GlobalKey();
        tester.view.physicalSize = Size(cols * (size + 6) * 1.0, ((ts.length + cols - 1) ~/ cols) * (size + 6) * 1.0);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: const Color(0xFF241C26),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Wrap(children: [for (final t in ts) _cell(id, size, t)]),
                ),
              ),
            ),
          ),
        );
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.runAsync(() async {
          final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
          File('$out/${id}_${size.toInt()}.png').writeAsBytesSync(bytes.buffer.asUint8List());
        });
        print('shot $id ${size.toInt()}');
      }
    }
  });
}
