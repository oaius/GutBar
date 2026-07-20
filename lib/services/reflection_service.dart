import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reflection.dart';

enum ReflectionImportChoice { keepExisting, overwrite, keepBoth }

typedef ReflectionConflictResolver =
    Future<ReflectionImportChoice> Function(ReflectionImportConflict conflict);

class ReflectionImportConflict {
  final Reflection existing;
  final Reflection imported;

  const ReflectionImportConflict({
    required this.existing,
    required this.imported,
  });
}

class ReflectionImportResult {
  final int added;
  final int overwritten;
  final int keptExisting;
  final int keptBoth;

  const ReflectionImportResult({
    required this.added,
    required this.overwritten,
    required this.keptExisting,
    required this.keptBoth,
  });

  int get changed => added + overwritten + keptBoth;
}

class ReflectionService {
  static const _kKey = 'reflections';
  static late SharedPreferences _prefs;
  static List<Reflection> _items = [];

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_kKey);
    if (raw != null && raw.isNotEmpty) {
      final List decoded = jsonDecode(raw) as List;
      _items = decoded
          .map((e) => Reflection.fromJson(Map<String, dynamic>.from(e)))
          .toList();
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
      if (_isSameDay(r.date, d)) return r;
    }
    return null;
  }

  static Reflection? getToday() => getForDate(DateTime.now());

  static Future<void> saveForDate(DateTime date, String text) async {
    if (text.trim().isEmpty) return;
    final d = DateTime(date.year, date.month, date.day);
    // remove existing for that day
    _items.removeWhere((r) => _isSameDay(r.date, d));
    _items.add(Reflection(date: d, text: text));
    await _persist();
  }

  static Future<void> saveToday(String text) =>
      saveForDate(DateTime.now(), text);

  static Future<void> _persist() async {
    final encoded = jsonEncode(_items.map((r) => r.toJson()).toList());
    await _prefs.setString(_kKey, encoded);
  }

  static Future<void> deleteForDate(DateTime date) async {
    final d = DateTime(date.year, date.month, date.day);
    _items.removeWhere((r) => _isSameDay(r.date, d));
    await _persist();
  }

  static String exportBackupJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(getAll().map((r) => r.toJson()).toList());
  }

  static List<Reflection> parseBackupJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Backup must be a list of entries.');
    }

    final seenDates = <DateTime>{};
    final entries = <Reflection>[];
    for (final item in decoded) {
      if (item is! Map) {
        throw const FormatException('Each entry must be an object.');
      }

      final dateValue = item['date'];
      final textValue = item['text'];
      if (dateValue is! String || textValue is! String) {
        throw const FormatException('Each entry needs date and text strings.');
      }

      final parsedDate = DateTime.tryParse(dateValue);
      final text = textValue.trim();
      if (parsedDate == null || text.isEmpty) {
        throw const FormatException('Entry date or text is invalid.');
      }

      final date = _dateOnly(parsedDate);
      if (!seenDates.add(date)) {
        throw const FormatException('Backup contains duplicate entry dates.');
      }

      entries.add(Reflection(date: date, text: text));
    }

    return entries;
  }

  static Future<ReflectionImportResult> importEntries(
    List<Reflection> imported, {
    required ReflectionConflictResolver resolveConflict,
  }) async {
    final nextItems = List<Reflection>.from(_items);
    final occupiedDates = {
      for (final reflection in nextItems) _dateOnly(reflection.date),
    };

    var added = 0;
    var overwritten = 0;
    var keptExisting = 0;
    var keptBoth = 0;

    for (final entry in imported) {
      final normalized = Reflection(
        date: _dateOnly(entry.date),
        text: entry.text.trim(),
      );
      final existingIndex = nextItems.indexWhere(
        (reflection) => _isSameDay(reflection.date, normalized.date),
      );

      if (existingIndex == -1) {
        nextItems.add(normalized);
        occupiedDates.add(normalized.date);
        added++;
        continue;
      }

      final choice = await resolveConflict(
        ReflectionImportConflict(
          existing: nextItems[existingIndex],
          imported: normalized,
        ),
      );

      switch (choice) {
        case ReflectionImportChoice.keepExisting:
          keptExisting++;
          break;
        case ReflectionImportChoice.overwrite:
          nextItems[existingIndex] = normalized;
          overwritten++;
          break;
        case ReflectionImportChoice.keepBoth:
          final newDate = _nextAvailableDate(normalized.date, occupiedDates);
          nextItems.add(Reflection(date: newDate, text: normalized.text));
          occupiedDates.add(newDate);
          keptBoth++;
          break;
      }
    }

    _items = nextItems;
    await _persist();

    return ReflectionImportResult(
      added: added,
      overwritten: overwritten,
      keptExisting: keptExisting,
      keptBoth: keptBoth,
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _nextAvailableDate(
    DateTime startDate,
    Set<DateTime> occupiedDates,
  ) {
    var candidate = _dateOnly(startDate).add(const Duration(days: 1));
    while (occupiedDates.contains(candidate)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
