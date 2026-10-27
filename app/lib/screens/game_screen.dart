import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/achievements.dart';
import '../models/game_view.dart';
import '../models/room.dart';
import '../models/table_tier.dart';
import '../models/tour.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/notes.dart';
import '../services/push.dart';
import '../services/music.dart';
import '../services/sfx.dart';
import '../services/telemetry.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/fx_sig.dart';
import '../widgets/game/card_hand.dart';
import '../widgets/game/game_log.dart';
import '../widgets/game/game_table.dart';
import '../widgets/game/lies_reveal.dart';
import '../widgets/game/overlays.dart';
import '../widgets/game/policy_card.dart';
import '../widgets/game/reactions_sheet.dart';
import '../widgets/game/scenes.dart';
import '../widgets/game/share_card.dart';
import '../widgets/game/tracks.dart';
import '../widgets/majlis.dart';
import '../widgets/player_card.dart';
import '../widgets/ui.dart';
import '../widgets/venues.dart';
import 'waiting_screen.dart';

const _winReasons = {
  'loyalPolicies': 'تمررت ٥ قرارات للأوفياء',
  'traitorPolicies': 'تمررت ٦ قرارات للخونة',
  'leaderElected': 'الزعيم انتُخب وزير',
  'leaderExecuted': 'الزعيم انطرد',
};

/// مشهد ينتظر دوره فوق الطاولة، ومعه جمل الراوي، ووش يصير لما يخلص.
typedef _Scene = ({GameScene scene, List<String> lines, VoidCallback? onEnd});

/// التوتر حسب قرارات الخونة: يبدأ من الثالث، وآخر قرار قبل فوزهم أقوى شي.
const _tensionByTraitorPolicies = [0.0, 0.0, 0.0, .35, .65, 1.0];

/// نفس engine/src/rules.ts → PHASE_SECONDS.
const _phaseSeconds = {
  Phase.nomination: 30,
  Phase.election: 25,
  Phase.presidentDiscard: 20,
  Phase.chancellorEnact: 20,
  Phase.vetoResponse: 15,
  Phase.power: 30,
};

/// لعبة الشرح: نصايح الراوي (نفس جمل tools/voice/lines.json).
const _tips = {
  'tut_nominate': 'أنت الرئيس هالجولة! اختر لك وزير من الطاولة… واحد تثق فيه.',
  'tut_vote': 'صوّت على الحكومة: موافق يعني تبيهم، ورافض يعني ما تثق فيهم.',
  'tut_discard': 'وصلتك ٣ كروت. ارمِ واحد بالسر، والباقي يروح للوزير يختار منه.',
  'tut_enacted': 'شف اللوحة فوق: هنا تنعد القرارات. الأزرق للأوفياء، والأحمر للخونة.',
  'tut_claim': 'الحين قول للكل وش وصلك. تقدر تقول الصدق… أو تكذب عليهم!',
  'tut_chat': 'تبي تتهم أحد أو تدافع عن نفسك؟ اضغط زر التفاعل، واختار ملصق أو كلام.',
  'tut_power': 'القرار الأحمر عطى الرئيس قدرة! انتبه وش بيسوي فيها.',
};

/// نصايح الخطوات تبقى لين تسويها، ونصايح المعلومات تختفي بعد شوي.
const _actionTips = {'tut_nominate', 'tut_vote', 'tut_discard', 'tut_claim'};

/// شاشة الطاولة: كل اللعب يصير هنا.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.code, this.watching});

  final String code;

  /// تتفرج على لعبة صاحبك: هذا هو (يقعد تحت). بدون حركات ولا أسرار.
  final String? watching;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _backend = Backend.instance;

  /// متفرج (صاحب أحد اللاعبين).
  bool get _spectating => widget.watching != null;
  late final StreamSubscription<Map<String, dynamic>?> _viewSub;
  late final StreamSubscription<Room?> _roomSub;
  late final Timer _ticker;
  late final Notes _notes = Notes(widget.code)..load();

  GameView? _view;
  Room? _room;

  /// وصل أول خبر عن الروم (ولو ما لقيناه)، عشان نعرف مكان الطاولة قبل ما نرسمها.
  bool _roomLoaded = false;

  /// «العب مرة ثانية»: الروم الجديد (لو أحد سواه) ومين دخله، وهل ننتظر السيرفر.
  StreamSubscription<Room?>? _nextSub;
  String? _watchingNext;
  Set<String> _nextReady = const {};
  bool _rematching = false;
  bool _roleShown = false;
  int _seenInvestigations = 0;

  /// حركات أرسلناها وننتظر السيرفر يطبقها (مفتاح الدور، أو الادعاء، أو 'seer')، ومعها كلمة تطلع لك مكان الأزرار.
  /// الأزرار تختفي من أول ضغطة عشان ما تحس بتأخير، ولو رفضها السيرفر ترجع.
  final _sent = <String, String>{};

  /// الكروت اللي وصلتك في كل جولة (٣ للرئيس، ٢ للوزير)، عشان نعلّم لك الصدق وقت الادعاء.
  final _seenHands = <int, List<Policy>>{};

  /// الادعاء اللي قلت له «بعدين» (يبقى له زر صغير يرجّعه)، واللي فتحته من الزر.
  String? _claimLater;
  String? _claimOpen;
  int? _seenLog;
  bool _wasMyTurn = false;
  bool _endSoundPlayed = false;

  /// شفنا اللعبة وهي شغالة (مو بس نتيجتها).
  bool _live = false;

  /// بعد اللعبة: النتيجة كاملة مفتوحة فوق الطاولة (وإلا الطاولة تبقى للسوالف والملخص في نصها).
  bool _resultsOpen = false;
  bool _leftTable = false;

  /// مشاهد تنتظر دورها فوق الطاولة (كشف التصويت، الختم، الطرد، كشف الأقنعة).
  final List<_Scene> _scenes = [];

  /// المطرودين: متى بدأ حزنهم على كراسيهم، واللي لسا مشهد طردهم ما خلص.
  final _deaths = <String, DateTime>{};
  final _hiddenDeaths = <String>{};

  /// رد ينتظر تختار له لاعب (مثل أشك في…).
  TextReaction? _pendingReaction;

  /// تختار لاعب تشيل رأيك فيه (أشك أو أثق).
  bool _clearPick = false;

  /// العرّاف ضغط "اكشف" وينتظر يختار لاعب.
  bool _seerPicking = false;
  String? _seerSeen;

  /// لعبة الشرح: نصيحة الراوي الظاهرة الحين، واللي انقالت (كل وحدة مرة).
  String? _tip;
  final _tipsSaid = <String>{};
  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();
    if (!_spectating) Push.setCurrentGame(widget.code);
    Music.play('game');
    _viewSub = (_spectating ? _backend.watchSpectator(widget.code) : _backend.watchView(widget.code)).listen((data) {
      if (data == null || !mounted) return;
      final view = GameView.fromJson(data, perspective: widget.watching);
      final before = _view;
      setState(() {
        _view = view;
        // اللي طبقه السيرفر (أو راح وقته) ما ننتظره بعد.
        final turn = _turnKey(view), claim = _claimKey(view);
        _sent.removeWhere(
          (k, _) => k != turn && k != claim && !(k == 'seer' && view.seerReady) && !(k == 'spy' && view.spyReady),
        );
        final mine =
            (view.phase == Phase.presidentDiscard && view.amPresident) ||
            (view.phase == Phase.chancellorEnact && view.amNominee);
        if (mine && view.hand.isNotEmpty) _seenHands[view.round] = view.hand;
      });
      _moments(before, view);
      _afterUpdate(view);
      // الجاسوس شاف الكومة: نوريه الكرت.
      if (before != null && before.spySaw == null && view.spySaw != null) _showSpySaw(view.spySaw!.card);
    }, onError: (Object e) => debugPrint('view listener: $e'));
    _roomSub = _backend.watchRoom(widget.code).listen((room) {
      if (!mounted) return;
      final before = _room;
      setState(() {
        _room = room;
        _roomLoaded = true;
      });
      if (before != null && room != null) _announceLeavers(before, room);
      if (room?.next case final next? when next != _watchingNext) _watchNext(next);
    }, onError: (Object e) => debugPrint('room listener: $e'));
    // كل ثانية: نحدّث العداد وفقاعات الردود، ونطلب من السيرفر يكمّل لو خلص الوقت.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _checkTimeout();
      _tick();
      if (_view case final v?) _coach(v);
    });
  }

  /// اللي يطلع يبان للكل: وقت اللعبة يكمل عنه بوت، وبعدها يطلع من الطاولة.
  void _announceLeavers(Room before, Room room) {
    for (final p in room.players) {
      if (p.uid == _backend.uid || p.uid.startsWith('bot_')) continue;
      if (room.gone.contains(p.uid) && !before.gone.contains(p.uid)) {
        _toast('${p.name} طلع من الطاولة');
      } else if (p.bot && !(before.player(p.uid)?.bot ?? true)) {
        _toast('${p.name} طلع من اللعبة، ويكمل عنه بوت');
      }
    }
  }

  /// اللحظات الخاصة للإطارات الأسطورية: لما تبدأ اللعبة (الكل)، ولما أحد يصير رئيس، والفايزين بالنهاية.
  void _moments(GameView? before, GameView v) {
    if (before == null) {
      for (final (i, p) in v.players.indexed) {
        Future.delayed(Duration(milliseconds: 600 + i * 250), () => Moments.trigger(p.id));
      }
      return;
    }
    if (v.presidentId != before.presidentId) Moments.trigger(v.presidentId);
    if (v.phase == Phase.gameOver && before.phase != Phase.gameOver && v.tutorial) _resultsOpen = true;
    if (v.phase == Phase.gameOver && before.phase != Phase.gameOver && v.winnerLoyal != null) {
      for (final p in v.players) {
        final role = p.knownRole;
        if (role != null && (role == Role.loyal) == v.winnerLoyal) Moments.trigger(p.id);
      }
    }
  }

  DateTime? _lastTimeoutCall;
  Timer? _timeoutTimer;

  /// لو خلص وقت الدور، أي لاعب في الطاولة يطلب من السيرفر يكمّل. نوزع الطلبات على اللاعبين
  /// عشان ما يطلبون كلهم بنفس اللحظة، والسيرفر ينفذ مرة وحدة بس.
  void _checkTimeout() {
    final v = _view;
    final deadline = v?.deadline;
    // المتفرج ما يطلب من السيرفر (اللاعبين يطلبون).
    if (v == null || deadline == null || v.phase == Phase.gameOver || _spectating) return;
    final now = DateTime.now();
    if (now.isBefore(deadline.add(_timeoutDelay(v)))) return;
    if (_lastTimeoutCall != null && now.difference(_lastTimeoutCall!) < const Duration(seconds: 2)) return;
    _lastTimeoutCall = now;
    _backend.timeout(widget.code).catchError((_) => false);
  }

  /// نطلب بالضبط لما يجي وقتنا (مو مع عداد الثانية)، عشان دور البوت ما يتأخر.
  void _scheduleTimeout(GameView v) {
    _timeoutTimer?.cancel();
    final deadline = v.deadline;
    if (deadline == null || v.phase == Phase.gameOver || _spectating) return;
    final wait = deadline.add(_timeoutDelay(v)).difference(DateTime.now());
    _timeoutTimer = Timer(wait.isNegative ? Duration.zero : wait + const Duration(milliseconds: 30), _checkTimeout);
  }

  /// متى نطلب بعد آخر الوقت: البوت السيرفر حاسب وقت تفكيره فنطلب على طول، واللاعب نعطيه ثانية زيادة.
  /// وأول لاعب (مو بوت) في الطاولة يطلب أول، والباقي ورا بعض لو ما مشى.
  Duration _timeoutDelay(GameView v) {
    final humans = [
      for (final p in v.players)
        if (!_botPlays(v, p.id)) p.id,
    ];
    final order = humans.indexOf(v.you).clamp(0, 99);
    return Duration(milliseconds: (_botTurn(v) ? 150 : 1000) + 600 * order);
  }

  static bool _botPlays(GameView v, String id) => id.startsWith('bot_') || v.autopilot.contains(id);

  /// الدور على بوتات بس.
  static bool _botTurn(GameView v) => switch (v.phase) {
    Phase.election => v.players.where((p) => p.alive && !p.hasVoted).every((p) => _botPlays(v, p.id)),
    Phase.chancellorEnact => v.nomineeId != null && _botPlays(v, v.nomineeId!),
    Phase.gameOver => false,
    _ => _botPlays(v, v.presidentId),
  };

  /// الراوي ينبهك مرة وحدة لما يبقى ٥ ثواني على دورك.
  DateTime? _hurriedFor;
  void _tick() {
    final v = _view;
    final deadline = v?.deadline;
    if (v == null || deadline == null || !_isMyTurn(v) || _hurriedFor == deadline) return;
    final left = deadline.difference(DateTime.now()).inSeconds;
    if (left >= 0 && left <= 5) {
      _hurriedFor = deadline;
      Sfx.say('hurry');
    }
  }

  Phase? _lastPhase;

  /// الراوي يعلن بداية التصويت أو القدرة للكل، ويقول لك وش تسوي لما يجي دورك.
  void _announce(GameView v, bool myTurnStarted) {
    final changed = v.phase != _lastPhase;
    _lastPhase = v.phase;
    // لعبة الشرح: أول مرة بكل خطوة، نصيحة الراوي تغني عن جملته العادية.
    final tip = _tipFor(v);
    if (tip != null && tip != 'tut_power' && !_tipsSaid.contains(tip)) return;
    if (changed && v.phase == Phase.election) return Sfx.say('vote');
    if (changed && v.phase == Phase.power) {
      return Sfx.say(switch (v.pendingPower) {
        Power.investigate => 'power_investigate',
        Power.peek => 'power_peek',
        Power.specialElection => 'power_special',
        _ => 'power_execute',
      });
    }
    if (!myTurnStarted) return;
    Sfx.say(switch (v.phase) {
      Phase.nomination => 'president',
      Phase.presidentDiscard => 'discard',
      Phase.chancellorEnact => 'enact',
      Phase.vetoResponse => 'veto',
      _ => 'your_turn',
    });
  }

  bool _isMyTurn(GameView v) {
    if (v.spectator || !v.me.alive) return false;
    return switch (v.phase) {
      Phase.nomination || Phase.presidentDiscard || Phase.vetoResponse || Phase.power => v.amPresident,
      Phase.chancellorEnact => v.amNominee,
      Phase.election => !v.me.hasVoted,
      Phase.gameOver => false,
    };
  }

  /// وش نصيحة الراوي اللي تناسب الحين في لعبة الشرح.
  String? _tipFor(GameView v) {
    if (!v.tutorial || !_introDone || v.phase == Phase.gameOver) return null;
    if (v.phase == Phase.power) return 'tut_power';
    if (_isMyTurn(v)) {
      return switch (v.phase) {
        Phase.nomination => 'tut_nominate',
        Phase.election => 'tut_vote',
        Phase.presidentDiscard => 'tut_discard',
        _ => null,
      };
    }
    final enacted = v.loyalPolicies + v.traitorPolicies > 0;
    if (enacted && !_tipsSaid.contains('tut_enacted')) return 'tut_enacted';
    if (_claimPending(v)) return 'tut_claim';
    return enacted ? 'tut_chat' : null;
  }

  /// يطلع نصيحة جديدة (مع صوتها) لما يجي وقتها، ويشيل نصيحة الخطوة لما تسويها.
  void _coach(GameView v) {
    final tip = _tipFor(v);
    final shown = _tip;
    if (shown != null && _actionTips.contains(shown) && tip != shown) {
      setState(() => _tip = null);
    } else if (shown != null) {
      return;
    }
    // ننتظر المشاهد (كشف التصويت والختم) تخلص، عشان النصيحة تنشاف.
    if (tip == null || _tipsSaid.contains(tip) || _scenes.isNotEmpty) return;
    _tipsSaid.add(tip);
    setState(() => _tip = tip);
    Sfx.say(tip);
    _tipTimer?.cancel();
    if (!_actionTips.contains(tip)) _tipTimer = Timer(const Duration(seconds: 10), _closeTip);
  }

  void _closeTip() {
    _tipTimer?.cancel();
    if (mounted) setState(() => _tip = null);
  }

  @override
  void dispose() {
    // طلعت من الطاولة بعد ما خلصت اللعبة (بالزر أو بالرجوع): الباقين يشوفون إنك طلعت.
    if (_spectating) {
      _backend.stopWatching(widget.code).ignore();
    } else if (_view?.phase == Phase.gameOver && !_leftTable) {
      _backend.leaveGame(widget.code).ignore();
    }
    _tipTimer?.cancel();
    _timeoutTimer?.cancel();
    if (!_spectating) Push.setCurrentGame(null);
    Music.play('menu');
    _viewSub.cancel();
    _roomSub.cancel();
    _nextSub?.cancel();
    _ticker.cancel();
    _notes.dispose();
    super.dispose();
  }

  /// أحد ضغط «العب مرة ثانية»: نتابع الروم الجديد عشان نعلّم على اللي دخلوه، ونقولك.
  void _watchNext(String next) {
    _watchingNext = next;
    _nextSub?.cancel();
    var told = false;
    _nextSub = _backend.watchRoom(next).listen((r) {
      if (!mounted || r == null) return;
      setState(() => _nextReady = {for (final p in r.players) p.uid});
      if (!told && r.hostId != _backend.uid) {
        told = true;
        _toast('${r.player(r.hostId)?.name ?? 'واحد'} يبي يلعب مرة ثانية! اضغط «العب مرة ثانية» وتدخل معه');
      }
    }, onError: (Object e) => debugPrint('next room listener: $e'));
  }

  /// «العب مرة ثانية»: روم جديد بنفس الإعدادات والبوتات (أو تدخل اللي سواه غيرك).
  Future<void> _rematch() async {
    if (_rematching) return;
    setState(() => _rematching = true);
    try {
      final r = await _backend.rematch(widget.code);
      if (!mounted) return;
      final room = _room;
      // الباقين يشوفون عند كرسيك إنك رحت للجولة الجاية.
      _leftTable = true;
      _backend.leaveGame(widget.code).ignore();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => r.started
              ? GameScreen(code: r.code)
              : WaitingScreen(tier: tierById(room?.tierId), playerCount: room?.maxPlayers ?? 5, code: r.code),
        ),
      );
    } on BackendException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _rematching = false);
    }
  }

  void _afterUpdate(GameView view) {
    // المتفرج: يشوف المشاهد بس (ما له دور ولا حركات).
    if (_spectating) {
      if (view.phase != Phase.gameOver) _live = true;
      if (!_roleShown) {
        _roleShown = true;
        _introDone = true;
        _seenLog = view.log.length;
      }
      _queueScenes(view);
      return;
    }
    _scheduleTimeout(view);
    if (view.autopilot.contains(view.you) && view.phase != Phase.gameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _kicked());
    }
    if (view.seerSees != null && _seerSeen == null && _roleShown) {
      final target = view.player(view.seerSees!);
      final traitor = target.knownRole != Role.loyal;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _alert(
          'كشف العرّاف',
          '${target.name} من ${traitor ? 'الخونة' : 'الأوفياء'}',
          'محد يدري إنك كشفته. استخدمها بذكاء',
          'seer',
          traitor,
        ),
      );
    }
    _seerSeen = view.seerSees;
    if (view.phase != Phase.gameOver) _live = true;
    if (!_roleShown) {
      _roleShown = true;
      _seenInvestigations = view.investigations.length;
      _seenLog = view.log.length;
      if (view.round == 1 && view.log.isEmpty) {
        Telemetry.gameStart(
          players: view.players.length,
          tutorial: view.tutorial,
          bots: view.players.any((p) => p.id.startsWith('bot_')),
        );
      }
      // الترحيب بس في بداية اللعبة (مو لو رجعت لها في النص)، وبعده جملة دورك لما تنقلب البطاقة.
      if (view.round == 1 && view.log.isEmpty) Sfx.say('intro');
      WidgetsBinding.instance.addPostFrameCallback((_) => _showRole());
    }
    _queueScenes(view);
    _maybeDanger();
    if (view.investigations.length > _seenInvestigations) {
      final result = view.investigations.last;
      _seenInvestigations = view.investigations.length;
      final name = view.player(result.target).name;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _alert(
          'نتيجة التحقيق',
          '$name من ${result.traitor ? 'الخونة' : 'الأوفياء'}',
          'هذي المعلومة لك بس. تقدر تقولها أو تكذب فيها',
          'search',
          result.traitor,
        ),
      );
    }
    final myTurn = _isMyTurn(view);
    if (myTurn && !_wasMyTurn) HapticFeedback.mediumImpact();
    // أول ما تدخل: الترحيب وبطاقة دورك أول، وإعلان الدور يجي بعد ما تقفل البطاقة.
    if (_introDone) _announce(view, myTurn && !_wasMyTurn);
    _wasMyTurn = myTurn;
    if (view.phase == Phase.gameOver && !_endSoundPlayed) {
      _endSoundPlayed = true;
      // نسجّل نهاية اللعبة بس لو حضرناها (مو لو فتحنا لعبة خلصت من قبل).
      if (_live) {
        final won = (view.yourRole == Role.loyal) == view.winnerLoyal && !view.autopilot.contains(view.you);
        Telemetry.gameEnd(won: won, reason: view.winReason ?? '', rounds: view.round, tutorial: view.tutorial);
        if (view.tutorial) Telemetry.tutorialComplete();
      }
      // حضرناها: الراوي يقول الفايز مع مشهد كشف الأقنعة. وإلا (فتحناها وهي خالصة) يقوله على طول.
      if (!_live) {
        Sfx.say((view.winnerLoyal ?? false) ? 'win_loyal' : 'win_traitor');
        if (view.tutorial) Sfx.say('tut_done');
      }
    }
    _coach(view);
  }

  /// أحداث جديدة في السجل تطلع كمشاهد قصيرة فوق الطاولة.
  void _queueScenes(GameView v) {
    final from = _seenLog ?? v.log.length;
    _seenLog = v.log.length;
    final wasEmpty = _scenes.isEmpty;
    for (final e in v.log.skip(from)) {
      final d = e.data;
      switch (e.type) {
        case 'voteResult':
          _scenes.add((
            scene: VoteScene(
              view: v,
              votes: Map<String, bool>.from(d['votes'] as Map),
              passed: d['passed'] == true,
              cancelledBy: d['cancelledBy'] as String?,
              weights: {
                for (final MapEntry(:key, :value) in ((d['weights'] as Map?) ?? const {}).entries)
                  key as String: (value as num).toInt(),
              },
            ),
            lines: [d['passed'] == true ? 'gov_passed' : 'gov_failed'],
            onEnd: null,
          ));
        case 'enacted':
          final gov = d['government'] as Map?;
          _scenes.add((
            scene: EnactScene(
              view: v,
              loyal: d['policy'] == 'L',
              chaos: d['chaos'] == true,
              from: gov?['chancellor'] as String?,
              skin: _skin,
            ),
            lines: [d['chaos'] == true ? 'chaos' : (d['policy'] == 'L' ? 'enact_loyal' : 'enact_traitor')],
            onEnd: null,
          ));
        case 'executed' || 'guarded':
          final id = d['target'] as String;
          final executed = e.type == 'executed';
          // كرسيه يبان عادي لين يخلص المشهد، وبعدها يحزن ويتغطى.
          if (executed) _hiddenDeaths.add(id);
          _scenes.add((
            scene: DeathScene(name: v.nameOf(id), avatar: _room?.player(id)?.avatar ?? 'masked', guarded: !executed),
            lines: [executed ? 'executed' : 'guarded'],
            onEnd: executed
                ? () {
                    _hiddenDeaths.remove(id);
                    _deaths[id] = DateTime.now();
                  }
                : null,
          ));
        case 'gameOver':
          _scenes.add((
            scene: UnmaskScene(view: v, room: _room),
            lines: [(v.winnerLoyal ?? false) ? 'win_loyal' : 'win_traitor', if (v.tutorial) 'tut_done'],
            // بعد كشف الأقنعة: النتيجة كاملة (ومعها «العب مرة ثانية» و«مين كذب؟» و«شارك»).
            onEnd: _spectating ? null : () => _resultsOpen = true,
          ));
      }
    }
    if (wasEmpty && _scenes.isNotEmpty) _scenes.first.lines.forEach(Sfx.say);
  }

  void _nextScene() {
    if (!mounted || _scenes.isEmpty) return;
    setState(() => _scenes.removeAt(0).onEnd?.call());
    if (_scenes.isNotEmpty) _scenes.first.lines.forEach(Sfx.say);
    _maybeDanger();
  }

  /// تنبيه الزعيم الكبير: مرة وحدة أول ما يصير عند الخونة ٣ قرارات، بعد ما يخلص مشهد الختم.
  void _maybeDanger() {
    final v = _view;
    if (v == null || _dangerShown || !_introDone || _scenes.isNotEmpty || _spectating) return;
    if (v.traitorPolicies < 3 || v.phase == Phase.gameOver) return;
    _dangerShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showLeaderDanger(v.yourRole));
  }

  /// مفتاح الدور الحالي (نفس turnKey في السيرفر): يتغير لما يجي دور جديد، والتصويت الواحد ما يغيره.
  static String _turnKey(GameView v) => '${v.round}:${v.phase.name}:${v.pendingPower?.name ?? ''}:${v.canVeto}';

  /// الادعاء يخص آخر حكومة مررت قرار.
  static String _claimKey(GameView v) {
    for (final e in v.log.reversed) {
      if (e.type == 'enacted' && e.data['government'] != null) return 'claim:${e.round}';
    }
    return 'claim';
  }

  /// يرسل حركتك. الأزرار تختفي على طول وتطلع [note] مكانها لين يرد السيرفر، ولو رفضها ترجع مع السبب.
  /// [key] للحركات اللي مو من دورك (الادعاء وكشف العرّاف)، وإلا مفتاح الدور الحالي.
  Future<void> _act(Map<String, dynamic> action, {String note = '', String? key}) async {
    final v = _view;
    if (v == null) return;
    final k = key ?? _turnKey(v);
    if (_sent.containsKey(k)) return;
    HapticFeedback.selectionClick();
    setState(() => _sent[k] = note);
    try {
      await _backend.act(widget.code, action);
    } on BackendException catch (e) {
      if (mounted) setState(() => _sent.remove(k));
      _toast(e.message);
    }
  }

  /// أرسلت حركتك لهالدور وتنتظر.
  bool _waiting(GameView v) => _sent.containsKey(_turnKey(v));

  /// رأيي الحالي في لاعب: true أشك، false أثق، null ما عندي رأي.
  bool? _myOpinion(String target) => _room?.opinions[_backend.uid]?[target];

  Future<void> _react(String kind, {String? target}) async {
    setState(() {
      _pendingReaction = null;
      _clearPick = false;
    });
    try {
      // نفس الرأي مرة ثانية على نفس اللاعب = تشيله (غيّرت رأيك).
      final same =
          target != null &&
          ((kind == 'suspect' && _myOpinion(target) == true) || (kind == 'trust' && _myOpinion(target) == false));
      if (same) {
        await _backend.clearOpinion(widget.code, target);
        _toast('شلت رأيك');
        return;
      }
      await _backend.react(widget.code, kind, target: target);
    } on BackendException catch (e) {
      _toast(e.message);
    }
  }

  /// يحفظ المفضلة (الصف جنب زر التفاعل يتحدث لما يرجع الملف من السيرفر).
  Future<void> _saveFavorites(List<String> ids) async {
    try {
      await _backend.setFavorites(ids);
    } on BackendException catch (e) {
      _toast(e.message);
    }
  }

  void _toast(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _alert(String title, String body, [String? note, String? icon, bool? traitor]) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Gfx(icon, size: 34), const SizedBox(width: 8)],
            Text(title, textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (traitor != null) ...[Seal(loyal: !traitor, size: 72), const SizedBox(height: 6)],
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: kufi, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            if (note != null) ...[
              const SizedBox(height: 10),
              Text(
                note,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ],
        ),
        actions: [GameButton(label: 'تمام', height: 46, fontSize: 16, onPressed: () => Navigator.pop(context))],
      ),
    );
  }

  bool _introDone = false;

  /// تنبيه "الزعيم لو صار وزير" الكبير يطلع مرة وحدة.
  bool _dangerShown = false;

  /// أول ما يصير عند الخونة ٣ قرارات: تنبيه كبير للكل، كل واحد بكلام يناسب دوره.
  Future<void> _showLeaderDanger(Role role) async {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'تنبيه',
      barrierColor: Colors.black.withValues(alpha: .75),
      transitionDuration: const Duration(milliseconds: 450),
      transitionBuilder: (context, a, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: a, child: child),
      ),
      pageBuilder: (context, _, _) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 520,
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF5A0F18), Color(0xFF22060B)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.traitor, width: 2),
              boxShadow: [BoxShadow(color: AppColors.traitor.withValues(alpha: .55), blurRadius: 40)],
            ),
            child: Row(
              children: [
                const LeaderSeal(size: 120),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'انتبهوا! الخونة عندهم ٣ قرارات',
                        style: TextStyle(fontFamily: kufi, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'من الحين: لو زعيم الخونة صار وزير وانتخبتوا حكومته، يفوزون الخونة على طول.',
                        style: TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(switch (role) {
                        Role.loyal => 'دقّقوا في كل وزير قبل لا توافقون.',
                        Role.traitor => 'فرصتكم: رشّحوا الزعيم وزير، وصوّتوا له.',
                        Role.leader => 'أنت الزعيم: لو صرت وزير، تفوزون!',
                      }, style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: GameButton(
                          label: 'فهمت',
                          tone: ButtonTone.red,
                          height: 42,
                          fontSize: 16,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRole() {
    final view = _view;
    if (view == null || !mounted) return;
    showRoleReveal(context, view, _room).then((_) {
      if (_introDone || !mounted) return;
      _introDone = true;
      final v = _view;
      if (v != null) {
        _lastPhase = null;
        _announce(v, _isMyTurn(v));
      }
    });
  }

  /// بطاقة اللاعب (ضغطة على صورته): ملفه، وملاحظتك الخاصة عليه، والحظر والبلاغ.
  void _editNote(String playerId) {
    final v = _view;
    if (v == null) return;
    final rp = _room?.player(playerId);
    showPlayerCard(
      context,
      uid: playerId,
      name: v.player(playerId).name,
      avatar: rp?.avatar ?? 'masked',
      frame: rp?.frame,
      // اللي طلع ويلعب عنه بوت يبقى لاعب حقيقي (تقدر تشوف ملفه وتبلّغ عنه).
      bot: playerId.startsWith('bot_'),
      code: widget.code,
      note: _notes.of(playerId),
      onNote: playerId == v.you ? null : (m) => _notes.set(playerId, m),
    );
  }

  /// ضغطة على لاعب ما ينفع تختاره: لو هو دورك تختار نقول لك ليش، وإلا تنفتح بطاقته.
  void _tapPlayer(GameView v, String id) {
    final why = _whyNot(v, id);
    if (why == null) return _editNote(id);
    _toast(why);
  }

  /// ليش هاللاعب ما ينفع تختاره الحين (وقت ترشيحك أو قدرتك بس).
  String? _whyNot(GameView v, String id) {
    if (!v.amPresident || !v.me.alive || _pendingReaction != null || _seerPicking || _clearPick) return null;
    final nominating = v.phase == Phase.nomination;
    final power =
        v.phase == Phase.power &&
        (v.pendingPower == Power.investigate ||
            v.pendingPower == Power.specialElection ||
            v.pendingPower == Power.execute);
    if (!nominating && !power || _waiting(v)) return null;
    final p = v.player(id);
    if (id == v.you) return nominating ? 'ما تقدر ترشّح نفسك، اختر لاعب ثاني' : 'اختر لاعب غيرك';
    if (!p.alive) return '${p.name} مطرود من المجلس';
    if (nominating && id == v.lastChancellor) {
      return '${p.name} كان الوزير في الحكومة اللي قبل، وما يصير وزير مرتين ورا بعض. اختر غيره';
    }
    if (nominating && id == v.lastPresident) return '${p.name} كان الرئيس في الحكومة اللي قبل، فما يصير وزير هالجولة';
    if (v.pendingPower == Power.investigate && v.investigations.any((i) => i.target == id)) {
      return 'حققت مع ${p.name} قبل، اختر غيره';
    }
    return null;
  }

  /// الردود السريعة: زر واحد يفتح اللوحة (كلام وملصقات)، بدال الشات.
  void _openReactions() {
    final over = _view?.phase == Phase.gameOver;
    final hasOpinion = !over && (_room?.opinions[_backend.uid] ?? const {}).isNotEmpty;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .82, maxWidth: 760),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: ReactionsSheet(
          profile: _backend.profile.value,
          over: over,
          onText: (r) {
            Navigator.pop(context);
            r.target ? setState(() => _pendingReaction = r) : _react(r.id);
          },
          onSticker: (st) {
            Navigator.pop(context);
            _react(st.id);
          },
          onFavorites: _saveFavorites,
          onClearOpinion: hasOpinion
              ? () {
                  Navigator.pop(context);
                  setState(() {
                    _pendingReaction = null;
                    _clearPick = true;
                  });
                }
              : null,
        ),
      ),
    );
  }

  /// اللاعبين اللي ينفع تختارهم من الطاولة الحين، ووش يصير لما تختار.
  (Set<String>, void Function(String)?) _selection(GameView v) {
    if (_clearPick) {
      return (
        (_room?.opinions[_backend.uid] ?? const {}).keys.toSet(),
        (id) async {
          setState(() => _clearPick = false);
          try {
            await _backend.clearOpinion(widget.code, id);
            _toast('شلت رأيك');
          } on BackendException catch (e) {
            _toast(e.message);
          }
        },
      );
    }
    if (_seerPicking) {
      return (
        {
          for (final p in v.alive)
            if (p.id != v.you) p.id,
        },
        (id) {
          setState(() => _seerPicking = false);
          _confirm(v, 'تكشف فريق', id, {'type': 'seerReveal', 'target': id}, key: 'seer');
        },
      );
    }
    final pending = _pendingReaction;
    if (pending != null) {
      return (
        {
          for (final p in v.players)
            if (p.id != v.you) p.id,
        },
        (id) => _react(pending.id, target: id),
      );
    }
    if (_waiting(v) || !v.amPresident) return (const {}, null);
    final others = {
      for (final p in v.alive)
        if (p.id != v.you) p.id,
    };
    switch ((v.phase, v.pendingPower)) {
      case (Phase.nomination, _):
        return (
          {for (final p in v.eligibleChancellors) p.id},
          (id) => _act({'type': 'nominate', 'chancellor': id}, note: 'رشّحت ${v.player(id).name} وزير'),
        );
      case (Phase.power, Power.investigate):
        final done = {for (final i in v.investigations) i.target};
        return (others.difference(done), (id) => _confirm(v, 'تحقق مع', id, {'type': 'investigate', 'target': id}));
      case (Phase.power, Power.specialElection):
        return (others, (id) => _confirm(v, 'تختار رئيس', id, {'type': 'specialElection', 'target': id}));
      case (Phase.power, Power.execute):
        return (others, (id) => _confirm(v, 'تطرد', id, {'type': 'execute', 'target': id}));
      default:
        return (const {}, null);
    }
  }

  /// عندك ادعاء ما قلته (كنت الرئيس أو الوزير في آخر حكومة مررت قرار).
  bool _canClaim(GameView v) => v.claimCount != null && v.phase != Phase.gameOver && !_sent.containsKey(_claimKey(v));

  /// نافذة الادعاء: تطلع لحالها بعد المشاهد لو ما عليك حركة (إلا لو قلت «بعدين»)، أو لما تفتحها من زرها.
  bool _claimPending(GameView v) {
    if (!_canClaim(v) || _scenes.isNotEmpty || _pendingReaction != null || _seerPicking || _clearPick) return false;
    final key = _claimKey(v);
    return _claimOpen == key || (_claimLater != key && !_isMyTurn(v));
  }

  /// الكروت اللي وصلتك فعلاً في الحكومة اللي تدّعي عنها: من السيرفر (يعرفها أكيد، حتى لو فتحت اللعبة
  /// من جديد)، وإلا اللي شفناها على هالجهاز (سيرفر قديم).
  List<Policy>? _truth(GameView v) {
    if (v.claimTruth case final truth? when truth.length == v.claimCount) return truth;
    final round = int.tryParse(_claimKey(v).split(':').last);
    final hand = round == null ? null : _seenHands[round];
    return hand != null && hand.length == v.claimCount ? hand : null;
  }

  void _claim(GameView v, List<Policy> policies) {
    final key = _claimKey(v);
    _claimOpen = null;
    _act({
      'type': 'claim',
      'policies': [for (final p in policies) p.code],
    }, key: key);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('قلت للكل إنه وصلك: ${_claimLabel(policies)}'), duration: const Duration(seconds: 2)),
        );
    }
  }

  Future<void> _confirm(GameView v, String verb, String id, Map<String, dynamic> action, {String? key}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('متأكد $verb ${v.player(id).name}؟', textAlign: TextAlign.center),
        actions: [
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: 'لا',
                  tone: ButtonTone.ghost,
                  height: 46,
                  fontSize: 16,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  label: 'إيه',
                  height: 46,
                  fontSize: 16,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok == true) await _act(action, key: key, note: '$verb ${v.player(id).name}…');
  }

  @override
  Widget build(BuildContext context) {
    final v = _view;
    if (v == null || !_roomLoaded) {
      return const NightScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }
    // وقت المشهد الضغطة تكمّله (تتخطاه)، فما نعلّم على أحد تحته عشان ما تحس إنك اخترت وما صار شي.
    final (selectable, onSelect) = _scenes.isEmpty && !_spectating ? _selection(v) : (const <String>{}, null);
    final (roleName, _, roleColor, _) = roleInfo[v.yourRole]!;
    final special = v.yourSpecial;

    final pickHint = _clearPick
        ? 'اختر اللاعب اللي تبي تشيل رأيك فيه'
        : _seerPicking
        ? 'اختر لاعب تكشف فريقه (سراً)'
        : _pendingReaction == null
        ? null
        : '${_pendingReaction!.label} اختر لاعب';
    final over = v.phase == Phase.gameOver;
    // الإضاءة تحمر وترمش كل ما قرّبوا الخونة من الفوز.
    final tension = over ? 0.0 : _tensionByTraitorPolicies[v.traitorPolicies.clamp(0, 5)];

    return PopScope(
      canPop: over || _leaving || _spectating,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF110905),
        body: Stack(
          children: [
            // المكان ورا الطاولة: كل طاولة لها مكانها (البر، المدينة، القصر…)، والخاص في المجلس.
            Positioned.fill(
              child: MajlisRoom(tension: tension, venue: _room?.tour != null ? Venue.kings : venueOf(_room?.tierId)),
            ),
            SafeArea(
              child: Stack(
                children: [
                  // الطاولة على الشاشة كلها، والباقي يطفو في الزوايا. القرار الأحمر يهزها.
                  Positioned.fill(
                    child: ValueListenableBuilder(
                      valueListenable: sceneShake,
                      builder: (context, shake, child) {
                        if (shake == 0) return child!;
                        final ms = DateTime.now().millisecondsSinceEpoch / 1000;
                        return Transform.translate(
                          offset: Offset(math.sin(ms * 83) * 10, math.cos(ms * 61) * 7) * shake,
                          child: child,
                        );
                      },
                      child: Padding(
                        padding: tablePadding,
                        child: GameTable(
                          view: v,
                          room: _room,
                          notes: _notes,
                          selectable: selectable,
                          onSelect: onSelect,
                          onNote: _editNote,
                          onTapPlayer: (id) => _tapPlayer(v, id),
                          spotlight: v.phase == Phase.election && pickHint == null
                              ? {v.presidentId, ?v.nomineeId}
                              : null,
                          deaths: _deaths,
                          hiddenDeaths: _hiddenDeaths,
                          timer: v.deadline != null && !over ? (deadline: v.deadline!, total: _phaseTotal(v)) : null,
                          ready: over ? _nextReady : const {},
                          center: over
                              ? _ResultCenter(
                                  view: v,
                                  room: _room,
                                  onTap: _spectating ? () {} : () => setState(() => _resultsOpen = true),
                                  onLies: () => showLiesReveal(context, v, _room),
                                )
                              : _TableCenter(view: v, room: _room),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(child: TensionOverlay(tension: tension)),
                  // بعد ٣ قرارات للخونة: لو الزعيم صار وزير يفوزون. نذكّر الكل وقت الترشيح والتصويت.
                  if (v.traitorPolicies >= 3 && (v.phase == Phase.nomination || v.phase == Phase.election))
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(child: _LeaderDanger(role: v.yourRole)),
                    ),
                  // فوق يمين: الجولة ودورك
                  PositionedDirectional(
                    top: 8,
                    start: 10,
                    child: _RoundHud(
                      view: v,
                      roleName: _spectating ? 'متفرج' : roleName,
                      roleColor: _spectating ? AppColors.muted : roleColor,
                      special: _spectating ? null : special,
                      onRole: _spectating ? () {} : _showRole,
                      onBack: _spectating ? () => Navigator.of(context).pop() : (over ? _leaveTable : _confirmLeave),
                    ),
                  ),
                  // كم واحد يتفرج (أصحاب اللاعبين).
                  if ((_room?.watchers.length ?? 0) > 0)
                    PositionedDirectional(top: 62, start: 14, child: _WatchersChip(count: _room!.watchers.length)),
                  // فوق يسار: النقاط مصغرة، تنضغط وتكبر
                  PositionedDirectional(
                    top: 8,
                    end: 10,
                    child: _tip == 'tut_enacted'
                        ? _Pulse(
                            child: MiniTracks(view: v, onTap: () => showTracksBoard(context, v)),
                          )
                        : MiniTracks(view: v, onTap: () => showTracksBoard(context, v)),
                  ),
                  // تحت يمين: التفاعل والعرّاف (والتفاعل يبقى بعد اللعبة للسوالف). المتفرج ما يتكلم.
                  if (!_spectating)
                    PositionedDirectional(
                      bottom: 10,
                      start: 10,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!over && v.spyReady && !_sent.containsKey('spy')) ...[
                            _RoundButton(
                              gfx: 'eye',
                              label: 'الجاسوس: شوف أول كرت',
                              color: const Color(0xFF7C5CFF),
                              onTap: () => _spyPeek(v),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (!over && v.seerReady && !_sent.containsKey('seer')) ...[
                            _RoundButton(
                              gfx: 'seer',
                              label: 'كشف العراف',
                              color: const Color(0xFF7C5CFF),
                              active: _seerPicking,
                              onTap: () => setState(() {
                                _pendingReaction = null;
                                _seerPicking = !_seerPicking;
                              }),
                            ),
                            const SizedBox(height: 10),
                          ],
                          // المطرود يتفرج بس، ما يتكلم (لين تخلص اللعبة).
                          if (!v.me.alive && !over)
                            const SizedBox.shrink()
                          else if (_tip == 'tut_chat')
                            _Pulse(
                              child: _RoundButton(
                                gfx: 'chat',
                                label: 'تفاعل',
                                color: AppColors.gold,
                                active: true,
                                onTap: () {
                                  _closeTip();
                                  _openReactions();
                                },
                              ),
                            )
                          else
                            _RoundButton(gfx: 'chat', label: 'تفاعل', color: AppColors.gold, onTap: _openReactions),
                        ],
                      ),
                    ),
                  // جنب زر التفاعل: ملصقاتك المفضلة بضغطة وحدة (المطرود ما يتكلم لين تخلص اللعبة).
                  if ((v.me.alive || over) && !_spectating)
                    PositionedDirectional(
                      bottom: 12,
                      start: 68,
                      child: ValueListenableBuilder(
                        valueListenable: _backend.profile,
                        builder: (context, p, _) => _FavoritesRow(
                          ids: p.favorites,
                          onSend: _react,
                          onRemove: (id) {
                            _saveFavorites([...p.favorites]..remove(id));
                            _toast('شلته من المفضلة');
                          },
                        ),
                      ),
                    ),
                  // تحت يسار جنب السجل: الادعاء اللي أجّلته (تحت، عشان ما يغطي مقعد أحد)
                  if (!over && _canClaim(v) && !_claimPending(v))
                    PositionedDirectional(
                      bottom: 17,
                      end: 158,
                      child: _Pulse(child: _ClaimChip(onTap: () => setState(() => _claimOpen = _claimKey(v)))),
                    ),
                  // تحت يسار: السجل والصوت
                  PositionedDirectional(
                    bottom: 10,
                    end: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: Sfx.muted,
                          builder: (context, muted, _) => _RoundButton(
                            gfx: muted ? 'mute' : 'sound',
                            label: muted ? 'شغّل الصوت' : 'اكتم الصوت',
                            size: 40,
                            onTap: Sfx.toggle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ValueListenableBuilder(
                          valueListenable: Music.muted,
                          builder: (context, muted, _) => _RoundButton(
                            gfx: muted ? 'music_off' : 'music',
                            label: muted ? 'شغّل الموسيقى' : 'اكتم الموسيقى',
                            size: 40,
                            onTap: Music.toggle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RoundButton(gfx: 'log', label: 'السجل', size: 40, onTap: () => showGameLog(context, v)),
                      ],
                    ),
                  ),
                  // حركتك أنت: بعد ما تخلص المشاهد، عشان ضغطتك ما تروح للمشهد وتحس إن الزر ما اشتغل.
                  if (_scenes.isEmpty && !_spectating) ..._actionLayer(v, pickHint),
                  // المتفرج: على لعبة مين، وإنه ما يشوف الأدوار (تحت يمين مكان التفاعل، عشان ما يغطي مقعد صاحبه).
                  if (_spectating)
                    PositionedDirectional(
                      bottom: 10,
                      start: 10,
                      child: _SpectatorBar(
                        name: _room?.player(widget.watching!)?.name ?? v.player(widget.watching!).name,
                      ),
                    ),
                  if (_claimPending(v))
                    Center(
                      child: _ClaimPrompt(
                        count: v.claimCount!,
                        truth: _truth(v),
                        onClaim: (policies) => _claim(v, policies),
                        onLater: () => setState(() {
                          _claimLater = _claimKey(v);
                          _claimOpen = null;
                        }),
                      ),
                    ),
                  if (_tip case final tip? when !over)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _CoachCard(key: ValueKey(tip), text: _tips[tip]!, onClose: _closeTip),
                      ),
                    ),
                  if (over && _scenes.isEmpty && _resultsOpen)
                    _GameOver(
                      view: v,
                      room: _room,
                      onPlayer: _editNote,
                      onClose: () => setState(() => _resultsOpen = false),
                      onLeave: _leaveTable,
                      onLies: () => showLiesReveal(context, v, _room),
                      onShare: () => showShareCard(context, v, _room),
                      // لعبة الشرح وجولات البطولة ما تنعاد.
                      onRematch: v.tutorial || _room?.tour != null || _rematching ? null : _rematch,
                      rematchReady: _room?.next == null ? 0 : _nextReady.length,
                    ),
                  if (_scenes.isNotEmpty)
                    Positioned.fill(
                      child: SceneOverlay(
                        key: ObjectKey(_scenes.first),
                        scene: _scenes.first.scene,
                        onDone: _nextScene,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _leaving = false;
  bool _kickShown = false;

  /// بعد ما خلصت اللعبة: تطلع من الطاولة للرئيسية، والباقين يشوفون عند كرسيك إنك طلعت.
  void _leaveTable() {
    if (_leftTable) return;
    _leftTable = true;
    _backend.leaveGame(widget.code).ignore();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  /// تطلع من اللعبة؟ يكمل عنك بوت، وما تاخذ فوز ولا جائزة.
  Future<void> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تطلع من اللعبة؟', textAlign: TextAlign.center),
        content: const Text('بيكمل عنك بوت لين تخلص، وما تاخذ فوز ولا جائزة من هالجولة.', textAlign: TextAlign.center),
        actions: [
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: 'أكمل',
                  tone: ButtonTone.ghost,
                  height: 46,
                  fontSize: 16,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  label: 'اطلع',
                  tone: ButtonTone.red,
                  height: 46,
                  fontSize: 16,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _leaving = true);
    if (_view case final v?) Telemetry.gameLeft(round: v.round, tutorial: v.tutorial);
    try {
      await _backend.leaveGame(widget.code);
    } on BackendException catch (e) {
      _toast(e.message);
    }
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  /// انطردت لأنك ما لعبت دورين: نقولك ونرجعك للرئيسية.
  void _kicked() {
    if (_kickShown || _leaving) return;
    _kickShown = true;
    _leaving = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('انطردت من اللعبة', textAlign: TextAlign.center),
        content: const Text(
          'ما لعبت دورك مرتين ورا بعض، فكمّل عنك بوت.\nتقدر ترجع تلعب بعد ٥ دقايق.',
          textAlign: TextAlign.center,
        ),
        actions: [
          GameButton(
            label: 'تمام',
            height: 46,
            fontSize: 16,
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
    );
  }

  /// شكل الكروت اللي لابسه اللاعب من المتجر.
  CardSkin get _skin => cardSkin(Backend.instance.profile.value.cards);

  /// الأزرار والكروت اللي تطلع لما يكون الدور عليك: التصويت جنب مقعدك، والكروت في نص الطاولة.
  List<Widget> _actionLayer(GameView v, String? pickHint) {
    if (pickHint != null) {
      return [
        _banner(
          pickHint,
          onCancel: () => setState(() {
            _pendingReaction = null;
            _seerPicking = false;
            _clearPick = false;
          }),
        ),
      ];
    }
    if (!v.me.alive) return const [];
    // أرسلت حركتك: الأزرار تختفي ويطلع لك وش سويت لين يرد السيرفر.
    if (_sent[_turnKey(v)] case final note?) return [if (note.isNotEmpty) _banner(note, icon: 'check')];
    switch (v.phase) {
      case Phase.nomination when v.amPresident:
        return [_banner('أنت الرئيس! اضغط على اللاعب اللي تبيه وزير', icon: 'crown')];
      case Phase.election when !v.me.hasVoted:
        return [
          _besideSeat(
            below: v.judgeReady
                ? GameButton(
                    label: 'ألغِ التصويت',
                    semantics: 'ألغِ التصويت',
                    icon: const Gfx('scales', size: 22),
                    tone: ButtonTone.purple,
                    height: 42,
                    fontSize: 14,
                    onPressed: () => _judgeCancel(v),
                  )
                : null,
            yes: GameButton(
              label: 'موافق',
              semantics: 'موافق',
              tone: ButtonTone.green,
              height: 50,
              onPressed: () => _act({'type': 'vote', 'ja': true}, note: 'صوّتت موافق… ننتظر الباقين'),
            ),
            no: GameButton(
              label: 'رافض',
              semantics: 'رافض',
              tone: ButtonTone.red,
              height: 50,
              onPressed: () => _act({'type': 'vote', 'ja': false}, note: 'صوّتت رافض… ننتظر الباقين'),
            ),
          ),
        ];
      case Phase.vetoResponse when v.amPresident:
        return [
          _banner('الوزير يبي يرمي الكرتين. توافق؟', bottom: 184, icon: 'hand'),
          _besideSeat(
            yes: GameButton(
              label: 'موافق',
              tone: ButtonTone.green,
              height: 50,
              onPressed: () => _act({'type': 'respondVeto', 'accept': true}, note: 'وافقت على الفيتو'),
            ),
            no: GameButton(
              label: 'رافض',
              tone: ButtonTone.red,
              height: 50,
              onPressed: () => _act({'type': 'respondVeto', 'accept': false}, note: 'رفضت الفيتو'),
            ),
          ),
        ];
      case Phase.presidentDiscard when v.amPresident:
        return [
          Positioned.fill(
            child: CardHand(
              key: ValueKey('discard${v.round}'),
              cards: v.hand,
              skin: _skin,
              hint: 'اسحب الكرت اللي بترميه للمجمرة (سري)',
              verb: 'ارمِ',
              target: HandTarget.burn,
              onPick: (i) => _act({'type': 'discard', 'index': i}, note: 'رميت كرت، والباقي راح للوزير'),
            ),
          ),
        ];
      case Phase.chancellorEnact when v.amNominee:
        return [
          Positioned.fill(
            child: CardHand(
              key: ValueKey('enact${v.round}'),
              cards: v.hand,
              skin: _skin,
              hint: 'اسحب الكرت اللي بتمرره للختم',
              verb: 'مرّر',
              target: HandTarget.stamp,
              onPick: (i) => _act({'type': 'enact', 'index': i}, note: 'مرّرت القرار'),
              extra: v.canVeto
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppColors.panel.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.gold.withValues(alpha: .5)),
                      ),
                      child: TextButton(
                        onPressed: () => _act({'type': 'proposeVeto'}, note: 'طلبت فيتو… ننتظر رد الرئيس'),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [Gfx('hand', size: 22), SizedBox(width: 4), Text('اطلب فيتو (نرمي الاثنين)')],
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ];
      case Phase.power when v.amPresident && v.pendingPower == Power.peek:
        return [
          Positioned.fill(
            child: CardHand(
              key: const ValueKey('peek'),
              cards: v.peeked ?? const <Policy>[],
              skin: _skin,
              hint: 'أول ٣ كروت في الكومة (لك بس)',
              extra: SizedBox(
                width: 120,
                child: GameButton(
                  label: 'تمام',
                  height: 42,
                  fontSize: 16,
                  onPressed: () => _act({'type': 'acknowledgePeek'}),
                ),
              ),
            ),
          ),
        ];
      case Phase.power when v.amPresident:
        return [_banner('${powerName[v.pendingPower]}: اختر لاعب من الطاولة', icon: powerIcon[v.pendingPower])];
      default:
        return const [];
    }
  }

  /// سطر تعليمات فوق مقعدك.
  Widget _banner(String text, {VoidCallback? onCancel, double bottom = 112, String? icon}) => Positioned(
    bottom: bottom,
    left: 0,
    right: 0,
    child: Center(
      child: Container(
        padding: EdgeInsets.fromLTRB(14, 6, onCancel == null ? 14 : 6, 6),
        decoration: BoxDecoration(
          color: AppColors.panel.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withValues(alpha: .6), width: 1.5),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Gfx(icon, size: 26), const SizedBox(width: 6)],
            Text(
              text,
              style: const TextStyle(fontFamily: kufi, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            if (onCancel != null) ...[
              const SizedBox(width: 6),
              TextButton(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: onCancel,
                child: const Text('إلغاء'),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  /// زرين على جنبين السجادة (فوق كومتين الأوراق)، عشان الصينية تبقى واضحة بالرئيس والوزير وأسمائهم.
  /// [below] زر ثالث تحت «رافض» (القاضي: ألغِ التصويت).
  Widget _besideSeat({required Widget yes, required Widget no, Widget? below}) => Positioned.fill(
    child: Stack(
      children: [
        Align(
          alignment: const Alignment(.5, .1),
          child: SizedBox(width: 130, child: yes),
        ),
        Align(
          alignment: const Alignment(-.5, .1),
          child: SizedBox(width: 130, child: no),
        ),
        if (below != null)
          Align(
            alignment: const Alignment(-.5, .5),
            child: SizedBox(width: 150, child: below),
          ),
      ],
    ),
  );

  /// القاضي: يلغي التصويت بدال ما يصوّت (مرة وحدة، وينكشف للكل).
  Future<void> _judgeCancel(GameView v) async {
    final ok = await _ask('تلغي التصويت؟', 'مرة وحدة باللعبة: الحكومة تسقط مهما كانت الأصوات، والكل بيعرف إنك القاضي.');
    if (ok) await _act({'type': 'judgeCancel'}, note: 'ألغيت التصويت… ننتظر الباقين');
  }

  /// الجاسوس: يشوف أول كرت بالكومة (مرة وحدة، لك بس).
  Future<void> _spyPeek(GameView v) async {
    final ok = await _ask('تشوف أول كرت بالكومة؟', 'مرة وحدة باللعبة، ومحد غيرك يشوفه.');
    if (ok) await _act({'type': 'spyPeek'}, key: 'spy');
  }

  /// سؤال بنعم أو لا.
  Future<bool> _ask(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: Text(body, textAlign: TextAlign.center),
        actions: [
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: 'لا',
                  tone: ButtonTone.ghost,
                  height: 46,
                  fontSize: 16,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  label: 'إيه',
                  height: 46,
                  fontSize: 16,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// الكرت اللي شافه الجاسوس.
  void _showSpySaw(Policy card) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('أول كرت بالكومة', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PolicyCard(policy: card, skin: _skin, width: 74),
            const SizedBox(height: 10),
            Text(
              card == Policy.loyal ? 'أزرق: قرار للأوفياء' : 'أحمر: قرار للخونة',
              style: TextStyle(
                fontFamily: kufi,
                fontWeight: FontWeight.w700,
                color: card == Policy.loyal ? AppColors.loyalLight : AppColors.traitorLight,
              ),
            ),
            const Text(
              'محد غيرك شافه. تقدر تقوله للكل… أو تخليه سر.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [GameButton(label: 'تمام', height: 44, fontSize: 16, onPressed: () => Navigator.pop(context))],
      ),
    );
  }
}

/// فوق يمين: الجولة، ودورك (تضغطه يطلع لك بطاقة دورك).
class _RoundHud extends StatelessWidget {
  const _RoundHud({
    required this.view,
    required this.roleName,
    required this.roleColor,
    required this.special,
    required this.onRole,
    this.onBack,
  });

  final GameView view;
  final String roleName;
  final Color roleColor;
  final Special? special;
  final VoidCallback onRole;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final deadline = view.deadline;
    final left = deadline == null || view.phase == Phase.gameOver
        ? null
        : deadline.difference(DateTime.now()).inSeconds.clamp(0, 999);
    final hud = Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: .35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (view.quick) const Padding(padding: EdgeInsetsDirectional.only(end: 2), child: Gfx('bolt', size: 16)),
              Text(
                'الجولة ${arabicNumber(view.round)}',
                style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              if (left != null) ...[
                const SizedBox(width: 8),
                const Gfx('hourglass', size: 16),
                Text(
                  arabicNumber(left),
                  style: TextStyle(
                    fontFamily: kufi,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: left <= 5 ? AppColors.traitorLight : AppColors.gold,
                  ),
                ),
              ],
            ],
          ),
          GestureDetector(
            onTap: onRole,
            child: Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: .18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: roleColor.withValues(alpha: .6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    roleName,
                    style: TextStyle(
                      color: roleColor == AppColors.loyal ? AppColors.loyalLight : AppColors.traitorLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  if (special != null) ...[
                    const SizedBox(width: 4),
                    Gfx(special == Special.seer ? 'seer' : 'shield', size: 15),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
    final back = onBack;
    if (back == null) return hud;
    // زر الخروج واضح ولحاله، عشان الكل يلقاه.
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: 'خروج من اللعبة',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: back,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8E1B2B), Color(0xFF4A0B15)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.traitorLight.withValues(alpha: .8), width: 1.6),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Gfx('exit', size: 30),
                  Text('خروج', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, height: 1.2)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        hud,
      ],
    );
  }
}

/// زر دائري يطفو في الزاوية.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.label,
    required this.onTap,
    required this.gfx,
    this.color = AppColors.muted,
    this.size = 52,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;

  /// أيقونة ملونة (assets/icons/gfx_*.png).
  final String gfx;
  final Color color;
  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color.withValues(alpha: .45) : AppColors.panel.withValues(alpha: .88),
            border: Border.all(color: color.withValues(alpha: .8), width: 2),
            boxShadow: [BoxShadow(color: active ? color : Colors.black54, blurRadius: active ? 14 : 8)],
          ),
          child: Gfx(gfx, size: size * .62),
        ),
      ),
    );
  }
}

/// مدة الدور كاملة بالثواني (الشرح أطول، والسريع نصها).
double _phaseTotal(GameView v) => (_phaseSeconds[v.phase] ?? 30) * (v.tutorial ? 4 : (v.quick ? .5 : 1));

/// الرسالة في نص الصينية: وش يصير الحين.
class _TableCenter extends StatelessWidget {
  const _TableCenter({required this.view, required this.room});

  final GameView view;
  final Room? room;

  @override
  Widget build(BuildContext context) {
    final v = view;
    // الصينية تشرح الوضع بالصور: الرئيس والوزير، وبينهم أيقونة المرحلة، والكروت تحت اللي ماسكها.
    final (String icon, bool cardsWithPresident, bool cardsWithMinister) = switch (v.phase) {
      Phase.nomination => ('crown', false, false),
      Phase.election => ('ballot', false, false),
      Phase.presidentDiscard => ('scroll', true, false),
      Phase.chancellorEnact || Phase.vetoResponse => ('scroll', false, true),
      Phase.power => (
        switch (v.pendingPower) {
          Power.investigate => 'search',
          Power.peek => 'eye',
          Power.specialElection => 'crown',
          _ => 'dagger',
        },
        false,
        false,
      ),
      Phase.gameOver => ('trophy', false, false),
    };
    final showMinister = v.phase != Phase.power && v.phase != Phase.gameOver;
    String name(String? id) => id == null ? '' : v.nameOf(id);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TraySeat(
                avatar: room?.player(v.presidentId)?.avatar,
                name: name(v.presidentId),
                crown: true,
                cards: cardsWithPresident ? 3 : 0,
              ),
              const SizedBox(width: 10),
              _PhaseIcon(icon: icon, pulse: v.phase == Phase.election || v.phase == Phase.power),
              if (showMinister) ...[
                const SizedBox(width: 10),
                _TraySeat(
                  avatar: v.nomineeId == null ? null : room?.player(v.nomineeId!)?.avatar,
                  name: v.nomineeId == null ? 'الوزير؟' : name(v.nomineeId),
                  waiting: v.nomineeId == null,
                  cards: cardsWithMinister ? 2 : 0,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// نص الصينية بعد اللعبة: فزت أو خسرت، ومين فاز وليش، وجوائزك. تنضغط وتفتح النتيجة كاملة.
class _ResultCenter extends StatelessWidget {
  const _ResultCenter({required this.view, required this.room, required this.onTap, required this.onLies});

  final GameView view;
  final Room? room;
  final VoidCallback onTap;
  final VoidCallback onLies;

  @override
  Widget build(BuildContext context) {
    final loyalWon = view.winnerLoyal ?? false;
    final iWon = (view.yourRole == Role.loyal) == loyalWon;
    // المتفرج: الفريق الفايز بدال فزت أو خسرت، وبدون جوائز.
    final spectator = view.spectator;
    final r = spectator ? null : room?.results[view.you];
    return Semantics(
      container: true,
      child: GestureDetector(
        onTap: onTap,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
            decoration: BoxDecoration(
              color: const Color(0xE60B0818),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gold.withValues(alpha: .55), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    iWon && !spectator ? const Gfx('trophy', size: 40) : Seal(loyal: loyalWon, size: 40),
                    const SizedBox(width: 6),
                    GoldText(
                      spectator
                          ? (loyalWon ? 'فاز الأوفياء' : 'فاز الخونة')
                          : iWon
                          ? 'فزت!'
                          : 'خسرت',
                      size: 30,
                    ),
                  ],
                ),
                Text(
                  '${loyalWon ? 'فاز الأوفياء' : 'فاز الخونة'} · ${_winReasons[view.winReason] ?? ''}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFD9CFFF)),
                ),
                if (r != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (r.coins > 0) ...[
                        Amount('coin', '+${arabicNumber(r.coins)}', size: 18, style: _rewardStyle(AppColors.gold)),
                        if (r.boost > 1)
                          Text(' ×${arabicNumber(r.boost)}', style: _rewardStyle(const Color(0xFFFF8A3C))),
                        const SizedBox(width: 12),
                      ],
                      Amount('xp', '+${arabicNumber(r.xp)}', size: 18, style: _rewardStyle(AppColors.diamond)),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!spectator) ...[
                      Semantics(
                        button: true,
                        label: 'النتيجة كاملة',
                        excludeSemantics: true,
                        child: _chip('النتيجة كاملة', AppColors.gold),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Semantics(
                      button: true,
                      label: 'مين كذب؟',
                      excludeSemantics: true,
                      child: GestureDetector(onTap: onLies, child: _chip('مين كذب؟', const Color(0xFFFF8A3C))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static TextStyle _rewardStyle(Color color) => TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15);

  static Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: .6)),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12.5),
    ),
  );
}

/// صورة في الصينية: الرئيس بتاج مرسوم فوقه، أو الوزير، أو دائرة فاضية تنبض لين يختاره الرئيس.
class _TraySeat extends StatelessWidget {
  const _TraySeat({required this.avatar, required this.name, this.crown = false, this.waiting = false, this.cards = 0});

  final String? avatar;

  /// الاسم تحت الصورة، لأن اثنين ممكن يختارون نفس الشخصية.
  final String name;
  final bool crown;
  final bool waiting;
  final int cards;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 108,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 14,
            child: waiting
                ? const _Pulse(
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Color(0x33000000),
                      child: Text(
                        '؟',
                        style: TextStyle(fontFamily: kufi, fontSize: 26, color: AppColors.goldInk),
                      ),
                    ),
                  )
                : PlayerAvatar(
                    avatar: avatar ?? 'masked',
                    frame: crown ? AppColors.gold : const Color(0xFFA78BFA),
                    size: 52,
                  ),
          ),
          if (crown) const Positioned(top: 0, child: GameIcon('crown', size: 22, color: Color(0xFFB8801F))),
          Positioned(
            top: 71,
            child: SizedBox(
              width: 76,
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldInk,
                  height: 1.2,
                ),
              ),
            ),
          ),
          if (cards > 0)
            Positioned(
              bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < cards; i++)
                    Container(
                      width: 12,
                      height: 17,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: const LinearGradient(colors: [Color(0xFF4A3592), Color(0xFF1C1638)]),
                        border: Border.all(color: AppColors.gold, width: 1),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// أيقونة المرحلة بين الرئيس والوزير (صندوق التصويت، القدرة، الكأس…).
class _PhaseIcon extends StatelessWidget {
  const _PhaseIcon({required this.icon, this.pulse = false});

  final String icon;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0x22000000),
        border: Border.all(color: const Color(0xFF9C6A1C), width: 1.5),
      ),
      child: GameIcon(icon, size: 24, color: const Color(0xFF5A3A08)),
    );
    return pulse ? _Pulse(child: badge) : badge;
  }
}

/// لعبة الشرح: الراوي (الشيبة) ينزل بنصيحة قصيرة تحت، بعيد عن المقاعد اللي تختار منها.
class _CoachCard extends StatelessWidget {
  const _CoachCard({super.key, required this.text, required this.onClose});

  final String text;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    // ما نغطي أزرار الزوايا تحت (التفاعل يمين، والصوت والسجل يسار).
    final maxW = (MediaQuery.sizeOf(context).width - 330).clamp(260.0, 470.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, 40 * (1 - t)),
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: Semantics(
        liveRegion: true,
        label: 'الراوي: $text',
        child: Container(
          constraints: BoxConstraints(maxWidth: maxW),
          padding: const EdgeInsetsDirectional.fromSTEB(8, 7, 4, 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xF22B1F5C), Color(0xF21A1240)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold, width: 1.8),
            boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: .3), blurRadius: 18)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PlayerAvatar(avatar: 'sheikh', frame: AppColors.gold, size: 40),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الراوي',
                      style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w800, height: 1.1),
                    ),
                    Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.4)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'إخفاء النصيحة',
                visualDensity: VisualDensity.compact,
                onPressed: onClose,
                icon: const Gfx('cross', size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// نبض خفيف يلفت النظر بدون كلام.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: Tween(begin: .92, end: 1.06).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
    child: widget.child,
  );
}

/// الادعاء كلام: «٢ خونة + ١ أوفياء».
String _claimLabel(List<Policy> option) {
  final t = option.where((p) => p == Policy.traitor).length;
  final l = option.length - t;
  return [if (t > 0) '${arabicNumber(t)} خونة', if (l > 0) '${arabicNumber(l)} أوفياء'].join(' + ');
}

/// الادعاء بعد الحكم: وش تقول للكل إنه وصلك؟ ضغطة وحدة، واللي وصلك فعلاً عليه علامة «الصدق».
/// «بعدين» يسكّرها ويبقى لها زر تحت تفتحها منه متى ما بغيت.
class _ClaimPrompt extends StatelessWidget {
  const _ClaimPrompt({required this.count, required this.truth, required this.onClaim, required this.onLater});

  final int count;

  /// الكروت اللي وصلتك فعلاً (لو شفتها من هالجهاز).
  final List<Policy>? truth;
  final ValueChanged<List<Policy>> onClaim;
  final VoidCallback onLater;

  static const _options = {
    3: [
      [Policy.traitor, Policy.traitor, Policy.traitor],
      [Policy.traitor, Policy.traitor, Policy.loyal],
      [Policy.traitor, Policy.loyal, Policy.loyal],
      [Policy.loyal, Policy.loyal, Policy.loyal],
    ],
    2: [
      [Policy.traitor, Policy.traitor],
      [Policy.traitor, Policy.loyal],
      [Policy.loyal, Policy.loyal],
    ],
  };

  static int _traitors(List<Policy> l) => l.where((p) => p == Policy.traitor).length;

  @override
  Widget build(BuildContext context) {
    final truth = this.truth;
    return Container(
      constraints: const BoxConstraints(maxWidth: 620),
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: .97),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: .6), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 24)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Gfx('megaphone', size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoldText(count == 3 ? 'وش تقول إنه وصلك وأنت رئيس؟' : 'وش تقول إنه وصلك وأنت وزير؟', size: 19),
                    Text(
                      'وصلك ${arabicNumber(count)} كروت. اللي تختاره يطلع للكل… قول الصدق أو اكذب',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 92,
                child: GameButton(label: 'بعدين', tone: ButtonTone.ghost, height: 38, fontSize: 15, onPressed: onLater),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              for (final option in _options[count]!)
                _ClaimOption(
                  option: option,
                  truth: truth != null && _traitors(truth) == _traitors(option),
                  onTap: () => onClaim(option),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// خيار ادعاء كبير: الأختام ووصفها، وينضغط بأي مكان فيه.
class _ClaimOption extends StatefulWidget {
  const _ClaimOption({required this.option, required this.truth, required this.onTap});

  final List<Policy> option;
  final bool truth;
  final VoidCallback onTap;

  @override
  State<_ClaimOption> createState() => _ClaimOptionState();
}

class _ClaimOptionState extends State<_ClaimOption> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final edge = widget.truth ? AppColors.green : AppColors.goldDark;
    return Semantics(
      button: true,
      label: 'ادعاء ${widget.option.map((p) => p.code).join()}${widget.truth ? ' (الصدق)' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? .93 : 1,
          duration: const Duration(milliseconds: 90),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                width: 128,
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFBF1DA), AppColors.parchmentDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: edge, width: widget.truth ? 3 : 2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.truth ? AppColors.green.withValues(alpha: .45) : Colors.black45,
                      blurRadius: widget.truth ? 14 : 6,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final p in widget.option)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Seal(loyal: p == Policy.loyal, size: 34),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _claimLabel(widget.option),
                      style: const TextStyle(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              if (widget.truth)
                Positioned(
                  top: -11,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF0B3A22), width: 1.5),
                    ),
                    child: const Text(
                      'الصدق',
                      style: TextStyle(color: Color(0xFF062814), fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر الادعاء لما تأجله: يبقى تحت لين تقول وش وصلك.
/// كم واحد يتفرج على اللعبة (أصحاب اللاعبين).
class _WatchersChip extends StatelessWidget {
  const _WatchersChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${arabicNumber(count)} يتفرجون',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 10, 2),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gfx('eye', size: 18),
          const SizedBox(width: 4),
          Text(
            '${arabicNumber(count)} يتفرجون',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
        ],
      ),
    ),
  );
}

/// شارة المتفرج تحت: على لعبة مين، وإنه ما يشوف الأدوار.
class _SpectatorBar extends StatelessWidget {
  const _SpectatorBar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 160),
    padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 12, 5),
    decoration: BoxDecoration(
      color: AppColors.panel.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFA48BFF), width: 1.5),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Gfx('eye', size: 24),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تتفرج على $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: kufi, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Text('بدون ما تشوف الأدوار', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// صف الملصقات المفضلة جنب زر التفاعل: ضغطة ترسل، وضغطة مطوّلة تشيله من المفضلة.
class _FavoritesRow extends StatelessWidget {
  const _FavoritesRow({required this.ids, required this.onSend, required this.onRemove});

  final List<String> ids;
  final void Function(String id) onSend;
  final void Function(String id) onRemove;

  @override
  Widget build(BuildContext context) {
    final list = [for (final id in ids) ?stickerById(id)];
    if (list.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in list)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 5),
            child: _FavoriteButton(sticker: s, onTap: () => onSend(s.id), onLongPress: () => onRemove(s.id)),
          ),
      ],
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton({required this.sticker, required this.onTap, required this.onLongPress});

  final Sticker sticker;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'ملصق مفضل ${widget.sticker.id}',
    excludeSemantics: true,
    child: GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? .86 : 1,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.panel.withValues(alpha: .9),
            border: Border.all(color: AppColors.gold.withValues(alpha: .65), width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
          ),
          child: Image.asset(widget.sticker.asset, filterQuality: FilterQuality.medium),
        ),
      ),
    ),
  );
}

class _ClaimChip extends StatelessWidget {
  const _ClaimChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'وش وصلك؟',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 14, 4),
        decoration: BoxDecoration(
          color: AppColors.panel.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.gold, width: 2),
          boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: .5), blurRadius: 12)],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gfx('megaphone', size: 30),
            SizedBox(width: 6),
            Text(
              'وش وصلك؟',
              style: TextStyle(fontFamily: kufi, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Reward extends StatelessWidget {
  const _Reward(this.text, this.color, {required this.icon});

  final String text;
  final Color color;
  final String icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .7), width: 1.5),
    ),
    child: Amount(
      icon,
      text,
      size: 20,
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
    ),
  );
}

/// آخر لعبة الشرح: كفو! والهدية (لو هذي أول مرة) تنتظره في الرئيسية.
class _TutorialDone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) {
        final gift = p.gifts.any((g) => g.tutorial);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withValues(alpha: .7)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Gfx(gift ? 'gift' : 'check', size: 26),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  gift ? 'خلّصت الشرح! هديتك تنتظرك في الرئيسية' : 'خلّصت الشرح! الحين أنت جاهز تلعب مع الناس',
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GameOver extends StatelessWidget {
  const _GameOver({
    required this.view,
    required this.room,
    required this.onPlayer,
    required this.onClose,
    required this.onLeave,
    required this.onLies,
    required this.onShare,
    required this.onRematch,
    this.rematchReady = 0,
  });

  final GameView view;
  final Room? room;

  /// ضغطة على لاعب: بطاقته (تقدر تبلّغ عنه بعد اللعبة).
  final ValueChanged<String> onPlayer;

  /// ترجع للطاولة (تسولف مع الباقين)، أو تطلع منها.
  final VoidCallback onClose;
  final VoidCallback onLeave;

  /// «مين كذب؟» و«شارك» و«العب مرة ثانية» (null: ما تنعاد، مثل لعبة الشرح).
  final VoidCallback onLies;
  final VoidCallback onShare;
  final VoidCallback? onRematch;

  /// كم واحد دخل الجولة الجاية (لو أحد ضغط «العب مرة ثانية»).
  final int rematchReady;

  @override
  Widget build(BuildContext context) {
    final loyalWon = view.winnerLoyal ?? false;
    final iWon = (view.yourRole == Role.loyal) == loyalWon;
    final teamColor = loyalWon ? AppColors.loyal : AppColors.traitor;
    final roles = [
      for (final p in view.players)
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onPlayer(p.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                PlayerAvatar(avatar: room?.player(p.id)?.avatar ?? 'masked', size: 32, dead: !p.alive),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    view.nameOf(p.id),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (p.knownSpecial != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: Gfx(specialInfo[p.knownSpecial]!.$3, size: 18),
                  ),
                Text(
                  roleInfo[p.knownRole]!.$1,
                  style: TextStyle(
                    fontFamily: kufi,
                    color: p.knownRole == Role.loyal ? AppColors.loyalLight : AppColors.traitorLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: .78),
        padding: const EdgeInsets.all(12),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: .8, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, s, child) => Transform.scale(scale: s, child: child),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 680),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: RadialGradient(
                    center: const AlignmentDirectional(-.6, -1).resolve(Directionality.of(context)),
                    radius: 1.4,
                    colors: [teamColor.withValues(alpha: .45), AppColors.panel],
                  ),
                  border: Border.all(color: AppColors.gold.withValues(alpha: .6), width: 2),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height - 50),
                  child: Row(
                    children: [
                      // النتيجة
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  iWon ? const Gfx('trophy', size: 46) : Seal(loyal: loyalWon, size: 46),
                                  const SizedBox(width: 6),
                                  GoldText(iWon ? 'فزت!' : 'خسرت', size: 32),
                                ],
                              ),
                              Text(
                                '${loyalWon ? 'فاز الأوفياء' : 'فاز الخونة'} · ${_winReasons[view.winReason] ?? ''}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Color(0xFFD9CFFF)),
                              ),
                              if (view.tutorial) ...[const SizedBox(height: 8), _TutorialDone()],
                              if (room?.results[view.you] case final r?) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (r.coins > 0)
                                      _Reward(
                                        r.boost > 1
                                            ? '+${arabicNumber(r.coins)} (×${arabicNumber(r.boost)})'
                                            : '+${arabicNumber(r.coins)}',
                                        AppColors.gold,
                                        icon: 'coin',
                                      ),
                                    if (r.coins > 0) const SizedBox(width: 10),
                                    _Reward('+${arabicNumber(r.xp)}', AppColors.diamond, icon: 'xp'),
                                    if (r.rank case final rank? when rank != 0) ...[
                                      const SizedBox(width: 10),
                                      _Reward(
                                        '${rank > 0 ? '+' : '−'}${arabicNumber(rank.abs())} تصنيف',
                                        rank > 0 ? AppColors.green : AppColors.traitorLight,
                                        icon: 'rank_${RankTier.of(Backend.instance.profile.value.rankPoints).id}',
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),
                              // البطولة: تأهلت للدور الجاي، أو طلعت، أو صرت البطل.
                              if (room?.results[view.you]?.tour case final t?) ...[
                                const SizedBox(height: 6),
                                Text(
                                  t.champion
                                      ? 'صرت بطل الأسبوع!'
                                      : t.out
                                      ? 'طلعت من البطولة هالأسبوع'
                                      : 'تأهلت لـ${tourStageNames[t.stage]}!',
                                  style: TextStyle(
                                    fontFamily: kufi,
                                    fontWeight: FontWeight.w700,
                                    color: t.out ? AppColors.traitorLight : AppColors.goldLight,
                                  ),
                                ),
                              ],
                              if (!view.tutorial && room?.tour == null) ...[
                                GameButton(
                                  label: rematchReady > 0
                                      ? 'العب مرة ثانية (${arabicNumber(rematchReady)} جاهزين)'
                                      : 'العب مرة ثانية',
                                  icon: const Gfx('games', size: 26),
                                  semantics: 'العب مرة ثانية',
                                  height: 46,
                                  fontSize: 16,
                                  onPressed: onRematch,
                                ),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                children: [
                                  Expanded(
                                    child: GameButton(
                                      label: 'مين كذب؟',
                                      icon: const Gfx('liar', size: 22),
                                      semantics: 'مين كذب؟',
                                      tone: ButtonTone.purple,
                                      height: 40,
                                      fontSize: 14,
                                      onPressed: onLies,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GameButton(
                                      label: 'شارك',
                                      icon: const Gfx('link', size: 22),
                                      semantics: 'شارك',
                                      tone: ButtonTone.green,
                                      height: 40,
                                      fontSize: 14,
                                      onPressed: onShare,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: GameButton(
                                      label: 'ارجع للطاولة',
                                      icon: const Gfx('chat', size: 22),
                                      semantics: 'ارجع للطاولة',
                                      tone: ButtonTone.ghost,
                                      height: 40,
                                      fontSize: 14,
                                      onPressed: onClose,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: GameButton(
                                      label: 'خروج',
                                      icon: const Gfx('exit', size: 22),
                                      semantics: 'خروج',
                                      tone: ButtonTone.ghost,
                                      height: 40,
                                      fontSize: 14,
                                      onPressed: onLeave,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 180,
                        child: VerticalDivider(width: 28, color: AppColors.gold.withValues(alpha: .25)),
                      ),
                      // الأدوار الحقيقية
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'الأدوار الحقيقية',
                              style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Flexible(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height - 110),
                                child: SingleChildScrollView(child: Column(children: roles)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// شريط التنبيه فوق وقت الترشيح والتصويت (بعد ٣ قرارات للخونة). ينبض عشان ينتبه له الكل.
class _LeaderDanger extends StatefulWidget {
  const _LeaderDanger({required this.role});

  final Role role;

  @override
  State<_LeaderDanger> createState() => _LeaderDangerState();
}

class _LeaderDangerState extends State<_LeaderDanger> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mine = widget.role == Role.leader;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Container(
        padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 14, 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6B111C), Color(0xFF2A070C)]),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Color.lerp(AppColors.traitor, Colors.white, _c.value * .35)!, width: 1.6),
          boxShadow: [BoxShadow(color: AppColors.traitor.withValues(alpha: .25 + _c.value * .4), blurRadius: 18)],
        ),
        child: child,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LeaderSeal(size: 38),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: mine ? 'لو صرت وزير ' : 'الزعيم وزير ',
                  style: const TextStyle(color: AppColors.gold),
                ),
                const TextSpan(text: '= '),
                const TextSpan(
                  text: 'فوز الخونة',
                  style: TextStyle(color: Color(0xFFFF8A8A)),
                ),
              ],
            ),
            style: const TextStyle(fontFamily: kufi, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
