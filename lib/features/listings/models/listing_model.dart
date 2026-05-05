import 'category_model.dart';
import '../../auth/models/user_model.dart';

class ListingModel {
  final int id;
  final String title;
  final String? description;
  final double pricePerDay;
  final String city;
  final String? address;
  final List<String> images;
  final String status;
  final bool isFeatured;
  final double? avgRating;
  final int? reviewsCount;
  final bool? isSaved;
  final CategoryModel? category;
  final SubCategoryModel? subCategory;
  final UserModel? host;
  final String? createdAt;

  ListingModel({
    required this.id,
    required this.title,
    this.description,
    required this.pricePerDay,
    required this.city,
    this.address,
    this.images = const [],
    this.status = 'active',
    this.isFeatured = false,
    this.avgRating,
    this.reviewsCount,
    this.isSaved,
    this.category,
    this.subCategory,
    this.host,
    this.createdAt,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    List<String> parseImages(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String) {
        try {
          // Handle JSON-encoded string
          final decoded = raw.replaceAll('[', '').replaceAll(']', '')
              .replaceAll('"', '').split(',');
          return decoded.where((e) => e.trim().isNotEmpty).toList();
        } catch (_) {
          return [raw];
        }
      }
      return [];
    }

    return ListingModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      pricePerDay: double.tryParse(json['price_per_day']?.toString() ?? '0') ?? 0,
      city: json['city'] ?? '',
      address: json['address'],
      images: parseImages(json['images']),
      status: json['status'] ?? 'active',
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
      avgRating: json['avg_rating'] != null
          ? double.tryParse(json['avg_rating'].toString())
          : null,
      reviewsCount: json['reviews_count'],
      isSaved: json['is_saved'],
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
      subCategory: json['sub_category'] != null
          ? SubCategoryModel.fromJson(json['sub_category'])
          : null,
      host: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      createdAt: json['created_at'],
    );
  }

  String get firstImage => images.isNotEmpty ? images.first : '';
}
