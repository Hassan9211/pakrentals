class CategoryModel {
  final int id;
  final String name;
  final String? icon;
  final String? image;
  final int? listingsCount;
  final List<SubCategoryModel> subCategories;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.image,
    this.listingsCount,
    this.subCategories = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'],
      image: json['image'],
      listingsCount: json['listings_count'],
      subCategories: (json['sub_categories'] as List<dynamic>? ?? [])
          .map((e) => SubCategoryModel.fromJson(e))
          .toList(),
    );
  }
}

class SubCategoryModel {
  final int id;
  final int categoryId;
  final String name;

  SubCategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryModel(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}
