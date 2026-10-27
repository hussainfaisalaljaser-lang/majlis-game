/// نسخة اللاعب من اللعبة كما يرسلها السيرفر (engine/src/view.ts).
library;

enum Role { loyal, traitor, leader }

/// أدوار خاصة: العرّاف والحارس لبعض الأوفياء، والقاضي والشيخ والجاسوس لأي لاعب إلا الزعيم.
enum Special { seer, guardian, judge, elder, spy }

enum Phase { nomination, election, presidentDiscard, chancellorEnact, vetoResponse, power, gameOver }

enum Power { investigate, peek, specialElection, execute }

/// قرار: أزرق للأوفياء أو أحمر للخونة.
enum Policy {
  loyal('L'),
  traitor('T');

  const Policy(this.code);
  final String code;

  static Policy parse(Object? code) => code == 'L' ? loyal : traitor;
}

class ViewPlayer {
  ViewPlayer.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      name = j['name'] as String,
      seat = j['seat'] as int,
      alive = j['alive'] as bool,
      knownRole = j['knownRole'] == null ? null : Role.values.byName(j['knownRole'] as String),
      knownSpecial = j['knownSpecial'] == null ? null : Special.values.byName(j['knownSpecial'] as String),
      hasVoted = j['hasVoted'] as bool;

  final String id;
  final String name;
  final int seat;
  final bool alive;
  final Role? knownRole;

  /// الدور الخاص لو تعرفه (دورك أنت، أو حارس انكشف، أو بعد نهاية اللعبة).
  final Special? knownSpecial;
  final bool hasVoted;
}

class Investigation {
  Investigation.fromJson(Map<String, dynamic> j) : target = j['target'] as String, traitor = j['team'] == 'traitor';

  final String target;
  final bool traitor;
}

class Claim {
  const Claim({required this.round, required this.by, required this.president, required this.policies});

  final int round;
  final String by;
  final bool president;
  final List<Policy> policies;
}

/// حدث في السجل. نحتفظ بالبيانات الخام عشان كل نوع له حقوله.
class GameEvent {
  GameEvent.fromJson(this.data) : type = data['type'] as String, round = data['round'] as int;

  final String type;
  final int round;
  final Map<String, dynamic> data;
}

class GameView {
  /// [perspective]: للمتفرج، اللاعب اللي يتفرج عليه (يقعد تحت في الطاولة).
  GameView.fromJson(Map<String, dynamic> j, {String? perspective})
    : spectator = j['spectator'] == true,
      you = j['spectator'] == true && perspective != null ? perspective : j['you'] as String,
      tutorial = j['tutorial'] as bool? ?? false,
      quick = j['quick'] as bool? ?? false,
      yourRole = Role.values.byName(j['yourRole'] as String),
      yourSpecial = j['yourSpecial'] == null ? null : Special.values.byName(j['yourSpecial'] as String),
      seerSees = j['seerSees'] as String?,
      seerReady = j['seerReady'] as bool? ?? false,
      judgeReady = j['judgeReady'] as bool? ?? false,
      spyReady = j['spyReady'] as bool? ?? false,
      spySaw = (j['spySaw'] as Map?) == null
          ? null
          : (card: Policy.parse((j['spySaw'] as Map)['card']), round: ((j['spySaw'] as Map)['round'] as num).toInt()),
      truths = (j['truths'] as Map?) == null
          ? null
          : {
              for (final MapEntry(:key, :value) in (j['truths'] as Map).entries)
                int.parse('$key'): (
                  president: [for (final c in ((value as Map)['president'] as List?) ?? const []) Policy.parse(c)],
                  chancellor: [for (final c in (value['chancellor'] as List?) ?? const []) Policy.parse(c)],
                ),
            },
      autopilot = {for (final id in (j['autopilot'] as List?) ?? const []) id as String},
      players = [for (final p in j['players'] as List) ViewPlayer.fromJson(_map(p))],
      phase = Phase.values.byName(j['phase'] as String),
      round = j['round'] as int,
      presidentId = j['presidentId'] as String,
      nomineeId = j['nomineeId'] as String?,
      lastPresident = (j['lastElected'] as Map?)?['president'] as String?,
      lastChancellor = (j['lastElected'] as Map?)?['chancellor'] as String?,
      electionTracker = j['electionTracker'] as int,
      drawPileCount = j['drawPileCount'] as int,
      discardPileCount = j['discardPileCount'] as int? ?? 0,
      loyalPolicies = j['loyalPolicies'] as int,
      traitorPolicies = j['traitorPolicies'] as int,
      pendingPower = j['pendingPower'] == null ? null : Power.values.byName(j['pendingPower'] as String),
      hand = [for (final c in j['hand'] as List) Policy.parse(c)],
      peeked = (j['peeked'] as List?)?.map(Policy.parse).toList(),
      canVeto = j['canVeto'] as bool,
      investigations = [for (final i in j['yourInvestigations'] as List) Investigation.fromJson(_map(i))],
      claimCount = (j['claimable'] as Map?)?['count'] as int?,
      claimTruth = ((j['claimable'] as Map?)?['truth'] as List?)?.map(Policy.parse).toList(),
      winnerLoyal = j['winner'] == null ? null : j['winner'] == 'loyal',
      winReason = j['winReason'] as String?,
      log = [for (final e in j['log'] as List) GameEvent.fromJson(_map(e))],
      deadline = j['deadline'] == null ? null : DateTime.fromMillisecondsSinceEpoch((j['deadline'] as num).toInt());

  static Map<String, dynamic> _map(Object? o) => Map<String, dynamic>.from(o as Map);

  /// نسخة المتفرج (صاحب يتفرج): [you] هو اللاعب اللي يتفرج عليه، وما فيه ولا سر.
  final bool spectator;

  final String you;

  /// اسم اللاعب، و«أنت» لو هو أنت (مو للمتفرج).
  String nameOf(String id) => id == you && !spectator ? 'أنت' : player(id).name;

  /// لعبة الشرح: الراوي يطلع نصايح لكل خطوة.
  final bool tutorial;

  /// الوضع السريع: وقت كل دور نص الوقت العادي.
  final bool quick;
  final Role yourRole;
  final Special? yourSpecial;

  /// لو أنت العرّاف: الخائن اللي تعرفه من البداية.
  final String? seerSees;

  /// أنت العرّاف وكشفك لسا ما استخدمته.
  final bool seerReady;

  /// أنت القاضي، والتصويت شغال وما صوّتت، وإلغاؤك ما استخدمته.
  final bool judgeReady;

  /// أنت الجاسوس وما شفت الكومة للحين.
  final bool spyReady;

  /// لو أنت الجاسوس وشفت: أول كرت كان بالكومة، وأي جولة.
  final ({Policy card, int round})? spySaw;

  /// بعد نهاية اللعبة: الكروت الحقيقية اللي وصلت كل حكومة (الجولة ← كروت الرئيس واللي عطاها الوزير).
  final Map<int, ({List<Policy> president, List<Policy> chancellor})>? truths;

  /// لاعبين طلعوا أو انطردوا، ويلعب بدالهم بوت.
  final Set<String> autopilot;
  final List<ViewPlayer> players;
  final Phase phase;
  final int round;
  final String presidentId;
  final String? nomineeId;
  final String? lastPresident;
  final String? lastChancellor;
  final int electionTracker;
  final int drawPileCount;
  final int discardPileCount;
  final int loyalPolicies;
  final int traitorPolicies;
  final Power? pendingPower;
  final List<Policy> hand;
  final List<Policy>? peeked;
  final bool canVeto;
  final List<Investigation> investigations;

  /// كم كرت تقدر تدّعي (٣ للرئيس، ٢ للوزير)، أو null لو ما لك ادعاء.
  final int? claimCount;

  /// الكروت اللي وصلتك فعلاً في الحكومة اللي تدّعي عنها (من السيرفر).
  final List<Policy>? claimTruth;
  final bool? winnerLoyal;
  final String? winReason;
  final List<GameEvent> log;

  /// آخر وقت للدور الحالي. بعده السيرفر يلعب بدال اللي تأخر.
  final DateTime? deadline;

  ViewPlayer player(String id) => players.firstWhere((p) => p.id == id);
  ViewPlayer get me => player(you);
  bool get amPresident => presidentId == you;
  bool get amNominee => nomineeId == you;
  List<ViewPlayer> get alive => players.where((p) => p.alive).toList();

  /// نفس قاعدة السيرفر: مو نفسك، ولا الوزير السابق، ولا الرئيس السابق لو الأحياء أكثر من ٥.
  List<ViewPlayer> get eligibleChancellors {
    final aliveCount = alive.length;
    return alive
        .where((p) => p.id != presidentId && p.id != lastChancellor)
        .where((p) => aliveCount <= 5 || p.id != lastPresident)
        .toList();
  }

  List<Claim> get claims => [
    for (final e in log)
      if (e.type == 'claim')
        Claim(
          round: e.round,
          by: (e.data['claim'] as Map)['by'] as String,
          president: (e.data['claim'] as Map)['office'] == 'president',
          policies: [for (final c in (e.data['claim'] as Map)['policies'] as List) Policy.parse(c)],
        ),
  ];

  /// القدرات حسب عدد اللاعبين، لعرضها على مسار الخونة (نفس engine/src/rules.ts).
  List<Power?> get traitorTrackPowers {
    final n = players.length;
    if (n <= 6) return [null, null, Power.peek, Power.execute, Power.execute, null];
    if (n <= 8) return [null, Power.investigate, Power.specialElection, Power.execute, Power.execute, null];
    return [Power.investigate, Power.investigate, Power.specialElection, Power.execute, Power.execute, null];
  }
}

/// حكومة مررت قرار، للكشف بعد اللعبة («مين كذب؟»): وش وصل كل واحد فعلاً ووش قال.
class GovernmentRecord {
  const GovernmentRecord({
    required this.round,
    required this.president,
    required this.chancellor,
    required this.enacted,
    this.presidentDrew,
    this.chancellorGot,
    this.presidentSaid,
    this.chancellorSaid,
  });

  final int round;
  final String president;
  final String chancellor;
  final Policy enacted;

  /// الكروت الحقيقية (من السيرفر بعد اللعبة).
  final List<Policy>? presidentDrew;
  final List<Policy>? chancellorGot;

  /// ادعاءاتهم (null لو ما قال شي).
  final List<Policy>? presidentSaid;
  final List<Policy>? chancellorSaid;

  static int _blues(List<Policy> l) => l.where((c) => c == Policy.loyal).length;

  /// كذب؟ (عدد الأزرق في كلامه غير اللي وصله). null لو ما ادعى أو ما نعرف الحقيقة.
  bool? get presidentLied =>
      presidentSaid == null || presidentDrew == null ? null : _blues(presidentSaid!) != _blues(presidentDrew!);
  bool? get chancellorLied =>
      chancellorSaid == null || chancellorGot == null ? null : _blues(chancellorSaid!) != _blues(chancellorGot!);
}

extension Governments on GameView {
  /// كل حكومة مررت قرار (مو الفوضى ولا الفيتو)، بالترتيب، ومعها الحقيقة والادعاءات.
  List<GovernmentRecord> get governments {
    final said = <(int, bool), List<Policy>>{for (final c in claims) (c.round, c.president): c.policies};
    return [
      for (final e in log)
        if (e.type == 'enacted' && e.data['chaos'] != true && e.data['government'] is Map)
          GovernmentRecord(
            round: e.round,
            president: (e.data['government'] as Map)['president'] as String,
            chancellor: (e.data['government'] as Map)['chancellor'] as String,
            enacted: Policy.parse(e.data['policy']),
            presidentDrew: truths?[e.round]?.president.length == 3 ? truths![e.round]!.president : null,
            chancellorGot: truths?[e.round]?.chancellor.length == 2 ? truths![e.round]!.chancellor : null,
            presidentSaid: said[(e.round, true)],
            chancellorSaid: said[(e.round, false)],
          ),
    ];
  }
}

/// هل ادعاء الرئيس والوزير متناقضين؟ الوزير لازم يكون وصله نفس كروت الرئيس ناقص واحد.
bool claimsContradict(List<Policy> president, List<Policy> chancellor, Policy? enacted) {
  int count(List<Policy> l, Policy p) => l.where((c) => c == p).length;
  final presT = count(president, Policy.traitor);
  final chanT = count(chancellor, Policy.traitor);
  final fits = chanT == presT || chanT == presT - 1;
  final enactedFits = enacted == null || chancellor.contains(enacted);
  return !fits || !enactedFits;
}
