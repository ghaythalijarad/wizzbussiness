/// Navigation Themes System
///
/// This file provides comprehensive navigation theming that follows
/// Material Design 3 principles with golden ratio proportions
/// and consistent styling throughout the application.

import 'package:flutter/material.dart';
import '../golden_ratio_constants.dart';
import '../../theme/app_colors.dart';

/// Navigation Themes class providing Material Design 3 navigation styles
class NavigationThemes {
  NavigationThemes._();

  // MARK: - App Bar Themes

  /// Standard app bar theme
  static AppBarTheme get standard => AppBarTheme(
        centerTitle: true,
        elevation: GoldenRatio.elevation1,
        scrolledUnderElevation: GoldenRatio.elevation1,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        surfaceTintColor: AppColors.primary,
        toolbarHeight: GoldenRatio.appBarHeight,
        titleTextStyle: TextStyle(
          fontSize: GoldenRatio.textXl,
          fontWeight: FontWeight.w600,
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
      );

  /// Large app bar theme
  static AppBarTheme get large => AppBarTheme(
        centerTitle: false,
        elevation: GoldenRatio.elevation1,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        surfaceTintColor: AppColors.primary,
        scrolledUnderElevation: GoldenRatio.elevation2,
        toolbarHeight: GoldenRatio.appBarHeight * 1.5,
        titleTextStyle: TextStyle(
          fontSize: GoldenRatio.textTitle,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimary,
        ),
        iconTheme: IconThemeData(
          size: GoldenRatio.iconLarge,
          color: AppColors.onPrimary,
        ),
        actionsIconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: AppColors.onPrimary,
        ),
      );

  /// Surface app bar theme (for secondary pages)
  static AppBarTheme get surface => AppBarTheme(
        centerTitle: true,
        elevation: GoldenRatio.elevation1,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        surfaceTintColor: AppColors.surfaceVariant,
        scrolledUnderElevation: GoldenRatio.elevation1,
        toolbarHeight: GoldenRatio.appBarHeight,
        titleTextStyle: TextStyle(
          fontSize: GoldenRatio.textXl,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        iconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: AppColors.onSurface,
        ),
        actionsIconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: AppColors.onSurface,
        ),
      );

  // MARK: - Bottom Navigation Bar Themes

  /// Standard bottom navigation bar theme
  static BottomNavigationBarThemeData get bottomNavigation =>
      BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        elevation: GoldenRatio.elevation1,
        selectedIconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: AppColors.primary,
        ),
        unselectedIconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: AppColors.onSurfaceVariant,
        ),
        selectedLabelStyle: TextStyle(
          fontSize: GoldenRatio.textXs,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: GoldenRatio.textXs,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  // MARK: - Navigation Rail Theme

  /// Standard navigation rail theme
  static NavigationRailThemeData get navigationRail => NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        elevation: GoldenRatio.elevation1,
        indicatorColor: AppColors.primaryContainer,
        selectedIconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: AppColors.primary,
        ),
        unselectedIconTheme: IconThemeData(
          size: GoldenRatio.iconRegular,
          color: AppColors.onSurfaceVariant,
        ),
        selectedLabelTextStyle: TextStyle(
          fontSize: GoldenRatio.textXs,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: GoldenRatio.textXs,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        useIndicator: true,
        minWidth: GoldenRatio.navRailWidth,
        minExtendedWidth: GoldenRatio.navRailWidth * 2,
      );

  // MARK: - Custom Navigation Widgets

  /// Create a custom navigation bar with golden ratio proportions
  static Widget customBottomBar({
    required List<NavigationItem> items,
    required int currentIndex,
    required ValueChanged<int> onTap,
    Color? backgroundColor,
    double? elevation,
  }) {
    return Container(
      height: GoldenRatio.bottomNavHeight,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        boxShadow: elevation != null
            ? [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: elevation,
                  offset: Offset(0, -elevation / 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == currentIndex;

          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              child: Container(
                height: double.infinity,
                padding: EdgeInsets.symmetric(vertical: GoldenRatio.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      size: GoldenRatio.iconRegular,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                    SizedBox(height: GoldenRatio.xs),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: GoldenRatio.textXs,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Create a custom app bar with actions
  static PreferredSizeWidget customAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
  }) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: GoldenRatio.textXl,
          fontWeight: FontWeight.w600,
          color: foregroundColor ?? AppColors.onPrimary,
        ),
      ),
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? AppColors.onPrimary,
      elevation: elevation ?? GoldenRatio.elevation1,
      scrolledUnderElevation: GoldenRatio.elevation1,
      toolbarHeight: GoldenRatio.appBarHeight,
      iconTheme: IconThemeData(
        size: GoldenRatio.iconRegular,
        color: foregroundColor ?? AppColors.onPrimary,
      ),
      actionsIconTheme: IconThemeData(
        size: GoldenRatio.iconRegular,
        color: foregroundColor ?? AppColors.onPrimary,
      ),
    );
  }

  // MARK: - Tab Bar Themes

  /// Standard tab bar theme
  static TabBarTheme get tabBar => TabBarTheme(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        labelStyle: TextStyle(
          fontSize: GoldenRatio.textSm,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: GoldenRatio.textSm,
          fontWeight: FontWeight.w400,
        ),
        indicator: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
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

  /// Create a custom tab bar with golden ratio spacing
  static Widget customTabBar({
    required List<String> tabs,
    required TabController controller,
    Color? indicatorColor,
    Color? labelColor,
    Color? unselectedLabelColor,
  }) {
    return Container(
      height: GoldenRatio.buttonHeight,
      margin: EdgeInsets.symmetric(horizontal: GoldenRatio.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
      ),
      child: TabBar(
        controller: controller,
        tabs: tabs
            .map((tab) => Tab(
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontSize: GoldenRatio.textSm,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
            .toList(),
        labelColor: labelColor ?? AppColors.primary,
        unselectedLabelColor:
            unselectedLabelColor ?? AppColors.onSurfaceVariant,
        indicator: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: GoldenRatio.elevation3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.all(GoldenRatio.xs),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
      ),
    );
  }

  // MARK: - Drawer Themes

  /// Create a custom drawer with proper theming
  static Widget customDrawer({
    Widget? header,
    required List<NavigationItem> items,
    int? selectedIndex,
    required ValueChanged<int> onItemTap,
    List<Widget>? footerItems,
  }) {
    return Drawer(
      width: GoldenRatio.drawerWidth,
      backgroundColor: AppColors.surface,
      elevation: GoldenRatio.elevation1,
      shape: const RoundedRectangleBorder(),
      child: Column(
        children: [
          if (header != null) header,
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: GoldenRatio.md),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == selectedIndex;

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: GoldenRatio.md),
                  child: ListTile(
                    leading: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      size: GoldenRatio.iconRegular,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: GoldenRatio.textSm,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurface,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    selectedTileColor: AppColors.primary.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                    ),
                    onTap: () => onItemTap(index),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: GoldenRatio.md, vertical: GoldenRatio.sm),
                  ),
                );
              },
            ),
          ),
          if (footerItems != null) ...footerItems,
        ],
      ),
    );
  }

  // MARK: - Breadcrumb Navigation

  /// Create a breadcrumb navigation widget
  static Widget breadcrumb({
    required List<BreadcrumbItem> items,
    Color? textColor,
    Color? separatorColor,
    double? fontSize,
  }) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) ...[
            SizedBox(width: GoldenRatio.sm),
            Icon(
              Icons.chevron_right,
              size: fontSize ?? GoldenRatio.textSm,
              color: separatorColor ?? AppColors.onSurfaceVariant,
            ),
            SizedBox(width: GoldenRatio.sm),
          ],
          GestureDetector(
            onTap: items[i].onTap,
            child: Text(
              items[i].label,
              style: TextStyle(
                fontSize: fontSize ?? GoldenRatio.textSm,
                fontWeight:
                    i == items.length - 1 ? FontWeight.w500 : FontWeight.w400,
                color: i == items.length - 1
                    ? (textColor ?? AppColors.onSurface)
                    : AppColors.onSurfaceVariant,
                decoration: items[i].onTap != null && i < items.length - 1
                    ? TextDecoration.underline
                    : null,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // MARK: - Utility Methods

  /// Get app bar theme by type
  static AppBarTheme getAppBarTheme(String type) {
    switch (type.toLowerCase()) {
      case 'large':
        return large;
      case 'surface':
        return surface;
      default:
        return standard;
    }
  }
}

/// Navigation item data class
class NavigationItem {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final VoidCallback? onTap;

  const NavigationItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.onTap,
  });
}

/// Breadcrumb item data class
class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({
    required this.label,
    this.onTap,
  });
}
