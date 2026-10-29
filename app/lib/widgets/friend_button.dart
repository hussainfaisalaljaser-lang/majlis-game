import 'package:flutter/material.dart';

import '../services/backend.dart';
import 'common.dart';
import 'design_social.dart';

void _toast(BuildContext context, String text) =>
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(text)));

/// زر الصداقة حسب الحالة: أضف صديق، انرسل الطلب، قبول (هو أرسل لك)، أو صديقك.
class FriendButton extends StatefulWidget {
  const FriendButton({super.key, required this.uid, required this.name, this.width = 150});

  final String uid;
  final String name;
  final double width;

  @override
  State<FriendButton> createState() => _FriendButtonState();
}

class _FriendButtonState extends State<FriendButton> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } on BackendException catch (e) {
      if (mounted) _toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// صديقك: الضغط يسألك تشيله من أصدقائك.
  Future<void> _remove(Backend backend) async {
    final ok = await socConfirm(context, title: 'تشيل ${widget.name} من أصدقائك؟', yes: 'شيله', danger: true);
    if (ok && mounted) await _run(() => backend.removeFriend(widget.uid));
  }

  @override
  Widget build(BuildContext context) {
    final backend = Backend.instance;
    return ValueListenableBuilder(
      valueListenable: backend.profile,
      builder: (context, p, _) {
        if (widget.uid == backend.uid) return const SizedBox.shrink();
        final (label, icon, tone, action) = p.friends.contains(widget.uid)
            ? ('صديقك', 'check', SocTone.grey, () => _remove(backend))
            : p.friendReqs.containsKey(widget.uid)
            ? (
                'قبول الصداقة',
                'friends',
                SocTone.green,
                () => _run(() async {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  await backend.friendRespond(widget.uid, true);
                  messenger?.showSnackBar(SnackBar(content: Text('صرت أنت و${widget.name} أصدقاء')));
                }),
              )
            : p.sentReqs.contains(widget.uid)
            ? ('انرسل الطلب', 'hourglass', SocTone.grey, null)
            : (
                'أضف صديق',
                'addfriend',
                SocTone.green,
                () => _run(() async {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  final status = await backend.friendRequest(widget.uid);
                  final text = status == 'accepted' ? 'صرت أنت و${widget.name} أصدقاء' : 'انرسل طلب الصداقة';
                  messenger?.showSnackBar(SnackBar(content: Text(text)));
                }),
              );
        return SocButton(
          label: label,
          icon: Gfx(icon, size: 20),
          tone: tone,
          width: widget.width,
          height: 40,
          fontSize: 15,
          onPressed: _busy ? null : action,
        );
      },
    );
  }
}
