import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../listings/models/listing_model.dart';
import '../../auth/models/user_model.dart';
import '../models/booking_model.dart';

class BookingsState {
  final List<BookingModel> renterBookings;
  final List<BookingModel> hostRequests;
  final bool isLoading;
  final String? error;

  const BookingsState({
    this.renterBookings = const [],
    this.hostRequests = const [],
    this.isLoading = false,
    this.error,
  });

  BookingsState copyWith({
    List<BookingModel>? renterBookings,
    List<BookingModel>? hostRequests,
    bool? isLoading,
    String? error,
  }) {
    return BookingsState(
      renterBookings: renterBookings ?? this.renterBookings,
      hostRequests: hostRequests ?? this.hostRequests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BookingsNotifier extends StateNotifier<BookingsState> {
  static final _db = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot>? _bookingsSub;

  BookingsNotifier() : super(const BookingsState()) {
    _init();
  }

  void _init() {
    // Listen to auth changes
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint('Auth changed: uid=${user.uid}');
        _startListening(user.uid);
      } else {
        _bookingsSub?.cancel();
        state = const BookingsState();
      }
    });
  }

  void _startListening(String uid) {
    _bookingsSub?.cancel();
    state = state.copyWith(isLoading: true);

    // Check if this is admin
    const adminUid = 't41DI9ZHowUAsk9pgyFd7iJrTsA3';
    final isAdmin = uid == adminUid;

    _bookingsSub = _db
        .collection('bookings')
        .snapshots()
        .listen((snap) async {
      debugPrint('Bookings snapshot: ${snap.docs.length} total, uid=$uid isAdmin=$isAdmin');

      final renterDocs = <DocumentSnapshot>[];
      final hostDocs = <DocumentSnapshot>[];

      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final renterId = data['renter_id']?.toString() ?? '';
        final hostId = data['host_id']?.toString() ?? '';
        debugPrint('  doc=${doc.id} renter=$renterId host=$hostId status=${data['status']}');

        // Renter sees their own bookings
        if (renterId == uid) renterDocs.add(doc);

        // Host sees bookings on their listings
        // Admin sees ALL bookings as host requests
        if (isAdmin || hostId == uid) hostDocs.add(doc);
      }

      debugPrint('Matched: renter=${renterDocs.length} host=${hostDocs.length}');

      final renterList = await _convertDocs(renterDocs);
      final hostList = await _convertDocs(hostDocs);

      renterList.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      hostList.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          renterBookings: renterList,
          hostRequests: hostList,
        );
      }
    }, onError: (e) {
      debugPrint('Bookings stream error: $e');
      if (mounted) state = state.copyWith(isLoading: false, error: e.toString());
    });
  }

  Future<List<BookingModel>> _convertDocs(List<DocumentSnapshot> docs) async {
    final results = await Future.wait(docs.map((d) => _docToBooking(d)));
    return results.whereType<BookingModel>().toList();
  }

  Future<void> load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _startListening(uid);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _bookingsSub?.cancel();
    super.dispose();
  }

  // ── Convert Firestore doc → BookingModel ───────────────────────────────────
  Future<BookingModel?> _docToBooking(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;

      ListingModel? listing;
      final listingId = data['listing_id']?.toString();
      if (listingId != null && listingId.isNotEmpty) {
        try {
          final ld = await _db.collection('listings').doc(listingId)
              .get().timeout(const Duration(seconds: 5));
          if (ld.exists) {
            listing = ListingModel.fromJson({'id': ld.id, ...ld.data()!});
          }
        } catch (_) {}
      }

      UserModel? renter;
      final renterId = data['renter_id']?.toString();
      if (renterId != null && renterId.isNotEmpty) {
        try {
          final rd = await _db.collection('users').doc(renterId)
              .get().timeout(const Duration(seconds: 5));
          if (rd.exists) {
            renter = UserModel.fromJson({'id': rd.id, ...rd.data()!});
          }
        } catch (_) {}
      }

      final ts = data['created_at'];
      final createdAt = ts is Timestamp ? ts.toDate().toIso8601String() : null;

      return BookingModel(
        id: doc.id.hashCode,
        firestoreId: doc.id,
        listingId: listing?.id ?? 0,
        renterId: 0,
        hostId: 0,
        startDate: data['start_date'] ?? '',
        endDate: data['end_date'] ?? '',
        totalDays: (data['total_days'] as num?)?.toInt() ?? 0,
        totalPrice: (data['total_price'] as num?)?.toDouble() ?? 0,
        status: data['status'] ?? 'pending',
        paymentMethod: data['payment_method'],
        paymentStatus: data['payment_status'],
        notes: data['notes'],
        listing: listing,
        renter: renter,
        createdAt: createdAt,
      );
    } catch (e) {
      debugPrint('_docToBooking error: $e');
      return null;
    }
  }

  // ── Create booking ─────────────────────────────────────────────────────────
  Future<bool> createBooking(Map<String, dynamic> data) async {
    final renterUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (renterUid.isEmpty) return false;

    try {
      final listingId = data['listing_id'].toString();
      final listingDoc = await _db.collection('listings').doc(listingId)
          .get().timeout(const Duration(seconds: 8));

      if (!listingDoc.exists) {
        debugPrint('Listing not found: $listingId');
        return false;
      }

      final listingData = listingDoc.data()!;
      final hostId = listingData['host_id']?.toString() ?? '';

      if (hostId == renterUid) {
        debugPrint('Cannot book own listing');
        return false;
      }

      await _db.collection('bookings').add({
        'listing_id': listingId,
        'renter_id': renterUid,
        'host_id': hostId,
        'start_date': data['start_date'],
        'end_date': data['end_date'],
        'total_days': data['total_days'],
        'total_price': data['total_price'],
        'status': 'pending',
        'notes': data['notes'] ?? '',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (hostId.isNotEmpty) {
        unawaited(_db.collection('notifications').add({
          'user_id': hostId,
          'type': 'booking_request',
          'title': 'New Booking Request',
          'body': 'Someone requested to book "${listingData['title']}"',
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        }));
      }

      return true; // stream will auto-update UI
    } catch (e) {
      debugPrint('createBooking error: $e');
      return false;
    }
  }

  // ── Status updates ─────────────────────────────────────────────────────────
  Future<bool> approve(int id) => _updateStatus(id, 'approved');
  Future<bool> reject(int id) => _updateStatus(id, 'rejected');
  Future<bool> complete(int id) => _updateStatus(id, 'completed');

  Future<bool> pay(int id, String method) async {
    final b = _find(id);
    if (b?.firestoreId == null) return false;
    try {
      await _db.collection('bookings').doc(b!.firestoreId!).update({
        'status': 'paid',
        'payment_method': method,
        'payment_status': 'paid',
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('pay error: $e');
      return false;
    }
  }

  BookingModel? _find(int id) {
    final all = [...state.renterBookings, ...state.hostRequests];
    try { return all.firstWhere((b) => b.id == id); } catch (_) { return null; }
  }

  Future<bool> _updateStatus(int id, String status) async {
    final b = _find(id);
    if (b?.firestoreId == null) return false;
    try {
      await _db.collection('bookings').doc(b!.firestoreId!).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });

      final renterId = (await _db.collection('bookings').doc(b.firestoreId!).get())
          .data()?['renter_id']?.toString();
      if (renterId != null && renterId.isNotEmpty) {
        unawaited(_db.collection('notifications').add({
          'user_id': renterId,
          'type': status == 'approved' ? 'booking_approved' : 'booking_rejected',
          'title': status == 'approved' ? 'Booking Approved!' : 'Booking Rejected',
          'body': status == 'approved'
              ? 'Your booking was approved. Please complete payment.'
              : 'Your booking request was declined.',
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        }));
      }
      return true;
    } catch (e) {
      debugPrint('_updateStatus error: $e');
      return false;
    }
  }
}

final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, BookingsState>((ref) {
  return BookingsNotifier();
});
