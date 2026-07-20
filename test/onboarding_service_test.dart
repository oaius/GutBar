import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await OnboardingService.init();
    });

    test('flags default to false', () {
      expect(OnboardingService.hasSeenYearIntro, isFalse);
      expect(OnboardingService.hasSeenLifeInputsPrompt, isFalse);
    });

    test(
      'year intro flag is independent from life inputs prompt flag',
      () async {
        await OnboardingService.markYearIntroSeen();

        expect(OnboardingService.hasSeenYearIntro, isTrue);
        expect(OnboardingService.hasSeenLifeInputsPrompt, isFalse);
      },
    );

    test(
      'life inputs prompt flag is independent from year intro flag',
      () async {
        await OnboardingService.markLifeInputsPromptSeen();

        expect(OnboardingService.hasSeenLifeInputsPrompt, isTrue);
        expect(OnboardingService.hasSeenYearIntro, isFalse);
      },
    );
  });
}
