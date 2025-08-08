import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/app_state.dart';
import '../utils/responsive_helper.dart';

class IOSSidebar extends ConsumerStatefulWidget {
  final bool isOnline;
  final Future<void> Function(bool) onToggleStatus;
  final VoidCallback onReturnOrder;
  final Function(int) onNavigate;
  final VoidCallback onClose;

  const IOSSidebar({
    super.key,
    required this.isOnline,
    required this.onToggleStatus,
    required this.onReturnOrder,
    required this.onNavigate,
    required this.onClose,
  });

  @override
  ConsumerState<IOSSidebar> createState() => _IOSSidebarState();
}

class _IOSSidebarState extends ConsumerState<IOSSidebar> {
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

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sign Out', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Disconnect from real-time service is now handled by AppAuthService.signOut()
      // context.read(realtimeOrderServiceProvider).disconnect();
      
      await AppAuthService.signOut();
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

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
                  width: ResponsiveHelper.getSidebarWidth(context),
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

  Widget _buildSidebarContent(
      BuildContext context, AppLocalizations localizations) {
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
    final isCompact = ResponsiveHelper.shouldUseCompactLayout(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.getResponsivePadding(context),
        ResponsiveHelper.getResponsivePadding(context),
        16,
        16,
      ),
      child: Row(
        children: [
          // App icon
          Container(
            width: ResponsiveHelper.getResponsiveIconSize(context, 32),
            height: ResponsiveHelper.getResponsiveIconSize(context, 32),
            decoration: BoxDecoration(
              color: const Color(0xff00c1e8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: ResponsiveHelper.getResponsiveIconSize(context, 18),
            ),
          ),
          const SizedBox(width: 12),

          // App name
          Expanded(
            child: Text(
              localizations.appTitle,
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              maxLines: isCompact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Close button
          GestureDetector(
            onTap: _close,
            child: Container(
              width: ResponsiveHelper.getResponsiveIconSize(context, 32),
              height: ResponsiveHelper.getResponsiveIconSize(context, 32),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.close,
                color: const Color(0xFF8E8E93),
                size: ResponsiveHelper.getResponsiveIconSize(context, 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSStatusSection(
      BuildContext context, AppLocalizations localizations) {
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
    final isCompact = ResponsiveHelper.shouldUseCompactLayout(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: responsivePadding,
        vertical: isCompact ? 8 : 12,
      ),
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: _appState.isOnline
            ? const Color(0xFF34C759).withValues(alpha: 0.1)
            : const Color(0xFFFF3B30).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isCompact
          ?
          // Compact layout for mobile
          Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _appState.isOnline
                            ? const Color(0xFF34C759)
                            : const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _appState.isOnline
                            ? localizations.online
                            : localizations.offline,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 16),
                          fontWeight: FontWeight.w600,
                          color: _appState.isOnline
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF3B30),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _appState.isOnline
                            ? localizations.readyToReceiveOrders
                            : localizations.ordersArePaused,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 13),
                          color: const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // iOS-style switch with loading state
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _appState.isOnline
                                        ? const Color(0xFF34C759)
                                        : const Color(0xFFFF3B30),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Switch.adaptive(
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
                                            backgroundColor:
                                                const Color(0xFFFF3B30),
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            activeColor: const Color(0xFF34C759),
                            inactiveThumbColor: const Color(0xFFFF3B30),
                            inactiveTrackColor:
                                const Color(0xFFFF3B30).withOpacity(0.3),
                          ),
                  ],
                ),
              ],
            )
          :
          // Full layout for tablet/desktop
          Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _appState.isOnline
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _appState.isOnline
                            ? localizations.online
                            : localizations.offline,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 16),
                          fontWeight: FontWeight.w600,
                          color: _appState.isOnline
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF3B30),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _appState.isOnline
                            ? localizations.readyToReceiveOrders
                            : localizations.ordersArePaused,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 13),
                          color: const Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),

                // iOS-style switch
                Switch.adaptive(
                  value: _appState.isOnline,
                  onChanged: widget.onToggleStatus,
                  activeColor: const Color(0xFF34C759),
                ),
              ],
            ),
    );
  }

  Widget _buildIOSNavigationMenu(
      BuildContext context, AppLocalizations localizations) {
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);

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
      margin: EdgeInsets.symmetric(horizontal: responsivePadding),
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
                    _buildIOSMenuTile(item, context),
                    if (!isLast)
                      Container(
                        margin: EdgeInsets.only(
                          left: ResponsiveHelper.getResponsiveIconSize(
                              context, 52),
                        ),
                        height: 0.5,
                        color: const Color(0xFFC6C6C8),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),

          SizedBox(
              height:
                  ResponsiveHelper.shouldUseCompactLayout(context) ? 16 : 24),

          // Quick actions section
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildIOSMenuTile(
                    _IOSMenuItem(
                      icon: Icons.language,
                      title: localizations.languageSettings,
                      onTap: () => _showLanguageDialog(context),
                    ),
                    context),
                Container(
                  margin: EdgeInsets.only(
                    left: ResponsiveHelper.getResponsiveIconSize(context, 52),
                  ),
                  height: 0.5,
                  color: const Color(0xFFC6C6C8),
                ),
                _buildIOSMenuTile(
                    _IOSMenuItem(
                      icon: Icons.undo,
                      title: localizations.returnOrder,
                      onTap: () {
                        widget.onReturnOrder();
                        _close();
                      },
                      isDestructive: true,
                    ),
                    context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSMenuTile(_IOSMenuItem item, BuildContext context) {
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
    final isCompact = ResponsiveHelper.shouldUseCompactLayout(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : responsivePadding,
            vertical: isCompact ? 12 : 16,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: item.isDestructive
                    ? const Color(0xFFFF3B30)
                    : const Color(0xff00c1e8),
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.w400,
                    color: item.isDestructive
                        ? const Color(0xFFFF3B30)
                        : Colors.black,
                  ),
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: const Color(0xFFC6C6C8),
                size: ResponsiveHelper.getResponsiveIconSize(context, 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSFooter(BuildContext context, AppLocalizations localizations) {
    final responsivePadding = ResponsiveHelper.getResponsivePadding(context);
    final isCompact = ResponsiveHelper.shouldUseCompactLayout(context);

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : responsivePadding),
      child: Text(
        localizations.tapOutsideOrPressEscToClose,
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
          color: const Color(0xFF8E8E93),
        ),
        textAlign: TextAlign.center,
        maxLines: isCompact ? 2 : 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _navigateAndClose(int index) {
    widget.onNavigate(index);
    _close();
  }

  void _showLanguageDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isCompact = ResponsiveHelper.shouldUseCompactLayout(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.language,
                size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                color: const Color(0xff00c1e8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localizations.changeAppLanguage,
                  style: TextStyle(
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 18),
                  ),
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageTile(
                context: context,
                flag: '🇺🇸',
                name: 'English',
                locale: const Locale('en'),
              ),
              const Divider(height: 1),
              _buildLanguageTile(
                context: context,
                flag: '🇸🇦',
                name: 'العربية',
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
    final isCompact = ResponsiveHelper.shouldUseCompactLayout(context);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 4 : 8,
      ),
      leading: Text(
        flag,
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: const Color(0xff00c1e8),
              size: ResponsiveHelper.getResponsiveIconSize(context, 24),
            )
          : null,
      onTap: () async {
        final provider = ref.read(localeProvider.notifier);
        await provider.setLocale(locale);

        if (context.mounted) {
          Navigator.of(context).pop();
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
