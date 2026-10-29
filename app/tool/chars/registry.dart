// Registry of every character the kit can render. Each pack file owns a list of
// specs; add yours to your own pack (see README.md) to avoid merge conflicts.
import 'characters/pack1.dart';
import 'characters/pack2.dart';
import 'characters/pack3.dart';
import 'characters/pack4.dart';
import 'characters/pack5.dart';
import 'characters/pack6.dart';
import 'characters/pack7.dart';
import 'characters/pack8.dart';
import 'characters/ref.dart';
import 'spec.dart';

final Map<String, CharSpec> allChars = {
  for (final c in [
    ...refChars,
    ...pack1,
    ...pack2,
    ...pack3,
    ...pack4,
    ...pack5,
    ...pack6,
    ...pack7,
    ...pack8,
  ])
    c.id: c,
};
