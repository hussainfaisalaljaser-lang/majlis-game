import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../models/profile.dart';
import '../models/room.dart';

/// شغّل التطبيق مع `--dart-define=USE_EMULATOR=true` عشان يتصل بمحاكي Firebase على جهازك.
const _useEmulator = bool.fromEnvironment('USE_EMULATOR');
const _emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');

/// كل الاتصال بالسيرفر يمر من هنا.
class Backend {
  Backend._();
  static final instance = Backend._();

  bool _ready = false;
  bool get isReady => _ready;

  late final FirebaseFunctions _functions;
  late final FirebaseFirestore _db;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  /// ملف اللاعب الحالي، يتحدث مباشرة من السيرفر. بدون سيرفر يبقى على الملف التجريبي.
  final profile = ValueNotifier<Profile>(Profile.demo);

  /// هل وصل الملف من السيرفر؟ قبلها ما نعرف إذا اختار اسمه.
  final profileLoaded = ValueNotifier<bool>(false);

  /// يتصل بـ Firebase ويسجل دخول كضيف. يرجع false لو المنصة ما لها إعدادات (مثل الويب حالياً).
  Future<bool> init() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) return false;
    try {
      await Firebase.initializeApp(options: options);
      _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      _db = FirebaseFirestore.instance;
      if (_useEmulator) {
        await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
        _db.useFirestoreEmulator(_emulatorHost, 8080);
        _functions.useFunctionsEmulator(_emulatorHost, 5001);
      }
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      _ready = true;
      _db.doc('users/$uid').snapshots().listen((s) {
        if (!s.exists) return;
        profile.value = Profile.fromJson(s.data()!);
        profileLoaded.value = true;
      });
      await _call('ensureProfile', {});
    } catch (e) {
      debugPrint('Firebase init failed: $e');
    }
    return _ready;
  }

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    try {
      final result = await _functions.httpsCallable(name).call<Map<String, dynamic>>(data);
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw BackendException(e.message ?? 'صار خطأ، جرّب مرة ثانية');
    }
  }

  Future<void> updateProfile({required String name, required String avatar}) =>
      _call('updateProfile', {'name': name, 'avatar': avatar});

  /// يرجع المكافأة اللي انضافت.
  Future<({int coins, int diamonds, int streak})> claimDaily() async {
    final r = await _call('claimDaily', {});
    return (coins: r['coins'] as int, diamonds: r['diamonds'] as int, streak: r['streak'] as int);
  }

  Future<String> createRoom({required int maxPlayers}) async {
    final r = await _call('createRoom', {'maxPlayers': maxPlayers});
    return r['code'] as String;
  }

  Future<String> joinRoom(String code) async {
    final r = await _call('joinRoom', {'code': code});
    return r['code'] as String;
  }

  Future<String> quickMatch({required int maxPlayers, required String tierId}) async {
    final r = await _call('quickMatch', {'maxPlayers': maxPlayers, 'tierId': tierId});
    return r['code'] as String;
  }

  Future<void> leaveRoom(String code) => _call('leaveRoom', {'code': code});

  Future<void> startGame(String code) => _call('startGame', {'code': code});

  Future<void> act(String code, Map<String, dynamic> action) => _call('act', {'code': code, 'action': action});

  Future<void> react(String code, ReactionKind kind, {String? target}) =>
      _call('react', {'code': code, 'kind': kind.name, 'target': ?target});

  Stream<Room?> watchRoom(String code) => _db
      .doc('rooms/$code')
      .snapshots()
      .map((s) => s.exists ? Room.fromJson(s.data()!) : null);

  /// نسخة اللاعب من اللعبة (فيها أسراره هو بس).
  Stream<Map<String, dynamic>?> watchView(String code) =>
      _db.doc('games/$code/views/$uid').snapshots().map((s) => s.data());
}

class BackendException implements Exception {
  BackendException(this.message);
  final String message;

  @override
  String toString() => message;
}
