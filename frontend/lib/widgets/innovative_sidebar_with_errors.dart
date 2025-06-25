import 'package:flutter/material.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';

class InnovativeSidebar extends StatefulWidget {
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
  State<InnovativeSidebar> createState() => _InnovativeSidebarState();
}

class _InnovativeSidebarState extends State<InnovativeSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeSidebar() async {
    await _animationController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return GestureDetector(
      onTap: _closeSidebar,
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: GestureDetector(
          onTap: () {}, // Prevent closing when tapping sidebar content
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Backdrop
                  Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                  // Sidebar
                  Positioned(
                    right: _slideAnimation.value * 350,
                    top: 0,
                    bottom: 0,
                    child: Material(
                      elevation: 0,
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
                          // Header
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
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
                                      onPressed: _closeSidebar,
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
                          // Status Section
                          Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: widget.isOnline 
                                  ? Colors.green.shade50 
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: widget.isOnline 
                                    ? Colors.green.shade200 
                                    : Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: widget.isOnline 
                                        ? Colors.green.shade100 
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    widget.isOnline ? Icons.wifi : Icons.wifi_off,
                                    color: widget.isOnline 
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
                                        widget.isOnline ? loc.online : loc.offline,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: widget.isOnline 
                                              ? Colors.green.shade700 
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                      Text(
                                        widget.isOnline 
                                            ? 'Ready to receive orders'
                                            : 'Orders are paused',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: widget.isOnline 
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
                                    value: widget.isOnline,
                                    onChanged: widget.onToggleStatus,
                                    activeColor: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quick Actions
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
                                      widget.onReturnOrder();
                                      _closeSidebar();
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionCard(
                                    icon: Icons.local_offer,
                                    title: loc.discounts,
                                    subtitle: 'Manage promotional offers',
                                    color: const Color(0xFF3399FF),
                                    onTap: () {
                                      widget.onNavigate(3);
                                      _closeSidebar();
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionCard(
                                    icon: Icons.analytics,
                                    title: 'Analytics',
                                    subtitle: 'View business insights',
                                    color: Colors.purple,
                                    onTap: () {
                                      widget.onNavigate(2);
                                      _closeSidebar();
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionCard(
                                    icon: Icons.inventory_2,
                                    title: 'Inventory',
                                    subtitle: 'Manage items & categories',
                                    color: Colors.green,
                                    onTap: () {
                                      widget.onNavigate(1);
                                      _closeSidebar();
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildActionCard(
                                    icon: Icons.settings,
                                    title: 'Settings',
                                    subtitle: 'App & account preferences',
                                    color: Colors.grey.shade600,
                                    onTap: () {
                                      widget.onNavigate(4);
                                      _closeSidebar();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Footer
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
                ],
              );
            },
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
