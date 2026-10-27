class RoomPlayer {
  const RoomPlayer({
    required this.uid,
    required this.name,
    required this.avatar,
    this.frame,
    this.bubble,
    this.bot = false,
  });

  factory RoomPlayer.fromJson(Map<String, dynamic> j) => RoomPlayer(
    uid: j['uid'] as String,
    name: j['name'] as String,
    avatar: j['avatar'] as String,
    frame: j['frame'] as String?,
    bubble: j['bubble'] as String?,
    bot: j['bot'] as bool? ?? false,
  );

  /// لاعب آلي.
  final bool bot;

  final String uid;
  final String name;
  final String avatar;

  /// إطار الصورة من المتجر.
  final String? frame;

  /// شكل فقاعة الكلام من المتجر.
  final String? bubble;
}

enum RoomStatus { waiting, playing, finished }

class Reaction {
  Reaction.fromJson(Map<String, dynamic> j)
    : from = j['from'] as String,
      kind = j['kind'] as String,
      target = j['target'] as String?,
      at = DateTime.fromMillisecondsSinceEpoch((j['at'] as num).toInt());

  final String from;

  /// كلام (models/catalog.dart → textReactions) أو ملصق (stickers).
  final String kind;
  final String? target;
  final DateTime at;
}

class Room {
  const Room({
    required this.code,
    required this.hostId,
    required this.status,
    required this.isPrivate,
    required this.maxPlayers,
    required this.tierId,
    required this.players,
    this.entryFee = 0,
    this.createdAt,
    this.results = const {},
    this.reactions = const [],
    this.opinions = const {},
    this.quick = false,
    this.roles = false,
    this.gone = const {},
    this.next,
    this.watchers = const [],
    this.tour,
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
    code: j['code'] as String,
    hostId: j['hostId'] as String,
    status: RoomStatus.values.byName(j['status'] as String),
    isPrivate: j['isPrivate'] as bool,
    maxPlayers: j['maxPlayers'] as int,
    tierId: j['tierId'] as String?,
    players: [for (final p in j['players'] as List) RoomPlayer.fromJson(Map<String, dynamic>.from(p as Map))],
    entryFee: j['entryFee'] as int? ?? 0,
    createdAt: j['createdAtMs'] == null ? null : DateTime.fromMillisecondsSinceEpoch(j['createdAtMs'] as int),
    results: {
      for (final MapEntry(:key, :value) in ((j['results'] as Map?) ?? const {}).entries)
        key as String: (
          won: (value as Map)['won'] as bool,
          coins: value['coins'] as int,
          xp: value['xp'] as int,
          rank: (value['rank'] as num?)?.toInt(),
          boost: (value['boost'] as num?)?.toInt() ?? 1,
          tour: (value['tour'] as Map?) == null
              ? null
              : (
                  stage: ((value['tour'] as Map)['stage'] as num).toInt(),
                  out: (value['tour'] as Map)['out'] == true,
                  champion: (value['tour'] as Map)['champion'] == true,
                ),
        ),
    },
    reactions: [
      for (final r in (j['reactions'] as List?) ?? const []) Reaction.fromJson(Map<String, dynamic>.from(r as Map)),
    ],
    opinions: {
      for (final MapEntry(:key, :value) in ((j['opinions'] as Map?) ?? const {}).entries)
        key as String: {for (final o in (value as Map).entries) o.key as String: o.value == 'suspect'},
    },
    quick: j['quick'] as bool? ?? false,
    roles: j['roles'] as bool? ?? false,
    gone: {for (final g in (j['gone'] as List?) ?? const []) g as String},
    next: j['next'] as String?,
    watchers: [for (final w in (j['watchers'] as List?) ?? const []) w as String],
    tour: (j['tour'] as num?)?.toInt(),
  );

  final String code;
  final String hostId;
  final RoomStatus status;
  final bool isPrivate;
  final int maxPlayers;
  final String? tierId;
  final List<RoomPlayer> players;
  final int entryFee;

  /// الوضع السريع: الوقت نص، واللعبة حوالي ٥ دقايق.
  final bool quick;

  /// طور الشخصيات (العرّاف والحارس والقاضي والشيخ والجاسوس). بدونه الطور العادي: الزعيم والخونة والأوفياء بس.
  final bool roles;

  /// وقت إنشاء الروم. الطاولة العامة تتكمل بالبوتات بعد شوي انتظار.
  final DateTime? createdAt;

  /// نفس functions/src/index.ts → BOT_FILL_AFTER_MS، مع ثواني زيادة احتياط لفرق الساعة.
  static const botFillAfter = Duration(seconds: 25);

  /// اللي كسبه كل لاعب لما انتهت اللعبة.
  final Map<String, ({bool won, int coins, int xp, int? rank, int boost, ({int stage, bool out, bool champion})? tour})>
  results;
  final List<Reaction> reactions;

  /// opinions[من][في] = true لو يشك فيه، false لو يثق فيه.
  final Map<String, Map<String, bool>> opinions;

  /// اللي طلعوا من الطاولة بعد ما خلصت اللعبة.
  final Set<String> gone;

  /// «العب مرة ثانية»: كود الروم الجديد بنفس الإعدادات (لو أحد ضغطها).
  final String? next;

  /// أصحاب اللاعبين اللي يتفرجون الحين.
  final List<String> watchers;

  /// طاولة بطولة الأسبوع: أي دور (٠ الأول، ١ نص النهائي، ٢ النهائي).
  final int? tour;

  RoomPlayer? player(String uid) => players.where((p) => p.uid == uid).firstOrNull;

  /// كم واحد يشك في هذا اللاعب، وكم واحد يثق فيه. رأي اللي حظرتهم ما ينحسب عندك.
  ({int suspect, int trust}) opinionOf(String uid, {Set<String> ignore = const {}}) {
    var suspect = 0, trust = 0;
    for (final MapEntry(key: from, value: o) in opinions.entries) {
      if (ignore.contains(from)) continue;
      final v = o[uid];
      if (v == true) suspect++;
      if (v == false) trust++;
    }
    return (suspect: suspect, trust: trust);
  }
}
