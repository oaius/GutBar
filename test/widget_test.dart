import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:progressbar/main.dart';

void main() {
  testWidgets('renders year progress dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(YearProgressWidget), findsOneWidget);
    expect(find.textContaining('% of'), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
  });
}
