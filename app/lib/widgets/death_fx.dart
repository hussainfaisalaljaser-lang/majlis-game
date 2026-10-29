import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/shop.dart';
import 'design_death.dart';
import 'fx.dart';

// افكتات الموت (DeathFx في models/shop.dart): كل افكت كيف تتغير صورة اللاعب ([deathLook]) وإيش ينرسم فوقها
// ([DeathPainter]) حسب الوقت من بداية الطرد. الرسم نفسه (المسند وكل افكت) في design_death.dart، ونفس الأشكال
// تبان في المعاينة (المتجر وغرفة التبديل) واللعبة: صورة اللاعب تنقلب مسند مخمل عليه الافكت، ويبقى بشكله الأخير.
// الافتراضي الغطا الرمادي (SeatCloth).

/// الحزن والرمادي أول (مثل الافتراضي)، وبعدها يبدأ الافكت.
const deathFxStart = 1.0;

/// طول الافكت؛ بعده تثبت آخر لقطة (اللي يتبقى على مكانه) لين تخلص اللعبة، وبعض الافكتات تظل فيها حركة خفيفة.
const deathFxLength = 2.6;

/// كيف تبان صورة اللاعب: شفافيتها، وفلتر لونها، وكم تنزل أو تطلع.
typedef DeathLook = ({double opacity, List<double>? matrix, double dy});

/// تقدم بين [a] و[b] (٠–١).
double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

List<double> _mix(List<double> to, double k) {
  const id = <double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
  return [for (var i = 0; i < 20; i++) id[i] + (to[i] - id[i]) * k];
}

/// رمادي.
const _grey = <double>[
  .33, .59, .11, 0, 0, //
  .33, .59, .11, 0, 0,
  .33, .59, .11, 0, 0,
  0, 0, 0, 1, 0,
];

/// ذهب: الإضاءة تصير ذهبية.
const _gold = <double>[
  .55, .45, .1, 0, 40, //
  .42, .38, .08, 0, 18,
  .12, .1, .05, 0, -10,
  0, 0, 0, 1, 0,
];

/// جليد: أزرق فاتح.
const _ice = <double>[
  .5, .3, .2, 0, 30, //
  .4, .5, .3, 0, 50,
  .4, .5, .5, 0, 90,
  0, 0, 0, 1, 0,
];

/// متفحم.
const _char = <double>[
  .18, .18, .1, 0, -10, //
  .14, .14, .08, 0, -14,
  .1, .1, .06, 0, -16,
  0, 0, 0, 1, 0,
];

/// متى (بثواني الافكت) يبدأ المسند يطلع مكان صورة اللاعب ويخلص: الصورة تخفت بنفس الوقت، وبعدها ما ترسم.
(double, double) _swap(DeathFx fx) => switch (fx) {
  DeathFx.smoke => (0, .55),
  DeathFx.sand => (.1, .9),
  DeathFx.petals => (.1, .8),
  DeathFx.ice => (.55, 1.3),
  DeathFx.fire => (0, .7),
  DeathFx.bats => (.1, .8),
  DeathFx.lightning => (.15, .6),
  DeathFx.ghost => (.3, 1.1),
  DeathFx.gold => (.9, 1.6),
  DeathFx.cloth => (0, .1),
};

/// شفافية المسند مكان اللاعب [s] ثواني من بداية الافكت.
double deathChairAlpha(DeathFx fx, double s) {
  final (a, b) = _swap(fx);
  return _seg(s, a, b);
}

/// [t] الوقت من بداية الطرد (ثواني).
DeathLook deathLook(DeathFx fx, double t) {
  final s = t - deathFxStart;
  final grey = _seg(t, 0, .9) * .8;
  if (s <= 0 || fx == DeathFx.cloth) return (opacity: 1, matrix: _mix(_grey, grey), dy: 0);
  final op = 1 - deathChairAlpha(fx, s);
  return switch (fx) {
    DeathFx.smoke => (opacity: op, matrix: _mix(_grey, .8), dy: 0),
    DeathFx.sand => (opacity: op, matrix: _mix(_grey, .8 - _seg(s, 0, .4) * .5), dy: 0),
    DeathFx.ice => (opacity: op, matrix: _mix(_ice, .4 + _seg(s, 0, 1) * .6), dy: 0),
    DeathFx.fire => (opacity: op, matrix: _mix(_char, _seg(s, .05, .6)), dy: 0),
    DeathFx.lightning => (opacity: op, matrix: _mix(_char, _seg(s, .1, .3) * .85), dy: 0),
    DeathFx.ghost => (opacity: op * .8, matrix: _mix(_grey, .9), dy: -_seg(s, .1, 1.0) * 6),
    DeathFx.gold => (opacity: op, matrix: _mix(_gold, .2 + _seg(s, 0, 1.0) * .8), dy: 0),
    DeathFx.petals => (opacity: op, matrix: _mix(_grey, .5), dy: 0),
    DeathFx.bats => (opacity: op, matrix: _mix(_char, .8), dy: 0),
    DeathFx.cloth => (opacity: 1, matrix: null, dy: 0),
  };
}

/// اللي ينرسم فوق صورة اللاعب ([size] = مكان الصورة نفسها؛ الرسمة تطلع برا شوي): المسند والافكت.
/// [clock] ساعة الحركات المستمرة (لهب، خفافيش…)، وبدونها يكون [idle] ثابت.
class DeathPainter extends CustomPainter {
  DeathPainter(this.fx, this.t, {this.idle = 0, ValueListenable<double>? clock})
    : _clock = clock,
      super(repaint: clock);

  final DeathFx fx;

  /// الوقت من بداية الطرد.
  final double t;

  final double idle;
  final ValueListenable<double>? _clock;

  @override
  void paint(Canvas canvas, Size size) {
    final s = t - deathFxStart;
    if (s <= 0 || fx == DeathFx.cloth) return;
    paintDeathAtSeat(canvas, size, fx, s: s, idle: _clock?.value ?? idle, chair: deathChairAlpha(fx, s));
  }

  @override
  bool shouldRepaint(DeathPainter old) => old.t != t || old.fx != fx || old.idle != idle || old._clock != _clock;
}

/// طبقة الافكت فوق صورة اللاعب بالطاولة: تعيد رسمها على ساعة الحركات (بدون ما تبني الواجهة).
class DeathLayer extends StatelessWidget {
  const DeathLayer({super.key, required this.fx, required this.t});

  final DeathFx fx;

  /// الوقت من بداية الطرد.
  final double t;

  @override
  Widget build(BuildContext context) {
    if (t <= deathFxStart || fx == DeathFx.cloth) return const SizedBox.shrink();
    return RepaintBoundary(
      child: FxClock(
        builder: (context, time) => CustomPaint(painter: DeathPainter(fx, t, clock: time)),
      ),
    );
  }
}

/// لما ينتهي الافكت: هل الصورة نفسها ما عادت تبان (عشان ما نرسم إطارها)؟
bool deathHidesAvatar(DeathFx fx, double t) => fx != DeathFx.cloth && t - deathFxStart >= _swap(fx).$2;

/// كان يطلع جمجمة مكان اللي يختفي؛ الحين الجمجمة جزء من رسمة الافكت نفسها (دخان، رمل)، والمسند يبين إنه مكانه.
class DeathMark extends StatelessWidget {
  const DeathMark({super.key, required this.fx, required this.t, this.size = 26});

  final DeathFx fx;
  final double t;
  final double size;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// معاينة الافكت (المتجر وغرفة التبديل): مسند مخمل والافكت ينزل عليه ويثبت على شكله، وبعدها يعيد.
/// ([avatar] و[frame] ما عادوا يبانون، المسند فاضي مثل التصميم؛ باقيين عشان الاستدعاءات القديمة.)
class DeathPreview extends StatelessWidget {
  const DeathPreview({super.key, required this.fx, required this.avatar, this.frame, this.size = 62});

  final DeathFx fx;
  final String avatar;
  final String? frame;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 1.7,
    height: size * 1.7,
    child: RepaintBoundary(
      child: FxClock(builder: (context, time) => CustomPaint(painter: _PreviewPainter(fx, time))),
    ),
  );
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.fx, this.time) : super(repaint: time);

  final DeathFx fx;
  final ValueListenable<double> time;

  /// المسند فاضي شوي، وبعدين الافكت ٢٫٦ ثانية، ويثبت على شكله، وآخر شي يخفت ويعيد.
  static const _pre = .45;
  static const _loop = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final now = time.value;
    // الوضع الخفيف: الشكل الأخير ثابت
    if (FxClock.lite.value) return paintDeathBox(canvas, size, fx, s: 4, idle: 1.3);
    final into = now % _loop;
    final edge = _seg(into, 0, .25) * (1 - _seg(into, _loop - .4, _loop));
    if (edge <= 0) return;
    if (edge < 1) {
      canvas.saveLayer(Offset.zero & size, Paint()..color = Color.fromRGBO(0, 0, 0, edge));
    }
    paintDeathBox(canvas, size, fx, s: into - _pre, idle: now);
    if (edge < 1) canvas.restore();
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => old.fx != fx || old.time != time;
}
