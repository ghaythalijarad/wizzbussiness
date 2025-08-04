import 'package:flutter/material.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../utils/responsive_helper.dart';
import '../widgets/modern_sidebar.dart';

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

  void _showSimpleSidebar(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      pageBuilder: (context, animation1, animation2) {
        return ModernSidebar(
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
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(animation),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrDesktop = ResponsiveHelper.isTablet(context) ||
        ResponsiveHelper.isDesktop(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    final loc = AppLocalizations.of(context)!;

    if (isDesktop) {
      return AppBar(
        title: Row(
          children: [
            Icon(
              Icons.store,
              size: 24,
              color: Colors.black87,
            ),
            const SizedBox(width: 12),
            Text(
              loc.dashboard,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: _buildDesktopActions(context),
      );
    } else {
      return AppBar(
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
      // Flat Sidebar Button
      IconButton(
        onPressed: () => _showSimpleSidebar(context),
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF00C1E8),
          shape: const RoundedRectangleBorder(),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        icon: const Icon(
          Icons.menu,
          color: Color(0xFF00C1E8),
          size: 24,
        ),
        tooltip: loc.quickActions,
      ),
    ];
  }

  List<Widget> _buildDesktopActions(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      const SizedBox(width: 8),
      // Flat Sidebar Button
      Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showSimpleSidebar(context),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.menu,
                    color: Color(0xFF00C1E8),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    loc.quickActions,
                    style: const TextStyle(
                      color: Color(0xFF00C1E8),
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
