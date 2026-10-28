import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/missions.dart';
import '../models/leaderboard.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/links.dart';
import '../services/music.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/daily_reward.dart';
import '../widgets/fx.dart';
import '../widgets/gifts.dart';
import '../widgets/majlis.dart';
import '../widgets/ui.dart';
import '../widgets/weekend.dart';
import '../models/events.dart';
import 'clans_screen.dart';
import 'friends_screen.dart';
import 'how_to_play_screen.dart';
import 'leaderboard_screen.dart';
import 'missions_screen.dart';
import 'mode_screen.dart';
import 'pass_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'tournament_screen.dart';
import 'wardrobe_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _push(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  /// اللعب (عشوائي أو خاص): اللاعب الجديد يتعلم أول (الشرح الإجباري)، وبعدها يختار الطور.
  Future<void> _play(BuildContext context, ModePurpose purpose) async {
    if (!await ensureOnboarded(context) || !context.mounted) return;
    _push(context, ModeScreen(purpose: purpose));
  }

  /// المهام: تفتح على أول تبويب فيه شي جاهز للاستلام.
  void _openMissions(BuildContext context) {
    final p = Backend.instance.profile.value;
    final tab = p.claimableMissions > 0
        ? 0
        : weeklyMissions.any(p.passMissions.isClaimable)
        ? 1
        : seasonMissions.any(p.passMissions.isClaimable)
        ? 2
        : 0;
    _push(context, MissionsScreen(tab: tab));
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
                          _Header(onGift: () => showDailyReward(context), onMissions: () => _openMissions(context)),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 10, child: _Hero(onPlay: () => _play(context, ModePurpose.random))),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 11,
                                  // الخاص فوق بالعرض، وتحته الديوان والموسم والمتجر.
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: _Tile(
                                          icon: 'friends',
                                          title: 'خاص',
                                          subtitle: 'روم مع أصحابك، وتقدر تضيف بوتات',
                                          colors: const [Color(0xFF2FBF71), Color(0xFF145C38)],
                                          shadow: const Color(0xFF0B3A22),
                                          onTap: () => _play(context, ModePurpose.private),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        flex: 3,
                                        child: ValueListenableBuilder(
                                          valueListenable: Backend.instance.profile,
                                          builder: (context, p, _) => Row(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                // ديوانك (أو تدخل واحد)، والشارة لو وصلتك دعوة لديوان.
                                                child: _Tile(
                                                  icon: 'shield',
                                                  title: 'الديوان',
                                                  subtitle: p.clan?.name ?? 'ادخل ديوان',
                                                  badge: p.clan == null && p.clanInvites.isNotEmpty,
                                                  colors: const [Color(0xFF4F7CF7), Color(0xFF1E3A8A)],
                                                  shadow: const Color(0xFF14254F),
                                                  onTap: () => _push(context, const ClansScreen()),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: _Tile(
                                                  icon: 'pass',
                                                  title: 'الموسم',
                                                  subtitle: 'الدرجة ${arabicNumber(p.pass.tier)}',
                                                  badge: p.pass.claimable,
                                                  colors: const [Color(0xFF14B8A6), Color(0xFF134E4A)],
                                                  shadow: const Color(0xFF062F2C),
                                                  onTap: () => _push(context, const PassScreen()),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: _Tile(
                                                  icon: 'shop',
                                                  title: 'المتجر',
                                                  subtitle: 'إطارات وشخصيات',
                                                  colors: const [Color(0xFFE0458B), Color(0xFF7A1A4E)],
                                                  shadow: const Color(0xFF45102C),
                                                  onTap: () => _push(context, const ShopScreen()),
                                                ),
                                              ),
                                            ],
                                          ),
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
                    onTour: () async {
                      if (await ensureOnboarded(context) && context.mounted) _push(context, const TournamentScreen());
                    },
                    onRank: () => _push(context, const LeaderboardScreen()),
                    onFriends: () => _push(context, FriendsScreen.forProfile(Backend.instance.profile.value)),
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

class _Header extends StatelessWidget {
  const _Header({required this.onGift, required this.onMissions});

  final VoidCallback onGift;
  final VoidCallback onMissions;

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
          _TopIcon(
            icon: 'gift',
            label: p.dailyAvailable ? 'هديتك اليومية جاهزة' : 'الهدية اليومية: تعال بكرة',
            ready: p.dailyAvailable && Backend.instance.isReady,
            onTap: onGift,
          ),
          const SizedBox(width: 6),
          _TopIcon(
            icon: 'missions',
            // اليومية والأسبوعية والموسم كلها تنحسب في الرقم.
            label: 'المهام',
            count: p.claimableMissions + p.claimablePassMissions,
            onTap: onMissions,
          ),
          const SizedBox(width: 8),
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

/// البطاقة الكبيرة: مجلسك (أنت قاعد على مسندك وقدامك القهوة) وزر "العب الحين".
class _Hero extends StatelessWidget {
  const _Hero({required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: .45), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: MajlisRoom()),
          // يغمّق فوق (عشان الكلام) وتحت (عشان الزر).
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: .45), Colors.transparent, Colors.black.withValues(alpha: .5)],
                  stops: const [0, .45, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // نهاية الأسبوع: الذهب مضاعف (وإلا «الأكثر لعباً»).
                MinuteTicker(
                  builder: (context, now) => Weekend.at(now).on
                      ? const WeekendChip()
                      : Container(
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
                ),
                const SizedBox(height: 4),
                const Text(
                  'عشوائي',
                  style: TextStyle(fontFamily: kufi, fontSize: 26, fontWeight: FontWeight.w700, height: 1.2),
                ),
                const Text('العب أونلاين مع ناس من كل مكان', style: TextStyle(fontSize: 12, color: Color(0xFFD9CFFF))),
                const Expanded(child: _MeSitting()),
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

/// أنت قاعد على مسندك في المجلس (بشخصيتك وإطارك)، وقدامك الدلة والفناجيل.
class _MeSitting extends StatelessWidget {
  const _MeSitting();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Backend.instance.profile,
    builder: (context, p, _) => LayoutBuilder(
      builder: (context, box) {
        // المسند ما يطلع فوق على الكلام.
        final av = math.min(box.maxHeight * .7, 104.0);
        final cx = box.maxWidth / 2, cy = box.maxHeight * .55;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: cx - av * .78,
              top: cy - av * .66,
              child: Cushion(width: av * 1.56, height: av * 1.04),
            ),
            Positioned(
              left: cx - av / 2,
              top: cy - av / 2,
              child: PlayerAvatar(
                avatar: p.avatar,
                style: frameStyle(p.frame),
                frame: frameStyle(p.frame) == null ? AppColors.gold : null,
                size: av,
              ),
            ),
            Positioned(
              left: cx - av * 1.55,
              top: cy + av * .02,
              child: CoffeeSet(width: av * .82),
            ),
            Positioned(
              left: cx + av * .78,
              top: cy - av * .2,
              child: Censer(width: av * .22),
            ),
            // تضغط على نفسك: غرفة التبديل (كل اللي تملكه بمكان واحد).
            Positioned(
              left: cx - av * .78,
              top: cy - av * .66,
              width: av * 1.56,
              height: av * 1.2,
              child: Semantics(
                button: true,
                label: 'غرفة التبديل',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WardrobeScreen())),
                ),
              ),
            ),
            Positioned(
              left: cx + av * .36,
              top: cy + av * .2,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.panel.withValues(alpha: .9),
                    border: Border.all(color: AppColors.gold, width: 1.5),
                  ),
                  child: const Gfx('edit', size: 16),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
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
          // الأيقونة تكبر على قد البطاقة ووراها هالة خفيفة. البطاقة العريضة (الخاص): الأيقونة جنب الاسم.
          child: LayoutBuilder(
            builder: (context, box) {
              Widget glow(double size) => Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: size * 1.55,
                    height: size * 1.55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.white.withValues(alpha: .22), Colors.white.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                  Gfx(icon, size: size),
                  if (badge)
                    PositionedDirectional(
                      top: size * .2,
                      end: size * .2,
                      child: const CircleAvatar(radius: 7, backgroundColor: AppColors.traitor),
                    ),
                ],
              );
              if (box.maxWidth > box.maxHeight * 2) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    glow((box.maxHeight * .6).clamp(40.0, 84.0)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 22),
                          ),
                          if (subtitle != null)
                            Text(subtitle!, style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                );
              }
              final big = box.maxHeight > 200;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  glow((box.maxHeight * .34).clamp(46.0, 96.0)),
                  SizedBox(height: big ? 4 : 0),
                  Text(
                    title,
                    style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: big ? 19 : 15),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: big ? 12.5 : 10.5, color: Colors.white70),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// أيقونة صغيرة فوق جنب الفلوس (الهدية اليومية والمهام). [ready]: تتوهج وتهتز شوي (فيه شي جاهز)،
/// و[count]: رقم أحمر (كم شي جاهز للاستلام).
class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon, required this.label, required this.onTap, this.ready = false, this.count = 0});

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool ready;
  final int count;

  @override
  Widget build(BuildContext context) {
    final lit = ready || count > 0;
    final circle = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: .35),
        border: Border.all(
          color: lit ? AppColors.gold.withValues(alpha: .85) : Colors.white.withValues(alpha: .12),
          width: 1.5,
        ),
      ),
      child: Opacity(opacity: lit ? 1 : .6, child: Gfx(icon, size: 27)),
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
                    color: AppColors.gold.withValues(alpha: .25 + .25 * (.5 + .5 * math.sin(t * 3))),
                    blurRadius: 12,
                    spreadRadius: 1,
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
                PositionedDirectional(
                  top: -4,
                  end: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.traitor,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.bg, width: 1.5),
                    ),
                    child: Text(
                      arabicNumber(count),
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, height: 1.1),
                    ),
                  ),
                )
              else if (ready)
                PositionedDirectional(
                  top: -1,
                  end: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.traitor,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شريط التنقل على الجنب (بالعرض)، بدال الشريط اللي تحت.
class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.onTour,
    required this.onRank,
    required this.onFriends,
    required this.onProfile,
    required this.onGuide,
  });

  final VoidCallback onTour;
  final VoidCallback onRank;
  final VoidCallback onFriends;
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: on ? AppColors.gold.withValues(alpha: .16) : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Opacity(opacity: on ? 1 : .75, child: Gfx(icon, size: 30)),
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
          MinuteTicker(
            builder: (context, now) => ValueListenableBuilder(
              valueListenable: Backend.instance.profile,
              builder: (context, p, _) {
                final open = Weekend.at(now).on;
                final t = p.tour?.week == gulfWeek(now) ? p.tour : null;
                return item('trophy', 'البطولة', onTour, badge: open && (t == null || (!t.out && !t.champion)));
              },
            ),
          ),
          item('rank', 'الترتيب', onRank),
          // نقطة حمرا لو فيه طلبات صداقة أو رسائل ما قريتها
          ValueListenableBuilder(
            valueListenable: Backend.instance.profile,
            builder: (context, p, _) =>
                item('friends', 'الأصدقاء', onFriends, badge: p.friendReqs.isNotEmpty || p.unreadDms > 0),
          ),
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
