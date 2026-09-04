import 'package:flutter/material.dart';
import '../services/prefs_service.dart';

/// MVVM ViewModel for app theme switching with SharedPreferences persistence.
class ThemeViewModel extends ChangeNotifier {
  final PrefsService _prefs;

  ThemeViewModel(this._prefs) {
    _loadTheme();
  }

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void _loadTheme() {
    final modeStr = _prefs.getThemeMode();
    if (modeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (modeStr == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  Future<void> toggleTheme([bool? isDark]) async {
    final target = isDark ?? !this.isDark;
    _themeMode = target ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _prefs.setThemeMode(target ? 'dark' : 'light');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs.setThemeMode(mode.name);
  }
}
