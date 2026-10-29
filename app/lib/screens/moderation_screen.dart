import 'package:flutter/material.dart';

import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import '../widgets/design_social.dart';

/// للمطور: بلاغات اللاعبين (مجمّعة حسب اللاعب)، ورسائل "تواصل معنا"، وطلبات الحذف من الموقع.
class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  final _backend = Backend.instance;
  late Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>, List<Map<String, dynamic>>)> _data = _load();
  bool _busy = false;
  int _tab = 0;

  static const _reasons = {'name': 'اسم مسيء', 'behavior': 'تخريب', 'cheat': 'غش'};
  static const _kinds = {'bug': 'مشكلة', 'idea': 'اقتراح', 'other': 'شي ثاني'};

  Future<(List<Map<String, dynamic>>, List<Map<String, dynamic>>, List<Map<String, dynamic>>)> _load() async {
    final r = await _backend.devData('reports');
    final f = await _backend.devData('feedback');
    final d = await _backend.devData('deletionRequests');
    List<Map<String, dynamic>> list(Object? o) => [
      for (final x in (o as List?) ?? const []) Map<String, dynamic>.from(x as Map),
    ];
    return (list(r['reports']), list(f['feedback']), list(d['requests']));
  }

  Future<void> _deletion(String id, bool confirm) async {
    setState(() => _busy = true);
    try {
      final r = await _backend.devData('deleteUser', {'request': id, 'confirm': confirm});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['deleted'] == true ? 'انحذف الحساب' : 'انقفل الطلب')));
      }
      setState(() => _data = _load());
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resolve(String target, String decision) async {
    setState(() => _busy = true);
    try {
      await _backend.devData('resolveReport', {'target': target, 'decision': decision, 'days': 3});
      setState(() => _data = _load());
    } on BackendException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static const _title = TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 16, color: socCream, height: 1.3);
  static const _sub = TextStyle(color: socMuted, fontSize: 12.5, fontFamily: kufi, fontWeight: FontWeight.w700, height: 1.3);

  Widget _row({required Widget info, List<Widget> actions = const []}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: SocPlankRow(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(child: info),
          for (final a in actions) Padding(padding: const EdgeInsetsDirectional.only(start: 6), child: a),
        ],
      ),
    ),
  );

  Widget _deletionRow(Map<String, dynamic> d) => _row(
    info: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${d['name']}  ·  ${_date(d['at'])}', style: _title),
        Text(
          d['uid'] == null ? 'ما لقينا حساب بهالاسم' : 'لقينا الحساب',
          style: TextStyle(
            color: d['uid'] == null ? const Color(0xFFFF9A8A) : socGreenText,
            fontSize: 13,
            fontFamily: kufi,
            fontWeight: FontWeight.w800,
          ),
        ),
        if ('${d['details']}'.isNotEmpty) Text('${d['details']}', style: const TextStyle(color: socCream, height: 1.4)),
        if ('${d['contact']}'.isNotEmpty) Text('للتواصل: ${d['contact']}', style: _sub),
      ],
    ),
    actions: [
      if (d['uid'] != null)
        SocButton(
          label: 'احذف الحساب',
          tone: SocTone.red,
          height: 34,
          fontSize: 13.5,
          width: 118,
          onPressed: _busy ? null : () => _deletion(d['id'] as String, true),
        ),
      SocButton(
        label: 'اقفل الطلب',
        tone: SocTone.grey,
        height: 34,
        fontSize: 13.5,
        width: 106,
        onPressed: _busy ? null : () => _deletion(d['id'] as String, false),
      ),
    ],
  );

  static String _date(Object? ms) {
    if (ms is! num) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ms.toInt());
    return '${arabicNumber(d.day)}/${arabicNumber(d.month)} ${arabicNumber(d.hour)}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _empty(String text) => Center(child: Text(text, style: _sub.copyWith(fontSize: 16)));

  @override
  Widget build(BuildContext context) {
    return SocScaffold(
      title: 'البلاغات والرسائل',
      icon: const Gfx('warning', size: 28),
      currency: false,
      trailing: SocButton(
        label: 'تحديث',
        tone: SocTone.blue,
        height: 32,
        fontSize: 14,
        onPressed: () => setState(() => _data = _load()),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
        child: WoodPanel(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  for (final (i, label) in const ['البلاغات', 'الرسائل', 'طلبات الحذف'].indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: SocTabPill(label: label, selected: _tab == i, onTap: () => setState(() => _tab = i)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder(
                  future: _data,
                  builder: (context, snap) {
                    if (snap.hasError) return Center(child: Text('${snap.error}', style: _sub));
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                    final (reports, feedback, deletions) = snap.data!;
                    return switch (_tab) {
                      0 =>
                        reports.isEmpty
                            ? _empty('ما فيه بلاغات مفتوحة')
                            : ListView(
                                children: [
                                  for (final r in reports)
                                    _row(
                                      info: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${r['name']}، ${arabicNumber((r['count'] as num).toInt())} بلاغ', style: _title),
                                          Text(
                                            [
                                              for (final MapEntry(:key, :value) in (r['reasons'] as Map).entries)
                                                '${_reasons[key] ?? key}: ${arabicNumber((value as num).toInt())}',
                                            ].join('، '),
                                            style: _sub,
                                          ),
                                          Text('آخر بلاغ ${_date(r['last'])}', style: _sub),
                                        ],
                                      ),
                                      actions: [
                                        for (final (decision, label, tone) in const [
                                          ('rename', 'غيّر اسمه', SocTone.orange),
                                          ('ban', 'امنعه ٣ أيام', SocTone.red),
                                          ('dismiss', 'ما فيه شي', SocTone.grey),
                                        ])
                                          SocButton(
                                            label: label,
                                            tone: tone,
                                            height: 34,
                                            fontSize: 13.5,
                                            width: 112,
                                            onPressed: _busy ? null : () => _resolve(r['target'] as String, decision),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                      1 =>
                        feedback.isEmpty
                            ? _empty('ما فيه رسائل')
                            : ListView(
                                children: [
                                  for (final f in feedback)
                                    _row(
                                      info: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${f['name']}  ·  ${_kinds[f['kind']] ?? f['kind']}  ·  ${_date(f['at'])}  ·  نسخة ${f['version'] ?? ''}',
                                            style: _title.copyWith(color: socGoldHi, fontSize: 13.5),
                                          ),
                                          const SizedBox(height: 4),
                                          Text('${f['text']}', style: const TextStyle(height: 1.5, color: socCream)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                      _ =>
                        deletions.isEmpty
                            ? _empty('ما فيه طلبات حذف')
                            : ListView(children: [for (final d in deletions) _deletionRow(d)]),
                    };
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
