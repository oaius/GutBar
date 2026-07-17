DateTime calendarDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int daysInYear(int year) {
  return DateTime(year + 1, 1, 1).difference(DateTime(year, 1, 1)).inDays;
}

int dayOfYear(DateTime value) {
  final date = calendarDate(value);
  return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
}

int daysLeftInYear([DateTime? value]) {
  final date = calendarDate(value ?? DateTime.now());
  final firstDayNextYear = DateTime(date.year + 1, 1, 1);
  return firstDayNextYear.difference(date).inDays - 1;
}

double yearProgress([DateTime? value]) {
  final now = value ?? DateTime.now();
  final startOfYear = DateTime(now.year, 1, 1);
  final endOfYear = DateTime(now.year + 1, 1, 1);
  final total = endOfYear.difference(startOfYear).inMilliseconds;
  final elapsed = now.difference(startOfYear).inMilliseconds;
  return elapsed / total;
}
