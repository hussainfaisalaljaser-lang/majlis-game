import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_view.dart';
import '../models/room.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/game/game_log.dart';
import '../widgets/game/game_table.dart';
import '../widgets/game/policy_card.dart';
import '../widgets/game/tracks.dart';

const _roleInfo = {
  Role.loyal: ('🔵', 'وفي', 'اكشف الخونة ومرّر ٥ قرارات زرقاء', AppColors.loyal),
  Role.traitor: ('🔴', 'خائن', 'ساعد زعيمك يوصل للحكم بدون ما تنكشف', AppColors.traitor),
  Role.leader: ('🦹', 'زعيم الخونة', 'خلّهم يثقون فيك وينتخبونك مستشار', AppColors.traitor),
};

const _winReasons = {
  'loyalPolicies': 'تمررت ٥ قرارات للأوفياء',
  'traitorPolicies': 'تمررت ٦ قرارات للخونة',
  'leaderElected': 'الزعيم انتُخب مستشار',
  'leaderExecuted': 'الزعيم انطرد',
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

  GameView? _view;
  Room? _room;
  bool _busy = false;
  bool _roleShown = false;
  int _seenInvestigations = 0;
  int? _claimDismissedRound;

  /// رد ينتظر تختار له لاعب (مثل أشك في…).
  ReactionKind? _pendingReaction;

  @override
  void initState() {
    super.initState();
    _viewSub = _backend.watchView(widget.code).listen((data) {
      if (data == null || !mounted) return;
      final view = GameView.fromJson(data);
      setState(() => _view = view);
      _afterUpdate(view);
    });
    _roomSub = _backend.watchRoom(widget.code).listen((room) {
      if (mounted) setState(() => _room = room);
    });
    // عشان فقاعات الردود تختفي بعد كم ثانية.
    // كل ثانية: نحدّث العداد وفقاعات الردود، ونطلب من السيرفر يكمّل لو خلص الوقت.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _checkTimeout();
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

  @override
  void dispose() {
    _viewSub.cancel();
    _roomSub.cancel();
    _ticker.cancel();
    super.dispose();
  }

  void _afterUpdate(GameView view) {
    if (!_roleShown) {
      _roleShown = true;
      _seenInvestigations = view.investigations.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showRole());
    }
    if (view.investigations.length > _seenInvestigations) {
      final result = view.investigations.last;
      _seenInvestigations = view.investigations.length;
      final name = view.player(result.target).name;
      WidgetsBinding.instance.addPostFrameCallback((_) => _alert(
            '🔍 نتيجة التحقيق',
            '$name من ${result.traitor ? 'الخونة 🔴' : 'الأوفياء 🔵'}',
            'هذي المعلومة لك بس. تقدر تقولها أو تكذب فيها 😏',
          ));
    }
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
        backgroundColor: AppColors.panel,
        title: Text(title, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            if (note != null) ...[
              const SizedBox(height: 10),
              Text(note, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            ],
          ],
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('تمام'))],
      ),
    );
  }

  void _showRole() {
    final view = _view;
    if (view == null || !mounted) return;
    final (emoji, name, goal, color) = _roleInfo[view.yourRole]!;
    final mates = view.players.where((p) => p.id != view.you && p.knownRole != null).toList();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('دورك السري 🤫', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            Text(emoji, style: const TextStyle(fontSize: 64)),
            Text(name, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 6),
            Text(goal, textAlign: TextAlign.center),
            if (mates.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('أعوانك:', style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 4),
              for (final m in mates)
                Text(
                  '${m.knownRole == Role.leader ? '🦹 الزعيم' : '🔴 خائن'}: ${m.name}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
            ],
          ],
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('فهمت'))],
      ),
    );
  }

  String _name(GameView v, String? id) => id == null ? '' : (id == v.you ? 'أنت' : v.player(id).name);

  /// اللاعبين اللي ينفع تختارهم من الطاولة الحين، ووش يصير لما تختار.
  (Set<String>, void Function(String)?) _selection(GameView v) {
    final pending = _pendingReaction;
    if (pending != null) {
      return ({for (final p in v.players) if (p.id != v.you) p.id}, (id) => _react(pending, target: id));
    }
    if (_busy || !v.amPresident) return (const {}, null);
    final others = {for (final p in v.alive) if (p.id != v.you) p.id};
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

  Future<void> _confirm(GameView v, String verb, String id, Map<String, dynamic> action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text('متأكد $verb ${v.player(id).name}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إيه')),
        ],
      ),
    );
    if (ok == true) await _act(action);
  }

  @override
  Widget build(BuildContext context) {
    final v = _view;
    if (v == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final (selectable, onSelect) = _selection(v);
    final (emoji, roleName, _, roleColor) = _roleInfo[v.yourRole]!;

    return PopScope(
      canPop: v.phase == Phase.gameOver,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: v.phase == Phase.gameOver,
          title: Text('الجولة ${arabicNumber(v.round)}', style: const TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            TextButton(
              onPressed: _showRole,
              child: Text('$emoji $roleName', style: TextStyle(color: roleColor, fontWeight: FontWeight.w800)),
            ),
            IconButton(
              tooltip: 'السجل',
              onPressed: () => showGameLog(context, v),
              icon: const Text('📜', style: TextStyle(fontSize: 22)),
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: PolicyTracks(view: v),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 28, 8, 4),
                      child: GameTable(
                        view: v,
                        room: _room,
                        selectable: selectable,
                        onSelect: onSelect,
                        center: _TableCenter(view: v, name: (id) => _name(v, id)),
                      ),
                    ),
                  ),
                  _ActionPanel(
                    view: v,
                    busy: _busy,
                    name: (id) => _name(v, id),
                    pendingReaction: _pendingReaction,
                    claimDismissed: _claimDismissedRound == v.round,
                    onAct: _act,
                    onReact: (kind) => kind.needsTarget ? setState(() => _pendingReaction = kind) : _react(kind),
                    onCancelReaction: () => setState(() => _pendingReaction = null),
                    onDismissClaim: () => setState(() => _claimDismissedRound = v.round),
                  ),
                ],
              ),
              if (v.phase == Phase.gameOver) _GameOver(view: v, room: _room),
            ],
          ),
        ),
      ),
    );
  }
}

/// الرسالة في نص الطاولة: وش يصير الحين.
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
      Phase.nomination => ('👑', '$pres يختار مستشار'),
      Phase.election => ('🗳️', 'تصويت على $pres + $nominee'),
      Phase.presidentDiscard => ('🃏', '$pres يختار الكروت'),
      Phase.chancellorEnact => ('📜', '$nominee يمرر قرار'),
      Phase.vetoResponse => ('✋', 'المستشار طلب فيتو'),
      Phase.power => (powerEmoji[v.pendingPower]!, '$pres يستخدم ${powerName[v.pendingPower]}'),
      Phase.gameOver => ('🏁', 'انتهت اللعبة'),
    };
    final lastClaims = v.claims.where((c) => c.round == v.claims.lastOrNull?.round).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        if (lastClaims.isNotEmpty) ...[
          const SizedBox(height: 4),
          for (final c in lastClaims)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${c.president ? '👑' : '📜'} ', style: const TextStyle(fontSize: 11)),
                MiniPolicies(c.policies, size: 10),
              ],
            ),
        ],
      ],
    );
  }
}

/// شريط الوقت المتبقي للدور. يحمر في آخر ٥ ثواني.
class _TurnTimer extends StatelessWidget {
  const _TurnTimer({required this.view});

  final GameView view;

  /// نفس engine/src/rules.ts → PHASE_SECONDS.
  static const _seconds = {
    Phase.nomination: 30,
    Phase.election: 25,
    Phase.presidentDiscard: 20,
    Phase.chancellorEnact: 20,
    Phase.vetoResponse: 15,
    Phase.power: 30,
  };

  @override
  Widget build(BuildContext context) {
    final total = _seconds[view.phase] ?? 30;
    final left = view.deadline!.difference(DateTime.now()).inSeconds.clamp(0, total);
    final urgent = left <= 5;
    final color = urgent ? AppColors.traitor : AppColors.gold;
    return Row(
      children: [
        Text('⏱️', style: TextStyle(fontSize: urgent ? 16 : 14)),
        const SizedBox(width: 6),
        Expanded(
          child: LinearProgressIndicator(
            value: left / total,
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: AppColors.card,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            arabicNumber(left),
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
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
    required this.pendingReaction,
    required this.claimDismissed,
    required this.onAct,
    required this.onReact,
    required this.onCancelReaction,
    required this.onDismissClaim,
  });

  final GameView view;
  final bool busy;
  final String Function(String?) name;
  final ReactionKind? pendingReaction;
  final bool claimDismissed;
  final ValueChanged<Map<String, dynamic>> onAct;
  final ValueChanged<ReactionKind> onReact;
  final VoidCallback onCancelReaction;
  final VoidCallback onDismissClaim;

  static const _claimOptions = {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (view.deadline != null && view.phase != Phase.gameOver) ...[
            _TurnTimer(view: view),
            const SizedBox(height: 10),
          ],
          _main(context),
          const SizedBox(height: 10),
          _reactions(),
        ],
      ),
    );
  }

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 13.5)),
      );

  Widget _main(BuildContext context) {
    final v = view;
    if (pendingReaction != null) {
      return Column(children: [
        _hint('${pendingReaction!.emoji} ${pendingReaction!.label} اختر لاعب من الطاولة 👆'),
        TextButton(onPressed: onCancelReaction, child: const Text('إلغاء')),
      ]);
    }

    final required = _required(v);
    if (required != null) return required;

    final claimCount = v.claimCount;
    if (claimCount != null && !claimDismissed && v.phase != Phase.gameOver) {
      return Column(children: [
        const Text('📢 وش تقول إنه وصلك؟', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 2),
        _hint('اختيارك يطلع للكل. تقدر تقول الصدق أو تكذب'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final option in _claimOptions[claimCount]!)
              Semantics(
                button: true,
                label: 'ادعاء ${option.map((p) => p.code).join()}',
                excludeSemantics: true,
                child: InkWell(
                  onTap: busy ? null : () => onAct({'type': 'claim', 'policies': [for (final p in option) p.code]}),
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.line, width: 1.5),
                    ),
                    child: MiniPolicies(option, size: 16),
                  ),
                ),
              ),
          ],
        ),
        TextButton(onPressed: onDismissClaim, child: const Text('بعدين')),
      ]);
    }

    return _waiting(v);
  }

  /// الحركة المطلوبة منك الحين، لو فيه. لها أولوية على الادعاء.
  Widget? _required(GameView v) {
    switch (v.phase) {
      case Phase.nomination when v.amPresident:
        return _hint('👑 أنت الرئيس! اختر مستشار من الطاولة 👆');
      case Phase.election when !v.me.hasVoted && v.me.alive:
        return Column(children: [
          _hint('صوّت على حكومة 👑 ${name(v.presidentId)} + 📜 ${name(v.nomineeId)}'),
          Row(children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: const Color(0xFF06210F)),
                onPressed: busy ? null : () => onAct({'type': 'vote', 'ja': true}),
                child: const Text('✅ موافق'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.traitor, foregroundColor: Colors.white),
                onPressed: busy ? null : () => onAct({'type': 'vote', 'ja': false}),
                child: const Text('❌ رافض'),
              ),
            ),
          ]),
        ]);
      case Phase.presidentDiscard when v.amPresident:
        return Column(children: [
          _hint('🃏 اختر الكرت اللي بترميه (سري)، والباقي يروح للمستشار'),
          _cards(v.hand, (i) => onAct({'type': 'discard', 'index': i}), 'ارمِ'),
        ]);
      case Phase.chancellorEnact when v.amNominee:
        return Column(children: [
          _hint('📜 اختر الكرت اللي بتمرره'),
          _cards(v.hand, (i) => onAct({'type': 'enact', 'index': i}), 'مرّر'),
          if (v.canVeto)
            TextButton(
              onPressed: busy ? null : () => onAct({'type': 'proposeVeto'}),
              child: const Text('✋ اطلب فيتو (نرمي الاثنين)'),
            ),
        ]);
      case Phase.vetoResponse when v.amPresident:
        return Column(children: [
          _hint('✋ المستشار يبي يرمي الكرتين. توافق؟'),
          Row(children: [
            Expanded(
              child: FilledButton(
                onPressed: busy ? null : () => onAct({'type': 'respondVeto', 'accept': true}),
                child: const Text('موافق'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: busy ? null : () => onAct({'type': 'respondVeto', 'accept': false}),
                child: const Text('رافض'),
              ),
            ),
          ]),
        ]);
      case Phase.power when v.amPresident && v.pendingPower == Power.peek:
        return Column(children: [
          _hint('👁️ هذي أول ٣ كروت في الكومة (لك بس)'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final p in v.peeked ?? const <Policy>[]) Padding(padding: const EdgeInsets.all(4), child: PolicyCard(policy: p))],
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: busy ? null : () => onAct({'type': 'acknowledgePeek'}), child: const Text('تمام')),
        ]);
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
            child: PolicyCard(
              policy: p,
              label: '$verb كرت ${i + 1} ${p == Policy.loyal ? 'أوفياء' : 'خونة'}',
              onTap: busy ? null : () => onPick(i),
            ),
          ),
      ],
    );
  }

  Widget _reactions() {
    if (view.phase == Phase.gameOver) return const SizedBox.shrink();
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final k in ReactionKind.values)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Semantics(
                button: true,
                label: 'رد ${k.name}',
                excludeSemantics: true,
                child: ActionChip(
                  backgroundColor: AppColors.card,
                  side: const BorderSide(color: AppColors.line),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  label: Text(k.label.isEmpty ? k.emoji : '${k.emoji} ${k.label}', style: const TextStyle(fontSize: 13)),
                  onPressed: () => onReact(k),
                ),
              ),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
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
    return Container(
      color: Colors.black.withValues(alpha: .82),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(iWon ? '🏆' : '💔', style: const TextStyle(fontSize: 64)),
              Text(
                iWon ? 'فزت!' : 'خسرت',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: iWon ? AppColors.gold : AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                '${loyalWon ? 'فاز الأوفياء 🔵' : 'فاز الخونة 🔴'}: ${_winReasons[view.winReason] ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              if (room?.results[view.you] case final r?) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (r.coins > 0) _Reward('+${arabicNumber(r.coins)} 🪙', AppColors.gold),
                    if (r.coins > 0) const SizedBox(width: 10),
                    _Reward('+${arabicNumber(r.xp)} ⭐ خبرة', AppColors.diamond),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    const Text('الأدوار الحقيقية', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    for (final p in view.players)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(room?.player(p.id)?.avatar ?? '🙂', style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p.id == view.you ? 'أنت' : p.name)),
                            Text(
                              '${_roleInfo[p.knownRole]!.$1} ${_roleInfo[p.knownRole]!.$2}',
                              style: TextStyle(color: _roleInfo[p.knownRole]!.$4, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('🏠 الرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
