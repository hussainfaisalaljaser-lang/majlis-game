import 'package:flutter/material.dart';

import '../models/shop.dart';
import '../services/backend.dart';
import '../services/sfx.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/daily_reward.dart';
import '../widgets/ui.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';
import 'missions_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'tables_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  /// تدريب: روم خاص فيه أنت و٤ بوتات، ويبدأ على طول.
  Future<void> _startPractice(BuildContext context) async {
    final backend = Backend.instance;
    if (!backend.isReady) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.gold),
            SizedBox(width: 16),
            Text('نجهّز المجلس… 🤖'),
          ],
        ),
      ),
    );
    try {
      final code = await backend.createRoom(maxPlayers: 5);
      for (var i = 0; i < 4; i++) {
        await backend.addBots(code);
      }
      await backend.startGame(code);
      navigator.pop();
      navigator.push(MaterialPageRoute(builder: (_) => GameScreen(code: code)));
    } on BackendException catch (e) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return NightScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
          children: [
            const _Header(),
            const SizedBox(height: 14),
            _Hero(onPlay: () => _push(context, const TablesScreen())),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Tile(
                    icon: 'friends',
                    title: 'مع أصحابك',
                    colors: const [Color(0xFF2FBF71), Color(0xFF145C38)],
                    shadow: const Color(0xFF0B3A22),
                    onTap: () => _push(context, const TablesScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Tile(
                    icon: 'bot',
                    title: 'تدريب',
                    subtitle: 'أنت و٤ بوتات',
                    colors: const [Color(0xFF7C5CFF), Color(0xFF3A1F9C)],
                    shadow: const Color(0xFF23125E),
                    onTap: () => _startPractice(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Tile(
                    icon: 'trophy',
                    title: 'الدوري',
                    colors: const [Color(0xFFF2B53A), Color(0xFF9C5E06)],
                    shadow: const Color(0xFF5C3603),
                    onTap: () => _push(context, const LeaderboardScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _DailyCard(onTap: () => showDailyReward(context))),
                const SizedBox(width: 10),
                SizedBox(width: 128, child: _MissionsCard(onTap: () => _push(context, const MissionsScreen()))),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        onShop: () => _push(context, const ShopScreen()),
        onRank: () => _push(context, const LeaderboardScreen()),
        onProfile: () => _push(context, const ProfileScreen()),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      PlayerAvatar(
                        avatar: p.avatar,
                        style: frameStyle(p.frame),
                        frame: frameStyle(p.frame) == null ? AppColors.gold : null,
                        size: 46,
                      ),
                      Positioned(
                        bottom: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(colors: [AppColors.goldLight, Color(0xFFD48B12)]),
                          ),
                          child: Text(
                            arabicNumber(p.level),
                            style: const TextStyle(fontFamily: kufi, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.goldInk),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: 90,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: p.xpInLevel / 100,
                              minHeight: 6,
                              backgroundColor: Colors.black.withValues(alpha: .4),
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          CurrencyPill(icon: '🪙', amount: p.coins),
          const SizedBox(width: 6),
          CurrencyPill(
            icon: '💎',
            amount: p.diamonds,
            onAdd: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopScreen(initialTab: 2))),
          ),
        ],
      ),
    );
  }
}

/// البطاقة الكبيرة: شخصيات المجلس وزر "العب الحين".
class _Hero extends StatelessWidget {
  const _Hero({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const RadialGradient(
          center: Alignment(-.4, -.4),
          radius: 1.2,
          colors: [Color(0xFF5B3AB0), Color(0xFF2A1B5E), Color(0xFF1A1140)],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: .45), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // فوانيس
          for (final x in [.08, .92])
            Align(
              alignment: Alignment(x * 2 - 1, -1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 1.5, height: 30, color: AppColors.gold),
                  Container(
                    width: 18,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                      boxShadow: [BoxShadow(color: AppColors.goldLight.withValues(alpha: .7), blurRadius: 16)],
                    ),
                  ),
                ],
              ),
            ),
          const Positioned(left: 14, bottom: 18, child: PlayerAvatar(avatar: 'pearl', size: 78)),
          const Positioned(left: 76, bottom: 32, child: PlayerAvatar(avatar: 'desert', size: 80)),
          const Positioned(left: 142, bottom: 46, child: PlayerAvatar(avatar: 'masked', frame: AppColors.traitor, size: 92)),
          Positioned(
            right: 18,
            top: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.traitor, borderRadius: BorderRadius.circular(8)),
                  child: const Text('🔥 الأكثر لعباً', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 6),
                const Text('مجلس\nالخونة', style: TextStyle(fontFamily: kufi, fontSize: 30, fontWeight: FontWeight.w700, height: 1.1)),
                const SizedBox(height: 4),
                const Text('٥ إلى ١٠ لاعبين', style: TextStyle(fontSize: 12, color: Color(0xFFD9CFFF))),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 14,
            width: 150,
            child: GameButton(label: '▶ العب الحين', semantics: 'العب الحين', height: 46, fontSize: 17, onPressed: onPlay),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.colors,
    required this.shadow,
    required this.onTap,
    this.subtitle,
  });

  final String icon;
  final String title;
  final String? subtitle;
  final List<Color> colors;
  final Color shadow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title ${subtitle ?? ''}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          Sfx.play('tap');
          onTap();
        },
        child: Container(
          height: 104,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: colors),
            border: Border.all(color: Colors.white.withValues(alpha: .25), width: 2),
            boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GameIcon(icon, size: 36),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 15)),
              if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 10.5, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) {
        final available = p.dailyAvailable && Backend.instance.isReady;
        return Semantics(
          button: true,
          label: available ? 'هديتك اليومية جاهزة' : 'الهدية اليومية',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(colors: [Color(0xFFC2255C), Color(0xFF5A0E33)]),
                border: Border.all(color: const Color(0x55FF9FC2), width: 2),
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const GameIcon('gift', size: 40, color: AppColors.goldLight),
                      if (available)
                        const Positioned(top: -2, left: -2, child: CircleAvatar(radius: 6, backgroundColor: AppColors.traitor)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الهدية اليومية', style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(
                          available ? 'يوم ${arabicNumber(p.nextDailyDay)} من ٧ · جاهزة!' : 'تعال بكرة 😉',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFFFD3E3)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MissionsCard extends StatelessWidget {
  const _MissionsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) {
        final claimable = p.claimableMissions;
        final claimed = p.missions.claimed.length;
        return Semantics(
          button: true,
          label: 'المهام اليومية',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 76,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: .06),
                border: Border.all(color: claimable > 0 ? AppColors.gold : Colors.white.withValues(alpha: .12), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('المهام', style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(
                    claimable > 0 ? '🎁 ${arabicNumber(claimable)} جاهزة' : '${arabicNumber(claimed)}/٥ ✦',
                    style: const TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: claimed / 5,
                      minHeight: 6,
                      backgroundColor: Colors.black.withValues(alpha: .4),
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.onShop, required this.onRank, required this.onProfile});

  final VoidCallback onShop;
  final VoidCallback onRank;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    Widget item(String icon, String label, VoidCallback? onTap, {bool on = false}) => Expanded(
          child: Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: on ? AppColors.gold.withValues(alpha: .16) : null,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: GameIcon(icon, size: 26, color: on ? AppColors.gold : AppColors.muted),
                  ),
                  const SizedBox(height: 3),
                  Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: on ? AppColors.gold : AppColors.muted)),
                ],
              ),
            ),
          ),
        );
    return Container(
      padding: EdgeInsets.fromLTRB(6, 10, 6, 10 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.panel, AppColors.bg]),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .08), width: 1.5)),
      ),
      child: Row(
        children: [
          item('home', 'الرئيسية', null, on: true),
          item('shop', 'المتجر', onShop),
          item('rank', 'الترتيب', onRank),
          item('profile', 'ملفي', onProfile),
        ],
      ),
    );
  }
}
