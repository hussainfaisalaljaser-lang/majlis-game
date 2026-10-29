// يرسم كرتي القرار (أوفياء وخونة) بخلفية شفافة، لتركيب أيقونة اللعبة (tools/logo/make_logo.py).
// التشغيل:  SHOT_DIR=<مجلد> flutter test tool/shots/logo_cards_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/widgets/design_game.dart';

import 'shot_helper.dart';

final _outDir = Platform.environment['SHOT_DIR'] ?? 'build/shots';

void main() {
  setUpAll(loadFonts);

  for (final kind in [GameCardKind.loyal, GameCardKind.traitor]) {
    testWidgets('logo card ${kind.name}', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(400, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: Center(child: GameCardFace(kind: kind, width: 300)),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        Directory(_outDir).createSync(recursive: true);
        File('$_outDir/logo_card_${kind.name}.png').writeAsBytesSync(bytes.buffer.asUint8List());
      });
    });
  }
}
