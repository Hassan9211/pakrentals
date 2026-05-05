import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/mock/mock_data.dart';
import '../models/listing_model.dart';
import '../models/review_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BROWSE STATE
// ─────────────────────────────────────────────────────────────────────────────
class BrowseState {
  final List<ListingModel> listings;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final Map<String, dynamic> filters;

  const BrowseState({
    this.listings = const [],
    this.isLoading = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.error,
    this.filters = const {},
  });

  BrowseState copyWith({
    List<ListingModel>? listings,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
    Map<String, dynamic>? filters,
  }) {
    return BrowseState(
      listings: listings ?? this.listings,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
      filters: filters ?? this.filters,
    );
  }
}

class BrowseNotifier extends StateNotifier<BrowseState> {
  BrowseNotifier() : super(const BrowseState()) {
    loadListings();
  }

  Future<void> loadListings({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 500));

    var results = List<ListingModel>.from(mockListings);

    // Apply filters
    final filters = state.filters;

    if (filters['search'] != null && (filters['search'] as String).isNotEmpty) {
      final q = (filters['search'] as String).toLowerCase();
      results = results
          .where((l) =>
              l.title.toLowerCase().contains(q) ||
              l.city.toLowerCase().contains(q) ||
              (l.category?.name.toLowerCase().contains(q) ?? false))
          .toList();
    }

    if (filters['category_id'] != null) {
      results = results
          .where((l) => l.category?.id == filters['category_id'])
          .toList();
    }

    if (filters['city'] != null && (filters['city'] as String).isNotEmpty) {
      final city = (filters['city'] as String).toLowerCase();
      results = results
          .where((l) => l.city.toLowerCase().contains(city))
          .toList();
    }

    if (filters['min_price'] != null) {
      final min = double.tryParse(filters['min_price'].toString()) ?? 0;
      results = results.where((l) => l.pricePerDay >= min).toList();
    }

    if (filters['max_price'] != null) {
      final max = double.tryParse(filters['max_price'].toString()) ?? double.infinity;
      results = results.where((l) => l.pricePerDay <= max).toList();
    }

    // Apply sort
    final sort = filters['sort'] ?? 'latest';
    switch (sort) {
      case 'price_asc':
        results.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
        break;
      case 'price_desc':
        results.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
        break;
      case 'rating':
        results.sort((a, b) => (b.avgRating ?? 0).compareTo(a.avgRating ?? 0));
        break;
      default: // latest
        results.sort((a, b) =>
            (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    }

    state = state.copyWith(
      isLoading: false,
      listings: results,
      hasMore: false,
    );
  }

  Future<void> applyFilters(Map<String, dynamic> filters) async {
    state = state.copyWith(
      filters: filters,
      listings: [],
      currentPage: 1,
    );
    await loadListings(refresh: true);
  }

  Future<void> search(String query) async {
    await applyFilters({...state.filters, 'search': query});
  }
}

final browseProvider =
    StateNotifierProvider<BrowseNotifier, BrowseState>((ref) {
  return BrowseNotifier();
});

// ─────────────────────────────────────────────────────────────────────────────
// LISTING DETAIL STATE
// ─────────────────────────────────────────────────────────────────────────────
class ListingDetailState {
  final ListingModel? listing;
  final List<ReviewModel> reviews;
  final List<String> unavailableDates;
  final bool isLoading;
  final String? error;

  const ListingDetailState({
    this.listing,
    this.reviews = const [],
    this.unavailableDates = const [],
    this.isLoading = false,
    this.error,
  });

  ListingDetailState copyWith({
    ListingModel? listing,
    List<ReviewModel>? reviews,
    List<String>? unavailableDates,
    bool? isLoading,
    String? error,
  }) {
    return ListingDetailState(
      listing: listing ?? this.listing,
      reviews: reviews ?? this.reviews,
      unavailableDates: unavailableDates ?? this.unavailableDates,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ListingDetailNotifier extends StateNotifier<ListingDetailState> {
  final int listingId;

  ListingDetailNotifier(this.listingId) : super(const ListingDetailState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 400));

    final listing = mockListings.firstWhere(
      (l) => l.id == listingId,
      orElse: () => mockListings.first,
    );

    final reviews = mockReviews
        .where((r) => r.listingId == listingId)
        .toList();

    state = state.copyWith(
      isLoading: false,
      listing: listing,
      reviews: reviews,
      unavailableDates: ['2024-05-18', '2024-05-19', '2024-05-25'],
    );
  }
}

final listingDetailProvider = StateNotifierProvider.family<
    ListingDetailNotifier, ListingDetailState, int>((ref, id) {
  return ListingDetailNotifier(id);
});
