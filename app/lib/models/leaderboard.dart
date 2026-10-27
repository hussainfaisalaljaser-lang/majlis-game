import 'catalog.dart';
import 'clan.dart';
import 'profile.dart';

/// أنواع جدول الترتيب.
enum Board { weekly, allTime, level, ranked }

/// سطر في جدول الترتيب (functions/src/profile.ts → toLeaderboard).
class LeaderboardEntry {
  LeaderboardEntry.fromJson(this.uid, Map<String, dynamic> j)
    : name = j['name'] as String,
      avatar = j['avatar'] as String,
      frame = j['frame'] as String?,
      level = j['level'] as int,
      xp = (j['xp'] as num?)?.toInt() ?? 0,
      gamesWon = j['gamesWon'] as int,
      gamesPlayed = j['gamesPlayed'] as int,
      weeklyWins = j['weeklyWins'] as int? ?? 0,
      badges = {
        for (final MapEntry(:key, :value) in ((j['badges'] as Map?) ?? const {}).entries)
          key as String: (value as num).toInt(),
      },
      rankPoints = j['rankSeason'] == season.id ? (j['rankPoints'] as num?)?.toInt() ?? 0 : 0,
      pid = j['pid'] as String? ?? '',
      pidTier = (j['pidTier'] as num?)?.toInt() ?? 0,
      playingSince = j['playingSince'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((j['playingSince'] as num).toInt()),
      clan = ClanTag.maybe(j['clan']);

  final String uid;
  final String name;
  final String avatar;
  final String? frame;
  final int level;
  final int xp;
  final int gamesWon;
  final int gamesPlayed;
  final int weeklyWins;

  /// درجة كل إنجاز وصله (١ برونزي، ٢ فضي، ٣ ذهبي).
  final Map<String, int> badges;

  /// نقاط التصنيف في الموسم الحالي.
  final int rankPoints;

  /// رمزه اللي يبحثون فيه عنه، ودرجته.
  final String pid;
  final int pidTier;

  /// يلعب الحين من متى (أصحابه يقدرون يتفرجون).
  final DateTime? playingSince;

  /// ديوانه.
  final ClanTag? clan;

  /// يلعب الحين؟ (لعبة بدأت من أقل من ساعة ونص، عشان لو علقت لعبة ما يبان يلعب للأبد).
  bool get playing => playingSince != null && DateTime.now().difference(playingSince!) < const Duration(minutes: 90);

  int get winRate => gamesPlayed == 0 ? 0 : (gamesWon * 100 / gamesPlayed).round();
}

/// رقم الأسبوع بتوقيت الخليج، الأسبوع يبدأ الأحد (نفس functions/src/missions.ts).
String gulfWeek(DateTime now) {
  final days = DateTime.parse('${gulfDay(now)}T00:00:00Z').millisecondsSinceEpoch ~/ 86400000;
  return 'W${((days - 3) / 7).floor()}';
}

/// أبطال الأسبوع اللي فات (meta/champions): أول ٣ ومعهم أغراض خاصة لين التتويج الجاي.
class Champions {
  Champions.fromJson(Map<String, dynamic> j)
    : until = DateTime.fromMillisecondsSinceEpoch((j['until'] as num).toInt()),
      list = [
        for (final c in (j['list'] as List?) ?? const [])
          (
            uid: (c as Map)['uid'] as String,
            rank: (c['rank'] as num).toInt(),
            name: c['name'] as String,
            avatar: c['avatar'] as String,
            wins: (c['wins'] as num).toInt(),
          ),
      ];

  final DateTime until;
  final List<({String uid, int rank, String name, String avatar, int wins})> list;

  bool get active => until.isAfter(DateTime.now());
}
