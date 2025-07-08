import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../services/unified_auth_service.dart';

class RegistrationFormScreen extends StatefulWidget {
  const RegistrationFormScreen({Key? key}) : super(key: key);

  @override
  _RegistrationFormScreenState createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Combined Business and Owner Information Controllers
  final _businessNameController = TextEditingController();
  String? _selectedBusinessType;
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController(); // Optional
  final _phoneController = TextEditingController(); // Iraqi phones only
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Business Address Controllers - Detailed
  final _businessCityController = TextEditingController();
  final _businessDistrictController = TextEditingController();
  final _businessCountryController = TextEditingController();
  final _businessZipCodeController = TextEditingController();
  final _businessNeighborhoodController = TextEditingController();
  final _businessStreetController = TextEditingController();
  final _businessHomeController = TextEditingController();

  // Additional Owner Information
  final _ownerNationalIdController = TextEditingController();
  final _ownerDateOfBirthController = TextEditingController();

  // Document Files
  File? _licenseFile;
  File? _identityFile;
  File? _healthCertificateFile;
  File? _ownerPhotoFile;

  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoadingLocation = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessCityController.dispose();
    _businessDistrictController.dispose();
    _businessCountryController.dispose();
    _businessZipCodeController.dispose();
    _businessNeighborhoodController.dispose();
    _businessStreetController.dispose();
    _businessHomeController.dispose();
    _ownerNationalIdController.dispose();
    _ownerDateOfBirthController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _autoFillAddress() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks[0];
        _businessCityController.text = placemark.locality ?? '';
        _businessDistrictController.text =
            placemark.subAdministrativeArea ?? '';
        _businessCountryController.text = placemark.country ?? '';
        _businessZipCodeController.text = placemark.postalCode ?? '';
        _businessNeighborhoodController.text = placemark.subLocality ?? '';
        _businessStreetController.text = placemark.street ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)!.errorGettingLocation}: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  // Enhanced Validation Methods
  String? _validateEmail(String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return loc.pleaseEnterEmailAddress;
    }
    // Correct email validation pattern
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return loc.pleaseEnterValidEmailAddress;
    }
    return null;
  }

  String? _validateIraqiPhone(String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return loc.phoneNumberIsRequired;
    }

    // Remove all spaces, dashes, and parentheses
    String cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it's exactly 10 digits (since +964 is added automatically)
    if (cleanPhone.length != 10) {
      return loc.pleaseEnterExactly10Digits;
    }

    // Check if all characters are digits
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      return loc.pleaseEnterOnlyNumbers;
    }

    // Iraqi mobile number patterns (first 3 digits after +964):
    // 77X, 78X, 79X for mobile
    // 1-9XX for landline
    final mobileRegex = RegExp(r'^(77[0-9]|78[0-9]|79[0-9])[0-9]{7}$');
    final landlineRegex = RegExp(r'^[1-9][0-9]{6,9}$');

    if (!mobileRegex.hasMatch(cleanPhone) &&
        !landlineRegex.hasMatch(cleanPhone)) {
      return loc.pleaseEnterValidIraqiNumber;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return loc.passwordIsRequired;
    }
    if (value.length < 8) {
      return loc.passwordMustBeAtLeast8Characters;
    }

    // Check for lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return loc.passwordMustContainLowercase;
    }

    // Check for uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return loc.passwordMustContainUppercase;
    }

    // Check for number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return loc.passwordMustContainNumber;
    }

    // Check for special character
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return loc.passwordMustContainSpecialCharacter;
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final loc = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return loc.pleaseConfirmYourPassword;
    }
    if (value != _passwordController.text) {
      return loc.passwordsDoNotMatchRegistration;
    }
    return null;
  }

  Future<void> _pickDocument(Function(File) onFilePicked) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          onFilePicked(File(result.files.single.path!));
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .documentSelectedSuccessfully)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.errorSelectingDocument)),
        );
      }
    }
  }

  Future<void> _pickImage(Function(File) onImagePicked) async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text(AppLocalizations.of(context)!.photoLibrary),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      setState(() {
                        onImagePicked(File(image.path));
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: Text(AppLocalizations.of(context)!.camera),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      setState(() {
                        onImagePicked(File(image.path));
                      });
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSelectingImage)),
      );
    }
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required String subtitle,
    required File? file,
    required VoidCallback onPressed,
    required IconData icon,
    bool isRequired = true,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF00C1E8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isRequired)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.required,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (file != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.path.split('/').last,
                        style: TextStyle(color: Colors.green[800]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          if (file == _licenseFile) _licenseFile = null;
                          if (file == _identityFile) _identityFile = null;
                          if (file == _healthCertificateFile) {
                            _healthCertificateFile = null;
                          }
                          if (file == _ownerPhotoFile) _ownerPhotoFile = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(file != null ? Icons.refresh : Icons.upload),
                label: Text(file != null
                    ? AppLocalizations.of(context)!.changeFile
                    : AppLocalizations.of(context)!.selectFile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: file != null
                      ? const Color(0xFF007fff)
                      : const Color(0xFF00C1E8),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00C1E8),
            ),
      ),
    );
  }

  void _submitForm() async {
    final l10n = AppLocalizations.of(context)!;

    // Check form validation and provide feedback
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.pleaseCompleteAllRequiredFields),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Prepare registration data
      Map<String, dynamic> registrationData = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'business_name': _businessNameController.text.trim(),
        'business_type': _selectedBusinessType,
        'owner_name': _ownerNameController.text.trim(),
        'phone_number': '+964${_phoneController.text.trim()}',
        'address': {
          'city': _businessCityController.text.trim(),
          'district': _businessDistrictController.text.trim(),
          'country': _businessCountryController.text.trim(),
          'zip_code': _businessZipCodeController.text.trim(),
          'neighborhood': _businessNeighborhoodController.text.trim(),
          'street': _businessStreetController.text.trim(),
          'home_address': _businessHomeController.text.trim(),
        },
        'owner_national_id': _ownerNationalIdController.text.trim(),
        'owner_date_of_birth': _ownerDateOfBirthController.text.trim(),
      };

      // Call the registration service
      final response = await UnifiedAuthService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        userData: registrationData,
        licenseFile: _licenseFile,
        identityFile: _identityFile,
        healthCertificateFile: _healthCertificateFile,
        ownerPhotoFile: _ownerPhotoFile,
      );

      // Close the loading dialog
      Navigator.of(context).pop();

      if (response['success']) {
        // Check if email verification is needed (Cognito)
        if (response['isSignUpComplete'] == false &&
            response['nextStep']?.contains('CONFIRM_SIGN_UP') == true) {
          // Show email verification dialog for Cognito
          _showEmailVerificationDialog(_emailController.text.trim());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.registrationSuccessLogin),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to login screen
          Navigator.of(context).pop();
        }
      } else {
        // It's good practice to check if the widget is still in the tree
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? l10n.registrationFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog
      Navigator.of(context).pop();
      // Ensure the widget is still mounted before showing a SnackBar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEmailVerificationDialog(String email) {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isVerifying = false;
    bool isResending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.mark_email_read,
                color: const Color(0xFF00C1E8),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C1E8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We sent a verification code to:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00C1E8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: codeController,
                  decoration: InputDecoration(
                    labelText: 'Verification Code',
                    hintText: 'Enter 6-digit code',
                    prefixIcon: const Icon(Icons.verified_user),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF00C1E8),
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the verification code';
                    }
                    if (value.trim().length != 6) {
                      return 'Code must be 6 digits';
                    }
                    return null;
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Check your email (including spam folder) for the verification code.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isResending
                  ? null
                  : () async {
                      setState(() => isResending = true);

                      try {
                        final result =
                            await UnifiedAuthService.resendConfirmationCode(
                          email: email,
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    result['success']
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child:
                                        Text(result['message'] ?? 'Code sent'),
                                  ),
                                ],
                              ),
                              backgroundColor:
                                  result['success'] ? Colors.green : Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => isResending = false);
                        }
                      }
                    },
              child: isResending
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey[600]!,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Sending...'),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh, size: 18),
                        const SizedBox(width: 4),
                        const Text('Resend Code'),
                      ],
                    ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isVerifying
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setState(() => isVerifying = true);

                      try {
                        final code = codeController.text.trim();
                        final result = await UnifiedAuthService.confirmSignUp(
                          email: email,
                          confirmationCode: code,
                        );

                        if (context.mounted) {
                          if (result['success']) {
                            // Close verification dialog
                            Navigator.of(context).pop();

                            // Now register business data with the backend
                            await _registerBusinessDataAfterVerification(email);

                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Registration completed successfully! You can now login.',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 4),
                              ),
                            );

                            // Navigate back to login screen
                            Navigator.of(context).pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(
                                      Icons.error,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        result['message'] ??
                                            'Verification failed',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => isVerifying = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C1E8),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isVerifying
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Verifying...'),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 18),
                        const SizedBox(width: 4),
                        const Text(
                          'Verify Email',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerBusinessDataAfterVerification(String email) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Completing registration...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // First, log in the user to get access tokens after email verification
      final loginResult = await UnifiedAuthService.signIn(
        email: email,
        password: _passwordController.text,
      );
      
      if (!loginResult['success']) {
        throw Exception('Failed to log in after verification: ${loginResult['message']}');
      }

      // Now get current Cognito user to get the user ID
      final currentUser = await UnifiedAuthService.getCurrentUser();
      if (!currentUser['success']) {
        throw Exception('Failed to get current user');
      }

      final cognitoUserId =
          currentUser['user']['userId'] ?? currentUser['user']['sub'];
      if (cognitoUserId == null) {
        throw Exception('Cognito user ID not found');
      }

      // Prepare address data
      final addressData = {
        'city': _businessCityController.text.trim(),
        'district': _businessDistrictController.text.trim(),
        'country': _businessCountryController.text.trim(),
        'zipcode': _businessZipCodeController.text.trim(), // Fixed: backend expects 'zipcode' not 'zip_code'
        'neighborhood': _businessNeighborhoodController.text.trim(),
        'street': _businessStreetController.text.trim(),
        'home_address': _businessHomeController.text.trim(),
      };

      // Register business data with the backend
      final businessResult = await UnifiedAuthService.registerBusinessData(
        cognitoUserId: cognitoUserId,
        email: email,
        businessName: _businessNameController.text.trim(),
        businessType: _selectedBusinessType ?? 'restaurant',
        ownerName: _ownerNameController.text.trim(),
        phoneNumber: '+964${_phoneController.text.trim()}',
        address: addressData,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!businessResult['success']) {
        throw Exception(
            businessResult['message'] ?? 'Failed to register business data');
      }

      print(
          'Business registration completed successfully: ${businessResult['message']}');
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Business registration failed: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      print('Business registration error: $e');
      // Don't throw here - let the user still proceed to login
      // The business data can be added later if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.businessRegistration),
        backgroundColor: const Color(0xFF00C1E8),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(l10n.businessAndOwnerInformation),
                // Business Type (mandatory)
                DropdownButtonFormField<String>(
                  value: _selectedBusinessType,
                  decoration: InputDecoration(
                    labelText: l10n.businessType,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: 'restaurant',
                      child: Text(l10n.restaurant),
                    ),
                    DropdownMenuItem<String>(
                      value: 'store',
                      child: Text(l10n.store),
                    ),
                    DropdownMenuItem<String>(
                      value: 'pharmacy',
                      child: Text(l10n.pharmacy),
                    ),
                    DropdownMenuItem<String>(
                      value: 'kitchen',
                      child: Text(l10n.cloudKitchen),
                    ),
                  ],
                  onChanged: (newValue) {
                    setState(() {
                      _selectedBusinessType = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? l10n.selectBusinessType : null,
                ),
                const SizedBox(height: 16),
                // Business Name (mandatory)
                TextFormField(
                  controller: _businessNameController,
                  decoration: InputDecoration(
                    labelText: l10n.businessName,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? l10n.pleaseEnterBusinessName : null,
                ),
                const SizedBox(height: 16),
                // Business Owner Name (mandatory)
                TextFormField(
                  controller: _ownerNameController,
                  decoration: InputDecoration(
                    labelText: l10n.ownerName,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? l10n.pleaseEnterOwnerName : null,
                ),
                const SizedBox(height: 16),
                // Email (mandatory)
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.emailAddress,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                // Phone (mandatory - Iraqi only)
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumber,
                    hintText: '7701234567 (10 digits)',
                    prefixText: '+964 ',
                    prefixStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: _validateIraqiPhone,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Only allow digits
                  ],
                ),
                const SizedBox(height: 16),
                // Password (mandatory, no paste)
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  enableInteractiveSelection: false, // Disable copy/paste
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                  validator: _validatePassword,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(
                        RegExp(r'\s')), // No spaces
                  ],
                ),
                const SizedBox(height: 16),
                // Confirm Password (mandatory, no paste)
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_confirmPasswordVisible,
                  enableInteractiveSelection: false, // Disable copy/paste
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)!.confirmPasswordLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: _validateConfirmPassword,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(
                        RegExp(r'\s')), // No spaces
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(l10n.businessAddressLabel),
                TextFormField(
                  controller: _businessCountryController,
                  decoration: InputDecoration(
                    labelText: l10n.country,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: _isLoadingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                                height: 10,
                                width: 10,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : IconButton(
                            icon: const Icon(Icons.my_location),
                            onPressed: _autoFillAddress,
                          ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? l10n.pleaseEnterCountry : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessCityController,
                  decoration: InputDecoration(
                    labelText: l10n.city,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? l10n.pleaseEnterCity : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessDistrictController,
                  decoration: InputDecoration(
                    labelText: l10n.district,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? l10n.pleaseEnterDistrict : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessZipCodeController,
                  decoration: InputDecoration(
                    labelText: l10n.zipCode,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? l10n.pleaseEnterZipCode : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessNeighborhoodController,
                  decoration: InputDecoration(
                    labelText: l10n.neighbourhood,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? l10n.pleaseEnterNeighbourhood : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessStreetController,
                  decoration: InputDecoration(
                    labelText: l10n.street,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? l10n.pleaseEnterStreet : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessHomeController,
                  decoration: InputDecoration(
                    labelText: l10n.buildingNumber,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(l10n.businessOwnerInformation),
                TextFormField(
                  controller: _ownerNationalIdController,
                  decoration: InputDecoration(
                    labelText: l10n.nationalId,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? l10n.pleaseEnterNationalId : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerDateOfBirthController,
                  decoration: InputDecoration(
                    labelText: l10n.dateOfBirth,
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          String formattedDate =
                              DateFormat('yyyy-MM-dd').format(pickedDate);
                          setState(() {
                            _ownerDateOfBirthController.text = formattedDate;
                          });
                        }
                      },
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? l10n.pleaseEnterDateOfBirth : null,
                ),
                const SizedBox(height: 16),
                _buildDocumentUploadCard(
                  title: l10n.ownerNationalId,
                  subtitle: l10n.ownerNationalIdSubtitle,
                  file: _identityFile,
                  onPressed: () =>
                      _pickDocument((file) => _identityFile = file),
                  icon: Icons.badge,
                  isRequired: false,
                ),
                _buildDocumentUploadCard(
                  title: l10n.ownerPhoto,
                  subtitle: l10n.ownerPhotoSubtitle,
                  file: _ownerPhotoFile,
                  onPressed: () => _pickImage((file) => _ownerPhotoFile = file),
                  icon: Icons.camera_alt,
                  isRequired: false,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(l10n.requiredDocuments),
                _buildDocumentUploadCard(
                  title: l10n.commercialLicense,
                  subtitle: l10n.commercialLicenseSubtitle,
                  file: _licenseFile,
                  onPressed: () => _pickDocument((file) => _licenseFile = file),
                  icon: Icons.document_scanner,
                  isRequired: false,
                ),
                _buildDocumentUploadCard(
                  title: l10n.healthCertificate,
                  subtitle: l10n.healthCertificateSubtitle,
                  file: _healthCertificateFile,
                  onPressed: () =>
                      _pickDocument((file) => _healthCertificateFile = file),
                  icon: Icons.health_and_safety,
                  isRequired: false,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF00C1E8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.submitRegistration,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
