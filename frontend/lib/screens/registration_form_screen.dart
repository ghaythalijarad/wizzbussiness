import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../widgets/wizz_business_text_form_field.dart';
import '../widgets/wizz_business_button.dart';
import '../services/app_auth_service.dart';
import '../services/image_upload_service.dart';
import '../services/document_upload_service.dart';
import '../models/business.dart';
import '../screens/dashboards/business_dashboard.dart';
import '../screens/auth/auth_screen.dart';

class RegistrationFormScreen extends ConsumerStatefulWidget {
  const RegistrationFormScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegistrationFormScreen> createState() =>
      _RegistrationFormScreenState();
}

class _RegistrationFormScreenState
    extends ConsumerState<RegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // User Information Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Business Information Controllers
  final _businessNameController = TextEditingController();
  final _businessStreetController = TextEditingController();
  final _businessCityController = TextEditingController();
  final _businessDistrictController = TextEditingController();
  final _businessCountryController = TextEditingController();
  
  // Verification
  final _verificationController = TextEditingController();

  // State Variables
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _selectedBusinessType = 'restaurant';
  int _currentPageIndex = 0;
  bool _agreedToTerms = false;

  // Document Files - Optional
  File? _licenseFile;
  File? _identityFile;
  File? _healthCertificateFile;
  File? _ownerPhotoFile;
  File? _businessPhotoFile;

  // Image picker instance
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _businessCountryController.text = 'Iraq';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _businessStreetController.dispose();
    _businessCityController.dispose();
    _businessDistrictController.dispose();
    _businessCountryController.dispose();
    _verificationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.registerYourBusiness),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFE8F5E8)],
          ),
        ),
        child: Column(
          children: [
            // Progress Indicator
            _buildProgressIndicator(),

            // Form Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                children: [
                  _buildUserInfoPage(loc),
                  _buildBusinessInfoPage(loc),
                  _buildDocumentsPage(loc),
                  _buildVerificationPage(loc),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentPageIndex;
          final isCompleted = index < _currentPageIndex;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF4CAF50)
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  if (index < 3)
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF4CAF50)
                            : isActive
                                ? const Color(0xFF4CAF50)
                                : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 12, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color:
                                    isActive ? Colors.white : Colors.grey[600],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUserInfoPage(AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              loc.createBusinessAccountButton,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the form below to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Personal Information Section
            _buildSectionHeader(loc.personalInformation, Icons.person),
            const SizedBox(height: 16),

            // First Name & Last Name Row
            Row(
              children: [
                Expanded(
                  child: WizzBusinessTextFormField(
                    controller: _firstNameController,
                    labelText: 'First Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: WizzBusinessTextFormField(
                    controller: _lastNameController,
                    labelText: 'Last Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email
            WizzBusinessTextFormField(
              controller: _emailController,
              labelText: loc.enterYourEmail,
              prefixIcon: const Icon(Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value.trim())) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Number
            WizzBusinessTextFormField(
              controller: _phoneController,
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone_outlined),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Account Security Section
            _buildSectionHeader('Account Security', Icons.security),
            const SizedBox(height: 16),

            // Password
            WizzBusinessTextFormField(
              controller: _passwordController,
              labelText: loc.createAStrongPassword,
              prefixIcon: const Icon(Icons.lock_outlined),
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)')
                    .hasMatch(value)) {
                  return 'Password must contain uppercase, lowercase and numbers';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm Password
            WizzBusinessTextFormField(
              controller: _confirmPasswordController,
              labelText: loc.confirmYourPassword,
              prefixIcon: const Icon(Icons.lock_outlined),
              obscureText: !_isConfirmPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(_isConfirmPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Next Button
            WizzBusinessButton(
              text: 'Next',
              isLoading: false,
              onPressed: () {
                if (_formKey.currentState?.validate() == true) {
                  _nextPage();
                }
              },
            ),
            const SizedBox(height: 16),

            // Back to Login
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(loc.backToLogin),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoPage(AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            loc.businessInformation,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Business Name
          WizzBusinessTextFormField(
            controller: _businessNameController,
            labelText: loc.enterYourBusinessName,
            prefixIcon: const Icon(Icons.business_outlined),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter business name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Business Type
          _buildBusinessTypeSelector(loc),
          const SizedBox(height: 24),

          // Business Address Section
          _buildSectionHeader(loc.businessAddress, Icons.location_on),
          const SizedBox(height: 16),

          // Street Address
          WizzBusinessTextFormField(
            controller: _businessStreetController,
            labelText: loc.streetName,
            prefixIcon: const Icon(Icons.home_outlined),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter street address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // City & District Row
          Row(
            children: [
              Expanded(
                child: WizzBusinessTextFormField(
                  controller: _businessCityController,
                  labelText: loc.city,
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter city';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: WizzBusinessTextFormField(
                  controller: _businessDistrictController,
                  labelText: loc.neighborhood,
                  prefixIcon: const Icon(Icons.map_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter neighborhood';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Country
          WizzBusinessTextFormField(
            controller: _businessCountryController,
            labelText: loc.country,
            prefixIcon: const Icon(Icons.flag_outlined),
            enabled: false,
          ),
          const SizedBox(height: 32),

          // Required Business Photo Section
          _buildSectionHeader(loc.businessPhoto + ' *', Icons.photo_camera),
          const SizedBox(height: 16),
          _buildBusinessPhotoUpload(loc),
          const SizedBox(height: 32),

          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousPage,
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: WizzBusinessButton(
                  text: 'Next',
                  isLoading: false,
                  onPressed: () {
                    if (_validateBusinessInfo()) {
                      _nextPage();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsPage(AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'Business Documents',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload optional documents to verify your business',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Optional Documents
          _buildDocumentUploadCard(
            title: 'Business License',
            subtitle: 'Upload your business license document',
            icon: Icons.description_outlined,
            file: _licenseFile,
            onTap: () => _pickDocument('license'),
          ),
          const SizedBox(height: 16),

          _buildDocumentUploadCard(
            title: 'Owner Identity',
            subtitle: 'Upload owner identification document',
            icon: Icons.badge_outlined,
            file: _identityFile,
            onTap: () => _pickDocument('identity'),
          ),
          const SizedBox(height: 16),

          _buildDocumentUploadCard(
            title: loc.healthCertificate,
            subtitle: 'Upload health certificate if applicable',
            icon: Icons.health_and_safety_outlined,
            file: _healthCertificateFile,
            onTap: () => _pickDocument('health'),
          ),
          const SizedBox(height: 16),

          _buildDocumentUploadCard(
            title: 'Owner Photo',
            subtitle: 'Upload a photo of the business owner',
            icon: Icons.person_outlined,
            file: _ownerPhotoFile,
            onTap: () => _pickDocument('owner'),
          ),
          const SizedBox(height: 32),

          // Terms and Conditions
          _buildTermsAndConditions(loc),
          const SizedBox(height: 32),

          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousPage,
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: WizzBusinessButton(
                  text: 'Register',
                  isLoading: _isLoading,
                  onPressed: _agreedToTerms ? _register : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationPage(AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Icon(
            Icons.email_outlined,
            size: 80,
            color: Color(0xFF4CAF50),
          ),
          const SizedBox(height: 24),

          Text(
            loc.checkYourEmail,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'We sent a verification code to your email address',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Verification Code Input
          WizzBusinessTextFormField(
            controller: _verificationController,
            labelText: 'Verification Code',
            prefixIcon: const Icon(Icons.security_outlined),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter verification code';
              }
              if (value.trim().length != 6) {
                return 'Verification code must be 6 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Verify Button
          WizzBusinessButton(
            text: 'Verify & Complete',
            isLoading: _isLoading,
            onPressed: _verifyRegistration,
          ),
          const SizedBox(height: 16),

          // Resend Code
          TextButton(
            onPressed: _isLoading ? null : _resendVerificationCode,
            child: Text(loc.resendCode),
          ),
          const SizedBox(height: 16),

          // Back to Previous Step
          TextButton(
            onPressed: _isLoading ? null : _previousPage,
            child: const Text('Previous'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4CAF50), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D32),
              ),
        ),
      ],
    );
  }

  Widget _buildBusinessTypeSelector(AppLocalizations loc) {
    final businessTypes = [
      {'value': 'restaurant', 'label': 'Restaurant', 'icon': Icons.restaurant},
      {'value': 'cafe', 'label': loc.cafe, 'icon': Icons.local_cafe},
      {'value': 'bakery', 'label': loc.bakery, 'icon': Icons.cake},
      {
        'value': 'grocery',
        'label': 'Grocery',
        'icon': Icons.local_grocery_store
      },
      {
        'value': 'pharmacy',
        'label': loc.pharmacy,
        'icon': Icons.local_pharmacy
      },
      {'value': 'store', 'label': 'Store', 'icon': Icons.store},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.selectYourBusinessType,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D32),
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: businessTypes.map((type) {
            final isSelected = _selectedBusinessType == type['value'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBusinessType = type['value'] as String;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4CAF50)
                        : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      color:
                          isSelected ? Colors.white : const Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type['label'] as String,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBusinessPhotoUpload(AppLocalizations loc) {
    return GestureDetector(
      onTap: () => _pickBusinessPhoto(),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: _businessPhotoFile != null
                ? const Color(0xFF4CAF50)
                : Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: _businessPhotoFile != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _businessPhotoFile!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _businessPhotoFile = null;
                        });
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_outlined,
                    size: 48,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload business photo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Required field',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: file != null ? const Color(0xFF4CAF50) : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF4CAF50),
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            if (file != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else
              const Icon(
                Icons.upload_outlined,
                color: Color(0xFF4CAF50),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndConditions(AppLocalizations loc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (value) {
            setState(() {
              _agreedToTerms = value ?? false;
            });
          },
          activeColor: const Color(0xFF4CAF50),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _agreedToTerms = !_agreedToTerms;
              });
            },
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: 'Terms and Conditions',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _nextPage() {
    if (_currentPageIndex < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateBusinessInfo() {
    if (_businessNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter business name');
      return false;
    }
    if (_businessStreetController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter street address');
      return false;
    }
    if (_businessCityController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter city');
      return false;
    }
    if (_businessDistrictController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter neighborhood');
      return false;
    }
    if (_businessPhotoFile == null) {
      _showErrorSnackBar('Please upload business photo');
      return false;
    }
    return true;
  }

  Future<void> _pickBusinessPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _businessPhotoFile = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _pickDocument(String type) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          switch (type) {
            case 'license':
              _licenseFile = File(image.path);
              break;
            case 'identity':
              _identityFile = File(image.path);
              break;
            case 'health':
              _healthCertificateFile = File(image.path);
              break;
            case 'owner':
              _ownerPhotoFile = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking document: $e');
    }
  }

  Future<void> _register() async {
    // Check if user agreed to terms
    if (!_agreedToTerms) {
      _showErrorSnackBar('You must agree to the terms and conditions');
      return;
    }

    // Validate all user info fields
    if (!_validateUserInfo()) {
      return;
    }

    // Validate business info including required business photo
    if (!_validateBusinessInfo()) {
      return;
    }

    setState(() => _isLoading = true);
    print('🔄 Starting registration process...');

    try {
      // Step 1: Check if email already exists
      print('📧 Checking if email exists: ${_emailController.text.trim()}');
      final emailCheckResult = await AppAuthService.checkEmailExists(
        email: _emailController.text.trim(),
      );
      print('📧 Email check result: exists=${emailCheckResult.exists}, message=${emailCheckResult.message}');

      if (emailCheckResult.exists) {
        print('❌ Email already exists, stopping registration');
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(emailCheckResult.message),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Login Instead',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );
                },
              ),
            ),
          );
        }
        return;
      }

      print('✅ Email check passed, proceeding with registration');

      // Step 2: Upload documents during registration
      print('📸 Starting document uploads...');
      String? businessPhotoUrl;
      String? licenseUrl;
      String? identityUrl;
      String? healthCertificateUrl;
      String? ownerPhotoUrl;
      
      // Additional safety check for required business photo
      if (_businessPhotoFile == null) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Business photo is required');
        return;
      }
      
      try {
        // Upload business photo (required)
        print('📸 Uploading business photo...');
        final businessPhotoUploadResult = await ImageUploadService.uploadBusinessPhoto(
          _businessPhotoFile!, 
          isRegistration: true
        );
        if (businessPhotoUploadResult['success'] == true) {
          businessPhotoUrl = businessPhotoUploadResult['imageUrl'];
          print('✅ Business photo uploaded successfully: $businessPhotoUrl');
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload business photo: ${businessPhotoUploadResult['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Upload optional documents
        if (_licenseFile != null) {
          print('📄 Uploading business license...');
          final licenseUploadResult = await DocumentUploadService.uploadBusinessLicense(
            _licenseFile!, 
            isRegistration: true
          );
          if (licenseUploadResult['success'] == true) {
            licenseUrl = licenseUploadResult['imageUrl'];
            print('✅ Business license uploaded successfully: $licenseUrl');
          } else {
            print('⚠️ Failed to upload business license: ${licenseUploadResult['message']}');
          }
        }

        if (_identityFile != null) {
          print('🆔 Uploading owner identity...');
          final identityUploadResult = await DocumentUploadService.uploadOwnerIdentity(
            _identityFile!, 
            isRegistration: true
          );
          if (identityUploadResult['success'] == true) {
            identityUrl = identityUploadResult['imageUrl'];
            print('✅ Owner identity uploaded successfully: $identityUrl');
          } else {
            print('⚠️ Failed to upload owner identity: ${identityUploadResult['message']}');
          }
        }

        if (_healthCertificateFile != null) {
          print('🏥 Uploading health certificate...');
          final healthUploadResult = await DocumentUploadService.uploadHealthCertificate(
            _healthCertificateFile!, 
            isRegistration: true
          );
          if (healthUploadResult['success'] == true) {
            healthCertificateUrl = healthUploadResult['imageUrl'];
            print('✅ Health certificate uploaded successfully: $healthCertificateUrl');
          } else {
            print('⚠️ Failed to upload health certificate: ${healthUploadResult['message']}');
          }
        }

        if (_ownerPhotoFile != null) {
          print('👤 Uploading owner photo...');
          final ownerPhotoUploadResult = await DocumentUploadService.uploadOwnerPhoto(
            _ownerPhotoFile!, 
            isRegistration: true
          );
          if (ownerPhotoUploadResult['success'] == true) {
            ownerPhotoUrl = ownerPhotoUploadResult['imageUrl'];
            print('✅ Owner photo uploaded successfully: $ownerPhotoUrl');
          } else {
            print('⚠️ Failed to upload owner photo: ${ownerPhotoUploadResult['message']}');
          }
        }

        print('📋 Document upload summary:');
        print('   Business Photo: ${businessPhotoUrl != null ? "✅" : "❌"}');
        print('   Business License: ${licenseUrl != null ? "✅" : "⏸️ (optional)"}');
        print('   Owner Identity: ${identityUrl != null ? "✅" : "⏸️ (optional)"}');
        print('   Health Certificate: ${healthCertificateUrl != null ? "✅" : "⏸️ (optional)"}');
        print('   Owner Photo: ${ownerPhotoUrl != null ? "✅" : "⏸️ (optional)"}');

      } catch (uploadError) {
        print('❌ Document upload failed: $uploadError');
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading documents: $uploadError'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Step 3: Register with business data including all document URLs
      print('🏢 Starting business registration with backend...');
      final businessData = {
        'businessName': _businessNameController.text.trim(),
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'businessType': _selectedBusinessType,
        'phoneNumber': _phoneController.text.trim(),
        'address': {
          'city': _businessCityController.text.trim(),
          'district': _businessDistrictController.text.trim(),
          'street': _businessStreetController.text.trim(),
          'country': _businessCountryController.text.trim(),
        },
        'businessPhotoUrl': businessPhotoUrl, // Required document URL
        'licenseUrl': licenseUrl, // Optional document URL
        'identityUrl': identityUrl, // Optional document URL
        'healthCertificateUrl': healthCertificateUrl, // Optional document URL
        'ownerPhotoUrl': ownerPhotoUrl, // Optional document URL
      };

      print('🏢 Business data prepared: ${businessData.keys.toList()}');
      final registerResult = await AppAuthService.registerWithBusiness(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        businessData: businessData,
      );
      print('🏢 Registration API result: success=${registerResult.success}, message=${registerResult.message}');

      setState(() => _isLoading = false);

      if (registerResult.success) {
        print('✅ Registration successful! Navigating to verification page...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(registerResult.message),
              backgroundColor: Colors.green,
            ),
          );
        }
        _nextPage(); // Move to verification page
      } else {
        print('❌ Registration failed: ${registerResult.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(registerResult.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('💥 Registration error caught: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyRegistration() async {
    if (_verificationController.text.trim().length != 6) {
      _showErrorSnackBar('Verification code must be 6 digits');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final confirmResult = await AppAuthService.confirmRegistration(
        email: _emailController.text.trim(),
        confirmationCode: _verificationController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (confirmResult.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(confirmResult.message ??
                  'Registration completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Check if we have user and business data for auto-navigation
        if (confirmResult.user != null && confirmResult.business != null) {
          // User verified successfully with business data - navigate to dashboard
          final businessData =
              Map<String, dynamic>.from(confirmResult.business as Map);

          // Ensure email is included in business data
          businessData['email'] = businessData['email'] ??
              confirmResult.user!['email'] ??
              _emailController.text.trim();

          try {
            Business.fromJson(businessData); // Validate the data

            // Navigate to business dashboard
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusinessDashboard(),
                ),
              );
            }
          } catch (businessError) {
            debugPrint('Error creating business object: $businessError');
            // Fall back to login screen if business data is invalid
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthScreen(),
                ),
              );
            }
          }
        } else {
          // Original flow - navigate to login
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AuthScreen(),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(confirmResult.message ?? 'Verification failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resendVerificationCode() async {
    try {
      await AppAuthService.resendRegistrationCode(
        email: _emailController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code resent'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _validateUserInfo() {
    if (_firstNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your first name');
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your last name');
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter your email');
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      _showErrorSnackBar('Please enter a valid email address');
      return false;
    }
    if (_passwordController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a password');
      return false;
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(_passwordController.text)) {
      _showErrorSnackBar('Password must contain at least one uppercase letter, one lowercase letter, and one number');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return false;
    }
    return true;
  }
}
