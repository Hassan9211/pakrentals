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

  BookingsNotifier() : super(const BookingsState()) {
    load();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Load bookings from Firestore ───────────────────────────────────────────
  Future<void> load() async {
    final uid = _uid;
    if (uid.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    debugPrint('BookingsNotifier.load() uid=$uid');

    try {
      // Fetch all bookings and filter client-side
      // This avoids index issues and ensures host sees their bookings
      final allSnap = await _db
          .collection('bookings')
          .get()
          .timeout(const Duration(seconds: 10));

      debugPrint('Total bookings in Firestore: ${allSnap.docs.length}');

      // Split into renter and host lists
      final renterDocs = <DocumentSnapshot>[];
      final hostDocs = <DocumentSnapshot>[];

      for (final doc in allSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final renterId = data['renter_id']?.toString() ?? '';
        final hostId = data['host_id']?.toString() ?? '';

        debugPrint('  Booking ${doc.id}: renter=$renterId host=$hostId status=${data['status']}');

        if (renterId == uid) renterDocs.add(doc);
        if (hostId == uid) hostDocs.add(doc);
      }

      debugPrint('Renter bookings: ${renterDocs.length}, Host requests: ${hostDocs.length}');

      final renterBookings =
          await Future.wait(renterDocs.map((d) => _docToBooking(d)));
      final hostRequests =
          await Future.wait(hostDocs.map((d) => _docToBooking(d)));

      final renterList = renterBookings.whereType<BookingModel>().toList()
        ..sort((a, b) =>
            (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      final hostList = hostRequests.whereType<BookingModel>().toList()
        ..sort((a, b) =>
            (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

      state = state.copyWith(
        isLoading: false,
        renterBookings: renterList,
        hostRequests: hostList,
      );
    } catch (e) {
      debugPrint('BookingsNotifier.load error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Convert Firestore doc → BookingModel ───────────────────────────────────
  Future<BookingModel?> _docToBooking(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;

      ListingModel? listing;
      final listingId = data['listing_id']?.toString();
      if (listingId != null && listingId.isNotEmpty) {
        try {
          final ld = await _db
              .collection('listings')
              .doc(listingId)
              .get()
              .timeout(const Duration(seconds: 5));
          if (ld.exists) {
            listing = ListingModel.fromJson(
                {'id': ld.id, ...ld.data()!});
          }
        } catch (_) {}
      }

      UserModel? renter;
      final renterId = data['renter_id']?.toString();
      if (renterId != null && renterId.isNotEmpty) {
        try {
          final rd = await _db
              .collection('users')
              .doc(renterId)
              .get()
              .timeout(const Duration(seconds: 5));
          if (rd.exists) {
            renter = UserModel.fromJson({'id': rd.id, ...rd.data()!});
          }
        } catch (_) {}
      }

      final ts = data['created_at'];
      String? createdAtStr;
      if (ts is Timestamp) {
        createdAtStr = ts.toDate().toIso8601String();
      }

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
        createdAt: createdAtStr,
      );
    } catch (e) {
      debugPrint('_docToBooking error: $e');
      return null;
    }
  }

  // ── Create booking ─────────────────────────────────────────────────────────
  Future<bool> createBooking(Map<String, dynamic> data) async {
    final renterUid = _uid;
    if (renterUid.isEmpty) {
      debugPrint('createBooking: no Firebase Auth UID');
      return false;
    }

    try {
      final listingId = data['listing_id'].toString();
      debugPrint('createBooking: listingId=$listingId renterUid=$renterUid');

      final listingDoc = await _db
          .collection('listings')
          .doc(listingId)
          .get()
          .timeout(const Duration(seconds: 8));

      if (!listingDoc.exists) {
        debugPrint('createBooking: listing not found: $listingId');
        return false;
      }

      final listingData = listingDoc.data()!;
      final hostId = listingData['host_id']?.toString() ?? '';
      debugPrint('createBooking: hostId=$hostId');

      final bookingRef = await _db.collection('bookings').add({
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

      debugPrint('Booking created: ${bookingRef.id}');

      // Notify host
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

      await load();
      return true;
    } catch (e) {
      debugPrint('createBooking error: $e');
      return false;
    }
  }

  // ── Approve / Reject / Pay / Complete ─────────────────────────────────────
  Future<bool> approve(int id) => _updateStatus(id, 'approved');
  Future<bool> reject(int id) => _updateStatus(id, 'rejected');
  Future<bool> complete(int id) => _updateStatus(id, 'completed');

  Future<bool> pay(int id, String method) async {
    final booking = _find(id);
    if (booking?.firestoreId == null) return false;
    try {
      await _db.collection('bookings').doc(booking!.firestoreId!).update({
        'status': 'paid',
        'payment_method': method,
        'payment_status': 'paid',
        'updated_at': FieldValue.serverTimestamp(),
      });
      await load();
      return true;
    } catch (e) {
      debugPrint('pay error: $e');
      return false;
    }
  }

  BookingModel? _find(int id) {
    final all = [...state.renterBookings, ...state.hostRequests];
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _updateStatus(int id, String status) async {
    final booking = _find(id);
    if (booking?.firestoreId == null) {
      debugPrint('_updateStatus: booking not found id=$id');
      return false;
    }
    try {
      await _db
          .collection('bookings')
          .doc(booking!.firestoreId!)
          .update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Notify renter
      final renterId = (await _db
              .collection('bookings')
              .doc(booking.firestoreId!)
              .get())
          .data()?['renter_id']
          ?.toString();
      if (renterId != null && renterId.isNotEmpty) {
        unawaited(_db.collection('notifications').add({
          'user_id': renterId,
          'type': status == 'approved'
              ? 'booking_approved'
              : 'booking_rejected',
          'title': status == 'approved'
              ? 'Booking Approved!'
              : 'Booking Rejected',
          'body': status == 'approved'
              ? 'Your booking was approved. Please complete payment.'
              : 'Your booking request was declined.',
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
        }));
      }

      await load();
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
