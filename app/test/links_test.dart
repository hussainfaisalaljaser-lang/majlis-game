import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/services/links.dart';

void main() {
  test('رمز الروم من روابط الدعوة', () {
    expect(Links.codeFrom(Uri.parse('https://majlis-game-1d739.web.app/r/K7Q2M')), 'K7Q2M');
    expect(Links.codeFrom(Uri.parse('https://majlis-game-1d739.web.app/r/k7q2m/')), 'K7Q2M');
    expect(Links.codeFrom(Uri.parse('majlis://room/AB12C')), 'AB12C');
    expect(Links.codeFrom(Uri.parse('https://majlis-game-1d739.web.app/?room=ab12c')), 'AB12C');
    // مو روابط روم
    expect(Links.codeFrom(Uri.parse('https://majlis-game-1d739.web.app/')), isNull);
    expect(Links.codeFrom(Uri.parse('https://majlis-game-1d739.web.app/r/TOOLONG')), isNull);
    expect(Links.codeFrom(Uri.parse('https://evil.example/r/K7Q2M')), isNull);
    expect(Links.codeFrom(Uri.parse('majlis://room/')), isNull);
  });

  test('رسالة الدعوة فيها الكود والرابط', () {
    final text = Links.inviteText('K7Q2M');
    expect(text, contains('K7Q2M'));
    expect(text, contains('https://majlis-game-1d739.web.app/r/K7Q2M'));
  });
}
