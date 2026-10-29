import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/achievements.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/push.dart';
import '../services/sfx.dart';
import '../theme.dart';
import 'badges.dart';
import 'common.dart';
import 'fx.dart';
import 'design_social.dart';
import 'item_preview.dart';

/// محتوى مكافأة: الذهب والجواهر والأغراض (كل غرض بمعاينته واسمه).
class RewardView extends StatelessWidget {
  const RewardView({super.key, required this.coins, required this.diamonds, required this.items, this.big = false});

  final int coins;
  final int diamonds;
  final List<String> items;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final p = Backend.instance.profile.value;
    final s = big ? 1.0 : .7;
    Widget chip(Widget child, String label, Color color) {
      final edge = Color.lerp(color, const Color(0xFF3A230F), .35)!;
      return Container(
        width: 120 * s,
        padding: EdgeInsets.symmetric(vertical: 10 * s, horizontal: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4E4BE), Color(0xFFDCBF88)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: edge, width: 2.4),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .3), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 70 * s,
              child: Center(child: FittedBox(child: child)),
            ),
            SizedBox(height: 6 * s),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kufi,
                fontWeight: FontWeight.w800,
                fontSize: 14 * (big ? 1 : .9),
                color: socInk,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final id in items)
          if (shopItem(id) case final item?) chip(ItemPreview(item: item, profile: p), item.name, item.rarity.color),
        if (coins > 0) chip(Gfx('coin', size: 60 * s), '${arabicNumber(coins)} ذهب', AppColors.gold),
        if (diamonds > 0) chip(Gfx('gem', size: 60 * s), '${arabicNumber(diamonds)} جوهرة', AppColors.diamond),
      ],
    );
  }
}

/// نافذة هدية (مستوى أو بطولة) مع احتفال.
Future<void> showGiftDialog(BuildContext context, Gift g) {
  HapticFeedback.heavyImpact();
  final ach = g.achievement == null ? null : achievementById(g.achievement!);
  final rank = g.rank ? rankTiers[g.n.clamp(0, rankTiers.length - 1)] : null;
  if (!g.tutorial && ach == null) Sfx.say(g.champion ? 'win_loyal' : 'enact_loyal');
  final from = g.passFrom;
  final title = from != null
      ? (g.n == 1 ? 'هدية من $from: تذكرة الموسم كاملة!' : 'هدية من $from: تذكرة الموسم!')
      : rank != null
      ? 'وصلت رتبة ${rank.name}!'
      : ach != null
      ? 'إنجاز جديد: ${ach.name}'
      : g.tutorial
      ? 'خلّصت الشرح!'
      : g.tour
      ? 'بطل بطولة الأسبوع!'
      : g.champion
      ? (g.n == 1 ? 'بطل الأسبوع!' : (g.n == 2 ? 'وصيف الأسبوع!' : 'ثالث الأسبوع!'))
      : 'هدية المستوى ${arabicNumber(g.n)}!';
  final note = from != null
      ? (g.n == 1
            ? 'كل درجات الموسم انفتحت لك. استلم مكافآتها من تذكرة الموسم.'
            : 'انفتح لك المسار المدفوع ومعه ${arabicNumber(season.bonusTiers)} درجات هدية. استلمها من تذكرة الموسم.')
      : rank != null
      ? 'هذي مكافأة أول وصول للرتبة هالموسم. كمّل في الطاولات العامة عشان تطلع أكثر.'
      : ach != null
      ? 'وصلت الدرجة ${tierNames[g.n.clamp(0, 3)]}: ${ach.descFor(g.n - 1)}. تطلع في ملفك للكل.'
      : g.tutorial
      ? 'هذي هديتك على أول لعبة. الحين أنت جاهز تلعب مع الناس!'
      : g.tour
      ? 'فزت بالنهائي! هذي جائزة البطل، واسمك بلوحة أبطال الأسبوع.'
      : g.champion
      ? 'الإطار والشخصية لك لين التتويج الجاي (أسبوع). لابسها الحين!'
      : 'وصلت ملفك، تقدر تلبسها من المتجر أو ملفك.';
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'هدية',
    barrierColor: Colors.black.withValues(alpha: .78),
    transitionDuration: const Duration(milliseconds: 420),
    transitionBuilder: (context, a, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: a, child: child),
    ),
    pageBuilder: (context, _, _) => Stack(
      children: [
        const Positioned.fill(child: IgnorePointer(child: Confetti())),
        SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: SocPopupCard(
                title: title,
                width: 620,
                rays: true,
                raysAt: const Alignment(0, -.62),
                titleSize: 21,
                padding: const EdgeInsets.fromLTRB(22, 30, 22, 18),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (rank != null)
                        RankEmblem(tier: rank, size: 66)
                      else if (ach != null)
                        BadgeMedal(achievement: ach, tier: g.n, size: 62)
                      else
                        Gfx(
                          from != null
                              ? 'pass'
                              : (g.tutorial || g.tour ? 'trophy' : (g.champion ? 'medal${g.n}' : 'gift')),
                          size: 62,
                        ),
                      const SizedBox(height: 12),
                      RewardView(coins: g.coins, diamonds: g.diamonds, items: g.items, big: true),
                      const SizedBox(height: 12),
                      SocPopupText(note, size: 14, muted: true),
                      const SizedBox(height: 14),
                      SocButton(
                        label: 'استلمت',
                        tone: SocTone.green,
                        height: 50,
                        fontSize: 21,
                        width: 240,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// يراقب ملف اللاعب، ولو وصلته هدايا يعرضها وحدة وحدة ثم يبلغ السيرفر إنه شافها.
class GiftWatcher extends StatefulWidget {
  const GiftWatcher({super.key, required this.child});

  final Widget child;

  @override
  State<GiftWatcher> createState() => _GiftWatcherState();
}

class _GiftWatcherState extends State<GiftWatcher> with RouteAware {
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    Backend.instance.profile.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context) case final route?) routeObserver.subscribe(this, route);
  }

  /// رجع للرئيسية (مثلاً بعد اللعبة): الهدية اللي وصلت وهو يلعب تطلع الحين.
  @override
  void didPopNext() => WidgetsBinding.instance.addPostFrameCallback((_) => _check());

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    Backend.instance.profile.removeListener(_check);
    super.dispose();
  }

  Future<void> _check() async {
    final gifts = Backend.instance.profile.value.gifts;
    if (_showing || gifts.isEmpty || !mounted || !Backend.instance.isReady) return;
    // ما نعرضها فوق صفحة ثانية (مثل اللعبة)، تنتظر لين يرجع للرئيسية.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _showing = true;
    try {
      for (final g in gifts) {
        if (!mounted) return;
        await showGiftDialog(context, g);
      }
      await Backend.instance.ackGifts();
    } catch (_) {
      // لو فشل، تطلع مرة ثانية الجاية.
    } finally {
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// قصاصات ملونة تنزل (للاحتفال).
class Confetti extends StatelessWidget {
  const Confetti({super.key});

  @override
  Widget build(BuildContext context) => FxClock(builder: (context, t) => CustomPaint(painter: _ConfettiPainter(t)));
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.time) : super(repaint: time);

  final ValueListenable<double> time;

  static const _colors = [
    Color(0xFFFFD43B),
    Color(0xFFFF6B6B),
    Color(0xFF4DABF7),
    Color(0xFF69DB7C),
    Color(0xFFDA77F2),
    Color(0xFFFFFFFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    for (var i = 0; i < 70; i++) {
      final speed = .12 + rnd(i) * .18;
      final y = ((t * speed + rnd(i, 1)) % 1) * (size.height + 40) - 20;
      final x = rnd(i, 2) * size.width + math.sin(t * (1 + rnd(i, 3)) + i) * 18;
      final rot = t * (2 + rnd(i, 4) * 4) + i;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 7 + rnd(i, 5) * 5, height: 4 + math.sin(rot * 2).abs() * 6),
        Paint()..color = _colors[i % _colors.length],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
