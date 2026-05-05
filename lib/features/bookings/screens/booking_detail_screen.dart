import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import '../models/booking_model.dart';
import '../providers/bookings_provider.dart';

class BookingDetailScreen extends ConsumerWidget {
  final int bookingId;
  final bool isHost;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    this.isHost = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingsProvider);
    final allBookings = [
      ...state.renterBookings,
      ...state.hostRequests,
    ];
    // Remove duplicates by id (a booking can appear in both lists if user is both renter and host)
    final seen = <int>{};
    final unique = allBookings.where((b) => seen.add(b.id)).toList();
    final booking = unique.firstWhere(      (b) => b.id == bookingId,
      orElse: () => unique.first,
    );

    final statusColor = bookingStatusColor(booking.status);

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status banner ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon(booking.status),
                      color: statusColor, size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bookingStatusLabel(booking.status),
                        style: GoogleFonts.syne(
                          color: statusColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _statusDescription(booking.status),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Listing info ───────────────────────────────────────────
            if (booking.listing != null) ...[
              Text('Listing',
                  style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              GlassCard(
                onTap: () =>
                    context.push('/listing/${booking.listingId}'),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.home_outlined,
                          color: AppColors.textMuted, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.listing!.title,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: AppColors.textMuted, size: 12),
                              const SizedBox(width: 3),
                              Text(booking.listing!.city,
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textMuted, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Booking details ────────────────────────────────────────
            Text('Booking Details',
                style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            GlassCard(
              child: Column(
                children: [
                  _detailRow(
                    Icons.calendar_today_outlined,
                    'Check-in',
                    formatDate(booking.startDate),
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  _detailRow(
                    Icons.calendar_today_outlined,
                    'Check-out',
                    formatDate(booking.endDate),
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  _detailRow(
                    Icons.access_time_outlined,
                    'Duration',
                    '${booking.totalDays} day${booking.totalDays > 1 ? 's' : ''}',
                  ),
                  const Divider(color: AppColors.border, height: 20),
                  _detailRow(
                    Icons.payments_outlined,
                    'Total Amount',
                    formatPrice(booking.totalPrice),
                    valueColor: AppColors.neonCyan,
                  ),
                  if (booking.paymentMethod != null) ...[
                    const Divider(color: AppColors.border, height: 20),
                    _detailRow(
                      Icons.credit_card_outlined,
                      'Payment Method',
                      _paymentLabel(booking.paymentMethod!),
                    ),
                  ],
                  if (booking.notes != null &&
                      booking.notes!.isNotEmpty) ...[
                    const Divider(color: AppColors.border, height: 20),
                    _detailRow(
                      Icons.notes_outlined,
                      'Notes',
                      booking.notes!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Renter/Host info ───────────────────────────────────────
            if (isHost && booking.renter != null) ...[
              Text('Renter',
                  style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          getInitials(booking.renter!.name),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.renter!.name,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          if (booking.renter!.phone != null)
                            Text(booking.renter!.phone!,
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Action buttons ─────────────────────────────────────────
            _buildActions(context, ref, booking),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
      BuildContext context, WidgetRef ref, BookingModel booking) {
    final actions = <Widget>[];

    if (isHost) {
      if (booking.status == 'pending') {
        actions.add(Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.read(bookingsProvider.notifier).reject(booking.id);
                  context.pop();
                  showSnackBar(context, 'Booking rejected');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryGlowButton(
                label: 'Approve',
                onPressed: () {
                  ref.read(bookingsProvider.notifier).approve(booking.id);
                  context.pop();
                  showSnackBar(context, 'Booking approved! ✅');
                },
              ),
            ),
          ],
        ));
      }
    } else {
      // Renter actions
      if (booking.status == 'approved') {
        actions.add(PrimaryGlowButton(
          label: 'Pay Now',
          width: double.infinity,
          icon: Icons.payment_outlined,
          onPressed: () => context.push(
            '/payment/${booking.id}?amount=${booking.totalPrice}',
          ),
        ));
      }
      if (booking.status == 'paid' || booking.status == 'active') {
        actions.add(PrimaryGlowButton(
          label: 'Mark as Completed',
          width: double.infinity,
          icon: Icons.check_circle_outline,
          onPressed: () {
            ref.read(bookingsProvider.notifier).complete(booking.id);
            context.pop();
            showSnackBar(context, 'Booking marked as completed!');
          },
        ));
      }
      if (booking.status == 'completed') {
        actions.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.neonGreen.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.neonGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Booking Completed',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (actions.isEmpty) return const SizedBox();
    return Column(children: actions);
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 16),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 13)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty_outlined;
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      case 'paid': return Icons.payment_outlined;
      case 'active': return Icons.play_circle_outline;
      case 'completed': return Icons.task_alt_outlined;
      case 'cancelled': return Icons.block_outlined;
      default: return Icons.info_outline;
    }
  }

  String _statusDescription(String status) {
    switch (status) {
      case 'pending': return 'Waiting for host approval';
      case 'approved': return 'Approved — complete payment to confirm';
      case 'rejected': return 'Host declined this request';
      case 'paid': return 'Payment received — booking confirmed';
      case 'active': return 'Rental is currently active';
      case 'completed': return 'Rental completed successfully';
      case 'cancelled': return 'Booking was cancelled';
      default: return '';
    }
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'jazzcash': return 'JazzCash';
      case 'easypaisa': return 'Easypaisa';
      case 'bank_transfer': return 'Bank Transfer';
      case 'cash': return 'Cash on Delivery';
      default: return method;
    }
  }
}
