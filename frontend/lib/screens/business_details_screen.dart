import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/latin_number_formatter.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';

class BusinessDetailsScreen extends StatefulWidget {
  final TextEditingController businessNameController;
  final TextEditingController ownerNameController;
  final TextEditingController phoneController;
  final TextEditingController businessCityController;
  final TextEditingController businessDistrictController;
  final TextEditingController businessStreetController;
  final Function(File?) onLicensePicked;
  final Function(File?) onIdentityPicked;
  final Function(File?) onHealthCertificatePicked;
  final Function(File?) onOwnerPhotoPicked;
  final VoidCallback onSubmit;
  final File? licenseFile;
  final File? identityFile;
  final File? healthCertificateFile;
  final File? ownerPhotoFile;
  final GlobalKey<FormState>? formKey;

  const BusinessDetailsScreen({
    Key? key,
    required this.businessNameController,
    required this.ownerNameController,
    required this.phoneController,
    required this.businessCityController,
    required this.businessDistrictController,
    required this.businessStreetController,
    required this.onLicensePicked,
    required this.onIdentityPicked,
    required this.onHealthCertificatePicked,
    required this.onOwnerPhotoPicked,
    required this.onSubmit,
    this.licenseFile,
    this.identityFile,
    this.healthCertificateFile,
    this.ownerPhotoFile,
    this.formKey,
  }) : super(key: key);

  @override
  _BusinessDetailsScreenState createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickDocument(Function(File?) onPicked) async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('Choose from Files'),
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
                      // Handle error
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Picture'),
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
                      // Handle error
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: widget.formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.business_outlined,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                loc.businessInformation,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                loc.tellUsAboutYourBusiness,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: widget.businessNameController,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
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
              TextFormField(
                controller: widget.ownerNameController,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: loc.ownerName,
                  hintText: loc.enterOwnerName,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.pleaseEnterOwnerName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.phoneController,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
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
              const SizedBox(height: 24),
              Text(
                loc.businessAddress,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.businessCityController,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
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
                controller: widget.businessDistrictController,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
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
                controller: widget.businessStreetController,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
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
              Text(
                loc.documentsRequired,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.pleaseUploadAllRequiredDocuments,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              _buildDocumentUploadCard(
                title: loc.businessLicense,
                file: widget.licenseFile,
                onPressed: () => _pickDocument(widget.onLicensePicked),
              ),
              _buildDocumentUploadCard(
                title: loc.ownerIdentity,
                file: widget.identityFile,
                onPressed: () => _pickDocument(widget.onIdentityPicked),
              ),
              _buildDocumentUploadCard(
                title: loc.healthCertificate,
                file: widget.healthCertificateFile,
                onPressed: () =>
                    _pickDocument(widget.onHealthCertificatePicked),
              ),
              _buildDocumentUploadCard(
                title: loc.ownerPhoto,
                file: widget.ownerPhotoFile,
                onPressed: () => _pickDocument(widget.onOwnerPhotoPicked),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: widget.onSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  loc.emailVerification,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentUploadCard({
    required String title,
    required File? file,
    required VoidCallback onPressed,
  }) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
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
            const SizedBox(height: 12),
            if (file != null) Text(file.path.split('/').last),
            if (file == null)
              Text(
                loc.required,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(file != null ? Icons.change_circle : Icons.upload),
              label: Text(file != null ? loc.changeFile : loc.selectFile),
            ),
          ],
        ),
      ),
    );
  }
}
