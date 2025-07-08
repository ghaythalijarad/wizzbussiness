import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../screens/login_page.dart';
import '../screens/dashboards/business_dashboard.dart';
import '../services/unified_auth_service.dart';
import '../services/api_service.dart';
import '../models/business.dart';
import '../models/business_type.dart';

/// Extracted WizzBusinessSplashPage from main.dart
class WizzBusinessSplashPage extends StatefulWidget {
  final Function(Locale) onLanguageChanged;

  const WizzBusinessSplashPage({Key? key, required this.onLanguageChanged})
      : super(key: key);

  @override
  State<WizzBusinessSplashPage> createState() => _WizzBusinessSplashPageState();
}

class _WizzBusinessSplashPageState extends State<WizzBusinessSplashPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _checkAuthentication();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    // Simulate a delay for splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    try {
      // Check if user is already signed in
      final isSignedIn = await UnifiedAuthService.isSignedIn();

      if (isSignedIn) {
        print('User is already signed in, checking for business data...');

        // User is signed in, try to get their business data and go to dashboard
        final apiService = ApiService();
        final businesses = await apiService.getUserBusinesses();

        if (businesses.isNotEmpty) {
          // User has business data, navigate to dashboard
          final businessData = businesses[0];
          final business = Business(
            id: businessData['id'],
            name: businessData['name'],
            email: businessData['email'] ?? '',
            phone: businessData['phone_number'] ?? '',
            address: businessData['address']?['street'] ?? '',
            latitude: businessData['address']?['latitude']?.toDouble() ?? 0.0,
            longitude: businessData['address']?['longitude']?.toDouble() ?? 0.0,
            offers: [],
            businessHours: {},
            settings: {},
            businessType:
                _getBusinessTypeFromString(businessData['business_type']),
          );

          print(
              'Navigating to dashboard with existing business: ${business.name}');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BusinessDashboard(
                business: business,
                onLanguageChanged: widget.onLanguageChanged,
              ),
            ),
          );
          return;
        } else {
          print(
              'User is signed in but has no business data, going to login screen');
        }
      } else {
        print('User is not signed in, going to login screen');
      }
    } catch (e) {
      print('Error checking authentication: $e');
      // Fall through to login screen on any error
    }

    // If we reach here, navigate to login screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginPage(onLanguageChanged: widget.onLanguageChanged),
      ),
    );
  }

  BusinessType _getBusinessTypeFromString(String? businessTypeString) {
    switch (businessTypeString?.toLowerCase()) {
      case 'restaurant':
        return BusinessType.restaurant;
      case 'store':
        return BusinessType.store;
      case 'pharmacy':
        return BusinessType.pharmacy;
      case 'kitchen':
        return BusinessType.kitchen;
      default:
        return BusinessType.restaurant; // Default fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    // UI rendering logic for splash page
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _logoFadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loc.welcome,
                  style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}
