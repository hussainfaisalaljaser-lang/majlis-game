import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/game_view.dart';
import '../../models/room.dart';
import '../../models/shop.dart';
import '../../services/backend.dart';
import '../../services/links.dart';
import '../../theme.dart';
import '../common.dart';
import '../design.dart';
import '../design_game.dart';
import '../ui.dart';
import 'overlays.dart';

/// صورة تنشرها بعد اللعبة: دورك ونتيجتك وكم مرة كذبت، ومين فزت عليهم، ورمزك عشان أصحابك يلقونك.
/// تطلع معاينة، وزر «شارك» يفتح قائمة المشاركة في الجوال (واتساب، سناب، انستقرام…).
Future<void> showShareCard(BuildContext context, GameView view, Room? room) => showDialog<void>(
  context: context,
  barrierColor: Colors.black.withValues(alpha: .8),
  builder: (context) => _ShareDialog(view: view, room: room),
);

/// جملة الصورة حسب دورك ونتيجتك.
String shareHeadline(GameView v) {
  final loyalWon = v.winnerLoyal ?? false;
  final iWon = (v.yourRole == Role.loyal) == loyalWon;
  final executed = !v.me.alive;
  return switch (v.yourRole) {
    Role.leader when iWon => executed ? 'انطردت لكن فريقي فاز!' : 'كنت الزعيم ومحد كشفني!',
    Role.leader => v.winReason == 'leaderExecuted' ? 'انكشفت وانطردت!' : 'كنت الزعيم وخسرنا…',
    Role.traitor when iWon => 'خنتهم كلهم وفزنا!',
    Role.traitor => 'انكشفنا هالمرة…',
    Role.loyal when iWon => 'كشفنا الخونة وفزنا!',
    Role.loyal => 'الخونة غلبونا هالمرة…',
  };
}

class _ShareDialog extends StatefulWidget {
  const _ShareDialog({required this.view, required this.room});

  final GameView view;
  final Room? room;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  final _key = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      // ٣٦٠ × ٣ = صورة ١٠٨٠ مربعة، تنفع لكل التطبيقات.
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final pid = Backend.instance.profile.value.pid;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes.buffer.asUint8List(), mimeType: 'image/png', name: 'majlis.png')],
          text: 'تحداني في مجلس الخونة${pid.isEmpty ? '' : ' (رمزي $pid)'}: https://${Links.host}',
        ),
      );
    } catch (e) {
      debugPrint('share failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('ما قدرنا نجهز الصورة، جرّب مرة ثانية')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final preview = (h - 70).clamp(180.0, 300.0);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(12),
      // لوح الخشب يرسمه التصميم، والمعاينة جواه (والصورة المصدّرة هي ShareCard نفسها)
      child: WoodPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // المعاينة بإطار ذهبي (مثل صورة معلقة)، والصورة المصدّرة هي ShareCard بدون الإطار
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: gameInk,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: .55), blurRadius: 12, offset: const Offset(0, 5)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: goldRingColors,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: SizedBox(
                        width: preview,
                        height: preview,
                        child: FittedBox(
                          child: RepaintBoundary(
                            key: _key,
                            child: ShareCard(view: widget.view, room: widget.room),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GoldTitle('شارك نتيجتك', size: 23),
                  const SizedBox(height: 6),
                  const Text(
                    'الصورة فيها رمزك، فأي واحد يشوفها يستطيع أن يضيفك ويتحداك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFE7CFA6),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GameButton(
                    label: _busy ? 'لحظة…' : 'شارك',
                    tone: ButtonTone.green,
                    icon: const Gfx('link', size: 24),
                    height: 48,
                    fontSize: 17,
                    onPressed: _busy ? null : _share,
                  ),
                  const SizedBox(height: 8),
                  GameButton(
                    label: 'لاحقاً',
                    tone: ButtonTone.ghost,
                    height: 40,
                    fontSize: 15,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// الصورة نفسها (٣٦٠ × ٣٦٠، وتنحفظ بثلاث أضعاف): ملصق مخمل وذهب على خشب، وشرائط رق.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.view, required this.room});

  final GameView view;
  final Room? room;

  @override
  Widget build(BuildContext context) {
    final v = view;
    final p = Backend.instance.profile.value;
    final loyalWon = v.winnerLoyal ?? false;
    final iWon = (v.yourRole == Role.loyal) == loyalWon;
    final (roleName, _, _, _) = roleInfo[v.yourRole]!;
    final lies = [
      for (final g in v.governments) ...[
        if (g.president == v.you) g.presidentLied,
        if (g.chancellor == v.you) g.chancellorLied,
      ],
    ].whereType<bool>();
    final lied = lies.where((l) => l).length;
    final rounds = v.governments.length;
    // الفريق الثاني (الأدوار تنكشف بعد اللعبة): فزت عليهم، أو غلبوك.
    final loyal = v.yourRole == Role.loyal;
    final rivals = [
      for (final pl in v.players)
        if (pl.id != v.you && pl.knownRole != null && (pl.knownRole == Role.loyal) != loyal) pl,
    ].take(6).toList();
    return SizedBox(
      width: 360,
      height: 360,
      child: Stack(
        children: [
          // خشب غامق وتحته ضو ذهبي خفيف
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.bg,
                image: DecorationImage(image: AssetImage(DesignAssets.woodWall), fit: BoxFit.cover),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(9),
            child: VelvetPanel(
              radius: 20,
              corners: false,
              padding: EdgeInsets.zero,
              child: Stack(
                children: [
                  // أشعة خفيفة ورا الصورة
                  Positioned(
                    left: -70,
                    right: -70,
                    top: -110,
                    height: 400,
                    child: CustomPaint(
                      painter: const SunRaysPainter(color: Color(0xFFFFE9A8), rays: 16, opacity: .09, turn: .2),
                    ),
                  ),
                  for (final (left, top) in const [(true, true), (false, true), (true, false), (false, false)])
                    Positioned(
                      left: left ? 0 : null,
                      right: left ? null : 0,
                      top: top ? 0 : null,
                      bottom: top ? null : 0,
                      child: Transform.scale(
                        scaleX: left ? 1 : -1,
                        scaleY: top ? -1 : 1,
                        child: Image.asset(DesignAssets.velvetCorner, width: 40, height: 40, fit: BoxFit.fill),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset('assets/logo.png', width: 28, height: 28),
                            ),
                            const SizedBox(width: 7),
                            const GoldTitle('مجلس الخونة', size: 18),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            GoldRingAvatar(avatar: p.avatar, style: frameStyle(p.frame), size: 70, animate: false),
                            Positioned(
                              bottom: -6,
                              right: -10,
                              child: v.yourRole == Role.leader
                                  ? const LeaderSeal(size: 40)
                                  : Seal(loyal: v.yourRole == Role.loyal, size: 36),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        FittedBox(fit: BoxFit.scaleDown, child: GoldTitle(shareHeadline(v), size: 25)),
                        const SizedBox(height: 3),
                        NamePill(
                          '${p.name} · $roleName',
                          size: 13,
                          color: loyal ? AppColors.loyalLight : AppColors.traitorLight,
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _chip(iWon ? 'فزت' : 'خسرت', iWon ? const Color(0xFF1F6B2A) : const Color(0xFFA3261C)),
                            _chip('${arabicNumber(rounds)} ${rounds == 1 ? 'قرار' : 'قرارات'}', AppColors.ink),
                            if (lies.isNotEmpty)
                              _chip(
                                lied == 0
                                    ? 'ما كذبت ولا مرة'
                                    : 'كذبت ${arabicNumber(lied)} ${lied == 1 ? 'مرة' : 'مرات'}',
                                lied == 0 ? const Color(0xFF1F6B2A) : const Color(0xFFB4560A),
                              ),
                          ],
                        ),
                        if (rivals.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          OutlinedText(
                            iWon ? 'فزت على' : 'غلبوني',
                            size: 12.5,
                            color: iWon ? const Color(0xFF8EE4AB) : AppColors.traitorLight,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final r in rivals)
                                SizedBox(
                                  width: 50,
                                  child: Column(
                                    children: [
                                      TableAvatar(
                                        avatar: room?.player(r.id)?.avatar ?? 'masked',
                                        ring: r.knownRole == Role.loyal ? AppColors.loyal : AppColors.traitor,
                                        size: 34,
                                        animate: false,
                                      ),
                                      NamePill(room?.player(r.id)?.name ?? r.name, size: 9.5),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const Spacer(),
                        // شريط رق تحت: رمزك والرابط
                        _Strip(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.pid.isEmpty ? 'حمّل اللعبة وتحداني' : 'حمّل اللعبة وتحداني · رمزي ${p.pid}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  height: 1.25,
                                ),
                              ),
                              const Text(
                                Links.host,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF7A5A3A),
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// شريحة رق بحبر بلون النتيجة.
  Widget _chip(String text, Color color) => _Strip(
    radius: 12,
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 1),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.3),
    ),
  );
}

/// شريط رق قديم بحد بني (شرائح النتيجة والشريط اللي تحت).
class _Strip extends StatelessWidget {
  const _Strip({
    required this.child,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
  });

  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF0DDB2), Color(0xFFD9BC84)],
      ),
      border: Border.all(color: const Color(0xFF3A230F), width: 2),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 5, offset: const Offset(0, 2))],
    ),
    child: child,
  );
}
