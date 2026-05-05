import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/mock/mock_data.dart';
import '../../listings/models/category_model.dart';
import '../../listings/models/listing_model.dart';
import '../../listings/models/review_model.dart';

class HomeState {
  final List<CategoryModel> categories;
  final List<ListingModel> featuredListings;
  final List<ReviewModel> latestReviews;
  final Map<String, dynamic> stats;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.categories = const [],
    this.featuredListings = const [],
    this.latestReviews = const [],
    this.stats = const {},
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    List<CategoryModel>? categories,
    List<ListingModel>? featuredListings,
    List<ReviewModel>? latestReviews,
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      categories: categories ?? this.categories,
      featuredListings: featuredListings ?? this.featuredListings,
      latestReviews: latestReviews ?? this.latestReviews,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState()) {
    loadHome();
  }

  Future<void> loadHome() async {
    state = state.copyWith(isLoading: true, error: null);
    // Simulate brief loading
    await Future.delayed(const Duration(milliseconds: 600));

    state = state.copyWith(
      isLoading: false,
      categories: mockCategories,
      featuredListings: mockListings.where((l) => l.isFeatured).toList(),
      latestReviews: mockReviews,
      stats: mockAdminStats,
    );
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});
