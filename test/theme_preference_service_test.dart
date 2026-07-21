import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar/services/theme_preference_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemePreferenceService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await ThemePreferenceService.init();
    });

    test('defaults to dark mode', () {
      expect(ThemePreferenceService.themeMode, ThemeMode.dark);
      expect(ThemePreferenceService.isDarkMode, isTrue);
    });

    test('saves and reloads light mode', () async {
      await ThemePreferenceService.setDarkMode(false);

      expect(ThemePreferenceService.themeMode, ThemeMode.light);

      await ThemePreferenceService.init();

      expect(ThemePreferenceService.themeMode, ThemeMode.light);
      expect(ThemePreferenceService.isDarkMode, isFalse);
    });
  });
}
