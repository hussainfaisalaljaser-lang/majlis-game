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
import '../death_fx.dart';
import '../design.dart';
import '../design_game.dart';
import '../fx.dart';
import '../majlis.dart';
import '../ui.dart';
import 'table_art.dart';

/// مسافة الطاولة من حواف الشاشة: صفر، لأن المسرح (١٦:٩) يتوسط المساحة بنفسه ([Stage]).
const tablePadding = EdgeInsets.zero;

/// مكان السجادة (أكبر مستطيل يحيط فيها) داخل طاولة بمقاس [table].
Rect rugRect(Size table) {
  final st = Stage(table);
  return st.rect(TablePos.bl.dx, TablePos.tl.dy, TablePos.br.dx, TablePos.bl.dy);
}

/// نص صورة كل لاعب على طاولة بمقاس [table] (نفس ترتيب GameTable).
Map<String, Offset> seatCenters(GameView view, Size table) {
  final st = Stage(table);
  final n = view.players.length;
  final layout = seatLayout(n);
  return {for (final p in view.players) p.id: seatPoint(st, layout[(p.seat - view.me.seat) % n])};
}

/// نص صورة مقعد على الشاشة. على الجوال الصغير الشريط والاسم تحت الصورة أكبر من التصميم، فالمقعد اللي تحت
/// يرتفع شوي عشان ما ينقص من حافة الشاشة.
Offset seatPoint(Stage st, Offset design) {
  final s = st.s;
  final d = seatDiameter * s;
  final ribbonH = math.max(48 * s, gameFont(26, s, min: 11) * 1.5);
  final pillH = math.max(32 * s, gameFont(22, s, min: 11) * 1.35);
  final below = d / 2 - 15 * s + ribbonH + pillH - 3 * s;
  final c = st.at(design.dx, design.dy);
  return Offset(c.dx, math.min(c.dy, st.size.height - below - 2));
}

/// مواقع المقاعد بإحداثيات التصميم، الأول مقعدك (تحت بالنص)، وبعده عكس عقارب الساعة (يمين ثم فوق ثم يسار).
/// الخمسة والسبعة مرسومة يدوي مثل الفيديو، والباقي موزع بالتساوي على شكل بيضاوي مربع الأطراف.
List<Offset> seatLayout(int n) {
  if (n == 7) {
    return const [
      Offset(958, 940),
      Offset(1527, 833),
      Offset(1758, 397),
      Offset(1247, 145),
      Offset(668, 145),
      Offset(155, 397),
      Offset(390, 833),
    ];
  }
  if (n == 5) {
    return const [Offset(958, 940), Offset(1740, 470), Offset(1247, 150), Offset(668, 150), Offset(178, 470)];
  }
  const cx = 960.0, cy = 545.0, rx = 800.0, ry = 395.0, e = .78;
  double sp(double v) => v.sign * math.pow(v.abs(), e);
  Offset at(double a) => Offset(cx + rx * sp(math.sin(a)), cy + ry * sp(math.cos(a)));
  const steps = 720;
  final lengths = <double>[0];
  for (var i = 1; i <= steps; i++) {
    lengths.add(lengths.last + (at(2 * math.pi * i / steps) - at(2 * math.pi * (i - 1) / steps)).distance);
  }
  final out = <Offset>[];
  var j = 0;
  for (var k = 0; k < n; k++) {
    final target = lengths.last * k / n;
    while (j < steps && lengths[j + 1] < target) {
      j++;
    }
    final seg = lengths[j + 1] - lengths[j];
    final f = seg == 0 ? 0.0 : (target - lengths[j]) / seg;
    out.add(at(2 * math.pi * (j + f) / steps));
  }
  return out;
}

/// قطر صورة اللاعب كاملة مع حلقتها (بوحدات التصميم).
const seatDiameter = 143.0;

/// طاولة المجلس: خيمة وسجادة، واللاعبين قاعدين حولها، وفي نصها البيضاوي الذهبي (الرئيس والوزير) وكومتين الأوراق.
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

  /// اللي في نص البيضاوي (الرئيس والوزير أو النتيجة): يبنى فوق كل المسرح، وبإحداثيات [Stage].
  final Widget Function(BuildContext context, Stage stage) center;
  final Notes notes;

  /// اللاعبين اللي ينفع تختارهم الحين (ترشيح، تحقيق، طرد…).
  final Set<String> selectable;
  final ValueChanged<String>? onSelect;

  /// بطاقة اللاعب (ضغطة طويلة، أو ضغطة لما ما فيه اختيار).
  final ValueChanged<String>? onNote;

  /// ضغطة على لاعب ما ينفع تختاره الحين (الافتراضي: بطاقته).
  final ValueChanged<String>? onTapPlayer;
  final DateTime? now;

  /// وقت التصويت: اللي برا الحكومة يخفتون شوي، عشان التركيز يكون على الرئيس والوزير.
  final Set<String>? spotlight;

  /// متى بدأ مشهد حزن كل مطرود على كرسيه (بعد ما يخلص مشهد طرده). بدونه يبان مغطى على طول.
  final Map<String, DateTime> deaths;

  /// مطرودين لسا مشهد طردهم ما خلص: يبانون عادي لين يجي وقتهم.
  final Set<String> hiddenDeaths;

  /// وقت الدور: ساعة رملية جنب اللي عليه الدور (وجنب البيضاوي وقت التصويت).
  final ({DateTime deadline, double total})? timer;

  /// بعد اللعبة: اللي دخلوا الجولة الجاية («العب مرة ثانية»).
  final Set<String> ready;

  @override
  Widget build(BuildContext context) {
    // كل لاعب يشوف الطاولة اللي لابسها من المتجر (لون السجادة).
    final skin = tableSkin(Backend.instance.profile.value.table);
    final palette = CarpetPalette.of(skin.carpet);
    final players = [...view.players]..sort((a, b) => a.seat.compareTo(b.seat));
    final mySeat = view.me.seat;
    final n = players.length;
    final layout = seatLayout(n);
    // وقت الاختيار (ترشيح، قدرة…) اللي ما ينفع تختارهم يظلمون، عشان يبان مين تقدر تختار.
    final picking = onSelect != null && selectable.isNotEmpty;

    return LayoutBuilder(
      builder: (context, box) {
        final st = Stage(box.biggest);
        final s = st.s;
        final pileW = TablePos.pileW * s;
        final pileH = pileW * 1.46;
        Widget pile(Offset c, GameCardKind kind, int count, String label) {
          final w = math.max(pileW + 40 * s, 92.0);
          return Positioned(
            left: st.at(c.dx, c.dy).dx - w / 2,
            top: st.at(c.dx, c.dy).dy - (pileH + 8) / 2,
            width: w,
            child: CardPile(count: count, label: label, cardW: pileW, kind: kind, scale: s),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: RepaintBoundary(child: CustomPaint(painter: CarpetPainter(palette))),
            ),
            Positioned.fill(
              child: RepaintBoundary(child: CustomPaint(painter: OvalPainter(palette))),
            ),
            pile(TablePos.draw, GameCardKind.draw, view.drawPileCount, 'السحب'),
            pile(TablePos.discard, GameCardKind.discard, view.discardPileCount, 'الرمي'),
            Positioned.fill(child: center(context, st)),
            for (final p in players)
              Builder(
                builder: (context) {
                  final design = layout[(p.seat - mySeat) % n];
                  final c = seatPoint(st, design);
                  final sw = 230 * s, sh = 300 * s;
                  return Positioned(
                    left: c.dx - sw / 2,
                    top: c.dy - 100 * s,
                    width: sw,
                    height: sh,
                    child: ListenableBuilder(
                      listenable: notes,
                      builder: (context, _) => AnimatedScale(
                        scale: spotlight != null && spotlight!.contains(p.id) ? 1.1 : 1,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        child: _SeatView(
                          scale: s,
                          // المقاعد اللي فوق: الملصق ينزل تحت الصورة عشان ما ينقص من فوق الشاشة.
                          stickerBelow: design.dy < 220,
                          deathHidden: hiddenDeaths.contains(p.id),
                          deathAt: deaths[p.id],
                          ready: ready.contains(p.id),
                          player: p,
                          view: view,
                          room: room,
                          note: notes.of(p.id),
                          now: now ?? DateTime.now(),
                          selectable: selectable.contains(p.id),
                          // وقت التصويت الكل يخفت إلا الحكومة، بس الخونة اللي تعرفهم يبقون واضحين.
                          // (الكلام والملصقات تبقى واضحة دايم)
                          dim: spotlight != null && !spotlight!.contains(p.id)
                              ? (p.id != view.you && (p.knownRole == Role.traitor || p.knownRole == Role.leader)
                                    ? .9
                                    : .55)
                              : picking && !selectable.contains(p.id) && p.id != view.you
                              ? .5
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
            if (timer case final timer?) _hourglass(timer, st, layout, players, mySeat),
          ],
        );
      },
    );
  }

  /// الساعة الرملية جنب اللي عليه الدور (يمين صورته)، ووقت التصويت فوق البيضاوي.
  Widget _hourglass(
    ({DateTime deadline, double total}) timer,
    Stage st,
    List<Offset> layout,
    List<ViewPlayer> players,
    int mySeat,
  ) {
    final gw = 40 * st.s;
    final actor = switch (view.phase) {
      Phase.chancellorEnact => view.nomineeId,
      Phase.election || Phase.gameOver => null,
      _ => view.presidentId,
    };
    final p = actor == null ? null : players.where((p) => p.id == actor).firstOrNull;
    final Offset at;
    if (p == null) {
      at = st.at(TablePos.oval.dx, TablePos.oval.dy - TablePos.ovalRy - 12);
    } else {
      final d = layout[(p.seat - mySeat) % players.length];
      at = st.at(d.dx + 104, d.dy - 8);
    }
    return Positioned(
      left: at.dx - gw / 2,
      top: at.dy - gw * .8,
      child: IgnorePointer(
        child: _Hourglass(deadline: timer.deadline, total: timer.total, width: gw),
      ),
    );
  }
}

/// كومة أوراق مقلوبة مع عدادها: كل ما زادت الأوراق زادت الطبقات (لين ٦). السحب أزرق، والرمي بنفسجي.
class CardPile extends StatelessWidget {
  const CardPile({
    super.key,
    required this.count,
    required this.label,
    required this.cardW,
    this.kind = GameCardKind.draw,
    this.scale = 1,
  });

  final int count;
  final String label;
  final double cardW;
  final GameCardKind kind;

  /// مقياس المسرح (لحجم الخط والأبعاد).
  final double scale;

  @override
  Widget build(BuildContext context) {
    final cardH = cardW * 1.46;
    final messy = kind == GameCardKind.discard;
    // الرمي فاضي أول اللعبة (مكانها بس، بإطار)، وتمتلي طبقة طبقة مع الوقت.
    final layers = count.clamp(0, 6);
    final fs = gameFont(22, scale, min: 11);
    return Semantics(
      label: '$label ${arabicNumber(count)}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: cardH + 8,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (layers == 0)
                  Container(
                    width: cardW,
                    height: cardH,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cardW * .1),
                      border: Border.all(color: Colors.white.withValues(alpha: .25), width: 2),
                    ),
                  ),
                for (var i = 0; i < layers; i++)
                  Transform.translate(
                    offset: Offset(
                      messy ? (i.isEven ? -1.2 : 1.2) * i * .5 * scale * 3 : 0,
                      (layers - 1 - i) * -scale * 3.2 + (layers - 1) * scale * 1.6,
                    ),
                    child: Transform.rotate(
                      angle: messy ? (i.isEven ? -.05 : .04) * (1 + i * .2) : 0,
                      child: GameCardFace(kind: kind, width: cardW),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8 * scale),
          UnconstrainedBox(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12 * scale + 2, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF241209).withValues(alpha: .88),
                borderRadius: BorderRadius.circular(40),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                child: Text(
                  // السحب والرمي كلهم بعددهم: الرمي يبدأ ٠ ويزيد بقدر الأوراق اللي تنتقل له (٢ كل مرة)
                  '$label ${arabicNumber(count)}',
                  key: ValueKey(count),
                  style: TextStyle(
                    fontFamily: kufi,
                    fontSize: fs,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFFF3DA),
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const noteColors = {
  NoteMark.trust: AppColors.green,
  NoteMark.suspect: AppColors.traitor,
  NoteMark.unsure: AppColors.gold,
};

/// مقعد لاعب: صورته بحلقتها، واسمه تحتها بلوح غامق، ومنصبه (الرئيس أو الوزير) بشريط ذهبي.
/// كل الأبعاد بوحدات التصميم مضروبة بالمقياس [scale].
class _SeatView extends StatelessWidget {
  const _SeatView({
    required this.scale,
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

  final double scale;
  final ViewPlayer player;
  final GameView view;
  final Room? room;
  final NoteMark? note;
  final DateTime now;
  final bool selectable;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// شفافية المقعد (يخفت وقت التصويت).
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
    final s = scale;
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
    final d = seatDiameter * s;

    Color? frame;
    if (over) {
      if (role == Role.traitor || role == Role.leader) frame = AppColors.traitor;
    } else if (p.id == view.presidentId) {
      frame = AppColors.gold;
    } else if (p.id == view.nomineeId) {
      frame = const Color(0xFFA78BFA);
    } else if (!isMe && (role == Role.traitor || role == Role.leader)) {
      frame = AppColors.traitor;
    }
    final style = frameStyle(rp?.frame);

    final avatar = AnimatedScale(
      scale: selectable ? 1.08 : 1,
      duration: const Duration(milliseconds: 250),
      // الإطار المشترى يبان دايم، والتمييز (رئيس، مختار، خاين تعرفه) توهج حوله.
      child: TableAvatar(
        avatar: rp?.avatar ?? 'masked',
        size: d,
        ring: style == null ? frame : null,
        glow: style == null ? null : frame,
        style: style,
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

    final office = over
        ? (ready
              ? const ('جاهز يعيد', [Color(0xFFB8F2CC), Color(0xFF4FCB86), Color(0xFF2A9A5C)], Color(0xFF062814))
              : gone
              ? const ('طلع', [Color(0xFFC9CCDD), Color(0xFF8E92AB), Color(0xFF5B5F78)], Colors.white)
              : null)
        : p.id == view.presidentId
        ? const ('الرئيس', [Color(0xFFFFE9A0), Color(0xFFF2C14E), Color(0xFFD29A2A)], Color(0xFF3A2400))
        : p.id == view.nomineeId
        ? const ('الوزير', [Color(0xFFE6D8FF), Color(0xFFB794F6), Color(0xFF8A63D8)], Color(0xFF1E0F4A))
        : null;
    final fs = gameFont(22, s, min: 11);
    final shownName = isMe && !view.spectator ? 'أنت' : p.name;
    final cx = 115 * s; // نص المقعد بالعرض
    final cy = 100 * s; // نص الصورة بالطول

    Widget at(double dx, double dy, Widget child) => Positioned(
      left: cx + dx * s,
      top: cy + dy * s,
      child: FractionalTranslation(translation: const Offset(-.5, -.5), child: child),
    );
    // مكان الشريط والاسم تحت الصورة بالبكسل: على الجوال الصغير الخط أكبر من التصميم، فنحسب على قد حجمهم.
    Widget below(double dy, Widget child) => Positioned(
      left: cx,
      top: cy + dy,
      child: FractionalTranslation(translation: const Offset(-.5, -.5), child: child),
    );
    final ribbonFs = gameFont(26, s, min: 11);
    final ribbonH = math.max(48 * s, ribbonFs * 1.5);
    final pillH = math.max(32 * s, fs * 1.35);
    final ribbonTop = d / 2 - 15 * s;
    final nameY = office == null ? d / 2 - 3 * s + pillH / 2 : ribbonTop + ribbonH + pillH / 2 - 3 * s;

    return Semantics(
      button: onTap != null,
      label: selectable ? 'اختيار ${p.name}' : 'ملف ${p.name}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // فانوس صغير جنب كل لاعب
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: gone ? math.min(dim, .4) : dim,
                duration: const Duration(milliseconds: 400),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    at(
                      0,
                      0,
                      _Since(
                        // بعد اللعبة الغطا ينشال عن الكل، عشان تبان الأدوار.
                        since: dead && !over ? deathAt : null,
                        seconds: _deathSeconds,
                        builder: (context, t) => _figure(t, dead && !over, over, moving, isMe, role, opinion, d, s),
                      ),
                    ),
                    if (office != null)
                      below(
                        ribbonTop + ribbonH / 2,
                        GoldRibbonLabel(office.$1, size: ribbonFs, colors: office.$2, ink: office.$3),
                      ),
                    below(
                      nameY,
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 190 * s + 30),
                        child: NamePill(shownName, size: fs, color: dead ? AppColors.muted : const Color(0xFFFFF6E6)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selectable) at(0, 0, PulseRing(size: d * .9)),
            // فوق كل شي (لوحة القرارات ولوحة الجولة اللي في الزوايا)، عشان كلام اللاعب ما يتغطى.
            if (reaction != null && sticker == null)
              at(
                0,
                -118,
                _AboveAll(
                  child: _Bubble(reaction: reaction, view: view, bubble: rp?.bubble, scale: s),
                ),
              ),
            // الملصق كبير ويلمس طرف الصورة بس: نحسب مكانه بالبكسل على قد حجمه، مو بوحدات التصميم.
            if (reaction != null && sticker != null)
              below(
                (stickerBelow ? 1 : -1) * (d / 2 + stickerSize(s) * .4),
                _AboveAll(
                  child: _Bubble(reaction: reaction, view: view, bubble: rp?.bubble, scale: s),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// اللاعب وفانوسه جنبه، وفوقه شاراته. المطرود ([dying]) يحزن، وبعدها ينطفي فانوسه
  /// ويطيح عليه غطا ([t] الوقت من بداية حزنه).
  Widget _figure(
    double t,
    bool dying,
    bool over,
    Widget avatar,
    bool isMe,
    Role? role,
    ({int suspect, int trust})? opinion,
    double d,
    double s,
  ) {
    final p = player;
    // افكت موته من المتجر (الكل يشوفه). الافتراضي: الغطا الرمادي.
    final fx = deathFxOf(room?.player(p.id)?.death);
    final custom = dying && fx != DeathFx.cloth;
    final sad = dying ? seg(t, 0, .6) * (1 - (custom ? seg(t, 1.2, 1.7) : seg(t, 2.8, 3.4))) : 0.0;
    final grey = dying ? seg(t, 0, .9) * .8 : 0.0;
    final lamp = over ? (p.alive ? 1.0 : 0.0) : (dying ? 1 - seg(t, 2.0, 2.5) : 1.0);
    final cloth = dying && !custom ? seg(t, 2.6, 3.8) : 0.0;
    Widget figure = Transform.translate(
      offset: Offset(0, 5 * sad),
      child: Transform.rotate(angle: .2 * sad, child: avatar),
    );
    if (custom) {
      final look = deathLook(fx, t);
      figure = Stack(
        clipBehavior: Clip.none,
        children: [
          if (!deathHidesAvatar(fx, t))
            Opacity(
              opacity: look.opacity.clamp(0.0, 1.0),
              child: look.matrix == null
                  ? figure
                  : ColorFiltered(colorFilter: ColorFilter.matrix(look.matrix!), child: figure),
            )
          else
            SizedBox(width: d, height: d),
          if (t < 1.6) Positioned.fill(child: CustomPaint(painter: _SadPainter(t))),
          Positioned.fill(
            child: DeathLayer(fx: fx, t: t),
          ),
          Positioned.fill(
            child: DeathMark(fx: fx, t: t),
          ),
        ],
      );
    } else if (dying) {
      figure = Stack(
        clipBehavior: Clip.none,
        children: [
          ColorFiltered(colorFilter: ColorFilter.matrix(greyMatrix(grey)), child: figure),
          if (t < 3) Positioned.fill(child: CustomPaint(painter: _SadPainter(t))),
        ],
      );
    }
    final badge = d * .27;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // لما يتغطى كامل ما نرسمه تحت الغطا (ولا يطل إطاره من تحته).
        if (cloth < 1) figure else SizedBox(width: d, height: d),
        Positioned(
          right: -d * .27,
          top: d * .56,
          child: FloorLantern(width: 22 * s, on: lamp, seed: p.seat),
        ),
        if (cloth > 0)
          Positioned(
            left: -d * .06,
            top: -d * .06,
            child: SeatCloth(k: cloth, width: d * 1.12, height: d * 1.12),
          ),
        if (over && !p.alive)
          Positioned.fill(
            child: Center(child: Gfx('skull', size: d * .5)),
          ),
        // ختم أحمر على كل خاين تعرفه (يبقى حتى لو صار رئيس أو وزير وتغيّر لون الإطار).
        // وبعد اللعبة الكل يبان ختمه، حتى الأوفياء.
        if (role != null && (over || !isMe && (role == Role.traitor || role == Role.leader)))
          Positioned(
            left: -d * .06,
            bottom: -d * .04,
            child: role == Role.leader ? LeaderSeal(size: badge * 1.2) : Seal(loyal: role == Role.loyal, size: badge),
          ),
        if (p.knownSpecial case final special? when !isMe && (over || special != Special.seer))
          Positioned(
            right: -d * .04,
            bottom: -d * .02,
            child: Gfx(specialIcon[special]!, size: badge * .95),
          ),
        if (room?.player(p.id)?.bot ?? false)
          Positioned(
            right: -d * .04,
            top: d * .1,
            child: Gfx('bot', size: badge * .9),
          ),
        if (view.phase == Phase.election && p.hasVoted)
          Positioned(
            left: -d * .04,
            top: -d * .02,
            child: Gfx('check', size: badge),
          ),
        if (note != null)
          Positioned(
            bottom: -2,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: math.max(10, d * .17),
                height: math.max(10, d * .17),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: noteColors[note],
                  border: Border.all(color: gameInk, width: 2),
                ),
              ),
            ),
          ),
        if (opinion != null && (opinion.suspect > 0 || opinion.trust > 0))
          Positioned(
            top: -d * .06,
            right: -d * .1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF241209),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: opinion.suspect >= opinion.trust ? AppColors.traitor : AppColors.green,
                  width: 1.4,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Gfx(opinion.suspect >= opinion.trust ? 'suspect' : 'trust', size: math.max(13, d * .2)),
                  const SizedBox(width: 2),
                  Text(
                    arabicNumber(opinion.suspect >= opinion.trust ? opinion.suspect : opinion.trust),
                    style: TextStyle(fontSize: math.max(10, d * .17), fontWeight: FontWeight.w800),
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
    final sand = urgent > 0 ? const Color(0xFFFF5A5A) : const Color(0xFFF7C948);
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
      ..moveTo(7, 8)
      ..lineTo(33, 8)
      ..quadraticBezierTo(33, 24, 21.5, 31)
      ..lineTo(18.5, 31)
      ..quadraticBezierTo(7, 24, 7, 8)
      ..close();
    final bottom = Path()
      ..moveTo(18.5, 33)
      ..lineTo(21.5, 33)
      ..quadraticBezierTo(33, 40, 33, 56)
      ..lineTo(7, 56)
      ..quadraticBezierTo(7, 40, 18.5, 33)
      ..close();
    final glass = Paint()..color = const Color(0xFFF4E6C8).withValues(alpha: .42);
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
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..color = gameInk;
    canvas.drawPath(top, outline);
    canvas.drawPath(bottom, outline);
    final wood = Paint()..color = const Color(0xFF9A6A38);
    for (final x in [3.5, 34.1]) {
      canvas.drawRect(Rect.fromLTWH(x, 6, 2.6, 52), wood);
      canvas.drawRect(
        Rect.fromLTWH(x, 6, 2.6, 52),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = gameInk,
      );
    }
    final cap = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD9A868), Color(0xFF8A5A30)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(0, 0, 40, 64));
    for (final y in [1.0, 56.0]) {
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(1, y, 38, 6), const Radius.circular(2.4));
      canvas.drawRRect(r, cap);
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = gameInk,
      );
    }
  }

  @override
  bool shouldRepaint(_HourglassPainter old) => true;
}

/// أيقونة كل دور خاص (نفس overlays.dart → specialInfo).
const specialIcon = {
  Special.seer: 'seer',
  Special.guardian: 'shield',
  Special.judge: 'scales',
  Special.elder: 'ballot',
  Special.spy: 'eye',
};

/// يرسم [child] فوق كل شي في الصفحة (طبقة الـOverlay)، ومكانه يلحق مكانه هني (وسطه على هذي النقطة).
class _AboveAll extends StatefulWidget {
  const _AboveAll({required this.child});

  final Widget child;

  @override
  State<_AboveAll> createState() => _AboveAllState();
}

class _AboveAllState extends State<_AboveAll> {
  final _link = LayerLink();
  final _portal = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    _portal.show();
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
    link: _link,
    child: OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => Positioned(
        left: 0,
        top: 0,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.center,
          followerAnchor: Alignment.center,
          child: IgnorePointer(child: widget.child),
        ),
      ),
      child: const SizedBox(width: 1, height: 1),
    ),
  );
}

/// حجم الملصق فوق اللاعب بالبكسل. على الجوال الصغير ما ينزل عن ٩٢ عشان يبان واضح.
double stickerSize(double scale) => math.max(92, 190 * scale);

/// اللي قاله اللاعب: ملصق، أو كلام بفقاعته من المتجر.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.reaction, required this.view, required this.bubble, required this.scale});

  final Reaction reaction;
  final GameView view;
  final String? bubble;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final sticker = stickerById(reaction.kind);
    if (sticker != null) return StickerView(sticker: sticker, size: stickerSize(scale));
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
      child: ChatBubble(
        style: bubbleStyle(bubble),
        text: text,
        fontSize: gameFont(20, scale, min: 12),
        maxWidth: math.max(150, 260 * scale),
      ),
    );
  }
}
