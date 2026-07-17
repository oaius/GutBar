import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar/widgets/reflection_year_grid.dart';

void main() {
  group('ReflectionYearGrid responsiveness', () {
    testWidgets('hides weekday labels on narrow widths', (tester) async {
      await tester.pumpWidget(_buildGrid(width: 280));

      expect(find.text('Mon'), findsNothing);
      expect(find.text('Wed'), findsNothing);
      expect(find.text('Fri'), findsNothing);
    });

    testWidgets('shows weekday labels when there is enough width', (
      tester,
    ) async {
      await tester.pumpWidget(_buildGrid(width: 320));

      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
    });
  });
}

Widget _buildGrid({required double width}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: ReflectionYearGrid(
            reflections: const [],
            now: DateTime(2025, 7, 2),
          ),
        ),
      ),
    ),
  );
}
