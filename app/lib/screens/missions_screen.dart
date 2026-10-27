import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../models/missions.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

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
    return '+${arabicNumber(coins)} ذهب و${arabicNumber(missionPassPoints)} نقطة باتل باس · ${m.title}';
  });

  void _claimPass(PassMissionDef m) => _claim(m.id, () async {
    final points = await Backend.instance.claimPassMission(m.id);
    return '+${arabicNumber(points)} نقطة باتل باس · ${m.title}';
  });

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Gfx('missions', size: 30), SizedBox(width: 8), Text('المهام')],
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Backend.instance.profile,
        builder: (context, p, _) {
          final daily = p.missions;
          final pass = p.passMissions;
          final ready = Backend.instance.isReady;
          final left = season.end.difference(DateTime.now()).inDays;
          final (String note, List<Widget> tiles) = switch (_tab) {
            0 => (
              'كل مهمة تعطي ذهب و${arabicNumber(missionPassPoints)} نقطة باتل باس · تتجدد كل يوم الساعة ١٢ بالليل',
              [
                for (final m in missionDefs)
                  _MissionTile(
                    icon: m.icon,
                    title: m.title,
                    progress: daily.progressOf(m),
                    target: m.target,
                    reward: Amount('coin', arabicNumber(m.coins), size: 18, style: _rewardStyle),
                    claimed: daily.claimed.contains(m.id),
                    busy: _claiming == m.id,
                    onClaim: ready && daily.isClaimable(m) ? () => _claimDaily(m) : null,
                  ),
              ],
            ),
            _ => (
              _tab == 1
                  ? 'نقاط باتل باس · تتجدد كل أحد الساعة ١٢ بالليل'
                  : 'نقاط باتل باس · لين نهاية الموسم (باقي ${arabicNumber(left.clamp(0, 999))} يوم)',
              [
                for (final m in _tab == 1 ? weeklyMissions : seasonMissions)
                  _MissionTile(
                    icon: m.icon,
                    title: m.title,
                    progress: pass.progressOf(m),
                    target: m.target,
                    reward: Amount('pass', arabicNumber(m.points), size: 18, style: _rewardStyle),
                    claimed: pass.isClaimed(m),
                    busy: _claiming == m.id,
                    onClaim: ready && season.active && pass.isClaimable(m) ? () => _claimPass(m) : null,
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
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: [
                    for (final (i, label) in const ['اليومية', 'الأسبوعية', 'الموسم'].indexed)
                      ButtonSegment(
                        value: i,
                        label: Text(badges[i] > 0 ? '$label (${arabicNumber(badges[i])})' : label),
                      ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
              Text(
                note,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: tiles),
              ),
            ],
          );
        },
      ),
    );
  }
}

const _rewardStyle = TextStyle(fontWeight: FontWeight.w800, color: Colors.black);

class _MissionTile extends StatelessWidget {
  const _MissionTile({
    required this.icon,
    required this.title,
    required this.progress,
    required this.target,
    required this.reward,
    required this.claimed,
    required this.busy,
    this.onClaim,
  });

  final String icon;
  final String title;
  final int progress;
  final int target;

  /// الجائزة على زر الاستلام (ذهب أو نقاط باتل باس).
  final Widget reward;
  final bool claimed;
  final bool busy;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final ready = onClaim != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: claimed ? const Color(0xFF14261B) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ready ? AppColors.gold : AppColors.line, width: ready ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Gfx(icon, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress / target,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(7),
                        backgroundColor: AppColors.bg,
                        color: claimed ? AppColors.green : AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${arabicNumber(progress)}/${arabicNumber(target)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          claimed
              ? const Gfx('check', size: 32)
              : FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(84, 40),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  onPressed: busy ? null : onClaim,
                  child: reward,
                ),
        ],
      ),
    );
  }
}
