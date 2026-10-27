/// بطولة الأسبوع (functions/src/tournament.ts).
library;

/// نفس functions/src/tournament.ts.
const tourFee = 1000;
const tourPrize = (coins: 15000, diamonds: 25);
const tourStages = 3;

/// أسماء الأدوار بالترتيب، وآخرها البطل.
const tourStageNames = ['الدور الأول', 'نص النهائي', 'النهائي', 'البطل'];

/// وين وصل اللاعب في بطولة أسبوع (من ملفه).
class TourState {
  const TourState({required this.week, required this.stage, required this.out});

  TourState.fromJson(Map<String, dynamic> j)
    : week = j['week'] as String,
      stage = (j['stage'] as num).toInt(),
      out = j['out'] as bool? ?? false;

  static TourState? maybe(Object? j) => j is Map ? TourState.fromJson(Map<String, dynamic>.from(j)) : null;

  final String week;

  /// كم دور فاز فيه (٠ الدور الأول … ٣ بطل).
  final int stage;
  final bool out;

  bool get champion => stage >= tourStages;
}

class TourEntry {
  TourEntry.fromJson(this.uid, Map<String, dynamic> j)
    : name = j['name'] as String,
      avatar = j['avatar'] as String,
      frame = j['frame'] as String?,
      stage = (j['stage'] as num).toInt(),
      out = j['out'] as bool? ?? false;

  final String uid;
  final String name;
  final String avatar;
  final String? frame;
  final int stage;
  final bool out;
}

/// لوحة بطولة الأسبوع: المشاركين ووين وصلوا.
class Tour {
  Tour.fromJson(Map<String, dynamic> j)
    : players = [
        for (final MapEntry(:key, :value) in ((j['players'] as Map?) ?? const {}).entries)
          TourEntry.fromJson(key as String, Map<String, dynamic>.from(value as Map)),
      ]..sort((a, b) => b.stage.compareTo(a.stage) == 0 ? a.name.compareTo(b.name) : b.stage.compareTo(a.stage)),
      champions = [for (final c in (j['champions'] as List?) ?? const []) c as String];

  static const empty = Tour._();
  const Tour._() : players = const [], champions = const [];

  final List<TourEntry> players;
  final List<String> champions;

  /// اللي وصلوا الدور [stage] أو أبعد.
  List<TourEntry> reached(int stage) => [
    for (final p in players)
      if (p.stage >= stage) p,
  ];
}
