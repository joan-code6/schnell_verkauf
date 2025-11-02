class ProductData {
  final String title;
  final String description;
  final double price;
  final List<String> imagePaths;
  final List<String> searchKeywords; // optional keywords returned by AI for smart pricing
  
  ProductData({
    required this.title,
    required this.description,
    required this.price,
    required this.imagePaths,
    this.searchKeywords = const [],
  });
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'imagePaths': imagePaths,
      'searchKeywords': searchKeywords,
    };
  }
  
  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      imagePaths: List<String>.from(json['imagePaths'] ?? []),
      searchKeywords: List<String>.from(json['searchKeywords'] ?? const []),
    );
  }
  
  ProductData copyWith({
    String? title,
    String? description,
    double? price,
    List<String>? imagePaths,
    List<String>? searchKeywords,
  }) {
    return ProductData(
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imagePaths: imagePaths ?? this.imagePaths,
      searchKeywords: searchKeywords ?? this.searchKeywords,
    );
  }
}
