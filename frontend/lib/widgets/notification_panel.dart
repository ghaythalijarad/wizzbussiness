import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../l10n/app_localizations.dart';

class NotificationPanel extends ConsumerWidget {
  const NotificationPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final notificationService = ref.watch(notificationServiceProvider);
    final notifications = notificationService.notifications;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.notificationsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => notificationService.clearAll(),
            tooltip: loc.clearAllNotifications,
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(child: Text(loc.noNotificationsYet))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(notification.title),
                    subtitle: Text(notification.message),
                    trailing: notification.data.containsKey('orderId')
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                child: Text(loc.accept),
                                onPressed: () {
                                  final orderId =
                                      notification.data['orderId'] as String;
                                  notificationService.handleOrderAction(
                                      orderId, 'ACCEPT_ORDER');
                                },
                              ),
                              TextButton(
                                child: Text(loc.reject),
                                onPressed: () {
                                  final orderId =
                                      notification.data['orderId'] as String;
                                  notificationService.handleOrderAction(
                                      orderId, 'REJECT_ORDER');
                                },
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
