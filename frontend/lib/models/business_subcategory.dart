class BusinessSubcategory {
  final String subcategoryId;
  final String businessType;
  final String nameEn;
  final String nameAr;
  final String? descriptionEn;
  final String? descriptionAr;

  const BusinessSubcategory({
    required this.subcategoryId,
    required this.businessType,
    required this.nameEn,
    required this.nameAr,
    this.descriptionEn,
    this.descriptionAr,
  });

  factory BusinessSubcategory.fromJson(Map<String, dynamic> json) {
    return BusinessSubcategory(
      subcategoryId: json['subcategoryId'] as String,
      businessType: json['businessType'] as String,
      nameEn: json['name_en'] as String,
      nameAr: json['name_ar'] as String,
      descriptionEn: json['description_en'] as String?,
      descriptionAr: json['description_ar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subcategoryId': subcategoryId,
      'businessType': businessType,
      'name_en': nameEn,
      'name_ar': nameAr,
      'description_en': descriptionEn,
      'description_ar': descriptionAr,
    };
  }

  @override
  String toString() {
    return 'BusinessSubcategory(subcategoryId: $subcategoryId, businessType: $businessType, nameEn: $nameEn, nameAr: $nameAr)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessSubcategory && other.subcategoryId == subcategoryId;
  }

  @override
  int get hashCode => subcategoryId.hashCode;
}
