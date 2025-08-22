import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';

class OrderTimerService {
  OrderTimeoutStatus getUrgency(Order order) {
    if (order.status != OrderStatus.pending) {
      return OrderTimeoutStatus.notApplicable;
    }
    return order.timeoutStatus;
  }
}

final orderTimerServiceProvider = Provider<OrderTimerService>((ref) {
  return OrderTimerService();
});
