import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/profile.dart';
import '../services/backend.dart';
import '../theme.dart';
import 'common.dart';
import 'ui.dart';

/// رقم النسخة من البناء (CI يمرره: --dart-define=BUILD=رقم التشغيل).
const appBuild = String.fromEnvironment('BUILD', defaultValue: 'dev');

/// الإعدادات في ملفك: المحظورين، وتواصل معنا، وحذف الحساب.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    Widget item(String icon, String label, VoidCallback onTap, {Color? color, String? semantics}) => Semantics(
      button: true,
      label: semantics ?? label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
          child: Row(
            children: [
              Gfx(icon, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color),
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.muted, size: 20),
            ],
          ),
        ),
      ),
    );
    return Panel(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Column(
        children: [
          item(
            'lock',
            profile.blocked.isEmpty ? 'المحظورين' : 'المحظورين (${arabicNumber(profile.blocked.length)})',
            () => _showBlocked(context),
          ),
          item('chat', 'تواصل معنا', () => _showFeedback(context), semantics: 'تواصل معنا'),
          item('info', 'سياسة الخصوصية', () => _open('privacy')),
          item('log', 'شروط الاستخدام', () => _open('terms')),
          item('exit', 'حذف الحساب', () => _deleteAccount(context), color: AppColors.traitorLight),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Text(
              'نسخة ${appBuild == 'dev' ? 'تجريبية' : arabicNumber(int.tryParse(appBuild) ?? 0)}',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// صفحات الموقع (site/): الخصوصية والشروط.
Future<void> _open(String page) =>
    launchUrl(Uri.parse('https://majlis-game-1d739.web.app/$page'), mode: LaunchMode.externalApplication);

void _toast(BuildContext context, String text) =>
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));

/// اللي حظرتهم، وتقدر تفك الحظر.
Future<void> _showBlocked(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: AppColors.panel,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
  constraints: const BoxConstraints(maxWidth: 560),
  builder: (context) => ValueListenableBuilder(
    valueListenable: Backend.instance.profile,
    builder: (context, p, _) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'المحظورين',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: kufi, fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const Text(
              'ما تشوف ردودهم ولا رأيهم، وما نحطك معهم في الطاولات العامة',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            if (p.blocked.isEmpty)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text('ما حظرت أحد', textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView(shrinkWrap: true, children: [for (final uid in p.blocked) _BlockedRow(uid: uid)]),
              ),
          ],
        ),
      ),
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
              PlayerAvatar(avatar: e?.avatar ?? 'masked', size: 38, animate: false),
              const SizedBox(width: 10),
              Expanded(
                child: Text(e?.name ?? 'لاعب', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await Backend.instance.setBlocked(uid, false);
                  } on BackendException catch (err) {
                    if (context.mounted) _toast(context, err.message);
                  }
                },
                child: const Text('فك الحظر'),
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
  final sent = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Row(children: [Gfx('chat', size: 28), SizedBox(width: 8), Text('تواصل معنا')]),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (id, label) in const [('bug', 'مشكلة'), ('idea', 'اقتراح'), ('other', 'شي ثاني')])
                      ChoiceChip(
                        label: Text(label),
                        selected: kind == id,
                        onSelected: (_) => setState(() => kind = id),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  maxLength: 1000,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'اكتب لنا وش صار، أو وش تبي نضيف…',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: GameButton(
                    label: 'إلغاء',
                    tone: ButtonTone.ghost,
                    height: 44,
                    fontSize: 15,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GameButton(
                    label: 'أرسل',
                    height: 44,
                    fontSize: 15,
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
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
  if (sent == true && context.mounted) _toast(context, 'وصلت رسالتك، شكراً لك');
}

/// حذف الحساب نهائياً (بعد تأكيد): يرجع للترحيب بحساب ضيف جديد.
Future<void> _deleteAccount(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('تحذف حسابك نهائياً؟', textAlign: TextAlign.center),
      content: const Text(
        'بينحذف اسمك ومستواك وذهبك وجواهرك وأغراضك وإنجازاتك ومكانك في الترتيب، وما نقدر نرجعها. '
        'لو حسابك مربوط بقوقل، ينفك الربط بعد.',
        textAlign: TextAlign.center,
        style: TextStyle(height: 1.6),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: GameButton(
                label: 'لا، رجعني',
                tone: ButtonTone.ghost,
                height: 44,
                fontSize: 15,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GameButton(
                label: 'احذف حسابي',
                tone: ButtonTone.red,
                height: 44,
                fontSize: 15,
                onPressed: () => Navigator.pop(context, true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(color: AppColors.gold),
          SizedBox(width: 16),
          Text('نحذف حسابك…'),
        ],
      ),
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
