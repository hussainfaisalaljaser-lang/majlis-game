import 'package:flutter/material.dart';

import '../models/table_tier.dart';
import '../services/backend.dart';
import '../services/telemetry.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/design_social.dart';
import '../widgets/mode_theme.dart';
import 'friends_screen.dart';
import 'waiting_screen.dart';

/// يدخل روم صاحبه بالكود (من هني ومن صفحة اختيار الطور، لأن الطور يحدده اللي سوّى الروم).
Future<void> joinRoomByCode(BuildContext context) async {
  if (!Backend.instance.isReady) return;
  final controller = TextEditingController();
  final code = await showSocDialog<String>(
    context,
    title: 'ادخل كود روم صاحبك',
    width: 420,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          maxLength: 5,
          textCapitalization: TextCapitalization.characters,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.w800, color: socInk),
          decoration: socParchInput(hint: 'K7Q2M', dense: false),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        const SizedBox(height: 12),
        SocActions(
          children: [
            SocButton(label: 'إلغاء', tone: SocTone.grey, height: 44, fontSize: 16, onPressed: () => Navigator.pop(context)),
            SocButton(
              label: 'دخول',
              tone: SocTone.green,
              height: 44,
              fontSize: 16,
              onPressed: () => Navigator.pop(context, controller.text.trim()),
            ),
          ],
        ),
      ],
    ),
  );
  if (code == null || code.isEmpty || !context.mounted) return;
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final joined = await Backend.instance.joinRoom(code);
    Telemetry.joinRoom('code');
    navigator.push(MaterialPageRoute(builder: (_) => WaitingScreen(tier: null, playerCount: 5, code: joined)));
  } on BackendException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// اللعب الخاص: روم لك ولأصحابك بس (بالكود أو بالدعوة)، مو مع لاعبين عشوائيين. الطور اختاره قبل (mode_screen.dart).
class PrivateScreen extends StatefulWidget {
  const PrivateScreen({super.key, required this.mode});

  final ModeTheme mode;

  @override
  State<PrivateScreen> createState() => _PrivateScreenState();
}

class _PrivateScreenState extends State<PrivateScreen> {
  int _playerCount = 5;
  bool _quick = false;
  bool _busy = false;

  Future<void> _create() async {
    if (!Backend.instance.isReady) return;
    setState(() => _busy = true);
    try {
      final code = await Backend.instance.createRoom(
        maxPlayers: _playerCount,
        quick: _quick,
        roles: widget.mode.roles,
      );
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

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    return ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) => PrivateRoomView(
        mode: mode,
        playerCount: _playerCount,
        quick: _quick,
        busy: _busy,
        ready: Backend.instance.isReady && !_busy,
        friendsCount: p.friends.length,
        onCount: (n) => setState(() => _playerCount = n),
        onQuick: (q) => setState(() => _quick = q),
        onCreate: _create,
        onJoin: () => joinRoomByCode(context),
        onFriends: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FriendsScreen())),
      ),
    );
  }
}

/// شكل صفحة الروم الخاص: لوحة مخمل فيها الخيارات وأزرار الإنشاء والدخول، ولوحة خشب تشرح الطريقة.
/// ما تلمس السيرفر (تنشاف بالتصوير ببيانات تجريبية).
class PrivateRoomView extends StatelessWidget {
  const PrivateRoomView({
    super.key,
    required this.mode,
    required this.playerCount,
    required this.quick,
    required this.busy,
    required this.ready,
    required this.friendsCount,
    required this.onCount,
    required this.onQuick,
    required this.onCreate,
    required this.onJoin,
    required this.onFriends,
  });

  final ModeTheme mode;
  final int playerCount;
  final bool quick;
  final bool busy;
  final bool ready;
  final int friendsCount;
  final ValueChanged<int> onCount;
  final ValueChanged<bool> onQuick;
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  final VoidCallback onFriends;

  @override
  Widget build(BuildContext context) {
    return SocScaffold(
      title: 'خاص · روم مع أصحابك',
      icon: const Gfx('friends', size: 30),
      currency: false,
      glow: mode.glow,
      trailing: ModeChip(mode: mode, onTap: () => Navigator.of(context).maybePop()),
      body: SocTwoPanels(
        mainFlex: 10,
        sideFlex: 11,
        main: VelvetPanel(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: _FitColumn(
            children: [
              SocSegments<int>(
                options: [for (final n in playerCounts) (n, '${arabicNumber(n)} لاعبين')],
                value: playerCount,
                onChanged: onCount,
              ),
              const SizedBox(height: 8),
              SocSegments<bool>(
                options: const [(false, 'عادي'), (true, 'سريع')],
                value: quick,
                onChanged: onQuick,
              ),
              const SizedBox(height: 4),
              Text(
                quick ? 'نص الوقت لكل دور، واللعبة حوالي ٥ دقايق' : 'الوقت العادي، واللعبة حوالي ١٠ دقايق',
                textAlign: TextAlign.center,
                style: const TextStyle(color: socMuted, fontSize: 12.5, fontFamily: kufi, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ModeSummary(mode: mode),
              const Spacer(),
              SocButton(
                label: busy ? 'لحظة…' : 'أنشئ روم ${mode.name}',
                icon: const Gfx('plus', size: 26),
                semantics: 'أنشئ روم خاص',
                tone: mode.roles ? SocTone.blue : SocTone.orange,
                height: 50,
                fontSize: 19,
                onPressed: ready ? onCreate : null,
              ),
              const SizedBox(height: 8),
              SocButton(
                label: 'ادخل بكود صاحبك',
                icon: const Gfx('key', size: 26),
                semantics: 'ادخل بكود صديق',
                tone: SocTone.green,
                height: 44,
                fontSize: 17,
                onPressed: ready ? onJoin : null,
              ),
            ],
          ),
        ),
        side: WoodPanel(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: _FitColumn(
            children: [
              const GoldTitle('كيف يشتغل الروم الخاص؟', size: 22),
              const SizedBox(height: 10),
              for (final (i, (icon, text)) in const [
                ('plus', 'أنشئ روم، ويطلع لك كود من ٥ حروف'),
                ('friends', 'ادعُ أصحابك من قائمة الأصدقاء، أو أرسل لهم الكود بالواتساب'),
                ('bot', 'ما اكتمل العدد؟ كمّله ببوتات وابدأ'),
              ].indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SocPlankRow(
                    padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: goldRingColors,
                            ),
                            border: Border.all(color: const Color(0xFF3A1606), width: 2),
                          ),
                          child: Text(
                            arabicNumber(i + 1),
                            style: const TextStyle(color: AppColors.goldInk, fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 15, height: 1.1),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Gfx(icon, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            text,
                            style: const TextStyle(fontFamily: kufi, fontSize: 15, fontWeight: FontWeight.w700, color: socCream, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              const Text(
                'الروم الخاص ما يدخله أحد غريب، وما يحسب في التصنيف.',
                textAlign: TextAlign.center,
                style: TextStyle(color: socMuted, fontSize: 12.5, fontFamily: kufi, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              SocButton(
                label: friendsCount == 0 ? 'أضف أصحابك برمزهم' : 'أصحابك (${arabicNumber(friendsCount)})',
                icon: const Gfx('friends', size: 24),
                tone: SocTone.blue,
                height: 40,
                fontSize: 15,
                onPressed: onFriends,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// عمود يتمدد على طول اللوحة (الفراغ بين الأجزاء يتوزع)، ويتمرر لو المحتوى أطول من الشاشة.
class _FitColumn extends StatelessWidget {
  const _FitColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: box.maxHeight),
        child: IntrinsicHeight(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    ),
  );
}
