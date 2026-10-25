import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/backend.dart';
import '../theme.dart';
import 'common.dart';
import 'ui.dart';

/// زر قوقل الأبيض بشعارها، مثل ما تطلبه قوقل في أزرار الدخول.
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
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          shadowColor: Colors.black54,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onPressed!();
                  },
            child: SizedBox(
              height: 54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/google_g.png', width: 24, height: 24),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(color: Color(0xFF1F1F1F), fontSize: 17, fontWeight: FontWeight.w700),
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

/// يربط الحساب بقوقل، ولو حساب قوقل له لاعب من قبل يسأل قبل ما يدخل عليه.
/// [fresh]: ضيف جديد ما عنده تقدم، فيدخل على الحساب القديم بدون سؤال.
/// يرجع true لو صار مربوط أو دخل على حسابه.
Future<bool> connectGoogle(BuildContext context, {bool fresh = false}) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String text) => messenger.showSnackBar(SnackBar(content: Text(text)));
  try {
    switch (await Backend.instance.linkGoogle()) {
      case GoogleLinked(:final reward):
        say(reward > 0 ? '✅ انربط حسابك بقوقل! +${arabicNumber(reward)} 🪙' : '✅ حسابك مربوط بقوقل');
        return true;
      case GoogleTaken(:final credential):
        if (!fresh && !(context.mounted && await _confirmSwitch(context))) return false;
        await Backend.instance.switchToGoogle(credential);
        say('👋 أهلاً فيك من جديد! رجعنا لك حسابك');
        return true;
      case GoogleCancelled():
        return false;
    }
  } on BackendException catch (e) {
    say(e.message);
    return false;
  }
}

Future<bool> _confirmSwitch(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('عندك حساب محفوظ 👀', textAlign: TextAlign.center),
        content: const Text(
          'حساب قوقل هذا مربوط بلاعب ثاني من قبل. تبي تدخل عليه؟\nتقدّمك الحالي كضيف بيضيع.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: 'لا',
                  tone: ButtonTone.ghost,
                  height: 46,
                  fontSize: 16,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  label: 'ادخل عليه',
                  height: 46,
                  fontSize: 16,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    ) ??
    false;

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
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تطلع من حسابك؟', textAlign: TextAlign.center),
        content: const Text('حسابك محفوظ في قوقل، وترجع له متى ما دخلت بنفس الحساب.', textAlign: TextAlign.center),
        actions: [
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: 'لا',
                  tone: ButtonTone.ghost,
                  height: 46,
                  fontSize: 16,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  label: 'اطلع',
                  tone: ButtonTone.red,
                  height: 46,
                  fontSize: 16,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
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

  Widget _guest(BuildContext context) => Panel(
    borderColor: AppColors.gold,
    gradient: const LinearGradient(colors: [Color(0xFF3A2A12), Color(0xFF1C1638)]),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚠️ أنت تلعب كضيف',
          style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        const SizedBox(height: 4),
        const Text(
          'لو حذفت اللعبة أو غيّرت جوالك يضيع ذهبك ومستواك. اربطه بقوقل واحصل على ٥٠٠ 🪙 هدية!',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
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

  Widget _linked(String email) => Panel(
    child: Row(
      children: [
        Image.asset('assets/images/google_g.png', width: 28, height: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✅ حسابك محفوظ',
                style: TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              Text(
                email,
                textDirection: TextDirection.ltr,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _busy ? null : _signOut,
          child: const Text('تسجيل خروج', style: TextStyle(color: AppColors.muted)),
        ),
      ],
    ),
  );
}
