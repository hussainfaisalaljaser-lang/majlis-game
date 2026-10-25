/// المهام اليومية (نفس functions/src/missions.ts).
class MissionDef {
  const MissionDef(this.id, this.emoji, this.title, this.target, this.coins);

  final String id;
  final String emoji;
  final String title;
  final int target;
  final int coins;
}

const missionDefs = [
  MissionDef('play3', '🎮', 'العب ٣ ألعاب', 3, 300),
  MissionDef('win1', '🏆', 'فز بلعبة', 1, 400),
  MissionDef('legislate1', '📜', 'مرّر قرار وأنت رئيس أو وزير', 1, 250),
  MissionDef('claim2', '📢', 'ادّعِ مرتين بعد ما تحكم', 2, 200),
  MissionDef('react5', '🤨', 'أرسل ٥ ردود سريعة', 5, 100),
];

/// تقدم اللاعب في مهام اليوم.
class MissionState {
  const MissionState({required this.day, required this.progress, required this.claimed});

  factory MissionState.fromJson(Map<String, dynamic>? j) => j == null
      ? const MissionState(day: '', progress: {}, claimed: {})
      : MissionState(
          day: j['day'] as String,
          progress: {
            for (final MapEntry(:key, :value) in ((j['progress'] as Map?) ?? const {}).entries) key as String: value as int,
          },
          claimed: {for (final c in (j['claimed'] as List?) ?? const []) c as String},
        );

  final String day;
  final Map<String, int> progress;
  final Set<String> claimed;

  /// التقدم الفعلي اليوم. لو المحفوظ من يوم قبل، يعتبر صفر.
  MissionState forDay(String today) => day == today ? this : MissionState(day: today, progress: const {}, claimed: const {});

  int progressOf(MissionDef m) => progress[m.id] ?? 0;
  bool isDone(MissionDef m) => progressOf(m) >= m.target;
  bool isClaimable(MissionDef m) => isDone(m) && !claimed.contains(m.id);
}
