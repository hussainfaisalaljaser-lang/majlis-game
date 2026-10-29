import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/room.dart';
import '../../models/shop.dart';
import '../../services/sounds.dart';
import '../../theme.dart';
import '../common.dart';
import '../death_fx.dart';
import '../design.dart';
import '../design_game.dart';
import '../fx.dart';
import '../majlis.dart';
import '../ui.dart';
import 'game_table.dart';
import 'policy_card.dart';
import 'table_art.dart';

/// المشاهد اللي تطلع فوق الطاولة بعد الأحداث: كشف التصويت، الختم، الطرد، وكشف الأقنعة بالنهاية.
/// كل مشهد يرسم نفسه حسب الوقت من بدايته، ويعرف وين كل لاعب قاعد (نفس حساب الطاولة، على [Stage]).

/// هزة الشاشة من المشاهد (القرار الأحمر): ٠ ثابت، ١ أقوى هزة. الطاولة تسمعها وتهتز معها.
final sceneShake = ValueNotifier<double>(0);

/// مؤثر صوتي يشتغل لما يوصل المشهد [at] ثانية من بدايته (الأسماء في assets/sfx، انظر Sounds).
class SceneCue {
  const SceneCue(this.at, this.sound, [this.volume = 1]);

  final double at;
  final String sound;
  final double volume;
}

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

  /// أصوات المشهد بترتيب أوقاتها.
  List<SceneCue> get cues => const [];

  /// تعتيم الأطراف (٠–١) بلون [vignetteColor]: يشد الأعصاب قبل اللحظة الكبيرة.
  double vignetteAt(double t) => 0;
  Color get vignetteColor => const Color(0xFF000000);

  /// وميض يغطي الشاشة (٠–١) بلون [flashColor] لحظة الضربة.
  double flashAt(double t) => 0;
  Color get flashColor => const Color(0xFFFFFFFF);

  /// [size] مقاس المشهد (نفس الطاولة: المسرح ١٦:٩ يتوسطه).
  Widget build(BuildContext context, double t, Size size);
}

/// يشغّل مشهد فوق الطاولة ويخلّصه لحاله بعد مدته، أو بضغطة.
class SceneOverlay extends StatefulWidget {
  const SceneOverlay({super.key, required this.scene, required this.onDone, this.freezeAt});

  final GameScene scene;
  final VoidCallback onDone;

  /// للتصوير: يوقف المشهد على هاللحظة (ثواني من بدايته) بدون صوت ولا حركة.
  final double? freezeAt;

  @override
  State<SceneOverlay> createState() => _SceneOverlayState();
}

class _SceneOverlayState extends State<SceneOverlay> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.scene.duration)..addListener(_tick);
  late final _cues = [...widget.scene.cues]..sort((a, b) => a.at.compareTo(b.at));
  int _cue = 0;
  bool _finished = false;

  double get _seconds => _c.value * widget.scene.duration.inMicroseconds / 1e6;

  @override
  void initState() {
    super.initState();
    if (widget.freezeAt case final at?) {
      _c.value = (at * 1e6 / widget.scene.duration.inMicroseconds).clamp(0.0, 1.0);
    } else {
      _c.forward().then((_) => _done());
    }
  }

  void _tick() {
    if (widget.freezeAt != null) return;
    final s = _seconds;
    sceneShake.value = FxClock.lite.value ? 0 : widget.scene.shakeAt(s);
    // الأصوات تشتغل بوقتها (حتى لو الشاشة بالوضع الخفيف)
    while (_cue < _cues.length && _cues[_cue].at <= s) {
      final cue = _cues[_cue++];
      Sounds.play(cue.sound, volume: cue.volume);
    }
  }

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
          return Opacity(
            opacity: fade,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: SceneFrame(scene: widget.scene, seconds: s),
                ),
                Positioned(
                  top: 6,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Text(
                      'اضغط بأي مكان عشان تكمل',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted.withValues(alpha: .8),
                        fontSize: 11.5,
                        shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
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

/// طبقات المشهد عند لحظة [seconds] من بدايته: تعتيم الطاولة، تعتيم الأطراف، المشهد نفسه، والوميض.
/// (مفصولة عشان اللقطات تصور أي لحظة بدون ما تشغّل المشهد.)
class SceneFrame extends StatelessWidget {
  const SceneFrame({super.key, required this.scene, required this.seconds});

  final GameScene scene;
  final double seconds;

  @override
  Widget build(BuildContext context) {
    final lite = FxClock.lite.value;
    final t = lite ? scene.settle : seconds;
    final vignette = lite ? 0.0 : scene.vignetteAt(seconds).clamp(0.0, 1.0);
    final flash = lite ? 0.0 : scene.flashAt(seconds).clamp(0.0, 1.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: scene.dim)),
        ),
        if (vignette > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: .95,
                    colors: [
                      scene.vignetteColor.withValues(alpha: 0),
                      scene.vignetteColor.withValues(alpha: vignette),
                    ],
                    stops: const [.45, 1],
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(child: LayoutBuilder(builder: (context, box) => scene.build(context, t, box.biggest))),
        if (flash > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: scene.flashColor.withValues(alpha: flash)),
            ),
          ),
      ],
    );
  }
}

// ───────── أدوات

Offset _bezier(Offset a, Offset c, Offset b, double t) => a * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + b * (t * t);

/// يحط الودجت ونصه على [c].
Widget _at(Offset c, double w, double h, Widget child) =>
    Positioned(left: c.dx - w / 2, top: c.dy - h / 2, width: w, height: h, child: child);

/// مكان كل لاعب والسجادة والبيضاوي بإحداثيات المشهد (المسرح).
({Map<String, Offset> seats, Rect rug, Size table, Stage stage}) _layout(GameView view, Size size) {
  return (seats: seatCenters(view, size), rug: rugRect(size), table: size, stage: Stage(size));
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

/// لوح الرسالة تحت الطاولة (نفس مكانه وشكله في الشاشة)، يطلع فيه نتيجة المشهد.
Widget _scenePlank(Stage st, String text, {Widget? icon, Color color = const Color(0xFFFFF6E6)}) {
  final s = st.s;
  final fs = gameFont(34, s, min: 13);
  final r = TablePos.plank;
  final w = math.max(r.width * s, math.min(996 * s - 8, 330.0));
  final h = math.max(r.height * s, fs * 1.4 + 14);
  final c = st.at(r.center.dx, r.center.dy);
  return Positioned(
    left: c.dx - w / 2,
    top: c.dy - h / 2,
    width: w,
    height: h,
    child: GamePlank(
      radius: math.max(10, 16 * s),
      padding: EdgeInsets.symmetric(horizontal: math.max(10, 18 * s), vertical: 2),
      child: Row(
        children: [
          if (icon != null) ...[icon, SizedBox(width: math.max(6, 10 * s))],
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: kufi,
                  fontWeight: FontWeight.w800,
                  fontSize: fs,
                  height: 1.3,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ───────── كشف التصويت

/// كشف التصويت: كرت بنفسجي مقلوب جنب كل لاعب صوّت، يرجف مع دق الطبول، وبعدها كلهم ينقلبون مرة وحدة
/// على ورقة «موافق» أو «رافض» (مثل التصميم)، ولوح النتيجة تحت.
class VoteScene extends GameScene {
  const VoteScene({
    required this.view,
    required this.votes,
    required this.passed,
    this.cancelledBy,
    this.weights = const {},
  });

  final GameView view;
  final Map<String, bool> votes;
  final bool passed;

  /// القاضي اللي ألغى التصويت.
  final String? cancelledBy;

  /// أصوات تنحسب بأكثر من واحد (الشيخ: ٢).
  final Map<String, int> weights;

  @override
  Duration get duration => const Duration(milliseconds: 3600);

  @override
  double get settle => 3.0;

  /// التصميم ما يعتّم الطاولة وقت الكشف.
  @override
  double get dim => 0;

  /// دقات الطبل: العصيان تسرع من ٤ لـ١٤ ضربة بالثانية بين ٠٫٢ و١٫٥ (نفس سرعة رسمة الطبل)، فنحسب وقت كل ضربة.
  static final _drumHits = [
    for (var k = 1; k <= 11; k++) .2 + (-4 + math.sqrt(16 + 4 * (10 / 2.6) * k)) / (2 * (10 / 2.6)),
  ];

  @override
  List<SceneCue> get cues => [
    const SceneCue(.05, 'whoosh', .45),
    for (final (i, at) in _drumHits.indexed) SceneCue(at, i.isEven ? 'drum' : 'drum2', .35 + .5 * i / _drumHits.length),
    const SceneCue(1.55, 'flip', .8),
    SceneCue(1.95, cancelledBy == null && passed ? 'yes' : 'no', .9),
    const SceneCue(2.2, 'tick', .6),
  ];

  /// الأطراف تعتم وتشد مع الطبل، وتنفك لما ينقلبون.
  @override
  double vignetteAt(double t) => .5 * seg(t, .2, 1.5) * (1 - seg(t, 1.5, 1.75));

  /// ولعة وقت النتيجة: ذهبي لو مشت، أحمر لو سقطت.
  @override
  double flashAt(double t) => .3 * bump(t, 1.95, 2.4);

  @override
  Color get flashColor => cancelledBy == null && passed ? AppColors.goldLight : AppColors.traitor;

  @override
  Widget build(BuildContext context, double t, Size size) {
    final (:seats, :rug, :table, :stage) = _layout(view, size);
    final s = stage.s;
    final appear = seg(t, 0, .35, Curves.easeOutBack);
    final drum = seg(t, .2, .45) * (1 - seg(t, 1.5, 1.7));
    final roll = seg(t, .2, 1.5);
    final flip = seg(t, 1.55, 1.95, Curves.easeInOut);
    final pop = bump(t, 1.95, 2.25);
    int weight(String id) => weights[id] ?? 1;
    final yes = votes.entries.where((e) => e.value).fold(0, (n, e) => n + weight(e.key));
    final no = votes.entries.where((e) => !e.value).fold(0, (n, e) => n + weight(e.key));
    final judge = cancelledBy;
    final mid = size.width / 2;
    final cw = (96 * s).clamp(50.0, 110.0);
    final ch = cw * 1.28;
    final d = seatDiameter * s;
    final oval = stage.at(TablePos.oval.dx, TablePos.oval.dy);
    final k = (s * 1.6).clamp(.7, 1.4);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (drum > 0)
          _at(
            oval,
            130 * k,
            120 * k,
            Opacity(
              opacity: drum,
              child: Transform.scale(
                scale: k,
                child: CustomPaint(painter: _DrumPainter(t, roll)),
              ),
            ),
          ),
        for (final (i, MapEntry(key: id, value: ja)) in votes.entries.indexed)
          if (seats[id] case final c?)
            _at(
              // الكرت جنب الصورة من جهة نص الطاولة، والمقاعد التحت ترفعه عشان ما يغطي لوح الرسالة.
              c +
                  Offset(
                    (c.dx < mid - 1 ? 1 : -1) * (d / 2 + cw / 2 + 6 * s),
                    c.dy > stage.box.top + 700 * s && c.dy < stage.box.top + 900 * s ? -62 * s : 12 * s,
                  ),
              cw,
              ch,
              Transform.translate(
                offset: Offset(0, math.sin(t * 37 + i * 2) * 3 * roll * (1 - flip)),
                child: Transform.rotate(
                  angle: math.sin(t * 43 + i) * .1 * roll * (1 - flip),
                  child: Transform.scale(
                    scale: appear * (1 + .2 * pop),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        _Flip(
                          angle: (1 - flip) * math.pi,
                          front: id == judge
                              ? VoteBadgeCard(yes: false, width: cw, label: 'ألغى', icon: const Gfx('scales', size: 40))
                              : VoteBadgeCard(yes: ja, width: cw),
                          back: GameCardFace(kind: GameCardKind.discard, width: cw * .9),
                        ),
                        // الشيخ: صوته بصوتين (شارة فوق كرته).
                        if (weight(id) > 1 && flip > .5)
                          Positioned(
                            top: -15,
                            left: -16,
                            right: -16,
                            child: Center(
                              child: Transform.scale(
                                scale: Curves.elasticOut.transform(seg(t, 1.9, 2.4)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A1B0A),
                                    borderRadius: BorderRadius.circular(40),
                                    border: Border.all(color: AppColors.gold, width: 2),
                                  ),
                                  child: Text(
                                    weight(id) == 2 ? 'صوتين' : '×${arabicNumber(weight(id))}',
                                    style: const TextStyle(
                                      fontFamily: kufi,
                                      color: AppColors.goldLight,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        if (t > 2.2)
          Positioned.fill(
            child: Opacity(
              opacity: seg(t, 2.2, 2.45),
              child: Stack(
                children: [
                  _scenePlank(
                    stage,
                    judge != null
                        ? 'القاضي ${judge == view.you && !view.spectator ? '(أنت)' : view.player(judge).name} ألغى التصويت'
                        : '${passed ? 'مشت' : 'سقطت'} الحكومة: ${arabicNumber(yes)} موافق و${arabicNumber(no)} رافض',
                    icon: judge != null ? const Gfx('scales', size: 30) : null,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
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

/// تمرير القرار: الكرت يطير من الوزير (أو من الكومة وقت الفوضى) لنص البيضاوي، ينقلب، والختم ينزل
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
  double get dim => .3;

  @override
  double shakeAt(double t) => !loyal && t >= 1.3 ? 1 - seg(t, 1.3, 1.85) : 0;

  @override
  List<SceneCue> get cues => [
    const SceneCue(.1, 'whoosh', .55),
    const SceneCue(.75, 'flip', .8),
    // نزول الختم: الأوفياء ختم خفيف وبريق، والخونة ضربة تقيلة تهز الشاشة
    if (loyal) ...const [SceneCue(1.3, 'stamp', .8), SceneCue(1.36, 'sparkle', .5)] else ...[
      const SceneCue(1.3, 'thud_red'),
      if (chaos) const SceneCue(1.3, 'drum', .8),
    ],
  ];

  /// الأطراف تحمر بعد ضربة الخونة.
  @override
  double vignetteAt(double t) => loyal ? 0 : .55 * seg(t, 1.3, 1.45) * (1 - seg(t, 1.5, 2.4));

  @override
  Color get vignetteColor => AppColors.traitor;

  @override
  double flashAt(double t) => (loyal ? .22 : .38) * bump(t, 1.3, 1.6);

  @override
  Widget build(BuildContext context, double t, Size size) {
    final (:seats, :rug, :table, :stage) = _layout(view, size);
    final s = stage.s;
    final draw = stage.at(TablePos.draw.dx, TablePos.draw.dy);
    final start = seats[from] ?? draw;
    final cardW = (170 * s).clamp(66.0, 190.0);
    final cardH = cardW * 1.46;
    final end = stage.at(TablePos.oval.dx, TablePos.oval.dy);
    final fly = seg(t, .1, .75, Curves.easeOutCubic);
    final pos = _bezier(start, Offset((start.dx + end.dx) / 2, math.min(start.dy, end.dy) - 90 * s), end, fly);
    final flip = seg(t, .75, 1.0, Curves.easeInOut);
    final stamp = seg(t, 1.0, 1.3, Curves.easeInCubic);
    final squash = bump(t, 1.3, 1.5) * .07;
    final shake = shakeAt(t);
    final classic = skin == null || skin!.border == null;
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
                back: GameCardFace(
                  kind: GameCardKind.draw,
                  width: cardW,
                  colors: classic ? null : (skin!.border!, skin!.loyal.first, skin!.loyal.last),
                ),
              ),
            ),
          ),
        ),
        if (t > 1.4)
          Positioned.fill(
            child: Opacity(
              opacity: seg(t, 1.4, 1.7),
              child: Stack(
                children: [
                  _scenePlank(
                    stage,
                    chaos ? 'فوضى! تمرر تلقائياً' : 'مشى قرار ${loyal ? 'للأوفياء' : 'للخونة'}!',
                    icon: chaos ? const Gfx('chaos', size: 30) : const Gfx('log', size: 30),
                    color: loyal ? const Color(0xFFD6E6FF) : const Color(0xFFFFD3D0),
                  ),
                ],
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
  const DeathScene({required this.name, required this.avatar, required this.guarded, this.fx = DeathFx.cloth});

  final String name;
  final String avatar;
  final bool guarded;

  /// افكت موته من المتجر: غير الغطا الرمادي يلعب كبير بوسط المشهد مكان تكسر الصورة.
  final DeathFx fx;

  bool get _custom => !guarded && fx != DeathFx.cloth;

  /// الافكت يبدأ (deathFxStart) على ١٫٥ ثانية من المشهد، بعد الارتجاف والشقوق.
  static const _fxAt = 1.5;

  @override
  Duration get duration => const Duration(milliseconds: 3800);

  @override
  double get settle => guarded ? 2.6 : (_custom ? 3.4 : 3.2);

  @override
  double get dim => .62;

  /// صوت كل افكت.
  static String _fxSound(DeathFx fx) => switch (fx) {
    DeathFx.lightning => 'thunder',
    DeathFx.fire => 'fire',
    DeathFx.ice => 'ice',
    DeathFx.bats => 'wings',
    DeathFx.ghost => 'ghost',
    DeathFx.gold => 'gong',
    DeathFx.petals => 'airy',
    DeathFx.smoke || DeathFx.sand => 'puff',
    DeathFx.cloth => 'shatter',
  };

  @override
  List<SceneCue> get cues => [
    const SceneCue(.2, 'heartbeat', .8),
    const SceneCue(.85, 'heartbeat', .9),
    const SceneCue(.9, 'crack', .8),
    if (guarded)
      const SceneCue(1.2, 'shield')
    else ...[
      SceneCue(_custom ? _fxAt : 1.55, _fxSound(fx)),
      const SceneCue(1.6, 'lamp_out', .8),
    ],
  ];

  /// الأطراف تحمر (أو تخضر مع الحارس) وهو يرتجف، وتنفك لما ينكسر.
  @override
  double vignetteAt(double t) => .65 * seg(t, .2, 1.4) * (1 - seg(t, 1.5, 2.0));

  @override
  Color get vignetteColor => guarded ? AppColors.loyal : AppColors.traitor;

  @override
  double flashAt(double t) => guarded ? .25 * bump(t, 1.2, 1.5) : .35 * bump(t, 1.5, 1.85);

  @override
  Widget build(BuildContext context, double t, Size size) {
    final r = math.min(150.0, size.height * .38);
    final c = Offset(size.width / 2, size.height * .42);
    final shake = seg(t, .2, 1.0) * (1 - seg(t, guarded ? 1.2 : 1.5, guarded ? 1.3 : 1.6));
    final crack = guarded ? seg(t, .9, 1.2) * (1 - seg(t, 1.4, 1.8)) : seg(t, .9, 1.35, Curves.easeOut);
    final shatter = guarded || _custom ? 0.0 : seg(t, 1.55, 2.6, Curves.easeIn);
    // وقت الافكت (يبدأ على deathFxStart لما نوصل _fxAt)
    final fxT = t - (_fxAt - deathFxStart);
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
            if (_custom) _deathFxAvatar(fx, avatar, r * 1.2, fxT) else TableAvatar(avatar: avatar, size: r * 1.2),
            if (crack > 0)
              Opacity(
                opacity: _custom ? 1 - seg(t, _fxAt, _fxAt + .4) : 1,
                child: SizedBox(
                  width: r,
                  height: r,
                  child: ClipOval(child: CustomPaint(painter: _CracksPainter(crack))),
                ),
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
        if (t > (guarded ? 1.8 : (_custom ? 2.8 : 2.6)))
          Positioned(
            left: 0,
            right: 0,
            top: c.dy + r * .62,
            child: Opacity(
              opacity: seg(t, guarded ? 1.8 : (_custom ? 2.8 : 2.6), guarded ? 2.2 : (_custom ? 3.2 : 3.0)),
              child: Column(
                children: [
                  GoldText(guarded ? '$name نجا! طلع حارس' : '$name انطرد', size: 28),
                  if (!guarded)
                    const Text(
                      'لا يستطيع أن يلعب بعد الآن',
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

/// صورة المطرود بافكت موته (نفس اللي يبان بالطاولة): تحزن وتترمد، وبعدها المسند والافكت مكانها.
Widget _deathFxAvatar(DeathFx fx, String avatar, double size, double fxT) {
  final look = deathLook(fx, math.max(0, fxT));
  return SizedBox(
    width: size,
    height: size,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        if (!deathHidesAvatar(fx, fxT))
          Positioned.fill(
            child: Opacity(
              opacity: look.opacity.clamp(0.0, 1.0),
              child: look.matrix == null
                  ? TableAvatar(avatar: avatar, size: size)
                  : ColorFiltered(
                      colorFilter: ColorFilter.matrix(look.matrix!),
                      child: TableAvatar(avatar: avatar, size: size),
                    ),
            ),
          ),
        Positioned.fill(
          child: DeathLayer(fx: fx, t: fxT),
        ),
      ],
    ),
  );
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
    final img = TableAvatar(avatar: avatar, size: size * 1.2, animate: false);
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
  List<SceneCue> get cues {
    final loyalWon = view.winnerLoyal ?? false;
    return [
      const SceneCue(_loyalAt, 'whoosh', .5),
      for (final (i, _) in traitors.indexed) ...[
        SceneCue(_firstTraitor + i * _gap, 'mask_drop'),
        // الزعيم آخر واحد: ضربة تقيلة
        if (i == traitors.length - 1) SceneCue(_firstTraitor + i * _gap + .05, 'thud_red', .8),
      ],
      SceneCue(_winAt, loyalWon ? 'win' : 'sting_traitor'),
      SceneCue(_winAt + .2, 'sparkle', .6),
    ];
  }

  /// وميض أحمر خفيف مع كل قناع يطيح، وذهبي كبير لما يعلن الفايز.
  @override
  double flashAt(double t) {
    var f = .3 * bump(t, _winAt, _winAt + .5);
    for (var i = 0; i < traitors.length; i++) {
      f = math.max(f, .14 * bump(t, _firstTraitor + i * _gap, _firstTraitor + i * _gap + .35));
    }
    return f;
  }

  @override
  Color get flashColor => (view.winnerLoyal ?? false) ? AppColors.goldLight : AppColors.traitor;

  @override
  Widget build(BuildContext context, double t, Size size) {
    final loyalWon = view.winnerLoyal ?? false;
    final n = view.players.length;
    final rows = n > 6 ? 2 : 1;
    final perRow = (n / rows).ceil();
    final cell = math.min(118.0, (size.width - 40) / perRow);
    final av = math.min(84.0, cell * .72);
    final rowH = av + 70;
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
                  name: view.nameOf(p.id),
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
                  child: TableAvatar(avatar: avatar, size: size * 1.14, ring: shown ? color : null),
                ),
              ),
              Transform.translate(
                offset: traitor ? Offset(0, size * 1.9 * off * off) : Offset(0, -size * 1.05 * off),
                child: Transform.rotate(
                  angle: wobble + (traitor ? off * 1.3 : -off * .4),
                  child: Opacity(
                    opacity: (1 - off).clamp(0.0, 1.0),
                    child: TableAvatar(avatar: 'masked', size: size * 1.14, animate: false),
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
        const SizedBox(height: 10),
        NamePill(name, size: 14, color: shown ? light : const Color(0xFFFFF6E6)),
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
