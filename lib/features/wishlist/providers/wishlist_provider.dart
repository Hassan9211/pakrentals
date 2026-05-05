import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/mock/mock_data.dart';
import '../../listings/models/listing_model.dart';

class WishlistState {
  final List<ListingModel> listings;
  final Set<int> savedIds; // exposed so ListingCard can watch it
  final bool isLoading;

  const WishlistState({
    this.listings = const [],
    this.savedIds = const {},
    this.isLoading = false,
  });

  WishlistState copyWith({
    List<ListingModel>? listings,
    Set<int>? savedIds,
    bool? isLoading,
  }) {
    return WishlistState(
      listings: listings ?? this.listings,
      savedIds: savedIds ?? this.savedIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WishlistNotifier extends StateNotifier<WishlistState> {
  static const _prefsKey = 'wishlist_ids';

  WishlistNotifier() : super(const WishlistState()) {
    _load();
  }

  // ── Load saved IDs from SharedPreferences ─────────────────────────────────
  Future<void> _load() async {
    state = state.copyWith(isLoading: true);

    // Restore persisted IDs
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey);
    final Set<int> ids = {};

    if (stored != null) {
      ids.addAll(stored.map((s) => int.tryParse(s) ?? -1).where((i) => i > 0));
    } else {
      // First run — seed from mock data
      for (final l in mockListings) {
        if (l.isSaved == true) ids.add(l.id);
      }
      await _persist(ids);
    }

    final saved = mockListings.where((l) => ids.contains(l.id)).toList();
    state = state.copyWith(isLoading: false, savedIds: ids, listings: saved);
  }

  // ── Persist IDs to SharedPreferences ──────────────────────────────────────
  Future<void> _persist(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, ids.map((i) => i.toString()).toList());
  }

  // ── Toggle a listing ───────────────────────────────────────────────────────
  Future<void> toggle(int listingId) async {
    final ids = Set<int>.from(state.savedIds);

    if (ids.contains(listingId)) {
      ids.remove(listingId);
    } else {
      ids.add(listingId);
    }

    // Update state immediately so UI reacts instantly
    final saved = mockListings.where((l) => ids.contains(l.id)).toList();
    state = state.copyWith(savedIds: ids, listings: saved);

    // Persist in background
    await _persist(ids);
  }

  // ── Public reload ──────────────────────────────────────────────────────────
  Future<void> load() => _load();

  bool isSaved(int listingId) => state.savedIds.contains(listingId);
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  return WishlistNotifier();
});
