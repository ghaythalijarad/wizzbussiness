import 'package:flutter/material.dart';
import '../models/dish.dart';
import '../models/item_category.dart';
import '../models/order.dart';
import '../models/business.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ItemsManagementPage extends StatefulWidget {
  final Business business;
  final List<Order> orders;
  final VoidCallback? onNavigateToOrders;
  final Function(String, OrderStatus)? onOrderUpdated;

  const ItemsManagementPage({
    Key? key,
    required this.business,
    required this.orders,
    this.onNavigateToOrders,
    this.onOrderUpdated,
  }) : super(key: key);

  @override
  _ItemsManagementPageState createState() => _ItemsManagementPageState();
}

class _ItemsManagementPageState extends State<ItemsManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ItemCategory> _categories = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_filterItems);
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories(widget.business.id);
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      // Handle error
      print(e);
    }
  }

  void _filterItems() {
    setState(() {});
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        business: widget.business,
        apiService: _apiService,
        onItemAdded: (category, item) {
          _loadCategories();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.itemAddedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showEditItemDialog(Dish item) {
    showDialog(
      context: context,
      builder: (context) => EditItemDialog(
        dish: item,
        business: widget.business,
        apiService: _apiService,
        onItemUpdated: (dish) {
          _loadCategories();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.itemUpdatedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.items),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
            tooltip: loc.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: loc.search,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _categories.isEmpty
                ? Center(child: Text(loc.noItemsFound))
                : ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _buildCategorySection(category);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        backgroundColor: const Color(0xFF00c1e8),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategorySection(ItemCategory category) {
    final query = _searchController.text.toLowerCase();
    final items = category.items.where((item) {
      return item.name.toLowerCase().contains(query);
    }).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(category.name,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        ...items.map((item) {
          return ListTile(
            title: Text(item.name),
            subtitle: Text('${loc.currency} ${item.price.toStringAsFixed(2)}'),
            onTap: () => _showEditItemDialog(item),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == loc.edit.toLowerCase()) {
                  _showEditItemDialog(item);
                } else if (value == loc.delete.toLowerCase()) {
                  _showDeleteConfirmation(item);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: loc.edit.toLowerCase(), child: Text(loc.edit)),
                PopupMenuItem(
                    value: loc.delete.toLowerCase(), child: Text(loc.delete)),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showDeleteConfirmation(Dish item) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteItem),
        content: Text(loc.deleteItemConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteItem(item);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }

  void _deleteItem(Dish item) async {
    try {
      await _apiService.deleteItem(item.id);
      _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.itemDeletedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Handle error
      print(e);
    }
  }
}

class AddItemDialog extends StatefulWidget {
  final Business business;
  final ApiService apiService;
  final Function(ItemCategory category, Dish item) onItemAdded;

  const AddItemDialog({
    Key? key,
    required this.business,
    required this.apiService,
    required this.onItemAdded,
  }) : super(key: key);

  @override
  _AddItemDialogState createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _newCategoryController = TextEditingController();

  XFile? _imageFile;
  String? _selectedCategoryId;
  bool _isAvailable = true;
  bool _showNewCategoryField = false;
  List<ItemCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.apiService.getCategories(widget.business.id);
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = image;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.addNewItem),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _imageFile != null
                  ? Image.file(File(_imageFile!.path), height: 150)
                  : const SizedBox(height: 0),
              TextButton.icon(
                icon: const Icon(Icons.photo_camera),
                label: Text(loc.uploadImage),
                onPressed: _pickImage,
              ),
              if (!_showNewCategoryField)
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: loc.selectCategory,
                    border: const OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) =>
                      value == null && !_showNewCategoryField
                          ? loc.pleaseSelectCategory
                          : null,
                ),
              if (_showNewCategoryField)
                TextFormField(
                  controller: _newCategoryController,
                  decoration: InputDecoration(
                    labelText: loc.newCategoryName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true && _showNewCategoryField
                          ? loc.pleaseEnterCategoryName
                          : null,
                ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showNewCategoryField = !_showNewCategoryField;
                  });
                },
                child: Text(_showNewCategoryField
                    ? loc.selectExistingCategory
                    : loc.addNewCategory),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.itemName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? loc.pleaseEnterItemName : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: loc.description,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: loc.price,
                  border: const OutlineInputBorder(),
                  prefixText: 'KWD ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return loc.pleaseEnterPrice;
                  if (double.tryParse(value!) == null) {
                    return loc.pleaseEnterValidPrice;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: '${loc.imageUrl} (${loc.optional})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(loc.available),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _addItem,
          child: Text(loc.add),
        ),
      ],
    );
  }

  void _addItem() async {
    if (_formKey.currentState!.validate()) {
      try {
        ItemCategory? category;
        if (_showNewCategoryField) {
          category = await widget.apiService.createCategory(
              widget.business.id, _newCategoryController.text);
        } else {
          category = _categories.firstWhere((c) => c.id == _selectedCategoryId);
        }

        final newItem = Dish(
          id: 'dish-${DateTime.now().millisecondsSinceEpoch}', // The backend will generate the ID
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          categoryId: category.id,
          isAvailable: _isAvailable,
          imageUrl: _imageUrlController.text,
          businessId: widget.business.id,
        );

        final createdItem = await widget.apiService.createItem(category.id, newItem);

        if (_imageFile != null) {
          final imageUrl = await widget.apiService.uploadItemImage(createdItem.id, _imageFile!);
          createdItem.imageUrl = imageUrl;
          await widget.apiService.updateItem(createdItem);
        }

        widget.onItemAdded(category, createdItem);
        Navigator.of(context).pop();
      } catch (e) {
        print(e);
        // Show error message
      }
    }
  }
}

class EditItemDialog extends StatefulWidget {
  final Dish dish;
  final Business business;
  final ApiService apiService;
  final Function(Dish item) onItemUpdated;

  const EditItemDialog({
    Key? key,
    required this.dish,
    required this.business,
    required this.apiService,
    required this.onItemUpdated,
  }) : super(key: key);

  @override
  _EditItemDialogState createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;

  String? _selectedCategoryId;
  late bool _isAvailable;
  List<ItemCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dish.name);
    _descriptionController =
        TextEditingController(text: widget.dish.description);
    _priceController =
        TextEditingController(text: widget.dish.price.toString());
    _imageUrlController =
        TextEditingController(text: widget.dish.imageUrl ?? '');
    _isAvailable = widget.dish.isAvailable;
    _selectedCategoryId = widget.dish.categoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await widget.apiService.getCategories(widget.business.id);
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print(e);
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(loc.editItem),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: loc.selectCategory,
                  border: const OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                validator: (value) =>
                    value == null ? loc.pleaseSelectCategory : null,
              ),
              const SizedBox(height: 16),

              // Item name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.itemName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? loc.pleaseEnterItemName : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: loc.description,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: loc.price,
                  border: const OutlineInputBorder(),
                  prefixText: 'KWD ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return loc.pleaseEnterPrice;
                  if (double.tryParse(value!) == null) {
                    return loc.pleaseEnterValidPrice;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image URL (optional)
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: '${loc.imageUrl} (${loc.optional})',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Availability toggle
              SwitchListTile(
                title: Text(loc.available),
                value: _isAvailable,
                onChanged: (value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: _updateItem,
          child: Text(loc.update),
        ),
      ],
    );
  }

  void _updateItem() async {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      final updatedDish = Dish(
        id: widget.dish.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        isAvailable: _isAvailable,
        categoryId: _selectedCategoryId!,
        businessId: widget.business.id,
      );

      try {
        final item = await widget.apiService.updateItem(updatedDish);
        widget.onItemUpdated(item);
        Navigator.of(context).pop();
      } catch (e) {
        print(e);
      }
    }
  }
}
