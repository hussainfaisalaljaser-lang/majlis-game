import 'package:flutter/material.dart';

import '../models/table_tier.dart';
import '../services/backend.dart';
import '../services/telemetry.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'friends_screen.dart';
import 'waiting_screen.dart';

/// اللعب الخاص: روم لك ولأصحابك بس (بالكود أو بالدعوة)، مو مع لاعبين عشوائيين.
class PrivateScreen extends StatefulWidget {
  const PrivateScreen({super.key});

  @override
  State<PrivateScreen> createState() => _PrivateScreenState();
}

class _PrivateScreenState extends State<PrivateScreen> {
  int _playerCount = 5;
  bool _quick = false;
  bool _busy = false;

  Future<void> _open(Future<String> Function() request) async {
    if (!Backend.instance.isReady) return;
    setState(() => _busy = true);
    try {
      final code = await request();
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WaitingScreen(tier: null, playerCount: _playerCount, code: code),
        ),
      );
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinByCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Gfx('key', size: 28), SizedBox(width: 8), Text('ادخل كود روم صاحبك')]),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 5,
          textCapitalization: TextCapitalization.characters,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 6, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('دخول')),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;
    await _open(() async {
      final joined = await Backend.instance.joinRoom(code);
      Telemetry.joinRoom('code');
      return joined;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ready = Backend.instance.isReady && !_busy;
    return NightScaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gfx('friends', size: 30),
            SizedBox(width: 8),
            Text('خاص · روم مع أصحابك', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Row(
          children: [
            SizedBox(
              width: 290,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      segments: [
                        for (final n in playerCounts) ButtonSegment(value: n, label: Text('${arabicNumber(n)} لاعبين')),
                      ],
                      selected: {_playerCount},
                      onSelectionChanged: (s) => setState(() => _playerCount = s.first),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      segments: const [
                        ButtonSegment(value: false, label: Text('عادي'), icon: Gfx('hourglass', size: 18)),
                        ButtonSegment(value: true, label: Text('سريع'), icon: Gfx('bolt', size: 18)),
                      ],
                      selected: {_quick},
                      onSelectionChanged: (s) => setState(() => _quick = s.first),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _quick ? 'نص الوقت لكل دور، واللعبة حوالي ٥ دقايق' : 'الوقت العادي، واللعبة حوالي ١٠ دقايق',
                      style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                    ),
                    const Spacer(),
                    GameButton(
                      label: _busy ? 'لحظة…' : 'أنشئ روم خاص',
                      icon: const Gfx('plus', size: 26),
                      semantics: 'أنشئ روم خاص',
                      tone: ButtonTone.purple,
                      onPressed: ready
                          ? () => _open(() => Backend.instance.createRoom(maxPlayers: _playerCount, quick: _quick))
                          : null,
                    ),
                    const SizedBox(height: 10),
                    GameButton(
                      label: 'ادخل بكود صاحبك',
                      icon: const Gfx('key', size: 26),
                      semantics: 'ادخل بكود صديق',
                      tone: ButtonTone.ghost,
                      height: 46,
                      fontSize: 16,
                      onPressed: ready ? _joinByCode : null,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 16, 12),
                child: Panel(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GoldText('كيف يشتغل الروم الخاص؟', size: 19, align: TextAlign.start),
                      const SizedBox(height: 10),
                      for (final (i, (icon, text)) in const [
                        ('plus', 'أنشئ روم، ويطلع لك كود من ٥ حروف'),
                        ('friends', 'ادعُ أصحابك من قائمة الأصدقاء، أو أرسل لهم الكود بالواتساب'),
                        ('bot', 'ما اكتمل العدد؟ كمّله ببوتات وابدأ'),
                      ].indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 13,
                                backgroundColor: AppColors.gold,
                                child: Text(
                                  arabicNumber(i + 1),
                                  style: const TextStyle(color: AppColors.goldInk, fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Gfx(icon, size: 26),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      const Text(
                        'الروم الخاص ما يدخله أحد غريب، وما يحسب في التصنيف.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      ValueListenableBuilder(
                        valueListenable: Backend.instance.profile,
                        builder: (context, p, _) => TextButton.icon(
                          onPressed: () =>
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FriendsScreen())),
                          icon: const Gfx('friends', size: 22),
                          label: Text(
                            p.friends.isEmpty ? 'أضف أصحابك برمزهم' : 'أصحابك (${arabicNumber(p.friends.length)})',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
