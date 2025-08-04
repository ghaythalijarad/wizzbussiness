import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/language_service.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en'));

  Future<void> loadLocale() async {
    final languageCode = await LanguageService.getLanguage();
    state = Locale(languageCode);
  }

  Future<void> setLocale(Locale locale) async {
    await LanguageService.setLanguage(locale.languageCode);
    state = locale;
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier()..loadLocale();
});
