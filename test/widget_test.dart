import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar/main.dart';
import 'package:progressbar/services/life_profile_service.dart';
import 'package:progressbar/services/reflection_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders year progress dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await ReflectionService.init();
    await LifeProfileService.init();
    await tester.pumpWidget(const MyApp());

    expect(find.byType(YearProgressWidget), findsOneWidget);
    expect(find.textContaining('% of'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
  });
}
