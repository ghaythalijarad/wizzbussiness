import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/notification_service.dart';
import '../../models/order.dart';

class ActionableOrderNotificationCard extends ConsumerWidget {
  final Order order;
  final VoidCallback onDismiss;

  const ActionableOrderNotificationCard({
    Key? key,
    required this.order,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationService = ref.read(notificationServiceProvider);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Order Received',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Order ID: ${order.id}'),
            Text('Customer: ${order.customerName}'),
            Text('Details: ${order.notes ?? 'No details'}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    notificationService.handleOrderAction(order.id, 'reject');
                    onDismiss();
                  },
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    notificationService.handleOrderAction(order.id, 'confirm');
                    onDismiss();
                  },
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
