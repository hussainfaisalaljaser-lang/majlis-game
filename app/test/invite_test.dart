import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/models/profile.dart';
import 'package:majlis/services/links.dart';
import 'package:majlis/widgets/gifts.dart';

void main() {
  test('رابط الدعوة: رمز الطاولة ورمز اللي أرسله (لهدية الدعوة)', () {
    final web = Uri.parse('https://majlis-game-1d739.web.app/r/abcde?by=12345678');
    expect(Links.codeFrom(web), 'ABCDE');
    expect(Links.inviterFrom(web), '12345678');
    final app = Uri.parse('majlis://room/K7Q2M?by=777');
    expect(Links.codeFrom(app), 'K7Q2M');
    expect(Links.inviterFrom(app), '777');
    // رابط قديم بدون رمز، أو رمز مو صحيح: الطاولة بس.
    expect(Links.inviterFrom(Uri.parse('https://majlis-game-1d739.web.app/r/ABCDE')), isNull);
    expect(Links.inviterFrom(Uri.parse('https://majlis-game-1d739.web.app/r/ABCDE?by=0123')), isNull);
    expect(Links.inviterFrom(Uri.parse('https://majlis-game-1d739.web.app/r/ABCDE?by=12ab')), isNull);
  });

  test('هدية الدعوة من السيرفر: اسم اللي دعاه أو صاحبه اللي لعب', () {
    final invited = Gift.fromJson({
      'kind': 'invite',
      'n': 0,
      'from': 'أحمد',
      'coins': 1000,
      'diamonds': 0,
      'items': [],
    });
    expect(invited.inviteFrom, 'أحمد');
    expect(invited.passFrom, isNull);
    final level = Gift.fromJson({'kind': 'level', 'n': 5, 'coins': 300, 'diamonds': 0, 'items': []});
    expect(level.inviteFrom, isNull);
  });

  testWidgets('نافذة هدية الدعوة: للجديد وللي دعاه', (tester) async {
    tester.view.physicalSize = const Size(2400, 1100);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    Future<void> open(Map<String, dynamic> json) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showGiftDialog(context, Gift.fromJson(json)),
                  child: const Text('افتح'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    await open({'kind': 'invite', 'n': 0, 'from': 'أحمد', 'coins': 1000, 'diamonds': 0, 'items': []});
    expect(find.text('هدية الدعوة!'), findsOneWidget);
    expect(find.textContaining('أحمد دعاك للمجلس'), findsOneWidget);
    await tester.tap(find.text('استلمت').first);
    await tester.pump(const Duration(milliseconds: 500));

    await open({'kind': 'invite', 'n': 1, 'from': 'سالم', 'coins': 1000, 'diamonds': 10, 'items': []});
    expect(find.text('سالم خلّص أول قيم له!'), findsOneWidget);
    expect(find.textContaining('لأنك دعيته'), findsOneWidget);
    await tester.tap(find.text('استلمت').first);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
