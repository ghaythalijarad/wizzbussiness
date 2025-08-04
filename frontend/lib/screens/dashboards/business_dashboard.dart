import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/business.dart';
import '../../l10n/app_localizations.dart';
import '../orders_page.dart';
import '../profile_settings_page.dart';
import '../discount_management_page.dart';
import '../products_management_screen.dart';
import '../../widgets/top_app_bar.dart';
import '../../utils/responsive_helper.dart';
import '../../providers/session_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/floating_order_notification_service.dart';

class BusinessDashboard extends ConsumerWidget {
  final Business? initialBusiness;
  const BusinessDashboard({
    Key? key,
    this.initialBusiness,
  }) : super(key: key);

  void _onToggleStatus(BuildContext context, WidgetRef ref, bool isOnline) {
    ref.read(businessOnlineStatusProvider.notifier).state = isOnline;

    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(isOnline ? loc.businessIsNowOnline : loc.businessIsNowOffline),
        backgroundColor: isOnline ? Colors.green : Colors.orange,
      ),
    );
  }

  void _onReturnOrder(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.returnOrderFeature),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _onNavigate(WidgetRef ref, int pageIndex) {
    ref.read(dashboardPageIndexProvider.notifier).state = pageIndex;
  }

  Widget _buildDashboardBody(WidgetRef ref, Business business) {
    final pageIndex = ref.watch(dashboardPageIndexProvider);
    final session = ref.watch(sessionProvider);

    if (!session.isAuthenticated || session.businessId == null) {
      return const Center(child: Text('Session expired. Please log in again.'));
    }

    switch (pageIndex) {
      case 0:
        return OrdersPage(
          businessId: session.businessId!,
        );
      case 1:
        return ProductsManagementScreen(business: business);
      case 2:
        return DiscountManagementPage(
          business: business,
          orders: const [], // Pass empty list as it's required for now
        );
      case 3:
        return ProfileSettingsPage(
          business: business,
          orders: const [], // Pass empty list as it's required for now
        );
      default:
        return Center(child: Text(AppLocalizations.of(ref.context)!.errorOccurred));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final businessAsyncValue = initialBusiness != null
        ? AsyncValue.data(initialBusiness!)
        : ref.watch(businessProvider);

    // Initialize floating notification service with root context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FloatingOrderNotificationService().initialize(context);
    });

    return businessAsyncValue.when(
      data: (business) {
        if (business == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('No business found for this account.'),
                  SizedBox(height: 16),
                  // TODO: Add a sign out button here
                ],
              ),
            ),
          );
        }

        final isDesktop = ResponsiveHelper.isDesktop(context);
        final isTablet = ResponsiveHelper.isTablet(context);

        if (isDesktop) {
          return _buildDesktopLayout(context, ref, loc, business);
        } else if (isTablet) {
          return _buildTabletLayout(context, ref, loc, business);
        } else {
          return _buildMobileLayout(context, ref, loc, business);
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error loading business: $error'),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, WidgetRef ref, AppLocalizations loc, Business business) {
    final isOnline = ref.watch(businessOnlineStatusProvider);
    final pageIndex = ref.watch(dashboardPageIndexProvider);

    return Scaffold(
      appBar: TopAppBar(
        title: '',
        isOnline: isOnline,
        onToggleStatus: (status) => _onToggleStatus(context, ref, status),
        onReturnOrder: () => _onReturnOrder(context),
        onNavigate: (index) => _onNavigate(ref, index),
      ),
      body: _buildDashboardBody(ref, business),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: pageIndex,
        onTap: (index) => _onNavigate(ref, index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: loc.orders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_bag),
            label: 'Products',
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

  Widget _buildTabletLayout(
      BuildContext context, WidgetRef ref, AppLocalizations loc, Business business) {
    final isOnline = ref.watch(businessOnlineStatusProvider);

    return Scaffold(
      appBar: TopAppBar(
        title: '',
        isOnline: isOnline,
        onToggleStatus: (status) => _onToggleStatus(context, ref, status),
        onReturnOrder: () => _onReturnOrder(context),
        onNavigate: (index) => _onNavigate(ref, index),
      ),
      body: Row(
        children: [
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
            child: _buildSideNavigation(context, ref, loc, business),
          ),
          Expanded(
            child: _buildDashboardBody(ref, business),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, WidgetRef ref, AppLocalizations loc, Business business) {
    final isOnline = ref.watch(businessOnlineStatusProvider);

    return Scaffold(
      appBar: TopAppBar(
        title: '',
        isOnline: isOnline,
        onToggleStatus: (status) => _onToggleStatus(context, ref, status),
        onReturnOrder: () => _onReturnOrder(context),
        onNavigate: (index) => _onNavigate(ref, index),
      ),
      body: Row(
        children: [
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
            child: _buildSideNavigation(context, ref, loc, business),
          ),
          Expanded(
            child: Container(
              padding: ResponsiveHelper.getResponsiveMargin(context),
              child: _buildDashboardBody(ref, business),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideNavigation(
      BuildContext context, WidgetRef ref, AppLocalizations loc, Business business) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                            business.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop ? 18 : 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            business.address ?? 'No address provided',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isDesktop ? 14 : 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildNavigationItem(
            context,
            ref,
            loc,
            icon: Icons.list_alt,
            label: loc.orders,
            index: 0,
          ),
          _buildNavigationItem(
            context,
            ref,
            loc,
            icon: Icons.shopping_bag,
            label: 'Products',
            index: 1,
          ),
          _buildNavigationItem(
            context,
            ref,
            loc,
            icon: Icons.local_offer,
            label: loc.discounts,
            index: 2,
          ),
          _buildNavigationItem(
            context,
            ref,
            loc,
            icon: Icons.settings,
            label: loc.settings,
            index: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(BuildContext context, WidgetRef ref, AppLocalizations loc,
      {required IconData icon, required String label, required int index}) {
    final pageIndex = ref.watch(dashboardPageIndexProvider);
    final isSelected = pageIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade600,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          ),
        ),
        onTap: () => _onNavigate(ref, index),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
