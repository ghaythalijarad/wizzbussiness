import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';

/// State for theme management
class ThemeManagerState {
  final ThemeMode themeMode;
  final bool useSystemTheme;
  const ThemeManagerState({
    this.themeMode = ThemeMode.light,
    this.useSystemTheme = true,
  });

  ThemeManagerState copyWith({ThemeMode? themeMode, bool? useSystemTheme}) =>
      ThemeManagerState(
        themeMode: themeMode ?? this.themeMode,
        useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      );
}

/// Notifier controlling theme state
class ThemeManagerNotifier extends StateNotifier<ThemeManagerState> {
  ThemeManagerNotifier() : super(const ThemeManagerState());

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode, useSystemTheme: false);
  }

  void setUseSystemTheme(bool value) {
    state = state.copyWith(useSystemTheme: value);
  }
}

/// Provider for theme manager
final themeManagerProvider =
    StateNotifierProvider<ThemeManagerNotifier, ThemeManagerState>((ref) {
  return ThemeManagerNotifier();
});

/// Light theme provider (locale-aware placeholder)
final themeDataProvider = Provider.family<ThemeData, Locale>((ref, locale) {
  // Could customize per-locale if needed
  return AppTheme.light();
});

/// Dark theme provider (locale-aware placeholder)
final darkThemeDataProvider = Provider.family<ThemeData, Locale>((ref, locale) {
  return AppTheme.dark();
});
