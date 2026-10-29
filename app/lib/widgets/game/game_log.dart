import 'package:flutter/material.dart';

import '../../models/game_view.dart';
import '../../theme.dart';
import '../common.dart';
import '../design.dart';
import '../design_dialogs.dart';
import '../design_game.dart';
import 'policy_card.dart';

/// سجل اللعبة: كل تصويت وادعاء وتمرير، مع تنبيه لما تتناقض الادعاءات.
void showGameLog(BuildContext context, GameView view) {
  showModalBottomSheet<void>(
    context: context,
    // اللوحة الخشب ترسمها _GameLog نفسها.
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 760),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      // على الجوال الأفقي الارتفاع قليل، فنفتح اللوحة أعلى
      initialChildSize: MediaQuery.sizeOf(context).height < 500 ? .88 : .75,
      maxChildSize: .95,
      builder: (context, controller) => _GameLog(view: view, controller: controller),
    ),
  );
}

class _GameLog extends StatelessWidget {
  const _GameLog({required this.view, required this.controller});

  final GameView view;
  final ScrollController controller;

  String _name(String id) => view.nameOf(id);

  @override
  Widget build(BuildContext context) {
    final rounds = <int, List<GameEvent>>{};
    for (final e in view.log) {
      rounds.putIfAbsent(e.round, () => []).add(e);
    }
    final claims = view.claims;
    final entries = rounds.entries.toList().reversed.toList();
    // عداد الحكومات الفاشلة وقت كل حدث (تصويت رُفض أو انلغى، أو فيتو). أي قرار يتمرر يصفّره.
    final failed = <GameEvent, int>{};
    var tracker = 0;
    for (final e in view.log) {
      switch (e.type) {
        case 'voteResult' when e.data['passed'] != true:
        case 'vetoed':
          failed[e] = ++tracker;
        case 'enacted':
          tracker = 0;
      }
    }

    return SheetPanel(
      child: Column(
        children: [
          const SizedBox(height: 13),
          const SheetHandle(),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 4, 12, 6),
            child: SheetTitle('سجل اللعبة', icon: Gfx('log', size: 32), size: 24),
          ),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'ما صار شي للحين',
                style: TextStyle(color: Color(0xFFE7CFA6), fontWeight: FontWeight.w700),
              ),
            ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              children: [
                // بالعرض (جوال أفقي) عمودين، والكروت تتوزع عليهم بالتناوب، وبالطول عمود واحد.
                LayoutBuilder(
                  builder: (context, box) {
                    final cols = box.maxWidth >= 560 ? 2 : 1;
                    final cards = [
                      for (final MapEntry(key: round, value: events) in entries)
                        _RoundCard(
                          round: round,
                          events: events,
                          claims: claims.where((c) => c.round == round).toList(),
                          name: _name,
                          failed: failed,
                        ),
                    ];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var c = 0; c < cols; c++) ...[
                          if (c > 0) const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              children: [
                                for (var i = c; i < cards.length; i += cols)
                                  Padding(padding: const EdgeInsets.only(bottom: 10), child: cards[i]),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({
    required this.round,
    required this.events,
    required this.claims,
    required this.name,
    required this.failed,
  });

  final int round;
  final List<GameEvent> events;
  final List<Claim> claims;
  final String Function(String) name;

  /// كم حكومة فاشلة ورا بعض صارت بعد هالحدث (من ٣).
  final Map<GameEvent, int> failed;

  /// «حكومة فاشلة ٢ من ٣»، والثالثة تمرر أول كرت تلقائياً.
  String _failNote(GameEvent e) {
    final n = failed[e];
    if (n == null) return '';
    return n >= 3 ? ' · ثالث حكومة فاشلة ورا بعض!' : ' · حكومة فاشلة ${arabicNumber(n)} من ٣';
  }

  @override
  Widget build(BuildContext context) {
    final lines = <Widget>[];
    // سطر بأيقونة مرسومة في أوله.
    Widget line(String icon, String text, [Widget? tail]) => Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Gfx(icon, size: 22),
        const SizedBox(width: 6),
        Flexible(child: Text(text)),
        ?tail,
      ],
    );
    Policy? enacted;
    for (final e in events) {
      final d = e.data;
      switch (e.type) {
        case 'nominated':
          lines.add(line('crown', '${name(d['president'] as String)} رشّح ${name(d['chancellor'] as String)} وزير'));
        case 'voteResult':
          final votes = Map<String, bool>.from(d['votes'] as Map);
          final weights = {
            for (final MapEntry(:key, :value) in ((d['weights'] as Map?) ?? const {}).entries)
              key as String: (value as num).toInt(),
          };
          final judge = d['cancelledBy'] as String?;
          lines.add(
            judge != null
                ? line('scales', 'القاضي ${name(judge)} ألغى التصويت، والحكومة سقطت${_failNote(e)}')
                : d['passed'] == true
                ? line('check', 'الحكومة انتخبت')
                : line('cross', 'الحكومة رُفضت${_failNote(e)}'),
          );
          lines.add(
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final MapEntry(:key, :value) in votes.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: value
                          ? const Color(0xFF3E9B3C).withValues(alpha: .2)
                          : const Color(0xFFD23A2E).withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: value ? const Color(0xFF2E7A2C) : const Color(0xFFB02A1E), width: 1.4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Gfx(value ? 'check' : 'cross', size: 14),
                        const SizedBox(width: 3),
                        Text(
                          (weights[key] ?? 1) > 1 ? '${name(key)} ×${arabicNumber(weights[key]!)}' : name(key),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: value ? const Color(0xFF1D5E1F) : const Color(0xFF8E1A12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        case 'enacted':
          enacted = Policy.parse(d['policy']);
          final chaos = d['chaos'] == true;
          lines.add(
            line(
              chaos ? 'chaos' : 'scales',
              chaos ? 'فوضى! ٣ حكومات فاشلة ورا بعض، فتمرر أول كرت بالكومة تلقائياً: ' : 'تمرر: ',
              MiniPolicies([enacted]),
            ),
          );
        case 'claim':
          final c = d['claim'] as Map;
          lines.add(
            line(
              'megaphone',
              '${name(c['by'] as String)} ${c['office'] == 'president' ? '(الرئيس)' : '(الوزير)'} ادّعى ',
              MiniPolicies([for (final p in c['policies'] as List) Policy.parse(p)]),
            ),
          );
        case 'vetoed':
          final gov = (d['government'] as Map?) ?? const {};
          final who = gov['chancellor'] is String && gov['president'] is String
              ? 'الوزير ${name(gov['chancellor'] as String)} طلب فيتو ووافق الرئيس ${name(gov['president'] as String)}'
              : 'الوزير طلب فيتو ووافق الرئيس';
          lines.add(line('hand', '$who: انرمت الكروت كلها بدون قرار${_failNote(e)}'));
        case 'vetoRejected':
          lines.add(line('cross', 'الرئيس رفض الفيتو، والوزير لازم يمرر قرار'));
        case 'investigated':
          lines.add(line('search', '${name(d['by'] as String)} حقق مع ${name(d['target'] as String)}'));
        case 'peeked':
          lines.add(line('eye', '${name(d['by'] as String)} تلصص على الكروت'));
        case 'specialElection':
          lines.add(line('ballot', '${name(d['by'] as String)} اختار ${name(d['target'] as String)} رئيس'));
        case 'executed':
          lines.add(line('dagger', '${name(d['by'] as String)} طرد ${name(d['target'] as String)}'));
        case 'guarded':
          lines.add(
            line('shield', '${name(d['by'] as String)} حاول يطرد ${name(d['target'] as String)}، ونجا لأنه حارس'),
          );
        case 'gameOver':
          final why = switch (d['reason']) {
            'loyalPolicies' => ': تمررت ٥ قرارات زرقاء',
            'traitorPolicies' => ': تمررت ٦ قرارات حمراء',
            'leaderElected' => ': انتخبوا الزعيم وزير بعد ٣ قرارات حمراء',
            'leaderExecuted' => ': انطرد الزعيم',
            _ => '',
          };
          lines.add(line('trophy', '${d['winner'] == 'loyal' ? 'فاز الأوفياء' : 'فاز الخونة'}$why'));
      }
    }

    final pres = claims.where((c) => c.president).firstOrNull;
    final chan = claims.where((c) => !c.president).firstOrNull;
    final contradiction = pres != null && chan != null && claimsContradict(pres.policies, chan.policies, enacted);

    return ParchmentCard(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GoldRibbonLabel('الجولة ${arabicNumber(round)}', size: 15),
            const SizedBox(height: 6),
            for (final l in lines) Padding(padding: const EdgeInsets.only(bottom: 4), child: l),
            if (contradiction)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFC8302E), Color(0xFF8E1C1C)],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: gameInk, width: 2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Gfx('warning', size: 20),
                    SizedBox(width: 6),
                    Text(
                      'تناقض! واحد منهم يكذب',
                      style: TextStyle(color: Color(0xFFFFF3DA), fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
