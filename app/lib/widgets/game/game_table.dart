import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/room.dart';
import '../../models/shop.dart';
import '../../theme.dart';
import '../common.dart';

/// اللاعبين جالسين حول الطاولة، وفي النص رسالة المرحلة.
class GameTable extends StatelessWidget {
  const GameTable({
    super.key,
    required this.view,
    required this.room,
    required this.center,
    this.selectable = const {},
    this.onSelect,
    this.now,
  });

  final GameView view;
  final Room? room;
  final Widget center;

  /// اللاعبين اللي ينفع تختارهم الحين (ترشيح، تحقيق، طرد…).
  final Set<String> selectable;
  final ValueChanged<String>? onSelect;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final players = [...view.players]..sort((a, b) => a.seat.compareTo(b.seat));
    // نخلي اللاعب نفسه تحت في النص، والباقين حوله.
    final mySeat = view.me.seat;
    final n = players.length;

    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        const seatW = 76.0, seatH = 92.0;
        final rx = (w - seatW) / 2;
        final ry = (h - seatH) / 2;
        return Stack(
          children: [
            Center(
              child: Container(
                width: w * .52,
                height: math.min(h * .36, w * .4),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(200),
                  gradient: const RadialGradient(colors: [Color(0xFF262C48), Color(0xFF191D31)]),
                  border: Border.all(color: AppColors.line, width: 2),
                ),
                child: center,
              ),
            ),
            for (final p in players)
              Builder(builder: (context) {
                final offset = (p.seat - mySeat) % n;
                final angle = math.pi / 2 + 2 * math.pi * offset / n;
                return Positioned(
                  left: rx + rx * math.cos(angle) * -1,
                  top: ry + ry * math.sin(angle),
                  width: seatW,
                  height: seatH,
                  child: _SeatView(
                    player: p,
                    view: view,
                    room: room,
                    now: now ?? DateTime.now(),
                    selectable: selectable.contains(p.id),
                    onTap: selectable.contains(p.id) ? () => onSelect?.call(p.id) : null,
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _SeatView extends StatelessWidget {
  const _SeatView({
    required this.player,
    required this.view,
    required this.room,
    required this.now,
    required this.selectable,
    this.onTap,
  });

  final ViewPlayer player;
  final GameView view;
  final Room? room;
  final DateTime now;
  final bool selectable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = player;
    final isMe = p.id == view.you;
    final avatar = room?.player(p.id)?.avatar ?? '🙂';
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
    } else if (isMe && frameStyle(room?.player(p.id)?.frame) == null) {
      frame = AppColors.green;
    }

    return Semantics(
      button: onTap != null,
      label: 'اختيار ${p.name}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: p.alive ? 1 : .4,
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
                        scale: selectable ? 1.08 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: PlayerAvatar(
                          emoji: p.alive ? avatar : '💀',
                          frame: frame,
                          style: frameStyle(room?.player(p.id)?.frame),
                          size: 54,
                        ),
                      ),
                      if (p.id == view.presidentId) const _Badge('👑', right: -6, bottom: -4),
                      if (p.id == view.nomineeId) const _Badge('📜', right: -6, bottom: -4),
                      if (role == Role.leader && !isMe) const _Badge('🦹', left: -6, bottom: -4),
                      if (view.phase == Phase.election && p.hasVoted) const _Badge('✅', left: -6, top: -4),
                      if (opinion != null && (opinion.suspect > 0 || opinion.trust > 0))
                        Positioned(
                          top: -8,
                          right: -14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.panel,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Text(
                              opinion.suspect >= opinion.trust
                                  ? '🤨${arabicNumber(opinion.suspect)}'
                                  : '🤝${arabicNumber(opinion.trust)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isMe ? 'أنت' : p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (reaction != null)
                Positioned(
                  top: -26,
                  child: _Bubble(reaction: reaction, room: room, view: view),
                ),
            ],
          ),
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
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.reaction, required this.room, required this.view});

  final Reaction reaction;
  final Room? room;
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Text(
        text,
        maxLines: 1,
        style: const TextStyle(color: Color(0xFF111111), fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
