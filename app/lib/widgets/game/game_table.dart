import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/room.dart';
import '../../models/shop.dart';
import '../../services/notes.dart';
import '../../theme.dart';
import '../common.dart';

/// سجادة المجلس: اللاعبين قاعدين حولها، وفي النص صينية نحاس فيها رسالة المرحلة.
class GameTable extends StatelessWidget {
  const GameTable({
    super.key,
    required this.view,
    required this.room,
    required this.center,
    required this.notes,
    this.selectable = const {},
    this.onSelect,
    this.onNote,
    this.now,
  });

  final GameView view;
  final Room? room;
  final Widget center;
  final Notes notes;

  /// اللاعبين اللي ينفع تختارهم الحين (ترشيح، تحقيق، طرد…).
  final Set<String> selectable;
  final ValueChanged<String>? onSelect;

  /// ضغطة طويلة على لاعب: تحط ملاحظتك عليه.
  final ValueChanged<String>? onNote;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final players = [...view.players]..sort((a, b) => a.seat.compareTo(b.seat));
    final mySeat = view.me.seat;
    final n = players.length;

    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        const seatW = 78.0, seatH = 96.0;
        final rx = (w - seatW) / 2;
        final ry = (h - seatH) / 2;
        final rug = math.min(w * .82, h * .78);
        return Stack(
          children: [
            Center(
              child: SizedBox(
                width: rug,
                height: rug,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset('assets/images/carpet.png', width: rug, height: rug),
                    Image.asset('assets/images/tray.png', width: rug * .48, height: rug * .48),
                    SizedBox(width: rug * .4, height: rug * .4, child: Center(child: center)),
                  ],
                ),
              ),
            ),
            for (final p in players)
              Builder(builder: (context) {
                final offset = (p.seat - mySeat) % n;
                final angle = math.pi / 2 + 2 * math.pi * offset / n;
                return Positioned(
                  left: rx - rx * math.cos(angle),
                  top: ry + ry * math.sin(angle),
                  width: seatW,
                  height: seatH,
                  child: ListenableBuilder(
                    listenable: notes,
                    builder: (context, _) => _SeatView(
                      player: p,
                      view: view,
                      room: room,
                      note: notes.of(p.id),
                      now: now ?? DateTime.now(),
                      selectable: selectable.contains(p.id),
                      onTap: selectable.contains(p.id) ? () => onSelect?.call(p.id) : null,
                      onLongPress: p.id == view.you ? null : () => onNote?.call(p.id),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

const noteColors = {
  NoteMark.trust: AppColors.green,
  NoteMark.suspect: AppColors.traitor,
  NoteMark.unsure: AppColors.gold,
};

class _SeatView extends StatelessWidget {
  const _SeatView({
    required this.player,
    required this.view,
    required this.room,
    required this.note,
    required this.now,
    required this.selectable,
    this.onTap,
    this.onLongPress,
  });

  final ViewPlayer player;
  final GameView view;
  final Room? room;
  final NoteMark? note;
  final DateTime now;
  final bool selectable;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final p = player;
    final isMe = p.id == view.you;
    final rp = room?.player(p.id);
    final role = p.knownRole;
    final opinion = room?.opinionOf(p.id);
    final reaction = room?.reactions.where((r) => r.from == p.id && now.difference(r.at).inSeconds < 5).lastOrNull;

    Color? frame;
    if (selectable) {
      frame = AppColors.gold;
    } else if (p.id == view.presidentId) {
      frame = AppColors.gold;
    } else if (p.id == view.nomineeId) {
      frame = const Color(0xFFA78BFA);
    } else if (!isMe && (role == Role.traitor || role == Role.leader)) {
      frame = AppColors.traitor;
    } else if (isMe && frameStyle(rp?.frame) == null) {
      frame = AppColors.green;
    }

    return Semantics(
      button: onTap != null,
      label: 'اختيار ${p.name}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedScale(
                      scale: selectable ? 1.1 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: PlayerAvatar(
                        avatar: rp?.avatar ?? 'masked',
                        frame: frame,
                        style: frameStyle(rp?.frame),
                        size: 54,
                        dead: !p.alive,
                      ),
                    ),
                    if (!p.alive) const Positioned.fill(child: Center(child: Text('💀', style: TextStyle(fontSize: 26)))),
                    if (p.id == view.presidentId) const _Badge('👑', top: -14, left: 0, right: 0),
                    if (p.id == view.nomineeId) const _Badge('📜', right: -6, bottom: -2),
                    if (role == Role.leader && !isMe) const _Badge('🦹', left: -6, bottom: -2),
                    if (p.knownSpecial == Special.guardian && !isMe) const _Badge('🛡️', left: -6, bottom: -2),
                    if (rp?.bot ?? false) const _Badge('🤖', right: -8, top: 16),
                    if (view.phase == Phase.election && p.hasVoted) const _Badge('🗳️', left: -6, top: -4),
                    if (note != null)
                      Positioned(
                        bottom: -2,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: noteColors[note],
                              border: Border.all(color: AppColors.bg, width: 2),
                            ),
                          ),
                        ),
                      ),
                    if (opinion != null && (opinion.suspect > 0 || opinion.trust > 0))
                      Positioned(
                        top: -6,
                        right: -14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: opinion.suspect >= opinion.trust ? AppColors.traitor : AppColors.green,
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            opinion.suspect >= opinion.trust ? '🤨${arabicNumber(opinion.suspect)}' : '🤝${arabicNumber(opinion.trust)}',
                            style: const TextStyle(fontSize: 10.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isMe ? 'أنت' : p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: p.alive ? AppColors.text : AppColors.muted,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ],
            ),
            if (reaction != null) Positioned(top: -28, child: _Bubble(reaction: reaction, view: view)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.emoji, {this.left, this.right, this.top, this.bottom});

  final String emoji;
  final double? left, right, top, bottom;

  @override
  Widget build(BuildContext context) => Positioned(
        left: left,
        right: right,
        top: top,
        bottom: bottom,
        child: Text(emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, shadows: [Shadow(blurRadius: 4)])),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.reaction, required this.view});

  final Reaction reaction;
  final GameView view;

  @override
  Widget build(BuildContext context) {
    final target = reaction.target;
    final targetName = target == null
        ? null
        : target == view.you
            ? 'أنت'
            : view.players.where((p) => p.id == target).firstOrNull?.name;
    final text = switch (reaction.kind) {
      ReactionKind.suspect => '🤨 أشك في $targetName',
      ReactionKind.trust => '🤝 أثق في $targetName',
      ReactionKind.liar => '❌ $targetName كذاب',
      ReactionKind.pick => '👉 جربوا $targetName',
      ReactionKind.innocent => '🙏 أنا بريء',
      final k => k.emoji,
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .6, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.parchment,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
        ),
        child: Text(text, maxLines: 1, style: const TextStyle(color: AppColors.ink, fontSize: 11.5, fontWeight: FontWeight.w800)),
      ),
    );
  }
}
