enum StoreItemType { frame, entry, entryEffect, fancyId }

class StoreItem {
  final String id;
  final String name;
  final String imagePath;
  final String svgaUrl;
  final double price;
  final StoreItemType type;

  /// The effective display URL: prefer svgaUrl if available, fallback to imagePath
  String get displayUrl => svgaUrl.isNotEmpty ? svgaUrl : imagePath;

  StoreItem({
    required this.id,
    required this.name,
    required this.imagePath,
    this.svgaUrl = '',
    required this.price,
    required this.type,
  });
}
