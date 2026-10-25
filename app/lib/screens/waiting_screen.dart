import 'dart:async';

import 'package:flutter/material.dart';

import '../models/room.dart';
import '../models/shop.dart';
import '../models/table_tier.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
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
    ('👩', 'نورة'), ('🧔', 'خالد'), ('👨‍🦱', 'سعد'), ('👴', 'عمر'), ('👱‍♀️', 'ريم'),
    ('🧑', 'فهد'), ('👩‍🦰', 'سارة'), ('👨', 'ناصر'), ('🧕', 'هيا'),
  ];

  final _demoJoined = [const RoomPlayer(uid: 'me', name: 'أنت', avatar: '😎')];
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
    });
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
        appBar: AppBar(title: Text(tier == null ? 'روم خاص 🔒' : 'طاولة ${tier.name} ${tier.emoji}')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  isPrivate
                      ? '👥 اعزم أصحابك بالكود'
                      : full
                          ? '✅ اكتملت الطاولة! اللعبة بتبدأ…'
                          : '🔍 نبحث عن لاعبين…',
                  style: const TextStyle(color: AppColors.muted, fontSize: 15),
                ),
                const SizedBox(height: 12),
                _CodeBox(code: widget.code ?? 'K7Q2M'),
                const SizedBox(height: 18),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    children: [
                      for (var i = 0; i < max; i++)
                        i < players.length
                            ? _Seat(
                                emoji: players[i].avatar,
                                name: players[i].uid == myUid ? 'أنت' : players[i].name,
                                bot: players[i].bot,
                                onTap: isPrivate && isHost && players[i].bot ? () => _removeBot(players[i]) : null,
                                style: frameStyle(players[i].frame),
                                frame: players[i].uid == myUid && frameStyle(players[i].frame) == null
                                    ? AppColors.gold
                                    : null,
                              )
                            : const _Seat(emoji: '＋', name: 'ينتظر…', empty: true),
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: players.length / max,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(10),
                  backgroundColor: AppColors.card,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 6),
                Text(
                  isPrivate
                      ? '${arabicNumber(players.length)} من ${arabicNumber(max)} · يحتاج ٥ لاعبين على الأقل'
                      : _botCountdown != null && _botCountdown! > 0
                          ? '${arabicNumber(players.length)} من ${arabicNumber(max)} · لو ما اكتملت خلال ${arabicNumber(_botCountdown!)} ثانية نكمّلها ببوتات 🤖'
                          : '${arabicNumber(players.length)} من ${arabicNumber(max)} · تبدأ تلقائياً لما تكتمل',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 12),
                if ((_room?.entryFee ?? tier?.entryFee ?? 0) > 0)
                  _PotBox(
                    pot: (_room?.entryFee ?? tier!.entryFee) *
                        (players.any((p) => p.bot) ? players.where((p) => !p.bot).length : max),
                  ),
                if (isPrivate && isHost) ...[
                  Row(
                    children: [
                      Expanded(
                        child: GameButton(
                          label: '🤖 أضف بوت',
                          tone: ButtonTone.purple,
                          onPressed: full || _addingBot ? null : _addBot,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GameButton(
                          label: _starting ? 'لحظة…' : '▶ ابدأ',
                          semantics: 'ابدأ',
                          onPressed: players.length >= 5 && !_starting ? _start : null,
                        ),
                      ),
                    ],
                  ),
                  if (players.any((p) => p.bot))
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('اضغط على البوت عشان تشيله', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ),
                ],
                const SizedBox(height: 12),
                GameButton(label: '✖ خروج', semantics: 'خروج', tone: ButtonTone.ghost, height: 46, fontSize: 16, onPressed: _leave),
                if ((_room?.entryFee ?? 0) > 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('لو طلعت قبل ما تبدأ اللعبة يرجع لك ذهبك', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
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
            '🏆 الجائزة: ${arabicNumber(pot)} 🪙',
            style: const TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const Text('تتوزع على الفريق الفايز', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _Seat extends StatelessWidget {
  const _Seat({
    required this.emoji,
    required this.name,
    this.frame,
    this.style,
    this.empty = false,
    this.bot = false,
    this.onTap,
  });

  final String emoji;
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
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.line, width: 2)),
                  child: const Text('＋', style: TextStyle(color: AppColors.muted, fontSize: 22)),
                )
              : Stack(
                  clipBehavior: Clip.none,
                  children: [
                    PlayerAvatar(avatar: emoji, frame: frame, style: style, size: 58),
                    if (bot) const Positioned(bottom: -4, left: -4, child: Text('🤖', style: TextStyle(fontSize: 18))),
                  ],
                ),
          const SizedBox(height: 5),
          Text(name, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: empty ? AppColors.muted : null)),
        ],
      ),
    );
  }
}
