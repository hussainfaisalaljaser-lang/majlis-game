import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../models/missions.dart';
import '../models/profile.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/design_season.dart';
import '../widgets/ui.dart';
import '../widgets/weekend.dart';

/// المهام: اليومية (ذهب ونقاط باتل باس، تتجدد كل يوم)، والأسبوعية (تتجدد كل أحد)، ومهام الموسم (لين نهاية
/// الباتل باس). الأسبوعية والموسم تعطي نقاط باتل باس.
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key, this.tab = 0});

  /// ٠ اليومية، ١ الأسبوعية، ٢ الموسم.
  final int tab;

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  String? _claiming;
  late int _tab = widget.tab;

  Future<void> _claim(String id, Future<String> Function() request) async {
    setState(() => _claiming = id);
    try {
      final note = await request();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(note)));
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _claiming = null);
    }
  }

  void _claimDaily(MissionDef m) => _claim(m.id, () async {
    final coins = await Backend.instance.claimMission(m.id);
    return '+${arabicNumber(coins)} ذهب و${arabicNumber(missionPassPoints)} نقطة موسم · ${m.title}';
  });

  void _claimPass(PassMissionDef m) => _claim(m.id, () async {
    final points = await Backend.instance.claimPassMission(m.id);
    return '+${arabicNumber(points)} نقطة موسم · ${m.title}';
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Backend.instance.profile,
    builder: (context, p, _) => MissionsView(
      profile: p,
      tab: _tab,
      onTab: (i) => setState(() => _tab = i),
      claiming: _claiming,
      ready: Backend.instance.isReady,
      onClaimDaily: _claimDaily,
      onClaimPass: _claimPass,
    ),
  );
}

/// سطر مهمة جاهز للرسم (يومية أو باتل باس).
class MissionRow {
  const MissionRow({
    required this.icon,
    required this.title,
    required this.progress,
    required this.target,
    required this.rewardIcon,
    required this.reward,
    required this.claimed,
    required this.busy,
    this.onClaim,
  });

  final String icon;
  final String title;
  final int progress;
  final int target;

  /// الجائزة: أيقونتها (coin أو pass) ورقمها.
  final String rewardIcon;
  final int reward;
  final bool claimed;
  final bool busy;

  /// null لو ما تنستلم (ما خلصت، أو مستلمة، أو ما فيه اتصال).
  final VoidCallback? onClaim;

  bool get done => progress >= target;
}

/// شاشة المهام بدون حالة ولا سيرفر (تنرسم بأي ملف لاعب).
class MissionsView extends StatelessWidget {
  const MissionsView({
    super.key,
    required this.profile,
    required this.tab,
    required this.onTab,
    required this.claiming,
    required this.ready,
    required this.onClaimDaily,
    required this.onClaimPass,
  });

  final Profile profile;
  final int tab;
  final ValueChanged<int> onTab;
  final String? claiming;
  final bool ready;
  final ValueChanged<MissionDef> onClaimDaily;
  final ValueChanged<PassMissionDef> onClaimPass;

  static const _titles = ['مهام اليوم', 'مهام الأسبوع', 'مهام الموسم'];

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final daily = p.missions;
    final pass = p.passMissions;
    final left = season.end.difference(DateTime.now()).inDays;
    final (String note, List<MissionRow> rows) = switch (tab) {
      0 => (
        'كل مهمة تعطي ذهب و${arabicNumber(missionPassPoints)} نقطة موسم · تتجدد كل يوم الساعة ١٢ منتصف الليل',
        [
          for (final m in missionDefs)
            MissionRow(
              icon: m.icon,
              title: m.title,
              progress: daily.progressOf(m).clamp(0, m.target),
              target: m.target,
              rewardIcon: 'coin',
              reward: m.coins,
              claimed: daily.claimed.contains(m.id),
              busy: claiming == m.id,
              onClaim: ready && daily.isClaimable(m) ? () => onClaimDaily(m) : null,
            ),
        ],
      ),
      _ => (
        tab == 1
            ? 'نقاط الموسم · تتجدد كل أحد الساعة ١٢ منتصف الليل'
            : 'نقاط الموسم · لين نهاية الموسم (باقي ${arabicNumber(left.clamp(0, 999))} يوم)',
        [
          for (final m in tab == 1 ? weeklyMissions : seasonMissions)
            MissionRow(
              icon: m.icon,
              title: m.title,
              progress: pass.progressOf(m),
              target: m.target,
              rewardIcon: 'pass',
              reward: m.points,
              claimed: pass.isClaimed(m),
              busy: claiming == m.id,
              onClaim: ready && season.active && pass.isClaimable(m) ? () => onClaimPass(m) : null,
            ),
        ],
      ),
    };
    int count(Iterable<bool> xs) => xs.where((x) => x).length;
    final badges = [
      count(missionDefs.map(daily.isClaimable)),
      count(weeklyMissions.map(pass.isClaimable)),
      count(seasonMissions.map(pass.isClaimable)),
    ];
    return NightScaffold(
      appBar: SnTopBar(
        title: 'المهام',
        icon: const Gfx('missions', size: 30),
        trailing: [SnWallet(coins: p.coins, diamonds: p.diamonds, infinite: p.dev)],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, box) {
            final leftW = (box.maxWidth * .25).clamp(170.0, 250.0);
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: WoodPanel(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: SnTabBar(
                              labels: const ['اليومية', 'الأسبوعية', 'الموسم'],
                              badges: badges,
                              selected: tab,
                              onChanged: onTab,
                              height: 36,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _ResetChip(tab: tab),
                          const SizedBox(height: 8),
                          Expanded(child: _MissionGrid(rows: rows)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: leftW,
                    child: _SummaryPanel(title: _titles[tab], note: note, rows: rows),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// وقت التجديد: اليومية كل يوم ١٢ منتصف الليل (بتوقيت الخليج)، والأسبوعية كل أحد، والموسم لين ينتهي.
/// العداد يتحدث كل دقيقة.
class _ResetChip extends StatelessWidget {
  const _ResetChip({required this.tab});

  final int tab;

  @override
  Widget build(BuildContext context) => MinuteTicker(
    builder: (context, now) {
      final g = now.toUtc().add(const Duration(hours: 3));
      final Duration left;
      switch (tab) {
        case 0:
          left = DateTime.utc(g.year, g.month, g.day + 1).difference(g);
        case 1:
          // الأسبوع يبدأ الأحد (نفس قاعدة السيرفر)
          left = DateTime.utc(g.year, g.month, g.day + (g.weekday == DateTime.sunday ? 7 : 7 - g.weekday)).difference(g);
        default:
          left = season.end.difference(now);
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withValues(alpha: .3),
          border: Border.all(color: const Color(0xFFE8B54E).withValues(alpha: .55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gfx('hourglass', size: 18),
            const SizedBox(width: 6),
            Text(
              tab == 2 ? 'ينتهي الموسم بعد ${timeLeft(left)}' : 'تتجدد بعد ${timeLeft(left)}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFFF6E2BC)),
            ),
          ],
        ),
      );
    },
  );
}

/// لوحة المخمل (يسار): أيقونة المهام وأشعة، وعنوان التبويب وملاحظته، وكم خلصت.
class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.title, required this.note, required this.rows});

  final String title;
  final String note;
  final List<MissionRow> rows;

  @override
  Widget build(BuildContext context) {
    final done = rows.where((r) => r.done).length;
    return LayoutBuilder(
      builder: (context, box) {
        final k = (box.maxHeight / 477).clamp(.6, 1.0);
        return VelvetPanel(
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              const Positioned.fill(child: SnSunburst(alignment: Alignment(0, -.5))),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 14 * k, 16, 16 * k),
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Center(child: Gfx('missions', size: 92 * k)),
                    ),
                    GoldTitle(title, size: math.max(16, 23 * k)),
                    SizedBox(height: 8 * k),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          note,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFF1DDBA),
                            fontSize: math.max(10.5, 12.5 * k),
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 6 * k),
                    OutlinedText(
                      'خلصت ${arabicNumber(done)} من ${arabicNumber(rows.length)}',
                      size: math.max(12, 15 * k),
                      stroke: const Color(0xFF260A10),
                      maxLines: 1,
                    ),
                    SizedBox(height: 6 * k),
                    SnProgressBar(value: rows.isEmpty ? 0 : done / rows.length, height: math.max(8.0, 11 * k)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// المهام: عمودين لو العرض يسمح، وإلا عمود.
class _MissionGrid extends StatelessWidget {
  const _MissionGrid({required this.rows});

  final List<MissionRow> rows;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = box.maxWidth >= 520 ? 2 : 1;
      // الصفوف تتمدد شوي عشان تعبي اللوح لو المهام قليلة.
      final lines = (rows.length / cols).ceil();
      final extent = lines == 0 ? 62.0 : ((box.maxHeight - 10 - 10 * (lines - 1)) / lines).clamp(62.0, 76.0);
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 10,
          crossAxisSpacing: 12,
          mainAxisExtent: extent,
        ),
        itemCount: rows.length,
        itemBuilder: (context, i) => _MissionTile(row: rows[i]),
      );
    },
  );
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.row});

  final MissionRow row;

  @override
  Widget build(BuildContext context) {
    final r = row;
    final ready = r.onClaim != null;
    final reward = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Gfx(r.rewardIcon, size: 20),
        const SizedBox(width: 4),
        Text(
          arabicNumber(r.reward),
          style: const TextStyle(
            fontFamily: kufi,
            fontWeight: FontWeight.w800,
            fontSize: 15,
            height: 1.2,
            color: Color(0xFFFFF3DA),
          ),
        ),
      ],
    );
    return PlankBar(
      radius: 12,
      gold: ready,
      padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 10, 6),
      child: Row(
        children: [
          GoldCircle(size: 44, child: Gfx(r.icon, size: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    r.title,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: kufi,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.2,
                      color: Color(0xFFFFF3DA),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: SnProgressBar(value: r.progress / r.target, height: 8, green: r.claimed),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${arabicNumber(r.progress)}/${arabicNumber(r.target)}',
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontFamily: kufi,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        height: 1.1,
                        color: Color(0xFFF2B552),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: r.claimed
                ? const Center(child: Gfx('check', size: 32))
                : ready
                ? SnButton(
                    label: arabicNumber(r.reward),
                    icon: Gfx(r.rewardIcon, size: 22),
                    tone: SnTone.green,
                    height: 36,
                    fontSize: 16,
                    semantics: 'استلم',
                    onPressed: r.busy ? null : r.onClaim,
                  )
                : SnPill(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Opacity(opacity: .75, child: reward),
                  ),
          ),
        ],
      ),
    );
  }
}
