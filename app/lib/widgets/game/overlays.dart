import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/room.dart';
import '../../services/sfx.dart';
import '../../services/sounds.dart';
import '../../theme.dart';
import '../common.dart';
import '../design.dart';
import '../design_game.dart';
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

/// كشف الدور: بطاقة مقلوبة تنقلب وتطلع دورك (رق بدرع ذهبي وشريط أحمر، وأشعة شمس خلفها).
Future<void> showRoleReveal(BuildContext context, GameView view, Room? room) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: .74),
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
      Sounds.play('flip');
      _flip.forward().then((_) {
        if (!mounted) return;
        _shine.forward();
        // ضربة الدور: خائن غامقة، وفي دافية، وزعيم بالنفير
        Sounds.play(switch (widget.view.yourRole) {
          Role.loyal => 'sting_loyal',
          Role.traitor => 'sting_traitor',
          Role.leader => 'sting_leader',
        });
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
    // ربعك الخونة (والزعيم): آخر اللعبة كل الأدوار تنكشف، فالأوفياء ما يدخلون هنا.
    final mates = v.players
        .where((p) => p.id != v.you && p.knownRole != null && p.knownRole != Role.loyal && p.id != v.seerSees)
        .toList()
      // الزعيم أول (فوق)، وبعده الخونة
      ..sort((a, b) => (b.knownRole == Role.leader ? 1 : 0) - (a.knownRole == Role.leader ? 1 : 0));
    final special = v.yourSpecial;
    final seerTarget = v.seerSees == null ? null : v.player(v.seerSees!);
    final hasExtra = special != null || v.spySaw != null || seerTarget != null || mates.isNotEmpty;

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final st = Stage(box.biggest);
            final s = st.s;
            final cardW = 375 * s, cardH = 520 * s;
            final c = st.at(960, 485);
            Widget at(Offset p, Widget child) => Positioned(
              left: p.dx,
              top: p.dy,
              child: FractionalTranslation(translation: const Offset(-.5, -.5), child: child),
            );
            return AnimatedBuilder(
              animation: _flip,
              builder: (context, _) {
                final shown = Curves.easeOut.transform(((_flip.value - .7) / .3).clamp(0.0, 1.0));
                final t = Curves.easeInOutBack.transform(_flip.value);
                final angle = t * math.pi;
                final showFront = angle > math.pi / 2;
                // ترتفع شوي وهي تنقلب، والمعلومات تطلع جنبها بعد ما تنقلب.
                final lift = math.sin(_flip.value * math.pi) * 18 * s;
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
                final extraW = math.max(210.0, 330 * s);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: .35 + .65 * shown,
                        child: Transform.translate(
                          offset: Offset(0, c.dy - box.maxHeight / 2),
                          child: const SunRays(opacity: .11),
                        ),
                      ),
                    ),
                    // توهج بلون الدور ينطلق من البطاقة لحظة ما تنقلب ويخفت
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _shine,
                          builder: (context, _) {
                            final burst = _shine.value == 0
                                ? 0.0
                                : 1 - Curves.easeOut.transform((_shine.value / .8).clamp(0.0, 1.0));
                            if (burst <= 0) return const SizedBox.shrink();
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment((c.dx / box.maxWidth) * 2 - 1, (c.dy / box.maxHeight) * 2 - 1),
                                  radius: .35 + .75 * (1 - burst),
                                  colors: [
                                    color.withValues(alpha: .55 * burst),
                                    color.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    at(st.at(960, 112), GoldTitle('دورك سري… غطّ الشاشة!', size: gameFont(52, s, min: 18))),
                    at(
                      c.translate(0, -lift),
                      Transform(
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
                    // هدفك على لوح، ومعلوماتك الخاصة (قدرتك، خونتك) على رق جنب البطاقة
                    at(
                      st.at(960, 822),
                      Opacity(
                        opacity: shown,
                        child: SizedBox(
                          width: math.max(560 * s, 300),
                          child: GamePlank(
                            radius: 14,
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: math.max(4, 14 * s)),
                            child: Text(
                              goal,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: kufi,
                                color: const Color(0xFFFFF6E6),
                                fontSize: gameFont(36, s, min: 13),
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (hasExtra)
                      Positioned(
                        left: math.max(8, c.dx - cardW / 2 - 18 - extraW),
                        top: c.dy - cardH / 2,
                        width: extraW,
                        height: cardH,
                        child: Opacity(
                          opacity: shown,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topRight,
                            child: SizedBox(
                              width: extraW,
                              child: _RoleExtra(
                                view: v,
                                room: widget.room,
                                special: special,
                                seerTarget: seerTarget,
                                mates: mates,
                              ),
                            ),
                          ),
                        ),
                      ),
                    at(
                      st.at(960, 958),
                      SizedBox(
                        width: math.max(325 * s, 150),
                        child: GameButton(
                          label: 'فهمت',
                          semantics: 'فهمت',
                          tone: ButtonTone.green,
                          height: math.max(42, 100 * s),
                          fontSize: gameFont(42, s, min: 17),
                          onPressed: _flip.isCompleted ? () => Navigator.pop(context) : null,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// معلوماتك الخاصة جنب البطاقة: قدرتك، وكرت الجاسوس، والخونة اللي تعرفهم.
class _RoleExtra extends StatelessWidget {
  const _RoleExtra({
    required this.view,
    required this.room,
    required this.special,
    required this.seerTarget,
    required this.mates,
  });

  final GameView view;
  final Room? room;
  final Special? special;
  final ViewPlayer? seerTarget;
  final List<ViewPlayer> mates;

  @override
  Widget build(BuildContext context) {
    final v = view;
    return ParchmentCard(
      radius: 14,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (special != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF3A2314),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFFD9A84E), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Gfx(specialInfo[special]!.$3, size: 22),
                  const SizedBox(width: 5),
                  Text(
                    specialInfo[special]!.$1,
                    style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, color: Color(0xFFFFF3DA)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              specialInfo[special]!.$2,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.ink, fontSize: 13, height: 1.5, fontWeight: FontWeight.w800),
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
                Flexible(
                  child: Text(
                    'شفت بالجولة ${arabicNumber(saw.round)}: أول كرت ${saw.card == Policy.loyal ? 'أزرق' : 'أحمر'}',
                    style: const TextStyle(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
          if (seerTarget != null || mates.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                if (seerTarget != null) _Known(room: room, player: seerTarget!, label: 'خائن: ${seerTarget!.name}'),
                for (final m in mates)
                  _Known(
                    room: room,
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
  }
}

/// وجه بطاقة الدور: رق قديم بإطار ذهبي رفيع، وشريط «دورك» فوق، والختم الشمعي نفسه اللي في سجل اللعبة
/// (درع الأوفياء، خنجر الخونة، وخنجر الزعيم بتاجه)، والاسم تحته.
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
    final s = height / 520;
    final nameColor = role == Role.loyal ? const Color(0xFF2F62B5) : const Color(0xFFC6322A);
    final nameEdge = role == Role.loyal ? const Color(0xFF10264C) : const Color(0xFF4A0C0A);
    final sealSize = 258 * s;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ParchmentCard(
              radius: 24 * s,
              padding: EdgeInsets.zero,
              child: Stack(
                children: [
                  // إطار ذهبي رفيع
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(12 * s),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14 * s),
                          border: Border.all(
                            color: const Color(0xFFD9A84E).withValues(alpha: .8),
                            width: math.max(1.5, 3 * s),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // الختم الشمعي: نفس ختم سجل اللعبة (للزعيم: ختم الخنجر وفوقه التاج)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 86 * s,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: .22), blurRadius: 14 * s, offset: Offset(0, 8 * s)),
                          ],
                        ),
                        child: role == Role.leader
                            ? LeaderSeal(size: sealSize)
                            : Seal(loyal: role == Role.loyal, size: sealSize),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: (special != null ? 342 : 352) * s,
                    child: Center(
                      child: OutlinedText(
                        name,
                        size: (role == Role.leader ? 64 : special != null ? 78 : 92) * s,
                        color: nameColor,
                        stroke: nameEdge,
                        strokeWidth: math.max(3, 8 * s),
                        shadow: false,
                      ),
                    ),
                  ),
                  // قدرتك (الطور المطوّر): كبسولة وحدة تحت الاسم بأيقونتها
                  if (special != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 24 * s,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 3 * s),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A2314),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: const Color(0xFFD9A84E), width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Gfx(specialInfo[special]!.$3, size: math.max(18, 30 * s)),
                              SizedBox(width: 6 * s),
                              Text(
                                specialInfo[special]!.$1,
                                style: TextStyle(
                                  fontFamily: kufi,
                                  fontSize: math.max(12, 26 * s),
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFFF3DA),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (shine > 0 && shine < 1)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20 * s),
                        child: CustomPaint(painter: _ShinePainter(shine)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // شريط «دورك» جوا البطاقة بأعلاها، بنص عرضها
          Positioned(
            left: 22 * s,
            right: 22 * s,
            top: 16 * s,
            child: Center(child: RibbonTitle('دورك', size: math.max(14, 30 * s))),
          ),
        ],
      ),
    );
  }
}

/// ظهر بطاقة الدور: مخمل أحمر بحد ذهبي، وشعار اللعبة.
class _RoleBack extends StatelessWidget {
  const _RoleBack({required this.width, required this.height});

  final double width, height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: VelvetPanel(
      radius: 22 * height / 520,
      corners: false,
      padding: EdgeInsets.zero,
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
                GoldTitle('دورك السري', size: math.max(14, width * .12)),
              ],
            ),
          ),
        ],
      ),
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
      TableAvatar(avatar: room?.player(player.id)?.avatar ?? 'masked', ring: AppColors.traitor, size: 46),
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
