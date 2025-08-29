/// Typography System
///
/// This file provides a comprehensive typography system that follows
/// Material Design 3 principles with golden ratio proportions
/// and consistent text styling throughout the application.

import 'package:flutter/material.dart';
import 'golden_ratio_constants.dart';

/// Typography system based on golden ratio and Material Design 3
class TypographySystem {
  TypographySystem._();

  // MARK: - Font Weights
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;

  // MARK: - Line Heights
  static const double lineHeightTight = 1.0;
  static const double lineHeightSnug = 1.2;
  static const double lineHeightNormal = 1.4;
  static const double lineHeightRelaxed = 1.6;
  static const double lineHeightLoose = 1.8;

  // MARK: - Letter Spacing
  static const double letterSpacingTight = -0.05;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.05;

  // MARK: - Material Design 3 Text Styles

  /// Display Large - For large, prominent text (57px)
  static TextStyle get displayLarge => TextStyle(
        fontSize: GoldenRatio.headlineSize,
        fontWeight: bold,
        height: lineHeightTight,
        letterSpacing: letterSpacingTight,
      );

  /// Display Medium - For prominent text (~45px)
  static TextStyle get displayMedium => TextStyle(
        fontSize: GoldenRatio.headlineSize * 0.8, // ~65px
        fontWeight: bold,
        height: lineHeightTight,
        letterSpacing: letterSpacingTight,
      );

  /// Display Small - For smaller prominent text (~36px)
  static TextStyle get displaySmall => TextStyle(
        fontSize: GoldenRatio.textHeadline,
        fontWeight: bold,
        height: lineHeightSnug,
        letterSpacing: letterSpacingNormal,
      );

  /// Headline Large - For section headings (~32px)
  static TextStyle get headlineLarge => TextStyle(
        fontSize: GoldenRatio.textHeadline,
        fontWeight: semiBold,
        height: lineHeightSnug,
        letterSpacing: letterSpacingNormal,
      );

  /// Headline Medium - For subsection headings (~28px)
  static TextStyle get headlineMedium => TextStyle(
        fontSize: GoldenRatio.textTitle * 1.17, // ~28px
        fontWeight: semiBold,
        height: lineHeightSnug,
        letterSpacing: letterSpacingNormal,
      );

  /// Headline Small - For smaller headings (~24px)
  static TextStyle get headlineSmall => TextStyle(
        fontSize: GoldenRatio.textTitle,
        fontWeight: semiBold,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
      );

  /// Title Large - For card titles (~22px)
  static TextStyle get titleLarge => TextStyle(
        fontSize: GoldenRatio.textTitle * 0.92, // ~22px
        fontWeight: medium,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
      );

  /// Title Medium - For section titles (~16px)
  static TextStyle get titleMedium => TextStyle(
        fontSize: GoldenRatio.textMd,
        fontWeight: medium,
        height: lineHeightNormal,
        letterSpacing: letterSpacingWide,
      );

  /// Title Small - For smaller titles (~14px)
  static TextStyle get titleSmall => TextStyle(
        fontSize: GoldenRatio.textSm,
        fontWeight: medium,
        height: lineHeightNormal,
        letterSpacing: letterSpacingWide,
      );

  /// Body Large - For prominent body text (~16px)
  static TextStyle get bodyLarge => TextStyle(
        fontSize: GoldenRatio.textMd,
        fontWeight: regular,
        height: lineHeightRelaxed,
        letterSpacing: letterSpacingNormal,
      );

  /// Body Medium - For standard body text (~14px)
  static TextStyle get bodyMedium => TextStyle(
        fontSize: GoldenRatio.textSm,
        fontWeight: regular,
        height: lineHeightRelaxed,
        letterSpacing: letterSpacingNormal,
      );

  /// Body Small - For smaller body text (~12px)
  static TextStyle get bodySmall => TextStyle(
        fontSize: GoldenRatio.textXs,
        fontWeight: regular,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
      );

  /// Label Large - For button text (~14px)
  static TextStyle get labelLarge => TextStyle(
        fontSize: GoldenRatio.textSm,
        fontWeight: medium,
        height: lineHeightNormal,
        letterSpacing: letterSpacingWide,
      );

  /// Label Medium - For smaller button text (~12px)
  static TextStyle get labelMedium => TextStyle(
        fontSize: GoldenRatio.textXs,
        fontWeight: medium,
        height: lineHeightNormal,
        letterSpacing: letterSpacingWide,
      );

  /// Label Small - For micro text (~11px)
  static TextStyle get labelSmall => TextStyle(
        fontSize: 11.0,
        fontWeight: medium,
        height: lineHeightNormal,
        letterSpacing: letterSpacingWide,
      );

  // MARK: - Custom App Styles

  /// App bar title style
  static TextStyle get appBarTitle => TextStyle(
        fontSize: GoldenRatio.textXl,
        fontWeight: medium,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
      );

  /// Navigation item label
  static TextStyle get navigationLabel => TextStyle(
        fontSize: GoldenRatio.textXs,
        fontWeight: medium,
        height: lineHeightNormal,
        letterSpacing: letterSpacingWide,
      );

  /// Button text style
  static TextStyle get buttonText => TextStyle(
        fontSize: GoldenRatio.textSm,
        fontWeight: medium,
        height: lineHeightNormal,
        letterSpacing: letterSpacingWide,
      );

  /// Input field text style
  static TextStyle get inputText => TextStyle(
        fontSize: GoldenRatio.textMd,
        fontWeight: regular,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
      );

  /// Input field hint style
  static TextStyle get inputHint => TextStyle(
        fontSize: GoldenRatio.textMd,
        fontWeight: regular,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
      );

  /// Error text style
  static TextStyle get errorText => TextStyle(
        fontSize: GoldenRatio.textXs,
        fontWeight: regular,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
      );

  /// Helper text style
  static TextStyle get helperText => TextStyle(
        fontSize: GoldenRatio.textXs,
        fontWeight: regular,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
      );

  /// Caption text style
  static TextStyle get caption => TextStyle(
        fontSize: GoldenRatio.textXs,
        fontWeight: regular,
        height: lineHeightNormal,
        letterSpacing: letterSpacingNormal,
      );

  /// Overline text style
  static TextStyle get overline => TextStyle(
        fontSize: 10.0,
        fontWeight: medium,
        height: lineHeightNormal,
        letterSpacing: 1.5,
      );

  // MARK: - Utility Methods

  /// Create a custom text style with golden ratio font size
  static TextStyle custom({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
    TextDecoration? decoration,
    double? decorationThickness,
    Color? decorationColor,
    String? fontFamily,
    List<FontFeature>? fontFeatures,
    TextStyle? base,
  }) {
    return (base ?? bodyMedium).copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      decoration: decoration,
      decorationThickness: decorationThickness,
      decorationColor: decorationColor,
      fontFamily: fontFamily,
      fontFeatures: fontFeatures,
    );
  }

  /// Apply golden ratio scaling to any text style
  static TextStyle scaleWithGoldenRatio(
    TextStyle style, {
    bool larger = true,
    int steps = 1,
  }) {
    final currentSize = style.fontSize ?? bodyMedium.fontSize!;
    final scaleFactor = larger ? GoldenRatio.phi : GoldenRatio.phiInverse;
    double newSize = currentSize;

    for (int i = 0; i < steps; i++) {
      newSize *= scaleFactor;
    }

    return style.copyWith(fontSize: newSize);
  }

  /// Get text style with responsive sizing
  static TextStyle responsive(TextStyle baseStyle, double screenWidth) {
    final scaleFactor = _getScaleFactor(screenWidth);
    final fontSize = (baseStyle.fontSize ?? bodyMedium.fontSize!) * scaleFactor;

    return baseStyle.copyWith(fontSize: fontSize);
  }

  /// Get scale factor based on screen width
  static double _getScaleFactor(double screenWidth) {
    if (screenWidth < 360) return 0.85; // Small phones
    if (screenWidth < 480) return 0.95; // Regular phones
    if (screenWidth < 768) return 1.0; // Large phones
    if (screenWidth < 1024) return 1.1; // Tablets
    return 1.2; // Desktop
  }

  /// Get appropriate text style for the given context
  static TextStyle forContext(String context) {
    switch (context.toLowerCase()) {
      case 'appbar':
        return appBarTitle;
      case 'navigation':
        return navigationLabel;
      case 'button':
        return buttonText;
      case 'input':
        return inputText;
      case 'error':
        return errorText;
      case 'helper':
        return helperText;
      case 'caption':
        return caption;
      case 'overline':
        return overline;
      default:
        return bodyMedium;
    }
  }
}
