import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/events.dart';
import '../models/leaderboard.dart';
import '../models/missions.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/links.dart';
import '../services/music.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/daily_reward.dart';
import '../widgets/design.dart';
import '../widgets/design_icons.dart';
import '../widgets/fx.dart';
import '../widgets/gifts.dart';
import '../widgets/mode_theme.dart';
import '../widgets/ui.dart';
import '../widgets/weekend.dart';
import 'clans_screen.dart';
import 'friends_screen.dart';
import 'how_to_play_screen.dart';
import 'leaderboard_screen.dart';
import 'missions_screen.dart';
import 'pass_screen.dart';
import 'private_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'tables_screen.dart';
import 'tournament_screen.dart';
import 'wardrobe_screen.dart';

/// الرئيسية (مثل التصميم): فوق اسمك وفلوسك، وعلى اليمين شخصيتك وزر «العب» والطور،
/// وعلى اليسار الروم الخاص على المخمل وتحته كروت الديوان والموسم والمتجر.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _modeKey = 'last_mode_roles';

  /// الطور اللي بيلعبه (عشوائي أو خاص). يتذكر آخر اختيار.
  ModeTheme _mode = ModeTheme.classic;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    try {
      final roles = (await SharedPreferences.getInstance()).getBool(_modeKey) ?? false;
      if (mounted) setState(() => _mode = roles ? ModeTheme.advanced : ModeTheme.classic);
    } catch (_) {}
  }

  Future<void> _setMode(ModeTheme mode) async {
    setState(() => _mode = mode);
    try {
      await (await SharedPreferences.getInstance()).setBool(_modeKey, mode.roles);
    } catch (_) {}
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  /// اللعب (عشوائي أو خاص): اللاعب الجديد يتعلم أول (الشرح الإجباري).
  Future<void> _play(VoidCallback go) async {
    if (!await ensureOnboarded(context) || !mounted) return;
    go();
  }

  /// المهام: تفتح على أول تبويب فيه شي جاهز للاستلام.
  void _openMissions() {
    final p = Backend.instance.profile.value;
    final tab = p.claimableMissions > 0
        ? 0
        : weeklyMissions.any(p.passMissions.isClaimable)
        ? 1
        : seasonMissions.any(p.passMissions.isClaimable)
        ? 2
        : 0;
    _push(MissionsScreen(tab: tab));
  }

  /// قائمة الاختصارات (البطولة، الترتيب، الأصدقاء، ملفي، كيف ألعب، الموسيقى): تنفتح من لوح اسمك فوق.
  Future<void> _openMenu(BuildContext context) async {
    final pick = await showDialog<_MenuItem>(context: context, builder: (_) => const _MenuDialog());
    if (pick == null || !mounted) return;
    switch (pick) {
      case _MenuItem.tour:
        if (await ensureOnboarded(this.context) && mounted) _push(const TournamentScreen());
      case _MenuItem.rank:
        _push(const LeaderboardScreen());
      case _MenuItem.friends:
        _push(FriendsScreen.forProfile(Backend.instance.profile.value));
      case _MenuItem.profile:
        _push(const ProfileScreen());
      case _MenuItem.guide:
        _push(const HowToPlayScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _Backdrop(
        child: GiftWatcher(
          child: LinkWatcher(
            child: _TutorialOffer(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 12),
                  child: Column(
                    children: [
                      _Header(
                        onGift: () => showDailyReward(context),
                        onMissions: _openMissions,
                        onMenu: () => _openMenu(context),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _Hero(
                                mode: _mode,
                                onMode: _setMode,
                                onPlay: () => _play(() => _push(TablesScreen(mode: _mode))),
                                onWardrobe: () => _push(const WardrobeScreen()),
                              ),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              flex: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _PrivatePanel(
                                      onCreate: () => _play(() => _push(PrivateScreen(mode: _mode))),
                                      onCode: () => _play(() => joinRoomByCode(context)),
                                      onFriends: () => _push(FriendsScreen.forProfile(Backend.instance.profile.value)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    flex: 4,
                                    child: _Tiles(
                                      onClans: () => _push(const ClansScreen()),
                                      onPass: () => _push(const PassScreen()),
                                      onShop: () => _push(const ShopScreen()),
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
    Backend.instance.profile.addListener(_renamed);
    _renamed();
    // جاي من رابط دعوة: يدخل مع أصحابه أول، والشرح الإجباري يطلع له المرة الجاية (أو لما يضغط «العب»).
    if (Links.pending.value != null) return;
    if (mounted) await ensureOnboarded(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// خلفية الرئيسية: الخيمة من ورا (مطموسة وغامقة)، وجمر يطير لفوق.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: Image(image: AssetImage(DesignAssets.homeBg), fit: BoxFit.cover)),
      const Positioned.fill(child: ColoredBox(color: Color(0x4D160A05))),
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(radius: 1.6, colors: [Colors.transparent, Color(0xC0000000)], stops: [.45, 1]),
          ),
        ),
      ),
      const Positioned.fill(child: IgnorePointer(child: _Embers())),
      Positioned.fill(child: child),
    ],
  );
}

class _Embers extends StatelessWidget {
  const _Embers();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FxClock(builder: (context, t) => CustomPaint(painter: _EmberPainter(t))),
  );
}

/// جمرات صغيرة تطلع من تحت وتتمايل وتختفي.
class _EmberPainter extends CustomPainter {
  _EmberPainter(this.time) : super(repaint: time);

  final ValueListenable<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final p = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (var i = 0; i < 18; i++) {
      final speed = 16 + rnd(i, 1) * 24;
      final life = size.height * .75 / speed;
      final u = (t + rnd(i, 2) * life) % life / life;
      final x = rnd(i, 3) * size.width + math.sin(t * (.6 + rnd(i, 4)) + i) * 14;
      final y = size.height * (1.02 - u * .75);
      p.color = Color.lerp(
        const Color(0xFFFFC266),
        const Color(0xFFFF7A2A),
        rnd(i, 7),
      )!.withValues(alpha: math.sin(u * math.pi) * (.35 + .4 * rnd(i, 5)));
      canvas.drawCircle(Offset(x, y), 1.2 + rnd(i, 6) * 1.8, p);
    }
  }

  @override
  bool shouldRepaint(_EmberPainter old) => false;
}

/// الشريط اللي فوق (مثل التصميم): لوح اسمك على اليمين، واسم اللعبة بنص الشاشة،
/// وعلى اليسار الجواهر والذهب والهدية اليومية والمهام.
class _Header extends StatelessWidget {
  const _Header({required this.onGift, required this.onMissions, required this.onMenu});

  final VoidCallback onGift;
  final VoidCallback onMissions;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) => SizedBox(
        height: 50,
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: _ProfilePlank(profile: p, onTap: onMenu),
              ),
            ),
            const GoldTitle('مجلس الخونة', size: 33),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TopIcon(
                      icon: const ScrollIcon(size: 28),
                      // اليومية والأسبوعية والموسم كلها تنحسب في الرقم.
                      label: 'المهام',
                      count: p.claimableMissions + p.claimablePassMissions,
                      onTap: onMissions,
                    ),
                    const SizedBox(width: 8),
                    _TopIcon(
                      icon: const ChestIcon(size: 30),
                      label: p.dailyAvailable ? 'هديتك اليومية جاهزة' : 'الهدية اليومية: تعال بكرة',
                      ready: p.dailyAvailable && Backend.instance.isReady,
                      onTap: onGift,
                    ),
                    const SizedBox(width: 12),
                    CurrencyPill(icon: 'coin', amount: p.coins, infinite: p.dev),
                    const SizedBox(width: 8),
                    CurrencyPill(
                      infinite: p.dev,
                      icon: 'gem',
                      amount: p.diamonds,
                      onTap: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute(builder: (_) => const ShopScreen(initialTab: ShopScreen.diamondsTab))),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// لوح خشب فيه صورتك واسمك ومستواك وشريط الخبرة. تضغطه: قائمة الاختصارات (ملفي، الأصدقاء، الترتيب...).
class _ProfilePlank extends StatelessWidget {
  const _ProfilePlank({required this.profile, required this.onTap});

  final Profile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Semantics(
      button: true,
      label: 'القائمة: ${p.name}، المستوى ${arabicNumber(p.level)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            PlankBar(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 3, 10, 3),
              radius: 12,
              child: SizedBox(
                width: 206,
                height: 38,
                child: Row(
                  children: [
                    GoldRingAvatar(avatar: p.avatar, style: frameStyle(p.frame), size: 33),
                    const SizedBox(width: 9),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 70),
                          child: OutlinedText(p.name, size: 17, maxLines: 1, align: TextAlign.start, strokeWidth: 3),
                        ),
                        Text(
                          'مستوى ${arabicNumber(p.level)}',
                          style: const TextStyle(
                            fontFamily: kufi,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF4C24F),
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _XpBar(value: p.levelProgress),
                  ],
                ),
              ),
            ),
            // نقطة حمرا لو فيه شي جديد في القائمة (طلب صداقة، رسالة، بطولة مفتوحة، الشرح).
            PositionedDirectional(top: -3, end: -3, child: _MenuDot()),
          ],
        ),
      ),
    );
  }
}

/// شريط الخبرة: ذهب يتعبى من اليمين، وتحته النسبة.
class _XpBar extends StatelessWidget {
  const _XpBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 66,
        height: 9,
        padding: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: const Color(0xFF1A0F08),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFF4A2F1B)),
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: goldRingColors),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 2),
      Text(
        '٪${arabicNumber((value.clamp(0.0, 1.0) * 100).round())}',
        style: const TextStyle(fontFamily: kufi, fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFD9C29A), height: 1),
      ),
    ],
  );
}

/// نقطة القائمة: تظهر لو أي اختصار فيها فيه شي جديد.
class _MenuDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MinuteTicker(
    builder: (context, now) => ValueListenableBuilder(
      valueListenable: Backend.instance.profile,
      builder: (context, p, _) => _menuAlerts(p, now).any((e) => e.$2) ? const _Dot(size: 13) : const SizedBox.shrink(),
    ),
  );
}

/// أي اختصار في القائمة فيه شي ينتظرك (النقطة الحمرا): البطولة، الأصدقاء، كيف ألعب.
List<(_MenuItem, bool)> _menuAlerts(Profile p, DateTime now) {
  final t = p.tour?.week == gulfWeek(now) ? p.tour : null;
  return [
    (_MenuItem.tour, Weekend.at(now).on && (t == null || (!t.out && !t.champion))),
    (_MenuItem.friends, p.friendReqs.isNotEmpty || p.unreadDms > 0),
    (_MenuItem.guide, !p.tutorialDone),
  ];
}

/// زر دائري فوق جنب الفلوس (الهدية اليومية والمهام). [ready]: يتوهج ويهتز شوي (فيه شي جاهز)،
/// و[count]: رقم أحمر (كم شي جاهز للاستلام).
class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon, required this.label, required this.onTap, this.ready = false, this.count = 0});

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool ready;
  final int count;

  @override
  Widget build(BuildContext context) {
    final lit = ready || count > 0;
    final circle = GoldCircle(
      size: 42,
      child: Opacity(opacity: lit ? 1 : .75, child: icon),
    );
    Widget body = circle;
    if (ready) {
      // توهج ذهبي ينبض، وكل ثلاث ثواني الهدية تهتز.
      body = FxClock(
        builder: (context, time) => AnimatedBuilder(
          animation: time,
          child: circle,
          builder: (context, child) {
            final t = time.value;
            final wiggle = t % 3 < .5 ? math.sin(t % 3 * math.pi * 6) * .14 * (1 - t % 3 * 2) : 0.0;
            return DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: .3 + .3 * (.5 + .5 * math.sin(t * 3))),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Transform.rotate(angle: wiggle, child: child),
            );
          },
        ),
      );
    }
    return Semantics(
      button: true,
      label: count > 0 ? '$label: ${arabicNumber(count)} جاهزة' : label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              body,
              if (count > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 19),
                    height: 19,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8352A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2A0B05), width: 2),
                    ),
                    child: Text(
                      arabicNumber(count),
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, height: 1.1),
                    ),
                  ),
                )
              else if (ready)
                const Positioned(top: -2, right: -2, child: _Dot()),
            ],
          ),
        ),
      ),
    );
  }
}

/// نقطة حمرا: فيه شي جديد أو جاهز للاستلام.
class _Dot extends StatelessWidget {
  const _Dot({this.size = 13});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFFD8352A),
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFF2A0B05), width: 2),
    ),
  );
}

/// شخصيتك وزر «العب» (أونلاين مع ناس من كل مكان)، وتحته الطور.
class _Hero extends StatelessWidget {
  const _Hero({required this.mode, required this.onMode, required this.onPlay, required this.onWardrobe});

  final ModeTheme mode;
  final ValueChanged<ModeTheme> onMode;
  final VoidCallback onPlay;
  final VoidCallback onWardrobe;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 5, child: _Me(onWardrobe: onWardrobe)),
        // زر العب والسطر والطور: يصغرون مع بعض لو الشاشة قصيرة.
        Expanded(
          flex: 3,
          child: LayoutBuilder(
            builder: (context, box) => FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: box.maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: box.maxWidth * .82,
                      child: GameButton(label: 'العب', semantics: 'العب الحين', height: 74, fontSize: 40, onPressed: onPlay),
                    ),
                    // نهاية الأسبوع: الذهب مضاعف.
                    SizedBox(
                      height: 30,
                      child: Center(
                        child: MinuteTicker(
                          builder: (context, now) => Weekend.at(now).on
                              ? const WeekendChip(compact: true)
                              : const Text(
                                  'مع ناس من كل الخليج',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFF6E2BC)),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(width: box.maxWidth * .76, child: _ModeToggle(mode: mode, onChanged: onMode)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// شخصيتك بحلقة الذهب وورها ضو وأشعة تدور، واسمك على لوح تحتها، وزر غرفة التبديل بالزاوية.
class _Me extends StatelessWidget {
  const _Me({required this.onWardrobe});

  final VoidCallback onWardrobe;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Backend.instance.profile,
    builder: (context, p, _) => LayoutBuilder(
      builder: (context, box) {
        final av = math.min((box.maxHeight - 70) / 1.15, box.maxWidth * .46).clamp(40.0, 150.0);
        final glow = av * .75;
        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: -glow,
                      top: -glow,
                      right: -glow,
                      bottom: -glow,
                      child: const IgnorePointer(child: _HeroGlow()),
                    ),
                    // تضغط على نفسك: غرفة التبديل (كل اللي تملكه بمكان واحد).
                    Semantics(
                      button: true,
                      label: 'غرفة التبديل',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: onWardrobe,
                        child: GoldRingAvatar(avatar: p.avatar, style: frameStyle(p.frame), size: av, gems: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PlankBar(
                  gold: true,
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 6),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: box.maxWidth * .7),
                    child: OutlinedText(p.name, size: 22, maxLines: 1, strokeWidth: 3.5),
                  ),
                ),
              ],
            ),
            PositionedDirectional(
              top: 10,
              start: 4,
              child: Semantics(
                button: true,
                label: 'غرفة التبديل',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onWardrobe,
                  child: const Column(
                    children: [
                      GoldCircle(size: 40, child: Gfx('cat_frame', size: 27)),
                      SizedBox(height: 2),
                      OutlinedText('غرفة\nالتبديل', size: 11.5, strokeWidth: 3, maxLines: 2),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _HeroGlow extends StatelessWidget {
  const _HeroGlow();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FxClock(builder: (context, t) => CustomPaint(painter: _RaysPainter(t))),
  );
}

/// ضو دافي ينبض ورا شخصيتك، وفوقه أشعة تدور ببطء.
class _RaysPainter extends CustomPainter {
  _RaysPainter(this.time) : super(repaint: time);

  final ValueListenable<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final t = time.value;
    final area = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFC56B).withValues(alpha: .34 + .08 * math.sin(t * 2)), const Color(0x00FFC56B)],
        ).createShader(area),
    );
    const n = 14;
    final rays = Path();
    for (var i = 0; i < n; i++) {
      final a = t * .12 + i * 2 * math.pi / n;
      rays
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - .105) * r, c.dy + math.sin(a - .105) * r)
        ..lineTo(c.dx + math.cos(a + .105) * r, c.dy + math.sin(a + .105) * r)
        ..close();
    }
    canvas.drawPath(
      rays,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x55FFE7A8), Color(0x10FFE7A8)],
          stops: [.3, 1],
        ).createShader(area),
    );
  }

  @override
  bool shouldRepaint(_RaysPainter old) => false;
}

/// اختيار الطور: الكلاسيكي أو المطوّر (للعشوائي والخاص).
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final ModeTheme mode;
  final ValueChanged<ModeTheme> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFF1A0F08).withValues(alpha: .92),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF5A3B22), width: 2),
    ),
    child: Row(
      children: [
        for (final m in const [ModeTheme.classic, ModeTheme.advanced])
          Expanded(
            child: Semantics(
              button: true,
              selected: m == mode,
              label: 'الطور ${m.name}',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: m == mode
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFC266), Color(0xFFF08A1C), Color(0xFFC4610C)],
                          ),
                          border: Border.all(color: const Color(0xFF5A2C02), width: 1.5),
                        )
                      : null,
                  child: m == mode
                      ? OutlinedText(m.name, size: 15, stroke: const Color(0xFF5A2C02), strokeWidth: 3)
                      : Text(
                          m.name,
                          style: const TextStyle(
                            fontFamily: kufi,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFCDB590),
                          ),
                        ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// الروم الخاص على المخمل: تسوي روم لربعك (أو تدخل روم صاحبك بكوده)، وجنبه صور أصحابك.
class _PrivatePanel extends StatelessWidget {
  const _PrivatePanel({required this.onCreate, required this.onCode, required this.onFriends});

  final VoidCallback onCreate;
  final VoidCallback onCode;
  final VoidCallback onFriends;

  @override
  Widget build(BuildContext context) {
    return VelvetPanel(
      padding: const EdgeInsetsDirectional.fromSTEB(22, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GoldTitle('روم خاص', size: 38, align: TextAlign.start),
                  const Text(
                    'العب مع ربعك بس',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFF6E2BC)),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 150,
                        child: GameButton(
                          label: 'سوّ روم',
                          semantics: 'سوّ روم خاص',
                          tone: ButtonTone.green,
                          height: 50,
                          fontSize: 24,
                          onPressed: onCreate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // الدخول بكود صاحبك (دائرة صغيرة جنب زر السوّ).
                      Semantics(
                        button: true,
                        label: 'ادخل روم صاحبك بالكود',
                        excludeSemantics: true,
                        child: Tooltip(
                          message: 'ادخل بكود',
                          child: GestureDetector(onTap: onCode, child: const GoldCircle(size: 40, child: Gfx('key', size: 24))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(flex: 8, child: _FriendFaces(onAdd: onFriends)),
        ],
      ),
    );
  }
}

/// صور أول ثلاث من أصحابك (ولو ما عندك أصحاب، شخصيات من اللعبة)، ودائرة «+» تضيف أصحاب.
class _FriendFaces extends StatefulWidget {
  const _FriendFaces({required this.onAdd});

  final VoidCallback onAdd;

  @override
  State<_FriendFaces> createState() => _FriendFacesState();
}

class _FriendFacesState extends State<_FriendFaces> {
  /// ملفات الأصحاب العامة (تنجاب مرة وحدة بالجلسة).
  static final _cache = <String, LeaderboardEntry?>{};

  /// شخصيات من اللعبة لو ما عنده أصحاب.
  static const List<(String, FrameStyle?)> _stand = [('jasmine', null), ('falcon', null), ('youth', null)];

  void _fetch(String uid) {
    if (_cache.containsKey(uid)) return;
    _cache[uid] = null;
    Backend.instance.fetchPlayer(uid).then((e) {
      _cache[uid] = e;
      if (mounted) setState(() {});
    }, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Backend.instance.profile,
    builder: (context, p, _) {
      final uids = p.friends.take(3).toList();
      uids.forEach(_fetch);
      final friends = <(String, FrameStyle?)>[
        for (final uid in uids)
          if (_cache[uid] case final e?) (e.avatar, frameStyle(e.frame)),
      ];
      final faces = friends.isEmpty ? _stand : friends;
      // الكبير بالنص والصغار على جنبه (الترتيب: يسار، نص، يمين).
      final spots = switch (faces.length) {
        1 => [(130.0, 60.0, 91.0)],
        2 => [(88.0, 62.0, 71.0), (172.0, 56.0, 91.0)],
        _ => [(47.0, 62.0, 71.0), (213.0, 62.0, 71.0), (130.0, 56.0, 91.0)],
      };
      final order = faces.length >= 3 ? [faces[0], faces[2], faces[1]] : faces;
      return Semantics(
        button: true,
        label: 'أصحابي',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onAdd,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 320,
              height: 116,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final (i, (x, y, size)) in spots.indexed)
                    Positioned(
                      left: x - size * .57,
                      top: y - size * .57,
                      child: GoldRingAvatar(
                        avatar: order[i].$1,
                        style: order[i].$2,
                        size: size,
                        animate: false,
                      ),
                    ),
                  const Positioned(left: 262, top: 28, child: _AddCircle()),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// دائرة منقطة فيها «+» (تضيف أصحاب).
class _AddCircle extends StatelessWidget {
  const _AddCircle();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 48,
    height: 48,
    child: CustomPaint(
      painter: _DashedCirclePainter(),
      child: const Center(
        child: Text(
          '+',
          style: TextStyle(fontFamily: kufi, fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFFF4C24F), height: 1),
        ),
      ),
    ),
  );
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1.5;
    canvas.drawCircle(c, r, Paint()..color = const Color(0x8C1E0D0A));
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE8B54E);
    const n = 12;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, math.pi / n * 1.1, false, dash);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => false;
}

/// كروت الرق: الديوان والموسم والمتجر.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.onClans, required this.onPass, required this.onShop});

  final VoidCallback onClans;
  final VoidCallback onPass;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Backend.instance.profile,
    builder: (context, p, _) => Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          // ديوانك (أو تدخل واحد)، والنقطة لو وصلتك دعوة لديوان.
          child: _ParchTile(
            icon: const ShieldSwordsIcon(size: 64),
            title: 'الديوان',
            subtitle: p.clan?.name ?? 'ادخل ديوان',
            badge: p.clan == null && p.clanInvites.isNotEmpty,
            onTap: onClans,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ParchTile(
            icon: const ChestIcon(size: 64),
            title: 'الموسم',
            subtitle: 'المرحلة ${arabicNumber(p.pass.tier)} من ${arabicNumber(season.tiers)}',
            badge: p.pass.claimable,
            onTap: onPass,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ParchTile(
            icon: const StallIcon(size: 64),
            title: 'المتجر',
            subtitle: 'عروض جديدة',
            tag: 'جديد',
            onTap: onShop,
          ),
        ),
      ],
    ),
  );
}

/// كرت رق: أيقونة كبيرة بالنص، واسم بالبني، وسطر صغير تحته. [tag]: شارة حمرا مائلة بالزاوية (مثل «جديد»).
class _ParchTile extends StatelessWidget {
  const _ParchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = false,
    this.tag,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// نقطة حمراء (فيه شي جاهز يستلمه).
  final bool badge;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title $subtitle',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ParchmentCard(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final ic = (box.maxHeight * .44).clamp(34.0, 104.0);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SizedBox(width: ic, height: ic, child: FittedBox(child: icon)),
                            if (badge) PositionedDirectional(top: ic * .05, end: -ic * .05, child: const _Dot(size: 16)),
                          ],
                        ),
                        SizedBox(height: ic * .16),
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: kufi,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3A2212),
                            height: 1.1,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF6B4A2A)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (tag != null)
              Positioned(
                top: 8,
                right: -4,
                child: Transform.rotate(
                  angle: .24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF4A0F08), width: 2),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFF2563E), Color(0xFFC22A18)],
                      ),
                    ),
                    child: OutlinedText(tag!, size: 15, stroke: const Color(0xFF4A0F08), strokeWidth: 3, shadow: false),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// اختصارات القائمة (كانت الشريط الجانبي).
enum _MenuItem { tour, rank, friends, profile, guide }

/// قائمة الاختصارات: بطاقة رق وعليها شريط العنوان الأحمر، وأزرار دائرية بحلقة ذهب. تقفل وترجع الاختيار.
class _MenuDialog extends StatelessWidget {
  const _MenuDialog();

  @override
  Widget build(BuildContext context) {
    Widget item(_MenuItem key, String icon, String label, {required bool badge}) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context, key),
        child: _MenuCell(label: label, badge: badge, child: Gfx(icon, size: 34)),
      ),
    );
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: ParchmentCard(
                padding: const EdgeInsets.fromLTRB(16, 34, 16, 16),
                child: MinuteTicker(
                  builder: (context, now) => ValueListenableBuilder(
                    valueListenable: Backend.instance.profile,
                    builder: (context, p, _) {
                      final alerts = {for (final e in _menuAlerts(p, now)) e.$1: e.$2};
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          item(_MenuItem.profile, 'profile', 'ملفي', badge: false),
                          item(_MenuItem.friends, 'friends', 'الأصدقاء', badge: alerts[_MenuItem.friends] ?? false),
                          item(_MenuItem.rank, 'rank', 'الترتيب', badge: false),
                          item(_MenuItem.tour, 'trophy', 'البطولة', badge: alerts[_MenuItem.tour] ?? false),
                          item(_MenuItem.guide, 'guide', 'كيف ألعب', badge: alerts[_MenuItem.guide] ?? false),
                          ValueListenableBuilder(
                            valueListenable: Music.muted,
                            builder: (context, muted, _) => Semantics(
                              button: true,
                              label: muted ? 'شغّل الموسيقى' : 'اكتم الموسيقى',
                              excludeSemantics: true,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: Music.toggle,
                                child: _MenuCell(
                                  label: 'الموسيقى',
                                  badge: false,
                                  child: Gfx(muted ? 'music_off' : 'music', size: 34),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const RibbonTitle('القائمة', size: 22),
          ],
        ),
      ),
    );
  }
}

class _MenuCell extends StatelessWidget {
  const _MenuCell({required this.label, required this.child, required this.badge});

  final String label;
  final Widget child;
  final bool badge;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 96,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GoldCircle(size: 56, child: child),
            if (badge) const Positioned(top: -2, right: -2, child: _Dot()),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          style: const TextStyle(fontFamily: kufi, fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF3A2212), height: 1.1),
        ),
      ],
    ),
  );
}
