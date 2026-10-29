import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat.dart';
import '../models/clan.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/links.dart';
import '../theme.dart';
import '../widgets/bubble.dart';
import '../widgets/clan_crest.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/design_social.dart';
import '../widgets/game/reactions_sheet.dart';
import '../widgets/player_card.dart';

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

/// الدردشة كصفحة كاملة (تنفتح من الإشعارات): شريط الصفحة وتحته [ChatPanel].
class ChatScreen extends StatelessWidget {
  const ChatScreen.clan({super.key, required ClanTag this.clan}) : friend = null;

  const ChatScreen.friend({super.key, required ChatFriend this.friend}) : clan = null;

  final ClanTag? clan;
  final ChatFriend? friend;

  /// الصاحب اللي محادثته مفتوحة الحين (عشان ما نطلع إشعار عن رسايله).
  static String? openFriend;

  @override
  Widget build(BuildContext context) => SocScaffold(
    title: clan != null ? 'دردشة الديوان' : 'الدردشة',
    icon: clan != null ? ClanCrest.of(clan!, size: 30) : const Gfx('chat', size: 28),
    currency: false,
    body: Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
      child: clan != null ? ChatPanel.clan(clan: clan!) : ChatPanel.friend(friend: friend!),
    ),
  );
}

/// لوحة الدردشة: دردشة الديوان (لأعضائه) أو محادثة صاحب. الكلام السيء ينخفى في السيرفر قبل ما يوصل أحد،
/// والأحدث تحت. ضغطة مطوّلة على رسالة أحد: تبلّغ عنها أو تحظره.
/// تنحط جنب قائمة الأصدقاء أو ديوانك، ومعها ChatScreen لو انفتحت لحالها. غيّر [key] لو غيرت المحادثة.
class ChatPanel extends StatefulWidget {
  const ChatPanel.clan({super.key, required ClanTag this.clan}) : friend = null;

  const ChatPanel.friend({super.key, required ChatFriend this.friend}) : clan = null;

  final ClanTag? clan;
  final ChatFriend? friend;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _backend = Backend.instance;
  final _input = TextEditingController();
  final _focus = FocusNode();
  late final Stream<List<ChatMessage>> _messages = widget.clan != null
      ? _backend.watchClanChat(widget.clan!.id)
      : _backend.watchDm(widget.friend!.uid);
  StreamSubscription<List<ChatMessage>>? _seenSub;
  bool _sending = false;

  /// قلت «لاحقاً» لدعوة الروم اللي بالمحادثة.
  bool _inviteLater = false;

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

  /// الملصقات: من باقاتك (والمقفلة تطلع باهتة مع وين تنكسب)، وضغطة ترسله على طول.
  Future<void> _stickers() async {
    _focus.unfocus();
    final sticker = await showModalBottomSheet<Sticker>(
      context: context,
      backgroundColor: AppColors.panel,
      isScrollControlled: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .72),
      builder: (context) =>
          ReactionsSheet(profile: _backend.profile.value, onSticker: (s) => Navigator.pop(context, s)),
    );
    if (sticker == null || !mounted || _sending) return;
    setState(() => _sending = true);
    try {
      await _backend.sendSticker(widget.clan != null ? 'clan' : widget.friend!.uid, sticker.id);
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// ضغطة مطوّلة على رسالة أحد ثاني.
  Future<void> _options(ChatMessage m) async {
    final action = await showSocDialog<String>(
      context,
      title: m.name,
      width: 400,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SocAvatar(avatar: m.avatar, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  m.sticker != null ? 'ملصق' : m.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, color: socInk),
                ),
              ),
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
          const SizedBox(height: 8),
          SocButton(
            label: 'بلّغ عن الرسالة',
            tone: SocTone.orange,
            icon: const Gfx('warning', size: 22),
            height: 40,
            onPressed: () => Navigator.pop(context, 'report'),
          ),
          const SizedBox(height: 8),
          SocButton(
            label: 'احظره (ما تشوف رسايله ولا ردوده)',
            tone: SocTone.red,
            icon: const Gfx('cross', size: 22),
            height: 40,
            onPressed: () => Navigator.pop(context, 'block'),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (action) {
        case 'card':
          showPlayerCard(context, uid: m.uid, name: m.name, avatar: m.avatar);
        case 'report':
          await _backend.reportPlayer(m.uid, 'chat', text: m.sticker != null ? 'ملصق ${m.sticker}' : m.text);
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
    return ValueListenableBuilder(
      valueListenable: _backend.profile,
      builder: (context, me, _) => StreamBuilder<List<ChatMessage>>(
        stream: _messages,
        builder: (context, snap) {
          final list = snap.data;
          // اللي حظرتهم: ما تشوف رسايلهم.
          final shown = list == null
              ? null
              : [
                  for (final m in list)
                    if (!me.blocked.contains(m.uid)) m,
                ];
          return ChatPanelView(
            header: clan != null
                ? const SocDiamondTitle('دردشة الديوان')
                : ChatFriendHeader(friend: friend!, presence: _backend.watchPresence(friend.uid)),
            messages: shown,
            error: snap.hasError,
            myUid: _backend.uid,
            clan: clan != null,
            controller: _input,
            focus: _focus,
            sending: _sending,
            onSend: _send,
            onStickers: _stickers,
            onLongPress: _options,
            footer: friend == null || _inviteLater
                ? null
                : friendInviteCard(me, friend, onLater: () => setState(() => _inviteLater = true)),
          );
        },
      ),
    );
  }
}

/// رأس محادثة الصاحب: صورته واسمه وحالته على لوح خشب.
class ChatFriendHeader extends StatelessWidget {
  const ChatFriendHeader({super.key, required this.friend, required this.presence});

  final ChatFriend friend;
  final Stream<Presence> presence;

  @override
  Widget build(BuildContext context) => SocPlankRow(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
    child: Row(
      children: [
        SocAvatar(avatar: friend.avatar, style: frameStyle(friend.frame), size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedText(friend.name, size: 18, maxLines: 1, align: TextAlign.start),
              StreamBuilder<Presence>(
                stream: presence,
                builder: (context, snap) {
                  final p = snap.data ?? const Presence();
                  return Text(
                    p.online ? 'متصل' : (p.lastSeen ?? 'غير متصل'),
                    style: TextStyle(
                      fontFamily: kufi,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: p.online ? socGreenText : socMuted,
                      height: 1.1,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// شكل لوحة الدردشة: [header] فوق، والرسائل (الأحدث تحت)، وشريط الكتابة. [messages] null يعني لسه يحمّل.
/// ما تلمس السيرفر (تنشاف بالتصوير ببيانات تجريبية).
class ChatPanelView extends StatelessWidget {
  const ChatPanelView({
    super.key,
    required this.header,
    required this.messages,
    required this.myUid,
    required this.clan,
    required this.controller,
    required this.focus,
    required this.sending,
    required this.onSend,
    required this.onStickers,
    this.onLongPress,
    this.error = false,
    this.footer,
  });

  final Widget header;
  final List<ChatMessage>? messages;
  final String myUid;

  /// دردشة ديوان (فيها اسم المرسل وصورته) أو محادثة صاحب.
  final bool clan;
  final TextEditingController controller;
  final FocusNode focus;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onStickers;
  final ValueChanged<ChatMessage>? onLongPress;
  final bool error;

  /// شي يطلع تحت آخر رسالة (مثل دعوة الروم).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final list = messages;
    Widget body;
    if (error) {
      body = const Center(
        child: Text(
          'ما قدرنا نفتح الدردشة',
          style: TextStyle(color: socMuted, fontFamily: kufi, fontWeight: FontWeight.w700),
        ),
      );
    } else if (list == null) {
      body = const Center(child: CircularProgressIndicator(color: AppColors.gold));
    } else if (list.isEmpty && footer == null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Opacity(opacity: .8, child: Gfx('chat', size: 52)),
            const SizedBox(height: 8),
            Text(
              clan ? 'ابدأ السوالف مع ربعك في الديوان' : 'ابدأ السوالف: قل السلام عليكم',
              style: const TextStyle(color: socMuted, fontFamily: kufi, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    } else {
      final count = list.length + (footer == null ? 0 : 1);
      body = ListView.builder(
        reverse: true,
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 4),
        itemCount: count,
        itemBuilder: (context, i) {
          if (footer != null) {
            if (i == 0) return Padding(padding: const EdgeInsets.only(top: 8), child: footer);
            i--;
          }
          final m = list[i];
          // رسائل ورا بعض من نفس الشخص (خلال ٣ دقايق): الاسم والصورة مرة وحدة.
          final older = i + 1 < list.length ? list[i + 1] : null;
          final grouped =
              older != null &&
              !older.system &&
              older.uid == m.uid &&
              m.at.difference(older.at) < const Duration(minutes: 3);
          return ChatMessageRow(
            message: m,
            mine: m.uid == myUid,
            grouped: grouped,
            clan: clan,
            onLongPress: m.system || m.uid == myUid || onLongPress == null ? null : () => onLongPress!(m),
          );
        },
      );
    }
    return WoodPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 6),
          Expanded(child: body),
          const SizedBox(height: 8),
          SocChatInput(controller: controller, focus: focus, sending: sending, onSend: onSend, onStickers: onStickers),
        ],
      ),
    );
  }
}

/// سطر رسالة: فقاعة رق، ومعها صورة المرسل واسمه (بدردشة الديوان) أو بدونها (محادثة صاحب).
class ChatMessageRow extends StatelessWidget {
  const ChatMessageRow({
    super.key,
    required this.message,
    required this.mine,
    required this.grouped,
    required this.clan,
    this.onLongPress,
  });

  final ChatMessage message;
  final bool mine;
  final bool grouped;
  final bool clan;
  final VoidCallback? onLongPress;

  /// لون الاسم على الرق (الشيخ أحمر، والنائب بنفسجي، والوجيه أخضر، والعضو أزرق).
  static Color roleColor(ClanRole? r) => switch (r) {
    ClanRole.owner => const Color(0xFFB3261E),
    ClanRole.deputy => const Color(0xFF7B3FA8),
    ClanRole.elder => const Color(0xFF1E8A74),
    _ => const Color(0xFF2F6BB8),
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
              color: Colors.black.withValues(alpha: .35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              m.text,
              style: const TextStyle(color: socMuted, fontSize: 12, fontFamily: kufi, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }
    final sticker = m.sticker == null ? null : stickerById(m.sticker!);
    final showName = clan && !mine && !grouped;
    final time = Text(
      _time,
      style: TextStyle(
        fontSize: 9.5,
        fontFamily: kufi,
        fontWeight: FontWeight.w700,
        color: socInk.withValues(alpha: .5),
        height: 1,
      ),
    );
    final bubble = GestureDetector(
      onLongPress: onLongPress,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: SocBubble(
          mine: mine,
          tail: !grouped,
          padding: EdgeInsets.fromLTRB(12, sticker != null ? 5 : 6, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showName)
                Text(
                  m.name,
                  style: TextStyle(
                    fontFamily: kufi,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: roleColor(m.role),
                    height: 1.2,
                  ),
                ),
              if (sticker != null)
                StickerView(sticker: sticker, size: 84, pop: false)
              else
                Text(
                  m.text,
                  style: const TextStyle(
                    fontFamily: kufi,
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                    height: 1.35,
                    color: socInk,
                  ),
                ),
              const SizedBox(height: 1),
              time,
            ],
          ),
        ),
      ),
    );
    final pad = EdgeInsets.only(top: grouped ? 3 : 9);
    if (mine || !clan) {
      return Padding(
        padding: pad,
        child: Align(alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart, child: bubble),
      );
    }
    return Padding(
      padding: pad,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 54, child: grouped ? null : SocAvatar(avatar: m.avatar, size: 38)),
          const SizedBox(width: 4),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

/// بطاقة «روم خاص من فلان» داخل محادثته: ادخل، أو لاحقاً.
class ChatInviteCard extends StatelessWidget {
  const ChatInviteCard({
    super.key,
    required this.name,
    required this.avatar,
    required this.note,
    required this.onJoin,
    required this.onLater,
  });

  final String name;
  final String avatar;
  final String note;
  final VoidCallback onJoin;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 250),
      child: VelvetPanel(
        radius: 12,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoldTitle('روم خاص من $name', size: 18, align: TextAlign.start),
                      Text(
                        note,
                        style: const TextStyle(
                          color: socCream,
                          fontFamily: kufi,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SocAvatar(avatar: avatar, size: 34),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: SocButton(label: 'ادخل', tone: SocTone.green, height: 34, fontSize: 15, onPressed: onJoin),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SocButton(label: 'لاحقاً', tone: SocTone.grey, height: 34, fontSize: 15, onPressed: onLater),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// فيه دعوة روم من هالصاحب (آخر دقيقتين)؟ تطلع بطاقتها تحت محادثته.
Widget? friendInviteCard(Profile p, ChatFriend friend, {required VoidCallback onLater}) {
  final inv = p.invite;
  if (inv == null || inv.from != friend.uid || DateTime.now().difference(inv.at) > const Duration(minutes: 2)) {
    return null;
  }
  if (inv.code == Links.seenInvite) return null;
  return ChatInviteCard(
    name: friend.name,
    avatar: friend.avatar,
    note: 'يبيك تلعب معه في الروم',
    onJoin: () => Links.joinInvite(inv.code),
    onLater: onLater,
  );
}
