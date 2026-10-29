// نافذة مستوى الصوت (الموسيقى والمعلق والمؤثرات).
// التشغيل:  flutter test tool/shots/volume_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/services/music.dart';
import 'package:majlis/services/sfx.dart';
import 'package:majlis/services/sounds.dart';
import 'package:majlis/widgets/design.dart';
import 'package:majlis/widgets/volume_panel.dart';

import 'shot_helper.dart';

class _Open extends StatefulWidget {
  const _Open();

  @override
  State<_Open> createState() => _OpenState();
}

class _OpenState extends State<_Open> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => showVolumeDialog(context));
  }

  @override
  Widget build(BuildContext context) => const WoodWall(child: SizedBox.expand());
}

void main() {
  setUpAll(loadFonts);

  for (final (name, size, music, narrator, fx) in [
    ('volume_dialog', const Size(960, 540), .5, 1.0, .35),
    ('volume_dialog_small', const Size(640, 360), .8, .0, 1.0),
  ]) {
    testWidgets(name, (tester) async {
      Music.volume.value = music;
      Sfx.volume.value = narrator;
      Sounds.volume.value = fx;
      await shot(tester, name, const _Open(), size: size);
    });
  }
}
