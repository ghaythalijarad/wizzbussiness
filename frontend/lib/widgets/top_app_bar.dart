import 'package:flutter/material.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../utils/responsive_helper.dart';

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

  @override
  Widget build(BuildContext context) {
    final isTabletOrDesktop = ResponsiveHelper.isTablet(context) ||
        ResponsiveHelper.isDesktop(context);

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

  List<Widget> _buildMobileActions(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isOnline ? loc.online : loc.offline,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isOnline,
              onChanged: onToggleStatus,
            ),
          ),
        ],
      ),
      IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.notificationsTapped)),
          );
        },
        tooltip: loc.notifications,
      ),
      PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'return_order') {
            onReturnOrder();
          } else if (value == 'manage_discounts') {
            onNavigate(3);
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'return_order',
            child: Text(loc.returnAnOrder),
          ),
          PopupMenuItem<String>(
            value: 'manage_discounts',
            child: Text(loc.manageDiscounts),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildDesktopActions(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return [
      // Status indicator
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isOnline ? Colors.green[50] : Colors.red[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOnline ? Colors.green : Colors.red,
            width: 1,
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
            const SizedBox(width: 8),
            Text(
              isOnline ? loc.online : loc.offline,
              style: TextStyle(
                color: isOnline ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: isOnline,
              onChanged: onToggleStatus,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      // Notifications
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.notificationsTapped)),
          );
        },
        tooltip: loc.notifications,
      ),
      const SizedBox(width: 8),
      // Quick actions
      TextButton.icon(
        onPressed: onReturnOrder,
        icon: const Icon(Icons.undo),
        label: Text(loc.returnOrder),
        style: TextButton.styleFrom(
          foregroundColor: Colors.orange,
        ),
      ),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: () => onNavigate(3),
        icon: const Icon(Icons.local_offer),
        label: Text(loc.discounts),
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
        ),
      ),
      const SizedBox(width: 16),
    ];
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
