import 'package:flutter/material.dart';
import './account_settings_page.dart';
import './pos_settings_page.dart';
import './change_password_screen.dart';
import './other_settings_page.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../models/order.dart';
import '../services/app_state.dart';
import '../services/app_auth_service.dart';
import '../services/api_service.dart';
import '../screens/login_page.dart';
import './working_hours_settings_screen.dart';

class ProfileSettingsPage extends StatefulWidget {
  final Business business;
  final Function(Locale)? onLanguageChanged;
  final List<Order> orders;
  final Function(int)? onNavigateToPage;
  final Function(String, OrderStatus)? onOrderUpdated;
  final Map<String, dynamic>? userData;
  final List<Map<String, dynamic>>? businessesData;

  const ProfileSettingsPage({
    Key? key,
    required this.business,
    this.onLanguageChanged,
    required this.orders,
    this.onNavigateToPage,
    this.onOrderUpdated,
    this.userData,
    this.businessesData,
  }) : super(key: key);

  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final AppState _appState = AppState();
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _businessData;
  bool _isLoadingUserData = true;
  bool _isLoadingBusinessData = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
    _loadUserData();
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

  Future<void> _loadUserData() async {
    setState(() {
      _isLoadingUserData = true;
      _isLoadingBusinessData = true;
      _errorMessage = null;
    });

    try {
      // Use passed user data if available, otherwise load from Cognito
      if (widget.userData != null) {
        setState(() {
          _userData = widget.userData;
          _isLoadingUserData = false;
        });
      } else {
        // Fallback to loading from Cognito
        final userResponse = await AppAuthService.getCurrentUser();
        if (userResponse != null && userResponse['success'] == true) {
          setState(() {
            _userData = userResponse['user'];
            _isLoadingUserData = false;
          });
        } else {
          setState(() {
            _errorMessage =
                userResponse?['message'] ?? 'Failed to load user data';
            _isLoadingUserData = false;
          });
        }
      }

      // Use passed business data if available, otherwise load from API
      if (widget.businessesData != null && widget.businessesData!.isNotEmpty) {
        setState(() {
          _businessData = widget.businessesData!.first;
          _isLoadingBusinessData = false;
        });
      } else {
        // Fallback to loading from API
        final apiService = ApiService();
        final businesses = await apiService.getUserBusinesses();

        if (businesses.isNotEmpty) {
          setState(() {
            _businessData = businesses[0]; // Get the first business
            _isLoadingBusinessData = false;
          });
        } else {
          setState(() {
            _businessData = null;
            _isLoadingBusinessData = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoadingUserData = false;
        _isLoadingBusinessData = false;
      });
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
    if (_isLoadingUserData || _isLoadingBusinessData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF5722),
              Color(0xFFE64A19),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              loc.errorLoadingProfile,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFF5722),
              ),
              child: Text(loc.retry),
            ),
          ],
        ),
      );
    }

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
              _buildCircularBusinessPhoto(
                  _businessData?['business_photo_url'] ??
                      _userData?['business_photo_url'] ??
                      widget.business.businessPhotoUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _businessData?['business_name'] ??
                          _userData?['business_name'] ??
                          loc.businessName,
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
                        _getBusinessTypeDisplayName(
                            _businessData?['business_type'] ??
                                _userData?['business_type']),
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
          _buildRatingSection(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusChip(
                loc.active,
                _userData?['is_active'] ?? false,
                _userData?['is_active'] == true ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildStatusChip(
                loc.verified,
                _userData?['is_verified'] ?? false,
                _userData?['is_verified'] == true
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

  Widget _buildRatingSection() {
    final loc = AppLocalizations.of(context)!;
    // Mock rating data - in real app, this would come from userData or API
    final double businessRating = _userData?['rating']?.toDouble() ?? 4.2;
    final int totalReviews = _userData?['total_reviews'] ?? 156;

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
      _appState.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => LoginPage(
                onLanguageChanged: widget.onLanguageChanged ?? (locale) {})),
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
                      builder: (context) => WorkingHoursSettingsScreen(business: widget.business),
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
