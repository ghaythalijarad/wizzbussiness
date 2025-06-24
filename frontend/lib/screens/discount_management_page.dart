import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/business.dart';
import '../models/discount.dart';
import '../models/order.dart';
import '../services/app_state.dart';

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
                  color: Colors.grey.withOpacity(0.1),
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
        backgroundColor: const Color(0xFF00c1e8),
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
        color: isSelected ? const Color(0xFF00c1e8) : Colors.white,
        shadowColor: isSelected
            ? const Color(0xFF00c1e8).withOpacity(0.3)
            : Colors.grey.withOpacity(0.1),
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
                color:
                    isSelected ? const Color(0xFF00c1e8) : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noDiscountsCreated,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.createYourFirstDiscount,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
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
        title: Text(AppLocalizations.of(context)!.deleteDiscount),
        content: Text(AppLocalizations.of(context)!
            .areYouSureYouWantToDeleteThisDiscount),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _business.discounts.removeWhere((d) => d.id == discount.id);
              });
              Navigator.of(context).pop();
            },
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
    var discountType = discount?.type ?? DiscountType.percentage;
    var startDate = discount?.validFrom ?? DateTime.now();
    var endDate =
        discount?.validTo ?? DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing
              ? AppLocalizations.of(context)!.editDiscount
              : AppLocalizations.of(context)!.createDiscount),
          content: StatefulBuilder(
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
                          labelText: AppLocalizations.of(context)!.description,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<DiscountType>(
                              value: discountType,
                              decoration: InputDecoration(
                                labelText:
                                    AppLocalizations.of(context)!.discountType,
                                border: const OutlineInputBorder(),
                              ),
                              items: DiscountType.values.map((type) {
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
                                  case DiscountType.freeDelivery:
                                    label = AppLocalizations.of(context)!
                                        .freeDelivery;
                                    break;
                                }
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(label),
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: valueController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.value,
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
                                child: Text(
                                    '${startDate.toLocal()}'.split(' ')[0]),
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
                                child:
                                    Text('${endDate.toLocal()}'.split(' ')[0]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newDiscount = Discount(
                    id: discount?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descriptionController.text,
                    type: discountType,
                    value: double.parse(valueController.text),
                    applicability: DiscountApplicability.allItems,
                    minimumOrderAmount:
                        double.tryParse(minOrderController.text) ?? 0.0,
                    validFrom: startDate,
                    validTo: endDate,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    status: DiscountStatus.active,
                  );

                  setState(() {
                    if (isEditing) {
                      final index = _business.discounts
                          .indexWhere((d) => d.id == newDiscount.id);
                      if (index != -1) {
                        _business.discounts[index] = newDiscount;
                      }
                    } else {
                      _business.discounts.add(newDiscount);
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
            color: Colors.grey.withOpacity(0.1),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
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
                          : '\$${discount.value.toStringAsFixed(2)} ${AppLocalizations.of(context)!.discount}',
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
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
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
