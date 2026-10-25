import 'package:flutter/material.dart';

import '../models/profile.dart';
import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// اختيار الاسم والصورة. يطلع أول مرة يفتح اللاعب اللعبة، ومن الملف الشخصي للتعديل.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.firstTime = false});

  final bool firstTime;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profile = Backend.instance.profile.value;
  late final _name = TextEditingController(text: widget.firstTime ? '' : _profile.name);
  late String _avatar = _profile.avatar;
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
    return Scaffold(
      appBar: widget.firstTime ? null : AppBar(title: const Text('تعديل الملف')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.firstTime) ...[
              const SizedBox(height: 20),
              const Text('🕵️', textAlign: TextAlign.center, style: TextStyle(fontSize: 56)),
              const Text(
                'أهلاً في مجلس الخونة!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'اختر اسمك وصورتك، وهذي اللي بيشوفها الكل في الطاولة',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
            ],
            Center(child: PlayerAvatar(emoji: _avatar, frame: AppColors.gold, size: 96)),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              maxLength: 16,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'اسمك',
                errorText: _error,
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 8),
            const Text('اختر صورتك', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                for (final a in avatars)
                  Semantics(
                    button: true,
                    label: 'صورة $a',
                    child: GestureDetector(
                      onTap: () => setState(() => _avatar = a),
                      child: PlayerAvatar(emoji: a, frame: a == _avatar ? AppColors.gold : null, size: 64),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'لحظة…' : (widget.firstTime ? 'يلا نبدأ 🚀' : 'حفظ')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('ملفي')),
      body: ValueListenableBuilder(
        valueListenable: Backend.instance.profile,
        builder: (context, p, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: PlayerAvatar(emoji: p.avatar, frame: AppColors.gold, size: 96)),
            const SizedBox(height: 10),
            Text(p.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            if (Backend.instance.isReady)
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                  child: const Text('✏️ تعديل الاسم والصورة'),
                ),
              ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('⭐ مستوى ${arabicNumber(p.level)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      const Spacer(),
                      Text(
                        '${arabicNumber(p.xpInLevel)} / ${arabicNumber(Profile.xpPerLevel)} خبرة',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: p.xpInLevel / Profile.xpPerLevel,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(10),
                    backgroundColor: AppColors.bg,
                    color: AppColors.gold,
                  ),
                  const SizedBox(height: 8),
                  const Text('كل لعبة +٢٠ خبرة، والفوز +٣٠ زيادة', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Stat(emoji: '🪙', value: arabicNumber(p.coins), label: 'ذهب')),
                const SizedBox(width: 10),
                Expanded(child: _Stat(emoji: '💎', value: arabicNumber(p.diamonds), label: 'جواهر')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _Stat(emoji: '🎮', value: arabicNumber(p.gamesPlayed), label: 'لعبة')),
                const SizedBox(width: 10),
                Expanded(child: _Stat(emoji: '🏆', value: arabicNumber(p.gamesWon), label: 'فوز')),
                const SizedBox(width: 10),
                Expanded(child: _Stat(emoji: '📈', value: '${arabicNumber(p.winRate)}٪', label: 'نسبة الفوز')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: child,
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.emoji, required this.value, required this.label});

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => _Card(
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      );
}
