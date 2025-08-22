import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';
import '../widgets/unified_status_toggle.dart';
import '../l10n/app_localizations.dart';

/// Manages responsive layout and optimal toggle placement
class ResponsiveLayoutManager {
  
  /// Determines the optimal toggle placement strategy for current screen
  static TogglePlacementStrategy getOptimalPlacementStrategy(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;
    
    if (ResponsiveHelper.isMobile(context)) {
      // Mobile: Always show in both AppBar and sidebar for accessibility
      return TogglePlacementStrategy.dualMobile;
    } else if (ResponsiveHelper.isTablet(context)) {
      if (orientation == Orientation.portrait) {
        // Tablet portrait: AppBar + NavigationRail
        return TogglePlacementStrategy.dualTabletPortrait;
      } else {
        // Tablet landscape: NavigationRail only (more space)
        return TogglePlacementStrategy.singleTabletLandscape;
      }
    } else {
      // Desktop: Sidebar primary, optional AppBar for quick access
      return screenWidth > 1400 
          ? TogglePlacementStrategy.dualDesktopWide
          : TogglePlacementStrategy.singleDesktop;
    }
  }

  /// Creates optimally configured toggle for specific placement
  static Widget createOptimalToggle({
    required BuildContext context,
    required bool isOnline,
    required bool isToggling,
    required Future<void> Function(bool) onToggle,
    required TogglePlacement placement,
    Color? activeColor,
    Color? inactiveColor,
  }) {
    final config = _getToggleConfig(context, placement);
    
    return UnifiedStatusToggle(
      isOnline: isOnline,
      isToggling: isToggling,
      onToggle: onToggle,
      variant: config.variant,
      size: config.size,
      showLabel: config.showLabel,
      showIcon: config.showIcon,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
    );
  }

  /// Gets optimal configuration for specific placement
  static ToggleConfig _getToggleConfig(BuildContext context, TogglePlacement placement) {
    switch (placement) {
      case TogglePlacement.appBarMobile:
        return const ToggleConfig(
          variant: StatusToggleVariant.iconButton,
          size: StatusToggleSize.medium,
          showLabel: false,
          showIcon: true,
        );
      
      case TogglePlacement.appBarTablet:
        return const ToggleConfig(
          variant: StatusToggleVariant.chip,
          size: StatusToggleSize.medium,
          showLabel: true,
          showIcon: true,
        );
      
      case TogglePlacement.appBarDesktop:
        return const ToggleConfig(
          variant: StatusToggleVariant.chip,
          size: StatusToggleSize.large,
          showLabel: true,
          showIcon: true,
        );
      
      case TogglePlacement.sidebarMobile:
        return const ToggleConfig(
          variant: StatusToggleVariant.toggle,
          size: StatusToggleSize.medium,
          showLabel: true,
          showIcon: false,
        );
      
      case TogglePlacement.navigationRailTablet:
        return const ToggleConfig(
          variant: StatusToggleVariant.card,
          size: StatusToggleSize.medium,
          showLabel: true,
          showIcon: true,
        );
      
      case TogglePlacement.sidebarDesktop:
        return const ToggleConfig(
          variant: StatusToggleVariant.card,
          size: StatusToggleSize.large,
          showLabel: true,
          showIcon: true,
        );
      
      case TogglePlacement.floatingAction:
        return const ToggleConfig(
          variant: StatusToggleVariant.button,
          size: StatusToggleSize.large,
          showLabel: true,
          showIcon: true,
        );
    }
  }

  /// Creates responsive AppBar with optimal toggle placement
  static PreferredSizeWidget createResponsiveAppBar({
    required BuildContext context,
    required String title,
    required bool isOnline,
    required bool isToggling,
    required Future<void> Function(bool) onToggle,
    List<Widget>? additionalActions,
    Widget? leading,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final strategy = getOptimalPlacementStrategy(context);
    final shouldShowToggle = strategy.showInAppBar;
    final placement = ResponsiveHelper.isMobile(context)
        ? TogglePlacement.appBarMobile
        : ResponsiveHelper.isTablet(context)
            ? TogglePlacement.appBarTablet
            : TogglePlacement.appBarDesktop;

    final actions = <Widget>[
      if (shouldShowToggle) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: createOptimalToggle(
            context: context,
            isOnline: isOnline,
            isToggling: isToggling,
            onToggle: onToggle,
            placement: placement,
          ),
        ),
      ],
      ...?additionalActions,
    ];

    if (ResponsiveHelper.isMobile(context)) {
      return AppBar(
        title: Text(title),
        leading: leading,
        actions: actions,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 1,
      );
    } else if (ResponsiveHelper.isTablet(context)) {
      return AppBar(
        title: Row(
          children: [
            if (shouldShowToggle) ...[
              createOptimalToggle(
                context: context,
                isOnline: isOnline,
                isToggling: isToggling,
                onToggle: onToggle,
                placement: placement,
              ),
              const SizedBox(width: 16),
            ],
            Text(title),
          ],
        ),
        leading: leading,
        actions: additionalActions,
        backgroundColor: backgroundColor ?? Colors.white,
        foregroundColor: foregroundColor ?? Colors.black87,
        elevation: 0,
      );
    } else {
      // Desktop
      return AppBar(
        title: Row(
          children: [
            Icon(Icons.store, size: 24),
            const SizedBox(width: 12),
            Text(title),
            const Spacer(),
            if (shouldShowToggle) ...[
              createOptimalToggle(
                context: context,
                isOnline: isOnline,
                isToggling: isToggling,
                onToggle: onToggle,
                placement: placement,
              ),
            ],
          ],
        ),
        leading: leading,
        actions: additionalActions,
        backgroundColor: backgroundColor ?? Colors.white,
        foregroundColor: foregroundColor ?? Colors.black87,
        elevation: 0,
      );
    }
  }

  /// Creates responsive navigation component with optimal toggle placement
  static Widget createResponsiveNavigation({
    required BuildContext context,
    required int selectedIndex,
    required Function(int) onNavigate,
    required bool isOnline,
    required bool isToggling,
    required Future<void> Function(bool) onToggle,
    required List<NavigationDestination> destinations,
    VoidCallback? onReturnOrder,
  }) {
    final strategy = getOptimalPlacementStrategy(context);

    if (ResponsiveHelper.isMobile(context)) {
      // Mobile: Bottom navigation + sidebar
      return _MobileNavigation(
        selectedIndex: selectedIndex,
        onNavigate: onNavigate,
        isOnline: isOnline,
        isToggling: isToggling,
        onToggle: onToggle,
        destinations: destinations,
        onReturnOrder: onReturnOrder,
        showToggleInSidebar: strategy.showInSidebar,
      );
    } else if (ResponsiveHelper.isTablet(context)) {
      // Tablet: Navigation rail
      return _TabletNavigationRail(
        selectedIndex: selectedIndex,
        onNavigate: onNavigate,
        isOnline: isOnline,
        isToggling: isToggling,
        onToggle: onToggle,
        destinations: destinations,
        showToggle: strategy.showInNavigationRail,
      );
    } else {
      // Desktop: Sidebar
      return _DesktopSidebar(
        selectedIndex: selectedIndex,
        onNavigate: onNavigate,
        isOnline: isOnline,
        isToggling: isToggling,
        onToggle: onToggle,
        destinations: destinations,
        onReturnOrder: onReturnOrder,
        showToggle: strategy.showInSidebar,
      );
    }
  }
}

/// Placement strategies for different screen configurations
enum TogglePlacementStrategy {
  dualMobile,              // AppBar + Sidebar
  dualTabletPortrait,      // AppBar + NavigationRail
  singleTabletLandscape,   // NavigationRail only
  singleDesktop,           // Sidebar only
  dualDesktopWide,         // AppBar + Sidebar
}

extension TogglePlacementStrategyExtension on TogglePlacementStrategy {
  bool get showInAppBar {
    switch (this) {
      case TogglePlacementStrategy.dualMobile:
      case TogglePlacementStrategy.dualTabletPortrait:
      case TogglePlacementStrategy.dualDesktopWide:
        return true;
      case TogglePlacementStrategy.singleTabletLandscape:
      case TogglePlacementStrategy.singleDesktop:
        return false;
    }
  }

  bool get showInSidebar {
    switch (this) {
      case TogglePlacementStrategy.dualMobile:
      case TogglePlacementStrategy.singleDesktop:
      case TogglePlacementStrategy.dualDesktopWide:
        return true;
      case TogglePlacementStrategy.dualTabletPortrait:
      case TogglePlacementStrategy.singleTabletLandscape:
        return false;
    }
  }

  bool get showInNavigationRail {
    switch (this) {
      case TogglePlacementStrategy.dualTabletPortrait:
      case TogglePlacementStrategy.singleTabletLandscape:
        return true;
      case TogglePlacementStrategy.dualMobile:
      case TogglePlacementStrategy.singleDesktop:
      case TogglePlacementStrategy.dualDesktopWide:
        return false;
    }
  }
}

/// Specific placement locations
enum TogglePlacement {
  appBarMobile,
  appBarTablet,
  appBarDesktop,
  sidebarMobile,
  navigationRailTablet,
  sidebarDesktop,
  floatingAction,
}

/// Configuration for toggle appearance
class ToggleConfig {
  final StatusToggleVariant variant;
  final StatusToggleSize size;
  final bool showLabel;
  final bool showIcon;

  const ToggleConfig({
    required this.variant,
    required this.size,
    required this.showLabel,
    required this.showIcon,
  });
}

/// Navigation destination data
class NavigationDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? description;

  const NavigationDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.description,
  });
}

// Implementation widgets for different screen sizes
class _MobileNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavigate;
  final bool isOnline;
  final bool isToggling;
  final Future<void> Function(bool) onToggle;
  final List<NavigationDestination> destinations;
  final VoidCallback? onReturnOrder;
  final bool showToggleInSidebar;

  const _MobileNavigation({
    required this.selectedIndex,
    required this.onNavigate,
    required this.isOnline,
    required this.isToggling,
    required this.onToggle,
    required this.destinations,
    this.onReturnOrder,
    required this.showToggleInSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: selectedIndex,
      onTap: onNavigate,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      items: destinations.map((dest) => BottomNavigationBarItem(
        icon: Icon(dest.icon),
        label: dest.label,
      )).toList(),
    );
  }
}

class _TabletNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavigate;
  final bool isOnline;
  final bool isToggling;
  final Future<void> Function(bool) onToggle;
  final List<NavigationDestination> destinations;
  final bool showToggle;

  const _TabletNavigationRail({
    required this.selectedIndex,
    required this.onNavigate,
    required this.isOnline,
    required this.isToggling,
    required this.onToggle,
    required this.destinations,
    required this.showToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          if (showToggle) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: ResponsiveLayoutManager.createOptimalToggle(
                context: context,
                isOnline: isOnline,
                isToggling: isToggling,
                onToggle: onToggle,
                placement: TogglePlacement.navigationRailTablet,
              ),
            ),
            const Divider(),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final dest = destinations[index];
                final isSelected = selectedIndex == index;
                
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onNavigate(index),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor.withOpacity(0.3)
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? (dest.selectedIcon ?? dest.icon) : dest.icon,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              size: 24,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dest.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Theme.of(context).colorScheme.onSurface,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (dest.description != null)
                                    Text(
                                      dest.description!,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavigate;
  final bool isOnline;
  final bool isToggling;
  final Future<void> Function(bool) onToggle;
  final List<NavigationDestination> destinations;
  final VoidCallback? onReturnOrder;
  final bool showToggle;

  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onNavigate,
    required this.isOnline,
    required this.isToggling,
    required this.onToggle,
    required this.destinations,
    this.onReturnOrder,
    required this.showToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          if (showToggle) ...[
            Padding(
              padding: const EdgeInsets.all(24),
              child: ResponsiveLayoutManager.createOptimalToggle(
                context: context,
                isOnline: isOnline,
                isToggling: isToggling,
                onToggle: onToggle,
                placement: TogglePlacement.sidebarDesktop,
              ),
            ),
            const Divider(),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final dest = destinations[index];
                final isSelected = selectedIndex == index;
                
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onNavigate(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? (dest.selectedIcon ?? dest.icon) : dest.icon,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              dest.label,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
