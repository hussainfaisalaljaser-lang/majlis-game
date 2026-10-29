import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/leaderboard.dart';
import '../models/missions.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/telemetry.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/design_season.dart';
import '../widgets/fx.dart';
import '../widgets/item_preview.dart';
import '../widgets/ui.dart';
import 'missions_screen.dart';

/// الباتل باس: مسار مجاني للكل، ومسار مدفوع فيه أغراض الموسم الخاصة.
class PassScreen extends StatefulWidget {
  const PassScreen({super.key});

  @override
  State<PassScreen> createState() => _PassScreenState();
}

class _PassScreenState extends State<PassScreen> {
  bool _busy = false;

  Future<void> _claim() async {
    setState(() => _busy = true);
    try {
      final got = await Backend.instance.claimPassRewards();
      if (!mounted) return;
      if (got.coins + got.diamonds + got.items.length == 0) return;
      await showDialog<void>(
        context: context,
        builder: (context) => SnPopup(
          title: 'استلمت!',
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SeasonRewardChips(
                profile: Backend.instance.profile.value,
                coins: got.coins,
                diamonds: got.diamonds,
                items: got.items,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 170,
                child: SnButton(label: 'تمام', tone: SnTone.green, onPressed: () => Navigator.pop(context)),
              ),
            ],
          ),
        ),
      );
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// خياري الشراء: الباتل باس (المسار المدفوع ومعه درجات هدية) أو الباتل باس كامل (كل الدرجات مفتوحة).
  /// يرجّع وش اختار: false العادي، true الكامل، null ولا شي. [owned]: عنده العادي (الكامل بالفرق بس).
  Future<bool?> _pickOption(Profile p, {required String title, bool owned = false}) => showDialog<bool>(
    context: context,
    builder: (context) => SnPopup(
      title: title,
      width: 560,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!owned) ...[
              Expanded(
                child: SeasonOption(
                  title: 'الباتل باس',
                  lines: ['المسار المدفوع وكل مكافآته', 'هدية: ${arabicNumber(season.bonusTiers)} درجات على طول'],
                  price: p.dev ? null : season.price,
                  tone: SnTone.orange,
                  onPick: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SeasonOption(
                title: 'الباتل باس كامل',
                lines: [
                  'المسار المدفوع وكل مكافآته',
                  'كل الدرجات الـ${arabicNumber(season.tiers)} مفتوحة على طول',
                  if (owned) 'تدفع الفرق بس',
                ],
                price: p.dev ? null : (owned ? season.fullPrice - season.price : season.fullPrice),
                tone: SnTone.blue,
                onPick: () => Navigator.pop(context, true),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _buy(Profile p) async {
    final owned = p.pass.premium;
    final full = await _pickOption(p, title: owned ? 'كمّل الباتل باس' : 'اشترِ الباتل باس', owned: owned);
    if (full == null) return;
    setState(() => _busy = true);
    try {
      await Backend.instance.buyPass(full: full);
      final price = full ? (owned ? season.fullPrice - season.price : season.fullPrice) : season.price;
      Telemetry.spend(full ? 'pass_full_${season.id}' : 'pass_${season.id}', 'diamonds', price);
      if (mounted) await _claim();
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// يهدي صاحب الباتل باس: يختار من أصحابه، وبعدين العادي أو الكامل.
  Future<void> _gift(Profile p) async {
    final friend = await showDialog<LeaderboardEntry>(
      context: context,
      builder: (context) => SnPopup(
        title: 'أهدِ الباتل باس لصاحبك',
        width: 460,
        child: SizedBox(
          height: 210,
          child: p.friends.isEmpty
              ? const SeasonFriendList(friends: [])
              : FutureBuilder(
                  future: Future.wait(p.friends.map(Backend.instance.fetchPlayer)),
                  builder: (context, snap) {
                    final list = [for (final e in snap.data ?? const <LeaderboardEntry?>[]) ?e];
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                    return SeasonFriendList(friends: list, onPick: (e) => Navigator.pop(context, e));
                  },
                ),
        ),
      ),
    );
    if (friend == null || !mounted) return;
    final full = await _pickOption(p, title: 'هدية لـ${friend.name}');
    if (full == null) return;
    setState(() => _busy = true);
    try {
      await Backend.instance.giftPass(friend.uid, full: full);
      Telemetry.spend(
        full ? 'gift_pass_full_${season.id}' : 'gift_pass_${season.id}',
        'diamonds',
        full ? season.fullPrice : season.price,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('أهديت ${friend.name} ${full ? 'الباتل باس كامل' : 'الباتل باس'}! بتطلع له هدية باسمك'),
          ),
        );
      }
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _missions(Profile p, {int? tab}) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MissionsScreen(
        tab:
            tab ??
            (!weeklyMissions.any(p.passMissions.isClaimable) && seasonMissions.any(p.passMissions.isClaimable) ? 2 : 1),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Backend.instance.profile,
    builder: (context, p, _) => SeasonView(
      profile: p,
      busy: _busy,
      onBuy: () => _buy(p),
      onClaim: _claim,
      onGift: () => _gift(p),
      onMissions: () => _missions(p),
      onDailyMissions: () => _missions(p, tab: 0),
    ),
  );
}

/// اسم الموسم بالعنوان: «الموسم ١» (من رقم معرّفه)، ولو ما فيه رقم نعرض اسمه كامل.
String seasonTitle() {
  final n = RegExp(r'\d+').firstMatch(season.id)?.group(0);
  return n == null ? season.name : 'الموسم ${arabicNumber(int.parse(n))}';
}

/// شاشة الموسم بدون حالة ولا سيرفر: كل شي ياخذه من ملف اللاعب وردود الفعل، فتنرسم بأي ملف (للتصوير والتجربة).
class SeasonView extends StatefulWidget {
  const SeasonView({
    super.key,
    required this.profile,
    required this.busy,
    required this.onBuy,
    required this.onClaim,
    required this.onGift,
    required this.onMissions,
    required this.onDailyMissions,
    this.now,
  });

  final Profile profile;
  final bool busy;
  final VoidCallback onBuy;
  final VoidCallback onClaim;
  final VoidCallback onGift;
  final VoidCallback onMissions;
  final VoidCallback onDailyMissions;

  /// الوقت الحالي (للتصوير بس، عشان العدّاد يطلع ثابت).
  final DateTime? now;

  @override
  State<SeasonView> createState() => _SeasonViewState();
}

class _SeasonViewState extends State<SeasonView> {
  final _scroll = ScrollController();
  bool _placed = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// أول ما تنرسم القائمة: نوقف عند الدرجة الحالية (قبلها بدرجتين عشان يبان اللي فاتت).
  void _place(double pitch) {
    if (_placed) return;
    _placed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final at = (widget.profile.pass.tier - 2).clamp(0, season.tiers) * pitch;
      _scroll.jumpTo(at.clamp(0.0, _scroll.position.maxScrollExtent));
    });
  }

  String _countdown() {
    final left = season.end.difference(widget.now ?? DateTime.now());
    if (left.isNegative) return 'انتهى الموسم';
    if (left.inDays < 1) return 'ينتهي اليوم';
    return 'ينتهي بعد ${arabicNumber(left.inDays)} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final active = season.active;
    return NightScaffold(
      appBar: SnTopBar(
        title: seasonTitle(),
        icon: const SnChest(size: 27),
        middle: [
          SnPill(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              _countdown(),
              style: const TextStyle(
                fontFamily: kufi,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                height: 1.2,
                color: Color(0xFFFFF3DA),
              ),
            ),
          ),
          SnPillButton(label: 'المهام', icon: 'missions', badge: p.claimablePassMissions, onTap: widget.onMissions),
          SnPillButton(label: 'أهدِ صاحبك', icon: 'gift', onTap: widget.busy || !active ? null : widget.onGift),
        ],
        trailing: [SnWallet(coins: p.coins, diamonds: p.diamonds, infinite: p.dev)],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, box) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: _Board(
                profile: p,
                busy: widget.busy,
                controller: _scroll,
                onPlace: _place,
                onClaim: widget.onClaim,
                onBuy: widget.onBuy,
                onDailyMissions: widget.onDailyMissions,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// نبض خفيف (يكبر ويصغر شوي) للشي اللي نبيه يلفت النظر. مع «حركات خفيفة» يوقف.
class _Breathe extends StatelessWidget {
  const _Breathe({required this.child, this.amount = .035});

  final Widget child;
  final double amount;

  @override
  Widget build(BuildContext context) => FxClock(
    builder: (context, time) => ValueListenableBuilder<double>(
      valueListenable: time,
      builder: (context, t, _) => Transform.scale(scale: 1 + amount * math.sin(t * 2.4), child: child),
    ),
  );
}

/// أحجام اللوح: بالشاشة الكبيرة [k] ١، وتصغر كل ما قصر الارتفاع (مع حدود دنيا للكلام والشرايط عشان تبقى مقروءة).
class _Dims {
  const _Dims(this.k);

  final double k;

  double get th => 110 * k;
  double get tw => 84 * k;
  double get pitch => tw + 15 * k;
  double get node => 40 * k;
  double get ropeTop => 13 * k;
  double get ropeH => node + ropeTop + 25 * k;
  double get head => math.max(28, 38 * k);
  double get label => math.max(16, 22 * k);
  double get gap => math.max(4, 6 * k);
  double get plank => math.max(32, 46 * k);
  double get missions => label + gap + plank;
  double get total => head + th * 2 + ropeH + missions;

  /// أكبر مقياس يتسع في الارتفاع [h] (ويترك شوي فراغ بين الأقسام).
  static _Dims fit(double h) {
    for (var k = 1.0; k > .45; k -= .01) {
      if (_Dims(k).total + 8 <= h) return _Dims(k);
    }
    return const _Dims(.45);
  }
}

/// اللوح الكبير (يمين): تقدّمك وزر «استلم الكل»، ومسار الجوائز (مجاني فوق وذهبي تحت وبينهم الحبل)، ومهمات اليوم.
class _Board extends StatelessWidget {
  const _Board({
    required this.profile,
    required this.busy,
    required this.controller,
    required this.onPlace,
    required this.onClaim,
    required this.onBuy,
    required this.onDailyMissions,
  });

  final Profile profile;
  final bool busy;
  final ScrollController controller;
  final void Function(double pitch) onPlace;
  final VoidCallback onClaim;
  final VoidCallback onBuy;
  final VoidCallback onDailyMissions;

  @override
  Widget build(BuildContext context) {
    final s = profile.pass;
    return WoodPanel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: LayoutBuilder(
        builder: (context, box) {
          final d = _Dims.fit(box.maxHeight);
          final k = d.k, th = d.th, ropeH = d.ropeH;
          final tabW = (30 * k).clamp(24.0, 32.0);
          onPlace(d.pitch);
          Widget tabsColumn() => SizedBox(
            width: tabW,
            child: Column(
              children: [
                SizedBox(
                  height: th,
                  child: SnSideTab(label: 'مجاني', width: tabW, fontSize: math.max(11, 14 * k)),
                ),
                SizedBox(height: ropeH),
                SizedBox(
                  height: th,
                  child: SnSideTab(label: 'ذهبي', gold: true, width: tabW, fontSize: math.max(11, 14 * k)),
                ),
              ],
            ),
          );
          return Column(
            children: [
              _Header(state: s, dev: profile.dev, busy: busy, onClaim: onClaim, onBuy: onBuy, d: d),
              const Spacer(flex: 3),
              SizedBox(
                height: th * 2 + ropeH,
                // تبويبي مجاني وذهبي على اليمين (جهة البداية)، والدرجات تمشي ناحية اليسار.
                child: Row(
                  children: [
                    tabsColumn(),
                    SizedBox(width: 8 * k),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        scrollDirection: Axis.horizontal,
                        itemExtent: d.pitch,
                        itemCount: season.tiers,
                        itemBuilder: (context, i) => _TierColumn(tier: i + 1, state: s, profile: profile, d: d),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              _DailyMissions(profile: profile, onAll: onDailyMissions, d: d, tail: tabW + 8 * k),
              const Spacer(),
            ],
          );
        },
      ),
    );
  }
}

/// أعلى اللوح: «الدرجة ٧ من ٣٠» وشريط نقاطك، و«استلم الكل».
class _Header extends StatelessWidget {
  const _Header({
    required this.state,
    required this.dev,
    required this.busy,
    required this.onClaim,
    required this.onBuy,
    required this.d,
  });

  final PassState state;
  final bool dev;
  final bool busy;
  final VoidCallback onClaim;
  final VoidCallback onBuy;
  final _Dims d;

  @override
  Widget build(BuildContext context) {
    final k = d.k;
    final done = state.tier >= season.tiers;
    final fs = math.max(11.0, 14 * k);
    final hint = d.head >= 34;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 22 * k),
      child: SizedBox(
        height: d.head,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      OutlinedText(
                        'الدرجة ${arabicNumber(state.tier)}',
                        size: fs + 1,
                        color: const Color(0xFFF9D277),
                        maxLines: 1,
                        shadow: false,
                      ),
                      SizedBox(width: 5 * k),
                      Text(
                        'من ${arabicNumber(season.tiers)}',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: math.max(10.0, 12 * k),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 12 * k),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 190 * k),
                          child: SnProgressBar(
                            value: done ? 1 : state.pointsInTier / season.tierPoints,
                            height: math.max(7.0, 9 * k),
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * k),
                      Text(
                        done ? '' : '${arabicNumber(state.pointsInTier)}/${arabicNumber(season.tierPoints)}',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: const Color(0xFFE8C98A),
                          fontSize: math.max(10.0, 12 * k),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  if (hint) ...[
                    SizedBox(height: 2 * k),
                    Text(
                      done
                          ? 'خلصت كل الدرجات!'
                          : state.premium
                          ? 'كل لعبة +٢٠ نقطة، والفوز +٣٠، والمهام نقاط أكثر'
                          : 'الذهبي: إطارات وشخصيات حصرية، وضعف الذهب من الجوائز، وملصقات ما تنباع',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.muted, fontSize: math.max(9.5, 11 * k)),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 10 * k),
            // فتح المسار الذهبي (أو إكمال كل الدرجات): ينبض بشويش عشان يلفت
            if (!(done && state.premium)) ...[
              SizedBox(
                width: math.max(130.0, 170 * k),
                child: _Breathe(
                  child: SnButton(
                    label: state.premium ? 'كمّل كل الدرجات' : (dev ? 'افتح الذهبي' : 'افتح الذهبي ${arabicNumber(season.price)}'),
                    semantics: state.premium ? 'كمّل كل الدرجات' : 'افتح المسار الذهبي',
                    icon: state.premium || dev ? null : Gfx('gem', size: 20 * k),
                    tone: state.premium ? SnTone.blue : SnTone.orange,
                    height: math.max(26.0, 32 * k),
                    fontSize: math.max(11.5, 14.5 * k),
                    onPressed: busy || !season.active ? null : onBuy,
                  ),
                ),
              ),
              SizedBox(width: 8 * k),
            ],
            SizedBox(
              width: math.max(96.0, 116 * k),
              child: SnButton(
                label: 'استلم الكل',
                tone: SnTone.green,
                height: math.max(26.0, 32 * k),
                fontSize: math.max(11.5, 14.5 * k),
                onPressed: busy || !state.claimable ? null : onClaim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// عمود درجة: جائزة المجاني فوق، وعقدة الرقم على الحبل، وجائزة الذهبي تحت.
class _TierColumn extends StatelessWidget {
  const _TierColumn({required this.tier, required this.state, required this.profile, required this.d});

  final int tier;
  final PassState state;
  final Profile profile;
  final _Dims d;

  double get k => d.k;

  @override
  Widget build(BuildContext context) {
    final cur = state.tier;
    final reached = tier <= cur;
    final th = d.th, tw = d.tw, node = d.node, ropeTop = d.ropeTop, ropeH = d.ropeH;
    final free = season.free[tier];
    final prem = season.premium[tier];
    return Column(
      children: [
        SizedBox(
          height: th,
          child: Center(
            child: SizedBox(
              width: tw,
              height: th,
              child: _rewardTile(free, claimed: state.free >= tier, locked: false, reached: reached, gold: false),
            ),
          ),
        ),
        SizedBox(
          height: ropeH,
          child: Stack(
            children: [
              Positioned(
                top: ropeTop,
                height: node,
                left: 0,
                right: 0,
                child: SnRopeSegment(
                  solidStart: reached,
                  solidEnd: tier < cur,
                  first: tier == 1,
                  last: tier == season.tiers,
                  thickness: math.max(5.0, 8 * k),
                ),
              ),
              Positioned(
                top: ropeTop,
                left: 0,
                right: 0,
                child: Center(
                  child: tier == cur
                      ? _Breathe(amount: .09, child: SnLevelNode(level: tier, reached: reached, current: true, size: node))
                      : SnLevelNode(level: tier, reached: reached, current: false, size: node),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: th,
          child: Center(
            child: SizedBox(
              width: tw,
              height: th,
              child: _rewardTile(
                prem,
                claimed: state.premium && state.prem >= tier,
                locked: !state.premium,
                reached: reached,
                gold: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rewardTile(
    LevelReward? r, {
    required bool claimed,
    required bool locked,
    required bool reached,
    required bool gold,
  }) {
    if (r == null) return SnRewardTile(art: const SizedBox(), label: '', empty: true, gold: gold, k: k);
    final (art, label, color) = seasonRewardArt(r, profile, k);
    return SnRewardTile(
      art: art,
      label: label,
      gold: gold,
      claimed: claimed,
      locked: locked,
      ready: reached && !claimed && !locked,
      labelColor: gold ? color : null,
      k: k,
    );
  }
}

/// رسمة جائزة الدرجة واسمها (ولون الاسم على البطاقة الغامقة).
(Widget, String, Color) seasonRewardArt(LevelReward r, Profile p, double k) {
  const tan = Color(0xFFC9A765);
  if (r.items.isNotEmpty) {
    final item = shopItem(r.items.first)!;
    final label = r.items.length > 1 ? '${item.name} +' : item.name;
    if (item.slot == ShopSlot.reactions && item.stickers != null) return (SnSealStamp(size: 52 * k), label, tan);
    return (ItemPreview(item: item, profile: p), label, tan);
  }
  if (r.diamonds > 0) return (Gfx('gem', size: 54 * k), arabicNumber(r.diamonds), const Color(0xFF7FA6DA));
  return (SnCoinPile(count: snCoinCount(r.coins), size: 58 * k), arabicNumber(r.coins), tan);
}

/// «مهمات اليوم»: لوح لكل مهمة (تقدّمك وعدّادها). الضغط يفتح صفحة المهام.
class _DailyMissions extends StatelessWidget {
  const _DailyMissions({required this.profile, required this.onAll, required this.d, required this.tail});

  final Profile profile;
  final VoidCallback onAll;
  final _Dims d;

  /// مساحة تبويبات الجوائز على الطرف (عشان الألواح تنتهي معها).
  final double tail;

  @override
  Widget build(BuildContext context) {
    final daily = profile.missions;
    final k = d.k;
    return SizedBox(
      height: d.missions,
      child: Column(
        children: [
          SizedBox(
            height: d.label,
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(start: tail + 4 * k),
                  child: Text(
                    'مهمات اليوم',
                    style: TextStyle(
                      fontFamily: kufi,
                      fontWeight: FontWeight.w800,
                      fontSize: math.max(12.0, 16 * k),
                      height: 1.2,
                      color: const Color(0xFFFCBD49),
                      shadows: const [Shadow(color: Color(0xFF1A0D06), offset: Offset(0, 2), blurRadius: 2)],
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAll,
                  child: Text(
                    'كل المهام ‹',
                    style: TextStyle(
                      color: const Color(0xFFE8C98A),
                      fontSize: math.max(10.5, 12.5 * k),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: d.gap),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: tail),
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = (box.maxWidth - 2 * 12 * k) / 3;
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: missionDefs.length,
                    separatorBuilder: (_, _) => SizedBox(width: 12 * k),
                    itemBuilder: (context, i) {
                      final m = missionDefs[i];
                      return SizedBox(
                        width: w,
                        child: SnMissionPlank(
                          title: m.title,
                          progress: daily.progressOf(m),
                          target: m.target,
                          done: daily.isDone(m),
                          onTap: onAll,
                          k: k,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// جوائز النافذة «استلمت!»: بطاقات ورق صغيرة لكل جائزة.
class SeasonRewardChips extends StatelessWidget {
  const SeasonRewardChips({
    super.key,
    required this.profile,
    required this.coins,
    required this.diamonds,
    required this.items,
  });

  final Profile profile;
  final int coins;
  final int diamonds;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    Widget tile(Widget art, String label) => SizedBox(
      width: 92,
      height: 108,
      child: SnRewardTile(art: art, label: label),
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final id in items)
          if (shopItem(id) case final item?)
            tile(
              item.slot == ShopSlot.reactions && item.stickers != null
                  ? const SnSealStamp(size: 52)
                  : ItemPreview(item: item, profile: profile),
              item.name,
            ),
        if (coins > 0) tile(SnCoinPile(count: snCoinCount(coins), size: 58), arabicNumber(coins)),
        if (diamonds > 0) tile(const Gfx('gem', size: 54), arabicNumber(diamonds)),
      ],
    );
  }
}

/// خيار شراء في نافذة الباتل باس: اسمه ووش فيه وسعره.
class SeasonOption extends StatelessWidget {
  const SeasonOption({
    super.key,
    required this.title,
    required this.lines,
    required this.price,
    required this.tone,
    required this.onPick,
  });

  final String title;
  final List<String> lines;

  /// بالجواهر (null: ببلاش للمطور).
  final int? price;
  final SnTone tone;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => ParchmentCard(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Gfx('pass', size: 40),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            fontFamily: kufi,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.25,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              l,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5A3B1C),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        const Spacer(),
        const SizedBox(height: 8),
        SnButton(
          label: price == null ? 'ببلاش (مطور)' : arabicNumber(price!),
          icon: const Gfx('gem', size: 24),
          tone: tone,
          height: 42,
          fontSize: 18,
          onPressed: onPick,
        ),
      ],
    ),
  );
}

/// قائمة أصحابك في نافذة الإهداء: كل صاحب على لوح خشب بصورته ومستواه.
class SeasonFriendList extends StatelessWidget {
  const SeasonFriendList({super.key, required this.friends, this.onPick});

  final List<LeaderboardEntry> friends;
  final ValueChanged<LeaderboardEntry>? onPick;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const Center(
        child: Text(
          'ما عندك أصحاب للحين. ضيفهم من «الأصدقاء» وبعدين أهدهم.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
      );
    }
    return ListView.separated(
      itemCount: friends.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final e = friends[i];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPick == null ? null : () => onPick!(e),
          child: PlankBar(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                GoldRingAvatar(avatar: e.avatar, size: 36, animate: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        style: const TextStyle(
                          fontFamily: kufi,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          height: 1.2,
                          color: Color(0xFFFFF3DA),
                        ),
                      ),
                      Text(
                        'مستوى ${arabicNumber(e.level)}',
                        style: const TextStyle(color: Color(0xFFE8C98A), fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const Gfx('gift', size: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
