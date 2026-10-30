import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import 'backend.dart';

/// حالة اتصالي: والتطبيق مفتوح قدامي أكتب نبضة كل ٣ دقايق (presence/{uid}، الوقت وقت السيرفر)، ولما يروح
/// للخلفية أكتب إني طلعت. أصحابي وربعي في الديوان يشوفونها (firestore.rules).
class PresenceService with WidgetsBindingObserver {
  PresenceService._();

  static final instance = PresenceService._();
  static const _beat = Duration(minutes: 3);

  Timer? _timer;
  bool _started = false;

  void start() {
    if (_started || !Backend.instance.isReady) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _online();
  }

  void _online() {
    _timer?.cancel();
    _write(true);
    _timer = Timer.periodic(_beat, (_) => _write(true));
  }

  void _away() {
    _timer?.cancel();
    _timer = null;
    _write(false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _online();
      case AppLifecycleState.paused || AppLifecycleState.hidden || AppLifecycleState.detached:
        _away();
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _write(bool on) {
    final backend = Backend.instance;
    if (!backend.isReady) return;
    backend.db
        .doc('presence/${backend.uid}')
        .set({'t': FieldValue.serverTimestamp(), 'on': on})
        .catchError((_) {});
  }
}
