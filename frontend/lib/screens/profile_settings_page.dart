import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './account_settings_page.dart';
import './business_details_screen.dart';
import './change_password_screen.dart';
import './pos_settings_page.dart';
import './notification_settings_page.dart';
import './other_settings_page.dart';
import './working_hours_settings_screen.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../models/order.dart';
import '../services/app_auth_service.dart';
import '../services/app_state.dart';
import '../screens/login_page.dart';
import '../providers/session_provider.dart';
import '../providers/business_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  final Business business;
  final List<Order> orders;
  final Function(int)? onNavigateToPage;
  final Function(String, OrderStatus)? onOrderUpdated;

  const ProfileSettingsPage({
    Key? key,
    required this.business,
    required this.orders,
    this.onNavigateToPage,
    this.onOrderUpdated,
  }) : super(key: key);

  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Load user data from AppAuthService
      final userResponse = await AppAuthService.getCurrentUser();
      if (userResponse != null && userResponse['success'] == true) {
        // User data loaded successfully
        debugPrint('User data loaded successfully');
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Failed to load user data: $e');
      }
    }
  }

















  Widget _buildModernSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.04),
            blurRadius: GoldenRatio.spacing20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
          child: Padding(
            padding: EdgeInsets.all(GoldenRatio.spacing20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(GoldenRatio.spacing12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: GoldenRatio.iconMd,
                  ),
                ),
                SizedBox(width: GoldenRatio.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TypographySystem.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: GoldenRatio.xs),
                      Text(
                        subtitle,
                        style: TypographySystem.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(GoldenRatio.sm),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(GoldenRatio.radiusSm),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color,
                    size: GoldenRatio.spacing16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.signOut),
        content: Text(loc.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.signOut, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(loc.signOut),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 5),
          ),
        );

        // Call AppAuthService.signOut() to handle backend authentication cleanup
        await AppAuthService.signOut();
        
        // Clear all Riverpod providers to reset cached state
        ref.invalidate(sessionProvider);
        ref.invalidate(businessProvider);
        
        // Clear app state (online status, etc.)
        final appState = AppState();
        appState.logout();

        if (mounted) {
          // Navigate to login page and clear navigation stack
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error during logout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundVariant,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.backgroundVariant,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(GoldenRatio.spacing20),
            children: [
              // Settings Cards with Modern Design
              _buildModernSettingsCard(
                icon: Icons.business_rounded,
                title: loc.businessDetails,
                subtitle: loc.manageYourBusinessProfileAndInformation,
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BusinessDetailsScreen(business: widget.business),
                    ),
                  );
                },
              ),
              SizedBox(height: GoldenRatio.spacing16),
              _buildModernSettingsCard(
                icon: Icons.account_circle_rounded,
                title: loc.accountSettings,
                subtitle: loc.manageYourPersonalInformation,
                color: AppColors.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AccountSettingsPage(business: widget.business),
                    ),
                  );
                },
              ),
              SizedBox(height: GoldenRatio.spacing16),
              _buildModernSettingsCard(
                icon: Icons.lock_rounded,
                title: loc.changePassword,
                subtitle: loc.updateYourPasswordAndSecurity,
                color: const Color(0xFF5B9BD5), // Material 3 blue variant
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildModernSettingsCard(
                icon: Icons.point_of_sale_rounded,
                title: loc.posSettings,
                subtitle: loc.configurePointOfSaleIntegration,
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PosSettingsPage(business: widget.business),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildModernSettingsCard(
                icon: Icons.volume_up_rounded,
                title: loc.soundNotifications,
                subtitle: loc.configureSoundAlertsForNewOrdersAndUpdates,
                color: const Color(0xFFFF9500), // Material 3 orange
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const NotificationSettingsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildModernSettingsCard(
                icon: Icons.notifications_rounded,
                title: loc.notifications,
                subtitle: loc.manageNotificationPreferencesAndDeliveryMethods,
                color: const Color(0xFFFF3B30), // Material 3 red
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildModernSettingsCard(
                icon: Icons.location_on_rounded,
                title: AppLocalizations.of(context)!.locationSettings,
                subtitle: loc.manageBusinessLocationAndGpsCoordinates,
                color: const Color(0xFF34C759), // Material 3 green
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OtherSettingsPage(business: widget.business),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildModernSettingsCard(
                icon: Icons.access_time_rounded,
                title: AppLocalizations.of(context)!.workingHoursSettings,
                subtitle: loc.setUpOpeningAndClosingHoursForYourBusiness,
                color: AppColors.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WorkingHoursSettingsScreen(business: widget.business),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Material 3 Logout Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF3B30),
                      const Color(0xFFFF3B30).withValues(alpha: 0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3B30).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _signOut,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            loc.logout,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
