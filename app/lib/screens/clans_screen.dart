import 'dart:async';

import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../models/clan.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/clan_crest.dart';
import '../widgets/common.dart';
import '../widgets/player_card.dart';
import '../widgets/ui.dart';

/// الدواوين: لو ما عندك ديوان تسوي واحد أو تدخل واحد من الترتيب، ولو عندك تشوف ديوانك وأعضاءه وهدف الأسبوع.
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
            'ديوان مع ربعك (بالكثير ٣٠)، وكل لعبة بطاولة عامة تزيد نقاطكم هالأسبوع',
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
                        children: [
                          _pill('المستوى ${arabicNumber(clan.level)}', AppColors.gold),
                          _pill('${arabicNumber(clan.count)} من ${arabicNumber(clanMax)} عضو', AppColors.muted),
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
                          'هدف الأسبوع: ${arabicNumber(clan.points)} من ${arabicNumber(clanGoal)} نقطة',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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
                        const SizedBox(height: 3),
                        Text(
                          reached
                              ? (claimed
                                    ? 'استلمت صندوق هالأسبوع'
                                    : (played ? 'وصلتوا الهدف! استلم صندوقك' : 'العب مع ديوانك وتستلم الصندوق'))
                              : 'كل لعبة بطاولة عامة: ١٠ نقاط، والفوز ٣٠',
                          style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      Opacity(opacity: reached && !claimed ? 1 : .45, child: const Gfx('gem_chest', size: 44)),
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

  bool get _canManage =>
      member.uid != me?.uid &&
      (me?.role == ClanRole.owner || (me?.role == ClanRole.deputy && member.role == ClanRole.member));

  Future<void> _manage(BuildContext context) async {
    final owner = me?.role == ClanRole.owner;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.panel,
      builder: (context) => SafeArea(
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
            if (owner)
              ListTile(
                leading: const Gfx('medal1', size: 26),
                title: Text(member.role == ClanRole.deputy ? 'رجّعه عضو' : 'خله نائب'),
                onTap: () => Navigator.pop(context, 'role'),
              ),
            ListTile(
              leading: const Gfx('exit', size: 26),
              title: const Text('طلّعه من الديوان', style: TextStyle(color: AppColors.traitorLight)),
              onTap: () => Navigator.pop(context, 'kick'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'card':
        showPlayerCard(context, uid: member.uid, name: member.name, avatar: member.avatar);
      case 'role':
        await _run(
          context,
          () => Backend.instance.clanRole(member.uid, deputy: member.role != ClanRole.deputy),
          member.role == ClanRole.deputy ? 'رجع عضو' : 'صار نائب',
        );
      case 'kick':
        await _run(context, () => Backend.instance.clanKick(member.uid), 'طلع من الديوان');
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
            PlayerAvatar(
              avatar: member.avatar,
              size: 40,
              animate: false,
              frame: member.role == ClanRole.owner ? AppColors.gold : null,
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
                style: const TextStyle(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.w800),
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
    await _run(context, () => Backend.instance.joinClan(c.id), 'دخلت ${c.name}!');
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
        return Container(
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
                    Text(
                      '${arabicNumber(c.count)} عضو · مستوى ${arabicNumber(c.level)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
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
                SizedBox(
                  height: 32,
                  child: TextButton(
                    onPressed: c.count >= clanMax || _joining != null ? null : () => _join(c),
                    child: Text(c.count >= clanMax ? 'مليان' : (_joining == c.id ? '…' : 'ادخل')),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
