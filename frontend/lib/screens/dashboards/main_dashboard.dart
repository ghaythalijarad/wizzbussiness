import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/design_system/design_system.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/business_provider.dart';
import '../../providers/auth_provider_riverpod.dart';
import '../../services/api_service.dart';
import '../auth/auth_screen.dart';
import '../business_details_screen.dart';
import '../products_management_screen.dart';

class MainDashboard extends ConsumerStatefulWidget {
  const MainDashboard({super.key});

  @override
  ConsumerState<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends ConsumerState<MainDashboard> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(businessProvider);

    return businessAsync.when(
      data: (business) {
        if (business == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('No business data available'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(businessProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildDashboard(context, business);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(businessProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, business) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(GoldenRatio.xs),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(GoldenRatio.xs),
              ),
              child: Icon(
                Icons.dashboard_rounded,
                size: GoldenRatio.lg,
                color: AppColors.secondary,
              ),
            ),
            SizedBox(width: GoldenRatio.md),
            Text(
              'WIZZ Business Manager',
              style: TypographySystem.headlineSmall.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: GoldenRatio.xs,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: GoldenRatio.xs),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.md),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_rounded),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Notifications feature coming soon'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GoldenRatio.md),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: GoldenRatio.xs),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.md),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Settings feature coming soon'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GoldenRatio.md),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          const DashboardHomeTab(),
          const OrdersTab(),
          ProductsManagementScreen(business: business),
          const AnalyticsTab(),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: selectedIndex == 0 ? FloatingActionButton(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Quick order feature coming soon'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}

// Dashboard Home Tab
class DashboardHomeTab extends StatelessWidget {
  const DashboardHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(GoldenRatio.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back!',
            style: TypographySystem.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: GoldenRatio.lg),
          
          // Stats Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: GoldenRatio.lg,
            mainAxisSpacing: GoldenRatio.lg,
            children: [
              _buildStatCard('Today\'s Orders', '24', Icons.receipt_long, AppColors.primary),
              _buildStatCard('Revenue', '\$1,245', Icons.attach_money, AppColors.secondary),
              _buildStatCard('Products', '156', Icons.inventory, AppColors.success),
              _buildStatCard('Reviews', '4.8', Icons.star, AppColors.warning),
            ],
          ),
          
          SizedBox(height: GoldenRatio.xl),
          
          // Recent Orders
          Text(
            'Recent Orders',
            style: TypographySystem.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: GoldenRatio.md),
          
          ...List.generate(3, (index) => _buildOrderCard(
            'Order #${1001 + index}',
            'Customer ${index + 1}',
            '\$${(25.50 + index * 10).toStringAsFixed(2)}',
            index == 0 ? 'New' : index == 1 ? 'Preparing' : 'Ready',
          )),
          
          SizedBox(height: GoldenRatio.xl),
          
          // Color Palette Showcase
          Text(
            'App Color Palette',
            style: TypographySystem.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: GoldenRatio.md),
          _buildColorPalette(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: GoldenRatio.xs,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GoldenRatio.md),
      ),
      child: Padding(
        padding: EdgeInsets.all(GoldenRatio.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: GoldenRatio.xl, color: color),
            SizedBox(height: GoldenRatio.xs),
            Text(
              value,
              style: TypographySystem.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TypographySystem.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildColorPalette() {
    final colorData = [
      {'name': 'Primary (Lime Green)', 'color': AppColors.primary, 'hex': '#32CD32'},
      {'name': 'Secondary (Gold)', 'color': AppColors.secondary, 'hex': '#FFD300'},
      {'name': 'Success', 'color': AppColors.success, 'hex': '#22C55E'},
      {'name': 'Warning', 'color': AppColors.warning, 'hex': '#F59E0B'},
      {'name': 'Error', 'color': AppColors.error, 'hex': '#EF4444'},
      {'name': 'Info', 'color': AppColors.info, 'hex': '#3B82F6'},
    ];
    
    return Card(
      elevation: GoldenRatio.xs,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GoldenRatio.md),
      ),
      child: Padding(
        padding: EdgeInsets.all(GoldenRatio.lg),
        child: Column(
          children: [
            ...colorData.map((data) => Padding(
                      padding: EdgeInsets.only(bottom: GoldenRatio.md),
              child: Row(
                children: [
                  Container(
                            width: GoldenRatio.xl,
                            height: GoldenRatio.xl,
                    decoration: BoxDecoration(
                      color: data['color'] as Color,
                              borderRadius:
                                  BorderRadius.circular(GoldenRatio.xs),
                      border: Border.all(
                                color: AppColors.border,
                        width: 1,
                      ),
                    ),
                  ),
                          SizedBox(width: GoldenRatio.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] as String,
                                  style: TypographySystem.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          data['hex'] as String,
                                  style: TypographySystem.bodySmall.copyWith(
                                    color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(String orderNumber, String customer, String amount, String status) {
    Color statusColor = status == 'New'
        ? AppColors.info
        : status == 'Preparing'
            ? AppColors.warning
            : AppColors.success;
    
    return Card(
      margin: EdgeInsets.only(bottom: GoldenRatio.xs),
      elevation: GoldenRatio.xs,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GoldenRatio.md),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(GoldenRatio.md),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.12),
          child: Icon(Icons.receipt, color: statusColor),
        ),
        title: Text(
          orderNumber,
          style: TypographySystem.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          customer,
          style: TypographySystem.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: TypographySystem.titleSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: GoldenRatio.xs,
                vertical: GoldenRatio.xs / 2,
              ),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(GoldenRatio.md),
              ),
              child: Text(
                status,
                style: TypographySystem.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Orders Tab
class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orders',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter Tabs
          DefaultTabController(
            length: 4,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'New'),
                    Tab(text: 'Preparing'),
                    Tab(text: 'Ready'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 400,
                  child: TabBarView(
                    children: [
                      _buildOrdersList(['All orders shown here']),
                      _buildOrdersList(['New orders shown here']),
                      _buildOrdersList(['Orders being prepared']),
                      _buildOrdersList(['Ready orders']),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<String> orders) {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text(orders[index]),
            subtitle: const Text('Demo order data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        );
      },
    );
  }
}

// Analytics Tab
class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Sales Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales This Week',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 3),
                              FlSpot(1, 1),
                              FlSpot(2, 4),
                              FlSpot(3, 2),
                              FlSpot(4, 5),
                              FlSpot(5, 3),
                              FlSpot(6, 4),
                            ],
                            isCurved: true,
                            color: Theme.of(context).primaryColor,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Performance Metrics
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '87%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text('Success Rate'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '12m',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const Text('Avg Prep Time'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Profile Tab
class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  bool _showWorkingHours = false;
  bool _showChangePassword = false;
  bool _isSavingWorkingHours = false;
  
  // Password form controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // User attributes cache
  Map<String, String> _userAttributes = {};
  bool _attributesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserAttributes();
    _loadWorkingHours();
  }
  
  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAttributes() async {
    if (!_attributesLoaded) {
      final authNotifier = ref.read(authProviderRiverpod.notifier);
      final attributes = await authNotifier.getUserAttributes();
      if (mounted) {
        setState(() {
          _userAttributes = attributes;
          _attributesLoaded = true;
        });
      }
    }
  }
  
  Future<void> _loadWorkingHours() async {
    final businessAsyncValue = ref.read(businessProvider);
    final business = businessAsyncValue.value;
    
    if (business == null) return;
    
    try {
      final apiService = ApiService();
      final response = await apiService.getBusinessWorkingHours(business.id);
      
      if (response['workingHours'] != null && mounted) {
        setState(() {
          // Convert backend format to frontend format
          final backendHours = response['workingHours'] as Map<String, dynamic>;
          
          for (String day in workingHours.keys) {
            if (backendHours.containsKey(day)) {
              final dayData = backendHours[day] as Map<String, dynamic>;
              workingHours[day] = {
                'isOpen': dayData['isOpen'] ?? false,
                'openTime': dayData['openTime'] ?? '09:00',
                'closeTime': dayData['closeTime'] ?? '17:00',
              };
            }
          }
        });
      }
    } catch (e) {
      print('Error loading working hours: $e');
      // Keep default values if loading fails
    }
  }
  
  Future<void> _saveWorkingHours() async {
    final businessAsyncValue = ref.read(businessProvider);
    final business = businessAsyncValue.value;
    
    if (business == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Business data not available'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isSavingWorkingHours = true;
    });
    
    try {
      final apiService = ApiService();
      
      // Convert frontend format to backend format
      final backendFormat = <String, Map<String, dynamic>>{};
      
      for (String day in workingHours.keys) {
        final dayData = workingHours[day]!;
        backendFormat[day] = {
          'isOpen': dayData['isOpen'],
          'openTime': dayData['isOpen'] ? dayData['openTime'] : null,
          'closeTime': dayData['isOpen'] ? dayData['closeTime'] : null,
        };
      }
      
      final requestData = {
        'workingHours': backendFormat,
      };
      
      await apiService.updateBusinessWorkingHours(business.id, requestData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Working hours saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('Error saving working hours: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save working hours: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingWorkingHours = false;
        });
      }
    }
  }

  Map<String, Map<String, dynamic>> workingHours = {
    'Monday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
    'Tuesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
    'Wednesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
    'Thursday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
    'Friday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '23:00'},
    'Saturday': {'isOpen': true, 'openTime': '10:00', 'closeTime': '23:00'},
    'Sunday': {'isOpen': false, 'openTime': '10:00', 'closeTime': '21:00'},
  };

  @override
  Widget build(BuildContext context) {
    final businessAsyncValue = ref.watch(businessProvider);
    final authState = ref.watch(authProviderRiverpod);
    final currentUser = authState.currentUser;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile Header
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary,
            child: businessAsyncValue.when(
              data: (business) {
                if (business?.businessPhotoUrl != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      business!.businessPhotoUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.restaurant,
                          size: 50,
                          color: Colors.white,
                        );
                      },
                    ),
                  );
                }
                return Icon(
                  Icons.restaurant,
                  size: 50,
                  color: Colors.white,
                );
              },
              loading: () => Icon(
                Icons.restaurant,
                size: 50,
                color: Colors.white,
              ),
              error: (_, __) => Icon(
                Icons.restaurant,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Business Name
          businessAsyncValue.when(
            data: (business) => Text(
              business?.name ?? 
              _userAttributes['custom:business_name'] ?? 
              _userAttributes['name'] ?? 
              currentUser?.username ?? 
              'Business Name',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            loading: () => Text(
              _userAttributes['custom:business_name'] ?? 
              _userAttributes['name'] ?? 
              'Loading...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            error: (error, _) => Text(
              _userAttributes['custom:business_name'] ?? 
              _userAttributes['name'] ?? 
              currentUser?.username ?? 
              'Business Name',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Business Email
          businessAsyncValue.when(
            data: (business) => Text(
              business?.email ?? 
              _userAttributes['email'] ?? 
              currentUser?.username ?? 
              'email@business.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            loading: () => Text(
              _userAttributes['email'] ?? 
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            error: (error, _) => Text(
              _userAttributes['email'] ?? 
              currentUser?.username ?? 
              'email@business.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Profile Menu Items
          _buildMenuItems(),
          
          // Working Hours Section (Expandable)
          if (_showWorkingHours) ...[
            const SizedBox(height: 16),
            _buildWorkingHoursSection(),
          ],
          
          // Change Password Section (Expandable)
          if (_showChangePassword) ...[
            const SizedBox(height: 16),
            _buildChangePasswordSection(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMenuItems() {
    final items = [
      {'icon': Icons.business, 'title': 'Business Details'},
      {'icon': Icons.access_time, 'title': 'Working Hours'},
      {'icon': Icons.notifications, 'title': 'Notification Settings'},
      {'icon': Icons.lock, 'title': 'Change Password'},
      {'icon': Icons.help, 'title': 'Help & Support'},
      {'icon': Icons.logout, 'title': 'Logout'},
    ];
    
    return Column(
      children: List.generate(items.length, (index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(items[index]['icon'] as IconData),
            title: Text(items[index]['title'] as String),
            trailing: Icon(
              items[index]['title'] == 'Working Hours' && _showWorkingHours
                  ? Icons.expand_less
                  : items[index]['title'] == 'Change Password' && _showChangePassword
                      ? Icons.expand_less
                      : Icons.chevron_right,
            ),
            onTap: () {
              if (items[index]['title'] == 'Working Hours') {
                setState(() {
                  _showWorkingHours = !_showWorkingHours;
                  _showChangePassword = false; // Close other sections
                });
              } else if (items[index]['title'] == 'Change Password') {
                setState(() {
                  _showChangePassword = !_showChangePassword;
                  _showWorkingHours = false; // Close other sections
                });
              } else if (items[index]['title'] == 'Logout') {
                _handleLogout();
              } else if (items[index]['title'] == 'Business Details') {
                // Navigate to Business Details Screen with real business data
                _navigateToBusinessDetails();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${items[index]['title']} feature coming soon'),
                  ),
                );
              }
            },
          ),
        );
      }),
    );
  }
  
  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading indicator with shorter duration
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('Signing out...'),
            ],
          ),
          duration: Duration(seconds: 5), // Reduced from 30 to 5 seconds
        ),
      );

      try {
        // Get AuthProvider and perform proper sign out
        final authNotifier = ref.read(authProviderRiverpod.notifier);
        await authNotifier.signOut();

        if (mounted) {
          // Hide loading snackbar immediately
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          // Show success message briefly
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Signed out successfully'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 1),
            ),
          );
          
          // Small delay to show success message, then navigate
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Navigate back to auth screen and clear all routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          // Hide loading snackbar
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _navigateToBusinessDetails() async {
    final businessAsyncValue = ref.read(businessProvider);
    
    businessAsyncValue.when(
      data: (business) {
        if (business != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusinessDetailsScreen(business: business),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No business data available. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading business details...'),
          ),
        );
      },
      error: (error, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading business details: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
  
  Widget _buildWorkingHoursSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Working Hours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Day by day working hours
            ...workingHours.entries.map((entry) {
              String day = entry.key;
              Map<String, dynamic> hours = entry.value;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    // Day name
                    SizedBox(
                      width: 80,
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    
                    // Open/Closed Switch
                    Switch(
                      value: hours['isOpen'],
                      onChanged: (value) {
                        setState(() {
                          workingHours[day]!['isOpen'] = value;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Time fields (only show if open)
                    if (hours['isOpen']) ...[
                      Expanded(
                        child: Row(
                          children: [
                            // Open time
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTime(context, day, 'openTime'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.primary),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    hours['openTime'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('-'),
                            ),
                            
                            // Close time
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _selectTime(context, day, 'closeTime'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.primary),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    hours['closeTime'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: Text(
                          'Closed',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 16),
            
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    onPressed: () {
                      setState(() {
                        // Reset to default hours
                        workingHours = {
                          'Monday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
                          'Tuesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
                          'Wednesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
                          'Thursday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '22:00'},
                          'Friday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '23:00'},
                          'Saturday': {'isOpen': true, 'openTime': '10:00', 'closeTime': '23:00'},
                          'Sunday': {'isOpen': false, 'openTime': '10:00', 'closeTime': '21:00'},
                        };
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Working hours reset to default'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isSavingWorkingHours 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSavingWorkingHours ? 'Saving...' : 'Save'),
                    onPressed: _isSavingWorkingHours ? null : _saveWorkingHours,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _selectTime(BuildContext context, String day, String timeType) async {
    final currentTime = workingHours[day]![timeType];
    final timeParts = currentTime.split(':');
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        workingHours[day]![timeType] = 
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }
  
  Widget _buildChangePasswordSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Current Password
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // New Password
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                    return 'Password must contain uppercase, lowercase, and numbers';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_reset, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Password Requirements
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password Requirements:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPasswordRequirement('At least 8 characters'),
                    _buildPasswordRequirement('At least one uppercase letter'),
                    _buildPasswordRequirement('At least one lowercase letter'),
                    _buildPasswordRequirement('At least one number'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                      onPressed: () {
                        setState(() {
                          _currentPasswordController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Form cleared'),
                            backgroundColor: AppColors.info,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Change Password'),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Simulate password change
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Password changed successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          
                          // Clear form and close section
                          setState(() {
                            _currentPasswordController.clear();
                            _newPasswordController.clear();
                            _confirmPasswordController.clear();
                            _showChangePassword = false;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPasswordRequirement(String requirement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Text(
            requirement,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
