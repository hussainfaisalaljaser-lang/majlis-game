import 'package:flutter/material.dart';

import '../models/missions.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

/// المهام اليومية: تتجدد الساعة ١٢ بالليل بتوقيت الخليج.
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  String? _claiming;

  Future<void> _claim(MissionDef m) async {
    setState(() => _claiming = m.id);
    try {
      final coins = await Backend.instance.claimMission(m.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('+${arabicNumber(coins)} 🪙 ${m.title}')));
      }
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _claiming = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      appBar: AppBar(title: const Text('✅ المهام اليومية')),
      body: ValueListenableBuilder(
        valueListenable: Backend.instance.profile,
        builder: (context, p, _) {
          final state = p.missions;
          final done = missionDefs.where((m) => state.claimed.contains(m.id)).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'خلصت ${arabicNumber(done)} من ${arabicNumber(missionDefs.length)} · تتجدد كل يوم الساعة ١٢ بالليل',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              for (final m in missionDefs)
                _MissionTile(
                  mission: m,
                  progress: state.progressOf(m),
                  claimed: state.claimed.contains(m.id),
                  busy: _claiming == m.id,
                  onClaim: Backend.instance.isReady && state.isClaimable(m) ? () => _claim(m) : null,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({
    required this.mission,
    required this.progress,
    required this.claimed,
    required this.busy,
    this.onClaim,
  });

  final MissionDef mission;
  final int progress;
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
          Text(mission.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mission.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress / mission.target,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(7),
                        backgroundColor: AppColors.bg,
                        color: claimed ? AppColors.green : AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${arabicNumber(progress)}/${arabicNumber(mission.target)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          claimed
              ? const Text('✅', style: TextStyle(fontSize: 24))
              : FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(84, 40),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  onPressed: busy ? null : onClaim,
                  child: Text('${arabicNumber(mission.coins)} 🪙'),
                ),
        ],
      ),
    );
  }
}
