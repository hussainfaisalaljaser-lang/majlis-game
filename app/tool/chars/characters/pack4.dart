// Character pack 4 (worker D1): the animated animal / mascot avatars with layered rigs.
// Each character's layer painters live in parts/d1_<name>.dart; the still is the composite of its layers.
import '../kit.dart';
import '../parts/d1_falcon.dart';
import '../parts/d1_leopard.dart';
import '../parts/d1_lion.dart';
import '../parts/d1_owl.dart';
import '../parts/d1_phoenix.dart';
import '../parts/d1_wolf.dart';

final List<CharSpec> pack4 = [
  wolfSpec(),
  falconBirdSpec(),
  owlSpec(),
  leopardSpec(),
  lionSpec(),
  phoenixSpec(),
];
