import 'clan.dart';
import 'leaderboard.dart' show gulfWeek;
import 'missions.dart';
import 'tour.dart';
import 'shop.dart';

/// ملف اللاعب كما يحفظه السيرفر (functions/src/profile.ts).
class Profile {
  const Profile({
    required this.name,
    required this.avatar,
    required this.setupDone,
    this.dev = false,
    this.owner = false,
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
    this.bubble = 'bubble_classic',
    this.temp = const {},
    this.gifts = const [],
    this.pass = const PassState(),
    this.passMissionsRaw = const PassMissionState(),
    this.tutorialDone = false,
    this.stats = const {},
    this.badges = const {},
    this.blocked = const {},
    this.renamed = false,
    this.rankPoints = 0,
    this.rankBest = 0,
    this.pid = '',
    this.pidTier = 0,
    this.friends = const [],
    this.friendReqs = const {},
    this.sentReqs = const {},
    this.invite,
    this.favorites = const [],
    this.clan,
    this.tour,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    name: j['name'] as String,
    avatar: j['avatar'] as String,
    setupDone: j['setupDone'] as bool? ?? false,
    dev: j['dev'] as bool? ?? false,
    owner: j['owner'] as bool? ?? false,
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
    bubble: (j['equipped'] as Map?)?['bubble'] as String? ?? 'bubble_classic',
    temp: {
      for (final MapEntry(:key, :value) in ((j['temp'] as Map?) ?? const {}).entries)
        key as String: DateTime.fromMillisecondsSinceEpoch((value as num).toInt()),
    },
    gifts: [for (final g in (j['gifts'] as List?) ?? const []) Gift.fromJson(Map<String, dynamic>.from(g as Map))],
    pass: PassState.fromJson((j['pass'] as Map?)?.cast<String, dynamic>()),
    passMissionsRaw: PassMissionState.fromJson((j['passMissions'] as Map?)?.cast<String, dynamic>(), season.id),
    tutorialDone: j['tutorialDone'] as bool? ?? false,
    stats: _ints(j['stats']),
    badges: _ints(j['badges']),
    blocked: {for (final b in (j['blocked'] as List?) ?? const []) b as String},
    renamed: j['renamed'] as bool? ?? false,
    rankPoints: (j['rank'] as Map?)?['season'] == season.id ? ((j['rank'] as Map)['points'] as num).toInt() : 0,
    rankBest: (j['rank'] as Map?)?['season'] == season.id ? ((j['rank'] as Map)['best'] as num).toInt() : 0,
    pid: j['pid'] as String? ?? '',
    pidTier: (j['pidTier'] as num?)?.toInt() ?? 0,
    friends: [for (final f in (j['friends'] as List?) ?? const []) f as String],
    friendReqs: _ints(j['friendReqs']),
    sentReqs: {for (final s in (j['sentReqs'] as List?) ?? const []) s as String},
    invite: j['invite'] == null ? null : Invite.fromJson(Map<String, dynamic>.from(j['invite'] as Map)),
    favorites: [for (final f in (j['favorites'] as List?) ?? const []) f as String],
    clan: ClanTag.maybe(j['clan']),
    tour: TourState.maybe(j['tour']),
  );

  static Map<String, int> _ints(Object? m) => {
    for (final MapEntry(:key, :value) in ((m as Map?) ?? const {}).entries) key as String: (value as num).toInt(),
  };

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

  /// صاحب اللعبة: يقدر يخلي أي لاعب مطوّر برمزه.
  final bool owner;
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
  final String bubble;

  /// أغراض مؤقتة (أبطال الأسبوع) ولين متى.
  final Map<String, DateTime> temp;

  /// خلّص لعبة الشرح (وأخذ مكافأتها).
  final bool tutorialDone;

  /// إحصائيات الإنجازات (games، caught…) ودرجة كل إنجاز وصله.
  final Map<String, int> stats;
  final Map<String, int> badges;

  /// لاعبين حظرهم: ما يشوف ردودهم ولا رأيهم.
  final Set<String> blocked;

  /// اسمه انغيّر لأنه انبلغ عنه: نطلب منه يختار اسم جديد.
  final bool renamed;

  /// نقاط التصنيف في الموسم الحالي، وأعلى نقاط وصلها فيه.
  final int rankPoints;
  final int rankBest;

  /// رمزه اللي يبحثون فيه عنه، ودرجته (٠ عادي … ٤ أسطوري).
  final String pid;
  final int pidTier;

  /// أصدقاؤه، وطلبات الصداقة اللي وصلته (مين ← متى)، واللي أرسلها وما انردت.
  final List<String> friends;
  final Map<String, int> friendReqs;
  final Set<String> sentReqs;

  /// آخر دعوة وصلته من صديق لروم.
  final Invite? invite;

  /// ملصقاته المفضلة (بالكثير [maxFavorites])، تطلع جنب زر التفاعل في اللعب.
  final List<String> favorites;

  /// نفس functions/src/index.ts → MAX_FAVORITES.
  static const maxFavorites = 5;

  /// ديوانه (أو null).
  final ClanTag? clan;

  /// بطولة الأسبوع اللي سجّل فيها آخر مرة.
  final TourState? tour;

  /// هدايا وصلت وما شافها (مستويات أو بطولة).
  final List<Gift> gifts;

  /// الباتل باس للموسم الحالي.
  final PassState pass;

  /// مهام الباتل باس (الأسبوعية والموسم).
  final PassMissionState passMissionsRaw;

  /// مهام الباتل باس هالأسبوع (لو المحفوظ من أسبوع قبل، الأسبوعية من الصفر).
  PassMissionState get passMissions => passMissionsRaw.forWeek(gulfWeek(DateTime.now()));

  /// كم مهمة باتل باس خلصها وما استلمها.
  int get claimablePassMissions => [...weeklyMissions, ...seasonMissions].where(passMissions.isClaimable).length;

  /// يملك الغرض؟ (الأساسي، أو اشتراه أو أخذه هدية، أو مؤقت وما خلص). نفس functions/src/profile.ts → owns.
  bool owns(String id) {
    if (shopItem(id)?.isDefault ?? false) return true;
    if (owned.contains(id)) return true;
    final until = temp[id];
    return until != null && until.isAfter(DateTime.now());
  }

  /// يقدر يختار هالشخصية؟
  bool ownsAvatar(String avatar) => freeAvatars.contains(avatar) || owns('avatar_$avatar');

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

/// هدية وصلت اللاعب (functions/src/profile.ts → Gift).
class Gift {
  Gift.fromJson(Map<String, dynamic> j)
    : champion = j['kind'] == 'champion',
      tutorial = j['kind'] == 'tutorial',
      achievement = j['kind'] == 'achievement' ? j['ach'] as String? : null,
      rank = j['kind'] == 'rank',
      tour = j['kind'] == 'tour',
      passFrom = j['kind'] == 'passGift' ? (j['from'] as String? ?? 'صاحبك') : null,
      n = (j['n'] as num).toInt(),
      coins = (j['coins'] as num?)?.toInt() ?? 0,
      diamonds = (j['diamonds'] as num?)?.toInt() ?? 0,
      items = [for (final i in (j['items'] as List?) ?? const []) i as String];

  /// بطولة الأسبوع (وإلا هدية مستوى).
  final bool champion;

  /// مكافأة أول لعبة شرح.
  final bool tutorial;

  /// معرف الإنجاز لو الهدية درجة إنجاز (و[n] الدرجة).
  final String? achievement;

  /// وصل رتبة تصنيف جديدة ([n] رقمها في rankTiers).
  final bool rank;

  /// بطل بطولة الأسبوع.
  final bool tour;

  /// هدية باتل باس من صاحب: اسمه ([n] = ١ لو الباتل باس كامل).
  final String? passFrom;

  /// المستوى، أو المركز للبطولة.
  final int n;
  final int coins;
  final int diamonds;
  final List<String> items;
}

/// الباتل باس (functions/src/rewards.ts → PassState).
class PassState {
  const PassState({this.points = 0, this.premium = false, this.free = 0, this.prem = 0});

  factory PassState.fromJson(Map<String, dynamic>? j) {
    if (j == null || j['season'] != season.id) return const PassState();
    return PassState(
      points: (j['points'] as num?)?.toInt() ?? 0,
      premium: j['premium'] as bool? ?? false,
      free: (j['free'] as num?)?.toInt() ?? 0,
      prem: (j['prem'] as num?)?.toInt() ?? 0,
    );
  }

  final int points;
  final bool premium;

  /// آخر درجة استلمها في المجاني والمدفوع.
  final int free;
  final int prem;

  int get tier => season.tierFor(points);

  /// نقاطه داخل الدرجة الحالية.
  int get pointsInTier => tier >= season.tiers ? season.tierPoints : points - tier * season.tierPoints;

  /// فيه مكافآت وصلها وما استلمها؟
  bool get claimable {
    for (var t = free + 1; t <= tier; t++) {
      if (season.free.containsKey(t)) return true;
    }
    if (premium) {
      for (var t = prem + 1; t <= tier; t++) {
        if (season.premium.containsKey(t)) return true;
      }
    }
    return false;
  }
}

/// دعوة من صديق لرومه.
class Invite {
  const Invite({required this.from, required this.name, required this.code, required this.at});

  Invite.fromJson(Map<String, dynamic> j)
    : from = j['from'] as String,
      name = j['name'] as String,
      code = j['code'] as String,
      at = DateTime.fromMillisecondsSinceEpoch((j['at'] as num).toInt());

  final String from;
  final String name;
  final String code;
  final DateTime at;
}
