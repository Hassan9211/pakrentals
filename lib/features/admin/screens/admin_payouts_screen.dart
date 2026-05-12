import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

// Payouts = paid bookings grouped by host
final adminPayoutsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('bookings')
      .where('status', isEqualTo: 'paid')
      .get()
      .timeout(const Duration(seconds: 10));

  // Group by host_id
  final Map<String, Map<String, dynamic>> hostMap = {};
  for (final doc in snap.docs) {
    final data = doc.data();
    final hostId = data['host_id']?.toString() ?? 'unknown';
    final amount = (data['total_price'] as num?)?.toDouble() ?? 0;

    if (!hostMap.containsKey(hostId)) {
      hostMap[hostId] = {
        'host_id': hostId,
        'total_earnings': 0.0,
        'booking_count': 0,
        'bookings': [],
      };
    }
    hostMap[hostId]!['total_earnings'] =
        (hostMap[hostId]!['total_earnings'] as double) + amount;
    hostMap[hostId]!['booking_count'] =
        (hostMap[hostId]!['booking_count'] as int) + 1;
    (hostMap[hostId]!['bookings'] as List).add(doc.id);
  }

  // Fetch host names
  final result = <Map<String, dynamic>>[];
  for (final entry in hostMap.entries) {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(entry.key)
          .get()
          .timeout(const Duration(seconds: 5));
      final userData = userDoc.data() ?? {};
      result.add({
        ...entry.value,
        'host_name': userData['name'] ?? 'Unknown',
        'host_email': userData['email'] ?? '',
      });
    } catch (_) {
      result.add(entry.value);
    }
  }

  result.sort((a, b) =>
      (b['total_earnings'] as double).compareTo(a['total_earnings'] as double));
  return result;
});

class AdminPayoutsScreen extends ConsumerWidget {
  const AdminPayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(adminPayoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Payouts',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(adminPayoutsProvider)),
        ],
      ),
      body: payoutsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error))),
        data: (payouts) => payouts.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payments_outlined,
                        color: AppColors.textMuted, size: 48),
                    const SizedBox(height: 12),
                    Text('No payouts yet',
                        style: GoogleFonts.syne(
                            color: AppColors.textMuted, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text('Payouts appear when bookings are paid',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              )
            : Column(
                children: [
                  // Total summary
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A1A2E), Color(0xFF1A0A2E)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.neonCyan.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Revenue',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                            Text(
                              formatPrice(payouts.fold(
                                  0.0,
                                  (total, p) =>
                                      total + (p['total_earnings'] as double))),
                              style: GoogleFonts.syne(
                                  color: AppColors.neonCyan,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Hosts',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                            Text('${payouts.length}',
                                style: GoogleFonts.syne(
                                    color: AppColors.neonViolet,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: payouts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final p = payouts[i];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
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
                                    getInitials(p['host_name']?.toString()),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p['host_name'] ?? 'Unknown',
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    Text(p['host_email'] ?? '',
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11)),
                                    Text(
                                        '${p['booking_count']} paid booking${p['booking_count'] == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),
                              Text(
                                formatPrice(p['total_earnings'] ?? 0),
                                style: GoogleFonts.syne(
                                    color: AppColors.neonGreen,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
