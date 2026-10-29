import 'package:flutter/material.dart';

import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/curtain_route.dart';
import '../widgets/ui.dart';
import 'game_screen.dart';
import 'moderation_screen.dart';

/// أدوات المطور: يجرّب فيها كل شي بسرعة. تطلع بس لحساب مطور، والسيرفر يتأكد بنفسه.
class DevScreen extends StatefulWidget {
  const DevScreen({super.key});

  @override
  State<DevScreen> createState() => _DevScreenState();
}

class _DevScreenState extends State<DevScreen> {
  bool _busy = false;
  final _pid = TextEditingController();

  /// المطورين اللي خليتهم (لصاحب اللعبة بس).
  List<({String name, String pid})>? _devs;

  /// الحماية من الغش مفعّلة؟ (null لين توصل من السيرفر)
  bool? _enforce;

  @override
  void initState() {
    super.initState();
    if (Backend.instance.profile.value.owner) {
      _loadDevs();
      _loadAppCheck();
    }
  }

  Future<void> _loadAppCheck([String? mode]) async {
    try {
      final data = await Backend.instance.devData('appCheck', {'mode': ?mode});
      if (mounted) setState(() => _enforce = data['mode'] == 'enforce');
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  void dispose() {
    _pid.dispose();
    super.dispose();
  }

  Future<void> _loadDevs() async {
    try {
      final data = await Backend.instance.devData('devs');
      if (!mounted) return;
      setState(
        () => _devs = [
          for (final d in (data['devs'] as List? ?? const []))
            (name: (d as Map)['name'] as String? ?? '', pid: d['pid'] as String? ?? ''),
        ],
      );
    } on BackendException catch (_) {}
  }

  /// يخلي لاعب مطوّر برمزه، أو يشيله.
  Future<void> _setDev(String pid, bool on) async {
    pid = pid.trim();
    if (pid.isEmpty) return;
    String? name;
    await _run(on ? 'صار مطوّر' : 'انشال من المطورين', () async {
      final r = await Backend.instance.devData('setDev', {'pid': pid, 'on': on});
      name = r['name'] as String?;
    });
    if (name != null) {
      _pid.clear();
      await _loadDevs();
    }
  }

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
    if (code != null && mounted) navigator.push(curtainRoute<void>((_) => GameScreen(code: code!)));
  }

  /// صاحب اللعبة: الحماية من الغش. السيرفر يقبل بس اللي جاي من التطبيق الأصلي (من قوقل بلاي) لما تتفعّل.
  Widget _appCheckPanel() => Panel(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    child: Row(
      children: [
        const Gfx('shield', size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(switch (_enforce) {
                true => 'الحماية من الغش: مفعّلة',
                false => 'الحماية من الغش: مراقبة فقط',
                null => 'الحماية من الغش',
              }, style: const TextStyle(fontFamily: kufi, fontSize: 16, fontWeight: FontWeight.w700)),
              const Text(
                'فعّلها بعد ما تنزل اللعبة على قوقل بلاي: أي طلب من نسخة معدّلة أو من برا المتجر ينرفض. '
                'أنت تستطيع أن تدخل دائماً.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: _enforce ?? false,
          activeThumbColor: AppColors.green,
          onChanged: _enforce == null || _busy ? null : (on) => _loadAppCheck(on ? 'enforce' : 'monitor'),
        ),
      ],
    ),
  );

  /// صاحب اللعبة: يخلي أي لاعب مطوّر برمزه، ويشوف المطورين ويشيلهم.
  Widget _devsPanel() => Panel(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المطورين',
          style: TextStyle(fontFamily: kufi, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const Text(
          'اكتب رمز اللاعب وخلّه مطوّر: تطلع له أدوات التجربة مثلك.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pid,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(hintText: 'رمز اللاعب', isDense: true),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: GameButton(
                label: 'خلّه مطوّر',
                tone: ButtonTone.green,
                height: 40,
                fontSize: 14,
                onPressed: _busy ? null : () => _setDev(_pid.text, true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_devs == null)
          const SizedBox.shrink()
        else if (_devs!.isEmpty)
          const Text('لا يوجد مطورين غيرك.', style: TextStyle(color: AppColors.muted, fontSize: 12.5))
        else
          for (final d in _devs!)
            Row(
              children: [
                const Gfx('tools', size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${d.name} (${d.pid})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _setDev(d.pid, false),
                  child: const Text('شيله', style: TextStyle(color: AppColors.traitorLight)),
                ),
              ],
            ),
      ],
    ),
  );

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
                          '+٣ درجات بتذكرة الموسم',
                          'انضافت نقاط الموسم',
                          () => backend.devTool('passPoints', {'points': 450}),
                          tone: ButtonTone.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: tool(
                          'توّج أبطال الأسبوع الآن',
                          'تتوّجوا الأبطال',
                          () => backend.devTool('crown'),
                          tone: ButtonTone.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GameButton(
                    label: 'البلاغات والرسائل',
                    icon: const Gfx('warning', size: 24),
                    tone: ButtonTone.red,
                    height: 44,
                    fontSize: 15,
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ModerationScreen())),
                  ),
                  if (backend.profile.value.owner) ...[
                    const SizedBox(height: 14),
                    _appCheckPanel(),
                    const SizedBox(height: 10),
                    _devsPanel(),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: tool(
                          'صفّر الهدية اليومية',
                          'تستطيع أن تستلم الهدية',
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
                    const [(null, 'عشوائي'), ('loyal', 'وفي'), ('traitor', 'خائن'), ('leader', 'زعيم')],
                    _role,
                    (v) => _role = v,
                  ),
                  const SizedBox(height: 10),
                  chips(
                    'دور خاص',
                    const [
                      (null, 'بدون'),
                      ('seer', 'العرّاف'),
                      ('guardian', 'الحارس'),
                      ('judge', 'القاضي'),
                      ('elder', 'الشيخ'),
                      ('spy', 'الجاسوس'),
                    ],
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
                    'العرّاف والحارس يخلّونك وفي تلقائياً، والقاضي والشيخ والجاسوس لأي فريق إلا الزعيم.',
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
