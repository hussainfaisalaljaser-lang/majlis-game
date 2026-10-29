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
import '../widgets/curtain_route.dart';
import '../widgets/design.dart';
import '../widgets/design_social.dart';
import '../widgets/friend_button.dart';
import '../widgets/pid.dart';
import '../widgets/player_card.dart';
import 'chat_screen.dart';
import 'game_screen.dart';
import 'waiting_screen.dart';

/// الأصدقاء: قائمتك، ومحادثاتك، والطلبات اللي وصلتك، وتضيف أحد برمزه. المحادثة تنفتح جنب القائمة.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, this.tab = friendsTab});

  /// يفتح على اللي يهمك: طلبات صداقة، أو رسائل ما قريتها، أو أصدقائك.
  FriendsScreen.forProfile(Profile p, {super.key})
    : tab = p.friendReqs.isNotEmpty
          ? requestsTab
          : p.unreadDms > 0
          ? chatsTab
          : friendsTab;

  /// [addTab]: يفتح نافذة «أضف صديق بالكود» على طول.
  static const friendsTab = 0, chatsTab = 1, requestsTab = 2, addTab = 3;

  final int tab;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

/// المحادثة المفتوحة جنب القائمة: صاحب، أو الديوان.
typedef _OpenChat = ({ChatFriend? friend, ClanTag? clan});

class _FriendsScreenState extends State<FriendsScreen> {
  final _backend = Backend.instance;
  late int _tab = widget.tab == FriendsScreen.addTab ? FriendsScreen.friendsTab : widget.tab;
  _OpenChat? _open;

  @override
  void initState() {
    super.initState();
    if (widget.tab == FriendsScreen.addTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showAddFriend(context);
      });
    }
  }

  void _openFriend(String uid, LeaderboardEntry? e) {
    if (e == null) return;
    setState(() => _open = (friend: (uid: uid, name: e.name, avatar: e.avatar, frame: e.frame), clan: null));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _backend.profile,
      builder: (context, p, _) {
        final reqs = p.friendReqs.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final open = _open;
        final selected = open?.friend?.uid;
        return SocScaffold(
          title: 'الأصدقاء',
          icon: SocAvatar(avatar: p.avatar, style: frameStyle(p.frame), size: 26),
          body: SocTwoPanels(
            main: FriendsPanelView(
              tab: _tab,
              onTab: (t) => setState(() => _tab = t),
              chatsBadge: p.unreadDms,
              requestsBadge: reqs.length,
              onAdd: () => showAddFriend(context),
              child: switch (_tab) {
                FriendsScreen.chatsTab => _ChatsList(
                  profile: p,
                  selected: open?.clan != null ? 'clan' : selected,
                  onFriend: _openFriend,
                  onClan: (tag) => setState(() => _open = (friend: null, clan: tag)),
                ),
                FriendsScreen.requestsTab =>
                  reqs.isEmpty
                      ? const FriendsEmpty(icon: 'addfriend', text: 'لا توجد طلبات صداقة')
                      : ListView(
                          padding: const EdgeInsets.only(top: 6),
                          children: [for (final r in reqs) _RequestRow(uid: r.key)],
                        ),
                _ =>
                  p.friends.isEmpty
                      ? FriendsEmpty(
                          icon: 'friends',
                          text: 'ليس لديك أصدقاء حتى الآن.\nضيفهم برمزهم من «أضف صديق بالرمز»، أو من بطاقة أي لاعب في الطاولة.',
                        )
                      : _FriendsList(uids: p.friends, unread: p.dmUnread, selected: selected, onOpen: _openFriend),
              },
            ),
            side: switch (open) {
              (friend: final f?, clan: _) => ChatPanel.friend(key: ValueKey('dm_${f.uid}'), friend: f),
              (friend: _, clan: final c?) => ChatPanel.clan(key: ValueKey('clan_${c.id}'), clan: c),
              _ => const ChatPlaceholder(),
            },
          ),
        );
      },
    );
  }
}

/// مكان المحادثة لما ما فيه محادثة مفتوحة.
class ChatPlaceholder extends StatelessWidget {
  const ChatPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const WoodPanel(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(opacity: .75, child: Gfx('chat', size: 64)),
          SizedBox(height: 10),
          Text(
            'اختر صاحب من القائمة وسولف معه',
            style: TextStyle(color: socMuted, fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    ),
  );
}

/// لوحة الأصدقاء (مخمل): تبويبات، والمحتوى، وزر «أضف صديق بالكود» تحت (في تبويب الأصدقاء).
/// ما تلمس السيرفر (تنشاف بالتصوير ببيانات تجريبية).
class FriendsPanelView extends StatelessWidget {
  const FriendsPanelView({
    super.key,
    required this.tab,
    required this.onTab,
    required this.chatsBadge,
    required this.requestsBadge,
    required this.onAdd,
    required this.child,
  });

  final int tab;
  final ValueChanged<int> onTab;
  final int chatsBadge;
  final int requestsBadge;
  final VoidCallback onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) => VelvetPanel(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: LayoutBuilder(
            builder: (context, box) {
              // التبويبات بعرض ثابت (١٢٠) وتضيق لو الشاشة صغيرة.
              final w = ((box.maxWidth - 16) / 3).clamp(60.0, 120.0);
              return Row(
                children: [
                  SizedBox(
                    width: w,
                    child: SocTabPill(
                      label: 'الأصدقاء',
                      selected: tab == FriendsScreen.friendsTab,
                      onTap: () => onTab(FriendsScreen.friendsTab),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: w,
                    child: SocTabPill(
                      label: 'الدردشات',
                      selected: tab == FriendsScreen.chatsTab,
                      badge: chatsBadge,
                      onTap: () => onTab(FriendsScreen.chatsTab),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: w,
                    child: SocTabPill(
                      label: 'الطلبات',
                      selected: tab == FriendsScreen.requestsTab,
                      badge: requestsBadge,
                      onTap: () => onTab(FriendsScreen.requestsTab),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: child),
        if (tab == FriendsScreen.friendsTab) ...[
          const SizedBox(height: 6),
          Center(
            child: SocButton(
              label: 'أضف صديق بالرمز',
              tone: SocTone.orange,
              height: 46,
              fontSize: 21,
              width: 250,
              semantics: 'أضف صديق بالرمز',
              onPressed: onAdd,
            ),
          ),
        ],
      ],
    ),
  );
}

class FriendsEmpty extends StatelessWidget {
  const FriendsEmpty({super.key, required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(opacity: .8, child: Gfx(icon, size: 56)),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: socMuted,
            height: 1.6,
            fontFamily: kufi,
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
      ],
    ),
  );
}

/// سطر صاحب: صورته بنقطة حالة، واسمه وحالته، والأزرار على الطرف. [selected] المحادثة المفتوحة (حد ذهبي).
class FriendRowView extends StatelessWidget {
  const FriendRowView({
    super.key,
    required this.name,
    required this.avatar,
    required this.status,
    required this.dot,
    this.statusColor = socMuted,
    this.style,
    this.unread = 0,
    this.selected = false,
    this.trailing = const [],
    this.onTap,
    this.onAvatar,
  });

  final String name;
  final String avatar;
  final FrameStyle? style;
  final String status;
  final Color statusColor;

  /// نقطة الحالة على الصورة (null: بدون).
  final Color? dot;
  final int unread;
  final bool selected;
  final List<Widget> trailing;
  final VoidCallback? onTap;
  final VoidCallback? onAvatar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: SocPlankRow(
      selected: selected,
      onTap: onTap,
      semantics: 'محادثة $name',
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAvatar,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SocAvatar(avatar: avatar, style: style, size: 42, dot: dot),
                if (unread > 0) PositionedDirectional(top: -4, start: -4, child: SocBadge(unread, size: 18)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedText(name, size: 19, maxLines: 1, align: TextAlign.start),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kufi,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: statusColor,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          for (final t in trailing) Padding(padding: const EdgeInsetsDirectional.only(start: 8), child: t),
        ],
      ),
    ),
  );
}

/// أصحابي: المتصلين أول (واللي يلعبون بعدهم)، وبعدين غير المتصلين من آخر ظهور. الحالة تتحدث مباشرة.
class _FriendsList extends StatefulWidget {
  const _FriendsList({required this.uids, required this.unread, required this.selected, required this.onOpen});

  final List<String> uids;

  /// رسائل ما قريتها من كل صاحب.
  final Map<String, int> unread;
  final String? selected;
  final void Function(String uid, LeaderboardEntry? e) onOpen;

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
    return ListView(
      padding: const EdgeInsets.only(top: 6),
      children: [
        for (final uid in sorted)
          _FriendRow(
            key: ValueKey(uid),
            uid: uid,
            entry: _entries[uid],
            presence: _presence[uid],
            unread: widget.unread[uid] ?? 0,
            selected: widget.selected == uid,
            onOpen: () => widget.onOpen(uid, _entries[uid]),
          ),
      ],
    );
  }
}

class _FriendRow extends StatefulWidget {
  const _FriendRow({
    super.key,
    required this.uid,
    required this.entry,
    required this.presence,
    required this.unread,
    required this.selected,
    required this.onOpen,
  });

  final String uid;
  final LeaderboardEntry? entry;
  final Presence? presence;
  final int unread;
  final bool selected;
  final VoidCallback onOpen;

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
        await Navigator.of(context).push(curtainRoute<void>((_) => GameScreen(code: code, watching: widget.uid)));
      }
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// ندعوه لروم خاص جديد (٥ لاعبين، الكلاسيكي): نسوي الروم ونرسل له الدعوة وندخل غرفة الانتظار.
  Future<void> _invite() async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code = await Backend.instance.createRoom(maxPlayers: 5);
      await Backend.instance.inviteFriend(widget.uid, code);
      navigator.push(MaterialPageRoute(builder: (_) => WaitingScreen(tier: null, playerCount: 5, code: code)));
    } on BackendException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final playing = e?.playing ?? false;
    final p = widget.presence;
    final online = playing || (p?.online ?? false);
    final (status, color) = playing
        ? ('يلعب الآن', socOrangeText)
        : online
        ? ('متصل الآن', socGreenText)
        : (p?.at == null ? 'غير متصل' : agoText(DateTime.now().difference(p!.at!)), socMuted);
    return FriendRowView(
      name: e?.name ?? '…',
      avatar: e?.avatar ?? 'masked',
      style: frameStyle(e?.frame),
      status: status,
      statusColor: color,
      dot: playing
          ? SocDot.playing
          : online
          ? SocDot.online
          : SocDot.offline,
      unread: widget.unread,
      selected: widget.selected,
      onTap: e == null ? null : widget.onOpen,
      onAvatar: e == null
          ? null
          : () => showPlayerCard(context, uid: widget.uid, name: e.name, avatar: e.avatar, frame: e.frame),
      trailing: [
        if (playing)
          SocButton(
            label: _busy ? 'لحظة…' : 'تفرّج',
            tone: SocTone.blue,
            height: 36,
            fontSize: 17,
            width: 86,
            onPressed: _busy ? null : _watch,
          )
        else if (online)
          SocButton(
            label: _busy ? 'لحظة…' : 'ادعُ',
            tone: SocTone.green,
            height: 36,
            fontSize: 17,
            width: 86,
            onPressed: _busy || !Backend.instance.isReady ? null : _invite,
          ),
      ],
    );
  }
}

/// محادثاتك: دردشة ديوانك (لو أنت في ديوان)، ومحادثاتك مع أصحابك (الأحدث فوق)، وكل وحدة فيها آخر رسالة
/// ومتى، وكم رسالة ما قريتها.
class _ChatsList extends StatefulWidget {
  const _ChatsList({required this.profile, required this.selected, required this.onFriend, required this.onClan});

  final Profile profile;

  /// المفتوحة الحين: uid الصاحب أو 'clan'.
  final String? selected;
  final void Function(String uid, LeaderboardEntry? e) onFriend;
  final ValueChanged<ClanTag> onClan;

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
      return const FriendsEmpty(
        icon: 'chat',
        text: 'لا يوجد محادثات حتى الآن.\nابدأ دردشة مع أي صاحب من «الأصدقاء»، أو ادخل ديوان وسولف مع ربعك.',
      );
    }
    return ListView(
      padding: const EdgeInsets.only(top: 6),
      children: [
        if (p.clan case final clan?)
          _ClanChatRow(clan: clan, selected: widget.selected == 'clan', onTap: () => widget.onClan(clan)),
        for (final uid in uids)
          _ChatRow(
            key: ValueKey(uid),
            uid: uid,
            entry: _entries[uid],
            last: p.dmLast[uid],
            unread: p.dmUnread[uid] ?? 0,
            me: Backend.instance.uid,
            selected: widget.selected == uid,
            onTap: () => widget.onFriend(uid, _entries[uid]),
          ),
      ],
    );
  }
}

/// سطر محادثة: الصورة والاسم، وآخر رسالة ومتى، وعدد اللي ما قريته.
class ChatTileView extends StatelessWidget {
  const ChatTileView({
    super.key,
    required this.leading,
    required this.title,
    required this.preview,
    required this.onTap,
    this.previewSticker,
    this.at,
    this.unread = 0,
    this.fresh = false,
    this.selected = false,
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
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hot = unread > 0 || fresh;
    final sticker = previewSticker == null ? null : stickerById(previewSticker!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SocPlankRow(
        selected: selected,
        onTap: onTap,
        semantics: 'محادثة $title',
        padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedText(title, size: 18, maxLines: 1, align: TextAlign.start),
                  Row(
                    children: [
                      if (sticker != null) ...[
                        Image.asset(sticker.asset, width: 20, height: 20, filterQuality: FilterQuality.medium),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hot ? socCream : socMuted,
                            fontFamily: kufi,
                            fontWeight: hot ? FontWeight.w800 : FontWeight.w700,
                            fontSize: 13.5,
                            height: 1.2,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                if (at != null)
                  Text(
                    agoText(DateTime.now().difference(at!)),
                    style: TextStyle(
                      color: hot ? socGoldHi : socMuted,
                      fontSize: 12,
                      fontFamily: kufi,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (unread > 0)
                  Padding(padding: const EdgeInsets.only(top: 3), child: SocBadge(unread, size: 20))
                else if (fresh)
                  const Padding(padding: EdgeInsets.only(top: 3), child: SocBadge(0, size: 12)),
              ],
            ),
          ],
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
  const _ClanChatRow({required this.clan, required this.selected, required this.onTap});

  final ClanTag clan;
  final bool selected;
  final VoidCallback onTap;

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
    if (old.selected && !widget.selected) _loadSeen();
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
      return ChatTileView(
        leading: ClanCrest.of(widget.clan, size: 44),
        title: 'ديوان ${widget.clan.name}',
        preview: m == null
            ? 'دردشة ربعك في الديوان'
            : m.system
            ? m.text
            : _previewOf(text: m.text, sticker: m.sticker, mine: m.uid == Backend.instance.uid, name: m.name),
        previewSticker: m?.sticker,
        at: m?.at,
        selected: widget.selected,
        fresh: !widget.selected && m != null && _seen != null && m.at.isAfter(_seen!) && m.uid != Backend.instance.uid,
        onTap: widget.onTap,
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
    required this.selected,
    required this.onTap,
  });

  final String uid;
  final LeaderboardEntry? entry;
  final ChatLast? last;
  final int unread;
  final String me;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final l = last;
    return ChatTileView(
      leading: SocAvatar(avatar: e?.avatar ?? 'masked', style: frameStyle(e?.frame), size: 40),
      title: e?.name ?? '…',
      preview: l == null ? 'رسائل جديدة' : _previewOf(text: l.text, sticker: l.sticker, mine: l.from == me),
      previewSticker: l?.sticker,
      at: l?.at,
      unread: selected ? 0 : unread,
      selected: selected,
      onTap: e == null ? null : onTap,
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
      final e = snap.data;
      final name = e?.name ?? 'لاعب';
      return FriendRowView(
        name: e?.name ?? '…',
        avatar: e?.avatar ?? 'masked',
        style: frameStyle(e?.frame),
        status: e == null ? '' : 'يريد أن يصير صديقك · مستوى ${arabicNumber(e.level)}',
        dot: null,
        onAvatar: e == null
            ? null
            : () => showPlayerCard(context, uid: widget.uid, name: e.name, avatar: e.avatar, frame: e.frame),
        trailing: [
          SocButton(
            label: 'قبول',
            tone: SocTone.green,
            height: 36,
            fontSize: 16,
            width: 80,
            onPressed: _busy ? null : () => _respond(true, name),
          ),
          SocButton(
            label: 'رفض',
            tone: SocTone.grey,
            height: 36,
            fontSize: 16,
            width: 70,
            onPressed: _busy ? null : () => _respond(false, name),
          ),
        ],
      );
    },
  );
}

void _toast(BuildContext context, String text) =>
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));

/// أضف صديق برمزه، وشارك رمزك (نافذة).
Future<void> showAddFriend(BuildContext context) =>
    showSocDialog<void>(context, title: 'أضف صديق بالرمز', width: 520, builder: (_) => const _AddFriend());

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
      builder: (context, p, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Gfx('idcard', size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'رمزك',
                      style: TextStyle(
                        fontFamily: kufi,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: socInk,
                        height: 1.2,
                      ),
                    ),
                    const Text(
                      'أعطه لأصدقائك عشان يضيفونك (اضغطه وينسخ)',
                      style: TextStyle(
                        color: Color(0xFF7A5A3A),
                        fontSize: 12.5,
                        fontFamily: kufi,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    PidBadge(pid: p.pid, tier: p.pidTier, size: 17),
                  ],
                ),
              ),
              Column(
                children: [
                  SocButton(
                    label: 'شارك رمزك',
                    tone: SocTone.green,
                    icon: const Gfx('invite', size: 22),
                    height: 38,
                    fontSize: 14.5,
                    width: 150,
                    onPressed: p.pid.isEmpty ? null : () => _share(p.pid),
                  ),
                  const SizedBox(height: 4),
                  SocButton(
                    label: 'رمز مميز',
                    tone: SocTone.blue,
                    icon: const Gfx('gem', size: 22),
                    height: 38,
                    fontSize: 14.5,
                    width: 150,
                    onPressed: () => showPremiumIds(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 2, color: socInk),
                  decoration: socParchInput(hint: 'اكتب رمز صديقك', dense: false),
                ),
              ),
              const SizedBox(width: 10),
              SocButton(
                label: 'دوّر',
                tone: SocTone.orange,
                icon: const Gfx('search', size: 22),
                height: 46,
                fontSize: 17,
                width: 110,
                onPressed: _busy ? null : _search,
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB3261E), fontWeight: FontWeight.w800, fontFamily: kufi),
              ),
            ),
          if (_found case final e?)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  SocAvatar(avatar: e.avatar, style: frameStyle(e.frame), size: 42),
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
                            fontSize: 17,
                            color: socInk,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          'مستوى ${arabicNumber(e.level)}',
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
                  FriendButton(uid: e.uid, name: e.name),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SocButton(
            label: 'تمام',
            tone: SocTone.grey,
            height: 42,
            fontSize: 16,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

/// من الروم: تدعو أصدقاءك (توصلهم الدعوة في اللعبة وبإشعار).
Future<void> showInviteFriends(BuildContext context, String code) => showSocDialog<void>(
  context,
  title: 'ادعُ أصدقاءك',
  width: 520,
  builder: (_) => _InviteSheet(code: code),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SocPopupText('توصلهم الدعوة في اللعبة وبإشعار، ويدخلون الطاولة بضغطة', size: 13.5, muted: true),
        const SizedBox(height: 8),
        if (friends.isEmpty) ...[
          const SocPopupText('ليس لديك أصدقاء حتى الآن'),
          const SizedBox(height: 10),
          SocButton(
            label: 'أضف أصدقاء',
            tone: SocTone.orange,
            height: 44,
            fontSize: 17,
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FriendsScreen(tab: FriendsScreen.addTab)),
              );
            },
          ),
        ] else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final uid in friends)
                  FutureBuilder(
                    future: Backend.instance.fetchPlayer(uid).catchError((_) => null),
                    builder: (context, snap) {
                      final e = snap.data;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: e == null
                                  ? null
                                  : () => showPlayerCard(
                                      context,
                                      uid: uid,
                                      name: e.name,
                                      avatar: e.avatar,
                                      frame: e.frame,
                                    ),
                              child: SocAvatar(avatar: e?.avatar ?? 'masked', style: frameStyle(e?.frame), size: 40),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                e?.name ?? '…',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: kufi,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: socInk,
                                ),
                              ),
                            ),
                            SocButton(
                              label: _sent.contains(uid) ? 'انرسلت' : 'ادعُ',
                              icon: Gfx(_sent.contains(uid) ? 'check' : 'invite', size: 20),
                              tone: _sent.contains(uid) ? SocTone.grey : SocTone.green,
                              height: 36,
                              fontSize: 15,
                              width: 112,
                              onPressed: _sent.contains(uid) || _busy.contains(uid) ? null : () => _invite(uid),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        SocButton(label: 'تمام', tone: SocTone.grey, height: 42, fontSize: 16, onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
