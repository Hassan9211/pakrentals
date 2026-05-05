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
// BOOKINGS SCREEN
//
// RENTER  → sees only their own bookings (items they booked)
//           Pay Now appears when status == 'approved'
//
// HOST    → sees only requests on their listings
//           Approve / Reject appears when status == 'pending'
//           NO Pay Now — host never pays, renter does
// ─────────────────────────────────────────────────────────────────────────────
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingsProvider);
    final user = ref.watch(authProvider).user;
    final isHost = user?.isHost ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isHost ? 'Booking Requests' : 'My Bookings',
          style: GoogleFonts.syne(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(bookingsProvider.notifier).load(),
        color: AppColors.neonCyan,
        backgroundColor: AppColors.surface,
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.neonCyan))
            : isHost
                // HOST — only sees requests on their listings
                ? _BookingList(
                    bookings: state.hostRequests,
                    isHost: true,
                  )
                // RENTER — only sees their own bookings
                : _BookingList(
                    bookings: state.renterBookings,
                    isHost: false,
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
                  ? 'When renters book your listings, requests will appear here'
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
          // ── Header (tappable → detail screen) ─────────────────────
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
                  // Title + status badge
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

                  // Dates
                  Row(
                    children: [
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
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Price
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined,
                          color: AppColors.textMuted, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        '${formatPrice(booking.totalPrice)} • ${booking.totalDays} day${booking.totalDays > 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),

                  // Renter info (host view only)
                  if (isHost && booking.renter != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outlined,
                            color: AppColors.textMuted, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          'Renter: ${booking.renter!.name}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],

                  // Tap hint
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'View details',
                        style: const TextStyle(
                            color: AppColors.neonCyan, fontSize: 11),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.neonCyan, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Action buttons (separate from tap) ────────────────────
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
    // HOST: show Approve/Reject only for pending requests
    if (isHost && booking.status == 'pending') return true;
    // RENTER: show Pay Now only for approved bookings
    if (!isHost && booking.status == 'approved') return true;
    return false;
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    // ── HOST: Approve / Reject ─────────────────────────────────────
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

    // ── RENTER ONLY: Pay Now ───────────────────────────────────────
    // This block NEVER runs for isHost == true
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
