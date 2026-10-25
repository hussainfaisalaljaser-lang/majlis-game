import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/room.dart';
import '../../services/sfx.dart';
import '../../theme.dart';
import '../common.dart';
import '../ui.dart';

const roleInfo = {
  Role.loyal: ('وفي', 'اكشف الخونة ومرّر ٥ قرارات زرقاء', AppColors.loyal, AppColors.loyalDark),
  Role.traitor: ('خائن', 'ساعد زعيمك يوصل للحكم بدون ما تنكشف', AppColors.traitor, AppColors.traitorDark),
  Role.leader: ('زعيم الخونة', 'خلّهم يثقون فيك وينتخبونك وزير', AppColors.traitor, AppColors.traitorDark),
};

const specialInfo = {
  Special.seer: ('🔮 العرّاف', 'مرة وحدة في اللعبة تقدر تكشف فريق أي لاعب. اختر الوقت الصح، ولا تنكشف!'),
  Special.guardian: ('🛡️ الحارس', 'لو أحد حاول يطردك، تنجو مرة وحدة ويبان للكل إنك حارس'),
};

/// كشف الدور: بطاقة مقلوبة تنقلب وتطلع دورك.
Future<void> showRoleReveal(BuildContext context, GameView view, Room? room) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: .85),
    pageBuilder: (context, _, _) => _RoleReveal(view: view, room: room),
  );
}

class _RoleReveal extends StatefulWidget {
  const _RoleReveal({required this.view, required this.room});

  final GameView view;
  final Room? room;

  @override
  State<_RoleReveal> createState() => _RoleRevealState();
}

class _RoleRevealState extends State<_RoleReveal> with SingleTickerProviderStateMixin {
  late final _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    // البطاقة تنقلب بعد ما يخلص الترحيب، عشان جملة الدور ما تركب عليه.
    Future.delayed(const Duration(milliseconds: 500)).then((_) => Sfx.whenQuiet()).then((_) {
      if (!mounted) return;
      _flip.forward().then((_) => Sfx.say(switch (widget.view.yourRole) {
            Role.loyal => 'role_loyal',
            Role.traitor => 'role_traitor',
            Role.leader => 'role_leader',
          }));
    });
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.view;
    final (name, goal, color, dark) = roleInfo[v.yourRole]!;
    final me = widget.room?.player(v.you);
    final mates = v.players.where((p) => p.id != v.you && p.knownRole != null && p.id != v.seerSees).toList();
    final special = v.yourSpecial;
    final seerTarget = v.seerSees == null ? null : v.player(v.seerSees!);

    final front = _CardFace(
      glow: color,
      edge: dark,
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerAvatar(avatar: me?.avatar ?? 'masked', frame: color, size: 96),
              const SizedBox(height: 4),
              Text(name, style: TextStyle(fontFamily: kufi, fontSize: 32, fontWeight: FontWeight.w700, color: dark)),
              if (special != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    specialInfo[special]!.$1,
                    style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  special == null ? goal : specialInfo[special]!.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.ink, fontSize: 15, height: 1.6, fontWeight: FontWeight.w700),
                ),
                if (seerTarget != null || mates.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      if (seerTarget != null)
                        _Known(room: widget.room, player: seerTarget, label: '🔴 خائن: ${seerTarget.name}'),
                      for (final m in mates)
                        _Known(
                          room: widget.room,
                          player: m,
                          label: '${m.knownRole == Role.leader ? '🦹 الزعيم' : '🔴 خائن'}: ${m.name}',
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final back = _CardFace(
      glow: AppColors.gold,
      edge: AppColors.goldDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.asset('assets/logo.png', width: 120, height: 120),
          ),
          const SizedBox(width: 20),
          const Text(
            'دورك السري',
            style: TextStyle(fontFamily: kufi, fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
        ],
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('❖ غطِّ الشاشة! ❖', style: TextStyle(fontFamily: kufi, color: AppColors.goldLight, fontSize: 16, letterSpacing: 1)),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _flip,
              builder: (context, _) {
                final t = Curves.easeInOutBack.transform(_flip.value);
                final angle = t * math.pi;
                final showFront = angle > math.pi / 2;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, .0012)
                    ..rotateY(angle),
                  child: showFront
                      ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: front)
                      : back,
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 300,
              child: AnimatedBuilder(
                animation: _flip,
                builder: (context, _) => GameButton(
                  label: 'فهمت 🤫',
                  semantics: 'فهمت',
                  tone: v.yourRole == Role.loyal ? ButtonTone.purple : ButtonTone.red,
                  height: 48,
                  onPressed: _flip.isCompleted ? () => Navigator.pop(context) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Known extends StatelessWidget {
  const _Known({required this.room, required this.player, required this.label});

  final Room? room;
  final ViewPlayer player;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerAvatar(avatar: room?.player(player.id)?.avatar ?? 'masked', frame: AppColors.traitor, size: 40),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      );
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.child, required this.glow, required this.edge});

  final Widget child;
  final Color glow;
  final Color edge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 540,
      height: 236,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF8EBD0), AppColors.parchmentDark]),
        border: Border.all(color: AppColors.goldDark, width: 4),
        boxShadow: [
          BoxShadow(color: edge, spreadRadius: 4),
          BoxShadow(color: glow.withValues(alpha: .55), blurRadius: 60, spreadRadius: 6),
        ],
      ),
      child: Center(child: child),
    );
  }
}

/// مشهد قصير يطلع فوق الطاولة ويختفي لحاله (كشف التصويت، تمرير قرار، طرد…).
class EventOverlay extends StatefulWidget {
  const EventOverlay({super.key, required this.child, required this.onDone, this.duration = const Duration(milliseconds: 2600)});

  final Widget child;
  final VoidCallback onDone;
  final Duration duration;

  @override
  State<EventOverlay> createState() => _EventOverlayState();
}

class _EventOverlayState extends State<EventOverlay> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration)..forward().then((_) => widget.onDone());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDone,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final v = _c.value;
          final opacity = v < .12 ? v / .12 : (v > .85 ? (1 - v) / .15 : 1.0);
          final scale = v < .2 ? Curves.elasticOut.transform((v / .2).clamp(0, 1)) : 1.0;
          return Opacity(
            opacity: opacity.clamp(0, 1),
            child: Container(
              color: Colors.black.withValues(alpha: .6),
              alignment: Alignment.center,
              child: Transform.scale(scale: .7 + .3 * scale, child: child),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// كشف التصويت: كل لاعب تحته لوحة نعم أو لا.
class VoteReveal extends StatelessWidget {
  const VoteReveal({super.key, required this.view, required this.room, required this.votes, required this.passed});

  final GameView view;
  final Room? room;
  final Map<String, bool> votes;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 720),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Panel(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2E2266), AppColors.panel]),
        borderColor: AppColors.gold.withValues(alpha: .5),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GoldText('🗳️ نتيجة التصويت', size: 24),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final (i, MapEntry(:key, :value)) in votes.entries.indexed)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + i * 120),
                    curve: Curves.easeOutBack,
                    builder: (context, t, child) => Transform.scale(scale: t, child: child),
                    child: Column(
                      children: [
                        PlayerAvatar(avatar: room?.player(key)?.avatar ?? 'masked', size: 46),
                        const SizedBox(height: 4),
                        Container(
                          width: 52,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: value ? AppColors.green : AppColors.traitor,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            value ? 'نعم' : 'لا',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, color: value ? const Color(0xFF062814) : Colors.white),
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            key == view.you ? 'أنت' : view.player(key).name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              passed ? '✅ الحكومة انتخبت' : '❌ الحكومة انرفضت',
              style: TextStyle(fontFamily: kufi, fontSize: 20, fontWeight: FontWeight.w700, color: passed ? AppColors.green : AppColors.traitorLight),
            ),
          ],
        ),
      ),
    );
  }
}

/// ختم القرار اللي تمرر.
class EnactStamp extends StatelessWidget {
  const EnactStamp({super.key, required this.loyal, required this.chaos});

  final bool loyal;
  final bool chaos;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 2.2, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInCubic,
          builder: (context, s, child) => Transform.scale(scale: s, child: Transform.rotate(angle: (s - 1) * .4, child: child)),
          child: Seal(loyal: loyal, size: 170),
        ),
        const SizedBox(height: 12),
        GoldText(chaos ? '🌪️ فوضى! تمرر تلقائياً' : 'تمرر قرار ${loyal ? 'للأوفياء' : 'للخونة'}', size: 26),
      ],
    );
  }
}

/// مشهد الطرد أو نجاة الحارس.
class ExecutionScene extends StatelessWidget {
  const ExecutionScene({super.key, required this.name, required this.avatar, required this.guarded});

  final String name;
  final String avatar;
  final bool guarded;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          builder: (context, t, child) => Transform.translate(
            offset: Offset(math.sin(t * math.pi * 6) * (1 - t) * 14, 0),
            child: child,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              PlayerAvatar(avatar: avatar, frame: guarded ? AppColors.loyal : AppColors.traitor, size: 130, dead: !guarded),
              Text(guarded ? '🛡️' : '🗡️', style: const TextStyle(fontSize: 64, shadows: [Shadow(blurRadius: 12)])),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GoldText(guarded ? '$name نجا! طلع حارس 🛡️' : '$name انطرد', size: 28),
        if (!guarded)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('ما يقدر يلعب بعد الحين', style: TextStyle(color: AppColors.muted)),
          ),
      ],
    );
  }
}
