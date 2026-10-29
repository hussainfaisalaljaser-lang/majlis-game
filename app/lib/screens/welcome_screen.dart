import 'package:flutter/material.dart';

import '../services/backend.dart';
import '../theme.dart';
import '../widgets/account.dart';
import '../widgets/design.dart';
import '../widgets/design_social.dart';
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
    return WelcomeView(busy: _busy, onGoogle: _google, onGuest: () => setState(() => _pickProfile = true));
  }
}

/// شكل شاشة الترحيب: الشعار والشخصيات، ولوحة مخمل فيها طرق الدخول. ما تلمس السيرفر.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key, required this.busy, required this.onGoogle, required this.onGuest});

  final bool busy;
  final VoidCallback onGoogle;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    return WoodWall(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            child: Row(
              children: [
                // الشعار والشخصيات
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFD9A84E), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFB02E).withValues(alpha: .4),
                                blurRadius: 26,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .5),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(27),
                            child: Image.asset('assets/logo.png', width: 120, height: 120),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const FittedBox(fit: BoxFit.scaleDown, child: GoldTitle('مجلس الخونة', size: 44)),
                      const SizedBox(height: 4),
                      const Text(
                        'بينكم خونة… اكشفهم قبل لا يحكمون المجلس',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFE9D3B5),
                          fontSize: 15,
                          fontFamily: kufi,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _Faces(),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                // طريقة الدخول
                Expanded(
                  child: Center(
                    child: VelvetPanel(
                      padding: const EdgeInsets.fromLTRB(26, 24, 26, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GoogleButton(onPressed: busy ? null : onGoogle),
                          const SizedBox(height: 8),
                          const OutlinedText(
                            '٥٠٠ ذهب هدية، وحسابك ينحفظ لو غيّرت جوالك',
                            size: 15,
                            gradient: goldTitleColors,
                            stroke: Color(0xFF3A1606),
                          ),
                          const SizedBox(height: 22),
                          SocButton(
                            label: 'ادخل كضيف',
                            semantics: 'ادخل كضيف',
                            tone: SocTone.orange,
                            height: 52,
                            fontSize: 20,
                            onPressed: busy ? null : onGuest,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'تستطيع أن تربط حسابك لاحقاً من «ملفي»',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: socMuted,
                              fontSize: 13,
                              fontFamily: kufi,
                              fontWeight: FontWeight.w700,
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
    const size = 56.0, step = 52.0;
    return SizedBox(
      height: size * 1.14 + 24,
      width: step * (_ids.length - 1) + size * 1.14 + 20,
      child: Stack(
        children: [
          // الملثّم في النص يترسم آخر شي عشان يطلع فوق الباقين.
          for (final (i, id)
              in _ids.indexed.toList()..sort((a, b) => (a.$2 == 'masked' ? 1 : 0) - (b.$2 == 'masked' ? 1 : 0)))
            Positioned(
              left: i * step,
              top: id == 'masked' ? 0 : 12,
              child: SocAvatar(
                avatar: id,
                size: id == 'masked' ? size + 10 : size,
                ring: SocRing.gold,
                animate: false,
                gems: id == 'masked',
              ),
            ),
        ],
      ),
    );
  }
}
