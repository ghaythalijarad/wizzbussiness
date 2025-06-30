import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../models/discount.dart';
import '../models/order.dart';
import '../models/item_category.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../utils/responsive_helper.dart';

class DiscountManagementPage extends StatefulWidget {
  final Business business;
  final List<Order> orders;
  final VoidCallback? onNavigateToOrders;
  final Function(String, OrderStatus)? onOrderUpdated;

  const DiscountManagementPage({
    Key? key,
    required this.business,
    required this.orders,
    this.onNavigateToOrders,
    this.onOrderUpdated,
  }) : super(key: key);

  @override
  _DiscountManagementPageState createState() => _DiscountManagementPageState();
}

class _DiscountManagementPageState extends State<DiscountManagementPage> {
  String _selectedFilter = 'all';
  final ApiService _apiService = ApiService();
  Business get _business => widget.business;

  List<Discount> get _filteredDiscounts {
    final allDiscounts = _business.discounts;

    switch (_selectedFilter) {
      case 'active':
        return allDiscounts
            .where((d) => d.status == DiscountStatus.active)
            .toList();
      case 'scheduled':
        return allDiscounts
            .where((d) => d.status == DiscountStatus.scheduled)
            .toList();
      case 'expired':
        return allDiscounts
            .where((d) => d.status == DiscountStatus.expired)
            .toList();
      default:
        return allDiscounts;
    }
  }

  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                      AppLocalizations.of(context)!.allDiscounts, 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      AppLocalizations.of(context)!.activeDiscounts, 'active'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      AppLocalizations.of(context)!.scheduledDiscounts,
                      'scheduled'),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      AppLocalizations.of(context)!.expiredDiscounts,
                      'expired'),
                ],
              ),
            ),
          ),
          // Discounts list
          Expanded(
            child: _filteredDiscounts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredDiscounts.length,
                    itemBuilder: (context, index) {
                      final discount = _filteredDiscounts[index];
                      return DiscountCard(
                        discount: discount,
                        onEdit: () => _showEditDiscountDialog(discount),
                        onDelete: () => _showDeleteConfirmationDialog(discount),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDiscountDialog(),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.createDiscount),
        backgroundColor: const Color(0xFFc1e8),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        elevation: isSelected ? 2 : 0.5,
        borderRadius: BorderRadius.circular(16),
        color: isSelected
            ? const Color(0xFFc1e8)
            : const Color(0xFF001133).withValues(alpha: 0.05),
        shadowColor: isSelected
            ? const Color(0xFFc1e8).withValues(alpha: 0.3)
            : const Color(0xFF001133).withValues(alpha: 0.1),
        child: InkWell(
          onTap: () => setState(() {
            _selectedFilter = value;
          }),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFc1e8)
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 64,
            color: const Color(0xFF001133).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noDiscountsCreated,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF001133).withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.createYourFirstDiscount,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF001133).withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }

  void _showCreateDiscountDialog() {
    _showDiscountDialog();
  }

  void _showEditDiscountDialog(Discount discount) {
    _showDiscountDialog(discount: discount);
  }

  void _showDeleteConfirmationDialog(Discount discount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:
              BorderSide(color: const Color(0xFF001133).withValues(alpha: 0.1)),
        ),
        title: Text(
          AppLocalizations.of(context)!.deleteDiscount,
          style: TextStyle(color: const Color(0xFF001133)),
        ),
        content: Text(
          AppLocalizations.of(context)!.areYouSureYouWantToDeleteThisDiscount,
          style:
              TextStyle(color: const Color(0xFF001133).withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF001133).withValues(alpha: 0.7),
            ),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _business.discounts.removeWhere((d) => d.id == discount.id);
              });
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  void _showDiscountDialog({Discount? discount}) {
    final isEditing = discount != null;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: discount?.title ?? '');
    final descriptionController =
        TextEditingController(text: discount?.description ?? '');
    final valueController =
        TextEditingController(text: discount?.value.toString() ?? '');
    final minOrderController = TextEditingController(
        text: discount?.minimumOrderAmount.toString() ?? '');

    // Handle free delivery checkbox state
    var includesFreeDelivery = discount?.type == DiscountType.freeDelivery;
    // If editing a free delivery discount, default the main type to percentage
    var discountType = discount?.type == DiscountType.freeDelivery
        ? DiscountType.percentage
        : (discount?.type ?? DiscountType.percentage);

    // Handle discount applicability
    var applicability =
        discount?.applicability ?? DiscountApplicability.allItems;
    var selectedItemIds = List<String>.from(discount?.applicableItemIds ?? []);
    var selectedCategoryIds =
        List<String>.from(discount?.applicableCategoryIds ?? []);

    // Buy X Get Y specific variables
    final buyXQuantityController = TextEditingController(
        text:
            discount?.conditionalParameters['buyQuantity']?.toString() ?? '1');
    final getYQuantityController = TextEditingController(
        text:
            discount?.conditionalParameters['getQuantity']?.toString() ?? '1');
    var selectedBuyItemId =
        discount?.conditionalParameters['buyItemId'] as String?;
    var selectedGetItemId =
        discount?.conditionalParameters['getItemId'] as String?;

    var startDate = discount?.validFrom ?? DateTime.now();
    var endDate =
        discount?.validTo ?? DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: const Color(0xFF001133).withValues(alpha: 0.1)),
          ),
          title: Text(
            isEditing
                ? AppLocalizations.of(context)!.editDiscount
                : AppLocalizations.of(context)!.createDiscount,
            style: TextStyle(color: const Color(0xFF001133)),
          ),
          content: Container(
            width: ResponsiveHelper.isDesktop(context)
                ? 600
                : ResponsiveHelper.isTablet(context)
                    ? 500
                    : MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.title,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .pleaseEnterTitle;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)!.description,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<DiscountType>(
                                value: discountType,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!
                                      .discountType,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                ),
                                isExpanded: true,
                                items: DiscountType.values
                                    .where((type) =>
                                        type != DiscountType.freeDelivery)
                                    .map((type) {
                                  String label;
                                  switch (type) {
                                    case DiscountType.percentage:
                                      label = AppLocalizations.of(context)!
                                          .percentage;
                                      break;
                                    case DiscountType.fixedAmount:
                                      label = AppLocalizations.of(context)!
                                          .fixedAmount;
                                      break;
                                    case DiscountType.conditional:
                                      label = AppLocalizations.of(context)!
                                          .conditional;
                                      break;
                                    case DiscountType.buyXGetY:
                                      label = AppLocalizations.of(context)!
                                          .buyXGetY;
                                      break;
                                    case DiscountType.others:
                                      label =
                                          AppLocalizations.of(context)!.others;
                                      break;
                                    case DiscountType.freeDelivery:
                                      // This case won't be reached since we filter it out
                                      label = '';
                                      break;
                                  }
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(
                                      label,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      discountType = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: valueController,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.value,
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)!
                                        .pleaseEnterValue;
                                  }
                                  if (double.tryParse(value) == null) {
                                    return AppLocalizations.of(context)!
                                        .pleaseEnterValidNumber;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Buy X Get Y Configuration Section
                        if (discountType == DiscountType.buyXGetY ||
                            discountType == DiscountType.conditional) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFc1e8)
                                  .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFc1e8)
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.shopping_cart,
                                        color: const Color(0xFFc1e8),
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      discountType == DiscountType.conditional
                                          ? AppLocalizations.of(context)!
                                              .conditionalDiscountConfiguration
                                          : AppLocalizations.of(context)!
                                              .buyXGetYConfiguration,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFc1e8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Buy X Configuration
                                Text(
                                  AppLocalizations.of(context)!
                                      .buyConfiguration,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        controller: buyXQuantityController,
                                        decoration: InputDecoration(
                                          labelText:
                                              AppLocalizations.of(context)!
                                                  .quantity,
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return AppLocalizations.of(context)!
                                                .required;
                                          }
                                          if (int.tryParse(value) == null ||
                                              int.parse(value) <= 0) {
                                            return AppLocalizations.of(context)!
                                                .enterValidQuantity;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showBuyItemSelectionDialog(
                                                selectedBuyItemId, (itemId) {
                                          setState(() {
                                            selectedBuyItemId = itemId;
                                          });
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade400),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  selectedBuyItemId == null
                                                      ? AppLocalizations.of(
                                                              context)!
                                                          .selectItem
                                                      : AppLocalizations.of(
                                                              context)!
                                                          .itemSelected,
                                                  style: TextStyle(
                                                    color: selectedBuyItemId ==
                                                            null
                                                        ? Colors.grey.shade600
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                              Icon(Icons.arrow_drop_down,
                                                  color: Colors.grey.shade600),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Get Y Configuration
                                Text(
                                  AppLocalizations.of(context)!
                                      .getConfiguration,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        controller: getYQuantityController,
                                        decoration: InputDecoration(
                                          labelText:
                                              AppLocalizations.of(context)!
                                                  .quantity,
                                          border: const OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return AppLocalizations.of(context)!
                                                .required;
                                          }
                                          if (int.tryParse(value) == null ||
                                              int.parse(value) <= 0) {
                                            return AppLocalizations.of(context)!
                                                .enterValidQuantity;
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showGetItemSelectionDialog(
                                                selectedGetItemId, (itemId) {
                                          setState(() {
                                            selectedGetItemId = itemId;
                                          });
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey.shade400),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  selectedGetItemId == null
                                                      ? AppLocalizations.of(
                                                              context)!
                                                          .selectItem
                                                      : AppLocalizations.of(
                                                              context)!
                                                          .itemSelected,
                                                  style: TextStyle(
                                                    color: selectedGetItemId ==
                                                            null
                                                        ? Colors.grey.shade600
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ),
                                              Icon(Icons.arrow_drop_down,
                                                  color: Colors.grey.shade600),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Discount Applicability Section
                        Opacity(
                          opacity: (discountType == DiscountType.conditional ||
                                  discountType == DiscountType.buyXGetY)
                              ? 0.5
                              : 1.0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  (discountType == DiscountType.conditional ||
                                          discountType == DiscountType.buyXGetY)
                                      ? const Color(0xFFc1e8)
                                          .withValues(alpha: 0.05)
                                      : const Color(0xFFc1e8)
                                          .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: (discountType ==
                                              DiscountType.conditional ||
                                          discountType == DiscountType.buyXGetY)
                                      ? Colors.grey.withValues(alpha: 0.3)
                                      : const Color(0xFFc1e8)
                                          .withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.category,
                                        color: const Color(0xFFc1e8),
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .discountApplicability,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFc1e8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<DiscountApplicability>(
                                  value: applicability,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                  ),
                                  isExpanded: true,
                                  items: DiscountApplicability.values
                                      .where((type) =>
                                          type !=
                                          DiscountApplicability.minimumOrder)
                                      .map((applicabilityType) {
                                    String label;
                                    switch (applicabilityType) {
                                      case DiscountApplicability.allItems:
                                        label = AppLocalizations.of(context)!
                                            .allItems;
                                        break;
                                      case DiscountApplicability.specificItems:
                                        label = AppLocalizations.of(context)!
                                            .specificItems;
                                        break;
                                      case DiscountApplicability
                                          .specificCategories:
                                        label = AppLocalizations.of(context)!
                                            .specificCategories;
                                        break;
                                      case DiscountApplicability.minimumOrder:
                                        label = AppLocalizations.of(context)!
                                            .minimumOrder; // This won't be reached due to filter
                                        break;
                                    }
                                    return DropdownMenuItem(
                                      value: applicabilityType,
                                      child: Text(
                                        label,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  }).toList(),
                                  // Disable for conditional and buyXGetY types
                                  onChanged: (discountType ==
                                              DiscountType.conditional ||
                                          discountType == DiscountType.buyXGetY)
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() {
                                              applicability = value;
                                              // Clear selections when changing applicability
                                              if (value !=
                                                  DiscountApplicability
                                                      .specificItems) {
                                                selectedItemIds.clear();
                                              }
                                              if (value !=
                                                  DiscountApplicability
                                                      .specificCategories) {
                                                selectedCategoryIds.clear();
                                              }
                                            });
                                          }
                                        },
                                ),

                                // Item Selection for Specific Items
                                if (applicability ==
                                    DiscountApplicability.specificItems) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.shopping_basket,
                                                size: 16,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 8),
                                            Text(
                                              AppLocalizations.of(context)!
                                                  .selectItems,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () => _showItemSelectionDialog(
                                              selectedItemIds, setState),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade400),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    selectedItemIds.isEmpty
                                                        ? AppLocalizations.of(
                                                                context)!
                                                            .noItemsSelected
                                                        : '${selectedItemIds.length} items selected',
                                                    style: TextStyle(
                                                      color: selectedItemIds
                                                              .isEmpty
                                                          ? Colors.grey.shade600
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                Icon(Icons.arrow_drop_down,
                                                    color:
                                                        Colors.grey.shade600),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Category Selection for Specific Categories
                                if (applicability ==
                                    DiscountApplicability
                                        .specificCategories) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.folder,
                                                size: 16,
                                                color: Colors.grey.shade600),
                                            const SizedBox(width: 8),
                                            Text(
                                              AppLocalizations.of(context)!
                                                  .selectCategories,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () =>
                                              _showCategorySelectionDialog(
                                                  selectedCategoryIds,
                                                  setState),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade400),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    selectedCategoryIds.isEmpty
                                                        ? AppLocalizations.of(
                                                                context)!
                                                            .noCategoriesSelected
                                                        : '${selectedCategoryIds.length} categories selected',
                                                    style: TextStyle(
                                                      color: selectedCategoryIds
                                                              .isEmpty
                                                          ? Colors.grey.shade600
                                                          : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                Icon(Icons.arrow_drop_down,
                                                    color:
                                                        Colors.grey.shade600),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ), // Close Opacity widget

                        // Add notice for disabled applicability
                        if (discountType == DiscountType.conditional ||
                            discountType == DiscountType.buyXGetY) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.grey.shade600, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .applicabilityNotConfigurable,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: minOrderController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!
                                .minimumOrderAmount(''),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                double.tryParse(value) == null) {
                              return AppLocalizations.of(context)!
                                  .pleaseEnterValidNumber;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: startDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      startDate = pickedDate;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(context)!.startDate,
                                    border: const OutlineInputBorder(),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                        '${startDate.toLocal()}'.split(' ')[0]),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: endDate,
                                    firstDate: startDate,
                                    lastDate: DateTime(2101),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      endDate = pickedDate;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText:
                                        AppLocalizations.of(context)!.endDate,
                                    border: const OutlineInputBorder(),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                        '${endDate.toLocal()}'.split(' ')[0]),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Free Delivery Checkbox
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                Icon(Icons.local_shipping,
                                    color: Colors.green.shade600, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.freeDelivery,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              AppLocalizations.of(context)!
                                  .addFreeDeliveryToDiscount,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                              ),
                            ),
                            value: includesFreeDelivery,
                            onChanged: (bool? value) {
                              setState(() {
                                includesFreeDelivery = value ?? false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Check for conflicting discounts
                  if ((applicability == DiscountApplicability.specificItems &&
                          selectedItemIds.isNotEmpty) ||
                      (applicability ==
                              DiscountApplicability.specificCategories &&
                          selectedCategoryIds.isNotEmpty)) {
                    if (_hasConflictingDiscounts(
                        selectedItemIds, selectedCategoryIds, discount?.id)) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(AppLocalizations.of(context)!
                              .conflictingDiscountsTitle),
                          content: Text(AppLocalizations.of(context)!
                              .someSelectedItemsAlreadyHaveDiscounts),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(AppLocalizations.of(context)!.ok),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                  }

                  // Prepare conditional parameters for Buy X Get Y and Conditional discounts
                  Map<String, dynamic> conditionalParams = {};
                  ConditionalDiscountRule? conditionalRule;

                  if (discountType == DiscountType.buyXGetY ||
                      discountType == DiscountType.conditional) {
                    if (selectedBuyItemId == null ||
                        selectedGetItemId == null) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title:
                              Text(AppLocalizations.of(context)!.missingItems),
                          content: Text(AppLocalizations.of(context)!
                              .missingItemsMessage(discountType ==
                                      DiscountType.conditional
                                  ? AppLocalizations.of(context)!.conditional
                                  : AppLocalizations.of(context)!.buyXGetY)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(AppLocalizations.of(context)!.ok),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    conditionalRule = ConditionalDiscountRule.buyXGetY;
                    conditionalParams = {
                      'buyItemId': selectedBuyItemId,
                      'buyQuantity': int.parse(buyXQuantityController.text),
                      'getItemId': selectedGetItemId,
                      'getQuantity': int.parse(getYQuantityController.text),
                    };
                  }

                  final newDiscount = Discount(
                    id: discount?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descriptionController.text,
                    type: discountType,
                    value: double.parse(valueController.text),
                    applicability: applicability,
                    applicableItemIds: selectedItemIds,
                    applicableCategoryIds: selectedCategoryIds,
                    minimumOrderAmount:
                        double.tryParse(minOrderController.text) ?? 0.0,
                    validFrom: startDate,
                    validTo: endDate,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    status: DiscountStatus.active,
                    conditionalRule: conditionalRule,
                    conditionalParameters: conditionalParams,
                  );

                  // Create free delivery discount if requested
                  Discount? freeDeliveryDiscount;
                  if (includesFreeDelivery && !isEditing) {
                    freeDeliveryDiscount = Discount(
                      id: (DateTime.now().millisecondsSinceEpoch + 1)
                          .toString(),
                      title: AppLocalizations.of(context)!
                          .freeDeliveryTitle(titleController.text),
                      description: AppLocalizations.of(context)!
                          .freeDeliveryIncludedWith(titleController.text),
                      type: DiscountType.freeDelivery,
                      value: 0.0,
                      applicability: applicability,
                      applicableItemIds: selectedItemIds,
                      applicableCategoryIds: selectedCategoryIds,
                      minimumOrderAmount:
                          double.tryParse(minOrderController.text) ?? 0.0,
                      validFrom: startDate,
                      validTo: endDate,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      status: DiscountStatus.active,
                    );
                  }

                  setState(() {
                    if (isEditing) {
                      final index = _business.discounts
                          .indexWhere((d) => d.id == newDiscount.id);
                      if (index != -1) {
                        _business.discounts[index] = newDiscount;
                      }
                    } else {
                      // Check for conflicting discounts before adding
                      if (!_hasConflictingDiscounts(
                          selectedItemIds, selectedCategoryIds, null)) {
                        _business.discounts.add(newDiscount);
                        // Add free delivery discount if created
                        if (freeDeliveryDiscount != null) {
                          _business.discounts.add(freeDeliveryDiscount);
                        }
                      } else {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!
                                .conflictingDiscounts),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  });

                  Navigator.of(context).pop();
                }
              },
              child: Text(isEditing
                  ? AppLocalizations.of(context)!.saveChanges
                  : AppLocalizations.of(context)!.create),
            ),
          ],
        );
      },
    );
  }

  // Add validation method to check for conflicting discounts
  bool _hasConflictingDiscounts(List<String> selectedItemIds,
      List<String> selectedCategoryIds, String? currentDiscountId) {
    final existingDiscounts = _business.discounts.where((d) =>
        d.id != currentDiscountId &&
        d.status == DiscountStatus.active &&
        d.type != DiscountType.freeDelivery);

    for (final discount in existingDiscounts) {
      // Check for item conflicts
      if (discount.applicability == DiscountApplicability.specificItems) {
        for (final itemId in selectedItemIds) {
          if (discount.applicableItemIds.contains(itemId)) {
            return true;
          }
        }
      }

      // Check for category conflicts
      if (discount.applicability == DiscountApplicability.specificCategories) {
        for (final categoryId in selectedCategoryIds) {
          if (discount.applicableCategoryIds.contains(categoryId)) {
            return true;
          }
        }
      }

      // Check if existing discount applies to all items
      if (discount.applicability == DiscountApplicability.allItems &&
          (selectedItemIds.isNotEmpty || selectedCategoryIds.isNotEmpty)) {
        return true;
      }
    }

    return false;
  }

  void _showItemSelectionDialog(
      List<String> selectedItemIds, StateSetter setState) async {
    // Load all available items
    List<ItemCategory> categories = [];
    try {
      categories = await _apiService.getCategories(_business.id);
    } catch (e) {
      print('Error loading categories: $e');
      return;
    }

    // Flatten all items from all categories
    List<Map<String, dynamic>> allItems = [];
    for (final category in categories) {
      for (final item in category.items) {
        allItems.add({
          'id': item.id,
          'name': item.name,
          'categoryName': category.name,
          'price': item.price,
        });
      }
    }

    if (allItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noItemsFound)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(selectedItemIds);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.selectItems),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Text(
                      '${tempSelected.length} ${AppLocalizations.of(context)!.items} selected',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: allItems.length,
                        itemBuilder: (context, index) {
                          final item = allItems[index];
                          final isSelected = tempSelected.contains(item['id']);

                          return CheckboxListTile(
                            dense: true,
                            title: Text(item['name']),
                            subtitle: Text(AppLocalizations.of(context)!
                                .categoryAndPrice(
                                    item['categoryName'],
                                    AppLocalizations.of(context)!.kwd,
                                    item['price'].toStringAsFixed(2))),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true)
                                  tempSelected.add(item['id']);
                                else
                                  tempSelected.remove(item['id']);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedItemIds.clear();
                      selectedItemIds.addAll(tempSelected);
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCategorySelectionDialog(
      List<String> selectedCategoryIds, StateSetter setState) async {
    // Load all available categories
    List<ItemCategory> categories = [];
    try {
      categories = await _apiService.getCategories(_business.id);
    } catch (e) {
      print('Error loading categories: $e');
      return;
    }

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.noCategoriesFound)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(selectedCategoryIds);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.selectCategories),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Text(
                      '${tempSelected.length} ${AppLocalizations.of(context)!.categories} selected',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = tempSelected.contains(category.id);

                          return CheckboxListTile(
                            dense: true,
                            title: Text(category.name),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true)
                                  tempSelected.add(category.id);
                                else
                                  tempSelected.remove(category.id);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCategoryIds.clear();
                      selectedCategoryIds.addAll(tempSelected);
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBuyItemSelectionDialog(
      String? selectedBuyItemId, Function(String?) onItemSelected) async {
    _showSingleItemSelectionDialog(
      selectedBuyItemId,
      AppLocalizations.of(context)!.selectBuyItem,
      onItemSelected,
    );
  }

  void _showGetItemSelectionDialog(
      String? selectedGetItemId, Function(String?) onItemSelected) async {
    _showSingleItemSelectionDialog(
      selectedGetItemId,
      AppLocalizations.of(context)!.selectGetItem,
      onItemSelected,
    );
  }

  void _showSingleItemSelectionDialog(
    String? selectedItemId,
    String title,
    Function(String?) onItemSelected,
  ) async {
    // Load all available items
    List<ItemCategory> categories = [];
    try {
      categories = await _apiService.getCategories(_business.id);
    } catch (e) {
      print('Error loading categories: $e');
      return;
    }

    // Flatten all items from all categories
    List<Map<String, dynamic>> allItems = [];
    for (final category in categories) {
      for (final item in category.items) {
        allItems.add({
          'id': item.id,
          'name': item.name,
          'categoryName': category.name,
          'price': item.price,
        });
      }
    }

    if (allItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noItemsFound)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String? tempSelected = selectedItemId;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    Text(
                      tempSelected != null
                          ? AppLocalizations.of(context)!.itemSelected
                          : AppLocalizations.of(context)!.noItemSelected,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: allItems.length,
                        itemBuilder: (context, index) {
                          final item = allItems[index];
                          return RadioListTile<String>(
                            dense: true,
                            title: Text(item['name']),
                            subtitle: Text(AppLocalizations.of(context)!
                                .categoryAndPrice(
                                    item['categoryName'],
                                    AppLocalizations.of(context)!.kwd,
                                    item['price'].toStringAsFixed(2))),
                            value: item['id'],
                            groupValue: tempSelected,
                            onChanged: (String? value) {
                              setDialogState(() {
                                tempSelected = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () {
                    onItemSelected(tempSelected);
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Top-level widget for individual discount cards
class DiscountCard extends StatelessWidget {
  final Discount discount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DiscountCard({
    Key? key,
    required this.discount,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(discount);
    final statusText = getStatusText(context, discount);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        discount.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Replace placeholder for status text container
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (discount.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    discount.description,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.local_offer,
                        color: Colors.grey.shade500, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      discount.type == DiscountType.percentage
                          ? '${discount.value}% ${AppLocalizations.of(context)!.off}'
                          : discount.type == DiscountType.freeDelivery
                              ? AppLocalizations.of(context)!.freeDelivery
                              : discount.type == DiscountType.fixedAmount
                                  ? '\$${discount.value.toStringAsFixed(2)} ${AppLocalizations.of(context)!.discount}'
                                  : discount.type == DiscountType.others
                                      ? AppLocalizations.of(context)!.others
                                      : '${AppLocalizations.of(context)!.conditional} ${AppLocalizations.of(context)!.discount}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (discount.minimumOrderAmount > 0) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.shopping_cart,
                          color: Colors.grey.shade500, size: 16),
                      const SizedBox(width: 8),
                      Text(
                          'Min: \$${discount.minimumOrderAmount.toStringAsFixed(2)}'),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.category, color: Colors.grey.shade500, size: 16),
                    const SizedBox(width: 8),
                    Text(getLocalizedApplicabilityText(context, discount)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.date_range,
                        color: Colors.grey.shade500, size: 16),
                    const SizedBox(width: 8),
                    Text(
                        'Valid: ${discount.validFrom.day}/${discount.validFrom.month}/${discount.validFrom.year} - ${discount.validTo.day}/${discount.validTo.month}/${discount.validTo.year}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFFc1e8)),
                    onPressed: onEdit,
                  ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String getLocalizedApplicabilityText(BuildContext context, Discount discount) {
  final loc = AppLocalizations.of(context)!;
  switch (discount.applicability) {
    case DiscountApplicability.allItems:
      return loc.appliesToAllItems;
    case DiscountApplicability.specificItems:
      return loc.appliesToSpecificItems(discount.applicableItemIds.length);
    case DiscountApplicability.specificCategories:
      return loc.appliesToCategories(discount.applicableCategoryIds.length);
    case DiscountApplicability.minimumOrder:
      return loc.appliesToMinimumOrder;
  }
}

String getApplicabilityText(Discount discount) {
  // This function needs context for localization, so it should be moved or refactored
  switch (discount.applicability) {
    case DiscountApplicability.allItems:
      return 'Applies to all items'; // Will be replaced with localized version
    case DiscountApplicability.specificItems:
      return 'Applies to ${discount.applicableItemIds.length} specific items'; // Will be replaced
    case DiscountApplicability.specificCategories:
      return 'Applies to ${discount.applicableCategoryIds.length} categories'; // Will be replaced
    case DiscountApplicability.minimumOrder:
      return 'Applies to orders above minimum amount'; // Will be replaced
  }
}

Color getStatusColor(Discount discount) {
  switch (discount.status) {
    case DiscountStatus.active:
      return Colors.green;
    case DiscountStatus.scheduled:
      return Colors.orange;
    case DiscountStatus.expired:
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String getStatusText(BuildContext context, Discount discount) {
  switch (discount.status) {
    case DiscountStatus.active:
      return AppLocalizations.of(context)!.active;
    case DiscountStatus.scheduled:
      return AppLocalizations.of(context)!.scheduled;
    case DiscountStatus.expired:
      return AppLocalizations.of(context)!.expired;
    default:
      return '';
  }
}
