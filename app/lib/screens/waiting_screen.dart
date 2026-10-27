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
import '../widgets/majlis.dart';
import '../widgets/player_card.dart';
import '../widgets/ui.dart';
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
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GameScreen(code: code)));
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: Text('تشيل البوت ${bot.name}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لا')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('شيله')),
        ],
      ),
    );
    if (ok == true) await Backend.instance.removeBot(widget.code!, bot.uid).catchError((_) {});
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => didPop ? null : _leave(),
      child: NightScaffold(
        // كل طاولة لها مكانها: تشوفه من غرفة الانتظار.
        background: _room?.tour != null
            ? const MajlisRoom(venue: Venue.kings)
            : tier == null
            ? null
            : MajlisRoom(venue: venueOf(tier.id)),
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Gfx(_room?.tour != null ? 'trophy' : (tier == null ? 'key' : tier.icon), size: 30),
              const SizedBox(width: 8),
              Text(
                _room?.tour != null
                    ? 'بطولة الأسبوع · ${tourStageNames[_room!.tour!]}'
                    : (tier == null ? 'روم خاص' : 'طاولة ${tier.name}'),
              ),
              if (_room?.quick ?? false) ...[
                const SizedBox(width: 10),
                const Gfx('bolt', size: 22),
                const Text(' سريع', style: TextStyle(color: AppColors.gold, fontSize: 15)),
              ],
              // طور الشخصيات (الطور العادي ما يحتاج علامة).
              if (_room?.roles ?? false) ...[
                const SizedBox(width: 10),
                const Gfx('seer', size: 22),
                const Text(' الشخصيات', style: TextStyle(color: Color(0xFFB9A4FF), fontSize: 15)),
              ],
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: Row(
            children: [
              // المعلومات والأزرار
              SizedBox(
                width: 300,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: [
                      Text(
                        isPrivate
                            ? 'اعزم أصحابك بالكود'
                            : full
                            ? 'اكتملت الطاولة! اللعبة بتبدأ…'
                            : 'نبحث عن لاعبين…',
                        style: const TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      _CodeBox(code: widget.code ?? 'K7Q2M'),
                      if (widget.code != null) ...[
                        const SizedBox(height: 8),
                        _Invite(code: widget.code!, private: isPrivate),
                      ],
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: players.length / max,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(10),
                        backgroundColor: AppColors.card,
                        color: AppColors.gold,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPrivate
                            ? '${arabicNumber(players.length)} من ${arabicNumber(max)} · يحتاج ٥ لاعبين على الأقل'
                            : _botCountdown != null && _botCountdown! > 0
                            ? '${arabicNumber(players.length)} من ${arabicNumber(max)} · لو ما اكتملت خلال ${arabicNumber(_botCountdown!)} ثانية نكمّلها ببوتات'
                            : '${arabicNumber(players.length)} من ${arabicNumber(max)} · تبدأ تلقائياً لما تكتمل',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      if ((_room?.entryFee ?? tier?.entryFee ?? 0) > 0) ...[
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
                              child: GameButton(
                                label: 'أضف بوت',
                                icon: const Gfx('bot', size: 26),
                                tone: ButtonTone.purple,
                                height: 48,
                                fontSize: 16,
                                onPressed: full || _addingBot ? null : _addBot,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GameButton(
                                label: _starting ? 'لحظة…' : 'ابدأ',
                                semantics: 'ابدأ',
                                height: 48,
                                fontSize: 16,
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
                              style: TextStyle(color: AppColors.muted, fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 10),
                      ],
                      GameButton(
                        label: 'خروج',
                        icon: const Gfx('exit', size: 26),
                        semantics: 'خروج',
                        tone: ButtonTone.ghost,
                        height: 44,
                        fontSize: 16,
                        onPressed: _leave,
                      ),
                      if ((_room?.entryFee ?? 0) > 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'لو طلعت قبل ما تبدأ اللعبة يرجع لك ذهبك',
                            style: TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // المقاعد
              Expanded(
                child: Center(
                  child: GridView.count(
                    crossAxisCount: 5,
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 16, 12),
                    mainAxisSpacing: 8,
                    childAspectRatio: .95,
                    children: [
                      for (var i = 0; i < max; i++)
                        i < players.length
                            ? _Seat(
                                avatar: players[i].avatar,
                                name: players[i].uid == myUid ? 'أنت' : players[i].name,
                                bot: players[i].bot,
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
                                frame: players[i].uid == myUid && frameStyle(players[i].frame) == null
                                    ? AppColors.gold
                                    : null,
                              )
                            : const _Seat(avatar: '', name: 'ينتظر…', empty: true),
                    ],
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
    final friends = GameButton(
      label: 'أصدقائي',
      semantics: 'ادع أصدقاءك',
      icon: const Gfx('friends', size: 26),
      tone: ButtonTone.purple,
      height: 44,
      fontSize: 14.5,
      onPressed: () => showInviteFriends(context, code),
    );
    if (!private) return friends;
    return Row(
      children: [
        Expanded(child: friends),
        const SizedBox(width: 8),
        Expanded(
          child: GameButton(
            label: 'واتساب',
            semantics: 'ادع أصحابك بالواتساب',
            icon: const Gfx('invite', size: 26),
            tone: ButtonTone.green,
            height: 44,
            fontSize: 14.5,
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
            child: Container(
              width: 50,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withValues(alpha: .6), width: 1.5),
              ),
              child: const Gfx('link', size: 30),
            ),
          ),
        ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Column(
        children: [
          const Text('كود الروم (لو تبي تعزم أصحابك)', style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
          Text(
            code,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 6),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(colors: [Color(0xFF3B2A05), Color(0xFF5B4208)]),
      ),
      child: Column(
        children: [
          Text(
            'الجائزة: ${arabicNumber(pot * boost)} ذهب',
            style: const TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Text(
            boost > 1 ? 'مضاعفة لأنها نهاية الأسبوع، وتتوزع على الفريق الفايز' : 'تتوزع على الفريق الفايز',
            style: const TextStyle(fontSize: 12),
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
    this.frame,
    this.style,
    this.empty = false,
    this.bot = false,
    this.onTap,
  });

  final String avatar;
  final String name;
  final Color? frame;
  final FrameStyle? style;
  final bool empty;
  final bool bot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          empty
              ? Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line, width: 2),
                  ),
                  child: const Icon(Icons.add_rounded, color: AppColors.muted, size: 28),
                )
              : Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PlayerAvatar(avatar: avatar, frame: frame, style: style, size: 58),
                    if (bot) const Positioned(bottom: -4, left: -4, child: Gfx('bot', size: 24)),
                  ],
                ),
          const SizedBox(height: 5),
          Text(
            name,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: empty ? AppColors.muted : null),
          ),
        ],
      ),
    );
  }
}
