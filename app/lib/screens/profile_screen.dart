import 'package:flutter/material.dart';

import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/account.dart';
import 'dev_screen.dart';
import 'shop_screen.dart';
import 'wardrobe_screen.dart';
import '../widgets/achievements_list.dart';
import '../widgets/common.dart';
import '../widgets/item_preview.dart';
import '../widgets/pid.dart';
import '../widgets/settings.dart';
import '../widgets/ui.dart';

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

  /// شخصية في القائمة.
  Widget _avatarChoice(String a, {required bool locked}) => Semantics(
    button: true,
    label: 'صورة $a',
    child: GestureDetector(
      onTap: locked ? () => _locked(a) : () => setState(() => _avatar = a),
      child: AnimatedScale(
        scale: a == _avatar ? 1.06 : .92,
        duration: const Duration(milliseconds: 180),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: locked ? .45 : 1,
              child: PlayerAvatar(
                avatar: a,
                frame: a == _avatar ? AppColors.gold : (premiumAvatars.contains(a) ? AppColors.diamond : null),
                size: 62,
                animate: a == _avatar,
              ),
            ),
            if (locked) const Gfx('lock', size: 26),
          ],
        ),
      ),
    ),
  );

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
    return NightScaffold(
      appBar: widget.firstTime ? null : AppBar(toolbarHeight: 44, title: const Text('تعديل الملف')),
      body: SafeArea(
        child: Row(
          children: [
            // المعاينة والاسم والحفظ
            SizedBox(
              width: 300,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  children: [
                    if (widget.firstTime) ...[
                      const GoldText('اختر اسمك وشخصيتك', size: 22),
                      const Text(
                        'هذي اللي بيشوفها الكل في المجلس',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                    const Spacer(),
                    PlayerAvatar(
                      avatar: _avatar,
                      style: frameStyle(_profile.frame),
                      frame: frameStyle(_profile.frame) == null ? AppColors.gold : null,
                      size: 96,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _name,
                      maxLength: 16,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: kufi, fontSize: 20, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(hintText: 'اسمك', errorText: _error, isDense: true, counterText: ''),
                      onSubmitted: (_) => _save(),
                    ),
                    const Spacer(),
                    GameButton(
                      label: _saving ? 'لحظة…' : (widget.firstTime ? 'يلا نبدأ' : 'حفظ'),
                      semantics: widget.firstTime ? 'يلا نبدأ' : 'حفظ',
                      height: 50,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
            // الشخصيات
            Expanded(
              child: GridView.count(
                crossAxisCount: 6,
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                mainAxisSpacing: 10,
                crossAxisSpacing: 6,
                children: [
                  for (final a in [...avatarIds, ...premiumAvatars])
                    _avatarChoice(a, locked: !Backend.instance.profile.value.ownsAvatar(a)),
                ],
              ),
            ),
          ],
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
    return NightScaffold(
      appBar: AppBar(title: const Text('ملفي')),
      body: ValueListenableBuilder(
        valueListenable: Backend.instance.profile,
        builder: (context, p, _) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة والاسم والحساب
            SizedBox(
              width: 330,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Center(
                    child: PlayerAvatar(
                      avatar: p.avatar,
                      style: frameStyle(p.frame),
                      frame: frameStyle(p.frame) == null ? AppColors.gold : null,
                      size: 84,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GoldText(p.name, size: 24),
                  // رمزه (ينسخ بالضغط) ورمز مميز ينشرى
                  if (p.pid.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PidBadge(pid: p.pid, tier: p.pidTier, size: 14),
                          const SizedBox(width: 6),
                          Semantics(
                            button: true,
                            label: 'رمز مميز',
                            excludeSemantics: true,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => showPremiumIds(context),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.gold.withValues(alpha: .6)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Gfx('gem', size: 16),
                                    SizedBox(width: 3),
                                    Text(
                                      'رمز مميز',
                                      style: TextStyle(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
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
                  if (Backend.instance.isReady)
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [Gfx('edit', size: 22), SizedBox(width: 6), Text('تعديل الاسم والشخصية')],
                        ),
                      ),
                    ),
                  if (Backend.instance.isReady)
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WardrobeScreen())),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [Gfx('cat_frame', size: 22), SizedBox(width: 6), Text('غرفة التبديل')],
                        ),
                      ),
                    ),
                  if (Backend.instance.isReady) const AccountCard(),
                  if (Backend.instance.isReady) ...[const SizedBox(height: 10), SettingsCard(profile: p)],
                  if (p.dev) ...[
                    const SizedBox(height: 10),
                    GameButton(
                      label: 'وضع المطور',
                      icon: const Gfx('tools', size: 26),
                      tone: ButtonTone.ghost,
                      height: 44,
                      fontSize: 15,
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DevScreen())),
                    ),
                  ],
                ],
              ),
            ),
            // المستوى والإحصائيات
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 4, 16),
                children: [
                  Panel(
                    gradient: const LinearGradient(colors: [Color(0xFF2E2266), Color(0xFF1C1638)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Gfx('xp', size: 22),
                            const SizedBox(width: 6),
                            Text(
                              'مستوى ${arabicNumber(p.level)}',
                              style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                            const Spacer(),
                            Text(
                              '${arabicNumber(p.xpInLevel)} / ${arabicNumber(p.xpToNext)} خبرة',
                              style: const TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: p.levelProgress,
                            minHeight: 12,
                            backgroundColor: Colors.black.withValues(alpha: .35),
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'كل لعبة +٢٠ خبرة، والفوز +٣٠ زيادة. وكل مستوى أصعب من اللي قبله',
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  LevelRoad(level: p.level),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(icon: 'coin', value: arabicNumber(p.coins), label: 'ذهب'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Stat(icon: 'gem', value: arabicNumber(p.diamonds), label: 'جواهر'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Stat(icon: 'games', value: arabicNumber(p.gamesPlayed), label: 'لعبة'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Stat(icon: 'trophy', value: arabicNumber(p.gamesWon), label: 'فوز'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Stat(icon: 'winrate', value: '${arabicNumber(p.winRate)}٪', label: 'نسبة الفوز'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RankPanel(profile: p),
                  const SizedBox(height: 10),
                  AchievementsPanel(profile: p),
                ],
              ),
            ),
          ],
        ),
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
  Widget build(BuildContext context) => Panel(
    child: Column(
      children: [
        Gfx(icon, size: 34),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontFamily: kufi, fontSize: 21, fontWeight: FontWeight.w700),
        ),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
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
    return Panel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Gfx('gift', size: 24),
              const SizedBox(width: 6),
              const Text(
                'هدايا المستويات',
                style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const Spacer(),
              if (next != null)
                Text(
                  'الهدية الجاية بعد ${arabicNumber(next.level - level)} ${next.level - level == 1 ? 'مستوى' : 'مستويات'}',
                  style: const TextStyle(color: AppColors.gold, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rewards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final r = rewards[i];
                final got = level >= r.level;
                final isNext = r == next;
                final item = r.items.isEmpty ? null : shopItem(r.items.first);
                return Container(
                  width: 104,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: got ? AppColors.green.withValues(alpha: .08) : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isNext ? AppColors.gold : (got ? AppColors.green.withValues(alpha: .6) : AppColors.line),
                      width: isNext ? 2 : 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'مستوى ${arabicNumber(r.level)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: got ? AppColors.green : (isNext ? AppColors.gold : AppColors.muted),
                        ),
                      ),
                      Expanded(
                        child: Opacity(
                          opacity: got || isNext ? 1 : .6,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: item != null
                                ? ItemPreview(item: item, profile: p)
                                : Gfx(r.diamonds > 0 ? 'gems' : 'coin', size: 54),
                          ),
                        ),
                      ),
                      Text(
                        item != null
                            ? (r.items.length > 1 ? '${item.name} +' : item.name)
                            : '${arabicNumber(r.coins)} ذهب',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      if (got) const Gfx('check', size: 16),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
