import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/image_source_sheet.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import '../models/booking_model.dart';
import '../providers/bookings_provider.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final int bookingId;
  final bool isHost;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    this.isHost = false,
  });

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _isUploading = false;

  // ── Upload photos to Firebase Storage ─────────────────────────────────────
  Future<List<String>> _uploadPhotos(
      List<String> paths, String folder) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final urls = <String>[];
    for (int i = 0; i < paths.length; i++) {
      try {
        final ref = FirebaseStorage.instance
            .ref('bookings/${widget.bookingId}/$folder/${uid}_$i.jpg');
        final task = await ref.putFile(
          File(paths[i]),
          SettableMetadata(contentType: 'image/jpeg'),
        );
        urls.add(await task.ref.getDownloadURL());
      } catch (e) {
        urls.add(paths[i]); // fallback to local path
      }
    }
    return urls;
  }

  // ── Send notification to admin ─────────────────────────────────────────────
  Future<void> _notifyAdmin(String title, String body,
      {List<String>? photoUrls}) async {
    const adminUid = 't41DI9ZHowUAsk9pgyFd7iJrTsA3';
    await FirebaseFirestore.instance.collection('notifications').add({
      'user_id': adminUid,
      'type': 'handover',
      'title': title,
      'body': body,
      'photo_urls': photoUrls ?? [],
      'booking_id': widget.bookingId.toString(),
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Send notification to host ──────────────────────────────────────────────
  Future<void> _notifyHost(
      String hostId, String title, String body,
      {List<String>? photoUrls}) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'user_id': hostId,
      'type': 'payment_proof',
      'title': title,
      'body': body,
      'photo_urls': photoUrls ?? [],
      'booking_id': widget.bookingId.toString(),
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Payment proof upload ───────────────────────────────────────────────────
  Future<void> _uploadPaymentProof(BookingModel booking) async {
    final paths = await pickMultipleImages(context, imageQuality: 85);
    if (paths.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      final urls = await _uploadPhotos(paths, 'payment_proof');

      // Save to Firestore booking doc
      final firestoreId = booking.firestoreId;
      if (firestoreId != null) {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(firestoreId)
            .set({'payment_proof_urls': urls}, SetOptions(merge: true));
      }

      // Get host_id from booking
      final bookingData = (await FirebaseFirestore.instance
              .collection('bookings')
              .doc(firestoreId)
              .get())
          .data() ?? {};
      final hostId = bookingData['host_id']?.toString() ?? '';
      final listingTitle = booking.listing?.title ?? 'a listing';
      final bookingRef = '#${widget.bookingId.toString().substring(0, 6)}';

      // Notify HOST
      if (hostId.isNotEmpty) {
        await _notifyHost(
          hostId,
          'Payment Proof Submitted',
          'Renter has uploaded payment proof for booking $bookingRef — "$listingTitle"',
          photoUrls: urls,
        );
      }

      // Notify ADMIN too
      await _notifyAdmin(
        'Payment Proof Received',
        'Renter submitted payment proof for booking $bookingRef — "$listingTitle"',
        photoUrls: urls,
      );

      if (mounted) showSnackBar(context, 'Payment proof sent to host & admin! ✅');
    } catch (e) {
      if (mounted) showSnackBar(context, 'Upload failed: $e', isError: true);
    }
    setState(() => _isUploading = false);
  }

  // ── Pickup proof (item received) ───────────────────────────────────────────
  Future<void> _uploadPickupProof(BookingModel booking) async {
    final paths = await pickMultipleImages(context, imageQuality: 85);
    if (paths.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      final urls = await _uploadPhotos(paths, 'pickup_proof');

      final firestoreId = booking.firestoreId;
      if (firestoreId != null) {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(firestoreId)
            .set({
          'pickup_proof_urls': urls,
          'status': 'active',
          'pickup_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await _notifyAdmin(
        'Item Picked Up',
        'Renter has confirmed receiving the item for booking #${widget.bookingId.toString().substring(0, 6)}',
        photoUrls: urls,
      );

      if (mounted) showSnackBar(context, 'Pickup confirmed! Item is now active 🎉');
    } catch (e) {
      if (mounted) showSnackBar(context, 'Upload failed: $e', isError: true);
    }
    setState(() => _isUploading = false);
  }

  // ── Return proof (item returned) ───────────────────────────────────────────
  Future<void> _uploadReturnProof(BookingModel booking) async {
    final paths = await pickMultipleImages(context, imageQuality: 85);
    if (paths.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      final urls = await _uploadPhotos(paths, 'return_proof');

      final firestoreId = booking.firestoreId;
      if (firestoreId != null) {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(firestoreId)
            .set({
          'return_proof_urls': urls,
          'status': 'completed',
          'returned_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await _notifyAdmin(
        'Item Returned',
        'Renter has returned the item for booking #${widget.bookingId.toString().substring(0, 6)}',
        photoUrls: urls,
      );

      if (mounted) showSnackBar(context, 'Return confirmed! Booking completed ✅');
    } catch (e) {
      if (mounted) showSnackBar(context, 'Upload failed: $e', isError: true);
    }
    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsProvider);
    final allBookings = [
      ...state.renterBookings,
      ...state.hostRequests,
    ];
    final seen = <int>{};
    final unique = allBookings.where((b) => seen.add(b.id)).toList();

    if (unique.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Booking Details',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700))),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan)),
      );
    }

    BookingModel? booking;
    try {
      booking = unique.firstWhere((b) => b.id == widget.bookingId);
    } catch (_) {
      booking = unique.first;
    }

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
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.neonCyan),
                  const SizedBox(height: 16),
                  Text('Uploading photos...',
                      style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status banner ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(_statusIcon(booking.status),
                            color: statusColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(bookingStatusLabel(booking.status),
                                  style: GoogleFonts.syne(
                                      color: statusColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              Text(
                                _statusDescription(booking.status),
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Listing ──────────────────────────────────────────
                  if (booking.listing != null) ...[
                    Text('Listing',
                        style: GoogleFonts.syne(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    GlassCard(
                      onTap: () =>
                          context.push('/listing/${booking!.listingId}'),
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
                                Text(booking.listing!.title,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                // City
                                Row(children: [
                                  const Icon(Icons.location_city_outlined,
                                      color: AppColors.textMuted, size: 12),
                                  const SizedBox(width: 3),
                                  Text(booking.listing!.city,
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12)),
                                ]),
                                // Full address — pickup location for renter
                                if (booking.listing!.address != null &&
                                    booking.listing!.address!.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on_outlined,
                                          color: AppColors.neonCyan,
                                          size: 12),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          booking.listing!.address!,
                                          style: const TextStyle(
                                            color: AppColors.neonCyan,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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

                  // ── Booking details ──────────────────────────────────
                  Text('Booking Details',
                      style: GoogleFonts.syne(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  GlassCard(
                    child: Column(children: [
                      _row(Icons.calendar_today_outlined, 'Check-in',
                          formatDate(booking.startDate)),
                      const Divider(color: AppColors.border, height: 20),
                      _row(Icons.calendar_today_outlined, 'Check-out',
                          formatDate(booking.endDate)),
                      const Divider(color: AppColors.border, height: 20),
                      _row(Icons.access_time_outlined, 'Duration',
                          '${booking.totalDays} day${booking.totalDays > 1 ? 's' : ''}'),
                      // Pickup address
                      if (booking.listing?.address != null &&
                          booking.listing!.address!.isNotEmpty) ...[
                        const Divider(color: AppColors.border, height: 20),
                        _row(
                          Icons.location_on_outlined,
                          'Pickup Address',
                          '${booking.listing!.city}, ${booking.listing!.address!}',
                          valueColor: AppColors.neonCyan,
                        ),
                      ] else if (booking.listing?.city != null) ...[
                        const Divider(color: AppColors.border, height: 20),
                        _row(
                          Icons.location_on_outlined,
                          'Pickup City',
                          booking.listing!.city,
                          valueColor: AppColors.neonCyan,
                        ),
                      ],                      const Divider(color: AppColors.border, height: 20),
                      _row(Icons.payments_outlined, 'Total Amount',
                          formatPrice(booking.totalPrice),
                          valueColor: AppColors.neonCyan),
                      if (booking.paymentMethod != null) ...[
                        const Divider(color: AppColors.border, height: 20),
                        _row(Icons.credit_card_outlined, 'Payment',
                            _paymentLabel(booking.paymentMethod!)),
                      ],
                      if (booking.notes != null &&
                          booking.notes!.isNotEmpty) ...[
                        const Divider(color: AppColors.border, height: 20),
                        _row(Icons.notes_outlined, 'Notes', booking.notes!),
                      ],
                    ]),
                  ),

                  const SizedBox(height: 20),

                  // ── Renter info (host view) ───────────────────────────
                  if (widget.isHost && booking.renter != null) ...[
                    Text('Renter',
                        style: GoogleFonts.syne(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text(getInitials(booking.renter!.name),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
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
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Action buttons ───────────────────────────────────
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

    // ── HOST / ADMIN actions ───────────────────────────────────────────
    if (widget.isHost) {
      if (booking.status == 'pending') {
        actions.add(Row(children: [
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
        ]));
      }
    }

    // ── RENTER actions ─────────────────────────────────────────────────
    if (!widget.isHost) {
      // Pay Now
      if (booking.status == 'approved') {
        actions.add(PrimaryGlowButton(
          label: 'Pay Now',
          width: double.infinity,
          icon: Icons.payment_outlined,
          onPressed: () => context.push(
              '/payment/${booking.id}?amount=${booking.totalPrice}'),
        ));
        actions.add(const SizedBox(height: 10));

        // Upload payment proof
        actions.add(_proofButton(
          icon: Icons.receipt_long_outlined,
          label: 'Upload Payment Screenshot',
          subtitle: 'Send payment proof to host & admin',
          color: AppColors.neonViolet,
          onTap: () => _uploadPaymentProof(booking),
        ));
      }

      // Pickup proof — item received
      if (booking.status == 'paid') {
        actions.add(_proofButton(
          icon: Icons.inventory_2_outlined,
          label: 'Confirm Item Received',
          subtitle: 'Upload photos — item is with you',
          color: AppColors.neonCyan,
          onTap: () => _uploadPickupProof(booking),
        ));
      }

      // Return proof — item returned
      if (booking.status == 'active') {
        actions.add(_proofButton(
          icon: Icons.assignment_return_outlined,
          label: 'Return Item',
          subtitle: 'Upload photos — returning item to owner',
          color: AppColors.neonPink,
          onTap: () => _uploadReturnProof(booking),
        ));
      }

      // Completed
      if (booking.status == 'completed') {
        actions.add(Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.neonGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neonGreen.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.neonGreen, size: 18),
              const SizedBox(width: 8),
              Text('Booking Completed',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
        ));
      }
    }

    if (actions.isEmpty) return const SizedBox();
    return Column(children: actions);
  }

  // ── Proof upload button ────────────────────────────────────────────────────
  Widget _proofButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.upload_outlined, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(children: [
      Icon(icon, color: AppColors.textMuted, size: 16),
      const SizedBox(width: 10),
      Text(label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
      const Spacer(),
      Flexible(
        child: Text(value,
            style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.end),
      ),
    ]);
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty_outlined;
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      case 'paid': return Icons.payment_outlined;
      case 'active': return Icons.play_circle_outline;
      case 'completed': return Icons.task_alt_outlined;
      default: return Icons.info_outline;
    }
  }

  String _statusDescription(String status) {
    switch (status) {
      case 'pending': return 'Waiting for host approval';
      case 'approved': return 'Approved — pay & upload payment proof';
      case 'rejected': return 'Host declined this request';
      case 'paid': return 'Paid — confirm item received with photos';
      case 'active': return 'Item with you — return with photos when done';      case 'completed': return 'Rental completed successfully';
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

void showSnackBar(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: isError ? AppColors.error : AppColors.neonGreen,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}
