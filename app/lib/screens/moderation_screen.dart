import 'package:flutter/material.dart';

import '../services/backend.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(r['deleted'] == true ? 'انحذف الحساب' : 'انقفل الطلب')));
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

  Widget _deletionRow(Map<String, dynamic> d) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Panel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${d['name']}  ·  ${_date(d['at'])}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                Text(
                  d['uid'] == null ? 'ما لقينا حساب بهالاسم' : 'لقينا الحساب',
                  style: TextStyle(
                    color: d['uid'] == null ? AppColors.traitorLight : AppColors.green,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ('${d['details']}'.isNotEmpty) Text('${d['details']}'),
                if ('${d['contact']}'.isNotEmpty)
                  Text('للتواصل: ${d['contact']}', style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ],
            ),
          ),
          if (d['uid'] != null)
            SizedBox(
              width: 120,
              child: GameButton(
                label: 'احذف الحساب',
                tone: ButtonTone.red,
                height: 38,
                fontSize: 13,
                onPressed: _busy ? null : () => _deletion(d['id'] as String, true),
              ),
            ),
          const SizedBox(width: 6),
          SizedBox(
            width: 110,
            child: GameButton(
              label: 'اقفل الطلب',
              tone: ButtonTone.ghost,
              height: 38,
              fontSize: 13,
              onPressed: _busy ? null : () => _deletion(d['id'] as String, false),
            ),
          ),
        ],
      ),
    ),
  );

  static String _date(Object? ms) {
    if (ms is! num) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ms.toInt());
    return '${arabicNumber(d.day)}/${arabicNumber(d.month)} ${arabicNumber(d.hour)}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: NightScaffold(
        appBar: AppBar(
          title: const Text('البلاغات والرسائل'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'البلاغات'),
              Tab(text: 'الرسائل'),
              Tab(text: 'طلبات الحذف'),
            ],
          ),
          actions: [IconButton(onPressed: () => setState(() => _data = _load()), icon: const Icon(Icons.refresh))],
        ),
        body: FutureBuilder(
          future: _data,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('${snap.error}'));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.gold));
            final (reports, feedback, deletions) = snap.data!;
            return TabBarView(
              children: [
                reports.isEmpty
                    ? const Center(child: Text('ما فيه بلاغات مفتوحة'))
                    : ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          for (final r in reports)
                            Panel(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${r['name']}  ·  ${arabicNumber((r['count'] as num).toInt())} بلاغ',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                        ),
                                        Text(
                                          [
                                            for (final MapEntry(:key, :value) in (r['reasons'] as Map).entries)
                                              '${_reasons[key] ?? key}: ${arabicNumber((value as num).toInt())}',
                                          ].join('، '),
                                          style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                                        ),
                                        Text(
                                          'آخر بلاغ ${_date(r['last'])}',
                                          style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (final (decision, label, tone) in const [
                                    ('rename', 'غيّر اسمه', ButtonTone.gold),
                                    ('ban', 'امنعه ٣ أيام', ButtonTone.red),
                                    ('dismiss', 'ما فيه شي', ButtonTone.ghost),
                                  ])
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(start: 6),
                                      child: SizedBox(
                                        width: 110,
                                        child: GameButton(
                                          label: label,
                                          tone: tone,
                                          height: 38,
                                          fontSize: 13,
                                          onPressed: _busy ? null : () => _resolve(r['target'] as String, decision),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                feedback.isEmpty
                    ? const Center(child: Text('ما فيه رسائل'))
                    : ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          for (final f in feedback)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Panel(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${f['name']}  ·  ${_kinds[f['kind']] ?? f['kind']}  ·  ${_date(f['at'])}  ·  نسخة ${f['version'] ?? ''}',
                                      style: const TextStyle(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${f['text']}', style: const TextStyle(height: 1.5)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                deletions.isEmpty
                    ? const Center(child: Text('ما فيه طلبات حذف'))
                    : ListView(
                        padding: const EdgeInsets.all(14),
                        children: [for (final d in deletions) _deletionRow(d)],
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
