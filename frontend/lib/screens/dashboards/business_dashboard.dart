import 'package:flutter/material.dart';
import '../../models/business.dart';
import '../../l10n/app_localizations.dart';
import '../orders_page.dart';
import '../items_management_page.dart';
import '../analytics_page.dart';
import '../discount_management_page.dart';
import '../profile_settings_page.dart';
import '../centralized_platform_page.dart';
import '../../models/order.dart';
import '../../widgets/top_app_bar.dart';
import '../../services/app_state.dart';

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

  Widget _buildDashboardBody() {
    switch (_selectedIndex) {
      case 0:
        return OrdersPage(
          orders: _orders,
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
        );
      case 1:
        return ItemsManagementPage(
          business: widget.business,
          orders: _orders,
        );
      case 2:
        return AnalyticsPage(
          business: widget.business,
          orders: _orders,
        );
      case 3:
        return DiscountManagementPage(
          business: widget.business,
          orders: _orders,
        );
      case 4:
        return ProfileSettingsPage(
          business: widget.business,
          orders: _orders,
          onLanguageChanged: widget.onLanguageChanged,
        );
      case 5:
        return CentralizedPlatformPage(
          business: widget.business,
          orders: _orders,
        );
      default:
        return const Center(child: Text('Error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: TopAppBar(
        title: '',
        isOnline: _appState.isOnline,
        onToggleStatus: _onToggleStatus,
        onReturnOrder: _onReturnOrder,
        onNavigate: _onNavigate,
      ),
      body: _buildDashboardBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: loc.orders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.store),
            label: loc.items,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics),
            label: loc.analytics,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.discount),
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
}
