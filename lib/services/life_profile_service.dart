import 'package:shared_preferences/shared_preferences.dart';

import '../models/life_profile.dart';
import '../utils/life_progress.dart';

class LifeProfileService {
  static const double defaultExpectancyYears = defaultLifeExpectancyYears;
  static const _birthdateKey = 'life_birthdate';
  static const _expectancyYearsKey = 'life_expectancy_years';

  static SharedPreferences? _prefs;
  static LifeProfile? _profile;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _profile = _readProfile();
  }

  static LifeProfile? get profile => _profile;

  static Future<void> saveProfile({
    required DateTime birthdate,
    required double lifeExpectancyYears,
  }) async {
    final prefs = _requirePrefs();
    final normalizedBirthdate = DateTime(
      birthdate.year,
      birthdate.month,
      birthdate.day,
    );

    _profile = LifeProfile(
      birthdate: normalizedBirthdate,
      lifeExpectancyYears: lifeExpectancyYears,
    );

    await prefs.setString(_birthdateKey, normalizedBirthdate.toIso8601String());
    await prefs.setDouble(_expectancyYearsKey, lifeExpectancyYears);
  }

  static LifeProfile? _readProfile() {
    final prefs = _requirePrefs();
    final rawBirthdate = prefs.getString(_birthdateKey);
    if (rawBirthdate == null || rawBirthdate.isEmpty) return null;

    final birthdate = DateTime.tryParse(rawBirthdate);
    if (birthdate == null) return null;

    final rawExpectancy = prefs.get(_expectancyYearsKey);
    final expectancyYears = rawExpectancy is num
        ? rawExpectancy.toDouble()
        : defaultExpectancyYears;

    return LifeProfile(
      birthdate: DateTime(birthdate.year, birthdate.month, birthdate.day),
      lifeExpectancyYears: expectancyYears,
    );
  }

  static SharedPreferences _requirePrefs() {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('LifeProfileService.init() must be called before use.');
    }
    return prefs;
  }
}
