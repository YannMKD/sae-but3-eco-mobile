import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _istutoswipesKey = "tuto_swipes_done";

  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_istutoswipesKey) ?? false;
  }

  static Future<void> setTutoSwipesComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_istutoswipesKey, true);
  }

  static Future<bool> isTutoSwipesComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_istutoswipesKey) ?? false;
  }

  static Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_seen_onboarding');
    await prefs.remove('tuto_swipes_done');
  }
}