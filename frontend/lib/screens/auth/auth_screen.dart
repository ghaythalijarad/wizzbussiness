import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../registration_form_screen.dart';
import '../merchant_status_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/language_provider_riverpod.dart';
import '../../providers/auth_provider_riverpod.dart';
import '../../providers/session_provider.dart';
import '../../providers/business_provider.dart';
import '../../services/app_auth_service.dart';
import '../../models/business.dart';
import '../../core/design_system/golden_ratio_constants.dart';
import '../../core/design_system/typography_system.dart';
import '../../core/theme/app_colors.dart';

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
      backgroundColor: AppColors.backgroundVariant,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.secondary.withOpacity(0.03),
              AppColors.background,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with logo and title
              _buildModernHeader(),

              // Tab bar
              _buildModernTabBar(),

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
      ),
    );
  }
  
  Widget _buildModernHeader() {
    final localizations = AppLocalizations.of(context)!;
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        GoldenRatio.spacing24, 
        GoldenRatio.xl, 
        GoldenRatio.spacing24, 
        GoldenRatio.spacing20
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.04),
            blurRadius: GoldenRatio.spacing12,
            offset: Offset(0, GoldenRatio.spacing4),
          ),
        ],
      ),
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
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        languageNotifier.toggleLanguage();
                      },
                      icon: Icon(
                        Icons.language,
                        color: AppColors.primary,
                        size: GoldenRatio.spacing20,
                      ),
                      tooltip: currentLocale.languageCode == 'en'
                          ? 'العربية'
                          : 'English',
                    ),
                  );
                },
              ),
            ],
          ),
          
          SizedBox(height: GoldenRatio.spacing16),
          
          // Title
          Text(
            localizations.appTitle,
            style: TypographySystem.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          
          SizedBox(height: GoldenRatio.spacing8),
          
          Text(
            'Restaurant Management System',
            style: TypographySystem.bodyLarge.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModernTabBar() {
    final localizations = AppLocalizations.of(context)!;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: GoldenRatio.spacing24),
      padding: EdgeInsets.all(GoldenRatio.spacing4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            blurRadius: GoldenRatio.spacing16,
            offset: Offset(0, GoldenRatio.spacing4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: GoldenRatio.spacing8,
              offset: Offset(0, GoldenRatio.spacing4),
            ),
          ],
        ),
        labelColor: AppColors.onPrimary,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        labelStyle: TypographySystem.labelLarge.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TypographySystem.labelLarge.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        overlayColor: MaterialStateProperty.all(Colors.transparent),
        tabs: [
          Tab(
            height: GoldenRatio.xl + GoldenRatio.spacing8,
            text: localizations.login,
          ),
          Tab(
            height: GoldenRatio.xl + GoldenRatio.spacing8,
            text: localizations.signUp,
          ),
          Tab(
            height: GoldenRatio.xl + GoldenRatio.spacing8,
            text: localizations.reset,
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoginTab() {
    final localizations = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(GoldenRatio.spacing24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: GoldenRatio.spacing20),
            
            // Welcome Section
            Container(
              padding: EdgeInsets.all(GoldenRatio.spacing24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    AppColors.secondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    localizations.welcomeBack,
                    style: TypographySystem.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: GoldenRatio.spacing8),
                  Text(
                    localizations.signInToYourAccount,
                    style: TypographySystem.bodyLarge.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: GoldenRatio.xl),
            
            // Email field
            _buildModernTextField(
              controller: _loginEmailController,
              label: localizations.email,
              hint: localizations.enterYourEmail,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
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
            
            SizedBox(height: GoldenRatio.spacing20),
            
            // Password field
            _buildModernTextField(
              controller: _loginPasswordController,
              label: localizations.password,
              hint: localizations.enterYourPassword,
              icon: Icons.lock_outline,
              obscureText: _obscureLoginPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureLoginPassword = !_obscureLoginPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            
            SizedBox(height: GoldenRatio.xl),
            
            // Login button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: GoldenRatio.spacing16,
                    offset: Offset(0, GoldenRatio.spacing8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleLogin(),
                  borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: GoldenRatio.spacing18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.login,
                          color: AppColors.onPrimary,
                          size: GoldenRatio.spacing20,
                        ),
                        SizedBox(width: GoldenRatio.spacing12),
                        Text(
                          localizations.signIn,
                          style: TypographySystem.titleMedium.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: GoldenRatio.spacing24),

          ],
        ),
      ),
    );
  }
  
  Widget _buildSignupTab() {
    final localizations = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(GoldenRatio.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: GoldenRatio.xl),
          
          // Business Icon with modern styling
          Container(
            padding: EdgeInsets.all(GoldenRatio.spacing24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.08),
                  blurRadius: GoldenRatio.spacing20,
                  offset: Offset(0, GoldenRatio.spacing8),
                ),
              ],
            ),
            child: Icon(
              Icons.business_center,
              size: GoldenRatio.xxxl,
              color: AppColors.primary,
            ),
          ),
          
          SizedBox(height: GoldenRatio.spacing20),
          
          // Header Section
          Container(
            padding: EdgeInsets.all(GoldenRatio.spacing24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.05),
                  AppColors.secondary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  localizations.createBusinessAccount,
                  style: TypographySystem.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: GoldenRatio.spacing12),
                Text(
                  localizations.joinThousandsOfBusinessOwners,
                  style: TypographySystem.bodyLarge.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          SizedBox(height: GoldenRatio.xl),
          
          // Features list with modern cards
          _buildModernFeatureItem(
            Icons.store,
            localizations.completeBusinessRegistration,
            localizations.setUpYourBusinessProfileWithAllNecessaryInformationAndDocuments,
            AppColors.primary,
          ),
          
          SizedBox(height: GoldenRatio.spacing20),
          
          _buildModernFeatureItem(
            Icons.verified_user,
            localizations.secureAndVerified,
            localizations.yourBusinessWillBeVerifiedBeforeActivationForSecurityAndTrust,
            AppColors.secondary,
          ),
          
          SizedBox(height: GoldenRatio.spacing20),
          
          _buildModernFeatureItem(
            Icons.dashboard,
            localizations.fullDashboardAccess,
            localizations.manageOrdersProductsAnalyticsAndBusinessSettingsInOnePlace,
            AppColors.success,
          ),
          
          SizedBox(height: GoldenRatio.xl),
          
          // Create account button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.secondary, AppColors.secondaryDark],
              ),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.3),
                  blurRadius: GoldenRatio.spacing16,
                  offset: Offset(0, GoldenRatio.spacing8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistrationFormScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: GoldenRatio.spacing18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_center,
                        color: AppColors.onSecondary,
                        size: GoldenRatio.spacing20,
                      ),
                      SizedBox(width: GoldenRatio.spacing12),
                      Text(
                        localizations.startBusinessRegistration,
                        style: TypographySystem.titleMedium.copyWith(
                          color: AppColors.onSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(height: GoldenRatio.spacing24),
          
          // Terms and conditions
          Container(
            padding: EdgeInsets.all(GoldenRatio.spacing16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              localizations
                  .byCreatingAnAccountYouAgreeToOurTermsOfServiceAndPrivacyPolicy,
              style: TypographySystem.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          SizedBox(height: GoldenRatio.spacing24),
        ],
      ),
    );
  }
  
  Widget _buildForgotPasswordTab() {
    final localizations = AppLocalizations.of(context)!;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(GoldenRatio.spacing24),
      child: Form(
        key: _forgotPasswordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: GoldenRatio.spacing20),
            
            // Icon with modern styling
            Container(
              padding: EdgeInsets.all(GoldenRatio.spacing24),
              margin: EdgeInsets.only(bottom: GoldenRatio.spacing24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.08),
                    blurRadius: GoldenRatio.spacing20,
                    offset: Offset(0, GoldenRatio.spacing8),
                  ),
                ],
              ),
              child: Icon(
                _forgotPasswordSent ? Icons.mark_email_read : Icons.lock_reset,
                size: GoldenRatio.xxxl,
                color: AppColors.primary,
              ),
            ),
            
            // Header Section
            Container(
              padding: EdgeInsets.all(GoldenRatio.spacing24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    AppColors.secondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _forgotPasswordSent
                        ? 'Check Your Email'
                        : localizations.resetPassword,
                    style: TypographySystem.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: GoldenRatio.spacing12),
                  Text(
                    _forgotPasswordSent
                        ? 'We\'ve sent a verification code to your email address. Please enter the code below along with your new password.'
                        : 'Enter your email address and we\'ll send you a verification code to reset your password.',
                    style: TypographySystem.bodyLarge.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            SizedBox(height: GoldenRatio.xl),
            
            if (!_forgotPasswordSent) ...[
              // Email field
              _buildModernTextField(
                controller: _forgotPasswordEmailController,
                label: localizations.email,
                hint: 'Enter your registered email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
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
              
              SizedBox(height: GoldenRatio.xl),
              
              // Send verification code button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning,
                      AppColors.warning.withOpacity(0.8)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withOpacity(0.3),
                      blurRadius: GoldenRatio.spacing16,
                      offset: Offset(0, GoldenRatio.spacing8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleForgotPassword(),
                    borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: GoldenRatio.spacing18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: Colors.white,
                            size: GoldenRatio.spacing20,
                          ),
                          SizedBox(width: GoldenRatio.spacing12),
                          Text(
                            'Send Verification Code',
                            style: TypographySystem.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Verification code field
              _buildModernTextField(
                controller: _forgotPasswordCodeController,
                label: 'Verification Code',
                hint: 'Enter 6-digit code',
                icon: Icons.vpn_key,
                keyboardType: TextInputType.number,
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
              
              SizedBox(height: GoldenRatio.spacing20),
              
              // New password field
              _buildModernTextField(
                controller: _forgotPasswordNewPasswordController,
                label: 'New Password',
                hint: 'Enter your new password',
                icon: Icons.lock_outline,
                obscureText: _obscureForgotPasswordNewPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureForgotPasswordNewPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureForgotPasswordNewPassword =
                          !_obscureForgotPasswordNewPassword;
                    });
                  },
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
              
              SizedBox(height: GoldenRatio.spacing20),
              
              // Confirm password field
              _buildModernTextField(
                controller: _forgotPasswordConfirmPasswordController,
                label: 'Confirm Password',
                hint: 'Confirm your new password',
                icon: Icons.lock_outline,
                obscureText: _obscureForgotPasswordConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureForgotPasswordConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.primary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureForgotPasswordConfirmPassword =
                          !_obscureForgotPasswordConfirmPassword;
                    });
                  },
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
              
              SizedBox(height: GoldenRatio.xl),
              
              // Reset password button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success,
                      AppColors.success.withOpacity(0.8)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.3),
                      blurRadius: GoldenRatio.spacing16,
                      offset: Offset(0, GoldenRatio.spacing8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleConfirmForgotPassword(),
                    borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: GoldenRatio.spacing18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: GoldenRatio.spacing20,
                          ),
                          SizedBox(width: GoldenRatio.spacing12),
                          Text(
                            'Reset Password',
                            style: TypographySystem.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: GoldenRatio.spacing20),
              
              // Resend code button
              TextButton.icon(
                onPressed: () => _handleResendEmail(),
                icon: Icon(
                  Icons.refresh,
                  color: AppColors.primary,
                  size: GoldenRatio.spacing18,
                ),
                label: Text(
                  'Resend Code',
                  style: TypographySystem.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            
            SizedBox(height: GoldenRatio.spacing24),
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
          duration: const Duration(seconds: 10),
        ),
      );
      
      try {
        debugPrint('🔐 AuthScreen: Starting login for: $email');

        // Use AppAuthService for consistent authentication and token storage
        final response = await AppAuthService.signIn(
          email: email,
          password: password,
        );

        debugPrint('📡 AuthScreen: Login response received: ${response.success}');

        if (mounted) {
          // Hide loading snackbar immediately
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          if (response.success) {
            debugPrint('✅ AuthScreen: Login successful, updating auth state');

            // CRITICAL: Update auth provider to reflect authenticated state
            ref.read(authProviderRiverpod.notifier).setAuthenticatedState();
            
            // CRITICAL: Store business session with full business data to avoid API call
            if (response.businesses.isNotEmpty) {
              final business = response.businesses.first;
              final businessId = business['businessId'];
              if (businessId != null) {
                debugPrint('📦 AuthScreen: Storing business data in session: $businessId');
                debugPrint('📦 AuthScreen: Business data keys: ${business.keys}');
                
                // Use setSessionWithBusinessData to store complete business info
                ref.read(sessionProvider.notifier).setSessionWithBusinessData(businessId, business);
                
                // Invalidate business provider to trigger refresh
                ref.invalidate(businessProvider);
              }
            }
            
            // Success - show brief success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Login successful! Welcome back.'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
            
            debugPrint('✅ AuthScreen: Auth state updated, AuthWrapper will handle authorization routing');
          } else {
            debugPrint('❌ AuthScreen: Login failed: ${response.message}');
            
            // Check if this is a pending status case
            if (response.accountStatus == 'pending') {
              debugPrint('⏸️ AuthScreen: Account pending - navigating to status screen');
              
              // Create a mock business object for the status screen
              final Business mockBusiness = Business(
                id: 'pending_business',
                name: 'Pending Business',
                email: email,
                status: 'pending',
                businessType: BusinessType.restaurant,
                address: '',
                phone: '',
                city: '',
                district: '',
                country: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              // Navigate to MerchantStatusScreen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => MerchantStatusScreen(
                    status: 'pending',
                    business: mockBusiness,
                  ),
                ),
                (route) => false,
              );
              return;
            }
            
            // Show error message for other cases
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message.isNotEmpty ? response.message : 'Failed to sign in'),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('💥 AuthScreen: Login error: $e');
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

  Widget _buildModernFeatureItem(
      IconData icon, String title, String description, Color color) {
    return Container(
      padding: EdgeInsets.all(GoldenRatio.spacing20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.04),
            blurRadius: GoldenRatio.spacing12,
            offset: Offset(0, GoldenRatio.spacing4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(GoldenRatio.spacing16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: GoldenRatio.spacing24,
            ),
          ),
          SizedBox(width: GoldenRatio.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TypographySystem.titleMedium.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: GoldenRatio.spacing4),
                Text(
                  description,
                  style: TypographySystem.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.04),
            blurRadius: GoldenRatio.spacing8,
            offset: Offset(0, GoldenRatio.spacing4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: TypographySystem.bodyLarge.copyWith(
          color: AppColors.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: EdgeInsets.all(GoldenRatio.spacing12),
            padding: EdgeInsets.all(GoldenRatio.spacing8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: GoldenRatio.spacing20,
            ),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          labelStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: GoldenRatio.spacing20,
            vertical: GoldenRatio.spacing16,
          ),
        ),
      ),
    );
  }
}
