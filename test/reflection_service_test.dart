import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar/services/reflection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReflectionService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await ReflectionService.init();
    });

    test('saveToday followed by getToday returns the saved text', () async {
      await ReflectionService.saveToday('Logged a small win');

      expect(ReflectionService.getToday()?.text, 'Logged a small win');
    });

    test('saving today twice overwrites instead of duplicating', () async {
      await ReflectionService.saveToday('First version');
      await ReflectionService.saveToday('Second version');

      final today = DateTime.now();
      final todayEntries = ReflectionService.getAll().where((reflection) {
        return _isSameCalendarDay(reflection.date, today);
      }).toList();

      expect(todayEntries, hasLength(1));
      expect(todayEntries.single.text, 'Second version');
    });

    test('saving whitespace does not create an entry', () async {
      await ReflectionService.saveToday('   ');

      expect(ReflectionService.getToday(), isNull);
      expect(ReflectionService.getAll(), isEmpty);
    });

    test('saving whitespace does not overwrite an existing entry', () async {
      await ReflectionService.saveToday('Keep this');
      await ReflectionService.saveToday('\t  \n');

      expect(ReflectionService.getToday()?.text, 'Keep this');
      expect(ReflectionService.getAll(), hasLength(1));
    });

    test('getAll returns entries most recent first', () async {
      await ReflectionService.saveForDate(DateTime(2025, 5, 1), 'Older');
      await ReflectionService.saveForDate(DateTime(2025, 5, 3), 'Newest');
      await ReflectionService.saveForDate(DateTime(2025, 5, 2), 'Middle');

      final texts = ReflectionService.getAll().map(
        (reflection) => reflection.text,
      );

      expect(texts, ['Newest', 'Middle', 'Older']);
    });

    test('getToday returns null when no entry exists for today', () {
      expect(ReflectionService.getToday(), isNull);
    });

    test('entries persist across a simulated app restart', () async {
      final savedDate = DateTime(2025, 6, 10);
      await ReflectionService.saveForDate(savedDate, 'Still here');

      await ReflectionService.init();

      expect(ReflectionService.getForDate(savedDate)?.text, 'Still here');
    });
  });
}

bool _isSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
