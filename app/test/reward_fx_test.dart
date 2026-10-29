import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/profile.dart';
import 'package:majlis/widgets/reward_fly.dart';

Profile _p({int coins = 1000, int xp = 60, int level = 1}) => Profile.fromJson({
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
  setUp(RewardFx.release);

  test('المستوى والتعبئة من الخبرة نفس معادلة البروفايل', () {
    expect(RewardFx.levelAt(0), (level: 1, progress: 0.0));
    expect(RewardFx.levelAt(60).level, 1);
    expect(RewardFx.levelAt(60).progress, closeTo(.6, 1e-9));
    expect(RewardFx.levelAt(100).level, 2);
    expect(RewardFx.levelAt(180).level, 2);
    expect(RewardFx.levelAt(180).progress, closeTo(80 / 150, 1e-9));
    for (final xp in [0, 99, 100, 249, 250, 449, 450, 1000]) {
      final lv = RewardFx.levelAt(xp).level;
      expect(Profile.xpForLevel(lv), lessThanOrEqualTo(xp));
      expect(Profile.xpForLevel(lv + 1), greaterThan(xp));
    }
  });

  test('المكافأة تنحسب مرة وحدة لكل طاولة', () {
    RewardFx.begin(_p());
    RewardFx.grant('AAAA', coins: 600, xp: 120);
    RewardFx.grant('AAAA', coins: 600, xp: 120);
    expect(RewardFx.heldCoins.value, 600);
    expect(RewardFx.heldXp.value, 120);
    expect(RewardFx.pending, isTrue);
    RewardFx.grant('BBBB', coins: 0, xp: 0);
    expect(RewardFx.heldCoins.value, 600);
    RewardFx.release();
    expect(RewardFx.pending, isFalse);
  });

  test('الرقم اللي يبان: القديم لين تطير المكافأة، وما ينزل تحت اللي قبل اللعبة', () {
    RewardFx.begin(_p(coins: 1000, xp: 60));
    // السيرفر حسب المكافأة: ١٦٠٠ ذهب و١٨٠ خبرة
    final credited = _p(coins: 1600, xp: 180, level: 2);
    RewardFx.grant('CCCC', coins: 600, xp: 120);
    expect(RewardFx.coinsShown(credited), 1000);
    expect(RewardFx.xpShown(credited).level, 1);
    expect(RewardFx.xpShown(credited).progress, closeTo(.6, 1e-9));
    // السيرفر ما حسبها بعد: الرقم القديم برضو (ما ينزل لـ٤٠٠)
    final notYet = _p(coins: 1000, xp: 60);
    expect(RewardFx.coinsShown(notYet), 1000);
    // العملات توصل واحدة واحدة
    RewardFx.heldCoins.value = 350;
    expect(RewardFx.coinsShown(credited), 1250);
    RewardFx.release();
    expect(RewardFx.coinsShown(credited), 1600);
    expect(RewardFx.xpShown(credited).level, 2);
  });
}
