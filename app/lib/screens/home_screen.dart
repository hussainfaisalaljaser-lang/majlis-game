import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shop.dart';
import '../services/backend.dart';
import '../services/links.dart';
import '../services/music.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/daily_reward.dart';
import '../widgets/gifts.dart';
import '../widgets/ui.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';
import 'leaderboard_screen.dart';
import 'missions_screen.dart';
import 'pass_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'tables_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _push(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

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
            Text('نجهّز المجلس…'),
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
      body: GiftWatcher(
        child: LinkWatcher(
          child: _TutorialOffer(
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 10, 12),
                      child: Column(
                        children: [
                          const _Header(),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 10, child: _Hero(onPlay: () => _push(context, const TablesScreen()))),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 11,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                              child: ValueListenableBuilder(
                                                valueListenable: Backend.instance.profile,
                                                builder: (context, p, _) => _Tile(
                                                  icon: 'pass',
                                                  title: 'الموسم',
                                                  subtitle: 'الدرجة ${arabicNumber(p.pass.tier)}',
                                                  badge: p.pass.claimable,
                                                  colors: const [Color(0xFF14B8A6), Color(0xFF134E4A)],
                                                  shadow: const Color(0xFF062F2C),
                                                  onTap: () => _push(context, const PassScreen()),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(child: _DailyCard(onTap: () => showDailyReward(context))),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                              width: 128,
                                              child: _MissionsCard(onTap: () => _push(context, const MissionsScreen())),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _SideNav(
                    onShop: () => _push(context, const ShopScreen()),
                    onRank: () => _push(context, const LeaderboardScreen()),
                    onProfile: () => _push(context, const ProfileScreen()),
                    onGuide: () => _push(context, const HowToPlayScreen()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// لاعب جديد (ما لعب ولا خلّص الشرح): نعرض عليه الشرح مرة وحدة أول ما يوصل الرئيسية.
class _TutorialOffer extends StatefulWidget {
  const _TutorialOffer({required this.child});

  final Widget child;

  @override
  State<_TutorialOffer> createState() => _TutorialOfferState();
}

class _TutorialOfferState extends State<_TutorialOffer> {
  static const _key = 'tutorial_offered';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    Backend.instance.profile.removeListener(_renamed);
    super.dispose();
  }

  bool _renameShown = false;

  /// اسمه انغيّر لأن أكثر من لاعب بلّغوا عنه: نطلب منه يختار اسم جديد.
  Future<void> _renamed() async {
    final p = Backend.instance.profile.value;
    if (!p.renamed || _renameShown || !mounted) return;
    _renameShown = true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Gfx('warning', size: 30), SizedBox(width: 8), Text('غيّرنا اسمك')]),
        content: Text(
          'أكثر من لاعب بلّغوا إن اسمك السابق مسيء، فصار اسمك "${p.name}". اختر لك اسم جديد يناسب المجلس.',
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          GameButton(
            label: 'اختر اسم',
            height: 44,
            fontSize: 15,
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _check() async {
    final backend = Backend.instance;
    Backend.instance.profile.addListener(_renamed);
    _renamed();
    final p = backend.profile.value;
    // جاي من رابط دعوة: يدخل مع أصحابه أول، والشرح نعرضه المرة الجاية.
    if (!backend.isReady || !p.setupDone || p.tutorialDone || p.gamesPlayed > 0 || Links.pending.value != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_key) ?? false) return;
      await prefs.setBool(_key, true);
    } catch (_) {
      return;
    }
    if (mounted) await offerTutorial(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
                            style: const TextStyle(
                              fontFamily: kufi,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldInk,
                            ),
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
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          width: 90,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: p.levelProgress,
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
          CurrencyPill(icon: 'coin', amount: p.coins, infinite: p.dev),
          const SizedBox(width: 6),
          CurrencyPill(
            infinite: p.dev,
            icon: 'gem',
            amount: p.diamonds,
            onAdd: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const ShopScreen(initialTab: ShopScreen.diamondsTab))),
          ),
          const SizedBox(width: 4),
          ValueListenableBuilder(
            valueListenable: Music.muted,
            builder: (context, muted, _) => IconButton(
              tooltip: muted ? 'شغّل الموسيقى' : 'اكتم الموسيقى',
              onPressed: Music.toggle,
              icon: Gfx(muted ? 'music_off' : 'music', size: 30),
            ),
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
          for (final x in [.06, .94])
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.traitor, borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Gfx('fire', size: 14),
                      SizedBox(width: 3),
                      Text('الأكثر لعباً', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'مجلس الخونة',
                  style: TextStyle(fontFamily: kufi, fontSize: 26, fontWeight: FontWeight.w700, height: 1.2),
                ),
                const Text('٥ إلى ١٠ لاعبين', style: TextStyle(fontSize: 12, color: Color(0xFFD9CFFF))),
                const Expanded(
                  child: FittedBox(
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: SizedBox(
                        width: 230,
                        height: 100,
                        child: Stack(
                          children: [
                            Positioned(left: 0, top: 18, child: PlayerAvatar(avatar: 'pearl', size: 72)),
                            Positioned(right: 0, top: 18, child: PlayerAvatar(avatar: 'desert', size: 72)),
                            Positioned(
                              left: 65,
                              top: 0,
                              child: PlayerAvatar(avatar: 'masked', frame: AppColors.traitor, size: 96),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: GameButton(
                    label: 'العب الحين',
                    icon: const Gfx('games', size: 30),
                    semantics: 'العب الحين',
                    height: 48,
                    fontSize: 18,
                    onPressed: onPlay,
                  ),
                ),
              ],
            ),
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
    this.badge = false,
  });

  final String icon;
  final String title;
  final String? subtitle;

  /// نقطة حمراء (فيه شي جاهز يستلمه).
  final bool badge;
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
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: colors),
            border: Border.all(color: Colors.white.withValues(alpha: .25), width: 2),
            boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Gfx(icon, size: 46),
                  if (badge)
                    const PositionedDirectional(
                      top: -2,
                      end: -4,
                      child: CircleAvatar(radius: 7, backgroundColor: AppColors.traitor),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 15),
              ),
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
                      const Gfx('gift', size: 46),
                      if (available)
                        const Positioned(
                          top: -2,
                          left: -2,
                          child: CircleAvatar(radius: 6, backgroundColor: AppColors.traitor),
                        ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الهدية اليومية',
                          style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          available ? 'يوم ${arabicNumber(p.nextDailyDay)} من ٧ · جاهزة!' : 'تعال بكرة',
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: .06),
                border: Border.all(
                  color: claimable > 0 ? AppColors.gold : Colors.white.withValues(alpha: .12),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Gfx('missions', size: 24),
                      SizedBox(width: 4),
                      Text(
                        'المهام',
                        style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ],
                  ),
                  Text(
                    claimable > 0 ? '${arabicNumber(claimable)} جاهزة للاستلام' : '${arabicNumber(claimed)} من ٥',
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

/// شريط التنقل على الجنب (بالعرض)، بدال الشريط اللي تحت.
class _SideNav extends StatelessWidget {
  const _SideNav({required this.onShop, required this.onRank, required this.onProfile, required this.onGuide});

  final VoidCallback onShop;
  final VoidCallback onRank;
  final VoidCallback onProfile;
  final VoidCallback onGuide;

  @override
  Widget build(BuildContext context) {
    Widget item(String icon, String label, VoidCallback? onTap, {bool on = false, bool badge = false}) => Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: on ? AppColors.gold.withValues(alpha: .16) : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Opacity(opacity: on ? 1 : .75, child: Gfx(icon, size: 34)),
                    if (badge)
                      const PositionedDirectional(
                        top: -2,
                        end: -4,
                        child: CircleAvatar(radius: 6, backgroundColor: AppColors.traitor),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: on ? AppColors.gold : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.panel, AppColors.bg]),
        border: BorderDirectional(start: BorderSide(color: Colors.white.withValues(alpha: .08), width: 1.5)),
      ),
      child: Column(
        children: [
          item('home', 'الرئيسية', null, on: true),
          item('shop', 'المتجر', onShop),
          item('rank', 'الترتيب', onRank),
          item('profile', 'ملفي', onProfile),
          ValueListenableBuilder(
            valueListenable: Backend.instance.profile,
            builder: (context, p, _) => item('guide', 'كيف ألعب', onGuide, badge: !p.tutorialDone),
          ),
        ],
      ),
    );
  }
}
