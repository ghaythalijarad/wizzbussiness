import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../l10n/app_localizations.dart';
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
    final showActionButtons = order.status == OrderStatus.pending ||
        order.status == OrderStatus.confirmed ||
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.onTheWay;

    // Responsive spacing and layout
    final horizontalPadding = ResponsiveHelper.getResponsivePadding(context);

    // Define the custom pink color #C6007E
    const customPinkColor = Color(0xFFC6007E);

    return Card(
      margin: EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: ResponsiveHelper.isMobile(context) ? 0 : 8.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: order.status == OrderStatus.pending
              ? customPinkColor
              : customPinkColor.withOpacity(0.4),
          width: order.status == OrderStatus.pending ? 2.0 : 1.5,
        ),
      ),
      elevation: 2.0,
      shadowColor: customPinkColor.withOpacity(0.1),
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
              if (showActionButtons) _buildActionButtons(context, loc),
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
            color: _getStatusColor(order.status).withValues(alpha: 0.1),
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
                Text('IQD ${item.price.toStringAsFixed(2)}'),
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
          'IQD ${order.totalAmount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        children: [
          if (order.status == OrderStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        onOrderUpdated(order.id, OrderStatus.cancelled),
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
                    onPressed: () =>
                        onOrderUpdated(order.id, OrderStatus.confirmed),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text(loc.accept),
                  ),
                ),
              ],
            ),
          ] else if (order.status == OrderStatus.confirmed) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        onOrderUpdated(order.id, OrderStatus.preparing),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: Text(loc.preparing),
                  ),
                ),
              ],
            ),
          ] else if (order.status == OrderStatus.preparing) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        onOrderUpdated(order.id, OrderStatus.ready),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC6007E),
                    ),
                    child: Text(loc.orderReady),
                  ),
                ),
              ],
            ),
          ] else if (order.status == OrderStatus.ready) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        onOrderUpdated(order.id, OrderStatus.onTheWay),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: Text(loc.onTheWay),
                  ),
                ),
              ],
            ),
          ] else if (order.status == OrderStatus.onTheWay) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        onOrderUpdated(order.id, OrderStatus.delivered),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text(loc.delivered),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    // Define custom colors with better hue consistency
    const customPinkColor = Color(0xFFC6007E);

    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFFF8C00); // Dark orange for better contrast
      case OrderStatus.confirmed:
        return const Color(0xFF00A86B); // Sea green for confirmed
      case OrderStatus.ready:
        return customPinkColor; // Use the main pink theme for ready orders
      case OrderStatus.onTheWay:
        return const Color(0xFF2196F3); // Blue for on the way
      case OrderStatus.delivered:
        return const Color(0xFF6A5ACD); // Slate blue for delivered
      case OrderStatus.cancelled:
        return const Color(0xFFDC143C); // Crimson red for cancelled
      case OrderStatus.expired:
        return const Color(0xFF708090); // Slate gray for expired
      case OrderStatus.returned:
        return const Color(0xFF8B4513); // Saddle brown for returned
      default:
        return const Color(0xFF2F4F4F); // Dark slate gray as default
    }
  }

  String _getStatusText(OrderStatus status, AppLocalizations loc) {
    switch (status) {
      case OrderStatus.pending:
        return loc.pending;
      case OrderStatus.confirmed:
        return loc.confirmed;
      case OrderStatus.preparing:
        return loc.preparing;
      case OrderStatus.ready:
        return loc.orderReady;
      case OrderStatus.onTheWay:
        return loc.onTheWay;
      case OrderStatus.delivered:
        return loc.delivered;
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
