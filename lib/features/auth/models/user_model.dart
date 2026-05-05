class SavedPaymentMethod {
  final String id;       // unique identifier
  final String type;     // 'jazzcash' | 'easypaisa' | 'bank' | 'card'
  final String title;    // display name e.g. "JazzCash - 0300..."
  final String account;  // masked account number
  final bool isDefault;

  const SavedPaymentMethod({
    required this.id,
    required this.type,
    required this.title,
    required this.account,
    this.isDefault = false,
  });

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      id: json['id'] ?? '',
      type: json['type'] ?? 'jazzcash',
      title: json['title'] ?? '',
      account: json['account'] ?? '',
      isDefault: json['is_default'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'account': account,
    'is_default': isDefault,
  };
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? photo;
  final String? cnic;
  final String? cnicFrontPhoto;
  final String? cnicBackPhoto;
  final String cnicStatus;
  final List<SavedPaymentMethod> paymentMethods;
  final String role;
  final bool isVerified;
  final String? city;
  final String? bio;
  final double? rating;
  final int? reviewsCount;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photo,
    this.cnic,
    this.cnicFrontPhoto,
    this.cnicBackPhoto,
    this.cnicStatus = 'none',
    this.paymentMethods = const [],
    this.role = 'user',
    this.isVerified = false,
    this.city,
    this.bio,
    this.rating,
    this.reviewsCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      photo: json['photo'],
      cnic: json['cnic'],
      cnicFrontPhoto: json['cnic_front_photo'],
      cnicBackPhoto: json['cnic_back_photo'],
      cnicStatus: json['cnic_status'] ?? 'none',
      paymentMethods: (json['payment_methods'] as List<dynamic>? ?? [])
          .map((e) => SavedPaymentMethod.fromJson(e as Map<String, dynamic>))
          .toList(),
      role: json['role'] ?? 'user',
      isVerified: json['is_verified'] == true || json['email_verified_at'] != null,
      city: json['city'],
      bio: json['bio'],
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : null,
      reviewsCount: json['reviews_count'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'photo': photo,
    'cnic': cnic,
    'cnic_front_photo': cnicFrontPhoto,
    'cnic_back_photo': cnicBackPhoto,
    'cnic_status': cnicStatus,
    'payment_methods': paymentMethods.map((m) => m.toJson()).toList(),
    'role': role,
    'is_verified': isVerified,
    'city': city,
    'bio': bio,
    'rating': rating,
    'reviews_count': reviewsCount,
  };

  bool get isAdmin => role == 'admin';
  bool get isHost => role == 'host' || role == 'admin';
  bool get isCnicVerified => cnicStatus == 'verified';
  bool get isCnicPending => cnicStatus == 'pending';

  SavedPaymentMethod? get defaultPaymentMethod =>
      paymentMethods.where((m) => m.isDefault).firstOrNull ??
      (paymentMethods.isNotEmpty ? paymentMethods.first : null);
}
