import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/backend.dart';
import '../theme.dart';
import 'common.dart';
import 'design_social.dart';

/// زر قوقل الأبيض بشعارها، مثل ما تطلبه قوقل في أزرار الدخول (بحد غامق وعمق مثل باقي الأزرار).
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed, this.label = 'المتابعة بحساب قوقل'});

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null ? .6 : 1,
        child: GestureDetector(
          onTap: onPressed == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                },
          child: Container(
            height: 54,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0xFFF1EBDD)],
              ),
              border: Border.all(color: const Color(0xFF2A1608), width: 2.4),
              boxShadow: [
                const BoxShadow(color: Color(0xFFB9A98A), offset: Offset(0, 4)),
                const BoxShadow(color: Color(0xFF2A1608), offset: Offset(0, 5.6)),
                BoxShadow(color: Colors.black.withValues(alpha: .35), blurRadius: 8, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/google_g.png', width: 24, height: 24),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(color: Color(0xFF1F1F1F), fontSize: 17, fontWeight: FontWeight.w800, fontFamily: kufi),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// يربط الحساب بقوقل، ولو حساب قوقل له لاعب من قبل يسأل قبل ما يدخل عليه.
/// [fresh]: ضيف جديد ما عنده تقدم، فيدخل على الحساب القديم بدون سؤال.
/// يرجع true لو صار مربوط أو دخل على حسابه.
Future<bool> connectGoogle(BuildContext context, {bool fresh = false}) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger.showSnackBar(SnackBar(content: Text(text)));
  try {
    switch (await Backend.instance.linkGoogle()) {
      case GoogleLinked(:final reward):
        say(reward > 0 ? 'انربط حسابك بقوقل! +${arabicNumber(reward)} ذهب' : 'حسابك مربوط بقوقل');
        return true;
      case GoogleTaken(:final credential):
        if (!fresh && !(context.mounted && await _confirmSwitch(context))) return false;
        await Backend.instance.switchToGoogle(credential);
        say('أهلاً فيك من جديد! رجعنا لك حسابك');
        return true;
      case GoogleCancelled():
        return false;
    }
  } on BackendException catch (e) {
    say(e.message);
    return false;
  }
}

Future<bool> _confirmSwitch(BuildContext context) => socConfirm(
  context,
  title: 'عندك حساب محفوظ',
  body: 'حساب قوقل هذا مربوط بلاعب ثاني من قبل. تبي تدخل عليه؟\nتقدّمك الحالي كضيف بيضيع.',
  yes: 'ادخل عليه',
);

/// بطاقة الحساب في الملف الشخصي: ضيف (مع دعوة للربط) أو مربوط بقوقل.
class AccountCard extends StatefulWidget {
  const AccountCard({super.key});

  @override
  State<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    final ok = await socConfirm(
      context,
      title: 'تطلع من حسابك؟',
      body: 'حسابك محفوظ في قوقل، وترجع له متى ما دخلت بنفس الحساب.',
      yes: 'اطلع',
      danger: true,
    );
    if (!ok || !mounted) return;
    final nav = Navigator.of(context);
    await _run(Backend.instance.signOut);
    nav.popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Backend.instance.googleEmail,
      builder: (context, email, _) => email == null ? _guest(context) : _linked(email),
    );
  }

  Widget _guest(BuildContext context) => SocCard(
    gold: true,
    tint: const Color(0xFFB8741E),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Gfx('warning', size: 26),
            SizedBox(width: 6),
            Text(
              'أنت تلعب كضيف',
              style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 18, color: socGoldHi),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'لو حذفت اللعبة أو غيّرت جوالك يضيع ذهبك ومستواك. اربطه بقوقل واحصل على ٥٠٠ ذهب هدية!',
          style: TextStyle(color: Color(0xFFE9D3B5), fontSize: 13.5, fontFamily: kufi, fontWeight: FontWeight.w700, height: 1.4),
        ),
        const SizedBox(height: 10),
        GoogleButton(
          label: _busy ? 'لحظة…' : 'اربط حسابك بقوقل',
          onPressed: _busy
              ? null
              : () => _run(() async {
                  final nav = Navigator.of(context);
                  final switched = await connectGoogle(context);
                  if (switched && !Backend.instance.profile.value.setupDone) nav.popUntil((r) => r.isFirst);
                }),
        ),
      ],
    ),
  );

  Widget _linked(String email) => SocPlankRow(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    child: Row(
      children: [
        Image.asset('assets/images/google_g.png', width: 28, height: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'حسابك محفوظ',
                style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 17, color: socCream, height: 1.2),
              ),
              Text(
                email,
                textDirection: TextDirection.ltr,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: socMuted, fontSize: 12.5),
              ),
            ],
          ),
        ),
        SocButton(label: 'تسجيل خروج', tone: SocTone.grey, height: 34, fontSize: 14, width: 112, onPressed: _busy ? null : _signOut),
      ],
    ),
  );
}
