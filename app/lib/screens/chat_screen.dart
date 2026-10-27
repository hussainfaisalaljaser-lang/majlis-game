import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat.dart';
import '../models/clan.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/clan_crest.dart';
import '../widgets/common.dart';
import '../widgets/player_card.dart';
import '../widgets/ui.dart';

/// آخر مرة فتحت دردشة الديوان (عشان نعلّم إن فيه رسائل جديدة).
Future<DateTime> clanChatSeen(String clanId) async {
  try {
    final ms = (await SharedPreferences.getInstance()).getInt('clan_chat_seen_$clanId');
    return DateTime.fromMillisecondsSinceEpoch(ms ?? 0);
  } catch (_) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

Future<void> _markClanChatSeen(String clanId) async {
  try {
    await (await SharedPreferences.getInstance()).setInt(
      'clan_chat_seen_$clanId',
      DateTime.now().millisecondsSinceEpoch,
    );
  } catch (_) {}
}

/// صاحبي اللي أراسله.
typedef ChatFriend = ({String uid, String name, String avatar, String? frame});

/// الدردشة: دردشة الديوان (لأعضائه) أو محادثة صاحب. الكلام السيء ينخفى في السيرفر قبل ما يوصل أحد،
/// والأحدث تحت. ضغطة مطوّلة على رسالة أحد: تبلّغ عنها أو تحظره.
class ChatScreen extends StatefulWidget {
  const ChatScreen.clan({super.key, required ClanTag this.clan}) : friend = null;

  const ChatScreen.friend({super.key, required ChatFriend this.friend}) : clan = null;

  final ClanTag? clan;
  final ChatFriend? friend;

  /// الصاحب اللي محادثته مفتوحة الحين (عشان ما نطلع إشعار عن رسايله).
  static String? openFriend;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _backend = Backend.instance;
  final _input = TextEditingController();
  final _focus = FocusNode();
  late final Stream<List<ChatMessage>> _messages = widget.clan != null
      ? _backend.watchClanChat(widget.clan!.id)
      : _backend.watchDm(widget.friend!.uid);
  StreamSubscription<List<ChatMessage>>? _seenSub;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // وأنا فاتحها: كل رسالة توصل تنحسب مقروءة.
    _seenSub = _messages.listen((_) => _markSeen());
    ChatScreen.openFriend = widget.friend?.uid;
  }

  void _markSeen() {
    if (widget.clan case final clan?) {
      _markClanChatSeen(clan.id);
    } else if ((_backend.profile.value.dmUnread[widget.friend!.uid] ?? 0) > 0) {
      _backend.readDm(widget.friend!.uid).ignore();
    }
  }

  @override
  void dispose() {
    if (ChatScreen.openFriend == widget.friend?.uid) ChatScreen.openFriend = null;
    _seenSub?.cancel();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _backend.sendChat(widget.clan != null ? 'clan' : widget.friend!.uid, text);
      _input.clear();
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
      _focus.requestFocus();
    }
  }

  /// ضغطة مطوّلة على رسالة أحد ثاني.
  Future<void> _options(ChatMessage m) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.panel,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: PlayerAvatar(avatar: m.avatar, size: 40, animate: false),
              title: Text(m.name),
              subtitle: Text(m.text, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            ListTile(
              leading: const Gfx('profile', size: 26),
              title: const Text('بطاقته'),
              onTap: () => Navigator.pop(context, 'card'),
            ),
            ListTile(
              leading: const Gfx('warning', size: 26),
              title: const Text('بلّغ عن الرسالة'),
              onTap: () => Navigator.pop(context, 'report'),
            ),
            ListTile(
              leading: const Gfx('cross', size: 26),
              title: const Text('احظره', style: TextStyle(color: AppColors.traitorLight)),
              subtitle: const Text('ما تشوف رسايله ولا ردوده'),
              onTap: () => Navigator.pop(context, 'block'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (action) {
        case 'card':
          showPlayerCard(context, uid: m.uid, name: m.name, avatar: m.avatar);
        case 'report':
          await _backend.reportPlayer(m.uid, 'chat', text: m.text);
          messenger.showSnackBar(const SnackBar(content: Text('وصلنا بلاغك، شكراً لك')));
        case 'block':
          await _backend.setBlocked(m.uid, true);
          messenger.showSnackBar(SnackBar(content: Text('حظرت ${m.name}')));
      }
    } on BackendException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final clan = widget.clan;
    final friend = widget.friend;
    return NightScaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (clan != null) ...[
              ClanCrest.of(clan, size: 34),
              const SizedBox(width: 8),
              Flexible(child: Text('دردشة ${clan.name}', overflow: TextOverflow.ellipsis)),
            ] else ...[
              PlayerAvatar(avatar: friend!.avatar, style: frameStyle(friend.frame), size: 34, animate: false),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(friend.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17)),
                    StreamBuilder<Presence>(
                      stream: _backend.watchPresence(friend.uid),
                      builder: (context, snap) {
                        final p = snap.data ?? const Presence();
                        return Text(
                          p.online ? 'متصل' : (p.lastSeen ?? 'غير متصل'),
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: p.online ? AppColors.green : AppColors.muted,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _backend.profile,
                builder: (context, me, _) => StreamBuilder<List<ChatMessage>>(
                  stream: _messages,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return const Center(
                        child: Text('ما قدرنا نفتح الدردشة', style: TextStyle(color: AppColors.muted)),
                      );
                    }
                    final list = snap.data;
                    if (list == null) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                    // اللي حظرتهم: ما تشوف رسايلهم.
                    final shown = [
                      for (final m in list)
                        if (!me.blocked.contains(m.uid)) m,
                    ];
                    if (shown.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Opacity(opacity: .8, child: Gfx('chat', size: 56)),
                            const SizedBox(height: 8),
                            Text(
                              clan != null ? 'ابدأ السوالف مع ربعك في الديوان' : 'ابدأ السوالف: قل السلام عليكم',
                              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      itemCount: shown.length,
                      itemBuilder: (context, i) {
                        final m = shown[i];
                        // رسائل ورا بعض من نفس الشخص (خلال ٣ دقايق): الاسم والصورة مرة وحدة.
                        final older = i + 1 < shown.length ? shown[i + 1] : null;
                        final grouped =
                            older != null &&
                            !older.system &&
                            older.uid == m.uid &&
                            m.at.difference(older.at) < const Duration(minutes: 3);
                        return _MessageRow(
                          message: m,
                          mine: m.uid == _backend.uid,
                          grouped: grouped,
                          onLongPress: m.system || m.uid == _backend.uid ? null : () => _options(m),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            _InputBar(controller: _input, focus: _focus, sending: _sending, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message, required this.mine, required this.grouped, this.onLongPress});

  final ChatMessage message;
  final bool mine;
  final bool grouped;
  final VoidCallback? onLongPress;

  static Color _roleColor(ClanRole? r) => switch (r) {
    ClanRole.owner => AppColors.gold,
    ClanRole.deputy => const Color(0xFFB9A4FF),
    ClanRole.elder => const Color(0xFF5EEAD4),
    _ => AppColors.text,
  };

  String get _time {
    final d = DateTime.now().difference(message.at);
    if (d.inHours < 24) {
      final t = TimeOfDay.fromDateTime(message.at);
      final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final min = '${t.minute < 10 ? '٠' : ''}${arabicNumber(t.minute)}';
      return '${arabicNumber(h)}:$min ${t.period == DayPeriod.am ? 'ص' : 'م'}';
    }
    return agoText(d);
  }

  @override
  Widget build(BuildContext context) {
    final m = message;
    if (m.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              m.text,
              style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }
    final bubble = GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 6),
        decoration: BoxDecoration(
          gradient: mine ? const LinearGradient(colors: [Color(0xFF6D4BD8), Color(0xFF4C2FA8)]) : null,
          color: mine ? null : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mine ? Colors.white.withValues(alpha: .18) : AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(m.text, style: const TextStyle(fontSize: 14.5, height: 1.45, fontWeight: FontWeight.w600)),
            const SizedBox(height: 1),
            Text(_time, style: TextStyle(fontSize: 9.5, color: Colors.white.withValues(alpha: .55))),
          ],
        ),
      ),
    );
    if (mine) {
      return Padding(
        padding: EdgeInsets.only(top: grouped ? 2 : 8),
        child: Align(alignment: AlignmentDirectional.centerEnd, child: bubble),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: grouped ? 2 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 38, child: grouped ? null : PlayerAvatar(avatar: m.avatar, size: 32, animate: false)),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!grouped)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.name,
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: _roleColor(m.role)),
                        ),
                        if (m.role != null && m.role != ClanRole.member) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _roleColor(m.role).withValues(alpha: .6)),
                            ),
                            child: Text(
                              m.role!.label,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _roleColor(m.role)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                bubble,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.focus, required this.sending, required this.onSend});

  final TextEditingController controller;
  final FocusNode focus;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .35),
      border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .08))),
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focus,
            maxLength: 200,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            decoration: const InputDecoration(
              hintText: 'اكتب رسالتك…',
              counterText: '',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 104,
          child: GameButton(
            label: sending ? '…' : 'أرسل',
            icon: const Gfx('chat', size: 20),
            height: 42,
            fontSize: 15,
            onPressed: sending ? null : onSend,
          ),
        ),
      ],
    ),
  );
}
