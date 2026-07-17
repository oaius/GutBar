import 'package:flutter_test/flutter_test.dart';
import 'package:progressbar/services/life_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LifeProfileService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await LifeProfileService.init();
    });

    test('returns null when no profile is saved', () {
      expect(LifeProfileService.profile, isNull);
    });

    test('saves and reloads a profile', () async {
      await LifeProfileService.saveProfile(
        birthdate: DateTime(1990, 5, 20, 13, 45),
        lifeExpectancyYears: 81.5,
      );

      await LifeProfileService.init();
      final profile = LifeProfileService.profile;

      expect(profile, isNotNull);
      expect(profile!.birthdate, DateTime(1990, 5, 20));
      expect(profile.lifeExpectancyYears, 81.5);
    });

    test('uses default expectancy when only birthdate exists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'life_birthdate': DateTime(1985, 2, 3).toIso8601String(),
      });

      await LifeProfileService.init();
      final profile = LifeProfileService.profile;

      expect(profile, isNotNull);
      expect(profile!.birthdate, DateTime(1985, 2, 3));
      expect(
        profile.lifeExpectancyYears,
        LifeProfileService.defaultExpectancyYears,
      );
    });
  });
}
