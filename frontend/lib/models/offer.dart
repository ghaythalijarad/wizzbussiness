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
}
