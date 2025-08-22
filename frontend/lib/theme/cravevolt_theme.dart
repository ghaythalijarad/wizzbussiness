// WhizzMerchants Theme - Legacy Compatibility
// Delegates to unified AppTheme for consistency
// Primary Color: Lime Green (#32CD32)

import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Legacy theme class for backward compatibility
class CraveVoltTheme {
  static ThemeData dark({Locale? locale}) {
    return AppTheme.dark();
  }

  static ThemeData light({Locale? locale}) {
    return AppTheme.light();
  }
}

/// Legacy colors - Use AppTheme colors instead for new code
class CraveVoltColors {
  static const Color neonLime = AppTheme.primary;
  static const Color neonYellow =
      AppTheme.primary; // Use lime green instead of yellow
  static const Color background = AppTheme.backgroundDark;
  static const Color surface = AppTheme.surfaceDark;
  static const Color textPrimary = AppTheme.textLight;
  static const Color textSecondary = AppTheme.textSecondary;
  static const Color textMuted = Color(0xFF757575);
  static const Color success = AppTheme.success;
  static const Color warning = AppTheme.primary; // Use lime green for warnings
  static const Color error = AppTheme.error;
}
