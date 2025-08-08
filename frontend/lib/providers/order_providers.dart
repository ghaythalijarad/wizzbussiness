import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import 'business_provider.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

final pendingOrdersProvider =
    FutureProvider.autoDispose<List<Order>>((ref) async {
  final businessId =
      await ref.watch(businessProvider.select((b) => b.value?.id));
  if (businessId == null) return [];
  final orders =
      await ref.watch(orderServiceProvider).getMerchantOrders(businessId);
  return orders
      .where((order) => order.status.toString().contains('pending'))
      .toList();
});

final confirmedOrdersProvider =
    FutureProvider.autoDispose<List<Order>>((ref) async {
  final businessId =
      await ref.watch(businessProvider.select((b) => b.value?.id));
  if (businessId == null) return [];
  final orders =
      await ref.watch(orderServiceProvider).getMerchantOrders(businessId);
  return orders
      .where((order) => order.status.toString().contains('confirmed'))
      .toList();
});

final allOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final businessId =
      await ref.watch(businessProvider.select((b) => b.value?.id));
  if (businessId == null) return [];
  return ref.watch(orderServiceProvider).getMerchantOrders(businessId);
});
