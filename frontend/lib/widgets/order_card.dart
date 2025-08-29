import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../utils/responsive_helper.dart';
import '../core/design_system/design_system.dart';

class OrderCard extends ConsumerWidget {
  final Order order;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final Function(String, OrderStatus)? onOrderUpdated;

  const OrderCard({
    Key? key,
    required this.order,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.onComplete,
    this.onOrderUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(isMobile ? GoldenRatio.md : GoldenRatio.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(GoldenRatio.lg),
          border: Border.all(
            color: _getStatusColor(order.status).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              spreadRadius: 2,
              blurRadius: GoldenRatio.md,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(GoldenRatio.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8)}',
                    style: TypographySystem.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: GoldenRatio.lg, vertical: GoldenRatio.xs),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(GoldenRatio.xl),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: TypographySystem.labelMedium.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: GoldenRatio.lg),

              // Customer Info
              Row(
                children: [
                  Icon(Icons.person,
                      size: GoldenRatio.lg, color: AppColors.onSurfaceVariant),
                  SizedBox(width: GoldenRatio.md),
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: TypographySystem.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: GoldenRatio.md),

              // Phone
              if (order.customerPhone?.isNotEmpty ?? false) ...[
                Row(
                  children: [
                    Icon(Icons.phone,
                        size: GoldenRatio.lg,
                        color: AppColors.onSurfaceVariant),
                    SizedBox(width: GoldenRatio.md),
                    Text(
                      order.customerPhone!,
                      style: TypographySystem.bodyMedium.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: GoldenRatio.md),
              ],

              // Items
              Container(
                padding: EdgeInsets.all(GoldenRatio.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(GoldenRatio.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items (${order.items.length})',
                      style: TypographySystem.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: GoldenRatio.md),
                    ...order.items.take(3).map((item) => Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: GoldenRatio.xs),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.quantity}x ${item.name}',
                                  style: TypographySystem.bodySmall.copyWith(
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                style: TypographySystem.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (order.items.length > 3) ...[
                      SizedBox(height: GoldenRatio.xs),
                      Text(
                        '+ ${order.items.length - 3} more items',
                        style: TypographySystem.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: GoldenRatio.lg),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TypographySystem.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: TypographySystem.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: GoldenRatio.lg),

              // Time
              Text(
                'Ordered ${_formatTime(order.createdAt)}',
                style: TypographySystem.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),

              // Action Buttons
              if (order.status == OrderStatus.pending) ...[
                SizedBox(height: GoldenRatio.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(GoldenRatio.md),
                          ),
                          padding: EdgeInsets.symmetric(vertical: GoldenRatio.lg),
                        ),
                        child: Text(
                          'Reject',
                          style: TypographySystem.labelLarge.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: GoldenRatio.lg),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(GoldenRatio.md),
                          ),
                          padding:
                              EdgeInsets.symmetric(vertical: GoldenRatio.lg),
                        ),
                        child: Text(
                          'Accept',
                          style: TypographySystem.labelLarge.copyWith(
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (order.status == OrderStatus.ready) ...[
                SizedBox(height: GoldenRatio.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(GoldenRatio.md),
                      ),
                      padding: EdgeInsets.symmetric(vertical: GoldenRatio.lg),
                    ),
                    child: Text(
                      'Mark as Completed',
                      style: TypographySystem.labelLarge.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.info;
      case OrderStatus.preparing:
        return AppColors.secondary;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.completed:
        return AppColors.successContainer;
      case OrderStatus.cancelled:
        return AppColors.error;
      case OrderStatus.expired:
        return AppColors.onSurfaceVariant;
      case OrderStatus.onTheWay:
        return AppColors.primary;
      case OrderStatus.delivered:
        return AppColors.secondary;
      case OrderStatus.returned:
        return AppColors.errorContainer;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.expired:
        return 'Expired';
      case OrderStatus.onTheWay:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.returned:
        return 'Returned';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
