import 'profile.dart';

/// سطر في جدول الترتيب (functions/src/profile.ts → toLeaderboard).
/// أنواع جدول الترتيب.
enum Board { weekly, allTime, level }

class LeaderboardEntry {
  LeaderboardEntry.fromJson(this.uid, Map<String, dynamic> j)
    : name = j['name'] as String,
      avatar = j['avatar'] as String,
      frame = j['frame'] as String?,
      level = j['level'] as int,
      gamesWon = j['gamesWon'] as int,
      gamesPlayed = j['gamesPlayed'] as int,
      weeklyWins = j['weeklyWins'] as int? ?? 0;

  final String uid;
  final String name;
  final String avatar;
  final String? frame;
  final int level;
  final int gamesWon;
  final int gamesPlayed;
  final int weeklyWins;
}

/// رقم الأسبوع بتوقيت الخليج، الأسبوع يبدأ الأحد (نفس functions/src/missions.ts).
String gulfWeek(DateTime now) {
  final days = DateTime.parse('${gulfDay(now)}T00:00:00Z').millisecondsSinceEpoch ~/ 86400000;
  return 'W${((days - 3) / 7).floor()}';
}
