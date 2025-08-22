// Design tokens & shared constants for theming
import 'package:flutter/material.dart';

// Spacing scale
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

// Border radii
class AppBorderRadius {
  static const double sm = 6;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;
}

// Elevation levels
class AppElevation {
  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;
  static const double level4 = 8;
  static const double level5 = 12;
}

// Enum describing semantic gradient selections
enum ThemeGradient { primary, secondary, primaryToSecondary, surface, status }

// Internal gradient palette
class _GradientPalette {
  const _GradientPalette();

  LinearGradient get primaryGradient => const LinearGradient(
        colors: [Color(0xFF32CD32), Color(0xFF32CD32)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get secondaryGradient => const LinearGradient(
        colors: [Color(0xFF1E8F1E), Color(0xFF146614)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  LinearGradient get primaryToSecondary => const LinearGradient(
        colors: [Color(0xFF32CD32), Color(0xFF1E8F1E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get surfaceGradient => LinearGradient(
        colors: [
          const Color(0xFF32CD32).withOpacity(0.06),
          const Color(0xFF146614).withOpacity(0.06)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient get statusGradient => const LinearGradient(
        colors: [Color(0xFF32CD32), Color(0xFFE53935)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient resolve(ThemeGradient g) {
    switch (g) {
      case ThemeGradient.primary:
        return primaryGradient;
      case ThemeGradient.secondary:
        return secondaryGradient;
      case ThemeGradient.primaryToSecondary:
        return primaryToSecondary;
      case ThemeGradient.surface:
        return surfaceGradient;
      case ThemeGradient.status:
        return statusGradient;
    }
  }
}

const _gradientPalette = _GradientPalette();

// BuildContext helpers
class _GradientAccess {
  const _GradientAccess();
  LinearGradient get primaryGradient => _gradientPalette.primaryGradient;
  LinearGradient get secondaryGradient => _gradientPalette.secondaryGradient;
  LinearGradient get primaryToSecondary => _gradientPalette.primaryToSecondary;
  LinearGradient get surfaceGradient => _gradientPalette.surfaceGradient;
  LinearGradient get statusGradient => _gradientPalette.statusGradient;
  LinearGradient call(ThemeGradient g) => _gradientPalette.resolve(g);
}

const _gradientAccess = _GradientAccess();

extension GradientContext on BuildContext {
  _GradientAccess get gradients => _gradientAccess;
}
