import 'package:flutter/material.dart';

import '../models/leaderboard.dart';
import '../models/missions.dart';
import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/telemetry.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/gifts.dart';
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
  static const _cell = 112.0;
  late final _scroll = ScrollController(
    initialScrollOffset: ((Backend.instance.profile.value.pass.tier - 2).clamp(0, season.tiers) * (_cell + 8))
        .toDouble(),
  );
  bool _busy = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    setState(() => _busy = true);
    try {
      final got = await Backend.instance.claimPassRewards();
      if (!mounted) return;
      if (got.coins + got.diamonds + got.items.length == 0) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.panel,
          title: const Text('استلمت!', textAlign: TextAlign.center),
          content: RewardView(coins: got.coins, diamonds: got.diamonds, items: got.items),
          actions: [
            Center(
              child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('تمام')),
            ),
          ],
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
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.panel,
      title: Text(title, textAlign: TextAlign.center),
      content: SizedBox(
        width: 520,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!owned) ...[
                Expanded(
                  child: _Option(
                    title: 'الباتل باس',
                    lines: ['المسار المدفوع وكل مكافآته', 'هدية: ${arabicNumber(season.bonusTiers)} درجات على طول'],
                    price: p.dev ? null : season.price,
                    tone: ButtonTone.gold,
                    onPick: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _Option(
                  title: 'الباتل باس كامل',
                  lines: [
                    'المسار المدفوع وكل مكافآته',
                    'كل الدرجات الـ${arabicNumber(season.tiers)} مفتوحة على طول',
                    if (owned) 'تدفع الفرق بس',
                  ],
                  price: p.dev ? null : (owned ? season.fullPrice - season.price : season.fullPrice),
                  tone: ButtonTone.purple,
                  onPick: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
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
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('أهدِ الباتل باس لصاحبك', textAlign: TextAlign.center),
        content: SizedBox(
          width: 420,
          height: 220,
          child: p.friends.isEmpty
              ? const Center(
                  child: Text(
                    'ما عندك أصحاب للحين. ضيفهم من «الأصدقاء» وبعدين أهدهم.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              : FutureBuilder(
                  future: Future.wait(p.friends.map(Backend.instance.fetchPlayer)),
                  builder: (context, snap) {
                    final list = [for (final e in snap.data ?? const <LeaderboardEntry?>[]) ?e];
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                    return ListView(
                      children: [
                        for (final e in list)
                          ListTile(
                            leading: PlayerAvatar(avatar: e.avatar, size: 40, animate: false),
                            title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            subtitle: Text('مستوى ${arabicNumber(e.level)}'),
                            onTap: () => Navigator.pop(context, e),
                          ),
                      ],
                    );
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

  @override
  Widget build(BuildContext context) {
    final left = season.end.difference(DateTime.now());
    return NightScaffold(
      glow: const Color(0xFF0F5C58),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gfx('pass', size: 34),
            const SizedBox(width: 8),
            Flexible(child: Text(season.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: Backend.instance.profile,
            builder: (context, p, _) => TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MissionsScreen(
                    tab:
                        !weeklyMissions.any(p.passMissions.isClaimable) &&
                            seasonMissions.any(p.passMissions.isClaimable)
                        ? 2
                        : 1,
                  ),
                ),
              ),
              icon: const Gfx('missions', size: 22),
              label: Text(
                p.claimablePassMissions > 0 ? 'المهام (${arabicNumber(p.claimablePassMissions)})' : 'المهام',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _busy || !season.active ? null : () => _gift(Backend.instance.profile.value),
            icon: const Gfx('gift', size: 22),
            label: const Text(
              'أهدِ صاحبك',
              style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            margin: const EdgeInsetsDirectional.only(end: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Gfx('hourglass', size: 20),
                const SizedBox(width: 5),
                Text(
                  left.isNegative ? 'انتهى الموسم' : 'باقي ${arabicNumber(left.inDays)} يوم',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Backend.instance.profile,
        builder: (context, p, _) {
          final s = p.pass;
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Column(
              children: [
                SizedBox(
                  height: 150,
                  child: _Header(p: p, busy: _busy, onBuy: () => _buy(p), onClaim: _claim),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      // عناوين المسارين
                      const SizedBox(
                        width: 64,
                        child: Column(
                          children: [
                            SizedBox(height: 34),
                            Expanded(
                              child: _TrackLabel(label: 'مجاني', icon: 'gift', color: AppColors.muted),
                            ),
                            SizedBox(height: 8),
                            Expanded(
                              child: _TrackLabel(label: 'الباتل باس', icon: 'pass', color: AppColors.gold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ListView.separated(
                          controller: _scroll,
                          scrollDirection: Axis.horizontal,
                          itemCount: season.tiers,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, i) => SizedBox(
                            width: _cell,
                            child: _TierColumn(tier: i + 1, state: s),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.p, required this.busy, required this.onBuy, required this.onClaim});

  final Profile p;
  final bool busy;
  final VoidCallback onBuy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final s = p.pass;
    final finalAvatar = shopItem('avatar_s1c')!;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF134E4A), Color(0xFF1E1B4B)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: .6), width: 1.5),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          PlayerAvatar(avatar: finalAvatar.avatar!, style: frameStyle('frame_s1c'), size: 100),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      'الدرجة ${arabicNumber(s.tier)}',
                      style: const TextStyle(fontFamily: kufi, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      ' من ${arabicNumber(season.tiers)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: s.pointsInTier / season.tierPoints,
                    minHeight: 10,
                    backgroundColor: Colors.black.withValues(alpha: .4),
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.tier >= season.tiers
                      ? 'خلصت كل الدرجات!'
                      : '${arabicNumber(s.pointsInTier)} / ${arabicNumber(season.tierPoints)} نقطة · كل لعبة +٢٠، والفوز +٣٠، والمهام نقاط أكثر',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 190,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!s.premium)
                  GameButton(
                    label: 'اشترِ الباتل باس',
                    icon: const Gfx('gem', size: 24),
                    height: 46,
                    fontSize: 15,
                    onPressed: busy || !season.active ? null : onBuy,
                  )
                else if (s.tier < season.tiers)
                  GameButton(
                    label: 'كمّل كل الدرجات',
                    icon: const Gfx('gem', size: 24),
                    tone: ButtonTone.purple,
                    height: 46,
                    fontSize: 15,
                    onPressed: busy || !season.active ? null : onBuy,
                  )
                else
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Gfx('check', size: 22),
                      SizedBox(width: 6),
                      Text(
                        'عندك الباتل باس كامل',
                        style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                GameButton(
                  label: 'استلم الكل',
                  tone: ButtonTone.green,
                  height: 42,
                  fontSize: 15,
                  onPressed: busy || !s.claimable ? null : onClaim,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackLabel extends StatelessWidget {
  const _TrackLabel({required this.label, required this.icon, required this.color});

  final String label;
  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: .4)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Gfx(icon, size: 30),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _TierColumn extends StatelessWidget {
  const _TierColumn({required this.tier, required this.state});

  final int tier;
  final PassState state;

  @override
  Widget build(BuildContext context) {
    final reached = state.tier >= tier;
    return Column(
      children: [
        Container(
          height: 26,
          margin: const EdgeInsets.only(bottom: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: reached ? const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFF2B53A)]) : null,
            color: reached ? null : AppColors.card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            arabicNumber(tier),
            style: TextStyle(
              fontFamily: kufi,
              fontWeight: FontWeight.w700,
              color: reached ? AppColors.goldInk : AppColors.muted,
            ),
          ),
        ),
        Expanded(
          child: _Cell(reward: season.free[tier], reached: reached, claimed: state.free >= tier, locked: false),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _Cell(
            reward: season.premium[tier],
            reached: reached,
            claimed: state.premium && state.prem >= tier,
            locked: !state.premium,
            premium: true,
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.reward,
    required this.reached,
    required this.claimed,
    required this.locked,
    this.premium = false,
  });

  final LevelReward? reward;
  final bool reached;
  final bool claimed;
  final bool locked;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final r = reward;
    final border = premium ? AppColors.gold : AppColors.line;
    final ready = reached && !claimed && !locked && r != null;
    Widget content = const SizedBox();
    String label = '';
    if (r != null) {
      if (r.items.isNotEmpty) {
        final item = shopItem(r.items.first)!;
        content = ItemPreview(item: item, profile: Backend.instance.profile.value);
        label = r.items.length > 1 ? '${item.name} +' : item.name;
      } else if (r.diamonds > 0) {
        content = const Gfx('gem', size: 54);
        label = '${arabicNumber(r.diamonds)} جوهرة';
      } else {
        content = const Gfx('coin', size: 54);
        label = '${arabicNumber(r.coins)} ذهب';
      }
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: premium ? [const Color(0xFF3B2A0C), AppColors.card] : [AppColors.card, AppColors.card],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ready ? AppColors.green : border.withValues(alpha: r == null ? .2 : .55),
          width: ready ? 2 : 1.2,
        ),
        boxShadow: [if (ready) BoxShadow(color: AppColors.green.withValues(alpha: .4), blurRadius: 12)],
      ),
      child: r == null
          ? null
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                  child: Column(
                    children: [
                      Expanded(
                        child: Opacity(
                          opacity: locked ? .5 : 1,
                          child: FittedBox(fit: BoxFit.scaleDown, child: content),
                        ),
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                if (claimed)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: .45),
                      alignment: Alignment.center,
                      child: const Gfx('check', size: 34),
                    ),
                  ),
                if (locked) const PositionedDirectional(top: 4, end: 4, child: Gfx('lock', size: 18)),
              ],
            ),
    );
  }
}

/// خيار شراء في نافذة الباتل باس: اسمه ووش فيه وسعره.
class _Option extends StatelessWidget {
  const _Option({
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
  final ButtonTone tone;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: tone == ButtonTone.purple ? const Color(0xFFA48BFF) : AppColors.gold, width: 1.5),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Gfx('pass', size: 40),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontFamily: kufi, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              l,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
          ),
        const SizedBox(height: 8),
        GameButton(
          label: price == null ? 'ببلاش (مطور)' : arabicNumber(price!),
          icon: const Gfx('gem', size: 22),
          tone: tone,
          height: 42,
          fontSize: 15,
          onPressed: onPick,
        ),
      ],
    ),
  );
}
