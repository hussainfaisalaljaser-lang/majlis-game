import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/leaderboard.dart';
import '../models/shop.dart';
import '../services/backend.dart';
import '../services/notes.dart';
import '../theme.dart';
import 'badges.dart';
import 'clan_crest.dart';
import 'common.dart';
import 'design_social.dart';
import 'friend_button.dart';
import 'pid.dart';

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
  return showSocDialog<void>(
    context,
    title: name,
    width: 640,
    rays: true,
    raysAt: const Alignment(.72, -.15),
    padding: const EdgeInsets.fromLTRB(22, 26, 22, 16),
    builder: (context) => _PlayerCard(
      uid: uid,
      name: name,
      avatar: avatar,
      frame: frame,
      bot: bot,
      code: code,
      note: note,
      onNote: onNote,
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
      final ok = await socConfirm(
        context,
        title: 'تحظر ${widget.name}؟',
        body: 'ما بتشوف ردوده ولا رأيه في الطاولة، وما نحطك معه في الطاولات العامة. تقدر تفك الحظر من ملفك.',
        yes: 'احظره',
        danger: true,
      );
      if (!ok) return;
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

  Future<void> _report() async {
    final reason = await showSocDialog<String>(
      context,
      title: 'بلاغ عن ${widget.name}',
      width: 460,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (id, icon, label, hint) in const [
            ('name', 'edit', 'اسمه مسيء', 'كلام بذيء أو إساءة في الاسم'),
            ('behavior', 'warning', 'يخرّب اللعب أو يزعج', 'يتعمد يخسّر فريقه، أو يضايق اللاعبين'),
            ('cheat', 'liar', 'غش', 'يتفق مع لاعبين برا اللعبة، أو يستغل خلل'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context, id),
                child: SocCard(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      Gfx(icon, size: 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 16, color: socCream),
                            ),
                            Text(
                              hint,
                              style: const TextStyle(color: socMuted, fontSize: 12.5, fontFamily: kufi, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
    return FutureBuilder<LeaderboardEntry?>(
      future: _entry,
      builder: (context, snap) {
        final e = snap.data;
        final loading = snap.connectionState != ConnectionState.done;
        return SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصورة (فوق الأشعة) وتحتها المستوى والرتبة والرمز
              SizedBox(
                width: 170,
                child: Column(
                  children: [
                    SocAvatar(avatar: e?.avatar ?? widget.avatar, style: style, size: 92, animate: true),
                    const SizedBox(height: 10),
                    if (_me)
                      const _Chip(icon: 'profile', text: 'أنت')
                    else if (widget.bot)
                      const _Chip(icon: 'bot', text: 'بوت يلعب معكم')
                    else if (e != null) ...[
                      _Chip(icon: 'xp', text: 'مستوى ${arabicNumber(e.level)}'),
                      const SizedBox(height: 6),
                      RankChip(points: e.rankPoints, size: 22),
                      if (e.pid.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        PidBadge(pid: e.pid, tier: e.pidTier, size: 12.5),
                      ],
                      if (e.clan case final clan?) ...[const SizedBox(height: 8), ClanBadge(tag: clan)],
                    ],
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
                        child: SocPopupText(
                          'البوت لاعب آلي يكمّل الطاولة. ما عنده ملف، ويلعب بنفس القوانين ويقدر يكذب مثلك.',
                          size: 14.5,
                        ),
                      )
                    else if (loading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator(color: AppColors.goldDark)),
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
                      const SocPopupText('الإنجازات', size: 16),
                      const SizedBox(height: 6),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: BadgeStrip(badges: e.badges, size: 38),
                      ),
                    ],
                    if (widget.onNote != null && !_me) ...[
                      const SizedBox(height: 12),
                      const SocPopupText('ملاحظتك الخاصة (محد يشوفها غيرك)', size: 13, muted: true),
                      const SizedBox(height: 6),
                      _NoteRow(
                        note: widget.note,
                        onNote: (m) {
                          widget.onNote!(m);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                    if (!_me && !widget.bot && _backend.isReady && e != null) ...[
                      const SizedBox(height: 12),
                      FriendButton(uid: widget.uid, name: e.name, width: double.infinity),
                    ],
                    if (!_me && !widget.bot && _backend.isReady) ...[
                      const SizedBox(height: 6),
                      ValueListenableBuilder(
                        valueListenable: _backend.profile,
                        builder: (context, p, _) {
                          final blocked = p.blocked.contains(widget.uid);
                          return Row(
                            children: [
                              Expanded(
                                child: SocButton(
                                  label: blocked ? 'فك الحظر' : 'حظر',
                                  semantics: blocked ? 'فك الحظر' : 'حظر اللاعب',
                                  icon: Gfx(blocked ? 'check' : 'lock', size: 20),
                                  tone: SocTone.grey,
                                  height: 40,
                                  fontSize: 15,
                                  onPressed: _busy ? null : () => _toggleBlock(blocked),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SocButton(
                                  label: 'بلاغ',
                                  semantics: 'بلاغ عن اللاعب',
                                  icon: const Gfx('warning', size: 20),
                                  tone: SocTone.red,
                                  height: 40,
                                  fontSize: 15,
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
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 3, 12, 3),
    decoration: BoxDecoration(
      color: const Color(0xFF3A2416),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFD9A84E), width: 1.8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Gfx(icon, size: 18),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(color: socGoldHi, fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 14, height: 1.3),
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
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SocCard(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Gfx(icon, size: 26),
            Text(
              value,
              style: const TextStyle(fontFamily: kufi, fontWeight: FontWeight.w800, fontSize: 18, color: socCream, height: 1.15),
            ),
            Text(
              label,
              style: const TextStyle(color: socMuted, fontSize: 12, fontFamily: kufi, fontWeight: FontWeight.w700, height: 1.1),
            ),
          ],
        ),
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
        (NoteMark.trust, 'أثق فيه', SocTone.green),
        (NoteMark.unsure, 'مو متأكد', SocTone.orange),
        (NoteMark.suspect, 'أشك فيه', SocTone.red),
      ])
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Opacity(
              opacity: note == null || note == mark ? 1 : .55,
              child: SocButton(
                label: label,
                icon: note == mark ? const Gfx('check', size: 18) : null,
                tone: tone,
                height: 38,
                fontSize: 14,
                padding: 6,
                onPressed: () => onNote(note == mark ? null : mark),
              ),
            ),
          ),
        ),
    ],
  );
}
