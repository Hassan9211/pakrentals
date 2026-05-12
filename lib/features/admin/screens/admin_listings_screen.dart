import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

final adminListingsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('listings')
      .get()
      .timeout(const Duration(seconds: 10));
  return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
});

class AdminListingsScreen extends ConsumerWidget {
  const AdminListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(adminListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Listings',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(adminListingsProvider)),
        ],
      ),
      body: listingsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error))),
        data: (listings) => listings.isEmpty
            ? const Center(
                child: Text('No listings',
                    style: TextStyle(color: AppColors.textMuted)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: listings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final l = listings[i];
                  final status = l['status'] ?? 'active';
                  final statusColor = status == 'active'
                      ? AppColors.neonGreen
                      : AppColors.textMuted;
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
                              child: Text(l['title'] ?? 'Untitled',
                                  style: GoogleFonts.syne(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: statusColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(status.toUpperCase(),
                                  style: TextStyle(
                                      color: statusColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: AppColors.textMuted, size: 13),
                            const SizedBox(width: 4),
                            Text(l['city'] ?? '',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                            const Spacer(),
                            Text(formatPrice(l['price_per_day'] ?? 0),
                                style: GoogleFonts.spaceGrotesk(
                                    color: AppColors.neonCyan,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            const Text('/day',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outlined,
                                color: AppColors.textMuted, size: 13),
                            const SizedBox(width: 4),
                            Text(
                                'Host: ${l['host_name'] ?? l['host_id'] ?? 'Unknown'}',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                        // Action buttons row
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Featured toggle
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final isFeatured = l['is_featured'] == true;
                                  await FirebaseFirestore.instance
                                      .collection('listings')
                                      .doc(l['id'].toString())
                                      .update({'is_featured': !isFeatured});
                                  ref.invalidate(adminListingsProvider);
                                  if (context.mounted) {
                                    showSnackBar(
                                      context,
                                      isFeatured
                                          ? 'Removed from featured'
                                          : 'Marked as featured ⭐',
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: l['is_featured'] == true
                                        ? AppColors.warning
                                            .withValues(alpha: 0.12)
                                        : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: l['is_featured'] == true
                                          ? AppColors.warning
                                              .withValues(alpha: 0.4)
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Icon(
                                        l['is_featured'] == true
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: l['is_featured'] == true
                                            ? AppColors.warning
                                            : AppColors.textMuted,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          l['is_featured'] == true
                                              ? 'Featured'
                                              : 'Feature',
                                          style: TextStyle(
                                            color: l['is_featured'] == true
                                                ? AppColors.warning
                                                : AppColors.textMuted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delete button
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _confirmDelete(context, ref,
                                    l['id'].toString(), l['title'] ?? ''),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.error.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.error
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Icon(Icons.delete_outline,
                                          color: AppColors.error, size: 13),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text('Delete',
                                            style: TextStyle(
                                                color: AppColors.error,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String title) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Listing',
            style: GoogleFonts.syne(color: AppColors.textPrimary)),
        content: Text('Delete "$title"? This cannot be undone.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed != true) return;
      await FirebaseFirestore.instance.collection('listings').doc(id).delete();
      ref.invalidate(adminListingsProvider);
      if (context.mounted) showSnackBar(context, 'Listing deleted');
    });
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
