class Offer {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime validFrom;
  final DateTime validTo;

  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.validFrom,
    required this.validTo,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
      validFrom: DateTime.tryParse(json['validFrom'] ?? json['valid_from'] ?? '') ?? DateTime.now(),
      validTo: DateTime.tryParse(json['validTo'] ?? json['valid_to'] ?? '') ?? DateTime.now().add(Duration(days: 30)),
    );
  }
}
