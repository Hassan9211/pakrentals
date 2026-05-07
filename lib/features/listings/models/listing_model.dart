import 'category_model.dart';
import '../../auth/models/user_model.dart';

class ListingModel {
  final int id;
  final String? firestoreId;   // Firebase document ID (string)
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
    this.firestoreId,
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
          final decoded = raw
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .split(',');
          return decoded.where((e) => e.trim().isNotEmpty).toList();
        } catch (_) {
          return [raw];
        }
      }
      return [];
    }

    // id: use int if available, else hash the string Firestore ID
    final rawId = json['id'];
    final int id;
    String? firestoreId;

    if (rawId is int) {
      id = rawId;
    } else if (rawId is String && rawId.isNotEmpty) {
      // Firestore string ID — store as firestoreId, hash for int id
      firestoreId = rawId;
      id = rawId.hashCode.abs();
    } else {
      id = 0;
    }

    // Also check explicit firestore_id field
    firestoreId ??= json['firestore_id']?.toString();

    // Build host from Firestore fields
    UserModel? host;
    if (json['user'] != null) {
      host = UserModel.fromJson(json['user']);
    } else if (json['host_id'] != null || json['host_name'] != null) {
      host = UserModel(
        id: (json['host_id']?.toString() ?? '').hashCode.abs(),
        name: json['host_name'] ?? '',
        email: json['host_email'] ?? '',
      );
    }

    // Build category from Firestore fields
    CategoryModel? category;
    if (json['category'] != null) {
      category = CategoryModel.fromJson(json['category']);
    } else if (json['category_name'] != null) {
      category = CategoryModel(
        id: int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
        name: json['category_name'] ?? '',
        icon: json['category_icon'],
      );
    }

    return ListingModel(
      id: id,
      firestoreId: firestoreId,
      title: json['title'] ?? '',
      description: json['description'],
      pricePerDay:
          double.tryParse(json['price_per_day']?.toString() ?? '0') ?? 0,
      city: json['city'] ?? '',
      address: json['address'],
      images: parseImages(json['images']),
      status: json['status'] ?? 'active',
      isFeatured:
          json['is_featured'] == true || json['is_featured'] == 1,
      avgRating: json['avg_rating'] != null
          ? double.tryParse(json['avg_rating'].toString())
          : null,
      reviewsCount: json['reviews_count'],
      isSaved: json['is_saved'],
      category: category,
      subCategory: json['sub_category'] != null
          ? SubCategoryModel.fromJson(json['sub_category'])
          : null,
      host: host,
      createdAt: json['created_at']?.toString(),
    );
  }

  String get firstImage => images.isNotEmpty ? images.first : '';

  /// Returns the correct ID to use for Firestore operations
  String get effectiveId => firestoreId ?? id.toString();
}
