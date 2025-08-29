import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';
import '../core/theme/app_colors.dart';
import '../widgets/language_switcher.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/registration_form_screen.dart';
import '../services/app_auth_service.dart';
import '../providers/session_provider.dart';
import '../providers/business_provider.dart';
import '../providers/auth_provider_riverpod.dart';
import '../models/business.dart';
import '../utils/responsive_helper.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
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
    final loc = AppLocalizations.of(context)!;

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

          // AppAuthService now handles session state via Riverpod providers
          debugPrint('✅ Login successful, session state automatically updated');

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

              debugPrint('🚀 Login successful, updating session and letting AuthWrapper handle routing');

              // CRITICAL: Update auth provider to reflect authenticated state
              ref.read(authProviderRiverpod.notifier).setAuthenticatedState();
              
              // Update session with selected business and refresh provider
              ref.read(sessionProvider.notifier).setSession(business.id);
              ref.invalidate(businessProvider);

              debugPrint('✅ Auth provider and session updated, AuthWrapper will handle authorization routing');
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
          // Enhanced user-friendly error categorization
          String errorMsg = _categorizeLoginError(response.message, loc);
          
          debugPrint('📝 Categorized error message: $errorMsg');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
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

  /// Categorizes login errors into user-friendly messages
  String _categorizeLoginError(String errorMessage, AppLocalizations loc) {
    final message = errorMessage.toLowerCase();

    // Authentication/Credential Errors (most common)
    if (message.contains('password') ||
        message.contains('email') ||
        message.contains('incorrect') ||
        message.contains('invalid') ||
        message.contains('unauthorized') ||
        message.contains('authentication') ||
        message.contains('credentials') ||
        message.contains('not found') ||
        message.contains('user not found') ||
        message.contains('wrong') ||
        message.contains('401')) {
      return loc.errorInvalidCredentials;
    }

    // Account Status Errors
    if (message.contains('not confirmed') ||
        message.contains('unconfirmed') ||
        message.contains('verify') ||
        message.contains('verification')) {
      return 'Your account is not verified. Please check your email for the verification code.';
    }

    if (message.contains('disabled') ||
        message.contains('suspended') ||
        message.contains('banned')) {
      return 'Your account has been disabled. Please contact support for assistance.';
    }

    // Rate Limiting
    if (message.contains('too many') ||
        message.contains('rate limit') ||
        message.contains('attempts') ||
        message.contains('429')) {
      return 'Too many login attempts. Please wait a few minutes and try again.';
    }

    // Network Errors
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('unreachable')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    // Server Errors
    if (message.contains('server') ||
        message.contains('500') ||
        message.contains('503') ||
        message.contains('maintenance')) {
      return 'Server is temporarily unavailable. Please try again later.';
    }

    // Default to credential error for security (don't reveal system details)
    return loc.errorInvalidCredentials;
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        inputFormatters: inputFormatters,
        style: TypographySystem.bodyLarge.copyWith(
          color: AppColors.onSurface,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: AppColors.primary,
            size: GoldenRatio.md,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.onSurfaceVariant.withOpacity(0.3),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.onSurfaceVariant.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: GoldenRatio.spacing16,
            vertical: GoldenRatio.spacing16,
          ),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: GoldenRatio.spacing16,
        vertical: GoldenRatio.spacing12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              padding: EdgeInsets.zero,
            ),
          Expanded(
            child: Text(
              loc.login,
              style: TypographySystem.headlineSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          LanguageSwitcher(showText: false),
        ],
      ),
    );
  }

  Widget _buildLoginCard(
      BuildContext context, AppLocalizations loc, bool isTabletOrDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(GoldenRatio.spacing16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(GoldenRatio.spacing24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
              _buildHeaderSection(context, loc),
              SizedBox(height: GoldenRatio.spacing24),

              // Email Field
              _buildModernTextField(
                controller: _emailController,
                labelText: loc.email,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [
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
              SizedBox(height: GoldenRatio.spacing16),

              // Password Field
              _buildModernTextField(
                controller: _passwordController,
                labelText: loc.password,
                prefixIcon: Icons.lock_outlined,
                obscureText: !_isPasswordVisible,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Z0-9!@#$%^&*()_+=\-\[\]{}|;:,.<>?/~`]'),
                  ),
                ],
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.primary,
                    size: GoldenRatio.md,
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
              SizedBox(height: GoldenRatio.spacing24),

              // Login Button
              _buildLoginButton(context, loc),
              SizedBox(height: GoldenRatio.spacing16),

              // Forgot Password Link
              _buildForgotPasswordLink(context, loc),
              SizedBox(height: GoldenRatio.spacing16),

              // Sign Up Link
              _buildSignUpLink(context, loc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, AppLocalizations loc) {
    return Column(
      children: [
        Container(
          width: GoldenRatio.xxxl,
          height: GoldenRatio.xxxl,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.business,
            color: Colors.white,
            size: GoldenRatio.xl,
          ),
        ),
        SizedBox(height: GoldenRatio.spacing16),
        Text(
          loc.welcomeBack,
          style: TypographySystem.headlineMedium.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: GoldenRatio.spacing8),
        Text(
          loc.signInToYourAccount,
          style: TypographySystem.bodyLarge.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context, AppLocalizations loc) {
    return Container(
      width: double.infinity,
      height: GoldenRatio.spacing20 * 2.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
          onTap: _isLoading
              ? null
              : () {
                  debugPrint('🔘 LOGIN BUTTON TAPPED!');
                  if (_isLoading) {
                    debugPrint('⏳ Already loading, ignoring tap');
                    return;
                  }
                  debugPrint('🎬 Calling _login() method');
                  _login();
                },
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: GoldenRatio.md,
                    height: GoldenRatio.md,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    loc.login,
                    style: TypographySystem.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink(BuildContext context, AppLocalizations loc) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ForgotPasswordScreen(),
          ),
        );
      },
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: TypographySystem.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text(loc.forgotPasswordQuestion),
    );
  }

  Widget _buildSignUpLink(BuildContext context, AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          loc.dontHaveAnAccount,
          style: TypographySystem.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegistrationFormScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: TypographySystem.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Text(loc.register),
        ),
      ],
    );
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(GoldenRatio.spacing20 * 2.5),
        child: _buildModernAppBar(context, loc),
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
              child: _buildLoginCard(context, loc, isTabletOrDesktop),
            ),
          ),
        ),
      ),
    );
  }
}
