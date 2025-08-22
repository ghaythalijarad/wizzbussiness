import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../l10n/app_localizations.dart';
import '../utils/responsive_helper.dart';
import '../services/realtime_order_service.dart';
import '../theme/theme_extensions.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  final Function(String, OrderStatus) onOrderUpdated;
  final bool initiallyExpanded;

  const OrderCard({
    Key? key,
    required this.order,
    required this.onOrderUpdated,
    this.initiallyExpanded = false,
  }) : super(key: key);

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _expanded = false;
  final RealtimeOrderService _realtimeService = RealtimeOrderService();

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    if (_expanded) _subscribeIfNeeded();
  }

  @override
  void didUpdateWidget(covariant OrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) {
      // Unsubscribe old
      _unsubscribe(oldWidget.order.id);
      // Subscribe new if expanded
      if (_expanded) _subscribeIfNeeded();
    }
    // Auto-collapse & unsubscribe if order reached terminal status
    if (_isTerminal(widget.order.status)) {
      _unsubscribe(widget.order.id);
      if (mounted && _expanded) setState(() => _expanded = false);
    }
  }

  bool _isTerminal(OrderStatus s) {
    switch (s) {
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
      case OrderStatus.returned:
      case OrderStatus.expired:
        return true;
      default:
        return false;
    }
  }

  void _subscribeIfNeeded() {
    if (!_isTerminal(widget.order.status)) {
      _realtimeService.subscribeToOrderDetail(widget.order.id);
    }
  }

  void _unsubscribe(String orderId) {
    _realtimeService.unsubscribeFromOrderDetail(orderId);
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _subscribeIfNeeded();
    } else {
      _unsubscribe(widget.order.id);
    }
  }

  @override
  void dispose() {
    _unsubscribe(widget.order.id);
    super.dispose();
  }

  Order get order => widget.order;
  Function(String, OrderStatus) get onOrderUpdated => widget.onOrderUpdated;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final showActionButtons = order.status == OrderStatus.pending ||
        order.status == OrderStatus.confirmed ||
        order.status == OrderStatus.ready;

    final horizontalPadding = ResponsiveHelper.getResponsivePadding(context);
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
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.getCardWidth(context),
            ),
            child: Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, loc),
                  if (_expanded) ...[
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations loc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order #',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 11)),
              const SizedBox(height: 2),
              Text(order.id,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context
                          .getStatusColor(order.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(order.status, loc),
                      style: TextStyle(
                          color: context.getStatusColor(order.status),
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20, color: Colors.grey.shade600),
                ],
              ),
              if (order.status == OrderStatus.pending && _expanded) ...[
                const SizedBox(height: 4),
                _buildTimeoutIndicator(context),
              ],
            ],
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
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('d MMM y, h:mm a').format(order.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildOrderItems(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 18,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                loc.items,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...order.items.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 6.0),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  // Quantity badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C1E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Item name
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.dishName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Price
                  Text(
                    'IQD ${item.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC6007E),
                        ),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
        Container(
          width: double.infinity,
          child: Text(
            order.notes!,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations loc) {
    return Row(
      children: [
        Expanded(
          child: Text(
            loc.total,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'IQD ${order.totalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations loc) {
    // Check if order should be auto-rejected due to timeout
    final shouldAutoReject =
        order.timeoutStatus == OrderTimeoutStatus.autoReject;
    
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        children: [
          if (order.status == OrderStatus.pending && !shouldAutoReject) ...[
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(loc.accept),
                  ),
                ),
              ],
            ),
          ] else if (order.status == OrderStatus.pending &&
              shouldAutoReject) ...[
            // Show disabled buttons and auto-reject message when order should be auto-rejected
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Order automatically rejected due to timeout',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: null, // Disabled
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text(loc.reject),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: null, // Disabled
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.grey.shade600,
                        ),
                        child: Text(loc.accept),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else if (order.status == OrderStatus.confirmed) ...[
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
          ],
        ],
      ),
    );
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

  /// Build timeout indicator widget for pending orders
  Widget _buildTimeoutIndicator(BuildContext context) {
    final timeoutStatus = order.timeoutStatus;
    final timeoutMessage = order.getTimeoutMessage(context);

    if (timeoutStatus == OrderTimeoutStatus.normal || timeoutMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    Color indicatorColor;
    IconData indicatorIcon;

    switch (timeoutStatus) {
      case OrderTimeoutStatus.firstAlert:
        indicatorColor = Theme.of(context).colorScheme.secondary;
        indicatorIcon = Icons.access_time;
        break;
      case OrderTimeoutStatus.urgentAlert:
        indicatorColor = Colors.red;
        indicatorIcon = Icons.warning_amber_rounded;
        break;
      case OrderTimeoutStatus.autoReject:
        indicatorColor = Colors.red.shade800;
        indicatorIcon = Icons.error_outline;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 200), // Limit width
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            indicatorIcon,
            size: 14,
            color: indicatorColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              timeoutMessage,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: indicatorColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
