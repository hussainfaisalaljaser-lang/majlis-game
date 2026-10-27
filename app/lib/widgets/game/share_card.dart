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
import '../majlis.dart';
import '../ui.dart';
import '../venues.dart';
import 'overlays.dart';

/// صورة تنشرها بعد اللعبة: دورك ونتيجتك وكم مرة كذبت، ورمزك عشان أصحابك يلقونك.
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
    Role.leader when iWon => executed ? 'انطردت بس فريقي فاز!' : 'كنت الزعيم ومحد كشفني!',
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
      backgroundColor: AppColors.panel,
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: preview,
              height: preview,
              child: FittedBox(
                child: RepaintBoundary(
                  key: _key,
                  child: ShareCard(view: widget.view, room: widget.room),
                ),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GoldText('شارك نتيجتك', size: 22),
                  const SizedBox(height: 6),
                  const Text(
                    'الصورة فيها رمزك، فأي واحد يشوفها يقدر يضيفك ويتحداك',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 14),
                  GameButton(
                    label: _busy ? 'لحظة…' : 'شارك',
                    icon: const Gfx('link', size: 24),
                    height: 48,
                    fontSize: 17,
                    onPressed: _busy ? null : _share,
                  ),
                  const SizedBox(height: 6),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('بعدين')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// الصورة نفسها (٣٦٠ × ٣٦٠، وتنحفظ بثلاث أضعاف).
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
    final (roleName, _, roleColor, _) = roleInfo[v.yourRole]!;
    final lies = [
      for (final g in v.governments) ...[
        if (g.president == v.you) g.presidentLied,
        if (g.chancellor == v.you) g.chancellorLied,
      ],
    ].whereType<bool>();
    final lied = lies.where((l) => l).length;
    final rounds = v.governments.length;
    return SizedBox(
      width: 360,
      height: 360,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: MajlisRoom(venue: venueOf(room?.tierId))),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .55),
                      Colors.black.withValues(alpha: .25),
                      Colors.black.withValues(alpha: .8),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.gold, width: 3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset('assets/logo.png', width: 28, height: 28),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'مجلس الخونة',
                        style: TextStyle(
                          fontFamily: kufi,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      PlayerAvatar(avatar: p.avatar, style: frameStyle(p.frame), size: 104, animate: false),
                      Positioned(
                        bottom: -6,
                        right: -8,
                        child: v.yourRole == Role.leader
                            ? const LeaderSeal(size: 40)
                            : Seal(loyal: v.yourRole == Role.loyal, size: 36),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GoldText(shareHeadline(v), size: 24),
                  const SizedBox(height: 2),
                  Text(
                    '${p.name} · $roleName',
                    style: TextStyle(fontFamily: kufi, fontSize: 14, fontWeight: FontWeight.w700, color: roleColor),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chip(iWon ? 'فزت' : 'خسرت', iWon ? AppColors.green : AppColors.traitorLight),
                      _chip('${arabicNumber(rounds)} ${rounds == 1 ? 'قرار' : 'قرارات'}', AppColors.goldLight),
                      if (lies.isNotEmpty)
                        _chip(
                          lied == 0 ? 'ما كذبت ولا مرة' : 'كذبت ${arabicNumber(lied)} ${lied == 1 ? 'مرة' : 'مرات'}',
                          lied == 0 ? AppColors.green : const Color(0xFFFF8A3C),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    p.pid.isEmpty ? 'حمّل اللعبة وتحداني' : 'حمّل اللعبة وتحداني · رمزي ${p.pid}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                  const Text(Links.host, style: TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: .8)),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
    ),
  );
}
