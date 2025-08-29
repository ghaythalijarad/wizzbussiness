import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadhir_business/l10n/app_localizations.dart';
import '../providers/locale_provider_riverpod.dart';
import '../services/language_service.dart';
import '../services/app_state.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/design_system/typography_system.dart';
import '../utils/responsive_helper.dart';
import 'dart:io';

/// ModernSidebar - Adaptive sidebar component
///
/// This component automatically adapts its behavior and appearance
/// based on the platform (iOS/Android) and screen size.
/// Features:
/// - Material Design 3 styling with golden ratio proportions
/// - Platform-specific animations and interactions
/// - Responsive layout for mobile/tablet/desktop
/// - Complete design system integration
class ModernSidebar extends ConsumerStatefulWidget {
  final bool isOnline;
  final Future<void> Function(bool) onToggleStatus;
  final VoidCallback onReturnOrder;
  final Function(int) onNavigate;
  final VoidCallback onClose;

  const ModernSidebar({
    super.key,
    required this.isOnline,
    required this.onToggleStatus,
    required this.onReturnOrder,
    required this.onNavigate,
    required this.onClose,
  });

  @override
  ConsumerState<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends ConsumerState<ModernSidebar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rippleController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_onAppStateChanged);

    // Platform-specific animation curves and durations
    final isIOS = Platform.isIOS;
    final animationDuration = isIOS
        ? const Duration(
            milliseconds: 400) // iOS prefers slightly longer animations
        : const Duration(milliseconds: 350); // Android standard

    final animationCurve = isIOS
        ? Curves.easeInOutCubic // iOS characteristic curve
        : Curves.easeOutCubic; // Material Design curve

    // Main slide animation
    _animationController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );

    // Ripple animation for interactions
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: animationCurve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: isIOS ? Curves.easeOutBack : Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rippleController.dispose();
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _closeWithAnimation() async {
    // Platform-specific haptic feedback
    if (Platform.isIOS) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    
    await _animationController.reverse();
    widget.onClose();
  }

  Future<void> _handleSwitchToggle(bool value) async {
    // Platform-specific haptic feedback for switch interaction
    if (Platform.isIOS) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }

    try {
      await _appState.setOnline(value, widget.onToggleStatus);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(GoldenRatio.xs),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius:
                        BorderRadius.circular(GoldenRatio.buttonRadius),
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: GoldenRatio.iconSm,
                  ),
                ),
                const SizedBox(width: GoldenRatio.spacing12),
                const Expanded(
                  child: Text(
                    'Failed to update status. Please try again.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isIOS = Platform.isIOS;
    final screenWidth = MediaQuery.of(context).size.width;

    // Platform and size-specific sidebar width
    double sidebarWidth;
    if (ResponsiveHelper.isDesktop(context)) {
      sidebarWidth = GoldenRatio.drawerWidth; // 304px for desktop
    } else if (ResponsiveHelper.isTablet(context)) {
      sidebarWidth = screenWidth * 0.75; // 75% on tablet
    } else {
      // Mobile: iOS prefers slightly wider sidebars
      sidebarWidth = isIOS ? screenWidth * 0.85 : screenWidth * 0.8;
    }

    return GestureDetector(
      onTap: _closeWithAnimation,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              _closeWithAnimation();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            children: [
              // Animated backdrop with platform-specific opacity
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  final backdropOpacity =
                      isIOS ? 0.4 : 0.5; // iOS uses lighter backdrop
                  return Container(
                    color: Colors.black.withValues(
                        alpha: _fadeAnimation.value * backdropOpacity),
                  );
                },
              ),
              // Main sidebar
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _slideAnimation.value * sidebarWidth,
                      0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: sidebarWidth,
                          height: MediaQuery.of(context).size.height,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                AppColors.primary.withOpacity(0.02),
                                AppColors.secondary.withOpacity(0.01),
                              ],
                              stops: const [0.0, 0.7, 1.0],
                            ),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(isIOS
                                  ? GoldenRatio.modalRadius
                                  : GoldenRatio.sheetRadius),
                              bottomRight: Radius.circular(isIOS
                                  ? GoldenRatio.modalRadius
                                  : GoldenRatio.sheetRadius),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.08),
                                blurRadius: isIOS
                                    ? GoldenRatio.elevation5
                                    : GoldenRatio.elevation4,
                                offset: const Offset(3, 0),
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: GoldenRatio.elevation2,
                                offset: const Offset(1, 0),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: GestureDetector(
                              onTap:
                                  () {}, // Prevent closing when tapping sidebar
                              child: _buildSidebarContent(
                                  context, localizations, colorScheme),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarContent(BuildContext context,
      AppLocalizations localizations, ColorScheme colorScheme) {
    return SafeArea(
      child: Column(
        children: [
          // Status card with glassmorphism effect
          _buildStatusCard(context, localizations, colorScheme),

          // Navigation menu
          Expanded(
            child: _buildNavigationMenu(context, localizations, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, AppLocalizations localizations,
      ColorScheme colorScheme) {
    final isOnline = _appState.isOnline;
    
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: GoldenRatio.spacing16, vertical: GoldenRatio.spacing12),
      padding: const EdgeInsets.all(GoldenRatio.spacing16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isOnline
                ? AppColors.success.withOpacity(0.1)
                : AppColors.warning.withOpacity(0.1),
            isOnline
                ? AppColors.success.withOpacity(0.05)
                : AppColors.warning.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
        border: Border.all(
          color: isOnline
              ? AppColors.success.withOpacity(0.2)
              : AppColors.warning.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? AppColors.success : AppColors.warning)
                .withOpacity(0.1),
            blurRadius: GoldenRatio.elevation2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Status icon with animation
              Container(
                padding: const EdgeInsets.all(GoldenRatio.spacing12),
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : AppColors.warning,
                  borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline ? AppColors.success : AppColors.warning)
                          .withOpacity(0.3),
                      blurRadius: GoldenRatio.elevation1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: GoldenRatio.iconSm,
                ),
              ),
              const SizedBox(width: GoldenRatio.spacing12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? localizations.online : localizations.offline,
                      style: TypographySystem.labelLarge.copyWith(
                        color: isOnline ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: GoldenRatio.xs),
                    Text(
                      isOnline
                          ? localizations.readyToReceiveOrders
                          : localizations.ordersArePaused,
                      style: TypographySystem.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Loading indicator or toggle switch with platform-specific behavior
              _appState.isToggling
                  ? Container(
                      width: 44,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: GoldenRatio.iconSm,
                          height: GoldenRatio.iconSm,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOnline ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Platform.isIOS
                      ? CupertinoSwitch(
                          value: isOnline,
                          onChanged:
                              _appState.isToggling ? null : _handleSwitchToggle,
                          activeColor: AppColors.success,
                          trackColor: AppColors.warning.withOpacity(0.3),
                        )
                      : Switch.adaptive(
                          value: isOnline,
                          onChanged:
                              _appState.isToggling ? null : _handleSwitchToggle,
                          activeColor: AppColors.success,
                          activeTrackColor: AppColors.success.withOpacity(0.3),
                          inactiveThumbColor: AppColors.warning,
                          inactiveTrackColor:
                              AppColors.warning.withOpacity(0.3),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu(BuildContext context,
      AppLocalizations localizations, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: GoldenRatio.spacing16),
      children: [
        // Main navigation items with consistent spacing
        _buildMenuItem(
          context: context,
          icon: Icons.shopping_bag,
          title: localizations.orders,
          onTap: () => _navigateAndClose(0),
          colorScheme: colorScheme,
        ),

        const SizedBox(height: GoldenRatio.sm),

        _buildMenuItem(
          context: context,
          icon: Icons.inventory_2,
          title: localizations.items,
          onTap: () => _navigateAndClose(1),
          colorScheme: colorScheme,
        ),

        const SizedBox(height: GoldenRatio.sm),

        _buildMenuItem(
          context: context,
          icon: Icons.analytics,
          title: localizations.analytics,
          onTap: () => _navigateAndClose(2),
          colorScheme: colorScheme,
        ),

        const SizedBox(height: GoldenRatio.sm),

        _buildMenuItem(
          context: context,
          icon: Icons.local_offer,
          title: localizations.discounts,
          onTap: () => _navigateAndClose(3),
          colorScheme: colorScheme,
        ),

        const SizedBox(height: GoldenRatio.sm),

        _buildMenuItem(
          context: context,
          icon: Icons.settings,
          title: localizations.settings,
          onTap: () => _navigateAndClose(4),
          colorScheme: colorScheme,
        ),

        const SizedBox(height: GoldenRatio.spacing16),
        Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),
        const SizedBox(height: GoldenRatio.spacing16),

        // Quick action items with consistent spacing
        _buildMenuItem(
          context: context,
          icon: Icons.language,
          title: localizations.language,
          onTap: () => _showLanguageDialog(context),
          colorScheme: colorScheme,
        ),

        const SizedBox(height: GoldenRatio.sm),

        _buildMenuItem(
          context: context,
          icon: Icons.undo_rounded,
          title: localizations.returnOrder,
          onTap: () {
            widget.onReturnOrder();
            _closeWithAnimation();
          },
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: GoldenRatio.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: GoldenRatio.spacing16,
                vertical: GoldenRatio.spacing12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(GoldenRatio.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(GoldenRatio.buttonRadius),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: GoldenRatio.iconSm,
                  ),
                ),
                const SizedBox(width: GoldenRatio.spacing12),
                Expanded(
                  child: Text(
                    title,
                    style: TypographySystem.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textSecondary,
                  size: GoldenRatio.iconXs,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateAndClose(int index) {
    widget.onNavigate(index);
    _closeWithAnimation();
  }

  void _showLanguageDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.primary.withOpacity(0.1),
          elevation: GoldenRatio.elevation4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.modalRadius),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(GoldenRatio.spacing12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: AppColors.primary,
                  size: GoldenRatio.iconRegular,
                ),
              ),
              const SizedBox(width: GoldenRatio.spacing12),
              Expanded(
                child: Text(
                  localizations.selectLanguage,
                  style: TypographySystem.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
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
                name: localizations.english,
                locale: const Locale('en'),
              ),
              const SizedBox(height: GoldenRatio.sm),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF00C1E8).withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: GoldenRatio.sm),
              _buildLanguageTile(
                context: context,
                flag: '🇸🇦',
                name: localizations.arabic,
                locale: const Locale('ar'),
              ),
            ],
          ),
          actions: [
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
                ),
              ),
              icon: const Icon(Icons.close_rounded),
              label: Text(localizations.cancel),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: GoldenRatio.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Update the locale using the provider
            ref.read(localeProvider.notifier).setLocale(locale);

            // Save the language preference
            await LanguageService.setLanguage(locale.languageCode);

            Navigator.of(context).pop();

            // Show confirmation
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(GoldenRatio.xs),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(GoldenRatio.buttonRadius),
                        ),
                        child: Icon(Icons.check_rounded,
                            color: AppColors.primary, size: GoldenRatio.iconSm),
                      ),
                      const SizedBox(width: GoldenRatio.spacing12),
                      Expanded(
                        child: Text(
                          locale.languageCode == 'ar'
                              ? localizations.languageChangedToArabic
                              : localizations.languageChangedToEnglish,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(GoldenRatio.spacing16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(GoldenRatio.cardRadius),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary.withOpacity(0.3),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(GoldenRatio.sm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surfaceContainer,
                    borderRadius:
                        BorderRadius.circular(GoldenRatio.buttonRadius),
                  ),
                  child: Text(flag, style: TypographySystem.titleMedium),
                ),
                const SizedBox(width: GoldenRatio.spacing16),
                Expanded(
                  child: Text(
                    name,
                    style: TypographySystem.bodyLarge.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(GoldenRatio.xs),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(GoldenRatio.buttonRadius),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: AppColors.onPrimary,
                      size: GoldenRatio.iconSm,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
