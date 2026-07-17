import 'dart:math' as math;

import 'year_progress.dart';

const double defaultLifeExpectancyYears = 73;
const double daysPerExpectedYear = 365.25;

class LifeProgress {
  final int daysLived;
  final double totalExpectedDays;
  final double percentage;
  final int daysRemaining;
  final bool expectancyExceeded;

  const LifeProgress({
    required this.daysLived,
    required this.totalExpectedDays,
    required this.percentage,
    required this.daysRemaining,
    required this.expectancyExceeded,
  });
}

LifeProgress lifeProgress({
  required DateTime birthdate,
  required double lifeExpectancyYears,
  DateTime? today,
}) {
  final birth = calendarDate(birthdate);
  final current = calendarDate(today ?? DateTime.now());
  final rawDaysLived = current.difference(birth).inDays;
  final daysLived = rawDaysLived < 0 ? 0 : rawDaysLived;
  final expectedDays = _expectedDays(lifeExpectancyYears);
  final rawPercentage = expectedDays <= 0
      ? (daysLived > 0 ? 1.0 : 0.0)
      : daysLived / expectedDays;
  final percentage = rawPercentage.clamp(0.0, 1.0).toDouble();
  final rawDaysRemaining = (expectedDays - daysLived).floor();

  return LifeProgress(
    daysLived: daysLived,
    totalExpectedDays: expectedDays,
    percentage: percentage,
    daysRemaining: rawDaysRemaining < 0 ? 0 : rawDaysRemaining,
    expectancyExceeded: daysLived > expectedDays,
  );
}

double _expectedDays(double lifeExpectancyYears) {
  final expectedDays = lifeExpectancyYears * daysPerExpectedYear;
  if (!expectedDays.isFinite) return 0;
  return math.max(0, expectedDays);
}
