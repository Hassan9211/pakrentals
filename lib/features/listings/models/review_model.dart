import '../../auth/models/user_model.dart';

class ReviewModel {
  final int id;
  final int listingId;
  final int userId;
  final int rating;
  final String? comment;
  final UserModel? user;
  final String? createdAt;

  ReviewModel({
    required this.id,
    required this.listingId,
    required this.userId,
    required this.rating,
    this.comment,
    this.user,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? 0,
      listingId: json['listing_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      createdAt: json['created_at'],
    );
  }
}
