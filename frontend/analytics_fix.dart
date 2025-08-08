// Fix for _getStatusColor function in analytics_page.dart
// Replace the existing _getStatusColor function with this complete version:

Color _getStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return const Color(0xFFFF9800);
    case OrderStatus.confirmed:
      return const Color(0xFF2196F3);
    case OrderStatus.preparing:
      return const Color(0xFF4169E1);
    case OrderStatus.ready:
      return const Color(0xFF4CAF50);
    case OrderStatus.onTheWay:
      return const Color(0xFF9932CC);
    case OrderStatus.delivered:
      return const Color(0xFF228B22);
    case OrderStatus.cancelled:
      return const Color(0xFFF44336);
    case OrderStatus.returned:
      return const Color(0xFF795548);
    case OrderStatus.expired:
      return const Color(0xFF607D8B);
    default:
      return const Color(0xFF607D8B); // Default fallback color
  }
}
