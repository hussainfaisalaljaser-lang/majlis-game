import 'package:flutter/material.dart';

import '../models/chat.dart' show agoText;
import '../models/game_view.dart';
import '../models/history.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
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
  Widget build(BuildContext context) => NightScaffold(
    appBar: AppBar(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [Gfx('log', size: 28), SizedBox(width: 8), Text('سجل مبارياتي')],
      ),
    ),
    body: FutureBuilder(
      future: _games,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
            child: Text('ما قدرنا نجيب السجل، جرّب بعد شوي', style: TextStyle(color: AppColors.muted)),
          );
        }
        final games = snap.data;
        if (games == null) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        if (games.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Gfx('games', size: 56),
                SizedBox(height: 8),
                Text('ما خلّصت ولا لعبة للحين', style: TextStyle(fontFamily: kufi, fontSize: 18)),
                Text('كل لعبة تخلصها تطلع هنا (آخر ٣٠ يوم)', style: TextStyle(color: AppColors.muted)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: games.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _GameRow(game: games[i], onTap: () => _open(games[i])),
        );
      },
    ),
  );

  void _open(HistoryEntry game) => showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .78),
    builder: (_) => _GameDetails(game: game),
  );
}

/// وين انلعبت: البطولة، أو روم خاص، أو طاولة عامة، وبأي طور.
String _where(HistoryEntry g) {
  final table = g.room.tour != null
      ? 'البطولة'
      : g.room.isPrivate
      ? 'روم خاص'
      : 'عشوائي';
  return '$table · ${g.room.roles ? 'المطوّر' : 'الكلاسيكي'}${g.room.quick ? ' · سريع' : ''}';
}

/// ختم الدور: أزرق للوفي، وأحمر للخاين، وختم الزعيم.
Widget _roleSeal(Role role, double size) =>
    role == Role.leader ? LeaderSeal(size: size) : Seal(loyal: role == Role.loyal, size: size);

class _GameRow extends StatelessWidget {
  const _GameRow({required this.game, required this.onTap});

  final HistoryEntry game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final v = game.view;
    final won = game.won;
    final result = game.room.results[v.you];
    final others = [
      for (final p in v.players)
        if (p.id != v.you) p,
    ];
    return Semantics(
      button: true,
      label: '${won ? 'فوز' : 'خسارة'} ${_where(game)}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [(won ? AppColors.green : AppColors.traitor).withValues(alpha: .22), AppColors.panel],
            ),
            border: Border.all(color: (won ? AppColors.green : AppColors.traitor).withValues(alpha: .5), width: 1.5),
          ),
          child: Row(
            children: [
              // النتيجة
              SizedBox(
                width: 62,
                child: Column(
                  children: [
                    Gfx(won ? 'trophy' : 'cross', size: 30),
                    Text(
                      won ? 'فوز' : 'خسارة',
                      style: TextStyle(
                        fontFamily: kufi,
                        fontWeight: FontWeight.w700,
                        color: won ? AppColors.green : AppColors.traitorLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // دورك
              _roleSeal(v.yourRole, 40),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          roleInfo[v.yourRole]!.$1,
                          style: TextStyle(
                            fontFamily: kufi,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: v.yourRole == Role.loyal ? AppColors.loyalLight : AppColors.traitorLight,
                          ),
                        ),
                        if (v.yourSpecial case final s?) ...[
                          const SizedBox(width: 6),
                          Gfx(specialInfo[s]!.$3, size: 18),
                          const SizedBox(width: 3),
                          Text(specialInfo[s]!.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                        ],
                        const Spacer(),
                        Text(
                          agoText(DateTime.now().difference(game.at)),
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      '${_where(game)} · ${(v.winnerLoyal ?? false) ? 'فاز الأوفياء' : 'فاز الخونة'}'
                      ' (${winReasons[v.winReason] ?? ''})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFD9CFFF), fontSize: 12.5),
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
                          const Gfx('coin', size: 16),
                          Text(' +${arabicNumber(result.coins)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                        ],
                        if (result != null) ...[
                          const Gfx('xp', size: 16),
                          Text(' +${arabicNumber(result.xp)}', style: const TextStyle(fontWeight: FontWeight.w800)),
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
    );
  }
}

/// تفاصيل لعبة: كل اللاعبين بأدوارهم، و«مين كذب؟»، و«شارك».
class _GameDetails extends StatelessWidget {
  const _GameDetails({required this.game});

  final HistoryEntry game;

  @override
  Widget build(BuildContext context) {
    final v = game.view;
    final room = game.room;
    final loyalWon = v.winnerLoyal ?? false;
    final players = [...v.players]
      ..sort((a, b) => (a.knownRole == Role.loyal ? 1 : 0) - (b.knownRole == Role.loyal ? 1 : 0));
    return Dialog(
      backgroundColor: AppColors.panel,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: AppColors.gold.withValues(alpha: .6), width: 2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                        const SizedBox(width: 6),
                        GoldText(game.won ? 'فزت' : 'خسرت', size: 28),
                      ],
                    ),
                    Text(
                      '${loyalWon ? 'فاز الأوفياء' : 'فاز الخونة'} · ${winReasons[v.winReason] ?? ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Color(0xFFD9CFFF)),
                    ),
                    Text(
                      '${_where(game)} · ${agoText(DateTime.now().difference(game.at))}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    GameButton(
                      label: 'مين كذب؟',
                      icon: const Gfx('liar', size: 22),
                      height: 44,
                      fontSize: 15,
                      onPressed: () => showLiesReveal(context, v, room),
                    ),
                    const SizedBox(height: 8),
                    GameButton(
                      label: 'شارك',
                      icon: const Gfx('invite', size: 22),
                      tone: ButtonTone.green,
                      height: 44,
                      fontSize: 15,
                      onPressed: () => showShareCard(context, v, room),
                    ),
                    const SizedBox(height: 8),
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('رجوع')),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // اللاعبين بأدوارهم (الخونة فوق)
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height - 70),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final p in players)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              PlayerAvatar(
                                avatar: room.player(p.id)?.avatar ?? 'masked',
                                style: frameStyle(room.player(p.id)?.frame),
                                size: 32,
                                dead: !p.alive,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  v.nameOf(p.id),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
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
                                    color: role == Role.loyal ? AppColors.loyalLight : AppColors.traitorLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
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
