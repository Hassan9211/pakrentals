import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../listings/models/listing_model.dart';

class WishlistState {
  final List<ListingModel> listings;
  final Set<String> savedIds;  // Firestore string IDs
  final bool isLoading;

  const WishlistState({
    this.listings = const [],
    this.savedIds = const {},
    this.isLoading = false,
  });

  WishlistState copyWith({
    List<ListingModel>? listings,
    Set<String>? savedIds,
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
  static final _db = FirebaseFirestore.instance;

  WishlistNotifier() : super(const WishlistState()) {
    _load();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _load() async {
    if (_uid.isEmpty) return;
    state = state.copyWith(isLoading: true);

    try {
      final doc = await _db
          .collection('users')
          .doc(_uid)
          .get()
          .timeout(const Duration(seconds: 8));

      final data = doc.data() ?? {};
      final ids = Set<String>.from(
          (data['wishlist'] as List<dynamic>? ?? []).map((e) => e.toString()));

      // Fetch listing details for each saved ID
      final listings = <ListingModel>[];
      for (final id in ids) {
        try {
          final ld = await _db
              .collection('listings')
              .doc(id)
              .get()
              .timeout(const Duration(seconds: 5));
          if (ld.exists) {
            listings.add(ListingModel.fromJson(
                {'id': ld.id, ...ld.data()!}));
          }
        } catch (_) {}
      }

      state = state.copyWith(
          isLoading: false, savedIds: ids, listings: listings);
    } catch (e) {
      debugPrint('WishlistNotifier error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> load() => _load();

  Future<void> toggle(int listingIntId) async {
    if (_uid.isEmpty) return;

    // Find the firestoreId from current listings or by int id hash
    String? firestoreId;
    for (final l in state.listings) {
      if (l.id == listingIntId) {
        firestoreId = l.firestoreId;
        break;
      }
    }

    // If not in wishlist listings, search browse listings
    firestoreId ??= _findFirestoreId(listingIntId);
    if (firestoreId == null) return;

    final ids = Set<String>.from(state.savedIds);
    if (ids.contains(firestoreId)) {
      ids.remove(firestoreId);
    } else {
      ids.add(firestoreId);
    }

    // Optimistic update
    state = state.copyWith(savedIds: ids);

    // Persist to Firestore
    try {
      await _db.collection('users').doc(_uid).update({
        'wishlist': ids.toList(),
      });
    } catch (e) {
      debugPrint('Wishlist toggle error: $e');
    }

    await _load();
  }

  // Check if a listing (by int id) is saved
  bool isSaved(int listingIntId) {
    // Check by matching int id to firestoreId hash
    for (final l in state.listings) {
      if (l.id == listingIntId) {
        return state.savedIds.contains(l.firestoreId);
      }
    }
    final fid = _findFirestoreId(listingIntId);
    return fid != null && state.savedIds.contains(fid);
  }

  String? _findFirestoreId(int intId) {
    // The int id is a hash of the firestoreId string
    for (final id in state.savedIds) {
      if (id.hashCode.abs() == intId) return id;
    }
    return null;
  }
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  return WishlistNotifier();
});
