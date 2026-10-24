import 'dart:async';

import 'package:flutter/material.dart';

import '../models/table_tier.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// غرفة الانتظار: المقاعد تتعبى لين تكتمل الطاولة.
///
/// حالياً اللاعبين وهميين يدخلون كل ثانية. لما نربط Firebase، بيجون من المطابقة الحقيقية.
class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key, required this.tier, required this.playerCount});

  final TableTier tier;
  final int playerCount;

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  static const _demoPlayers = [
    ('👩', 'نورة'), ('🧔', 'خالد'), ('👨‍🦱', 'سعد'), ('👴', 'عمر'), ('👱‍♀️', 'ريم'),
    ('🧑', 'فهد'), ('👩‍🦰', 'سارة'), ('👨', 'ناصر'), ('🧕', 'هيا'),
  ];

  final _joined = <(String, String)>[('😎', 'أنت')];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (_joined.length >= widget.playerCount) {
        _timer?.cancel();
        return;
      }
      setState(() => _joined.add(_demoPlayers[_joined.length - 1]));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final full = _joined.length >= widget.playerCount;
    final pot = widget.tier.entryFee * widget.playerCount;
    return Scaffold(
      appBar: AppBar(title: Text('طاولة ${widget.tier.name} ${widget.tier.emoji}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                full ? '✅ اكتملت الطاولة! اللعبة بتبدأ…' : '🔍 نبحث عن لاعبين…',
                style: const TextStyle(color: AppColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gold, width: 1.5),
                ),
                child: const Column(
                  children: [
                    Text('كود الروم (لو تبي تعزم أصحابك)', style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
                    Text(
                      'K7Q2M',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  children: [
                    for (var i = 0; i < widget.playerCount; i++)
                      i < _joined.length
                          ? _Seat(emoji: _joined[i].$1, name: _joined[i].$2, frame: i == 0 ? AppColors.gold : null)
                          : const _Seat(emoji: '＋', name: 'ينتظر…', empty: true),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: _joined.length / widget.playerCount,
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
                backgroundColor: AppColors.card,
                color: AppColors.gold,
              ),
              const SizedBox(height: 6),
              Text(
                '${arabicNumber(_joined.length)} من ${arabicNumber(widget.playerCount)} · تبدأ تلقائياً لما تكتمل',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
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
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('✖ خروج')),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _Seat extends StatelessWidget {
  const _Seat({required this.emoji, required this.name, this.frame, this.empty = false});

  final String emoji;
  final String name;
  final Color? frame;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    return Column(
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
            : PlayerAvatar(emoji: emoji, frame: frame, size: 58),
        const SizedBox(height: 5),
        Text(name, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: empty ? AppColors.muted : null)),
      ],
    );
  }
}
