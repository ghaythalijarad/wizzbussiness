import 'package:flutter/material.dart';

/// Application color palette and theme colors
class AppColors {
  AppColors._();

  // Primary brand color - Lime Green
  static const Color primary = Color(0xFF32CD32);
  
  // Primary color variations
  static const Color primaryLight = Color(0xFF66FF66);
  static const Color primaryDark = Color(0xFF228B22);
  static const Color primaryContainer = Color(0xFFE8F5E8);
  
  // Secondary colors - Gold
  static const Color secondary = Color(0xFFFFD300);
  static const Color secondaryLight = Color(0xFFFFFF52);
  static const Color secondaryDark = Color(0xFFC7A600);
  static const Color secondaryContainer = Color(0xFFFFF8E1);
  
  // Neutral colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color surfaceContainer = Color(0xFFFAFAFA);
  static const Color surfaceContainerHigh = Color(0xFFF0F0F0);
  static const Color surfaceContainerHighest = Color(0xFFE8E8E8);
  
  // Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundVariant = Color(0xFFFAFAFA);
  
  // Text colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF0A2E0A);
  static const Color onSecondary = Color(0xFF000000);
  static const Color onSecondaryContainer = Color(0xFF3D3100);
  static const Color onSurface = Color(0xFF1C1C1C);
  static const Color onSurfaceVariant = Color(0xFF666666);
  static const Color onBackground = Color(0xFF1C1C1C);
  static const Color textPrimary = Color(0xFF1C1C1C);
  static const Color textSecondary = Color(0xFF666666);
  
  // Status colors
  static const Color success = Color(0xFF22C55E);
  static const Color successContainer = Color(0xFFE8F5E8);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFFF8E8);
  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFFE8E8);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFE8F2FF);
  
  // Order status colors
  static const Color orderPending = Color(0xFFF59E0B);
  static const Color orderConfirmed = Color(0xFF32CD32);
  static const Color orderPreparing = Color(0xFF8B5CF6);
  static const Color orderReady = Color(0xFF06B6D4);
  static const Color orderDelivered = Color(0xFF22C55E);
  static const Color orderCancelled = Color(0xFFEF4444);
  
  // Chart colors (harmonious with lime green)
  static const List<Color> chartColors = [
    Color(0xFF32CD32), // Lime Green
    Color(0xFF6366F1), // Indigo
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
    Color(0xFFEC4899), // Pink
  ];
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF32CD32), Color(0xFF228B22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadow colors
  static Color shadow = const Color(0xFF000000).withValues(alpha: 0.1);
  static Color shadowLight = const Color(0xFF000000).withValues(alpha: 0.05);
  static Color shadowMedium = const Color(0xFF000000).withValues(alpha: 0.15);
  static Color shadowDark = const Color(0xFF000000).withValues(alpha: 0.25);
  
  // Border colors
  static Color border = const Color(0xFF000000).withValues(alpha: 0.1);
  static Color borderLight = const Color(0xFF000000).withValues(alpha: 0.05);
  static Color borderMedium = const Color(0xFF000000).withValues(alpha: 0.15);
  
  // Overlay colors
  static Color overlay = const Color(0xFF000000).withValues(alpha: 0.5);
  static Color overlayLight = const Color(0xFF000000).withValues(alpha: 0.3);
  static Color overlayDark = const Color(0xFF000000).withValues(alpha: 0.7);
  
  // Helper methods
  static ColorScheme get lightColorScheme => ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        surface: surface,
        surfaceVariant: surfaceVariant,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
        background: background,
        error: error,
        errorContainer: errorContainer,
        onPrimary: onPrimary,
        onPrimaryContainer: onPrimaryContainer,
        onSecondary: onSecondary,
        onSecondaryContainer: onSecondaryContainer,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        onBackground: onBackground,
        onError: onPrimary,
        onErrorContainer: onPrimaryContainer,
      );
  
  static ColorScheme get darkColorScheme => ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        primaryContainer: Color(0xFF1A3D1A),
        secondary: secondaryLight,
        secondaryContainer: Color(0xFF2A2A4A),
        surface: Color(0xFF121212),
        surfaceVariant: Color(0xFF1E1E1E),
        surfaceContainer: Color(0xFF1A1A1A),
        surfaceContainerHigh: Color(0xFF2A2A2A),
        surfaceContainerHighest: Color(0xFF333333),
        background: Color(0xFF0F0F0F),
        error: Color(0xFFFF6B6B),
        errorContainer: Color(0xFF4A1A1A),
        onPrimary: Color(0xFF000000),
        onPrimaryContainer: Color(0xFFB8E6B8),
        onSecondary: Color(0xFF000000),
        onSecondaryContainer: Color(0xFFE8E8FF),
        onSurface: Color(0xFFE8E8E8),
        onSurfaceVariant: Color(0xFFB8B8B8),
        onBackground: Color(0xFFE8E8E8),
        onError: Color(0xFF000000),
        onErrorContainer: Color(0xFFFFB8B8),
      );
}
