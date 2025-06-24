import 'package:flutter/material.dart';

/// AppSettings is a ChangeNotifier for managing app-wide settings such as theme, language, and notifications.
class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode;
  Locale _locale;
  bool _orderNotifications;
  bool _emailNotifications;
  bool _sound;
  bool _vibration;

  AppSettings({
    ThemeMode themeMode = ThemeMode.system,
    Locale? locale,
    bool orderNotifications = true,
    bool emailNotifications = true,
    bool sound = true,
    bool vibration = true,
  })  : _themeMode = themeMode,
        _locale = locale ?? const Locale('en'),
        _orderNotifications = orderNotifications,
        _emailNotifications = emailNotifications,
        _sound = sound,
        _vibration = vibration;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get orderNotifications => _orderNotifications;
  bool get emailNotifications => _emailNotifications;
  bool get sound => _sound;
  bool get vibration => _vibration;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void setLocale(Locale locale) {
    if (_locale != locale) {
      _locale = locale;
      notifyListeners();
    }
  }

  void setOrderNotifications(bool value) {
    if (_orderNotifications != value) {
      _orderNotifications = value;
      notifyListeners();
    }
  }

  void setEmailNotifications(bool value) {
    if (_emailNotifications != value) {
      _emailNotifications = value;
      notifyListeners();
    }
  }

  void setSound(bool value) {
    if (_sound != value) {
      _sound = value;
      notifyListeners();
    }
  }

  void setVibration(bool value) {
    if (_vibration != value) {
      _vibration = value;
      notifyListeners();
    }
  }
}
