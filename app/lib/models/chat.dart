import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/common.dart' show arabicNumber;
import 'clan.dart';

/// رسالة في الدردشة (functions/src/chat.ts): الكلام السيء منخفي من السيرفر.
class ChatMessage {
  ChatMessage.fromJson(this.id, Map<String, dynamic> j)
    : uid = j['uid'] as String? ?? '',
      name = j['name'] as String? ?? '',
      avatar = j['avatar'] as String? ?? 'masked',
      text = j['text'] as String? ?? '',
      sticker = j['sticker'] as String?,
      role = ClanRole.values.asNameMap()[j['role']],
      system = j['system'] == true,
      at = DateTime.fromMillisecondsSinceEpoch((j['at'] as num?)?.toInt() ?? 0);

  final String id;
  final String uid;
  final String name;
  final String avatar;
  final String text;

  /// ملصق بدال الكلام.
  final String? sticker;

  /// رتبته في الديوان وقت ما كتب (دردشة الديوان بس).
  final ClanRole? role;

  /// سطر من النظام (دخل، طلع، صار نائب…).
  final bool system;
  final DateTime at;
}

/// آخر رسالة في محادثة صاحب (قائمة المحادثات): الكلام أو الملصق، ومتى، ومن أرسلها.
class ChatLast {
  ChatLast.fromJson(Map<String, dynamic> j)
    : text = j['text'] as String? ?? '',
      sticker = j['sticker'] as String?,
      at = DateTime.fromMillisecondsSinceEpoch((j['at'] as num?)?.toInt() ?? 0),
      from = j['from'] as String? ?? '';

  final String text;
  final String? sticker;
  final DateTime at;
  final String from;
}

/// حالة اتصال لاعب: نبضته كل ٣ دقايق والتطبيق مفتوح، ولما يطلع للخلفية تنكتب إنه طلع.
class Presence {
  const Presence({this.on = false, this.at});

  factory Presence.fromJson(Map<String, dynamic>? j) {
    final t = j?['t'];
    return Presence(on: j?['on'] == true, at: t is Timestamp ? t.toDate() : null);
  }

  final bool on;
  final DateTime? at;

  /// نبضة وحدة ضاعت ما تخليه غير متصل.
  static const window = Duration(minutes: 7);

  bool get online => on && at != null && DateTime.now().difference(at!) < window;

  /// «آخر ظهور قبل ساعتين»، أو null لو ما نعرف.
  String? get lastSeen => at == null ? null : 'آخر ظهور ${agoText(DateTime.now().difference(at!))}';
}

/// المدة بكلامنا: الحين، قبل دقيقتين، قبل ٣ ساعات، قبل يوم…
String agoText(Duration d) {
  String count(int n, String one, String two, String few, String many) => switch (n) {
    1 => 'قبل $one',
    2 => 'قبل $two',
    <= 10 => 'قبل ${arabicNumber(n)} $few',
    _ => 'قبل ${arabicNumber(n)} $many',
  };
  if (d.inMinutes < 1) return 'الحين';
  if (d.inMinutes < 60) return count(d.inMinutes, 'دقيقة', 'دقيقتين', 'دقايق', 'دقيقة');
  if (d.inHours < 24) return count(d.inHours, 'ساعة', 'ساعتين', 'ساعات', 'ساعة');
  if (d.inDays <= 30) return count(d.inDays, 'يوم', 'يومين', 'أيام', 'يوم');
  return 'من زمان';
}
