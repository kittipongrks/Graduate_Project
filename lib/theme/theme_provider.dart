import 'package:flutter/material.dart';

enum AppTheme {
  light,
  dark,
  system,
}

class ThemeProvider extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.system;

  AppTheme get currentTheme => _currentTheme;

  void setTheme(AppTheme theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  void toggleTheme() {
    if (_currentTheme == AppTheme.light) {
      setTheme(AppTheme.dark);
    } else if (_currentTheme == AppTheme.dark) {
      setTheme(AppTheme.light);
    } else {
      setTheme(AppTheme.system);
    }
  }
}
