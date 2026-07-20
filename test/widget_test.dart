import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar/main.dart';
import 'package:progressbar/screens/life_progress_screen.dart';
import 'package:progressbar/services/life_profile_service.dart';
import 'package:progressbar/services/onboarding_service.dart';
import 'package:progressbar/services/reflection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders year progress dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ReflectionService.init();
    await LifeProfileService.init();
    await OnboardingService.init();
    await tester.pumpWidget(const MyApp());

    expect(find.byType(YearProgressWidget), findsOneWidget);
    expect(find.textContaining('% of'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
  });

  testWidgets('shows and dismisses the first-launch year caption', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ReflectionService.init();
    await LifeProfileService.init();
    await OnboardingService.init();
    await tester.pumpWidget(const MyApp());

    expect(find.text('No streaks. Just the number.'), findsOneWidget);

    await tester.tap(find.byType(YearProgressWidget));
    await tester.pump();

    expect(find.text('No streaks. Just the number.'), findsNothing);
    expect(OnboardingService.hasSeenYearIntro, isTrue);
  });

  testWidgets('life progress first visit opens inputs with context', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LifeProfileService.init();
    await OnboardingService.init();

    await tester.pumpWidget(const MaterialApp(home: LifeProgressScreen()));
    await tester.pumpAndSettle();

    expect(find.text('This is an estimate, not a prediction.'), findsOneWidget);
    expect(OnboardingService.hasSeenLifeInputsPrompt, isTrue);
  });
}
