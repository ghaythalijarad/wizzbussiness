import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../core/theme/app_colors.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';
import '../services/image_upload_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider_riverpod.dart';

// Provider for loading state
final addProductLoadingProvider = StateProvider<bool>((ref) => false);

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  String? _selectedCategoryId;
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Load categories when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productProviderRiverpod.notifier).loadCategories('restaurant');
    });
  }

  Future<void> _pickImage() async {
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
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
              // Modern App Bar
              _buildModernAppBar(),

              // Content
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final productState = ref.watch(productProviderRiverpod);
                    final isLoading = ref.watch(addProductLoadingProvider);

                    return Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(GoldenRatio.spacing20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            _buildHeaderSection(),
                            SizedBox(height: GoldenRatio.spacing24),
                            
                            // Product Image Section
                            _buildImageSection(),
                            SizedBox(height: GoldenRatio.spacing24),

                            // Product Details Section
                            _buildProductDetailsSection(productState),
                            SizedBox(height: GoldenRatio.spacing24),

                            // Add Product Button
                            _buildAddProductButton(isLoading),
                            
                            // Bottom spacing
                            SizedBox(height: GoldenRatio.spacing24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a product image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref.read(addProductLoadingProvider.notifier).state = true;

    try {
      // First upload the image
      final uploadResult = await ImageUploadService.uploadProductImage(_selectedImage!);
      
      if (!uploadResult['success']) {
        throw Exception(uploadResult['message'] ?? 'Image upload failed');
      }
      
      final imageUrl = uploadResult['imageUrl'] as String;

      final product = Product(
        id: '', // Will be set by backend
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        categoryId: _selectedCategoryId!,
        imageUrls: [imageUrl], // Use the uploaded image URL
        isAvailable: true,
        businessId: '', // Will be set by backend based on authenticated user
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success =
          await ref.read(productProviderRiverpod.notifier).addProduct(product);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        final currentState = ref.read(productProviderRiverpod);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to add product: ${currentState.errorMessage ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(addProductLoadingProvider.notifier).state = false;
      }
    }
  }

  Widget _buildModernAppBar() {
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
                  'Add Product',
                  style: TypographySystem.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Create a new product for your menu',
                  style: TypographySystem.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(GoldenRatio.spacing20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(GoldenRatio.spacing12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
            ),
            child: Icon(
              Icons.add_box_rounded,
              color: AppColors.primary,
              size: GoldenRatio.spacing24,
            ),
          ),
          SizedBox(width: GoldenRatio.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Information',
                  style: TypographySystem.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: GoldenRatio.spacing4),
                Text(
                  'Add details, image, and pricing for your new product',
                  style: TypographySystem.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      padding: EdgeInsets.all(GoldenRatio.spacing20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        border: Border.all(
          color: AppColors.border,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image_rounded,
                color: AppColors.primary,
                size: GoldenRatio.spacing20,
              ),
              SizedBox(width: GoldenRatio.spacing8),
              Text(
                'Product Image',
                style: TypographySystem.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: GoldenRatio.spacing16),
          if (_selectedImage != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: GoldenRatio.spacing12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.edit_rounded, size: GoldenRatio.spacing16),
                    label: Text('Change Image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding:
                          EdgeInsets.symmetric(vertical: GoldenRatio.spacing12),
                    ),
                  ),
                ),
                SizedBox(width: GoldenRatio.spacing12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _removeImage,
                    icon:
                        Icon(Icons.delete_rounded, size: GoldenRatio.spacing16),
                    label: Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      padding:
                          EdgeInsets.symmetric(vertical: GoldenRatio.spacing12),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.backgroundVariant,
                  borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                  border: Border.all(
                    color: AppColors.border,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(GoldenRatio.spacing16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_rounded,
                        color: AppColors.primary,
                        size: GoldenRatio.textHeadline,
                      ),
                    ),
                    SizedBox(height: GoldenRatio.spacing12),
                    Text(
                      'Tap to add product image',
                      style: TypographySystem.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: GoldenRatio.spacing4),
                    Text(
                      'JPG, PNG • Max 5MB',
                      style: TypographySystem.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductDetailsSection(dynamic productState) {
    return Container(
      padding: EdgeInsets.all(GoldenRatio.spacing20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        border: Border.all(
          color: AppColors.border,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_rounded,
                color: AppColors.primary,
                size: GoldenRatio.spacing20,
              ),
              SizedBox(width: GoldenRatio.spacing8),
              Text(
                'Product Details',
                style: TypographySystem.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: GoldenRatio.spacing20),

          // Product Name
          _buildFormField(
            controller: _nameController,
            label: 'Product Name',
            hint: 'Enter product name',
            icon: Icons.shopping_bag_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter product name';
              }
              return null;
            },
          ),
          SizedBox(height: GoldenRatio.spacing20),

          // Description
          _buildFormField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Enter product description',
            icon: Icons.description_rounded,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter product description';
              }
              return null;
            },
          ),
          SizedBox(height: GoldenRatio.spacing20),

          // Category
          _buildCategoryDropdown(productState),
          SizedBox(height: GoldenRatio.spacing20),

          // Price
          _buildFormField(
            controller: _priceController,
            label: 'Price',
            hint: 'Enter price',
            icon: Icons.attach_money_rounded,
            keyboardType: TextInputType.number,
            prefixText: '\$',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter price';
              }
              final price = double.tryParse(value);
              if (price == null || price <= 0) {
                return 'Please enter a valid price';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TypographySystem.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: GoldenRatio.spacing8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TypographySystem.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixIcon: Icon(icon, color: AppColors.primary),
            hintStyle: TypographySystem.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.backgroundVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
              borderSide: BorderSide(color: AppColors.error),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: GoldenRatio.spacing16,
              vertical: GoldenRatio.spacing16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(dynamic productState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TypographySystem.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: GoldenRatio.spacing8),
        DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          style: TypographySystem.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Select a category',
            prefixIcon: Icon(Icons.category_rounded, color: AppColors.primary),
            hintStyle: TypographySystem.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.backgroundVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
              borderSide: BorderSide(color: AppColors.error),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: GoldenRatio.spacing16,
              vertical: GoldenRatio.spacing16,
            ),
          ),
          items: () {
            // Remove duplicate categories based on ID
            final Map<String, ProductCategory> uniqueCategories = {};
            for (final category in productState.categories) {
              uniqueCategories[category.id] = category;
            }
            return uniqueCategories.values.map((category) {
              return DropdownMenuItem<String>(
                value: category.id,
                child: Text(category.name),
              );
            }).toList();
          }(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAddProductButton(bool isLoading) {
    return Container(
      width: double.infinity,
      height: 56.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: GoldenRatio.spacing12,
            offset: Offset(0, GoldenRatio.spacing4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
          onTap: isLoading ? null : _addProduct,
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: GoldenRatio.spacing20,
                    height: GoldenRatio.spacing20,
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.surface),
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: AppColors.surface,
                        size: GoldenRatio.spacing20,
                      ),
                      SizedBox(width: GoldenRatio.spacing8),
                      Text(
                        'Add Product',
                        style: TypographySystem.bodyLarge.copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
