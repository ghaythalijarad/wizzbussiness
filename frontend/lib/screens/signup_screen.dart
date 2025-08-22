import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_auth_service.dart';
import '../services/api_service.dart';
import '../models/business_subcategory.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'signin_screen.dart';
import 'email_verification_screen.dart';
import '../l10n/app_localizations.dart';
import '../utils/latin_number_formatter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Address controllers
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedBusinessType = 'restaurant';
  bool _agreedToTerms = false;
  int _currentStep = 0;

  final List<String> _businessTypes = [
    'restaurant',
    'store',
    'cafe',
    'bakery',
    'cloudkitchen',
    'pharmacy',
    'herbalspices',
    'cosmetics',
    'betshop',
  ];

  List<BusinessSubcategory> _availableSubcategories = [];
  final Set<String> _selectedSubcategoryIds = <String>{};

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSubcategoriesForType(_selectedBusinessType);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.register),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 32),

                // Progress indicator
                _buildProgressIndicator(),
                const SizedBox(height: 32),

                // Form content based on current step
                _buildFormContent(),
                const SizedBox(height: 32),

                // Navigation buttons
                _buildNavigationButtons(),
                const SizedBox(height: 24),

                // Sign in link
                _buildSignInLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Text(
          l10n.joinOrderReceiver,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.signUpSubtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= _currentStep
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildFormContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildBusinessInfoStep();
      case 2:
        return _buildAccountSecurityStep();
      default:
        return _buildPersonalInfoStep();
    }
  }

  Widget _buildPersonalInfoStep() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.personalInformation,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _fullNameController,
          labelText: l10n.ownerName,
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.pleaseEnterOwnerName;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          labelText: l10n.emailAddress,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.emailRequired;
            }
            if (!_isValidEmail(value!)) {
              return l10n.invalidEmailFormat;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _phoneController,
          labelText: l10n.phoneNumber,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          inputFormatters: [LatinNumberInputFormatter()],
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.phoneNumberRequired;
            }
            return LatinPhoneValidator.validate(value);
          },
        ),
      ],
    );
  }

  Widget _buildBusinessInfoStep() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.businessInformation,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _businessNameController,
          labelText: l10n.businessName,
          prefixIcon: Icons.store_outlined,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.businessNameRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedBusinessType,
          decoration: InputDecoration(
            labelText: l10n.businessType,
            prefixIcon: const Icon(Icons.business_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: _businessTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getBusinessTypeLabel(type)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedBusinessType = value!);
            _loadSubcategoriesForType(_selectedBusinessType);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.selectBusinessType;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        if (_availableSubcategories.isNotEmpty) ...[
          Text('Business Subcategories (optional)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSubcategories.map((sub) {
              final selected =
                  _selectedSubcategoryIds.contains(sub.subcategoryId);
              final label = Localizations.localeOf(context).languageCode == 'ar'
                  ? sub.nameAr
                  : sub.nameEn;
              return FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedSubcategoryIds.add(sub.subcategoryId);
                    } else {
                      _selectedSubcategoryIds.remove(sub.subcategoryId);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          l10n.businessAddress,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _streetController,
          labelText: l10n.streetAddress,
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CustomTextField(
                controller: _cityController,
                labelText: l10n.city,
                prefixIcon: Icons.location_city_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _stateController,
                labelText: l10n.state,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountSecurityStep() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountSecurity,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          labelText: l10n.password,
          prefixIcon: Icons.lock_outlined,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.passwordRequired;
            }
            if (!_isValidPassword(value!)) {
              return l10n.weakPassword;
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Text(
            _getPasswordRequirements(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
            ),
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _confirmPasswordController,
          labelText: l10n.confirmPassword,
          prefixIcon: Icons.lock_outlined,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword
                ? Icons.visibility_off
                : Icons.visibility),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return l10n.confirmPasswordRequired;
            }
            if (value != _passwordController.text) {
              return l10n.passwordsDoNotMatch;
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          value: _agreedToTerms,
          onChanged: (value) {
            setState(() {
              _agreedToTerms = value ?? false;
            });
          },
          title: Text(
            '${l10n.iAgreeToThe}${l10n.termsOfService} ${l10n.and} ${l10n.privacyPolicy}.',
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: CustomButton(
              text: l10n.back,
              onPressed: _isLoading ? null : _previousStep,
              isOutlined: true,
            ),
          ),
          const SizedBox(width: 16),
        ],
        Expanded(
          flex: _currentStep > 0 ? 1 : 1,
          child: CustomButton(
            text: _currentStep == 2 ? l10n.register : l10n.next,
            onPressed: _isLoading ? null : _nextStep,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInLink() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.alreadyHaveAccount,
          style: TextStyle(color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignInScreen()),
            );
          },
          child: Text(
            'Sign In',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _nextStep() async {
    if (_currentStep < 2) {
      if (_validateCurrentStep()) {
        // Async email availability pre-check on step 0
        if (_currentStep == 0) {
          final l10n = AppLocalizations.of(context)!;
          final email = _emailController.text.trim();
          try {
            setState(() => _isLoading = true);
            print('🧪 EMAIL DEBUG (signup): Pre-check availability for "$email"');
            final emailCheck = await AppAuthService.checkEmailExists(email: email);
            print('🧪 EMAIL DEBUG (signup): Exists=${emailCheck.exists} message=${emailCheck.message}');

            if (emailCheck.exists) {
              setState(() => _isLoading = false);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    emailCheck.message.isNotEmpty
                        ? emailCheck.message
                        : l10n.emailAlreadyInUse,
                  ),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: l10n.loginInstead,
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                      );
                    },
                  ),
                ),
              );
              return; // stop progression
            }
          } catch (e) {
            print('⚠️ EMAIL DEBUG (signup): Availability check failed: $e');
            // Non-blocking on network issues
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        }

        setState(() {
          _currentStep++;
        });
        _scrollToTop();
      }
    } else {
      _submitForm();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _validatePersonalInfo();
      case 1:
        return _validateBusinessInfo();
      case 2:
        return _validateAccountSecurity();
      default:
        return false;
    }
  }

  bool _validatePersonalInfo() {
    return _fullNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _isValidEmail(_emailController.text) &&
        _phoneController.text.isNotEmpty;
  }

  bool _validateBusinessInfo() {
    return _businessNameController.text.isNotEmpty;
  }

  bool _validateAccountSecurity() {
    return _passwordController.text.isNotEmpty &&
        _isValidPassword(_passwordController.text) &&
        _confirmPasswordController.text == _passwordController.text &&
        _agreedToTerms;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || !_agreedToTerms) {
      if (!_agreedToTerms) {
        _showErrorSnackBar('You must agree to the terms and conditions');
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final address = {
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
      };

      final businessData = {
        'owner_name': _fullNameController.text,
        'business_name': _businessNameController.text,
        'phone_number': _phoneController.text,
        'business_type': _selectedBusinessType,
        'address': {
          'city': address['city'] ?? '',
          'district': address['state'] ?? '',
          'street': address['street'] ?? '',
          'country': 'Iraq',
        },
        // flat fallbacks for backward compatibility
        'city': address['city'] ?? '',
        'district': address['state'] ?? '',
        'street': address['street'] ?? '',
        'country': 'Iraq',
        if (_selectedSubcategoryIds.isNotEmpty)
          'businessSubcategories': _selectedSubcategoryIds.toList(),
      };

      final result = await AppAuthService.registerWithBusiness(
        email: _emailController.text,
        password: _passwordController.text,
        businessData: businessData,
      );

      if (result.success) {
        _showSuccessSnackBar(result.message);

        // Navigate to email verification, clearing the navigation stack.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationScreen(
              email: _emailController.text,
              businessData: businessData,
            ),
          ),
          (route) => false,
        );
      } else {
        _showErrorSnackBar(result.message);
      }
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getBusinessTypeLabel(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type.toLowerCase()) {
      case 'restaurant':
        return l10n.restaurant;
      case 'store':
        return l10n.store;
      case 'cafe':
        return l10n.cafe;
      case 'bakery':
        return l10n.bakery;
      case 'cloudkitchen':
        return l10n.cloudKitchen;
      case 'pharmacy':
        return l10n.pharmacy;
      case 'herbalspices':
        return l10n.herbalspices;
      case 'cosmetics':
        return l10n.cosmetics;
      case 'betshop':
        return l10n.betshop;
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  // Validation methods
  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    print('🧪 EMAIL DEBUG (signup): Validating "$trimmed"');
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    final ok = emailRegex.hasMatch(trimmed);
    if (!ok) {
      print('🧪 EMAIL DEBUG (signup): Validation failed for "$trimmed"');
    } else {
      print('🧪 EMAIL DEBUG (signup): Validation passed');
    }
    return ok;
  }

  bool _isValidPassword(String password) {
    final lengthOk = password.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);
    return lengthOk && hasUpper && hasLower && hasNumber && hasSpecial;
  }

  String _getPasswordRequirements() {
    return 'Password must be at least 8 characters long and include uppercase, lowercase, numbers, and a special character.';
  }

  Future<void> _loadSubcategoriesForType(String businessType) async {
    try {
      final list =
          await ApiService().getBusinessSubcategoriesByType(businessType);
      setState(() {
        _availableSubcategories = list
            .map((e) => BusinessSubcategory.fromJson(e))
            .toList(growable: false);
        _selectedSubcategoryIds.clear();
      });
    } catch (_) {}
  }
}
