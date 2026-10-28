import 'game_view.dart';
import 'room.dart';

/// لعبة في سجل المباريات (functions/src/index.ts → historyEntry): نسختك منها بعد النهاية (كل الأدوار
/// والادعاءات والكروت الحقيقية) ولاعبين الروم ونتيجتك. تنحذف بعد ٣٠ يوم.
class HistoryEntry {
  HistoryEntry.fromJson(this.id, Map<String, dynamic> j)
    : at = DateTime.fromMillisecondsSinceEpoch((j['at'] as num).toInt()),
      view = GameView.fromJson(Map<String, dynamic>.from(j['view'] as Map)),
      room = Room.fromJson(Map<String, dynamic>.from(j['room'] as Map));

  final String id;
  final DateTime at;
  final GameView view;
  final Room room;

  /// فزت؟ (اللي طلع قبل النهاية ما ينحسب له فوز.)
  bool get won => room.results[view.you]?.won ?? false;
}
