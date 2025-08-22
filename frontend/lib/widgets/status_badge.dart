// Status Badge Component - Material You status indicators
// Displays order status with proper color coding and accessibility

import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';
import '../theme/theme_config.dart'; // add for AppSpacing & AppBorderRadius

enum StatusVariant {
  filled,
  outlined,
  soft,
}

enum StatusSize {
  small,
  medium,
  large,
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.variant = StatusVariant.filled,
    this.size = StatusSize.medium,
    this.customColor,
    this.customBackgroundColor,
    this.icon,
  });

  final String status;
  final StatusVariant variant;
  final StatusSize size;
  final Color? customColor;
  final Color? customBackgroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final statusColor = customColor ?? context.getStatusColor(status);
    final backgroundColor =
        customBackgroundColor ?? context.getStatusBackgroundColor(status);

    final padding = _getPadding();
    final textStyle = _getTextStyle(context);

    return Container(
      padding: padding,
      decoration: _getDecoration(statusColor, backgroundColor, context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: _getIconSize(),
              color: _getContentColor(statusColor, backgroundColor, context),
            ),
            SizedBox(width: AppSpacing.xs),
          ],
          Text(
            _getDisplayText(),
            style: textStyle.copyWith(
              color: _getContentColor(statusColor, backgroundColor, context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case StatusSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        );
      case StatusSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
      case StatusSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case StatusSize.small:
        return AppBorderRadius.sm;
      case StatusSize.medium:
        return AppBorderRadius.md;
      case StatusSize.large:
        return AppBorderRadius.lg;
    }
  }

  double _getIconSize() {
    switch (size) {
      case StatusSize.small:
        return 12.0;
      case StatusSize.medium:
        return 16.0;
      case StatusSize.large:
        return 20.0;
    }
  }

  TextStyle _getTextStyle(BuildContext context) {
    final theme = Theme.of(context);
    switch (size) {
      case StatusSize.small:
        return theme.textTheme.labelSmall!;
      case StatusSize.medium:
        return theme.textTheme.labelMedium!;
      case StatusSize.large:
        return theme.textTheme.labelLarge!;
    }
  }

  Decoration _getDecoration(
      Color statusColor, Color backgroundColor, BuildContext context) {
    switch (variant) {
      case StatusVariant.filled:
        return BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        );
      case StatusVariant.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: statusColor, width: 1.5),
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        );
      case StatusVariant.soft:
        return BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(_getBorderRadius()),
        );
    }
  }

  Color _getContentColor(
      Color statusColor, Color backgroundColor, BuildContext context) {
    switch (variant) {
      case StatusVariant.filled:
        // Use white text on filled backgrounds
        return Colors.white;
      case StatusVariant.outlined:
        return statusColor;
      case StatusVariant.soft:
        return statusColor;
    }
  }

  String _getDisplayText() {
    // Capitalize first letter and format the status text
    return status
        .split('_')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  /// Factory constructors for common status types
  factory StatusBadge.delivered({
    StatusVariant variant = StatusVariant.filled,
    StatusSize size = StatusSize.medium,
  }) {
    return StatusBadge(
      status: 'delivered',
      variant: variant,
      size: size,
      icon: Icons.check_circle,
    );
  }

  factory StatusBadge.processing({
    StatusVariant variant = StatusVariant.filled,
    StatusSize size = StatusSize.medium,
  }) {
    return StatusBadge(
      status: 'processing',
      variant: variant,
      size: size,
      icon: Icons.hourglass_top,
    );
  }

  factory StatusBadge.pending({
    StatusVariant variant = StatusVariant.filled,
    StatusSize size = StatusSize.medium,
  }) {
    return StatusBadge(
      status: 'pending',
      variant: variant,
      size: size,
      icon: Icons.schedule,
    );
  }

  factory StatusBadge.cancelled({
    StatusVariant variant = StatusVariant.filled,
    StatusSize size = StatusSize.medium,
  }) {
    return StatusBadge(
      status: 'cancelled',
      variant: variant,
      size: size,
      icon: Icons.cancel,
    );
  }
}
