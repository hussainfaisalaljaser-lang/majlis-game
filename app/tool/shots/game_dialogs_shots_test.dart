// تصوير نوافذ اللعبة (سجل اللعبة، الردود، مين كذب، المشاركة، الشارات، الرموز) ببيانات تجريبية.
// التشغيل:  flutter test tool/shots/game_dialogs_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/catalog.dart';
import 'package:majlis/models/game_view.dart';
import 'package:majlis/models/profile.dart';
import 'package:majlis/models/room.dart';
import 'package:majlis/services/backend.dart';
import 'package:majlis/theme.dart';
import 'package:majlis/widgets/badges.dart';
import 'package:majlis/widgets/common.dart';
import 'package:majlis/widgets/design.dart';
import 'package:majlis/widgets/fx.dart';
import 'package:majlis/widgets/game/game_log.dart';
import 'package:majlis/widgets/game/lies_reveal.dart';
import 'package:majlis/widgets/game/reactions_sheet.dart';
import 'package:majlis/widgets/game/share_card.dart';
import 'package:majlis/widgets/pid.dart';

import 'shot_helper.dart';

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
const _roles = {
  'me': 'loyal',
  'lulwa': 'loyal',
  'badr': 'loyal',
  'turki': 'traitor',
  'faisal': 'loyal',
  'majed': 'loyal',
  'jood': 'leader',
};

/// سجل لعبة فيه كل أنواع الأحداث الشائعة (ترشيح، تصويت، قرار، ادعاءات متناقضة، حكومة فاشلة، طرد).
List<Map<String, dynamic>> _log() => [
  {'type': 'nominated', 'round': 1, 'president': 'me', 'chancellor': 'faisal'},
  {
    'type': 'voteResult',
    'round': 1,
    'passed': true,
    'votes': {'me': true, 'lulwa': true, 'badr': true, 'turki': false, 'faisal': true, 'majed': true, 'jood': false},
  },
  {
    'type': 'enacted',
    'round': 1,
    'policy': 'T',
    'government': {'president': 'me', 'chancellor': 'faisal'},
  },
  {
    'type': 'claim',
    'round': 1,
    'claim': {
      'by': 'me',
      'office': 'president',
      'policies': ['L', 'L', 'T'],
    },
  },
  {
    'type': 'claim',
    'round': 1,
    'claim': {
      'by': 'faisal',
      'office': 'chancellor',
      'policies': ['L', 'L'],
    },
  },
  {'type': 'nominated', 'round': 2, 'president': 'lulwa', 'chancellor': 'badr'},
  {
    'type': 'voteResult',
    'round': 2,
    'passed': false,
    'votes': {'me': false, 'lulwa': true, 'badr': true, 'turki': false, 'faisal': false, 'majed': false, 'jood': true},
  },
  {'type': 'nominated', 'round': 3, 'president': 'badr', 'chancellor': 'majed'},
  {
    'type': 'voteResult',
    'round': 3,
    'passed': true,
    'votes': {'me': true, 'lulwa': true, 'badr': true, 'turki': true, 'faisal': true, 'majed': true, 'jood': true},
    'weights': {'jood': 2},
  },
  {
    'type': 'enacted',
    'round': 3,
    'policy': 'L',
    'government': {'president': 'badr', 'chancellor': 'majed'},
  },
  {'type': 'executed', 'round': 3, 'by': 'badr', 'target': 'turki'},
  {'type': 'gameOver', 'round': 3, 'winner': 'loyal', 'reason': 'loyalPolicies'},
];

/// أحداث أندر: النقض، قاضي، تحقيق، تلصص، فوضى، انتخاب خاص، حارس.
List<Map<String, dynamic>> _logRare() => [
  {'type': 'nominated', 'round': 4, 'president': 'jood', 'chancellor': 'badr'},
  {
    'type': 'voteResult',
    'round': 4,
    'passed': false,
    'cancelledBy': 'majed',
    'votes': {'me': true, 'lulwa': true, 'badr': true, 'turki': false, 'faisal': true, 'majed': true, 'jood': true},
  },
  {'type': 'nominated', 'round': 5, 'president': 'turki', 'chancellor': 'faisal'},
  {
    'type': 'voteResult',
    'round': 5,
    'passed': true,
    'votes': {'me': true, 'lulwa': true, 'badr': true, 'turki': true, 'faisal': true, 'majed': false, 'jood': false},
  },
  {
    'type': 'vetoed',
    'round': 5,
    'government': {'president': 'turki', 'chancellor': 'faisal'},
  },
  {'type': 'vetoRejected', 'round': 5},
  {'type': 'investigated', 'round': 5, 'by': 'turki', 'target': 'me'},
  {'type': 'peeked', 'round': 5, 'by': 'turki'},
  {'type': 'specialElection', 'round': 5, 'by': 'turki', 'target': 'lulwa'},
  {'type': 'guarded', 'round': 5, 'by': 'turki', 'target': 'badr'},
  {'type': 'enacted', 'round': 6, 'policy': 'T', 'chaos': true},
  {'type': 'gameOver', 'round': 6, 'winner': 'traitor', 'reason': 'leaderElected'},
];

/// سجل للكشف («مين كذب؟»): ثلاث حكومات مررت قرار، والكروت الحقيقية في [truths].
List<Map<String, dynamic>> _liesLog() => [
  for (final (round, pres, chan, policy, said1, said2) in [
    (1, 'me', 'faisal', 'T', ['L', 'L', 'T'], ['L', 'T']),
    (2, 'badr', 'majed', 'L', ['L', 'T', 'T'], ['L', 'T']),
    (3, 'lulwa', 'jood', 'T', ['L', 'T', 'T'], ['T', 'T']),
  ]) ...[
    {
      'type': 'enacted',
      'round': round,
      'policy': policy,
      'government': {'president': pres, 'chancellor': chan},
    },
    {
      'type': 'claim',
      'round': round,
      'claim': {'by': pres, 'office': 'president', 'policies': said1},
    },
    {
      'type': 'claim',
      'round': round,
      'claim': {'by': chan, 'office': 'chancellor', 'policies': said2},
    },
  ],
];

Map<String, dynamic> _viewJson({
  List<Map<String, dynamic>> log = const [],
  bool over = false,
  String yourRole = 'loyal',
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
          'alive': true,
          'hasVoted': false,
          if (over || ids[i] == 'me') 'knownRole': ids[i] == 'me' ? yourRole : _roles[ids[i]],
        },
    ],
    'phase': over ? 'gameOver' : 'nomination',
    'round': 3,
    'presidentId': 'me',
    'electionTracker': 0,
    'drawPileCount': 12,
    'discardPileCount': 3,
    'loyalPolicies': 2,
    'traitorPolicies': 2,
    'hand': const [],
    'canVeto': false,
    'yourInvestigations': const [],
    'winner': over ? 'loyal' : null,
    'winReason': over ? 'loyalPolicies' : null,
    'log': log,
    if (over)
      'truths': {
        '1': {
          'president': ['L', 'T', 'T'],
          'chancellor': ['L', 'T'],
        },
        '2': {
          'president': ['L', 'L', 'T'],
          'chancellor': ['L', 'L'],
        },
        '3': {
          'president': ['L', 'T', 'T'],
          'chancellor': ['T', 'T'],
        },
      },
  };
}

GameView _view(Map<String, dynamic> json) => GameView.fromJson(json);

Room _room() => Room.fromJson({
  'code': 'ABCD',
  'hostId': 'me',
  'status': 'finished',
  'isPrivate': false,
  'maxPlayers': 7,
  'tierId': null,
  'players': [
    for (final id in _names.keys) {'uid': id, 'name': _names[id], 'avatar': _avatars[id], 'bot': false},
  ],
  'results': {
    'me': {'won': true, 'coins': 600, 'xp': 120, 'rank': 12, 'boost': 1},
  },
});

/// خلفية تشبه طاولة الليل، عشان نشوف حافة النافذة فوقها.
class _Backdrop extends StatelessWidget {
  const _Backdrop({this.after});

  final void Function(BuildContext context)? after;

  @override
  Widget build(BuildContext context) => _Launcher(
    after: after,
    child: const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111A33), Color(0xFF3B3A5C), Color(0xFFB9824A)],
        ),
      ),
      child: SizedBox.expand(),
    ),
  );
}

/// يشغّل [after] بعد أول فريم (لعرض نافذة فوق الخلفية).
class _Launcher extends StatefulWidget {
  const _Launcher({required this.child, this.after});

  final Widget child;
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
  Widget build(BuildContext context) => widget.child;
}

final _outDir = Platform.environment['SHOT_DIR'] ?? 'build/shots';

/// يفتح الشاشة على الحجم المطلوب (الصورة بضعف الدقة).
Future<GlobalKey> _open(WidgetTester tester, Widget screen, {Size size = const Size(960, 540), int frames = 6}) async {
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
  await _settle(tester, frames);
  return key;
}

/// يحرك الفريمات (والصور تنفك بوقت حقيقي).
Future<void> _settle(WidgetTester tester, int frames) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _save(WidgetTester tester, GlobalKey key, String name) async {
  auditAlign(name);
  await _saveImage(tester, key, name);
}

Future<void> _saveImage(WidgetTester tester, GlobalKey key, String name) => tester.runAsync(() async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  Directory(_outDir).createSync(recursive: true);
  File('$_outDir/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
});

/// لقطة شاشة كاملة بعد فتح النافذة.
Future<void> _shot(
  WidgetTester tester,
  String name,
  Widget screen, {
  Size size = const Size(960, 540),
  int frames = 6,
}) async {
  final key = await _open(tester, screen, size: size, frames: frames);
  await _save(tester, key, name);
}

const _phone = Size(800, 360);
const _small = Size(700, 320);

void main() {
  setUpAll(() async {
    await loadFonts();
    // أيقونات Material (النجمة والإغلاق) ما تنحمل بالاختبار، فنحملها من الـ SDK.
    final root = Platform.environment['FLUTTER_ROOT'];
    final icons = root == null ? null : File('$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf');
    if (icons != null && icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())))).load();
    }
  });
  setUp(() {
    FxClock.manual.value = 3.0;
    Backend.instance.profile.value = Profile.fromJson({
      'name': 'أنا',
      'avatar': 'emir',
      'coins': 1000,
      'diamonds': 320,
      'xp': 100,
      'level': 3,
      'gamesPlayed': 10,
      'gamesWon': 5,
      'dailyStreak': 1,
      'pid': '4821',
      'pidTier': 2,
      'rank': {'season': season.id, 'points': 540, 'best': 600},
      'favorites': ['b_laugh', 'b_angry', 'laugh_tears', 'ang_steam', 'cof_cup'],
      'owned': ['pack_phrases'],
    });
  });
  tearDown(() => FxClock.manual.value = null);

  for (final (tag, size) in [('', const Size(960, 540)), ('_phone', _phone), ('_small', _small)]) {
    testWidgets('game_log$tag', (tester) async {
      final view = _view(_viewJson(log: _log(), over: true));
      await _shot(tester, 'log$tag', _Backdrop(after: (c) => showGameLog(c, view)), size: size);
    });

    testWidgets('game_log_scrolled$tag', (tester) async {
      // نزّل لآخر السجل (الجولة الأولى فيها ادعاءات متناقضة) وجرّب الأحداث النادرة
      final view = _view(_viewJson(log: [..._log(), ..._logRare()], over: true));
      final key = await _open(tester, _Backdrop(after: (c) => showGameLog(c, view)), size: size);
      await _save(tester, key, 'log_top$tag');
      // أول سحبة توسّع اللوحة، والثانية تمرر القائمة
      for (var i = 0; i < 2; i++) {
        await tester.drag(find.byType(ListView).last, const Offset(0, -2000));
        await _settle(tester, 3);
      }
      await _save(tester, key, 'log_bottom$tag');
    });

    testWidgets('game_log_empty$tag', (tester) async {
      final view = _view(_viewJson());
      await _shot(tester, 'log_empty$tag', _Backdrop(after: (c) => showGameLog(c, view)), size: size);
    });

    testWidgets('reactions$tag', (tester) async {
      final profile = Backend.instance.profile.value;
      Future<void> sheet(BuildContext c) => showModalBottomSheet<void>(
        context: c,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        constraints: BoxConstraints(maxHeight: size.height * .82, maxWidth: 760),
        builder: (context) => SizedBox(
          height: size.height * .82,
          child: ReactionsSheet(
            profile: profile,
            onText: (_) {},
            onSticker: (_) {},
            onFavorites: (_) {},
            onClearOpinion: () {},
          ),
        ),
      );
      final key = await _open(tester, _Backdrop(after: sheet), size: size);
      await _save(tester, key, 'reactions_stickers$tag');
      // تبويب الكلام
      await tester.tap(find.text('كلام'));
      await _settle(tester, 3);
      await _save(tester, key, 'reactions_text$tag');
      // أول باقة مقفلة
      final lock = find.byWidgetPredicate((w) => w is Gfx && w.name == 'lock').first;
      await tester.ensureVisible(lock);
      await tester.tap(lock);
      await _settle(tester, 3);
      await _save(tester, key, 'reactions_locked$tag');
    });

    testWidgets('reactions_chat$tag', (tester) async {
      // مثل الدردشة (chat_screen): الملصقات بس، بدون ارتفاع ثابت
      final profile = Backend.instance.profile.value;
      Future<void> sheet(BuildContext c) => showModalBottomSheet<void>(
        context: c,
        backgroundColor: AppColors.panel,
        isScrollControlled: true,
        constraints: BoxConstraints(maxHeight: size.height * .72),
        builder: (context) => ReactionsSheet(profile: profile, onSticker: (_) {}),
      );
      await _shot(tester, 'reactions_chat$tag', _Backdrop(after: sheet), size: size);
    });

    testWidgets('lies$tag', (tester) async {
      final view = _view(_viewJson(log: _liesLog(), over: true));
      final room = _room();
      final key = await _open(tester, _Backdrop(after: (c) => showLiesReveal(c, view, room)), size: size, frames: 8);
      await _save(tester, key, 'lies_mid$tag');
      await _settle(tester, 20);
      await _save(tester, key, 'lies_done$tag');
    });

    testWidgets('lies_empty$tag', (tester) async {
      final view = _view(_viewJson(over: true));
      await _shot(
        tester,
        'lies_empty$tag',
        _Backdrop(after: (c) => showLiesReveal(c, view, _room())),
        size: size,
        frames: 20,
      );
    });

    testWidgets('share$tag', (tester) async {
      final view = _view(_viewJson(log: _liesLog(), over: true));
      final room = _room();
      await _shot(tester, 'share_dialog$tag', _Backdrop(after: (c) => showShareCard(c, view, room)), size: size);
    });

    testWidgets('premium_ids$tag', (tester) async {
      // اقتراحات وعرض سعر تجريبي بدل ما نسأل السيرفر
      final ideas = [
        for (final (pid, price, tier) in [
          ('7777', 4000, 4),
          ('1234', 1500, 3),
          ('5050', 600, 2),
          ('48210', 250, 1),
          ('90909', 90, 0),
        ])
          PidQuote.fromJson({'pid': pid, 'price': price, 'tier': tier, 'available': true}),
      ];
      final quote = PidQuote.fromJson({'pid': '1234', 'price': 250, 'tier': 3, 'available': true});
      final key = await _open(
        tester,
        _Backdrop(
          after: (c) => showPremiumIds(c, sampleIdeas: ideas, sampleQuote: quote),
        ),
        size: size,
      );
      await _save(tester, key, 'pid_dialog$tag');
      // نافذة تأكيد الشراء
      final buy = find.text('اشتره بـ ٢٥٠').last;
      await tester.ensureVisible(buy);
      await tester.tap(buy);
      await _settle(tester, 3);
      await _save(tester, key, 'pid_confirm$tag');
    });

    testWidgets('premium_ids_offline$tag', (tester) async {
      // بدون سيرفر: تطلع رسالة تعذر الاقتراحات
      await _shot(tester, 'pid_offline$tag', _Backdrop(after: showPremiumIds), size: size);
    });
  }

  testWidgets('share_card_poster', (tester) async {
    for (final role in ['loyal', 'leader']) {
      final view = _view(_viewJson(log: _liesLog(), over: true, yourRole: role));
      await _shot(
        tester,
        'share_poster_$role',
        Scaffold(
          body: Center(
            child: ShareCard(view: view, room: _room()),
          ),
        ),
        size: const Size(400, 400),
      );
    }
  });

  testWidgets('badges', (tester) async {
    await _shot(
      tester,
      'badges',
      Scaffold(
        body: WoodWall(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (final t in [0, 1, 2, 3]) ...[
                      BadgeMedal(achievement: achievements.first, tier: t, size: 64),
                      const SizedBox(width: 12),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                BadgeStrip(badges: {for (final (i, a) in achievements.take(9).indexed) a.id: 1 + i % 3}, size: 44),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final p in [0, 250, 600, 1000, 1500]) RankChip(points: p, size: 26),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final t in [0, 1, 2, 3, 4]) PidBadge(pid: '${1000 + t * 4321}', tier: t, size: 18),
                    const PidBadge(pid: '77', tier: 4, size: 18, copy: false),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final t in rankTiers) ...[RankEmblem(tier: t, size: 48), const SizedBox(width: 8)],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  });
}
