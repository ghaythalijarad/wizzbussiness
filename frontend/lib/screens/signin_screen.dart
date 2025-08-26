import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_auth_service.dart';
import '../providers/session_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../screens/dashboards/business_dashboard.dart';
import 'signup_screen.dart';
// import 'forgot_password_page.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.login),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Email Field
                CustomTextField(
                  controller: _emailController,
                  labelText: l10n.email,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterYourEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  labelText: l10n.password,
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterYourPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Sign In Button
                CustomButton(
                  text: l10n.login,
                  onPressed: _isLoading ? null : _signIn,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 32),

                // Sign Up Link
                _buildSignUpLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.dontHaveAnAccount,
          style: TextStyle(color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const SignUpScreen()),
            );
          },
          child: Text(
            l10n.register,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    debugPrint('🎯 SIGNIN BUTTON PRESSED - Starting validation');

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      debugPrint('🔐 Starting login for: $email');

      final result = await AppAuthService.signIn(
        email: email,
        password: password,
      );

      debugPrint('📡 Login response received: ${result.success}');
      debugPrint('📄 Response user: ${result.user}');

      if (result.success) {
        debugPrint('✅ Login successful!');

        // AppAuthService now handles session state via Riverpod providers
        debugPrint('✅ Login successful, session state automatically updated');

        // Extract business data from the response
        final businessData =
            result.businesses.isNotEmpty ? result.businesses.first : null;
        final userData = result.user;

        debugPrint('🏢 Business data found: ${businessData != null}');

        if (businessData != null && mounted) {
          try {
            // Add user email to business data since API doesn't include it
            final businessWithEmail = Map<String, dynamic>.from(businessData);
            businessWithEmail['email'] = userData?['email'] ?? email;

            debugPrint('🔧 Modified business data: $businessWithEmail');

            final business = Business.fromJson(businessWithEmail);
            debugPrint(
                '✅ Business object created: ${business.name} (ID: ${business.id})');

            debugPrint('🚀 Navigating to BusinessDashboard...');

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const BusinessDashboard(),
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
          debugPrint('❌ No business data in response');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No business associated with this account'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        debugPrint('❌ Login failed: ${result.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result.message), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('💥 Login error: $e');
      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.loginFailedMessage),
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
  }
}
