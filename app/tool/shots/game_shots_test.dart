// تصوير شاشة اللعبة (الطاولة والنوافذ) ببيانات تجريبية، بدون جوال ولا سيرفر.
// التشغيل:  flutter test tool/shots/game_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/game_view.dart';
import 'package:majlis/models/profile.dart';
import 'package:majlis/models/room.dart';
import 'package:majlis/models/shop.dart';
import 'package:majlis/screens/game_screen.dart';
import 'package:majlis/services/backend.dart';
import 'package:majlis/services/music.dart';
import 'package:majlis/widgets/fx.dart';
import 'package:majlis/widgets/game/overlays.dart';
import 'package:majlis/widgets/game/scenes.dart';
import 'package:majlis/widgets/majlis.dart';
import 'package:majlis/theme.dart';
import 'package:majlis/widgets/venues.dart';

import 'shot_helper.dart';

/// سبعة لاعبين مثل الفيديو: أنت (الرئيس) وبعدك عكس عقارب الساعة.
const _names = {
  'me': 'أنا',
  'lulwa': 'لولوة',
  'badr': 'بدر',
  'turki': 'تركي',
  'faisal': 'فيصل',
  'majed': 'ماجد',
  'jood': 'جود',
};
const _avatars = {
  'me': 'emir',
  'lulwa': 'jasmine',
  'badr': 'youth',
  'turki': 'masked',
  'faisal': 'night',
  'majed': 'sky',
  'jood': 'rose',
};
const _frames = {'turki': 'frame_fire', 'faisal': 'frame_lv20'};
const _roles = {
  'me': 'loyal',
  'lulwa': 'loyal',
  'badr': 'loyal',
  'turki': 'traitor',
  'faisal': 'loyal',
  'majed': 'loyal',
  'jood': 'leader',
};

/// ما يعرفه اللاعب عن الأدوار: دورك بس (أو الكل بعد اللعبة).
Map<String, dynamic> _viewJson({
  String phase = 'nomination',
  String? nominee,
  String president = 'me',
  List<String> hand = const [],
  int loyal = 0,
  int traitor = 0,
  Map<String, bool> voted = const {},
  bool over = false,
  String? winner,
  String yourRole = 'loyal',
  String? pendingPower,
  bool canVeto = false,
  List<Map<String, dynamic>> log = const [],
  int round = 1,
  int tracker = 0,
  bool traitorsKnown = false,
  List<String> dead = const [],
  List<String>? claim,
}) {
  final ids = _names.keys.toList();
  return {
    'you': 'me',
    'yourRole': yourRole,
    'players': [
      for (var i = 0; i < ids.length; i++)
        {
          'id': ids[i],
          'name': _names[ids[i]],
          'seat': i,
          'alive': !dead.contains(ids[i]),
          'hasVoted': voted[ids[i]] ?? false,
          if (over || ids[i] == 'me' || (traitorsKnown && _roles[ids[i]] != 'loyal'))
            'knownRole': ids[i] == 'me' ? yourRole : _roles[ids[i]],
        },
    ],
    'phase': over ? 'gameOver' : phase,
    'round': round,
    'presidentId': president,
    'nomineeId': nominee,
    'electionTracker': tracker,
    'drawPileCount': 17,
    'discardPileCount': 0,
    'loyalPolicies': loyal,
    'traitorPolicies': traitor,
    'pendingPower': pendingPower,
    'hand': hand,
    'canVeto': canVeto,
    'yourInvestigations': const [],
    'winner': winner,
    'winReason': over ? 'loyalPolicies' : null,
    'log': log,
    if (claim != null) 'claimable': {'count': claim.length, 'truth': claim},
    'deadline': over ? null : DateTime.now().add(const Duration(seconds: 18)).millisecondsSinceEpoch,
  };
}

/// ملصقات طالعة الحين فوق لاعبين: [from] → رقم الملصق في القائمة.
List<Map<String, dynamic>> _stickerReactions(Map<String, int> from) => [
  for (final e in from.entries)
    {'from': e.key, 'kind': stickers[e.value].id, 'at': DateTime.now().millisecondsSinceEpoch - 600},
];

/// مستوى الطاولة لكل مكان (الجو والخلفية يتبعونه).
const venueTier = {
  Venue.desert: 'starter',
  Venue.city: 'city',
  Venue.palace: 'palace',
  Venue.kings: 'kings',
  Venue.vip: 'vip',
};

Room _room({
  bool finished = false,
  List<String> watchers = const [],
  List<Map<String, dynamic>> reactions = const [],
  String? tier,
}) => Room.fromJson({
  'code': 'ABCD',
  'hostId': 'me',
  'status': finished ? 'finished' : 'playing',
  'isPrivate': false,
  'maxPlayers': 7,
  'tierId': tier,
  'players': [
    for (final id in _names.keys)
      {'uid': id, 'name': _names[id], 'avatar': _avatars[id], 'frame': _frames[id], 'bot': false},
  ],
  'watchers': watchers,
  'reactions': reactions,
  if (finished)
    'results': {
      'me': {'won': true, 'coins': 600, 'xp': 120, 'rank': 12, 'boost': 1},
    },
});

GameView _view(Map<String, dynamic> json) => GameView.fromJson(json);

/// يفتح الشاشة ثم يشغّل [after] بعد أول فريم (لعرض نافذة فوقها).
class _Launcher extends StatefulWidget {
  const _Launcher({required this.preview, this.after});

  final GamePreview preview;
  final void Function(BuildContext context)? after;

  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher> {
  @override
  void initState() {
    super.initState();
    if (widget.after case final f?) WidgetsBinding.instance.addPostFrameCallback((_) => f(context));
  }

  @override
  Widget build(BuildContext context) => GameScreen.preview(preview: widget.preview);
}

final _outDir = Platform.environment['SHOT_DIR'] ?? 'build/shots';

/// مثل shot() بس الصورة بدقة الفيديو الكاملة (١٩٢٠×١٠٨٠ لشاشة ٩٦٠×٥٤٠)، عشان نقارن التفاصيل.
Future<void> _hiRes(
  WidgetTester tester,
  String name,
  Widget screen, {
  Size size = const Size(960, 540),
  int frames = 6,
}) async {
  final key = GlobalKey();
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: screen,
      ),
    ),
  );
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump(const Duration(milliseconds: 250));
  }
  auditAlign(name);
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    Directory(_outDir).createSync(recursive: true);
    File('$_outDir/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

void main() {
  setUpAll(loadFonts);
  setUp(() {
    FxClock.manual.value = 3.0;
    // الراوي ما يتكلم بالاختبار (ما فيه مشغل صوت).
    Music.visible.value = false;
    // ملف لاعب فيه ملصقات مفضلة، عشان يبان عمود الردود على الجنب.
    Backend.instance.profile.value = Profile.fromJson({
      'name': 'أنا',
      'avatar': 'emir',
      'coins': 1000,
      'diamonds': 5,
      'xp': 100,
      'level': 3,
      'gamesPlayed': 10,
      'gamesWon': 5,
      'dailyStreak': 1,
      'favorites': ['b_laugh', 'b_angry', 'laugh_tears', 'ang_steam', 'cof_cup'],
    });
  });
  tearDown(() => FxClock.manual.value = null);

  Future<void> screen(
    WidgetTester tester,
    String name,
    GamePreview preview, {
    Size size = const Size(960, 540),
    void Function(BuildContext)? after,
    int frames = 6,
  }) => _hiRes(
    tester,
    name,
    _Launcher(preview: preview, after: after),
    size: size,
    frames: frames,
  );

  testWidgets('nominate', (tester) async {
    final view = _view(_viewJson());
    await screen(tester, 'game_nominate', GamePreview(view: view, room: _room()));
  });

  testWidgets('election', (tester) async {
    final view = _view(_viewJson(phase: 'election', nominee: 'faisal', voted: {'turki': true}));
    await screen(tester, 'game_election', GamePreview(view: view, room: _room()));
  });

  testWidgets('discard', (tester) async {
    final view = _view(_viewJson(phase: 'presidentDiscard', nominee: 'faisal', hand: ['L', 'T', 'L']));
    await screen(tester, 'game_discard', GamePreview(view: view, room: _room()));
  });

  testWidgets('role', (tester) async {
    final view = _view(_viewJson(phase: 'nomination'));
    await screen(
      tester,
      'game_role',
      GamePreview(view: view, room: _room()),
      after: (context) => showRoleReveal(context, view, _room()),
      frames: 10,
    );
  });

  testWidgets('role traitor', (tester) async {
    for (final (tag, size) in [('800', const Size(800, 360)), ('phone', const Size(660, 297))]) {
      final view = _view(_viewJson(yourRole: 'traitor', traitorsKnown: true, president: 'jood'));
      await screen(
        tester,
        'game_role_traitor_$tag',
        GamePreview(view: view, room: _room()),
        size: size,
        after: (context) => showRoleReveal(context, view, _room()),
        frames: 10,
      );
    }
  });

  testWidgets('enact_chancellor', (tester) async {
    final view = _view(
      _viewJson(
        phase: 'chancellorEnact',
        president: 'faisal',
        nominee: 'me',
        hand: ['L', 'T'],
        canVeto: true,
        loyal: 1,
        traitor: 1,
      ),
    );
    await screen(tester, 'game_enact_hand', GamePreview(view: view, room: _room()));
  });

  testWidgets('vote_scene', (tester) async {
    FxClock.lite.value = true;
    addTearDown(() => FxClock.lite.value = false);
    final view = _view(_viewJson(phase: 'presidentDiscard', nominee: 'faisal'));
    final votes = {
      'me': true,
      'lulwa': false,
      'badr': true,
      'turki': true,
      'faisal': true,
      'majed': false,
      'jood': true,
    };
    await screen(
      tester,
      'game_vote_scene',
      GamePreview(
        view: view,
        room: _room(),
        scene: VoteScene(view: view, votes: votes, passed: true),
      ),
    );
  });

  testWidgets('enact_scene', (tester) async {
    FxClock.lite.value = true;
    addTearDown(() => FxClock.lite.value = false);
    final view = _view(_viewJson(phase: 'nomination', loyal: 1));
    await screen(
      tester,
      'game_enact_scene',
      GamePreview(
        view: view,
        room: _room(),
        scene: EnactScene(view: view, loyal: true, chaos: false, from: 'faisal'),
      ),
    );
    await screen(
      tester,
      'game_enact_scene_red',
      GamePreview(
        view: view,
        room: _room(),
        scene: EnactScene(view: view, loyal: false, chaos: false, from: 'faisal'),
      ),
    );
  });

  testWidgets('death_unmask', (tester) async {
    FxClock.lite.value = true;
    addTearDown(() => FxClock.lite.value = false);
    final view = _view(_viewJson(phase: 'nomination', dead: ['badr']));
    await screen(
      tester,
      'game_death_scene',
      GamePreview(
        view: view,
        room: _room(),
        scene: const DeathScene(name: 'بدر', avatar: 'youth', guarded: false),
      ),
    );
    final over = _view(_viewJson(over: true, winner: 'loyal', loyal: 5, traitor: 2));
    await screen(
      tester,
      'game_unmask_scene',
      GamePreview(
        view: over,
        room: _room(finished: true),
        scene: UnmaskScene(view: over, room: _room(finished: true)),
      ),
    );
  });

  testWidgets('game_over', (tester) async {
    final over = _view(_viewJson(over: true, winner: 'loyal', loyal: 5, traitor: 2));
    await screen(tester, 'game_over_table', GamePreview(view: over, room: _room(finished: true)));
    await screen(tester, 'game_over_results', GamePreview(view: over, room: _room(finished: true), resultsOpen: true));
    final lost = _view(_viewJson(over: true, winner: 'traitor', loyal: 2, traitor: 6, yourRole: 'traitor'));
    await screen(tester, 'game_over_lost', GamePreview(view: lost, room: _room(finished: true), resultsOpen: true));
  });

  testWidgets('phones', (tester) async {
    for (final size in const [Size(800, 360), Size(700, 320)]) {
      final tag = '${size.width.toInt()}';
      await screen(
        tester,
        'game_nominate_$tag',
        GamePreview(view: _view(_viewJson()), room: _room()),
        size: size,
      );
      await screen(
        tester,
        'game_election_$tag',
        GamePreview(
          view: _view(_viewJson(phase: 'election', nominee: 'faisal')),
          room: _room(),
        ),
        size: size,
      );
      await screen(
        tester,
        'game_discard_$tag',
        GamePreview(
          view: _view(_viewJson(phase: 'presidentDiscard', nominee: 'faisal', hand: ['L', 'T', 'L'])),
          room: _room(),
        ),
        size: size,
      );
      final view = _view(_viewJson());
      await screen(
        tester,
        'game_role_$tag',
        GamePreview(view: view, room: _room()),
        size: size,
        after: (context) => showRoleReveal(context, view, _room()),
      );
    }
  });

  testWidgets('stickers_on_table', (tester) async {
    // ملصقات فوق أكثر من لاعب، على الجوال وعلى الشاشة الكبيرة
    final reactions = _stickerReactions({'me': 3, 'majed': 12, 'jood': 30, 'lulwa': 45});
    for (final size in const [Size(800, 360), Size(960, 540)]) {
      await screen(
        tester,
        'game_stickers_${size.width.toInt()}',
        GamePreview(
          view: _view(_viewJson()),
          room: _room(reactions: reactions),
        ),
        size: size,
      );
    }
  });

  // جو كل مستوى طاولة (على الجوال وعلى الشاشة الكبيرة)، والمطر عند لحظة برق
  testWidgets('atmospheres', (tester) async {
    final bolt = 2 + 4 * rnd(0, 61) + .05;
    for (final (name, venue, t) in [
      ('majlis', Venue.majlis, 7.3),
      ('desert', Venue.desert, 5.0),
      ('city', Venue.city, bolt),
      ('city_calm', Venue.city, bolt + 3),
      ('palace', Venue.palace, 4.0),
      ('kings', Venue.kings, 3.0),
      ('vip', Venue.vip, 6.0),
    ]) {
      FxClock.manual.value = t;
      for (final size in const [Size(960, 540), Size(800, 360)]) {
        await screen(
          tester,
          'game_atmo_${name}_${size.width.toInt()}',
          GamePreview(
            view: _view(_viewJson()),
            room: _room(tier: venueTier[venue]),
          ),
          size: size,
          frames: 8,
        );
      }
    }
  });

  testWidgets('extras', (tester) async {
    final nomination = _view(_viewJson());
    await screen(
      tester,
      'game_tip',
      GamePreview(
        view: nomination,
        room: _room(watchers: ['a', 'b']),
        tip: 'tut_nominate',
      ),
    );
    final pick = textReactions.firstWhere((r) => r.target);
    await screen(tester, 'game_pick_reaction', GamePreview(view: nomination, room: _room(), pendingReaction: pick));
    final claim = _view(_viewJson(president: 'faisal', claim: ['L', 'T', 'L']));
    await screen(tester, 'game_claim', GamePreview(view: claim, room: _room()));
    final voted = _view(_viewJson(phase: 'election', nominee: 'faisal', voted: {'me': true}));
    await screen(tester, 'game_waiting', GamePreview(view: voted, room: _room(), sent: 'صوّتت موافق… ننتظر الباقين'));
    final traitor = _view(_viewJson(yourRole: 'traitor', traitorsKnown: true, president: 'jood'));
    await screen(tester, 'game_traitor', GamePreview(view: traitor, room: _room()));
  });

  testWidgets('phones_more', (tester) async {
    FxClock.lite.value = true;
    addTearDown(() => FxClock.lite.value = false);
    final over = _view(_viewJson(over: true, winner: 'loyal', loyal: 5, traitor: 2));
    final votes = {
      'me': true,
      'lulwa': false,
      'badr': true,
      'turki': true,
      'faisal': true,
      'majed': false,
      'jood': true,
    };
    final view = _view(_viewJson(phase: 'presidentDiscard', nominee: 'faisal'));
    for (final size in const [Size(800, 360), Size(700, 320)]) {
      final tag = '${size.width.toInt()}';
      await screen(
        tester,
        'game_over_results_$tag',
        GamePreview(view: over, room: _room(finished: true), resultsOpen: true),
        size: size,
      );
      await screen(
        tester,
        'game_over_table_$tag',
        GamePreview(view: over, room: _room(finished: true)),
        size: size,
      );
      await screen(
        tester,
        'game_unmask_$tag',
        GamePreview(
          view: over,
          room: _room(finished: true),
          scene: UnmaskScene(view: over, room: _room(finished: true)),
        ),
        size: size,
      );
      await screen(
        tester,
        'game_vote_$tag',
        GamePreview(
          view: view,
          room: _room(),
          scene: VoteScene(view: view, votes: votes, passed: true),
        ),
        size: size,
      );
      final claim = _view(_viewJson(president: 'faisal', claim: ['L', 'T', 'L']));
      await screen(
        tester,
        'game_claim_$tag',
        GamePreview(view: claim, room: _room()),
        size: size,
      );
    }
  });

  testWidgets('scene_venues', (tester) async {
    for (final v in [Venue.city, Venue.palace, Venue.kings, Venue.vip]) {
      await shot(tester, 'game_scene_${v.name}', MajlisRoom(venue: v));
    }
  });

  // لحظات الطاولة: كل مشهد على أكثر من لحظة (للفحص: tm_<مشهد>_<ثانية بالأجزاء من عشرة>)
  String sec(double t) => (t * 10).round().toString().padLeft(2, '0');

  testWidgets('moments_vote', (tester) async {
    final view = _view(_viewJson(phase: 'presidentDiscard', nominee: 'faisal'));
    final votes = {
      'me': true,
      'lulwa': false,
      'badr': true,
      'turki': true,
      'faisal': true,
      'majed': false,
      'jood': true,
    };
    for (final t in [.9, 1.75, 2.1, 2.9]) {
      await screen(
        tester,
        'tm_vote_${sec(t)}',
        GamePreview(
          view: view,
          room: _room(),
          scene: VoteScene(view: view, votes: votes, passed: t != 2.9),
          sceneAt: t,
        ),
        frames: 2,
      );
    }
  });

  testWidgets('moments_enact', (tester) async {
    final view = _view(_viewJson(phase: 'nomination', loyal: 1));
    for (final t in [.5, 1.4, 2.0]) {
      await screen(
        tester,
        'tm_enact_red_${sec(t)}',
        GamePreview(
          view: view,
          room: _room(),
          scene: EnactScene(view: view, loyal: false, chaos: false, from: 'faisal'),
          sceneAt: t,
        ),
        frames: 2,
      );
    }
  });

  testWidgets('moments_death', (tester) async {
    final view = _view(_viewJson(phase: 'nomination', dead: ['badr']));
    for (final fx in [DeathFx.fire, DeathFx.ice, DeathFx.lightning]) {
      for (final t in [1.0, 1.7, 2.2, 3.3]) {
        await screen(
          tester,
          'tm_death_${fx.name}_${sec(t)}',
          GamePreview(
            view: view,
            room: _room(),
            scene: DeathScene(name: 'بدر', avatar: 'youth', guarded: false, fx: fx),
            sceneAt: t,
          ),
          frames: 2,
        );
      }
    }
    for (final fx in [
      DeathFx.cloth,
      DeathFx.smoke,
      DeathFx.sand,
      DeathFx.petals,
      DeathFx.bats,
      DeathFx.ghost,
      DeathFx.gold,
    ]) {
      await screen(
        tester,
        'tm_death_${fx.name}_33',
        GamePreview(
          view: view,
          room: _room(),
          scene: DeathScene(name: 'بدر', avatar: 'youth', guarded: false, fx: fx),
          sceneAt: 3.3,
        ),
        frames: 2,
      );
    }
    await screen(
      tester,
      'tm_death_guarded_17',
      GamePreview(
        view: view,
        room: _room(),
        scene: const DeathScene(name: 'بدر', avatar: 'youth', guarded: true),
        sceneAt: 1.7,
      ),
      frames: 2,
    );
  });
}
