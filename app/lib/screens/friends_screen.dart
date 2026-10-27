import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/leaderboard.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/friend_button.dart';
import '../widgets/pid.dart';
import '../widgets/player_card.dart';
import '../widgets/ui.dart';
import 'game_screen.dart';

/// الأصدقاء: قائمتك، والطلبات اللي وصلتك، وتضيف أحد برمزه.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, this.tab = 0});

  /// ٠ أصدقائي، ١ الطلبات، ٢ أضف صديق.
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
          length: 3,
          initialIndex: widget.tab,
          child: NightScaffold(
            appBar: AppBar(
              title: const Row(children: [Gfx('friends', size: 30), SizedBox(width: 8), Text('الأصدقاء')]),
              bottom: TabBar(
                tabs: [
                  Tab(text: p.friends.isEmpty ? 'أصدقائي' : 'أصدقائي (${arabicNumber(p.friends.length)})'),
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
                        action: ('أضف صديق', () => DefaultTabController.of(context).animateTo(2)),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                        children: [for (final uid in p.friends.reversed) _FriendRow(uid: uid)],
                      ),
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
  const _PlayerRow({required this.uid, required this.entry, this.trailing = const [], this.playing = false});

  final String uid;
  final LeaderboardEntry? entry;
  final List<Widget> trailing;

  /// يلعب الحين (نقطة خضرا وسطر تحت اسمه).
  final bool playing;

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
                      PlayerAvatar(
                        avatar: e?.avatar ?? 'masked',
                        style: frameStyle(e?.frame),
                        size: 46,
                        animate: false,
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
                                playing ? 'يلعب الحين' : 'مستوى ${arabicNumber(e.level)}',
                                style: TextStyle(
                                  color: playing ? AppColors.green : AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: playing ? FontWeight.w800 : null,
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

class _FriendRow extends StatefulWidget {
  const _FriendRow({required this.uid});

  final String uid;

  @override
  State<_FriendRow> createState() => _FriendRowState();
}

class _FriendRowState extends State<_FriendRow> {
  late final Future<LeaderboardEntry?> _entry = Backend.instance.fetchPlayer(widget.uid).catchError((_) => null);
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

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _entry,
    builder: (context, snap) {
      final e = snap.data;
      return _PlayerRow(
        uid: widget.uid,
        entry: e,
        playing: e?.playing ?? false,
        trailing: [
          if (e?.playing ?? false)
            SizedBox(
              width: 110,
              child: GameButton(
                label: _busy ? 'لحظة…' : 'تفرّج',
                icon: const Gfx('eye', size: 20),
                tone: ButtonTone.purple,
                height: 40,
                fontSize: 14,
                onPressed: _busy ? null : _watch,
              ),
            ),
        ],
      );
    },
  );
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
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen(tab: 2)));
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
