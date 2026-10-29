import 'dart:async';

import 'package:flutter/material.dart';

import '../models/events.dart';
import '../models/room.dart';
import '../models/shop.dart';
import '../models/table_tier.dart';
import '../models/tour.dart';
import '../services/backend.dart';
import '../services/links.dart';
import '../services/telemetry.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/curtain_route.dart';
import '../widgets/design.dart';
import '../widgets/design_social.dart';
import '../widgets/majlis.dart';
import '../widgets/mode_theme.dart';
import '../widgets/player_card.dart';
import '../widgets/venues.dart';
import 'friends_screen.dart';
import 'game_screen.dart';

/// غرفة الانتظار: المقاعد تتعبى لين تكتمل الطاولة.
///
/// لو فيه [code] تتابع الروم الحقيقي من السيرفر. بدونه (مثل نسخة الويب حالياً)
/// تشتغل بلاعبين وهميين للعرض.
class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key, required this.tier, required this.playerCount, this.code});

  final TableTier? tier;
  final int playerCount;
  final String? code;

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  static const _demoPlayers = [
    ('pearl', 'نورة'),
    ('desert', 'خالد'),
    ('cool', 'سعد'),
    ('sheikh', 'عمر'),
    ('rose', 'ريم'),
    ('youth', 'فهد'),
    ('jasmine', 'سارة'),
    ('merchant', 'ناصر'),
    ('sky', 'هيا'),
  ];

  final _demoJoined = [const RoomPlayer(uid: 'me', name: 'أنت', avatar: 'falcon')];
  StreamSubscription<Room?>? _sub;
  Timer? _timer;
  Room? _room;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    final code = widget.code;
    if (code == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
        if (_demoJoined.length >= widget.playerCount) return _timer?.cancel();
        final (avatar, name) = _demoPlayers[_demoJoined.length - 1];
        setState(() => _demoJoined.add(RoomPlayer(uid: name, name: name, avatar: avatar)));
      });
      return;
    }
    _sub = Backend.instance.watchRoom(code).listen((room) {
      if (!mounted) return;
      if (room?.status == RoomStatus.playing) {
        _sub?.cancel();
        Navigator.of(context).pushReplacement(curtainRoute<void>((_) => GameScreen(code: code)));
        return;
      }
      setState(() => _room = room);
    }, onError: (Object e) => debugPrint('room listener: $e'));
    // الطاولة العامة: لو ما اكتملت بعد شوي، نكملها بالبوتات.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      final room = _room;
      final created = room?.createdAt;
      if (room == null || room.isPrivate || created == null || _botsRequested) return;
      if (DateTime.now().isAfter(created.add(Room.botFillAfter))) {
        _botsRequested = true;
        Backend.instance.addBots(code).catchError((_) => _botsRequested = false);
      }
    });
  }

  bool _botsRequested = false;
  bool _addingBot = false;

  Future<void> _addBot() async {
    setState(() => _addingBot = true);
    try {
      await Backend.instance.addBots(widget.code!);
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _addingBot = false);
    }
  }

  Future<void> _removeBot(RoomPlayer bot) async {
    final ok = await socConfirm(context, title: 'تشيل البوت ${bot.name}؟', yes: 'شيله', danger: true);
    if (ok) await Backend.instance.removeBot(widget.code!, bot.uid).catchError((_) {});
  }

  /// كم ثانية باقية قبل ما نكمل الطاولة العامة بالبوتات.
  int? get _botCountdown {
    final created = _room?.createdAt;
    if (_room == null || _room!.isPrivate || created == null) return null;
    final left = created.add(Room.botFillAfter).difference(DateTime.now()).inSeconds;
    return left > 0 ? left : 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _leave() async {
    final code = widget.code;
    Navigator.of(context).pop();
    if (code != null) await Backend.instance.leaveRoom(code);
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await Backend.instance.startGame(widget.code!);
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = widget.code != null;
    final players = online ? (_room?.players ?? const <RoomPlayer>[]) : _demoJoined;
    final max = _room?.maxPlayers ?? widget.playerCount;
    final isPrivate = _room?.isPrivate ?? false;
    final isHost = online && _room?.hostId == Backend.instance.uid;
    final full = players.length >= max;
    final tier = widget.tier;
    final myUid = online ? Backend.instance.uid : 'me';
    final fee = _room?.entryFee ?? tier?.entryFee ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => didPop ? null : _leave(),
      child: SocScaffold(
        // كل طاولة لها مكانها: تشوفه من غرفة الانتظار.
        background: _room?.tour != null
            ? const MajlisRoom(venue: Venue.kings)
            : tier == null
            ? null
            : MajlisRoom(venue: venueOf(tier.id)),
        shade: .45,
        currency: false,
        onBack: _leave,
        icon: Gfx(_room?.tour != null ? 'trophy' : (tier == null ? 'key' : tier.icon), size: 30),
        title: _room?.tour != null
            ? 'بطولة الأسبوع · ${tourStageNames[_room!.tour!]}'
            : (tier == null ? 'طاولة خاصة' : 'طاولة ${tier.name}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_room?.quick ?? false) ...[const SocChip('سريع', kind: SocChipKind.orange), const SizedBox(width: 8)],
            // الطور (الكلاسيكي أو المطوّر) بثيمه.
            if (_room case final room?) ModeChip(mode: ModeTheme.of(room.roles)),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // المعلومات والأزرار
              SizedBox(
                width: 310,
                child: VelvetPanel(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isPrivate
                              ? 'اعزم أصحابك بالرمز'
                              : full
                              ? 'اكتملت الطاولة! اللعبة بتبدأ…'
                              : 'نبحث عن لاعبين…',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: socCream,
                            fontSize: 15,
                            fontFamily: kufi,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _CodeBox(code: widget.code ?? 'K7Q2M'),
                        if (widget.code != null) ...[
                          const SizedBox(height: 8),
                          _Invite(code: widget.code!, private: isPrivate),
                        ],
                        const SizedBox(height: 10),
                        SocBar(value: players.length / max, rope: false, height: 11),
                        const SizedBox(height: 4),
                        Text(
                          isPrivate
                              ? '${arabicNumber(players.length)} من ${arabicNumber(max)}، يحتاج ٥ لاعبين على الأقل'
                              : _botCountdown != null && _botCountdown! > 0
                              ? '${arabicNumber(players.length)} من ${arabicNumber(max)}، لو ما اكتملت خلال ${arabicNumber(_botCountdown!)} ثانية نكمّلها ببوتات'
                              : '${arabicNumber(players.length)} من ${arabicNumber(max)}، تبدأ تلقائياً لما تكتمل',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: socMuted,
                            fontSize: 12.5,
                            fontFamily: kufi,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (fee > 0) ...[
                          _PotBox(
                            pot:
                                (_room?.entryFee ?? tier!.entryFee) *
                                (players.any((p) => p.bot) ? players.where((p) => !p.bot).length : max),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (isPrivate && isHost) ...[
                          Row(
                            children: [
                              Expanded(
                                child: SocButton(
                                  label: 'أضف بوت',
                                  icon: const Gfx('bot', size: 24),
                                  tone: SocTone.blue,
                                  height: 44,
                                  fontSize: 16,
                                  padding: 8,
                                  onPressed: full || _addingBot ? null : _addBot,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SocButton(
                                  label: _starting ? 'لحظة…' : 'ابدأ',
                                  semantics: 'ابدأ',
                                  tone: SocTone.orange,
                                  height: 44,
                                  fontSize: 17,
                                  onPressed: players.length >= 5 && !_starting ? _start : null,
                                ),
                              ),
                            ],
                          ),
                          if (players.any((p) => p.bot))
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'اضغط على البوت عشان تشيله',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: socMuted,
                                  fontSize: 12.5,
                                  fontFamily: kufi,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                        ],
                        SocButton(
                          label: 'خروج',
                          icon: const Gfx('exit', size: 24),
                          semantics: 'خروج',
                          tone: SocTone.red,
                          height: 42,
                          fontSize: 16,
                          onPressed: _leave,
                        ),
                        if ((_room?.entryFee ?? 0) > 0)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              'لو طلعت قبل ما تبدأ اللعبة يرجع لك ذهبك',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: socMuted,
                                fontSize: 12.5,
                                fontFamily: kufi,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // المقاعد
              Expanded(
                child: WoodPanel(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                  child: Center(
                    child: GridView.count(
                      crossAxisCount: 5,
                      shrinkWrap: true,
                      mainAxisSpacing: 8,
                      childAspectRatio: .92,
                      children: [
                        for (var i = 0; i < max; i++)
                          i < players.length
                              ? _Seat(
                                  avatar: players[i].avatar,
                                  name: players[i].uid == myUid ? 'أنت' : players[i].name,
                                  bot: players[i].bot,
                                  me: players[i].uid == myUid,
                                  onTap: isPrivate && isHost && players[i].bot
                                      ? () => _removeBot(players[i])
                                      : () => showPlayerCard(
                                          context,
                                          uid: players[i].uid,
                                          name: players[i].name,
                                          avatar: players[i].avatar,
                                          frame: players[i].frame,
                                          bot: players[i].uid.startsWith('bot_'),
                                          code: widget.code,
                                        ),
                                  style: frameStyle(players[i].frame),
                                )
                              : const _Seat(avatar: '', name: 'ينتظر…', empty: true),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// دعوة الأصحاب: أصدقاؤك في اللعبة (دعوة وإشعار)، أو واتساب برسالة فيها الكود والرابط، أو نسخ الرسالة.
/// الطاولة العامة: الأصدقاء بس.
class _Invite extends StatelessWidget {
  const _Invite({required this.code, required this.private});

  final String code;
  final bool private;

  @override
  Widget build(BuildContext context) {
    final friends = SocButton(
      label: 'أصدقائي',
      semantics: 'ادع أصدقاءك',
      icon: const Gfx('friends', size: 24),
      tone: SocTone.blue,
      height: 40,
      fontSize: 15,
      padding: 8,
      onPressed: () => showInviteFriends(context, code),
    );
    if (!private) return friends;
    return Row(
      children: [
        Expanded(child: friends),
        const SizedBox(width: 8),
        Expanded(
          child: SocButton(
            label: 'واتساب',
            semantics: 'ادع أصحابك بالواتساب',
            icon: const Gfx('invite', size: 24),
            tone: SocTone.green,
            height: 40,
            fontSize: 15,
            padding: 8,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Telemetry.invite('whatsapp');
              if (!await Links.whatsapp(code)) {
                await Links.copy(code);
                messenger.showSnackBar(
                  const SnackBar(content: Text('ما انفتح الواتساب، نسخنا لك الدعوة. الصقها لأصحابك')),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: 'انسخ رابط الدعوة',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              Telemetry.invite('copy');
              await Links.copy(code);
              messenger.showSnackBar(const SnackBar(content: Text('نسخنا الدعوة، الصقها لأصحابك وين ما تبي')));
            },
            child: const GoldCircle(size: 42, child: Gfx('link', size: 26)),
          ),
        ),
      ],
    );
  }
}

/// كود الروم: لوح خشب بحد ذهبي والكود بحروف ذهبية كبيرة.
class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return SocPlankRow(
      selected: true,
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        children: [
          const Text(
            'رمز الطاولة (لو تبي تعزم أصحابك)',
            style: TextStyle(color: socMuted, fontSize: 12.5, fontFamily: kufi, fontWeight: FontWeight.w700),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: OutlinedText(code, size: 30, gradient: goldTitleColors, stroke: const Color(0xFF3A1606)),
          ),
        ],
      ),
    );
  }
}

class _PotBox extends StatelessWidget {
  const _PotBox({required this.pot});

  final int pot;

  @override
  Widget build(BuildContext context) {
    // نهاية الأسبوع: ذهب الفوز مضاعف.
    final boost = Weekend.at(DateTime.now()).boost;
    return SocCard(
      gold: true,
      tint: const Color(0xFF8A6410),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Gfx('coin', size: 28),
              const SizedBox(width: 8),
              Flexible(
                child: OutlinedText(
                  'الجائزة: ${arabicNumber(pot * boost)} ذهب',
                  size: 20,
                  gradient: goldTitleColors,
                  stroke: const Color(0xFF3A1606),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          Text(
            boost > 1 ? 'مضاعفة لأنها نهاية الأسبوع، وتتوزع على الفريق الفايز' : 'تتوزع على الفريق الفايز',
            textAlign: TextAlign.center,
            style: const TextStyle(color: socCream, fontSize: 12.5, fontFamily: kufi, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Seat extends StatelessWidget {
  const _Seat({
    required this.avatar,
    required this.name,
    this.style,
    this.empty = false,
    this.bot = false,
    this.me = false,
    this.onTap,
  });

  final String avatar;
  final String name;
  final FrameStyle? style;
  final bool empty;
  final bool bot;
  final bool me;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            empty
                ? Container(
                    width: 66,
                    height: 66,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: .25),
                      border: Border.all(color: const Color(0xFF6B4A2C), width: 2.5),
                    ),
                    child: const Icon(Icons.add_rounded, color: Color(0xFF8E7A62), size: 30),
                  )
                : Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SocAvatar(avatar: avatar, style: style, size: 58, gems: me, animate: true),
                      if (bot) const Positioned(bottom: -4, left: -4, child: Gfx('bot', size: 26)),
                    ],
                  ),
            const SizedBox(height: 5),
            empty
                ? const Text(
                    'ينتظر…',
                    style: TextStyle(
                      fontFamily: kufi,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8E7A62),
                    ),
                  )
                : NamePill(name, size: 14),
          ],
        ),
      ),
    );
  }
}
