import 'package:isar/isar.dart';

part 'product.g.dart';

@collection
class Product {
  Id get isarId => fastHash(id);
  
  /// Unique ID
  @Index(unique: true)
  final String id;
  
  /// Product name
  final String name;
  
  /// Product description
  final String description;
  
  /// Price in dollars
  final double price;
  
  /// Discount percentage (0-100)
  final double? discountPercent;
  
  /// Product rating (0-5)
  final double? rating;
  
  /// Number of ratings
  final int? ratingCount;
  
  /// Product category
  @Enumerated(EnumType.name)
  final ProductCategory category;
  
  /// Sub-category for more specific categorization
  final String? subCategory;
  
  /// Pet types this product is suitable for
  final List<String> forPetTypes;
  
  /// Images of the product
  final List<String> imageUrls;
  
  /// Whether this product is featured
  final bool isFeatured;
  
  /// Whether this product is a best seller
  final bool isBestSeller;
  
  /// Whether this product is new
  final bool isNew;
  
  /// Available sizes (if applicable)
  final List<String>? availableSizes;
  
  /// Available colors (if applicable)
  final List<String>? availableColors;
  
  /// Stock quantity
  final int stock;
  
  /// Product brand
  final String brand;
  
  /// Product tags
  final List<String> tags;
  
  /// When the product was created
  final DateTime createdAt;
  
  /// When the product was last updated
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPercent,
    this.rating,
    this.ratingCount,
    required this.category,
    this.subCategory,
    required this.forPetTypes,
    required this.imageUrls,
    required this.isFeatured,
    required this.isBestSeller,
    required this.isNew,
    this.availableSizes,
    this.availableColors,
    required this.stock,
    required this.brand,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// Calculate the discounted price
  double get discountedPrice {
    if (discountPercent == null || discountPercent! <= 0 || discountPercent! >= 100) {
      return price;
    }
    
    return price * (1 - discountPercent! / 100);
  }
  
  /// Check if the product is on sale
  bool get isOnSale => discountPercent != null && discountPercent! > 0;
  
  /// Check if the product is in stock
  bool get isInStock => stock > 0;
  
  /// Create a copy of this product with optional new values
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discountPercent,
    double? rating,
    int? ratingCount,
    ProductCategory? category,
    String? subCategory,
    List<String>? forPetTypes,
    List<String>? imageUrls,
    bool? isFeatured,
    bool? isBestSeller,
    bool? isNew,
    List<String>? availableSizes,
    List<String>? availableColors,
    int? stock,
    String? brand,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPercent: discountPercent ?? this.discountPercent,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      forPetTypes: forPetTypes ?? this.forPetTypes,
      imageUrls: imageUrls ?? this.imageUrls,
      isFeatured: isFeatured ?? this.isFeatured,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      isNew: isNew ?? this.isNew,
      availableSizes: availableSizes ?? this.availableSizes,
      availableColors: availableColors ?? this.availableColors,
      stock: stock ?? this.stock,
      brand: brand ?? this.brand,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Convert product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discount_percent': discountPercent,
      'rating': rating,
      'rating_count': ratingCount,
      'category': category.name,
      'sub_category': subCategory,
      'for_pet_types': forPetTypes,
      'image_urls': imageUrls,
      'is_featured': isFeatured,
      'is_best_seller': isBestSeller,
      'is_new': isNew,
      'available_sizes': availableSizes,
      'available_colors': availableColors,
      'stock': stock,
      'brand': brand,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  /// Create product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] is int)
          ? json['price'].toDouble()
          : json['price'],
      discountPercent: json['discount_percent'] != null
          ? (json['discount_percent'] is int)
              ? json['discount_percent'].toDouble()
              : json['discount_percent']
          : null,
      rating: json['rating'] != null
          ? (json['rating'] is int)
              ? json['rating'].toDouble()
              : json['rating']
          : null,
      ratingCount: json['rating_count'],
      category: _parseCategory(json['category']),
      subCategory: json['sub_category'],
      forPetTypes: json['for_pet_types'] != null
          ? List<String>.from(json['for_pet_types'])
          : [],
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : [],
      isFeatured: json['is_featured'] ?? false,
      isBestSeller: json['is_best_seller'] ?? false,
      isNew: json['is_new'] ?? false,
      availableSizes: json['available_sizes'] != null
          ? List<String>.from(json['available_sizes'])
          : null,
      availableColors: json['available_colors'] != null
          ? List<String>.from(json['available_colors'])
          : null,
      stock: json['stock'] ?? 0,
      brand: json['brand'] ?? '',
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }
  
  /// Parse category from string
  static ProductCategory _parseCategory(String? categoryName) {
    switch (categoryName?.toLowerCase()) {
      case 'food':
        return ProductCategory.food;
      case 'treats':
        return ProductCategory.treats;
      case 'toys':
        return ProductCategory.toys;
      case 'accessories':
        return ProductCategory.accessories;
      case 'health':
        return ProductCategory.health;
      case 'grooming':
        return ProductCategory.grooming;
      case 'clothing':
        return ProductCategory.clothing;
      case 'travel':
        return ProductCategory.travel;
      case 'training':
        return ProductCategory.training;
      case 'technology':
        return ProductCategory.technology;
      case 'services':
        return ProductCategory.services;
      default:
        return ProductCategory.other;
    }
  }
}

/// Product categories
enum ProductCategory {
  food,
  treats,
  toys,
  accessories,
  health,
  grooming,
  clothing,
  travel,
  training,
  technology,
  services,
  other,
}

/// Convert string to integer hash for Isar ID
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}