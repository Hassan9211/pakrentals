import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

final adminReportsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('reports')
      .get()
      .timeout(const Duration(seconds: 10));
  return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
});

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(adminReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reports',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(adminReportsProvider)),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error))),
        data: (reports) => reports.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flag_outlined,
                        color: AppColors.textMuted, size: 48),
                    const SizedBox(height: 12),
                    Text('No reports',
                        style: GoogleFonts.syne(
                            color: AppColors.textMuted, fontSize: 16)),
                  ],
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final r = reports[i];
                  final status = r['status'] ?? 'open';
                  final isOpen = status == 'open';
                  final type = r['type'] ?? 'general';
                  final ts = r['created_at'];
                  String dateStr = '';
                  if (ts is Timestamp) {
                    dateStr = formatDate(ts.toDate().toIso8601String());
                  }

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isOpen
                            ? AppColors.error.withValues(alpha: 0.4)
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flag_outlined,
                                color: isOpen
                                    ? AppColors.error
                                    : AppColors.textMuted,
                                size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(r['subject'] ?? 'No subject',
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? AppColors.error.withValues(alpha: 0.12)
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(status.toUpperCase(),
                                  style: TextStyle(
                                      color: isOpen
                                          ? AppColors.error
                                          : AppColors.textMuted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(type.toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 10)),
                        ),
                        const SizedBox(height: 6),
                        if (r['description'] != null)
                          Text(r['description'].toString(),
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.4),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis),
                        if (dateStr.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(dateStr,
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ],
                        // Resolve button
                        if (isOpen) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('reports')
                                    .doc(r['id'].toString())
                                    .update({'status': 'resolved'});
                                ref.invalidate(adminReportsProvider);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.neonGreen,
                                side: const BorderSide(
                                    color: AppColors.neonGreen),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('Mark as Resolved'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
