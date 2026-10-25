import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_view.dart';
import '../models/room.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/notes.dart';
import '../services/push.dart';
import '../services/music.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game/game_log.dart';
import '../widgets/game/game_table.dart';
import '../widgets/game/overlays.dart';
import '../widgets/game/policy_card.dart';
import '../widgets/game/tracks.dart';
import '../widgets/ui.dart';

const _winReasons = {
  'loyalPolicies': 'تمررت ٥ قرارات للأوفياء',
  'traitorPolicies': 'تمررت ٦ قرارات للخونة',
  'leaderElected': 'الزعيم انتُخب وزير',
  'leaderExecuted': 'الزعيم انطرد',
};

/// نفس engine/src/rules.ts → PHASE_SECONDS.
const _phaseSeconds = {
  Phase.nomination: 30,
  Phase.election: 25,
  Phase.presidentDiscard: 20,
  Phase.chancellorEnact: 20,
  Phase.vetoResponse: 15,
  Phase.power: 30,
};

/// شاشة الطاولة: كل اللعب يصير هنا.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.code});

  final String code;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _backend = Backend.instance;
  late final StreamSubscription<Map<String, dynamic>?> _viewSub;
  late final StreamSubscription<Room?> _roomSub;
  late final Timer _ticker;
  late final Notes _notes = Notes(widget.code)..load();

  GameView? _view;
  Room? _room;
  bool _busy = false;
  bool _roleShown = false;
  int _seenInvestigations = 0;
  int? _claimDismissedRound;
  int? _seenLog;
  bool _wasMyTurn = false;
  bool _endSoundPlayed = false;

  /// مشاهد تنتظر دورها فوق الطاولة (كشف التصويت، الختم، الطرد…)، ومعها جملة الراوي.
  final List<(Widget, String, Duration)> _scenes = [];

  /// رد ينتظر تختار له لاعب (مثل أشك في…).
  ReactionKind? _pendingReaction;

  /// تختار لاعب تشيل رأيك فيه (أشك أو أثق).
  bool _clearPick = false;

  /// العرّاف ضغط "اكشف" وينتظر يختار لاعب.
  bool _seerPicking = false;
  String? _seerSeen;

  @override
  void initState() {
    super.initState();
    Push.setCurrentGame(widget.code);
    Music.play('game');
    _viewSub = _backend.watchView(widget.code).listen((data) {
      if (data == null || !mounted) return;
      final view = GameView.fromJson(data);
      setState(() => _view = view);
      _afterUpdate(view);
    });
    _roomSub = _backend.watchRoom(widget.code).listen((room) {
      if (mounted) setState(() => _room = room);
    });
    // كل ثانية: نحدّث العداد وفقاعات الردود، ونطلب من السيرفر يكمّل لو خلص الوقت.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _checkTimeout();
      _tick();
    });
  }

  DateTime? _lastTimeoutCall;

  /// لو خلص وقت الدور، أي لاعب في الطاولة يطلب من السيرفر يكمّل. نوزع الطلبات على المقاعد
  /// عشان ما يطلبون كلهم بنفس اللحظة، والسيرفر ينفذ مرة وحدة بس.
  void _checkTimeout() {
    final v = _view;
    final deadline = v?.deadline;
    if (v == null || deadline == null || v.phase == Phase.gameOver) return;
    final now = DateTime.now();
    final myDelay = Duration(milliseconds: 1000 + 400 * v.me.seat);
    if (now.isBefore(deadline.add(myDelay))) return;
    if (_lastTimeoutCall != null && now.difference(_lastTimeoutCall!).inSeconds < 3) return;
    _lastTimeoutCall = now;
    _backend.timeout(widget.code).catchError((_) => false);
  }

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
    if (!v.me.alive) return false;
    return switch (v.phase) {
      Phase.nomination || Phase.presidentDiscard || Phase.vetoResponse || Phase.power => v.amPresident,
      Phase.chancellorEnact => v.amNominee,
      Phase.election => !v.me.hasVoted,
      Phase.gameOver => false,
    };
  }

  @override
  void dispose() {
    Push.setCurrentGame(null);
    Music.play('menu');
    _viewSub.cancel();
    _roomSub.cancel();
    _ticker.cancel();
    _notes.dispose();
    super.dispose();
  }

  void _afterUpdate(GameView view) {
    if (view.autopilot.contains(view.you) && view.phase != Phase.gameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _kicked());
    }
    if (view.seerSees != null && _seerSeen == null && _roleShown) {
      final target = view.player(view.seerSees!);
      final traitor = target.knownRole != Role.loyal;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _alert(
          '🔮 كشف العرّاف',
          '${target.name} من ${traitor ? 'الخونة 🔴' : 'الأوفياء 🔵'}',
          'محد يدري إنك كشفته. استخدمها بذكاء 🤫',
        ),
      );
    }
    _seerSeen = view.seerSees;
    if (!_dangerShown && _introDone && view.traitorPolicies >= 3 && view.phase != Phase.gameOver) {
      _dangerShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLeaderDanger(view.yourRole));
    }
    if (!_roleShown) {
      _roleShown = true;
      _seenInvestigations = view.investigations.length;
      _seenLog = view.log.length;
      // الترحيب بس في بداية اللعبة (مو لو رجعت لها في النص)، وبعده جملة دورك لما تنقلب البطاقة.
      if (view.round == 1 && view.log.isEmpty) Sfx.say('intro');
      WidgetsBinding.instance.addPostFrameCallback((_) => _showRole());
    }
    _queueScenes(view);
    if (view.investigations.length > _seenInvestigations) {
      final result = view.investigations.last;
      _seenInvestigations = view.investigations.length;
      final name = view.player(result.target).name;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _alert(
          '🔍 نتيجة التحقيق',
          '$name من ${result.traitor ? 'الخونة 🔴' : 'الأوفياء 🔵'}',
          'هذي المعلومة لك بس. تقدر تقولها أو تكذب فيها 😏',
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
      final line = (view.winnerLoyal ?? false) ? 'win_loyal' : 'win_traitor';
      Future.delayed(Duration(milliseconds: 400 + 2600 * _scenes.length), () => Sfx.say(line));
    }
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
            VoteReveal(
              view: v,
              room: _room,
              votes: Map<String, bool>.from(d['votes'] as Map),
              passed: d['passed'] == true,
            ),
            d['passed'] == true ? 'gov_passed' : 'gov_failed',
            const Duration(milliseconds: 2800),
          ));
        case 'enacted':
          _scenes.add((
            EnactStamp(loyal: d['policy'] == 'L', chaos: d['chaos'] == true),
            d['chaos'] == true ? 'chaos' : (d['policy'] == 'L' ? 'enact_loyal' : 'enact_traitor'),
            const Duration(milliseconds: 1900),
          ));
        case 'executed' || 'guarded':
          final id = d['target'] as String;
          _scenes.add((
            ExecutionScene(
              name: id == v.you ? 'أنت' : v.player(id).name,
              avatar: _room?.player(id)?.avatar ?? 'masked',
              guarded: e.type == 'guarded',
            ),
            e.type == 'guarded' ? 'guarded' : 'executed',
            const Duration(milliseconds: 2600),
          ));
      }
    }
    if (wasEmpty && _scenes.isNotEmpty) Sfx.say(_scenes.first.$2);
  }

  void _nextScene() {
    if (!mounted || _scenes.isEmpty) return;
    setState(() => _scenes.removeAt(0));
    if (_scenes.isNotEmpty) Sfx.say(_scenes.first.$2);
  }

  Future<void> _act(Map<String, dynamic> action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _backend.act(widget.code, action);
    } on BackendException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// رأيي الحالي في لاعب: true أشك، false أثق، null ما عندي رأي.
  bool? _myOpinion(String target) => _room?.opinions[_backend.uid]?[target];

  Future<void> _react(ReactionKind kind, {String? target}) async {
    setState(() {
      _pendingReaction = null;
      _clearPick = false;
    });
    try {
      // نفس الرأي مرة ثانية على نفس اللاعب = تشيله (غيّرت رأيك).
      final same =
          target != null &&
          ((kind == ReactionKind.suspect && _myOpinion(target) == true) ||
              (kind == ReactionKind.trust && _myOpinion(target) == false));
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

  void _toast(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _alert(String title, String body, [String? note]) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                const _LeaderSeal(size: 110),
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
                      Text(
                        switch (role) {
                          Role.loyal => '🔵 دقّقوا في كل وزير قبل لا توافقون.',
                          Role.traitor => '🔴 فرصتكم: رشّحوا الزعيم وزير، وصوّتوا له.',
                          Role.leader => '👑 أنت الزعيم: لو صرت وزير، تفوزون!',
                        },
                        style: const TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w800),
                      ),
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

  /// ملاحظتك الخاصة على لاعب (ضغطة طويلة على صورته).
  void _editNote(String playerId) {
    final v = _view;
    if (v == null) return;
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerAvatar(avatar: _room?.player(playerId)?.avatar ?? 'masked', size: 56),
              const SizedBox(height: 6),
              Text(
                v.player(playerId).name,
                style: const TextStyle(fontFamily: kufi, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const Text('ملاحظتك الخاصة. محد يشوفها غيرك 🤫', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final (mark, label) in const [
                    (NoteMark.trust, '🟢 أثق فيه'),
                    (NoteMark.unsure, '🟡 مو متأكد'),
                    (NoteMark.suspect, '🔴 أشك فيه'),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GameButton(
                          label: label,
                          height: 46,
                          fontSize: 14,
                          tone: switch (mark) {
                            NoteMark.trust => ButtonTone.green,
                            NoteMark.suspect => ButtonTone.red,
                            NoteMark.unsure => ButtonTone.gold,
                          },
                          onPressed: () {
                            _notes.set(playerId, mark);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                ],
              ),
              if (_notes.of(playerId) != null)
                TextButton(
                  onPressed: () {
                    _notes.set(playerId, null);
                    Navigator.pop(context);
                  },
                  child: const Text('امسح الملاحظة'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// الردود السريعة: زر واحد يفتح القائمة، بدال الشات.
  void _openReactions() {
    final owned = _backend.profile.value.owned;
    final locked = ReactionKind.values.where((k) => k.pack != null && !owned.contains(k.pack)).length;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '💬 قول شي للطاولة',
                style: TextStyle(fontFamily: kufi, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (final k in ReactionKind.values)
                    if (k.pack == null || owned.contains(k.pack))
                      Semantics(
                        button: true,
                        label: 'رد ${k.name}',
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            k.needsTarget ? setState(() => _pendingReaction = k) : _react(k);
                          },
                          child: Container(
                            height: 46,
                            padding: EdgeInsets.symmetric(horizontal: k.label.isEmpty ? 12 : 16),
                            decoration: BoxDecoration(
                              color: k.pack == null ? AppColors.card : const Color(0xFF2E2346),
                              borderRadius: BorderRadius.circular(23),
                              border: Border.all(
                                color: (k.pack == null ? AppColors.gold : AppColors.diamond).withValues(alpha: .45),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                k.label.isEmpty ? k.emoji : '${k.emoji} ${k.label}',
                                style: TextStyle(fontSize: k.label.isEmpty ? 24 : 15, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
              if (locked > 0) ...[
                const SizedBox(height: 10),
                Text(
                  '🔒 فيه ${arabicNumber(locked)} رد زيادة في المتجر (تبويب الردود)',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                ),
              ],
              if ((_room?.opinions[_backend.uid] ?? const {}).isNotEmpty) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _pendingReaction = null;
                      _clearPick = true;
                    });
                  },
                  child: const Text('↩ أشيل رأيي في لاعب'),
                ),
              ],
            ],
          ),
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
          _confirm(v, 'تكشف فريق', id, {'type': 'seerReveal', 'target': id});
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
        (id) => _react(pending, target: id),
      );
    }
    if (_busy || !v.amPresident) return (const {}, null);
    final others = {
      for (final p in v.alive)
        if (p.id != v.you) p.id,
    };
    switch ((v.phase, v.pendingPower)) {
      case (Phase.nomination, _):
        return ({for (final p in v.eligibleChancellors) p.id}, (id) => _act({'type': 'nominate', 'chancellor': id}));
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

  /// الادعاء ينتظرك، وما عليك حركة ثانية الحين.
  bool _claimPending(GameView v) =>
      v.claimCount != null &&
      _claimDismissedRound != v.round &&
      v.phase != Phase.gameOver &&
      !_isMyTurn(v) &&
      _pendingReaction == null &&
      !_seerPicking;

  Future<void> _confirm(GameView v, String verb, String id, Map<String, dynamic> action) async {
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
    if (ok == true) await _act(action);
  }

  @override
  Widget build(BuildContext context) {
    final v = _view;
    if (v == null) {
      return const NightScaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }
    final (selectable, onSelect) = _selection(v);
    final (roleName, _, roleColor, _) = roleInfo[v.yourRole]!;
    final special = v.yourSpecial;

    final pickHint = _clearPick
        ? 'اختر اللاعب اللي تبي تشيل رأيك فيه'
        : _seerPicking
        ? '🔮 اختر لاعب تكشف فريقه (سراً)'
        : _pendingReaction == null
        ? null
        : '${_pendingReaction!.emoji} ${_pendingReaction!.label} اختر لاعب';
    final over = v.phase == Phase.gameOver;

    return PopScope(
      canPop: over || _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: NightScaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // الطاولة على الشاشة كلها، والباقي يطفو في الزوايا.
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 34, 20, 2),
                  child: GameTable(
                    view: v,
                    room: _room,
                    notes: _notes,
                    selectable: selectable,
                    onSelect: onSelect,
                    onNote: _editNote,
                    spotlight: v.phase == Phase.election && pickHint == null ? {v.presidentId, ?v.nomineeId} : null,
                    center: _TableCenter(view: v, room: _room),
                  ),
                ),
              ),
              if (v.deadline != null && !over) Positioned(top: 0, left: 0, right: 0, child: _TopTimer(view: v)),
              // بعد ٣ قرارات للخونة: لو الزعيم صار وزير يفوزون. نذكّر الكل وقت الترشيح والتصويت.
              if (v.traitorPolicies >= 3 && (v.phase == Phase.nomination || v.phase == Phase.election))
                Positioned(top: 10, left: 0, right: 0, child: Center(child: _LeaderDanger(role: v.yourRole))),
              // فوق يمين: الجولة ودورك
              PositionedDirectional(
                top: 8,
                start: 10,
                child: _RoundHud(
                  view: v,
                  roleName: roleName,
                  roleColor: roleColor,
                  special: special,
                  onRole: _showRole,
                  onBack: over ? () => Navigator.of(context).maybePop() : _confirmLeave,
                ),
              ),
              // فوق يسار: النقاط مصغرة، تنضغط وتكبر
              PositionedDirectional(
                top: 8,
                end: 10,
                child: MiniTracks(view: v, onTap: () => showTracksBoard(context, v)),
              ),
              // تحت يمين: التفاعل والعرّاف
              if (!over)
                PositionedDirectional(
                  bottom: 10,
                  start: 10,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (v.seerReady) ...[
                        _RoundButton(
                          emoji: '🔮',
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
                      _RoundButton(emoji: '💬', label: 'تفاعل', color: AppColors.gold, onTap: _openReactions),
                    ],
                  ),
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
                        icon: muted ? 'mute' : 'sound',
                        label: muted ? 'شغّل الصوت' : 'اكتم الصوت',
                        size: 40,
                        onTap: Sfx.toggle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder(
                      valueListenable: Music.muted,
                      builder: (context, muted, _) => _RoundButton(
                        emoji: muted ? '🔇' : '🎵',
                        label: muted ? 'شغّل الموسيقى' : 'اكتم الموسيقى',
                        size: 40,
                        onTap: Music.toggle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RoundButton(icon: 'scroll', label: 'السجل', size: 40, onTap: () => showGameLog(context, v)),
                  ],
                ),
              ),
              // حركتك أنت
              ..._actionLayer(v, pickHint),
              if (_claimPending(v))
                Center(
                  child: _ClaimPrompt(
                    count: v.claimCount!,
                    president: v.claimCount == 3,
                    busy: _busy,
                    onClaim: (policies) => _act({
                      'type': 'claim',
                      'policies': [for (final p in policies) p.code],
                    }),
                    onLater: () => setState(() => _claimDismissedRound = v.round),
                  ),
                ),
              if (over && _scenes.isEmpty) _GameOver(view: v, room: _room),
              if (_scenes.isNotEmpty)
                Positioned.fill(
                  child: EventOverlay(
                    key: ObjectKey(_scenes.first),
                    duration: _scenes.first.$3,
                    onDone: _nextScene,
                    child: _scenes.first.$1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _leaving = false;
  bool _kickShown = false;

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
    switch (v.phase) {
      case Phase.nomination when v.amPresident:
        return [_banner('👑 أنت الرئيس! اختر وزير من الطاولة')];
      case Phase.election when !v.me.hasVoted:
        return [
          _besideSeat(
            yes: GameButton(
              label: 'موافق',
              semantics: 'موافق',
              tone: ButtonTone.green,
              height: 50,
              onPressed: _busy ? null : () => _act({'type': 'vote', 'ja': true}),
            ),
            no: GameButton(
              label: 'رافض',
              semantics: 'رافض',
              tone: ButtonTone.red,
              height: 50,
              onPressed: _busy ? null : () => _act({'type': 'vote', 'ja': false}),
            ),
          ),
        ];
      case Phase.vetoResponse when v.amPresident:
        return [
          _banner('✋ الوزير يبي يرمي الكرتين. توافق؟', bottom: 184),
          _besideSeat(
            yes: GameButton(
              label: 'موافق',
              tone: ButtonTone.green,
              height: 50,
              onPressed: _busy ? null : () => _act({'type': 'respondVeto', 'accept': true}),
            ),
            no: GameButton(
              label: 'رافض',
              tone: ButtonTone.red,
              height: 50,
              onPressed: _busy ? null : () => _act({'type': 'respondVeto', 'accept': false}),
            ),
          ),
        ];
      case Phase.presidentDiscard when v.amPresident:
        return [
          _hand(
            '🃏 اختر الكرت اللي بترميه (سري)',
            _cards(v.hand, (i) => _act({'type': 'discard', 'index': i}), 'ارمِ'),
          ),
        ];
      case Phase.chancellorEnact when v.amNominee:
        return [
          _hand(
            '📜 اختر الكرت اللي بتمرره',
            _cards(v.hand, (i) => _act({'type': 'enact', 'index': i}), 'مرّر'),
            extra: v.canVeto
                ? TextButton(
                    onPressed: _busy ? null : () => _act({'type': 'proposeVeto'}),
                    child: const Text('✋ اطلب فيتو (نرمي الاثنين)'),
                  )
                : null,
          ),
        ];
      case Phase.power when v.amPresident && v.pendingPower == Power.peek:
        return [
          _hand(
            '👁️ أول ٣ كروت في الكومة (لك بس)',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final p in v.peeked ?? const <Policy>[])
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: PolicyCard(policy: p, skin: _skin, width: 66),
                  ),
              ],
            ),
            extra: SizedBox(
              width: 160,
              child: GameButton(
                label: 'تمام',
                height: 42,
                fontSize: 16,
                onPressed: _busy ? null : () => _act({'type': 'acknowledgePeek'}),
              ),
            ),
          ),
        ];
      case Phase.power when v.amPresident:
        return [_banner('${powerEmoji[v.pendingPower]} ${powerName[v.pendingPower]}: اختر لاعب من الطاولة')];
      default:
        return const [];
    }
  }

  /// سطر تعليمات فوق مقعدك.
  Widget _banner(String text, {VoidCallback? onCancel, double bottom = 112}) => Positioned(
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
  Widget _besideSeat({required Widget yes, required Widget no}) => Positioned.fill(
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
      ],
    ),
  );

  /// الكروت في نص الطاولة.
  Widget _hand(String hint, Widget cards, {Widget? extra}) => Center(
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: .6), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 24)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hint,
            style: const TextStyle(fontFamily: kufi, fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          cards,
          if (extra != null) ...[const SizedBox(height: 6), extra],
        ],
      ),
    ),
  );

  Widget _cards(List<Policy> hand, void Function(int) onPick, String verb) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, p) in hand.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + i * 120),
              curve: Curves.easeOutBack,
              builder: (context, t, child) => Transform.translate(
                offset: Offset(0, 40 * (1 - t)),
                child: Opacity(opacity: t.clamp(0, 1), child: child),
              ),
              child: PolicyCard(
                policy: p,
                skin: _skin,
                width: 84,
                label: '$verb كرت ${i + 1} ${p == Policy.loyal ? 'أوفياء' : 'خونة'}',
                onTap: _busy ? null : () => onPick(i),
              ),
            ),
          ),
      ],
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
        : deadline.difference(DateTime.now()).inSeconds.clamp(0, 99);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: .85),
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
              if (onBack != null) GestureDetector(onTap: onBack, child: const Icon(Icons.arrow_forward, size: 18)),
              Text(
                'الجولة ${arabicNumber(view.round)}',
                style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              if (left != null) ...[
                const SizedBox(width: 8),
                Text(
                  '⏳${arabicNumber(left)}',
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
              child: Text(
                '$roleName${special == null ? '' : ' ${special == Special.seer ? '🔮' : '🛡️'}'}',
                style: TextStyle(
                  color: roleColor == AppColors.loyal ? AppColors.loyalLight : AppColors.traitorLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// زر دائري يطفو في الزاوية.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.label,
    required this.onTap,
    this.emoji,
    this.icon,
    this.color = AppColors.muted,
    this.size = 52,
    this.active = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? emoji;
  final String? icon;
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
          child: emoji != null
              ? Text(emoji!, style: TextStyle(fontSize: size * .45))
              : GameIcon(icon!, size: size * .5, color: color),
        ),
      ),
    );
  }
}

/// شريط الوقت على حافة الشاشة فوق. يحمر في آخر ٥ ثواني.
class _TopTimer extends StatelessWidget {
  const _TopTimer({required this.view});

  final GameView view;

  @override
  Widget build(BuildContext context) {
    final total = _phaseSeconds[view.phase] ?? 30;
    final left = view.deadline!.difference(DateTime.now()).inMilliseconds.clamp(0, total * 1000) / 1000;
    final urgent = left <= 5;
    return LinearProgressIndicator(
      value: left / total,
      minHeight: 4,
      backgroundColor: Colors.transparent,
      color: urgent ? AppColors.traitor : AppColors.gold,
    );
  }
}

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
    String name(String? id) => id == null ? '' : (id == v.you ? 'أنت' : v.player(id).name);
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

/// الادعاء بعد الحكم: وش وصلك من كروت؟ يطلع فوق الطاولة بخيارات كبيرة وواضحة.
class _ClaimPrompt extends StatelessWidget {
  const _ClaimPrompt({
    required this.count,
    required this.president,
    required this.busy,
    required this.onClaim,
    required this.onLater,
  });

  final int count;
  final bool president;
  final bool busy;
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

  static String _label(List<Policy> option) {
    final t = option.where((p) => p == Policy.traitor).length;
    final l = option.length - t;
    return [if (t > 0) '${arabicNumber(t)} خونة', if (l > 0) '${arabicNumber(l)} أوفياء'].join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: .6), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 24)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GoldText(president ? '📢 وش وصلك وأنت رئيس؟' : '📢 وش وصلك وأنت وزير؟', size: 20),
          Text(
            'وصلك ${arabicNumber(count)} كروت. اختيارك يطلع للكل… قول الصدق أو اكذب 😏',
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final option in _options[count]!)
                Semantics(
                  button: true,
                  label: 'ادعاء ${option.map((p) => p.code).join()}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: busy ? null : () => onClaim(option),
                    child: Container(
                      width: 104,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFBF1DA), AppColors.parchmentDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.goldDark, width: 2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final p in option)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 1),
                                  child: Seal(loyal: p == Policy.loyal, size: 28),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _label(option),
                            style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          TextButton(onPressed: onLater, child: const Text('بعدين')),
        ],
      ),
    );
  }
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

class _GameOver extends StatelessWidget {
  const _GameOver({required this.view, required this.room});

  final GameView view;
  final Room? room;

  @override
  Widget build(BuildContext context) {
    final loyalWon = view.winnerLoyal ?? false;
    final iWon = (view.yourRole == Role.loyal) == loyalWon;
    final teamColor = loyalWon ? AppColors.loyal : AppColors.traitor;
    final roles = [
      for (final p in view.players)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              PlayerAvatar(avatar: room?.player(p.id)?.avatar ?? 'masked', size: 32, dead: !p.alive),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  p.id == view.you ? 'أنت' : p.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (p.knownSpecial != null)
                Text('${specialInfo[p.knownSpecial]!.$1}  ', style: const TextStyle(fontSize: 12)),
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
    ];
    return Container(
      color: Colors.black.withValues(alpha: .78),
      padding: const EdgeInsets.all(12),
      child: Center(
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        iWon ? const Gfx('trophy', size: 64) : const Text('💔', style: TextStyle(fontSize: 50)),
                        GoldText(iWon ? 'فزت!' : 'خسرت', size: 36),
                        const SizedBox(height: 2),
                        Text(
                          '${loyalWon ? 'فاز الأوفياء 🔵' : 'فاز الخونة 🔴'}\n${_winReasons[view.winReason] ?? ''}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Color(0xFFD9CFFF)),
                        ),
                        if (room?.results[view.you] case final r?) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (r.coins > 0) _Reward('+${arabicNumber(r.coins)}', AppColors.gold, icon: 'coin'),
                              if (r.coins > 0) const SizedBox(width: 10),
                              _Reward('+${arabicNumber(r.xp)}', AppColors.diamond, icon: 'xp'),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        GameButton(
                          label: '🏠 الرئيسية',
                          semantics: 'الرئيسية',
                          height: 48,
                          fontSize: 17,
                          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                        ),
                      ],
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
    );
  }
}

/// ختم الخونة وفوقه تاج: رمز زعيم الخونة.
class _LeaderSeal extends StatelessWidget {
  const _LeaderSeal({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * 1.12,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Seal(loyal: false, size: size),
        Positioned(top: 0, child: GameIcon('crown', size: size * .42, color: AppColors.gold)),
      ],
    ),
  );
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
          const _LeaderSeal(size: 34),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: mine ? 'لو صرت وزير ' : 'الزعيم وزير ',
                  style: const TextStyle(color: AppColors.gold),
                ),
                const TextSpan(text: '= '),
                const TextSpan(text: 'فوز الخونة', style: TextStyle(color: Color(0xFFFF8A8A))),
              ],
            ),
            style: const TextStyle(fontFamily: kufi, fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
