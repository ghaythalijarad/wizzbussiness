/// Types of discounts available
enum DiscountType {
  percentage,
  conditional,
  freeDelivery,
  buyXGetY,
}

/// Applicability rules for discounts
enum DiscountApplicability {
  allItems,
  specificItems,
  specificCategories,
  minimumOrder,
}

/// Status of a discount
enum DiscountStatus {
  active,
  scheduled,
  expired,
  paused,
}

/// Rules for conditional discounts
enum ConditionalDiscountRule {
  buyXGetY,
  buyXGetYPercent,
  tieredQuantity,
  bundleDiscount,
}

/// Represents a discount available to a business
class Discount {
  final String id;
  final String title;
  final String description;
  final DiscountType type;
  final double value;
  final DiscountApplicability applicability;
  final List<String> applicableItemIds;
  final List<String> applicableCategoryIds;
  final double minimumOrderAmount;
  final DateTime validFrom;
  final DateTime validTo;
  final int? usageLimit;
  final int usageCount;
  final DiscountStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ConditionalDiscountRule? conditionalRule;
  final Map<String, dynamic> conditionalParameters;

  Discount({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.applicability,
    this.applicableItemIds = const [],
    this.applicableCategoryIds = const [],
    this.minimumOrderAmount = 0.0,
    required this.validFrom,
    required this.validTo,
    this.usageLimit,
    this.usageCount = 0,
    this.status = DiscountStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.conditionalRule,
    this.conditionalParameters = const {},
  });

  bool get isActive => status == DiscountStatus.active;

  /// Creates a copy of this discount with modified fields
  Discount copyWith({
    DiscountStatus? status,
  }) {
    return Discount(
      id: id,
      title: title,
      description: description,
      type: type,
      value: value,
      applicability: applicability,
      applicableItemIds: applicableItemIds,
      applicableCategoryIds: applicableCategoryIds,
      minimumOrderAmount: minimumOrderAmount,
      validFrom: validFrom,
      validTo: validTo,
      usageLimit: usageLimit,
      usageCount: usageCount,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      conditionalRule: conditionalRule,
      conditionalParameters: conditionalParameters,
    );
  }

  /// Convert Discount to a JSON-serializable map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'value': value,
      'applicability': applicability.name,
      'applicableItemIds': applicableItemIds,
      'applicableCategoryIds': applicableCategoryIds,
      'minimumOrderAmount': minimumOrderAmount,
      'validFrom': validFrom.toIso8601String(),
      'validTo': validTo.toIso8601String(),
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'conditionalRule': conditionalRule?.name,
      'conditionalParameters': conditionalParameters,
    };
  }

  /// Create a Discount instance from JSON map
  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      id: json['id'] ?? json['discountId'] ?? json['discount_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: _parseDiscountType(json['type']),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      applicability: _parseDiscountApplicability(json['applicability']),
      applicableItemIds: List<String>.from(
          json['applicableItemIds'] ?? json['applicable_item_ids'] ?? []),
      applicableCategoryIds: List<String>.from(json['applicableCategoryIds'] ??
          json['applicable_category_ids'] ??
          []),
      minimumOrderAmount:
          (json['minimumOrderAmount'] ?? json['minimum_order_amount'] as num?)
                  ?.toDouble() ??
              0.0,
      validFrom: _parseDateTime(json['validFrom'] ?? json['valid_from']),
      validTo: _parseDateTime(json['validTo'] ?? json['valid_to']),
      usageLimit: json['usageLimit'] ?? json['usage_limit'] as int?,
      usageCount: (json['usageCount'] ?? json['usage_count'] as int?) ?? 0,
      status: _parseDiscountStatus(json['status']),
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
      conditionalRule:
          json['conditionalRule'] != null || json['conditional_rule'] != null
              ? ConditionalDiscountRule.values.firstWhere(
                  (e) =>
                      e.name ==
                      (json['conditionalRule'] ?? json['conditional_rule']),
                  orElse: () => ConditionalDiscountRule.buyXGetY)
              : null,
      conditionalParameters: Map<String, dynamic>.from(
          json['conditionalParameters'] ??
              json['conditional_parameters'] ??
              {}),
    );
  }

  static DiscountType _parseDiscountType(dynamic type) {
    if (type == null) return DiscountType.percentage;
    return DiscountType.values.firstWhere(
      (e) => e.name == type.toString(),
      orElse: () => DiscountType.percentage,
    );
  }

  static DiscountApplicability _parseDiscountApplicability(
      dynamic applicability) {
    if (applicability == null) return DiscountApplicability.allItems;
    return DiscountApplicability.values.firstWhere(
      (e) => e.name == applicability.toString(),
      orElse: () => DiscountApplicability.allItems,
    );
  }

  static DiscountStatus _parseDiscountStatus(dynamic status) {
    if (status == null) return DiscountStatus.active;
    return DiscountStatus.values.firstWhere(
      (e) => e.name == status.toString(),
      orElse: () => DiscountStatus.active,
    );
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();

    try {
      // Handle string dates from backend
      if (dateTime is String) {
        // Remove microseconds if present for compatibility
        String dateStr = dateTime;
        if (dateStr.contains('.') && !dateStr.endsWith('Z')) {
          // Format like "2025-07-18T02:43:32.014670" needs to be converted
          dateStr = dateStr.split('.')[0] + 'Z';
        }
        return DateTime.parse(dateStr);
      }

      // Handle DateTime objects
      if (dateTime is DateTime) {
        return dateTime;
      }

      // Fallback to current time
      return DateTime.now();
    } catch (e) {
      print('Error parsing date: $dateTime, error: $e');
      return DateTime.now();
    }
  }
}
