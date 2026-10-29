// Character pack 5 (worker D2): the animated animal busts — s1a caracal, s1b gazelle, s1c horse,
// champ1/2/3 Arabian oryx. All are cut-outs (the app draws the coloured disc behind them) with
// hand-built rig layers: body / ear_l / ear_r / head / blink (+ mane, mouth, medal) on the 240-unit canvas.
import '../kit.dart';
import '../parts/d2_animal.dart';
import '../parts/d2_caracal.dart';
import '../parts/d2_gazelle.dart';
import '../parts/d2_horse.dart';
import '../parts/d2_oryx.dart';

final List<CharSpec> pack5 = [
  CharSpec(
    id: 's1a',
    cutout: true,
    custom: (pen, h) {
      d2Circle(pen, () => caracalBody(pen));
      caracalEar(pen, -1);
      caracalEar(pen, 1);
      caracalHead(pen);
    },
    extraLayers: {
      'body': (pen, h) => caracalBody(pen),
      'ear_l': (pen, h) => caracalEar(pen, -1),
      'ear_r': (pen, h) => caracalEar(pen, 1),
      'head': (pen, h) => caracalHead(pen),
      'blink': (pen, h) => caracalBlink(pen),
    },
  ),
  CharSpec(
    id: 's1b',
    cutout: true,
    custom: (pen, h) {
      d2Circle(pen, () => gazelleBody(pen));
      gazelleEar(pen, -1);
      gazelleEar(pen, 1);
      gazelleHead(pen);
    },
    extraLayers: {
      'body': (pen, h) => gazelleBody(pen),
      'ear_l': (pen, h) => gazelleEar(pen, -1),
      'ear_r': (pen, h) => gazelleEar(pen, 1),
      'head': (pen, h) => gazelleHead(pen),
      'blink': (pen, h) => gazelleBlink(pen),
    },
  ),
  CharSpec(
    id: 's1c',
    cutout: true,
    custom: (pen, h) {
      d2Circle(pen, () => horseBody(pen));
      horseMane(pen);
      horseHead(pen);
    },
    extraLayers: {
      'body': (pen, h) => horseBody(pen),
      'mane': (pen, h) => horseMane(pen),
      'head': (pen, h) => horseHead(pen),
      'blink': (pen, h) => horseBlink(pen),
    },
  ),
  for (final v in [oryxGold, oryxSilver, oryxBronze]) _oryx(v),
];

/// The three weekly champions share one design; only the metal (and the medal number) changes.
CharSpec _oryx(OryxMetal v) => CharSpec(
  id: 'champ${v.n}',
  cutout: true,
  custom: (pen, h) {
    d2Circle(pen, () => oryxBody(pen, v));
    oryxEar(pen, -1);
    oryxEar(pen, 1);
    oryxHead(pen, v);
    oryxMedal(pen, v);
  },
  extraLayers: {
    'body': (pen, h) => oryxBody(pen, v),
    'ear_l': (pen, h) => oryxEar(pen, -1),
    'ear_r': (pen, h) => oryxEar(pen, 1),
    'head': (pen, h) => oryxHead(pen, v),
    'blink': (pen, h) => oryxBlink(pen),
    'mouth': (pen, h) => oryxMouth(pen),
    'medal': (pen, h) => oryxMedal(pen, v),
  },
);
