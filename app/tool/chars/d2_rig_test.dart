// Filmstrip harness for the animated animal avatars (s1a, s1b, s1c, champ1-3): renders the real
// AnimAvatar widget (rig + layers + the in-app backdrop) at several moments (rest, each rig event,
// regular samples) and at 256 / 128 / 64 px, one PNG per id.
//
//   cd app && D2_OUT=/tmp/film flutter test tool/chars/d2_rig_test.dart
//   D2_IDS=s1a,champ1   D2_DPR=2 (pixel ratio of the capture, default 1)
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/shop.dart';
import 'package:majlis/widgets/anim_avatar.dart';
import 'package:majlis/widgets/fx.dart';

/// Same seed formula as AvatarRig.
int _seed(String id) => id.codeUnits.fold(7, (a, c) => (a * 31 + c) & 0xffff);

/// A time at which `_phase(period, dur, offset)` is at fraction [at] of its run (cycle [k]).
double _ev(String id, double period, double dur, double offset, {double at = .5, int k = 1}) {
  final base = dur * at - offset - _seed(id) * .013;
  return ((base % period) + period) % period + k * period;
}

/// (label, time) pairs: rest + every id-specific rig event + regular samples.
List<(String, double)> _moments(String id) {
  final rest = <(String, double)>[('rest', .25)];
  final events = switch (id) {
    's1a' => [('earL', _ev(id, 3.1, .22, 0)), ('earR', _ev(id, 3.7, .22, 1.4)), ('glint', _ev(id, 3.6, .55, 0))],
    's1b' => [('earL', _ev(id, 4.2, .25, 0)), ('earR', _ev(id, 5.1, .25, 2)), ('glint', _ev(id, 3.2, .5, .8))],
    's1c' => [('nod', _ev(id, 5.8, 1.1, 0)), ('glint', _ev(id, 3, .5, 1))],
    _ => [('proud', _ev(id, 6, 1.2, 0)), ('laugh', _ev(id, 9, 1.3, 3, at: .5)), ('laugh2', _ev(id, 9, 1.3, 3, at: .33))],
  };
  final regular = [('t1.7', 1.7), ('t2.9', 2.9), ('t4.6', 4.6), ('t6.2', 6.2)];
  return [...rest, ...events, ...regular].take(8).toList();
}

Widget _cell(String id, double size, double t) {
  final art = avatarArt(id)!;
  final time = ValueNotifier<double>(t);
  return SizedBox(
    width: size,
    height: size,
    child: ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: CustomPaint(painter: AvatarBgPainter(art, time))),
            AnimAvatar(id: id, size: size, time: time),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('d2 rig filmstrips', (tester) async {
    final env = Platform.environment;
    final out = env['D2_OUT'] ?? 'build/d2';
    final dpr = double.tryParse(env['D2_DPR'] ?? '') ?? 1;
    final ids = (env['D2_IDS'] ?? 's1a,s1b,s1c,champ1,champ2,champ3').split(',').where((e) => e.trim().isNotEmpty).map((e) => e.trim()).toList();
    for (final id in ids) {
      final ms = _moments(id);
      const gap = 8.0;
      final w = ms.length * (256 + gap) + gap;
      const h = 256 + 128 + 64 + 5 * gap + 22;
      final key = GlobalKey();
      tester.view.physicalSize = Size(w * dpr, h * dpr);
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.reset);
      Widget row(double size, double top) => Positioned(
        left: gap,
        top: top,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final m in ms) Padding(padding: const EdgeInsets.only(right: gap), child: _cell(id, size, m.$2))],
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
              child: Stack(
                children: [
                  row(256, gap),
                  row(128, 256 + 2 * gap),
                  row(64, 256 + 128 + 3 * gap),
                ],
              ),
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
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        Directory(out).createSync(recursive: true);
        File('$out/film_$id.png').writeAsBytesSync(bytes.buffer.asUint8List());
      });
      print('film $id: ${ms.map((m) => '${m.$1}@${m.$2.toStringAsFixed(2)}').join(' ')}');
    }
  });
}
