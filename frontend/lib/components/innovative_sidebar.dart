// filepath: /Users/ghaythallaheebi/order-receiver-app-2/frontend/lib/components/innovative_sidebar.dart
import 'package:flutter/material.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../services/app_state.dart';

class InnovativeSidebar extends StatefulWidget {
  final bool isOnline;
  final Future<void> Function(bool) onToggleStatus;
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
  State<InnovativeSidebar> createState() => _InnovativeSidebarState();
}

class _InnovativeSidebarState extends State<InnovativeSidebar> {
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
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // Background overlay
        GestureDetector(
          onTap: widget.onClose,
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
                              onPressed: widget.onClose,
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
                          color: _appState.isOnline
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _appState.isOnline
                                ? Colors.green.shade200
                                : Colors.red.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _appState.isOnline ? Icons.wifi : Icons.wifi_off,
                              color: _appState.isOnline
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _appState.isOnline
                                        ? loc.online
                                        : loc.offline,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _appState.isOnline
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                  Text(
                                    _appState.isOnline
                                        ? loc.readyToReceiveOrders
                                        : loc.ordersArePaused,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _appState.isToggling
                                ? SizedBox(
                                    width: 48,
                                    height: 28,
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            _appState.isOnline
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Switch(
                                    value: _appState.isOnline,
                                    onChanged: _appState.isToggling
                                        ? null
                                        : (value) async {
                                            try {
                                              await _appState.setOnline(
                                                  value, widget.onToggleStatus);
                                            } catch (error) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Failed to update status. Please try again.',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                    duration:
                                                        Duration(seconds: 3),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                    activeColor: Colors.green.shade700,
                                    activeTrackColor: Colors.green.shade300,
                                    inactiveThumbColor: Colors.red.shade700,
                                    inactiveTrackColor: Colors.red.shade300,
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
                              title: loc.orders,
                              onTap: () {
                                widget.onNavigate(0);
                                widget.onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.inventory_2,
                              title: loc.items,
                              onTap: () {
                                widget.onNavigate(1);
                                widget.onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.local_offer,
                              title: loc.discounts,
                              onTap: () {
                                widget.onNavigate(2);
                                widget.onClose();
                              },
                            ),
                            _buildMenuItem(
                              icon: Icons.settings,
                              title: loc.settings,
                              onTap: () {
                                widget.onNavigate(3);
                                widget.onClose();
                              },
                            ),
                            const Divider(),
                            _buildMenuItem(
                              icon: Icons.undo,
                              title: loc.returnOrder,
                              onTap: () {
                                widget.onReturnOrder();
                                widget.onClose();
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
                                loc.tapOutsideOrPressEscToClose,
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
