import 'package:flutter/material.dart';

import '../models/events.dart';
import '../models/leaderboard.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../models/tour.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
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
  Widget build(BuildContext context) => NightScaffold(
    glow: const Color(0xFF6B4A12),
    appBar: AppBar(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Gfx('trophy', size: 30), SizedBox(width: 8), Text('بطولة الأسبوع')],
      ),
    ),
    body: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: StreamBuilder<Tour>(
          stream: _tour,
          builder: (context, snap) {
            final tour = snap.data ?? Tour.empty;
            return ValueListenableBuilder(
              valueListenable: Backend.instance.profile,
              builder: (context, p, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 280, child: _status(p)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Panel(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                      child: _Bracket(tour: tour, me: Backend.instance.uid),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _status(Profile p) => MinuteTicker(
    builder: (context, now) {
      final w = Weekend.at(now);
      final mine = p.tour?.week == _week ? p.tour : null;
      final (String title, String note, Widget? action) = switch (mine) {
        null when !w.on => ('البطولة مقفلة', 'تفتح الخميس ٦ المغرب مع نهاية الأسبوع', null),
        null => (
          'سجّل في البطولة',
          'تفوز تتأهل، وتخسر تطلع. ٣ فوزات ورا بعض وأنت البطل.',
          GameButton(
            label: _busy ? 'لحظة…' : 'سجّل بـ${arabicNumber(tourFee)} ذهب',
            icon: const Gfx('coin', size: 24),
            height: 48,
            fontSize: 16,
            onPressed: _busy ? null : () => _run(Backend.instance.tourJoin),
          ),
        ),
        TourState(champion: true) => (
          'أنت بطل الأسبوع!',
          'فزت بالنهائي وأخذت الجائزة. ترجع تتحدى الأسبوع الجاي.',
          null,
        ),
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
          GameButton(
            label: _busy ? 'لحظة…' : 'العب جولتك',
            icon: const Gfx('games', size: 26),
            height: 48,
            fontSize: 17,
            onPressed: _busy ? null : _play,
          ),
        ),
      };
      return Panel(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: (w.on ? AppColors.green : AppColors.muted).withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: w.on ? AppColors.green : AppColors.muted),
                ),
                child: Text(
                  w.on
                      ? 'مفتوحة الحين · باقي ${timeLeft(w.ends.difference(now))}'
                      : 'تفتح بعد ${timeLeft(w.starts.difference(now))}',
                  style: TextStyle(
                    color: w.on ? AppColors.green : AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GoldText(title, size: 22),
            const SizedBox(height: 4),
            Text(
              note,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withValues(alpha: .45)),
              ),
              child: Row(
                children: [
                  const Gfx('trophy', size: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('جائزة البطل', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                        Row(
                          children: [
                            Amount('coin', arabicNumber(tourPrize.coins), size: 16),
                            const SizedBox(width: 10),
                            Amount('gem', arabicNumber(tourPrize.diamonds), size: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (action != null) ...[const SizedBox(height: 10), action],
          ],
        ),
      );
    },
  );
}

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
      const top = 30.0;
      // الأعمدة من اليمين لليسار.
      final xs = [w * .87, w * .62, w * .37, w * .12];
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
              painter: _Lines(xs: xs, y: y),
            ),
          ),
          for (final (c, name) in tourStageNames.indexed)
            Positioned(
              left: xs[c] - 55,
              width: 110,
              top: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gold.withValues(alpha: .5)),
                  ),
                  child: Text(name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          for (var c = 0; c < 4; c++)
            for (var i = 0; i < _slots[c]; i++)
              Positioned(
                left: xs[c] - (c == 3 ? 34 : 21),
                top: y(c, i) - (c == 3 ? 34 : 21),
                child: i < columns[c].length
                    ? _Seat(entry: columns[c][i], me: me, col: c)
                    : _Empty(size: c == 3 ? 68 : 42),
              ),
          if (total > 8)
            Positioned(
              right: 4,
              bottom: 0,
              child: Text(
                '${arabicNumber(total)} مشارك هالأسبوع',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
          if (total == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 30),
                child: Text('ما سجّل أحد للحين، كن أول واحد!', style: TextStyle(color: AppColors.muted)),
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
  const _Seat({required this.entry, required this.me, required this.col});

  final TourEntry entry;
  final String me;
  final int col;

  @override
  Widget build(BuildContext context) {
    final mine = entry.uid == me;
    // طلع بهالدور بالذات (مو بعده).
    final lost = entry.out && entry.stage == col;
    final size = col == 3 ? 68.0 : 42.0;
    return Tooltip(
      message: entry.name,
      child: Opacity(
        opacity: lost ? .4 : 1,
        child: PlayerAvatar(
          avatar: entry.avatar,
          size: size,
          animate: col == 3,
          style: col == 3 ? frameStyle(entry.frame) : null,
          frame: mine ? AppColors.gold : (col == 3 ? AppColors.goldLight : null),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: .04),
      border: Border.all(color: AppColors.gold.withValues(alpha: .25), width: 1.5),
    ),
  );
}

class _Lines extends CustomPainter {
  _Lines({required this.xs, required this.y});

  final List<double> xs;
  final double Function(int col, int i) y;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.gold.withValues(alpha: .3);
    const slots = [8, 4, 2, 1];
    for (var c = 0; c < 3; c++) {
      for (var i = 0; i < slots[c]; i++) {
        final a = Offset(xs[c] - 24, y(c, i));
        final b = Offset(xs[c + 1] + (c + 1 == 3 ? 36 : 24), y(c + 1, i ~/ 2));
        final mid = (a.dx + b.dx) / 2;
        canvas.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..lineTo(mid, a.dy)
            ..lineTo(mid, b.dy)
            ..lineTo(b.dx, b.dy),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Lines old) => false;
}
