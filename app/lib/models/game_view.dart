/// نسخة اللاعب من اللعبة كما يرسلها السيرفر (engine/src/view.ts).
library;

enum Role { loyal, traitor, leader }

/// أدوار خاصة لبعض الأوفياء.
enum Special { seer, guardian }

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
  Investigation.fromJson(Map<String, dynamic> j)
      : target = j['target'] as String,
        traitor = j['team'] == 'traitor';

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
  GameEvent.fromJson(this.data)
      : type = data['type'] as String,
        round = data['round'] as int;

  final String type;
  final int round;
  final Map<String, dynamic> data;
}

class GameView {
  GameView.fromJson(Map<String, dynamic> j)
      : you = j['you'] as String,
        yourRole = Role.values.byName(j['yourRole'] as String),
        yourSpecial = j['yourSpecial'] == null ? null : Special.values.byName(j['yourSpecial'] as String),
        seerSees = j['seerSees'] as String?,
        seerReady = j['seerReady'] as bool? ?? false,
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
        winnerLoyal = j['winner'] == null ? null : j['winner'] == 'loyal',
        winReason = j['winReason'] as String?,
        log = [for (final e in j['log'] as List) GameEvent.fromJson(_map(e))],
        deadline = j['deadline'] == null ? null : DateTime.fromMillisecondsSinceEpoch(j['deadline'] as int);

  static Map<String, dynamic> _map(Object? o) => Map<String, dynamic>.from(o as Map);

  final String you;
  final Role yourRole;
  final Special? yourSpecial;

  /// لو أنت العرّاف: الخائن اللي تعرفه من البداية.
  final String? seerSees;

  /// أنت العرّاف وكشفك لسا ما استخدمته.
  final bool seerReady;
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

/// هل ادعاء الرئيس والوزير متناقضين؟ الوزير لازم يكون وصله نفس كروت الرئيس ناقص واحد.
bool claimsContradict(List<Policy> president, List<Policy> chancellor, Policy? enacted) {
  int count(List<Policy> l, Policy p) => l.where((c) => c == p).length;
  final presT = count(president, Policy.traitor);
  final chanT = count(chancellor, Policy.traitor);
  final fits = chanT == presT || chanT == presT - 1;
  final enactedFits = enacted == null || chancellor.contains(enacted);
  return !fits || !enactedFits;
}
