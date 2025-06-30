import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../services/language_service.dart';

class IOSSidebar extends StatefulWidget {
  final bool isOnline;
  final Function(bool) onToggleStatus;
  final VoidCallback onReturnOrder;
  final Function(int) onNavigate;
  final VoidCallback onClose;
  final Function(Locale)? onLanguageChanged;

  const IOSSidebar({
    super.key,
    required this.isOnline,
    required this.onToggleStatus,
    required this.onReturnOrder,
    required this.onNavigate,
    required this.onClose,
    this.onLanguageChanged,
  });

  @override
  State<IOSSidebar> createState() => _IOSSidebarState();
}

class _IOSSidebarState extends State<IOSSidebar> {
  void _close() {
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: _close,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              _close();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            children: [
              // Backdrop
              Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
              // Sidebar
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.15),
                        blurRadius: 20,
                        offset: Offset(5, 0),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {}, // Prevent closing when tapping sidebar
                      child: _buildSidebarContent(context, localizations),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarContent(BuildContext context, AppLocalizations localizations) {
    return SafeArea(
      child: Column(
        children: [
          // iOS-style header
          _buildIOSHeader(context, localizations),

          // iOS-style status section
          _buildIOSStatusSection(context, localizations),

          // iOS-style navigation menu
          Expanded(
            child: _buildIOSNavigationMenu(context, localizations),
          ),

          // iOS-style footer
          _buildIOSFooter(context, localizations),
        ],
      ),
    );
  }

  Widget _buildIOSHeader(BuildContext context, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      child: Row(
        children: [
          // App icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xff00c1e8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          
          // App name
          Expanded(
            child: Text(
              localizations.appTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          
          // Close button
          GestureDetector(
            onTap: _close,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFF8E8E93),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSStatusSection(BuildContext context, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isOnline 
            ? const Color(0xFF34C759).withValues(alpha: 0.1) 
            : const Color(0xFFFF3B30).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.isOnline ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isOnline ? localizations.online : localizations.offline,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isOnline ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isOnline 
                      ? localizations.readyToReceiveOrders 
                      : localizations.ordersArePaused,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          
          // iOS-style switch
          Switch.adaptive(
            value: widget.isOnline,
            onChanged: widget.onToggleStatus,
            activeColor: const Color(0xFF34C759),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSNavigationMenu(BuildContext context, AppLocalizations localizations) {
    final menuItems = [
      _IOSMenuItem(
        icon: Icons.list_alt,
        title: localizations.orders,
        onTap: () => _navigateAndClose(0),
      ),
      _IOSMenuItem(
        icon: Icons.inventory_2,
        title: localizations.items,
        onTap: () => _navigateAndClose(1),
      ),
      _IOSMenuItem(
        icon: Icons.local_offer,
        title: localizations.discounts,
        onTap: () => _navigateAndClose(2),
      ),
      _IOSMenuItem(
        icon: Icons.settings,
        title: localizations.settings,
        onTap: () => _navigateAndClose(3),
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Main navigation
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: menuItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == menuItems.length - 1;
                
                return Column(
                  children: [
                    _buildIOSMenuTile(item),
                    if (!isLast) 
                      Container(
                        margin: const EdgeInsets.only(left: 52),
                        height: 0.5,
                        color: const Color(0xFFC6C6C8),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick actions section
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildIOSMenuTile(_IOSMenuItem(
                  icon: Icons.language,
                  title: localizations.language,
                  onTap: () => _showLanguageDialog(context),
                )),
                Container(
                  margin: const EdgeInsets.only(left: 52),
                  height: 0.5,
                  color: const Color(0xFFC6C6C8),
                ),
                _buildIOSMenuTile(_IOSMenuItem(
                  icon: Icons.undo,
                  title: localizations.returnOrder,
                  onTap: () {
                    widget.onReturnOrder();
                    _close();
                  },
                  isDestructive: true,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSMenuTile(_IOSMenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: item.isDestructive ? const Color(0xFFFF3B30) : const Color(0xff00c1e8),
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: item.isDestructive ? const Color(0xFFFF3B30) : Colors.black,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFC6C6C8),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSFooter(BuildContext context, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Text(
        localizations.tapOutsideOrPressEscToClose,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF8E8E93),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _navigateAndClose(int index) {
    widget.onNavigate(index);
    _close();
  }

  void _showLanguageDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.language,
                size: 24,
                color: Color(0xff00c1e8),
              ),
              const SizedBox(width: 8),
              Text(
                localizations.selectLanguage,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageTile(
                context: context,
                flag: '🇺🇸',
                name: localizations.english,
                locale: const Locale('en'),
              ),
              const Divider(height: 1),
              _buildLanguageTile(
                context: context,
                flag: '🇸🇦',
                name: localizations.arabic,
                locale: const Locale('ar'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.cancel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageTile({
    required BuildContext context,
    required String flag,
    required String name,
    required Locale locale,
  }) {
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context);
    final isSelected = currentLocale.languageCode == locale.languageCode;

    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle,
              color: Color(0xff00c1e8),
            )
          : null,
      onTap: () async {
        if (widget.onLanguageChanged != null) {
          widget.onLanguageChanged!(locale);
        }

        await LanguageService.setLanguage(locale.languageCode);
        Navigator.of(context).pop();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                locale.languageCode == 'ar'
                    ? localizations.languageChangedToArabic
                    : localizations.languageChangedToEnglish,
              ),
              backgroundColor: const Color(0xFF34C759),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      },
    );
  }
}

class _IOSMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  _IOSMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });
}
