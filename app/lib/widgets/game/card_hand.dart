import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/shop.dart';
import '../../theme.dart';
import '../design.dart';
import '../design_game.dart';
import '../fx.dart';
import 'policy_card.dart';
import 'table_art.dart';

/// وش يصير للكرت اللي تختاره من يدك.
enum HandTarget {
  /// الرئيس يرميه على كومة الرمي.
  burn,

  /// الوزير يمرره لنص الطاولة (يختمه).
  stamp,
}

/// كروتك بيدك: تطلع من تحت وتنفتح مروحة بنص الطاولة (مثل التصميم). اضغط الكرت أو اسحبه: الرئيس يرميه على
/// كومة الرمي (يسار) ويحترق، والوزير يمرره لنص الطاولة ويختمه. بدون [onPick] الكروت للعرض بس (كشف أول ٣ كروت).
/// التعليمة نفسها (اختار الكرت…) تطلع على لوح الرسالة تحت من الشاشة.
class CardHand extends StatefulWidget {
  const CardHand({
    super.key,
    required this.cards,
    required this.hint,
    this.skin,
    this.onPick,
    this.verb = '',
    this.target = HandTarget.burn,
    this.extra,
  });

  final List<Policy> cards;

  /// نص التعليمة (للقارئ والاختبارات).
  final String hint;
  final CardSkin? skin;
  final ValueChanged<int>? onPick;

  /// الكلمة اللي قبل اسم الكرت (للقارئ والاختبارات): ارمِ كرت ١ خونة.
  final String verb;
  final HandTarget target;

  /// جنب الكروت (طلب الفيتو أو زر تمام).
  final Widget? extra;

  @override
  State<CardHand> createState() => _CardHandState();
}

class _CardHandState extends State<CardHand> with TickerProviderStateMixin {
  late final _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  late final _back = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  late final _use = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));

  /// الكرت اللي تسحبه الحين ومكانه.
  int? _drag;
  Offset _at = Offset.zero;

  /// الكرت اللي رجع لمكانه، ومن وين رجع.
  int? _returning;
  Offset _returnFrom = Offset.zero;

  /// الكرت اللي اخترته (يروح للكومة أو لنص الطاولة)، ومن وين راح.
  int? _used;
  Offset _usedFrom = Offset.zero;

  @override
  void dispose() {
    _enter.dispose();
    _back.dispose();
    _use.dispose();
    super.dispose();
  }

  void _pick(int i, Offset from) {
    if (_used != null || widget.onPick == null) return;
    setState(() {
      _used = i;
      _usedFrom = from;
      _drag = null;
    });
    // الحركة تخلص وبعدها نرسلها (تاخذ نص ثانية بس).
    _use.forward(from: 0).then((_) {
      if (mounted) widget.onPick!(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        final st = Stage(size);
        final target = _target(st);
        final n = widget.cards.length;
        final cardW = _cardW(st);
        final cardH = cardW * 1.46;
        final zone = _zone(st);
        Offset rest(int i) {
          final k = i - (n - 1) / 2;
          final c = st.at(958, 672);
          // المروحة ما تغطي لوح الرسالة تحت (على الجوال الصغير الكروت أكبر من التصميم، فنرفعها).
          final plankH = math.max(TablePos.plank.height * st.s, gameFont(34, st.s, min: 13) * 1.4 + 14);
          final plankTop = st.at(0, TablePos.plank.center.dy).dy - plankH / 2;
          final y = math.min(c.dy, plankTop - cardH * .5 - 6 - 10 * st.s);
          return Offset(c.dx + k * cardW * .8, y + k.abs() * 10 * st.s);
        }

        double restAngle(int i) => (i - (n - 1) / 2) * .075;
        final heat = _drag == null ? 0.0 : (1 - ((_at - target).distance - zone) / (zone * 2.5)).clamp(0.0, 1.0);
        return AnimatedBuilder(
          animation: Listenable.merge([_enter, _back, _use]),
          builder: (context, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              if (widget.onPick != null)
                Positioned(
                  left: target.dx - zone,
                  top: target.dy - zone,
                  width: zone * 2,
                  height: zone * 2,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: _enter.value,
                      child: _DropZone(
                        burn: widget.target == HandTarget.burn,
                        heat: math.max(heat, _used == null ? 0 : _use.value),
                      ),
                    ),
                  ),
                ),
              for (var i = 0; i < n; i++)
                if (i != _drag && i != _used) _card(i, rest(i), restAngle(i), cardW, cardH),
              // اللي بيدك فوق الباقين.
              if (_drag case final i?) _card(i, _at, 0, cardW, cardH, lifted: true),
              if (_used case final i?) _usedCard(i, target, cardW, cardH),
              if (widget.extra case final extra?)
                Positioned(
                  left: st.at(1215, 700).dx,
                  top: st.at(1215, 700).dy - 22,
                  child: Opacity(opacity: _enter.value, child: extra),
                ),
            ],
          ),
        );
      },
    );
  }

  /// مكان الرمي (كومة الرمي) أو الختم (نص البيضاوي).
  Offset _target(Stage st) => widget.target == HandTarget.burn
      ? st.at(TablePos.discard.dx, TablePos.discard.dy)
      : st.at(TablePos.oval.dx, TablePos.oval.dy);

  /// عرض الكرت: على قد الشاشة، وما يصغر عن حجم ينضغط بالإصبع.
  static double _cardW(Stage st) => (170 * st.s).clamp(66.0, 190.0);

  static double _zone(Stage st) => math.max(54.0, 120 * st.s);

  /// كرت بمكانه بالمروحة (أو بيدك وأنت تسحبه).
  Widget _card(int i, Offset at, double angle, double w, double h, {bool lifted = false}) {
    final policy = widget.cards[i];
    // تطلع من تحت ورا بعض وتنفتح.
    final e = Curves.easeOutBack.transform(
      ((_enter.value - i * .12) / (1 - (widget.cards.length - 1) * .12)).clamp(0.0, 1.0),
    );
    var pos = Offset(at.dx, at.dy + (1 - e) * (h + 40));
    if (i == _returning && _back.isAnimating) {
      pos = Offset.lerp(_returnFrom, at, Curves.easeOut.transform(_back.value))!;
    }
    final pickable = widget.onPick != null && _used == null;
    Widget card = PolicyCard(
      policy: policy,
      skin: widget.skin,
      width: w,
      highlight: lifted,
      label: '${widget.verb} كرت ${i + 1} ${policy == Policy.loyal ? 'أوفياء' : 'خونة'}',
      onTap: pickable ? () => _pick(i, at) : null,
    );
    if (pickable) {
      card = GestureDetector(
        onPanStart: (_) => setState(() {
          _drag = i;
          _at = at;
        }),
        onPanUpdate: (d) => setState(() => _at += d.delta),
        onPanEnd: (_) => _drop(i, at),
        onPanCancel: () => _drop(i, at),
        child: card,
      );
    }
    return Positioned(
      left: pos.dx - w / 2,
      top: pos.dy - h / 2,
      width: w,
      height: h,
      child: Transform.rotate(
        angle: angle * e,
        child: Transform.scale(scale: lifted ? 1.08 : 1, child: card),
      ),
    );
  }

  /// تركت الكرت: لو فوق المكان ينختار، وإلا يرجع لمكانه.
  void _drop(int i, Offset home) {
    if (_drag != i) return;
    final box = context.size;
    if (box == null) return;
    final st = Stage(box);
    if ((_at - _target(st)).distance < _zone(st) * 1.2) return _pick(i, _at);
    setState(() {
      _drag = null;
      _returning = i;
      _returnFrom = _at;
    });
    _back.forward(from: 0);
  }

  /// الكرت المختار: يطير للكومة (أو لنص الطاولة) ويصغر. بالرمي يحمر ويحترق، وبالتمرير يلمع.
  Widget _usedCard(int i, Offset target, double w, double h) {
    final p = _use.value;
    final fly = Curves.easeInCubic.transform((p / .55).clamp(0.0, 1.0));
    final pos = Offset.lerp(_usedFrom, target, fly)!;
    final burn = widget.target == HandTarget.burn;
    final end = ((p - .55) / .45).clamp(0.0, 1.0);
    final scale = burn ? (1 - .45 * fly) * (1 - .8 * end) : 1 - .1 * fly;
    return Positioned(
      left: pos.dx - w / 2,
      top: pos.dy - h / 2,
      width: w,
      height: h,
      child: IgnorePointer(
        child: Opacity(
          opacity: burn ? 1 - end : 1,
          child: Transform.scale(
            scale: scale,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                burn
                    ? const Color(0xFFFF6A00).withValues(alpha: .85 * end)
                    : Colors.white.withValues(alpha: .6 * math.sin(end * math.pi)),
                BlendMode.srcATop,
              ),
              child: PolicyCard(policy: widget.cards[i], skin: widget.skin, width: w),
            ),
          ),
        ),
      ),
    );
  }
}

/// مكان الرمي أو التمرير: هالة تتوهج لما يقرب الكرت ([heat] ٠–١)، وكلمة صغيرة تحتها.
class _DropZone extends StatelessWidget {
  const _DropZone({required this.burn, required this.heat});

  final bool burn;
  final double heat;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      NamePill(burn ? 'ارمِ هنا' : 'مرّر هنا', size: 13, color: AppColors.goldLight),
      Expanded(
        child: RepaintBoundary(
          child: FxClock(
            builder: (context, time) => CustomPaint(size: Size.infinite, painter: _ZonePainter(time, heat, burn)),
          ),
        ),
      ),
    ],
  );
}

class _ZonePainter extends CustomPainter {
  _ZonePainter(this.time, this.heat, this.burn) : super(repaint: time);

  final ValueListenable<double> time;
  final double heat;
  final bool burn;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final c = Offset(size.width / 2, size.height * .5);
    final r = size.shortestSide / 2;
    final col = burn ? const Color(0xFFFF8A1F) : AppColors.gold;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            col.withValues(alpha: .18 + .5 * heat),
            col.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    final pulse = .5 + .5 * math.sin(t * 5);
    canvas.drawCircle(
      c,
      r * (.62 + .1 * pulse + .12 * heat),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + 2 * heat
        ..color = Color.lerp(col, Colors.white, heat)!.withValues(alpha: .55 + .35 * heat),
    );
    if (burn) {
      for (var k = 0; k < 4; k++) {
        final q = (t * (1.4 + heat) + k / 4) % 1;
        final x = c.dx + (k - 1.5) * r * .22 + math.sin(t * 6 + k) * 3;
        final h = (r * .22 + r * .35 * heat) * (1 - q * .4);
        canvas.drawPath(
          Path()
            ..moveTo(x - 5, c.dy + r * .5)
            ..quadraticBezierTo(x - 3, c.dy + r * .5 - h * .6, x, c.dy + r * .5 - h)
            ..quadraticBezierTo(x + 3, c.dy + r * .5 - h * .6, x + 5, c.dy + r * .5)
            ..close(),
          Paint()
            ..color = Color.lerp(
              const Color(0xFFFFD166),
              const Color(0xFFFF4D00),
              q,
            )!.withValues(alpha: .85 * (.4 + .6 * heat)),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ZonePainter old) => old.heat != heat || old.time != time;
}
