// تصوير شاشات الموسم والتقدّم (الباتل باس، المهام، البطولة، الترتيب، الطاولات، السجل) ببيانات تجريبية.
// التشغيل:  flutter test tool/shots/season_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/game_view.dart';
import 'package:majlis/models/history.dart';
import 'package:majlis/models/leaderboard.dart';
import 'package:majlis/models/missions.dart';
import 'package:majlis/models/profile.dart';
import 'package:majlis/models/table_tier.dart';
import 'package:majlis/models/tour.dart';
import 'package:majlis/screens/history_screen.dart';
import 'package:majlis/screens/leaderboard_screen.dart';
import 'package:majlis/screens/missions_screen.dart';
import 'package:majlis/screens/pass_screen.dart';
import 'package:majlis/screens/tables_screen.dart';
import 'package:majlis/screens/tournament_screen.dart';
import 'package:majlis/theme.dart';
import 'package:majlis/widgets/design_season.dart';
import 'package:majlis/widgets/mode_theme.dart';
import 'package:majlis/widgets/ui.dart';

import 'shot_helper.dart';

/// مثل shot() بس بدقة ١٩٢٠×١٠٨٠ فعلاً (pixelRatio ٢) عشان نقارن التفاصيل مع الفيديو.
Future<void> shotHi(WidgetTester tester, String name, Widget screen, {Size size = const Size(960, 540)}) async {
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
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump(const Duration(milliseconds: 250));
  }
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    final dir = Platform.environment['SHOT_DIR'] ?? 'build/shots';
    Directory(dir).createSync(recursive: true);
    File('$dir/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
  });
}

/// ملف لاعب مثل اللي بالفيديو: درجة ٧ في الموسم، وجواهر وذهب، ومهام اليوم بين شغّالة وخالصة.
Profile fakeProfile({
  bool premium = false,
  int points = 7 * 150 + 70,
  int free = 6,
  int prem = 0,
  TourState? tour,
  int level = 12,
  int coins = 48250,
}) => Profile(
  name: 'سلمان',
  avatar: 'falcon',
  setupDone: true,
  coins: coins,
  diamonds: 320,
  xp: 1500,
  level: level,
  vip: false,
  gamesPlayed: 64,
  gamesWon: 31,
  lastDaily: null,
  dailyStreak: 3,
  tour: tour,
  pass: PassState(points: points, premium: premium, free: free, prem: prem),
  passMissionsRaw: PassMissionState(
    week: gulfWeek(DateTime.now()),
    weekly: const {'play': 10, 'win': 3, 'winTraitor': 1, 'win10': 0, 'loyalLaw': 1},
    total: const {'killLeader': 3, 'win': 12, 'play': 50, 'found': 2},
    weeklyClaimed: const {'w_traitor'},
    seasonClaimed: const {'s_play50'},
  ),
  missionsRaw: MissionState(
    day: gulfDay(DateTime.now()),
    progress: const {'play3': 3, 'win1': 1, 'legislate1': 0, 'claim2': 1, 'react5': 5},
    claimed: const {'win1'},
  ),
);

// ===== الموسم والمهام =====

Widget seasonView(Profile p) => SeasonView(
  profile: p,
  busy: false,
  onBuy: () {},
  onClaim: () {},
  onGift: () {},
  onMissions: () {},
  onDailyMissions: () {},
  now: DateTime.now(),
);

Widget missionsView(Profile p, int tab) => MissionsView(
  profile: p,
  tab: tab,
  onTab: (_) {},
  claiming: null,
  ready: true,
  onClaimDaily: (_) {},
  onClaimPass: (_) {},
);

// ===== الترتيب =====

const _names = ['جود', 'فيصل', 'لولوة', 'بدر', 'ماجد', 'سلمان', 'هند', 'نواف', 'ريم', 'خالد', 'مها', 'عمر', 'سارة'];
const _avatars = [
  'falcon',
  'sheikh',
  'cool',
  'scholar',
  'desert',
  'hawk',
  'falcon',
  'sheikh',
  'cool',
  'scholar',
  'desert',
  'hawk',
  'falcon',
];

LeaderboardEntry entry(int i, {String? frame}) => LeaderboardEntry.fromJson('u$i', {
  'name': _names[i],
  'avatar': _avatars[i],
  'frame': frame,
  'level': 38 - i * 2,
  'xp': 9000 - i * 400,
  'gamesWon': 140 - i * 9,
  'gamesPlayed': 260 - i * 10,
  'weeklyWins': 21 - i,
  'rankSeason': 's1',
  'rankPoints': 1500 - i * 110,
});

List<LeaderboardEntry> fakeEntries() => [
  for (var i = 0; i < _names.length; i++)
    entry(i, frame: i == 0 ? 'frame_blackgold' : (i == 2 ? 'frame_emerald' : null)),
];

Widget leaderboardView(Board board, {List<LeaderboardEntry>? entries, String me = 'u5'}) =>
    LeaderboardView(profile: fakeProfile(), board: board, onBoard: (_) {}, me: me, entries: entries ?? fakeEntries());

// ===== البطولة =====

Tour fakeTour() => Tour.fromJson({
  'players': {
    for (var i = 0; i < 11; i++)
      'u$i': {
        'name': _names[i],
        'avatar': _avatars[i],
        'frame': i == 0 ? 'frame_blackgold' : null,
        'stage': i == 0 ? 3 : (i < 3 ? 2 : (i < 6 ? 1 : 0)),
        'out': i >= 3 && i < 6,
      },
  },
});

final _tourNow = DateTime.utc(2026, 10, 30, 12);

Widget tournamentView(Profile p, {Tour? tour, DateTime? now}) => TournamentView(
  profile: p,
  tour: tour ?? fakeTour(),
  me: 'u5',
  week: gulfWeek(_tourNow),
  now: now ?? _tourNow,
  busy: false,
  onJoin: () {},
  onPlay: () {},
);

// ===== الطاولات =====

Widget tablesView(ModeTheme mode, {int count = 7, bool quick = false, int level = 12, int coins = 48250}) => TablesView(
  mode: mode,
  profile: fakeProfile(level: level, coins: coins),
  playerCount: count,
  onCount: (_) {},
  tier: tableTiers[1],
  onTier: (_) {},
  quick: quick,
  onQuick: (_) {},
  busy: false,
  onPlay: () {},
);

// ===== السجل =====

HistoryEntry fakeGame(
  int n, {
  required bool won,
  Role role = Role.loyal,
  Special? special,
  bool roles = false,
  int minutes = 90,
}) {
  const ids = ['u0', 'u1', 'u2', 'u3', 'u4', 'u5', 'u6'];
  final traitors = {'u2', 'u5'};
  Role roleOf(String id) =>
      id == 'u0' ? role : (traitors.contains(id) ? (id == 'u5' ? Role.leader : Role.traitor) : Role.loyal);
  final loyalWon = role == Role.loyal ? won : !won;
  String nameOf(int i) => _names[(i + 5) % _names.length];
  return HistoryEntry.fromJson('g$n', {
    'at': DateTime.now().subtract(Duration(minutes: minutes)).millisecondsSinceEpoch,
    'view': {
      'you': 'u0',
      'yourRole': role.name,
      'yourSpecial': special?.name,
      'players': [
        for (var i = 0; i < ids.length; i++)
          {
            'id': ids[i],
            'name': nameOf(i),
            'seat': i,
            'alive': i != 3 && i != 6,
            'knownRole': roleOf(ids[i]).name,
            'knownSpecial': i == 0 ? special?.name : null,
            'hasVoted': false,
          },
      ],
      'phase': 'gameOver',
      'round': 9,
      'presidentId': 'u1',
      'electionTracker': 0,
      'drawPileCount': 4,
      'loyalPolicies': loyalWon ? 5 : 3,
      'traitorPolicies': loyalWon ? 2 : 6,
      'hand': [],
      'canVeto': false,
      'yourInvestigations': [],
      'log': [],
      'winner': loyalWon ? 'loyal' : 'traitor',
      'winReason': loyalWon ? 'loyalPolicies' : 'traitorPolicies',
    },
    'room': {
      'code': 'ABCD$n',
      'hostId': 'u1',
      'status': 'finished',
      'isPrivate': n % 4 == 3,
      'maxPlayers': 7,
      'tierId': 'city',
      'roles': roles,
      'quick': n % 5 == 2,
      'players': [
        for (var i = 0; i < ids.length; i++) {'uid': ids[i], 'name': nameOf(i), 'avatar': _avatars[i]},
      ],
      'results': {
        'u0': {'won': won, 'coins': won ? 1400 : 0, 'xp': won ? 80 : 30},
      },
    },
  });
}

List<HistoryEntry> fakeGames() => [
  fakeGame(0, won: true, minutes: 20),
  fakeGame(1, won: false, role: Role.traitor, minutes: 150),
  fakeGame(2, won: true, special: Special.seer, roles: true, minutes: 60 * 6),
  fakeGame(3, won: false, role: Role.leader, minutes: 60 * 26),
  fakeGame(4, won: true, role: Role.traitor, minutes: 60 * 50),
  fakeGame(5, won: false, minutes: 60 * 72),
];

Widget historyView(List<HistoryEntry>? games, {bool error = false}) =>
    HistoryView(profile: fakeProfile(), games: games, error: error, onOpen: (_) {});

void main() {
  setUpAll(loadFonts);

  // الشاشات الحقيقية (مع الحالة) بدون سيرفر: تنبني بلا أخطاء بملف اللاعب التجريبي.
  testWidgets('الشاشات الحقيقية', (tester) async {
    await shot(tester, 'real_pass', const PassScreen());
    await shot(tester, 'real_missions', const MissionsScreen(tab: 1));
    await shot(tester, 'real_tables', const TablesScreen(mode: ModeTheme.advanced));
    await shot(tester, 'real_leaderboard', const LeaderboardScreen());
  });

  testWidgets('pass', (tester) async {
    await shotHi(tester, 'pass', seasonView(fakeProfile()));
  });

  testWidgets('pass_premium', (tester) async {
    await shotHi(
      tester,
      'pass_premium',
      seasonView(fakeProfile(premium: true, points: 12 * 150 + 30, free: 10, prem: 9)),
    );
  });

  testWidgets('pass_popup_claim', (tester) async {
    final popup = SnPopup(
      title: 'استلمت!',
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SeasonRewardChips(
            profile: fakeProfile(),
            coins: 1500,
            diamonds: 10,
            items: const ['frame_s1a', 'stk_s1', 'avatar_s1a'],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 170,
            child: SnButton(label: 'تمام', tone: SnTone.green, onPressed: () {}),
          ),
        ],
      ),
    );
    await shotHi(tester, 'pass_popup_claim', NightScaffold(body: Center(child: popup)));
  });

  testWidgets('pass_popup_options', (tester) async {
    final popup = SnPopup(
      title: 'اشترِ الباتل باس',
      width: 560,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SeasonOption(
                title: 'الباتل باس',
                lines: const ['المسار المدفوع وكل مكافآته', 'هدية: ١٠ درجات على طول'],
                price: 150,
                tone: SnTone.orange,
                onPick: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SeasonOption(
                title: 'الباتل باس كامل',
                lines: const ['المسار المدفوع وكل مكافآته', 'كل الدرجات الـ٣٠ مفتوحة على طول'],
                price: 750,
                tone: SnTone.blue,
                onPick: () {},
              ),
            ),
          ],
        ),
      ),
    );
    await shotHi(tester, 'pass_popup_options', NightScaffold(body: Center(child: popup)));
  });

  testWidgets('pass_popup_gift', (tester) async {
    final popup = SnPopup(
      title: 'أهدِ الباتل باس لصاحبك',
      width: 460,
      child: SizedBox(height: 210, child: SeasonFriendList(friends: [entry(0), entry(1), entry(2), entry(3)])),
    );
    await shotHi(tester, 'pass_popup_gift', NightScaffold(body: Center(child: popup)));
  });

  testWidgets('pass_small', (tester) async {
    await shot(tester, 'pass_small', seasonView(fakeProfile()), size: const Size(700, 320));
  });

  for (final tab in [0, 1, 2]) {
    testWidgets('missions_$tab', (tester) async {
      await shotHi(tester, 'missions_$tab', missionsView(fakeProfile(), tab));
    });
  }

  testWidgets('missions_small', (tester) async {
    await shot(tester, 'missions_small', missionsView(fakeProfile(), 2), size: const Size(700, 320));
  });

  testWidgets('leaderboard_weekly', (tester) async {
    await shotHi(tester, 'leaderboard_weekly', leaderboardView(Board.weekly));
  });

  testWidgets('leaderboard_ranked', (tester) async {
    await shotHi(tester, 'leaderboard_ranked', leaderboardView(Board.ranked));
  });

  testWidgets('leaderboard_level', (tester) async {
    await shot(tester, 'leaderboard_level', leaderboardView(Board.level, me: 'nobody'));
  });

  testWidgets('leaderboard_empty', (tester) async {
    await shot(tester, 'leaderboard_empty', leaderboardView(Board.weekly, entries: const []));
  });

  testWidgets('leaderboard_small', (tester) async {
    await shot(tester, 'leaderboard_small', leaderboardView(Board.ranked), size: const Size(700, 320));
  });

  testWidgets('tournament_play', (tester) async {
    final mine = TourState(week: gulfWeek(_tourNow), stage: 1, out: false);
    await shotHi(tester, 'tournament_play', tournamentView(fakeProfile(tour: mine)));
  });

  testWidgets('tournament_join', (tester) async {
    await shot(tester, 'tournament_join', tournamentView(fakeProfile()));
  });

  testWidgets('tournament_closed', (tester) async {
    final closed = DateTime.utc(2026, 10, 27, 12);
    await shot(tester, 'tournament_closed', tournamentView(fakeProfile(), tour: Tour.empty, now: closed));
  });

  testWidgets('tournament_small', (tester) async {
    await shot(tester, 'tournament_small', tournamentView(fakeProfile()), size: const Size(700, 320));
  });

  testWidgets('tables_classic', (tester) async {
    await shotHi(tester, 'tables_classic', tablesView(ModeTheme.classic));
  });

  testWidgets('tables_advanced', (tester) async {
    await shot(
      tester,
      'tables_advanced',
      tablesView(ModeTheme.advanced, count: 10, quick: true, level: 5, coins: 3000),
    );
  });

  testWidgets('tables_small', (tester) async {
    await shot(tester, 'tables_small', tablesView(ModeTheme.classic), size: const Size(700, 320));
  });

  testWidgets('history', (tester) async {
    await shotHi(tester, 'history', historyView(fakeGames()));
  });

  testWidgets('history_empty', (tester) async {
    await shot(tester, 'history_empty', historyView(const []));
  });

  testWidgets('history_details', (tester) async {
    final game = fakeGame(2, won: true, special: Special.seer, roles: true);
    await shotHi(
      tester,
      'history_details',
      NightScaffold(
        body: Center(child: HistoryDetails(game: game)),
      ),
    );
  });

  testWidgets('history_small', (tester) async {
    await shot(tester, 'history_small', historyView(fakeGames()), size: const Size(700, 320));
  });

  // مقاس جوال صغير (٨٠٠×٣٦٠): نتأكد ما فيه overflow ولا شي ينقص.
  group('جوال ٨٠٠×٣٦٠', () {
    const phone = Size(800, 360);
    final screens = <String, Widget Function()>{
      'pass': () => seasonView(fakeProfile()),
      'missions': () => missionsView(fakeProfile(), 0),
      'leaderboard': () => leaderboardView(Board.weekly),
      'ranked': () => leaderboardView(Board.ranked),
      'tournament': () => tournamentView(fakeProfile()),
      'tables': () => tablesView(ModeTheme.classic),
      'history': () => historyView(fakeGames()),
    };
    for (final e in screens.entries) {
      testWidgets(e.key, (tester) async {
        await shot(tester, '${e.key}_800', e.value(), size: phone);
      });
    }
  });
}
