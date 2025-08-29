/// Material Design 3 Theme Integration
///
/// This file integrates the golden ratio design system with Material Design 3
/// theme structure, providing consistent theming throughout the application.

import 'package:flutter/material.dart';
import 'golden_ratio_constants.dart';
import 'typography_system.dart';
import '../theme/app_colors.dart';

/// Material Theme class providing Material Design 3 themes
class MaterialTheme {
  MaterialTheme._();

  // MARK: - Light Theme
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.lightColorScheme,

        // Typography theme using our golden ratio typography system
        textTheme: TextTheme(
          displayLarge: TypographySystem.displayLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          displayMedium: TypographySystem.displayMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          displaySmall: TypographySystem.displaySmall.copyWith(
            color: AppColors.textPrimary,
          ),
          headlineLarge: TypographySystem.headlineLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          headlineMedium: TypographySystem.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          headlineSmall: TypographySystem.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
          titleLarge: TypographySystem.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          titleMedium: TypographySystem.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          titleSmall: TypographySystem.titleSmall.copyWith(
            color: AppColors.textPrimary,
          ),
          bodyLarge: TypographySystem.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          bodyMedium: TypographySystem.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
          bodySmall: TypographySystem.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          labelLarge: TypographySystem.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          labelMedium: TypographySystem.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          labelSmall: TypographySystem.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        // App Bar Theme
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: GoldenRatio.elevation1,
          scrolledUnderElevation: GoldenRatio.elevation2,
          toolbarHeight: GoldenRatio.appBarHeight,
          titleTextStyle: TypographySystem.titleLarge.copyWith(
            color: AppColors.onPrimary,
          ),
          iconTheme: IconThemeData(
            size: GoldenRatio.iconRegular,
            color: AppColors.onPrimary,
          ),
          actionsIconTheme: IconThemeData(
            size: GoldenRatio.iconRegular,
            color: AppColors.onPrimary,
          ),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          elevation: GoldenRatio.elevation1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
          ),
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: Size(
              GoldenRatio.buttonHeight * 2,
              GoldenRatio.buttonHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
            ),
            textStyle: TypographySystem.labelLarge,
          ),
        ),

        // Outlined Button Theme
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: Size(
              GoldenRatio.buttonHeight * 2,
              GoldenRatio.buttonHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
            ),
            textStyle: TypographySystem.labelLarge,
          ),
        ),

        // Text Button Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: Size(
              GoldenRatio.buttonHeightCompact * 2,
              GoldenRatio.buttonHeightCompact,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
            ),
            textStyle: TypographySystem.labelLarge,
          ),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
            borderSide: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          hintStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          labelStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          errorStyle: TypographySystem.bodySmall.copyWith(
            color: AppColors.error,
          ),
        ),

        // Chip Theme
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: AppColors.primaryContainer,
          secondarySelectedColor: AppColors.secondaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: TypographySystem.labelMedium,
          secondaryLabelStyle: TypographySystem.labelMedium,
          brightness: Brightness.light,
          elevation: GoldenRatio.elevation1,
          pressElevation: GoldenRatio.elevation2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
          ),
        ),

        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          elevation: GoldenRatio.elevation2,
          selectedIconTheme: IconThemeData(
            size: GoldenRatio.iconRegular,
            color: AppColors.primary,
          ),
          unselectedIconTheme: IconThemeData(
            size: GoldenRatio.iconRegular,
            color: AppColors.textSecondary,
          ),
          selectedLabelStyle: TypographySystem.labelMedium.copyWith(
            color: AppColors.primary,
          ),
          unselectedLabelStyle: TypographySystem.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        // Navigation Rail Theme
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: AppColors.surface,
          elevation: GoldenRatio.elevation1,
          selectedIconTheme: IconThemeData(
            size: GoldenRatio.iconRegular,
            color: AppColors.primary,
          ),
          unselectedIconTheme: IconThemeData(
            size: GoldenRatio.iconRegular,
            color: AppColors.textSecondary,
          ),
          selectedLabelTextStyle: TypographySystem.labelMedium.copyWith(
            color: AppColors.primary,
          ),
          unselectedLabelTextStyle: TypographySystem.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        // Tab Bar Theme
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: TypographySystem.labelLarge,
          unselectedLabelStyle: TypographySystem.labelLarge,
          indicator: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
          ),
        ),

        // Floating Action Button Theme
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: GoldenRatio.elevation3,
          focusElevation: GoldenRatio.elevation4,
          hoverElevation: GoldenRatio.elevation4,
          highlightElevation: GoldenRatio.elevation5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.sheetRadius),
          ),
          iconSize: GoldenRatio.iconRegular,
        ),

        // Dialog Theme
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          elevation: GoldenRatio.elevation5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.modalRadius),
          ),
          titleTextStyle: TypographySystem.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
          contentTextStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),

        // Bottom Sheet Theme
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          elevation: GoldenRatio.elevation4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(GoldenRatio.sheetRadius),
            ),
          ),
        ),

        // Snack Bar Theme
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.onSurface,
          contentTextStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.surface,
          ),
          actionTextColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
          ),
        ),

        // Divider Theme
        dividerTheme: DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 1,
        ),

        // Icon Theme
        iconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: AppColors.textPrimary,
        ),

        // Primary Icon Theme
        primaryIconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: AppColors.onPrimary,
        ),
      );

  // MARK: - Dark Theme
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.darkColorScheme,

        // Typography theme (same as light theme with different colors)
        textTheme: lightTheme.textTheme.apply(
          bodyColor: AppColors.darkColorScheme.onSurface,
          displayColor: AppColors.darkColorScheme.onSurface,
        ),

        // App Bar Theme for dark mode
        appBarTheme: lightTheme.appBarTheme.copyWith(
          backgroundColor: AppColors.darkColorScheme.surface,
          foregroundColor: AppColors.darkColorScheme.onSurface,
          titleTextStyle: TypographySystem.titleLarge.copyWith(
            color: AppColors.darkColorScheme.onSurface,
          ),
          iconTheme: IconThemeData(
            size: GoldenRatio.iconRegular,
            color: AppColors.darkColorScheme.onSurface,
          ),
          actionsIconTheme: IconThemeData(
            size: GoldenRatio.iconRegular,
            color: AppColors.darkColorScheme.onSurface,
          ),
        ),

        // Card Theme for dark mode
        cardTheme: lightTheme.cardTheme.copyWith(
          color: AppColors.darkColorScheme.surfaceContainer,
        ),

        // Input Decoration Theme for dark mode
        inputDecorationTheme: lightTheme.inputDecorationTheme.copyWith(
          fillColor: AppColors.darkColorScheme.surfaceVariant,
          hintStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.darkColorScheme.onSurfaceVariant,
          ),
          labelStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.darkColorScheme.onSurfaceVariant,
          ),
        ),

        // Bottom Navigation Bar Theme for dark mode
        bottomNavigationBarTheme: lightTheme.bottomNavigationBarTheme.copyWith(
          backgroundColor: AppColors.darkColorScheme.surface,
          selectedItemColor: AppColors.darkColorScheme.primary,
          unselectedItemColor: AppColors.darkColorScheme.onSurfaceVariant,
        ),

        // Other themes inherit from light theme with color scheme changes
        elevatedButtonTheme: lightTheme.elevatedButtonTheme,
        outlinedButtonTheme: lightTheme.outlinedButtonTheme,
        textButtonTheme: lightTheme.textButtonTheme,
        chipTheme: lightTheme.chipTheme,
        navigationRailTheme: lightTheme.navigationRailTheme,
        tabBarTheme: lightTheme.tabBarTheme,
        floatingActionButtonTheme: lightTheme.floatingActionButtonTheme,
        dialogTheme: lightTheme.dialogTheme,
        bottomSheetTheme: lightTheme.bottomSheetTheme,
        snackBarTheme: lightTheme.snackBarTheme,
        dividerTheme: lightTheme.dividerTheme,
        iconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: AppColors.darkColorScheme.onSurface,
        ),
        primaryIconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: AppColors.darkColorScheme.onPrimary,
        ),
      );

  // MARK: - Utility Methods

  /// Get theme data based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.light ? lightTheme : darkTheme;
  }

  /// Get theme data based on theme mode and system brightness
  static ThemeData getThemeForMode(
      ThemeMode mode, Brightness systemBrightness) {
    switch (mode) {
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.system:
        return systemBrightness == Brightness.light ? lightTheme : darkTheme;
    }
  }
}
