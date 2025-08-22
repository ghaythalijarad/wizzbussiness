// Themed App Bar Component - Material You app bar with gradients
// Provides consistent app bar styling across the application

import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';
import '../theme/theme_config.dart';
import 'gradient_container.dart';

enum AppBarVariant {
  standard,
  gradient,
  glass,
  elevated,
}

class ThemedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ThemedAppBar({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.actions,
    this.variant = AppBarVariant.standard,
    this.showBackButton = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
    this.gradient,
    this.height,
  }) : assert(title != null || titleText != null,
            'Either title or titleText must be provided');

  final Widget? title;
  final String? titleText;
  final Widget? leading;
  final List<Widget>? actions;
  final AppBarVariant variant;
  final bool showBackButton;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool centerTitle;
  final GradientVariant? gradient;
  final double? height;

  @override
  Size get preferredSize => Size.fromHeight(height ?? kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final theme = Theme.of(context);

    final effectiveTitle = title ??
        Text(
          titleText!,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: foregroundColor ?? colorScheme.onSurface,
          ),
        );

    final effectiveLeading = leading ??
        (showBackButton && Navigator.canPop(context)
            ? _buildBackButton(context)
            : null);

    switch (variant) {
      case AppBarVariant.standard:
        return _buildStandardAppBar(context, effectiveTitle, effectiveLeading);
      case AppBarVariant.gradient:
        return _buildGradientAppBar(context, effectiveTitle, effectiveLeading);
      case AppBarVariant.glass:
        return _buildGlassAppBar(context, effectiveTitle, effectiveLeading);
      case AppBarVariant.elevated:
        return _buildElevatedAppBar(context, effectiveTitle, effectiveLeading);
    }
  }

  Widget _buildStandardAppBar(
      BuildContext context, Widget title, Widget? leading) {
    final colorScheme = context.colorScheme;

    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: elevation ?? AppElevation.level0,
      centerTitle: centerTitle,
      scrolledUnderElevation: AppElevation.level2,
    );
  }

  Widget _buildGradientAppBar(
      BuildContext context, Widget title, Widget? leading) {
    final colorScheme = context.colorScheme;
    final effectiveGradient = gradient ?? GradientVariant.primaryToSecondary;

    return PreferredSize(
      preferredSize: preferredSize,
      child: GradientContainer(
        gradient: effectiveGradient,
        height: preferredSize.height,
        child: SafeArea(
          child: Container(
            height: preferredSize.height,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading,
                  SizedBox(width: AppSpacing.sm),
                ],
                if (centerTitle)
                  Expanded(child: Center(child: title))
                else
                  Expanded(child: title),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassAppBar(
      BuildContext context, Widget title, Widget? leading) {
    final colorScheme = context.colorScheme;

    return PreferredSize(
      preferredSize: preferredSize,
      child: Container(
        height: preferredSize.height + MediaQuery.of(context).padding.top,
        decoration: BoxDecoration(
          color: colorScheme.surface.withOpacity(0.85),
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: const ColorFilter.matrix(<double>[
              1,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: SafeArea(
              child: Container(
                height: preferredSize.height,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading,
                      SizedBox(width: AppSpacing.sm),
                    ],
                    if (centerTitle)
                      Expanded(child: Center(child: title))
                    else
                      Expanded(child: title),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElevatedAppBar(
      BuildContext context, Widget title, Widget? leading) {
    final colorScheme = context.colorScheme;

    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor ?? colorScheme.surfaceContainerHighest,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: elevation ?? AppElevation.level3,
      centerTitle: centerTitle,
      shadowColor: colorScheme.shadow,
      surfaceTintColor: colorScheme.surfaceTint,
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final colorScheme = context.colorScheme;

    return IconButton(
      icon: Icon(
        Icons.arrow_back_ios_new,
        color: foregroundColor ?? colorScheme.onSurface,
      ),
      onPressed: () => Navigator.pop(context),
      tooltip: 'Back',
    );
  }

  /// Factory constructors for common app bar types
  factory ThemedAppBar.gradient({
    String? titleText,
    Widget? title,
    Widget? leading,
    List<Widget>? actions,
    GradientVariant gradient = GradientVariant.primaryToSecondary,
    bool centerTitle = true,
    double? height,
  }) {
    return ThemedAppBar(
      titleText: titleText,
      title: title,
      leading: leading,
      actions: actions,
      variant: AppBarVariant.gradient,
      gradient: gradient,
      centerTitle: centerTitle,
      height: height,
    );
  }

  factory ThemedAppBar.glass({
    String? titleText,
    Widget? title,
    List<Widget>? actions,
    bool centerTitle = true,
    double? height,
  }) {
    return ThemedAppBar(
      titleText: titleText,
      title: title,
      actions: actions,
      variant: AppBarVariant.glass,
      centerTitle: centerTitle,
      height: height,
    );
  }

  factory ThemedAppBar.elevated({
    String? titleText,
    Widget? title,
    List<Widget>? actions,
    bool centerTitle = true,
    double? height,
    double? elevation,
  }) {
    return ThemedAppBar(
      titleText: titleText,
      title: title,
      actions: actions,
      variant: AppBarVariant.elevated,
      centerTitle: centerTitle,
      height: height,
      elevation: elevation,
    );
  }
}
