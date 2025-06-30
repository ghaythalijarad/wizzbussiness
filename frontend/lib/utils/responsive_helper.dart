import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  static int getGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  static double getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) return screenWidth - 32;
    if (isTablet(context)) return (screenWidth - 72) / 2;
    return (screenWidth - 128) / 3;
  }

  // Enhanced responsive helpers for better UI adaptation
  static double getSidebarWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) return screenWidth * 0.85;
    if (isTablet(context)) return screenWidth * 0.6;
    return 400; // Fixed width for desktop
  }

  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    if (isMobile(context)) return baseSize;
    if (isTablet(context)) return baseSize * 1.1;
    return baseSize * 1.2;
  }

  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    if (isMobile(context)) return baseSize;
    if (isTablet(context)) return baseSize * 1.1;
    return baseSize * 1.2;
  }

  static EdgeInsets getResponsiveMargin(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(16);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(32);
  }

  static bool shouldUseCompactLayout(BuildContext context) {
    return isMobile(context) ||
        (isTablet(context) &&
            MediaQuery.of(context).orientation == Orientation.portrait);
  }

  static int getResponsiveItemsPerRow(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) {
      return MediaQuery.of(context).orientation == Orientation.portrait ? 2 : 3;
    }
    return 4;
  }

  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) return screenWidth * 0.9;
    if (isTablet(context)) return 500;
    return 600;
  }

  static double getMaxDialogHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.8;
  }
}
