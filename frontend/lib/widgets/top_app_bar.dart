import 'package:flutter/material.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../utils/responsive_helper.dart';
import 'package:hadhir_business/components/innovative_sidebar.dart';

class TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isOnline;
  final Function(bool) onToggleStatus;
  final VoidCallback onReturnOrder;
  final Function(int) onNavigate;

  const TopAppBar({
    super.key,
    required this.title,
    required this.isOnline,
    required this.onToggleStatus,
    required this.onReturnOrder,
    required this.onNavigate,
  });

  void _showInnovativeSidebar(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, animation1, animation2) {
        return InnovativeSidebar(
          isOnline: isOnline,
          onToggleStatus: onToggleStatus,
          onReturnOrder: onReturnOrder,
          onNavigate: onNavigate,
          onClose: () => Navigator.of(context).pop(),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrDesktop = ResponsiveHelper.isTablet(context) ||
        ResponsiveHelper.isDesktop(context);

    final loc = AppLocalizations.of(context)!;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.notificationsTapped)),
          );
        },
        tooltip: loc.notifications,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isTabletOrDesktop ? 24 : 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevation: isTabletOrDesktop ? 0 : 1,
      backgroundColor: isTabletOrDesktop ? Colors.white : null,
      foregroundColor: isTabletOrDesktop ? Colors.black87 : null,
      actions: isTabletOrDesktop
          ? _buildDesktopActions(context)
          : _buildMobileActions(context),
    );
  }

  List<Widget> _buildMobileActions(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      // Status Indicator
      Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isOnline ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOnline ? Colors.green.shade200 : Colors.red.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              isOnline ? loc.online : loc.offline,
              style: TextStyle(
                color: isOnline ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      // Innovative Sidebar Button
      IconButton(
        onPressed: () => _showInnovativeSidebar(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3399FF), Color(0xFF030e8e)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.dashboard_customize,
            color: Colors.white,
            size: 20,
          ),
        ),
        tooltip: 'Quick Actions',
      ),
    ];
  }

  List<Widget> _buildDesktopActions(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      const SizedBox(width: 8),
      // Innovative Sidebar Button
      Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showInnovativeSidebar(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3399FF), Color(0xFF030e8e)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3399FF).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.dashboard_customize,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Actions',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Status Indicator
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isOnline ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOnline ? Colors.green.shade200 : Colors.red.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOnline ? loc.online : loc.offline,
              style: TextStyle(
                color: isOnline ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
    ];
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
