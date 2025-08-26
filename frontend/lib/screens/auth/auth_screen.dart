import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../registration_form_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/language_provider_riverpod.dart';
import '../../providers/auth_provider_riverpod.dart';
import '../../services/app_auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Login form
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _obscureLoginPassword = true;
  
  // Forgot password form
  final _forgotPasswordFormKey = GlobalKey<FormState>();
  final _forgotPasswordEmailController = TextEditingController();
  final _forgotPasswordCodeController = TextEditingController();
  final _forgotPasswordNewPasswordController = TextEditingController();
  final _forgotPasswordConfirmPasswordController = TextEditingController();
  bool _forgotPasswordSent = false;
  bool _obscureForgotPasswordNewPassword = true;
  bool _obscureForgotPasswordConfirmPassword = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _forgotPasswordEmailController.dispose();
    _forgotPasswordCodeController.dispose();
    _forgotPasswordNewPasswordController.dispose();
    _forgotPasswordConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with logo and title
            _buildHeader(),
            
            // Tab bar
            _buildTabBar(),
            
            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginTab(),
                  _buildSignupTab(),
                  _buildForgotPasswordTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    final localizations = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24.0, 48.0, 24.0, 32.0),
      child: Column(
        children: [
          // Language toggle button at the top right
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final currentLocale = ref.watch(languageProviderRiverpod);
                  final languageNotifier = ref.read(languageProviderRiverpod.notifier);
                  return IconButton(
                    onPressed: () {
                      languageNotifier.toggleLanguage();
                    },
                    icon: Icon(
                      Icons.language,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: currentLocale.languageCode == 'en' ? 'العربية' : 'English',
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            localizations.appTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Restaurant Management System',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabBar() {
    final localizations = AppLocalizations.of(context)!;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: Theme.of(context).textTheme.labelLarge,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: localizations.login),
          Tab(text: localizations.signUp),
          Tab(text: localizations.reset),
        ],
      ),
    );
  }
  
  Widget _buildLoginTab() {
    final localizations = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            
            Text(
              localizations.welcomeBack,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              localizations.signInToYourAccount,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // Email field
            TextFormField(
              controller: _loginEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: localizations.email,
                hintText: localizations.enterYourEmail,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Password field
            TextFormField(
              controller: _loginPasswordController,
              obscureText: _obscureLoginPassword,
              decoration: InputDecoration(
                labelText: localizations.password,
                hintText: localizations.enterYourPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureLoginPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureLoginPassword = !_obscureLoginPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Login button
            FilledButton(
              onPressed: () => _handleLogin(),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(localizations.signIn),
            ),
            

          ],
        ),
      ),
    );
  }
  
  Widget _buildSignupTab() {
    final localizations = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 80),
          
          // Icon
          Icon(
            Icons.business_center,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          
          const SizedBox(height: 32),
          
          Text(
            localizations.createBusinessAccount,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          Text(
            localizations.joinThousandsOfBusinessOwners,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          // Features list
          _buildFeatureItem(
            Icons.store,
            localizations.completeBusinessRegistration,
            localizations.setUpYourBusinessProfileWithAllNecessaryInformationAndDocuments,
          ),
          
          const SizedBox(height: 20),
          
          _buildFeatureItem(
            Icons.verified_user,
            localizations.secureAndVerified,
            localizations.yourBusinessWillBeVerifiedBeforeActivationForSecurityAndTrust,
          ),
          
          const SizedBox(height: 20),
          
          _buildFeatureItem(
            Icons.dashboard,
            localizations.fullDashboardAccess,
            localizations.manageOrdersProductsAnalyticsAndBusinessSettingsInOnePlace,
          ),
          
          const SizedBox(height: 48),
          
          // Create account button
          FilledButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegistrationFormScreen(),
                ),
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              localizations.startBusinessRegistration,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Terms and conditions
          Text(
            localizations.byCreatingAnAccountYouAgreeToOurTermsOfServiceAndPrivacyPolicy,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildForgotPasswordTab() {
    final localizations = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _forgotPasswordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            
            // Icon
            Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _forgotPasswordSent ? Icons.mark_email_read : Icons.lock_reset,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            
            Text(
              _forgotPasswordSent ? 'Check Your Email' : localizations.resetPassword,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _forgotPasswordSent 
                ? 'We\'ve sent a verification code to your email address. Please enter the code below along with your new password.'
                : 'Enter your email address and we\'ll send you a verification code to reset your password.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            if (!_forgotPasswordSent) ...[
              // Email field
              TextFormField(
                controller: _forgotPasswordEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: localizations.email,
                  hintText: 'Enter your registered email',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Send verification code button
              FilledButton(
                onPressed: () => _handleForgotPassword(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Send Verification Code'),
              ),
            ] else ...[
              // Verification code field
              TextFormField(
                controller: _forgotPasswordCodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  hintText: 'Enter 6-digit code',
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Verification code is required';
                  }
                  if (value.length != 6) {
                    return 'Code must be 6 digits';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // New password field
              TextFormField(
                controller: _forgotPasswordNewPasswordController,
                obscureText: _obscureForgotPasswordNewPassword,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter your new password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureForgotPasswordNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureForgotPasswordNewPassword = !_obscureForgotPasswordNewPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'New password is required';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Confirm password field
              TextFormField(
                controller: _forgotPasswordConfirmPasswordController,
                obscureText: _obscureForgotPasswordConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your new password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureForgotPasswordConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureForgotPasswordConfirmPassword = !_obscureForgotPasswordConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _forgotPasswordNewPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Reset password button
              FilledButton(
                onPressed: () => _handleConfirmForgotPassword(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Reset Password'),
              ),
              
              const SizedBox(height: 16),
              
              // Resend code button
              OutlinedButton(
                onPressed: () => _handleResendEmail(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Resend Code'),
              ),
              
              const SizedBox(height: 16),
              
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _forgotPasswordSent = false;
                    _forgotPasswordEmailController.clear();
                    _forgotPasswordCodeController.clear();
                    _forgotPasswordNewPasswordController.clear();
                    _forgotPasswordConfirmPasswordController.clear();
                  });
                  _tabController.animateTo(0); // Go back to login
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Back to login'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  void _handleLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      final email = _loginEmailController.text.trim();
      final password = _loginPasswordController.text.trim();
      
      // Show loading with shorter duration
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Signing in...'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 10), // Reduced from 30 to 10 seconds
        ),
      );
      
      try {
        final authNotifier = ref.read(authProviderRiverpod.notifier);
        
        await authNotifier.signIn(
          email: email,
          password: password,
        );
        
        final authState = ref.read(authProviderRiverpod);
        
        if (mounted) {
          // Hide loading snackbar immediately
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          if (authState.isAuthenticated) {
            // Success - show brief success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Login successful! Welcome back.'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
            // Navigation will be handled automatically by the main app based on auth state
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authState.errorMessage ?? 'Failed to sign in'),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          // Hide loading snackbar
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }
  
  void _handleForgotPassword() async {
    if (_forgotPasswordFormKey.currentState!.validate()) {
      final email = _forgotPasswordEmailController.text.trim();
      
      try {
        // First check user status before sending reset code
        final userStatus = await AppAuthService.checkUserStatus(email: email);
        
        if (mounted) {
          if (userStatus.exists && userStatus.isConfirmed) {
            // Account exists and is confirmed - proceed with password reset
            final result = await AppAuthService.forgotPassword(email: email);
            
            if (result.success) {
              setState(() {
                _forgotPasswordSent = true;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Verification code sent to $email'),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.message.isNotEmpty ? result.message : 'Failed to send verification code'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          } else if (userStatus.exists && !userStatus.isConfirmed) {
            // Account exists but is not confirmed - navigate to comprehensive registration for email verification
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegistrationFormScreen(),
              ),
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Your account exists but is not verified. Please complete the registration process including email verification.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          } else {
            // Account doesn't exist - navigate to comprehensive registration
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegistrationFormScreen(),
              ),
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No account found with this email. Please complete business registration to create an account.'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
  
  void _handleConfirmForgotPassword() async {
    if (_forgotPasswordFormKey.currentState!.validate()) {
      final email = _forgotPasswordEmailController.text.trim();
      final code = _forgotPasswordCodeController.text.trim();
      final newPassword = _forgotPasswordNewPasswordController.text.trim();
      
      try {
        final result = await AppAuthService.confirmForgotPassword(
          email: email,
          confirmationCode: code,
          newPassword: newPassword,
        );
        
        if (mounted) {
          if (result.success) {
            // Reset the form and go back to login
            setState(() {
              _forgotPasswordSent = false;
              _forgotPasswordEmailController.clear();
              _forgotPasswordCodeController.clear();
              _forgotPasswordNewPasswordController.clear();
              _forgotPasswordConfirmPasswordController.clear();
            });
            _tabController.animateTo(0); // Go back to login tab
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password reset successfully! You can now sign in with your new password.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message.isNotEmpty ? result.message : 'Failed to reset password'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
  
  void _handleResendEmail() async {
    final email = _forgotPasswordEmailController.text.trim();
    if (email.isNotEmpty) {
      try {
        final result = await AppAuthService.forgotPassword(email: email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.success 
                ? 'Verification code sent again!'
                : 'Failed to resend code: ${result.message}'),
              backgroundColor: result.success ? Colors.green : Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to resend code: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
  
  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
