// تصوير كل شاشات اللعبة بملف لاعب تجريبي (بدون جوال ولا سيرفر)، عشان نقارن التصميم باللقطات.
// التشغيل:  flutter test tool/shots/shots_test.dart   (ويقدر كل واحد يسوي ملف ثاني بنفس الطريقة)
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/screens/home_screen.dart';
import 'package:majlis/screens/shop_screen.dart';
import 'package:majlis/screens/pass_screen.dart';
import 'package:majlis/screens/wardrobe_screen.dart';
import 'package:majlis/screens/missions_screen.dart';
import 'package:majlis/screens/leaderboard_screen.dart';
import 'package:majlis/screens/profile_screen.dart';
import 'package:majlis/screens/history_screen.dart';
import 'package:majlis/screens/friends_screen.dart';
import 'package:majlis/screens/tables_screen.dart';
import 'package:majlis/widgets/mode_theme.dart';
import 'shot_helper.dart';

void main() {
  setUpAll(loadFonts);

  testWidgets('home', (tester) async {
    await shot(tester, 'home', const HomeScreen());
  });

  testWidgets('shop', (tester) async {
    await shot(tester, 'shop', const ShopScreen());
  });

  testWidgets('pass', (tester) async {
    await shot(tester, 'pass', const PassScreen());
  });

  testWidgets('wardrobe', (tester) async {
    await shot(tester, 'wardrobe', const WardrobeScreen());
  });

  testWidgets('missions', (tester) async {
    await shot(tester, 'missions', const MissionsScreen());
  });

  testWidgets('leaderboard', (tester) async {
    await shot(tester, 'leaderboard', const LeaderboardScreen());
  });

  testWidgets('profile', (tester) async {
    await shot(tester, 'profile', const ProfileScreen());
  });

  testWidgets('history', (tester) async {
    await shot(tester, 'history', const HistoryScreen());
  });

  testWidgets('friends', (tester) async {
    await shot(tester, 'friends', const FriendsScreen());
  });

  testWidgets('tables', (tester) async {
    await shot(tester, 'tables', const TablesScreen(mode: ModeTheme.classic));
  });

}
