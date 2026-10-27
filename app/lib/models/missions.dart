/// المهام اليومية (نفس functions/src/missions.ts).
class MissionDef {
  const MissionDef(this.id, this.icon, this.title, this.target, this.coins);

  final String id;

  /// أيقونة المهمة (assets/icons/gfx_*.png).
  final String icon;
  final String title;
  final int target;
  final int coins;
}

/// نقاط الباتل باس لكل مهمة يومية (نفس functions/src/economy.ts → MISSION_PASS_POINTS).
const missionPassPoints = 25;

const missionDefs = [
  MissionDef('play3', 'games', 'العب ٣ ألعاب', 3, 300),
  MissionDef('win1', 'trophy', 'فز بلعبة', 1, 400),
  MissionDef('legislate1', 'log', 'مرّر قرار وأنت رئيس أو وزير', 1, 250),
  MissionDef('claim2', 'megaphone', 'ادّعِ مرتين بعد ما تحكم', 2, 200),
  MissionDef('react5', 'chat', 'أرسل ٥ ردود سريعة', 5, 100),
];

/// تقدم اللاعب في مهام اليوم.
class MissionState {
  const MissionState({required this.day, required this.progress, required this.claimed});

  factory MissionState.fromJson(Map<String, dynamic>? j) => j == null
      ? const MissionState(day: '', progress: {}, claimed: {})
      : MissionState(
          day: j['day'] as String,
          progress: {
            for (final MapEntry(:key, :value) in ((j['progress'] as Map?) ?? const {}).entries)
              key as String: value as int,
          },
          claimed: {for (final c in (j['claimed'] as List?) ?? const []) c as String},
        );

  final String day;
  final Map<String, int> progress;
  final Set<String> claimed;

  /// التقدم الفعلي اليوم. لو المحفوظ من يوم قبل، يعتبر صفر.
  MissionState forDay(String today) =>
      day == today ? this : MissionState(day: today, progress: const {}, claimed: const {});

  int progressOf(MissionDef m) => progress[m.id] ?? 0;
  bool isDone(MissionDef m) => progressOf(m) >= m.target;
  bool isClaimable(MissionDef m) => isDone(m) && !claimed.contains(m.id);
}

/// مهمة باتل باس (نفس functions/src/missions.ts → WEEKLY_MISSIONS و SEASON_MISSIONS): تعطي نقاط باتل باس.
class PassMissionDef {
  const PassMissionDef(this.id, this.stat, this.icon, this.title, this.target, this.points);

  final String id;

  /// الإحصائية اللي تتقدم فيها (PassStat في السيرفر).
  final String stat;
  final String icon;
  final String title;
  final int target;
  final int points;
}

/// مهام الأسبوع (تتجدد كل أحد بتوقيت الخليج).
const weeklyMissions = [
  PassMissionDef('w_play10', 'play', 'games', 'العب ١٠ ألعاب', 10, 120),
  PassMissionDef('w_win5', 'win', 'trophy', 'فز ٥ ألعاب', 5, 150),
  PassMissionDef('w_traitor', 'winTraitor', 'dagger', 'فز وأنت من الخونة', 1, 150),
  PassMissionDef('w_ten', 'win10', 'friends', 'فز في طاولة ١٠ لاعبين', 1, 150),
  PassMissionDef('w_laws', 'loyalLaw', 'scales', 'مرّر ٣ قرارات زرقاء وأنت وزير', 3, 120),
];

/// مهام الموسم كله (لين نهاية الباتل باس).
const seasonMissions = [
  PassMissionDef('s_leader3', 'killLeader', 'skull', 'اطرد زعيم الخونة ٣ مرات وأنت رئيس', 3, 400),
  PassMissionDef('s_minister', 'leaderMinister', 'crown', 'فز وأنت الزعيم بعد ما تصير وزير', 1, 500),
  PassMissionDef('s_traitor10', 'winTraitor', 'dagger', 'فز ١٠ مرات وأنت من الخونة', 10, 400),
  PassMissionDef('s_ten5', 'win10', 'friends', 'فز ٥ مرات في طاولة ١٠ لاعبين', 5, 400),
  PassMissionDef('s_win30', 'win', 'trophy', 'فز ٣٠ لعبة', 30, 500),
  PassMissionDef('s_found5', 'found', 'search', 'اكشف ٥ خونة بالتحقيق', 5, 300),
  PassMissionDef('s_roles10', 'rolesGame', 'seer', 'العب ١٠ ألعاب في الطور المطوّر', 10, 300),
  PassMissionDef('s_play50', 'play', 'games', 'العب ٥٠ لعبة', 50, 300),
];

/// تقدم مهام الباتل باس: هالأسبوع وكل الموسم (functions/src/missions.ts → PassMissionState).
class PassMissionState {
  const PassMissionState({
    this.week = '',
    this.weekly = const {},
    this.total = const {},
    this.weeklyClaimed = const {},
    this.seasonClaimed = const {},
  });

  /// [seasonId] الموسم الحالي: لو المحفوظ من موسم قبل، يبدأ من الصفر.
  factory PassMissionState.fromJson(Map<String, dynamic>? j, String seasonId) {
    if (j == null || j['season'] != seasonId) return const PassMissionState();
    Map<String, int> counts(Object? m) => {
      for (final MapEntry(:key, :value) in ((m as Map?) ?? const {}).entries) key as String: (value as num).toInt(),
    };
    return PassMissionState(
      week: j['week'] as String? ?? '',
      weekly: counts(j['weekly']),
      total: counts(j['total']),
      weeklyClaimed: {for (final c in (j['weeklyClaimed'] as List?) ?? const []) c as String},
      seasonClaimed: {for (final c in (j['seasonClaimed'] as List?) ?? const []) c as String},
    );
  }

  final String week;
  final Map<String, int> weekly;
  final Map<String, int> total;
  final Set<String> weeklyClaimed;
  final Set<String> seasonClaimed;

  /// لو المحفوظ من أسبوع قبل، الأسبوعية تبدأ من الصفر (والموسم يبقى).
  PassMissionState forWeek(String now) =>
      week == now ? this : PassMissionState(week: now, total: total, seasonClaimed: seasonClaimed);

  bool isWeekly(PassMissionDef m) => m.id.startsWith('w_');
  int progressOf(PassMissionDef m) => ((isWeekly(m) ? weekly : total)[m.stat] ?? 0).clamp(0, m.target);
  bool isClaimed(PassMissionDef m) => (isWeekly(m) ? weeklyClaimed : seasonClaimed).contains(m.id);
  bool isClaimable(PassMissionDef m) => !isClaimed(m) && progressOf(m) >= m.target;
}
