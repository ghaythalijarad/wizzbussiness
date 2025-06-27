// filepath: /Users/ghaythallaheebi/order-receiver-app-2/frontend/lib/components/innovative_sidebar.dart
import 'package:flutter/material.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';

class InnovativeSidebar extends StatelessWidget {
  final bool isOnline;
  final Function(bool) onToggleStatus;
  final VoidCallback onReturnOrder;
  final Function(int) onNavigate;
  final VoidCallback onClose;

  const InnovativeSidebar({
    super.key,
    required this.isOnline,
    required this.onToggleStatus,
    required this.onReturnOrder,
    required this.onNavigate,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Stack(
      children: [
        // Background overlay
        GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.black54,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // Sidebar
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping sidebar
            child: Material(
              elevation: 16,
              child: Container(
                width: 320,
                height: double.infinity,
                color: Colors.white,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        color: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                loc.quickActions,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: onClose,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Status section
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOnline ? Colors.green.shade200 : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isOnline ? Icons.wifi : Icons.wifi_off,
                              color: isOnline ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOnline ? loc.online : loc.offline,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isOnline ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    isOnline ? 'Ready to receive orders' : 'Orders are paused',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isOnline,
                              onChanged: onToggleStatus,
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ),
                      
                      // Menu items
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          children: [
                            _buildMenuItem(
                              icon: Icons.shopping_bag,
                              title: 'Orders',
                              onTap: () {
                                onNavigate(0);
                                onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.inventory_2,
                              title: 'Items',
                              onTap: () {
                                onNavigate(1);
                                onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.local_offer,
                              title: 'Discounts',
                              onTap: () {
                                onNavigate(2);
                                onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.settings,
                              title: 'Settings',
                              onTap: () {
                                onNavigate(3);
                                onClose();
                              },
                            ),
                            const Divider(),
                            _buildMenuItem(
                              icon: Icons.undo,
                              title: 'Return Order',
                              onTap: () {
                                onReturnOrder();
                                onClose();
                              },
                              isDestructive: true,
                            ),
                          ],
                        ),
                      ),
                      
                      // Footer
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey.shade600,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap outside to close',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.orange : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.orange : Colors.grey.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
