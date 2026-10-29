// تصوير افكتات الموت: المعاينة (المتجر) بمقاسات ٦٤/١٢٨/٢٥٦، وشرائط حركة كل افكت (المعاينة واللعبة).
// التشغيل:  flutter test tool/shots/death_shots_test.dart   (والصور تنحفظ في مجلد SHOT_DIR)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/game_view.dart';
import 'package:majlis/models/room.dart';
import 'package:majlis/models/shop.dart';
import 'package:majlis/services/notes.dart';
import 'package:majlis/widgets/common.dart';
import 'package:majlis/widgets/death_fx.dart';
import 'package:majlis/widgets/design_death.dart';
import 'package:majlis/widgets/fx.dart';
import 'package:majlis/widgets/game/game_table.dart';
import 'package:majlis/widgets/majlis.dart';

import 'shot_helper.dart';

const _parchment = Color(0xFFE6CC9A);

/// مربع المعاينة (نفس رسمة المتجر) في لقطة ثابتة.
class _Still extends StatelessWidget {
  const _Still(this.fx, this.size, {this.s = 4, this.idle = 1.7});

  final DeathFx fx;
  final double size, s, idle;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _StillPainter(fx, s, idle));
}

class _StillPainter extends CustomPainter {
  _StillPainter(this.fx, this.s, this.idle);

  final DeathFx fx;
  final double s, idle;

  @override
  void paint(Canvas canvas, Size size) => paintDeathBox(canvas, size, fx, s: s, idle: idle);

  @override
  bool shouldRepaint(_StillPainter old) => true;
}

/// خلفية بطاقة المتجر (ورق) حول الرسمة.
Widget _tile(Widget child, double size) => Container(
  width: size + 16,
  height: size + 16,
  margin: const EdgeInsets.all(5),
  padding: const EdgeInsets.all(8),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF2DDB0), _parchment],
    ),
    border: Border.all(color: const Color(0xFF6B4423), width: 2),
  ),
  child: child,
);

/// صورة اللاعب بالطاولة بوقت [t] من بداية الطرد (نفس تركيب game_table: الصورة بفلترها + الافكت فوقها).
class _Seat extends StatelessWidget {
  const _Seat(this.fx, this.t, this.d, {this.idle = 1.7});

  final DeathFx fx;
  final double t, d, idle;

  @override
  Widget build(BuildContext context) {
    final look = deathLook(fx, t);
    Widget avatar = PlayerAvatar(avatar: 'falcon', frame: const Color(0xFFE9B949), size: d, animate: false);
    if (look.matrix != null) avatar = ColorFiltered(colorFilter: ColorFilter.matrix(look.matrix!), child: avatar);
    final cloth = fx == DeathFx.cloth ? ((t - 2.6) / 1.2).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (cloth < 1 && !deathHidesAvatar(fx, t))
            Opacity(opacity: look.opacity.clamp(0.0, 1.0), child: avatar)
          else
            SizedBox(width: d, height: d),
          Positioned.fill(
            child: CustomPaint(painter: DeathPainter(fx, t, idle: idle)),
          ),
          if (cloth > 0)
            Positioned(
              left: -d * .06,
              top: -d * .06,
              child: SeatCloth(k: cloth, width: d * 1.12, height: d * 1.12),
            ),
        ],
      ),
    );
  }
}

const _names = ['me', 'lulwa', 'badr', 'turki', 'faisal', 'majed', 'jood'];
const _avatarIds = ['emir', 'jasmine', 'youth', 'masked', 'night', 'sky', 'rose'];

/// طاولة اللعبة الحقيقية (GameTable) بسبعة لاعبين، وفيها مطرودين بافكتاتهم (آخر لقطة لأن ما فيه deathAt).
Widget _table(Map<String, DeathFx> dead) {
  final view = GameView.fromJson({
    'you': 'me',
    'yourRole': 'loyal',
    'players': [
      for (var i = 0; i < _names.length; i++)
        {
          'id': _names[i],
          'name': ['أنا', 'لولوة', 'بدر', 'تركي', 'فيصل', 'ماجد', 'جود'][i],
          'seat': i,
          'alive': !dead.containsKey(_names[i]),
          'hasVoted': false,
          if (i == 0) 'knownRole': 'loyal',
        },
    ],
    'phase': 'nomination',
    'round': 1,
    'presidentId': 'me',
    'nomineeId': null,
    'electionTracker': 0,
    'drawPileCount': 17,
    'discardPileCount': 0,
    'loyalPolicies': 0,
    'traitorPolicies': 0,
    'pendingPower': null,
    'hand': const [],
    'canVeto': false,
    'yourInvestigations': const [],
    'winner': null,
    'winReason': null,
    'log': const [],
    'deadline': null,
  });
  final room = Room.fromJson({
    'code': 'ABCD',
    'hostId': 'me',
    'status': 'playing',
    'isPrivate': false,
    'maxPlayers': 7,
    'tierId': null,
    'players': [
      for (var i = 0; i < _names.length; i++)
        {
          'uid': _names[i],
          'name': _names[i],
          'avatar': _avatarIds[i],
          'bot': false,
          if (dead[_names[i]] != null) 'death': 'death_${dead[_names[i]]!.name}',
        },
    ],
    'watchers': const <String>[],
  });
  return Container(
    color: const Color(0xFF1B2A44),
    child: GameTable(view: view, room: room, center: (context, stage) => const SizedBox.shrink(), notes: Notes('x')),
  );
}

const _frames = <double>[0, .25, .5, .9, 1.4, 2.0, 2.6, 4.0];

void main() {
  setUpAll(loadFonts);

  testWidgets('death_previews', (tester) async {
    Widget row(double size, Iterable<DeathFx> list) =>
        Row(mainAxisSize: MainAxisSize.min, children: [for (final fx in list) _tile(_Still(fx, size), size)]);
    const all = DeathFx.values;
    final a = all.take(5), b = all.skip(5);
    for (final (name, size) in const [('256', 256.0), ('128', 128.0)]) {
      await shot(
        tester,
        'death_prev_$name',
        Scaffold(
          backgroundColor: const Color(0xFF3A1E12),
          body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [row(size, a), row(size, b)]),
          ),
        ),
        size: size > 200 ? const Size(1500, 640) : const Size(780, 330),
      );
    }
    await shot(
      tester,
      'death_prev_64',
      Scaffold(
        backgroundColor: const Color(0xFF3A1E12),
        body: Center(child: row(64, all)),
      ),
      size: const Size(940, 120),
    );
  });

  testWidgets('table_final', (tester) async {
    FxClock.lite.value = true;
    addTearDown(() => FxClock.lite.value = false);
    const all = DeathFx.values;
    for (var g = 0; g < 4; g++) {
      final fxs = all.skip(g * 3).take(3).toList();
      if (fxs.length < 3) fxs.addAll(all.take(3 - fxs.length));
      await shot(tester, 'death_table_$g', _table({'badr': fxs[0], 'turki': fxs[1], 'majed': fxs[2]}));
    }
  });

  for (final fx in DeathFx.values) {
    testWidgets('film_${fx.name}', (tester) async {
      await shot(
        tester,
        'death_film_${fx.name}',
        Scaffold(
          backgroundColor: const Color(0xFF3A1E12),
          body: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // المعاينة: s من بداية الافكت
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [for (final s in _frames) _tile(_Still(fx, 128, s: s, idle: 1.7 + s), 128)],
                ),
                // اللعبة: الصورة نفسها تتحول (t من بداية الطرد؛ الغطا الافتراضي له توقيته)
                Container(
                  color: const Color(0xFF1B2A44),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final s in _frames)
                        SizedBox(
                          width: 146,
                          height: 150,
                          child: Center(
                            child: _Seat(fx, (fx == DeathFx.cloth ? 2.6 : deathFxStart) + s, 84, idle: 1.7 + s),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        size: const Size(1250, 360),
      );
    });
  }
}
