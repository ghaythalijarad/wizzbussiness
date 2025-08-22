import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './account_settings_page.dart';
import './pos_settings_page.dart';
import './change_password_screen.dart';
import './other_settings_page.dart';
import './discount_management_page.dart';
import './sound_notification_settings_page.dart';
import './notification_settings_page.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../models/order.dart';
import '../services/app_auth_service.dart';
import '../screens/signin_screen.dart';
import './working_hours_settings_screen.dart';
import '../providers/session_provider.dart';
import '../providers/business_provider.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  final Business business;
  final List<Order> orders;
  final Function(int)? onNavigateToPage;
  final Function(String, OrderStatus)? onOrderUpdated;
  final bool embedded;

  const ProfileSettingsPage({
    Key? key,
    required this.business,
    required this.orders,
    this.onNavigateToPage,
    this.onOrderUpdated,
    this.embedded = false,
  }) : super(key: key);

  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  // ignore: unused_field
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
      case 'bakery':
        return 'Bakery';
      case 'herbalspices':
        return 'Herbal & Spices';
      case 'cosmetics':
        return 'Cosmetics';
      case 'betshop':
        return 'Bet Shop';
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
                        color: Colors.white.withOpacity(0.2),
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
                business.status == 'approved'
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
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
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
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
        color: Colors.white.withOpacity(0.2),
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
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
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
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_rounded,
            color: Theme.of(context).colorScheme.primary,
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
          const SizedBox(height: 6),
          _buildStarRating(businessRating),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 16,
            color: Colors.white.withOpacity(0.3),
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
            color: Theme.of(context).colorScheme.primary,
          );
        } else if (fillAmount > 0.0) {
          // Half star
          return Stack(
            children: [
              Icon(
                Icons.star_rounded,
                size: 14,
                color: Colors.white.withOpacity(0.3),
              ),
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: fillAmount,
                  child: Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
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
            color: Colors.white.withOpacity(0.3),
          );
        }
      }),
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
            builder: (context) => const SignInScreen(
                  noticeMessage: 'Signed out successfully',
                )),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserProfileHeader(),
          const SizedBox(height: 24),
          _buildSettingsSection(
            loc.accountSettings,
            [
              _buildSettingsItem(
                context,
                Icons.person_outline,
                loc.personalInformation,
                () =>
                    _navigateTo(AccountSettingsPage(business: widget.business)),
              ),
              _buildSettingsItem(
                context,
                Icons.lock_outline,
                loc.changePassword,
                () => _navigateTo(const ChangePasswordScreen()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            loc.businessManagement,
            [
              _buildSettingsItem(
                context,
                Icons.store_outlined,
                loc.businessInformation,
                () =>
                    _navigateTo(AccountSettingsPage(business: widget.business)),
              ),
              _buildSettingsItem(
                context,
                Icons.local_offer_outlined,
                loc.manageDiscounts,
                () => _navigateTo(DiscountManagementPage(
                  business: widget.business,
                  orders: widget.orders,
                )),
              ),
              _buildSettingsItem(
                context,
                Icons.access_time,
                loc.workingHoursSettings,
                () => _navigateTo(
                    WorkingHoursSettingsScreen(business: widget.business)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            loc.appConfiguration,
            [
              _buildSettingsItem(
                context,
                Icons.language_outlined,
                loc.languageSettings,
                () => _navigateTo(const OtherSettingsPage()),
              ),
              _buildSettingsItem(
                context,
                Icons.notifications_outlined,
                loc.notifications,
                () => _navigateTo(const NotificationSettingsPage()),
              ),
              _buildSettingsItem(
                context,
                Icons.volume_up_outlined,
                'Sound & Notification',
                () => _navigateTo(const SoundNotificationSettingsPage()),
              ),
              _buildSettingsItem(
                context,
                Icons.print_outlined,
                loc.posSettings,
                () => _navigateTo(PosSettingsPage(business: widget.business)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildLogoutButton(context),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      body: content,
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: children,
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout, color: Colors.white),
        label: Text(loc.logout, style: const TextStyle(color: Colors.white)),
        onPressed: () => _signOut(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        ),
      ),
    );
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
  }
}
