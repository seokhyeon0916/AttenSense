import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 테마 설정을 관리하는 Provider 클래스
class ThemeProvider extends ChangeNotifier {
  static const String _themePrefsKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  /// 현재 테마 모드
  ThemeMode get themeMode => _themeMode;

  /// 생성자
  ThemeProvider() {
    _loadThemePreference();
  }

  /// 테마 모드 설정
  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;

    _themeMode = mode;
    notifyListeners();

    // 설정 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefsKey, mode.toString());
  }

  /// 저장된 테마 설정 불러오기
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePrefsKey);

      if (savedTheme != null) {
        switch (savedTheme) {
          case 'ThemeMode.light':
            _themeMode = ThemeMode.light;
            break;
          case 'ThemeMode.dark':
            _themeMode = ThemeMode.dark;
            break;
          default:
            _themeMode = ThemeMode.system;
        }
        notifyListeners();
      }
    } catch (e) {
      // 설정을 불러오는데 실패하면 시스템 테마 사용
      _themeMode = ThemeMode.system;
    }
  }

  /// 테마 토글 (라이트 ↔ 다크)
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  /// 다크 모드 여부 확인
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}
