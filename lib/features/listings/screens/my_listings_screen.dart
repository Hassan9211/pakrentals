import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/neon_gradient_text.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import '../models/listing_model.dart';

// ── Firestore-backed my listings ──────────────────────────────────────────────
final myListingsProvider =
    FutureProvider<List<ListingModel>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (uid.isEmpty) return [];

  final snap = await FirebaseFirestore.instance
      .collection('listings')
      .where('host_id', isEqualTo: uid)
      .get()
      .timeout(const Duration(seconds: 10));

  return snap.docs
      .map((doc) => ListingModel.fromJson({'id': doc.id, ...doc.data()}))
      .toList();
});

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Listings',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(myListingsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push('/create-listing');
              ref.invalidate(myListingsProvider);
            },
          ),
        ],
      ),
      body: listingsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Error loading listings',
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(myListingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (listings) => listings.isEmpty
            ? _buildEmpty(context, ref)
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myListingsProvider),
                color: AppColors.neonCyan,
                backgroundColor: AppColors.surface,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return _MyListingCard(
                      listing: listing,
                      onTap: () => context.push('/listing/${listing.id}'),
                      onDelete: () =>
                          _confirmDelete(context, ref, listing),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/create-listing');
          ref.invalidate(myListingsProvider);
        },
        backgroundColor: AppColors.neonCyan,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add),
        label: Text('New Listing',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ListingModel listing) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Listing',
            style: GoogleFonts.syne(color: AppColors.textPrimary)),
        content: Text('Delete "${listing.title}"? This cannot be undone.',
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
      final fid = listing.firestoreId;
      if (fid != null) {
        await FirebaseFirestore.instance
            .collection('listings')
            .doc(fid)
            .delete();
        ref.invalidate(myListingsProvider);
        if (context.mounted) showSnackBar(context, 'Listing deleted');
      }
    });
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.home_work_outlined,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: 24),
            NeonGradientText('Start Earning Today',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'List your car, camera, tools, or any item and earn money from people nearby.',
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            PrimaryGlowButton(
              label: 'Create Your First Listing',
              icon: Icons.add_circle_outline,
              onPressed: () async {
                await context.push('/create-listing');
                ref.invalidate(myListingsProvider);
              },
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
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

class _MyListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MyListingCard({
    required this.listing,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: _buildThumb(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.title,
                      style: GoogleFonts.syne(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppColors.textMuted, size: 12),
                    const SizedBox(width: 3),
                    Text(listing.city,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ]),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${formatPrice(listing.pricePerDay)}/day',
                          style: GoogleFonts.spaceGrotesk(
                              color: AppColors.neonCyan,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 18),
                      ),
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
    );
  }

  Widget _buildThumb() {
    final img = listing.images.isNotEmpty ? listing.images.first : null;
    if (img == null || img.isEmpty) {
      return Container(
          color: AppColors.surfaceVariant,
          child: const Center(
              child: Icon(Icons.image_outlined,
                  color: AppColors.textMuted, size: 28)));
    }
    if (img.startsWith('http')) {
      return Image.network(img,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
              color: AppColors.surfaceVariant,
              child: const Icon(Icons.broken_image_outlined,
                  color: AppColors.textMuted, size: 28)));
    }
    return Image.file(File(img),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            color: AppColors.surfaceVariant,
            child: const Icon(Icons.image_outlined,
                color: AppColors.textMuted, size: 28)));
  }
}
