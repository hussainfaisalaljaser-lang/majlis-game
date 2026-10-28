import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/chat.dart';
import '../models/clan.dart';
import '../models/leaderboard.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/clan_crest.dart';
import '../widgets/common.dart';
import '../widgets/friend_button.dart';
import '../widgets/pid.dart';
import '../widgets/player_card.dart';
import '../widgets/ui.dart';
import 'chat_screen.dart';
import 'game_screen.dart';

/// الأصدقاء: قائمتك، ومحادثاتك، والطلبات اللي وصلتك، وتضيف أحد برمزه.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, this.tab = friendsTab});

  /// يفتح على اللي يهمك: طلبات صداقة، أو رسائل ما قريتها، أو أصدقائك.
  FriendsScreen.forProfile(Profile p, {super.key})
    : tab = p.friendReqs.isNotEmpty
          ? requestsTab
          : p.unreadDms > 0
          ? chatsTab
          : friendsTab;

  static const friendsTab = 0, chatsTab = 1, requestsTab = 2, addTab = 3;

  final int tab;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _backend = Backend.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _backend.profile,
      builder: (context, p, _) {
        final reqs = p.friendReqs.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        return DefaultTabController(
          length: 4,
          initialIndex: widget.tab,
          child: NightScaffold(
            appBar: AppBar(
              title: const Row(children: [Gfx('friends', size: 30), SizedBox(width: 8), Text('الأصدقاء')]),
              bottom: TabBar(
                tabs: [
                  Tab(text: p.friends.isEmpty ? 'أصدقائي' : 'أصدقائي (${arabicNumber(p.friends.length)})'),
                  Tab(text: p.unreadDms == 0 ? 'الدردشات' : 'الدردشات (${arabicNumber(p.unreadDms)})'),
                  Tab(text: reqs.isEmpty ? 'الطلبات' : 'الطلبات (${arabicNumber(reqs.length)})'),
                  const Tab(text: 'أضف صديق'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                p.friends.isEmpty
                    ? _Empty(
                        icon: 'friends',
                        text: 'ما عندك أصدقاء للحين.\nضيفهم برمزهم من «أضف صديق»، أو من بطاقة أي لاعب في الطاولة.',
                        action: ('أضف صديق', () => DefaultTabController.of(context).animateTo(FriendsScreen.addTab)),
                      )
                    : _FriendsList(uids: p.friends, unread: p.dmUnread),
                _ChatsList(profile: p),
                reqs.isEmpty
                    ? const _Empty(icon: 'invite', text: 'ما فيه طلبات صداقة')
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                        children: [for (final r in reqs) _RequestRow(uid: r.key)],
                      ),
                const _AddFriend(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text, this.action});

  final String icon;
  final String text;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(opacity: .8, child: Gfx(icon, size: 64)),
        const SizedBox(height: 10),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, height: 1.6),
        ),
        if (action case (final label, final onTap)) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 200,
            child: GameButton(label: label, height: 44, fontSize: 15, onPressed: onTap),
          ),
        ],
      ],
    ),
  );
}

/// سطر لاعب: صورته واسمه ومستواه ورمزه، والضغط يفتح بطاقته. [trailing] أزرار على الطرف.
class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.uid,
    required this.entry,
    this.trailing = const [],
    this.playing = false,
    this.status,
    this.online,
  });

  final String uid;
  final LeaderboardEntry? entry;
  final List<Widget> trailing;

  /// يلعب الحين (نقطة خضرا وسطر تحت اسمه).
  final bool playing;

  /// حالة الاتصال تحت اسمه (متصل، آخر ظهور…)، ونقطة على صورته: خضرا متصل، ورمادية لا (null: بدون نقطة).
  final String? status;
  final bool? online;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'ملف ${e?.name ?? 'لاعب'}',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: e == null
                      ? null
                      : () => showPlayerCard(context, uid: uid, name: e.name, avatar: e.avatar, frame: e.frame),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          PlayerAvatar(
                            avatar: e?.avatar ?? 'masked',
                            style: frameStyle(e?.frame),
                            size: 46,
                            animate: false,
                          ),
                          if (online != null)
                            PositionedDirectional(
                              bottom: 0,
                              end: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: online! ? AppColors.green : const Color(0xFF6B6785),
                                  border: Border.all(color: AppColors.panel, width: 2.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e?.name ?? '…',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                            ),
                            if (e != null)
                              Text(
                                playing
                                    ? 'يلعب الحين'
                                    : status == null
                                    ? 'مستوى ${arabicNumber(e.level)}'
                                    : '$status · مستوى ${arabicNumber(e.level)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: playing || (online ?? false) ? AppColors.green : AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: playing || (online ?? false) ? FontWeight.w800 : null,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (e != null) PidBadge(pid: e.pid, tier: e.pidTier, size: 12, copy: false),
                    ],
                  ),
                ),
              ),
            ),
            for (final t in trailing) Padding(padding: const EdgeInsetsDirectional.only(start: 8), child: t),
          ],
        ),
      ),
    );
  }
}

/// أصحابي: المتصلين أول (واللي يلعبون بعدهم)، وبعدين غير المتصلين من آخر ظهور. الحالة تتحدث مباشرة.
class _FriendsList extends StatefulWidget {
  const _FriendsList({required this.uids, required this.unread});

  final List<String> uids;

  /// رسائل ما قريتها من كل صاحب.
  final Map<String, int> unread;

  @override
  State<_FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<_FriendsList> {
  final _entries = <String, LeaderboardEntry?>{};
  final _presence = <String, Presence>{};
  final _subs = <String, StreamSubscription<Presence>>{};

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_FriendsList old) {
    super.didUpdateWidget(old);
    _sync();
  }

  /// كل صاحب: ملفه العام مرة، وحالته مباشرة. اللي انشال من الأصحاب نوقف متابعته.
  void _sync() {
    final backend = Backend.instance;
    for (final uid in widget.uids) {
      if (!_entries.containsKey(uid)) {
        _entries[uid] = null;
        backend.fetchPlayer(uid).then((e) {
          if (mounted) setState(() => _entries[uid] = e);
        }, onError: (_) {});
      }
      _subs.putIfAbsent(
        uid,
        () => backend.watchPresence(uid).listen((p) {
          if (mounted) setState(() => _presence[uid] = p);
        }),
      );
    }
    for (final uid in _subs.keys.toList()) {
      if (widget.uids.contains(uid)) continue;
      _subs.remove(uid)!.cancel();
      _presence.remove(uid);
      _entries.remove(uid);
    }
  }

  @override
  void dispose() {
    for (final s in _subs.values) {
      s.cancel();
    }
    super.dispose();
  }

  bool _online(String uid) => (_presence[uid]?.online ?? false) || (_entries[uid]?.playing ?? false);

  @override
  Widget build(BuildContext context) {
    // متصل (وما يلعب) ← يلعب ← غير متصل من آخر ظهور. وبين المتساوين: اللي أضفته أخيراً أول.
    final order = {for (final (i, uid) in widget.uids.indexed) uid: i};
    int rank(String uid) => (_entries[uid]?.playing ?? false) ? 1 : (_online(uid) ? 0 : 2);
    final sorted = [...widget.uids]
      ..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        if (rank(a) == 2) {
          final ta = _presence[a]?.at, tb = _presence[b]?.at;
          if (ta != tb) return (tb ?? DateTime(2000)).compareTo(ta ?? DateTime(2000));
        }
        return order[b]!.compareTo(order[a]!);
      });
    final online = sorted.where(_online).toList();
    final offline = sorted.where((u) => !_online(u)).toList();
    Widget header(String text, int n, Color color) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            '$text (${arabicNumber(n)})',
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      children: [
        if (online.isNotEmpty) header('متصلين الحين', online.length, AppColors.green),
        for (final uid in online)
          _FriendRow(
            key: ValueKey(uid),
            uid: uid,
            entry: _entries[uid],
            presence: _presence[uid],
            unread: widget.unread[uid] ?? 0,
          ),
        if (offline.isNotEmpty) header('غير متصلين', offline.length, AppColors.muted),
        for (final uid in offline)
          _FriendRow(
            key: ValueKey(uid),
            uid: uid,
            entry: _entries[uid],
            presence: _presence[uid],
            unread: widget.unread[uid] ?? 0,
          ),
      ],
    );
  }
}

/// محادثاتك: دردشة ديوانك (لو أنت في ديوان)، ومحادثاتك مع أصحابك (الأحدث فوق)، وكل وحدة فيها آخر رسالة
/// ومتى، وكم رسالة ما قريتها.
class _ChatsList extends StatefulWidget {
  const _ChatsList({required this.profile});

  final Profile profile;

  @override
  State<_ChatsList> createState() => _ChatsListState();
}

class _ChatsListState extends State<_ChatsList> {
  final _entries = <String, LeaderboardEntry?>{};

  /// الأصحاب اللي بينا محادثة (أو رسائل ما قريتها من قبل ما تنحفظ آخر رسالة)، والأحدث أول.
  List<String> get _uids {
    final p = widget.profile;
    final ids = {...p.dmLast.keys, ...p.dmUnread.keys}.where(p.friends.contains).toList();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    ids.sort((a, b) => (p.dmLast[b]?.at ?? epoch).compareTo(p.dmLast[a]?.at ?? epoch));
    return ids;
  }

  void _fetch(String uid) {
    if (_entries.containsKey(uid)) return;
    _entries[uid] = null;
    Backend.instance.fetchPlayer(uid).then((e) {
      if (mounted) setState(() => _entries[uid] = e);
    }, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final uids = _uids;
    uids.forEach(_fetch);
    if (p.clan == null && uids.isEmpty) {
      return const _Empty(
        icon: 'chat',
        text: 'ما فيه محادثات للحين.\nابدأ دردشة مع أي صاحب من «أصدقائي»، أو ادخل ديوان وسولف مع ربعك.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      children: [
        if (p.clan case final clan?) _ClanChatRow(clan: clan),
        for (final uid in uids)
          _ChatRow(
            key: ValueKey(uid),
            uid: uid,
            entry: _entries[uid],
            last: p.dmLast[uid],
            unread: p.dmUnread[uid] ?? 0,
            me: Backend.instance.uid,
          ),
      ],
    );
  }
}

/// سطر محادثة: الصورة والاسم، وآخر رسالة ومتى، وعدد اللي ما قريته.
class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.leading,
    required this.title,
    required this.preview,
    required this.onTap,
    this.previewSticker,
    this.at,
    this.unread = 0,
    this.fresh = false,
  });

  final Widget leading;
  final String title;
  final String preview;

  /// لو آخر رسالة ملصق: صورته الصغيرة قبل الكلام.
  final String? previewSticker;
  final DateTime? at;
  final int unread;

  /// فيه جديد (دردشة الديوان ما تنعد، بس نعلّمها).
  final bool fresh;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hot = unread > 0 || fresh;
    final sticker = previewSticker == null ? null : stickerById(previewSticker!);
    return Semantics(
      button: true,
      label: 'محادثة $title',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(
              color: hot ? AppColors.gold.withValues(alpha: .08) : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: hot ? AppColors.gold.withValues(alpha: .5) : AppColors.line),
            ),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      Row(
                        children: [
                          if (sticker != null) ...[
                            Image.asset(sticker.asset, width: 22, height: 22, filterQuality: FilterQuality.medium),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hot ? AppColors.text : AppColors.muted,
                                fontWeight: hot ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (at != null)
                      Text(
                        agoText(DateTime.now().difference(at!)),
                        style: TextStyle(color: hot ? AppColors.goldLight : AppColors.muted, fontSize: 11.5),
                      ),
                    const SizedBox(height: 4),
                    if (unread > 0)
                      Container(
                        constraints: const BoxConstraints(minWidth: 22),
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.traitor, borderRadius: BorderRadius.circular(11)),
                        child: Text(
                          arabicNumber(unread),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, height: 1.1),
                        ),
                      )
                    else if (fresh)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.traitor),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// آخر رسالة بالكلام: «ملصق» جنب صورته، و«أنت: » لو أنت اللي أرسلتها.
String _previewOf({required String text, required String? sticker, required bool mine, String? name}) {
  final body = sticker != null ? 'ملصق' : text;
  if (mine) return 'أنت: $body';
  return name == null || name.isEmpty ? body : '$name: $body';
}

class _ClanChatRow extends StatefulWidget {
  const _ClanChatRow({required this.clan});

  final ClanTag clan;

  @override
  State<_ClanChatRow> createState() => _ClanChatRowState();
}

class _ClanChatRowState extends State<_ClanChatRow> {
  late Stream<ChatMessage?> _last = Backend.instance.watchClanLast(widget.clan.id);
  DateTime? _seen;

  @override
  void initState() {
    super.initState();
    _loadSeen();
  }

  @override
  void didUpdateWidget(_ClanChatRow old) {
    super.didUpdateWidget(old);
    if (old.clan.id != widget.clan.id) _last = Backend.instance.watchClanLast(widget.clan.id);
  }

  Future<void> _loadSeen() async {
    final seen = await clanChatSeen(widget.clan.id);
    if (mounted) setState(() => _seen = seen);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<ChatMessage?>(
    stream: _last,
    builder: (context, snap) {
      final m = snap.data;
      return _ChatTile(
        leading: ClanCrest.of(widget.clan, size: 44),
        title: 'ديوان ${widget.clan.name}',
        preview: m == null
            ? 'دردشة ربعك في الديوان'
            : m.system
            ? m.text
            : _previewOf(text: m.text, sticker: m.sticker, mine: m.uid == Backend.instance.uid, name: m.name),
        previewSticker: m?.sticker,
        at: m?.at,
        fresh: m != null && _seen != null && m.at.isAfter(_seen!) && m.uid != Backend.instance.uid,
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen.clan(clan: widget.clan)));
          _loadSeen();
        },
      );
    },
  );
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({
    super.key,
    required this.uid,
    required this.entry,
    required this.last,
    required this.unread,
    required this.me,
  });

  final String uid;
  final LeaderboardEntry? entry;
  final ChatLast? last;
  final int unread;
  final String me;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final l = last;
    return _ChatTile(
      leading: PlayerAvatar(avatar: e?.avatar ?? 'masked', style: frameStyle(e?.frame), size: 44, animate: false),
      title: e?.name ?? '…',
      preview: l == null ? 'رسائل جديدة' : _previewOf(text: l.text, sticker: l.sticker, mine: l.from == me),
      previewSticker: l?.sticker,
      at: l?.at,
      unread: unread,
      onTap: e == null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen.friend(friend: (uid: uid, name: e.name, avatar: e.avatar, frame: e.frame)),
              ),
            ),
    );
  }
}

class _FriendRow extends StatefulWidget {
  const _FriendRow({super.key, required this.uid, required this.entry, required this.presence, required this.unread});

  final String uid;
  final LeaderboardEntry? entry;
  final Presence? presence;
  final int unread;

  @override
  State<_FriendRow> createState() => _FriendRowState();
}

class _FriendRowState extends State<_FriendRow> {
  bool _busy = false;

  /// تتفرج على لعبته وهي شغالة.
  Future<void> _watch() async {
    setState(() => _busy = true);
    try {
      final code = await Backend.instance.spectate(widget.uid);
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GameScreen(code: code, watching: widget.uid),
          ),
        );
      }
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _chat() {
    final e = widget.entry;
    if (e == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen.friend(friend: (uid: widget.uid, name: e.name, avatar: e.avatar, frame: e.frame)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final playing = e?.playing ?? false;
    final p = widget.presence;
    final online = playing || (p?.online ?? false);
    return _PlayerRow(
      uid: widget.uid,
      entry: e,
      playing: playing,
      online: online,
      status: online ? 'متصل' : (p?.lastSeen ?? 'غير متصل'),
      trailing: [
        if (playing)
          SizedBox(
            width: 104,
            child: GameButton(
              label: _busy ? 'لحظة…' : 'تفرّج',
              icon: const Gfx('eye', size: 20),
              tone: ButtonTone.purple,
              height: 40,
              fontSize: 14,
              onPressed: _busy ? null : _watch,
            ),
          ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              width: 96,
              child: GameButton(
                label: 'دردشة',
                icon: const Gfx('chat', size: 20),
                tone: widget.unread > 0 ? ButtonTone.gold : ButtonTone.ghost,
                height: 40,
                fontSize: 14,
                onPressed: e == null ? null : _chat,
              ),
            ),
            if (widget.unread > 0)
              PositionedDirectional(
                top: -6,
                end: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.traitor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.bg, width: 1.5),
                  ),
                  child: Text(
                    arabicNumber(widget.unread),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, height: 1.1),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RequestRow extends StatefulWidget {
  const _RequestRow({required this.uid});

  final String uid;

  @override
  State<_RequestRow> createState() => _RequestRowState();
}

class _RequestRowState extends State<_RequestRow> {
  late final Future<LeaderboardEntry?> _entry = Backend.instance.fetchPlayer(widget.uid).catchError((_) => null);
  bool _busy = false;

  Future<void> _respond(bool accept, String name) async {
    setState(() => _busy = true);
    try {
      await Backend.instance.friendRespond(widget.uid, accept);
      if (mounted && accept) _toast(context, 'صرت أنت و$name أصدقاء');
    } on BackendException catch (e) {
      if (mounted) _toast(context, e.message);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _entry,
    builder: (context, snap) {
      final name = snap.data?.name ?? 'لاعب';
      return _PlayerRow(
        uid: widget.uid,
        entry: snap.data,
        trailing: [
          SizedBox(
            width: 96,
            child: GameButton(
              label: 'قبول',
              tone: ButtonTone.green,
              height: 40,
              fontSize: 14,
              onPressed: _busy ? null : () => _respond(true, name),
            ),
          ),
          SizedBox(
            width: 84,
            child: GameButton(
              label: 'رفض',
              tone: ButtonTone.ghost,
              height: 40,
              fontSize: 14,
              onPressed: _busy ? null : () => _respond(false, name),
            ),
          ),
        ],
      );
    },
  );
}

void _toast(BuildContext context, String text) =>
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));

/// أضف صديق برمزه، وشارك رمزك.
class _AddFriend extends StatefulWidget {
  const _AddFriend();

  @override
  State<_AddFriend> createState() => _AddFriendState();
}

class _AddFriendState extends State<_AddFriend> {
  final _backend = Backend.instance;
  final _input = TextEditingController();
  LeaderboardEntry? _found;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final pid = cleanPidInput(_input.text);
    if (pid.length < 3) return setState(() => _error = 'اكتب رمز صديقك (أرقام)');
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _found = null;
    });
    try {
      final e = await _backend.findPlayer(pid);
      if (mounted) setState(() => _found = e);
    } on BackendException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(String pid) async {
    final text = 'ضيفني في «مجلس الخونة»! رمزي: $pid\nhttps://majlis-game-1d739.web.app';
    await launchUrl(
      Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _backend.profile,
      builder: (context, p, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Panel(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Gfx('idcard', size: 40),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'رمزك',
                        style: TextStyle(fontFamily: kufi, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const Text(
                        'أعطه لأصدقائك عشان يضيفونك (اضغطه وينسخ)',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: PidBadge(pid: p.pid, tier: p.pidTier, size: 17),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    SizedBox(
                      width: 150,
                      child: GameButton(
                        label: 'شارك رمزك',
                        icon: const Gfx('invite', size: 22),
                        tone: ButtonTone.green,
                        height: 40,
                        fontSize: 14,
                        onPressed: p.pid.isEmpty ? null : () => _share(p.pid),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 150,
                      child: GameButton(
                        label: 'رمز مميز',
                        icon: const Gfx('gem', size: 22),
                        tone: ButtonTone.purple,
                        height: 40,
                        fontSize: 14,
                        onPressed: () => showPremiumIds(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  maxLength: 8,
                  onSubmitted: (_) => _search(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: 'اكتب رمز صديقك',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: GameButton(
                  label: 'دوّر',
                  icon: const Gfx('search', size: 22),
                  height: 46,
                  fontSize: 15,
                  onPressed: _busy ? null : _search,
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.traitorLight, fontWeight: FontWeight.w700),
              ),
            ),
          if (_found case final e?) ...[
            const SizedBox(height: 10),
            _PlayerRow(
              uid: e.uid,
              entry: e,
              trailing: [FriendButton(uid: e.uid, name: e.name)],
            ),
          ],
        ],
      ),
    );
  }
}

/// من الروم: تدعو أصدقاءك (توصلهم الدعوة في اللعبة وبإشعار).
Future<void> showInviteFriends(BuildContext context, String code) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: AppColors.panel,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
  constraints: BoxConstraints(maxWidth: 620, maxHeight: MediaQuery.sizeOf(context).height * .9),
  builder: (context) => _InviteSheet(code: code),
);

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.code});

  final String code;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _sent = <String>{};
  final _busy = <String>{};

  Future<void> _invite(String uid) async {
    setState(() => _busy.add(uid));
    try {
      await Backend.instance.inviteFriend(uid, widget.code);
      if (mounted) setState(() => _sent.add(uid));
    } on BackendException catch (e) {
      if (mounted) _toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy.remove(uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = Backend.instance.profile.value.friends.reversed.toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ادعُ أصدقاءك',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: kufi, fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const Text(
              'توصلهم الدعوة في اللعبة وبإشعار، ويدخلون الروم بضغطة',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            if (friends.isEmpty)
              _Empty(
                icon: 'friends',
                text: 'ما عندك أصدقاء للحين',
                action: (
                  'أضف أصدقاء',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FriendsScreen(tab: FriendsScreen.addTab)),
                    );
                  },
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final uid in friends)
                      FutureBuilder(
                        future: Backend.instance.fetchPlayer(uid).catchError((_) => null),
                        builder: (context, snap) => _PlayerRow(
                          uid: uid,
                          entry: snap.data,
                          trailing: [
                            SizedBox(
                              width: 112,
                              child: GameButton(
                                label: _sent.contains(uid) ? 'انرسلت' : 'ادعُ',
                                icon: Gfx(_sent.contains(uid) ? 'check' : 'invite', size: 20),
                                tone: _sent.contains(uid) ? ButtonTone.ghost : ButtonTone.green,
                                height: 40,
                                fontSize: 14,
                                onPressed: _sent.contains(uid) || _busy.contains(uid) ? null : () => _invite(uid),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
