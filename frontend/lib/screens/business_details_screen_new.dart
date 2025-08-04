import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/latin_number_formatter.dart';

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
              const Text(
                'Business Information',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Step 2 of 3: Tell us about your business',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: widget.businessNameController,
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
              TextFormField(
                controller: widget.ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Owner Name',
                  hintText: 'Enter the owner\'s full name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the owner name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your business phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.left,
                textDirection: TextDirection.ltr,
                inputFormatters: [LatinNumberInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return LatinPhoneValidator.validate(value);
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Business Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: widget.businessCityController,
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
                controller: widget.businessDistrictController,
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
                controller: widget.businessStreetController,
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
              const Text(
                'Required Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please upload all required documents to complete registration',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              _buildDocumentUploadCard(
                title: 'License',
                file: widget.licenseFile,
                onPressed: () => _pickDocument(widget.onLicensePicked),
              ),
              _buildDocumentUploadCard(
                title: 'Identity',
                file: widget.identityFile,
                onPressed: () => _pickDocument(widget.onIdentityPicked),
              ),
              _buildDocumentUploadCard(
                title: 'Health Certificate',
                file: widget.healthCertificateFile,
                onPressed: () =>
                    _pickDocument(widget.onHealthCertificatePicked),
              ),
              _buildDocumentUploadCard(
                title: 'Owner Photo',
                file: widget.ownerPhotoFile,
                onPressed: () => _pickDocument(widget.onOwnerPhotoPicked),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: widget.onSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Continue to Email Verification',
                  style: TextStyle(fontSize: 16),
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
              const Text(
                'Required - Please select a file',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(file != null ? Icons.change_circle : Icons.upload),
              label:
                  Text(file != null ? 'Change File' : 'Select Required File'),
            ),
          ],
        ),
      ),
    );
  }
}
