import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferenceService {
  static const themeModeKey = 'theme_mode';
  static const _darkValue = 'dark';
  static const _lightValue = 'light';

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    themeModeNotifier.value = _readThemeMode();
  }

  static ThemeMode get themeMode => themeModeNotifier.value;

  static bool get isDarkMode => themeMode == ThemeMode.dark;

  static Future<void> setDarkMode(bool enabled) async {
    await setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }

  static Future<void> toggleTheme() async {
    await setDarkMode(!isDarkMode);
  }

  static Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = _requirePrefs();
    themeModeNotifier.value = themeMode;
    await prefs.setString(
      themeModeKey,
      themeMode == ThemeMode.dark ? _darkValue : _lightValue,
    );
  }

  static ThemeMode _readThemeMode() {
    final value = _requirePrefs().getString(themeModeKey);
    return value == _lightValue ? ThemeMode.light : ThemeMode.dark;
  }

  static SharedPreferences _requirePrefs() {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'ThemePreferenceService.init() must be called before use.',
      );
    }
    return prefs;
  }
}
