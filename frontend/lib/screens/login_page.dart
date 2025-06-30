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

        // Attempt real login
        var response = await AuthService.login(email, password);
        bool isTest = false;

        // If real login fails, attempt test login for local development
        if (response['success'] != true) {
          final testResp = await AuthService.testLogin(email, password);
          if (testResp['success'] == true) {
            response = testResp;
            isTest = true;
          }
        }

        if (response['success'] == true) {
          // Store and print token
          final accessToken = response['access_token'];
          print('Login successful, access token: $accessToken');

          if (isTest) {
            // Fetch test user profile
            final profileResp = await AuthService.testGetCurrentUser();
            if (profileResp['success'] == true) {
              final user = profileResp['user'];
              // Build business from test profile
              final business = Business(
                id: user['id'],
                name: user['business_name'],
                email: user['email'],
                phone: user['phone_number'] ?? '',
                address: AppLocalizations.of(context)!.notAvailable,
                latitude: 0.0,
                longitude: 0.0,
                offers: [],
                businessHours: {},
                settings: {},
                businessType: _getBusinessTypeFromString(user['business_type']),
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
              return;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(profileResp['message'] ??
                      AppLocalizations.of(context)!.failedToFetchProfile),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            // Real login: fetch user's businesses
            final apiService = ApiService();
            final businesses = await apiService.getUserBusinesses();

            if (businesses.isNotEmpty) {
              // Existing flow unchanged
              final businessData = businesses[0];
              final business = Business(
                id: businessData['id'],
                name: businessData['name'],
                email: businessData['email'] ?? email,
                phone: businessData['phone_number'] ?? '',
                address: businessData['address']?['street'] ?? '',
                latitude:
                    businessData['address']?['latitude']?.toDouble() ?? 0.0,
                longitude:
                    businessData['address']?['longitude']?.toDouble() ?? 0.0,
                offers: [],
                businessHours: {},
                settings: {},
                businessType:
                    _getBusinessTypeFromString(businessData['business_type']),
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
              // No businesses
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      AppLocalizations.of(context)!.noBusinessFoundForThisUser),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          // All login attempts failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ??
                  AppLocalizations.of(context)!.loginFailedMessage),
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
