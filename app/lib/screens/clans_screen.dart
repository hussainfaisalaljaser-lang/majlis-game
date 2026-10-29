import 'dart:async';

import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../models/chat.dart';
import '../models/clan.dart';
import '../models/leaderboard.dart';
import '../models/profile.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/clan_crest.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/design_social.dart';
import '../widgets/player_card.dart';
import 'chat_screen.dart';

/// الدواوين: لو ما عندك ديوان تسوي واحد أو تدخل واحد من الترتيب (أو بدعوة)، ولو عندك تشوف ديوانك: وصفه
/// وشروطه، والأعضاء برتبهم ومين متصل، والدردشة (تنفتح مكان الترتيب)، والدعوات والطلبات، وهدف الأسبوع.
/// النقاط من الطاولات العامة بس: كل لعبة لعضو ١٠ نقاط، والفوز ٣٠.
class ClansScreen extends StatefulWidget {
  const ClansScreen({super.key});

  @override
  State<ClansScreen> createState() => _ClansScreenState();
}

class _ClansScreenState extends State<ClansScreen> {
  /// دردشة الديوان مفتوحة مكان الترتيب.
  bool _chat = false;

  @override
  Widget build(BuildContext context) => SocScaffold(
    title: 'الدواوين',
    icon: const Gfx('shield', size: 30),
    currency: false,
    body: ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) {
        final clan = p.clan;
        // طلعت من الديوان: الدردشة ترجع مغلقة للديوان الجاي.
        if (clan == null) _chat = false;
        return SocTwoPanels(
          main: clan == null
              ? const _CreateClan()
              : _MyClan(
                  key: ValueKey(clan.id),
                  id: clan.id,
                  chatOpen: _chat,
                  onChat: () => setState(() => _chat = !_chat),
                ),
          side: clan != null && _chat
              ? ChatPanel.clan(key: ValueKey('chat_${clan.id}'), clan: clan)
              : _Ranking(mine: clan?.id, canJoin: clan == null),
        );
      },
    ),
  );
}

Future<void> _run(BuildContext context, Future<void> Function() job, [String? done]) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await job();
    if (done != null) messenger.showSnackBar(SnackBar(content: Text(done)));
  } on BackendException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// تسوي ديوانك: الاسم واللون والشعار.
class _CreateClan extends StatefulWidget {
  const _CreateClan();

  @override
  State<_CreateClan> createState() => _CreateClanState();
}

class _CreateClanState extends State<_CreateClan> {
  final _name = TextEditingController();
  int _color = 0;
  String _emblem = freeAvatars.first;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    await _run(
      context,
      () => Backend.instance.createClan(name: _name.text.trim(), color: _color, emblem: _emblem),
      'سويت ديوانك! ادعُ ربعك يدخلونه',
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = Backend.instance.profile.value;
    return CreateClanView(
      name: _name,
      color: _color,
      emblem: _emblem,
      busy: _busy,
      label: _busy ? 'لحظة…' : (p.dev ? 'سوّ الديوان' : 'سوّ الديوان بـ${arabicNumber(clanPrice)} ذهب'),
      onName: () => setState(() {}),
      onColor: (i) => setState(() => _color = i),
      onEmblem: (a) => setState(() => _emblem = a),
      onCreate: _busy || _name.text.trim().length < 3 ? null : _create,
      inviteBanner: p.clanInvites.isEmpty ? null : _InviteBanner(invites: p.clanInvites),
    );
  }
}

/// شكل صفحة «سوّ ديوانك»: ما تلمس السيرفر.
class CreateClanView extends StatelessWidget {
  const CreateClanView({
    super.key,
    required this.name,
    required this.color,
    required this.emblem,
    required this.busy,
    required this.label,
    required this.onName,
    required this.onColor,
    required this.onEmblem,
    required this.onCreate,
    this.inviteBanner,
  });

  final TextEditingController name;
  final int color;
  final String emblem;
  final bool busy;
  final String label;
  final VoidCallback onName;
  final ValueChanged<int> onColor;
  final ValueChanged<String> onEmblem;
  final VoidCallback? onCreate;
  final Widget? inviteBanner;

  @override
  Widget build(BuildContext context) {
    Widget caption(String t) => SizedBox(
      width: 56,
      child: Text(
        t,
        style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 15, color: socCream),
      ),
    );
    // كل شي يبان بدون تمرير (الشاشة بالعرض قصيرة).
    return VelvetPanel(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?inviteBanner,
          if (inviteBanner != null) const SizedBox(height: 8),
          Row(
            children: [
              ClanCrest(color: clanColors[color], emblem: emblem, size: 72),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: name,
                  maxLength: 20,
                  style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 18, color: socCream),
                  decoration: socInput(hint: 'اسم ديوانك (مثلاً: ديوان الصقور)', dense: false),
                  onChanged: (_) => onName(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              caption('اللون'),
              for (final (i, c) in clanColors.indexed)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 7),
                  child: Semantics(
                    button: true,
                    label: 'لون ${i + 1}',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => onColor(i),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i == color ? const Color(0xFFFFE08A) : const Color(0xFF2A1608),
                            width: i == color ? 3 : 2,
                          ),
                          boxShadow: i == color
                              ? [BoxShadow(color: const Color(0xFFF2B33E).withValues(alpha: .7), blurRadius: 8)]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              caption('الشعار'),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      for (final a in freeAvatars)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: Semantics(
                            button: true,
                            label: 'شعار $a',
                            excludeSemantics: true,
                            child: GestureDetector(
                              onTap: () => onEmblem(a),
                              child: Center(
                                child: SocAvatar(avatar: a, size: 40, ring: a == emblem ? SocRing.gold : SocRing.blue),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text(
            'ديوان مع ربعك (بالكثير ٣٠)، وكل لعبة بطاولة عامة تزيد نقاطكم هالأسبوع. الوصف والشروط من الإعدادات بعدين',
            textAlign: TextAlign.center,
            style: TextStyle(color: socMuted, fontSize: 12.5, fontFamily: kufi, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SocButton(
            label: label,
            tone: SocTone.orange,
            icon: const Gfx('shield', size: 26),
            height: 46,
            fontSize: 18,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

/// ديوانك: الشعار والمستوى والأعضاء، وهدف الأسبوع وصندوقه.
class _MyClan extends StatelessWidget {
  const _MyClan({super.key, required this.id, required this.chatOpen, required this.onChat});

  final String id;
  final bool chatOpen;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) => StreamBuilder<Clan?>(
    stream: Backend.instance.watchClan(id),
    builder: (context, snap) {
      final clan = snap.data;
      if (clan == null) {
        return const VelvetPanel(
          child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
        );
      }
      final me = Backend.instance.uid;
      return _NewMessages(
        clan: clan,
        builder: (fresh) => ClanPanelView(
          clan: clan,
          myUid: me,
          chatFresh: fresh,
          chatOpen: chatOpen,
          memberBuilder: (m, big) => _OnlineMember(clan: clan, member: m, big: big),
          onLeave: () => _leave(context, clan),
          onChat: onChat,
          onInvite: () => _invite(context, clan),
          onRequests: () => _requests(context, clan),
          onSettings: () => _settings(context, clan),
          onClaim: () => _run(
            context,
            Backend.instance.claimClanChest,
            'استلمت ${arabicNumber(clanChest.coins)} ذهب و${arabicNumber(clanChest.diamonds)} جواهر',
          ),
        ),
      );
    },
  );

  Future<void> _leave(BuildContext context, Clan clan) async {
    final alone = clan.count == 1;
    final ok = await socConfirm(
      context,
      title: 'تطلع من الديوان؟',
      body: alone
          ? 'أنت آخر واحد فيه، فبينحذف الديوان.'
          : clan.ownerId == Backend.instance.uid
          ? 'المشيخة بتروح لنائبك (أو أقدم عضو).'
          : 'تقدر تدخل ديوان ثاني بعدين.',
      yes: 'اطلع',
      danger: true,
    );
    if (ok && context.mounted) await _run(context, Backend.instance.leaveClan, 'طلعت من الديوان');
  }
}

/// لوحة ديوانك (مخمل): الشعار والاسم والشارات، وأزرار الدردشة والدعوة والإعدادات، وهدف الأسبوع، والأعضاء.
/// ما تلمس السيرفر: كل شي يجيها بالمعطيات (تنشاف بالتصوير ببيانات تجريبية).
class ClanPanelView extends StatelessWidget {
  const ClanPanelView({
    super.key,
    required this.clan,
    required this.myUid,
    required this.chatFresh,
    required this.chatOpen,
    required this.memberBuilder,
    required this.onLeave,
    required this.onChat,
    required this.onInvite,
    required this.onRequests,
    required this.onSettings,
    required this.onClaim,
  });

  final Clan clan;
  final String myUid;

  /// فيه رسائل جديدة في دردشة الديوان.
  final bool chatFresh;
  final bool chatOpen;

  /// العضو: صغير في الشبكة، أو كبير تحت ([big]).
  final Widget Function(ClanMember member, bool big) memberBuilder;
  final VoidCallback onLeave;
  final VoidCallback onChat;
  final VoidCallback onInvite;
  final VoidCallback onRequests;
  final VoidCallback onSettings;
  final VoidCallback onClaim;

  /// شروط الدخول كشارات: الطريقة، وأقل مستوى.
  static List<Widget> conditions(Clan clan, {double size = 12.5}) => [
    SocChip('الدخول ${clan.join.label}', kind: SocChipKind.green, size: size),
    if (clan.minLevel > 0) SocChip('مستوى ${arabicNumber(clan.minLevel)}+', kind: SocChipKind.orange, size: size),
  ];

  @override
  Widget build(BuildContext context) {
    final mine = clan.member(myUid);
    final power = mine?.role.power ?? 0;
    final reached = clan.points >= clanGoal;
    final played = (mine?.points ?? 0) > 0;
    final claimed = clan.claimed.contains(myUid);
    return LayoutBuilder(
      builder: (context, box) {
        // الجوالات الصغيرة: رأس أصغر عشان يبان الأعضاء.
        final compact = box.maxHeight < 420;
        return VelvetPanel(
          padding: EdgeInsets.fromLTRB(compact ? 14 : 18, compact ? 6 : 9, compact ? 14 : 18, compact ? 6 : 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClanCrest.of(clan.tag, size: compact ? 46 : 64),
                  SizedBox(width: compact ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: GoldTitle(clan.name, size: compact ? 19 : 24),
                        ),
                        SizedBox(height: compact ? 1 : 3),
                        Wrap(
                          spacing: compact ? 4 : 6,
                          runSpacing: compact ? 2 : 4,
                          children: [
                            SocChip(
                              'المستوى ${arabicNumber(clan.level)}',
                              kind: SocChipKind.gold,
                              size: compact ? 10.5 : 12.5,
                            ),
                            SocChip(
                              '${arabicNumber(clan.count)} من ${arabicNumber(clanMax)} عضو',
                              kind: SocChipKind.blue,
                              size: compact ? 10.5 : 12.5,
                            ),
                            ...conditions(clan, size: compact ? 10.5 : 12.5),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SocButton(
                    label: 'اطلع',
                    tone: SocTone.red,
                    height: compact ? 28 : 34,
                    fontSize: compact ? 14 : 16,
                    width: compact ? 58 : 72,
                    padding: 6,
                    onPressed: onLeave,
                  ),
                ],
              ),
              if (clan.desc.isNotEmpty && !compact)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    clan.desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE9D3B5),
                      fontSize: 13,
                      fontFamily: kufi,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              SizedBox(height: compact ? 2 : 4),
              // الدردشة، والدعوة والطلبات (الوجهاء وفوق)، والإعدادات (الشيخ ونوابه).
              Row(
                children: [
                  ClanActionButton(
                    icon: 'chat',
                    label: 'الدردشة',
                    tone: chatOpen ? SocTone.orange : SocTone.red,
                    dot: chatFresh,
                    compact: compact,
                    onTap: onChat,
                  ),
                  if (power >= ClanRole.elder.power) ...[
                    const SizedBox(width: 8),
                    ClanActionButton(
                      icon: 'invite',
                      label: 'دعوة',
                      tone: SocTone.green,
                      compact: compact,
                      onTap: onInvite,
                    ),
                    if (clan.join == ClanJoin.request || clan.requests.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      ClanActionButton(
                        icon: 'addfriend',
                        label: 'الطلبات',
                        tone: SocTone.orange,
                        count: clan.requests.length,
                        compact: compact,
                        onTap: onRequests,
                      ),
                    ],
                  ],
                  if (power >= ClanRole.deputy.power) ...[
                    const SizedBox(width: 8),
                    ClanActionButton(
                      icon: 'tools',
                      label: 'الإعدادات',
                      tone: SocTone.blue,
                      compact: compact,
                      onTap: onSettings,
                    ),
                  ],
                ],
              ),
              SizedBox(height: compact ? 3 : 5),
              ClanGoalBar(
                clan: clan,
                reached: reached,
                played: played,
                claimed: claimed,
                compact: compact,
                onClaim: onClaim,
              ),
              SizedBox(height: compact ? 4 : 6),
              Expanded(
                child: _Members(clan: clan, memberBuilder: memberBuilder),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// أعضاء الديوان: شبكة بطاقات صغيرة، وتحتها لو فيه مكان أبرز الأعضاء ببطاقات كبيرة.
class _Members extends StatelessWidget {
  const _Members({required this.clan, required this.memberBuilder});

  final Clan clan;
  final Widget Function(ClanMember member, bool big) memberBuilder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // البطاقات الكبيرة تطلع بس لو الشبكة الصغيرة ما تاخذ مكان زيادة.
      final perRow = ((box.maxWidth + 8) / 82).floor().clamp(1, 20);
      final rows = (clan.members.length / perRow).ceil().clamp(1, 20);
      final tilesHeight = rows * 94.0 + (rows - 1) * 8;
      final big = box.maxWidth >= 250 && tilesHeight + 4 + 188 <= box.maxHeight;
      final tiles = SingleChildScrollView(
        child: Wrap(spacing: 8, runSpacing: 8, children: [for (final m in clan.members) memberBuilder(m, false)]),
      );
      if (!big) return tiles;
      final cols = ((box.maxWidth + 10) / 128).floor().clamp(1, 3);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tiles),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, m) in clan.members.take(cols).indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                memberBuilder(m, true),
              ],
            ],
          ),
        ],
      );
    },
  );
}

/// زر صغير في لوحة الديوان، ومعه نقطة (جديد) أو رقم.
class ClanActionButton extends StatelessWidget {
  const ClanActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
    this.dot = false,
    this.count = 0,
    this.compact = false,
  });

  final String icon;
  final String label;
  final SocTone tone;
  final VoidCallback onTap;
  final bool dot;
  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      SocButton(
        label: label,
        tone: tone,
        icon: Gfx(icon, size: compact ? 16 : 20),
        height: compact ? 26 : 32,
        fontSize: compact ? 12.5 : 14.5,
        padding: compact ? 7 : 10,
        onPressed: onTap,
      ),
      if (count > 0) PositionedDirectional(top: -3, end: -6, child: SocBadge(count, size: 18)),
      if (dot && count == 0) PositionedDirectional(top: -3, end: -3, child: SocBadge(0, size: 12)),
    ],
  );
}

/// هدف الأسبوع: صندوق، وكلام التقدم، وشريط ذهب على مجرى حبل.
class ClanGoalBar extends StatelessWidget {
  const ClanGoalBar({
    super.key,
    required this.clan,
    required this.reached,
    required this.played,
    required this.claimed,
    required this.onClaim,
    this.compact = false,
  });

  final Clan clan;
  final bool reached;
  final bool played;
  final bool claimed;
  final VoidCallback onClaim;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(10, compact ? 3 : 7, 10, compact ? 4 : 8),
    decoration: BoxDecoration(
      color: const Color(0xFF2A0A10).withValues(alpha: .8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFB58A3C).withValues(alpha: .75), width: 1.6),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'هدف الأسبوع: ${arabicNumber(clan.points)} من ${arabicNumber(clanGoal)} نقطة'
                '${reached ? '' : ' · اللعبة العامة ١٠ والفوز ٣٠'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kufi,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 12 : 13.5,
                  color: socCream,
                  height: 1.3,
                ),
              ),
              SizedBox(height: compact ? 2 : 4),
              SocBar(value: clan.points / clanGoal, height: compact ? 9 : 11),
              if (reached) ...[
                const SizedBox(height: 3),
                Text(
                  claimed
                      ? 'استلمت صندوق هالأسبوع'
                      : (played ? 'وصلتوا الهدف! استلم صندوقك' : 'العب مع ديوانك وتستلم الصندوق'),
                  style: const TextStyle(color: socMuted, fontSize: 12, fontFamily: kufi, fontWeight: FontWeight.w700),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: reached && !claimed ? 1 : .85,
              child: SocChest(size: compact ? 28 : 40),
            ),
            if (reached && played && !claimed)
              SocButton(label: 'استلم', tone: SocTone.green, height: 26, fontSize: 13, padding: 8, onPressed: onClaim),
          ],
        ),
      ],
    ),
  );
}

/// العضو مع حالة اتصاله (تنتابع مباشرة).
class _OnlineMember extends StatelessWidget {
  const _OnlineMember({required this.clan, required this.member, required this.big});

  final Clan clan;
  final ClanMember member;
  final bool big;

  /// الشيخ ونوابه يقدرون على اللي تحتهم بالرتبة.
  bool _canManage(ClanMember? me) =>
      member.uid != me?.uid && (me?.role.power ?? 0) >= ClanRole.deputy.power && me!.role.power > member.role.power;

  @override
  Widget build(BuildContext context) {
    final me = clan.member(Backend.instance.uid);
    return StreamBuilder<Presence>(
      stream: Backend.instance.watchPresence(member.uid),
      builder: (context, snap) => ClanMemberTile(
        member: member,
        online: (snap.data?.online ?? false) || member.uid == me?.uid,
        big: big,
        onTap: _canManage(me)
            ? () => _manage(context, clan, member, me)
            : () => showPlayerCard(context, uid: member.uid, name: member.name, avatar: member.avatar),
      ),
    );
  }
}

/// عضو في الديوان: صورته واسمه ودوره ونقاطه هالأسبوع. الشيخ بذهب وتاج، والباقي بأزرق.
/// [big] بطاقة كبيرة (أبرز الأعضاء)، وبدونه بطاقة صغيرة في الشبكة.
class ClanMemberTile extends StatelessWidget {
  const ClanMemberTile({super.key, required this.member, required this.online, required this.big, required this.onTap});

  final ClanMember member;
  final bool online;
  final bool big;
  final VoidCallback onTap;

  static Color roleColor(ClanRole r) => switch (r) {
    ClanRole.owner => const Color(0xFFFFC94D),
    ClanRole.deputy => const Color(0xFFD2B8FF),
    _ => const Color(0xFF7FEBD6),
  };

  @override
  Widget build(BuildContext context) {
    final owner = member.role == ClanRole.owner;
    final rank = member.role != ClanRole.member;
    final dot = online ? SocDot.online : SocDot.offline;
    final points = Text(
      '${arabicNumber(member.points)} نقطة',
      style: TextStyle(
        fontFamily: kufi,
        fontWeight: FontWeight.w700,
        fontSize: big ? 14 : 11,
        color: socMuted,
        height: 1.2,
      ),
    );
    final roleLine = rank
        ? Text(
            member.roleName,
            maxLines: 1,
            style: TextStyle(
              fontFamily: kufi,
              fontWeight: FontWeight.w800,
              fontSize: big ? 15 : 11.5,
              color: roleColor(member.role),
              height: 1.2,
            ),
          )
        : null;
    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(big ? 16 : 12),
      gradient: owner
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6B4524), Color(0xFF4A2D18)],
            )
          : big
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3A1519), Color(0xFF260C10)],
            )
          : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2B315C), Color(0xFF1D2144)],
            ),
      border: Border.all(
        color: owner
            ? const Color(0xFFD9A84E)
            : big
            ? const Color(0xFF6B3A3C)
            : const Color(0xFF4A62B0),
        width: owner ? 2 : 1.6,
      ),
    );
    final semantics = 'عضو ${member.name}';
    if (!big) {
      return Semantics(
        button: true,
        label: semantics,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 74,
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            decoration: decoration,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SocAvatar(avatar: member.avatar, size: 40, ring: owner ? SocRing.gold : SocRing.blue, dot: dot),
                const SizedBox(height: 3),
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kufi,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: socCream,
                    height: 1.2,
                  ),
                ),
                ?roleLine,
                points,
              ],
            ),
          ),
        ),
      );
    }
    // البطاقة الكبيرة: الصورة تطلع فوق البطاقة (وتاج للشيخ).
    final avatar = owner ? 88.0 : 78.0;
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 118,
          height: owner ? 188 : 160,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: owner ? 122 : 108,
                child: DecoratedBox(decoration: decoration),
              ),
              Positioned(
                top: owner ? 26 : 10,
                child: owner
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFB02E).withValues(alpha: .6),
                              blurRadius: 22,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: SocAvatar(avatar: member.avatar, size: avatar, gems: true),
                      )
                    : SocAvatar(avatar: member.avatar, size: avatar, ring: SocRing.blue),
              ),
              if (owner) const Positioned(top: 0, child: SocCrown(width: 38)),
              Positioned(
                left: 4,
                right: 4,
                bottom: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(fit: BoxFit.scaleDown, child: OutlinedText(member.name, size: 18, maxLines: 1)),
                    ?roleLine,
                    points,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// الشيخ أو نائبه يضغط على عضو: بطاقته، أو يغيّر رتبته، أو يطلّعه.
Future<void> _manage(BuildContext context, Clan clan, ClanMember member, ClanMember? me) async {
  /// الرتب اللي أقدر أعطيه: الشيخ أي رتبة (والمشيخة نفسها)، والنائب بين العضو والوجيه.
  final roles = [
    if (me?.role == ClanRole.owner) ...[ClanRole.owner, ClanRole.deputy],
    ClanRole.elder,
    ClanRole.member,
  ].where((r) => r != member.role).toList();
  final action = await showSocDialog<String>(
    context,
    title: member.name,
    width: 420,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SocAvatar(avatar: member.avatar, size: 44),
            const SizedBox(width: 12),
            SocPopupText(member.roleName, size: 16),
          ],
        ),
        const SizedBox(height: 12),
        SocButton(
          label: 'بطاقته',
          tone: SocTone.blue,
          icon: const Gfx('profile', size: 22),
          height: 40,
          onPressed: () => Navigator.pop(context, 'card'),
        ),
        for (final r in roles) ...[
          const SizedBox(height: 8),
          SocButton(
            label: switch (r) {
              ClanRole.owner => 'سلّمه المشيخة (وتصير نائب)',
              ClanRole.member => 'رجّعه عضو',
              _ => 'خله ${r.label}',
            },
            tone: SocTone.orange,
            icon: Gfx(r == ClanRole.owner ? 'trophy' : 'medal${r == ClanRole.member ? 3 : r.index}', size: 22),
            height: 40,
            onPressed: () => Navigator.pop(context, 'role:${r.name}'),
          ),
        ],
        const SizedBox(height: 8),
        SocButton(
          label: 'طلّعه من الديوان',
          tone: SocTone.red,
          icon: const Gfx('exit', size: 22),
          height: 40,
          onPressed: () => Navigator.pop(context, 'kick'),
        ),
      ],
    ),
  );
  if (!context.mounted || action == null) return;
  if (action == 'card') {
    showPlayerCard(context, uid: member.uid, name: member.name, avatar: member.avatar);
  } else if (action == 'kick') {
    await _run(context, () => Backend.instance.clanKick(member.uid), 'طلع من الديوان');
  } else if (action.startsWith('role:')) {
    final role = ClanRole.values.byName(action.substring(5));
    if (role == ClanRole.owner) {
      final sure = await socConfirm(
        context,
        title: 'تسلّمه المشيخة؟',
        body: '${member.name} بيصير شيخ الديوان، وأنت تصير نائب.',
        yes: 'سلّمه',
      );
      if (!sure || !context.mounted) return;
    }
    await _run(context, () => Backend.instance.clanRole(member.uid, role), 'صار ${role.label}');
  }
}

/// ترتيب الدواوين هالأسبوع، والبحث بالاسم. اللي ما عنده ديوان يقدر يدخل من هنا.
class _Ranking extends StatefulWidget {
  const _Ranking({required this.mine, required this.canJoin});

  final String? mine;
  final bool canJoin;

  @override
  State<_Ranking> createState() => _RankingState();
}

class _RankingState extends State<_Ranking> {
  late final Stream<List<Clan>> _top = Backend.instance.watchTopClans();
  final _search = TextEditingController();
  Timer? _debounce;
  List<Clan>? _found;
  String? _joining;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) return setState(() => _found = null);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final list = await Backend.instance.searchClans(q.trim()).catchError((_) => <Clan>[]);
      if (mounted) setState(() => _found = list);
    });
  }

  Future<void> _join(Clan c) async {
    setState(() => _joining = c.id);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final requested = await Backend.instance.joinClan(c.id);
      messenger.showSnackBar(
        SnackBar(content: Text(requested ? 'انرسل طلبك لـ${c.name}، ينتظر موافقة الوجهاء' : 'دخلت ${c.name}!')),
      );
    } on BackendException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
    if (mounted) setState(() => _joining = null);
  }

  @override
  Widget build(BuildContext context) => ClanRankingView(
    search: _search,
    onSearch: _onSearch,
    clans: _found ?? const [],
    ranked: _found == null,
    stream: _found == null ? _top : null,
    mine: widget.mine,
    canJoin: widget.canJoin,
    joining: _joining,
    labelOf: (c) => joinLabel(c, Backend.instance.profile.value),
    onJoin: _join,
    onDetails: (c) => _details(context, c, canJoin: widget.canJoin, onJoin: () => _join(c)),
  );
}

/// لوحة الترتيب (خشب): عنوان، وبحث، وقائمة الدواوين. [stream] للترتيب المباشر، و[clans] لنتيجة البحث.
class ClanRankingView extends StatelessWidget {
  const ClanRankingView({
    super.key,
    required this.search,
    required this.onSearch,
    required this.clans,
    required this.ranked,
    required this.mine,
    required this.canJoin,
    required this.labelOf,
    required this.onJoin,
    required this.onDetails,
    this.stream,
    this.joining,
  });

  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final List<Clan> clans;
  final Stream<List<Clan>>? stream;
  final bool ranked;
  final String? mine;
  final bool canJoin;
  final String? joining;
  final (String, bool) Function(Clan) labelOf;
  final ValueChanged<Clan> onJoin;
  final ValueChanged<Clan> onDetails;

  @override
  Widget build(BuildContext context) => WoodPanel(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SocPanelTitle('ترتيب الدواوين هالأسبوع'),
        const SizedBox(height: 8),
        SocPlankRow(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Row(
            children: [
              const Gfx('search', size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: search,
                  onChanged: onSearch,
                  style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 15, color: socCream),
                  decoration: const InputDecoration(
                    hintText: 'دوّر ديوان بالاسم',
                    hintStyle: TextStyle(
                      fontFamily: kufi,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFFD9C3A0),
                    ),
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: stream == null
              ? _list(context, clans)
              : StreamBuilder<List<Clan>>(
                  stream: stream,
                  builder: (context, snap) => snap.data == null
                      ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                      : _list(context, snap.data!),
                ),
        ),
      ],
    ),
  );

  Widget _list(BuildContext context, List<Clan> list) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          ranked ? 'ما فيه دواوين لعبت هالأسبوع للحين' : 'ما لقينا ديوان بهالاسم',
          style: const TextStyle(color: socMuted, fontFamily: kufi, fontWeight: FontWeight.w700),
        ),
      );
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 7),
      itemBuilder: (context, i) {
        final c = list[i];
        final isMine = c.id == mine;
        return SocPlankRow(
          selected: isMine,
          semantics: 'تفاصيل ${c.name}',
          onTap: () => onDetails(c),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Row(
            children: [
              if (ranked)
                SizedBox(
                  width: 26,
                  child: Text(
                    arabicNumber(i + 1),
                    style: const TextStyle(
                      fontFamily: kufi,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: socCream,
                    ),
                  ),
                ),
              ClanCrest.of(c.tag, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kufi,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: socCream,
                        height: 1.2,
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${arabicNumber(c.count)} عضو · مستوى ${arabicNumber(c.level)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: socMuted,
                              fontSize: 12.5,
                              fontFamily: kufi,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (c.join == ClanJoin.invite) ...[const SizedBox(width: 4), const Gfx('lock', size: 13)],
                        if (c.minLevel > 0)
                          Text(
                            '، ${arabicNumber(c.minLevel)}+',
                            style: const TextStyle(
                              color: socOrangeText,
                              fontSize: 12,
                              fontFamily: kufi,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                arabicNumber(c.points),
                style: const TextStyle(
                  fontFamily: kufi,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFFFFD27A),
                ),
              ),
              if (canJoin) ...[
                const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    final (label, ok) = labelOf(c);
                    return SocButton(
                      label: joining == c.id ? '…' : label,
                      tone: ok ? SocTone.green : SocTone.grey,
                      height: 30,
                      fontSize: 13.5,
                      padding: 8,
                      onPressed: !ok || joining != null ? null : () => onJoin(c),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// زر الديوان ودخوله حسب الشروط: (الكلام، يقدر يضغطه).
(String, bool) joinLabel(Clan c, Profile p) {
  final invited = p.clanInvites.any((i) => i.id == c.id);
  if (c.count >= clanMax) return ('مليان', false);
  if (invited) return ('ادخل', true);
  if (p.level < c.minLevel) return ('مستوى ${arabicNumber(c.minLevel)}+', false);
  return switch (c.join) {
    ClanJoin.invite => ('بالدعوة', false),
    ClanJoin.request => c.requests.any((r) => r.uid == Backend.instance.uid) ? ('انطلب', false) : ('اطلب', true),
    ClanJoin.open => ('ادخل', true),
  };
}

/// فيه رسائل في دردشة الديوان ما شفتها؟ (نقارن آخر رسالة بآخر مرة فتحتها).
class _NewMessages extends StatelessWidget {
  const _NewMessages({required this.clan, required this.builder});

  final Clan clan;
  final Widget Function(bool fresh) builder;

  @override
  Widget build(BuildContext context) => FutureBuilder<DateTime>(
    key: ValueKey(clan.chatAt),
    future: clanChatSeen(clan.id),
    builder: (context, snap) => builder(snap.hasData && clan.chatAt.isAfter(snap.data!)),
  );
}

/// عنوان صغير فوق حقل داخل النافذة.
Widget _fieldLabel(String t) => Padding(padding: const EdgeInsets.only(bottom: 4), child: SocPopupText(t, size: 14.5));

/// إعدادات الديوان (الشيخ ونوابه): الوصف، وأقل مستوى، وطريقة الدخول.
Future<void> _settings(BuildContext context, Clan clan) async {
  final desc = TextEditingController(text: clan.desc);
  var level = clan.minLevel;
  var join = clan.join;
  final save = await showSocDialog<bool>(
    context,
    title: 'إعدادات الديوان',
    width: 500,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: desc,
            maxLength: clanDescMax,
            maxLines: 2,
            style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, color: socInk),
            decoration: socParchInput(
              label: 'وصف الديوان',
              hint: 'مثلاً: ديوان للي يحبون اللعب الجاد، نلعب كل ليلة',
              dense: false,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fieldLabel('أقل مستوى'),
                    DropdownButtonFormField<int>(
                      initialValue: level,
                      isDense: true,
                      dropdownColor: const Color(0xFFF1DFB8),
                      style: const TextStyle(
                        fontFamily: kufi,
                        fontWeight: FontWeight.w800,
                        color: socInk,
                        fontSize: 14,
                      ),
                      decoration: socParchInput(),
                      items: [
                        for (final n in clanLevelSteps)
                          DropdownMenuItem(value: n, child: Text(n == 0 ? 'أي أحد' : '${arabicNumber(n)} وفوق')),
                      ],
                      onChanged: (v) => set(() => level = v ?? 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fieldLabel('الدخول'),
                    SocSegments<ClanJoin>(
                      light: true,
                      options: [for (final j in ClanJoin.values) (j, j.label)],
                      value: join,
                      onChanged: (v) => set(() => join = v),
                    ),
                    const SizedBox(height: 4),
                    SocPopupText(join.hint, size: 12.5, muted: true),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SocActions(
            children: [
              SocButton(
                label: 'إلغاء',
                tone: SocTone.grey,
                height: 42,
                fontSize: 16,
                onPressed: () => Navigator.pop(context, false),
              ),
              SocButton(
                label: 'حفظ',
                tone: SocTone.green,
                height: 42,
                fontSize: 16,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  final text = desc.text.trim();
  if (save == true && context.mounted) {
    await _run(
      context,
      () => Backend.instance.clanSettings(desc: text, minLevel: level, join: join),
      'انحفظت إعدادات الديوان',
    );
  }
}

/// دعوة للديوان (الوجهاء وفوق): من أصحابك اللي ما عندهم ديوان، أو برمز أي لاعب.
Future<void> _invite(BuildContext context, Clan clan) => showSocDialog<void>(
  context,
  title: 'ادعُ لـ${clan.name}',
  width: 520,
  builder: (_) => _InviteDialog(clan: clan),
);

class _InviteDialog extends StatefulWidget {
  const _InviteDialog({required this.clan});

  final Clan clan;

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _pid = TextEditingController();
  late final Future<List<LeaderboardEntry>> _friends = _load();
  final _sent = <String>{};
  LeaderboardEntry? _found;
  String? _busy;

  @override
  void dispose() {
    _pid.dispose();
    super.dispose();
  }

  Future<List<LeaderboardEntry>> _load() async {
    final ids = Backend.instance.profile.value.friends;
    final all = await Future.wait(ids.map((id) => Backend.instance.fetchPlayer(id).catchError((_) => null)));
    return [
      for (final e in all)
        if (e != null && e.clan == null) e,
    ];
  }

  Future<void> _send(LeaderboardEntry e) async {
    setState(() => _busy = e.uid);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Backend.instance.clanInvite(e.uid);
      _sent.add(e.uid);
    } on BackendException catch (err) {
      messenger.showSnackBar(SnackBar(content: Text(err.message)));
    }
    if (mounted) setState(() => _busy = null);
  }

  Future<void> _search() async {
    final pid = _pid.text.trim();
    if (pid.isEmpty) return;
    try {
      final e = await Backend.instance.findPlayer(pid);
      if (mounted) setState(() => _found = e);
    } on BackendException catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.message)));
    }
  }

  Widget _row(LeaderboardEntry e) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SocAvatar(avatar: e.avatar, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.name,
                style: const TextStyle(
                  fontFamily: kufi,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: socInk,
                  height: 1.2,
                ),
              ),
              Text(
                e.clan != null ? 'في ديوان ${e.clan!.name}' : 'مستوى ${arabicNumber(e.level)}',
                style: const TextStyle(
                  color: Color(0xFF7A5A3A),
                  fontSize: 12.5,
                  fontFamily: kufi,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SocButton(
          label: _sent.contains(e.uid) ? 'انرسلت' : (_busy == e.uid ? '…' : 'ادعُه'),
          tone: _sent.contains(e.uid) ? SocTone.grey : SocTone.green,
          height: 34,
          fontSize: 14,
          width: 92,
          onPressed: _sent.contains(e.uid) || _busy != null || e.clan != null ? null : () => _send(e),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 290,
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pid,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, color: socInk),
                decoration: socParchInput(hint: 'رمز اللاعب'),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: 8),
            SocButton(label: 'دوّر', tone: SocTone.blue, height: 40, width: 80, onPressed: _search),
          ],
        ),
        if (_found case final f?) _row(f),
        const Divider(color: Color(0xFFB59560)),
        Expanded(
          child: FutureBuilder<List<LeaderboardEntry>>(
            future: _friends,
            builder: (context, snap) {
              final list = snap.data;
              if (list == null) return const Center(child: CircularProgressIndicator(color: AppColors.goldDark));
              if (list.isEmpty) {
                return const Center(
                  child: SocPopupText('كل أصحابك في دواوين (أو ما عندك أصحاب)، دوّر لاعب برمزه', size: 14, muted: true),
                );
              }
              return ListView(children: [for (final e in list) _row(e)]);
            },
          ),
        ),
        const SizedBox(height: 8),
        SocButton(
          label: 'تمام',
          tone: SocTone.green,
          height: 42,
          fontSize: 16,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

/// طلبات الدخول (الوجهاء وفوق): قبول أو رفض.
Future<void> _requests(BuildContext context, Clan clan) async {
  final handled = <String>{};
  await showSocDialog<void>(
    context,
    title: 'طلبات الدخول',
    width: 520,
    builder: (context) => StatefulBuilder(
      builder: (context, set) {
        final list = clan.requests.where((r) => !handled.contains(r.uid)).toList();
        Future<void> respond(ClanRequest r, bool accept) async {
          await _run(
            context,
            () => Backend.instance.clanRespond(r.uid, accept: accept),
            accept ? '${r.name} دخل الديوان' : 'رفضت طلب ${r.name}',
          );
          set(() => handled.add(r.uid));
        }

        return SizedBox(
          height: 270,
          child: Column(
            children: [
              Expanded(
                child: list.isEmpty
                    ? const Center(child: SocPopupText('ما فيه طلبات', muted: true))
                    : ListView(
                        children: [
                          for (final r in list)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SocAvatar(avatar: r.avatar, size: 36),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.name,
                                          style: const TextStyle(
                                            fontFamily: kufi,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: socInk,
                                            height: 1.2,
                                          ),
                                        ),
                                        Text(
                                          'مستوى ${arabicNumber(r.level)}، ${agoText(DateTime.now().difference(r.at))}',
                                          style: const TextStyle(
                                            color: Color(0xFF7A5A3A),
                                            fontSize: 12.5,
                                            fontFamily: kufi,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SocButton(
                                    label: 'قبول',
                                    tone: SocTone.green,
                                    height: 34,
                                    fontSize: 14,
                                    width: 76,
                                    onPressed: () => respond(r, true),
                                  ),
                                  const SizedBox(width: 6),
                                  SocButton(
                                    label: 'رفض',
                                    tone: SocTone.grey,
                                    height: 34,
                                    fontSize: 14,
                                    width: 66,
                                    onPressed: () => respond(r, false),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
              SocButton(
                label: 'تمام',
                tone: SocTone.green,
                height: 42,
                fontSize: 16,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// تفاصيل ديوان من الترتيب: وصفه وشروطه وأعضاؤه، وزر الدخول (أو الطلب).
Future<void> _details(BuildContext context, Clan c, {required bool canJoin, required VoidCallback onJoin}) {
  final (label, ok) = joinLabel(c, Backend.instance.profile.value);
  return showSocDialog<void>(
    context,
    title: c.name,
    width: 520,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ClanCrest.of(c.tag, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  SocChip('المستوى ${arabicNumber(c.level)}', kind: SocChipKind.gold),
                  SocChip('${arabicNumber(c.count)} من ${arabicNumber(clanMax)} عضو', kind: SocChipKind.blue),
                  ...ClanPanelView.conditions(c),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SocPopupText(c.desc.isEmpty ? 'ما كتبوا وصف للديوان' : c.desc, size: 14.5, muted: c.desc.isEmpty),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final m in c.members.take(16))
              Tooltip(
                message: '${m.name} · ${m.roleName}',
                child: SocAvatar(
                  avatar: m.avatar,
                  size: 34,
                  ring: m.role == ClanRole.owner ? SocRing.gold : SocRing.blue,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        SocActions(
          children: [
            SocButton(
              label: 'سكّر',
              tone: SocTone.grey,
              height: 42,
              fontSize: 16,
              onPressed: () => Navigator.pop(context),
            ),
            if (canJoin)
              SocButton(
                label: label,
                tone: SocTone.green,
                height: 42,
                fontSize: 16,
                onPressed: ok
                    ? () {
                        Navigator.pop(context);
                        onJoin();
                      }
                    : null,
              ),
          ],
        ),
      ],
    ),
  );
}

/// دعوات الدواوين اللي وصلتك (لو ما عندك ديوان).
class _InviteBanner extends StatelessWidget {
  const _InviteBanner({required this.invites});

  final List<ClanInvite> invites;

  @override
  Widget build(BuildContext context) {
    final inv = invites.first;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: .28),
        border: Border.all(color: const Color(0xFFD9A84E), width: 1.8),
      ),
      child: Row(
        children: [
          ClanCrest.of(inv.tag, size: 38),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              invites.length > 1
                  ? '${inv.fromName} يدعوك تدخل ${inv.tag.name} (و${arabicNumber(invites.length - 1)} دعوات ثانية)'
                  : '${inv.fromName} يدعوك تدخل ${inv.tag.name}',
              maxLines: 2,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: kufi,
                fontWeight: FontWeight.w800,
                color: socCream,
                height: 1.3,
              ),
            ),
          ),
          SocButton(
            label: 'ادخل',
            tone: SocTone.green,
            height: 32,
            fontSize: 14,
            width: 66,
            onPressed: () =>
                _run(context, () => Backend.instance.clanInviteRespond(inv.id, accept: true), 'دخلت ${inv.tag.name}!'),
          ),
          const SizedBox(width: 6),
          SocButton(
            label: 'لا',
            tone: SocTone.grey,
            height: 32,
            fontSize: 14,
            width: 50,
            onPressed: () => _run(context, () => Backend.instance.clanInviteRespond(inv.id, accept: false)),
          ),
        ],
      ),
    );
  }
}
