import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/account.dart';
import '../widgets/achievements_list.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/design_social.dart';
import '../widgets/item_preview.dart';
import '../widgets/pid.dart';
import '../widgets/settings.dart';
import 'dev_screen.dart';
import 'history_screen.dart';
import 'shop_screen.dart';
import 'wardrobe_screen.dart';

/// اختيار الاسم والشخصية. يطلع أول مرة يفتح اللاعب اللعبة، ومن الملف الشخصي للتعديل.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.firstTime = false});

  final bool firstTime;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profile = Backend.instance.profile.value;
  late final _name = TextEditingController(
    text: widget.firstTime ? (Backend.instance.googleName ?? '') : _profile.name,
  );
  late String _avatar = _profile.ownsAvatar(_profile.avatar) ? _profile.avatar : 'falcon';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// المقفلة: اللي تنشرى تودّيه للمتجر، والباقي يقول له من وين تنكسب (مستوى، موسم، بطولة).
  void _locked(String a) {
    final item = avatarItem(a);
    if (item != null && item.buyable) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const ShopScreen(initialTab: ShopScreen.avatarsTab)))
          .then((_) => setState(() {}));
    } else if (item != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${item.name}" ${item.source}')));
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.length < 2) return setState(() => _error = 'اكتب اسم من حرفين على الأقل');
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await Backend.instance.updateProfile(name: name, avatar: _avatar);
      if (mounted && !widget.firstTime) Navigator.of(context).pop();
    } on BackendException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owned = Backend.instance.profile.value;
    return EditProfileView(
      firstTime: widget.firstTime,
      avatar: _avatar,
      frame: frameStyle(_profile.frame),
      name: _name,
      error: _error,
      saving: _saving,
      choices: [...avatarIds, ...premiumAvatars],
      locked: (a) => !owned.ownsAvatar(a),
      onPick: (a) => setState(() => _avatar = a),
      onLocked: _locked,
      onSave: _saving ? null : _save,
    );
  }
}

/// شكل صفحة اختيار الاسم والشخصية: ما تلمس السيرفر (تنشاف بالتصوير ببيانات تجريبية).
class EditProfileView extends StatelessWidget {
  const EditProfileView({
    super.key,
    required this.firstTime,
    required this.avatar,
    required this.frame,
    required this.name,
    required this.error,
    required this.saving,
    required this.choices,
    required this.locked,
    required this.onPick,
    required this.onLocked,
    required this.onSave,
  });

  final bool firstTime;
  final String avatar;
  final FrameStyle? frame;
  final TextEditingController name;
  final String? error;
  final bool saving;
  final List<String> choices;
  final bool Function(String avatar) locked;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onLocked;
  final VoidCallback? onSave;

  /// شخصية في القائمة.
  Widget _choice(String a) {
    final isLocked = locked(a);
    final selected = a == avatar;
    return Semantics(
      button: true,
      label: 'صورة $a',
      child: GestureDetector(
        onTap: isLocked ? () => onLocked(a) : () => onPick(a),
        child: AnimatedScale(
          scale: selected ? 1.08 : .92,
          duration: const Duration(milliseconds: 180),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: isLocked ? .45 : 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFB02E).withValues(alpha: .65),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: SocAvatar(
                    avatar: a,
                    size: 54,
                    ring: selected || !premiumAvatars.contains(a) ? SocRing.gold : SocRing.blue,
                    animate: selected,
                  ),
                ),
              ),
              if (isLocked) const Gfx('lock', size: 26),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (firstTime) ...[
          const GoldTitle('اختر اسمك وشخصيتك', size: 22),
          const SizedBox(height: 2),
          const Text(
            'هذي اللي بيشوفها الكل في المجلس',
            style: TextStyle(color: socMuted, fontSize: 13, fontFamily: kufi, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: const Color(0xFFFFB02E).withValues(alpha: .45), blurRadius: 26, spreadRadius: 2),
            ],
          ),
          child: SocAvatar(avatar: avatar, style: frame, size: 100, animate: true, gems: true),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: name,
          maxLength: 16,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: kufi, fontSize: 21, fontWeight: FontWeight.w800, color: socCream),
          decoration: socInput(hint: 'اسمك', error: error),
          onSubmitted: (_) => onSave?.call(),
        ),
        const Spacer(),
        SocButton(
          label: saving ? 'لحظة…' : (firstTime ? 'يلا نبدأ' : 'حفظ'),
          semantics: firstTime ? 'يلا نبدأ' : 'حفظ',
          tone: SocTone.green,
          height: 50,
          fontSize: 21,
          onPressed: onSave,
        ),
      ],
    );
    return SocScaffold(
      title: firstTime ? 'مجلس الخونة' : 'تعديل الملف',
      icon: firstTime ? null : const Gfx('edit', size: 28),
      currency: false,
      back: !firstTime,
      body: SocTwoPanels(
        mainFlex: 8,
        sideFlex: 11,
        main: VelvetPanel(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(child: preview),
              ),
            ),
          ),
        ),
        side: WoodPanel(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: GridView.count(
            crossAxisCount: 6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 4,
            children: [for (final a in choices) _choice(a)],
          ),
        ),
      ),
    );
  }
}

/// الملف الشخصي: المستوى والإحصائيات.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SocScaffold(
      title: 'ملفي',
      icon: const Gfx('profile', size: 28),
      body: ValueListenableBuilder(
        valueListenable: Backend.instance.profile,
        builder: (context, p, _) => SocTwoPanels(
          mainFlex: 8,
          sideFlex: 11,
          main: ProfileIdentityPanel(
            profile: p,
            ready: Backend.instance.isReady,
            onEdit: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            onWardrobe: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WardrobeScreen())),
            onDev: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DevScreen())),
            onPremiumId: () => showPremiumIds(context),
            account: const AccountCard(),
            settings: SettingsCard(profile: p),
          ),
          side: ProfileStatsPanel(
            profile: p,
            levelRoad: LevelRoad(level: p.level),
            onHistory: Backend.instance.isReady
                ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()))
                : null,
          ),
        ),
      ),
    );
  }
}

/// لوحة هويتك (مخمل): الصورة والاسم والرمز، وأزرار التعديل وغرفة التبديل، وحسابك وإعداداتك.
class ProfileIdentityPanel extends StatelessWidget {
  const ProfileIdentityPanel({
    super.key,
    required this.profile,
    required this.ready,
    required this.onEdit,
    required this.onWardrobe,
    required this.onDev,
    required this.onPremiumId,
    this.account,
    this.settings,
  });

  final Profile profile;

  /// السيرفر جاهز (الأزرار اللي تحتاجه تطلع).
  final bool ready;
  final VoidCallback onEdit;
  final VoidCallback onWardrobe;
  final VoidCallback onDev;
  final VoidCallback onPremiumId;
  final Widget? account;
  final Widget? settings;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final style = frameStyle(p.frame);
    return VelvetPanel(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFFB02E).withValues(alpha: .4), blurRadius: 24, spreadRadius: 1),
                ],
              ),
              child: SocAvatar(avatar: p.avatar, style: style, size: 86, animate: true, gems: true),
            ),
          ),
          const SizedBox(height: 6),
          GoldTitle(p.name, size: 26),
          // رمزه (ينسخ بالضغط) ورمز مميز ينشرى
          if (p.pid.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PidBadge(pid: p.pid, tier: p.pidTier, size: 14),
                  const SizedBox(width: 8),
                  SocButton(
                    label: 'رمز مميز',
                    semantics: 'رمز مميز',
                    tone: SocTone.blue,
                    icon: const Gfx('gem', size: 18),
                    height: 30,
                    fontSize: 13,
                    padding: 8,
                    onPressed: onPremiumId,
                  ),
                ],
              ),
            ),
          if (ready) ...[
            const SizedBox(height: 8),
            SocButton(
              label: 'تعديل الاسم والشخصية',
              tone: SocTone.blue,
              icon: const Gfx('edit', size: 22),
              height: 40,
              fontSize: 15,
              onPressed: onEdit,
            ),
            const SizedBox(height: 4),
            SocButton(
              label: 'غرفة التبديل',
              tone: SocTone.orange,
              icon: const HangerBadge(size: 26),
              height: 40,
              fontSize: 15,
              onPressed: onWardrobe,
            ),
            const SizedBox(height: 6),
            ?account,
            const SizedBox(height: 10),
            ?settings,
          ],
          if (p.dev) ...[
            const SizedBox(height: 10),
            SocButton(
              label: 'وضع المطور',
              tone: SocTone.grey,
              icon: const Gfx('tools', size: 24),
              height: 40,
              fontSize: 15,
              onPressed: onDev,
            ),
          ],
        ],
      ),
    );
  }
}

/// لوحة مستواك (خشب): بطاقة المستوى، وهدايا المستويات، والإحصائيات، والتصنيف، والإنجازات.
class ProfileStatsPanel extends StatelessWidget {
  const ProfileStatsPanel({super.key, required this.profile, required this.levelRoad, required this.onHistory});

  final Profile profile;
  final Widget levelRoad;

  /// null: سجل المباريات ما يطلع (السيرفر مو جاهز).
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return WoodPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SocCard(
            gold: true,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Gfx('xp', size: 26),
                    const SizedBox(width: 8),
                    GoldTitle('مستوى ${arabicNumber(p.level)}', size: 22),
                    const Spacer(),
                    Text(
                      '${arabicNumber(p.xpInLevel)} / ${arabicNumber(p.xpToNext)} خبرة',
                      style: const TextStyle(
                        color: socMuted,
                        fontSize: 13.5,
                        fontFamily: kufi,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SocBar(value: p.levelProgress, height: 13),
                const SizedBox(height: 6),
                const Text(
                  'كل لعبة +٢٠ خبرة، والفوز +٣٠ زيادة. وكل مستوى أصعب من اللي قبله',
                  style: TextStyle(color: socMuted, fontSize: 12.5, fontFamily: kufi, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          levelRoad,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Stat(icon: 'coin', value: arabicNumber(p.coins), label: 'ذهب'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(icon: 'gem', value: arabicNumber(p.diamonds), label: 'جواهر'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(icon: 'games', value: arabicNumber(p.gamesPlayed), label: 'لعبة'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(icon: 'trophy', value: arabicNumber(p.gamesWon), label: 'فوز'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(icon: 'winrate', value: '${arabicNumber(p.winRate)}٪', label: 'نسبة الفوز'),
              ),
            ],
          ),
          if (onHistory != null) ...[
            const SizedBox(height: 10),
            SocButton(
              label: 'سجل مبارياتي',
              tone: SocTone.blue,
              icon: const Gfx('log', size: 24),
              height: 42,
              fontSize: 16,
              onPressed: onHistory,
            ),
          ],
          const SizedBox(height: 8),
          RankPanel(profile: p),
          const SizedBox(height: 14),
          AchievementsPanel(profile: p),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => SocCard(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Column(
      children: [
        Gfx(icon, size: 30),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: kufi,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: socCream,
              height: 1.2,
            ),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: socMuted,
            fontSize: 12.5,
            fontFamily: kufi,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ],
    ),
  );
}

/// طريق المستويات: هدايا كل ٥ مستويات، وكل ١٠ إطار وشخصية خاصة.
class LevelRoad extends StatelessWidget {
  const LevelRoad({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final p = Backend.instance.profile.value;
    // بعد آخر هدية في القائمة: كل ٥ مستويات ذهب وجواهر (نعرض اللي جاي منها).
    final rewards = [...levelRewards];
    for (var l = levelRewards.last.level + lateReward.every; l <= level + 10; l += lateReward.every) {
      rewards.add(LevelReward(l, coins: lateReward.coins, diamonds: lateReward.diamonds));
    }
    final next = rewards.where((r) => r.level > level).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Gfx('gift', size: 26),
            const SizedBox(width: 8),
            const GoldTitle('هدايا المستويات', size: 20),
            const Spacer(),
            if (next != null)
              Text(
                'الهدية الجاية بعد ${arabicNumber(next.level - level)} ${next.level - level == 1 ? 'مستوى' : 'مستويات'}',
                style: const TextStyle(color: socGoldHi, fontSize: 13, fontFamily: kufi, fontWeight: FontWeight.w800),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 138,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: rewards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final r = rewards[i];
              final got = level >= r.level;
              final isNext = r == next;
              final item = r.items.isEmpty ? null : shopItem(r.items.first);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 104,
                    padding: const EdgeInsets.fromLTRB(6, 7, 6, 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: got
                            ? const [Color(0xFFD9E5B0), Color(0xFFB4CC84)]
                            : const [Color(0xFFF1E0B8), Color(0xFFD9BC86)],
                      ),
                      border: Border.all(
                        color: isNext
                            ? const Color(0xFFE08A12)
                            : (got ? const Color(0xFF5E8A2E) : const Color(0xFF6B4A2C)),
                        width: isNext ? 3 : 2,
                      ),
                      boxShadow: [
                        if (isNext) BoxShadow(color: const Color(0xFFFFB02E).withValues(alpha: .7), blurRadius: 12),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .35),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'مستوى ${arabicNumber(r.level)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontFamily: kufi,
                            fontWeight: FontWeight.w800,
                            color: got
                                ? const Color(0xFF2F6A12)
                                : (isNext ? const Color(0xFFB45F08) : const Color(0xFF7A5A3A)),
                            height: 1.2,
                          ),
                        ),
                        Expanded(
                          child: Opacity(
                            opacity: got || isNext ? 1 : .65,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: item != null
                                  ? ItemPreview(item: item, profile: p)
                                  : Gfx(r.diamonds > 0 ? 'gem' : 'coin', size: 54),
                            ),
                          ),
                        ),
                        Text(
                          item != null
                              ? (r.items.length > 1 ? '${item.name} +' : item.name)
                              : '${arabicNumber(r.coins)} ذهب',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontFamily: kufi,
                            fontWeight: FontWeight.w800,
                            color: socInk,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (got) const PositionedDirectional(top: -7, end: -5, child: SocCheck(size: 20)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
