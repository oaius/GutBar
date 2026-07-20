import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar/main.dart';
import 'package:progressbar/services/life_profile_service.dart';
import 'package:progressbar/services/onboarding_service.dart';
import 'package:progressbar/services/reflection_service.dart';
import 'package:progressbar/widgets/reflection_entry_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ReflectionService.init();
    await LifeProfileService.init();
    await OnboardingService.init();
  });

  testWidgets('reflection entry field uses visible input colors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: ReflectionEntrySheet(),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.style?.color, Colors.white);
    expect(field.cursorColor, const Color(0xFF00CC44));
    expect(field.decoration?.hintStyle?.color, const Color(0xFF888888));
    expect(field.decoration?.hintStyle?.color, isNot(field.style?.color));

    await tester.enterText(find.byType(TextField), 'Readable text');
    await tester.pump();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.style.color, Colors.white);
    expect(editable.cursorColor, const Color(0xFF00CC44));
  });

  testWidgets('shows last years reflection as quiet context', (
    WidgetTester tester,
  ) async {
    await ReflectionService.saveForDate(
      DateTime(2025, 7, 20),
      'Same day last year',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: ReflectionEntrySheet(now: DateTime(2026, 7, 20)),
        ),
      ),
    );

    final yearAgoText = tester.widget<Text>(
      find.text('A year ago: Same day last year'),
    );

    expect(yearAgoText.style?.color, const Color(0xFF888888));
    expect(yearAgoText.style?.fontSize, 13);
  });

  testWidgets('shows last year context even when today is prefilled', (
    WidgetTester tester,
  ) async {
    await ReflectionService.saveForDate(DateTime(2025, 7, 20), 'Last year');
    await ReflectionService.saveForDate(DateTime(2026, 7, 20), 'Today');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: ReflectionEntrySheet(now: DateTime(2026, 7, 20)),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));

    expect(field.controller?.text, 'Today');
    expect(find.text('A year ago: Last year'), findsOneWidget);
  });

  testWidgets('does not fall back for invalid leap-day last-year date', (
    WidgetTester tester,
  ) async {
    await ReflectionService.saveForDate(
      DateTime(2023, 3, 1),
      'Not the same calendar date',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: ReflectionEntrySheet(now: DateTime(2024, 2, 29)),
        ),
      ),
    );

    expect(find.textContaining('A year ago:'), findsNothing);
  });

  testWidgets('compact reflection text remains visible on the main screen', (
    WidgetTester tester,
  ) async {
    await ReflectionService.saveToday('Visible entry');

    await tester.pumpWidget(const MyApp());

    final compactText = tester.widget<Text>(find.text('Visible entry'));

    expect(compactText.style?.color, const Color(0xFFCCCCCC));
    expect(compactText.style?.color, isNot(const Color(0xFF111111)));
  });

  testWidgets('reflection bottom sheet stays above the keyboard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('One thing you did today'));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 520);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final fieldRect = tester.getRect(find.byType(TextField));
    final keyboardTop =
        tester.view.physicalSize.height / tester.view.devicePixelRatio -
        tester.view.viewInsets.bottom;

    expect(fieldRect.bottom, lessThan(keyboardTop));
  });
}
