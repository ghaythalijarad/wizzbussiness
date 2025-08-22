// Gradient Container Component - Material You gradient backgrounds
// Provides consistent gradient containers with theme integration

import 'package:flutter/material.dart';

enum GradientVariant {
  primary,
  secondary,
  primaryToSecondary,
  surface,
  status,
}

class GradientContainer extends StatelessWidget {
  const GradientContainer({
    super.key,
    required this.child,
    this.gradient = GradientVariant.primaryToSecondary,
    this.opacity = 1.0,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.customGradient,
  });

  final Widget child;
  final GradientVariant gradient;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final Gradient? customGradient;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = customGradient ?? _getThemeGradient(context);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);

    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        gradient: _applyOpacity(effectiveGradient),
        borderRadius: effectiveBorderRadius,
      ),
      child: child,
    );
  }

  Gradient _getThemeGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (gradient) {
      case GradientVariant.primary:
        return LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary],
        );
      case GradientVariant.secondary:
        return LinearGradient(
          colors: [colorScheme.secondary, colorScheme.secondary],
        );
      case GradientVariant.primaryToSecondary:
        return LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GradientVariant.surface:
        return LinearGradient(
          colors: [colorScheme.surface, colorScheme.surfaceVariant],
        );
      case GradientVariant.status:
        return LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
        );
    }
  }

  Gradient _applyOpacity(Gradient gradient) {
    if (opacity == 1.0) return gradient;

    if (gradient is LinearGradient) {
      return LinearGradient(
        begin: gradient.begin,
        end: gradient.end,
        colors:
            gradient.colors.map((color) => color.withOpacity(opacity)).toList(),
        stops: gradient.stops,
        tileMode: gradient.tileMode,
        transform: gradient.transform,
      );
    } else if (gradient is RadialGradient) {
      return RadialGradient(
        center: gradient.center,
        radius: gradient.radius,
        colors:
            gradient.colors.map((color) => color.withOpacity(opacity)).toList(),
        stops: gradient.stops,
        tileMode: gradient.tileMode,
        focal: gradient.focal,
        focalRadius: gradient.focalRadius,
        transform: gradient.transform,
      );
    } else if (gradient is SweepGradient) {
      return SweepGradient(
        center: gradient.center,
        startAngle: gradient.startAngle,
        endAngle: gradient.endAngle,
        colors:
            gradient.colors.map((color) => color.withOpacity(opacity)).toList(),
        stops: gradient.stops,
        tileMode: gradient.tileMode,
        transform: gradient.transform,
      );
    }

    return gradient;
  }

  /// Factory constructors for common gradient types
  factory GradientContainer.primary({
    required Widget child,
    double opacity = 1.0,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    AlignmentGeometry? alignment,
  }) {
    return GradientContainer(
      gradient: GradientVariant.primary,
      opacity: opacity,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      alignment: alignment,
      child: child,
    );
  }

  factory GradientContainer.secondary({
    required Widget child,
    double opacity = 1.0,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    AlignmentGeometry? alignment,
  }) {
    return GradientContainer(
      gradient: GradientVariant.secondary,
      opacity: opacity,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      alignment: alignment,
      child: child,
    );
  }

  factory GradientContainer.hero({
    required Widget child,
    double opacity = 0.85,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    AlignmentGeometry? alignment,
  }) {
    return GradientContainer(
      gradient: GradientVariant.primaryToSecondary,
      opacity: opacity,
      borderRadius: BorderRadius.circular(28),
      padding: padding ?? const EdgeInsets.all(32),
      margin: margin,
      width: width,
      height: height,
      alignment: alignment,
      child: child,
    );
  }

  factory GradientContainer.surface({
    required Widget child,
    double opacity = 0.5,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    AlignmentGeometry? alignment,
  }) {
    return GradientContainer(
      gradient: GradientVariant.surface,
      opacity: opacity,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      alignment: alignment,
      child: child,
    );
  }
}
