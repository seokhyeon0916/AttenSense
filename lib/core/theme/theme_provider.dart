import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String themePreferenceKey = 'theme_preference';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? themePreference = prefs.getString(themePreferenceKey);

    if (themePreference == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themePreference == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String themeValue;

    switch (mode) {
      case ThemeMode.dark:
        themeValue = 'dark';
        break;
      case ThemeMode.light:
        themeValue = 'light';
        break;
      default:
        themeValue = 'system';
    }

    await prefs.setString(themePreferenceKey, themeValue);
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
