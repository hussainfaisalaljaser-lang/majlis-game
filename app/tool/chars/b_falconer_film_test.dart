// Filmstrip of the REAL animated falconer (AnimAvatar rig + layers + the in-app backdrop + the
// pop layer that goes over the frame) at several moments and at 256 / 128 / 64 px.
//
//   cd app && FILM_OUT=/tmp/film flutter test tool/chars/b_falconer_film_test.dart
//   FILM_T=0.3,0.57,2.55   (override the moments)   FILM_DPR=2
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/shop.dart';
import 'package:majlis/widgets/anim_avatar.dart';
import 'package:majlis/widgets/fx.dart';

const _id = 'falconer';

// rest, wing lifting, wing at its peak, wing coming down, feathers falling, bird blink, head turned, man blink
const _defaultTimes = [2.0, 0.3, 0.57, 0.95, 1.8, 2.55, 3.7, 4.35];

Widget _cell(double size, double t) {
  final art = avatarArt(_id)!;
  final time = ValueNotifier<double>(t);
  // same layering as PlayerAvatar: the clipped avatar, then the pop layer over the frame
  return SizedBox(
    width: size,
    height: size,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        ClipOval(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: CustomPaint(painter: AvatarBgPainter(art, time))),
                AnimAvatar(id: _id, size: size, time: time),
              ],
            ),
          ),
        ),
        Positioned.fill(child: IgnorePointer(child: AnimAvatar(id: _id, size: size, time: time, pop: true))),
      ],
    ),
  );
}

void main() {
  testWidgets('falconer filmstrip', (tester) async {
    final env = Platform.environment;
    final out = env['FILM_OUT'] ?? 'build/film';
    final dpr = double.tryParse(env['FILM_DPR'] ?? '') ?? 1;
    final times = (env['FILM_T'] ?? '').isEmpty ? _defaultTimes : env['FILM_T']!.split(',').map(double.parse).toList();
    const gap = 26.0;
    final w = times.length * (256 + gap) + gap;
    const h = 256 + 128 + 64 + 5 * gap;
    final key = GlobalKey();
    tester.view.physicalSize = Size(w * dpr, h * dpr);
    tester.view.devicePixelRatio = dpr;
    addTearDown(tester.view.reset);
    Widget row(double size, double top) => Positioned(
      left: gap,
      top: top,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final t in times) Padding(padding: const EdgeInsets.only(right: gap), child: _cell(size, t))],
      ),
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: w,
            height: h,
            color: const Color(0xFF241C18),
            child: Stack(children: [row(256, gap), row(128, 256 + 2 * gap), row(64, 256 + 128 + 3 * gap)]),
          ),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: dpr);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      Directory(out).createSync(recursive: true);
      File('$out/film_$_id.png').writeAsBytesSync(bytes.buffer.asUint8List());
    });
    print('film $_id: ${times.join(' ')}');
  });
}
