import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/profile.dart';
import '../services/backend.dart';
import '../theme.dart';
import 'common.dart';
import 'design_social.dart';
import 'fx.dart';
import 'volume_panel.dart';

/// رقم النسخة من البناء (CI يمرره: --dart-define=BUILD=رقم التشغيل).
const appBuild = String.fromEnvironment('BUILD', defaultValue: 'dev');

/// الإعدادات في ملفك: المحظورين، وتواصل معنا، وحذف الحساب.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    Widget item(String icon, String label, VoidCallback onTap, {Color? color, String? semantics}) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        button: true,
        label: semantics ?? label,
        excludeSemantics: true,
        child: SocPlankRow(
          onTap: onTap,
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
          child: Row(
            children: [
              Gfx(icon, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: kufi,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: color ?? socCream,
                    height: 1.25,
                  ),
                ),
              ),
              const Icon(Icons.chevron_left, color: Color(0xFFE8B54E), size: 22),
            ],
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // الجوالات الضعيفة: توقف حركات الإطارات والشخصيات وتبقى الرسمات ثابتة.
        ValueListenableBuilder(
          valueListenable: FxClock.lite,
          builder: (context, lite, _) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SocPlankRow(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
              child: Row(
                children: [
                  const Gfx('bolt', size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حركات خفيفة',
                          style: TextStyle(
                            fontFamily: kufi,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: socCream,
                            height: 1.25,
                          ),
                        ),
                        Text(
                          'توقف حركات الإطارات والشخصيات. للجوالات الضعيفة',
                          style: TextStyle(
                            color: socMuted,
                            fontSize: 12,
                            fontFamily: kufi,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SocSwitch(value: lite, onChanged: FxClock.setLite),
                ],
              ),
            ),
          ),
        ),
        item('sound', 'مستوى الصوت (الموسيقى والمعلق والمؤثرات)', () => showVolumeDialog(context)),
        item(
          'lock',
          profile.blocked.isEmpty ? 'المحظورين' : 'المحظورين (${arabicNumber(profile.blocked.length)})',
          () => _showBlocked(context),
        ),
        item('chat', 'تواصل معنا', () => _showFeedback(context), semantics: 'تواصل معنا'),
        item('info', 'سياسة الخصوصية', () => _open('privacy')),
        item('log', 'شروط الاستخدام', () => _open('terms')),
        item('exit', 'حذف الحساب', () => _deleteAccount(context), color: const Color(0xFFFF9A8A)),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 4),
          child: Text(
            'نسخة ${appBuild == 'dev' ? 'تجريبية' : arabicNumber(int.tryParse(appBuild) ?? 0)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: socMuted, fontSize: 12, fontFamily: kufi, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// صفحات الموقع (site/): الخصوصية والشروط.
Future<void> _open(String page) =>
    launchUrl(Uri.parse('https://majlis-game-1d739.web.app/$page'), mode: LaunchMode.externalApplication);

void _toast(BuildContext context, String text) =>
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));

/// اللي حظرتهم، وتقدر تفك الحظر.
Future<void> _showBlocked(BuildContext context) => showSocDialog<void>(
  context,
  title: 'المحظورين',
  width: 520,
  builder: (context) => ValueListenableBuilder(
    valueListenable: Backend.instance.profile,
    builder: (context, p, _) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SocPopupText('ما تشوف ردودهم ولا رأيهم، وما نحطك معهم في الطاولات العامة', size: 13.5, muted: true),
        const SizedBox(height: 10),
        if (p.blocked.isEmpty)
          const Padding(padding: EdgeInsets.all(18), child: SocPopupText('ما حظرت أحد'))
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView(shrinkWrap: true, children: [for (final uid in p.blocked) _BlockedRow(uid: uid)]),
          ),
        const SizedBox(height: 10),
        SocButton(
          label: 'تمام',
          tone: SocTone.green,
          height: 42,
          fontSize: 16,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  ),
);

class _BlockedRow extends StatelessWidget {
  const _BlockedRow({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Backend.instance.fetchPlayer(uid).catchError((_) => null),
      builder: (context, snap) {
        final e = snap.data;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SocAvatar(avatar: e?.avatar ?? 'masked', size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e?.name ?? 'لاعب',
                  style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 16, color: socInk),
                ),
              ),
              SocButton(
                label: 'فك الحظر',
                tone: SocTone.blue,
                height: 34,
                fontSize: 14,
                width: 96,
                onPressed: () async {
                  try {
                    await Backend.instance.setBlocked(uid, false);
                  } on BackendException catch (err) {
                    if (context.mounted) _toast(context, err.message);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// رسالة للمطور: مشكلة، أو اقتراح، أو أي شي.
Future<void> _showFeedback(BuildContext context) async {
  final controller = TextEditingController();
  var kind = 'bug';
  var busy = false;
  final sent = await showSocDialog<bool>(
    context,
    title: 'تواصل معنا',
    width: 500,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SocSegments<String>(
            light: true,
            options: const [('bug', 'مشكلة'), ('idea', 'اقتراح'), ('other', 'شي ثاني')],
            value: kind,
            onChanged: (v) => setState(() => kind = v),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLength: 1000,
            minLines: 3,
            maxLines: 5,
            style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w700, color: socInk),
            decoration: socParchInput(hint: 'اكتب لنا وش صار، أو وش تبي نضيف…', dense: false),
          ),
          const SizedBox(height: 10),
          SocActions(
            children: [
              SocButton(
                label: 'إلغاء',
                tone: SocTone.grey,
                height: 44,
                fontSize: 16,
                onPressed: () => Navigator.pop(context, false),
              ),
              SocButton(
                label: 'أرسل',
                tone: SocTone.green,
                height: 44,
                fontSize: 16,
                onPressed: busy
                    ? null
                    : () async {
                        setState(() => busy = true);
                        try {
                          await Backend.instance.sendFeedback(kind, controller.text, version: appBuild);
                          if (context.mounted) Navigator.pop(context, true);
                        } on BackendException catch (e) {
                          if (context.mounted) _toast(context, e.message);
                          setState(() => busy = false);
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    ),
  );
  if (sent == true && context.mounted) _toast(context, 'وصلت رسالتك، شكراً لك');
}

/// حذف الحساب نهائياً (بعد تأكيد): يرجع للترحيب بحساب ضيف جديد.
Future<void> _deleteAccount(BuildContext context) async {
  final ok = await socConfirm(
    context,
    title: 'تحذف حسابك نهائياً؟',
    body:
        'بينحذف اسمك ومستواك وذهبك وجواهرك وأغراضك وإنجازاتك ومكانك في الترتيب، وما نقدر نرجعها. '
        'لو حسابك مربوط بقوقل، ينفك الربط بعد.',
    yes: 'احذف حسابي',
    no: 'لا، رجعني',
    danger: true,
  );
  if (!ok || !context.mounted) return;
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  showSocDialog<void>(
    context,
    title: 'حذف الحساب',
    width: 360,
    dismissible: false,
    builder: (_) => const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: AppColors.goldDark),
        SizedBox(width: 16),
        SocPopupText('نحذف حسابك…'),
      ],
    ),
  );
  try {
    await Backend.instance.deleteAccount();
    navigator.popUntil((r) => r.isFirst);
    messenger.showSnackBar(const SnackBar(content: Text('انحذف حسابك. تقدر تبدأ من جديد متى ما تبي')));
  } on BackendException catch (e) {
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}
