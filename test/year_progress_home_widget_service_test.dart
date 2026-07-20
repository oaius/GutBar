import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar/services/year_progress_home_widget_service.dart';

void main() {
  group('YearProgressWidgetSnapshot', () {
    test('formats year progress widget data from a date', () {
      final snapshot = YearProgressWidgetSnapshot.from(DateTime(2026, 1, 1));

      expect(snapshot.title, '0% of 2026 has passed');
      expect(snapshot.shortTitle, '2026: 0%');
      expect(snapshot.daysLeftText, '364 days left');
      expect(snapshot.dateText, 'January 1');
      expect(snapshot.progressBasisPoints, 0);
    });
  });
}
