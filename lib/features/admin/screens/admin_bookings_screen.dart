import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

final adminBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('bookings')
      .get()
      .timeout(const Duration(seconds: 10));
  return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
});

class AdminBookingsScreen extends ConsumerWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(adminBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bookings', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(adminBookingsProvider)),
        ],
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        data: (bookings) => bookings.isEmpty
            ? const Center(child: Text('No bookings', style: TextStyle(color: AppColors.textMuted)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final b = bookings[i];
                  final status = b['status'] ?? 'pending';
                  final statusColor = bookingStatusColor(status);
                  final ts = b['created_at'];
                  String dateStr = '';
                  if (ts is Timestamp) dateStr = formatDate(ts.toDate().toIso8601String());

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Booking #${b['id'].toString().substring(0, 6)}',
                                  style: GoogleFonts.syne(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withOpacity(0.4)),
                              ),
                              child: Text(bookingStatusLabel(status),
                                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _row(Icons.calendar_today_outlined,
                            '${formatDate(b['start_date']?.toString())} → ${formatDate(b['end_date']?.toString())}'),
                        _row(Icons.payments_outlined,
                            '${formatPrice(b['total_price'] ?? 0)} • ${b['total_days'] ?? 0} days'),
                        _row(Icons.person_outlined, 'Renter: ${b['renter_id']?.toString().substring(0, 8) ?? ''}...'),
                        _row(Icons.home_outlined, 'Host: ${b['host_id']?.toString().substring(0, 8) ?? ''}...'),
                        if (dateStr.isNotEmpty) _row(Icons.access_time_outlined, 'Created: $dateStr'),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 13),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
