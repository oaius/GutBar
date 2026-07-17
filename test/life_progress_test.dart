import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar/utils/life_progress.dart';

void main() {
  group('life progress date logic', () {
    test('calculates days lived, remaining days, and percentage', () {
      final result = lifeProgress(
        birthdate: DateTime(2000, 1, 1),
        lifeExpectancyYears: 73,
        today: DateTime(2001, 1, 1),
      );

      expect(result.daysLived, 366);
      expect(result.totalExpectedDays, 73 * 365.25);
      expect(result.daysRemaining, 26297);
      expect(result.percentage, closeTo(366 / (73 * 365.25), 0.000001));
      expect(result.expectancyExceeded, isFalse);
    });

    test('caps future birthdates at zero progress', () {
      final result = lifeProgress(
        birthdate: DateTime(2030, 1, 1),
        lifeExpectancyYears: 73,
        today: DateTime(2029, 1, 1),
      );

      expect(result.daysLived, 0);
      expect(result.percentage, 0);
      expect(result.daysRemaining, (73 * 365.25).floor());
      expect(result.expectancyExceeded, isFalse);
    });

    test(
      'caps exceeded expectancy at full progress and zero days remaining',
      () {
        final result = lifeProgress(
          birthdate: DateTime(2000, 1, 1),
          lifeExpectancyYears: 1,
          today: DateTime(2002, 1, 1),
        );

        expect(result.percentage, 1);
        expect(result.daysRemaining, 0);
        expect(result.expectancyExceeded, isTrue);
      },
    );

    test('handles zero or negative expectancy without negative output', () {
      final result = lifeProgress(
        birthdate: DateTime(2000, 1, 1),
        lifeExpectancyYears: -4,
        today: DateTime(2000, 1, 2),
      );

      expect(result.totalExpectedDays, 0);
      expect(result.percentage, 1);
      expect(result.daysRemaining, 0);
      expect(result.expectancyExceeded, isTrue);
    });
  });
}
