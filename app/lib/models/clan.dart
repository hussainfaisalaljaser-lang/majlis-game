/// الدواوين (functions/src/clans.ts).
library;

import 'dart:ui';

/// نفس functions/src/clans.ts.
const clanPrice = 5000;
const clanMax = 30;
const clanGoal = 3000;
const clanChest = (coins: 1000, diamonds: 5);

/// ألوان الشعار بالترتيب (نفس العدد في السيرفر CLAN_COLORS).
const clanColors = [
  Color(0xFF7C3AED),
  Color(0xFF16A34A),
  Color(0xFF0EA5E9),
  Color(0xFFF59E0B),
  Color(0xFFDC2626),
  Color(0xFFDB2777),
  Color(0xFF0D9488),
  Color(0xFF64748B),
];

/// مفتاح الاسم للبحث (نفس functions/src/profile.ts → nameKey).
String clanKey(String name) => name
    .toLowerCase()
    .replaceAll(RegExp('[\u064B-\u0652\u0640]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .replaceAll(RegExp(r'\s+'), '');

/// اللي يطلع عن ديوان اللاعب في ملفه وبطاقته.
class ClanTag {
  const ClanTag({required this.id, required this.name, required this.color, required this.emblem});

  ClanTag.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      name = j['name'] as String,
      color = (j['color'] as num).toInt(),
      emblem = j['emblem'] as String;

  static ClanTag? maybe(Object? j) => j is Map ? ClanTag.fromJson(Map<String, dynamic>.from(j)) : null;

  final String id;
  final String name;
  final int color;
  final String emblem;

  Color get tint => clanColors[color.clamp(0, clanColors.length - 1)];
}

enum ClanRole { owner, deputy, member }

class ClanMember {
  ClanMember.fromJson(this.uid, Map<String, dynamic> j, String week)
    : name = j['name'] as String,
      avatar = j['avatar'] as String,
      role = ClanRole.values.byName(j['role'] as String),
      joined = DateTime.fromMillisecondsSinceEpoch((j['joined'] as num).toInt()),
      points = j['week'] == week ? (j['points'] as num).toInt() : 0;

  final String uid;
  final String name;
  final String avatar;
  final ClanRole role;
  final DateTime joined;

  /// نقاطه هالأسبوع للديوان.
  final int points;

  String get roleName => switch (role) {
    ClanRole.owner => 'شيخ الديوان',
    ClanRole.deputy => 'نائب',
    ClanRole.member => 'عضو',
  };
}

class Clan {
  Clan.fromJson(Map<String, dynamic> j, this.week)
    : tag = ClanTag.fromJson(j),
      ownerId = j['ownerId'] as String,
      count = (j['count'] as num).toInt(),
      total = (j['total'] as num?)?.toInt() ?? 0,
      points = ((j['weekly'] as Map?)?[week] as num?)?.toInt() ?? 0,
      claimed = {for (final u in (((j['chest'] as Map?)?[week] as List?) ?? const [])) u as String},
      members =
          [
            for (final MapEntry(:key, :value) in ((j['members'] as Map?) ?? const {}).entries)
              ClanMember.fromJson(key as String, Map<String, dynamic>.from(value as Map), week),
          ]..sort(
            (a, b) => a.role.index.compareTo(b.role.index) == 0
                ? b.points.compareTo(a.points)
                : a.role.index.compareTo(b.role.index),
          );

  final String week;
  final ClanTag tag;
  final String ownerId;
  final int count;
  final int total;

  /// نقاط هالأسبوع.
  final int points;

  /// اللي استلموا صندوق هالأسبوع.
  final Set<String> claimed;
  final List<ClanMember> members;

  String get id => tag.id;
  String get name => tag.name;

  /// المستوى من كل النقاط (يزيد أبطأ كل ما ارتفع).
  int get level {
    var l = 1;
    while (200 * l * l <= total) {
      l++;
    }
    return l;
  }

  ClanMember? member(String uid) => members.where((m) => m.uid == uid).firstOrNull;
}
