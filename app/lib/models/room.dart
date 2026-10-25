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
      at = DateTime.fromMillisecondsSinceEpoch(j['at'] as int);

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
        key as String: (won: (value as Map)['won'] as bool, coins: value['coins'] as int, xp: value['xp'] as int),
    },
    reactions: [
      for (final r in (j['reactions'] as List?) ?? const []) Reaction.fromJson(Map<String, dynamic>.from(r as Map)),
    ],
    opinions: {
      for (final MapEntry(:key, :value) in ((j['opinions'] as Map?) ?? const {}).entries)
        key as String: {for (final o in (value as Map).entries) o.key as String: o.value == 'suspect'},
    },
  );

  final String code;
  final String hostId;
  final RoomStatus status;
  final bool isPrivate;
  final int maxPlayers;
  final String? tierId;
  final List<RoomPlayer> players;
  final int entryFee;

  /// وقت إنشاء الروم. الطاولة العامة تتكمل بالبوتات بعد شوي انتظار.
  final DateTime? createdAt;

  /// نفس functions/src/index.ts → BOT_FILL_AFTER_MS، مع ثواني زيادة احتياط لفرق الساعة.
  static const botFillAfter = Duration(seconds: 25);

  /// اللي كسبه كل لاعب لما انتهت اللعبة.
  final Map<String, ({bool won, int coins, int xp})> results;
  final List<Reaction> reactions;

  /// opinions[من][في] = true لو يشك فيه، false لو يثق فيه.
  final Map<String, Map<String, bool>> opinions;

  RoomPlayer? player(String uid) => players.where((p) => p.uid == uid).firstOrNull;

  /// كم واحد يشك في هذا اللاعب، وكم واحد يثق فيه.
  ({int suspect, int trust}) opinionOf(String uid) {
    var suspect = 0, trust = 0;
    for (final o in opinions.values) {
      final v = o[uid];
      if (v == true) suspect++;
      if (v == false) trust++;
    }
    return (suspect: suspect, trust: trust);
  }
}
