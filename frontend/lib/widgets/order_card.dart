import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../l10n/app_localizations.dart';
import '../services/order_timer_service.dart';
import '../utils/responsive_helper.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final Function(String, OrderStatus) onOrderUpdated;

  const OrderCard({
    Key? key,
    required this.order,
    required this.onOrderUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isPending = order.status == OrderStatus.pending;
    final remainingSeconds =
        isPending ? OrderTimerService.getRemainingSeconds(order.id) : 0;
    final isExpired = isPending && remainingSeconds <= 0;

    // Responsive spacing and layout
    final horizontalPadding = ResponsiveHelper.getResponsivePadding(context);

    return Card(
      margin: EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: ResponsiveHelper.isMobile(context) ? 0 : 8.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isPending ? Colors.orange.shade300 : Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      elevation: 2.0,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveHelper.getCardWidth(context),
        ),
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, loc),
              const SizedBox(height: 12),
              _buildCustomerDetails(context, loc),
              const SizedBox(height: 12),
              _buildOrderItems(context, loc),
              const SizedBox(height: 12),
              if (order.notes != null && order.notes!.isNotEmpty)
                _buildNotes(context, loc),
              if (order.notes != null && order.notes!.isNotEmpty)
                const SizedBox(height: 12),
              const Divider(height: 24),
              _buildFooter(context, loc),
              if (isPending) _buildActionButtons(context, loc, isExpired),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '#${order.id}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(order.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getStatusText(order.status, loc),
            style: TextStyle(
              color: _getStatusColor(order.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDetails(BuildContext context, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.customerName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('d MMM y, h:mm a').format(order.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildOrderItems(BuildContext context, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.items,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...order.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${item.quantity}x ${item.dishName}'),
                Text('KWD ${item.price.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(BuildContext context, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.notes,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          order.notes!,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations loc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          loc.total,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          'KWD ${order.totalAmount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, AppLocalizations loc, bool isExpired) {
    final remainingSeconds = OrderTimerService.getRemainingSeconds(order.id);
    final minutes = (remainingSeconds / 60).floor();
    final seconds = remainingSeconds % 60;
    final timerText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        children: [
          if (!isExpired)
            Center(
              child: Text(
                timerText,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isExpired
                      ? null
                      : () => onOrderUpdated(order.id, OrderStatus.cancelled),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: Text(loc.reject),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isExpired
                      ? null
                      : () => onOrderUpdated(order.id, OrderStatus.confirmed),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text(loc.accept),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.green;
      case OrderStatus.ready:
        return Colors.blue;
      case OrderStatus.pickedUp:
        return Colors.purple;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.expired:
        return Colors.grey;
      case OrderStatus.returned:
        return Colors.brown;
      default:
        return Colors.black;
    }
  }

  String _getStatusText(OrderStatus status, AppLocalizations loc) {
    switch (status) {
      case OrderStatus.pending:
        return loc.pending;
      case OrderStatus.confirmed:
        return loc.confirmed;
      case OrderStatus.ready:
        return loc.orderReady;
      case OrderStatus.pickedUp:
        return loc.pickedUp;
      case OrderStatus.cancelled:
        return loc.cancelled;
      case OrderStatus.expired:
        return loc.expired;
      case OrderStatus.returned:
        return loc.orderReturned;
      default:
        return '';
    }
  }
}
