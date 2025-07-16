import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../widgets/language_switcher.dart';
import '../widgets/wizz_business_text_form_field.dart';
import '../widgets/wizz_business_button.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/registration_form_screen.dart';
import '../screens/dashboards/business_dashboard.dart';
import '../services/app_auth_service.dart';
import '../models/business.dart';
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
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    debugPrint('🎯 LOGIN BUTTON PRESSED - Starting validation');

    if (_formKey.currentState!.validate()) {
      debugPrint('✅ Form validation passed');
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        debugPrint('🔐 Starting login for: $email');

        // Use AppAuthService for consistent authentication
        final response = await AppAuthService.signIn(
          email: email,
          password: password,
        );

        debugPrint('📡 Login response received: ${response.success}');
        debugPrint('📄 Response user: ${response.user}');

        if (response.success && mounted) {
          debugPrint(
              '🔍 Widget mounted: $mounted, Context valid: ${context.mounted}');
          final userData = response.user;
          debugPrint('👤 User data found: ${userData != null}');

          if (userData != null && response.businesses.isNotEmpty) {
            debugPrint('👤 User data: $userData');
            debugPrint(
                '🏢 Businesses available: ${response.businesses.length}');

            // Use first business from the businesses list
            final businessData =
                Map<String, dynamic>.from(response.businesses.first);
            businessData['email'] =
                businessData['email'] ?? userData['email'] ?? email;

            debugPrint('🏢 Business data used: $businessData');

            try {
              final business = Business.fromJson(businessData);
              debugPrint(
                  '✅ Business object created: ${business.name} (ID: ${business.id})');

              debugPrint('🚀 Attempting navigation...');

              final navigator = Navigator.of(context, rootNavigator: true);
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => BusinessDashboard(
                    business: business,
                    onLanguageChanged: widget.onLanguageChanged,
                    userData: userData,
                    businessesData: response.businesses,
                  ),
                ),
              );
              debugPrint('✅ Navigation completed');
            } catch (businessError) {
              debugPrint('💥 Error creating business object: $businessError');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating business: $businessError'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } else {
            debugPrint('❌ No user data or businesses in response');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'No business associated with this account. Please contact support.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else if (mounted) {
          debugPrint('❌ Login failed: ${response.message}');
          // Login failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        debugPrint('💥 Login error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorOccurred),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        debugPrint('🔄 Finally block - resetting loading state');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      debugPrint('❌ Form validation failed');
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
                          keyboardType: TextInputType.emailAddress,
                          inputFormatters: [
                            // Only allow English Latin letters, numbers, and email symbols
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9@._-]'),
                            ),
                          ],
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
                          obscureText: !_isPasswordVisible,
                          inputFormatters: [
                            // Only allow English Latin letters, numbers, and common password symbols
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9!@#$%^&*()_+=\-\[\]{}|;:,.<>?/~`]'),
                            ),
                          ],
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible 
                                ? Icons.visibility_off_rounded 
                                : Icons.visibility_rounded,
                              color: const Color(0xFF3399FF),
                              size: 22,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
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
                            debugPrint('🔘 LOGIN BUTTON TAPPED!');
                            if (_isLoading) {
                              debugPrint('⏳ Already loading, ignoring tap');
                              return;
                            }
                            debugPrint('🎬 Calling _login() method');
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
                                    const ForgotPasswordScreen(),
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
