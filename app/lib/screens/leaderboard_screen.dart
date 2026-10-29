import 'package:flutter/material.dart';

import '../models/achievements.dart';
import '../models/leaderboard.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/badges.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/design_season.dart';
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

  /// تدفق الجدول الحالي (بدون سيرفر ما نفتح شي).
  Stream<List<LeaderboardEntry>>? _stream;

  @override
  void initState() {
    super.initState();
    if (Backend.instance.isReady) _stream = Backend.instance.watchLeaderboard(_board);
  }

  void _pick(Board b) => setState(() {
    _board = b;
    if (Backend.instance.isReady) _stream = Backend.instance.watchLeaderboard(b);
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Backend.instance.profile,
    builder: (context, p, _) {
      if (_stream == null) {
        return LeaderboardView(profile: p, board: _board, onBoard: _pick, me: '', entries: null, offline: true);
      }
      return StreamBuilder(
        stream: _stream,
        builder: (context, snap) {
          Widget view(Champions? champions) => LeaderboardView(
            profile: p,
            board: _board,
            onBoard: _pick,
            me: Backend.instance.uid,
            entries: snap.data,
            error: snap.hasError,
            champions: champions,
          );
          if (_board != Board.weekly) return view(null);
          return StreamBuilder(stream: Backend.instance.watchChampions(), builder: (context, c) => view(c.data));
        },
      );
    },
  );
}

/// شاشة الترتيب بدون سيرفر: [entries] null يعني لسا يحمّل (أو [offline] ما فيه اتصال، أو [error] فشل).
class LeaderboardView extends StatelessWidget {
  const LeaderboardView({
    super.key,
    required this.profile,
    required this.board,
    required this.onBoard,
    required this.me,
    required this.entries,
    this.offline = false,
    this.error = false,
    this.champions,
  });

  final Profile profile;
  final Board board;
  final ValueChanged<Board> onBoard;

  /// معرّفك (يظهر صفّك بالأخضر… بالذهبي).
  final String me;
  final List<LeaderboardEntry>? entries;
  final bool offline;
  final bool error;

  /// أبطال الأسبوع اللي فات (بالتبويب الأسبوعي بس).
  final Champions? champions;

  static const _boards = [Board.weekly, Board.allTime, Board.level, Board.ranked];

  int _score(LeaderboardEntry e) => switch (board) {
    Board.weekly => e.weeklyWins,
    Board.allTime => e.gamesWon,
    Board.level => e.level,
    Board.ranked => e.rankPoints,
  };

  /// النتيجة بأيقونتها (فوز أو مستوى أو رتبة التصنيف).
  Widget _scoreView(LeaderboardEntry e, {double size = 18, Color color = const Color(0xFFF9D277)}) {
    final style = TextStyle(
      fontFamily: kufi,
      fontWeight: FontWeight.w800,
      fontSize: size * .85,
      height: 1.2,
      color: color,
    );
    return board == Board.ranked
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RankEmblem(tier: RankTier.of(e.rankPoints), size: size * 1.4),
              const SizedBox(width: 3),
              Text(arabicNumber(e.rankPoints), style: style.copyWith(color: RankTier.of(e.rankPoints).color)),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Gfx(board == Board.level ? 'xp' : 'trophy', size: size),
              const SizedBox(width: 3),
              Text(
                board == Board.level ? 'مستوى ${arabicNumber(e.level)}' : '${arabicNumber(_score(e))} فوز',
                style: style,
              ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    final list = entries?.where((e) => _score(e) > 0).toList();
    return NightScaffold(
      appBar: SnTopBar(
        title: 'الترتيب',
        icon: const Gfx('rank', size: 30),
        trailing: [SnWallet(coins: profile.coins, diamonds: profile.diamonds, infinite: profile.dev)],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, box) {
            final leftW = (box.maxWidth * .34).clamp(230.0, 330.0);
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: WoodPanel(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: SnTabBar(
                              labels: const ['هذا الأسبوع', 'الكل', 'المستوى', 'التصنيف'],
                              icons: const ['fire', 'trophy', 'xp', 'rank_gold'],
                              selected: _boards.indexOf(board),
                              onChanged: (i) => onBoard(_boards[i]),
                              height: 34,
                              fontSize: 14,
                            ),
                          ),
                          if (board == Board.weekly &&
                              champions != null &&
                              champions!.active &&
                              champions!.list.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: _LastChampions(champions: champions!),
                            ),
                          const SizedBox(height: 8),
                          Expanded(child: _list(list)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: leftW, child: _stage(list)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _message(String text) => Center(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.muted, height: 1.6, fontWeight: FontWeight.w700),
    ),
  );

  /// قائمة الباقي (من المركز الرابع).
  Widget _list(List<LeaderboardEntry>? list) {
    if (offline) return _message('يحتاج اتصال بالخادم');
    if (error) return _message('ما قدرنا نجيب الترتيب');
    if (list == null) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    final myIndex = list.indexWhere((e) => e.uid == me);
    return Column(
      children: [
        Expanded(
          child: list.length <= 3
              ? _message('العب وفز عشان تطلع هنا')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(2, 2, 2, 6),
                  children: [
                    for (final (i, e) in list.indexed.skip(3))
                      _Row(rank: i + 1, entry: e, isMe: e.uid == me, score: _scoreView(e)),
                  ],
                ),
        ),
        // صفّك ثابت تحت لو مو باين في القائمة.
        if (myIndex == -1 || myIndex >= 9)
          myIndex == -1
              ? PlankBar(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Gfx('fire', size: 22),
                      const SizedBox(width: 6),
                      Text(
                        board == Board.weekly ? 'فز هذا الأسبوع عشان تدخل الترتيب' : 'فز عشان تدخل الترتيب',
                        style: const TextStyle(color: Color(0xFFE8D3AE), fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                )
              : _Row(rank: myIndex + 1, entry: list[myIndex], isMe: true, score: _scoreView(list[myIndex]), margin: 0),
      ],
    );
  }

  /// لوحة المخمل: المنصة، وتحتها جوائز الأبطال أو سلّم الرتب.
  Widget _stage(List<LeaderboardEntry>? list) =>
      LayoutBuilder(builder: (context, box) => _stagePanel(list, compact: box.maxHeight < 380));

  Widget _stagePanel(List<LeaderboardEntry>? list, {required bool compact}) => VelvetPanel(
    padding: EdgeInsets.zero,
    child: Stack(
      children: [
        const Positioned.fill(child: SnSunburst(alignment: Alignment(0, -.3))),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            children: [
              Expanded(
                child: list == null || list.isEmpty
                    ? _message(
                        offline || error || list == null
                            ? ''
                            : board == Board.weekly
                            ? 'لا أحد فاز هذا الأسبوع حتى الآن.\nكن أول واحد!'
                            : board == Board.ranked
                            ? 'لا أحد دخل التصنيف هالموسم حتى الآن.\nالعب في الطاولات العامة!'
                            : 'لا يوجد أحد في الترتيب حتى الآن',
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: 300,
                          height: 300,
                          child: _Podium(entries: list.take(3).toList(), me: me, score: _scoreView),
                        ),
                      ),
              ),
              if (board == Board.weekly) _ChampionPrizes(compact: compact),
              if (board == Board.ranked) _RankLadder(mine: profile.rankPoints, compact: compact),
            ],
          ),
        ),
      ],
    ),
  );
}

/// المنصة: الثاني والأول والثالث بأحجام وألوان مختلفة.
class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.me, required this.score});

  final List<LeaderboardEntry> entries;
  final String me;
  final Widget Function(LeaderboardEntry, {double size, Color color}) score;

  static const _heights = [90.0, 66.0, 50.0];
  static const _colors = [
    [Color(0xFFFFEBA6), Color(0xFFE0A640), Color(0xFFB07418)],
    [Color(0xFFF7F9FC), Color(0xFFBAC3CF), Color(0xFF808A97)],
    [Color(0xFFF4C698), Color(0xFFC98249), Color(0xFF8B5427)],
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
                  if (i == 0) const Gfx('crown', size: 36),
                  GoldRingAvatar(
                    avatar: entries[i].avatar,
                    style: frameStyle(entries[i].frame),
                    size: i == 0 ? 72 : 56,
                    animate: i == 0,
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 96),
                    child: NamePill(entries[i].uid == me ? 'أنت' : entries[i].name, size: 13),
                  ),
                  const SizedBox(height: 3),
                  score(entries[i], size: 15, color: const Color(0xFFF9D277)),
                  const SizedBox(height: 6),
                  Container(
                    height: _heights[i],
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _colors[i],
                      ),
                      border: Border.all(color: const Color(0xFF3A1606), width: 2.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 6, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Gfx('medal${i + 1}', size: i == 0 ? 44 : 36),
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
  const _RankLadder({required this.mine, this.compact = false});

  final int mine;

  /// بدون العنوان وسطر المكافآت (للشاشات القصيرة).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final current = RankTier.of(mine);
    return PlankBar(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Text(
              'رتبتك: ${current.name} (${arabicNumber(mine)}) · يتصفّر مع الموسم',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFE8D3AE), fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              for (final t in rankTiers)
                Expanded(
                  child: Opacity(
                    opacity: t.index <= current.index ? 1 : .55,
                    child: Column(
                      children: [
                        RankEmblem(tier: t, size: compact ? 24 : 30),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            t.name,
                            style: TextStyle(color: t.color, fontSize: 10.5, fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (!compact)
                          Text(
                            t.coins == 0 ? arabicNumber(t.min) : '+${arabicNumber(t.coins)}',
                            style: const TextStyle(color: Color(0xFFC8AE88), fontSize: 9.5),
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
  const _ChampionPrizes({this.compact = false});

  /// بدون الكلام (للشاشات القصيرة).
  final bool compact;

  static String _avatar(List<String> items) =>
      items.firstWhere((i) => i.startsWith('avatar_')).replaceFirst('avatar_', '');

  @override
  Widget build(BuildContext context) => PlankBar(
    gold: true,
    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
    child: Row(
      children: [
        Expanded(
          child: compact
              ? const SizedBox()
              : const Text(
                  'الأوائل ياخذون إطار وشخصية خاصة لمدة أسبوع',
                  style: TextStyle(color: Color(0xFFF9D277), fontWeight: FontWeight.w800, fontSize: 12, height: 1.35),
                ),
        ),
        for (final rank in [1, 2, 3])
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GoldRingAvatar(
                  avatar: _avatar(championRewards[rank]!.items),
                  style: frameStyle(championRewards[rank]!.items.first),
                  size: 30,
                  animate: false,
                ),
                PositionedDirectional(bottom: -7, end: -5, child: Gfx('medal$rank', size: 18)),
              ],
            ),
          ),
      ],
    ),
  );
}

/// أبطال الأسبوع اللي فات (لابسين أغراضهم الخاصة لين التتويج الجاي).
class _LastChampions extends StatelessWidget {
  const _LastChampions({required this.champions});

  final Champions champions;

  @override
  Widget build(BuildContext context) => PlankBar(
    gold: true,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(
      children: [
        const Gfx('crown', size: 26),
        const SizedBox(width: 6),
        const Text(
          'أبطال الأسبوع اللي فات',
          style: TextStyle(
            fontFamily: kufi,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            height: 1.2,
            color: Color(0xFFF9D277),
          ),
        ),
        const Spacer(),
        for (final ch in champions.list) ...[
          Gfx('medal${ch.rank}', size: 22),
          const SizedBox(width: 2),
          Text(
            ch.name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFFFFF3DA)),
          ),
          const SizedBox(width: 12),
        ],
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.rank, required this.entry, required this.isMe, required this.score, this.margin = 8});

  final int rank;
  final LeaderboardEntry entry;
  final bool isMe;
  final Widget score;
  final double margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: margin),
      child: _Tap(
        label: 'ملف ${entry.name}',
        onTap: () => _openCard(context, entry),
        child: PlankBar(
          gold: isMe,
          radius: 12,
          padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 14, 5),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                child: Center(child: SnRankMedal(rank: rank, size: 34)),
              ),
              const SizedBox(width: 8),
              GoldRingAvatar(avatar: entry.avatar, style: frameStyle(entry.frame), size: 38, animate: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isMe ? 'أنت' : entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kufi,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        height: 1.2,
                        color: Color(0xFFFFF3DA),
                      ),
                    ),
                    Row(
                      children: [
                        const Gfx('xp', size: 14),
                        const SizedBox(width: 3),
                        Text(
                          'مستوى ${arabicNumber(entry.level)}',
                          style: const TextStyle(color: Color(0xFFD9C29B), fontSize: 12, fontWeight: FontWeight.w700),
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
      ),
    );
  }
}

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

/// بطاقة اللاعب من الترتيب: ملفه وإنجازاته، ومنها الحظر والبلاغ.
void _openCard(BuildContext context, LeaderboardEntry e) =>
    showPlayerCard(context, uid: e.uid, name: e.name, avatar: e.avatar, frame: e.frame);
