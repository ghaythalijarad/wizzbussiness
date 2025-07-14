import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import '../services/app_auth_service.dart';

class RegistrationFormScreen extends StatefulWidget {
  const RegistrationFormScreen({Key? key}) : super(key: key);

  @override
  _RegistrationFormScreenState createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showVerificationField = false;

  // User Account Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationController = TextEditingController();

  // Business Information Controllers
  final _businessNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Business Address Controllers
  final _businessCityController = TextEditingController();
  final _businessDistrictController = TextEditingController();
  final _businessCountryController = TextEditingController();
  final _businessStreetController = TextEditingController();

  // Document Files - Optional
  File? _licenseFile;
  File? _identityFile;
  File? _healthCertificateFile;
  File? _ownerPhotoFile;

  // Business Type
  String _selectedBusinessType = 'restaurant';

  @override
  void initState() {
    super.initState();
    _businessCountryController.text = 'Iraq';
    // default selections
    _selectedBusinessType = 'restaurant';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationController.dispose();
    _businessNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _businessCityController.dispose();
    _businessDistrictController.dispose();
    _businessCountryController.dispose();
    _businessStreetController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(Function(File?) onPicked) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        onPicked(file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your Business'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(
                Icons.business_center,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Create Your Business Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Account Information Section
              _buildSectionHeader('Account Information'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Business Information Section
              _buildSectionHeader('Business Information'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Business Name',
                  hintText: 'Enter your business name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your business name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Owner First and Last Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Owner First Name',
                  hintText: 'Enter owner first name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter owner first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Owner Last Name',
                  hintText: 'Enter owner last name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter owner last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Business Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBusinessType,
                items: ['restaurant','cloudkitchen','kitchen','store','pharmacy','cafe']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Business Type',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _selectedBusinessType = value!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your business phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Business Address Section
              _buildSectionHeader('Business Address'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessCityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'Enter your city',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessDistrictController,
                decoration: const InputDecoration(
                  labelText: 'District',
                  hintText: 'Enter your district/area',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your district';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessStreetController,
                decoration: const InputDecoration(
                  labelText: 'Street Address',
                  hintText: 'Enter your street address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your street address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Documents Section (Optional)
              _buildSectionHeader('Documents (Optional)'),
              const SizedBox(height: 8),
              const Text(
                'You can upload these documents now or later',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              _buildDocumentUploadCard(
                title: 'Business License',
                file: _licenseFile,
                onPressed: () => _pickDocument(
                    (file) => setState(() => _licenseFile = file)),
              ),
              const SizedBox(height: 12),

              _buildDocumentUploadCard(
                title: 'Owner Identity',
                file: _identityFile,
                onPressed: () => _pickDocument(
                    (file) => setState(() => _identityFile = file)),
              ),
              const SizedBox(height: 12),

              _buildDocumentUploadCard(
                title: 'Health Certificate',
                file: _healthCertificateFile,
                onPressed: () => _pickDocument(
                    (file) => setState(() => _healthCertificateFile = file)),
              ),
              const SizedBox(height: 12),

              _buildDocumentUploadCard(
                title: 'Owner Photo',
                file: _ownerPhotoFile,
                onPressed: () => _pickDocument(
                    (file) => setState(() => _ownerPhotoFile = file)),
              ),
              const SizedBox(height: 32),

              // Email Verification Section (Conditional)
              if (_showVerificationField) ...[
                _buildSectionHeader('Email Verification'),
                const SizedBox(height: 16),
                const Text(
                  'Please enter the verification code sent to your email:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _verificationController,
                  decoration: const InputDecoration(
                    labelText: 'Verification Code',
                    hintText: 'Enter 6-digit code',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (value) {
                    if (_showVerificationField &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter the verification code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _resendVerificationCode,
                  child: const Text('Resend Verification Code'),
                ),
                const SizedBox(height: 32),
              ],

              // Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _showVerificationField
                              ? 'Complete Registration'
                              : 'Create Account',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required File? file,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
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
                  const SizedBox(height: 4),
                  Text(
                    file != null
                        ? file.path.split('/').last
                        : 'No file selected',
                    style: TextStyle(
                      fontSize: 14,
                      color: file != null ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(file != null ? Icons.change_circle : Icons.upload),
              label: Text(file != null ? 'Change' : 'Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: file != null ? Colors.orange : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!_showVerificationField) {
        // Step 1: Check if email exists
        final emailCheckResult = await AppAuthService.checkEmailExists(
          email: _emailController.text.trim(),
        );

        if (emailCheckResult.exists) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(emailCheckResult.message),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Login Instead',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
              ),
            ),
          );
          return;
        }

        // Step 2: Register with business data
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
        };

        final registerResult = await AppAuthService.registerWithBusiness(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          businessData: businessData,
        );

        setState(() => _isLoading = false);

        if (registerResult.success) {
          setState(() => _showVerificationField = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Registration initiated! Please check your email for verification code.'),
              backgroundColor: Colors.green,
            ),
          );
          // Scroll to verification field
          Future.delayed(const Duration(milliseconds: 300), () {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 500),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(registerResult.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Step 3: Confirm registration with verification code
        final confirmResult = await AppAuthService.confirmRegistration(
          email: _emailController.text.trim(),
          confirmationCode: _verificationController.text.trim(),
        );

        setState(() => _isLoading = false);

        if (confirmResult.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(confirmResult.message ??
                  'Registration completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to home screen
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendVerificationCode() async {
    try {
      await AppAuthService.resendRegistrationCode(
        email: _emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resending code: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
