import 'package:flutter/material.dart';

import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'game_screen.dart';

/// أدوات المطور: يجرّب فيها كل شي بسرعة. تطلع بس لحساب مطور، والسيرفر يتأكد بنفسه.
class DevScreen extends StatefulWidget {
  const DevScreen({super.key});

  @override
  State<DevScreen> createState() => _DevScreenState();
}

class _DevScreenState extends State<DevScreen> {
  bool _busy = false;
  double _level = 1;
  int _players = 5;
  String? _role;
  String? _special;

  Future<void> _run(String done, Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// لعبة تدريب بعدد اللاعبين اللي تبيه، وبالدور اللي تختاره.
  Future<void> _practice() async {
    final backend = Backend.instance;
    final navigator = Navigator.of(context);
    String? code;
    await _run('بدأت اللعبة', () async {
      code = await backend.createRoom(maxPlayers: _players);
      for (var i = 1; i < _players; i++) {
        await backend.addBots(code!);
      }
      await backend.startGame(code!);
      if (_role != null || _special != null) {
        await backend.devTool('forceRole', {'code': code, 'role': ?_role, 'special': ?_special});
      }
    });
    if (code != null && mounted) navigator.push(MaterialPageRoute(builder: (_) => GameScreen(code: code!)));
  }

  @override
  Widget build(BuildContext context) {
    final backend = Backend.instance;
    Widget tool(String label, String done, Future<void> Function() job, {ButtonTone tone = ButtonTone.purple}) =>
        GameButton(label: label, tone: tone, height: 44, fontSize: 15, onPressed: _busy ? null : () => _run(done, job));
    Widget chips(String title, List<(String?, String)> options, String? value, ValueChanged<String?> onPick) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (v, label) in options)
              ChoiceChip(label: Text(label), selected: value == v, onSelected: (_) => setState(() => onPick(v))),
          ],
        ),
      ],
    );

    return NightScaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [Gfx('tools', size: 30), SizedBox(width: 8), Text('وضع المطور')],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // حسابك
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 16),
                children: [
                  const Text(
                    'حسابك',
                    style: TextStyle(fontFamily: kufi, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: tool('+١٠٬٠٠٠ ذهب', 'انضاف الذهب', () => backend.devTool('grant', {'coins': 10000})),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: tool('+٥٠٠ جوهرة', 'انضافت الجواهر', () => backend.devTool('grant', {'diamonds': 500})),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('المستوى: ${arabicNumber(_level.round())}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Slider(
                    value: _level,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: AppColors.gold,
                    onChanged: (v) => setState(() => _level = v),
                  ),
                  tool('حط المستوى', 'تغيّر المستوى', () => backend.devTool('level', {'level': _level.round()})),
                  const SizedBox(height: 8),
                  tool('افتح كل أغراض المتجر', 'انفتح كل شي', () => backend.devTool('unlockAll')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: tool(
                          '+٣ درجات بالباتل باس',
                          'انضافت نقاط الموسم',
                          () => backend.devTool('passPoints', {'points': 450}),
                          tone: ButtonTone.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: tool(
                          'توّج أبطال الأسبوع الحين',
                          'تتوّجوا الأبطال',
                          () => backend.devTool('crown'),
                          tone: ButtonTone.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: tool(
                          'صفّر الهدية اليومية',
                          'تقدر تستلم الهدية',
                          () => backend.devTool('resetDaily'),
                          tone: ButtonTone.ghost,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: tool(
                          'شيل العقوبة',
                          'انشالت العقوبة',
                          () => backend.devTool('unban'),
                          tone: ButtonTone.ghost,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // لعبة تجربة
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
                children: [
                  const Text(
                    'لعبة تجربة',
                    style: TextStyle(fontFamily: kufi, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  chips('عدد اللاعبين', [for (var n = 5; n <= 10; n++) ('$n', arabicNumber(n))], '$_players', (v) {
                    _players = int.parse(v!);
                  }),
                  const SizedBox(height: 10),
                  chips(
                    'دورك',
                    const [(null, 'عشوائي'), ('loyal', 'وفي'), ('traitor', 'خاين'), ('leader', 'زعيم')],
                    _role,
                    (v) => _role = v,
                  ),
                  const SizedBox(height: 10),
                  chips(
                    'دور خاص',
                    const [(null, 'بدون'), ('seer', 'العرّاف'), ('guardian', 'الحارس')],
                    _special,
                    (v) => _special = v,
                  ),
                  const SizedBox(height: 14),
                  GameButton(
                    label: 'ابدأ لعبة مع بوتات',
                    icon: const Gfx('bot', size: 28),
                    onPressed: _busy ? null : _practice,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'العرّاف والحارس يخلّونك وفي تلقائياً.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
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
