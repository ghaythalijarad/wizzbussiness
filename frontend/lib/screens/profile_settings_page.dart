import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './account_settings_page.dart';
import './pos_settings_page.dart';
import './change_password_screen.dart';
import './other_settings_page.dart';
import './discount_management_page.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../models/order.dart';
import '../services/app_auth_service.dart';
import '../screens/login_page.dart';
import './working_hours_settings_screen.dart';
import '../providers/session_provider.dart';
import '../providers/business_provider.dart';

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
  Map<String, dynamic>? _userData;

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
        if (mounted) {
          setState(() {
            _userData = userResponse;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userData = null;
        });
      }
    }
  }

  String _getBusinessTypeDisplayName(String? businessType) {
    final loc = AppLocalizations.of(context)!;
    if (businessType == null) return loc.notSpecified;

    switch (businessType.toLowerCase()) {
      case 'kitchen':
        return 'Kitchen';
      case 'cloudkitchen':
      case 'cloud kitchen':
        return 'Cloud Kitchen';
      case 'store':
        return 'Store';
      case 'pharmacy':
        return 'Pharmacy';
      case 'caffe':
      case 'cafe':
        return 'Caffe';
      default:
        return businessType;
    }
  }

  Widget _buildUserProfileHeader() {
    final loc = AppLocalizations.of(context)!;
    final business = widget.business;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00D4FF),
            Color(0xFF0099CC),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildCircularBusinessPhoto(business.businessPhotoUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getBusinessTypeDisplayName(business.businessType.name),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRatingSection(business),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusChip(
                loc.active,
                business.status == 'approved',
                business.status == 'approved' ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                loc.verified,
                business.status == 'approved',
                business.status == 'approved'
                    ? const Color(0xFF007fff)
                    : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build circular business photo widget for header
  Widget _buildCircularBusinessPhoto(String? businessPhotoUrl) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: businessPhotoUrl != null && businessPhotoUrl.isNotEmpty
            ? Image.network(
                businessPhotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to default icon if image fails to load
                  return _buildCircularDefaultIcon();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  );
                },
              )
            : _buildCircularDefaultIcon(),
      ),
    );
  }

  // Build circular default business icon for header
  Widget _buildCircularDefaultIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.business,
        size: 30,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isActive, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(Business business) {
    final loc = AppLocalizations.of(context)!;
    // Use business rating if available, otherwise default
    final double businessRating = 4.2; // business.rating or mock data
    final int totalReviews = 156; // mock data - replace with actual reviews

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_rounded,
            color: Colors.amber[300],
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            businessRating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          _buildStarRating(businessRating),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 16,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.rating,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$totalReviews reviews',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        double fillAmount = rating - index;
        if (fillAmount >= 1.0) {
          // Full star
          return Icon(
            Icons.star_rounded,
            size: 14,
            color: Colors.amber[300],
          );
        } else if (fillAmount > 0.0) {
          // Half star
          return Stack(
            children: [
              Icon(
                Icons.star_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: fillAmount,
                  child: Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Colors.amber[300],
                  ),
                ),
              ),
            ],
          );
        } else {
          // Empty star
          return Icon(
            Icons.star_rounded,
            size: 14,
            color: Colors.white.withValues(alpha: 0.3),
          );
        }
      }),
    );
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color,
                    size: 16,
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
      await AppAuthService.signOut();
      // Clear all providers
      ref.invalidate(sessionProvider);
      ref.invalidate(businessProvider);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFF), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // User Profile Header
              _buildUserProfileHeader(),
              const SizedBox(height: 24),

              // Settings Cards with Modern Design
              _buildModernSettingsCard(
                icon: Icons.account_circle_rounded,
                title: loc.accountSettings,
                subtitle: 'Manage your personal information',
                color: const Color(0xFF3399FF),
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
              const SizedBox(height: 16),
              _buildModernSettingsCard(
                icon: Icons.lock_rounded,
                title: loc.changePassword,
                subtitle: 'Update your password and security',
                color: const Color(0xFF00C1E8),
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
                subtitle: 'Configure point of sale integration',
                color: const Color(0xFF00D4FF),
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
                icon: Icons.location_on_rounded,
                title: AppLocalizations.of(context)!.locationSettings,
                subtitle: 'Manage business location and GPS coordinates',
                color: const Color(0xFF4CAF50),
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
                subtitle: 'Set up opening and closing hours for your business',
                color: const Color(0xFF2196F3),
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
              const SizedBox(height: 16),
              _buildModernSettingsCard(
                icon: Icons.local_offer_rounded,
                title: 'Discount Management',
                subtitle: 'Create and manage your discounts',
                color: const Color(0xFFFF9800),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiscountManagementPage(
                        business: widget.business,
                        orders: widget.orders,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Logout Button with Compact Design
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _signOut,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            loc.logout,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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
