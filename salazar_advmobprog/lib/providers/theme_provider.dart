import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void setDarkMode(bool value) {
    _isDark = value;
    notifyListeners();
  }

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}