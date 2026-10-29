import 'package:flutter_test/flutter_test.dart';
import 'package:majlis/widgets/game/atmosphere.dart';
import 'package:majlis/widgets/venues.dart';

void main() {
  test('كل مستوى طاولة له جوه، والطاولات الخاصة ليل هادئ', () {
    expect(Atmosphere.kindFor(Venue.majlis), AtmoKind.night);
    expect(Atmosphere.kindFor(Venue.desert), AtmoKind.desert);
    expect(Atmosphere.kindFor(Venue.city), AtmoKind.city);
    expect(Atmosphere.kindFor(Venue.palace), AtmoKind.palace);
    expect(Atmosphere.kindFor(Venue.kings), AtmoKind.kings);
    expect(Atmosphere.kindFor(Venue.vip), AtmoKind.vip);
    expect(
      {for (final v in Venue.values) Atmosphere.kindFor(v)}.length,
      Venue.values.length,
      reason: 'كل مكان له جو مختلف',
    );
  });
}
