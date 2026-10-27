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
import '../widgets/player_card.dart';
import '../widgets/ui.dart';
import 'chat_screen.dart';

/// الدواوين: لو ما عندك ديوان تسوي واحد أو تدخل واحد من الترتيب (أو بدعوة)، ولو عندك تشوف ديوانك: وصفه
/// وشروطه، والأعضاء برتبهم ومين متصل، والدردشة، والدعوات والطلبات، وهدف الأسبوع.
/// النقاط من الطاولات العامة بس: كل لعبة لعضو ١٠ نقاط، والفوز ٣٠.
class ClansScreen extends StatelessWidget {
  const ClansScreen({super.key});

  @override
  Widget build(BuildContext context) => NightScaffold(
    appBar: AppBar(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Gfx('shield', size: 30), SizedBox(width: 8), Text('الدواوين')],
      ),
    ),
    body: SafeArea(
      top: false,
      child: ValueListenableBuilder(
        valueListenable: Backend.instance.profile,
        builder: (context, p, _) => Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 11,
                child: p.clan == null ? const _CreateClan() : _MyClan(key: ValueKey(p.clan!.id), id: p.clan!.id),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 10,
                child: _Ranking(mine: p.clan?.id, canJoin: p.clan == null),
              ),
            ],
          ),
        ),
      ),
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
    // كل شي يبان بدون تمرير (الشاشة بالعرض قصيرة).
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (p.clanInvites.isNotEmpty) ...[_InviteBanner(invites: p.clanInvites), const SizedBox(height: 8)],
          Row(
            children: [
              ClanCrest(color: clanColors[_color], emblem: _emblem, size: 58),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _name,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'اسم ديوانك',
                    hintText: 'مثلاً: ديوان الصقور',
                    counterText: '',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                width: 52,
                child: Text('اللون', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              for (final (i, c) in clanColors.indexed)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: Semantics(
                    button: true,
                    label: 'لون ${i + 1}',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => setState(() => _color = i),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i == _color ? AppColors.gold : Colors.white24,
                            width: i == _color ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(
                width: 52,
                child: Text('الشعار', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final a in freeAvatars)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: Semantics(
                            button: true,
                            label: 'شعار $a',
                            excludeSemantics: true,
                            child: GestureDetector(
                              onTap: () => setState(() => _emblem = a),
                              child: PlayerAvatar(
                                avatar: a,
                                size: 40,
                                animate: false,
                                frame: a == _emblem ? AppColors.gold : null,
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
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          GameButton(
            label: _busy ? 'لحظة…' : (p.dev ? 'سوّ الديوان' : 'سوّ الديوان · ${arabicNumber(clanPrice)} ذهب'),
            icon: const Gfx('shield', size: 26),
            height: 46,
            fontSize: 16,
            onPressed: _busy || _name.text.trim().length < 3 ? null : _create,
          ),
        ],
      ),
    );
  }
}

/// ديوانك: الشعار والمستوى والأعضاء، وهدف الأسبوع وصندوقه.
class _MyClan extends StatelessWidget {
  const _MyClan({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => StreamBuilder<Clan?>(
    stream: Backend.instance.watchClan(id),
    builder: (context, snap) {
      final clan = snap.data;
      if (clan == null) {
        return const Panel(
          child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
        );
      }
      final me = Backend.instance.uid;
      final mine = clan.member(me);
      final power = mine?.role.power ?? 0;
      final reached = clan.points >= clanGoal;
      final played = (mine?.points ?? 0) > 0;
      final claimed = clan.claimed.contains(me);
      return Panel(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClanCrest.of(clan.tag, size: 66),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoldText(clan.name, size: 22, align: TextAlign.start),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        runSpacing: 3,
                        children: [
                          _pill('المستوى ${arabicNumber(clan.level)}', AppColors.gold),
                          _pill('${arabicNumber(clan.count)} من ${arabicNumber(clanMax)} عضو', AppColors.muted),
                          ..._conditions(clan),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _leave(context, clan),
                  child: const Text('اطلع', style: TextStyle(color: AppColors.traitorLight)),
                ),
              ],
            ),
            if (clan.desc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  clan.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFD9CFFF), fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 6),
            // الدردشة، والدعوة والطلبات (الوجهاء وفوق)، والإعدادات (الشيخ ونوابه).
            Row(
              children: [
                _NewMessages(
                  clan: clan,
                  builder: (fresh) => _Action(
                    icon: 'chat',
                    label: 'الدردشة',
                    dot: fresh,
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen.clan(clan: clan.tag))),
                  ),
                ),
                if (power >= ClanRole.elder.power) ...[
                  const SizedBox(width: 6),
                  _Action(icon: 'invite', label: 'دعوة', onTap: () => _invite(context, clan)),
                  if (clan.join == ClanJoin.request || clan.requests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _Action(
                      icon: 'addfriend',
                      label: 'الطلبات',
                      count: clan.requests.length,
                      onTap: () => _requests(context, clan),
                    ),
                  ],
                ],
                if (power >= ClanRole.deputy.power) ...[
                  const SizedBox(width: 6),
                  _Action(icon: 'tools', label: 'الإعدادات', onTap: () => _settings(context, clan)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // هدف الأسبوع وصندوقه
            Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withValues(alpha: .4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'هدف الأسبوع: ${arabicNumber(clan.points)} من ${arabicNumber(clanGoal)} نقطة'
                          '${reached ? '' : ' · اللعبة العامة ١٠ والفوز ٣٠'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (clan.points / clanGoal).clamp(0.0, 1.0),
                            minHeight: 9,
                            backgroundColor: Colors.black38,
                            color: AppColors.gold,
                          ),
                        ),
                        if (reached) ...[
                          const SizedBox(height: 3),
                          Text(
                            claimed
                                ? 'استلمت صندوق هالأسبوع'
                                : (played ? 'وصلتوا الهدف! استلم صندوقك' : 'العب مع ديوانك وتستلم الصندوق'),
                            style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      Opacity(opacity: reached && !claimed ? 1 : .45, child: const Gfx('gem_chest', size: 34)),
                      if (reached && played && !claimed)
                        SizedBox(
                          height: 30,
                          child: TextButton(
                            onPressed: () => _run(
                              context,
                              Backend.instance.claimClanChest,
                              'استلمت ${arabicNumber(clanChest.coins)} ذهب و${arabicNumber(clanChest.diamonds)} جواهر',
                            ),
                            child: const Text('استلم'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.extent(
                maxCrossAxisExtent: 86,
                childAspectRatio: .78,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [for (final m in clan.members) _MemberCell(clan: clan, member: m, me: mine)],
              ),
            ),
          ],
        ),
      );
    },
  );

  static Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: .7)),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w800),
    ),
  );

  /// شروط الدخول كشارات: الطريقة، وأقل مستوى.
  static List<Widget> _conditions(Clan clan) => [
    _pill('الدخول ${clan.join.label}', const Color(0xFF7FE9FF)),
    if (clan.minLevel > 0) _pill('مستوى ${arabicNumber(clan.minLevel)}+', const Color(0xFFFFB86B)),
  ];

  Future<void> _leave(BuildContext context, Clan clan) async {
    final alone = clan.count == 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تطلع من الديوان؟', textAlign: TextAlign.center),
        content: Text(
          alone
              ? 'أنت آخر واحد فيه، فبينحذف الديوان.'
              : clan.ownerId == Backend.instance.uid
              ? 'المشيخة بتروح لنائبك (أو أقدم عضو).'
              : 'تقدر تدخل ديوان ثاني بعدين.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('اطلع')),
        ],
      ),
    );
    if (ok == true && context.mounted) await _run(context, Backend.instance.leaveClan, 'طلعت من الديوان');
  }
}

/// عضو في الديوان: صورته واسمه ودوره ونقاطه هالأسبوع. الشيخ (أو نائبه) يضغط عليه ويطلّعه أو يخليه نائب.
class _MemberCell extends StatelessWidget {
  const _MemberCell({required this.clan, required this.member, required this.me});

  final Clan clan;
  final ClanMember member;
  final ClanMember? me;

  /// الشيخ ونوابه يقدرون على اللي تحتهم بالرتبة.
  bool get _canManage =>
      member.uid != me?.uid && (me?.role.power ?? 0) >= ClanRole.deputy.power && me!.role.power > member.role.power;

  /// الرتب اللي أقدر أعطيه: الشيخ أي رتبة (والمشيخة نفسها)، والنائب بين العضو والوجيه.
  List<ClanRole> get _roles => [
    if (me?.role == ClanRole.owner) ...[ClanRole.owner, ClanRole.deputy],
    ClanRole.elder,
    ClanRole.member,
  ].where((r) => r != member.role).toList();

  Future<void> _manage(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.panel,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: PlayerAvatar(avatar: member.avatar, size: 40, animate: false),
                title: Text(member.name),
                subtitle: Text(member.roleName),
              ),
              ListTile(
                leading: const Gfx('profile', size: 26),
                title: const Text('بطاقته'),
                onTap: () => Navigator.pop(context, 'card'),
              ),
              for (final r in _roles)
                ListTile(
                  leading: Gfx(r == ClanRole.owner ? 'trophy' : 'medal${r == ClanRole.member ? 3 : r.index}', size: 26),
                  title: Text(switch (r) {
                    ClanRole.owner => 'سلّمه المشيخة (وتصير نائب)',
                    ClanRole.member => 'رجّعه عضو',
                    _ => 'خله ${r.label}',
                  }),
                  onTap: () => Navigator.pop(context, 'role:${r.name}'),
                ),
              ListTile(
                leading: const Gfx('exit', size: 26),
                title: const Text('طلّعه من الديوان', style: TextStyle(color: AppColors.traitorLight)),
                onTap: () => Navigator.pop(context, 'kick'),
              ),
            ],
          ),
        ),
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
        final sure = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تسلّمه المشيخة؟'),
            content: Text('${member.name} بيصير شيخ الديوان، وأنت تصير نائب.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('سلّمه')),
            ],
          ),
        );
        if (sure != true || !context.mounted) return;
      }
      await _run(context, () => Backend.instance.clanRole(member.uid, role), 'صار ${role.label}');
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'عضو ${member.name}',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: _canManage
          ? () => _manage(context)
          : () => showPlayerCard(context, uid: member.uid, name: member.name, avatar: member.avatar),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: member.uid == me?.uid ? .09 : .04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: member.role == ClanRole.owner ? AppColors.gold : AppColors.line),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                PlayerAvatar(
                  avatar: member.avatar,
                  size: 40,
                  animate: false,
                  frame: member.role == ClanRole.owner ? AppColors.gold : null,
                ),
                // متصل الحين؟
                PositionedDirectional(
                  bottom: -1,
                  end: -1,
                  child: StreamBuilder<Presence>(
                    stream: Backend.instance.watchPresence(member.uid),
                    builder: (context, snap) => Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (snap.data?.online ?? false) || member.uid == me?.uid
                            ? AppColors.green
                            : const Color(0xFF6B6785),
                        border: Border.all(color: AppColors.panel, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              member.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
            if (member.role != ClanRole.member)
              Text(
                member.roleName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: switch (member.role) {
                    ClanRole.owner => AppColors.gold,
                    ClanRole.deputy => const Color(0xFFB9A4FF),
                    _ => const Color(0xFF5EEAD4),
                  },
                ),
              ),
            Text('${arabicNumber(member.points)} نقطة', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          ],
        ),
      ),
    ),
  );
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
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ترتيب الدواوين هالأسبوع',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: kufi, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: TextField(
            controller: _search,
            onChanged: _onSearch,
            decoration: const InputDecoration(
              hintText: 'دوّر ديوان بالاسم',
              prefixIcon: Padding(padding: EdgeInsets.all(8), child: Gfx('search', size: 20)),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _found != null
              ? _list(_found!, ranked: false)
              : StreamBuilder<List<Clan>>(
                  stream: _top,
                  builder: (context, snap) => snap.data == null
                      ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                      : _list(snap.data!, ranked: true),
                ),
        ),
      ],
    ),
  );

  Widget _list(List<Clan> clans, {required bool ranked}) {
    if (clans.isEmpty) {
      return Center(
        child: Text(
          ranked ? 'ما فيه دواوين لعبت هالأسبوع للحين' : 'ما لقينا ديوان بهالاسم',
          style: const TextStyle(color: AppColors.muted),
        ),
      );
    }
    return ListView.separated(
      itemCount: clans.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final c = clans[i];
        final mine = c.id == widget.mine;
        final row = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: mine ? AppColors.gold.withValues(alpha: .16) : Colors.white.withValues(alpha: .04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: mine ? AppColors.gold : Colors.transparent, width: 1.4),
          ),
          child: Row(
            children: [
              if (ranked)
                SizedBox(
                  width: 24,
                  child: Text(
                    arabicNumber(i + 1),
                    style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, color: AppColors.gold),
                  ),
                ),
              ClanCrest.of(c.tag, size: 34),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${arabicNumber(c.count)} عضو · مستوى ${arabicNumber(c.level)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted, fontSize: 11),
                          ),
                        ),
                        if (c.join == ClanJoin.invite) ...[const SizedBox(width: 4), const Gfx('lock', size: 13)],
                        if (c.minLevel > 0)
                          Text(
                            ' · ${arabicNumber(c.minLevel)}+',
                            style: const TextStyle(color: Color(0xFFFFB86B), fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                arabicNumber(c.points),
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.goldLight),
              ),
              if (widget.canJoin) ...[
                const SizedBox(width: 6),
                Builder(
                  builder: (context) {
                    final (label, ok) = joinLabel(c, Backend.instance.profile.value);
                    return SizedBox(
                      height: 32,
                      child: TextButton(
                        onPressed: !ok || _joining != null ? null : () => _join(c),
                        child: Text(_joining == c.id ? '…' : label),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
        return Semantics(
          button: true,
          label: 'تفاصيل ${c.name}',
          child: GestureDetector(
            onTap: () => _details(context, c, canJoin: widget.canJoin, onJoin: () => _join(c)),
            child: row,
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

/// زر صغير في لوحة الديوان، ومعه نقطة (جديد) أو رقم.
class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap, this.dot = false, this.count = 0});

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool dot;
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 10, 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: .07),
              border: Border.all(color: dot || count > 0 ? AppColors.gold : Colors.white.withValues(alpha: .16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Gfx(icon, size: 20),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          if (count > 0 || dot)
            PositionedDirectional(
              top: -5,
              end: -4,
              child: Container(
                constraints: BoxConstraints(minWidth: count > 0 ? 18 : 11),
                height: count > 0 ? 18 : 11,
                padding: EdgeInsets.symmetric(horizontal: count > 0 ? 4 : 0),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.traitor,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.panel, width: 1.5),
                ),
                child: count > 0
                    ? Text(arabicNumber(count), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900))
                    : null,
              ),
            ),
        ],
      ),
    ),
  );
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

/// إعدادات الديوان (الشيخ ونوابه): الوصف، وأقل مستوى، وطريقة الدخول.
Future<void> _settings(BuildContext context, Clan clan) async {
  final desc = TextEditingController(text: clan.desc);
  var level = clan.minLevel;
  var join = clan.join;
  final save = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => AlertDialog(
        title: const Row(children: [Gfx('tools', size: 28), SizedBox(width: 8), Text('إعدادات الديوان')]),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: desc,
                  maxLength: clanDescMax,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'وصف الديوان',
                    hintText: 'مثلاً: ديوان للي يحبون اللعب الجاد، نلعب كل ليلة',
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('أقل مستوى', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<int>(
                            initialValue: level,
                            isDense: true,
                            decoration: const InputDecoration(isDense: true),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('الدخول', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          SegmentedButton<ClanJoin>(
                            showSelectedIcon: false,
                            style: const ButtonStyle(visualDensity: VisualDensity.compact),
                            segments: [for (final j in ClanJoin.values) ButtonSegment(value: j, label: Text(j.label))],
                            selected: {join},
                            onSelectionChanged: (v) => set(() => join = v.first),
                          ),
                          const SizedBox(height: 4),
                          Text(join.hint, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ')),
        ],
      ),
    ),
  );
  if (save == true && context.mounted) {
    await _run(
      context,
      () => Backend.instance.clanSettings(desc: desc.text.trim(), minLevel: level, join: join),
      'انحفظت إعدادات الديوان',
    );
  }
}

/// دعوة للديوان (الوجهاء وفوق): من أصحابك اللي ما عندهم ديوان، أو برمز أي لاعب.
Future<void> _invite(BuildContext context, Clan clan) => showDialog<void>(
  context: context,
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

  Widget _row(LeaderboardEntry e) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: PlayerAvatar(avatar: e.avatar, size: 36, animate: false),
    title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(
      e.clan != null ? 'في ديوان ${e.clan!.name}' : 'مستوى ${arabicNumber(e.level)}',
      style: const TextStyle(color: AppColors.muted, fontSize: 12),
    ),
    trailing: SizedBox(
      width: 92,
      child: GameButton(
        label: _sent.contains(e.uid) ? 'انرسلت' : (_busy == e.uid ? '…' : 'ادعُه'),
        tone: _sent.contains(e.uid) ? ButtonTone.ghost : ButtonTone.gold,
        height: 36,
        fontSize: 13.5,
        onPressed: _sent.contains(e.uid) || _busy != null || e.clan != null ? null : () => _send(e),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: [
        const Gfx('invite', size: 28),
        const SizedBox(width: 8),
        Flexible(child: Text('ادعُ لـ${widget.clan.name}', overflow: TextOverflow.ellipsis)),
      ],
    ),
    content: SizedBox(
      width: 480,
      height: 300,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pid,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(hintText: 'رمز اللاعب', isDense: true),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: _search, child: const Text('دوّر')),
            ],
          ),
          if (_found case final f?) _row(f),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<LeaderboardEntry>>(
              future: _friends,
              builder: (context, snap) {
                final list = snap.data;
                if (list == null) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      'كل أصحابك في دواوين (أو ما عندك أصحاب)، دوّر لاعب برمزه',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                return ListView(children: [for (final e in list) _row(e)]);
              },
            ),
          ),
        ],
      ),
    ),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تمام'))],
  );
}

/// طلبات الدخول (الوجهاء وفوق): قبول أو رفض.
Future<void> _requests(BuildContext context, Clan clan) async {
  final handled = <String>{};
  await showDialog<void>(
    context: context,
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

        return AlertDialog(
          title: const Row(children: [Gfx('addfriend', size: 28), SizedBox(width: 8), Text('طلبات الدخول')]),
          content: SizedBox(
            width: 480,
            height: 260,
            child: list.isEmpty
                ? const Center(
                    child: Text('ما فيه طلبات', style: TextStyle(color: AppColors.muted)),
                  )
                : ListView(
                    children: [
                      for (final r in list)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: PlayerAvatar(avatar: r.avatar, size: 36, animate: false),
                          title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(
                            'مستوى ${arabicNumber(r.level)} · ${agoText(DateTime.now().difference(r.at))}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 76,
                                child: GameButton(
                                  label: 'قبول',
                                  tone: ButtonTone.green,
                                  height: 34,
                                  fontSize: 13,
                                  onPressed: () => respond(r, true),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 66,
                                child: GameButton(
                                  label: 'رفض',
                                  tone: ButtonTone.ghost,
                                  height: 34,
                                  fontSize: 13,
                                  onPressed: () => respond(r, false),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('تمام'))],
        );
      },
    ),
  );
}

/// تفاصيل ديوان من الترتيب: وصفه وشروطه وأعضاؤه، وزر الدخول (أو الطلب).
Future<void> _details(BuildContext context, Clan c, {required bool canJoin, required VoidCallback onJoin}) =>
    showDialog<void>(
      context: context,
      builder: (context) {
        final (label, ok) = joinLabel(c, Backend.instance.profile.value);
        return AlertDialog(
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClanCrest.of(c.tag, size: 64),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GoldText(c.name, size: 22, align: TextAlign.start),
                            Wrap(
                              spacing: 6,
                              runSpacing: 3,
                              children: [
                                _MyClan._pill('المستوى ${arabicNumber(c.level)}', AppColors.gold),
                                _MyClan._pill(
                                  '${arabicNumber(c.count)} من ${arabicNumber(clanMax)} عضو',
                                  AppColors.muted,
                                ),
                                ..._MyClan._conditions(c),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    c.desc.isEmpty ? 'ما كتبوا وصف للديوان' : c.desc,
                    style: TextStyle(color: c.desc.isEmpty ? AppColors.muted : AppColors.text, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final m in c.members.take(16))
                        Tooltip(
                          message: '${m.name} · ${m.roleName}',
                          child: PlayerAvatar(
                            avatar: m.avatar,
                            size: 34,
                            animate: false,
                            frame: m.role == ClanRole.owner ? AppColors.gold : null,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('سكّر')),
            if (canJoin)
              TextButton(
                onPressed: ok
                    ? () {
                        Navigator.pop(context);
                        onJoin();
                      }
                    : null,
                child: Text(label),
              ),
          ],
        );
      },
    );

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
        color: AppColors.gold.withValues(alpha: .1),
        border: Border.all(color: AppColors.gold.withValues(alpha: .6)),
      ),
      child: Row(
        children: [
          ClanCrest.of(inv.tag, size: 36),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              invites.length > 1
                  ? '${inv.fromName} يدعوك تدخل ${inv.tag.name} (و${arabicNumber(invites.length - 1)} دعوات ثانية)'
                  : '${inv.fromName} يدعوك تدخل ${inv.tag.name}',
              maxLines: 2,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: () =>
                _run(context, () => Backend.instance.clanInviteRespond(inv.id, accept: true), 'دخلت ${inv.tag.name}!'),
            child: const Text('ادخل'),
          ),
          TextButton(
            onPressed: () => _run(context, () => Backend.instance.clanInviteRespond(inv.id, accept: false)),
            child: const Text('لا', style: TextStyle(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}
