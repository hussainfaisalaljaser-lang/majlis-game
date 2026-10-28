import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/room.dart';
import '../../services/sfx.dart';
import '../../theme.dart';
import '../common.dart';
import '../ui.dart';

const roleInfo = {
  Role.loyal: ('وفي', 'اكشف الخونة ومرّر ٥ قرارات زرقاء', AppColors.loyal, AppColors.loyalDark),
  Role.traitor: ('خائن', 'ساعد زعيمك يوصل للحكم بدون ما تنكشف', AppColors.traitor, AppColors.traitorDark),
  Role.leader: ('زعيم الخونة', 'خلّهم يثقون فيك وينتخبونك وزير', AppColors.traitor, AppColors.traitorDark),
};

/// ليش انتهت اللعبة (engine → WinReason).
const winReasons = {
  'loyalPolicies': 'تمررت ٥ قرارات للأوفياء',
  'traitorPolicies': 'تمررت ٦ قرارات للخونة',
  'leaderElected': 'الزعيم انتُخب وزير',
  'leaderExecuted': 'الزعيم انطرد',
};

const specialInfo = {
  Special.seer: ('العرّاف', 'مرة وحدة في اللعبة تقدر تكشف فريق أي لاعب. اختر الوقت الصح، ولا تنكشف!', 'seer'),
  Special.guardian: ('الحارس', 'لو أحد حاول يطردك، تنجو مرة وحدة ويبان للكل إنك حارس', 'shield'),
  Special.judge: (
    'القاضي',
    'مرة وحدة باللعبة تقدر تلغي تصويت: الحكومة تسقط مهما كانت الأصوات، والكل يعرف إنك القاضي',
    'scales',
  ),
  Special.elder: ('الشيخ', 'صوتك بصوتين في كل تصويت، والكل يعرف إنك الشيخ من أول تصويت', 'ballot'),
  Special.spy: ('الجاسوس', 'مرة وحدة باللعبة، في أي وقت، تشوف أول كرت بالكومة (لك بس)', 'eye'),
};

/// كشف الدور: بطاقة مقلوبة تنقلب وتطلع دورك.
Future<void> showRoleReveal(BuildContext context, GameView view, Room? room) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: .85),
    pageBuilder: (context, _, _) => _RoleReveal(view: view, room: room),
  );
}

class _RoleReveal extends StatefulWidget {
  const _RoleReveal({required this.view, required this.room});

  final GameView view;
  final Room? room;

  @override
  State<_RoleReveal> createState() => _RoleRevealState();
}

class _RoleRevealState extends State<_RoleReveal> with TickerProviderStateMixin {
  late final _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  /// لمعة تمر على البطاقة بعد ما تنقلب.
  late final _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void initState() {
    super.initState();
    // البطاقة تنقلب على طول (ما تنتظر الترحيب)، وجملة الدور تنتظر دورها عند الراوي بعده.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _flip.forward().then((_) {
        if (!mounted) return;
        _shine.forward();
        Sfx.say(switch (widget.view.yourRole) {
          Role.loyal => 'role_loyal',
          Role.traitor => 'role_traitor',
          Role.leader => 'role_leader',
        });
      });
    });
  }

  @override
  void dispose() {
    _flip.dispose();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.view;
    final (name, goal, color, dark) = roleInfo[v.yourRole]!;
    final mates = v.players.where((p) => p.id != v.you && p.knownRole != null && p.id != v.seerSees).toList();
    final special = v.yourSpecial;
    final seerTarget = v.seerSees == null ? null : v.player(v.seerSees!);
    // البطاقة على قد الشاشة (بالعرض الطول قليل).
    final cardH = (MediaQuery.sizeOf(context).height - 130).clamp(200.0, 290.0);
    final cardW = cardH * .69;

    final front = AnimatedBuilder(
      animation: _shine,
      builder: (context, _) => _RoleCard(
        role: v.yourRole,
        name: name,
        color: color,
        dark: dark,
        special: special,
        width: cardW,
        height: cardH,
        shine: _shine.value,
      ),
    );

    // اللي لازم تعرفه: هدفك، وقدرتك الخاصة، والخونة اللي تعرفهم.
    final info = Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8EBD0), AppColors.parchmentDark],
        ),
        border: Border.all(color: AppColors.goldDark, width: 3),
        boxShadow: [BoxShadow(color: color.withValues(alpha: .4), blurRadius: 30)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            goal,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: kufi, color: dark, fontSize: 16, height: 1.5, fontWeight: FontWeight.w700),
          ),
          if (special != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Gfx(specialInfo[special]!.$3, size: 22),
                  const SizedBox(width: 5),
                  Text(
                    specialInfo[special]!.$1,
                    style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              specialInfo[special]!.$2,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.ink, fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w700),
            ),
          ],
          // الجاسوس: اللي شافه بالكومة.
          if (v.spySaw case final saw?) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Seal(loyal: saw.card == Policy.loyal, size: 26),
                const SizedBox(width: 6),
                Text(
                  'شفت بالجولة ${arabicNumber(saw.round)}: أول كرت ${saw.card == Policy.loyal ? 'أزرق' : 'أحمر'}',
                  style: const TextStyle(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
          if (seerTarget != null || mates.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                if (seerTarget != null)
                  _Known(room: widget.room, player: seerTarget, label: 'خائن: ${seerTarget.name}'),
                for (final m in mates)
                  _Known(
                    room: widget.room,
                    player: m,
                    label: '${m.knownRole == Role.leader ? 'الزعيم' : 'خائن'}: ${m.name}',
                    leader: m.knownRole == Role.leader,
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'غطِّ الشاشة!',
              style: TextStyle(fontFamily: kufi, color: AppColors.goldLight, fontSize: 16, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _flip,
              builder: (context, _) {
                final t = Curves.easeInOutBack.transform(_flip.value);
                final angle = t * math.pi;
                final showFront = angle > math.pi / 2;
                // ترتفع شوي وهي تنقلب، والمعلومات تطلع جنبها بعد ما تنقلب.
                final lift = math.sin(_flip.value * math.pi) * 18;
                final shown = Curves.easeOut.transform(((_flip.value - .7) / .3).clamp(0.0, 1.0));
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.translate(
                      offset: Offset(0, -lift),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, .0012)
                          ..rotateY(angle),
                        child: showFront
                            ? Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(math.pi),
                                child: front,
                              )
                            : _RoleBack(width: cardW, height: cardH),
                      ),
                    ),
                    SizedBox(width: 18 * shown),
                    ClipRect(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: shown,
                        child: Opacity(opacity: shown, child: info),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 300,
              child: AnimatedBuilder(
                animation: _flip,
                builder: (context, _) => GameButton(
                  label: 'فهمت',
                  semantics: 'فهمت',
                  tone: v.yourRole == Role.loyal ? ButtonTone.purple : ButtonTone.red,
                  height: 48,
                  onPressed: _flip.isCompleted ? () => Navigator.pop(context) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// وجه بطاقة الدور: رسمة الدور (درع للوفي، خنجر للخائن، عقرب للزعيم) خلف قوس المجلس، واسمه تحتها.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.name,
    required this.color,
    required this.dark,
    required this.special,
    required this.width,
    required this.height,
    required this.shine,
  });

  final Role role;
  final String name;
  final Color color, dark;
  final Special? special;
  final double width, height, shine;

  @override
  Widget build(BuildContext context) {
    final s = height / 290;
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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18 * s),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8EBD0), AppColors.parchmentDark],
        ),
        border: Border.all(color: AppColors.goldDark, width: 3),
        boxShadow: [
          BoxShadow(color: dark, spreadRadius: 3),
          BoxShadow(color: color.withValues(alpha: .55), blurRadius: 40, spreadRadius: 4),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15 * s),
        child: Stack(
          children: [
            Positioned(
              left: 10 * s,
              right: 10 * s,
              top: 10 * s,
              height: 180 * s,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12 * s),
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
                    Positioned.fill(child: CustomPaint(painter: _ArtBack())),
                    Positioned(
                      bottom: 22 * s,
                      child: Container(
                        width: 96 * s,
                        height: 16 * s,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: Colors.black.withValues(alpha: .35),
                        ),
                      ),
                    ),
                    Image.asset('assets/icons/gfx_card_$icon.png', width: 116 * s, height: 116 * s),
                    if (special != null)
                      Positioned(
                        top: 6 * s,
                        right: 6 * s,
                        child: Container(
                          padding: EdgeInsets.all(4 * s),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xCC0B0818),
                            border: Border.all(color: AppColors.gold, width: 1.5),
                          ),
                          child: Gfx(specialInfo[special]!.$3, size: 26 * s),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 196 * s,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: kufi,
                  fontSize: (role == Role.leader ? 27 : 34) * s,
                  fontWeight: FontWeight.w700,
                  color: dark,
                ),
              ),
            ),
            if (special != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12 * s,
                child: Text(
                  specialInfo[special]!.$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kufi,
                    fontSize: 15 * s,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
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

/// ظهر بطاقة الدور: بنفسجي بنقشة ذهبية، وشعار اللعبة.
class _RoleBack extends StatelessWidget {
  const _RoleBack({required this.width, required this.height});

  final double width, height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
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
                child: Image.asset('assets/logo.png', width: width * .48, height: width * .48),
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

/// نقشة ذهبية متقاطعة على ظهر البطاقة.
class _Lattice extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final inner = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)).deflate(9);
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

/// أشعة وقوس مجلس خلف رمز الدور.
class _ArtBack extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final c = Offset(w / 2, h * .45);
    final ray = Paint()..color = Colors.white.withValues(alpha: .1);
    for (var k = 0; k < 16; k++) {
      final a = k / 16 * 2 * math.pi;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + math.cos(a - .09) * 300, c.dy + math.sin(a - .09) * 300)
          ..lineTo(c.dx + math.cos(a + .09) * 300, c.dy + math.sin(a + .09) * 300)
          ..close(),
        ray,
      );
    }
    final inner = Path()
      ..moveTo(w * .18, h)
      ..lineTo(w * .18, h * .5)
      ..quadraticBezierTo(w * .2, h * .14, w * .5, h * .06)
      ..quadraticBezierTo(w * .8, h * .14, w * .82, h * .5)
      ..lineTo(w * .82, h);
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path.from(inner)..close()),
      Paint()..color = Colors.black.withValues(alpha: .35),
    );
    canvas.drawPath(
      inner,
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
  bool shouldRepaint(_Corners old) => old.color != color;
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

class _Known extends StatelessWidget {
  const _Known({required this.room, required this.player, required this.label, this.leader = false});

  final Room? room;
  final ViewPlayer player;
  final String label;
  final bool leader;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      PlayerAvatar(avatar: room?.player(player.id)?.avatar ?? 'masked', frame: AppColors.traitor, size: 40),
      const SizedBox(height: 3),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leader ? const LeaderSeal(size: 20) : const Seal(loyal: false, size: 18),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ],
  );
}
