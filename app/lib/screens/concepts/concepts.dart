import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/shop.dart';
import '../../theme.dart';
import '../../widgets/bubble.dart';
import '../../widgets/common.dart';
import '../../widgets/fx.dart';
import '../../widgets/game/overlays.dart' show roleInfo;
import '../../widgets/game/policy_card.dart';
import '../../widgets/ui.dart';
import 'scene.dart';

/// نموذج واحد: عنوانه ومدته (يعيد نفسه)، ويرسم نفسه حسب الوقت من بدايته.
class Concept {
  const Concept(this.id, this.title, this.duration, this.build);

  final String id;
  final String title;
  final double duration;
  final Widget Function(double t) build;
}

final concepts = <Concept>[
  Concept('majlis', '١ · مجلس حقيقي: أقواس، فوانيس، دلة وفناجيل، وبخور', 5, _majlis),
  Concept('cushions', '٢ · كل لاعب على مسند، والمطرود ينطفي فانوسه وينغطى', 5, _cushions),
  Concept('tension', '٣ · الإضاءة تحمر وترمش كل ما قرب الخونة من الفوز', 7, _tension),
  Concept('enact', '٤ · تمرير القرار: الكرت يطير وينختم بالشمع، والأحمر يهز الشاشة', 6, _enact),
  Concept('vote', '٥ · كشف التصويت: دق طبول، وبعدها الكروت تنقلب على الكل مرة وحدة', 5, _vote),
  Concept('execute', '٦ · الطرد: الصورة تتشقق وتتكسر، وينطفي فانوسه', 4.5, _execute),
  Concept('unmask', '٧ · نهاية اللعبة: أقنعة الخونة تطيح وحدة وحدة، وورق ملون للفايزين', 7, _unmask),
  Concept('role', '٨ · بطاقة الدور برسمة، وتنقلب لك', 7.5, _role),
  Concept('hand', '٩ · كروت الرئيس تنفتح بيدك، وتسحب اللي تبي ترميه', 6, _hand),
  Concept('react', '١٠ · شخصيتك تضحك مع ملصقك، وتزعل لو انطردت', 6, _react),
  Concept('home', '١١ · الرئيسية: شخصيتك قاعدة في المجلس', 5, _home),
  Concept('hourglass', '١٢ · ساعة رملية جنب الرئيس بدل الشريط', 6, _hourglass),
  Concept('seasons', '١٣ · أشكال المواسم: رمضان، العيد، اليوم الوطني', 9, _seasons),
  Concept('buttons', '١٤ · الأزرار تنضغط بحركة واضحة مع اهتزاز خفيف', 4, _buttons),
];

/// معرض النماذج (نسخة المحاكي على الويب بس): ‎?gallery=concepts‎ يعرضها ورا بعض، و‎&only=vote‎ نموذج واحد يعيد نفسه.
/// كل شي يمشي على ساعة الحركات، فالتصوير (window.fxTime) يطلع نفس الشي كل مرة.
class ConceptGalleryApp extends StatelessWidget {
  const ConceptGalleryApp(this.q, {super.key});

  final Map<String, String> q;

  @override
  Widget build(BuildContext context) {
    final only = q['only'];
    final list = [
      for (final c in concepts)
        if (only == null || c.id == only) c,
    ];
    final total = list.fold(0.0, (sum, c) => sum + c.duration);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          color: Colors.black,
          child: Center(
            child: FittedBox(
              child: SizedBox(
                width: sceneW,
                height: sceneH,
                child: ClipRect(
                  child: FxClock(
                    builder: (context, time) => ValueListenableBuilder<double>(
                      valueListenable: time,
                      builder: (context, now, _) {
                        var t = now % total;
                        for (final c in list) {
                          if (t < c.duration) return _Stage(concept: c, t: t);
                          t -= c.duration;
                        }
                        return _Stage(concept: list.last, t: 0);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.concept, required this.t});

  final Concept concept;
  final double t;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: concept.build(t)),
      Positioned(
        top: 8,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xE60B0818),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withValues(alpha: .6), width: 1.2),
            ),
            child: Text(
              concept.title,
              style: const TextStyle(
                fontFamily: kufi,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.goldLight,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

// ───────── أدوات

/// تقدم الحركة بين [a] و[b] (٠–١) على منحنى.
double seg(double t, double a, double b, [Curve curve = Curves.linear]) =>
    curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// تطلع وتنزل مرة وحدة بين [a] و[b].
double bump(double t, double a, double b) => math.sin(seg(t, a, b) * math.pi);

Offset bezier(Offset a, Offset c, Offset b, double t) => a * ((1 - t) * (1 - t)) + c * (2 * (1 - t) * t) + b * (t * t);

/// يقرّب الكاميرا على [focus] بقد [k] (٠ المشهد كامل، ١ مقرب [scale] مرات والنقطة بالنص).
Widget zoom(Widget child, Offset focus, double scale, double k) {
  final s = 1 + (scale - 1) * k;
  final to = Offset.lerp(focus, const Offset(sceneW / 2, sceneH / 2), k)!;
  return Transform(
    transform: Matrix4.identity()
      ..translateByDouble(to.dx, to.dy, 0, 1)
      ..scaleByDouble(s, s, 1, 1)
      ..translateByDouble(-focus.dx, -focus.dy, 0, 1),
    child: child,
  );
}

/// يحط الودجت ونصه على [c].
Widget at(Offset c, double w, double h, Widget child) =>
    Positioned(left: c.dx - w / 2, top: c.dy - h / 2, width: w, height: h, child: child);

Widget dim(double a) => Positioned.fill(
  child: IgnorePointer(
    child: ColoredBox(color: Colors.black.withValues(alpha: a.clamp(0.0, 1.0))),
  ),
);

Sticker sticker(String id) => stickers.firstWhere((s) => s.id == id);

class _Title extends StatelessWidget {
  const _Title(this.text, this.color, {this.size = 28});

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontFamily: kufi,
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      shadows: const [
        Shadow(color: Colors.black, blurRadius: 12),
        Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 2),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.color = AppColors.goldLight, this.border = AppColors.gold, this.size = 14});

  final String text;
  final Color color, border;
  final double size;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xE60B0818),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border.withValues(alpha: .7)),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: kufi, fontSize: size, fontWeight: FontWeight.w700, color: color),
      ),
    ),
  );
}

/// إصبع اللاعب (دائرة لمس تنضغط).
class _Touch extends StatelessWidget {
  const _Touch({required this.press});

  final double press;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 60,
    height: 60,
    child: Stack(
      alignment: Alignment.center,
      children: [
        if (press > 0)
          Container(
            width: 30 + 30 * press,
            height: 30 + 30 * press,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .7 * press), width: 2),
            ),
          ),
        Container(
          width: 30 - 6 * press,
          height: 30 - 6 * press,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .55 + .25 * press),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
          ),
        ),
      ],
    ),
  );
}

/// كرت ينقلب: [angle] صفر يبين الوجه، وπ يبين الظهر.
class _FlipCard extends StatelessWidget {
  const _FlipCard({required this.angle, required this.front, required this.back});

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

/// ظهر كرت: بنفسجي بنقشة ذهبية وهلال.
class _CardBack extends StatelessWidget {
  const _CardBack();

  static const width = 120.0, height = 174.0;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4A2775), Color(0xFF1A0F33)],
      ),
      border: Border.all(color: AppColors.gold, width: 3),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 6))],
    ),
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _Lattice())),
        Center(child: Image.asset('assets/icons/gfx_card_crescent.png', width: width * .42)),
      ],
    ),
  );
}

class _Lattice extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final inner = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)).deflate(8);
    canvas.save();
    canvas.clipRRect(inner);
    final line = Paint()
      ..color = AppColors.gold.withValues(alpha: .16)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width + size.height; x += 16) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), line);
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), line);
    }
    canvas.restore();
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.gold.withValues(alpha: .55),
    );
  }

  @override
  bool shouldRepaint(_Lattice old) => false;
}

/// دخان يطلع من [from] (بعد ما ينطفي شي).
class _Smoke extends CustomPainter {
  _Smoke(this.from, this.p);

  final Offset from;
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / sceneW);
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
  bool shouldRepaint(_Smoke old) => true;
}

/// ورق ملون يطيح من فوق.
class _Confetti extends CustomPainter {
  _Confetti(this.t, {this.colors = _party, this.count = 70, this.loop = false, this.speed = 1});

  final double t;
  final List<Color> colors;
  final int count;
  final bool loop;
  final double speed;

  static const _party = [
    Color(0xFFFFD166),
    Color(0xFF06D6A0),
    Color(0xFFEF476F),
    Color(0xFF4CC9F0),
    Color(0xFFF2C14E),
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / sceneW);
    for (var k = 0; k < count; k++) {
      final life = t - (loop ? 0 : rnd(k, 1) * .8);
      if (life < 0) continue;
      final fall = life * (110 + rnd(k, 3) * 120) * speed;
      final y = loop ? (fall + rnd(k, 1) * (sceneH + 40)) % (sceneH + 40) - 20 : -20 + fall;
      if (y > sceneH + 20) continue;
      final x = rnd(k, 2) * sceneW + math.sin(life * 3 + k) * 18;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(life * (3 + rnd(k, 4) * 5) + k);
      canvas.scale(1, .25 + .75 * math.cos(life * 6 + k).abs());
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 7, height: 11),
        Paint()..color = colors[k % colors.length],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti old) => true;
}

// ───────── ١ المجلس

Widget _majlis(double t) => zoom(MajlisScene(t: t), const Offset(400, 250), 1.08, seg(t, 0, 5, Curves.easeInOut));

// ───────── ٢ المساند

Widget _cushions(double t) => zoom(
  MajlisScene(t: t, dead: {3: seg(t, 1.5, 3.7)}),
  seatAt(3, 6) + const Offset(0, -25),
  1.8,
  seg(t, .3, 1.2, Curves.easeInOut) * (1 - seg(t, 4.1, 4.9, Curves.easeInOut)),
);

// ───────── ٣ التوتر

const _tensionSteps = [1.2, 2.6, 4.0];

Widget _tension(double t) {
  final calm = 1 - seg(t, 6.3, 6.9);
  final tension = (seg(t, 1.2, 2.0) * .33 + seg(t, 2.6, 3.4) * .33 + seg(t, 4.0, 4.8) * .34) * calm;
  final filled = t >= 6.5 ? 2 : 2 + _tensionSteps.where((s) => t >= s).length;
  return Stack(
    children: [
      Positioned.fill(
        child: MajlisScene(t: t, tension: tension),
      ),
      Positioned(
        top: 46,
        left: 0,
        right: 0,
        child: Center(
          child: _TraitorTrack(t: t, filled: filled),
        ),
      ),
      if (t > 4.4 && t < 6.5)
        Positioned(
          top: 98,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: seg(t, 4.4, 4.7) * (1 - seg(t, 6.1, 6.4)) * (.65 + .35 * math.sin(t * 9)),
            child: const _Chip(
              'قرار واحد ويفوزون!',
              color: AppColors.traitorLight,
              border: AppColors.traitor,
              size: 18,
            ),
          ),
        ),
    ],
  );
}

class _TraitorTrack extends StatelessWidget {
  const _TraitorTrack({required this.t, required this.filled});

  final double t;
  final int filled;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xD90B0818),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.traitor.withValues(alpha: .6)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'قرارات الخونة',
          style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, color: AppColors.traitorLight, fontSize: 14),
        ),
        const SizedBox(width: 10),
        for (var j = 0; j < 6; j++)
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black38,
              border: Border.all(color: AppColors.traitor.withValues(alpha: .35)),
            ),
            child: j < filled
                ? Transform.scale(
                    scale: j < 2
                        ? 1.0
                        : Curves.elasticOut.transform(seg(t, _tensionSteps[j - 2], _tensionSteps[j - 2] + .6)),
                    child: const Seal(loyal: false, size: 30),
                  )
                : j == 5
                ? const Opacity(opacity: .45, child: Gfx('skull', size: 20))
                : null,
          ),
      ],
    ),
  );
}

// ───────── ٤ تمرير القرار

Widget _enact(double t) {
  final red = t >= 3;
  final u = red ? t - 3 : t;
  final fade = 1 - seg(u, 2.65, 2.95);
  final shake = red && u >= 1.45 ? 1 - seg(u, 1.45, 2.0) : 0.0;
  final from = seatAt(4, 6) + const Offset(0, -25);
  const to = Offset(400, 205);
  final fly = seg(u, .15, .85, Curves.easeOutCubic);
  final pos = bezier(from, Offset((from.dx + to.dx) / 2, to.dy - 110), to, fly);
  final flip = seg(u, .85, 1.15, Curves.easeInOut);
  final stamp = seg(u, 1.15, 1.45, Curves.easeInCubic);
  final squash = bump(u, 1.45, 1.65) * .07;
  final card = Transform.rotate(
    angle: (1 - fly) * -.7,
    child: Transform.scale(
      scaleX: .3 + .7 * fly + squash,
      scaleY: .3 + .7 * fly - squash,
      child: _FlipCard(
        angle: (1 - flip) * math.pi,
        front: _Parchment(loyal: !red, stamp: stamp),
        back: const _CardBack(),
      ),
    ),
  );
  return Transform.translate(
    offset: Offset(math.sin(u * 83) * 10, math.cos(u * 61) * 7) * shake,
    child: Transform.scale(
      scale: 1 + .03 * shake,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: MajlisScene(t: t)),
          dim(.5 * seg(u, 0, .4) * fade),
          if (u < 1)
            at(from + const Offset(0, -64), 80, 24, Opacity(opacity: 1 - seg(u, .7, 1), child: const _Chip('الوزير'))),
          if (u > 1.45 && u < 2.3) Positioned.fill(child: CustomPaint(painter: _Burst(to, seg(u, 1.45, 2.3), red))),
          at(pos, 120, 174, Opacity(opacity: fade, child: card)),
          if (u > 1.55)
            Positioned(
              left: 0,
              right: 0,
              top: 306,
              child: Opacity(
                opacity: seg(u, 1.55, 1.9) * fade,
                child: red
                    ? const _Chip(
                        'تمرر قرار للخونة',
                        color: AppColors.traitorLight,
                        border: AppColors.traitor,
                        size: 24,
                      )
                    : const _Chip('تمرر قرار للأوفياء', color: AppColors.loyalLight, border: AppColors.loyal, size: 24),
              ),
            ),
          if (shake > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: const Color(0xFFDC2626).withValues(alpha: .28 * shake)),
              ),
            ),
        ],
      ),
    ),
  );
}

/// ورقة القرار قبل الختم وبعده.
class _Parchment extends StatelessWidget {
  const _Parchment({required this.loyal, required this.stamp});

  final bool loyal;

  /// ٠ قبل الختم، ١ انختم.
  final double stamp;

  @override
  Widget build(BuildContext context) {
    final edge = loyal ? AppColors.loyalDark : AppColors.traitorDark;
    return Container(
      width: 120,
      height: 174,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8EBD0), AppColors.parchmentDark],
        ),
        border: Border.all(color: edge, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB88A4A), width: 1.2),
              ),
            ),
          ),
          if (stamp > 0 && stamp < 1)
            Align(
              alignment: const Alignment(0, -.25),
              child: Container(
                width: 70 * (1.6 - .6 * stamp),
                height: 70 * (1.6 - .6 * stamp),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: .3 * stamp),
                ),
              ),
            ),
          if (stamp > 0)
            Align(
              alignment: const Alignment(0, -.25),
              child: Opacity(
                opacity: stamp,
                child: Transform.rotate(
                  angle: (1 - stamp) * .9,
                  child: Transform.scale(
                    scale: 1 + (1 - stamp) * 2.4,
                    child: Seal(loyal: loyal, size: 70),
                  ),
                ),
              ),
            ),
          if (stamp >= 1)
            Align(
              alignment: const Alignment(0, .78),
              child: Text(
                loyal ? 'أوفياء' : 'خونة',
                style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 20, color: edge),
              ),
            ),
        ],
      ),
    );
  }
}

/// ضربة الختم: حلقة تتوسع وشرار يتطاير.
class _Burst extends CustomPainter {
  _Burst(this.c, this.p, this.red);

  final Offset c;
  final double p;
  final bool red;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / sceneW);
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
  bool shouldRepaint(_Burst old) => true;
}

// ───────── ٥ كشف التصويت

const _votes = [true, false, true, true, false, true];

/// كرت التصويت جنب صورة اللاعب (من جهة الصينية).
Offset _voteSpot(int i) {
  final dx = switch (i) {
    1 || 2 => 70.0,
    4 || 5 => -70.0,
    _ => 76.0,
  };
  return seatAt(i, 6) + Offset(dx, -22);
}

Widget _vote(double t) {
  final fade = 1 - seg(t, 4.6, 5);
  final appear = seg(t, 0, .4, Curves.easeOutBack);
  final drum = seg(t, .3, .6) * (1 - seg(t, 1.75, 1.95));
  final roll = seg(t, .3, 1.8);
  final flip = seg(t, 1.85, 2.3, Curves.easeInOut);
  final pop = bump(t, 2.3, 2.6);
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned.fill(child: MajlisScene(t: t)),
      dim(.3 * seg(t, 0, .3) * fade),
      if (drum > 0)
        at(
          const Offset(400, 292),
          130,
          120,
          Opacity(
            opacity: drum,
            child: CustomPaint(painter: _Drum(t, roll)),
          ),
        ),
      for (final (i, yes) in _votes.indexed)
        at(
          _voteSpot(i),
          50,
          70,
          Opacity(
            opacity: fade,
            child: Transform.translate(
              offset: Offset(0, math.sin(t * 37 + i * 2) * 3 * roll * (1 - flip)),
              child: Transform.rotate(
                angle: math.sin(t * 43 + i) * .1 * roll * (1 - flip),
                child: Transform.scale(
                  scale: appear * (1 + .2 * pop),
                  child: _FlipCard(angle: (1 - flip) * math.pi, front: _VoteFace(yes), back: const _VoteBack()),
                ),
              ),
            ),
          ),
        ),
      if (t > 2.7)
        at(
          const Offset(400, 300),
          320,
          62,
          Opacity(
            opacity: seg(t, 2.7, 3.0) * fade,
            child: Transform.scale(scale: seg(t, 2.7, 3.1, Curves.easeOutBack), child: const _VoteBanner()),
          ),
        ),
    ],
  );
}

class _VoteFace extends StatelessWidget {
  const _VoteFace(this.yes);

  final bool yes;

  @override
  Widget build(BuildContext context) => Container(
    width: 50,
    height: 70,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(9),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: yes ? const [Color(0xFF6DE3A0), Color(0xFF1E8E52)] : const [Color(0xFFFF8C98), Color(0xFFA3172D)],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: .85), width: 2),
      boxShadow: [BoxShadow(color: (yes ? AppColors.green : AppColors.traitor).withValues(alpha: .7), blurRadius: 14)],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Gfx(yes ? 'check' : 'cross', size: 26),
        Text(
          yes ? 'نعم' : 'لا',
          style: TextStyle(
            fontFamily: kufi,
            fontWeight: FontWeight.w700,
            fontSize: 15,
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
    width: 50,
    height: 70,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(9),
      gradient: const LinearGradient(colors: [Color(0xFF4A2775), Color(0xFF1A0F33)]),
      border: Border.all(color: AppColors.gold, width: 2),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3))],
    ),
    child: const Text(
      '؟',
      style: TextStyle(fontFamily: kufi, fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.goldLight),
    ),
  );
}

class _VoteBanner extends StatelessWidget {
  const _VoteBanner();

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xF00B0818),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.green, width: 2),
      boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: .45), blurRadius: 24)],
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Gfx('check', size: 30),
        SizedBox(width: 8),
        Text(
          'الحكومة انتخبت',
          style: TextStyle(fontFamily: kufi, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.green),
        ),
        SizedBox(width: 12),
        Text(
          '٤ – ٢',
          style: TextStyle(fontFamily: kufi, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
        ),
      ],
    ),
  );
}

/// طبل وعصيه تضرب بالتناوب، وتسرع مع [roll].
class _Drum extends CustomPainter {
  _Drum(this.t, this.roll);

  final double t, roll;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 + 14);
    final speed = 4 + roll * 10;
    for (var k = 0; k < 3; k++) {
      final q = frac(t * speed / 4 + k / 3);
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
      final end = tip + Offset(side * 30, -26);
      canvas.drawLine(
        tip,
        end,
        Paint()
          ..color = const Color(0xFF8A5A00)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(tip, 4.5, Paint()..color = const Color(0xFFFFF2C2));
    }
  }

  @override
  bool shouldRepaint(_Drum old) => true;
}

// ───────── ٦ الطرد

Widget _execute(double t) {
  const c = Offset(400, 200);
  const lamp = Offset(528, 236);
  final shake = seg(t, .2, 1.0) * (1 - seg(t, 1.5, 1.6));
  final crack = seg(t, .9, 1.35, Curves.easeOut);
  final shatter = seg(t, 1.55, 2.6, Curves.easeIn);
  final fade = 1 - seg(t, 4.1, 4.5);
  final out = seg(t, 1.6, 2.1);
  final on = out == 0 ? 1.0 : (1 - out) * (.5 + .5 * math.sin(t * 50).abs());
  final avatar = Transform.translate(
    offset: Offset(math.sin(t * 61) * 4, math.cos(t * 47) * 2) * shake,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.traitor.withValues(alpha: .65 * shake), blurRadius: 40, spreadRadius: 8),
            ],
          ),
        ),
        if (shatter == 0) ...[
          const PlayerAvatar(avatar: 'wolf', size: 150),
          if (crack > 0)
            SizedBox(
              width: 150,
              height: 150,
              child: ClipOval(child: CustomPaint(painter: _Cracks(crack))),
            ),
        ] else
          _Shatter(avatar: 'wolf', size: 150, p: shatter),
        if (t > 1.55 && t < 1.85)
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .8 * (1 - seg(t, 1.55, 1.85))),
            ),
          ),
      ],
    ),
  );
  return Stack(
    children: [
      Positioned.fill(
        child: MajlisScene(t: t, dead: {3: seg(t, 2.6, 3.8)}),
      ),
      dim(.62 * seg(t, 0, .3) * fade),
      at(c, 240, 240, Opacity(opacity: fade, child: avatar)),
      at(
        lamp,
        40,
        75,
        Opacity(
          opacity: fade,
          child: FloorLantern(t: t, on: on, scale: 2.5),
        ),
      ),
      if (t > 2.0)
        Positioned.fill(
          child: Opacity(
            opacity: fade,
            child: CustomPaint(painter: _Smoke(lamp + const Offset(0, -30), seg(t, 2.0, 3.8))),
          ),
        ),
      if (t > 2.6)
        Positioned(
          left: 0,
          right: 0,
          top: 300,
          child: Opacity(
            opacity: seg(t, 2.6, 3.0) * fade,
            child: const Column(
              children: [
                _Title('تركي انطرد', AppColors.traitorLight, size: 30),
                Text(
                  'ما يقدر يلعب بعد الحين',
                  style: TextStyle(color: AppColors.muted, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

/// شقوق تمشي من نقطة الضربة لأطراف الصورة.
class _Cracks extends CustomPainter {
  _Cracks(this.p);

  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w * .43, w * .4);
    final dark = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withValues(alpha: .6);
    final light = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: .95);
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
  bool shouldRepaint(_Cracks old) => old.p != p;
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
    return Positioned.fill(
      child: Transform.translate(
        offset: dir * (p * (30 + rnd(k, 6) * 60)) + Offset(0, p * p * 170),
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

// ───────── ٧ نهاية اللعبة

Widget _unmask(double t) {
  final fade = 1 - seg(t, 6.6, 7);
  final win = seg(t, 4.2, 4.8, Curves.easeOutBack);
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned.fill(child: MajlisBackdrop(t: t, tray: false)),
      Positioned.fill(child: Lanterns(t: t)),
      dim(.55),
      for (final (i, s) in demoSeats.indexed)
        at(
          Offset(105 + i * 118.0, 250),
          112,
          170,
          Opacity(
            opacity: fade,
            child: _Unmask(seat: s, i: i, t: t, at: s.traitor ? (i == 1 ? 1.9 : 3.1) : .8),
          ),
        ),
      if (t > 4.2)
        Positioned(
          left: 0,
          right: 0,
          top: 70,
          child: Opacity(
            opacity: fade,
            child: Transform.scale(scale: win, child: const GoldText('فاز الأوفياء!', size: 42)),
          ),
        ),
      if (t > 4.2)
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _Confetti(t - 4.2))),
        ),
    ],
  );
}

class _Unmask extends StatelessWidget {
  const _Unmask({required this.seat, required this.i, required this.t, required this.at});

  final SeatInfo seat;
  final int i;
  final double t;

  /// متى يطيح قناعه.
  final double at;

  @override
  Widget build(BuildContext context) {
    final traitor = seat.traitor;
    final wobble = traitor && t > at && t < at + .35 ? math.sin(t * 40) * .14 : 0.0;
    final off = seg(t, traitor ? at + .35 : at, traitor ? at + 1.0 : at + .6, Curves.easeIn);
    final shown = off > .3;
    final color = traitor ? AppColors.traitor : AppColors.loyal;
    final light = traitor ? AppColors.traitorLight : AppColors.loyalLight;
    final flash = traitor ? bump(t, at + .35, at + .95) : 0.0;
    final stamp = traitor ? seg(t, at + .55, at + .85, Curves.easeInCubic) : 0.0;
    final hop = !traitor && t > 4.2 ? -math.sin((t - 4.2) * 7 + i).abs() * 12 : 0.0;
    final lost = traitor ? seg(t, 4.2, 4.8) : 0.0;
    return Column(
      children: [
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (flash > 0)
                Container(
                  width: 96,
                  height: 96,
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
                  child: PlayerAvatar(avatar: seat.avatar, size: 84, frame: shown ? color : null),
                ),
              ),
              Transform.translate(
                offset: traitor ? Offset(0, 160 * off * off) : Offset(0, -90 * off),
                child: Transform.rotate(
                  angle: wobble + (traitor ? off * 1.3 : -off * .4),
                  child: Opacity(
                    opacity: (1 - off).clamp(0.0, 1.0),
                    child: const PlayerAvatar(avatar: 'masked', size: 84, animate: false),
                  ),
                ),
              ),
              if (stamp > 0)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Opacity(
                    opacity: stamp,
                    child: Transform.scale(scale: 1 + (1 - stamp) * 2, child: const Seal(loyal: false, size: 42)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          seat.name,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: shown ? light : AppColors.text),
        ),
        Opacity(
          opacity: seg(off, .3, 1),
          child: Text(
            traitor ? 'خائن' : 'وفي',
            style: TextStyle(fontFamily: kufi, fontSize: 14, fontWeight: FontWeight.w700, color: light),
          ),
        ),
      ],
    );
  }
}

// ───────── ٨ بطاقة الدور

Widget _role(double t) {
  const roles = [Role.loyal, Role.traitor, Role.leader];
  final fade = 1 - seg(t, 7.1, 7.5);
  return Stack(
    children: [
      Positioned.fill(child: MajlisBackdrop(t: t, tray: false)),
      Positioned.fill(child: Lanterns(t: t)),
      dim(.6),
      for (final (i, r) in roles.indexed) _roleCard(t, i, r, fade),
    ],
  );
}

Widget _roleCard(double t, int i, Role role, double fade) {
  final t0 = .5 + i * 1.7;
  final flip = seg(t, t0, t0 + .75, Curves.easeInOutBack);
  final lift = bump(t, t0, t0 + .75) * 24;
  final float = math.sin(t * 1.6 + i) * 3;
  return at(
    Offset(160 + i * 240.0, 250 - lift + float),
    200,
    290,
    Opacity(
      opacity: fade,
      child: _FlipCard(
        angle: (1 - flip) * math.pi,
        front: _RoleFront(role: role, shine: seg(t, t0 + .75, t0 + 1.45)),
        back: const _RoleBack(),
      ),
    ),
  );
}

class _RoleFront extends StatelessWidget {
  const _RoleFront({required this.role, required this.shine});

  final Role role;
  final double shine;

  @override
  Widget build(BuildContext context) {
    final (name, goal, color, dark) = roleInfo[role]!;
    return Container(
      width: 200,
      height: 290,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8EBD0), AppColors.parchmentDark],
        ),
        border: Border.all(color: AppColors.goldDark, width: 3),
        boxShadow: [
          BoxShadow(color: dark, spreadRadius: 3),
          BoxShadow(color: color.withValues(alpha: .5), blurRadius: 30, spreadRadius: 2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned(left: 10, right: 10, top: 10, height: 150, child: _RoleArt(role: role)),
            Positioned(
              left: 0,
              right: 0,
              top: 164,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: kufi,
                  fontSize: role == Role.leader ? 25 : 30,
                  fontWeight: FontWeight.w700,
                  color: dark,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 214,
              child: Text(
                goal,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.ink, fontSize: 13, height: 1.5, fontWeight: FontWeight.w700),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _Corners(dark))),
            if (shine > 0 && shine < 1) Positioned.fill(child: CustomPaint(painter: _ShinePainter(shine))),
          ],
        ),
      ),
    );
  }
}

/// رسمة الدور: شمس خلف قوس المجلس، والرمز بالنص.
class _RoleArt extends StatelessWidget {
  const _RoleArt({required this.role});

  final Role role;

  @override
  Widget build(BuildContext context) {
    final (light, deep) = switch (role) {
      Role.loyal => (const Color(0xFF8FC1FF), const Color(0xFF0B2A66)),
      Role.traitor => (const Color(0xFFFF8A8A), const Color(0xFF5C0A16)),
      Role.leader => (const Color(0xFFFF6A3D), const Color(0xFF1F0508)),
    };
    final icon = switch (role) {
      Role.loyal => 'shield',
      Role.traitor => 'dagger',
      Role.leader => 'scorpion',
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(center: const Alignment(0, -.1), radius: .9, colors: [light, deep]),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _ArtBack(light))),
          Positioned(
            bottom: 18,
            child: Container(
              width: 90,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.black.withValues(alpha: .35),
              ),
            ),
          ),
          Image.asset('assets/icons/gfx_card_$icon.png', width: 100, height: 100),
        ],
      ),
    );
  }
}

/// أشعة وقوس مجلس خلف الرمز.
class _ArtBack extends CustomPainter {
  _ArtBack(this.light);

  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * .45);
    final ray = Paint()..color = Colors.white.withValues(alpha: .1);
    for (var k = 0; k < 16; k++) {
      final a = k / 16 * 2 * math.pi;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + math.cos(a - .09) * 200, c.dy + math.sin(a - .09) * 200)
          ..lineTo(c.dx + math.cos(a + .09) * 200, c.dy + math.sin(a + .09) * 200)
          ..close(),
        ray,
      );
    }
    final w = size.width, h = size.height;
    final arch = Path()
      ..moveTo(0, h)
      ..lineTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w * .82, h)
      ..lineTo(w * .82, h * .5)
      ..quadraticBezierTo(w * .8, h * .14, w * .5, h * .06)
      ..quadraticBezierTo(w * .2, h * .14, w * .18, h * .5)
      ..lineTo(w * .18, h)
      ..close();
    canvas.drawPath(arch, Paint()..color = Colors.black.withValues(alpha: .35));
    canvas.drawPath(
      Path()
        ..moveTo(w * .18, h)
        ..lineTo(w * .18, h * .5)
        ..quadraticBezierTo(w * .2, h * .14, w * .5, h * .06)
        ..quadraticBezierTo(w * .8, h * .14, w * .82, h * .5)
        ..lineTo(w * .82, h),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.gold.withValues(alpha: .8),
    );
  }

  @override
  bool shouldRepaint(_ArtBack old) => false;
}

/// زخارف ذهبية على زوايا البطاقة.
class _Corners extends CustomPainter {
  _Corners(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.goldDark;
    final dot = Paint()..color = color;
    for (final (sx, sy) in [(1.0, 1.0), (-1.0, 1.0), (1.0, -1.0), (-1.0, -1.0)]) {
      canvas.save();
      canvas.translate(sx > 0 ? 0 : size.width, sy > 0 ? 0 : size.height);
      canvas.scale(sx, sy);
      canvas.drawPath(
        Path()
          ..moveTo(6, 34)
          ..lineTo(6, 14)
          ..quadraticBezierTo(6, 6, 14, 6)
          ..lineTo(34, 6),
        p,
      );
      canvas.drawCircle(const Offset(12, 12), 2.6, dot);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Corners old) => false;
}

/// لمعة تمر على البطاقة مرة وحدة.
class _ShinePainter extends CustomPainter {
  _ShinePainter(this.p);

  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(-60 + p * (size.width + 120), size.height / 2);
    canvas.rotate(.35);
    final r = Rect.fromCenter(center: Offset.zero, width: 56, height: size.height * 1.7);
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: .55),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(r),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShinePainter old) => old.p != p;
}

class _RoleBack extends StatelessWidget {
  const _RoleBack();

  @override
  Widget build(BuildContext context) => Container(
    width: 200,
    height: 290,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4A2775), Color(0xFF140B29)],
      ),
      border: Border.all(color: AppColors.gold, width: 3),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8))],
    ),
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _Lattice())),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset('assets/logo.png', width: 96, height: 96),
              ),
              const SizedBox(height: 12),
              const Text(
                'دورك السري',
                style: TextStyle(
                  fontFamily: kufi,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldLight,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ───────── ٩ كروت الرئيس

Widget _hand(double t) {
  const hand = [Policy.traitor, Policy.loyal, Policy.traitor];
  const bin = Offset(118, 300);
  final minister = seatAt(4, 6) + const Offset(0, -25);
  final fade = 1 - seg(t, 5.6, 6);
  final rise = seg(t, 0, .6, Curves.easeOutCubic);
  final fan = seg(t, .35, 1.0, Curves.easeOutBack);
  final grab = seg(t, 1.7, 1.9, Curves.easeOut);
  final drag = seg(t, 1.95, 2.95, Curves.easeInOut);
  final burn = seg(t, 2.95, 3.6);
  final close = seg(t, 3.4, 3.9, Curves.easeInOut);
  final send = seg(t, 4.4, 5.2, Curves.easeInCubic);

  Offset fanned(int i) => Offset(400 + (i - 1) * 118 * fan, 520 - 196 * rise + (i - 1).abs() * 14 * fan);
  final lifted = fanned(0) + Offset(0, -36 * grab);
  final card0 = bezier(lifted, const Offset(250, 170), bin, drag);

  Widget kept(int i) {
    final closed = Offset(400 + (i == 1 ? -62 : 62), 330);
    final pos = Offset.lerp(Offset.lerp(fanned(i), closed, close), minister + Offset(i == 1 ? -12 : 12, 0), send)!;
    final angle = (i - 1) * .2 * fan * (1 - close) + (i == 1 ? -.08 : .08) * close;
    return at(
      pos,
      100,
      145,
      Opacity(
        opacity: fade * (1 - seg(t, 5.0, 5.3)),
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: 1 - .7 * send,
            child: PolicyCard(policy: hand[i], width: 100),
          ),
        ),
      ),
    );
  }

  final touchAt = t < 1.6
      ? Offset.lerp(const Offset(600, 480), fanned(0), seg(t, 1.1, 1.6, Curves.easeOut))!
      : t < 2.95
      ? card0
      : Offset.lerp(bin, const Offset(250, 490), seg(t, 3.05, 3.6, Curves.easeIn))!;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned.fill(child: MajlisScene(t: t)),
      dim(.5),
      Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: .6)],
              ),
            ),
          ),
        ),
      ),
      if (t > 3.8 && t < 5.5)
        at(
          minister,
          80,
          80,
          Opacity(
            opacity: seg(t, 3.8, 4.1) * (1 - seg(t, 5.2, 5.5)),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 3),
                boxShadow: [
                  BoxShadow(color: AppColors.gold.withValues(alpha: .7), blurRadius: 18 + 8 * math.sin(t * 8)),
                ],
              ),
            ),
          ),
        ),
      if (t > 3.8 && t < 5.5)
        at(minister + const Offset(0, -56), 80, 24, Opacity(opacity: seg(t, 3.8, 4.1), child: const _Chip('الوزير'))),
      at(
        bin,
        110,
        110,
        Opacity(
          opacity: fade,
          child: CustomPaint(painter: _Brazier(t, math.max(seg(drag, .6, 1), bump(t, 2.95, 3.9)))),
        ),
      ),
      at(
        bin + const Offset(0, 62),
        90,
        24,
        Opacity(
          opacity: fade,
          child: const _Chip('المرمى', color: AppColors.text),
        ),
      ),
      kept(1),
      kept(2),
      if (burn < 1)
        at(
          card0,
          100,
          145,
          Transform.rotate(
            angle: -.2 * fan - .5 * drag,
            child: Transform.scale(
              scale: (1 + .08 * grab - .2 * drag) * (1 - .8 * burn),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Color.lerp(Colors.transparent, const Color(0xFFFF6A00), burn)!,
                  BlendMode.srcATop,
                ),
                child: Opacity(
                  opacity: 1 - burn,
                  child: PolicyCard(policy: hand[0], width: 100, highlight: grab > 0 && drag < 1),
                ),
              ),
            ),
          ),
        ),
      if (t > 2.95 && t < 4.4) Positioned.fill(child: CustomPaint(painter: _Embers(bin, seg(t, 2.95, 4.4)))),
      if (t > 1.05 && t < 3.6)
        at(touchAt + const Offset(0, 10), 60, 60, _Touch(press: bump(t, 1.6, 1.85) + (t > 1.85 && t < 2.95 ? .6 : 0))),
      Positioned(
        top: 50,
        left: 0,
        right: 0,
        child: Opacity(
          opacity: t < 3.3 ? seg(t, 1.0, 1.3) * (1 - seg(t, 3.0, 3.3)) : seg(t, 3.6, 3.9) * (1 - seg(t, 5.3, 5.6)),
          child: _Title(t < 3.3 ? 'اسحب الكرت اللي تبي ترميه' : 'والباقي يروح للوزير', AppColors.goldLight, size: 22),
        ),
      ),
    ],
  );
}

/// مجمرة الكروت المرمية: تولع أكثر لما يقرب الكرت.
class _Brazier extends CustomPainter {
  _Brazier(this.t, this.heat);

  final double t, heat;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 + 10);
    canvas.drawCircle(
      c + const Offset(0, -10),
      50,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF8A1F).withValues(alpha: .25 + .45 * heat),
            const Color(0x00FF8A1F),
          ],
        ).createShader(Rect.fromCircle(center: c + const Offset(0, -10), radius: 50)),
    );
    for (var k = 0; k < 5; k++) {
      final q = frac(t * (1.6 + heat) + k / 5);
      final x = c.dx + (k - 2) * 8 + math.sin(t * 6 + k) * 3;
      final h = (14 + 26 * heat) * (1 - q * .4);
      canvas.drawPath(
        Path()
          ..moveTo(x - 6, c.dy - 6)
          ..quadraticBezierTo(x - 4, c.dy - 6 - h * .6, x, c.dy - 6 - h)
          ..quadraticBezierTo(x + 4, c.dy - 6 - h * .6, x + 6, c.dy - 6)
          ..close(),
        Paint()..color = Color.lerp(const Color(0xFFFFD166), const Color(0xFFFF4D00), q)!.withValues(alpha: .85),
      );
    }
    final bowl = Path()
      ..moveTo(c.dx - 36, c.dy - 8)
      ..quadraticBezierTo(c.dx, c.dy + 34, c.dx + 36, c.dy - 8)
      ..close();
    canvas.drawPath(
      bowl,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF8A5A00), Color(0xFFD4A017), Color(0xFF6B4300)])
            .createShader(Rect.fromLTWH(c.dx - 36, c.dy - 8, 72, 30)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(0, -8), width: 72, height: 12),
      Paint()..color = const Color(0xFF3B1A0A),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(0, -8), width: 60, height: 8),
      Paint()..color = Color.lerp(const Color(0xFF7A2E0A), const Color(0xFFFF8A1F), heat)!,
    );
    canvas.drawRect(
      Rect.fromCenter(center: c + const Offset(0, 22), width: 10, height: 16),
      Paint()..color = const Color(0xFF6B4300),
    );
    canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(0, 32), width: 40, height: 9),
      Paint()..color = const Color(0xFF8A5A00),
    );
  }

  @override
  bool shouldRepaint(_Brazier old) => true;
}

/// جمر يطلع لفوق من [from].
class _Embers extends CustomPainter {
  _Embers(this.from, this.p);

  final Offset from;
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / sceneW);
    for (var k = 0; k < 18; k++) {
      final q = (p * 1.5 - rnd(k, 1) * .5).clamp(0.0, 1.0);
      if (q <= 0 || q >= 1) continue;
      final pos = from + Offset((rnd(k, 2) - .5) * 60 + math.sin(q * 8 + k) * 8, -10 - q * (80 + rnd(k, 3) * 70));
      canvas.drawCircle(
        pos,
        1.5 + rnd(k, 4) * 2,
        Paint()..color = Color.lerp(const Color(0xFFFFE08A), const Color(0xFFFF4D00), q)!.withValues(alpha: 1 - q),
      );
    }
  }

  @override
  bool shouldRepaint(_Embers old) => true;
}

// ───────── ١٠ شخصيتك تتفاعل

Widget _react(double t) {
  final laugh = seg(t, .55, .8) * (1 - seg(t, 2.6, 2.9));
  final sad = seg(t, 3.1, 3.7, Curves.easeOut);
  final hop = math.sin(t * 15).abs();
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned.fill(child: MajlisBackdrop(t: t)),
      Positioned.fill(child: Lanterns(t: t)),
      dim(.45),
      // يضحك
      at(
        const Offset(250, 225),
        170,
        170,
        Transform.translate(
          offset: Offset(0, -hop * 10 * laugh),
          child: Transform.rotate(
            angle: math.sin(t * 7.5) * .09 * laugh,
            child: Transform.scale(
              scaleX: 1 + .04 * laugh * hop,
              scaleY: 1 - .05 * laugh * hop,
              child: const PlayerAvatar(avatar: 'emir', size: 150),
            ),
          ),
        ),
      ),
      if (t > .35)
        at(
          const Offset(360, 112),
          110,
          110,
          Opacity(
            opacity: 1 - seg(t, 2.7, 3.0),
            child: Transform.rotate(
              angle: (1 - seg(t, .35, .95)) * -.4,
              child: Transform.scale(
                scale: Curves.elasticOut.transform(seg(t, .35, .95)),
                child: StickerView(sticker: sticker('laugh_tears'), size: 100, pop: false),
              ),
            ),
          ),
        ),
      for (var k = 0; k < 4; k++) _haha(t, k),
      at(const Offset(250, 330), 90, 26, const _Chip('أنت', color: AppColors.text)),
      // يزعل
      at(
        const Offset(560, 225),
        170,
        170,
        Transform.translate(
          offset: Offset(0, 14 * sad),
          child: Transform.rotate(
            angle: .2 * sad,
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix(greyMatrix(.7 * sad)),
                    child: const PlayerAvatar(avatar: 'wolf', size: 150),
                  ),
                  for (var k = 0; k < 2; k++)
                    if (t > 3.6 + k * .9) _tear(seg(t, 3.6 + k * .9, 4.6 + k * .9)),
                ],
              ),
            ),
          ),
        ),
      ),
      if (sad > 0)
        at(
          const Offset(560, 108),
          120,
          90,
          Opacity(
            opacity: sad,
            child: CustomPaint(painter: _RainCloud(t)),
          ),
        ),
      at(
        const Offset(560, 330),
        120,
        26,
        t < 3.1
            ? const _Chip('تركي', color: AppColors.text)
            : const _Chip('تركي · انطرد', color: AppColors.traitorLight, border: AppColors.traitor),
      ),
    ],
  );
}

Widget _haha(double t, int k) {
  final start = .7 + k * .45;
  if (t < start || t > start + 1.2) return const SizedBox.shrink();
  final q = seg(t, start, start + 1.2);
  return at(
    Offset(250 + (k.isEven ? -70 : 70) + math.sin(q * 6) * 6, 150 - q * 80),
    90,
    30,
    Opacity(opacity: math.sin(q * math.pi), child: const _Title('هههه', AppColors.goldLight, size: 20)),
  );
}

/// دمعة تنزل من عينه اليسار.
Widget _tear(double q) => Positioned(
  left: 56,
  top: 80 + q * 46,
  child: Opacity(
    opacity: math.sin(q * math.pi).clamp(0.0, 1.0),
    child: Container(
      width: 9,
      height: 13,
      decoration: const BoxDecoration(
        color: Color(0xFF7DD3FC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(2),
          topRight: Radius.circular(9),
          bottomLeft: Radius.circular(9),
          bottomRight: Radius.circular(9),
        ),
        boxShadow: [BoxShadow(color: Colors.white54, blurRadius: 3)],
      ),
    ),
  ),
);

/// غيمة فوق راسه تمطر.
class _RainCloud extends CustomPainter {
  _RainCloud(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final drop = Paint()
      ..color = const Color(0xFF7DD3FC)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 6; k++) {
      final q = frac(t * 1.6 + k / 6);
      final x = cx - 30 + k * 12;
      final y = 40 + q * 44;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 2, y + 7),
        drop..color = const Color(0xFF7DD3FC).withValues(alpha: 1 - q),
      );
    }
    final cloud = Paint()..color = const Color(0xFF64748B);
    for (final (dx, dy, r) in [
      (-24.0, 30.0, 16.0),
      (0.0, 22.0, 22.0),
      (24.0, 30.0, 16.0),
      (-10.0, 34.0, 14.0),
      (12.0, 34.0, 14.0),
    ]) {
      canvas.drawCircle(Offset(cx + dx, dy), r, cloud);
    }
  }

  @override
  bool shouldRepaint(_RainCloud old) => true;
}

// ───────── ١١ الرئيسية

Widget _home(double t) {
  const me = Offset(590, 200);
  final pulse = 1 + .025 * math.sin(t * 3);
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned.fill(child: MajlisBackdrop(t: t, tray: false)),
      Positioned.fill(child: Lanterns(t: t)),
      at(me + const Offset(0, 22), 250, 170, const Cushion(width: 250, height: 170)),
      at(me, 170, 170, const PlayerAvatar(avatar: 'emir', size: 160)),
      Positioned.fill(
        child: TrayView(t: t, at: me + const Offset(0, 142)),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        child: Align(
          alignment: const Alignment(.475, .93),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 3, 12, 5),
            decoration: BoxDecoration(
              color: const Color(0xE60B0818),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: .5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('أبو فهد', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(width: 10),
                const Gfx('xp', size: 18),
                const SizedBox(width: 3),
                const Text(
                  'مستوى ١٢',
                  style: TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 70,
                  height: 7,
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    width: 46,
                    decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      const Positioned(
        left: 20,
        top: 50,
        child: Row(
          children: [
            CurrencyPill(icon: 'coin', amount: 12500),
            SizedBox(width: 8),
            CurrencyPill(icon: 'gem', amount: 340),
          ],
        ),
      ),
      Positioned(
        left: 70,
        top: 120,
        width: 290,
        child: Column(
          children: [
            Transform.scale(
              scale: pulse,
              child: GameButton(
                label: 'العب',
                onPressed: () {},
                height: 72,
                fontSize: 30,
                icon: const Gfx('games', size: 34),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GameButton(
                    label: 'المتجر',
                    onPressed: () {},
                    tone: ButtonTone.purple,
                    height: 52,
                    fontSize: 17,
                    icon: const Gfx('shop', size: 24),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GameButton(
                    label: 'الأصدقاء',
                    onPressed: () {},
                    tone: ButtonTone.green,
                    height: 52,
                    fontSize: 17,
                    icon: const Gfx('friends', size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GameButton(
                    label: 'المهام',
                    onPressed: () {},
                    tone: ButtonTone.ghost,
                    height: 46,
                    fontSize: 16,
                    icon: const Gfx('missions', size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GameButton(
                    label: 'التصنيف',
                    onPressed: () {},
                    tone: ButtonTone.ghost,
                    height: 46,
                    fontSize: 16,
                    icon: const Gfx('rank', size: 22),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

// ───────── ١٢ الساعة الرملية

Widget _hourglass(double t) {
  final pres = seatAt(2, 6);
  final p = seg(t, .6, 5.4);
  final flip = seg(t, 5.5, 5.95, Curves.easeInOut);
  final urgent = seg(p, .72, .8) * (1 - flip);
  final glass = pres + const Offset(74, -24);
  final secs = (30 * (1 - p)).ceil();
  return zoom(
    Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: MajlisScene(t: t)),
        at(
          pres + const Offset(0, -20),
          70,
          70,
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 3),
              boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: .6), blurRadius: 14 + 6 * math.sin(t * 4))],
            ),
          ),
        ),
        at(pres + const Offset(0, -80), 70, 22, const _Chip('الرئيس', size: 12)),
        at(
          glass,
          40,
          64,
          Transform.translate(
            offset: Offset(math.sin(t * 50) * 1.6 * urgent, 0),
            child: Transform.rotate(
              angle: flip * math.pi,
              child: CustomPaint(painter: _Hourglass(t, flip > 0 ? 1 : p, urgent)),
            ),
          ),
        ),
        at(
          glass + const Offset(0, 44),
          44,
          18,
          Opacity(
            opacity: 1 - flip,
            child: Text(
              '${arabicNumber(secs)} ث',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color.lerp(AppColors.goldLight, AppColors.traitorLight, urgent),
              ),
            ),
          ),
        ),
      ],
    ),
    const Offset(215, 220),
    1.9,
    seg(t, .2, 1.0, Curves.easeInOut) * (1 - seg(t, 5.2, 5.95, Curves.easeInOut)),
  );
}

/// ساعة رملية: الرمل ينزل مع [p]، وتحمر وتضوي لما يقرب يخلص.
class _Hourglass extends CustomPainter {
  _Hourglass(this.t, this.p, this.urgent);

  final double t, p, urgent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 40);
    final sand = Color.lerp(const Color(0xFFF2C14E), const Color(0xFFFF5A5A), urgent)!;
    if (urgent > 0) {
      canvas.drawCircle(
        const Offset(20, 32),
        34,
        Paint()
          ..color = const Color(0xFFFF3B3B).withValues(alpha: .35 * urgent * (.6 + .4 * math.sin(t * 10)))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
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
    final glass = Paint()..color = Colors.white.withValues(alpha: .12);
    canvas.drawPath(top, glass);
    canvas.drawPath(bottom, glass);
    final fill = Paint()..color = sand;
    canvas.save();
    canvas.clipPath(top);
    final surface = 9 + 22 * p;
    canvas.drawRect(Rect.fromLTRB(0, surface, 40, 32), fill);
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
        final q = frac(t * 3 + k / 3);
        canvas.drawCircle(Offset(20 + math.sin(k * 2.0) * .6, 32 + q * (24 - h)), .9, fill);
      }
    }
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: .7);
    canvas.drawPath(top, outline);
    canvas.drawPath(bottom, outline);
    final wood = Paint()..color = const Color(0xFF8A5A00);
    canvas.drawRect(const Rect.fromLTWH(4, 7, 2.2, 50), wood);
    canvas.drawRect(const Rect.fromLTWH(33.8, 7, 2.2, 50), wood);
    final cap = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFB87A12)])
          .createShader(const Rect.fromLTWH(0, 0, 40, 64));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(1, 1, 38, 6), const Radius.circular(2)), cap);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(1, 57, 38, 6), const Radius.circular(2)), cap);
  }

  @override
  bool shouldRepaint(_Hourglass old) => true;
}

// ───────── ١٣ المواسم

const _seasonThemes = [SceneTheme.ramadan, SceneTheme.eid, SceneTheme.national];
const _seasonNames = ['رمضان كريم', 'عيدكم مبارك', 'اليوم الوطني'];

Widget _seasons(double t) {
  final i = (t / 3).floor().clamp(0, 2);
  final into = t - i * 3;
  return Stack(
    children: [
      Positioned.fill(child: _season(t, i)),
      if (i > 0 && into < .5)
        Positioned.fill(
          child: Opacity(opacity: 1 - into / .5, child: _season(t, i - 1)),
        ),
    ],
  );
}

Widget _season(double t, int i) => Stack(
  children: [
    Positioned.fill(
      child: MajlisScene(t: t, theme: _seasonThemes[i]),
    ),
    if (i == 1)
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _Confetti(
              t,
              loop: true,
              count: 40,
              speed: .5,
              colors: const [Color(0xFFFFE08A), Color(0xFFF2C14E), Colors.white],
            ),
          ),
        ),
      ),
    if (i == 2)
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _Confetti(t, loop: true, count: 50, speed: .7, colors: const [Color(0xFF16A34A), Colors.white]),
          ),
        ),
      ),
    Positioned(
      top: 108,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xD90B0818),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withValues(alpha: .6)),
          ),
          child: GoldText(_seasonNames[i], size: 26),
        ),
      ),
    ),
  ],
);

// ───────── ١٤ الأزرار

const _pressAt = [.5, 1.6, 2.7];

Widget _buttons(double t) {
  const items = [
    ('العب', [Color(0xFFFFE08A), Color(0xFFF2B53A), Color(0xFFD48B12)], Color(0xFF8E5A07), AppColors.goldInk),
    ('المتجر', [Color(0xFFA48BFF), Color(0xFF7C5CFF), Color(0xFF4B2DC2)], Color(0xFF2A1680), Colors.white),
    ('خروج', [Color(0xFFFF8C98), Color(0xFFE0314B), Color(0xFFA3172D)], Color(0xFF6B0C1C), Colors.white),
  ];
  Offset center(int j) => Offset(400, 150 + j * 92.0);
  final points = [
    const Offset(620, 480),
    for (var j = 0; j < 3; j++) center(j) + const Offset(40, 6),
    const Offset(640, 490),
  ];
  final times = [0.0, ..._pressAt, 3.4];
  var touch = points.last;
  for (var j = 0; j < times.length - 1; j++) {
    final arrive = times[j + 1];
    if (t < arrive) {
      touch = Offset.lerp(
        points[j],
        points[j + 1],
        seg(t, j == 0 ? 0 : times[j] + .45, arrive - .05, Curves.easeInOut),
      )!;
      break;
    }
    if (j == times.length - 2) touch = Offset.lerp(points[j + 1], points.last, seg(t, arrive + .45, arrive + .9))!;
  }
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned.fill(child: MajlisBackdrop(t: t, tray: false)),
      dim(.6),
      for (final (j, (label, colors, edge, fg)) in items.indexed)
        at(center(j), 300, 80, _PressButton(label: label, colors: colors, edge: edge, fg: fg, t: t - _pressAt[j])),
      for (var j = 0; j < 3; j++)
        if (t > _pressAt[j] - .05 && t < _pressAt[j] + .6)
          at(center(j) + const Offset(-210, 0), 70, 80, _Buzz(t: t, p: seg(t, _pressAt[j], _pressAt[j] + .6))),
      if (t < 3.9) at(touch, 60, 60, _Touch(press: [for (final p in _pressAt) bump(t, p, p + .3)].reduce(math.max))),
    ],
  );
}

/// زر بنفس شكل أزرار اللعبة، ينضغط لتحت ويرجع بنطة، وتطلع منه موجة.
class _PressButton extends StatelessWidget {
  const _PressButton({
    required this.label,
    required this.colors,
    required this.edge,
    required this.fg,
    required this.t,
  });

  final String label;
  final List<Color> colors;
  final Color edge, fg;

  /// الوقت من لحظة الضغط (سالب قبلها).
  final double t;

  @override
  Widget build(BuildContext context) {
    final down = seg(t, 0, .07) * (1 - seg(t, .22, .32));
    final spring = math.sin(seg(t, .26, .6) * math.pi) * .04;
    final depth = 6 - 4.5 * down;
    final ripple = seg(t, .03, .55);
    return Center(
      child: Transform.scale(
        scale: 1 - .06 * down + spring,
        child: SizedBox(
          width: 260,
          height: 66,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 6,
                height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: edge,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 6 - depth + 6,
                height: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withValues(alpha: .45), width: 1.5),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (ripple > 0 && ripple < 1)
                          Positioned(
                            left: 170 - 20 - 150 * ripple,
                            top: 30 - 20 - 150 * ripple,
                            child: Container(
                              width: 40 + 300 * ripple,
                              height: 40 + 300 * ripple,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: .4 * (1 - ripple)),
                              ),
                            ),
                          ),
                        Text(
                          label,
                          style: TextStyle(fontFamily: kufi, fontSize: 24, fontWeight: FontWeight.w700, color: fg),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (t > 0 && t < .6) Positioned.fill(child: CustomPaint(painter: _Sparkles(seg(t, 0, .6)))),
            ],
          ),
        ),
      ),
    );
  }
}

/// نجوم صغيرة تطلع من أطراف الزر.
class _Sparkles extends CustomPainter {
  _Sparkles(this.p);

  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var k = 0; k < 10; k++) {
      final a = k / 10 * 2 * math.pi;
      final pos = c + Offset(math.cos(a) * (130 + 40 * p), math.sin(a) * (34 + 26 * p));
      final r = 4 * (1 - p);
      final star = Path();
      for (var j = 0; j < 8; j++) {
        final rr = j.isEven ? r * 2 : r * .6;
        final aa = j / 8 * 2 * math.pi;
        final pt = pos + Offset(math.cos(aa), math.sin(aa)) * rr;
        j == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(star..close(), Paint()..color = AppColors.goldLight.withValues(alpha: 1 - p));
    }
  }

  @override
  bool shouldRepaint(_Sparkles old) => old.p != p;
}

/// جوال يهتز (اهتزاز خفيف مع الضغطة).
class _Buzz extends StatelessWidget {
  const _Buzz({required this.t, required this.p});

  final double t, p;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: math.sin(p * math.pi).clamp(0.0, 1.0),
    child: Column(
      children: [
        Transform.rotate(
          angle: math.sin(t * 90) * .14 * (1 - p),
          child: CustomPaint(size: const Size(60, 50), painter: _Phone()),
        ),
        const Text(
          'اهتزاز',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.muted),
        ),
      ],
    ),
  );
}

class _Phone extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final body = RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 22, height: 38), const Radius.circular(5));
    canvas.drawRRect(body, Paint()..color = const Color(0xFF1F2937));
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.text,
    );
    canvas.drawRect(Rect.fromCenter(center: c, width: 15, height: 26), Paint()..color = const Color(0xFF4B2DC2));
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.goldLight;
    for (final s in [-1.0, 1.0]) {
      for (var k = 0; k < 2; k++) {
        final r = 17.0 + k * 6;
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), s < 0 ? math.pi - .5 : -.5, 1.0, false, wave);
      }
    }
  }

  @override
  bool shouldRepaint(_Phone old) => false;
}
