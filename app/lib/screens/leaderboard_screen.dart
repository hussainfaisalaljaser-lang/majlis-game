import 'package:flutter/material.dart';

import '../models/achievements.dart';
import '../models/leaderboard.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/badges.dart';
import '../widgets/common.dart';
import '../widgets/player_card.dart';
import '../widgets/ui.dart';

/// جدول الترتيب: منصة للثلاثة الأوائل، وجوائز أبطال الأسبوع، والباقي في قائمة.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  Board _board = Board.weekly;

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      glow: const Color(0xFF5A3A12),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Gfx('rank', size: 32), SizedBox(width: 8), Text('الترتيب')],
        ),
        actions: [
          _Tabs(board: _board, onChanged: (b) => setState(() => _board = b)),
          const SizedBox(width: 12),
        ],
      ),
      body: !Backend.instance.isReady
          ? const Center(
              child: Text('يحتاج اتصال بالسيرفر', style: TextStyle(color: AppColors.muted)),
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _Board(key: ValueKey(_board), board: _board),
            ),
    );
  }
}

/// التبويبات: هذا الأسبوع / الكل / المستوى.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.board, required this.onChanged});

  final Board board;
  final ValueChanged<Board> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        for (final (b, label, icon) in const [
          (Board.weekly, 'هذا الأسبوع', 'fire'),
          (Board.allTime, 'الكل', 'trophy'),
          (Board.level, 'المستوى', 'xp'),
          (Board.ranked, 'التصنيف', 'rank_gold'),
        ])
          Semantics(
            button: true,
            selected: b == board,
            label: label,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onChanged(b),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: b == board ? const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFF2B53A)]) : null,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Gfx(icon, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: b == board ? AppColors.goldInk : AppColors.muted,
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

class _Board extends StatelessWidget {
  const _Board({super.key, required this.board});

  final Board board;

  bool get weekly => board == Board.weekly;

  int _score(LeaderboardEntry e) => switch (board) {
    Board.weekly => e.weeklyWins,
    Board.allTime => e.gamesWon,
    Board.level => e.level,
    Board.ranked => e.rankPoints,
  };

  bool get ranked => board == Board.ranked;

  /// النتيجة بأيقونتها (فوز أو مستوى أو رتبة التصنيف).
  Widget _scoreView(LeaderboardEntry e, {double size = 18, Color color = AppColors.gold}) => ranked
      ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RankEmblem(tier: RankTier.of(e.rankPoints), size: size * 1.3),
            const SizedBox(width: 3),
            Text(
              arabicNumber(e.rankPoints),
              style: TextStyle(
                color: RankTier.of(e.rankPoints).color,
                fontWeight: FontWeight.w800,
                fontSize: size * .8,
              ),
            ),
          ],
        )
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gfx(board == Board.level ? 'xp' : 'trophy', size: size),
            const SizedBox(width: 3),
            Text(
              board == Board.level ? 'مستوى ${arabicNumber(e.level)}' : '${arabicNumber(_score(e))} فوز',
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: size * .78),
            ),
          ],
        );

  @override
  Widget build(BuildContext context) {
    final me = Backend.instance.uid;
    return StreamBuilder(
      stream: Backend.instance.watchLeaderboard(board),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
            child: Text('ما قدرنا نجيب الترتيب', style: TextStyle(color: AppColors.muted)),
          );
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        final entries = snap.data!.where((e) => _score(e) > 0).toList();
        final myIndex = entries.indexWhere((e) => e.uid == me);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // المنصة والجوائز
            SizedBox(
              width: 360,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 8, 12),
                child: Column(
                  children: [
                    Expanded(
                      child: entries.isEmpty
                          ? Center(
                              child: Text(
                                weekly
                                    ? 'ما أحد فاز هذا الأسبوع للحين.\nكن أول واحد!'
                                    : ranked
                                    ? 'ما أحد دخل التصنيف هالموسم للحين.\nالعب في الطاولات العامة!'
                                    : 'ما فيه أحد في الترتيب للحين',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.muted, height: 1.6),
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: 330,
                                height: 300,
                                child: _Podium(entries: entries.take(3).toList(), me: me, score: _scoreView),
                              ),
                            ),
                    ),
                    if (weekly) const _ChampionPrizes(),
                    if (ranked) const _RankLadder(),
                  ],
                ),
              ),
            ),
            // القائمة
            Expanded(
              child: Column(
                children: [
                  if (weekly) const _LastChampions(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(8, 4, 14, 10),
                      children: [
                        for (final (i, e) in entries.indexed.skip(3))
                          _Row(rank: i + 1, entry: e, isMe: e.uid == me, score: _scoreView(e)),
                        if (entries.length <= 3)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'العب وفز عشان تطلع هنا',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // صفّك ثابت تحت لو مو باين في القائمة.
                  if (myIndex == -1 || myIndex >= 9)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 14, 10),
                      child: myIndex == -1
                          ? Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.panel,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Gfx('fire', size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    weekly ? 'فز هذا الأسبوع عشان تدخل الترتيب' : 'فز عشان تدخل الترتيب',
                                    style: const TextStyle(color: AppColors.muted),
                                  ),
                                ],
                              ),
                            )
                          : _Row(
                              rank: myIndex + 1,
                              entry: entries[myIndex],
                              isMe: true,
                              score: _scoreView(entries[myIndex]),
                            ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// المنصة: الثاني والأول والثالث بأحجام وألوان مختلفة.
class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.me, required this.score});

  final List<LeaderboardEntry> entries;
  final String me;
  final Widget Function(LeaderboardEntry, {double size, Color color}) score;

  static const _heights = [96.0, 70.0, 54.0];
  static const _colors = [
    [Color(0xFFFFE08A), Color(0xFFB9780F)],
    [Color(0xFFF1F5F9), Color(0xFF8E99A8)],
    [Color(0xFFF0B27A), Color(0xFF8D5524)],
  ];

  @override
  Widget build(BuildContext context) {
    final order = [1, 0, 2].where((i) => i < entries.length);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final i in order)
          Expanded(
            child: _Tap(
              label: 'ملف ${entries[i].name}',
              onTap: () => _openCard(context, entries[i]),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (i == 0) const Gfx('crown', size: 34),
                  PlayerAvatar(
                    avatar: entries[i].avatar,
                    style: frameStyle(entries[i].frame),
                    frame: frameStyle(entries[i].frame) != null ? null : _colors[i][0],
                    size: i == 0 ? 78 : 60,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 110),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: entries[i].uid == me
                          ? AppColors.green.withValues(alpha: .25)
                          : Colors.black.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entries[i].uid == me ? 'أنت' : entries[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 2),
                  score(entries[i], size: 16),
                  const SizedBox(height: 6),
                  Container(
                    height: _heights[i],
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_colors[i][0].withValues(alpha: .9), _colors[i][1].withValues(alpha: .55)],
                      ),
                      border: Border.all(color: _colors[i][0], width: 1.5),
                      boxShadow: [BoxShadow(color: _colors[i][0].withValues(alpha: .35), blurRadius: 16)],
                    ),
                    child: Gfx('medal${i + 1}', size: i == 0 ? 46 : 38),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// رتب التصنيف ومكافأة أول وصول لكل وحدة في الموسم.
class _RankLadder extends StatelessWidget {
  const _RankLadder();

  @override
  Widget build(BuildContext context) {
    final mine = Backend.instance.profile.value.rankPoints;
    final current = RankTier.of(mine);
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'رتبتك: ${current.name} (${arabicNumber(mine)}) · يتصفّر مع الموسم',
            style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final t in rankTiers)
                Expanded(
                  child: Opacity(
                    opacity: t.index <= current.index ? 1 : .55,
                    child: Column(
                      children: [
                        RankEmblem(tier: t, size: 30),
                        Text(
                          t.name,
                          style: TextStyle(color: t.color, fontSize: 10.5, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          t.coins == 0 ? arabicNumber(t.min) : '+${arabicNumber(t.coins)}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// جوائز أبطال الأسبوع: الإطار والشخصية الخاصة لكل مركز.
class _ChampionPrizes extends StatelessWidget {
  const _ChampionPrizes();

  static String _avatar(List<String> items) =>
      items.firstWhere((i) => i.startsWith('avatar_')).replaceFirst('avatar_', '');

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF3B2A0C), Color(0xFF1C1638)]),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.gold.withValues(alpha: .55)),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'الأوائل ياخذون إطار وشخصية خاصة لمدة أسبوع',
            style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
        for (final rank in [1, 2, 3])
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                PlayerAvatar(
                  avatar: _avatar(championRewards[rank]!.items),
                  style: frameStyle(championRewards[rank]!.items.first),
                  size: 34,
                ),
                PositionedDirectional(bottom: -6, end: -4, child: Gfx('medal$rank', size: 18)),
              ],
            ),
          ),
      ],
    ),
  );
}

/// أبطال الأسبوع اللي فات (لابسين أغراضهم الخاصة لين التتويج الجاي).
class _LastChampions extends StatelessWidget {
  const _LastChampions();

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: Backend.instance.watchChampions(),
    builder: (context, snap) {
      final c = snap.data;
      if (c == null || !c.active || c.list.isEmpty) return const SizedBox();
      return Container(
        margin: const EdgeInsets.fromLTRB(8, 4, 14, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4A3510), Color(0xFF2A1F45)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold),
        ),
        child: Row(
          children: [
            const Gfx('crown', size: 26),
            const SizedBox(width: 6),
            const Text(
              'أبطال الأسبوع اللي فات',
              style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            for (final ch in c.list) ...[
              Gfx('medal${ch.rank}', size: 22),
              const SizedBox(width: 2),
              Text(ch.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
              const SizedBox(width: 12),
            ],
          ],
        ),
      );
    },
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.rank, required this.entry, required this.isMe, required this.score});

  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;
  final Widget score;

  @override
  Widget build(BuildContext context) {
    return _Tap(
      label: 'ملف ${entry.name}',
      onTap: () => _openCard(context, entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isMe ? [const Color(0xFF173A26), const Color(0xFF14261B)] : [AppColors.card, AppColors.panel],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isMe ? AppColors.green : AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: .3),
                border: Border.all(color: AppColors.gold.withValues(alpha: .4)),
              ),
              child: Text(
                arabicNumber(rank),
                style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, color: AppColors.gold),
              ),
            ),
            const SizedBox(width: 10),
            PlayerAvatar(avatar: entry.avatar, style: frameStyle(entry.frame), size: 42, animate: false),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isMe ? 'أنت' : entry.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Row(
                    children: [
                      const Gfx('xp', size: 14),
                      const SizedBox(width: 3),
                      Text(
                        'مستوى ${arabicNumber(entry.level)}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            score,
          ],
        ),
      ),
    );
  }
}

/// بطاقة اللاعب من الترتيب: ملفه وإنجازاته، ومنها الحظر والبلاغ.
/// ضغطة تفتح بطاقة لاعب (وتنقرا كزر لقارئ الشاشة).
class _Tap extends StatelessWidget {
  const _Tap({required this.label, required this.onTap, required this.child});

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: child),
  );
}

void _openCard(BuildContext context, LeaderboardEntry e) =>
    showPlayerCard(context, uid: e.uid, name: e.name, avatar: e.avatar, frame: e.frame);
