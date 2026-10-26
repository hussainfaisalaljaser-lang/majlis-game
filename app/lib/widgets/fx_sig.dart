import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/shop.dart';
import 'frames/epic.dart';
import 'frames/kit.dart';
import 'frames/legendary.dart';
import 'frames/rare.dart';

export 'frames/kit.dart' show Moments, SigLayer, momentSeconds;

typedef _Make = FrameArt Function(
  ValueListenable<double> time, {
  required double avatar,
  required SigLayer layer,
  ValueListenable<double?>? moment,
});

/// رسمة كل إطار (FrameStyle.sig → رسامه). كل إطار رسمة وحركة ما تتكرر في غيره.
final Map<String, _Make> _frames = {
  // نادر: ثابت ولمعة تمر
  'ice': IceFrame.new,
  'sand': SandFrame.new,
  'oasis': OasisFrame.new,
  'pearl': PearlFrame.new,
  'night': NightFrame.new,
  'knight': KnightFrame.new,
  'crescent': CrescentFrame.new,
  // ملحمي: يتحرك
  'fire': FireFrame.new,
  'smoke': SmokeFrame.new,
  'lightning': LightningFrame.new,
  'comet': CometFrame.new,
  'neon': NeonFrame.new,
  'rainbow': RainbowFrame.new,
  'emerald': EmeraldFrame.new,
  'blood': BloodFrame.new,
  'blackgold': BlackGoldFrame.new,
  'elite': EliteFrame.new,
  'golden': GoldenFrame.new,
  'lanterns': LanternsFrame.new,
  // أسطوري: أكثر من طبقة، وله لحظة خاصة
  'sun': SunFrame.new,
  'arabesque': ArabesqueFrame.new,
  'peacock': PeacockFrame.new,
  'galaxy': GalaxyFrame.new,
  'ruby': RubyFrame.new,
  'phoenix': PhoenixFrame.new,
  'storm': StormFrame.new,
  'fireworks': FireworksFrame.new,
  'champ1': (t, {required avatar, required layer, moment}) =>
      ChampionFrame(t, avatar: avatar, layer: layer, moment: moment, rank: 1),
  'champ2': (t, {required avatar, required layer, moment}) =>
      ChampionFrame(t, avatar: avatar, layer: layer, moment: moment, rank: 2),
  'champ3': (t, {required avatar, required layer, moment}) =>
      ChampionFrame(t, avatar: avatar, layer: layer, moment: moment, rank: 3),
};

/// رسام الإطار حسب [FrameStyle.sig]، أو null لو ما له رسمة.
CustomPainter? sigFramePainter(
  FrameStyle style,
  ValueListenable<double> time, {
  required double avatar,
  required SigLayer layer,
  ValueListenable<double?>? moment,
}) => _frames[style.sig]?.call(time, avatar: avatar, layer: layer, moment: moment);
