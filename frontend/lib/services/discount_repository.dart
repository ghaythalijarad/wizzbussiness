import '../models/discount.dart';

/// Repository interface for managing discounts (abstracts backend/storage details).
abstract class DiscountRepository {
  /// Fetch all discounts for the given business.
  Future<List<Discount>> fetchDiscounts(String businessId);

  /// Create a new discount in backend.
  Future<Discount> createDiscount(String businessId, Discount discount);

  /// Update an existing discount.
  Future<Discount> updateDiscount(String businessId, Discount discount);

  /// Delete a discount by ID.
  Future<void> deleteDiscount(String businessId, String discountId);

  /// Toggle discount status (active/paused).
  Future<void> toggleDiscountStatus(String businessId, String discountId);
}

/// A mock implementation of [DiscountRepository] for local/testing.
class MockDiscountRepository implements DiscountRepository {
  final Map<String, List<Discount>> _store = {};

  @override
  Future<Discount> createDiscount(String businessId, Discount discount) async {
    final list = _store.putIfAbsent(businessId, () => []);
    list.add(discount);
    return discount;
  }

  @override
  Future<void> deleteDiscount(String businessId, String discountId) async {
    _store[businessId]?.removeWhere((d) => d.id == discountId);
  }

  @override
  Future<List<Discount>> fetchDiscounts(String businessId) async {
    return _store[businessId] ?? [];
  }

  @override
  Future<Discount> updateDiscount(String businessId, Discount discount) async {
    final list = _store[businessId];
    if (list == null) throw Exception('Business not found');
    final index = list.indexWhere((d) => d.id == discount.id);
    if (index == -1) throw Exception('Discount not found');
    list[index] = discount;
    return discount;
  }

  @override
  Future<void> toggleDiscountStatus(
      String businessId, String discountId) async {
    final list = _store[businessId];
    if (list == null) return;
    final index = list.indexWhere((d) => d.id == discountId);
    if (index == -1) return;
    final disc = list[index];
    final newStatus = disc.status == DiscountStatus.active
        ? DiscountStatus.paused
        : DiscountStatus.active;
    list[index] = disc.copyWith(status: newStatus);
  }
}
