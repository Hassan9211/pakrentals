import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  static final _db = FirebaseFirestore.instance;

  BrowseNotifier() : super(const BrowseState()) {
    loadListings();
  }

  Future<void> loadListings({bool refresh = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      Query q = _db.collection('listings').where('status', isEqualTo: 'active');

      final filters = state.filters;

      // Category filter
      if (filters['category_id'] != null) {
        q = q.where('category_id',
            isEqualTo: filters['category_id'].toString());
      }

      // City filter
      if (filters['city'] != null && (filters['city'] as String).isNotEmpty) {
        q = q.where('city', isEqualTo: filters['city']);
      }

      // Price filters
      if (filters['min_price'] != null) {
        q = q.where('price_per_day',
            isGreaterThanOrEqualTo:
                double.tryParse(filters['min_price'].toString()) ?? 0);
      }
      if (filters['max_price'] != null) {
        q = q.where('price_per_day',
            isLessThanOrEqualTo:
                double.tryParse(filters['max_price'].toString()) ??
                    double.infinity);
      }

      final snap = await q.limit(50).get().timeout(const Duration(seconds: 10));

      var results = snap.docs.map((doc) {
        return ListingModel.fromJson(
            {'id': doc.id, ...doc.data() as Map<String, dynamic>});
      }).toList();

      // Client-side search
      final search = filters['search']?.toString().toLowerCase() ?? '';
      if (search.isNotEmpty) {
        results = results
            .where((l) =>
                l.title.toLowerCase().contains(search) ||
                l.city.toLowerCase().contains(search) ||
                (l.category?.name.toLowerCase().contains(search) ?? false))
            .toList();
      }

      // Client-side sort
      final sort = filters['sort'] ?? 'latest';
      switch (sort) {
        case 'price_asc':
          results.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
          break;
        case 'price_desc':
          results.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
          break;
        case 'rating':
          results
              .sort((a, b) => (b.avgRating ?? 0).compareTo(a.avgRating ?? 0));
          break;
        default:
          // latest — Firestore returns in insertion order by default
          break;
      }

      state = state.copyWith(
        isLoading: false,
        listings: results,
        hasMore: false,
      );
    } catch (e) {
      debugPrint('BrowseNotifier error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
  static final _db = FirebaseFirestore.instance;

  ListingDetailNotifier(this.listingId) : super(const ListingDetailState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // listingId is a hash of the Firestore string ID
      // We need to find the doc by querying or by direct ID
      // Since we store firestoreId in the model, try to find by hash match
      final snap = await _db
          .collection('listings')
          .where('status', isEqualTo: 'active')
          .limit(100)
          .get()
          .timeout(const Duration(seconds: 10));

      ListingModel? listing;
      for (final doc in snap.docs) {
        final candidate = ListingModel.fromJson({'id': doc.id, ...doc.data()});
        if (candidate.id == listingId) {
          listing = candidate;
          break;
        }
      }

      // Fetch reviews
      List<ReviewModel> reviews = [];
      if (listing?.firestoreId != null) {
        try {
          final reviewSnap = await _db
              .collection('reviews')
              .where('listing_id', isEqualTo: listing!.firestoreId)
              .get()
              .timeout(const Duration(seconds: 5));
          reviews = reviewSnap.docs.map((d) {
            return ReviewModel.fromJson({'id': d.id, ...d.data()});
          }).toList();
        } catch (_) {}
      }

      // Fetch unavailable dates (existing bookings)
      List<String> unavailableDates = [];
      if (listing?.firestoreId != null) {
        try {
          final bookingSnap = await _db
              .collection('bookings')
              .where('listing_id', isEqualTo: listing!.firestoreId)
              .where('status', whereIn: ['approved', 'paid', 'active'])
              .get()
              .timeout(const Duration(seconds: 5));

          for (final doc in bookingSnap.docs) {
            final data = doc.data();
            final start = DateTime.parse(data['start_date']);
            final end = DateTime.parse(data['end_date']);

            // Fill all dates between start and end
            for (var d = start;
                d.isBefore(end) || d.isAtSameMomentAs(end);
                d = d.add(const Duration(days: 1))) {
              unavailableDates.add(
                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
            }
          }
        } catch (_) {}
      }

      state = state.copyWith(
        isLoading: false,
        listing: listing,
        reviews: reviews,
        unavailableDates: unavailableDates,
      );
    } catch (e) {
      debugPrint('ListingDetailNotifier error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final listingDetailProvider = StateNotifierProvider.family<
    ListingDetailNotifier, ListingDetailState, int>((ref, id) {
  return ListingDetailNotifier(id);
});
