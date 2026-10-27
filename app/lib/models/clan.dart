/// الدواوين (functions/src/clans.ts).
library;

import 'dart:ui';

/// نفس functions/src/clans.ts.
const clanPrice = 5000;
const clanMax = 30;
const clanGoal = 3000;
const clanChest = (coins: 1000, diamonds: 5);
const clanDeputies = 3;
const clanElders = 8;
const clanDescMax = 120;

/// الطلبات والدعوات تنتهي بعد أسبوع.
const clanInviteTtl = Duration(days: 7);

/// شروط المستوى اللي يختار منها الشيخ.
const clanLevelSteps = [0, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

/// طريقة الدخول: مفتوح لأي أحد تنطبق عليه الشروط، أو بطلب يقبله الوجهاء وفوق، أو بالدعوة بس.
enum ClanJoin {
  open('مفتوح', 'أي أحد تنطبق عليه الشروط يدخل على طول'),
  request('بطلب', 'يرسل طلب، والوجهاء وفوق يقبلونه'),
  invite('بالدعوة', 'محد يدخل إلا بدعوة من الوجهاء وفوق');

  const ClanJoin(this.label, this.hint);

  final String label;
  final String hint;
}

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

/// الرتب من الأعلى: شيخ الديوان، والنواب (٣)، والوجهاء (٨)، والأعضاء.
enum ClanRole { owner, deputy, elder, member }

extension ClanRoleName on ClanRole {
  String get label => switch (this) {
    ClanRole.owner => 'شيخ الديوان',
    ClanRole.deputy => 'نائب',
    ClanRole.elder => 'وجيه',
    ClanRole.member => 'عضو',
  };

  /// قوة الرتبة: الأعلى يقدر على اللي تحته.
  int get power => 3 - index;
}

/// طلب دخول للديوان.
class ClanRequest {
  ClanRequest.fromJson(this.uid, Map<String, dynamic> j)
    : name = j['name'] as String? ?? '',
      avatar = j['avatar'] as String? ?? 'masked',
      level = (j['level'] as num?)?.toInt() ?? 1,
      at = DateTime.fromMillisecondsSinceEpoch((j['at'] as num?)?.toInt() ?? 0);

  final String uid;
  final String name;
  final String avatar;
  final int level;
  final DateTime at;
}

/// دعوة وصلتني لديوان (في ملفي clanInvites).
class ClanInvite {
  ClanInvite.fromJson(this.id, Map<String, dynamic> j)
    : tag = ClanTag(
        id: id,
        name: j['name'] as String? ?? '',
        color: (j['color'] as num?)?.toInt() ?? 0,
        emblem: j['emblem'] as String? ?? 'hawk',
      ),
      fromName = j['fromName'] as String? ?? '',
      at = DateTime.fromMillisecondsSinceEpoch((j['at'] as num?)?.toInt() ?? 0);

  final String id;
  final ClanTag tag;
  final String fromName;
  final DateTime at;

  bool get live => DateTime.now().difference(at) < clanInviteTtl;
}

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

  String get roleName => role.label;
}

class Clan {
  Clan.fromJson(Map<String, dynamic> j, this.week)
    : tag = ClanTag.fromJson(j),
      ownerId = j['ownerId'] as String,
      count = (j['count'] as num).toInt(),
      total = (j['total'] as num?)?.toInt() ?? 0,
      points = ((j['weekly'] as Map?)?[week] as num?)?.toInt() ?? 0,
      claimed = {for (final u in (((j['chest'] as Map?)?[week] as List?) ?? const [])) u as String},
      desc = (j['desc'] as String?) ?? '',
      minLevel = (j['minLevel'] as num?)?.toInt() ?? 0,
      join = ClanJoin.values.asNameMap()[j['join']] ?? ClanJoin.open,
      chatAt = DateTime.fromMillisecondsSinceEpoch((j['chatAt'] as num?)?.toInt() ?? 0),
      requests = [
        for (final MapEntry(:key, :value) in ((j['requests'] as Map?) ?? const {}).entries)
          if (value is Map) ClanRequest.fromJson(key as String, Map<String, dynamic>.from(value)),
      ].where((r) => DateTime.now().difference(r.at) < clanInviteTtl).toList()..sort((a, b) => a.at.compareTo(b.at)),
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

  /// وصف الديوان، وشروط الدخول.
  final String desc;
  final int minLevel;
  final ClanJoin join;

  /// طلبات الدخول (لو الدخول بطلب)، الأقدم أول.
  final List<ClanRequest> requests;

  /// وقت آخر رسالة في الدردشة (عشان نعلّم إن فيه جديد).
  final DateTime chatAt;

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
