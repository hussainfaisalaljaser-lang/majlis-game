import 'package:flutter/material.dart';

import '../services/backend.dart';
import '../theme.dart';
import '../widgets/account.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';
import 'profile_screen.dart';

/// أول شاشة للاعب الجديد: يدخل بقوقل (وحسابه ينحفظ) أو يجرب كضيف. بعدها يختار اسمه وشخصيته.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // لو ربط قوقل قبل وطلع قبل ما يختار اسمه، نوديه على طول لاختيار الاسم.
  late bool _pickProfile = Backend.instance.isLinked;
  bool _busy = false;

  Future<void> _google() async {
    setState(() => _busy = true);
    final ok = await connectGoogle(context, fresh: true);
    if (!mounted) return;
    // لو دخل على حساب قديم مكتمل، البوابة تفتح الرئيسية بنفسها.
    setState(() {
      _busy = false;
      if (ok) _pickProfile = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pickProfile) return const EditProfileScreen(firstTime: true);
    return NightScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Row(
            children: [
              // الشعار والشخصيات
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset('assets/logo.png', width: 120, height: 120),
                    ),
                    const SizedBox(height: 8),
                    const GoldText('مجلس الخونة', size: 38),
                    const SizedBox(height: 4),
                    const Text(
                      'بينكم خونة… اكشفهم قبل لا يحكمون المجلس',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    const _Faces(),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              // طريقة الدخول
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GoogleButton(onPressed: _busy ? null : _google),
                    const SizedBox(height: 8),
                    const Text(
                      '🎁 ٥٠٠ ذهب هدية، وحسابك ينحفظ لو غيّرت جوالك',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 22),
                    GameButton(
                      label: 'ادخل كضيف',
                      semantics: 'ادخل كضيف',
                      tone: ButtonTone.ghost,
                      height: 50,
                      fontSize: 17,
                      onPressed: _busy ? null : () => setState(() => _pickProfile = true),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'تقدر تربط حسابك بعدين من «ملفي»',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صف شخصيات متداخل تحت العنوان.
class _Faces extends StatelessWidget {
  const _Faces();

  static const _ids = ['pearl', 'desert', 'masked', 'sheikh', 'rose'];

  @override
  Widget build(BuildContext context) {
    const size = 58.0, step = 44.0;
    return SizedBox(
      height: size + 28,
      width: step * (_ids.length - 1) + size + 24,
      child: Stack(
        children: [
          // الملثّم في النص يترسم آخر شي عشان يطلع فوق الباقين.
          for (final (i, id)
              in _ids.indexed.toList()..sort((a, b) => (a.$2 == 'masked' ? 1 : 0) - (b.$2 == 'masked' ? 1 : 0)))
            Positioned(
              left: i * step,
              top: id == 'masked' ? 0 : 10,
              child: PlayerAvatar(
                avatar: id,
                size: id == 'masked' ? size + 10 : size,
                frame: id == 'masked' ? AppColors.traitor : AppColors.gold,
              ),
            ),
        ],
      ),
    );
  }
}
