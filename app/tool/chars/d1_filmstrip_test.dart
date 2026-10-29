// Filmstrips of the animated avatar widgets (worker D1): renders the REAL rig (AnimAvatar over the in-app
// avatar background, clipped to a circle) at several time steps and sizes, to check for gaps, detached
// parts and misplaced wings / crests.
//   D1_IDS=wolf,lv20   (default: the six D1 ids)
//   D1_OUT=<dir>       (default: build/d1_film)
// Writes <id>_<size>.png (rows of frames) for sizes 64 / 128 / 256.
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/shop.dart';
import 'package:majlis/widgets/anim_avatar.dart';
import 'package:majlis/widgets/fx.dart';

/// A moment (seconds) in the middle of a rig event that starts every [period] s and lasts [dur] s.
double _mid(int seed, double period, double dur, double offset, [double at = .5]) {
  var t = dur * at - offset - seed * .013;
  while (t < 0) {
    t += period;
  }
  return t;
}

List<double> _times(String id) {
  final seed = id.codeUnits.fold(7, (a, c) => (a * 31 + c) & 0xffff);
  final base = <double>[0.6, 1.4];
  switch (id) {
    case 'wolf':
      return [...base, _mid(seed, 8.5, 2.3, 3, .12), _mid(seed, 8.5, 2.3, 3, .5), _mid(seed, 8.5, 2.3, 3, .88), _mid(seed, 2.7, .2, 0), _mid(seed, 3.3, .2, 1.2), 5.1];
    case 'falcon_bird':
      return [...base, _mid(seed, 7.5, .85, 2, .5), _mid(seed, 7.5, .85, 2, .7), _mid(seed, 2.8, .17, 0), 3.9, 6.2, 9.4];
    case 'lv20':
      return [...base, _mid(seed, 6, 2.6, 0, .4), _mid(seed, 6, 1.8, 0, .55), _mid(seed, 6, 1.8, 0, .7), _mid(seed, 9, 1.6, 4, .5), 7.4, 12.1];
    case 'lv30':
      return [...base, _mid(seed, 5.6, 1.1, 0), _mid(seed, 2.4, .5, 0), 3.3, 4.4, 6.0, 8.8];
    case 'lv40':
      return [...base, _mid(seed, 7.5, 1.2, 2, .3), _mid(seed, 7.5, 1.2, 2, .6), 3.3, 4.4, 6.0, 8.8];
    case 'lv50':
      return [...base, _mid(seed, 6, 1.2, 1, .5), _mid(seed, 3, .5, 0), 0.3, 0.9, 2.2, 3.1];
  }
  return [...base, 2.3, 3.4, 4.5, 5.6, 6.7, 7.8];
}

Widget _tile(String id, double size, double t) {
  final art = avatarArt(id);
  final time = ValueNotifier<double>(t);
  return SizedBox(
    width: size,
    height: size,
    child: ClipOval(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (art != null) Positioned.fill(child: CustomPaint(painter: AvatarBgPainter(art, time))),
          AnimAvatar(id: id, size: size, time: time),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('filmstrip', (tester) async {
    final env = Platform.environment;
    final out = env['D1_OUT'] ?? 'build/d1_film';
    final ids = (env['D1_IDS'] ?? 'wolf,falcon_bird,lv20,lv30,lv40,lv50').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    Directory(out).createSync(recursive: true);
    for (final id in ids) {
      final times = _times(id);
      for (final size in const [64.0, 128.0, 256.0]) {
        final cols = size >= 256 ? 4 : (size >= 128 ? 8 : 8);
        final rows = (times.length / cols).ceil();
        final key = GlobalKey();
        tester.view.physicalSize = Size(cols * (size + 6) + 6, rows * (size + 6) + 6);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: ColoredBox(
                color: const Color(0xFF2B242B),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final t in times) _tile(id, size, t)],
                  ),
                ),
              ),
            ),
          ),
        );
        for (var i = 0; i < 4; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.runAsync(() async {
          final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: size >= 256 ? 1 : 2);
          final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
          File('$out/${id}_${size.toInt()}.png').writeAsBytesSync(bytes.buffer.asUint8List());
        });
      }
      print('film $id: ${_times(id).map((e) => e.toStringAsFixed(2)).join(' ')}');
    }
  });
}
