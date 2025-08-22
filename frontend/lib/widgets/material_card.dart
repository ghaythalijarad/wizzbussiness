// Material Card Component - Enhanced Material You card with gradients
// Provides consistent card styling with elevation, gradients, and surface tints

import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';
import '../theme/theme_config.dart';

enum CardElevation {
  none,
  low,
  medium,
  high,
}

enum CardSurface {
  standard,
  elevated,
  filled,
  outlined,
}

enum CardGradient {
  none,
  subtle,
  primary,
  secondary,
  primaryToSecondary,
}

class MaterialCard extends StatelessWidget {
  const MaterialCard({
    super.key,
    required this.child,
    this.elevation = CardElevation.low,
    this.surface = CardSurface.standard,
    this.gradient = CardGradient.none,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
    this.semanticLabel,
  });

  final Widget child;
  final CardElevation elevation;
  final CardSurface surface;
  final CardGradient gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Clip clipBehavior;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cardBorderRadius =
        borderRadius ?? BorderRadius.circular(AppBorderRadius.md);
    final cardPadding = padding ?? const EdgeInsets.all(AppSpacing.md);
    final cardMargin = margin ?? const EdgeInsets.all(AppSpacing.sm);

    Widget cardContent = Container(
      width: width,
      height: height,
      padding: cardPadding,
      decoration: _getDecoration(context, colorScheme, cardBorderRadius),
      child: child,
    );

    // Wrap with gesture detector if onTap is provided
    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: cardBorderRadius,
        child: cardContent,
      );
    }

    // Wrap with semantic label if provided
    if (semanticLabel != null) {
      cardContent = Semantics(
        label: semanticLabel,
        child: cardContent,
      );
    }

    return Container(
      margin: cardMargin,
      child: Material(
        elevation: _getElevationValue(),
        borderRadius: cardBorderRadius,
        clipBehavior: clipBehavior,
        surfaceTintColor: _getSurfaceTintColor(colorScheme),
        shadowColor: _getShadowColor(colorScheme),
        child: cardContent,
      ),
    );
  }

  Decoration _getDecoration(BuildContext context, ColorScheme colorScheme,
      BorderRadius borderRadius) {
    Color? backgroundColor;
    Border? border;
    Gradient? backgroundGradient;

    // Determine base color based on surface type
    switch (surface) {
      case CardSurface.standard:
        backgroundColor = colorScheme.surface;
        break;
      case CardSurface.elevated:
        backgroundColor = colorScheme.surfaceContainerHighest;
        break;
      case CardSurface.filled:
        backgroundColor = colorScheme.surfaceContainerHighest;
        break;
      case CardSurface.outlined:
        backgroundColor = colorScheme.surface;
        border = Border.all(color: colorScheme.outline);
        break;
    }

    // Apply gradient if specified
    switch (gradient) {
      case CardGradient.none:
        break;
      case CardGradient.subtle:
        backgroundGradient = LinearGradient(
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        backgroundColor = null;
        break;
      case CardGradient.primary:
        backgroundGradient = context.primaryGradient;
        backgroundColor = null;
        break;
      case CardGradient.secondary:
        backgroundGradient = context.secondaryGradient;
        backgroundColor = null;
        break;
      case CardGradient.primaryToSecondary:
        backgroundGradient = context.primaryToSecondaryGradient;
        backgroundColor = null;
        break;
    }

    return BoxDecoration(
      color: backgroundColor,
      gradient: backgroundGradient,
      border: border,
      borderRadius: borderRadius,
    );
  }

  double _getElevationValue() {
    switch (elevation) {
      case CardElevation.none:
        return AppElevation.level0;
      case CardElevation.low:
        return AppElevation.level1;
      case CardElevation.medium:
        return AppElevation.level3;
      case CardElevation.high:
        return AppElevation.level5;
    }
  }

  Color? _getSurfaceTintColor(ColorScheme colorScheme) {
    if (gradient != CardGradient.none) return null;
    return colorScheme.surfaceTint;
  }

  Color _getShadowColor(ColorScheme colorScheme) {
    return colorScheme.shadow;
  }

  /// Factory constructors for common card types
  factory MaterialCard.elevated({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    return MaterialCard(
      elevation: CardElevation.medium,
      surface: CardSurface.elevated,
      padding: padding,
      margin: margin,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: child,
    );
  }

  factory MaterialCard.filled({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    return MaterialCard(
      elevation: CardElevation.none,
      surface: CardSurface.filled,
      padding: padding,
      margin: margin,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: child,
    );
  }

  factory MaterialCard.outlined({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    return MaterialCard(
      elevation: CardElevation.none,
      surface: CardSurface.outlined,
      padding: padding,
      margin: margin,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: child,
    );
  }

  factory MaterialCard.gradient({
    required Widget child,
    CardGradient gradient = CardGradient.primaryToSecondary,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    return MaterialCard(
      elevation: CardElevation.medium,
      surface: CardSurface.standard,
      gradient: gradient,
      padding: padding,
      margin: margin,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}
