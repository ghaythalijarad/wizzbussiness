import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/order.dart';

// Utility class for return order functionality that can be used by all pages
class ReturnOrderUtils {
  static void showReturnOrderDialog(BuildContext context, List<Order> orders,
      Function(String, OrderStatus) onOrderUpdated) {
    final TextEditingController orderNumberController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.returnOrderTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.enterOrderNumber,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderNumberController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.enterOrderNumber,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.receipt),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () => _processReturnOrder(context,
                  orderNumberController.text.trim(), orders, onOrderUpdated),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)!.returnOrder),
            ),
          ],
        );
      },
    );
  }

  static void _processReturnOrder(BuildContext context, String orderNumber,
      List<Order> orders, Function(String, OrderStatus) onOrderUpdated) {
    if (orderNumber.isEmpty) return;

    // Find the order by ID
    final orderIndex = orders.indexWhere(
        (order) => order.id.toUpperCase() == orderNumber.toUpperCase());

    if (orderIndex == -1) {
      // Order not found
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.orderNotFound),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Check if order can be returned (should be delivered or ready)
    final order = orders[orderIndex];
    if (order.status != OrderStatus.delivered &&
        order.status != OrderStatus.ready) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Order #${order.id} cannot be returned. Only delivered or ready orders can be returned.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Mark order as returned
    onOrderUpdated(order.id, OrderStatus.returned);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.orderReturnedSuccessfully),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
