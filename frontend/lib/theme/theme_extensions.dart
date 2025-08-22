// filepath: /Users/ghaythallaheebi/order-receiver-app-2/frontend/lib/theme/theme_extensions.dart
import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/discount.dart'; // for DiscountStatus

/// Convenience extensions for accessing Theme data from BuildContext.
/// Keeps widget code concise (e.g. context.colorScheme.primary).
extension ContextThemeExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // Added gradient helpers for MaterialCard
  Gradient get primaryGradient => LinearGradient(
        colors: [
          colorScheme.primary,
          colorScheme.primaryContainer,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  Gradient get secondaryGradient => LinearGradient(
        colors: [
          colorScheme.secondary,
          colorScheme.secondaryContainer,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  Gradient get primaryToSecondaryGradient => LinearGradient(
        colors: [
          colorScheme.primary,
          colorScheme.secondary,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

/// Unified status color utilities replacing scattered helpers.
/// Supports OrderStatus enum, DiscountStatus enum, or raw status String.
extension StatusColorExtensions on BuildContext {
  // Primary foreground color for a status
  Color getStatusColor(dynamic status) {
    final scheme = colorScheme;
    // Normalize status key
    String key;
    if (status is OrderStatus) {
      key = status.name;
    } else if (status is DiscountStatus) {
      key = status.name;
    } else if (status is String) {
      key = status.toLowerCase();
    } else {
      key = status.toString().toLowerCase();
    }

    switch (key) {
      // Order lifecycle
      case 'pending':
        return scheme.primary;
      case 'confirmed':
        return const Color(0xFF00A86B); // sea green
      case 'preparing':
        return const Color(0xFF4169E1); // royal blue
      case 'ready':
        return const Color(0xFFC6007E); // brand pink accent
      case 'ontheway':
      case 'on_the_way':
      case 'on-the-way':
      case 'onthewaydelivery':
        return const Color(0xFF9932CC); // dark orchid
      case 'delivered':
        return const Color(0xFF228B22); // forest green
      case 'cancelled':
      case 'canceled':
      case 'rejected':
        return const Color(0xFFDC143C); // crimson
      case 'returned':
        return const Color(0xFF8B4513); // saddle brown
      case 'expired':
        return const Color(0xFF708090); // slate gray

      // Discount statuses
      case 'active':
        return Colors.green.shade400;
      case 'scheduled':
        return scheme.primary;
      // fallthrough for discount expired uses existing expired mapping

      default:
        return scheme.secondary; // fallback accent
    }
  }

  // Softer background tint for status (used in soft / outlined variants)
  Color getStatusBackgroundColor(dynamic status) {
    final base = getStatusColor(status);
    // Use alpha-based translucent background ensuring sufficient contrast
    return base.withOpacity(0.12);
  }
}
