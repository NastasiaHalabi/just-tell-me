import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists dark/light choice. Defaults to dark to match the lime assistant look.
class ThemeController extends ChangeNotifier {
  static const prefsKey = 'theme_mode';

  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;

  bool get isDark => _mode != ThemeMode.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    _mode = raw == 'light' ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> setDark(bool dark) async {
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, dark ? 'dark' : 'light');
  }
}
