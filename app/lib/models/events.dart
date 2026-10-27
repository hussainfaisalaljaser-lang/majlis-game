/// أحداث بوقت محدد.
library;

/// نهاية الأسبوع بتوقيت الخليج: من الخميس ٦ المغرب لين نهاية السبت، ذهب الفوز مضاعف.
/// نفس functions/src/economy.ts → weekendBoost.
class Weekend {
  const Weekend._({required this.on, required this.starts, required this.ends});

  factory Weekend.at(DateTime now) {
    // ساعة الخليج محفوظة كأنها UTC، عشان الحسبة ما تتأثر بساعة الجوال.
    final g = now.toUtc().add(_gulf);
    final thursday = DateTime.utc(g.year, g.month, g.day).subtract(Duration(days: (g.weekday - DateTime.thursday) % 7));
    var starts = thursday.add(const Duration(hours: 18));
    var ends = thursday.add(const Duration(days: 3));
    if (!g.isBefore(ends)) {
      starts = starts.add(const Duration(days: 7));
      ends = ends.add(const Duration(days: 7));
    }
    return Weekend._(on: !g.isBefore(starts), starts: starts.subtract(_gulf), ends: ends.subtract(_gulf));
  }

  static const _gulf = Duration(hours: 3);

  /// شغال الحين؟
  final bool on;

  /// متى يبدأ (الجاي لو مو شغال) ومتى يخلص.
  final DateTime starts;
  final DateTime ends;

  /// كم ينضرب ذهب الفوز.
  int get boost => on ? 2 : 1;
}
