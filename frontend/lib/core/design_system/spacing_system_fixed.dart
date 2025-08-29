/// Spacing System based on Golden Ratio Progression
///
/// This file provides a comprehensive spacing system that follows
/// the golden ratio progression for consistent visual hierarchy
/// and balanced layouts throughout the application.

import 'package:flutter/material.dart';
import 'golden_ratio_constants.dart';

/// Spacing System class providing golden ratio based spacing values
class SpacingSystem {
  SpacingSystem._();

  // MARK: - Core Spacing Values
  /// Extra small spacing (4px) - for micro adjustments
  static const double xs = GoldenRatio.xs;

  /// Small spacing (8px) - for tight spacing between related elements
  static const double sm = GoldenRatio.sm;

  /// Medium spacing (~13px) - standard spacing between elements
  static const double md = GoldenRatio.md;

  /// Large spacing (~21px) - spacing between sections
  static const double lg = GoldenRatio.lg;

  /// Extra large spacing (~34px) - major section spacing
  static const double xl = GoldenRatio.xl;

  /// Double extra large spacing (~55px) - page-level spacing
  static const double xxl = GoldenRatio.xxl;

  // MARK: - EdgeInsets Presets
  /// No padding
  static const EdgeInsets none = EdgeInsets.zero;

  /// All sides padding - Extra Small (4px)
  static const EdgeInsets allXs = EdgeInsets.all(xs);

  /// All sides padding - Small (8px)
  static const EdgeInsets allSm = EdgeInsets.all(sm);

  /// All sides padding - Medium (~13px)
  static const EdgeInsets allMd = EdgeInsets.all(md);

  /// All sides padding - Large (~21px)
  static const EdgeInsets allLg = EdgeInsets.all(lg);

  /// All sides padding - Extra Large (~34px)
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  /// All sides padding - Double Extra Large (~55px)
  static const EdgeInsets allXxl = EdgeInsets.all(xxl);

  // MARK: - Horizontal Padding
  /// Horizontal padding - Small (8px)
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);

  /// Horizontal padding - Medium (~13px)
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);

  /// Horizontal padding - Large (~21px)
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  /// Horizontal padding - Extra Large (~34px)
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  /// Horizontal padding - Double Extra Large (~55px)
  static const EdgeInsets horizontalXxl = EdgeInsets.symmetric(horizontal: xxl);

  // MARK: - Vertical Padding
  /// Vertical padding - Small (8px)
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);

  /// Vertical padding - Medium (~13px)
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);

  /// Vertical padding - Large (~21px)
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);

  /// Vertical padding - Extra Large (~34px)
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);

  /// Vertical padding - Double Extra Large (~55px)
  static const EdgeInsets verticalXxl = EdgeInsets.symmetric(vertical: xxl);

  // MARK: - Card and Container Padding
  /// Standard card padding (~21px all sides)
  static const EdgeInsets card = EdgeInsets.all(lg);

  /// Compact card padding (~13px all sides)
  static const EdgeInsets cardCompact = EdgeInsets.all(md);

  /// Spacious card padding (~34px all sides)
  static const EdgeInsets cardSpacious = EdgeInsets.all(xl);

  /// Page content padding (~34px horizontal, ~21px vertical)
  static const EdgeInsets pageContent = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  /// Screen edge padding (standard safe area padding)
  static const EdgeInsets screenEdge = EdgeInsets.all(xl);

  /// Bottom sheet padding (~34px horizontal, ~55px vertical)
  static const EdgeInsets bottomSheet = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: xxl,
  );

  /// Dialog padding (~55px all sides)
  static const EdgeInsets dialog = EdgeInsets.all(xxl);

  // MARK: - Component-Specific Padding
  /// Button padding (~21px horizontal, ~13px vertical)
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Large button padding (~34px horizontal, ~21px vertical)
  static const EdgeInsets buttonLarge = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  /// Small button padding (~13px horizontal, 8px vertical)
  static const EdgeInsets buttonSmall = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  /// Input field padding (~21px horizontal, ~21px vertical)
  static const EdgeInsets inputField = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: lg,
  );

  /// List item padding (~34px horizontal, ~21px vertical)
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: lg,
  );

  /// Compact list item padding (~21px horizontal, ~13px vertical)
  static const EdgeInsets listItemCompact = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// App bar action padding (~13px all sides)
  static const EdgeInsets appBarAction = EdgeInsets.all(md);

  /// Chip padding (~13px horizontal, 8px vertical)
  static const EdgeInsets chip = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
}

/// SizedBox presets for consistent spacing
class SpacingWidgets {
  SpacingWidgets._();

  // MARK: - Vertical Spacing (Height)
  /// Vertical spacing - Extra Small (4px)
  static const SizedBox verticalXs = SizedBox(height: SpacingSystem.xs);

  /// Vertical spacing - Small (8px)
  static const SizedBox verticalSm = SizedBox(height: SpacingSystem.sm);

  /// Vertical spacing - Medium (~13px)
  static const SizedBox verticalMd = SizedBox(height: SpacingSystem.md);

  /// Vertical spacing - Large (~21px)
  static const SizedBox verticalLg = SizedBox(height: SpacingSystem.lg);

  /// Vertical spacing - Extra Large (~34px)
  static const SizedBox verticalXl = SizedBox(height: SpacingSystem.xl);

  /// Vertical spacing - Double Extra Large (~55px)
  static const SizedBox verticalXxl = SizedBox(height: SpacingSystem.xxl);

  // MARK: - Horizontal Spacing (Width)
  /// Horizontal spacing - Extra Small (4px)
  static const SizedBox horizontalXs = SizedBox(width: SpacingSystem.xs);

  /// Horizontal spacing - Small (8px)
  static const SizedBox horizontalSm = SizedBox(width: SpacingSystem.sm);

  /// Horizontal spacing - Medium (~13px)
  static const SizedBox horizontalMd = SizedBox(width: SpacingSystem.md);

  /// Horizontal spacing - Large (~21px)
  static const SizedBox horizontalLg = SizedBox(width: SpacingSystem.lg);

  /// Horizontal spacing - Extra Large (~34px)
  static const SizedBox horizontalXl = SizedBox(width: SpacingSystem.xl);

  /// Horizontal spacing - Double Extra Large (~55px)
  static const SizedBox horizontalXxl = SizedBox(width: SpacingSystem.xxl);

  // MARK: - Flexible Spacing
  /// Creates a flexible vertical space that expands
  static const Widget flexibleVertical = Expanded(child: SizedBox());

  /// Creates a flexible horizontal space that expands
  static const Widget flexibleHorizontal = Expanded(child: SizedBox());

  /// Creates custom vertical spacing
  static SizedBox vertical(double height) => SizedBox(height: height);

  /// Creates custom horizontal spacing
  static SizedBox horizontal(double width) => SizedBox(width: width);
}

/// Padding extension for widgets
extension PaddingExtension on Widget {
  /// Apply custom padding
  Widget withPadding(EdgeInsets padding) => Padding(
        padding: padding,
        child: this,
      );

  /// Apply all sides padding
  Widget paddingAll(double value) => Padding(
        padding: EdgeInsets.all(value),
        child: this,
      );

  /// Apply horizontal padding
  Widget paddingHorizontal(double value) => Padding(
        padding: EdgeInsets.symmetric(horizontal: value),
        child: this,
      );

  /// Apply vertical padding
  Widget paddingVertical(double value) => Padding(
        padding: EdgeInsets.symmetric(vertical: value),
        child: this,
      );

  /// Apply custom symmetric padding
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) =>
      Padding(
        padding:
            EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
        child: this,
      );

  /// Apply padding using spacing system values
  Widget paddingSpacing({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    if (all != null) {
      return withPadding(EdgeInsets.all(all));
    }

    return withPadding(EdgeInsets.only(
      top: top ?? vertical ?? 0,
      bottom: bottom ?? vertical ?? 0,
      left: left ?? horizontal ?? 0,
      right: right ?? horizontal ?? 0,
    ));
  }
}

/// Margin extension for widgets
extension MarginExtension on Widget {
  /// Apply custom margin using Container
  Widget withMargin(EdgeInsets margin) => Container(
        margin: margin,
        child: this,
      );

  /// Apply all sides margin
  Widget marginAll(double value) => Container(
        margin: EdgeInsets.all(value),
        child: this,
      );

  /// Apply horizontal margin
  Widget marginHorizontal(double value) => Container(
        margin: EdgeInsets.symmetric(horizontal: value),
        child: this,
      );

  /// Apply vertical margin
  Widget marginVertical(double value) => Container(
        margin: EdgeInsets.symmetric(vertical: value),
        child: this,
      );

  /// Apply custom symmetric margin
  Widget marginSymmetric({double horizontal = 0, double vertical = 0}) =>
      Container(
        margin:
            EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
        child: this,
      );
}
