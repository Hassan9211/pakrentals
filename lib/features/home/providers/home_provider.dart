import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../listings/models/category_model.dart';
import '../../listings/models/listing_model.dart';
class HomeStats {
  final int totalListings;
  final int totalUsers;
  final int totalCities;
  final double avgRating;

  const HomeStats({
    this.totalListings = 0,
    this.totalUsers = 0,
    this.totalCities = 0,
    this.avgRating = 0.0,
  });
}

class HomeState {
  final List<CategoryModel> categories;
  final List<ListingModel> featuredListings;
  final HomeStats stats;
  final bool isLoading;
  final String? error;

  const HomeState({
    this.categories = const [],
    this.featuredListings = const [],
    this.stats = const HomeStats(),
    this.isLoading = false,
    this.error,
  });

  HomeState copyWith({
    List<CategoryModel>? categories,
    List<ListingModel>? featuredListings,
    HomeStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return HomeState(
      categories: categories ?? this.categories,
      featuredListings: featuredListings ?? this.featuredListings,
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

    try {
      // Load categories from Firestore
      List<CategoryModel> cats = [];
      try {
        final catSnap = await FirebaseFirestore.instance
            .collection('categories')
            .orderBy('order')
            .get()
            .timeout(const Duration(seconds: 8));
        if (catSnap.docs.isNotEmpty) {
          cats = catSnap.docs.map((d) {
            return CategoryModel.fromJson({'id': d.id, ...d.data()});
          }).toList();
        }
      } catch (_) {
        // Try without orderBy if index not ready
        try {
          final catSnap = await FirebaseFirestore.instance
              .collection('categories')
              .get()
              .timeout(const Duration(seconds: 8));
          cats = catSnap.docs.map((d) {
            return CategoryModel.fromJson({'id': d.id, ...d.data()});
          }).toList();
        } catch (_) {}
      }

      // Fallback to empty list if Firestore has no categories yet
      // (add categories in Firebase Console → categories collection)
      final results = await Future.wait([
        _fetchFeaturedListings(),
        _fetchStats(),
      ]);

      state = state.copyWith(
        isLoading: false,
        categories: cats,
        featuredListings: results[0] as List<ListingModel>,
        stats: results[1] as HomeStats,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        categories: state.categories.isEmpty ? [] : state.categories,
        featuredListings: [],
        stats: const HomeStats(),
      );
    }
  }

  // ── Fetch featured listings from Firestore ─────────────────────────────────
  Future<List<ListingModel>> _fetchFeaturedListings() async {
    try {
      // First try featured listings
      final featuredSnap = await FirebaseFirestore.instance
          .collection('listings')
          .where('is_featured', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .limit(10)
          .get()
          .timeout(const Duration(seconds: 8));

      if (featuredSnap.docs.isNotEmpty) {
        return featuredSnap.docs.map((doc) {
          return ListingModel.fromJson({'id': doc.id, ...doc.data()});
        }).toList();
      }

      // Fallback: show latest active listings if no featured ones
      final latestSnap = await FirebaseFirestore.instance
          .collection('listings')
          .where('status', isEqualTo: 'active')
          .limit(10)
          .get()
          .timeout(const Duration(seconds: 8));

      return latestSnap.docs.map((doc) {
        return ListingModel.fromJson({'id': doc.id, ...doc.data()});
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Fetch real stats from Firestore ────────────────────────────────────────
  Future<HomeStats> _fetchStats() async {
    try {
      // Use get() instead of count() — more compatible with Firestore rules
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('listings')
            .where('status', isEqualTo: 'active')
            .get()
            .timeout(const Duration(seconds: 8)),
        FirebaseFirestore.instance
            .collection('users')
            .get()
            .timeout(const Duration(seconds: 8)),
      ]);

      final listingsSnap = results[0] as QuerySnapshot;
      final usersSnap = results[1] as QuerySnapshot;

      final listingsCount = listingsSnap.docs.length;
      final usersCount = usersSnap.docs.length;

      // Count unique cities
      final cities = listingsSnap.docs
          .map((d) =>
              (d.data() as Map<String, dynamic>)['city']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toSet();

      // Average rating
      double avgRating = 0.0;
      final ratings = listingsSnap.docs
          .map((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['avg_rating'] as num?)?.toDouble() ?? 0.0;
          })
          .where((r) => r > 0)
          .toList();
      if (ratings.isNotEmpty) {
        avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
      }

      return HomeStats(
        totalListings: listingsCount,
        totalUsers: usersCount,
        totalCities: cities.length,
        avgRating: avgRating,
      );
    } catch (_) {
      return const HomeStats();
    }
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});
