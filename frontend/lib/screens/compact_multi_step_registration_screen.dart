import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_auth_service.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../models/business_subcategory.dart';
import '../services/api_service.dart';
import '../utils/latin_number_formatter.dart';
import '../services/document_upload_service.dart';
import '../services/image_upload_service.dart';

class CompactMultiStepRegistrationScreen extends StatefulWidget {
  const CompactMultiStepRegistrationScreen({Key? key}) : super(key: key);

  @override
  _CompactMultiStepRegistrationScreenState createState() =>
      _CompactMultiStepRegistrationScreenState();
}

class _CompactMultiStepRegistrationScreenState
    extends State<CompactMultiStepRegistrationScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form keys for each step
  final _accountFormKey = GlobalKey<FormState>();
  final _businessFormKey = GlobalKey<FormState>();
  final _locationFormKey = GlobalKey<FormState>();
  final _documentsFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _showVerificationField = false;

  // Step 1: Account Information
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationController = TextEditingController();

  // Step 2: Business Information
  final _businessNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedBusinessType = 'restaurant';
  String? _selectedSubcategory;
  List<BusinessSubcategory> _availableSubcategories = [];

  // Step 3: Location Information
  final _businessCityController = TextEditingController();
  final _businessDistrictController = TextEditingController();
  final _businessCountryController = TextEditingController();
  final _businessStreetController = TextEditingController();

  // Step 4: Documents (Optional)
  File? _licenseFile;
  File? _identityFile;
  File? _healthCertificateFile;
  File? _ownerPhotoFile;
  File? _businessPhotoFile;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _businessCountryController.text = 'Iraq';
    _loadSubcategoriesForType(_selectedBusinessType);
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationController.dispose();
    _businessNameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _businessCityController.dispose();
    _businessDistrictController.dispose();
    _businessCountryController.dispose();
    _businessStreetController.dispose();
    super.dispose();
  }

  Future<void> _loadSubcategoriesForType(String businessType) async {
    try {
      final api = ApiService();
      final list = await api.getBusinessSubcategoriesByType(businessType);
      final subs = list
          .map((e) => BusinessSubcategory.fromJson(e))
          .toList(growable: false);
      setState(() {
        _availableSubcategories = subs;
        _selectedSubcategory = null; // Reset selection
      });
    } catch (e) {
      // Silent fail; keep UI usable even if fetch fails
    }
  }

  String _getBusinessTypeText(String businessType) {
    final loc = AppLocalizations.of(context)!;
    switch (businessType) {
      case 'restaurant':
        return loc.restaurant;
      case 'cloudkitchen':
        return loc.cloudKitchen;
      case 'store':
        return loc.store;
      case 'pharmacy':
        return loc.pharmacy;
      case 'cafe':
        return loc.cafe;
      default:
        return businessType;
    }
  }

  Widget _buildCompactStepIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          bool isActive = index <= _currentStep;
          bool isCurrent = index == _currentStep;
          bool isCompleted = index < _currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress line
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF00c1e8)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Step indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF00c1e8)
                          : isCurrent
                              ? const Color(0xFF00c1e8)
                              : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00c1e8).withOpacity(0.3),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrent
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Step title
                  Text(
                    _getStepTitle(index),
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFF00c1e8)
                          : Colors.grey.shade500,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
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

  String _getStepTitle(int step) {
    final loc = AppLocalizations.of(context)!;
    switch (step) {
      case 0:
        return loc.account;
      case 1:
        return loc.business;
      case 2:
        return loc.location;
      case 3:
        return loc.documents;
      default:
        return '';
    }
  }

  Widget _buildCompactNavigationButtons() {
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_ios,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        loc.back,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00c1e8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == _totalSteps - 1
                                ? loc.register
                                : loc.next,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_currentStep < _totalSteps - 1) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() async {
    // Pre-check email availability on the first step
    if (_currentStep == 0) {
      final loc = AppLocalizations.of(context)!;
      if (_accountFormKey.currentState?.validate() != true) {
        return;
      }

      final email = _emailController.text.trim();
      try {
        setState(() => _isLoading = true);
        print('🧪 EMAIL DEBUG (compact): Pre-check availability for "$email"');
        final emailCheck = await AppAuthService.checkEmailExists(email: email);
        print(
            '🧪 EMAIL DEBUG (compact): Exists=${emailCheck.exists} message=${emailCheck.message}');

        if (emailCheck.exists) {
          setState(() => _isLoading = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                emailCheck.message.isNotEmpty
                    ? emailCheck.message
                    : loc.emailAlreadyInUse,
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: loc.loginInstead,
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ),
          );
          return; // Stop here if email is already taken
        }
      } catch (e) {
        print('⚠️ EMAIL DEBUG (compact): Availability check failed: $e');
        // Non-blocking on network issues
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps - 1) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
        );
      } else {
        _submitRegistration();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _accountFormKey.currentState?.validate() ?? false;
      case 1:
        return _businessFormKey.currentState?.validate() ?? false;
      case 2:
        return _locationFormKey.currentState?.validate() ?? false;
      case 3:
        return true; // Documents are optional
      default:
        return false;
    }
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF00c1e8), width: 2),
          ),
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        maxLines: maxLines,
        validator: validator,
      ),
    );
  }

  Widget _buildAccountStep() {
    final loc = AppLocalizations.of(context)!;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Form(
        key: _accountFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.createYourAccount,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a202c),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.enterAccountDetails,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            _buildCompactTextField(
              controller: _emailController,
              label: loc.emailAddress,
              hint: loc.enterYourEmail,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc.pleaseEnterYourEmail;
                }
                if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                    .hasMatch(value.trim())) {
                  return loc.invalidEmailFormat;
                }
                return null;
              },
            ),
            _buildCompactTextField(
              controller: _passwordController,
              label: loc.password,
              hint: loc.enterYourPassword,
              icon: Icons.lock_outlined,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc.pleaseEnterYourPassword;
                }
                final pwd = value;
                final lengthOk = pwd.length >= 8;
                final hasLower = RegExp(r'[a-z]').hasMatch(pwd);
                final hasUpper = RegExp(r'[A-Z]').hasMatch(pwd);
                final hasNumber = RegExp(r'[0-9]').hasMatch(pwd);
                final hasSpecial =
                    RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pwd);
                if (!(lengthOk &&
                    hasLower &&
                    hasUpper &&
                    hasNumber &&
                    hasSpecial)) {
                  return loc.weakPassword;
                }
                return null;
              },
            ),
            _buildCompactTextField(
              controller: _confirmPasswordController,
              label: loc.confirmPassword,
              hint: loc.reEnterYourPassword,
              icon: Icons.lock_outlined,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc.confirmPasswordRequired;
                }
                if (value != _passwordController.text) {
                  return loc.passwordsDoNotMatch;
                }
                return null;
              },
            ),
            if (_showVerificationField)
              _buildCompactTextField(
                controller: _verificationController,
                label: loc.verificationCode,
                hint: loc.enterVerificationCode,
                icon: Icons.verified_user_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (_showVerificationField &&
                      (value == null || value.isEmpty)) {
                    return loc.pleaseEnterVerificationCode;
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessStep() {
    final loc = AppLocalizations.of(context)!;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Form(
        key: _businessFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.businessInformation,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a202c),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.tellUsAboutYourBusiness,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            _buildCompactTextField(
              controller: _businessNameController,
              label: loc.businessName,
              hint: loc.enterYourBusinessName,
              icon: Icons.business_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc.pleaseEnterYourBusinessName;
                }
                return null;
              },
            ),

            _buildCompactTextField(
              controller: _fullNameController,
              label: loc.ownerName,
              hint: loc.enterOwnerName,
              icon: Icons.person_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc.pleaseEnterOwnerName;
                }
                return null;
              },
            ),

            _buildCompactTextField(
              controller: _phoneController,
              label: loc.phoneNumber,
              hint: loc.enterYourBusinessPhone,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [LatinNumberInputFormatter()],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc.pleaseEnterYourPhoneNumber;
                }
                return null;
              },
            ),

            // Business Type Dropdown
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                value: _selectedBusinessType,
                items: [
                  'restaurant',
                  'cloudkitchen',
                  'store',
                  'pharmacy',
                  'cafe'
                ]
                    .map((type) => DropdownMenuItem(
                        value: type, child: Text(_getBusinessTypeText(type))))
                    .toList(),
                decoration: InputDecoration(
                  labelText: loc.businessType,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Color(0xFF00c1e8), width: 2),
                  ),
                  prefixIcon: Icon(Icons.category_outlined,
                      color: Colors.grey.shade600, size: 20),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedBusinessType = value);
                  _loadSubcategoriesForType(value);
                },
              ),
            ),

            // Subcategory Dropdown - Elegant Implementation
            if (_availableSubcategories.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: _selectedSubcategory,
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        loc.selectSubcategory,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    ..._availableSubcategories.map((sub) {
                      final label =
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? sub.nameAr
                              : sub.nameEn;
                      return DropdownMenuItem<String>(
                        value: sub.subcategoryId,
                        child: Text(label),
                      );
                    }),
                  ],
                  decoration: InputDecoration(
                    labelText: loc.businessSubcategory,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF00c1e8), width: 2),
                    ),
                    prefixIcon: Icon(Icons.label_outlined,
                        color: Colors.grey.shade600, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onChanged: (value) {
                    setState(() => _selectedSubcategory = value);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    final loc = AppLocalizations.of(context)!;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Form(
        key: _locationFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.businessLocation,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a202c),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.whereIsYourBusiness,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            _buildCompactTextField(
              controller: _businessCountryController,
              label: loc.country,
              hint: loc.enterCountry,
              icon: Icons.public_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc.pleaseEnterCountry;
                }
                return null;
              },
            ),
            Row(
              children: [
                Expanded(
                  child: _buildCompactTextField(
                    controller: _businessCityController,
                    label: loc.city,
                    hint: loc.enterCity,
                    icon: Icons.location_city_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.pleaseEnterCity;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactTextField(
                    controller: _businessDistrictController,
                    label: loc.district,
                    hint: loc.enterDistrict,
                    icon: Icons.location_on_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return loc.pleaseEnterDistrict;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            _buildCompactTextField(
              controller: _businessStreetController,
              label: loc.streetAddress,
              hint: loc.enterStreetAddress,
              icon: Icons.home_outlined,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return loc.pleaseEnterStreetAddress;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsStep() {
    final loc = AppLocalizations.of(context)!;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Form(
        key: _documentsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.documents,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1a202c),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.uploadDocumentsOptional,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            _buildCompactDocumentCard(
              title: loc.businessLicense,
              subtitle: loc.uploadBusinessLicense,
              file: _licenseFile,
              icon: Icons.description_outlined,
              onTap: () => _pickDocument('license'),
            ),
            _buildCompactDocumentCard(
              title: loc.identityDocument,
              subtitle: loc.uploadIdentityDocument,
              file: _identityFile,
              icon: Icons.badge_outlined,
              onTap: () => _pickDocument('identity'),
            ),
            _buildCompactDocumentCard(
              title: loc.healthCertificate,
              subtitle: loc.uploadHealthCertificate,
              file: _healthCertificateFile,
              icon: Icons.health_and_safety_outlined,
              onTap: () => _pickDocument('health'),
            ),
            _buildCompactDocumentCard(
              title: loc.ownerPhoto,
              subtitle: loc.uploadOwnerPhoto,
              file: _ownerPhotoFile,
              icon: Icons.person_outline,
              onTap: () => _pickImage('owner'),
            ),
            _buildCompactDocumentCard(
              title: loc.businessPhoto,
              subtitle: loc.uploadBusinessPhoto,
              file: _businessPhotoFile,
              icon: Icons.business_outlined,
              onTap: () => _pickImage('business'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDocumentCard({
    required String title,
    required String subtitle,
    required File? file,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: file != null
                    ? const Color(0xFF00c1e8)
                    : Colors.grey.shade200,
                width: file != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: file != null
                        ? const Color(0xFF00c1e8).withOpacity(0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    file != null ? Icons.check_circle_outline : icon,
                    color: file != null
                        ? const Color(0xFF00c1e8)
                        : Colors.grey.shade500,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1a202c),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        file != null ? file.path.split('/').last : subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: file != null
                              ? const Color(0xFF00c1e8)
                              : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  file != null
                      ? Icons.edit_outlined
                      : Icons.upload_file_outlined,
                  color: file != null
                      ? const Color(0xFF00c1e8)
                      : Colors.grey.shade400,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDocument(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null) {
        setState(() {
          switch (type) {
            case 'license':
              _licenseFile = File(result.files.single.path!);
              break;
            case 'identity':
              _identityFile = File(result.files.single.path!);
              break;
            case 'health':
              _healthCertificateFile = File(result.files.single.path!);
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context)!.errorPickingFile}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage(String type) async {
    try {
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(AppLocalizations.of(context)!.selectImageSource),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: Text(AppLocalizations.of(context)!.camera),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: Text(AppLocalizations.of(context)!.gallery),
            ),
          ],
        ),
      );

      if (source != null) {
        final XFile? image = await _imagePicker.pickImage(source: source);
        if (image != null) {
          setState(() {
            switch (type) {
              case 'owner':
                _ownerPhotoFile = File(image.path);
                break;
              case 'business':
                _businessPhotoFile = File(image.path);
                break;
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppLocalizations.of(context)!.errorPickingImage}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    try {
      if (_showVerificationField && _verificationController.text.isNotEmpty) {
        final confirmResult = await AppAuthService.confirmRegistration(
          email: _emailController.text.trim(),
          confirmationCode: _verificationController.text.trim(),
        );

        setState(() => _isLoading = false);

        if (confirmResult.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .registrationVerifiedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
          return;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .verificationFailedWithReason(
                      confirmResult.message ?? 'Unknown error')),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Step 1: Create Cognito account
      final signUpResult = await AppAuthService.registerSimple(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!signUpResult.success) {
        throw Exception(signUpResult.message);
      }

      // Show verification field if not already shown
      if (!_showVerificationField) {
        setState(() {
          _showVerificationField = true;
          _currentStep = 0; // Go back to account step
        });
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.verificationCodeSent),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // Step 2: Upload documents (if provided)
      Map<String, String> documentUrls = {};

      if (_licenseFile != null) {
        final licenseResult =
            await DocumentUploadService.uploadBusinessLicense(_licenseFile!);
        if (licenseResult['success'] == true) {
          documentUrls['licenseUrl'] = licenseResult['imageUrl'];
        }
      }

      if (_identityFile != null) {
        final identityResult =
            await DocumentUploadService.uploadOwnerIdentity(_identityFile!);
        if (identityResult['success'] == true) {
          documentUrls['identityUrl'] = identityResult['imageUrl'];
        }
      }

      if (_healthCertificateFile != null) {
        final healthResult =
            await DocumentUploadService.uploadHealthCertificate(
                _healthCertificateFile!);
        if (healthResult['success'] == true) {
          documentUrls['healthCertificateUrl'] = healthResult['imageUrl'];
        }
      }

      if (_ownerPhotoFile != null) {
        final ownerPhotoResult =
            await DocumentUploadService.uploadOwnerPhoto(_ownerPhotoFile!);
        if (ownerPhotoResult['success'] == true) {
          documentUrls['ownerPhotoUrl'] = ownerPhotoResult['imageUrl'];
        }
      }

      if (_businessPhotoFile != null) {
        final businessPhotoResult =
            await ImageUploadService.uploadBusinessPhoto(_businessPhotoFile!);
        if (businessPhotoResult['success'] == true) {
          documentUrls['businessPhotoUrl'] = businessPhotoResult['imageUrl'];
        }
      }

      // Split full name into first and last name for backend compatibility
      final nameParts = _fullNameController.text.trim().split(' ');
      final firstName = nameParts.first;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Step 3: Register with business data
      final businessData = {
        'businessName': _businessNameController.text.trim(),
        'firstName': firstName,
        'lastName': lastName,
        'businessType': _selectedBusinessType,
        'phoneNumber': _phoneController.text.trim(),
        'address': {
          'city': _businessCityController.text.trim(),
          'district': _businessDistrictController.text.trim(),
          'street': _businessStreetController.text.trim(),
          'country': _businessCountryController.text.trim(),
        },
        ...documentUrls,
        if (_selectedSubcategory != null)
          'subcategoryIds': [_selectedSubcategory],
      };

      final registrationResult = await AppAuthService.registerWithBusiness(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        businessData: businessData,
      );

      if (!registrationResult.success) {
        throw Exception(registrationResult.message);
      }

      setState(() {
        _showVerificationField = true;
        _currentStep = 0;
        _isLoading = false;
      });

      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.verificationCodeSentToEmail),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!
              .registrationFailedWithReason(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          AppLocalizations.of(context)!.createAccount,
          style: const TextStyle(
            color: Color(0xFF1a202c),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF1a202c), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: _buildCompactStepIndicator(),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStepContent(_buildAccountStep()),
                _buildStepContent(_buildBusinessStep()),
                _buildStepContent(_buildLocationStep()),
                _buildStepContent(_buildDocumentsStep()),
              ],
            ),
          ),
          _buildCompactNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepContent(Widget content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: content,
    );
  }
}
