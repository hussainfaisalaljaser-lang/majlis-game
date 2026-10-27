import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../models/game_view.dart';
import '../../models/room.dart';
import '../../models/shop.dart';
import '../../services/backend.dart';
import '../../services/notes.dart';
import '../../theme.dart';
import '../bubble.dart';
import '../common.dart';
import '../fx.dart';
import '../majlis.dart';
import '../ui.dart';

/// مسافة الطاولة من حواف الشاشة (نفسها للمشاهد اللي تطلع فوقها، عشان تعرف وين كل لاعب).
const tablePadding = EdgeInsets.fromLTRB(20, 34, 20, 2);

const _seatW = 88.0, _seatH = 114.0;

/// مكان السجادة داخل طاولة بمقاس [table]: عريضة (٢:١) تناسب الشاشة بالعرض.
Rect rugRect(Size table) {
  final w = math.min(table.width * .72, table.height * .74 * _rugAspect);
  return Rect.fromCenter(center: table.center(Offset.zero), width: w, height: w / _rugAspect);
}

/// نص صورة كل لاعب على طاولة بمقاس [table] (نفس ترتيب GameTable).
Map<String, Offset> seatCenters(GameView view, Size table) {
  final rx = (table.width - _seatW) / 2, ry = (table.height - _seatH) / 2;
  final n = view.players.length;
  final angles = _seatAngles(n, rx, ry);
  return {
    for (final p in view.players)
      p.id: _seatOrigin(angles[(p.seat - view.me.seat) % n], rx, ry) + const Offset(_seatW / 2, 31),
  };
}

Offset _seatOrigin(double angle, double rx, double ry) => Offset(rx - rx * math.cos(angle), ry + ry * math.sin(angle));

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
    this.onTapPlayer,
    this.now,
    this.spotlight,
    this.deaths = const {},
    this.hiddenDeaths = const {},
    this.timer,
    this.ready = const {},
  });

  final GameView view;
  final Room? room;
  final Widget center;
  final Notes notes;

  /// اللاعبين اللي ينفع تختارهم الحين (ترشيح، تحقيق، طرد…).
  final Set<String> selectable;
  final ValueChanged<String>? onSelect;

  /// بطاقة اللاعب (ضغطة طويلة، أو ضغطة لما ما فيه اختيار).
  final ValueChanged<String>? onNote;

  /// ضغطة على لاعب ما ينفع تختاره الحين (الافتراضي: بطاقته).
  final ValueChanged<String>? onTapPlayer;
  final DateTime? now;

  /// وقت التصويت: الطاولة تظلم إلا الرئيس والوزير، عشان التركيز يكون عليهم.
  final Set<String>? spotlight;

  /// متى بدأ مشهد حزن كل مطرود على كرسيه (بعد ما يخلص مشهد طرده). بدونه يبان مغطى على طول.
  final Map<String, DateTime> deaths;

  /// مطرودين لسا مشهد طردهم ما خلص: يبانون عادي لين يجي وقتهم.
  final Set<String> hiddenDeaths;

  /// وقت الدور: ساعة رملية جنب اللي عليه الدور (وجنب الصينية وقت التصويت).
  final ({DateTime deadline, double total})? timer;

  /// بعد اللعبة: اللي دخلوا الجولة الجاية («العب مرة ثانية»).
  final Set<String> ready;

  @override
  Widget build(BuildContext context) {
    // كل لاعب يشوف الطاولة اللي لابسها من المتجر.
    final skin = tableSkin(Backend.instance.profile.value.table);
    final players = [...view.players]..sort((a, b) => a.seat.compareTo(b.seat));
    final mySeat = view.me.seat;
    final n = players.length;
    // وقت الاختيار (ترشيح، قدرة…) اللي ما ينفع تختارهم يظلمون، عشان يبان مين تقدر تختار.
    final picking = onSelect != null && selectable.isNotEmpty;

    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        const seatW = _seatW, seatH = _seatH;
        final rx = (w - seatW) / 2;
        final ry = (h - seatH) / 2;
        // سجادة عريضة (٢:١) تناسب الشاشة بالعرض، وصينية بيضاوية في نصها.
        final rug = rugRect(Size(w, h));
        final rugW = rug.width;
        final rugH = rug.height;
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
                    // دلة وفناجيل بزاوية، ومبخرة بالزاوية الثانية.
                    Positioned(
                      left: rugW * .045,
                      bottom: rugH * .07,
                      child: CoffeeSet(width: rugH * .3),
                    ),
                    Positioned(
                      right: rugW * .055,
                      bottom: rugH * .06,
                      child: Censer(width: rugH * .1),
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
                  final top = ry + ry * math.sin(angle);
                  return Positioned(
                    left: rx - rx * math.cos(angle),
                    top: top,
                    width: seatW,
                    height: seatH,
                    child: ListenableBuilder(
                      listenable: notes,
                      builder: (context, _) => AnimatedScale(
                        scale: spotlight != null && spotlight!.contains(p.id) ? 1.15 : 1,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        child: _SeatView(
                          // المقاعد اللي فوق: الملصق ينزل تحت الصورة عشان ما ينقص من فوق الشاشة.
                          stickerBelow: top < 30,
                          deathHidden: hiddenDeaths.contains(p.id),
                          deathAt: deaths[p.id],
                          ready: ready.contains(p.id),
                          player: p,
                          view: view,
                          room: room,
                          note: notes.of(p.id),
                          now: now ?? DateTime.now(),
                          selectable: selectable.contains(p.id),
                          // وقت التصويت الكل يظلم إلا الحكومة، بس الخونة اللي تعرفهم يبقون واضحين.
                          // (الكلام والملصقات تبقى واضحة دايم)
                          dim: spotlight != null && !spotlight!.contains(p.id)
                              ? (p.id != view.you && (p.knownRole == Role.traitor || p.knownRole == Role.leader)
                                    ? .85
                                    : .3)
                              : picking && !selectable.contains(p.id) && p.id != view.you
                              ? .45
                              : 1,
                          // تختاره (وقت الترشيح أو القدرة)، وإلا تفتح بطاقته.
                          onTap: selectable.contains(p.id)
                              ? () => onSelect?.call(p.id)
                              : () => (onTapPlayer ?? onNote)?.call(p.id),
                          onLongPress: () => onNote?.call(p.id),
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (timer case final timer?) _hourglass(timer, Size(w, h), rug, trayH, angles, players, mySeat),
          ],
        );
      },
    );
  }

  /// الساعة الرملية جنب اللي عليه الدور (من جهة نص الطاولة)، ووقت التصويت فوق الصينية.
  Widget _hourglass(
    ({DateTime deadline, double total}) timer,
    Size table,
    Rect rug,
    double trayH,
    List<double> angles,
    List<ViewPlayer> players,
    int mySeat,
  ) {
    const gw = 24.0, gh = gw * 1.6;
    final actor = switch (view.phase) {
      Phase.chancellorEnact => view.nomineeId,
      Phase.election || Phase.gameOver => null,
      _ => view.presidentId,
    };
    final p = actor == null ? null : players.where((p) => p.id == actor).firstOrNull;
    final Offset at;
    if (p == null) {
      at = Offset(table.width / 2 - gw / 2, rug.center.dy - trayH / 2 - gh + 4);
    } else {
      final rx = (table.width - _seatW) / 2, ry = (table.height - _seatH) / 2;
      final o = _seatOrigin(angles[(p.seat - mySeat) % players.length], rx, ry);
      final right = o.dx + _seatW / 2 <= table.width / 2 + 1;
      at = Offset(right ? o.dx + _seatW - 6 : o.dx - gw + 6, o.dy + 4);
    }
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: IgnorePointer(
        child: _Hourglass(deadline: timer.deadline, total: timer.total, width: gw),
      ),
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
    this.stickerBelow = false,
    this.deathHidden = false,
    this.deathAt,
    this.ready = false,
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

  /// الملصق يطلع تحت الصورة بدال فوقها (المقاعد اللي فوق).
  final bool stickerBelow;

  /// انطرد بس مشهد طرده لسا ما خلص: يبان عادي.
  final bool deathHidden;

  /// متى يبدأ حزنه على كرسيه (وبعده ينطفي فانوسه ويتغطى).
  final DateTime? deathAt;

  /// دخل الجولة الجاية («العب مرة ثانية»).
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final p = player;
    final isMe = p.id == view.you;
    final rp = room?.player(p.id);
    final role = p.knownRole;
    final over = view.phase == Phase.gameOver;
    // طلع من الطاولة بعد ما خلصت اللعبة (إلا لو راح للجولة الجاية).
    final gone = !ready && (room?.gone.contains(p.id) ?? false);
    // اللي حظرتهم: ما تشوف ردودهم ولا رأيهم.
    final blocked = Backend.instance.profile.value.blocked;
    final opinion = room?.opinionOf(p.id, ignore: blocked);
    final reaction = blocked.contains(p.id)
        ? null
        // ردود البوتات وقتها بعد المشاهد (مستقبلاً)، فتطلع لما يجي وقتها.
        : room?.reactions
              .where((r) => r.from == p.id && !r.at.isAfter(now) && now.difference(r.at).inSeconds < 5)
              .lastOrNull;
    final dead = !p.alive && !deathHidden;

    Color? frame;
    if (selectable) {
      frame = AppColors.gold;
    } else if (over) {
      if (role == Role.traitor || role == Role.leader) frame = AppColors.traitor;
    } else if (p.id == view.presidentId) {
      frame = AppColors.gold;
    } else if (p.id == view.nomineeId) {
      frame = const Color(0xFFA78BFA);
    } else if (!isMe && (role == Role.traitor || role == Role.leader)) {
      frame = AppColors.traitor;
    } else if (isMe && frameStyle(rp?.frame) == null) {
      frame = AppColors.green;
    }

    final avatar = AnimatedScale(
      scale: selectable ? 1.1 : 1,
      duration: const Duration(milliseconds: 250),
      // الإطار المشترى يبان دايم، والتمييز (رئيس، مختار، خاين تعرفه) توهج حوله
      child: PlayerAvatar(
        avatar: rp?.avatar ?? 'masked',
        frame: frameStyle(rp?.frame) == null ? frame : null,
        highlight: frameStyle(rp?.frame) == null ? null : frame,
        style: frameStyle(rp?.frame),
        size: 62,
        dead: over && !p.alive,
        momentKey: p.id,
      ),
    );
    final sticker = reaction == null ? null : stickerById(reaction.kind);
    // الشخصية تتحرك مع ملصقها (تضحك، تعصب، تنصدم…).
    final moving = _Since(
      since: sticker == null ? null : reaction!.at,
      seconds: _moodSeconds,
      builder: (context, t) => _moodMotion(sticker == null ? _Mood.hop : _moodOf(sticker.id), t, avatar),
    );

    return Semantics(
      button: onTap != null,
      label: selectable ? 'اختيار ${p.name}' : 'ملف ${p.name}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            AnimatedOpacity(
              opacity: gone ? math.min(dim, .4) : dim,
              duration: const Duration(milliseconds: 400),
              child: Column(
                children: [
                  _Since(
                    // بعد اللعبة الغطا ينشال عن الكل، عشان تبان الأدوار.
                    since: dead && !over ? deathAt : null,
                    seconds: _deathSeconds,
                    builder: (context, t) => _figure(t, dead && !over, over, moving, isMe, role, opinion),
                  ),
                  const SizedBox(height: 3),
                  if (over) ...[
                    if (ready)
                      const _Office('جاهز يعيد', AppColors.green, Color(0xFF062814))
                    else if (gone)
                      const _Office('طلع', Color(0xFF5B5F78), Colors.white),
                  ] else if (p.id == view.presidentId)
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
                      isMe && !view.spectator ? 'أنت' : p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                        color: dead ? AppColors.muted : AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (reaction != null)
              Positioned(
                top: sticker == null ? -30 : (stickerBelow ? 56 : -62),
                child: _Bubble(reaction: reaction, view: view, bubble: rp?.bubble),
              ),
          ],
        ),
      ),
    );
  }

  /// اللاعب على مسنده وفانوسه جنبه، وفوقه شاراته. المطرود ([dying]) يحزن، وبعدها ينطفي فانوسه
  /// ويطيح عليه غطا ([t] الوقت من بداية حزنه).
  Widget _figure(
    double t,
    bool dying,
    bool over,
    Widget avatar,
    bool isMe,
    Role? role,
    ({int suspect, int trust})? opinion,
  ) {
    final p = player;
    final sad = dying ? seg(t, 0, .6) * (1 - seg(t, 2.8, 3.4)) : 0.0;
    final grey = dying ? seg(t, 0, .9) * .8 : 0.0;
    final lamp = over ? (p.alive ? 1.0 : 0.0) : (dying ? 1 - seg(t, 2.0, 2.5) : 1.0);
    final cloth = dying ? seg(t, 2.6, 3.8) : 0.0;
    Widget figure = Transform.translate(
      offset: Offset(0, 5 * sad),
      child: Transform.rotate(angle: .2 * sad, child: avatar),
    );
    if (dying) {
      figure = Stack(
        clipBehavior: Clip.none,
        children: [
          ColorFiltered(colorFilter: ColorFilter.matrix(greyMatrix(grey)), child: figure),
          if (t < 3) Positioned.fill(child: CustomPaint(painter: _SadPainter(t))),
        ],
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // المسند ورا اللاعب، وفانوسه جنبه.
        Positioned(left: -11, top: -12, child: Cushion(width: 84, height: 58, dead: over && !p.alive ? 1 : 0)),
        Positioned(
          right: -18,
          top: 34,
          child: FloorLantern(width: 14, on: lamp, seed: p.seat),
        ),
        // لما يتغطى كامل ما نرسمه تحت الغطا (ولا يطل إطاره من تحته).
        if (cloth < 1) figure else const SizedBox(width: 62, height: 62),
        if (cloth > 0) Positioned(left: -13, top: -16, child: SeatCloth(k: cloth, width: 88, height: 82)),
        if (over && !p.alive) const Positioned.fill(child: Center(child: Gfx('skull', size: 34))),
        if (!over && p.id == view.presidentId) const Positioned(top: -26, left: 0, right: 0, child: _Crown()),
        // ختم أحمر على كل خاين تعرفه (يبقى حتى لو صار رئيس أو وزير وتغيّر لون الإطار).
        // وبعد اللعبة الكل يبان ختمه، حتى الأوفياء.
        if (role != null && (over || !isMe && (role == Role.traitor || role == Role.leader)))
          Positioned(
            left: -8,
            bottom: -4,
            child: role == Role.leader ? const LeaderSeal(size: 32) : Seal(loyal: role == Role.loyal, size: 26),
          ),
        if (p.knownSpecial case final special? when !isMe && (over || special != Special.seer))
          _Badge(specialIcon[special]!, right: -8, bottom: -2),
        if (room?.player(p.id)?.bot ?? false) const _Badge('bot', right: -8, top: 16),
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
    );
  }
}

/// تقدم الحركة بين [a] و[b] (٠–١).
double seg(double t, double a, double b, [Curve curve = Curves.linear]) =>
    curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// تطلع وتنزل مرة وحدة بين [a] و[b].
double bump(double t, double a, double b) => math.sin(seg(t, a, b) * math.pi);

const _moodSeconds = 2.6;
const _deathSeconds = 4.0;

enum _Mood { laugh, angry, shock, sad, hop }

/// وش تسوي الشخصية مع الملصق.
_Mood _moodOf(String id) {
  if (id.contains('laugh') || id.startsWith('par_') || id.startsWith('hype_') || id.startsWith('vip_')) {
    return _Mood.laugh;
  }
  if (id.startsWith('ang_') || id == 'b_angry') return _Mood.angry;
  if (id.startsWith('shock_') || id.startsWith('det_') || id == 'b_eyes') return _Mood.shock;
  if (id.startsWith('nerv_') || id == 'inn_cry' || id == 'inn_pls') return _Mood.sad;
  return _Mood.hop;
}

/// حركة الشخصية بعد ملصقها بـ[t] ثانية: تضحك وتنط، تعصب وتهتز، تنصدم وتنقز، تتوتر وتميل.
Widget _moodMotion(_Mood mood, double t, Widget child) {
  final env = seg(t, 0, .15) * (1 - seg(t, 2.1, _moodSeconds));
  var dx = 0.0, dy = 0.0, rot = 0.0, sx = 1.0, sy = 1.0;
  switch (mood) {
    case _Mood.laugh:
      final hop = math.sin(t * 14).abs();
      dy = -hop * 7 * env;
      rot = math.sin(t * 7) * .08 * env;
      sx = 1 + .04 * env * hop;
      sy = 1 - .05 * env * hop;
    case _Mood.angry:
      dx = math.sin(t * 42) * 3.5 * env;
      sx = sy = 1 + .05 * env;
    case _Mood.shock:
      final jump = bump(t, 0, .35);
      dy = -16 * jump;
      sx = sy = 1 + .14 * jump;
      if (t > .35) dx = math.sin(t * 50) * 1.5 * env;
    case _Mood.sad:
      rot = -.14 * env;
      dy = 4 * env;
      dx = math.sin(t * 30) * env;
    case _Mood.hop:
      dy = -9 * bump(t, 0, .3) - 4 * bump(t, .3, .55);
  }
  return Transform.translate(
    offset: Offset(dx, dy),
    child: Transform.rotate(
      angle: rot,
      child: Transform.scale(scaleX: sx, scaleY: sy, child: child),
    ),
  );
}

/// دموع تنزل وغيمة فوق راسه تمطر (أول ما ينطرد).
class _SadPainter extends CustomPainter {
  _SadPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final fade = seg(t, .2, .6) * (1 - seg(t, 2.5, 3));
    // الغيمة
    final cx = w / 2, cy = -14.0;
    final drop = Paint()
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 5; k++) {
      final q = (t * 1.6 + k / 5) % 1;
      final x = cx - 16 + k * 8;
      final y = cy + 8 + q * 22;
      drop.color = const Color(0xFF7DD3FC).withValues(alpha: (1 - q) * fade);
      canvas.drawLine(Offset(x, y), Offset(x - 1.5, y + 5), drop);
    }
    final cloud = Paint()..color = const Color(0xFF64748B).withValues(alpha: fade);
    for (final (dx, dy, r) in const [
      (-13.0, 2.0, 9.0),
      (0.0, -3.0, 12.0),
      (13.0, 2.0, 9.0),
      (-5.0, 5.0, 8.0),
      (6.0, 5.0, 8.0),
    ]) {
      canvas.drawCircle(Offset(cx + dx, cy + dy), r, cloud);
    }
    // دمعتين
    for (var k = 0; k < 2; k++) {
      final q = seg(t, .5 + k * .9, 1.5 + k * .9);
      if (q <= 0 || q >= 1) continue;
      final at = Offset(w * (k.isEven ? .38 : .62), size.height * (.55 + q * .35));
      canvas.drawPath(
        Path()
          ..moveTo(at.dx, at.dy - 6)
          ..quadraticBezierTo(at.dx + 4, at.dy, at.dx, at.dy + 3)
          ..quadraticBezierTo(at.dx - 4, at.dy, at.dx, at.dy - 6),
        Paint()..color = const Color(0xFF7DD3FC).withValues(alpha: math.sin(q * math.pi)),
      );
    }
  }

  @override
  bool shouldRepaint(_SadPainter old) => old.t != t;
}

/// يعيد البناء كل فريم من [since] لين تخلص [seconds]، وبعدها يثبت على آخر لحظة.
/// بدون [since] (أو بالوضع الخفيف) يرسم آخر لحظة على طول.
class _Since extends StatefulWidget {
  const _Since({required this.since, required this.seconds, required this.builder});

  final DateTime? since;
  final double seconds;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_Since> createState() => _SinceState();
}

class _SinceState extends State<_Since> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => _tick());
  late double _t = _elapsed();

  double _elapsed() {
    final since = widget.since;
    if (since == null || FxClock.lite.value) return widget.seconds;
    return (DateTime.now().difference(since).inMicroseconds / 1e6).clamp(0.0, widget.seconds);
  }

  void _sync() {
    _t = _elapsed();
    if (_t < widget.seconds) {
      if (!_ticker.isActive) _ticker.start();
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick() {
    setState(() => _t = _elapsed());
    if (_t >= widget.seconds) _ticker.stop();
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Since old) {
    super.didUpdateWidget(old);
    if (old.since != widget.since) _sync();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _t);
}

/// ساعة رملية: الرمل ينزل لين يخلص الوقت، وآخر ٥ ثواني تحمر وتهتز.
class _Hourglass extends StatelessWidget {
  const _Hourglass({required this.deadline, required this.total, this.width = 24});

  final DateTime deadline;
  final double total;
  final double width;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FxClock(
      builder: (context, time) =>
          CustomPaint(size: Size(width, width * 1.6), painter: _HourglassPainter(time, deadline, total)),
    ),
  );
}

class _HourglassPainter extends CustomPainter {
  _HourglassPainter(this.time, this.deadline, this.total) : super(repaint: time);

  final ValueListenable<double> time;
  final DateTime deadline;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final left = deadline.difference(DateTime.now()).inMilliseconds / 1000;
    final p = (1 - left / total).clamp(0.0, 1.0);
    final urgent = left <= 5 ? 1.0 : 0.0;
    final t = time.value;
    canvas.scale(size.width / 40);
    if (urgent > 0) canvas.translate(math.sin(t * 50) * 1.4, 0);
    final sand = urgent > 0 ? const Color(0xFFFF5A5A) : const Color(0xFFF2C14E);
    if (urgent > 0) {
      canvas.drawCircle(
        const Offset(20, 32),
        30,
        Paint()
          ..color = const Color(0xFFFF3B3B).withValues(alpha: .3 * (.6 + .4 * math.sin(t * 10)))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    final top = Path()
      ..moveTo(7, 7)
      ..lineTo(33, 7)
      ..quadraticBezierTo(33, 24, 21.5, 31)
      ..lineTo(18.5, 31)
      ..quadraticBezierTo(7, 24, 7, 7)
      ..close();
    final bottom = Path()
      ..moveTo(18.5, 33)
      ..lineTo(21.5, 33)
      ..quadraticBezierTo(33, 40, 33, 57)
      ..lineTo(7, 57)
      ..quadraticBezierTo(7, 40, 18.5, 33)
      ..close();
    final glass = Paint()..color = const Color(0xFF0B0818).withValues(alpha: .55);
    canvas.drawPath(top, glass);
    canvas.drawPath(bottom, glass);
    final fill = Paint()..color = sand;
    canvas.save();
    canvas.clipPath(top);
    canvas.drawRect(Rect.fromLTRB(0, 9 + 22 * p, 40, 32), fill);
    canvas.restore();
    canvas.save();
    canvas.clipPath(bottom);
    final h = 22 * p;
    canvas.drawPath(
      Path()
        ..moveTo(0, 58)
        ..lineTo(0, 58 - h * .55)
        ..quadraticBezierTo(20, 58 - h * 1.5, 40, 58 - h * .55)
        ..lineTo(40, 58)
        ..close(),
      fill,
    );
    canvas.restore();
    if (p < 1) {
      canvas.drawLine(
        const Offset(20, 31),
        Offset(20, 57 - h),
        Paint()
          ..color = sand
          ..strokeWidth = 1.4,
      );
      for (var k = 0; k < 3; k++) {
        canvas.drawCircle(Offset(20, 32 + ((t * 3 + k / 3) % 1) * (24 - h)), .9, fill);
      }
    }
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: .75);
    canvas.drawPath(top, outline);
    canvas.drawPath(bottom, outline);
    final wood = Paint()..color = const Color(0xFF8A5A00);
    canvas.drawRect(const Rect.fromLTWH(3.5, 7, 2.4, 50), wood);
    canvas.drawRect(const Rect.fromLTWH(34.1, 7, 2.4, 50), wood);
    final cap = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFB87A12)])
          .createShader(const Rect.fromLTWH(0, 0, 40, 64));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(1, 1, 38, 6), const Radius.circular(2)), cap);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(1, 57, 38, 6), const Radius.circular(2)), cap);
  }

  @override
  bool shouldRepaint(_HourglassPainter old) => true;
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

/// أيقونة كل دور خاص (نفس overlays.dart → specialInfo).
const specialIcon = {
  Special.seer: 'seer',
  Special.guardian: 'shield',
  Special.judge: 'scales',
  Special.elder: 'ballot',
  Special.spy: 'eye',
};

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
        : target == view.you && !view.spectator
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
