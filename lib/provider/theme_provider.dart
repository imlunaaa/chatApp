import 'package:chat_app/services/theme_preference.dart';
import 'package:flutter/material.dart'; // Adjust import path as needed

class ThemeProvider extends ChangeNotifier {
  final DarkThemePref darkThemePrefs = DarkThemePref();
  bool _darkTheme = false;

  // Getter to access current theme state
  bool get getDarkTheme => _darkTheme;

  // Setter to update theme state and persist to SharedPreferences
  set setDarkTheme(bool value) {
    _darkTheme = value;
    darkThemePrefs.setDarkTheme(value); // Save to local storage
    notifyListeners(); // Rebuild dependent widgets
  }
}
