import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'golden_ratio_constants.dart';
import 'typography_system.dart';

/// Material Theme Configuration
///
/// Provides complete Material Design 3 themes with golden ratio proportions
/// and the app's brand colors (lime green and gold).

class MaterialTheme {
  MaterialTheme._();

  // ══════════════════════════════════════════════════════════════════════════
  // COLOR SCHEMES
  // ══════════════════════════════════════════════════════════════════════════

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.secondary,
    onSecondary: Colors.black,
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    background: Color(0xFFFFFBFE),
    onBackground: Color(0xFF1C1B1F),
    surface: Color(0xFFFFFBFE),
    onSurface: Color(0xFF1C1B1F),
    surfaceVariant: Color(0xFFE7E0EC),
    onSurfaceVariant: Color(0xFF49454F),
    outline: Color(0xFF79747E),
    outlineVariant: Color(0xFFCAC4D0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: Color(0xFF90CAF9),
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryLight,
    onPrimary: Colors.black,
    secondary: AppColors.secondaryLight,
    onSecondary: Colors.black,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    background: Color(0xFF1C1B1F),
    onBackground: Color(0xFFE6E1E5),
    surface: Color(0xFF1C1B1F),
    onSurface: Color(0xFFE6E1E5),
    surfaceVariant: Color(0xFF49454F),
    onSurfaceVariant: Color(0xFFCAC4D0),
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454F),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE6E1E5),
    onInverseSurface: Color(0xFF313033),
    inversePrimary: AppColors.primary,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // TEXT THEMES
  // ══════════════════════════════════════════════════════════════════════════

  static const TextTheme textTheme = TextTheme(
    displayLarge: TypographySystem.displayLarge,
    displayMedium: TypographySystem.displayMedium,
    displaySmall: TypographySystem.displaySmall,
    headlineLarge: TypographySystem.headlineLarge,
    headlineMedium: TypographySystem.headlineMedium,
    headlineSmall: TypographySystem.headlineSmall,
    titleLarge: TypographySystem.titleLarge,
    titleMedium: TypographySystem.titleMedium,
    titleSmall: TypographySystem.titleSmall,
    labelLarge: TypographySystem.labelLarge,
    labelMedium: TypographySystem.labelMedium,
    labelSmall: TypographySystem.labelSmall,
    bodyLarge: TypographySystem.bodyLarge,
    bodyMedium: TypographySystem.bodyMedium,
    bodySmall: TypographySystem.bodySmall,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ══════════════════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      textTheme: textTheme,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.surface,
        foregroundColor: lightColorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TypographySystem.titleLarge.copyWith(
          color: lightColorScheme.onSurface,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: GoldenRatio.xs,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.md),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: GoldenRatio.xs,
          padding: EdgeInsets.symmetric(
            horizontal: GoldenRatio.lg,
            vertical: GoldenRatio.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.md),
          ),
          textStyle: TypographySystem.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: GoldenRatio.lg,
            vertical: GoldenRatio.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.md),
          ),
          textStyle: TypographySystem.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: GoldenRatio.md,
            vertical: GoldenRatio.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.sm),
          ),
          textStyle: TypographySystem.labelLarge,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColorScheme.surfaceVariant.withOpacity(0.5),
        contentPadding: EdgeInsets.symmetric(
          horizontal: GoldenRatio.md,
          vertical: GoldenRatio.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.md),
          borderSide: BorderSide(
            color: lightColorScheme.outline,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.md),
          borderSide: BorderSide(
            color: lightColorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.md),
          borderSide: BorderSide(
            color: lightColorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.md),
          borderSide: BorderSide(
            color: lightColorScheme.error,
            width: 2,
          ),
        ),
        labelStyle: TypographySystem.bodyMedium,
        hintStyle: TypographySystem.bodyMedium.copyWith(
          color: lightColorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ══════════════════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      textTheme: textTheme,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.surface,
        foregroundColor: darkColorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TypographySystem.titleLarge.copyWith(
          color: darkColorScheme.onSurface,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: GoldenRatio.xs,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.md),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: GoldenRatio.xs,
          padding: EdgeInsets.symmetric(
            horizontal: GoldenRatio.lg,
            vertical: GoldenRatio.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.md),
          ),
          textStyle: TypographySystem.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: GoldenRatio.lg,
            vertical: GoldenRatio.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.md),
          ),
          textStyle: TypographySystem.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: GoldenRatio.md,
            vertical: GoldenRatio.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.sm),
          ),
          textStyle: TypographySystem.labelLarge,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.surfaceVariant.withOpacity(0.5),
        contentPadding: EdgeInsets.symmetric(
          horizontal: GoldenRatio.md,
          vertical: GoldenRatio.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.md),
          borderSide: BorderSide(
            color: darkColorScheme.outline,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.md),
          borderSide: BorderSide(
            color: darkColorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.md),
          borderSide: BorderSide(
            color: darkColorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.md),
          borderSide: BorderSide(
            color: darkColorScheme.error,
            width: 2,
          ),
        ),
        labelStyle: TypographySystem.bodyMedium,
        hintStyle: TypographySystem.bodyMedium.copyWith(
          color: darkColorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
