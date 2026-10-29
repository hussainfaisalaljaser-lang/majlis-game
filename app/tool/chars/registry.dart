// Registry of every character the kit can render. Each pack file owns a list of
// specs; add yours to your own pack (see README.md) to avoid merge conflicts.
import 'characters/ref.dart';
import 'spec.dart';

final Map<String, CharSpec> allChars = {
  for (final c in [
    ...refChars,
  ])
    c.id: c,
};
