/// Navigation Component Themes
///
/// This file provides comprehensive navigation theming that follows
/// Material Design 3 principles with golden ratio proportions
/// and the app's brand colors.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../golden_ratio_constants.dart';

/// Navigation themes following Material Design 3 and golden ratio principles
class NavigationThemes {
  NavigationThemes._();

  // MARK: - App Bar Themes
  /// Primary app bar theme
  static AppBarTheme get primaryAppBar => AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: GoldenRatio.elevation1,
        centerTitle: true,
        titleSpacing: GoldenRatio.lg,
        toolbarHeight: GoldenRatio.appBarHeight,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: null, // Will use theme colors
        iconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: Colors.grey.shade700,
        ),
        actionsIconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: Colors.grey.shade700,
        ),
        titleTextStyle: TextStyle(
          fontSize: GoldenRatio.textLg,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
          letterSpacing: 0.1,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      );

  /// Colored app bar (with primary color background)
  static AppBarTheme get coloredAppBar => primaryAppBar.copyWith(
        backgroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        foregroundColor: Colors.black87,
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),
        actionsIconTheme: const IconThemeData(
          color: Colors.black87,
        ),
        titleTextStyle: primaryAppBar.titleTextStyle?.copyWith(
          color: Colors.black87,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      );

  /// Elevated app bar with shadow
  static AppBarTheme get elevatedAppBar => primaryAppBar.copyWith(
        elevation: GoldenRatio.elevation2,
        scrolledUnderElevation: GoldenRatio.elevation3,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
      );

  // MARK: - Bottom Navigation Bar Themes
  /// Primary bottom navigation theme
  static BottomNavigationBarThemeData get primaryBottomNav =>
      BottomNavigationBarThemeData(
        elevation: GoldenRatio.elevation2,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey.shade600,
        selectedIconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: AppColors.primary,
        ),
        unselectedIconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: Colors.grey.shade600,
        ),
        selectedLabelStyle: TextStyle(
          fontSize: GoldenRatio.textXs,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: GoldenRatio.textXs,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
        ),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  /// Material 3 Navigation Bar (newer style)
  static NavigationBarThemeData get materialNavigationBar =>
      NavigationBarThemeData(
        elevation: GoldenRatio.elevation1,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.05),
        height: GoldenRatio.bottomNavHeight,
        iconTheme: MaterialStateProperty.resolveWith<IconThemeData?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return IconThemeData(
                size: GoldenRatio.iconRegular,
                color: AppColors.primary,
              );
            }
            return IconThemeData(
              size: GoldenRatio.iconRegular,
              color: Colors.grey.shade600,
            );
          },
        ),
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return TextStyle(
                fontSize: GoldenRatio.textXs,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              );
            }
            return TextStyle(
              fontSize: GoldenRatio.textXs,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            );
          },
        ),
        indicatorColor: AppColors.primary.withOpacity(0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        ),
      );

  // MARK: - Navigation Drawer Themes
  /// Primary navigation drawer theme
  static DrawerThemeData get primaryDrawer => DrawerThemeData(
        elevation: GoldenRatio.elevation4,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        width: GoldenRatio.drawerWidth,
      );

  /// Drawer header widget
  static Widget drawerHeader({
    String? title,
    String? subtitle,
    ImageProvider? backgroundImage,
    Widget? accountInfo,
    Color? backgroundColor,
  }) {
    return Container(
      height: GoldenRatio.appBarHeight * 2.5,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary,
        image: backgroundImage != null
            ? DecorationImage(
                image: backgroundImage,
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GoldenRatio.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (accountInfo != null)
                accountInfo
              else if (title != null || subtitle != null) ...[
                if (title != null)
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: GoldenRatio.textLg,
                      fontWeight: FontWeight.bold,
                      color: backgroundImage != null
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: GoldenRatio.sm),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: GoldenRatio.textSm,
                      color: backgroundImage != null
                          ? Colors.white.withOpacity(0.9)
                          : Colors.black.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Drawer list tile theme
  static ListTileThemeData get drawerListTile => ListTileThemeData(
        contentPadding: const EdgeInsets.all(GoldenRatio.md),
        minVerticalPadding: GoldenRatio.sm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
        ),
        titleTextStyle: TextStyle(
          fontSize: GoldenRatio.textMd,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: GoldenRatio.textSm,
          color: Colors.grey.shade600,
        ),
        leadingAndTrailingTextStyle: TextStyle(
          fontSize: GoldenRatio.textXs,
          color: Colors.grey.shade600,
        ),
        iconColor: Colors.grey.shade600,
        selectedColor: AppColors.primary,
        selectedTileColor: AppColors.primary.withOpacity(0.08),
      );

  // MARK: - Tab Bar Themes
  /// Primary tab bar theme
  static TabBarTheme get primaryTabBar => TabBarTheme(
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: TextStyle(
          fontSize: GoldenRatio.textSm,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: GoldenRatio.textSm,
          fontWeight: FontWeight.w500,
        ),
        overlayColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.hovered)) {
              return AppColors.primary.withOpacity(0.04);
            }
            if (states.contains(MaterialState.pressed)) {
              return AppColors.primary.withOpacity(0.12);
            }
            return null;
          },
        ),
      );

  /// Pill-style tab bar (rounded tabs)
  static Widget pillTabBar({
    required List<String> tabs,
    required int selectedIndex,
    required ValueChanged<int> onTabChanged,
    Color? selectedColor,
    Color? unselectedColor,
  }) {
    return Container(
      height: GoldenRatio.buttonHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final int index = entry.key;
          final String tab = entry.value;
          final bool isSelected = index == selectedIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(index),
              child: Container(
                margin: EdgeInsets.all(GoldenRatio.xs),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (selectedColor ?? AppColors.primary)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontSize: GoldenRatio.textSm,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.black87
                          : (unselectedColor ?? Colors.grey.shade600),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // MARK: - Breadcrumb Navigation
  /// Breadcrumb navigation widget
  static Widget breadcrumb({
    required List<String> items,
    ValueChanged<int>? onItemTapped,
    Color? textColor,
    Color? separatorColor,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.asMap().entries.expand((entry) {
          final int index = entry.key;
          final String item = entry.value;
          final bool isLast = index == items.length - 1;

          return [
            GestureDetector(
              onTap: onItemTapped != null ? () => onItemTapped(index) : null,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: GoldenRatio.textSm,
                  fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
                  color: isLast
                      ? (textColor ?? Colors.grey.shade800)
                      : (textColor ?? AppColors.primary),
                  decoration: !isLast && onItemTapped != null
                      ? TextDecoration.underline
                      : null,
                ),
              ),
            ),
            if (!isLast) ...[
              const SizedBox(width: GoldenRatio.sm),
              Icon(
                Icons.chevron_right,
                size: GoldenRatio.iconSm,
                color: separatorColor ?? Colors.grey.shade500,
              ),
              const SizedBox(width: GoldenRatio.sm),
            ],
          ];
        }).toList(),
      ),
    );
  }

  // MARK: - Custom Navigation Components
  /// Floating navigation bar
  static Widget floatingNavigationBar({
    required List<NavigationItem> items,
    required int selectedIndex,
    required ValueChanged<int> onItemSelected,
    Color? backgroundColor,
    Color? selectedColor,
    double? elevation,
  }) {
    return Container(
      margin: const EdgeInsets.all(GoldenRatio.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: elevation ?? GoldenRatio.elevation3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(GoldenRatio.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: items.asMap().entries.map((entry) {
            final int index = entry.key;
            final NavigationItem item = entry.value;
            final bool isSelected = index == selectedIndex;

            return GestureDetector(
              onTap: () => onItemSelected(index),
              child: Container(
                padding: const EdgeInsets.all(GoldenRatio.md),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (selectedColor ?? AppColors.primary).withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: GoldenRatio.iconRegular,
                      color: isSelected
                          ? (selectedColor ?? AppColors.primary)
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(height: GoldenRatio.xs),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: GoldenRatio.textXs,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? (selectedColor ?? AppColors.primary)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Navigation item model
class NavigationItem {
  final IconData icon;
  final String label;
  final String? route;
  final Widget? badge;

  const NavigationItem({
    required this.icon,
    required this.label,
    this.route,
    this.badge,
  });
}
