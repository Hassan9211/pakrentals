import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/neon_gradient_text.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import 'create_listing_screen.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(myListingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('My Listings',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          if (listings.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/create-listing'),
              tooltip: 'Add new listing',
            ),
        ],
      ),
      body: listings.isEmpty
          ? _buildEmpty(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                return _MyListingCard(
                  title: listing.title,
                  city: listing.city,
                  pricePerDay: listing.pricePerDay,
                  status: listing.status,
                  imagePath: listing.images.isNotEmpty
                      ? listing.images.first
                      : null,
                  onTap: () => context.push('/listing/${listing.id}'),
                );
              },
            ),
      floatingActionButton: listings.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/create-listing'),
              backgroundColor: AppColors.neonCyan,
              foregroundColor: AppColors.background,
              icon: const Icon(Icons.add),
              label: Text(
                'New Listing',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }

  Widget _buildEmpty(BuildContext context) {
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
                    color: AppColors.neonCyan.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.home_work_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            NeonGradientText(
              'Start Earning Today',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'List your car, camera, tools, or any item and earn money from people nearby.',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...[
              ('💰', 'Earn passive income'),
              ('🔒', 'Secure payments'),
              ('⭐', 'Build your reputation'),
            ].map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      item.$2,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            PrimaryGlowButton(
              label: 'Create Your First Listing',
              icon: Icons.add_circle_outline,
              onPressed: () => context.push('/create-listing'),
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Individual listing card ───────────────────────────────────────────────────
class _MyListingCard extends StatelessWidget {
  final String title;
  final String city;
  final double pricePerDay;
  final String status;
  final String? imagePath;
  final VoidCallback onTap;

  const _MyListingCard({
    required this.title,
    required this.city,
    required this.pricePerDay,
    required this.status,
    required this.onTap,
    this.imagePath,
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
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: _buildThumb(),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.textMuted, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        city,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${formatPrice(pricePerDay)}/day',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.neonCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.neonGreen.withOpacity(0.4)),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.neonGreen,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
    if (imagePath == null || imagePath!.isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(Icons.image_outlined,
              color: AppColors.textMuted, size: 28),
        ),
      );
    }
    if (imagePath!.startsWith('http')) {
      return Image.network(
        imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surfaceVariant,
          child: const Icon(Icons.broken_image_outlined,
              color: AppColors.textMuted, size: 28),
        ),
      );
    }
    // Local file
    return Image.file(
      File(imagePath!),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.surfaceVariant,
        child: const Icon(Icons.image_outlined,
            color: AppColors.textMuted, size: 28),
      ),
    );
  }
}
