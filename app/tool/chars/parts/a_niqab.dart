// Worker A: a niqab = hijab hood + face veil in one headwear (eyes stay visible).
import 'dart:ui';

import '../core/head.dart';
import '../core/palette.dart';
import '../core/pen.dart';
import 'headwear.dart';

/// Black hood (the kit's [Hijab] shape) with the [FaceVeil] drawn over the lower face.
class Niqab extends Headwear {
  const Niqab({
    this.cloth = const Tones(Color(0xFF28232F), Color(0xFF15111B), Color(0xFF46404F)),
    this.hem = -27.0,
    this.eyeBottom = 8.0,
    this.width = 1.1,
  });

  final Tones cloth;
  final double hem, eyeBottom, width;

  Hijab get _hood => Hijab(cloth: cloth, hem: hem, width: width, flap: false);
  FaceVeil get _veil => FaceVeil(cloth: cloth, eyeBottom: eyeBottom);

  @override
  void back(Pen pen, Head h, Skin skin) => _hood.back(pen, h, skin);

  @override
  void front(Pen pen, Head h, Skin skin) {
    _hood.front(pen, h, skin);
    _veil.front(pen, h, skin);
  }
}
