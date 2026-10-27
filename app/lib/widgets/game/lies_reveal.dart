import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/room.dart';
import '../../models/shop.dart';
import '../../theme.dart';
import '../bubble.dart';
import '../common.dart';
import '../ui.dart';

/// «مين كذب؟»: بعد اللعبة، كل حكومة مررت قرار: وش وصل الرئيس والوزير فعلاً، ووش قال كل واحد،
/// وختم «صادق» أو «كذاب» على كل كلام. وبالآخر أكبر كذاب وأصدق واحد.
Future<void> showLiesReveal(BuildContext context, GameView view, Room? room) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'مين كذب؟',
  barrierColor: Colors.black.withValues(alpha: .82),
  transitionDuration: const Duration(milliseconds: 240),
  transitionBuilder: (context, a, _, child) => FadeTransition(opacity: a, child: child),
  pageBuilder: (context, _, _) => _LiesReveal(view: view, room: room),
);

class _LiesReveal extends StatefulWidget {
  const _LiesReveal({required this.view, required this.room});

  final GameView view;
  final Room? room;

  @override
  State<_LiesReveal> createState() => _LiesRevealState();
}

class _LiesRevealState extends State<_LiesReveal> with SingleTickerProviderStateMixin {
  late final List<GovernmentRecord> _govs = widget.view.governments;

  /// كل حكومة تطلع ورا اللي قبلها، والجوائز بالآخر.
  static const _step = .9;
  late final double _total = .4 + _govs.length * _step + 1.2;
  late final _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_total * 1000).round()),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _name(String id) => widget.view.nameOf(id);
  String _avatar(String id) => widget.room?.player(id)?.avatar ?? 'masked';

  /// أكبر كذاب (أكثر كذبات)، وأصدق واحد (أكثر كلام صادق وما كذب ولا مرة).
  ({String? liar, int lies, String? honest, int truths}) get _awards {
    final lies = <String, int>{}, truths = <String, int>{};
    void count(String id, bool? lied) {
      if (lied == null) return;
      if (lied) {
        lies[id] = (lies[id] ?? 0) + 1;
      } else {
        truths[id] = (truths[id] ?? 0) + 1;
      }
    }

    for (final g in _govs) {
      count(g.president, g.presidentLied);
      count(g.chancellor, g.chancellorLied);
    }
    final liar = lies.entries.fold<MapEntry<String, int>?>(null, (b, e) => b == null || e.value > b.value ? e : b);
    final honest = truths.entries
        .where((e) => !lies.containsKey(e.key))
        .fold<MapEntry<String, int>?>(null, (b, e) => b == null || e.value > b.value ? e : b);
    return (liar: liar?.key, lies: liar?.value ?? 0, honest: honest?.key, truths: honest?.value ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final awards = _awards;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        // ضغطة تخلّص الحركة على طول (للي ما يبي ينتظر).
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _c.value = 1,
          child: LayoutBuilder(
            builder: (context, box) {
              // على قد الشاشة: البطاقات تصغر لو الطول ما يكفي.
              final scale = math.min(1.0, (box.maxHeight - 8) / 336);
              return Center(
                child: Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: box.maxWidth / scale,
                    height: 336,
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) {
                        final t = _c.value * _total;
                        return Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(width: 48),
                                const Expanded(child: Center(child: GoldText('مين كذب؟', size: 28))),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded, color: AppColors.muted, size: 28),
                                  tooltip: 'سكّر',
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 222,
                              child: _govs.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'ما تمرر ولا قرار بحكومة، فما فيه أحد يكذب!',
                                        style: TextStyle(fontFamily: kufi, fontSize: 16),
                                      ),
                                    )
                                  : ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      itemCount: _govs.length,
                                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                                      itemBuilder: (context, i) => _GovCard(
                                        index: i,
                                        gov: _govs[i],
                                        t: t - (.4 + i * _step),
                                        name: _name,
                                        avatar: _avatar,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 10),
                            _AwardsRow(
                              t: t - (.4 + _govs.length * _step),
                              liar: awards.liar,
                              lies: awards.lies,
                              honest: awards.honest,
                              truths: awards.truths,
                              name: _name,
                              avatar: _avatar,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

double _seg(double t, double a, double b, [Curve curve = Curves.linear]) =>
    curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// بطاقة حكومة: الرئيس والوزير، وش وصلهم ووش قالوا، والقرار اللي تمرر.
class _GovCard extends StatelessWidget {
  const _GovCard({required this.index, required this.gov, required this.t, required this.name, required this.avatar});

  final int index;
  final GovernmentRecord gov;

  /// الوقت من بداية ظهور هالبطاقة (بالثواني).
  final double t;
  final String Function(String) name;
  final String Function(String) avatar;

  @override
  Widget build(BuildContext context) {
    final appear = _seg(t, 0, .35, Curves.easeOut);
    final real = _seg(t, .3, .7);
    final said = _seg(t, .55, .85);
    final stamp = _seg(t, .8, 1.05, Curves.easeInCubic);
    final lied = (gov.presidentLied ?? false) || (gov.chancellorLied ?? false);
    final shake = lied ? math.sin(t * 60) * 4 * (1 - _seg(t, 1.05, 1.35)) * (t > 1.05 ? 1 : 0) : 0.0;
    return Opacity(
      opacity: appear,
      child: Transform.translate(
        offset: Offset(shake, 24 * (1 - appear)),
        child: Container(
          width: 236,
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          decoration: BoxDecoration(
            color: AppColors.panel.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: lied && stamp > 0 ? AppColors.traitorLight : AppColors.gold.withValues(alpha: .7),
              width: 1.8,
            ),
          ),
          child: Column(
            children: [
              Text(
                'الحكومة ${arabicNumber(index + 1)}',
                style: const TextStyle(
                  fontFamily: kufi,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _side(
                      gov.president,
                      'الرئيس',
                      gov.presidentDrew,
                      gov.presidentSaid,
                      gov.presidentLied,
                      3,
                      real,
                      said,
                      stamp,
                    ),
                    Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 6), color: Colors.white12),
                    _side(
                      gov.chancellor,
                      'الوزير',
                      gov.chancellorGot,
                      gov.chancellorSaid,
                      gov.chancellorLied,
                      2,
                      real,
                      said,
                      stamp,
                    ),
                  ],
                ),
              ),
              Opacity(
                opacity: said,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('تمرر ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    Seal(loyal: gov.enacted == Policy.loyal, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seals(List<Policy>? cards, int count, double k) {
    if (cards == null) {
      return const SizedBox(
        height: 22,
        child: Text('؟', style: TextStyle(color: AppColors.muted, fontSize: 14)),
      );
    }
    return SizedBox(
      height: 22,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (j, c) in ([...cards]..sort((a, b) => a.index.compareTo(b.index))).indexed)
            Transform.scale(
              scale: _seg(k, j * .25, j * .25 + .6, Curves.easeOutBack),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Seal(loyal: c == Policy.loyal, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _side(
    String id,
    String role,
    List<Policy>? truth,
    List<Policy>? claim,
    bool? lied,
    int count,
    double real,
    double said,
    double stamp,
  ) {
    const label = TextStyle(fontSize: 11, color: AppColors.goldLight, fontWeight: FontWeight.w700);
    return Expanded(
      child: Column(
        children: [
          PlayerAvatar(avatar: avatar(id), size: 34, animate: false),
          Text(
            name(id),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
          ),
          Text(role, style: const TextStyle(color: AppColors.muted, fontSize: 10.5)),
          const SizedBox(height: 2),
          const Text('وصله', style: label),
          _seals(truth, count, real),
          const SizedBox(height: 2),
          const Text('قال', style: label),
          claim == null
              ? SizedBox(
                  height: 22,
                  child: Opacity(
                    opacity: said,
                    child: const Text('ما قال شي', style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
                  ),
                )
              : _seals(claim, count, said),
          const SizedBox(height: 4),
          SizedBox(
            height: 26,
            child: lied == null || stamp == 0
                ? null
                : Transform.rotate(
                    angle: -.18,
                    child: Transform.scale(
                      scale: 1 + (1 - stamp) * 1.6,
                      child: Opacity(
                        opacity: stamp,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: (lied ? AppColors.traitor : AppColors.green).withValues(alpha: .25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: lied ? AppColors.traitorLight : AppColors.green, width: 2),
                          ),
                          child: Text(
                            lied ? 'كذاب' : 'صادق',
                            style: TextStyle(
                              fontFamily: kufi,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: lied ? AppColors.traitorLight : const Color(0xFF6DE3A0),
                            ),
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
}

/// أكبر كذاب وأصدق واحد.
class _AwardsRow extends StatelessWidget {
  const _AwardsRow({
    required this.t,
    required this.liar,
    required this.lies,
    required this.honest,
    required this.truths,
    required this.name,
    required this.avatar,
  });

  final double t;
  final String? liar;
  final int lies;
  final String? honest;
  final int truths;
  final String Function(String) name;
  final String Function(String) avatar;

  @override
  Widget build(BuildContext context) {
    if (t <= 0) return const SizedBox(height: 64);
    Widget award(int i, String? id, String title, String sub, Color color, String sticker) {
      final s = Curves.elasticOut.transform(_seg(t, i * .3, i * .3 + .8));
      return Transform.scale(
        scale: s,
        child: Container(
          width: 270,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.panel.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: .35), blurRadius: 16)],
          ),
          child: Row(
            children: [
              if (id != null) PlayerAvatar(avatar: avatar(id), size: 42, frame: color, animate: false),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, color: color, fontSize: 15),
                    ),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (stickerById(sticker) case final st?) StickerView(sticker: st, size: 44, pop: false),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          award(
            0,
            liar,
            liar == null ? 'ما كذب أحد!' : 'أكبر كذاب',
            liar == null
                ? 'الكل قال الصدق هاللعبة'
                : '${name(liar!)} · ${arabicNumber(lies)} ${lies == 1 ? 'كذبة' : 'كذبات'}',
            AppColors.traitorLight,
            'tr_mask',
          ),
          if (honest != null) ...[
            const SizedBox(width: 12),
            award(1, honest, 'أصدق واحد', '${name(honest!)} · ما كذب ولا مرة', AppColors.green, 'inn_halo'),
          ],
        ],
      ),
    );
  }
}
