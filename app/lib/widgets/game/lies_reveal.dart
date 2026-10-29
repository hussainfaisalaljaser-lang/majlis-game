import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../models/room.dart';
import '../../models/shop.dart';
import '../../theme.dart';
import '../bubble.dart';
import '../common.dart';
import '../design.dart';
import '../design_game.dart';
import '../ui.dart';

/// «مين كذب؟»: بعد اللعبة، كل حكومة مررت قرار: وش وصل الرئيس والوزير فعلاً، ووش قال كل واحد،
/// وختم «صادق» أو «كذاب» على كل كلام. وبالآخر أكبر كذاب وأصدق واحد.
Future<void> showLiesReveal(BuildContext context, GameView view, Room? room) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'من كذب؟',
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

  /// ارتفاع التصميم كله (العنوان + البطاقات + الجوائز).
  static const _designHeight = 376.0;

  @override
  Widget build(BuildContext context) {
    final awards = _awards;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // أشعة خفيفة ورا النافذة (مثل نوافذ التصميم)
          const Positioned.fill(child: RepaintBoundary(child: SunRays(opacity: .07, rays: 16))),
          SafeArea(
            // ضغطة تخلّص الحركة على طول (للي ما يبي ينتظر).
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _c.value = 1,
              child: LayoutBuilder(
                builder: (context, box) {
                  // على قد الشاشة: البطاقات تصغر لو الطول ما يكفي.
                  final scale = math.min(1.0, (box.maxHeight - 8) / _designHeight);
                  return Center(
                    child: Transform.scale(
                      scale: scale,
                      // الارتفاع ثابت بالتصميم، وبعدها يصغر بالمقياس (بدون ما يشتكي من الحجم)
                      child: OverflowBox(
                        minWidth: box.maxWidth / scale,
                        maxWidth: box.maxWidth / scale,
                        minHeight: _designHeight,
                        maxHeight: _designHeight,
                        child: AnimatedBuilder(
                          animation: _c,
                          builder: (context, _) {
                            final t = _c.value * _total;
                            return Column(
                              children: [
                                SizedBox(
                                  height: 50,
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 56),
                                      const Expanded(
                                        child: Center(
                                          child: SizedBox(width: 280, child: RibbonTitle('من كذب؟', size: 21)),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 56,
                                        child: Center(
                                          child: GameRoundButton(
                                            size: 42,
                                            semantics: 'سكّر',
                                            onTap: () => Navigator.pop(context),
                                            child: const Icon(Icons.close_rounded, color: Color(0xFFFFF3DA), size: 26),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: 240,
                                  child: _govs.isEmpty
                                      ? const Center(
                                          child: GamePlank(
                                            child: Text(
                                              'ما تمرر ولا قرار بحكومة، فما فيه أحد يكذب!',
                                              style: TextStyle(
                                                fontFamily: kufi,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFFFF3DA),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: ListView.separated(
                                            shrinkWrap: true,
                                            scrollDirection: Axis.horizontal,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                            itemCount: _govs.length,
                                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                                            itemBuilder: (context, i) => _GovCard(
                                              index: i,
                                              gov: _govs[i],
                                              t: t - (.4 + i * _step),
                                              name: _name,
                                              avatar: _avatar,
                                            ),
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
        ],
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
        child: SizedBox(
          width: 244,
          // الحكومة اللي فيها كذب يتوهج كرتها بالأحمر لما ينختم
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              boxShadow: lied && stamp > 0
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE0382B).withValues(alpha: .7 * stamp),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ParchmentCard(
              radius: 16,
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 7),
              child: Column(
                children: [
                  GoldRibbonLabel('الحكومة ${arabicNumber(index + 1)}', size: 13),
                  const SizedBox(height: 2),
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
                          real,
                          said,
                          stamp,
                        ),
                        Container(
                          width: 1.5,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: const Color(0xFF8E6A3C).withValues(alpha: .45),
                        ),
                        _side(
                          gov.chancellor,
                          'الوزير',
                          gov.chancellorGot,
                          gov.chancellorSaid,
                          gov.chancellorLied,
                          real,
                          said,
                          stamp,
                        ),
                      ],
                    ),
                  ),
                  // القرار اللي تمرر: شريط غامق مثل أسماء اللاعبين
                  Opacity(
                    opacity: said,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF21140B).withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'تمرر ',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFFFF3DA)),
                          ),
                          Seal(loyal: gov.enacted == Policy.loyal, size: 22),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// سطر: كلمة («وصله» أو «قال») وجنبها الأختام.
  Widget _line(String label, Widget content) => SizedBox(
    height: 24,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A5A0A), fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 4),
          content,
        ],
      ),
    ),
  );

  Widget _seals(List<Policy>? cards, double k) {
    if (cards == null) {
      return const Text(
        '؟',
        style: TextStyle(color: Color(0xFF7A5A3A), fontSize: 15, fontWeight: FontWeight.w800),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (j, c) in ([...cards]..sort((a, b) => a.index.compareTo(b.index))).indexed)
          Transform.scale(
            scale: _seg(k, j * .25, j * .25 + .6, Curves.easeOutBack),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Seal(loyal: c == Policy.loyal, size: 22),
            ),
          ),
      ],
    );
  }

  Widget _side(
    String id,
    String role,
    List<Policy>? truth,
    List<Policy>? claim,
    bool? lied,
    double real,
    double said,
    double stamp,
  ) {
    return Expanded(
      child: Column(
        children: [
          TableAvatar(avatar: avatar(id), size: 44, animate: false),
          Text(
            name(id),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.ink, height: 1.15),
          ),
          Text(
            role,
            style: const TextStyle(color: Color(0xFF7A5A3A), fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.1),
          ),
          const SizedBox(height: 2),
          _line('وصله', _seals(truth, real)),
          const SizedBox(height: 2),
          _line(
            'قال',
            claim == null
                ? Opacity(
                    opacity: said,
                    child: const Text(
                      'ما قال شي',
                      style: TextStyle(color: Color(0xFF7A5A3A), fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  )
                : _seals(claim, said),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 28,
            child: lied == null || stamp == 0
                ? null
                : Transform.rotate(
                    angle: -.18,
                    child: Transform.scale(
                      scale: 1 + (1 - stamp) * 1.6,
                      child: Opacity(
                        opacity: stamp,
                        child: _Stamp(lied: lied),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// ختم «كذاب» (أحمر) أو «صادق» (أخضر) مثل ختم الحبر على الرق.
class _Stamp extends StatelessWidget {
  const _Stamp({required this.lied});

  final bool lied;

  @override
  Widget build(BuildContext context) {
    final color = lied ? const Color(0xFFB3261E) : const Color(0xFF2B7A2A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color, width: 2.4),
      ),
      child: Text(
        lied ? 'كذاب' : 'صادق',
        style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 15, color: color, height: 1.15),
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
    if (t <= 0) return const SizedBox(height: 70);
    Widget award(int i, String? id, String title, String sub, Color color, String sticker) {
      final s = Curves.elasticOut.transform(_seg(t, i * .3, i * .3 + .8));
      return Transform.scale(
        scale: s,
        child: SizedBox(
          width: 276,
          height: 70,
          // لوح خشب بحافة ذهبية، وتوهج بلون الجائزة
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              boxShadow: [BoxShadow(color: color.withValues(alpha: .4), blurRadius: 18)],
            ),
            child: GameHudPlank(
              gold: true,
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                children: [
                  if (id != null) TableAvatar(avatar: avatar(id), size: 50, ring: color, animate: false),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedText(title, size: 16, color: color, align: TextAlign.start, maxLines: 1),
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                            color: Color(0xFFFFF3DA),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (stickerById(sticker) case final st?) StickerView(sticker: st, size: 44, pop: false),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          award(
            0,
            liar,
            liar == null ? 'ما كذب أحد!' : 'أكبر كذاب',
            liar == null
                ? 'الكل قال الصدق هاللعبة'
                : '${name(liar!)}: ${arabicNumber(lies)} ${lies == 1 ? 'كذبة' : 'كذبات'}',
            AppColors.traitorLight,
            'tr_mask',
          ),
          if (honest != null) ...[
            const SizedBox(width: 12),
            award(1, honest, 'أصدق واحد', '${name(honest!)}: ما كذب ولا مرة', const Color(0xFF6DE3A0), 'inn_halo'),
          ],
        ],
      ),
    );
  }
}
