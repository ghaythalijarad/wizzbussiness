import 'package:flutter/material.dart';
import '../models/discount.dart';
import '../l10n/app_localizations.dart';

/// Stateless widget extracting the UI for a single discount card.
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
    final statusColor = _getStatusColor(discount);
    final statusText = _getStatusText(context, discount);
    final loc = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discount.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (discount.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          discount.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (discount.type == DiscountType.freeDelivery) ...[
                        Icon(Icons.local_shipping,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          loc.freeDelivery,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ] else ...[
                        Icon(Icons.percent, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          discount.type == DiscountType.percentage
                              ? '${discount.value}% ${AppLocalizations.of(context)!.off}'
                              : '\$${discount.value.toStringAsFixed(2)} ${AppLocalizations.of(context)!.discount}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (discount.minimumOrderAmount > 0) ...[
                        Icon(Icons.shopping_cart,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          loc.minimumOrderAmount(
                              '\$${discount.minimumOrderAmount.toStringAsFixed(2)}'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${loc.validityPeriod}: ${discount.validFrom.day}/${discount.validFrom.month}/${discount.validFrom.year} - ${discount.validTo.day}/${discount.validTo.month}/${discount.validTo.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(AppLocalizations.of(context)!.edit),
                  style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF007fff)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 16),
                  label: Text(AppLocalizations.of(context)!.delete),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(Discount discount) {
    switch (discount.status) {
      case DiscountStatus.expired:
        return Colors.red.shade400;
      case DiscountStatus.scheduled:
        return Colors.orange.shade400;
      case DiscountStatus.active:
        return Colors.green.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  String _getStatusText(BuildContext context, Discount discount) {
    final loc = AppLocalizations.of(context)!;
    switch (discount.status) {
      case DiscountStatus.expired:
        return loc.expired;
      case DiscountStatus.scheduled:
        return loc.scheduled;
      case DiscountStatus.active:
        return loc.active;
      default:
        return loc.unknownStatus;
    }
  }
}
