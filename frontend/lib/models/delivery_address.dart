class DeliveryAddress {
  final String street;
  final String city;
  final String? state;
  final String? zipCode;
  final String? instructions;
  final double? latitude;
  final double? longitude;

  DeliveryAddress({
    required this.street,
    required this.city,
    this.state,
    this.zipCode,
    this.instructions,
    this.latitude,
    this.longitude,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as Map<String, dynamic>?;
    return DeliveryAddress(
      street: json['street'] ?? 'N/A',
      city: json['city'] ?? 'N/A',
      state: json['state'],
      zipCode: json['zipCode'],
      instructions: json['instructions'],
      latitude: (coordinates?['latitude'] as num?)?.toDouble(),
      longitude: (coordinates?['longitude'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() {
    return '$street, $city, ${state ?? ''} ${zipCode ?? ''}';
  }
}
