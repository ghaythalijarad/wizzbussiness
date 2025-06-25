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
    
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        elevation: 8,
        color: Colors.transparent,
        child: Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(-5, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3399FF),
                      Color(0xFF030e8e),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.dashboard_customize,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.quickActions,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Smart business controls',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                ),
              ),
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isOnline 
                      ? Colors.green.shade50 
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOnline 
                        ? Colors.green.shade200 
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isOnline 
                            ? Colors.green.shade100 
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isOnline ? Icons.wifi : Icons.wifi_off,
                        color: isOnline 
                            ? Colors.green.shade700 
                            : Colors.red.shade700,
                      ),
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
                              color: isOnline 
                                  ? Colors.green.shade700 
                                  : Colors.red.shade700,
                            ),
                          ),
                          Text(
                            isOnline 
                                ? 'Ready to receive orders'
                                : 'Orders are paused',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline 
                                  ? Colors.green.shade600 
                                  : Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: Switch(
                        value: isOnline,
                        onChanged: onToggleStatus,
                        activeColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActionCard(
                        icon: Icons.undo,
                        title: loc.returnOrder,
                        subtitle: 'Process order returns',
                        color: Colors.orange,
                        onTap: () {
                          onReturnOrder();
                          onClose();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        icon: Icons.local_offer,
                        title: loc.discounts,
                        subtitle: 'Manage promotional offers',
                        color: const Color(0xFF3399FF),
                        onTap: () {
                          onNavigate(3);
                          onClose();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        icon: Icons.analytics,
                        title: 'Analytics',
                        subtitle: 'View business insights',
                        color: Colors.purple,
                        onTap: () {
                          onNavigate(2);
                          onClose();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        icon: Icons.inventory_2,
                        title: 'Inventory',
                        subtitle: 'Manage items & categories',
                        color: Colors.green,
                        onTap: () {
                          onNavigate(1);
                          onClose();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        icon: Icons.cloud_sync,
                        title: 'Platform Integration',
                        subtitle: 'Centralized delivery platform',
                        color: const Color(0xFF9C27B0),
                        onTap: () {
                          onNavigate(5);
                          onClose();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        icon: Icons.settings,
                        title: 'Settings',
                        subtitle: 'App & account preferences',
                        color: Colors.grey.shade600,
                        onTap: () {
                          onNavigate(4);
                          onClose();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3399FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lightbulb,
                        color: Color(0xFF3399FF),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: Use keyboard shortcuts for faster actions',
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
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
