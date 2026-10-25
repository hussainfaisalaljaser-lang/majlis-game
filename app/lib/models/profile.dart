import 'missions.dart';

/// ملف اللاعب كما يحفظه السيرفر (functions/src/profile.ts).
class Profile {
  const Profile({
    required this.name,
    required this.avatar,
    required this.setupDone,
    this.dev = false,
    required this.coins,
    required this.diamonds,
    required this.xp,
    required this.level,
    required this.vip,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.lastDaily,
    required this.dailyStreak,
    this.missionsRaw = const MissionState(day: '', progress: {}, claimed: {}),
    this.owned = const {},
    this.frame = 'frame_none',
    this.cards = 'cards_classic',
    this.table = 'table_majlis',
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    name: j['name'] as String,
    avatar: j['avatar'] as String,
    setupDone: j['setupDone'] as bool? ?? false,
    dev: j['dev'] as bool? ?? false,
    coins: j['coins'] as int,
    diamonds: j['diamonds'] as int,
    xp: j['xp'] as int,
    level: j['level'] as int,
    vip: j['vip'] as bool? ?? false,
    gamesPlayed: j['gamesPlayed'] as int,
    gamesWon: j['gamesWon'] as int,
    lastDaily: j['lastDaily'] as String?,
    dailyStreak: j['dailyStreak'] as int,
    missionsRaw: MissionState.fromJson((j['missions'] as Map?)?.cast<String, dynamic>()),
    owned: {for (final o in (j['owned'] as List?) ?? const []) o as String},
    frame: (j['equipped'] as Map?)?['frame'] as String? ?? 'frame_none',
    cards: (j['equipped'] as Map?)?['cards'] as String? ?? 'cards_classic',
    table: (j['equipped'] as Map?)?['table'] as String? ?? 'table_majlis',
  );

  /// للعرض التجريبي بدون سيرفر (نسخة الويب).
  static const demo = Profile(
    name: 'ضيف',
    avatar: 'falcon',
    setupDone: true,
    coins: 2000,
    diamonds: 0,
    xp: 0,
    level: 1,
    vip: false,
    gamesPlayed: 0,
    gamesWon: 0,
    lastDaily: null,
    dailyStreak: 0,
  );

  final String name;
  final String avatar;
  final bool setupDone;

  /// حساب مطور: تطلع له أدوات التجربة.
  final bool dev;
  final int coins;
  final int diamonds;
  final int xp;
  final int level;
  final bool vip;
  final int gamesPlayed;
  final int gamesWon;
  final String? lastDaily;
  final int dailyStreak;
  final MissionState missionsRaw;

  /// أغراض المتجر اللي يملكها، واللي لابسها.
  final Set<String> owned;
  final String frame;
  final String cards;
  final String table;

  /// مهام اليوم (لو المحفوظ من أمس تبدأ من الصفر).
  MissionState get missions => missionsRaw.forDay(gulfDay(DateTime.now()));

  int get claimableMissions => missionDefs.where(missions.isClaimable).length;

  /// كل مستوى أصعب: ١٠٠ خبرة للمستوى ٢، وبعدها كل مستوى يزيد ٥٠ (نفس functions/src/economy.ts).
  static int xpForLevel(int level) {
    final n = level - 1;
    return 100 * n + 50 * n * (n - 1) ~/ 2;
  }

  /// الخبرة المطلوبة من مستواك الحين للي بعده.
  int get xpToNext => 100 + 50 * (level - 1);
  int get xpInLevel => (xp - xpForLevel(level)).clamp(0, xpToNext);
  double get levelProgress => xpInLevel / xpToNext;

  int get winRate => gamesPlayed == 0 ? 0 : (gamesWon * 100 / gamesPlayed).round();

  bool get dailyAvailable => lastDaily != gulfDay(DateTime.now());

  /// رقم اليوم الجاي في سلسلة الهدية (١ إلى ٧).
  int get nextDailyDay {
    final today = gulfDay(DateTime.now());
    final yesterday = gulfDay(DateTime.now().subtract(const Duration(days: 1)));
    if (lastDaily == today) return dailyStreak;
    if (lastDaily == yesterday) return dailyStreak % dailyRewards.length + 1;
    return 1;
  }
}

/// مكافآت الأيام السبعة (نفس functions/src/economy.ts).
const dailyRewards = [
  (coins: 200, diamonds: 0),
  (coins: 300, diamonds: 0),
  (coins: 400, diamonds: 0),
  (coins: 500, diamonds: 0),
  (coins: 700, diamonds: 0),
  (coins: 900, diamonds: 0),
  (coins: 1500, diamonds: 10),
];

/// تاريخ اليوم بتوقيت الخليج (UTC+3).
String gulfDay(DateTime t) => t.toUtc().add(const Duration(hours: 3)).toIso8601String().substring(0, 10);
