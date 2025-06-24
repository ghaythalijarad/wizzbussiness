import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'ar'; // Changed to Arabic as default

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? _defaultLanguage;
  }

  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  static Locale getLocaleFromLanguageCode(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return const Locale('ar');
      case 'en':
      default:
        return const Locale('en');
    }
  }

  static List<Locale> getSupportedLocales() {
    return [
      const Locale('ar'), // Arabic first (primary)
      const Locale('en'), // English second
    ];
  }

  static List<Map<String, String>> getAvailableLanguages() {
    return [
      {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'}, // Arabic first
      {
        'code': 'en',
        'name': 'English',
        'nativeName': 'English'
      }, // English second
    ];
  }
}
