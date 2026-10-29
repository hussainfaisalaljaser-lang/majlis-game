import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/profile.dart';
import 'package:majlis/models/shop.dart';

Profile _p({Map<String, dynamic>? pass, bool vip = false}) => Profile.fromJson({
  'name': 'أنا',
  'avatar': 'emir',
  'coins': 0,
  'diamonds': 0,
  'xp': 0,
  'level': 1,
  'gamesPlayed': 0,
  'gamesWon': 0,
  'dailyStreak': 0,
  'vip': vip,
  'pass': ?pass,
});

void main() {
  test('VIP يفتح بباتل الموسم الحالي المدفوع، ويقفل لو ما اشتراه أو الموسم قديم', () {
    expect(_p().hasVip, isFalse, reason: 'بدون باتل');
    final bought = _p(pass: {'season': season.id, 'points': 0, 'premium': true, 'free': 0, 'prem': 0});
    expect(bought.hasVip, season.active, reason: 'اشترى باتل الموسم الشغال (ولو الموسم خلص ينقفل)');
    final freeTrack = _p(pass: {'season': season.id, 'points': 500, 'premium': false, 'free': 0, 'prem': 0});
    expect(freeTrack.hasVip, isFalse, reason: 'المسار المجاني ما يفتحه');
    final old = _p(pass: {'season': 'old', 'points': 0, 'premium': true, 'free': 0, 'prem': 0});
    expect(old.hasVip, isFalse, reason: 'اشتراه في موسم قديم وما جدد');
    expect(_p(vip: true).hasVip, isTrue, reason: 'علامة المطوّر اليدوية');
  });
}
