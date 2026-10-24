import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// إعدادات Firebase. القيم من ملف android/app/google-services.json، وهي مو سرية.
///
/// نسخة الويب تحتاج تضيف "Web app" في Firebase Console وتحط إعداداتها هنا.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) return const bool.fromEnvironment('USE_EMULATOR') ? webEmulator : null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      _ => null,
    };
  }

  /// للتجربة على المحاكي من المتصفح بس، ما تشتغل مع السيرفر الحقيقي.
  static const webEmulator = FirebaseOptions(
    apiKey: 'emulator',
    appId: '1:1041177786311:web:emulator',
    messagingSenderId: '1041177786311',
    projectId: 'majlis-game-1d739',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBvUqssl1P_-P6Zd7CaJmzLKYlZeYYVmwQ',
    appId: '1:1041177786311:android:8477477407d976e9680be2',
    messagingSenderId: '1041177786311',
    projectId: 'majlis-game-1d739',
    storageBucket: 'majlis-game-1d739.firebasestorage.app',
  );
}
