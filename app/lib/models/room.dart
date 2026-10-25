class RoomPlayer {
  const RoomPlayer({required this.uid, required this.name, required this.avatar, this.frame});

  factory RoomPlayer.fromJson(Map<String, dynamic> j) => RoomPlayer(
        uid: j['uid'] as String,
        name: j['name'] as String,
        avatar: j['avatar'] as String,
        frame: j['frame'] as String?,
      );

  final String uid;
  final String name;
  final String avatar;

  /// إطار الصورة من المتجر.
  final String? frame;
}

enum RoomStatus { waiting, playing, finished }

/// الردود السريعة المسموحة. [needsTarget] يعني لازم تختار لاعب (مثل أشك في فلان).
enum ReactionKind {
  suspect('🤨', 'أشك في…', true),
  trust('🤝', 'أثق في…', true),
  liar('❌', 'كذاب', true),
  pick('👉', 'جربوا فلان', true),
  innocent('🙏', 'أنا بريء', false),
  laugh('😂', '', false),
  think('🤔', '', false),
  angry('😡', '', false),
  eyes('👀', '', false),
  zip('🤐', '', false),
  smirk('😏', '', false);

  const ReactionKind(this.emoji, this.label, this.needsTarget);
  final String emoji;
  final String label;
  final bool needsTarget;
}

class Reaction {
  Reaction.fromJson(Map<String, dynamic> j)
      : from = j['from'] as String,
        kind = ReactionKind.values.byName(j['kind'] as String),
        target = j['target'] as String?,
        at = DateTime.fromMillisecondsSinceEpoch(j['at'] as int);

  final String from;
  final ReactionKind kind;
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
        results: {
          for (final MapEntry(:key, :value) in ((j['results'] as Map?) ?? const {}).entries)
            key as String: (
              won: (value as Map)['won'] as bool,
              coins: value['coins'] as int,
              xp: value['xp'] as int,
            ),
        },
        reactions: [
          for (final r in (j['reactions'] as List?) ?? const []) Reaction.fromJson(Map<String, dynamic>.from(r as Map)),
        ],
        opinions: {
          for (final MapEntry(:key, :value) in ((j['opinions'] as Map?) ?? const {}).entries)
            key as String: {
              for (final o in (value as Map).entries) o.key as String: o.value == 'suspect',
            },
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
