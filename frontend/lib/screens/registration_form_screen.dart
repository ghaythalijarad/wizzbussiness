import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/app_auth_service.dart';
import '../services/image_upload_service.dart';
import '../services/document_upload_service.dart';
import '../utils/latin_number_formatter.dart';
import '../models/business.dart';
import '../screens/dashboards/business_dashboard.dart';
import 'login_page.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';

class RegistrationFormScreen extends StatefulWidget {
  const RegistrationFormScreen({Key? key}) : super(key: key);

  @override
  _RegistrationFormScreenState createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  // Form state and text controllers
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showVerificationField = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessCityController = TextEditingController();
  final _businessDistrictController = TextEditingController();
  final _businessCountryController = TextEditingController();
  final _businessStreetController = TextEditingController();

  // Document Files - Optional
  File? _licenseFile;
  File? _identityFile;
  File? _healthCertificateFile;
  File? _ownerPhotoFile;
  File? _businessPhotoFile;

  // Business Type
  String _selectedBusinessType = 'restaurant';

  // Image picker instance
  final ImagePicker _imagePicker = ImagePicker();

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

  String _getBusinessTypeText(String businessType) {
    final loc = AppLocalizations.of(context)!;
    switch (businessType) {
      case 'restaurant':
        return loc.restaurant;
      case 'cloudkitchen':
        return loc.cloudKitchen;
      case 'kitchen':
        return loc.kitchen;
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

  Future<void> _pickDocument(Function(File?) onPicked) async {
    try {
      final loc = AppLocalizations.of(context)!;
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: Text(loc.chooseFromFiles),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                      );

                      if (result != null) {
                        File file = File(result.files.single.path!);
                        onPicked(file);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${loc.errorPickingFile}: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text(loc.takePicture),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final XFile? image = await _imagePicker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 95,
                        maxWidth: 1920,
                        maxHeight: 1920,
                      );
                      if (image != null) {
                        onPicked(File(image.path));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${loc.errorPickingImage}: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.errorPickingFile}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Business photo picker with optimized compression settings:
  // - maxWidth/maxHeight: 1920px for better detail
  // - imageQuality: 95% for less compression
  // - Typical result: 500KB-2MB files with much better quality
  Future<void> _pickBusinessPhoto() async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          final loc = AppLocalizations.of(context)!;
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text(loc.chooseFromGallery),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 95,
                      maxWidth: 1920,
                      maxHeight: 1920,
                    );
                    if (image != null) {
                      setState(() {
                        _businessPhotoFile = File(image.path);
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: Text(loc.takePhoto),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 95,
                      maxWidth: 1920,
                      maxHeight: 1920,
                    );
                    if (image != null) {
                      setState(() {
                        _businessPhotoFile = File(image.path);
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${AppLocalizations.of(context)!.errorPickingImage}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.registerYourBusiness),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Account Information Section
              _buildSectionHeader(loc.accountInformation),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: loc.emailAddress,
                  hintText: loc.enterYourEmail,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterYourEmail;
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return loc.pleaseEnterAValidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: loc.password,
                  hintText: loc.enterYourPassword,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterYourPassword;
                  }
                  if (value.length < 8) {
                    return loc.passwordMustBeAtLeast8Chars;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: loc.confirmPassword,
                  hintText: loc.reEnterYourPassword,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return loc.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Business Information Section
              _buildSectionHeader(loc.businessInformation),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessNameController,
                decoration: InputDecoration(
                  labelText: loc.businessName,
                  hintText: loc.enterYourBusinessName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.store),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterYourBusinessName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Owner First and Last Name
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: loc.ownerFirstName,
                  hintText: loc.enterOwnerFirstName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterOwnerFirstName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: loc.ownerLastName,
                  hintText: loc.enterOwnerLastName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterOwnerLastName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Business Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedBusinessType,
                items: [
                  'restaurant',
                  'cloudkitchen',
                  'kitchen',
                  'store',
                  'pharmacy',
                  'cafe'
                ]
                    .map((type) => DropdownMenuItem(
                        value: type, child: Text(_getBusinessTypeText(type))))
                    .toList(),
                decoration: InputDecoration(
                  labelText: loc.businessType,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) =>
                    setState(() => _selectedBusinessType = value!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: loc.phoneNumber,
                  hintText: loc.enterYourBusinessPhone,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.left,
                textDirection: TextDirection.ltr,
                inputFormatters: [LatinNumberInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterYourPhoneNumber;
                  }
                  return LatinPhoneValidator.validate(value);
                },
              ),
              const SizedBox(height: 32),

              // Business Photo Section
              _buildSectionHeader('${loc.businessPhoto} *'),
              const SizedBox(height: 8),
              Text(
                loc.addAPhotoToShowcaseYourBusiness,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),

              _buildBusinessPhotoCard(),
              const SizedBox(height: 32),

              // Business Address Section
              _buildSectionHeader(loc.businessAddress),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessCityController,
                decoration: InputDecoration(
                  labelText: loc.city,
                  hintText: loc.enterYourCity,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterYourCity;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessDistrictController,
                decoration: InputDecoration(
                  labelText: loc.district,
                  hintText: loc.enterYourDistrict,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.map),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterYourDistrict;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessStreetController,
                decoration: InputDecoration(
                  labelText: loc.streetAddress,
                  hintText: loc.enterYourStreetAddress,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.home),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterYourStreetAddress;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Documents Section (Required)
              _buildSectionHeader('${loc.documentsRequired} *'),
              const SizedBox(height: 8),
              Text(
                loc.pleaseUploadAllRequiredDocuments,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),

              _buildCompactDocumentsGrid(),
              const SizedBox(height: 32),

              // Email Verification Section (Conditional)
              if (_showVerificationField) ...[
                _buildSectionHeader(loc.emailVerification),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        loc.enterTheCodeSentToYourEmail,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showVerificationField = false;
                          _verificationController.clear();
                        });
                      },
                      child: Text(loc.changeEmail),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _verificationController,
                  decoration: InputDecoration(
                    labelText: loc.verificationCode,
                    hintText: loc.enter6DigitCode,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.vpn_key),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (value) {
                    if (_showVerificationField &&
                        (value == null || value.isEmpty)) {
                      return loc.pleaseEnterTheVerificationCode;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _resendVerificationCode,
                  child: Text(loc.resendVerificationCode),
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
                              ? loc.completeRegistration
                              : loc.createAccount,
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

  Widget _buildCompactDocumentsGrid() {
    final loc = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCompactDocumentCard(
                  title: loc.businessLicense,
                  icon: Icons.description,
                  file: _licenseFile,
                  onPressed: () => _pickDocument(
                      (file) => setState(() => _licenseFile = file)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactDocumentCard(
                  title: loc.ownerIdentity,
                  icon: Icons.person,
                  file: _identityFile,
                  onPressed: () => _pickDocument(
                      (file) => setState(() => _identityFile = file)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCompactDocumentCard(
                  title: loc.healthCertificate,
                  icon: Icons.local_hospital,
                  file: _healthCertificateFile,
                  onPressed: () => _pickDocument(
                      (file) => setState(() => _healthCertificateFile = file)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCompactDocumentCard(
                  title: loc.ownerPhoto,
                  icon: Icons.camera_alt,
                  file: _ownerPhotoFile,
                  onPressed: () => _pickDocument(
                      (file) => setState(() => _ownerPhotoFile = file)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDocumentCard({
    required String title,
    required IconData icon,
    required File? file,
    required VoidCallback onPressed,
  }) {
    final bool hasFile = file != null;
    final loc = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasFile ? Colors.green.shade300 : Colors.grey.shade300,
          width: hasFile ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasFile
                            ? Colors.green.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        hasFile ? Icons.check_circle : icon,
                        size: 18,
                        color: hasFile
                            ? Colors.green.shade600
                            : Colors.blue.shade600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasFile ? Colors.green : Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hasFile
                            ? loc.uploaded.toUpperCase()
                            : loc.upload.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      '*',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasFile
                      ? file.path.split('/').last
                      : '${loc.tapToSelectFile} (Required)',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        hasFile ? Colors.green.shade700 : Colors.red.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessPhotoCard() {
    final loc = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular preview of selected business photo (or default icon)
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: _businessPhotoFile != null
                    ? FileImage(_businessPhotoFile!)
                    : null,
                backgroundColor: Colors.grey.shade200,
                child: _businessPhotoFile == null
                    ? Icon(
                        Icons.business,
                        size: 40,
                        color: Colors.grey.shade600,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            loc.businessPhoto,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _businessPhotoFile != null
                            ? _businessPhotoFile!.path.split('/').last
                            : loc.requiredPleaseAddAPhoto,
                        style: TextStyle(
                          fontSize: 14,
                          color: _businessPhotoFile != null
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickBusinessPhoto,
                  icon: Icon(_businessPhotoFile != null
                      ? Icons.change_circle
                      : Icons.camera_alt),
                  label: Text(
                      _businessPhotoFile != null ? loc.change : loc.addPhoto),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _businessPhotoFile != null
                        ? Colors.orange
                        : Colors.blue,
                  ),
                ),
              ],
            ),
            if (_businessPhotoFile != null) ...[
              const SizedBox(height: 12),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _businessPhotoFile!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    final loc = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.pleaseFillInAllRequiredFields),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if business photo is provided (mandatory)
    if (_businessPhotoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.businessPhotoIsRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if all required documents are provided (mandatory)
    if (_licenseFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.businessLicenseRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_identityFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.ownerIdentityRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_healthCertificateFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.healthCertificateRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_ownerPhotoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.ownerPhotoRequired),
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(emailCheckResult.message),
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
          }
          return;
        }

        // Step 2: Upload business photo (required)
        String? businessPhotoUrl;
        try {
          final uploadResult =
              await ImageUploadService.uploadBusinessPhoto(_businessPhotoFile!);
          if (uploadResult['success'] == true) {
            businessPhotoUrl = uploadResult['imageUrl'];
            debugPrint(
                '✅ Business photo uploaded successfully: $businessPhotoUrl');
          } else {
            setState(() => _isLoading = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${loc.failedToUploadBusinessPhoto}: ${uploadResult['message']}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${loc.errorUploadingBusinessPhoto}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Step 3: Upload mandatory documents
        String? licenseUrl, identityUrl, healthCertificateUrl, ownerPhotoUrl;

        try {
          // Upload business license
          final licenseResult =
              await DocumentUploadService.uploadBusinessLicense(_licenseFile!);
          if (licenseResult['success'] == true) {
            licenseUrl = licenseResult['imageUrl'];
            debugPrint('✅ Business license uploaded successfully: $licenseUrl');
          } else {
            setState(() => _isLoading = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${loc.failedToUploadBusinessLicense}: ${licenseResult['message']}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // Upload owner identity
          final identityResult =
              await DocumentUploadService.uploadOwnerIdentity(_identityFile!);
          if (identityResult['success'] == true) {
            identityUrl = identityResult['imageUrl'];
            debugPrint('✅ Owner identity uploaded successfully: $identityUrl');
          } else {
            setState(() => _isLoading = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${loc.failedToUploadOwnerIdentity}: ${identityResult['message']}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // Upload health certificate
          final healthResult =
              await DocumentUploadService.uploadHealthCertificate(
                  _healthCertificateFile!);
          if (healthResult['success'] == true) {
            healthCertificateUrl = healthResult['imageUrl'];
            debugPrint(
                '✅ Health certificate uploaded successfully: $healthCertificateUrl');
          } else {
            setState(() => _isLoading = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${loc.failedToUploadHealthCertificate}: ${healthResult['message']}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // Upload owner photo
          final ownerPhotoResult =
              await DocumentUploadService.uploadOwnerPhoto(_ownerPhotoFile!);
          if (ownerPhotoResult['success'] == true) {
            ownerPhotoUrl = ownerPhotoResult['imageUrl'];
            debugPrint('✅ Owner photo uploaded successfully: $ownerPhotoUrl');
          } else {
            setState(() => _isLoading = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${loc.failedToUploadOwnerPhoto}: ${ownerPhotoResult['message']}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${loc.errorUploadingDocuments}: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Step 4: Register with business data including document URLs
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
          'businessPhotoUrl':
              businessPhotoUrl, // Always included since it's mandatory
          'businessLicenseUrl': licenseUrl,
          'ownerIdentityUrl': identityUrl,
          'healthCertificateUrl': healthCertificateUrl,
          'ownerPhotoUrl': ownerPhotoUrl,
        };

        final registerResult = await AppAuthService.registerWithBusiness(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          businessData: businessData,
        );

        setState(() => _isLoading = false);

        if (registerResult.success) {
          setState(() => _showVerificationField = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.registrationInitiated),
                backgroundColor: Colors.green,
              ),
            );
          }
          // Scroll to verification field
          Future.delayed(const Duration(milliseconds: 300), () {
            final currentContext = _formKey.currentContext;
            if (currentContext != null) {
              Scrollable.ensureVisible(
                currentContext,
                duration: const Duration(milliseconds: 500),
                alignment: 0.5,
              );
            }
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(registerResult.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Step 3: Confirm registration with verification code
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
                    loc.registrationCompletedSuccessfully),
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
                    builder: (context) => const LoginPage(),
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
                  builder: (context) => const LoginPage(),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(confirmResult.message ?? loc.verificationFailed),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.error}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resendVerificationCode() async {
    setState(() => _isLoading = true);
    final loc = AppLocalizations.of(context)!;
    try {
      await AppAuthService.resendRegistrationCode(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(loc.verificationCodeSentTo(_emailController.text.trim())),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.error}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class ArabicPhoneValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    // Updated regex to match Iraqi phone numbers (e.g., 07xxxxxxxxx or +9647xxxxxxxxx)
    // And also general numbers for other regions.
    final phoneRegExp =
        RegExp(r'^(?:\+964|0)?7[3-9]\d{8}$|^[0-9\s\-\(\)]{7,}$');
    if (!phoneRegExp.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }
}
