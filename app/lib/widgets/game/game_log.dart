import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../theme.dart';
import '../common.dart';
import 'policy_card.dart';
import 'tracks.dart';

/// سجل اللعبة: كل تصويت وادعاء وتمرير، مع تنبيه لما تتناقض الادعاءات.
void showGameLog(BuildContext context, GameView view) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.panel,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .95,
      builder: (context, controller) => _GameLog(view: view, controller: controller),
    ),
  );
}

class _GameLog extends StatelessWidget {
  const _GameLog({required this.view, required this.controller});

  final GameView view;
  final ScrollController controller;

  String _name(String id) => id == view.you ? 'أنت' : view.player(id).name;

  @override
  Widget build(BuildContext context) {
    final rounds = <int, List<GameEvent>>{};
    for (final e in view.log) {
      rounds.putIfAbsent(e.round, () => []).add(e);
    }
    final claims = view.claims;
    final entries = rounds.entries.toList().reversed.toList();

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text('📜 سجل اللعبة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        ),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('ما صار شي للحين', style: TextStyle(color: AppColors.muted)),
          ),
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            children: [
              for (final MapEntry(key: round, value: events) in entries)
                _RoundCard(
                  round: round,
                  events: events,
                  claims: claims.where((c) => c.round == round).toList(),
                  name: _name,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({required this.round, required this.events, required this.claims, required this.name});

  final int round;
  final List<GameEvent> events;
  final List<Claim> claims;
  final String Function(String) name;

  @override
  Widget build(BuildContext context) {
    final lines = <Widget>[];
    Policy? enacted;
    for (final e in events) {
      final d = e.data;
      switch (e.type) {
        case 'nominated':
          lines.add(Text('👑 ${name(d['president'] as String)} رشّح 📜 ${name(d['chancellor'] as String)}'));
        case 'voteResult':
          final votes = Map<String, bool>.from(d['votes'] as Map);
          lines.add(Text(d['passed'] == true ? '✅ الحكومة انتخبت' : '❌ الحكومة رُفضت'));
          lines.add(Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final MapEntry(:key, :value) in votes.entries)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: value ? const Color(0xFF162A1D) : const Color(0xFF5C1F26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${value ? '✅' : '❌'} ${name(key)}',
                    style: TextStyle(fontSize: 12, color: value ? const Color(0xFF8EE4AB) : const Color(0xFFFFB0B0)),
                  ),
                ),
            ],
          ));
        case 'enacted':
          enacted = Policy.parse(d['policy']);
          final chaos = d['chaos'] == true;
          lines.add(Row(children: [
            Text(chaos ? '🌪️ فوضى! تمرر تلقائياً: ' : '⚖️ تمرر: '),
            MiniPolicies([enacted]),
          ]));
        case 'claim':
          final c = d['claim'] as Map;
          lines.add(Row(children: [
            Text('📢 ${name(c['by'] as String)} ${c['office'] == 'president' ? '(الرئيس)' : '(المستشار)'} ادّعى '),
            MiniPolicies([for (final p in c['policies'] as List) Policy.parse(p)]),
          ]));
        case 'vetoed':
          lines.add(const Text('✋ الحكومة استخدمت الفيتو'));
        case 'vetoRejected':
          lines.add(const Text('🙅 الرئيس رفض الفيتو'));
        case 'investigated':
          lines.add(Text('🔍 ${name(d['by'] as String)} حقق مع ${name(d['target'] as String)}'));
        case 'peeked':
          lines.add(Text('👁️ ${name(d['by'] as String)} تلصص على الكروت'));
        case 'specialElection':
          lines.add(Text('🗳️ ${name(d['by'] as String)} اختار ${name(d['target'] as String)} رئيس'));
        case 'executed':
          lines.add(Text('🗡️ ${name(d['by'] as String)} طرد ${name(d['target'] as String)}'));
        case 'gameOver':
          lines.add(Text(d['winner'] == 'loyal' ? '🏆 فاز الأوفياء' : '🏆 فاز الخونة'));
      }
    }

    final pres = claims.where((c) => c.president).firstOrNull;
    final chan = claims.where((c) => !c.president).firstOrNull;
    final contradiction = pres != null && chan != null && claimsContradict(pres.policies, chan.policies, enacted);

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 13.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الجولة ${arabicNumber(round)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 6),
            for (final l in lines) Padding(padding: const EdgeInsets.only(bottom: 4), child: l),
            if (contradiction)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A1D22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF7A2E38)),
                ),
                child: const Text(
                  '⚠️ تناقض! واحد منهم يكذب',
                  style: TextStyle(color: Color(0xFFFFC2C2), fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// اسم القدرة مع الإيموجي، للاستخدام في أماكن ثانية.
String powerLabel(Power p) => '${powerEmoji[p]} ${powerName[p]}';
