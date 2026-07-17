import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar/utils/year_progress.dart';

void main() {
  group('year progress date logic', () {
    test('returns correct days left and progress for a mid-year date', () {
      final middayHalfwayThrough2025 = DateTime(2025, 7, 2, 12);

      expect(daysLeftInYear(middayHalfwayThrough2025), 182);
      expect(yearProgress(middayHalfwayThrough2025), closeTo(0.5, 0.000001));
    });

    test('returns days in year minus one and near zero progress on Jan 1', () {
      final jan1 = DateTime(2025, 1, 1);

      expect(daysLeftInYear(jan1), daysInYear(2025) - 1);
      expect(yearProgress(jan1), closeTo(0, 0.000001));
    });

    test('returns 0 days left and near complete progress on Dec 31', () {
      final dec31Late = DateTime(2025, 12, 31, 23, 59);

      expect(daysLeftInYear(dec31Late), 0);
      expect(yearProgress(dec31Late), closeTo(1, 0.00001));
    });

    test('counts leap years and Feb 29 correctly', () {
      expect(daysInYear(2024), 366);
      expect(daysInYear(2025), 365);
      expect(dayOfYear(DateTime(2024, 2, 29)), 60);
      expect(dayOfYear(DateTime(2024, 3, 1)), 61);
      expect(dayOfYear(DateTime(2025, 3, 1)), 60);
      expect(daysLeftInYear(DateTime(2024, 2, 29)), 306);
    });

    test('does not drift at the Dec 31 year boundary', () {
      final dec31Late = DateTime(2025, 12, 31, 23, 59);

      expect(daysLeftInYear(dec31Late), 0);
      expect(daysLeftInYear(dec31Late), isNonNegative);
      expect(daysLeftInYear(dec31Late), isNot(2));
    });

    test('uses calendar dates for days-left regardless of time of day', () {
      final justAfterMidnight = DateTime(2025, 7, 2, 0, 1);
      final justBeforeMidnight = DateTime(2025, 7, 2, 23, 59);

      expect(daysLeftInYear(justAfterMidnight), 182);
      expect(daysLeftInYear(justBeforeMidnight), 182);
    });
  });
}
