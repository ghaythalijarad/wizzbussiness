import 'package:flutter/material.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../widgets/language_switcher.dart';
import '../widgets/wizz_business_text_form_field.dart';
import '../widgets/wizz_business_button.dart';
import '../screens/forgot_password_page.dart';
import '../screens/registration_form_screen.dart';
import '../screens/dashboards/business_dashboard.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/business.dart';
import '../models/business_type.dart';
import '../utils/responsive_helper.dart';

class LoginPage extends StatefulWidget {
  final Function(Locale) onLanguageChanged;

  const LoginPage({Key? key, required this.onLanguageChanged})
      : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        // Call the actual backend API for login
        final response = await AuthService.login(email, password);

        if (response['success'] == true) {
          // Login successful, store the token if needed
          final accessToken = response['access_token'];
          print('Login successful, access token: $accessToken');

          // Fetch user's businesses from backend
          try {
            final apiService = ApiService();
            final businesses = await apiService.getUserBusinesses();
            
            if (businesses.isNotEmpty) {
              // Use the first business (users should have at least one business)
              final businessData = businesses[0];
              final business = Business(
                id: businessData['id'],
                name: businessData['name'],
                email: businessData['email'] ?? email,
                phone: businessData['phone_number'] ?? '',
                address: businessData['address']?['street'] ?? '',
                latitude: businessData['address']?['latitude']?.toDouble() ?? 0.0,
                longitude: businessData['address']?['longitude']?.toDouble() ?? 0.0,
                offers: [],
                businessHours: {},
                settings: {},
                businessType: _getBusinessTypeFromString(businessData['business_type']),
              );
              
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => BusinessDashboard(
                    business: business,
                    onLanguageChanged: widget.onLanguageChanged,
                  ),
                ),
              );
            } else {
              // User has no businesses - this shouldn't happen but handle it
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No business found for this user'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } catch (e) {
            print('Error fetching user business: $e');
            // Fallback to demo business if API fails
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    _createDashboard(BusinessType.restaurant, email, context),
              ),
            );
          }
        } else {
          // Login failed, show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Login failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  Widget _createDashboard(
      BusinessType businessType, String username, BuildContext context) {
    final business = Business(
      id: '${businessType.name}_001',
      name: _getDemoBusinessName(businessType, context),
      email: username,
      phone: '+965 1234 5678',
      address: 'Kuwait City, Kuwait',
      latitude: 29.3759,
      longitude: 47.9774,
      offers: [],
      businessHours: {},
      settings: {},
      businessType: businessType,
    );
    return BusinessDashboard(
      business: business,
      onLanguageChanged: widget.onLanguageChanged,
    );
  }

  String _getDemoBusinessName(BusinessType type, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (type) {
      case BusinessType.store:
        return loc.demoStore;
      case BusinessType.pharmacy:
        return loc.demoPharmacy;
      case BusinessType.restaurant:
        return loc.demoRestaurant;
      case BusinessType.kitchen:
        return loc.demoKitchen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isTabletOrDesktop = ResponsiveHelper.isTablet(context) ||
        ResponsiveHelper.isDesktop(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final formWidth = isTabletOrDesktop
        ? (ResponsiveHelper.isDesktop(context) ? 400.0 : 500.0)
        : screenWidth;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.login),
        elevation: isTabletOrDesktop ? 0 : 1,
        backgroundColor: isTabletOrDesktop ? Colors.white : null,
        foregroundColor: isTabletOrDesktop ? Colors.black87 : null,
        actions: [
          LanguageSwitcher(
            onLanguageChanged: widget.onLanguageChanged,
            showAsIcon: true,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
            child: Container(
              width: formWidth,
              constraints: isTabletOrDesktop
                  ? const BoxConstraints(maxWidth: 500)
                  : null,
              child: Card(
                elevation: isTabletOrDesktop ? 8 : 0,
                shadowColor: isTabletOrDesktop ? Colors.black26 : null,
                shape: isTabletOrDesktop
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          loc.welcomeBack,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.signInToYourAccount,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 32),
                        WizzBusinessTextFormField(
                          controller: _emailController,
                          labelText: loc.email,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return loc.pleaseEnterYourEmail;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        WizzBusinessTextFormField(
                          controller: _passwordController,
                          labelText: loc.password,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return loc.pleaseEnterYourPassword;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        WizzBusinessButton(
                          onPressed: () {
                            if (_isLoading) return;
                            _login();
                          },
                          text: loc.login,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: Text(loc.forgotPasswordQuestion),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(loc.dontHaveAnAccount),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegistrationFormScreen(),
                                  ),
                                );
                              },
                              child: Text(loc.register),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
