import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ملاحظتك الخاصة على لاعب: محد يشوفها غيرك.
enum NoteMark { trust, suspect, unsure }

/// ملاحظات اللاعب على باقي اللاعبين في كل طاولة. تنحفظ في الجهاز بس.
class Notes extends ChangeNotifier {
  Notes(this.code);

  final String code;
  final Map<String, NoteMark> _marks = {};

  String get _key => 'notes_$code';

  NoteMark? of(String playerId) => _marks[playerId];

  Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return;
      final map = Map<String, String>.from(jsonDecode(raw) as Map);
      _marks
        ..clear()
        ..addAll({for (final e in map.entries) e.key: NoteMark.values.byName(e.value)});
      notifyListeners();
    } catch (_) {}
  }

  Future<void> set(String playerId, NoteMark? mark) async {
    if (mark == null) {
      _marks.remove(playerId);
    } else {
      _marks[playerId] = mark;
    }
    notifyListeners();
    try {
      (await SharedPreferences.getInstance())
          .setString(_key, jsonEncode({for (final e in _marks.entries) e.key: e.value.name}));
    } catch (_) {}
  }
}
