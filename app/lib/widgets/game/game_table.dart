import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/room.dart';
import '../../models/shop.dart';
import '../../services/backend.dart';
import '../../services/notes.dart';
import '../../theme.dart';
import '../bubble.dart';
import '../common.dart';
import '../fx.dart';
import '../ui.dart';

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
    // كل لاعب يشوف الطاولة اللي لابسها من المتجر.
    final skin = tableSkin(Backend.instance.profile.value.table);
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
        final trayW = rugW * .46;
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
                      child: Image.asset(skin.carpet, width: rugW, height: rugH, fit: BoxFit.fill),
                    ),
                    Image.asset(skin.tray, width: trayW, height: trayH, fit: BoxFit.fill),
                    // كومة السحب (يمين) وكومة الرمي (يسار)، بين الصينية وحافة السجادة.
                    Positioned(
                      right: rugW * .11,
                      child: CardPile(count: view.drawPileCount, label: 'السحب', cardW: rugH * .2),
                    ),
                    Positioned(
                      left: rugW * .11,
                      child: CardPile(count: view.discardPileCount, label: 'الرمي', cardW: rugH * .2, messy: true),
                    ),
                    SizedBox(
                      width: trayW * .74,
                      height: trayH * .72,
                      child: Center(child: center),
                    ),
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
                      builder: (context, _) => AnimatedScale(
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
                          // وقت التصويت الكل يظلم إلا الحكومة، بس الخونة اللي تعرفهم يبقون واضحين.
                          // (الكلام والملصقات تبقى واضحة دايم)
                          dim: spotlight == null || spotlight!.contains(p.id)
                              ? 1
                              : (p.id != view.you && (p.knownRole == Role.traitor || p.knownRole == Role.leader)
                                    ? .85
                                    : .3),
                          onTap: selectable.contains(p.id) ? () => onSelect?.call(p.id) : null,
                          onLongPress: p.id == view.you ? null : () => onNote?.call(p.id),
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

/// كومة أوراق مقلوبة مع عدادها: كل ما زادت الأوراق زادت الطبقات (لين ٦).
class CardPile extends StatelessWidget {
  const CardPile({super.key, required this.count, required this.label, required this.cardW, this.messy = false});

  final int count;
  final String label;
  final double cardW;

  /// الرمي: الأوراق مايلة شوي كأنها انرمت.
  final bool messy;

  @override
  Widget build(BuildContext context) {
    final cardH = cardW * 1.4;
    final layers = count.clamp(0, 6);
    return Semantics(
      label: '$label ${arabicNumber(count)}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: cardW + 10,
            height: cardH + 10,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (layers == 0)
                  Container(
                    width: cardW,
                    height: cardH,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cardW * .12),
                      border: Border.all(color: AppColors.gold.withValues(alpha: .35), width: 1.5),
                    ),
                  ),
                for (var i = 0; i < layers; i++)
                  Transform.translate(
                    offset: Offset(messy ? (i.isEven ? -1.5 : 1.5) * i * .6 : 0, -i * 1.6),
                    child: Transform.rotate(
                      angle: messy ? (i.isEven ? -.08 : .07) * (1 + i * .3) : 0,
                      child: _CardBack(width: cardW, height: cardH),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
              child: Text(
                '$label ${arabicNumber(count)}',
                key: ValueKey(count),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.goldLight),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ظهر الورقة: بنفسجي غامق بإطار ذهبي ونجمة في النص.
class _CardBack extends StatelessWidget {
  const _CardBack({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    padding: EdgeInsets.all(width * .08),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(width * .12),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4A3592), Color(0xFF1C1638)],
      ),
      border: Border.all(color: AppColors.gold, width: 1.5),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))],
    ),
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * .08),
        border: Border.all(color: AppColors.gold.withValues(alpha: .5), width: 1),
      ),
      child: CustomPaint(size: Size.square(width * .42), painter: _StarPainter()),
    ),
  );
}

/// نجمة ذهبية على ظهر الكرت.
class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawPath(star4(c, size.width / 2), Paint()..color = AppColors.gold);
    canvas.drawCircle(c, size.width * .09, Paint()..color = AppColors.goldLight);
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}

/// نسبة عرض السجادة لطولها (assets/tables/carpet_*.webp).
const _rugAspect = 1500 / 714;

const noteColors = {
  NoteMark.trust: AppColors.green,
  NoteMark.suspect: AppColors.traitor,
  NoteMark.unsure: AppColors.gold,
};

class _SeatView extends StatelessWidget {
  const _SeatView({
    this.dim = 1,
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

  /// شفافية المقعد (يظلم وقت التصويت).
  final double dim;

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
            AnimatedOpacity(
              opacity: dim,
              duration: const Duration(milliseconds: 400),
              child: Column(
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
                      if (!p.alive) const Positioned.fill(child: Center(child: Gfx('skull', size: 34))),
                      if (p.id == view.presidentId) const Positioned(top: -26, left: 0, right: 0, child: _Crown()),
                      // ختم أحمر على كل خاين تعرفه (يبقى حتى لو صار رئيس أو وزير وتغيّر لون الإطار).
                      if (!isMe && (role == Role.traitor || role == Role.leader))
                        Positioned(
                          left: -8,
                          bottom: -4,
                          child: role == Role.leader ? const LeaderSeal(size: 32) : const Seal(loyal: false, size: 26),
                        ),
                      if (p.knownSpecial == Special.guardian && !isMe) const _Badge('shield', left: -6, bottom: -2),
                      if (rp?.bot ?? false) const _Badge('bot', right: -8, top: 16),
                      if (view.phase == Phase.election && p.hasVoted) const _Badge('check', left: -6, top: -4),
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Gfx(opinion.suspect >= opinion.trust ? 'suspect' : 'trust', size: 15),
                                const SizedBox(width: 2),
                                Text(
                                  arabicNumber(opinion.suspect >= opinion.trust ? opinion.suspect : opinion.trust),
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
                                ),
                              ],
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
                  // الاسم على خلفية داكنة عشان يبان فوق أي لون (السجادة أو الخلفية).
                  Container(
                    constraints: const BoxConstraints(maxWidth: 92),
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xD90B0818),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: .14)),
                    ),
                    child: Text(
                      isMe ? 'أنت' : p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                        color: p.alive ? AppColors.text : AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (reaction != null)
              Positioned(
                top: stickerById(reaction.kind) != null ? -62 : -30,
                child: _Bubble(reaction: reaction, view: view, bubble: rp?.bubble),
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
      child: const Gfx('crown', size: 36),
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
  const _Badge(this.icon, {this.left, this.right, this.top, this.bottom});

  /// أيقونة ملونة (assets/icons/gfx_*.png).
  final String icon;
  final double? left, right, top, bottom;

  @override
  Widget build(BuildContext context) =>
      Positioned(left: left, right: right, top: top, bottom: bottom, child: Gfx(icon, size: 24));
}

/// اللي قاله اللاعب: ملصق، أو كلام بفقاعته من المتجر.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.reaction, required this.view, required this.bubble});

  final Reaction reaction;
  final GameView view;
  final String? bubble;

  @override
  Widget build(BuildContext context) {
    final sticker = stickerById(reaction.kind);
    if (sticker != null) return StickerView(sticker: sticker, size: 70);
    final target = reaction.target;
    final targetName = target == null
        ? null
        : target == view.you
        ? 'أنت'
        : view.players.where((p) => p.id == target).firstOrNull?.name;
    final text = textReaction(reaction.kind)?.text(targetName) ?? '…';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .6, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: ChatBubble(style: bubbleStyle(bubble), text: text),
    );
  }
}
