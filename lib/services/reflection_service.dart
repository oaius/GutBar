import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reflection.dart';

class ReflectionService {
  static const _kKey = 'reflections';
  static late SharedPreferences _prefs;
  static List<Reflection> _items = [];

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_kKey);
    if (raw != null && raw.isNotEmpty) {
      final List decoded = jsonDecode(raw) as List;
      _items = decoded.map((e) => Reflection.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      _items = [];
    }
  }

  static List<Reflection> getAll() {
    final copy = List<Reflection>.from(_items);
    copy.sort((a, b) => b.date.compareTo(a.date));
    return copy;
  }

  static Reflection? getForDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    for (final r in _items) {
      if (r.date.year == d.year && r.date.month == d.month && r.date.day == d.day) return r;
    }
    return null;
  }

  static Reflection? getToday() => getForDate(DateTime.now());

  static Future<void> saveForDate(DateTime date, String text) async {
    if (text.trim().isEmpty) return;
    final d = DateTime(date.year, date.month, date.day);
    // remove existing for that day
    _items.removeWhere((r) => r.date.year == d.year && r.date.month == d.month && r.date.day == d.day);
    _items.add(Reflection(date: d, text: text));
    await _persist();
  }

  static Future<void> saveToday(String text) => saveForDate(DateTime.now(), text);

  static Future<void> _persist() async {
    final encoded = jsonEncode(_items.map((r) => r.toJson()).toList());
    await _prefs.setString(_kKey, encoded);
  }

  static Future<void> deleteForDate(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    _items.removeWhere((r) => r.date.year == d.year && r.date.month == d.month && r.date.day == d.day);
    await _persist();
  }
}
