import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/wizz_business_button.dart';
import '../widgets/wizz_business_text_form_field.dart';
import '../l10n/app_localizations.dart';

class AddProductScreen extends StatefulWidget {
  final List<ProductCategory> categories;

  const AddProductScreen({
    super.key,
    required this.categories,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedCategoryFilter = 'all'; // Add category filter state
  bool _isAvailable = true;
  bool _isLoading = false;

  // Get filtered categories based on selected filter
  List<ProductCategory> get _filteredCategories {
    if (_selectedCategoryFilter == 'all') {
      return widget.categories;
    }
    
    // Filter categories by name (for demonstration - can be enhanced)
    return widget.categories.where((category) {
      final categoryName = category.name.toLowerCase();
      switch (_selectedCategoryFilter) {
        case 'electronics':
          return categoryName.contains('electronic') || categoryName.contains('tech');
        case 'clothing':
          return categoryName.contains('clothing') || categoryName.contains('apparel');
        case 'food':
          return categoryName.contains('food') || categoryName.contains('drink');
        case 'home':
          return categoryName.contains('home') || categoryName.contains('garden');
        default:
          return true;
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    print('AddProductScreen: initState called');
    print(
        'AddProductScreen: Initial _selectedCategoryId: $_selectedCategoryId');
    print('AddProductScreen: Categories passed: ${widget.categories.length}');

    // Debug category data
    for (int i = 0; i < widget.categories.length; i++) {
      final category = widget.categories[i];
      print(
          'AddProductScreen: Category $i - ID: "${category.id}", Name: "${category.name}"');
    }
    
    // Pre-select first category if available and none is selected
    if (widget.categories.isNotEmpty && _selectedCategoryId == null) {
      // Get only valid categories (with non-empty ID and name)
      final validCategories = widget.categories
          .where((cat) => cat.id.isNotEmpty && cat.name.isNotEmpty)
          .toList();
      
      if (validCategories.isNotEmpty) {
        _selectedCategoryId = validCategories.first.id;
        print('AddProductScreen: Pre-selected first valid category: ${validCategories.first.id}');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  String? _getValidDropdownValue() {
    print(
        'AddProductScreen: Validating dropdown value - Selected ID: "$_selectedCategoryId"');
    print(
        'AddProductScreen: Filtered categories available: ${_filteredCategories.length}');

    // If no selection or empty string, return null
    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      print('AddProductScreen: Selected ID is null or empty, returning null');
      return null;
    }

    // Check if the selected category exists in the valid filtered categories list
    // (only categories with non-empty ID and name)
    final validCategories = _filteredCategories
        .where((cat) => cat.id.isNotEmpty && cat.name.isNotEmpty)
        .toList();
    
    final categoryExists = validCategories.any((cat) => cat.id == _selectedCategoryId);
    
    if (categoryExists) {
      print('AddProductScreen: Selected category exists, returning: $_selectedCategoryId');
      return _selectedCategoryId;
    } else {
      print('AddProductScreen: Selected category does not exist in valid filtered categories, returning null');
      return null;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot create product: No categories available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ProductService.createProduct(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _selectedCategoryId!,
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        isAvailable: _isAvailable,
      );

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create product: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Product name is required';
    }
    if (value.trim().length < 2) {
      return 'Product name must be at least 2 characters';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Product description is required';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    return null;
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }

    final price = double.tryParse(value.trim());
    if (price == null) {
      return 'Please enter a valid price';
    }

    if (price <= 0) {
      return 'Price must be greater than 0';
    }

    if (price > 9999.99) {
      return 'Price cannot exceed \$9999.99';
    }

    return null;
  }

  String? _validateImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Image URL is optional
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedCategoryFilter == value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        elevation: isSelected ? 2 : 0.5,
        borderRadius: BorderRadius.circular(16),
        color: isSelected
            ? const Color(0xFF00C1E8)
            : const Color(0xFF001133).withValues(alpha: 0.05),
        shadowColor: isSelected
            ? const Color(0xFF00C1E8).withValues(alpha: 0.3)
            : const Color(0xFF001133).withValues(alpha: 0.1),
        child: InkWell(
          onTap: () => setState(() {
            _selectedCategoryFilter = value;
            // Reset category selection when filter changes
            _selectedCategoryId = null;
          }),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00C1E8)
                    : const Color(0xFF001133).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF001133),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug information
    print('AddProductScreen: Categories count: ${widget.categories.length}');
    print(
        'AddProductScreen: Categories: ${widget.categories.map((c) => '${c.id}: ${c.name}').toList()}');
    print('AddProductScreen: Selected category ID: $_selectedCategoryId');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Category Filter Carousel
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('All Categories', 'all'),
                  const SizedBox(width: 6),
                  _buildFilterChip('Electronics', 'electronics'),
                  const SizedBox(width: 6),
                  _buildFilterChip('Clothing', 'clothing'),
                  const SizedBox(width: 6),
                  _buildFilterChip('Food & Drinks', 'food'),
                  const SizedBox(width: 6),
                  _buildFilterChip('Home & Garden', 'home'),
                ],
              ),
            ),
          ),
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Product Name
                    WizzBusinessTextFormField(
                      controller: _nameController,
                      labelText: 'Product Name *',
                      prefixIcon: const Icon(Icons.shopping_bag),
                      validator: _validateName,
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    WizzBusinessTextFormField(
                      controller: _descriptionController,
                      labelText: 'Description *',
                      prefixIcon: const Icon(Icons.description),
                      validator: _validateDescription,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Price
                    WizzBusinessTextFormField(
                      controller: _priceController,
                      labelText: 'Price (\$) *',
                      prefixIcon: const Icon(Icons.attach_money),
                      validator: _validatePrice,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category Selection
                    if (_filteredCategories.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          border: Border.all(color: Colors.orange[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[600]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No categories available for the selected filter.',
                                style: TextStyle(color: Colors.orange[800]),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.category, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _getValidDropdownValue(),
                                  hint: const Text(
                                      'Select Category *'),
                                  isExpanded: true,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedCategoryId = newValue;
                                      print(
                                          'AddProductScreen: Category selection changed to: $newValue');
                                    });
                                  },
                                  items: _filteredCategories.isNotEmpty
                                      ? _filteredCategories
                                          .where((category) => 
                                              category.id.isNotEmpty && 
                                              category.name.isNotEmpty)
                                          .map((category) {
                                          print(
                                              'AddProductScreen: Creating dropdown item - ID: "${category.id}", Name: "${category.name}"');
                                          return DropdownMenuItem<String>(
                                            value: category.id,
                                            child: Text(category.name),
                                          );
                                        }).toList()
                                      : [
                                          const DropdownMenuItem<String>(
                                            value: null,
                                            child: Text('No categories available'),
                                          ),
                                        ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Image URL (Optional)
                    WizzBusinessTextFormField(
                      controller: _imageUrlController,
                      labelText: 'Image URL (Optional)',
                      prefixIcon: const Icon(Icons.image),
                      validator: _validateImageUrl,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),

                    // Availability Toggle
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Product Availability',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _isAvailable
                                      ? 'Product will be available for orders'
                                      : 'Product will be hidden from customers',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isAvailable,
                            onChanged: (bool value) {
                              setState(() {
                                _isAvailable = value;
                              });
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : WizzBusinessButton(
                            onPressed: _saveProduct,
                            text: 'Add Product',
                          ),
                    const SizedBox(height: 16),

                    // Cancel Button
                    OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
