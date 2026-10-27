import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/room.dart';
import '../../models/shop.dart';
import '../../theme.dart';
import '../common.dart';
import '../fx.dart';
import '../majlis.dart';
import '../ui.dart';
import 'game_table.dart';
import 'policy_card.dart';

/// المشاهد اللي تطلع فوق الطاولة بعد الأحداث: كشف التصويت، الختم، الطرد، وكشف الأقنعة بالنهاية.
/// كل مشهد يرسم نفسه حسب الوقت من بدايته، ويعرف وين كل لاعب قاعد (نفس حساب الطاولة).

/// هزة الشاشة من المشاهد (القرار الأحمر): ٠ ثابت، ١ أقوى هزة. الطاولة تسمعها وتهتز معها.
final sceneShake = ValueNotifier<double>(0);

abstract class GameScene {
  const GameScene();

  /// مدة المشهد: أقل من وقته في السيرفر (functions/src/pacing.ts → SCENE_MS)، عشان ما ياكل من وقت الدور.
  Duration get duration;

  /// تعتيم الطاولة تحت المشهد.
  double get dim => .5;

  /// الوضع الخفيف: المشهد يثبت على هاللحظة (اللي يبان فيها كل شي) بدال الحركة.
  double get settle;

  /// قد إيش الشاشة تهتز بهاللحظة.
  double shakeAt(double t) => 0;

  /// [size] مقاس المشهد (نفس الطاولة مع حوافها: [tablePadding]).
  Widget build(BuildContext context, double t, Size size);
}

/// يشغّل مشهد فوق الطاولة ويخلّصه لحاله بعد مدته، أو بضغطة.
class SceneOverlay extends StatefulWidget {
  const SceneOverlay({super.key, required this.scene, required this.onDone});

  final GameScene scene;
  final VoidCallback onDone;

  @override
  State<SceneOverlay> createState() => _SceneOverlayState();
}

class _SceneOverlayState extends State<SceneOverlay> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.scene.duration)
    ..addListener(_shake)
    ..forward().then((_) => _done());
  bool _finished = false;

  double get _seconds => _c.value * widget.scene.duration.inMicroseconds / 1e6;

  void _shake() => sceneShake.value = FxClock.lite.value ? 0 : widget.scene.shakeAt(_seconds);

  void _done() {
    if (_finished) return;
    _finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    sceneShake.value = 0;
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.scene.duration.inMicroseconds / 1e6;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _done,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final s = _seconds;
          final fade = (s / .2).clamp(0.0, 1.0) * ((total - s) / .3).clamp(0.0, 1.0);
          final t = FxClock.lite.value ? widget.scene.settle : s;
          return Opacity(
            opacity: fade,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ColoredBox(color: Colors.black.withValues(alpha: widget.scene.dim)),
                ),
                Positioned.fill(
                  child: LayoutBuilder(builder: (context, box) => widget.scene.build(context, t, box.biggest)),
                ),
                const Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Text(
                    'اضغط بأي مكان عشان تكمل',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ───────── أدوات

Offset _bezier(Offset a, Offset c, Offset b, double t) => a * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + b * (t * t);

/// يحط الودجت ونصه على [c].
Widget _at(Offset c, double w, double h, Widget child) =>
    Positioned(left: c.dx - w / 2, top: c.dy - h / 2, width: w, height: h, child: child);

/// مكان كل لاعب ومكان السجادة بإحداثيات المشهد.
({Map<String, Offset> seats, Rect rug, Size table}) _layout(GameView view, Size size) {
  final table = Size(size.width - tablePadding.horizontal, size.height - tablePadding.vertical);
  final o = Offset(tablePadding.left, tablePadding.top);
  return (
    seats: {for (final MapEntry(:key, :value) in seatCenters(view, table).entries) key: value + o},
    rug: rugRect(table).shift(o),
    table: table,
  );
}

/// كرت ينقلب: [angle] صفر يبين الوجه، وπ يبين الظهر.
class _Flip extends StatelessWidget {
  const _Flip({required this.angle, required this.front, required this.back});

  final double angle;
  final Widget front, back;

  @override
  Widget build(BuildContext context) {
    final a = angle % (2 * math.pi);
    final face = a < math.pi / 2 || a > 3 * math.pi / 2;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, .0015)
        ..rotateY(angle),
      child: face ? front : Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: back),
    );
  }
}

/// ظهر الكرت (نفس الكومة على الطاولة).
class _Back extends StatelessWidget {
  const _Back({required this.width, required this.height});

  final double width, height;

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
      border: Border.all(color: AppColors.gold, width: 2),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 5))],
    ),
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * .08),
        border: Border.all(color: AppColors.gold.withValues(alpha: .5)),
      ),
      child: CustomPaint(size: Size.square(width * .42), painter: _StarPainter()),
    ),
  );
}

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

/// لوحة نتيجة داكنة بحافة ملونة.
class _Plate extends StatelessWidget {
  const _Plate({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xF00B0818),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color, width: 2),
      boxShadow: [BoxShadow(color: color.withValues(alpha: .45), blurRadius: 24)],
    ),
    child: child,
  );
}

// ───────── كشف التصويت

/// كشف التصويت: كرت مقلوب جنب كل لاعب صوّت، يرجف مع دق الطبول، وبعدها كلهم ينقلبون مرة وحدة.
class VoteScene extends GameScene {
  const VoteScene({required this.view, required this.votes, required this.passed});

  final GameView view;
  final Map<String, bool> votes;
  final bool passed;

  @override
  Duration get duration => const Duration(milliseconds: 3600);

  @override
  double get settle => 3.0;

  @override
  double get dim => .3;

  @override
  Widget build(BuildContext context, double t, Size size) {
    final (:seats, :rug, :table) = _layout(view, size);
    final appear = seg(t, 0, .35, Curves.easeOutBack);
    final drum = seg(t, .2, .45) * (1 - seg(t, 1.5, 1.7));
    final roll = seg(t, .2, 1.5);
    final flip = seg(t, 1.55, 1.95, Curves.easeInOut);
    final pop = bump(t, 1.95, 2.25);
    final yes = votes.values.where((v) => v).length;
    final mid = size.width / 2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (drum > 0)
          _at(
            rug.center,
            130,
            120,
            Opacity(
              opacity: drum,
              child: CustomPaint(painter: _DrumPainter(t, roll)),
            ),
          ),
        for (final (i, MapEntry(key: id, value: ja)) in votes.entries.indexed)
          if (seats[id] case final c?)
            _at(
              c + Offset(c.dx <= mid + 1 ? 52 : -52, -2),
              42,
              58,
              Transform.translate(
                offset: Offset(0, math.sin(t * 37 + i * 2) * 3 * roll * (1 - flip)),
                child: Transform.rotate(
                  angle: math.sin(t * 43 + i) * .1 * roll * (1 - flip),
                  child: Transform.scale(
                    scale: appear * (1 + .2 * pop),
                    child: _Flip(angle: (1 - flip) * math.pi, front: _VoteFace(ja), back: const _VoteBack()),
                  ),
                ),
              ),
            ),
        if (t > 2.2)
          _at(
            rug.center,
            320,
            60,
            Center(
              child: Opacity(
                opacity: seg(t, 2.2, 2.45),
                child: Transform.scale(
                  scale: seg(t, 2.2, 2.55, Curves.easeOutBack),
                  child: _Plate(
                    color: passed ? AppColors.green : AppColors.traitor,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Gfx(passed ? 'check' : 'cross', size: 28),
                        const SizedBox(width: 8),
                        Text(
                          passed ? 'الحكومة انتخبت' : 'الحكومة انرفضت',
                          style: TextStyle(
                            fontFamily: kufi,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: passed ? AppColors.green : AppColors.traitorLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${arabicNumber(yes)} – ${arabicNumber(votes.length - yes)}',
                          style: const TextStyle(fontFamily: kufi, fontSize: 21, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VoteFace extends StatelessWidget {
  const _VoteFace(this.yes);

  final bool yes;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 58,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: yes ? const [Color(0xFF6DE3A0), Color(0xFF1E8E52)] : const [Color(0xFFFF8C98), Color(0xFFA3172D)],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: .85), width: 2),
      boxShadow: [BoxShadow(color: (yes ? AppColors.green : AppColors.traitor).withValues(alpha: .7), blurRadius: 12)],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Gfx(yes ? 'check' : 'cross', size: 22),
        Text(
          yes ? 'نعم' : 'لا',
          style: TextStyle(
            fontFamily: kufi,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            height: 1.3,
            color: yes ? const Color(0xFF062814) : Colors.white,
          ),
        ),
      ],
    ),
  );
}

class _VoteBack extends StatelessWidget {
  const _VoteBack();

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 58,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      gradient: const LinearGradient(colors: [Color(0xFF4A2775), Color(0xFF1A0F33)]),
      border: Border.all(color: AppColors.gold, width: 2),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3))],
    ),
    child: const Text(
      '؟',
      style: TextStyle(fontFamily: kufi, fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.goldLight),
    ),
  );
}

/// طبل وعصيه تضرب بالتناوب، وتسرع مع [roll].
class _DrumPainter extends CustomPainter {
  _DrumPainter(this.t, this.roll);

  final double t, roll;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 + 14);
    final speed = 4 + roll * 10;
    for (var k = 0; k < 3; k++) {
      final q = (t * speed / 4 + k / 3) % 1;
      canvas.drawCircle(
        c + const Offset(0, -10),
        30 + q * 34,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 * (1 - q)
          ..color = AppColors.goldLight.withValues(alpha: .6 * (1 - q)),
      );
    }
    final body = Rect.fromCenter(center: c + const Offset(0, 8), width: 66, height: 34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF7F1D1D), Color(0xFFDC2626), Color(0xFF7F1D1D)])
            .createShader(body),
    );
    final rope = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 2;
    for (var k = 0; k < 4; k++) {
      final x = body.left + 5 + k * 14.5;
      canvas.drawLine(Offset(x, body.top + 2), Offset(x + 7, body.bottom - 2), rope);
      canvas.drawLine(Offset(x + 7, body.bottom - 2), Offset(x + 14, body.top + 2), rope);
    }
    final top = Rect.fromCenter(center: c + const Offset(0, -9), width: 66, height: 16);
    canvas.drawOval(top, Paint()..color = const Color(0xFFF6E7C8));
    canvas.drawOval(
      top,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.goldDark,
    );
    final hit = math.sin(t * speed * math.pi);
    for (final (side, lift) in [(-1.0, hit), (1.0, -hit)]) {
      final tip = c + Offset(side * 14, -12 - 16 * math.max(0, lift));
      canvas.drawLine(
        tip,
        tip + Offset(side * 30, -26),
        Paint()
          ..color = const Color(0xFF8A5A00)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(tip, 4.5, Paint()..color = const Color(0xFFFFF2C2));
    }
  }

  @override
  bool shouldRepaint(_DrumPainter old) => true;
}

// ───────── تمرير القرار

/// تمرير القرار: الكرت يطير من الوزير (أو من الكومة وقت الفوضى) لنص الطاولة، ينقلب، والختم ينزل
/// عليه مع شرار. الأحمر يهز الشاشة.
class EnactScene extends GameScene {
  const EnactScene({required this.view, required this.loyal, required this.chaos, this.from, this.skin});

  final GameView view;
  final bool loyal;
  final bool chaos;

  /// الوزير اللي مرّره.
  final String? from;
  final CardSkin? skin;

  @override
  Duration get duration => const Duration(milliseconds: 3200);

  @override
  double get settle => 2.4;

  @override
  double get dim => .45;

  @override
  double shakeAt(double t) => !loyal && t >= 1.3 ? 1 - seg(t, 1.3, 1.85) : 0;

  @override
  Widget build(BuildContext context, double t, Size size) {
    final (:seats, :rug, :table) = _layout(view, size);
    final start = seats[from] ?? Offset(rug.right - rug.width * .14, rug.center.dy);
    final cardW = (rug.height * .42).clamp(72.0, 112.0);
    final cardH = cardW * 1.45;
    final end = Offset(rug.center.dx, math.max(cardH / 2 + 8, rug.center.dy - cardH * .12));
    final fly = seg(t, .1, .75, Curves.easeOutCubic);
    final pos = _bezier(start, Offset((start.dx + end.dx) / 2, math.min(start.dy, end.dy) - 90), end, fly);
    final flip = seg(t, .75, 1.0, Curves.easeInOut);
    final stamp = seg(t, 1.0, 1.3, Curves.easeInCubic);
    final squash = bump(t, 1.3, 1.5) * .07;
    final shake = shakeAt(t);
    final color = loyal ? AppColors.loyalLight : AppColors.traitorLight;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (t > 1.3 && t < 2.1)
          Positioned.fill(child: CustomPaint(painter: _BurstPainter(end, seg(t, 1.3, 2.1), !loyal))),
        _at(
          pos,
          cardW,
          cardH,
          Transform.rotate(
            angle: (1 - fly) * -.7,
            child: Transform.scale(
              scaleX: .3 + .7 * fly + squash,
              scaleY: .3 + .7 * fly - squash,
              child: _Flip(
                angle: (1 - flip) * math.pi,
                front: PolicyCard(
                  policy: loyal ? Policy.loyal : Policy.traitor,
                  skin: skin,
                  width: cardW,
                  stamp: stamp,
                ),
                back: _Back(width: cardW, height: cardH),
              ),
            ),
          ),
        ),
        if (t > 1.4)
          Positioned(
            left: 0,
            right: 0,
            top: end.dy + cardH / 2 + 10,
            child: Center(
              child: Opacity(
                opacity: seg(t, 1.4, 1.7),
                child: _Plate(
                  color: loyal ? AppColors.loyal : AppColors.traitor,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (chaos) ...[const Gfx('chaos', size: 28), const SizedBox(width: 6)],
                      Text(
                        chaos ? 'فوضى! تمرر تلقائياً' : 'تمرر قرار ${loyal ? 'للأوفياء' : 'للخونة'}',
                        style: TextStyle(fontFamily: kufi, fontSize: 21, fontWeight: FontWeight.w700, color: color),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (shake > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: const Color(0xFFDC2626).withValues(alpha: .26 * shake)),
            ),
          ),
      ],
    );
  }
}

/// ضربة الختم: حلقة تتوسع وشرار يتطاير.
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.c, this.p, this.red);

  final Offset c;
  final double p;
  final bool red;

  @override
  void paint(Canvas canvas, Size size) {
    final e = Curves.easeOutCubic.transform(p);
    final base = red ? const Color(0xFFFF4D4D) : AppColors.gold;
    canvas.drawCircle(
      c,
      40 + 170 * e,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 * (1 - p)
        ..color = base.withValues(alpha: (1 - p) * .9),
    );
    canvas.drawCircle(
      c,
      20 + 60 * (1 - p),
      Paint()
        ..color = Colors.white.withValues(alpha: .5 * (1 - p) * (1 - p))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    const sparks = [Color(0xFFFFF3C4), Color(0xFFFFC94D), Color(0xFFFF8A1F)];
    for (var k = 0; k < 28; k++) {
      final a = k / 28 * 2 * math.pi + rnd(k, 1) * .4;
      final v = 110 + rnd(k, 2) * 170;
      final pos = c + Offset(math.cos(a), math.sin(a)) * (v * e) + Offset(0, 90 * p * p);
      final col = red && k.isEven ? const Color(0xFFFF5A5A) : sparks[k % 3];
      canvas.drawCircle(pos, 1.5 + 3.5 * (1 - p), Paint()..color = col.withValues(alpha: 1 - p));
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => true;
}

// ───────── الطرد

/// الطرد: الصورة ترجف وتتشقق وتتكسر قطع، وفانوسه ينطفي ويطلع منه دخان. الحارس: درع يحميه والشقوق تختفي.
class DeathScene extends GameScene {
  const DeathScene({required this.name, required this.avatar, required this.guarded});

  final String name;
  final String avatar;
  final bool guarded;

  @override
  Duration get duration => const Duration(milliseconds: 3800);

  @override
  double get settle => guarded ? 2.6 : 3.2;

  @override
  double get dim => .62;

  @override
  Widget build(BuildContext context, double t, Size size) {
    final r = math.min(150.0, size.height * .38);
    final c = Offset(size.width / 2, size.height * .42);
    final shake = seg(t, .2, 1.0) * (1 - seg(t, guarded ? 1.2 : 1.5, guarded ? 1.3 : 1.6));
    final crack = guarded ? seg(t, .9, 1.2) * (1 - seg(t, 1.4, 1.8)) : seg(t, .9, 1.35, Curves.easeOut);
    final shatter = guarded ? 0.0 : seg(t, 1.55, 2.6, Curves.easeIn);
    final shield = guarded ? seg(t, 1.2, 1.5, Curves.easeOutBack) : 0.0;
    final out = guarded ? 0.0 : seg(t, 1.6, 2.1);
    final lampOn = out == 0 ? 1.0 : (1 - out) * (.5 + .5 * math.sin(t * 50).abs());
    final glow = guarded ? AppColors.loyal : AppColors.traitor;
    final lamp = c + Offset(r * .85, r * .25);
    final figure = Transform.translate(
      offset: Offset(math.sin(t * 61) * 4, math.cos(t * 47) * 2) * shake,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: r + 10,
            height: r + 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: .65 * math.max(shake, shield)),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          if (shatter == 0) ...[
            PlayerAvatar(avatar: avatar, size: r),
            if (crack > 0)
              SizedBox(
                width: r,
                height: r,
                child: ClipOval(child: CustomPaint(painter: _CracksPainter(crack))),
              ),
          ] else
            _Shatter(avatar: avatar, size: r, p: shatter),
          if (!guarded && t > 1.55 && t < 1.85)
            Container(
              width: r,
              height: r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .8 * (1 - seg(t, 1.55, 1.85))),
              ),
            ),
          if (shield > 0)
            Transform.scale(
              scale: shield,
              child: Container(
                width: r * 1.25,
                height: r * 1.25,
                alignment: Alignment.bottomRight,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.loyal.withValues(alpha: .18),
                  border: Border.all(color: AppColors.loyalLight.withValues(alpha: .9), width: 3),
                ),
                child: Gfx('shield', size: r * .42),
              ),
            ),
        ],
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _at(c, r * 1.6, r * 1.6, figure),
        if (!guarded) ...[
          _at(lamp, r * .3, r * .3 * 1.9, FloorLantern(on: lampOn, width: r * .3, seed: 3, flicker: true)),
          if (t > 2.0)
            Positioned.fill(child: CustomPaint(painter: _SmokePainter(lamp - Offset(0, r * .2), seg(t, 2.0, 3.8)))),
        ],
        if (t > (guarded ? 1.8 : 2.6))
          Positioned(
            left: 0,
            right: 0,
            top: c.dy + r * .62,
            child: Opacity(
              opacity: seg(t, guarded ? 1.8 : 2.6, guarded ? 2.2 : 3.0),
              child: Column(
                children: [
                  GoldText(guarded ? '$name نجا! طلع حارس' : '$name انطرد', size: 28),
                  if (!guarded)
                    const Text(
                      'ما يقدر يلعب بعد الحين',
                      style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// شقوق تمشي من نقطة الضربة لأطراف الصورة.
class _CracksPainter extends CustomPainter {
  _CracksPainter(this.p);

  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w * .43, w * .4);
    final dark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w / 44
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withValues(alpha: .6 * math.min(1, p * 3));
    final light = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w / 107
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .95 * math.min(1, p * 3));
    for (var k = 0; k < 8; k++) {
      final base = k / 8 * 2 * math.pi + rnd(k, 8) * .5;
      final path = Path()..moveTo(c.dx, c.dy);
      const parts = 5;
      final reach = (p * parts).clamp(0.0, parts.toDouble());
      var prev = c;
      for (var j = 1; j <= reach.ceil(); j++) {
        final a = base + (rnd(k * 7 + j, 9) - .5) * .7;
        final next = c + Offset(math.cos(a), math.sin(a)) * (j / parts * w * .62);
        final pt = j <= reach ? next : Offset.lerp(prev, next, reach - (j - 1))!;
        path.lineTo(pt.dx, pt.dy);
        prev = next;
      }
      canvas.drawPath(path, dark);
      canvas.drawPath(path, light);
    }
  }

  @override
  bool shouldRepaint(_CracksPainter old) => old.p != p;
}

/// الصورة تتكسر قطع تطيح وتختفي.
class _Shatter extends StatelessWidget {
  const _Shatter({required this.avatar, required this.size, required this.p});

  final String avatar;
  final double size, p;

  static const n = 9;

  double _angle(int j) => j / n * 2 * math.pi + rnd(j % n, 5) * .35;

  @override
  Widget build(BuildContext context) {
    final img = PlayerAvatar(avatar: avatar, size: size, animate: false);
    final c = Offset(size * .43, size * .4);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: [for (var k = 0; k < n; k++) _shard(k, img, c)]),
    );
  }

  Widget _shard(int k, Widget img, Offset c) {
    final a0 = _angle(k), a1 = _angle(k + 1), mid = (a0 + a1) / 2, r = size * 1.3;
    Offset rim(double a) => c + Offset(math.cos(a), math.sin(a)) * r;
    final path = Path()
      ..moveTo(c.dx, c.dy)
      ..lineTo(rim(a0).dx, rim(a0).dy)
      ..lineTo(rim(mid).dx, rim(mid).dy)
      ..lineTo(rim(a1).dx, rim(a1).dy)
      ..close();
    final dir = Offset(math.cos(mid), math.sin(mid));
    final s = size / 150;
    return Positioned.fill(
      child: Transform.translate(
        offset: dir * (p * (30 + rnd(k, 6) * 60) * s) + Offset(0, p * p * 170 * s),
        child: Transform.rotate(
          angle: p * (rnd(k, 7) - .5) * 2.6,
          child: Opacity(
            opacity: (1 - p * p).clamp(0.0, 1.0),
            child: ClipPath(clipper: _PathClip(path), child: img),
          ),
        ),
      ),
    );
  }
}

class _PathClip extends CustomClipper<Path> {
  _PathClip(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClip old) => true;
}

/// دخان يطلع من [from] بعد ما ينطفي الفانوس.
class _SmokePainter extends CustomPainter {
  _SmokePainter(this.from, this.p);

  final Offset from;
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    for (var j = 0; j < 6; j++) {
      final q = (p * 1.4 - j * .1).clamp(0.0, 1.0);
      if (q <= 0 || q >= 1) continue;
      canvas.drawCircle(
        from + Offset(math.sin(q * 5 + j) * 9, -q * 95),
        5 + q * 18,
        Paint()
          ..color = const Color(0xFFB8B8C8).withValues(alpha: .38 * (1 - q))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(_SmokePainter old) => true;
}

// ───────── نهاية اللعبة

/// كشف الأقنعة: كل اللاعبين بأقنعة، قناع الأوفياء يرتفع مع بعض، وأقنعة الخونة تطيح وحدة وحدة
/// (الزعيم آخر واحد) مع ختمهم. بعدها الفريق الفايز يفرح وورق ملون يطيح عليه.
class UnmaskScene extends GameScene {
  UnmaskScene({required this.view, required this.room})
    : traitors = [
        for (final p in view.players)
          if (p.knownRole == Role.traitor) p.id,
        for (final p in view.players)
          if (p.knownRole == Role.leader) p.id,
      ];

  final GameView view;
  final Room? room;

  /// ترتيب كشف الخونة (الزعيم آخر).
  final List<String> traitors;

  static const _loyalAt = .8, _firstTraitor = 1.7, _gap = 1.1;

  double get _winAt => _firstTraitor + traitors.length * _gap + .3;

  @override
  Duration get duration => Duration(milliseconds: ((_winAt + 2.8) * 1000).round());

  @override
  double get settle => _winAt + 1.2;

  @override
  double get dim => .84;

  @override
  Widget build(BuildContext context, double t, Size size) {
    final loyalWon = view.winnerLoyal ?? false;
    final n = view.players.length;
    final rows = n > 6 ? 2 : 1;
    final perRow = (n / rows).ceil();
    final cell = math.min(118.0, (size.width - 40) / perRow);
    final av = math.min(84.0, cell * .72);
    final rowH = av + 62;
    final top = size.height / 2 - rows * rowH / 2 + (rows == 1 ? 20 : 34);
    final win = seg(t, _winAt, _winAt + .6, Curves.easeOutBack);
    final players = [...view.players]..sort((a, b) => a.seat.compareTo(b.seat));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final (i, p) in players.indexed)
          Builder(
            builder: (context) {
              final row = i ~/ perRow;
              final inRow = row == rows - 1 ? n - perRow * row : perRow;
              final col = i % perRow;
              final x = size.width / 2 + (col - (inRow - 1) / 2) * cell;
              final y = top + row * rowH;
              final traitor = p.knownRole != Role.loyal;
              final at = traitor ? _firstTraitor + traitors.indexOf(p.id) * _gap : _loyalAt;
              final winner = (p.knownRole == Role.loyal) == loyalWon;
              return _at(
                Offset(x, y + rowH / 2),
                cell,
                rowH,
                _Unmask(
                  name: p.id == view.you ? 'أنت' : p.name,
                  avatar: room?.player(p.id)?.avatar ?? 'masked',
                  role: p.knownRole ?? Role.loyal,
                  size: av,
                  t: t,
                  at: at,
                  hop: winner && t > _winAt ? -math.sin((t - _winAt) * 7 + i).abs() * 12 : 0,
                  lost: winner ? 0 : seg(t, _winAt, _winAt + .6),
                ),
              );
            },
          ),
        if (t > _winAt)
          Positioned(
            left: 0,
            right: 0,
            top: math.max(30, top - 70),
            child: Transform.scale(scale: win, child: GoldText(loyalWon ? 'فاز الأوفياء!' : 'فاز الخونة!', size: 38)),
          ),
        if (t > _winAt)
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _ConfettiPainter(t - _winAt))),
          ),
      ],
    );
  }
}

class _Unmask extends StatelessWidget {
  const _Unmask({
    required this.name,
    required this.avatar,
    required this.role,
    required this.size,
    required this.t,
    required this.at,
    required this.hop,
    required this.lost,
  });

  final String name;
  final String avatar;
  final Role role;
  final double size, t;

  /// متى يطيح قناعه.
  final double at;
  final double hop, lost;

  @override
  Widget build(BuildContext context) {
    final traitor = role != Role.loyal;
    final wobble = traitor && t > at && t < at + .35 ? math.sin(t * 40) * .14 : 0.0;
    final off = seg(t, traitor ? at + .35 : at, traitor ? at + 1.0 : at + .6, Curves.easeIn);
    final shown = off > .3;
    final color = traitor ? AppColors.traitor : AppColors.loyal;
    final light = traitor ? AppColors.traitorLight : AppColors.loyalLight;
    final flash = traitor ? bump(t, at + .35, at + .95) : 0.0;
    final stamp = traitor ? seg(t, at + .55, at + .85, Curves.easeInCubic) : 0.0;
    return Column(
      children: [
        SizedBox(
          width: size + 16,
          height: size + 16,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (flash > 0)
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.traitor.withValues(alpha: .85 * flash),
                        blurRadius: 34,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                ),
              Transform.translate(
                offset: Offset(0, hop),
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(greyMatrix(.6 * lost)),
                  child: PlayerAvatar(avatar: avatar, size: size, frame: shown ? color : null),
                ),
              ),
              Transform.translate(
                offset: traitor ? Offset(0, size * 1.9 * off * off) : Offset(0, -size * 1.05 * off),
                child: Transform.rotate(
                  angle: wobble + (traitor ? off * 1.3 : -off * .4),
                  child: Opacity(
                    opacity: (1 - off).clamp(0.0, 1.0),
                    child: PlayerAvatar(avatar: 'masked', size: size, animate: false),
                  ),
                ),
              ),
              if (stamp > 0)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: stamp,
                    child: Transform.scale(
                      scale: 1 + (1 - stamp) * 2,
                      child: role == Role.leader ? LeaderSeal(size: size * .55) : Seal(loyal: false, size: size * .48),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: shown ? light : AppColors.text),
        ),
        Opacity(
          opacity: seg(off, .3, 1),
          child: Text(switch (role) {
            Role.loyal => 'وفي',
            Role.traitor => 'خائن',
            Role.leader => 'الزعيم',
          }, style: TextStyle(fontFamily: kufi, fontSize: 13, fontWeight: FontWeight.w700, color: light)),
        ),
      ],
    );
  }
}

/// ورق ملون يطيح من فوق.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);

  final double t;

  static const _colors = [
    Color(0xFFFFD166),
    Color(0xFF06D6A0),
    Color(0xFFEF476F),
    Color(0xFF4CC9F0),
    Color(0xFFF2C14E),
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var k = 0; k < 80; k++) {
      final life = t - rnd(k, 1) * .8;
      if (life < 0) continue;
      final y = -20 + life * (size.height * .3 + rnd(k, 3) * size.height * .3);
      if (y > size.height + 20) continue;
      final x = rnd(k, 2) * size.width + math.sin(life * 3 + k) * 18;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(life * (3 + rnd(k, 4) * 5) + k);
      canvas.scale(1, .25 + .75 * math.cos(life * 6 + k).abs());
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 11),
        Paint()..color = _colors[k % _colors.length],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
