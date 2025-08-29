/// Card Themes System
/// 
/// This file provides comprehensive card theming that follows
/// Material Design 3 principles with golden ratio proportions
/// and consistent styling throughout the application.

import 'package:flutter/material.dart';
import '../golden_ratio_constants.dart';
import '../spacing_system.dart';
import '../../theme/app_colors.dart';

/// Card Themes class providing Material Design 3 card styles
class CardThemesFixed {
  CardThemesFixed._();

  // MARK: - Base Card Styles

  /// Standard card theme
  static CardThemeData get standard => CardThemeData(
    elevation: GoldenRatio.xs,
    color: AppColors.surface,
    shadowColor: AppColors.shadow,
    surfaceTintColor: AppColors.surfaceVariant,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
    ),
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.all(GoldenRatio.md),
  );

  /// Elevated card theme
  static CardThemeData get elevated => CardThemeData(
    elevation: GoldenRatio.sm,
    color: AppColors.surface,
    shadowColor: AppColors.shadow,
    surfaceTintColor: AppColors.surfaceVariant,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
    ),
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.all(GoldenRatio.md),
  );

  /// Outlined card theme
  static CardThemeData get outlined => CardThemeData(
    elevation: 0,
    color: AppColors.surface,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
      side: BorderSide(
        color: AppColors.border,
        width: 1,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.all(GoldenRatio.md),
  );

  /// Filled card theme
  static CardThemeData get filled => CardThemeData(
    elevation: 0,
    color: AppColors.surfaceVariant,
    shadowColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.radiusSm),
    ),
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.all(GoldenRatio.sm),
  );

  /// Large card theme
  static CardThemeData get large => CardThemeData(
    elevation: GoldenRatio.xs,
    color: AppColors.surface,
    shadowColor: AppColors.shadow,
    surfaceTintColor: AppColors.surfaceVariant,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
    ),
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.all(GoldenRatio.lg),
  );

  // MARK: - Interactive Card Widgets

  /// Create a standard interactive card
  static Widget interactive({
    required Widget child,
    VoidCallback? onTap,
    bool isSelected = false,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? elevation,
  }) {
    return Card(
      elevation: isSelected ? GoldenRatio.sm : GoldenRatio.xs,
      color: isSelected ? AppColors.primaryContainer : AppColors.surface,
      shadowColor: AppColors.shadow,
      surfaceTintColor: isSelected ? AppColors.primary : AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
        side: isSelected 
          ? BorderSide(color: AppColors.primary, width: 2)
          : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      margin: margin ?? EdgeInsets.all(GoldenRatio.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
        child: Padding(
          padding: padding ?? EdgeInsets.all(GoldenRatio.lg),
          child: child,
        ),
      ),
    );
  }

  /// Create a status card with icon and text
  static Widget status({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Color? backgroundColor,
    bool isSelected = false,
  }) {
    return interactive(
      onTap: onTap,
      isSelected: isSelected,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(GoldenRatio.md),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
            ),
            child: Icon(
              icon,
              size: GoldenRatio.iconRegular,
              color: iconColor ?? AppColors.primary,
            ),
          ),
          SizedBox(width: GoldenRatio.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: GoldenRatio.textMd,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: GoldenRatio.xs),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: GoldenRatio.textSm,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            SizedBox(width: GoldenRatio.sm),
            Icon(
              Icons.chevron_right,
              size: GoldenRatio.iconSm,
              color: AppColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  /// Create a metric card with large number and description
  static Widget metric({
    required String value,
    required String label,
    String? subtitle,
    IconData? icon,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return interactive(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: GoldenRatio.iconLarge,
              color: valueColor ?? AppColors.primary,
            ),
            SizedBox(height: GoldenRatio.md),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: GoldenRatio.textHeadline,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.primary,
            ),
          ),
          SizedBox(height: GoldenRatio.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: GoldenRatio.textSm,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: GoldenRatio.xs),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: GoldenRatio.textXs,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Create an image card with overlay text
  static Widget image({
    required String imageUrl,
    required String title,
    String? subtitle,
    double? height,
    VoidCallback? onTap,
    List<Widget>? actions,
  }) {
    final cardHeight = height ?? (GoldenRatio.xl * GoldenRatio.phi);
    
    return Card(
      elevation: GoldenRatio.xs,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.all(GoldenRatio.md),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: cardHeight,
          width: cardHeight * GoldenRatio.phi, // Golden ratio width
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
            padding: EdgeInsets.all(GoldenRatio.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: GoldenRatio.textLg,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: GoldenRatio.xs),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: GoldenRatio.textSm,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
                if (actions != null) ...[
                  SizedBox(height: GoldenRatio.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - Specialized Cards

  /// Create a feature card with icon, title, and description
  static Widget feature({
    required IconData icon,
    required String title,
    required String description,
    VoidCallback? onTap,
    Color? iconColor,
    bool isEnabled = true,
  }) {
    return interactive(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(GoldenRatio.md),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(GoldenRatio.buttonRadius),
              ),
              child: Icon(
                icon,
                size: GoldenRatio.iconLarge,
                color: iconColor ?? AppColors.primary,
              ),
            ),
            SizedBox(height: GoldenRatio.md),
            Text(
              title,
              style: TextStyle(
                fontSize: GoldenRatio.textLg,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: GoldenRatio.sm),
            Text(
              description,
              style: TextStyle(
                fontSize: GoldenRatio.textSm,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Create a summary card with multiple metrics
  static Widget summary({
    required String title,
    required List<MapEntry<String, String>> metrics,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return interactive(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: GoldenRatio.iconRegular,
                  color: AppColors.primary,
                ),
                SizedBox(width: GoldenRatio.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: GoldenRatio.textLg,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: GoldenRatio.md),
          ...metrics.map((metric) => Padding(
            padding: EdgeInsets.only(bottom: GoldenRatio.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  metric.key,
                  style: TextStyle(
                    fontSize: GoldenRatio.textSm,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  metric.value,
                  style: TextStyle(
                    fontSize: GoldenRatio.textSm,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // MARK: - Utility Methods

  /// Get card theme by type
  static CardThemeData getTheme(String type) {
    switch (type.toLowerCase()) {
      case 'elevated': return elevated;
      case 'outlined': return outlined;
      case 'filled': return filled;
      case 'large': return large;
      default: return standard;
    }
  }

  /// Create a card with custom styling
  static Widget custom({
    required Widget child,
    double? elevation,
    Color? color,
    Color? shadowColor,
    Color? surfaceTintColor,
    ShapeBorder? shape,
    EdgeInsets? margin,
    EdgeInsets? padding,
    VoidCallback? onTap,
    bool? clipBehavior,
  }) {
    return Card(
      elevation: elevation ?? GoldenRatio.xs,
      color: color ?? AppColors.surface,
      shadowColor: shadowColor ?? AppColors.shadow,
      surfaceTintColor: surfaceTintColor ?? AppColors.surfaceVariant,
      shape: shape ?? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
      ),
      clipBehavior: clipBehavior == true ? Clip.antiAlias : Clip.none,
      margin: margin ?? EdgeInsets.all(GoldenRatio.md),
      child: onTap != null
        ? InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
            child: Padding(
              padding: padding ?? EdgeInsets.all(GoldenRatio.lg),
              child: child,
            ),
          )
        : Padding(
            padding: padding ?? EdgeInsets.all(GoldenRatio.lg),
            child: child,
          ),
    );
  }
}
