import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../models/catalog.dart';
import '../models/leaderboard.dart';
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

  /// إيميل قوقل لو الحساب مربوط، و null لو ضيف.
  final googleEmail = ValueNotifier<String?>(null);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

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
      FirebaseAuth.instance.userChanges().listen((u) => googleEmail.value = _googleOf(u)?.email ?? _googleOf(u)?.uid);
      await _openAccount();
    } catch (e) {
      debugPrint('Firebase init failed: $e');
    }
    return _ready;
  }

  /// يتابع ملف الحساب الحالي. ينعاد بعد كل تبديل حساب.
  Future<void> _openAccount() async {
    await _profileSub?.cancel();
    profileLoaded.value = false;
    _profileSub = _db.doc('users/$uid').snapshots().listen((s) {
      if (!s.exists) return;
      profile.value = Profile.fromJson(s.data()!);
      profileLoaded.value = true;
    }, onError: (Object e) => debugPrint('profile listener: $e'));
    await _call('ensureProfile', {});
  }

  static UserInfo? _googleOf(User? u) =>
      u?.providerData.where((p) => p.providerId == GoogleAuthProvider.PROVIDER_ID).firstOrNull;

  bool get isLinked => _googleOf(FirebaseAuth.instance.currentUser) != null;

  /// اسمه في قوقل، نقترحه عليه أول مرة يختار اسمه.
  String? get googleName {
    final name = _googleOf(FirebaseAuth.instance.currentUser)?.displayName?.trim();
    if (name == null || name.isEmpty) return null;
    final first = name.split(' ').first;
    return first.length > 16 ? first.substring(0, 16) : first;
  }

  /// عميل الويب من google-services.json، قوقل ترجع توكن له عشان Firebase تتحقق منه.
  static const _webClientId = '1041177786311-gma3962uiqmqb1lbtfqdal99usg7hjj3.apps.googleusercontent.com';
  bool _googleReady = false;

  /// يفتح نافذة اختيار الحساب من الجوال نفسه (مو متصفح). null لو سكّرها.
  Future<AuthCredential?> _googleCredential() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(serverClientId: _webClientId);
      _googleReady = true;
    }
    try {
      final account = await google.authenticate();
      return GoogleAuthProvider.credential(idToken: account.authentication.idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      debugPrint('Google sign-in failed: ${e.code} ${e.description}');
      throw BackendException('ما قدرنا نوصل لحسابك في قوقل، جرّب مرة ثانية');
    }
  }

  /// يربط حساب الضيف الحالي بقوقل، فيبقى نفس الحساب بكل تقدمه.
  /// لو حساب قوقل هذا مربوط من قبل بلاعب ثاني، يرجع [GoogleLink.taken] ومعه اللي نحتاجه عشان ندخل عليه.
  Future<GoogleLink> linkGoogle() async {
    final user = FirebaseAuth.instance.currentUser!;
    AuthCredential? credential;
    try {
      if (kIsWeb) {
        await user.linkWithPopup(GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'}));
      } else {
        credential = await _googleCredential();
        if (credential == null) return const GoogleLink.cancelled();
        await user.linkWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'credential-already-in-use' || 'email-already-in-use':
          return GoogleLink.taken(e.credential ?? credential);
        case 'provider-already-linked':
          break;
        case 'popup-closed-by-user' || 'cancelled-popup-request':
          return const GoogleLink.cancelled();
        default:
          debugPrint('Google link failed: ${e.code} ${e.message}');
          throw BackendException('ما قدرنا نربط حسابك بقوقل، جرّب مرة ثانية');
      }
    }
    // التوكن الجديد فيه هوية قوقل، والسيرفر يتأكد منها قبل يعطي المكافأة.
    await user.getIdToken(true);
    await user.reload();
    final r = await _call('claimLinkReward', {});
    return GoogleLink.linked(r['coins'] as int);
  }

  /// يترك حساب الضيف ويدخل على حساب قوقل اللي مربوط من قبل.
  Future<void> switchToGoogle(AuthCredential? credential) async {
    final auth = FirebaseAuth.instance;
    try {
      if (credential != null) {
        await auth.signInWithCredential(credential);
      } else if (kIsWeb) {
        await auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final fresh = await _googleCredential();
        if (fresh == null) return;
        await auth.signInWithCredential(fresh);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in failed: ${e.code} ${e.message}');
      throw BackendException('ما قدرنا ندخل على حسابك، جرّب مرة ثانية');
    }
    await _openAccount();
  }

  /// يطلع من حساب قوقل ويبدأ كضيف جديد. الحساب يبقى محفوظ ويرجع له متى ما دخل بقوقل.
  Future<void> signOut() async {
    // نوقف متابعة الملف القديم قبل الخروج، وإلا يطلع خطأ صلاحيات من Firestore.
    await _profileSub?.cancel();
    _profileSub = null;
    if (!kIsWeb && _googleReady) await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance.signInAnonymously();
    await _openAccount();
  }

  /// كل الطلبات تمر من دالة وحدة في السيرفر (api): تبقى صاحية من أول طلب، فالأزرار ترد بسرعة.
  late final _api = _functions.httpsCallable('api');

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    try {
      final result = await _api.call<Map<String, dynamic>>({'fn': name, 'data': data});
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      // نسخة الويب تضيف رقم الحالة آخر الرسالة (مثل [400])، ما نحتاجه.
      throw BackendException((e.message ?? 'صار خطأ، جرّب مرة ثانية').replaceAll(RegExp(r'\s*\[\d{3}\]$'), ''));
    } catch (e) {
      debugPrint('$name failed: $e');
      throw BackendException('ما قدرنا نوصل للسيرفر، تأكد من النت وجرّب مرة ثانية');
    }
  }

  Future<void> updateProfile({required String name, required String avatar}) =>
      _call('updateProfile', {'name': name, 'avatar': avatar});

  /// يرجع المكافأة اللي انضافت.
  Future<({int coins, int diamonds, int streak})> claimDaily() async {
    final r = await _call('claimDaily', {});
    return (coins: r['coins'] as int, diamonds: r['diamonds'] as int, streak: r['streak'] as int);
  }

  /// الروم الخاص: يضيف بوت واحد. الطاولة العامة: يكملها كلها ببوتات (بعد ٢٠ ثانية انتظار).
  Future<void> addBots(String code) => _call('addBots', {'code': code});

  Future<void> removeBot(String code, String botId) => _call('removeBot', {'code': code, 'botId': botId});

  Future<void> buyItem(String id) => _call('buyItem', {'id': id});

  Future<void> equipItem(String id) => _call('equipItem', {'id': id});

  Future<void> registerPushToken(String token) => _call('registerPushToken', {'token': token});

  /// يرجع كم ذهب انضاف.
  Future<int> claimMission(String id) async => (await _call('claimMission', {'id': id}))['coins'] as int;

  /// يطلب من السيرفر يلعب بدال اللي خلص وقته. يرجع true لو انطبق.
  Future<bool> timeout(String code) async => (await _call('timeout', {'code': code}))['applied'] == true;

  /// أفضل ٥٠ لاعب: هذا الأسبوع (بعدد الفوز فيه)، أو من البداية، أو بالمستوى.
  Stream<List<LeaderboardEntry>> watchLeaderboard(Board board) {
    final col = _db.collection('leaderboard');
    final q = switch (board) {
      Board.weekly => col.where('week', isEqualTo: gulfWeek(DateTime.now())).orderBy('weeklyWins', descending: true),
      Board.allTime => col.orderBy('gamesWon', descending: true),
      Board.level => col.orderBy('level', descending: true).orderBy('xp', descending: true),
      Board.ranked => col.where('rankSeason', isEqualTo: season.id).orderBy('rankPoints', descending: true),
    };
    return q.limit(50).snapshots().map((s) => [for (final d in s.docs) LeaderboardEntry.fromJson(d.id, d.data())]);
  }

  Future<String> createRoom({required int maxPlayers, bool quick = false}) async {
    final r = await _call('createRoom', {'maxPlayers': maxPlayers, 'quick': quick});
    return r['code'] as String;
  }

  Future<String> joinRoom(String code) async {
    final r = await _call('joinRoom', {'code': code});
    return r['code'] as String;
  }

  Future<String> quickMatch({required int maxPlayers, required String tierId, bool quick = false}) async {
    final r = await _call('quickMatch', {'maxPlayers': maxPlayers, 'tierId': tierId, 'quick': quick});
    return r['code'] as String;
  }

  /// لعبة الشرح: أنت و٤ بوتات، تبدأ على طول، ويرجع رمزها.
  Future<String> startTutorial() async => (await _call('startTutorial', const {}))['code'] as String;

  /// تدريب: روم خاص فيه أنت و٤ بوتات، يبدأ على طول بطلب واحد، ويرجع رمزه.
  Future<String> startTraining() async => (await _call('startTraining', const {}))['code'] as String;

  Future<void> leaveRoom(String code) => _call('leaveRoom', {'code': code});

  Future<void> startGame(String code) => _call('startGame', {'code': code});

  Future<void> act(String code, Map<String, dynamic> action) => _call('act', {'code': code, 'action': action});

  /// أدوات المطور (السيرفر يرفضها لغير المطور).
  Future<void> devTool(String action, [Map<String, dynamic> data = const {}]) =>
      _call('devTool', {'action': action, ...data});

  /// أدوات المطور اللي ترجع بيانات (البلاغات والرسائل).
  Future<Map<String, dynamic>> devData(String action, [Map<String, dynamic> data = const {}]) =>
      _call('devTool', {'action': action, ...data});

  /// يطلع من لعبة شغالة، ويكمل عنه بوت.
  Future<void> leaveGame(String code) => _call('leaveGame', {'code': code});

  Future<void> clearOpinion(String code, String target) => _call('clearOpinion', {'code': code, 'target': target});

  /// رد في الطاولة: كلام (textReactions) أو ملصق (stickers).
  Future<void> react(String code, String kind, {String? target}) =>
      _call('react', {'code': code, 'kind': kind, 'target': ?target});

  /// الملف العام لأي لاعب (نفس سطره في الترتيب). null لو ما له ملف (مثل البوت).
  Future<LeaderboardEntry?> fetchPlayer(String uid) async {
    final d = await _db.doc('leaderboard/$uid').get();
    return d.exists ? LeaderboardEntry.fromJson(d.id, d.data()!) : null;
  }

  /// بلاغ عن لاعب: name (اسم مسيء)، behavior (يخرّب اللعب)، cheat (غش). يرجع true لو بلّغت عنه قبل اليوم.
  Future<bool> reportPlayer(String uid, String reason, {String? code}) async =>
      (await _call('reportPlayer', {'uid': uid, 'reason': reason, 'code': ?code}))['already'] == true;

  Future<void> setBlocked(String uid, bool blocked) => _call('setBlocked', {'uid': uid, 'blocked': blocked});

  /// يدور لاعب برمزه.
  Future<LeaderboardEntry> findPlayer(String pid) async {
    final r = await _call('findPlayer', {'pid': pid});
    return LeaderboardEntry.fromJson(r['uid'] as String, r);
  }

  /// طلب صداقة. يرجع 'sent' (انرسل)، أو 'accepted' (كان مرسل لك، فصرتوا أصدقاء)، أو 'friends'.
  Future<String> friendRequest(String uid) async => (await _call('friendRequest', {'uid': uid}))['status'] as String;

  Future<void> friendRespond(String uid, bool accept) => _call('friendRespond', {'uid': uid, 'accept': accept});

  Future<void> removeFriend(String uid) => _call('removeFriend', {'uid': uid});

  /// يدعو صديق لرومك (الدعوة تطلع له في اللعبة وبإشعار).
  Future<void> inviteFriend(String uid, String code) => _call('inviteFriend', {'uid': uid, 'code': code});

  /// سعر رمز مميز ودرجته، وهل هو متاح.
  Future<PidQuote> quotePid(String pid) async => PidQuote.fromJson(await _call('quotePid', {'pid': pid}));

  /// اقتراحات رموز مميزة متاحة.
  Future<List<PidQuote>> suggestIds() async => [
    for (final q in (await _call('suggestIds', const {}))['list'] as List)
      PidQuote.fromJson({...Map<String, dynamic>.from(q as Map), 'available': true}),
  ];

  Future<void> buyPid(String pid) => _call('buyPid', {'pid': pid});

  Future<void> sendFeedback(String kind, String text, {String? version}) =>
      _call('sendFeedback', {'kind': kind, 'text': text, 'version': ?version});

  /// يحذف الحساب نهائياً من السيرفر، ثم يبدأ حساب ضيف جديد.
  Future<void> deleteAccount() async {
    await _call('deleteAccount', const {});
    await signOut();
  }

  /// يشيل الهدايا اللي شافها.
  Future<void> ackGifts() => _call('ackGifts', const {});

  /// يشتري المسار المدفوع في الباتل باس.
  Future<void> buyPass() => _call('buyPass', const {});

  /// يستلم مكافآت الباتل باس. يرجّع اللي أخذه.
  Future<({int coins, int diamonds, List<String> items})> claimPassRewards() async {
    final r = await _call('claimPassRewards', const {});
    return (
      coins: (r['coins'] as num?)?.toInt() ?? 0,
      diamonds: (r['diamonds'] as num?)?.toInt() ?? 0,
      items: [for (final i in (r['items'] as List?) ?? const []) i as String],
    );
  }

  /// أبطال الأسبوع الحاليين (meta/champions).
  Stream<Champions?> watchChampions() =>
      _db.doc('meta/champions').snapshots().map((s) => s.exists ? Champions.fromJson(s.data()!) : null);

  Stream<Room?> watchRoom(String code) =>
      _db.doc('rooms/$code').snapshots().map((s) => s.exists ? Room.fromJson(s.data()!) : null);

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

/// نتيجة محاولة ربط الحساب بقوقل.
sealed class GoogleLink {
  const GoogleLink();
  const factory GoogleLink.linked(int reward) = GoogleLinked;
  const factory GoogleLink.taken(AuthCredential? credential) = GoogleTaken;
  const factory GoogleLink.cancelled() = GoogleCancelled;
}

class GoogleLinked extends GoogleLink {
  const GoogleLinked(this.reward);
  final int reward;
}

class GoogleTaken extends GoogleLink {
  const GoogleTaken(this.credential);
  final AuthCredential? credential;
}

class GoogleCancelled extends GoogleLink {
  const GoogleCancelled();
}

/// سعر رمز مميز (من السيرفر).
class PidQuote {
  PidQuote.fromJson(Map<String, dynamic> j)
    : pid = j['pid'] as String,
      price = (j['price'] as num).toInt(),
      tier = (j['tier'] as num).toInt(),
      available = j['available'] as bool? ?? false,
      mine = j['mine'] as bool? ?? false;

  final String pid;
  final int price;
  final int tier;
  final bool available;
  final bool mine;
}
