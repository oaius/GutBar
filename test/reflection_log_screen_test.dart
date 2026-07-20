import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar/screens/reflection_log_screen.dart';
import 'package:progressbar/services/reflection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ReflectionService.init();
  });

  testWidgets('shows current week and month retrospective counts', (
    WidgetTester tester,
  ) async {
    await ReflectionService.saveForDate(DateTime(2026, 7, 1), 'Month');
    await ReflectionService.saveForDate(DateTime(2026, 7, 18), 'Last week');
    await ReflectionService.saveForDate(DateTime(2026, 7, 19), 'Sunday');
    await ReflectionService.saveForDate(DateTime(2026, 7, 21), 'Tuesday');
    await ReflectionService.saveForDate(DateTime(2026, 7, 22), 'Wednesday');
    await ReflectionService.saveForDate(DateTime(2026, 7, 23), 'Future');

    await tester.pumpWidget(
      MaterialApp(home: ReflectionLogScreen(now: DateTime(2026, 7, 22))),
    );

    expect(find.text('This week: 3/4 days accounted for'), findsOneWidget);
    expect(find.text('This month: 5/22 days accounted for'), findsOneWidget);
  });

  testWidgets('shows honest zero counts on first day of week and month', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ReflectionLogScreen(now: DateTime(2026, 2, 1))),
    );

    expect(find.text('This week: 0/1 days accounted for'), findsOneWidget);
    expect(find.text('This month: 0/1 days accounted for'), findsOneWidget);
  });
}
