import 'package:flutter/material.dart';

import '../models/events.dart';
import '../models/profile.dart';
import '../models/table_tier.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/design_season.dart';
import '../widgets/mode_theme.dart';
import '../widgets/ui.dart';
import '../widgets/venues.dart';
import '../widgets/weekend.dart';
import 'pass_screen.dart';
import 'waiting_screen.dart';

/// اللعب العشوائي: تختار عدد اللاعبين ومستوى الطاولة، وندخلك مع لاعبين من كل مكان (مثل يلا لودو).
/// الطور اختاره قبل (mode_screen.dart)، والصفحة كلها بثيمه. اللعب مع الأصحاب في «خاص» (private_screen.dart).
class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key, required this.mode});

  final ModeTheme mode;

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  int _playerCount = 7;
  TableTier _tier = tableTiers[0];
  bool _busy = false;

  /// الوضع السريع: نفس اللعبة بنص الوقت (حوالي ٥ دقايق).
  bool _quick = false;

  /// ينفذ طلب للسيرفر ويفتح غرفة الانتظار. بدون سيرفر (نسخة الويب) يفتح العرض التجريبي.
  Future<void> _enter(Future<String> Function()? request, {TableTier? tier}) async {
    if (request == null || !Backend.instance.isReady) {
      _openWaiting(null, tier ?? _tier);
      return;
    }
    setState(() => _busy = true);
    try {
      _openWaiting(await request(), tier);
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openWaiting(String? code, TableTier? tier) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WaitingScreen(tier: tier, playerCount: _playerCount, code: code),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Backend.instance.profile,
    builder: (context, profile, _) => TablesView(
      mode: widget.mode,
      profile: profile,
      playerCount: _playerCount,
      onCount: (n) => setState(() => _playerCount = n),
      tier: _tier,
      onTier: (t) => setState(() => _tier = t),
      quick: _quick,
      onQuick: (q) => setState(() => _quick = q),
      busy: _busy,
      onPlay: () => _enter(
        () => Backend.instance.quickMatch(
          maxPlayers: _playerCount,
          tierId: _tier.id,
          quick: _quick,
          roles: widget.mode.roles,
        ),
        tier: _tier,
      ),
    ),
  );
}

/// شاشة الطاولات بدون سيرفر: الخيارات يسار، ومستويات الطاولات يمين.
class TablesView extends StatelessWidget {
  const TablesView({
    super.key,
    required this.mode,
    required this.profile,
    required this.playerCount,
    required this.onCount,
    required this.tier,
    required this.onTier,
    required this.quick,
    required this.onQuick,
    required this.busy,
    required this.onPlay,
  });

  final ModeTheme mode;
  final Profile profile;
  final int playerCount;
  final ValueChanged<int> onCount;
  final TableTier tier;
  final ValueChanged<TableTier> onTier;
  final bool quick;
  final ValueChanged<bool> onQuick;
  final bool busy;
  final VoidCallback onPlay;

  /// طاولة النخبة تنفتح بباتل الموسم الحالي (المسار المدفوع).
  void _vipHint(BuildContext context) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('طاولة النخبة تنفتح بتذكرة الموسم الحالي، وتنقفل لما يخلص الموسم لو ما جددته'),
        action: SnackBarAction(
          label: 'افتح التذكرة',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PassScreen())),
        ),
      ),
    );

  bool _locked(TableTier t) => t.requiredLevel > profile.level || (t.vipOnly && !profile.hasVip);

  @override
  Widget build(BuildContext context) {
    final tone = mode.roles ? SnTone.blue : SnTone.orange;
    return NightScaffold(
      appBar: SnTopBar(
        title: 'عشوائي',
        icon: const Gfx('games', size: 30),
        middle: [
          const Text(
            'مع لاعبين من كل مكان',
            style: TextStyle(color: Color(0xFFE8D3AE), fontWeight: FontWeight.w800, fontSize: 14),
          ),
          ModeChip(mode: mode, onTap: () => Navigator.of(context).maybePop()),
        ],
        trailing: [SnWallet(coins: profile.coins, diamonds: profile.diamonds, infinite: profile.dev)],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, box) {
            final leftW = (box.maxWidth * .31).clamp(230.0, 310.0);
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: WoodPanel(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final h = ((box.maxHeight - 9 * (tableTiers.length - 1)) / tableTiers.length).clamp(
                            62.0,
                            88.0,
                          );
                          return ListView.builder(
                            itemCount: tableTiers.length,
                            itemBuilder: (context, i) {
                              final t = tableTiers[i];
                              final locked = _locked(t);
                              final poor = !profile.dev && profile.coins < t.entryFee;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: _TierTile(
                                  height: h,
                                  tier: t,
                                  mode: mode,
                                  players: playerCount,
                                  locked: locked,
                                  poor: poor,
                                  selected: t == tier,
                                  // طاولة النخبة المقفلة: الضغطة تشرح كيف تنفتح وتوديك للباتل
                                  onTap: locked && t.vipOnly
                                      ? () => _vipHint(context)
                                      : locked || poor
                                      ? null
                                      : () => onTier(t),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: leftW, child: _controls(tone)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// عدد اللاعبين والوقت وزر اللعب (لوحة المخمل).
  Widget _controls(SnTone tone) => VelvetPanel(
    padding: EdgeInsets.zero,
    child: Stack(
      children: [
        Positioned.fill(
          child: SnSunburst(alignment: const Alignment(0, -.2), color: mode.accentLight, opacity: .16),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SnTabBar(
                        labels: [for (final n in playerCounts) '${arabicNumber(n)} لاعبين'],
                        selected: playerCounts.indexOf(playerCount),
                        onChanged: (i) => onCount(playerCounts[i]),
                        height: 32,
                        fontSize: 13,
                        spacing: 6,
                      ),
                      const SizedBox(height: 9),
                      SnTabBar(
                        labels: const ['عادي', 'سريع'],
                        icons: const ['hourglass', 'bolt'],
                        selected: quick ? 1 : 0,
                        onChanged: (i) => onQuick(i == 1),
                        height: 32,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        quick ? 'نص الوقت لكل دور، واللعبة حوالي ٥ دقايق' : 'الوقت العادي، واللعبة حوالي ١٠ دقايق',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFF1DDBA), fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      ModeSummary(mode: mode),
                    ],
                  ),
                ),
              ),
              const WeekendChip(),
              const SizedBox(height: 6),
              const Text(
                'الطاولات العامة تحسب في تصنيفك',
                style: TextStyle(color: Color(0xFFF1DDBA), fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SnButton(
                label: busy ? 'لحظة…' : 'العب الحين',
                semantics: 'العب الحين',
                icon: const Gfx('games', size: 30),
                tone: tone,
                height: 50,
                fontSize: 20,
                onPressed: busy ? null : onPlay,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TierTile extends StatelessWidget {
  const _TierTile({
    required this.height,
    required this.tier,
    required this.mode,
    required this.players,
    required this.locked,
    required this.poor,
    required this.selected,
    this.onTap,
  });

  final double height;
  final TableTier tier;

  /// الطاولة المختارة بلون الطور.
  final ModeTheme mode;
  final int players;
  final bool locked;
  final bool poor;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hint = locked
        ? (tier.vipOnly ? 'يفتح بتذكرة الموسم' : 'يفتح في مستوى ${arabicNumber(tier.requiredLevel)}')
        : poor
        ? 'ما عندك ذهب كافي'
        : null;
    const base = Color(0xFF3A2416);
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: tier.name,
      excludeSemantics: true,
      child: Opacity(
        opacity: locked || poor ? .5 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF130B06),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: .4), blurRadius: 6, offset: const Offset(0, 3)),
                if (selected) BoxShadow(color: mode.select.withValues(alpha: .35), blurRadius: 14),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? mode.select : const Color(0xFF5A3A24),
                    width: selected ? 2.5 : 1.5,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // مكان الطاولة ورا الكلام: لمحة من اللي بتشوفه لما تدخل.
                    _VenuePeek(tier: tier, tint: base),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: _row(hint)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String? hint) => Row(
    children: [
      Opacity(opacity: locked ? .5 : 1, child: Gfx(tier.icon, size: 44)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    tier.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: kufi,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      height: 1.2,
                      color: Color(0xFFFFF3DA),
                    ),
                  ),
                ),
                if (locked) ...[const SizedBox(width: 5), const Gfx('lock', size: 18)],
              ],
            ),
            if (hint != null)
              Text(
                hint,
                style: const TextStyle(color: Color(0xFFD9C29B), fontSize: 12, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Amount(
            'coin',
            arabicNumber(tier.entryFee),
            size: 17,
            style: const TextStyle(
              fontFamily: kufi,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              height: 1.2,
              color: Color(0xFFFFF3DA),
            ),
          ),
          Amount(
            'trophy',
            // نهاية الأسبوع: الجائزة مضاعفة.
            arabicNumber(tier.pot(players) * Weekend.at(DateTime.now()).boost),
            size: 16,
            style: const TextStyle(
              fontFamily: kufi,
              color: Color(0xFF8FE05F),
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ],
  );
}

/// رسمة مكان الطاولة (ثابتة) مقصوصة على البطاقة، ومغطاة بظل من جهة الكلام.
class _VenuePeek extends StatelessWidget {
  const _VenuePeek({required this.tier, required this.tint});

  final TableTier tier;

  /// لون البطاقة اللي يغطي الرسمة من جهة الكلام.
  final Color tint;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: 400,
          height: 225,
          child: RepaintBoundary(child: CustomPaint(painter: venueBackdrop(venueOf(tier.id)), isComplex: true)),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: [tint.withValues(alpha: .97), tint.withValues(alpha: .62), tint.withValues(alpha: .9)],
            stops: const [.28, .62, 1],
          ),
        ),
      ),
    ],
  );
}
