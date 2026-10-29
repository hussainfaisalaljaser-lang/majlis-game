import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/chat.dart' show agoText;
import '../models/game_view.dart';
import '../models/history.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/design_season.dart';
import '../widgets/game/lies_reveal.dart';
import '../widgets/game/overlays.dart';
import '../widgets/game/share_card.dart';
import '../widgets/ui.dart';

/// سجل مبارياتي: آخر ٣٠ لعبة (آخر ٣٠ يوم). كل لعبة: فزت أو خسرت، ودورك، ومين كان معك وأدوارهم،
/// وتقدر تفتح «مين كذب؟» أو تشاركها.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Future<List<HistoryEntry>> _games = Backend.instance.history();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Backend.instance.profile,
    builder: (context, p, _) => FutureBuilder(
      future: _games,
      builder: (context, snap) => HistoryView(profile: p, games: snap.data, error: snap.hasError, onOpen: _open),
    ),
  );

  void _open(HistoryEntry game) => showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .78),
    builder: (_) => HistoryDetails(game: game),
  );
}

/// وين انلعبت: البطولة، أو روم خاص، أو طاولة عامة، وبأي طور.
String _where(HistoryEntry g) {
  final table = g.room.tour != null
      ? 'البطولة'
      : g.room.isPrivate
      ? 'طاولة خاصة'
      : 'عشوائي';
  return '$table · ${g.room.roles ? 'المطوّر' : 'الكلاسيكي'}${g.room.quick ? ' · سريع' : ''}';
}

/// ختم الدور: أزرق للوفي، وأحمر للخاين، وختم الزعيم.
Widget _roleSeal(Role role, double size) =>
    role == Role.leader ? LeaderSeal(size: size) : Seal(loyal: role == Role.loyal, size: size);

const _cream = Color(0xFFFFF3DA);
const _tan = Color(0xFFD9C29B);

/// شاشة السجل بدون سيرفر: [games] null يعني لسا يحمّل، و[error] فشل التحميل.
class HistoryView extends StatelessWidget {
  const HistoryView({super.key, required this.profile, required this.games, this.error = false, required this.onOpen});

  final Profile profile;
  final List<HistoryEntry>? games;
  final bool error;
  final ValueChanged<HistoryEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final list = games ?? const <HistoryEntry>[];
    return NightScaffold(
      appBar: SnTopBar(
        title: 'سجل مبارياتي',
        icon: const Gfx('log', size: 30),
        trailing: [SnWallet(coins: profile.coins, diamonds: profile.diamonds, infinite: profile.dev)],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, box) {
            final leftW = (box.maxWidth * .24).clamp(180.0, 240.0);
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: WoodPanel(padding: const EdgeInsets.fromLTRB(14, 16, 14, 10), child: _body(list)),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: leftW,
                    child: _Summary(games: list),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _body(List<HistoryEntry> list) {
    if (error) {
      return const Center(
        child: Text(
          'ما قدرنا نجيب السجل، جرّب بعد شوي',
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
        ),
      );
    }
    if (games == null) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    if (list.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gfx('games', size: 56),
            SizedBox(height: 8),
            Text(
              'ما خلّصت ولا لعبة للحين',
              style: TextStyle(fontFamily: kufi, fontSize: 19, fontWeight: FontWeight.w800, color: _cream),
            ),
            Text(
              'كل لعبة تخلصها تطلع هنا (آخر ٣٠ يوم)',
              style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 9),
      itemBuilder: (context, i) => _GameRow(game: list[i], onTap: () => onOpen(list[i])),
    );
  }
}

/// لوحة المخمل (يسار): ملخص آخر ٣٠ يوم: كم فزت من كم، ونسبة الفوز، وكم كسبت.
class _Summary extends StatelessWidget {
  const _Summary({required this.games});

  final List<HistoryEntry> games;

  @override
  Widget build(BuildContext context) {
    final wins = games.where((g) => g.won).length;
    var coins = 0, xp = 0;
    for (final g in games) {
      final r = g.room.results[g.view.you];
      coins += r?.coins ?? 0;
      xp += r?.xp ?? 0;
    }
    final rate = games.isEmpty ? 0.0 : wins / games.length;
    return LayoutBuilder(
      builder: (context, box) {
        final k = (box.maxHeight / 477).clamp(.6, 1.0);
        Widget stat(String icon, String text) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Gfx(icon, size: 22),
            const SizedBox(width: 6),
            OutlinedText(text, size: 16, stroke: const Color(0xFF260A10), maxLines: 1, shadow: false),
          ],
        );
        return VelvetPanel(
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              const Positioned.fill(child: SnSunburst(alignment: Alignment(0, -.5))),
              Padding(
                padding: EdgeInsets.fromLTRB(14, 12 * k, 14, 16 * k),
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Center(child: Gfx('trophy', size: 86 * k)),
                    ),
                    GoldTitle('فزت ${arabicNumber(wins)}', size: math.max(16, 24 * k)),
                    Text(
                      'من ${arabicNumber(games.length)} لعبة · آخر ٣٠ يوم',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFF1DDBA), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 10 * k),
                    SnProgressBar(value: rate, height: math.max(9.0, 12 * k)),
                    SizedBox(height: 3 * k),
                    Text(
                      'نسبة الفوز ${arabicNumber((rate * 100).round())}٪',
                      style: const TextStyle(color: Color(0xFFF2B552), fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(flex: 2),
                    stat('coin', '+${arabicNumber(coins)}'),
                    SizedBox(height: 6 * k),
                    stat('xp', '+${arabicNumber(xp)}'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GameRow extends StatelessWidget {
  const _GameRow({required this.game, required this.onTap});

  final HistoryEntry game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = game.view;
    final won = game.won;
    final edge = won ? const Color(0xFF7BD357) : const Color(0xFFD9573F);
    final result = game.room.results[v.you];
    final others = [
      for (final p in v.players)
        if (p.id != v.you) p,
    ];
    return Semantics(
      button: true,
      label: '${won ? 'فوز' : 'خسارة'} ${_where(game)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF130B06),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF573420),
              image: const DecorationImage(image: AssetImage(DesignAssets.plank), fit: BoxFit.fill),
              border: Border.all(color: edge.withValues(alpha: .85), width: 2),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: AlignmentDirectional.centerStart,
                  end: AlignmentDirectional.centerEnd,
                  colors: [edge.withValues(alpha: .28), Colors.transparent],
                  stops: const [0, .55],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
                child: Row(
                  children: [
                    // النتيجة
                    SizedBox(
                      width: 62,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Gfx(won ? 'trophy' : 'cross', size: 30),
                          OutlinedText(
                            won ? 'فوز' : 'خسارة',
                            size: 15,
                            color: won ? const Color(0xFFB6F08C) : const Color(0xFFFF9A8A),
                            maxLines: 1,
                            shadow: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // دورك
                    _roleSeal(v.yourRole, 42),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                roleInfo[v.yourRole]!.$1,
                                style: TextStyle(
                                  fontFamily: kufi,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  color: v.yourRole == Role.loyal ? AppColors.loyalLight : AppColors.traitorLight,
                                ),
                              ),
                              if (v.yourSpecial case final s?) ...[
                                const SizedBox(width: 8),
                                Gfx(specialInfo[s]!.$3, size: 18),
                                const SizedBox(width: 3),
                                Text(
                                  specialInfo[s]!.$1,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: _cream),
                                ),
                              ],
                              const Spacer(),
                              Text(
                                agoText(DateTime.now().difference(game.at)),
                                style: const TextStyle(color: _tan, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Text(
                            '${_where(game)} · ${(v.winnerLoyal ?? false) ? 'فاز الأوفياء' : 'فاز الخونة'}'
                            ' (${winReasons[v.winReason] ?? ''})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE6D8FF),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // اللي كانوا معك، وكل واحد بلون فريقه
                              for (final p in others.take(9))
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(end: 3),
                                  child: Container(
                                    padding: const EdgeInsets.all(1.5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: p.knownRole == Role.loyal ? AppColors.loyal : AppColors.traitor,
                                    ),
                                    child: PlayerAvatar(avatar: game.room.player(p.id)?.avatar ?? 'masked', size: 24),
                                  ),
                                ),
                              const Spacer(),
                              if (result != null && result.coins > 0) ...[
                                const Gfx('coin', size: 17),
                                Text(' +${arabicNumber(result.coins)}', style: _rewardText),
                                const SizedBox(width: 10),
                              ],
                              if (result != null) ...[
                                const Gfx('xp', size: 17),
                                Text(' +${arabicNumber(result.xp)}', style: _rewardText),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _rewardText = TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 14, height: 1.2, color: _cream);

/// تفاصيل لعبة: كل اللاعبين بأدوارهم، و«مين كذب؟»، و«شارك».
class HistoryDetails extends StatelessWidget {
  const HistoryDetails({super.key, required this.game});

  final HistoryEntry game;

  @override
  Widget build(BuildContext context) {
    final v = game.view;
    final room = game.room;
    final loyalWon = v.winnerLoyal ?? false;
    final players = [...v.players]
      ..sort((a, b) => (a.knownRole == Role.loyal ? 1 : 0) - (b.knownRole == Role.loyal ? 1 : 0));
    return SnPopup(
      title: game.won ? 'فزت' : 'خسرت',
      width: 640,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // النتيجة والأزرار
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    game.won ? const Gfx('trophy', size: 40) : Seal(loyal: loyalWon, size: 40),
                    const SizedBox(width: 8),
                    Flexible(
                      child: OutlinedText(
                        loyalWon ? 'فاز الأوفياء' : 'فاز الخونة',
                        size: 19,
                        color: loyalWon ? AppColors.loyalLight : AppColors.traitorLight,
                        stroke: const Color(0xFF260A10),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  winReasons[v.winReason] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFE6D8FF), fontWeight: FontWeight.w700),
                ),
                Text(
                  '${_where(game)} · ${agoText(DateTime.now().difference(game.at))}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _tan, fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SnButton(
                  label: 'مين كذب؟',
                  icon: const Gfx('liar', size: 24),
                  height: 44,
                  fontSize: 16,
                  onPressed: () => showLiesReveal(context, v, room),
                ),
                const SizedBox(height: 8),
                SnButton(
                  label: 'شارك',
                  icon: const Gfx('invite', size: 24),
                  tone: SnTone.green,
                  height: 44,
                  fontSize: 16,
                  onPressed: () => showShareCard(context, v, room),
                ),
                const SizedBox(height: 4),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('رجوع')),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // اللاعبين بأدوارهم (الخونة فوق)
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: math.max(120, MediaQuery.sizeOf(context).height - 130)),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .28),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD9A84E).withValues(alpha: .35)),
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  children: [
                    for (final p in players)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            GoldRingAvatar(
                              avatar: room.player(p.id)?.avatar ?? 'masked',
                              style: frameStyle(room.player(p.id)?.frame),
                              size: 30,
                              animate: false,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                v.nameOf(p.id),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: kufi,
                                  fontSize: 15,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                  color: p.alive ? _cream : _tan.withValues(alpha: .6),
                                  decoration: p.alive ? null : TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                            if (p.knownSpecial != null)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(end: 6),
                                child: Gfx(specialInfo[p.knownSpecial]!.$3, size: 18),
                              ),
                            if (p.knownRole case final role?)
                              Text(
                                roleInfo[role]!.$1,
                                style: TextStyle(
                                  fontFamily: kufi,
                                  height: 1.2,
                                  color: role == Role.loyal ? AppColors.loyalLight : AppColors.traitorLight,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
