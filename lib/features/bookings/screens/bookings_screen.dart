import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/booking_model.dart';
import '../providers/bookings_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BOOKINGS SCREEN — Two tabs for everyone
// Tab 1: My Bookings (as renter)
// Tab 2: Booking Requests (as host of their listings)
// ─────────────────────────────────────────────────────────────────────────────
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bookings',
              style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () => ref.read(bookingsProvider.notifier).load(),
              tooltip: 'Refresh',
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.neonCyan,
            labelColor: AppColors.neonCyan,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('My Bookings'),
                    if (state.renterBookings.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${state.renterBookings.length}',
                          style: const TextStyle(
                              color: AppColors.background,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Requests'),
                    if (state.hostRequests
                        .where((b) => b.status == 'pending')
                        .isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${state.hostRequests.where((b) => b.status == 'pending').length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.read(bookingsProvider.notifier).load(),
          color: AppColors.neonCyan,
          backgroundColor: AppColors.surface,
          child: state.isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.neonCyan))
              : TabBarView(
                  children: [
                    _BookingList(
                        bookings: state.renterBookings, isHost: false),
                    _BookingList(
                        bookings: state.hostRequests, isHost: true),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Booking list ──────────────────────────────────────────────────────────────
class _BookingList extends ConsumerWidget {
  final List<BookingModel> bookings;
  final bool isHost;

  const _BookingList({required this.bookings, required this.isHost});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              isHost ? 'No booking requests yet' : 'No bookings yet',
              style: GoogleFonts.syne(
                  color: AppColors.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              isHost
                  ? 'When renters book your listings, requests appear here'
                  : 'Browse listings and make your first booking',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (!isHost) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.push('/browse'),
                child: const Text('Browse Listings'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _BookingCard(
          booking: bookings[index],
          isHost: isHost,
        );
      },
    );
  }
}

// ── Booking card ──────────────────────────────────────────────────────────────
class _BookingCard extends ConsumerWidget {
  final BookingModel booking;
  final bool isHost;

  const _BookingCard({required this.booking, required this.isHost});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = bookingStatusColor(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tappable header ────────────────────────────────────────
          InkWell(
            onTap: () => context.push(
                '/booking/${booking.id}?host=${isHost ? '1' : '0'}'),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.listing?.title ??
                              'Listing #${booking.listingId}',
                          style: GoogleFonts.syne(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          bookingStatusLabel(booking.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.textMuted, size: 13),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${formatDate(booking.startDate)} → ${formatDate(booking.endDate)}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.payments_outlined,
                        color: AppColors.textMuted, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      '${formatPrice(booking.totalPrice)} • ${booking.totalDays} day${booking.totalDays > 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ]),
                  if (isHost && booking.renter != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.person_outlined,
                          color: AppColors.textMuted, size: 13),
                      const SizedBox(width: 5),
                      Text('Renter: ${booking.renter!.name}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ]),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('View details',
                          style: TextStyle(
                              color: AppColors.neonCyan, fontSize: 11)),
                      const Icon(Icons.chevron_right,
                          color: AppColors.neonCyan, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Action buttons ─────────────────────────────────────────
          if (_hasActions())
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: _buildActions(context, ref),
            ),
        ],
      ),
    );
  }

  bool _hasActions() {
    if (isHost && booking.status == 'pending') return true;
    if (!isHost && booking.status == 'approved') return true;
    return false;
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    // HOST: Approve / Reject
    if (isHost && booking.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final ok = await ref
                    .read(bookingsProvider.notifier)
                    .reject(booking.id);
                if (ok && context.mounted) {
                  showSnackBar(context, 'Booking rejected');
                }
              },
              icon: const Icon(Icons.close, size: 15),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () async {
                final ok = await ref
                    .read(bookingsProvider.notifier)
                    .approve(booking.id);
                if (ok && context.mounted) {
                  showSnackBar(context, 'Booking approved! ✅');
                }
              },
              icon: const Icon(Icons.check, size: 15),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      );
    }

    // RENTER: Pay Now
    if (!isHost && booking.status == 'approved') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => context.push(
            '/payment/${booking.id}?amount=${booking.totalPrice}',
          ),
          icon: const Icon(Icons.payment, size: 15),
          label: const Text('Pay Now'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

    return const SizedBox();
  }
}

void showSnackBar(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: isError ? AppColors.error : AppColors.neonGreen,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}
