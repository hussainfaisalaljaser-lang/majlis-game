import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/profile.dart';
import 'package:majlis/screens/home_screen.dart';
import 'package:majlis/services/backend.dart';
import 'package:majlis/services/sounds.dart';
import 'package:majlis/widgets/reward_fly.dart';

Profile _p(int coins, int xp, int level) => Profile.fromJson({
  'name': 'أنا',
  'avatar': 'emir',
  'coins': coins,
  'diamonds': 0,
  'xp': xp,
  'level': level,
  'gamesPlayed': 1,
  'gamesWon': 0,
  'dailyStreak': 0,
});

void main() {
  setUp(() {
    Sounds.silent = true;
    RewardFx.release();
  });

  testWidgets('المكافأة تطير للرصيد: الرقم القديم يزيد شوي شوي لين يوصل للجديد', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    // قبل اللعبة: ١٠٠٠ ذهب و٦٠ خبرة. بعدها السيرفر حسب المكافأة: ١٦٠٠ و١٨٠ (مستوى ٢)
    Backend.instance.profile.value = _p(1000, 60, 1);
    RewardFx.begin(Backend.instance.profile.value);
    Backend.instance.profile.value = _p(1600, 180, 2);
    RewardFx.grant('T1', coins: 600, xp: 120);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    // أول فريم: الرقم لسا قديم
    expect(RewardFx.coinsShown(Backend.instance.profile.value), 1000);
    expect(RewardFx.xpShown(Backend.instance.profile.value).level, 1);

    final seen = <int>[];
    var maxXpLevel = 1;
    for (var i = 0; i < 200 && RewardFx.pending; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      seen.add(RewardFx.coinsShown(Backend.instance.profile.value));
      maxXpLevel = RewardFx.xpShown(Backend.instance.profile.value).level;
    }
    expect(RewardFx.pending, isFalse, reason: 'الحركة لازم تخلص وتفك الرقم');
    expect(seen.first, lessThan(1600));
    expect(seen.last, 1600);
    // الرقم يزيد ولا ينقص، ويمر بقيم بين القديم والجديد
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i], greaterThanOrEqualTo(seen[i - 1]));
    }
    expect(seen.any((v) => v > 1000 && v < 1600), isTrue);
    expect(maxXpLevel, 2);
    await tester.pump(const Duration(seconds: 1));
    expect(RewardFx.coinsShown(Backend.instance.profile.value), 1600);
  });

  testWidgets('بدون مكافأة ما تطلع حركة ولا يتغير الرقم', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    Backend.instance.profile.value = _p(1000, 60, 1);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(RewardFx.pending, isFalse);
    expect(RewardFx.coinsShown(Backend.instance.profile.value), 1000);
  });
}
