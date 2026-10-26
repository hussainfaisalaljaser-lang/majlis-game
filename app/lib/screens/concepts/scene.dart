import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/fx.dart';

/// نماذج الشكل الجديد (للمراجعة، مو داخل اللعبة): مشهد مجلس على لوحة ٨٠٠×٤٥٠ تتكبر على الشاشة.

const sceneW = 800.0, sceneH = 450.0;

enum SceneTheme { normal, ramadan, eid, national }

/// لاعب على مسنده.
class SeatInfo {
  const SeatInfo(this.avatar, this.name, {this.traitor = false});

  final String avatar;
  final String name;
  final bool traitor;
}

const demoSeats = [
  SeatInfo('emir', 'أنت'),
  SeatInfo('lady_gold', 'مها', traitor: true),
  SeatInfo('falconer', 'بدر'),
  SeatInfo('wolf', 'تركي', traitor: true),
  SeatInfo('pilot', 'فيصل'),
  SeatInfo('sultana', 'العنود'),
];

/// مكان كل مسند حول الصينية (أنت تحت بالنص).
Offset seatAt(int i, int n) {
  final a = math.pi / 2 + i * 2 * math.pi / n;
  return Offset(400 + math.cos(a) * 285, 300 + math.sin(a) * 98);
}

double frac(double x) => x - x.floorToDouble();

/// موجة ناعمة بين ٠ و١ للوميض.
double flicker(double t, int i, double amount) =>
    1 - amount * (.5 + .25 * math.sin(t * 9.1 + i * 2.3) + .25 * math.sin(t * 23.7 + i * 1.1));

/// خلفية المجلس: جدار بأقواس ونقشة، وفوانيس معلقة، وأرضية وسجادة وصينية عليها دلة وفناجيل، ومبخرة.
class MajlisBackdrop extends StatelessWidget {
  const MajlisBackdrop({
    super.key,
    required this.t,
    this.tension = 0,
    this.theme = SceneTheme.normal,
    this.tray = true,
    this.trayAt = const Offset(400, 308),
  });

  final double t;
  final double tension;
  final SceneTheme theme;
  final bool tray;

  /// نص الصينية.
  final Offset trayAt;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: CustomPaint(painter: _Wall(t, tension, theme))),
      Positioned(
        left: 140,
        top: 222,
        width: 520,
        height: 210,
        child: Image.asset('assets/tables/carpet_majlis.webp', fit: BoxFit.fill),
      ),
      if (tray)
        Positioned.fill(
          child: TrayView(t: t, at: trayAt),
        ),
      Positioned.fill(child: CustomPaint(painter: _Censer(t))),
    ],
  );
}

class _Wall extends CustomPainter {
  _Wall(this.t, this.tension, this.theme);

  final double t, tension;
  final SceneTheme theme;

  static const _walls = {
    SceneTheme.normal: [Color(0xFF1C110B), Color(0xFF3B2416)],
    SceneTheme.ramadan: [Color(0xFF170D2B), Color(0xFF34204F)],
    SceneTheme.eid: [Color(0xFF0B241A), Color(0xFF1C4532)],
    SceneTheme.national: [Color(0xFF082414), Color(0xFF125232)],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / sceneW;
    canvas.scale(s);
    final colors = _walls[theme]!;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, sceneW, 300),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(colors[0], const Color(0xFF1A0505), tension * .6)!,
            Color.lerp(colors[1], const Color(0xFF3A0B0B), tension * .6)!,
          ],
        ).createShader(const Rect.fromLTWH(0, 0, sceneW, 300)),
    );
    // نقشة فوق
    final frieze = Paint()..color = AppColors.gold.withValues(alpha: .35);
    for (var x = 8.0; x < sceneW; x += 22) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 26)
          ..lineTo(x + 7, 19)
          ..lineTo(x + 14, 26)
          ..lineTo(x + 7, 33)
          ..close(),
        frieze,
      );
    }
    canvas.drawLine(const Offset(0, 38), const Offset(sceneW, 38), frieze..strokeWidth = 1.5);
    canvas.drawLine(const Offset(0, 14), const Offset(sceneW, 14), frieze);
    // الأقواس
    for (var i = 0; i < 5; i++) {
      final cx = 80.0 + i * 160;
      final arch = Path()
        ..moveTo(cx - 58, 300)
        ..lineTo(cx - 58, 150)
        ..quadraticBezierTo(cx - 56, 92, cx, 72)
        ..quadraticBezierTo(cx + 56, 92, cx + 58, 150)
        ..lineTo(cx + 58, 300)
        ..close();
      canvas.drawPath(
        arch,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: .45), Colors.black.withValues(alpha: .15)],
          ).createShader(Rect.fromLTWH(cx - 58, 72, 116, 228)),
      );
      if (i == 2) _window(canvas, cx, arch);
      canvas.drawPath(
        arch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = AppColors.gold.withValues(alpha: .45),
      );
    }
    // الأرضية
    canvas.drawRect(
      const Rect.fromLTWH(0, 290, sceneW, 160),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A1A10), Color(0xFF120A06)],
        ).createShader(const Rect.fromLTWH(0, 290, sceneW, 160)),
    );
    // زينة المواسم
    switch (theme) {
      case SceneTheme.ramadan:
        _garland(canvas);
      case SceneTheme.eid:
        _lights(canvas);
      case SceneTheme.national:
        _bunting(canvas);
      case SceneTheme.normal:
        break;
    }
  }

  /// الشباك اللي بالنص: سما ونجوم، وهلال برمضان.
  void _window(Canvas canvas, double cx, Path arch) {
    canvas.save();
    canvas.clipPath(arch);
    canvas.drawRect(
      Rect.fromLTWH(cx - 58, 72, 116, 228),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1030), Color(0xFF2B1F4A)],
        ).createShader(Rect.fromLTWH(cx - 58, 72, 116, 228)),
    );
    for (var k = 0; k < 14; k++) {
      final tw = .4 + .6 * (.5 + .5 * math.sin(t * 2 + k * 1.7));
      canvas.drawCircle(
        Offset(cx - 50 + rnd(k, 1) * 100, 90 + rnd(k, 2) * 150),
        1 + rnd(k, 3),
        Paint()..color = Colors.white.withValues(alpha: tw),
      );
    }
    final moon = Offset(cx + 18, 118);
    canvas.drawCircle(moon, 30, Paint()..color = const Color(0xFFFDE68A).withValues(alpha: .12));
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: moon, radius: 15)),
        Path()..addOval(Rect.fromCircle(center: moon + const Offset(7, -4), radius: 13)),
      ),
      Paint()..color = const Color(0xFFFDE68A),
    );
    canvas.restore();
  }

  /// زينة رمضان: أهلة ونجوم معلقة على حبل.
  void _garland(Canvas canvas) {
    final rope = Path()..moveTo(0, 46);
    for (var x = 0.0; x < sceneW; x += 160) {
      rope.quadraticBezierTo(x + 80, 70, x + 160, 46);
    }
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.gold.withValues(alpha: .75);
    canvas.drawPath(rope, gold);
    final fill = Paint()..color = const Color(0xFFFDE68A);
    for (var k = 0; k < 20; k++) {
      final x = 20.0 + k * 40;
      final u = frac(x / 160);
      final y0 = 46 + 48 * u * (1 - u);
      final tip = Offset(x + math.sin(t * 2 + k) * 1.5, y0 + 10 + (k % 3) * 7);
      canvas.drawLine(Offset(x, y0), tip, gold);
      canvas.drawCircle(tip + const Offset(0, 7), 13, Paint()..color = const Color(0xFFFDE68A).withValues(alpha: .1));
      if (k.isEven) {
        final c = tip + const Offset(0, 7);
        canvas.drawPath(
          Path.combine(
            PathOperation.difference,
            Path()..addOval(Rect.fromCircle(center: c, radius: 6.5)),
            Path()..addOval(Rect.fromCircle(center: c + const Offset(3, -2), radius: 5.5)),
          ),
          fill,
        );
      } else {
        final c = tip + const Offset(0, 6);
        final star = Path();
        for (var j = 0; j < 10; j++) {
          final r = j.isEven ? 6.0 : 2.6;
          final a = -math.pi / 2 + j * math.pi / 5;
          final pt = c + Offset(math.cos(a), math.sin(a)) * r;
          j == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(star..close(), fill);
      }
    }
  }

  /// أضواء العيد على حبل.
  void _lights(Canvas canvas) {
    final path = Path()..moveTo(0, 50);
    for (var x = 0.0; x <= sceneW; x += 100) {
      path.quadraticBezierTo(x + 50, 78, x + 100, 50);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.black54,
    );
    const colors = [Color(0xFFFFD166), Color(0xFF06D6A0), Color(0xFFFF6B6B), Color(0xFF4CC9F0)];
    for (var k = 0; k < 32; k++) {
      final x = k * 25.0 + 12;
      final y = 50 + 28 * math.sin(frac(x / 100) * math.pi) * .98;
      final on = (k + (t * 3).floor()) % 3 != 0;
      final c = colors[k % colors.length];
      if (on) canvas.drawCircle(Offset(x, y + 4), 9, Paint()..color = c.withValues(alpha: .25));
      canvas.drawCircle(Offset(x, y + 4), 3.6, Paint()..color = on ? c : c.withValues(alpha: .35));
    }
  }

  /// أعلام مثلثات خضرا وبيضا.
  void _bunting(Canvas canvas) {
    for (var row = 0; row < 2; row++) {
      final y0 = 46.0 + row * 34;
      for (var k = 0; k < 20; k++) {
        final x = k * 42.0 + row * 21;
        final sway = 2 * math.sin(t * 3 + k + row);
        canvas.drawPath(
          Path()
            ..moveTo(x, y0)
            ..lineTo(x + 32, y0)
            ..lineTo(x + 16 + sway, y0 + 24)
            ..close(),
          Paint()..color = k.isEven ? const Color(0xFF16A34A) : Colors.white,
        );
      }
      canvas.drawLine(
        Offset(0, y0),
        Offset(sceneW, y0),
        Paint()
          ..color = Colors.black45
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(_Wall old) => true;
}

/// الصينية وعليها الدلة والفناجيل والتمر، ونصها على [at].
class TrayView extends StatelessWidget {
  const TrayView({super.key, required this.t, this.at = const Offset(400, 308)});

  final double t;
  final Offset at;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        left: at.dx - 100,
        top: at.dy - 56,
        width: 200,
        height: 112,
        child: Image.asset('assets/tables/tray_majlis.webp', fit: BoxFit.fill),
      ),
      Positioned.fill(child: CustomPaint(painter: _TrayItems(t, at))),
    ],
  );
}

/// الدلة والفناجيل والتمر على الصينية.
class _TrayItems extends CustomPainter {
  _TrayItems(this.t, this.at);

  final double t;
  final Offset at;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / sceneW);
    canvas.translate(at.dx - 400, at.dy - 308);
    const brass = [Color(0xFFFDE68A), Color(0xFFD4A017), Color(0xFF8A5A00)];
    // الدلة
    const d = Offset(372, 298);
    final body = Path()
      ..moveTo(d.dx - 14, d.dy + 22)
      ..quadraticBezierTo(d.dx - 20, d.dy + 4, d.dx - 9, d.dy - 8)
      ..lineTo(d.dx - 7, d.dy - 18)
      ..lineTo(d.dx + 7, d.dy - 18)
      ..lineTo(d.dx + 9, d.dy - 8)
      ..quadraticBezierTo(d.dx + 20, d.dy + 4, d.dx + 14, d.dy + 22)
      ..close();
    canvas.drawPath(
      body,
      Paint()..shader = const LinearGradient(colors: brass).createShader(Rect.fromLTWH(d.dx - 20, d.dy - 20, 40, 44)),
    );
    // المنقار
    canvas.drawPath(
      Path()
        ..moveTo(d.dx - 8, d.dy - 10)
        ..quadraticBezierTo(d.dx - 22, d.dy - 16, d.dx - 30, d.dy - 30)
        ..lineTo(d.dx - 26, d.dy - 31)
        ..quadraticBezierTo(d.dx - 18, d.dy - 20, d.dx - 6, d.dy - 6)
        ..close(),
      Paint()..color = brass[1],
    );
    // الغطا والقبضة
    canvas.drawPath(
      Path()
        ..moveTo(d.dx - 8, d.dy - 18)
        ..quadraticBezierTo(d.dx, d.dy - 34, d.dx + 8, d.dy - 18)
        ..close(),
      Paint()..color = brass[0],
    );
    canvas.drawCircle(Offset(d.dx, d.dy - 31), 2.6, Paint()..color = brass[1]);
    canvas.drawPath(
      Path()
        ..moveTo(d.dx + 9, d.dy - 12)
        ..quadraticBezierTo(d.dx + 26, d.dy - 8, d.dx + 13, d.dy + 14),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = brass[2],
    );
    // بخار خفيف من المنقار
    for (var k = 0; k < 2; k++) {
      final q = frac(t * .5 + k * .5);
      canvas.drawCircle(
        Offset(d.dx - 31 - q * 6, d.dy - 34 - q * 22),
        3 + q * 4,
        Paint()..color = Colors.white.withValues(alpha: .25 * (1 - q)),
      );
    }
    // الفناجيل
    for (final (i, p) in const [Offset(420, 312), Offset(440, 304), Offset(458, 314)].indexed) {
      canvas.drawPath(
        Path()
          ..moveTo(p.dx - 7, p.dy - 6)
          ..lineTo(p.dx + 7, p.dy - 6)
          ..lineTo(p.dx + 5, p.dy + 4)
          ..quadraticBezierTo(p.dx, p.dy + 7, p.dx - 5, p.dy + 4)
          ..close(),
        Paint()..color = const Color(0xFFFFFBF0),
      );
      canvas.drawLine(
        Offset(p.dx - 6, p.dy - 3),
        Offset(p.dx + 6, p.dy - 3),
        Paint()
          ..color = i.isEven ? const Color(0xFF16A34A) : const Color(0xFFB91C1C)
          ..strokeWidth = 1.6,
      );
    }
    // صحن التمر
    canvas.drawOval(Rect.fromCenter(center: const Offset(405, 326), width: 36, height: 13), Paint()..color = brass[1]);
    for (var k = 0; k < 5; k++) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(394 + k * 5.5, 323 - (k % 2) * 2.0), width: 7, height: 4.6),
        Paint()..color = const Color(0xFF5A2E0E),
      );
    }
  }

  @override
  bool shouldRepaint(_TrayItems old) => true;
}

/// المبخرة بالزاوية ودخانها.
class _Censer extends CustomPainter {
  _Censer(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / sceneW);
    const base = Offset(742, 336);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx - 14, base.dy)
        ..lineTo(base.dx + 14, base.dy)
        ..lineTo(base.dx + 8, base.dy - 12)
        ..lineTo(base.dx + 14, base.dy - 26)
        ..lineTo(base.dx - 14, base.dy - 26)
        ..lineTo(base.dx - 8, base.dy - 12)
        ..close(),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFB45309)])
            .createShader(Rect.fromLTWH(base.dx - 14, base.dy - 26, 28, 26)),
    );
    canvas.drawCircle(base + const Offset(0, -28), 5, Paint()..color = const Color(0xFFFF7A1A).withValues(alpha: .8));
    for (var k = 0; k < 3; k++) {
      final q = frac(t * .28 + k / 3);
      final path = Path()..moveTo(base.dx, base.dy - 30);
      for (var j = 1; j <= 6; j++) {
        path.lineTo(base.dx + math.sin(j * 1.2 + t * 1.5 + k * 2) * (5 + j * 2), base.dy - 30 - j * 14 * (.4 + q));
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .16 * (1 - q))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_Censer old) => true;
}

/// الفوانيس المعلقة: ترمش، وتحمر مع التوتر، وبرمضان فوقها هلال.
class Lanterns extends StatelessWidget {
  const Lanterns({super.key, required this.t, this.tension = 0, this.theme = SceneTheme.normal});

  final double t, tension;
  final SceneTheme theme;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _Lanterns(t, tension, theme), size: Size.infinite);
}

class _Lanterns extends CustomPainter {
  _Lanterns(this.t, this.tension, this.theme);

  final double t, tension;
  final SceneTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / sceneW);
    for (final (i, x) in const [120.0, 300.0, 500.0, 680.0].indexed) {
      final light = flicker(t, i, .12 + .55 * tension);
      final warm = Color.lerp(const Color(0xFFFFC857), const Color(0xFFFF3B3B), tension)!;
      final swing = .04 * math.sin(t * 1.3 + i);
      canvas.save();
      canvas.translate(x, 0);
      canvas.rotate(swing);
      canvas.drawLine(
        Offset.zero,
        const Offset(0, 44),
        Paint()
          ..color = const Color(0xFF8A6A2A)
          ..strokeWidth = 1.6,
      );
      canvas.drawCircle(
        const Offset(0, 72),
        90,
        Paint()
          ..shader = RadialGradient(
            colors: [
              warm.withValues(alpha: .38 * light),
              warm.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: const Offset(0, 72), radius: 90)),
      );
      final frame = Paint()..color = const Color(0xFFC9A227);
      if (theme == SceneTheme.ramadan) {
        canvas.drawPath(
          Path.combine(
            PathOperation.difference,
            Path()..addOval(Rect.fromCircle(center: const Offset(0, 36), radius: 7)),
            Path()..addOval(Rect.fromCircle(center: const Offset(3, 34), radius: 6)),
          ),
          frame,
        );
      }
      canvas.drawPath(
        Path()
          ..moveTo(-8, 52)
          ..lineTo(0, 43)
          ..lineTo(8, 52)
          ..close(),
        frame,
      );
      final glass = Rect.fromLTWH(-12, 52, 24, 36);
      canvas.drawRRect(
        RRect.fromRectAndRadius(glass, const Radius.circular(5)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(warm, Colors.white, .5)!.withValues(alpha: light),
              warm.withValues(alpha: light),
            ],
          ).createShader(glass),
      );
      for (final dx in const [-4.0, 4.0]) {
        canvas.drawLine(Offset(dx, 52), Offset(dx, 88), frame..strokeWidth = 1.2);
      }
      canvas.drawRect(const Rect.fromLTWH(-14, 87, 28, 5), frame);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Lanterns old) => true;
}

/// مسند اللاعب وراه، وفانوس صغير جنبه (ينطفي لو انطرد)، وغطا ينزل عليه لو انطرد.
class SeatView extends StatelessWidget {
  const SeatView({super.key, required this.seat, required this.t, this.dead = 0, this.size = 56, this.avatarOverride});

  final SeatInfo seat;
  final double t;

  /// ٠ عايش، ١ مطرود (والغطا نزل كامل).
  final double dead;
  final double size;
  final Widget? avatarOverride;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 96,
    height: 104,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 4,
          child: CustomPaint(size: const Size(80, 58), painter: _Cushion(dead)),
        ),
        Positioned(
          right: -2,
          top: 46,
          child: CustomPaint(size: const Size(16, 30), painter: _SeatLantern(t, (1 - dead * 2.5).clamp(0.0, 1.0))),
        ),
        Positioned(
          top: 18,
          child:
              avatarOverride ??
              ColorFiltered(
                colorFilter: ColorFilter.matrix(greyMatrix((dead * 2).clamp(0.0, 1.0))),
                child: PlayerAvatar(avatar: seat.avatar, size: size),
              ),
        ),
        if (dead > .3)
          Positioned(
            top: 0,
            child: CustomPaint(size: const Size(88, 80), painter: _Cloth((dead - .3) / .7)),
          ),
        Positioned(
          top: 82,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: const Color(0xD90B0818), borderRadius: BorderRadius.circular(8)),
            child: Text(
              seat.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color.lerp(AppColors.text, AppColors.muted, dead),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// يطفي الألوان بقد [k] (٠ ملون، ١ رمادي).
List<double> greyMatrix(double k) {
  const lr = .2126, lg = .7152, lb = .0722;
  final i = 1 - k;
  return [
    i + k * lr, k * lg, k * lb, 0, 0, //
    k * lr, i + k * lg, k * lb, 0, 0,
    k * lr, k * lg, i + k * lb, 0, 0,
    0, 0, 0, 1 - k * .3, 0,
  ];
}

/// مسند أحمر بحافة ذهبية (يرمّد لما [dead] تقرب من ١).
class Cushion extends StatelessWidget {
  const Cushion({super.key, this.dead = 0, this.width = 80, this.height = 58});

  final double dead, width, height;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(width, height), painter: _Cushion(dead));
}

class _Cushion extends CustomPainter {
  _Cushion(this.dead);

  final double dead;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(0, 8, size.width, size.height - 8), const Radius.circular(14));
    final c1 = Color.lerp(const Color(0xFF9F1239), const Color(0xFF3F3F46), dead)!;
    final c2 = Color.lerp(const Color(0xFF4C0519), const Color(0xFF18181B), dead)!;
    canvas.drawRRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c1, c2],
        ).createShader(r.outerRect),
    );
    canvas.drawRRect(
      r.deflate(4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = AppColors.gold.withValues(alpha: .7 * (1 - dead * .7)),
    );
    // اللفة فوق
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(4, 0, size.width - 8, 16), const Radius.circular(8)),
      Paint()..color = Color.lerp(c1, Colors.white, .12)!,
    );
    // الشراريب
    for (final x in [6.0, size.width - 6]) {
      canvas.drawLine(
        Offset(x, 10),
        Offset(x, 22),
        Paint()
          ..color = AppColors.gold
          ..strokeWidth = 2,
      );
      canvas.drawCircle(Offset(x, 23), 2.4, Paint()..color = AppColors.gold);
    }
  }

  @override
  bool shouldRepaint(_Cushion old) => old.dead != dead;
}

/// فانوس واقف على الأرض، ينطفي لما [on] تنزل للصفر.
class FloorLantern extends StatelessWidget {
  const FloorLantern({super.key, required this.t, this.on = 1, this.scale = 1});

  final double t, on, scale;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(16 * scale, 30 * scale), painter: _SeatLantern(t, on, scale));
}

class _SeatLantern extends CustomPainter {
  _SeatLantern(this.t, this.on, [this.scale = 1]);

  final double t, on, scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    final c = Offset(size.width / scale / 2, size.height / scale / 2 + 2);
    final light = on * flicker(t, 7, .15);
    if (light > 0) {
      canvas.drawCircle(
        c,
        22,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFC857).withValues(alpha: .45 * light),
              const Color(0x00FFC857),
            ],
          ).createShader(Rect.fromCircle(center: c, radius: 22)),
      );
    }
    final glass = Rect.fromCenter(center: c, width: 10, height: 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(glass, const Radius.circular(3)),
      Paint()..color = Color.lerp(const Color(0xFF3B2A1A), const Color(0xFFFFD27A), light)!,
    );
    final frame = Paint()..color = const Color(0xFFC9A227);
    canvas.drawRect(Rect.fromLTWH(c.dx - 6, c.dy - 9, 12, 2.4), frame);
    canvas.drawRect(Rect.fromLTWH(c.dx - 6, c.dy + 7, 12, 2.4), frame);
    canvas.drawLine(Offset(c.dx, c.dy - 9), Offset(c.dx, c.dy - 13), frame..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(_SeatLantern old) => true;
}

/// غطا رمادي يطيح من فوق على مسند المطرود.
class _Cloth extends CustomPainter {
  _Cloth(this.k);

  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    final e = Curves.easeOutCubic.transform(k.clamp(0.0, 1.0));
    final a = (k * 4).clamp(0.0, 1.0);
    final w = size.width, h = size.height;
    canvas.translate(0, -46 * (1 - e));
    final sway = math.sin(k * math.pi) * 4;
    final sheet = Path()
      ..moveTo(w * .5, 4)
      ..cubicTo(w * .8, 4, w * .84, h * .3, w * .86 + sway, h * .55)
      ..quadraticBezierTo(w * .98, h * .8, w, h * .96)
      ..quadraticBezierTo(w * .86, h * .9, w * .74, h * .98)
      ..quadraticBezierTo(w * .62, h * .9, w * .5, h)
      ..quadraticBezierTo(w * .38, h * .9, w * .26, h * .98)
      ..quadraticBezierTo(w * .14, h * .9, 0, h * .96)
      ..quadraticBezierTo(w * .02, h * .8, w * .14 - sway, h * .55)
      ..cubicTo(w * .16, h * .3, w * .2, 4, w * .5, 4)
      ..close();
    canvas.drawPath(
      sheet,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF3F3F46).withValues(alpha: a),
            const Color(0xFF8A8A94).withValues(alpha: a),
            const Color(0xFF5B5B64).withValues(alpha: a),
            const Color(0xFF34343B).withValues(alpha: a),
          ],
          stops: const [0, .38, .62, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    final fold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Colors.black.withValues(alpha: .28 * a);
    for (final x in [.28, .42, .58, .72]) {
      canvas.drawLine(Offset(w * (.5 + (x - .5) * .4), h * .3), Offset(w * x, h * .93), fold);
    }
    canvas.drawOval(
      Rect.fromLTWH(w * .3, 9, w * .26, h * .16),
      Paint()..color = Colors.white.withValues(alpha: .14 * a),
    );
  }

  @override
  bool shouldRepaint(_Cloth old) => old.k != k;
}

/// يغمق الأطراف ويحمرها مع التوتر، ونبض قلب لما يقرب الخطر.
class TensionOverlay extends StatelessWidget {
  const TensionOverlay({super.key, required this.t, required this.tension});

  final double t, tension;

  @override
  Widget build(BuildContext context) {
    final beat = tension > .75 ? _beat(t) * (tension - .75) / .25 : 0.0;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: const Color(0xFF7F1D1D).withValues(alpha: .18 * tension)),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.0 - .15 * beat,
                  colors: [
                    Colors.transparent,
                    Color.lerp(
                      Colors.black,
                      const Color(0xFF450A0A),
                      tension,
                    )!.withValues(alpha: .25 + .5 * tension + .2 * beat),
                  ],
                  stops: const [.55, 1],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// دقتين ورا بعض كل ٠٫٩ ثانية.
  static double _beat(double t) {
    final q = frac(t / .9);
    double hump(double c) => math.max(0, 1 - ((q - c) / .06).abs());
    return math.max(hump(.08), hump(.26) * .7);
  }
}

/// المجلس كامل: الخلفية والفوانيس واللاعبين على مساندهم، وفوقهم أي شي ثاني.
class MajlisScene extends StatelessWidget {
  const MajlisScene({
    super.key,
    required this.t,
    this.tension = 0,
    this.theme = SceneTheme.normal,
    this.dead = const {},
    this.seats = demoSeats,
    this.seatOverride,
    this.over = const [],
  });

  final double t, tension;
  final SceneTheme theme;

  /// [dead][رقم المسند] = قد إيش انطرد (٠–١).
  final Map<int, double> dead;
  final List<SeatInfo> seats;
  final Widget? Function(int i)? seatOverride;
  final List<Widget> over;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned.fill(
        child: MajlisBackdrop(t: t, tension: tension, theme: theme),
      ),
      Positioned.fill(
        child: Lanterns(t: t, tension: tension, theme: theme),
      ),
      for (final (i, s) in seats.indexed)
        Positioned(
          left: seatAt(i, seats.length).dx - 48,
          top: seatAt(i, seats.length).dy - 66,
          child: SeatView(seat: s, t: t, dead: dead[i] ?? 0, avatarOverride: seatOverride?.call(i)),
        ),
      if (tension > 0)
        Positioned.fill(
          child: TensionOverlay(t: t, tension: tension),
        ),
      ...over,
    ],
  );
}
