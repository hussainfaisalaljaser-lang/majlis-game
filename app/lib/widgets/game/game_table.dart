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
    this.spotlight,
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

  /// وقت التصويت: الطاولة تظلم إلا الرئيس والوزير، عشان التركيز يكون عليهم.
  final Set<String>? spotlight;

  @override
  Widget build(BuildContext context) {
    final players = [...view.players]..sort((a, b) => a.seat.compareTo(b.seat));
    final mySeat = view.me.seat;
    final n = players.length;

    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        const seatW = 88.0, seatH = 114.0;
        final rx = (w - seatW) / 2;
        final ry = (h - seatH) / 2;
        // سجادة عريضة (٢:١) تناسب الشاشة بالعرض، وصينية بيضاوية في نصها.
        final rugW = math.min(w * .72, h * .74 * _rugAspect);
        final rugH = rugW / _rugAspect;
        final trayW = rugW * .40;
        final trayH = trayW * .625;
        final angles = _seatAngles(n, rx, ry);
        return Stack(
          children: [
            Center(
              child: SizedBox(
                width: rugW,
                height: rugH,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: spotlight == null ? 1 : .35,
                      duration: const Duration(milliseconds: 400),
                      child: Image.asset('assets/images/carpet_wide.png', width: rugW, height: rugH, fit: BoxFit.fill),
                    ),
                    Image.asset('assets/images/tray_wide.png', width: trayW, height: trayH, fit: BoxFit.fill),
                    SizedBox(width: trayW * .74, height: trayH * .72, child: Center(child: center)),
                  ],
                ),
              ),
            ),
            for (final p in players)
              Builder(
                builder: (context) {
                  final offset = (p.seat - mySeat) % n;
                  final angle = angles[offset];
                  return Positioned(
                    left: rx - rx * math.cos(angle),
                    top: ry + ry * math.sin(angle),
                    width: seatW,
                    height: seatH,
                    child: ListenableBuilder(
                      listenable: notes,
                      builder: (context, _) => AnimatedOpacity(
                        opacity: spotlight == null || spotlight!.contains(p.id) ? 1 : .3,
                        duration: const Duration(milliseconds: 400),
                        child: AnimatedScale(
                          scale: spotlight != null && spotlight!.contains(p.id) ? 1.15 : 1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutBack,
                          child: _SeatView(
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
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

/// زوايا المقاعد حول السجادة. نوزعهم بمسافات متساوية على محيط الشكل البيضاوي (مو بزوايا متساوية)،
/// عشان بالعرض ينحط أكثرهم فوق وتحت، وما يتكدسون على الجنبين. نبدأ منك تحت في النص.
List<double> _seatAngles(int n, double rx, double ry) {
  const steps = 720;
  final lengths = <double>[0];
  for (var i = 1; i <= steps; i++) {
    final a0 = math.pi / 2 + 2 * math.pi * (i - 1) / steps;
    final a1 = math.pi / 2 + 2 * math.pi * i / steps;
    final dx = rx * (math.cos(a1) - math.cos(a0));
    final dy = ry * (math.sin(a1) - math.sin(a0));
    lengths.add(lengths.last + math.sqrt(dx * dx + dy * dy));
  }
  final total = lengths.last;
  final out = <double>[];
  var j = 0;
  for (var k = 0; k < n; k++) {
    final target = total * k / n;
    while (j < steps && lengths[j + 1] < target) {
      j++;
    }
    final seg = lengths[j + 1] - lengths[j];
    final f = seg == 0 ? 0.0 : (target - lengths[j]) / seg;
    out.add(math.pi / 2 + 2 * math.pi * (j + f) / steps);
  }
  return out;
}

/// نسبة عرض السجادة لطولها (assets/images/carpet_wide.png).
const _rugAspect = 1500 / 714;

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
                        size: 62,
                        dead: !p.alive,
                      ),
                    ),
                    if (!p.alive)
                      const Positioned.fill(
                        child: Center(child: Text('💀', style: TextStyle(fontSize: 26))),
                      ),
                    if (p.id == view.presidentId) const Positioned(top: -26, left: 0, right: 0, child: _Crown()),
                    if (role == Role.leader && !isMe) const _Badge('🦹', left: -6, bottom: -2),
                    if (p.knownSpecial == Special.guardian && !isMe) const _Badge('🛡️', left: -6, bottom: -2),
                    if (rp?.bot ?? false) const _Badge('🤖', right: -8, top: 16),
                    if (view.phase == Phase.election && p.hasVoted) const _Badge('✅', left: -6, top: -4),
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
                            opinion.suspect >= opinion.trust
                                ? '🤨${arabicNumber(opinion.suspect)}'
                                : '🤝${arabicNumber(opinion.trust)}',
                            style: const TextStyle(fontSize: 10.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                if (p.id == view.presidentId)
                  const _Office('الرئيس', AppColors.gold, AppColors.goldInk)
                else if (p.id == view.nomineeId)
                  const _Office('الوزير', Color(0xFFA78BFA), Color(0xFF1E0F4A)),
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
            if (reaction != null)
              Positioned(
                top: -28,
                child: _Bubble(reaction: reaction, view: view),
              ),
          ],
        ),
      ),
    );
  }
}

/// تاج الرئيس فوق راسه، كبير ويلمع.
class _Crown extends StatelessWidget {
  const _Crown();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: AppColors.goldLight.withValues(alpha: .55), blurRadius: 14)],
      ),
      child: const Text('👑', style: TextStyle(fontSize: 30, height: 1)),
    ),
  );
}

/// لوحة المنصب تحت الصورة: الرئيس (ذهبي) أو الوزير (بنفسجي).
class _Office extends StatelessWidget {
  const _Office(this.label, this.color, this.ink);

  final String label;
  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 1),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: color.withValues(alpha: .6), blurRadius: 8)],
    ),
    child: Text(
      label,
      style: TextStyle(fontFamily: kufi, fontSize: 12, fontWeight: FontWeight.w700, color: ink, height: 1.4),
    ),
  );
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
    child: Text(
      emoji,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 17, shadows: [Shadow(blurRadius: 4)]),
    ),
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
        child: Text(
          text,
          maxLines: 1,
          style: const TextStyle(color: AppColors.ink, fontSize: 11.5, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
