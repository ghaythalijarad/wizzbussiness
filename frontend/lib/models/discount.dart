/// Types of discounts available
enum DiscountType {
  percentage,
  fixedAmount,
  conditional,
  freeDelivery,
  others,
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
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: DiscountType.values.firstWhere((e) => e.name == json['type']),
      value: (json['value'] as num).toDouble(),
      applicability: DiscountApplicability.values
          .firstWhere((e) => e.name == json['applicability']),
      applicableItemIds: List<String>.from(json['applicableItemIds'] ?? []),
      applicableCategoryIds:
          List<String>.from(json['applicableCategoryIds'] ?? []),
      minimumOrderAmount:
          (json['minimumOrderAmount'] as num?)?.toDouble() ?? 0.0,
      validFrom: DateTime.parse(json['validFrom'] as String),
      validTo: DateTime.parse(json['validTo'] as String),
      usageLimit: json['usageLimit'] as int?,
      usageCount: json['usageCount'] as int? ?? 0,
      status: DiscountStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      conditionalRule: json['conditionalRule'] != null
          ? ConditionalDiscountRule.values
              .firstWhere((e) => e.name == json['conditionalRule'])
          : null,
      conditionalParameters:
          Map<String, dynamic>.from(json['conditionalParameters'] ?? {}),
    );
  }
}
