import 'package:flutter/material.dart';

import '../models/leaderboard.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

/// جدول الترتيب: فوز هذا الأسبوع (يتصفر كل أحد)، أو الفوز من البداية، أو المستوى.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: NightScaffold(
        appBar: AppBar(
          title: const Text('🏆 الترتيب'),
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.muted,
            tabs: [
              Tab(text: 'هذا الأسبوع'),
              Tab(text: 'الكل'),
              Tab(text: 'المستوى'),
            ],
          ),
        ),
        body: !Backend.instance.isReady
            ? const Center(
                child: Text('يحتاج اتصال بالسيرفر', style: TextStyle(color: AppColors.muted)),
              )
            : const TabBarView(
                children: [
                  _Board(board: Board.weekly),
                  _Board(board: Board.allTime),
                  _Board(board: Board.level),
                ],
              ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.board});

  final Board board;

  bool get weekly => board == Board.weekly;

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
        final entries = (snap.data ?? const <LeaderboardEntry>[]).where((e) => _wins(e) > 0).toList();
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (entries.isEmpty) {
          return Center(
            child: Text(
              weekly ? 'ما أحد فاز هذا الأسبوع للحين.\nكن أول واحد! 💪' : 'ما فيه أحد في الترتيب للحين',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          );
        }
        final myIndex = entries.indexWhere((e) => e.uid == me);
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Podium(entries: entries.take(3).toList(), label: _label, me: me),
                  const SizedBox(height: 16),
                  for (final (i, e) in entries.indexed.skip(3))
                    _Row(rank: i + 1, entry: e, label: _label(e), isMe: e.uid == me),
                ],
              ),
            ),
            if (myIndex == -1 || myIndex >= 3)
              Container(
                width: double.infinity,
                color: AppColors.panel,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: myIndex == -1
                    ? Text(
                        weekly ? 'فز هذا الأسبوع عشان تدخل الترتيب 🔥' : 'فز عشان تدخل الترتيب 🔥',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      )
                    : _Row(rank: myIndex + 1, entry: entries[myIndex], label: _label(entries[myIndex]), isMe: true),
              ),
          ],
        );
      },
    );
  }

  int _wins(LeaderboardEntry e) => switch (board) {
    Board.weekly => e.weeklyWins,
    Board.allTime => e.gamesWon,
    Board.level => e.level,
  };

  String _label(LeaderboardEntry e) =>
      board == Board.level ? 'مستوى ${arabicNumber(e.level)}' : '${arabicNumber(_wins(e))} فوز';
}

class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.label, required this.me});

  final List<LeaderboardEntry> entries;
  final String Function(LeaderboardEntry) label;
  final String me;

  @override
  Widget build(BuildContext context) {
    // الترتيب على المنصة: الثاني، الأول، الثالث.
    const medals = ['🥇', '🥈', '🥉'];
    const heights = [120.0, 90.0, 70.0];
    final order = [1, 0, 2].where((i) => i < entries.length);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final i in order)
          Expanded(
            child: Column(
              children: [
                PlayerAvatar(
                  avatar: entries[i].avatar,
                  style: frameStyle(entries[i].frame),
                  frame: frameStyle(entries[i].frame) != null
                      ? null
                      : (entries[i].uid == me ? AppColors.green : AppColors.gold),
                  size: i == 0 ? 72 : 58,
                ),
                const SizedBox(height: 4),
                Text(
                  entries[i].uid == me ? 'أنت' : entries[i].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(label(entries[i]), style: const TextStyle(color: AppColors.gold, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  height: heights[i],
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.gold.withValues(alpha: i == 0 ? .5 : .3),
                        AppColors.card,
                      ],
                    ),
                  ),
                  child: Text(medals[i], style: const TextStyle(fontSize: 28)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.rank, required this.entry, required this.label, required this.isMe});

  final int rank;
  final LeaderboardEntry entry;
  final String label;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF14261B) : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isMe ? AppColors.green : AppColors.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              arabicNumber(rank),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.muted),
            ),
          ),
          PlayerAvatar(avatar: entry.avatar, style: frameStyle(entry.frame), size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMe ? 'أنت' : entry.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  'مستوى ${arabicNumber(entry.level)}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
