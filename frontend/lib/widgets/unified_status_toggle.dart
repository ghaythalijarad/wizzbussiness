import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../utils/responsive_helper.dart';

/// Unified online/offline status toggle component with optimal responsive design
/// Automatically adapts appearance based on screen size and layout context
class UnifiedStatusToggle extends StatefulWidget {
  final bool isOnline;
  final bool isToggling;
  final Future<void> Function(bool) onToggle;
  final StatusToggleVariant variant;
  final StatusToggleSize size;
  final bool showLabel;
  final bool showIcon;
  final Color? activeColor;
  final Color? inactiveColor;

  const UnifiedStatusToggle({
    Key? key,
    required this.isOnline,
    required this.isToggling,
    required this.onToggle,
    this.variant = StatusToggleVariant.adaptive,
    this.size = StatusToggleSize.medium,
    this.showLabel = true,
    this.showIcon = true,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  State<UnifiedStatusToggle> createState() => _UnifiedStatusToggleState();
}

class _UnifiedStatusToggleState extends State<UnifiedStatusToggle>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    if (widget.isOnline) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(UnifiedStatusToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline) {
      if (widget.isOnline) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleToggle() async {
    if (widget.isToggling) return;

    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Scale animation for visual feedback
    await _scaleController.forward();
    _scaleController.reverse();

    try {
      await widget.onToggle(!widget.isOnline);
    } catch (e) {
      // Error handled by parent
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    // Determine variant based on screen size if adaptive
    final effectiveVariant = widget.variant == StatusToggleVariant.adaptive
        ? _getAdaptiveVariant(context)
        : widget.variant;

    // Get responsive dimensions
    final dimensions = _getResponsiveDimensions(context, widget.size);
    
    // Get colors
    final activeColor = widget.activeColor ?? Colors.green.shade600;
    final inactiveColor = widget.inactiveColor ?? theme.colorScheme.error;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _buildVariant(
            context,
            effectiveVariant,
            localizations,
            theme,
            dimensions,
            activeColor,
            inactiveColor,
          ),
        );
      },
    );
  }

  StatusToggleVariant _getAdaptiveVariant(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) {
      return StatusToggleVariant.iconButton;
    } else if (ResponsiveHelper.isTablet(context)) {
      return StatusToggleVariant.chip;
    } else {
      return StatusToggleVariant.card;
    }
  }

  StatusToggleDimensions _getResponsiveDimensions(
    BuildContext context,
    StatusToggleSize size,
  ) {
    final baseScale = ResponsiveHelper.isMobile(context) 
        ? 1.0 
        : ResponsiveHelper.isTablet(context) 
            ? 1.1 
            : 1.2;

    switch (size) {
      case StatusToggleSize.small:
        return StatusToggleDimensions(
          iconSize: 16 * baseScale,
          fontSize: 12 * baseScale,
          padding: EdgeInsets.all(8 * baseScale),
          height: 32 * baseScale,
        );
      case StatusToggleSize.medium:
        return StatusToggleDimensions(
          iconSize: 20 * baseScale,
          fontSize: 14 * baseScale,
          padding: EdgeInsets.all(12 * baseScale),
          height: 40 * baseScale,
        );
      case StatusToggleSize.large:
        return StatusToggleDimensions(
          iconSize: 24 * baseScale,
          fontSize: 16 * baseScale,
          padding: EdgeInsets.all(16 * baseScale),
          height: 48 * baseScale,
        );
    }
  }

  Widget _buildVariant(
    BuildContext context,
    StatusToggleVariant variant,
    AppLocalizations localizations,
    ThemeData theme,
    StatusToggleDimensions dimensions,
    Color activeColor,
    Color inactiveColor,
  ) {
    switch (variant) {
      case StatusToggleVariant.iconButton:
        return _buildIconButton(
          context, localizations, dimensions, activeColor, inactiveColor);
      
      case StatusToggleVariant.chip:
        return _buildChip(
          context, localizations, theme, dimensions, activeColor, inactiveColor);
      
      case StatusToggleVariant.card:
        return _buildCard(
          context, localizations, theme, dimensions, activeColor, inactiveColor);
      
      case StatusToggleVariant.toggle:
        return _buildSwitch(
          context, localizations, dimensions, activeColor, inactiveColor);
      
      case StatusToggleVariant.button:
        return _buildButton(
          context, localizations, theme, dimensions, activeColor, inactiveColor);
      
      case StatusToggleVariant.adaptive:
        // This should not happen as we resolve adaptive above
        return _buildChip(
          context, localizations, theme, dimensions, activeColor, inactiveColor);
    }
  }

  Widget _buildIconButton(
    BuildContext context,
    AppLocalizations localizations,
    StatusToggleDimensions dimensions,
    Color activeColor,
    Color inactiveColor,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isOnline ? _pulseAnimation.value : 1.0,
          child: Tooltip(
            message: widget.isOnline 
                ? localizations.goOffline
                : localizations.goOnline,
            child: Container(
              width: dimensions.height,
              height: dimensions.height,
              decoration: BoxDecoration(
                color: widget.isOnline 
                    ? activeColor.withOpacity(0.1)
                    : inactiveColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(dimensions.height / 2),
                border: Border.all(
                  color: widget.isOnline ? activeColor : inactiveColor,
                  width: 2,
                ),
              ),
              child: widget.isToggling
                  ? Center(
                      child: SizedBox(
                        width: dimensions.iconSize,
                        height: dimensions.iconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            widget.isOnline ? activeColor : inactiveColor,
                          ),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _handleToggle,
                      icon: Icon(
                        widget.isOnline ? Icons.wifi : Icons.wifi_off,
                        color: widget.isOnline ? activeColor : inactiveColor,
                        size: dimensions.iconSize,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(
    BuildContext context,
    AppLocalizations localizations,
    ThemeData theme,
    StatusToggleDimensions dimensions,
    Color activeColor,
    Color inactiveColor,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: dimensions.height,
      decoration: BoxDecoration(
        color: widget.isOnline 
            ? activeColor.withOpacity(0.1)
            : inactiveColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(dimensions.height / 2),
        border: Border.all(
          color: widget.isOnline ? activeColor : inactiveColor,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isToggling ? null : _handleToggle,
          borderRadius: BorderRadius.circular(dimensions.height / 2),
          child: Padding(
            padding: dimensions.padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showIcon) ...[
                  widget.isToggling
                      ? SizedBox(
                          width: dimensions.iconSize,
                          height: dimensions.iconSize,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              widget.isOnline ? activeColor : inactiveColor,
                            ),
                          ),
                        )
                      : Icon(
                          widget.isOnline ? Icons.wifi : Icons.wifi_off,
                          color: widget.isOnline ? activeColor : inactiveColor,
                          size: dimensions.iconSize,
                        ),
                  if (widget.showLabel) SizedBox(width: dimensions.iconSize * 0.5),
                ],
                if (widget.showLabel)
                  Text(
                    widget.isOnline 
                        ? localizations.online 
                        : localizations.offline,
                    style: TextStyle(
                      color: widget.isOnline ? activeColor : inactiveColor,
                      fontSize: dimensions.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    AppLocalizations localizations,
    ThemeData theme,
    StatusToggleDimensions dimensions,
    Color activeColor,
    Color inactiveColor,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isOnline 
              ? activeColor.withOpacity(0.3)
              : inactiveColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isOnline ? activeColor : inactiveColor)
                .withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isToggling ? null : _handleToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: dimensions.padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showIcon) ...[
                  Container(
                    padding: EdgeInsets.all(dimensions.iconSize * 0.3),
                    decoration: BoxDecoration(
                      color: widget.isOnline 
                          ? activeColor.withOpacity(0.1)
                          : inactiveColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: widget.isToggling
                        ? SizedBox(
                            width: dimensions.iconSize,
                            height: dimensions.iconSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                widget.isOnline ? activeColor : inactiveColor,
                              ),
                            ),
                          )
                        : Icon(
                            widget.isOnline ? Icons.wifi : Icons.wifi_off,
                            color: widget.isOnline ? activeColor : inactiveColor,
                            size: dimensions.iconSize,
                          ),
                  ),
                  if (widget.showLabel) SizedBox(width: dimensions.iconSize * 0.7),
                ],
                if (widget.showLabel)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isOnline 
                              ? localizations.online 
                              : localizations.offline,
                          style: TextStyle(
                            color: widget.isOnline ? activeColor : inactiveColor,
                            fontSize: dimensions.fontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.isOnline
                              ? localizations.readyToReceiveOrders
                              : localizations.ordersArePaused,
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: dimensions.fontSize * 0.85,
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
    );
  }

  Widget _buildSwitch(
    BuildContext context,
    AppLocalizations localizations,
    StatusToggleDimensions dimensions,
    Color activeColor,
    Color inactiveColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel) ...[
          Text(
            widget.isOnline 
                ? localizations.online 
                : localizations.offline,
            style: TextStyle(
              fontSize: dimensions.fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: dimensions.iconSize * 0.5),
        ],
        widget.isToggling
            ? SizedBox(
                width: 48,
                height: 28,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        widget.isOnline ? activeColor : inactiveColor,
                      ),
                    ),
                  ),
                ),
              )
            : Switch.adaptive(
                value: widget.isOnline,
                onChanged: (value) => _handleToggle(),
                activeColor: activeColor,
                inactiveThumbColor: inactiveColor,
                activeTrackColor: activeColor.withOpacity(0.3),
                inactiveTrackColor: inactiveColor.withOpacity(0.3),
              ),
      ],
    );
  }

  Widget _buildButton(
    BuildContext context,
    AppLocalizations localizations,
    ThemeData theme,
    StatusToggleDimensions dimensions,
    Color activeColor,
    Color inactiveColor,
  ) {
    return SizedBox(
      height: dimensions.height,
      child: ElevatedButton.icon(
        onPressed: widget.isToggling ? null : _handleToggle,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.isOnline ? activeColor : inactiveColor,
          foregroundColor: Colors.white,
          padding: dimensions.padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dimensions.height / 2),
          ),
        ),
        icon: widget.isToggling
            ? SizedBox(
                width: dimensions.iconSize,
                height: dimensions.iconSize,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Icon(
                widget.isOnline ? Icons.wifi : Icons.wifi_off,
                size: dimensions.iconSize,
              ),
        label: widget.showLabel
            ? Text(
                widget.isOnline 
                    ? localizations.goOffline ?? 'Go Offline'
                    : localizations.goOnline ?? 'Go Online',
                style: TextStyle(
                  fontSize: dimensions.fontSize,
                  fontWeight: FontWeight.w600,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// Variants for different UI contexts
enum StatusToggleVariant {
  adaptive,    // Automatically chooses best variant for screen size
  iconButton,  // Compact icon button (mobile AppBars)
  chip,        // Chip style (tablet navigation)
  card,        // Card style (desktop sidebars)
  toggle,      // Toggle switch component (settings pages)
  button,      // Button style (dedicated status pages)
}

/// Size variants
enum StatusToggleSize {
  small,
  medium,
  large,
}

/// Responsive dimensions container
class StatusToggleDimensions {
  final double iconSize;
  final double fontSize;
  final EdgeInsets padding;
  final double height;

  const StatusToggleDimensions({
    required this.iconSize,
    required this.fontSize,
    required this.padding,
    required this.height,
  });
}
