import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../services/app_state.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: widget.onClose,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Focus(
          autofocus: true,
          onKey: (node, event) {
            if (event is RawKeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              widget.onClose();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                        _slideAnimation.value *
                            MediaQuery.of(context).size.width *
                            0.7,
                        0),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.height,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF2196F3),
                              Color(0xFF0066CC),
                              Color(0xFF004499),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: Offset(5, 0),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with enhanced close button
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF3399FF),
                                      Color(0xFF030e8e),
                                    ],
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.dashboard_customize,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  localizations
                                                      .businessManagement,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                                Text(
                                                  localizations.dashboard,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Tooltip(
                                      message: localizations.close,
                                      child: InkWell(
                                        onTap: widget.onClose,
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Status Toggle Section
                              Container(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${localizations.online}/${localizations.offline} Status',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            widget.isOnline
                                                ? Icons.wifi
                                                : Icons.wifi_off,
                                            color: widget.isOnline
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              widget.isOnline
                                                  ? localizations.online
                                                  : localizations.offline,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Switch(
                                            value: widget.isOnline,
                                            onChanged: widget.onToggleStatus,
                                            activeColor: Colors.green,
                                            activeTrackColor: Colors.green
                                                .withValues(alpha: 0.3),
                                            inactiveThumbColor: Colors.red,
                                            inactiveTrackColor: Colors.red
                                                .withValues(alpha: 0.3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Menu Items
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Column(
                                    children: [
                                      _buildMenuItem(
                                        icon: Icons.shopping_bag,
                                        title: localizations.orders,
                                        onTap: () => widget.onNavigate(0),
                                      ),
                                      _buildMenuItem(
                                        icon: Icons.settings,
                                        title: localizations.settings,
                                        onTap: () => widget.onNavigate(1),
                                      ),
                                      const SizedBox(height: 20),
                                      _buildMenuItem(
                                        icon: Icons.undo,
                                        title: localizations.returnOrder,
                                        onTap: widget.onReturnOrder,
                                        isSpecial: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Footer with close button
                              Container(
                                padding: const EdgeInsets.all(20),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: widget.onClose,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.2),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.close),
                                        const SizedBox(width: 8),
                                        Text(localizations.close),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSpecial = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: isSpecial
                  ? Colors.orange.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSpecial
                    ? Colors.orange.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSpecial ? Colors.orange : Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSpecial ? Colors.orange : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: isSpecial ? Colors.orange : Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
