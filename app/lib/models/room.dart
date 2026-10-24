class RoomPlayer {
  const RoomPlayer({required this.uid, required this.name, required this.avatar});

  factory RoomPlayer.fromJson(Map<String, dynamic> j) =>
      RoomPlayer(uid: j['uid'] as String, name: j['name'] as String, avatar: j['avatar'] as String);

  final String uid;
  final String name;
  final String avatar;
}

enum RoomStatus { waiting, playing, finished }

class Room {
  const Room({
    required this.code,
    required this.hostId,
    required this.status,
    required this.isPrivate,
    required this.maxPlayers,
    required this.tierId,
    required this.players,
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
        code: j['code'] as String,
        hostId: j['hostId'] as String,
        status: RoomStatus.values.byName(j['status'] as String),
        isPrivate: j['isPrivate'] as bool,
        maxPlayers: j['maxPlayers'] as int,
        tierId: j['tierId'] as String?,
        players: [for (final p in j['players'] as List) RoomPlayer.fromJson(Map<String, dynamic>.from(p as Map))],
      );

  final String code;
  final String hostId;
  final RoomStatus status;
  final bool isPrivate;
  final int maxPlayers;
  final String? tierId;
  final List<RoomPlayer> players;
}
