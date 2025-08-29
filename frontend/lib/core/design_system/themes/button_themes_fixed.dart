/// Button Themes System
/// 
/// This file provides comprehensive button theming that follows
/// Material Design 3 principles with golden ratio proportions
/// and consistent styling throughout the application.

import 'package:flutter/material.dart';
import '../design_system.dart';

/// Button Themes class providing Material Design 3 button styles
class ButtonThemes {
  ButtonThemes._();

  // MARK: - Button Sizes
  
  /// Small button size
  static const Size smallSize = Size(
    GoldenRatio.buttonHeightCompact * 2,
    GoldenRatio.buttonHeightCompact,
  );
  
  /// Medium button size (default)
  static const Size mediumSize = Size(
    GoldenRatio.buttonHeight * 2,
    GoldenRatio.buttonHeight,
  );
  
  /// Large button size
  static const Size largeSize = Size(
    GoldenRatio.buttonHeightLarge * 2,
    GoldenRatio.buttonHeightLarge,
  );

  // MARK: - Primary Buttons (Elevated)

  /// Primary elevated button style
  static ButtonStyle get primaryElevatedButton => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    elevation: GoldenRatio.elevation1,
    minimumSize: mediumSize,
    padding: EdgeInsets.symmetric(
      horizontal: GoldenRatio.lg,
      vertical: GoldenRatio.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
    ),
    textStyle: TextStyle(
      fontSize: GoldenRatio.textSm,
      fontWeight: FontWeight.w500,
    ),
  );

  /// Secondary elevated button style
  static ButtonStyle get secondaryElevatedButton => ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.onSecondary,
    elevation: GoldenRatio.elevation1,
    minimumSize: mediumSize,
    padding: EdgeInsets.symmetric(
      horizontal: GoldenRatio.lg,
      vertical: GoldenRatio.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
    ),
    textStyle: TextStyle(
      fontSize: GoldenRatio.textSm,
      fontWeight: FontWeight.w500,
    ),
  );

  /// Large elevated button style
  static ButtonStyle get largeElevatedButton => primaryElevatedButton.copyWith(
    minimumSize: MaterialStateProperty.all(largeSize),
    padding: MaterialStateProperty.all(EdgeInsets.symmetric(
      horizontal: GoldenRatio.xl,
      vertical: GoldenRatio.lg,
    )),
    textStyle: MaterialStateProperty.all(TextStyle(
      fontSize: GoldenRatio.textMd,
      fontWeight: FontWeight.w500,
    )),
  );

  /// Small elevated button style
  static ButtonStyle get smallElevatedButton => primaryElevatedButton.copyWith(
    minimumSize: MaterialStateProperty.all(smallSize),
    padding: MaterialStateProperty.all(EdgeInsets.symmetric(
      horizontal: GoldenRatio.md,
      vertical: GoldenRatio.sm,
    )),
    textStyle: MaterialStateProperty.all(TextStyle(
      fontSize: GoldenRatio.textXs,
      fontWeight: FontWeight.w500,
    )),
  );

  // MARK: - Outlined Buttons

  /// Primary outlined button style
  static ButtonStyle get primaryOutlinedButton => OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    minimumSize: mediumSize,
    padding: EdgeInsets.symmetric(
      horizontal: GoldenRatio.lg,
      vertical: GoldenRatio.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
    ),
    side: BorderSide(
      color: AppColors.primary,
      width: 1.5,
    ),
    textStyle: TextStyle(
      fontSize: GoldenRatio.textSm,
      fontWeight: FontWeight.w500,
    ),
  ).copyWith(
    overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
      if (states.contains(MaterialState.hovered)) {
        return AppColors.primary.withOpacity(0.04);
      }
      if (states.contains(MaterialState.pressed)) {
        return AppColors.primary.withOpacity(0.12);
      }
      return null;
    }),
  );

  /// Secondary outlined button style
  static ButtonStyle get secondaryOutlinedButton => OutlinedButton.styleFrom(
    foregroundColor: AppColors.secondary,
    minimumSize: mediumSize,
    padding: EdgeInsets.symmetric(
      horizontal: GoldenRatio.lg,
      vertical: GoldenRatio.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
    ),
    side: BorderSide(
      color: AppColors.secondary,
      width: 1.5,
    ),
    textStyle: TextStyle(
      fontSize: GoldenRatio.textSm,
      fontWeight: FontWeight.w500,
    ),
  ).copyWith(
    overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
      if (states.contains(MaterialState.hovered)) {
        return AppColors.secondary.withOpacity(0.04);
      }
      if (states.contains(MaterialState.pressed)) {
        return AppColors.secondary.withOpacity(0.12);
      }
      return null;
    }),
  );

  /// Large outlined button style
  static ButtonStyle get largeOutlinedButton => primaryOutlinedButton.copyWith(
    minimumSize: MaterialStateProperty.all(largeSize),
    padding: MaterialStateProperty.all(EdgeInsets.symmetric(
      horizontal: GoldenRatio.xl,
      vertical: GoldenRatio.lg,
    )),
    textStyle: MaterialStateProperty.all(TextStyle(
      fontSize: GoldenRatio.textMd,
      fontWeight: FontWeight.w500,
    )),
  );

  /// Small outlined button style
  static ButtonStyle get smallOutlinedButton => primaryOutlinedButton.copyWith(
    minimumSize: MaterialStateProperty.all(smallSize),
    padding: MaterialStateProperty.all(EdgeInsets.symmetric(
      horizontal: GoldenRatio.md,
      vertical: GoldenRatio.sm,
    )),
    textStyle: MaterialStateProperty.all(TextStyle(
      fontSize: GoldenRatio.textXs,
      fontWeight: FontWeight.w500,
    )),
  );

  // MARK: - Text Buttons

  /// Primary text button style
  static ButtonStyle get primaryTextButton => TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    minimumSize: Size(
      GoldenRatio.buttonHeightCompact * 1.5,
      GoldenRatio.buttonHeightCompact,
    ),
    padding: EdgeInsets.symmetric(
      horizontal: GoldenRatio.md,
      vertical: GoldenRatio.sm,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
    ),
    textStyle: TextStyle(
      fontSize: GoldenRatio.textSm,
      fontWeight: FontWeight.w500,
    ),
  ).copyWith(
    overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
      if (states.contains(MaterialState.hovered)) {
        return AppColors.primary.withOpacity(0.04);
      }
      if (states.contains(MaterialState.pressed)) {
        return AppColors.primary.withOpacity(0.12);
      }
      return null;
    }),
  );

  /// Success text button style
  static ButtonStyle get successTextButton => TextButton.styleFrom(
    foregroundColor: AppColors.success,
    minimumSize: Size(
      GoldenRatio.buttonHeightCompact * 1.5,
      GoldenRatio.buttonHeightCompact,
    ),
    padding: EdgeInsets.symmetric(
      horizontal: GoldenRatio.md,
      vertical: GoldenRatio.sm,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
    ),
    textStyle: TextStyle(
      fontSize: GoldenRatio.textSm,
      fontWeight: FontWeight.w500,
    ),
  );

  /// Destructive text button style
  static ButtonStyle get destructiveTextButton => TextButton.styleFrom(
    foregroundColor: AppColors.error,
    minimumSize: Size(
      GoldenRatio.buttonHeightCompact * 1.5,
      GoldenRatio.buttonHeightCompact,
    ),
    padding: EdgeInsets.symmetric(
      horizontal: GoldenRatio.md,
      vertical: GoldenRatio.sm,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
    ),
    textStyle: TextStyle(
      fontSize: GoldenRatio.textSm,
      fontWeight: FontWeight.w500,
    ),
  );

  // MARK: - Icon Buttons

  /// Standard icon button style
  static ButtonStyle get iconButton => IconButton.styleFrom(
    foregroundColor: AppColors.primary,
    backgroundColor: Colors.transparent,
    padding: EdgeInsets.all(GoldenRatio.md),
    fixedSize: Size(
      GoldenRatio.buttonHeight,
      GoldenRatio.buttonHeight,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
    ),
  ).copyWith(
    overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
      if (states.contains(MaterialState.hovered)) {
        return AppColors.primary.withOpacity(0.04);
      }
      if (states.contains(MaterialState.pressed)) {
        return AppColors.primary.withOpacity(0.12);
      }
      return null;
    }),
  );

  /// Filled icon button style
  static ButtonStyle get filledIconButton => IconButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    padding: EdgeInsets.all(GoldenRatio.md),
    fixedSize: Size(
      GoldenRatio.buttonHeight,
      GoldenRatio.buttonHeight,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
    ),
  );

  // MARK: - Floating Action Buttons

  /// Standard FAB style as ButtonStyle (for use with ElevatedButton)
  static ButtonStyle get standardFab => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    elevation: GoldenRatio.elevation3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.sheetRadius),
    ),
    minimumSize: const Size(56, 56),
    maximumSize: const Size(56, 56),
  );

  /// Extended FAB style as ButtonStyle
  static ButtonStyle get extendedFab => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    elevation: GoldenRatio.elevation3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.sheetRadius),
    ),
    minimumSize: const Size(80, 56),
    padding: EdgeInsets.symmetric(
      horizontal: GoldenRatio.lg,
      vertical: GoldenRatio.md,
    ),
  );

  /// Small FAB style as ButtonStyle
  static ButtonStyle get smallFab => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    elevation: GoldenRatio.elevation3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
    ),
    minimumSize: const Size(40, 40),
    maximumSize: const Size(40, 40),
  );

  /// Large FAB style as ButtonStyle
  static ButtonStyle get largeFab => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    elevation: GoldenRatio.elevation3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.sheetRadius),
    ),
    minimumSize: const Size(96, 96),
    maximumSize: const Size(96, 96),
  );

  // MARK: - Special Purpose Buttons

  /// Success button style (green)
  static ButtonStyle get successButton => ElevatedButton.styleFrom(
    backgroundColor: AppColors.success,
    foregroundColor: Colors.white,
    elevation: GoldenRatio.elevation1,
    minimumSize: mediumSize,
    padding: EdgeInsets.symmetric(
      horizontal: GoldenRatio.lg,
      vertical: GoldenRatio.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
    ),
    textStyle: TextStyle(
      fontSize: GoldenRatio.textSm,
      fontWeight: FontWeight.w500,
    ),
  );

  /// Destructive button style (red)
  static ButtonStyle get destructiveButton => ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: Colors.white,
    elevation: GoldenRatio.elevation1,
    minimumSize: mediumSize,
    padding: EdgeInsets.symmetric(
      horizontal: GoldenRatio.lg,
      vertical: GoldenRatio.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
    ),
    textStyle: TextStyle(
      fontSize: GoldenRatio.textSm,
      fontWeight: FontWeight.w500,
    ),
  );

  /// Disabled button style
  static ButtonStyle get disabledButton => ElevatedButton.styleFrom(
    backgroundColor: AppColors.surfaceVariant,
    foregroundColor: AppColors.onSurfaceVariant,
    elevation: 0,
    minimumSize: mediumSize,
    padding: EdgeInsets.symmetric(
      horizontal: GoldenRatio.lg,
      vertical: GoldenRatio.md,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
    ),
    textStyle: TextStyle(
      fontSize: GoldenRatio.textSm,
      fontWeight: FontWeight.w500,
    ),
  );

  // MARK: - Button Group Utilities

  /// Spacing between buttons in a group
  static const double buttonGroupSpacing = GoldenRatio.md;

  /// Create a horizontal button group with proper spacing
  static Widget horizontalGroup(List<Widget> buttons) {
    if (buttons.isEmpty) return const SizedBox.shrink();
    if (buttons.length == 1) return buttons.first;

    final List<Widget> spacedButtons = [];
    for (int i = 0; i < buttons.length; i++) {
      spacedButtons.add(buttons[i]);
      if (i < buttons.length - 1) {
        spacedButtons.add(SizedBox(width: buttonGroupSpacing));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: spacedButtons,
    );
  }

  /// Create a vertical button group with proper spacing
  static Widget verticalGroup(List<Widget> buttons) {
    if (buttons.isEmpty) return const SizedBox.shrink();
    if (buttons.length == 1) return buttons.first;

    final List<Widget> spacedButtons = [];
    for (int i = 0; i < buttons.length; i++) {
      spacedButtons.add(buttons[i]);
      if (i < buttons.length - 1) {
        spacedButtons.add(SizedBox(height: buttonGroupSpacing));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: spacedButtons,
    );
  }

  // MARK: - Button Size Presets

  /// Size presets for consistent button sizing
  static const Size tiny = Size(
    GoldenRatio.buttonHeightCompact,
    GoldenRatio.buttonHeightCompact,
  );

  static const Size compact = Size(
    GoldenRatio.buttonHeightCompact * 1.5,
    GoldenRatio.buttonHeightCompact,
  );

  static const Size regular = mediumSize;

  static const Size extended = Size(
    GoldenRatio.buttonHeight * 3,
    GoldenRatio.buttonHeight,
  );

  static const Size fullWidth = Size(
    double.infinity,
    GoldenRatio.buttonHeight,
  );

  // MARK: - Helper Methods

  /// Apply golden ratio scaling to button size
  static Size scaleSize(Size baseSize, {bool larger = true, int steps = 1}) {
    final scaleFactor = larger ? GoldenRatio.phi : GoldenRatio.phiInverse;
    double newWidth = baseSize.width;
    double newHeight = baseSize.height;
    
    for (int i = 0; i < steps; i++) {
      newWidth *= scaleFactor;
      newHeight *= scaleFactor;
    }
    
    return Size(newWidth, newHeight);
  }

  /// Get button style by type and variant
  static ButtonStyle getStyle(String type, {String variant = 'primary'}) {
    switch (type.toLowerCase()) {
      case 'elevated':
        switch (variant) {
          case 'secondary': return secondaryElevatedButton;
          case 'large': return largeElevatedButton;
          case 'small': return smallElevatedButton;
          case 'success': return successButton;
          case 'destructive': return destructiveButton;
          case 'disabled': return disabledButton;
          default: return primaryElevatedButton;
        }
      case 'outlined':
        switch (variant) {
          case 'secondary': return secondaryOutlinedButton;
          case 'large': return largeOutlinedButton;
          case 'small': return smallOutlinedButton;
          default: return primaryOutlinedButton;
        }
      case 'text':
        switch (variant) {
          case 'success': return successTextButton;
          case 'destructive': return destructiveTextButton;
          default: return primaryTextButton;
        }
      case 'icon':
        switch (variant) {
          case 'filled': return filledIconButton;
          default: return iconButton;
        }
      case 'fab':
        switch (variant) {
          case 'extended': return extendedFab;
          case 'small': return smallFab;
          case 'large': return largeFab;
          default: return standardFab;
        }
      default:
        return primaryElevatedButton;
    }
  }
}
