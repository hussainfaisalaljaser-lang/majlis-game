import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/events.dart';
import '../models/leaderboard.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../models/tour.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/design_season.dart';
import '../widgets/ui.dart';
import '../widgets/weekend.dart';
import 'waiting_screen.dart';

/// بطولة الأسبوع: تفتح وقت نهاية الأسبوع، تسجّل برسوم، وكل جولة تفوزها تتأهل للي بعدها
/// (الدور الأول ← نص النهائي ← النهائي)، وتخسر تطلع. اللي يفوز النهائي بطل الأسبوع.
class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  final _week = gulfWeek(DateTime.now());
  late final Stream<Tour> _tour = Backend.instance.watchTour(_week);
  bool _busy = false;

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _play() => _run(() async {
    final code = await Backend.instance.tourPlay();
    if (!mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => WaitingScreen(tier: null, playerCount: 7, code: code)));
  });

  @override
  Widget build(BuildContext context) => StreamBuilder<Tour>(
    stream: _tour,
    builder: (context, snap) => ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) => MinuteTicker(
        builder: (context, now) => TournamentView(
          profile: p,
          tour: snap.data ?? Tour.empty,
          me: Backend.instance.uid,
          week: _week,
          now: now,
          busy: _busy,
          onJoin: () => _run(Backend.instance.tourJoin),
          onPlay: _play,
        ),
      ),
    ),
  );
}

/// شاشة البطولة بدون سيرفر: الحالة يسار، وشجرة المشاركين يمين.
class TournamentView extends StatelessWidget {
  const TournamentView({
    super.key,
    required this.profile,
    required this.tour,
    required this.me,
    required this.week,
    required this.now,
    required this.busy,
    required this.onJoin,
    required this.onPlay,
  });

  final Profile profile;
  final Tour tour;
  final String me;
  final String week;
  final DateTime now;
  final bool busy;
  final VoidCallback onJoin;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => NightScaffold(
    appBar: SnTopBar(
      title: 'بطولة الأسبوع',
      icon: const Gfx('trophy', size: 30),
      trailing: [SnWallet(coins: profile.coins, diamonds: profile.diamonds, infinite: profile.dev)],
    ),
    body: SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, box) {
          final leftW = (box.maxWidth * .3).clamp(230.0, 300.0);
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: WoodPanel(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: _Bracket(tour: tour, me: me),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: leftW, child: _status()),
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _status() {
    final p = profile;
    final w = Weekend.at(now);
    final mine = p.tour?.week == week ? p.tour : null;
    final (String title, String note, Widget? action) = switch (mine) {
      null when !w.on => ('البطولة مقفلة', 'تفتح الخميس ٦ المغرب مع نهاية الأسبوع', null),
      null => (
        'سجّل في البطولة',
        'تفوز تتأهل، وتخسر تطلع. ٣ فوزات ورا بعض وأنت البطل.',
        SnButton(
          label: busy ? 'لحظة…' : 'سجّل بـ${arabicNumber(tourFee)} ذهب',
          icon: const Gfx('coin', size: 26),
          height: 46,
          fontSize: 16,
          onPressed: busy ? null : onJoin,
        ),
      ),
      TourState(champion: true) => ('أنت بطل الأسبوع!', 'فزت بالنهائي وأخذت الجائزة. ترجع تتحدى الأسبوع الجاي.', null),
      TourState(out: true, :final stage) => (
        'طلعت من البطولة',
        'خسرت بـ${tourStageNames[stage]}. تقدر تسجّل الأسبوع الجاي.',
        null,
      ),
      final TourState t when !w.on => (
        'البطولة خلصت',
        'وصلت ${tourStageNames[t.stage]}. ترجع تتحدى الأسبوع الجاي.',
        null,
      ),
      final TourState t => (
        'دورك: ${tourStageNames[t.stage]}',
        'طاولة البطولة ٧ لاعبين، ولو فاز فريقك تتأهل للي بعدها.',
        SnButton(
          label: busy ? 'لحظة…' : 'العب جولتك',
          icon: const Gfx('games', size: 28),
          tone: SnTone.green,
          height: 46,
          fontSize: 17,
          onPressed: busy ? null : onPlay,
        ),
      ),
    };
    return LayoutBuilder(
      builder: (context, box) {
        final k = (box.maxHeight / 477).clamp(.6, 1.0);
        return VelvetPanel(
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              const Positioned.fill(child: SnSunburst(alignment: Alignment(0, -.5))),
              Padding(
                padding: EdgeInsets.fromLTRB(14, 12 * k, 14, 14 * k),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SnPill(
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          w.on
                              ? 'مفتوحة الحين · باقي ${timeLeft(w.ends.difference(now))}'
                              : 'تفتح بعد ${timeLeft(w.starts.difference(now))}',
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: kufi,
                            color: w.on ? const Color(0xFFA6EE7A) : const Color(0xFFD9C29B),
                            fontSize: 12.5,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Center(child: Gfx('trophy', size: 96 * k)),
                    ),
                    GoldTitle(title, size: math.max(16, 23 * k)),
                    SizedBox(height: 6 * k),
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Text(
                          note,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFF1DDBA),
                            fontSize: math.max(11, 12.5 * k),
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    PlankBar(
                      gold: true,
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                      child: Row(
                        children: [
                          const Gfx('trophy', size: 32),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'جائزة البطل',
                                  style: TextStyle(
                                    fontFamily: kufi,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    height: 1.2,
                                    color: Color(0xFFF9D277),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Amount('coin', arabicNumber(tourPrize.coins), size: 16, style: _prizeText),
                                    const SizedBox(width: 10),
                                    Amount('gem', arabicNumber(tourPrize.diamonds), size: 16, style: _prizeText),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (action != null) ...[SizedBox(height: 10 * k), action],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const _prizeText = TextStyle(
  fontFamily: kufi,
  fontWeight: FontWeight.w800,
  fontSize: 14,
  height: 1.2,
  color: Color(0xFFFFF3DA),
);

/// شجرة البطولة: من اليمين الدور الأول، وبعده نص النهائي والنهائي، وآخرها البطل.
/// كل عمود فيه اللي وصلوه (بالكثير ٨ و٤ و٢ و١)، وأنت بإطار ذهبي، واللي طلع باهت.
class _Bracket extends StatelessWidget {
  const _Bracket({required this.tour, required this.me});

  final Tour tour;
  final String me;

  static const _slots = [8, 4, 2, 1];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      const top = 34.0;
      // الأعمدة من اليمين لليسار.
      final xs = [w * .87, w * .62, w * .37, w * .12];
      final seat = ((h - top - 8) / 8 * .86).clamp(30.0, 46.0);
      final big = (seat * 1.6).clamp(48.0, 72.0);
      double y(int col, int i) {
        final n = _slots[col];
        final step = (h - top - 8) / n;
        return top + step * (i + .5);
      }

      final columns = [for (var c = 0; c < 4; c++) _pick(tour.reached(c), _slots[c])];
      final total = tour.players.length;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _Lines(xs: xs, y: y, seat: seat, big: big),
            ),
          ),
          for (final (c, name) in tourStageNames.indexed)
            Positioned(
              left: xs[c] - 56,
              width: 112,
              top: 0,
              child: Center(
                child: PlankBar(
                  radius: 10,
                  gold: c == 3,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontFamily: kufi,
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFF3DA),
                    ),
                  ),
                ),
              ),
            ),
          for (var c = 0; c < 4; c++)
            for (var i = 0; i < _slots[c]; i++)
              Positioned(
                left: xs[c] - (c == 3 ? big : seat) / 2 - (c == 3 ? 6 : 4),
                top: y(c, i) - (c == 3 ? big : seat) / 2 - (c == 3 ? 6 : 4),
                child: i < columns[c].length
                    ? _Seat(entry: columns[c][i], me: me, col: c, size: c == 3 ? big : seat)
                    : _Empty(size: c == 3 ? big : seat, trophy: c == 3),
              ),
          if (total > 8)
            Positioned(
              left: 4,
              bottom: 0,
              child: Text(
                '${arabicNumber(total)} مشارك هالأسبوع',
                style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          if (total == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 30),
                child: Text(
                  'ما سجّل أحد للحين، كن أول واحد!',
                  style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      );
    },
  );

  /// أفضل [n] (أبعد واحد وصل أول)، وأنت دايم معهم لو وصلت.
  List<TourEntry> _pick(List<TourEntry> list, int n) {
    final mine = list.where((e) => e.uid == me);
    final rest = list.where((e) => e.uid != me);
    return [...mine, ...rest].take(n).toList();
  }
}

class _Seat extends StatelessWidget {
  const _Seat({required this.entry, required this.me, required this.col, required this.size});

  final TourEntry entry;
  final String me;
  final int col;
  final double size;

  @override
  Widget build(BuildContext context) {
    final mine = entry.uid == me;
    // طلع بهالدور بالذات (مو بعده).
    final lost = entry.out && entry.stage == col;
    return Tooltip(
      message: entry.name,
      child: Opacity(
        opacity: lost ? .4 : 1,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (mine)
              Container(
                width: size + 10,
                height: size + 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: .85), blurRadius: 12, spreadRadius: 1)],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: GoldRingAvatar(
                avatar: entry.avatar,
                size: size,
                animate: col == 3,
                style: col == 3 ? frameStyle(entry.frame) : null,
                gems: col == 3,
              ),
            ),
            if (col == 3)
              PositionedDirectional(
                top: -size * .42,
                child: Gfx('crown', size: size * .5),
              ),
          ],
        ),
      ),
    );
  }
}

/// مكان فاضي بالشجرة: دائرة غامقة بحلقة ذهب باهتة (وبالنهائي كأس باهت).
class _Empty extends StatelessWidget {
  const _Empty({required this.size, this.trophy = false});

  final double size;
  final bool trophy;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(4),
    child: Container(
      width: size + size * .15,
      height: size + size * .15,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(colors: [Color(0xFF2B1A0F), Color(0xFF1A0F08)]),
        border: Border.all(color: const Color(0xFF8A6A3A).withValues(alpha: .6), width: 2),
      ),
      child: trophy ? Opacity(opacity: .35, child: Gfx('trophy', size: size * .6)) : null,
    ),
  );
}

class _Lines extends CustomPainter {
  _Lines({required this.xs, required this.y, required this.seat, required this.big});

  final List<double> xs;
  final double Function(int col, int i) y;
  final double seat, big;

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF140B06);
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFC99A3E).withValues(alpha: .85);
    const slots = [8, 4, 2, 1];
    for (var c = 0; c < 3; c++) {
      for (var i = 0; i < slots[c]; i++) {
        final a = Offset(xs[c] - seat / 2 - 6, y(c, i));
        final b = Offset(xs[c + 1] + (c + 1 == 3 ? big : seat) / 2 + 6, y(c + 1, i ~/ 2));
        final mid = (a.dx + b.dx) / 2;
        final path = Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(mid, a.dy)
          ..lineTo(mid, b.dy)
          ..lineTo(b.dx, b.dy);
        canvas.drawPath(path, dark);
        canvas.drawPath(path, gold);
      }
    }
  }

  @override
  bool shouldRepaint(_Lines old) => old.seat != seat || old.big != big;
}
