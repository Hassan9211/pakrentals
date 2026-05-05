import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../features/listings/models/listing_model.dart';
import '../../features/wishlist/providers/wishlist_provider.dart';

// ── ConsumerWidget so it can watch wishlist state live ────────────────────────
class ListingCard extends ConsumerWidget {
  final ListingModel listing;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistTap;
  final bool showWishlist;

  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.onWishlistTap,
    this.showWishlist = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = getFullImageUrl(listing.firstImage);

    // ── Read live saved state from wishlist provider ───────────────────────
    // This rebuilds the heart icon whenever wishlist changes
    final isSaved = ref.watch(
      wishlistProvider.select((s) => s.savedIds.contains(listing.id)),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ─────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15)),
                    child: imageUrl.isNotEmpty
                        ? _buildImage(imageUrl)
                        : _imagePlaceholder(),
                  ),

                  // Featured badge
                  if (listing.isFeatured)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Featured',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                  // ── Wishlist heart — live from provider ──────────────
                  if (showWishlist)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(wishlistProvider.notifier)
                            .toggle(listing.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSaved
                                ? AppColors.neonPink.withOpacity(0.15)
                                : AppColors.background.withOpacity(0.75),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSaved
                                  ? AppColors.neonPink.withOpacity(0.5)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved
                                ? AppColors.neonPink
                                : AppColors.textMuted,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (listing.category != null)
                    Text(
                      listing.category!.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.neonCyan,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 3),

                  Text(
                    listing.title,
                    style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.textMuted, size: 11),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          listing.city,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${formatPrice(listing.pricePerDay)}/day',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.neonCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (listing.avgRating != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                color: Color(0xFFF59E0B), size: 11),
                            const SizedBox(width: 2),
                            Text(
                              listing.avgRating!.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildImage(String path) {
    if (isLocalFile(path)) {
      return Image.file(
        File(path),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return CachedNetworkImage(
      imageUrl: path,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, __) => _imagePlaceholder(),
      errorWidget: (_, __, ___) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.image_outlined,
            color: AppColors.textMuted, size: 32),
      ),
    );
  }
}
