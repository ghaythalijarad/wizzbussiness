import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/business.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/image_upload_service.dart';
import '../providers/business_provider.dart';
import '../providers/session_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';
import 'login_page.dart';

class BusinessDetailsScreen extends ConsumerStatefulWidget {
  final Business business;

  const BusinessDetailsScreen({Key? key, required this.business})
      : super(key: key);

  @override
  ConsumerState<BusinessDetailsScreen> createState() =>
      _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends ConsumerState<BusinessDetailsScreen> {
  late TextEditingController _businessNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _descriptionController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final business = widget.business;
    _businessNameController = TextEditingController(text: business.name);
    _ownerNameController =
        TextEditingController(text: business.ownerName ?? '');
    _phoneController = TextEditingController(text: business.phone ?? '');
    _emailController = TextEditingController(text: business.email);
    _descriptionController =
        TextEditingController(text: business.description ?? '');
    _websiteController = TextEditingController(text: business.website ?? '');
    _addressController = TextEditingController(text: business.address ?? '');
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(GoldenRatio.radiusXl),
                topRight: Radius.circular(GoldenRatio.radiusXl),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.1),
                  blurRadius: GoldenRatio.spacing24,
                  offset: Offset(0, -GoldenRatio.spacing8),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(GoldenRatio.spacing24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: GoldenRatio.spacing24 * 2,
                      height: GoldenRatio.spacing4,
                      decoration: BoxDecoration(
                        color: AppColors.onSurfaceVariant.withOpacity(0.3),
                        borderRadius:
                            BorderRadius.circular(GoldenRatio.spacing4),
                      ),
                    ),
                    SizedBox(height: GoldenRatio.spacing20),
                    // Title
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(GoldenRatio.spacing12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.secondary.withOpacity(0.1),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(GoldenRatio.radiusMd),
                          ),
                          child: Icon(
                            Icons.photo_camera_rounded,
                            color: AppColors.primary,
                            size: GoldenRatio.spacing20,
                          ),
                        ),
                        SizedBox(width: GoldenRatio.spacing16),
                        Text(
                          'Update Business Photo',
                          style: TypographySystem.headlineSmall.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: GoldenRatio.spacing24),
                    // Gallery option
                    _buildPhotoOption(
                      icon: Icons.photo_library_rounded,
                      title: 'Choose from Gallery',
                      subtitle: 'Select an existing photo',
                      color: AppColors.secondary,
                      onTap: () async {
                        Navigator.pop(context);
                        await _pickImageFromGallery();
                      },
                    ),
                    SizedBox(height: GoldenRatio.spacing16),
                    // Camera option
                    _buildPhotoOption(
                      icon: Icons.camera_alt_rounded,
                      title: 'Take Photo',
                      subtitle: 'Use camera to take a new photo',
                      color: AppColors.primary,
                      onTap: () async {
                        Navigator.pop(context);
                        await _pickImageFromCamera();
                      },
                    ),
                    SizedBox(height: GoldenRatio.spacing16),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      _showSnackBar('Error selecting photo option: $e', isError: true);
    }
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: GoldenRatio.spacing8,
            offset: Offset(0, GoldenRatio.spacing4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
          child: Padding(
            padding: EdgeInsets.all(GoldenRatio.spacing20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(GoldenRatio.spacing12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: GoldenRatio.spacing20,
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: GoldenRatio.spacing4),
                      Text(
                        subtitle,
                        style: TypographySystem.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: GoldenRatio.spacing20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadBusinessPhoto();
      }
    } catch (e) {
      _showSnackBar('Error picking image from gallery: $e', isError: true);
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadBusinessPhoto();
      }
    } catch (e) {
      _showSnackBar('Error taking photo: $e', isError: true);
    }
  }

  Future<void> _uploadBusinessPhoto() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final session = ref.read(sessionProvider);
      if (!session.isAuthenticated) {
        _showAuthenticationRequiredDialog();
        return;
      }

      // Use static method with correct signature
      final response =
          await ImageUploadService.uploadBusinessPhoto(_selectedImage!);
      final photoUrl = response['url'] as String;

      final apiService = ApiService();
      await apiService.updateBusinessPhoto(widget.business.id, photoUrl);

      // Update business object locally
      widget.business.updateProfile(businessPhotoUrl: photoUrl);

      // Refresh business provider
      ref.invalidate(businessProvider);

      setState(() {
        _selectedImage = null;
        _isUploadingPhoto = false;
      });

      _showSnackBar('Business photo updated successfully!');
    } catch (e) {
      setState(() {
        _selectedImage = null;
        _isUploadingPhoto = false;
      });
      _showSnackBar('Failed to upload photo: $e', isError: true);
    }
  }

  Future<void> _saveBusinessProfile() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final session = ref.read(sessionProvider);
      if (!session.isAuthenticated) {
        _showAuthenticationRequiredDialog();
        return;
      }

      final apiService = ApiService();
      final updateData = {
        'businessName': _businessNameController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'website': _websiteController.text.trim(),
        'address': _addressController.text.trim(),
      };

      await apiService.updateBusinessProfile(widget.business.id, updateData);

      // Update business object locally
      widget.business.updateProfile(
        name: _businessNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        phone: _phoneController.text.trim(),
        description: _descriptionController.text.trim(),
        website: _websiteController.text.trim(),
        address: _addressController.text.trim(),
      );

      // Refresh business provider
      ref.invalidate(businessProvider);

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      _showSnackBar('Business profile updated successfully!');
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showSnackBar('Failed to update profile: $e', isError: true);
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers if canceling edit
        _initializeControllers();
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showAuthenticationRequiredDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.security,
          color: const Color(0xFF00C1E8),
          size: 48,
        ),
        title: Text(
          'Authentication Required',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        content: Text(
          loc.pleaseSignInToAccessLocationSettings,
          style: TextStyle(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF00C1E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(loc.signIn),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final business = widget.business;

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
              // Modern App Bar
              _buildModernAppBar(l10n),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(GoldenRatio.spacing20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business Header Card
                      _buildBusinessHeaderCard(business),
                      SizedBox(height: GoldenRatio.spacing24),
                      // Business Details Section
                      _buildDetailsTab(l10n, business),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernAppBar(AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: GoldenRatio.spacing20,
        vertical: GoldenRatio.spacing16,
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
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SizedBox(width: GoldenRatio.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.businessDetails,
                  style: TypographySystem.headlineSmall.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Manage your business profile',
                  style: TypographySystem.bodyMedium.copyWith(
                    color: AppColors.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (!_isEditing)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.secondary, AppColors.secondaryDark],
                ),
                borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.3),
                    blurRadius: GoldenRatio.spacing8,
                    offset: Offset(0, GoldenRatio.spacing4),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.edit_rounded, color: AppColors.onSecondary),
                onPressed: _toggleEditMode,
              ),
            ),
          if (_isEditing) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: IconButton(
                icon: Icon(Icons.close_rounded,
                    color: AppColors.onSurfaceVariant),
                onPressed: _toggleEditMode,
              ),
            ),
            SizedBox(width: GoldenRatio.spacing12),
            Container(
              decoration: BoxDecoration(
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
              child: IconButton(
                icon: _isSaving
                    ? SizedBox(
                        width: GoldenRatio.spacing20,
                        height: GoldenRatio.spacing20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Icon(Icons.check_rounded, color: AppColors.onPrimary),
                onPressed: _isSaving ? null : _saveBusinessProfile,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBusinessHeaderCard(Business business) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(GoldenRatio.spacing24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: GoldenRatio.spacing20,
            offset: Offset(0, GoldenRatio.spacing8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _HeaderPatternPainter(),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(GoldenRatio.spacing24),
            child: Row(
              children: [
                // Business Photo
                Stack(
                  children: [
                    Container(
                      width: GoldenRatio.spacing24 * 4,
                      height: GoldenRatio.spacing24 * 4,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface.withOpacity(0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow.withOpacity(0.2),
                            blurRadius: GoldenRatio.spacing20,
                            offset: Offset(0, GoldenRatio.spacing8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _selectedImage != null
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                            : business.businessPhotoUrl != null &&
                                    business.businessPhotoUrl!.isNotEmpty
                                ? Image.network(
                                    business.businessPhotoUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildDefaultBusinessIcon();
                                    },
                                  )
                                : _buildDefaultBusinessIcon(),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingPhoto ? null : _pickImage,
                        child: Container(
                          padding: EdgeInsets.all(GoldenRatio.spacing8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow.withOpacity(0.2),
                                blurRadius: GoldenRatio.spacing8,
                                offset: Offset(0, GoldenRatio.spacing4),
                              ),
                            ],
                          ),
                          child: _isUploadingPhoto
                              ? SizedBox(
                                  width: GoldenRatio.spacing16,
                                  height: GoldenRatio.spacing16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onSecondary,
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt_rounded,
                                  color: AppColors.onSecondary,
                                  size: GoldenRatio.spacing16,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: GoldenRatio.spacing20),
                // Business Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.name,
                        style: TypographySystem.headlineMedium.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: GoldenRatio.spacing8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: GoldenRatio.spacing16,
                          vertical: GoldenRatio.spacing8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(GoldenRatio.spacing20),
                        ),
                        child: Text(
                          business.businessType.name.toUpperCase(),
                          style: TypographySystem.labelSmall.copyWith(
                            color: AppColors.onSecondary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      SizedBox(height: GoldenRatio.spacing12),
                      // Status indicators
                      Row(
                        children: [
                          _buildStatusChip(
                            business.status == 'approved'
                                ? 'Active'
                                : 'Pending',
                            business.status == 'approved',
                          ),
                          SizedBox(width: GoldenRatio.spacing8),
                          _buildStatusChip('Verified', true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultBusinessIcon() {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Icon(
        Icons.business_rounded,
        size: GoldenRatio.spacing24 * 1.5,
        color: AppColors.onPrimary,
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: GoldenRatio.spacing12,
        vertical: GoldenRatio.spacing8,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withOpacity(0.2)
            : AppColors.warning.withOpacity(0.2),
        borderRadius: BorderRadius.circular(GoldenRatio.spacing16),
        border: Border.all(
          color: isActive ? AppColors.success : AppColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: GoldenRatio.spacing8,
            height: GoldenRatio.spacing8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.success : AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: GoldenRatio.spacing8),
          Text(
            label,
            style: TypographySystem.labelSmall.copyWith(
              color: isActive ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(AppLocalizations l10n, Business business) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(GoldenRatio.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information Card
          _buildModernCard(
            title: l10n.businessInformation,
            icon: Icons.business_rounded,
            children: [
              _buildFormField(
                label: l10n.businessName,
                controller: _businessNameController,
                icon: Icons.store_rounded,
                enabled: _isEditing,
              ),
              SizedBox(height: GoldenRatio.spacing20),
              _buildFormField(
                label: l10n.ownerName,
                controller: _ownerNameController,
                icon: Icons.person_rounded,
                enabled: _isEditing,
              ),
              SizedBox(height: GoldenRatio.spacing20),
              _buildFormField(
                label: l10n.emailAddress,
                controller: _emailController,
                icon: Icons.email_rounded,
                enabled: false, // Email should not be editable
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: GoldenRatio.spacing20),
              _buildFormField(
                label: l10n.phoneNumber,
                controller: _phoneController,
                icon: Icons.phone_rounded,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          SizedBox(height: GoldenRatio.spacing24),

          // Business Details Card
          _buildModernCard(
            title: 'Business Details',
            icon: Icons.description_rounded,
            children: [
              _buildFormField(
                label: 'Description',
                controller: _descriptionController,
                icon: Icons.description_rounded,
                enabled: _isEditing,
                maxLines: 3,
              ),
              SizedBox(height: GoldenRatio.spacing20),
              _buildFormField(
                label: 'Website',
                controller: _websiteController,
                icon: Icons.language_rounded,
                enabled: _isEditing,
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        border: Border.all(
          color: AppColors.border.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            blurRadius: GoldenRatio.spacing24,
            offset: Offset(0, GoldenRatio.spacing8),
          ),
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.02),
            blurRadius: GoldenRatio.spacing4,
            offset: Offset(0, GoldenRatio.spacing4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(GoldenRatio.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(GoldenRatio.spacing12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        AppColors.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: GoldenRatio.spacing20,
                  ),
                ),
                SizedBox(width: GoldenRatio.spacing16),
                Text(
                  title,
                  style: TypographySystem.headlineSmall.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: GoldenRatio.spacing24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TypographySystem.bodyLarge.copyWith(
        color: enabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TypographySystem.bodyMedium.copyWith(
          color: enabled
              ? AppColors.onSurfaceVariant
              : AppColors.onSurfaceVariant.withOpacity(0.6),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          margin: EdgeInsets.all(GoldenRatio.spacing8),
          padding: EdgeInsets.all(GoldenRatio.spacing8),
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.1),
                    ],
                  )
                : null,
            color: enabled ? null : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
            border: Border.all(
              color: enabled
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.border.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: enabled
                ? AppColors.primary
                : AppColors.onSurfaceVariant.withOpacity(0.5),
            size: GoldenRatio.spacing20,
          ),
        ),
        filled: true,
        fillColor: enabled
            ? AppColors.surface
            : AppColors.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
          borderSide: BorderSide(
            color: AppColors.border.withOpacity(0.2),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
          borderSide: BorderSide(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
          borderSide: BorderSide(
            color: AppColors.border.withOpacity(0.1),
            width: 1,
          ),
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: GoldenRatio.spacing20,
          vertical: GoldenRatio.spacing16,
        ),
      ),
    );
  }
}

class _HeaderPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw geometric pattern
    for (int i = 0; i < size.width ~/ 20; i++) {
      for (int j = 0; j < size.height ~/ 20; j++) {
        if ((i + j) % 3 == 0) {
          canvas.drawCircle(
            Offset(i * 20.0 + 10, j * 20.0 + 10),
            2,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
