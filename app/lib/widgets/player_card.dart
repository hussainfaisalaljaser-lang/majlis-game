import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/leaderboard.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/notes.dart';
import '../theme.dart';
import 'badges.dart';
import 'common.dart';
import 'ui.dart';

/// بطاقة لاعب: صورته ومستواه وإحصائياته وإنجازاته (من ملفه العام)، ومنها تحظره أو تبلّغ عنه.
/// في اللعبة فيها كمان ملاحظتك الخاصة عليه ([note] و[onNote]).
Future<void> showPlayerCard(
  BuildContext context, {
  required String uid,
  required String name,
  required String avatar,
  String? frame,
  bool bot = false,
  String? code,
  NoteMark? note,
  ValueChanged<NoteMark?>? onNote,
}) {
  HapticFeedback.selectionClick();
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: _PlayerCard(
        uid: uid,
        name: name,
        avatar: avatar,
        frame: frame,
        bot: bot,
        code: code,
        note: note,
        onNote: onNote,
      ),
    ),
  );
}

class _PlayerCard extends StatefulWidget {
  const _PlayerCard({
    required this.uid,
    required this.name,
    required this.avatar,
    required this.frame,
    required this.bot,
    required this.code,
    required this.note,
    required this.onNote,
  });

  final String uid;
  final String name;
  final String avatar;
  final String? frame;
  final bool bot;
  final String? code;
  final NoteMark? note;
  final ValueChanged<NoteMark?>? onNote;

  @override
  State<_PlayerCard> createState() => _PlayerCardState();
}

class _PlayerCardState extends State<_PlayerCard> {
  final _backend = Backend.instance;
  late final Future<LeaderboardEntry?> _entry = widget.bot || !_backend.isReady
      ? Future.value(null)
      : _backend.fetchPlayer(widget.uid).catchError((_) => null);
  bool _busy = false;

  bool get _me => _backend.isReady && widget.uid == _backend.uid;

  void _toast(String text) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _toggleBlock(bool blocked) async {
    if (!blocked) {
      final ok = await _confirm(
        'تحظر ${widget.name}؟',
        'ما بتشوف ردوده ولا رأيه في الطاولة، وما نحطك معه في الطاولات العامة. تقدر تفك الحظر من ملفك.',
        'احظره',
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    try {
      await _backend.setBlocked(widget.uid, !blocked);
      _toast(blocked ? 'فكّيت الحظر عن ${widget.name}' : 'حظرت ${widget.name}');
    } on BackendException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirm(String title, String body, String yes) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, textAlign: TextAlign.center),
      content: Text(body, textAlign: TextAlign.center),
      actions: [
        Row(
          children: [
            Expanded(
              child: GameButton(
                label: 'لا',
                tone: ButtonTone.ghost,
                height: 44,
                fontSize: 15,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GameButton(
                label: yes,
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

  Future<void> _report() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('بلاغ عن ${widget.name}', textAlign: TextAlign.center),
        children: [
          for (final (id, icon, label, hint) in const [
            ('name', 'edit', 'اسمه مسيء', 'كلام بذيء أو إساءة في الاسم'),
            ('behavior', 'warning', 'يخرّب اللعب أو يزعج', 'يتعمد يخسّر فريقه، أو يضايق اللاعبين'),
            ('cheat', 'liar', 'غش', 'يتفق مع لاعبين برا اللعبة، أو يستغل خلل'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, id),
              child: Row(
                children: [
                  Gfx(icon, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        Text(hint, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final already = await _backend.reportPlayer(widget.uid, reason, code: widget.code);
      _toast(already ? 'بلّغت عنه اليوم، وبلاغك عندنا' : 'وصل بلاغك، شكراً لك. نراجعه بأسرع وقت');
    } on BackendException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = frameStyle(widget.frame);
    return Container(
      width: 620,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .94),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(.7, -.8),
          radius: 1.3,
          colors: [Color(0xFF4A3394), AppColors.panel],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.gold.withValues(alpha: .55), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 30)],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: FutureBuilder<LeaderboardEntry?>(
          future: _entry,
          builder: (context, snap) {
            final e = snap.data;
            final loading = snap.connectionState != ConnectionState.done;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الصورة والاسم
                SizedBox(
                  width: 170,
                  child: Column(
                    children: [
                      PlayerAvatar(
                        avatar: e?.avatar ?? widget.avatar,
                        style: style,
                        frame: style == null ? AppColors.gold : null,
                        size: 96,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _me ? '${widget.name} (أنت)' : (e?.name ?? widget.name),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: kufi, fontSize: 19, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      if (widget.bot)
                        const _Chip(icon: 'bot', text: 'بوت يلعب معكم')
                      else if (e != null)
                        _Chip(icon: 'xp', text: 'مستوى ${arabicNumber(e.level)}'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.bot)
                        const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 10),
                          child: Text(
                            'البوت لاعب آلي يكمّل الطاولة. ما عنده ملف، ويلعب بنفس القوانين ويقدر يكذب مثلك.',
                            style: TextStyle(fontSize: 14, height: 1.6),
                          ),
                        )
                      else if (loading)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                        )
                      else if (e != null) ...[
                        Row(
                          children: [
                            _Stat('games', arabicNumber(e.gamesPlayed), 'لعبة'),
                            _Stat('trophy', arabicNumber(e.gamesWon), 'فوز'),
                            _Stat('winrate', '${arabicNumber(e.winRate)}٪', 'نسبة الفوز'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'الإنجازات',
                          style: TextStyle(fontFamily: kufi, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        BadgeStrip(badges: e.badges, size: 38),
                      ],
                      if (widget.onNote != null && !_me) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'ملاحظتك الخاصة (محد يشوفها غيرك)',
                          style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                        ),
                        const SizedBox(height: 6),
                        _NoteRow(
                          note: widget.note,
                          onNote: (m) {
                            widget.onNote!(m);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                      if (!_me && !widget.bot && _backend.isReady) ...[
                        const SizedBox(height: 12),
                        ValueListenableBuilder(
                          valueListenable: _backend.profile,
                          builder: (context, p, _) {
                            final blocked = p.blocked.contains(widget.uid);
                            return Row(
                              children: [
                                Expanded(
                                  child: GameButton(
                                    label: blocked ? 'فك الحظر' : 'حظر',
                                    semantics: blocked ? 'فك الحظر' : 'حظر اللاعب',
                                    icon: Gfx(blocked ? 'check' : 'lock', size: 22),
                                    tone: ButtonTone.ghost,
                                    height: 42,
                                    fontSize: 14,
                                    onPressed: _busy ? null : () => _toggleBlock(blocked),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GameButton(
                                    label: 'بلاغ',
                                    semantics: 'بلاغ عن اللاعب',
                                    icon: const Gfx('warning', size: 22),
                                    tone: ButtonTone.red,
                                    height: 42,
                                    fontSize: 14,
                                    onPressed: _busy ? null : _report,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .3),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.gold.withValues(alpha: .5)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Gfx(icon, size: 18),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label);

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: Column(
        children: [
          Gfx(icon, size: 24),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
        ],
      ),
    ),
  );
}

/// ملاحظتك الخاصة على اللاعب في هالطاولة: أثق، مو متأكد، أشك (ونفسها مرة ثانية تشيلها).
class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, required this.onNote});

  final NoteMark? note;
  final ValueChanged<NoteMark?> onNote;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (mark, label, tone) in const [
        (NoteMark.trust, 'أثق فيه', ButtonTone.green),
        (NoteMark.unsure, 'مو متأكد', ButtonTone.gold),
        (NoteMark.suspect, 'أشك فيه', ButtonTone.red),
      ])
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Opacity(
              opacity: note == null || note == mark ? 1 : .55,
              child: GameButton(
                label: label,
                icon: note == mark ? const Gfx('check', size: 20) : null,
                tone: tone,
                height: 40,
                fontSize: 13.5,
                onPressed: () => onNote(note == mark ? null : mark),
              ),
            ),
          ),
        ),
    ],
  );
}
