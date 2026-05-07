import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── Collections ────────────────────────────────────────────────────────────
  static CollectionReference get users => _db.collection('users');
  static CollectionReference get listings => _db.collection('listings');
  static CollectionReference get bookings => _db.collection('bookings');
  static CollectionReference get conversations =>
      _db.collection('conversations');
  static CollectionReference get notifications =>
      _db.collection('notifications');
  static CollectionReference get reviews => _db.collection('reviews');
  static CollectionReference get reports => _db.collection('reports');
  static CollectionReference get categories => _db.collection('categories');

  // ── LISTINGS ───────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getListings({
    String? categoryId,
    String? city,
    String? search,
    double? minPrice,
    double? maxPrice,
    String sort = 'latest',
    int limit = 20,
  }) async {
    Query q = listings.where('status', isEqualTo: 'active');

    if (categoryId != null) {
      q = q.where('category_id', isEqualTo: categoryId);
    }
    if (city != null && city.isNotEmpty) {
      q = q.where('city', isEqualTo: city);
    }
    if (minPrice != null) {
      q = q.where('price_per_day', isGreaterThanOrEqualTo: minPrice);
    }
    if (maxPrice != null) {
      q = q.where('price_per_day', isLessThanOrEqualTo: maxPrice);
    }

    switch (sort) {
      case 'price_asc':
        q = q.orderBy('price_per_day');
        break;
      case 'price_desc':
        q = q.orderBy('price_per_day', descending: true);
        break;
      case 'rating':
        q = q.orderBy('avg_rating', descending: true);
        break;
      default:
        q = q.orderBy('created_at', descending: true);
    }

    final snap = await q.limit(limit).get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getFeaturedListings() async {
    final snap = await listings
        .where('is_featured', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .limit(10)
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  static Future<Map<String, dynamic>?> getListing(String id) async {
    final doc = await listings.doc(id).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
  }

  static Future<String> createListing(Map<String, dynamic> data) async {
    final ref = await listings.add({
      ...data,
      'status': 'active',
      'created_at': FieldValue.serverTimestamp(),
      'avg_rating': 0.0,
      'reviews_count': 0,
    });
    return ref.id;
  }

  static Future<void> updateListing(
      String id, Map<String, dynamic> data) async {
    await listings.doc(id).update(data);
  }

  static Future<void> deleteListing(String id) async {
    await listings.doc(id).delete();
  }

  static Future<List<Map<String, dynamic>>> getUserListings(
      String userId) async {
    final snap = await listings
        .where('host_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  // ── CATEGORIES ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCategories() async {
    final snap =
        await categories.orderBy('name').get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  // ── BOOKINGS ───────────────────────────────────────────────────────────────

  static Future<String> createBooking(Map<String, dynamic> data) async {
    final ref = await bookings.add({
      ...data,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<List<Map<String, dynamic>>> getRenterBookings(
      String userId) async {
    final snap = await bookings
        .where('renter_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getHostRequests(
      String userId) async {
    final snap = await bookings
        .where('host_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  static Future<void> updateBookingStatus(
      String id, String status, {Map<String, dynamic>? extra}) async {
    await bookings.doc(id).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
      if (extra != null) ...extra,
    });
  }

  // ── REVIEWS ────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getListingReviews(
      String listingId) async {
    final snap = await reviews
        .where('listing_id', isEqualTo: listingId)
        .orderBy('created_at', descending: true)
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  static Future<void> addReview(Map<String, dynamic> data) async {
    await reviews.add({
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
    // Update listing avg_rating
    final allReviews = await getListingReviews(data['listing_id']);
    if (allReviews.isNotEmpty) {
      final avg = allReviews
              .map((r) => (r['rating'] as num).toDouble())
              .reduce((a, b) => a + b) /
          allReviews.length;
      await listings.doc(data['listing_id']).update({
        'avg_rating': avg,
        'reviews_count': allReviews.length,
      });
    }
  }

  // ── MESSAGES ───────────────────────────────────────────────────────────────

  static String conversationId(
      String listingId, String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '${listingId}_${sorted.join('_')}';
  }

  static Future<List<Map<String, dynamic>>> getConversations(
      String userId) async {
    final snap = await conversations
        .where('participants', arrayContains: userId)
        .orderBy('updated_at', descending: true)
        .get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  static Stream<List<Map<String, dynamic>>> messagesStream(
      String convId) {
    return conversations
        .doc(convId)
        .collection('messages')
        .orderBy('created_at')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
            .toList());
  }

  static Future<void> sendMessage({
    required String listingId,
    required String senderId,
    required String receiverId,
    required String body,
    required String listingTitle,
  }) async {
    final convId = conversationId(listingId, senderId, receiverId);
    final convRef = conversations.doc(convId);

    // Create/update conversation
    await convRef.set({
      'listing_id': listingId,
      'listing_title': listingTitle,
      'participants': [senderId, receiverId],
      'last_message': body,
      'last_sender_id': senderId,
      'updated_at': FieldValue.serverTimestamp(),
      'unread_count_$receiverId': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // Add message
    await convRef.collection('messages').add({
      'sender_id': senderId,
      'body': body,
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> markMessagesRead(
      String convId, String userId) async {
    await conversations.doc(convId).update({
      'unread_count_$userId': 0,
    });
  }

  // ── NOTIFICATIONS ──────────────────────────────────────────────────────────

  static Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await notifications.add({
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data ?? {},
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> notificationsStream(
      String userId) {
    return notifications
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                {'id': d.id, ...d.data() as Map<String, dynamic>})
            .toList());
  }

  static Future<void> markNotificationRead(String id) async {
    await notifications.doc(id).update({'is_read': true});
  }

  // ── WISHLIST ───────────────────────────────────────────────────────────────

  static Future<List<String>> getWishlist(String userId) async {
    final doc = await users.doc(userId).get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>;
    return List<String>.from(data['wishlist'] ?? []);
  }

  static Future<void> toggleWishlist(
      String userId, String listingId) async {
    final doc = await users.doc(userId).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final wishlist = List<String>.from(data['wishlist'] ?? []);

    if (wishlist.contains(listingId)) {
      wishlist.remove(listingId);
    } else {
      wishlist.add(listingId);
    }

    await users.doc(userId).update({'wishlist': wishlist});
  }

  // ── REPORTS ────────────────────────────────────────────────────────────────

  static Future<void> createReport(Map<String, dynamic> data) async {
    await reports.add({
      ...data,
      'status': 'open',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ── ADMIN ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getAdminStats() async {
    final results = await Future.wait([
      users.count().get(),
      listings.count().get(),
      bookings.count().get(),
    ]);

    return {
      'total_users': results[0].count ?? 0,
      'total_listings': results[1].count ?? 0,
      'total_bookings': results[2].count ?? 0,
    };
  }
}
