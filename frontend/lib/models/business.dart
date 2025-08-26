import 'package:flutter/foundation.dart';

enum BusinessType { restaurant, cloudKitchen, pharmacy, store }

class Business {
  String id;
  String name;
  String email;
  String? phone;
  String? ownerName;
  BusinessType businessType;
  String? address;
  double? latitude;
  double? longitude;
  String? description;
  String? website;
  String? businessPhotoUrl;
  String status;
  DateTime? createdAt;
  DateTime? updatedAt;

  Business({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.ownerName,
    required this.businessType,
    this.address,
    this.latitude,
    this.longitude,
    this.description,
    this.website,
    this.businessPhotoUrl,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['businessId'] ?? json['id'] ?? '',
      name: json['businessName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phoneNumber'] ?? json['phone'] ?? json['phone_number'],
      ownerName: json['ownerName'] ?? json['owner_name'],
      businessType: _parseBusinessType(
          json['businessType'] ?? json['business_type'] ?? 'restaurant'),
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      description: json['description'],
      website: json['website'],
      businessPhotoUrl: json['businessPhotoUrl'] ?? json['business_photo_url'],
      status: json['status'] ?? 'pending',
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  static BusinessType _parseBusinessType(String type) {
    switch (type.toLowerCase()) {
      case 'restaurant':
        return BusinessType.restaurant;
      case 'cloudkitchen':
      case 'cloud_kitchen':
        return BusinessType.cloudKitchen;
      case 'pharmacy':
        return BusinessType.pharmacy;
      case 'store':
        return BusinessType.store;
      default:
        return BusinessType.restaurant;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': id,
      'businessName': name,
      'email': email,
      'phoneNumber': phone,
      'ownerName': ownerName,
      'businessType': businessType.name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'website': website,
      'businessPhotoUrl': businessPhotoUrl,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  void updateProfile({
    String? name,
    String? ownerName,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    String? email,
    String? description,
    String? website,
    String? businessPhotoUrl,
  }) {
    if (name != null) this.name = name;
    if (ownerName != null) this.ownerName = ownerName;
    if (phone != null) this.phone = phone;
    if (address != null) this.address = address;
    if (latitude != null) this.latitude = latitude;
    if (longitude != null) this.longitude = longitude;
    if (email != null) this.email = email;
    if (description != null) this.description = description;
    if (website != null) this.website = website;
    if (businessPhotoUrl != null) this.businessPhotoUrl = businessPhotoUrl;
    updatedAt = DateTime.now();
  }

  Business copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? ownerName,
    BusinessType? businessType,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
    String? website,
    String? businessPhotoUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      ownerName: ownerName ?? this.ownerName,
      businessType: businessType ?? this.businessType,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      website: website ?? this.website,
      businessPhotoUrl: businessPhotoUrl ?? this.businessPhotoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Business(id: $id, name: $name, email: $email, businessType: $businessType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Business && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
