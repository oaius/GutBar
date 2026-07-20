import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const hasSeenYearIntroKey = 'hasSeenYearIntro';
  static const hasSeenLifeInputsPromptKey = 'hasSeenLifeInputsPrompt';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get hasSeenYearIntro =>
      _requirePrefs().getBool(hasSeenYearIntroKey) ?? false;

  static bool get hasSeenLifeInputsPrompt =>
      _requirePrefs().getBool(hasSeenLifeInputsPromptKey) ?? false;

  static Future<void> markYearIntroSeen() async {
    await _requirePrefs().setBool(hasSeenYearIntroKey, true);
  }

  static Future<void> markLifeInputsPromptSeen() async {
    await _requirePrefs().setBool(hasSeenLifeInputsPromptKey, true);
  }

  static SharedPreferences _requirePrefs() {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('OnboardingService.init() must be called before use.');
    }
    return prefs;
  }
}
