import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/account.dart';
import '../widgets/common.dart';
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
  late String _avatar = avatarIds.contains(_profile.avatar) ? _profile.avatar : 'falcon';
  bool _saving = false;
  String? _error;

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
                    PlayerAvatar(avatar: _avatar, frame: AppColors.gold, size: 96),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _name,
                      maxLength: 16,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: kufi, fontSize: 20, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        hintText: 'اسمك',
                        errorText: _error,
                        isDense: true,
                        counterText: '',
                      ),
                      onSubmitted: (_) => _save(),
                    ),
                    const Spacer(),
                    GameButton(
                      label: _saving ? 'لحظة…' : (widget.firstTime ? 'يلا نبدأ 🚀' : 'حفظ'),
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
                  for (final a in avatarIds)
                    Semantics(
                      button: true,
                      label: 'صورة $a',
                      child: GestureDetector(
                        onTap: () => setState(() => _avatar = a),
                        child: AnimatedScale(
                          scale: a == _avatar ? 1.06 : .92,
                          duration: const Duration(milliseconds: 180),
                          child: Center(
                            child: PlayerAvatar(avatar: a, frame: a == _avatar ? AppColors.gold : null, size: 62),
                          ),
                        ),
                      ),
                    ),
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
                  if (Backend.instance.isReady)
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                        child: const Text('✏️ تعديل الاسم والشخصية'),
                      ),
                    ),
                  if (Backend.instance.isReady) const AccountCard(),
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
                            Text(
                              '⭐ مستوى ${arabicNumber(p.level)}',
                              style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                            const Spacer(),
                            Text(
                              '${arabicNumber(p.xpInLevel)} / ${arabicNumber(Profile.xpPerLevel)} خبرة',
                              style: const TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: p.xpInLevel / Profile.xpPerLevel,
                            minHeight: 12,
                            backgroundColor: Colors.black.withValues(alpha: .35),
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'كل لعبة +٢٠ خبرة، والفوز +٣٠ زيادة',
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _Stat(icon: '🪙', value: arabicNumber(p.coins), label: 'ذهب')),
                      const SizedBox(width: 10),
                      Expanded(child: _Stat(icon: '💎', value: arabicNumber(p.diamonds), label: 'جواهر')),
                      const SizedBox(width: 10),
                      Expanded(child: _Stat(icon: '🎮', value: arabicNumber(p.gamesPlayed), label: 'لعبة')),
                      const SizedBox(width: 10),
                      Expanded(child: _Stat(icon: '🏆', value: arabicNumber(p.gamesWon), label: 'فوز')),
                      const SizedBox(width: 10),
                      Expanded(child: _Stat(icon: '📈', value: '${arabicNumber(p.winRate)}٪', label: 'نسبة الفوز')),
                    ],
                  ),
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
        Text(icon, style: const TextStyle(fontSize: 24)),
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
