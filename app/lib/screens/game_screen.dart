import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_view.dart';
import '../models/room.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/notes.dart';
import '../services/push.dart';
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

  /// مشاهد تنتظر دورها فوق الطاولة (كشف التصويت، الختم، الطرد…).
  final List<(Widget, String, Duration)> _scenes = [];

  /// رد ينتظر تختار له لاعب (مثل أشك في…).
  ReactionKind? _pendingReaction;

  /// العرّاف ضغط "اكشف" وينتظر يختار لاعب.
  bool _seerPicking = false;
  String? _seerSeen;

  @override
  void initState() {
    super.initState();
    Push.setCurrentGame(widget.code);
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

  /// صوت تكتكة في آخر ٥ ثواني من دورك.
  void _tick() {
    final v = _view;
    final deadline = v?.deadline;
    if (v == null || deadline == null || !_isMyTurn(v)) return;
    final left = deadline.difference(DateTime.now()).inSeconds;
    if (left >= 0 && left <= 5) Sfx.play('tick');
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
    _viewSub.cancel();
    _roomSub.cancel();
    _ticker.cancel();
    _notes.dispose();
    super.dispose();
  }

  void _afterUpdate(GameView view) {
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
    if (!_roleShown) {
      _roleShown = true;
      _seenInvestigations = view.investigations.length;
      _seenLog = view.log.length;
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
    if (myTurn && !_wasMyTurn) {
      HapticFeedback.mediumImpact();
      Sfx.play('alert');
    }
    _wasMyTurn = myTurn;
    if (view.phase == Phase.gameOver && !_endSoundPlayed) {
      _endSoundPlayed = true;
      final iWon = (view.yourRole == Role.loyal) == (view.winnerLoyal ?? false);
      Future.delayed(Duration(milliseconds: 400 + 2600 * _scenes.length), () => Sfx.play(iWon ? 'win' : 'lose'));
    }
  }

  /// أحداث جديدة في السجل تطلع كمشاهد قصيرة فوق الطاولة.
  void _queueScenes(GameView v) {
    final from = _seenLog ?? v.log.length;
    _seenLog = v.log.length;
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
            'vote',
            const Duration(milliseconds: 2800),
          ));
        case 'enacted':
          _scenes.add((
            EnactStamp(loyal: d['policy'] == 'L', chaos: d['chaos'] == true),
            'stamp',
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
            e.type == 'guarded' ? 'guard' : 'execute',
            const Duration(milliseconds: 2600),
          ));
      }
    }
    if (_scenes.isNotEmpty) Sfx.play(_scenes.first.$2);
  }

  void _nextScene() {
    if (!mounted || _scenes.isEmpty) return;
    setState(() => _scenes.removeAt(0));
    if (_scenes.isNotEmpty) Sfx.play(_scenes.first.$2);
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

  Future<void> _react(ReactionKind kind, {String? target}) async {
    setState(() => _pendingReaction = null);
    try {
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

  void _showRole() {
    final view = _view;
    if (view == null || !mounted) return;
    showRoleReveal(context, view, _room);
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
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
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(color: AppColors.gold.withValues(alpha: .35), width: 1.5),
                          ),
                          child: Text(
                            k.label.isEmpty ? k.emoji : '${k.emoji} ${k.label}',
                            style: TextStyle(fontSize: k.label.isEmpty ? 24 : 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _name(GameView v, String? id) => id == null ? '' : (id == v.you ? 'أنت' : v.player(id).name);

  /// اللاعبين اللي ينفع تختارهم من الطاولة الحين، ووش يصير لما تختار.
  (Set<String>, void Function(String)?) _selection(GameView v) {
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

    return PopScope(
      canPop: v.phase == Phase.gameOver,
      child: NightScaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Row(
                children: [
                  // اللوحة الجانبية (يمين): الجولة والمسارات وحركتك والردود.
                  _SidePanel(
                    header: Row(
                      children: [
                        if (v.phase == Phase.gameOver)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_forward, size: 20),
                          ),
                        Text(
                          'الجولة ${arabicNumber(v.round)}',
                          style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 17),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: GestureDetector(
                            onTap: _showRole,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: .15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: roleColor.withValues(alpha: .6)),
                              ),
                              child: Text(
                                '$roleName${special == null ? '' : ' ${special == Special.seer ? '🔮' : '🛡️'}'}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: roleColor == AppColors.loyal ? AppColors.loyalLight : AppColors.traitorLight,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        ValueListenableBuilder(
                          valueListenable: Sfx.muted,
                          builder: (context, muted, _) => IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: muted ? 'شغّل الصوت' : 'اكتم الصوت',
                            onPressed: Sfx.toggle,
                            icon: GameIcon(muted ? 'mute' : 'sound', size: 20, color: AppColors.muted),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'السجل',
                          onPressed: () => showGameLog(context, v),
                          icon: const GameIcon('scroll', size: 22, color: AppColors.gold),
                        ),
                      ],
                    ),
                    tracks: PolicyTracks(view: v),
                    action: _ActionPanel(
                      view: v,
                      busy: _busy,
                      name: (id) => _name(v, id),
                      pickHint: _seerPicking
                          ? '🔮 اختر لاعب من الطاولة تكشف فريقه (سراً) 👈'
                          : _pendingReaction == null
                          ? null
                          : '${_pendingReaction!.emoji} ${_pendingReaction!.label} اختر لاعب من الطاولة 👈',
                      claimPending: _claimPending(v),
                      onAct: _act,
                      onCancelPick: () => setState(() {
                        _pendingReaction = null;
                        _seerPicking = false;
                      }),
                    ),
                    footer: v.phase == Phase.gameOver
                        ? null
                        : Row(
                            children: [
                              Expanded(
                                child: GameButton(
                                  label: '💬 تفاعل',
                                  semantics: 'تفاعل',
                                  tone: ButtonTone.ghost,
                                  height: 40,
                                  fontSize: 15,
                                  onPressed: _openReactions,
                                ),
                              ),
                              if (v.seerReady) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GameButton(
                                    label: '🔮 اكشف',
                                    semantics: 'كشف العراف',
                                    tone: ButtonTone.purple,
                                    height: 40,
                                    fontSize: 15,
                                    onPressed: () => setState(() {
                                      _pendingReaction = null;
                                      _seerPicking = !_seerPicking;
                                    }),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 26, 4, 4),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: GameTable(
                              view: v,
                              room: _room,
                              notes: _notes,
                              selectable: selectable,
                              onSelect: onSelect,
                              onNote: _editNote,
                              spotlight: v.phase == Phase.election ? {v.presidentId, ?v.nomineeId} : null,
                              center: _TableCenter(view: v, name: (id) => _name(v, id)),
                            ),
                          ),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (v.phase == Phase.gameOver && _scenes.isEmpty) _GameOver(view: v, room: _room),
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
}

/// اللوحة الجانبية بالعرض: فوق الجولة والمسارات، وتحت حركتك والردود السريعة.
class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.header, required this.tracks, required this.action, this.footer});

  final Widget header;
  final Widget tracks;
  final Widget action;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 290,
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xEE221A46), Color(0xEE160F2E)],
        ),
        borderRadius: const BorderRadiusDirectional.horizontal(end: Radius.circular(24)),
        border: BorderDirectional(end: BorderSide(color: AppColors.gold.withValues(alpha: .35), width: 2)),
      ),
      child: Column(
        children: [
          header,
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(width: 380, child: tracks),
          ),
          Divider(height: 12, color: AppColors.gold.withValues(alpha: .2)),
          Expanded(child: action),
          if (footer != null) ...[const SizedBox(height: 6), footer!],
        ],
      ),
    );
  }
}

/// الرسالة في نص الصينية: وش يصير الحين.
class _TableCenter extends StatelessWidget {
  const _TableCenter({required this.view, required this.name});

  final GameView view;
  final String Function(String?) name;

  @override
  Widget build(BuildContext context) {
    final v = view;
    final pres = name(v.presidentId);
    final nominee = name(v.nomineeId);
    final (icon, text) = switch (v.phase) {
      Phase.nomination => ('👑', '$pres يختار وزير'),
      Phase.election => ('🗳️', 'التصويت'),
      Phase.presidentDiscard => ('🃏', '$pres يختار الكروت'),
      Phase.chancellorEnact => ('📜', '$nominee يمرر قرار'),
      Phase.vetoResponse => ('✋', 'الوزير طلب فيتو'),
      Phase.power => (powerEmoji[v.pendingPower]!, '$pres يستخدم ${powerName[v.pendingPower]}'),
      Phase.gameOver => ('🏁', 'انتهت اللعبة'),
    };
    final lastClaims = v.claims.where((c) => c.round == v.claims.lastOrNull?.round).toList();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.3),
            ),
            if (lastClaims.isNotEmpty) ...[
              const SizedBox(height: 3),
              for (final c in lastClaims)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${c.president ? '👑' : '📜'} ', style: const TextStyle(fontSize: 11)),
                    MiniPolicies(c.policies, size: 9),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// شريط الوقت المتبقي للدور. يحمر في آخر ٥ ثواني.
class _TurnTimer extends StatelessWidget {
  const _TurnTimer({required this.view});

  final GameView view;

  @override
  Widget build(BuildContext context) {
    final total = _phaseSeconds[view.phase] ?? 30;
    final left = view.deadline!.difference(DateTime.now()).inSeconds.clamp(0, total);
    final urgent = left <= 5;
    final color = urgent ? AppColors.traitor : AppColors.gold;
    return Row(
      children: [
        Text('⏳', style: TextStyle(fontSize: urgent ? 16 : 14)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: left / total,
              minHeight: 8,
              backgroundColor: Colors.black.withValues(alpha: .4),
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            arabicNumber(left),
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: kufi, color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.view,
    required this.busy,
    required this.name,
    required this.pickHint,
    required this.claimPending,
    required this.onAct,
    required this.onCancelPick,
  });

  final GameView view;
  final bool busy;
  final String Function(String?) name;

  /// تختار لاعب من الطاولة (رد أو كشف العرّاف).
  final String? pickHint;
  final bool claimPending;
  final ValueChanged<Map<String, dynamic>> onAct;
  final VoidCallback onCancelPick;

  /// شكل الكروت اللي لابسه اللاعب من المتجر.
  CardSkin get _skin => cardSkin(Backend.instance.profile.value.cards);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (view.deadline != null && view.phase != Phase.gameOver) ...[
          _TurnTimer(view: view),
          const SizedBox(height: 6),
        ],
        Expanded(
          child: Center(child: SingleChildScrollView(child: _main(context))),
        ),
      ],
    );
  }

  Widget _hint(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFFD9CFFF), fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );

  Widget _main(BuildContext context) {
    final v = view;
    if (pickHint != null) {
      return Column(
        children: [
          _hint(pickHint!),
          TextButton(onPressed: onCancelPick, child: const Text('إلغاء')),
        ],
      );
    }
    final required = _required(v);
    if (required != null) return required;
    if (claimPending) return _hint('📢 قول للكل وش وصلك من كروت 👈');
    return _waiting(v);
  }

  /// الحركة المطلوبة منك الحين، لو فيه. لها أولوية على الادعاء.
  Widget? _required(GameView v) {
    switch (v.phase) {
      case Phase.nomination when v.amPresident:
        return _hint('👑 أنت الرئيس! اختر وزير من الطاولة 👆');
      case Phase.election when !v.me.hasVoted && v.me.alive:
        return Column(
          children: [
            const Text(
              'صوّت على الحكومة',
              style: TextStyle(fontFamily: kufi, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GameButton(
                    label: 'موافق',
                    semantics: 'موافق',
                    tone: ButtonTone.green,
                    onPressed: busy ? null : () => onAct({'type': 'vote', 'ja': true}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GameButton(
                    label: 'رافض',
                    semantics: 'رافض',
                    tone: ButtonTone.red,
                    onPressed: busy ? null : () => onAct({'type': 'vote', 'ja': false}),
                  ),
                ),
              ],
            ),
          ],
        );
      case Phase.presidentDiscard when v.amPresident:
        return Column(
          children: [
            _hint('🃏 اختر الكرت اللي بترميه (سري)، والباقي يروح للوزير'),
            _cards(v.hand, (i) => onAct({'type': 'discard', 'index': i}), 'ارمِ'),
          ],
        );
      case Phase.chancellorEnact when v.amNominee:
        return Column(
          children: [
            _hint('📜 اختر الكرت اللي بتمرره'),
            _cards(v.hand, (i) => onAct({'type': 'enact', 'index': i}), 'مرّر'),
            if (v.canVeto)
              TextButton(
                onPressed: busy ? null : () => onAct({'type': 'proposeVeto'}),
                child: const Text('✋ اطلب فيتو (نرمي الاثنين)'),
              ),
          ],
        );
      case Phase.vetoResponse when v.amPresident:
        return Column(
          children: [
            _hint('✋ الوزير يبي يرمي الكرتين. توافق؟'),
            Row(
              children: [
                Expanded(
                  child: GameButton(
                    label: 'موافق',
                    tone: ButtonTone.green,
                    onPressed: busy ? null : () => onAct({'type': 'respondVeto', 'accept': true}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GameButton(
                    label: 'رافض',
                    tone: ButtonTone.red,
                    onPressed: busy ? null : () => onAct({'type': 'respondVeto', 'accept': false}),
                  ),
                ),
              ],
            ),
          ],
        );
      case Phase.power when v.amPresident && v.pendingPower == Power.peek:
        return Column(
          children: [
            _hint('👁️ هذي أول ٣ كروت في الكومة (لك بس)'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final p in v.peeked ?? const <Policy>[])
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: PolicyCard(policy: p, skin: _skin, width: 66),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GameButton(
              label: 'تمام',
              height: 46,
              fontSize: 17,
              onPressed: busy ? null : () => onAct({'type': 'acknowledgePeek'}),
            ),
          ],
        );
      case Phase.power when v.amPresident:
        return _hint('${powerEmoji[v.pendingPower]} ${powerName[v.pendingPower]}: اختر لاعب من الطاولة 👆');
      default:
        return null;
    }
  }

  Widget _waiting(GameView v) {
    switch (v.phase) {
      case Phase.election:
        final waiting = v.alive.where((p) => !p.hasVoted).length;
        return _hint('⏳ ننتظر ${arabicNumber(waiting)} يصوّتون…');
      case Phase.gameOver:
        return const SizedBox.shrink();
      default:
        final who = switch (v.phase) {
          Phase.chancellorEnact => name(v.nomineeId),
          _ => name(v.presidentId),
        };
        return _hint('⏳ ننتظر $who…');
    }
  }

  Widget _cards(List<Policy> hand, void Function(int) onPick, String verb) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (i, p) in hand.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
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
                width: hand.length == 3 ? 72 : 80,
                label: '$verb كرت ${i + 1} ${p == Policy.loyal ? 'أوفياء' : 'خونة'}',
                onTap: busy
                    ? null
                    : () {
                        Sfx.play('flip');
                        onPick(i);
                      },
              ),
            ),
          ),
      ],
    );
  }
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
  const _Reward(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: .7), width: 1.5),
    ),
    child: Text(
      text,
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
                        Text(iWon ? '🏆' : '💔', style: const TextStyle(fontSize: 50)),
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
                              if (r.coins > 0) _Reward('+${arabicNumber(r.coins)} 🪙', AppColors.gold),
                              if (r.coins > 0) const SizedBox(width: 10),
                              _Reward('+${arabicNumber(r.xp)} ⭐', AppColors.diamond),
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
