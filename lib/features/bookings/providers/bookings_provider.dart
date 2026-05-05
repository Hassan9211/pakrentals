import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/mock/mock_data.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/booking_model.dart';

class BookingsState {
  final List<BookingModel> renterBookings; // bookings where I am the renter
  final List<BookingModel> hostRequests;   // bookings on my listings (I am host)
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
  final Ref _ref;

  // Single source of truth — all bookings in the system
  // In real app this comes from the API
  final List<BookingModel> _all = [
    ...mockBookings,
    ...mockHostRequests,
  ];

  BookingsNotifier(this._ref) : super(const BookingsState()) {
    load();
  }

  // ── Get current user id ────────────────────────────────────────────────────
  int get _currentUserId => _ref.read(authProvider).user?.id ?? 0;

  // ── Reload state from _all list ────────────────────────────────────────────
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 300));

    final userId = _currentUserId;
    final user = _ref.read(authProvider).user;
    final isHost = user?.isHost ?? false;

    // Renter bookings = bookings where I am the renter
    final renter = _all
        .where((b) => b.renterId == userId)
        .toList()
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

    List<BookingModel> host = [];
    if (isHost) {
      // Match by explicit hostId first
      host = _all.where((b) => b.hostId == userId).toList();

      // If no matches (mock data has old IDs), show ALL pending bookings
      // that don't belong to the current user as renter
      // This ensures host always sees requests in mock/test mode
      if (host.isEmpty) {
        host = _all
            .where((b) =>
                b.renterId != userId && // not my own booking
                b.status == 'pending')  // only pending requests
            .toList();
      }

      host.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    }

    state = state.copyWith(
      isLoading: false,
      renterBookings: renter,
      hostRequests: host,
    );
  }

  // ── Create booking (renter action) ────────────────────────────────────────
  Future<bool> createBooking(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final listingId = data['listing_id'] as int;
    final listing = mockListings.firstWhere(
      (l) => l.id == listingId,
      orElse: () => mockListings.first,
    );

    final startDate = data['start_date'] as String;
    final endDate = data['end_date'] as String;
    final days =
        DateTime.parse(endDate).difference(DateTime.parse(startDate)).inDays +
            1;

    final currentUser = _ref.read(authProvider).user;

    // hostId comes from the listing's host — this is who needs to approve
    final hostId = listing.host?.id ?? 0;

    final newBooking = BookingModel(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      listingId: listingId,
      renterId: currentUser?.id ?? 1,
      hostId: hostId,
      startDate: startDate,
      endDate: endDate,
      totalDays: days,
      totalPrice: listing.pricePerDay * days,
      status: 'pending',
      notes: data['notes']?.toString().isNotEmpty == true
          ? data['notes'].toString()
          : null,
      listing: listing,
      renter: currentUser,
      createdAt: DateTime.now().toIso8601String(),
    );

    _all.insert(0, newBooking);
    await load();
    return true;
  }

  // ── Approve (host action) ─────────────────────────────────────────────────
  Future<bool> approve(int id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _updateStatus(id, 'approved');
    await load();
    return true;
  }

  // ── Reject (host action) ──────────────────────────────────────────────────
  Future<bool> reject(int id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _updateStatus(id, 'rejected');
    await load();
    return true;
  }

  // ── Pay (renter action) ───────────────────────────────────────────────────
  Future<bool> pay(int id, String method) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _all.indexWhere((b) => b.id == id);
    if (idx != -1) {
      final b = _all[idx];
      _all[idx] = BookingModel(
        id: b.id,
        listingId: b.listingId,
        renterId: b.renterId,
        hostId: b.hostId,
        startDate: b.startDate,
        endDate: b.endDate,
        totalDays: b.totalDays,
        totalPrice: b.totalPrice,
        status: 'paid',
        paymentMethod: method,
        paymentStatus: 'paid',
        notes: b.notes,
        listing: b.listing,
        renter: b.renter,
        createdAt: b.createdAt,
      );
    }
    await load();
    return true;
  }

  // ── Complete (renter action) ──────────────────────────────────────────────
  Future<bool> complete(int id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _updateStatus(id, 'completed');
    await load();
    return true;
  }

  // ── Helper: update status in _all list ────────────────────────────────────
  void _updateStatus(int id, String newStatus) {
    final idx = _all.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    final b = _all[idx];
    _all[idx] = BookingModel(
      id: b.id,
      listingId: b.listingId,
      renterId: b.renterId,
      hostId: b.hostId,
      startDate: b.startDate,
      endDate: b.endDate,
      totalDays: b.totalDays,
      totalPrice: b.totalPrice,
      status: newStatus,
      paymentMethod: b.paymentMethod,
      paymentStatus: b.paymentStatus,
      notes: b.notes,
      listing: b.listing,
      renter: b.renter,
      createdAt: b.createdAt,
    );
  }
}

final bookingsProvider =
    StateNotifierProvider<BookingsNotifier, BookingsState>((ref) {
  return BookingsNotifier(ref);
});
