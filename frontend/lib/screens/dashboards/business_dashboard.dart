import 'package:flutter/material.dart';
import '../../models/business.dart';
import '../../l10n/app_localizations.dart';
import '../orders_page.dart';
import '../profile_settings_page.dart';
import '../items_management_page.dart';
import '../discount_management_page.dart';
import '../../models/order.dart';
import '../../widgets/top_app_bar.dart';
import '../../services/app_state.dart';
import '../../utils/responsive_helper.dart';

class BusinessDashboard extends StatefulWidget {
  final Business business;
  final void Function(Locale) onLanguageChanged;

  const BusinessDashboard({
    Key? key,
    required this.business,
    required this.onLanguageChanged,
  }) : super(key: key);

  @override
  _BusinessDashboardState createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends State<BusinessDashboard> {
  int _selectedIndex = 0;
  List<Order> _orders = [];
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onToggleStatus(bool isOnline) {
    // Update global app state instead of local state
    _appState.setOnline(isOnline);

    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(isOnline ? loc.businessIsNowOnline : loc.businessIsNowOffline),
        backgroundColor: isOnline ? Colors.green : Colors.orange,
      ),
    );
  }

  void _onReturnOrder() {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.returnOrderFeature),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _onNavigate(int pageIndex) {
    setState(() {
      _selectedIndex = pageIndex;
    });
  }

  Future<void> _refreshOrders() async {
    // This would typically fetch fresh orders from the API
    // For now, we'll just trigger a rebuild to show new orders
    // In a real implementation, you'd call the API service to fetch latest orders
    setState(() {
      // The orders will be refreshed through the normal flow
      // when new orders are created via simulation
    });
  }

  Widget _buildDashboardBody() {
    switch (_selectedIndex) {
      case 0:
        return OrdersPage(
          orders: _orders,
          businessId: widget.business.id,
          onOrderUpdated: (orderId, status) {
            // Handle order status updates
            final orderIndex =
                _orders.indexWhere((order) => order.id == orderId);
            if (orderIndex != -1) {
              setState(() {
                _orders[orderIndex] =
                    _orders[orderIndex].copyWith(status: status);
              });
            }
          },
          onOrdersRefresh: _refreshOrders,
        );
      case 1:
        return ItemsManagementPage(
          business: widget.business,
          orders: _orders,
          onNavigateToOrders: () => setState(() => _selectedIndex = 0),
          onOrderUpdated: (orderId, status) {
            final orderIndex =
                _orders.indexWhere((order) => order.id == orderId);
            if (orderIndex != -1) {
              setState(() {
                _orders[orderIndex] =
                    _orders[orderIndex].copyWith(status: status);
              });
            }
          },
        );
      case 2:
        return DiscountManagementPage(
          business: widget.business,
          orders: _orders,
        );
      case 3:
        return ProfileSettingsPage(
          business: widget.business,
          orders: _orders,
          onLanguageChanged: widget.onLanguageChanged,
        );
      default:
        return Center(child: Text(AppLocalizations.of(context)!.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    
    if (isDesktop) {
      return _buildDesktopLayout(context, loc);
    } else if (isTablet) {
      return _buildTabletLayout(context, loc);
    } else {
      return _buildMobileLayout(context, loc);
    }
  }

  Widget _buildMobileLayout(BuildContext context, AppLocalizations loc) {
    return Scaffold(
      appBar: TopAppBar(
        title: '',
        isOnline: _appState.isOnline,
        onToggleStatus: _onToggleStatus,
        onReturnOrder: _onReturnOrder,
        onNavigate: _onNavigate,
        onLanguageChanged: widget.onLanguageChanged,
      ),
      body: _buildDashboardBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: loc.orders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2),
            label: loc.items,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_offer),
            label: loc.discounts,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: loc.settings,
          ),
        ],
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, AppLocalizations loc) {
    return Scaffold(
      appBar: TopAppBar(
        title: '',
        isOnline: _appState.isOnline,
        onToggleStatus: _onToggleStatus,
        onReturnOrder: _onReturnOrder,
        onNavigate: _onNavigate,
        onLanguageChanged: widget.onLanguageChanged,
      ),
      body: Row(
        children: [
          // Side navigation for tablet
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                right: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: _buildSideNavigation(context, loc),
          ),
          // Main content area
          Expanded(
            child: _buildDashboardBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppLocalizations loc) {
    return Scaffold(
      appBar: TopAppBar(
        title: '',
        isOnline: _appState.isOnline,
        onToggleStatus: _onToggleStatus,
        onReturnOrder: _onReturnOrder,
        onNavigate: _onNavigate,
        onLanguageChanged: widget.onLanguageChanged,
      ),
      body: Row(
        children: [
          // Side navigation for desktop
          Container(
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
            child: _buildSideNavigation(context, loc),
          ),
          // Main content area
          Expanded(
            child: Container(
              padding: ResponsiveHelper.getResponsiveMargin(context),
              child: _buildDashboardBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavigation(BuildContext context, AppLocalizations loc) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business info header
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.store,
                        color: Colors.white,
                        size: isDesktop ? 24 : 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.business.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isDesktop ? 18 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _appState.isOnline 
                                ? Colors.green.withOpacity(0.2)
                                : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _appState.isOnline 
                                  ? Colors.green
                                  : Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _appState.isOnline ? loc.online : loc.offline,
                              style: TextStyle(
                                color: _appState.isOnline 
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Navigation items
          Expanded(
            child: ListView(
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.list_alt,
                  title: loc.orders,
                  isSelected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.inventory_2,
                  title: loc.items,
                  isSelected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.local_offer,
                  title: loc.discounts,
                  isSelected: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _buildNavItem(
                  context,
                  icon: Icons.settings,
                  title: loc.settings,
                  isSelected: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 16 : 12,
              vertical: isDesktop ? 16 : 12,
            ),
            decoration: BoxDecoration(
              color: isSelected 
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected 
                ? Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    width: 1,
                  )
                : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
                  size: isDesktop ? 24 : 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected 
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade700,
                      fontSize: isDesktop ? 16 : 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
