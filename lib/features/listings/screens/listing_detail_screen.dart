import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/api/api_client.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../models/review_model.dart';
import '../providers/listings_provider.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final int listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  final _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Image helpers ──────────────────────────────────────────────────────────
  Widget _buildGalleryImage(String path) {
    if (isLocalFile(path)) {
      return Image.file(File(path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _galleryPlaceholder());
    }
    return CachedNetworkImage(
      imageUrl: path,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => Container(color: AppColors.surfaceVariant),
      errorWidget: (_, __, ___) => _galleryPlaceholder(),
    );
  }

  Widget _galleryPlaceholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(Icons.broken_image_outlined,
              color: AppColors.textMuted, size: 48),
        ),
      );

  // ── Message host ───────────────────────────────────────────────────────────
  void _messageHost(BuildContext context, int hostId, int listingId) {
    if (!ref.read(authProvider).isAuthenticated) {
      context.push('/login');
      return;
    }
    context.push('/messages/$listingId/$hostId');
  }

  // ── Write review dialog ────────────────────────────────────────────────────
  void _showReviewDialog(BuildContext context, int listingId) {
    if (!ref.read(authProvider).isAuthenticated) {
      context.push('/login');
      return;
    }
    int rating = 5;
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Write a Review',
                style: GoogleFonts.syne(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              // Star rating
              Text('Rating',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setModalState(() => rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFF59E0B),
                        size: 32,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Comment
              TextField(
                controller: commentCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Your experience (optional)',
                  hintText: 'Tell others about this listing...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryGlowButton(
                label: 'Submit Review',
                width: double.infinity,
                onPressed: () {
                  // Add to mock reviews
                  final user = ref.read(authProvider).user;
                  final newReview = ReviewModel(
                    id: mockReviews.length + 100,
                    listingId: listingId,
                    userId: user?.id ?? 1,
                    rating: rating,
                    comment: commentCtrl.text.trim().isEmpty
                        ? null
                        : commentCtrl.text.trim(),
                    user: user,
                    createdAt: DateTime.now().toIso8601String(),
                  );
                  mockReviews.add(newReview);
                  // Reload listing detail
                  ref.read(listingDetailProvider(listingId).notifier).load();
                  Navigator.pop(ctx);
                  showSnackBar(context, 'Review submitted! ⭐');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listingDetailProvider(widget.listingId));
    final authState = ref.watch(authProvider);

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan)),
      );
    }

    if (state.error != null || state.listing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(state.error ?? 'Listing not found',
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(listingDetailProvider(widget.listingId).notifier)
                    .load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final listing = state.listing!;
    final images = listing.images
        .map((img) => getFullImageUrl(img))
        .where((url) => url.isNotEmpty)
        .toList();

    final currentUser = authState.user;
    final isOwnListing = currentUser != null &&
        listing.host != null &&
        currentUser.id == listing.host!.id;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Gallery AppBar ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
            ),
            actions: [
              // Wishlist
              GestureDetector(
                onTap: () =>
                    ref.read(wishlistProvider.notifier).toggle(listing.id),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    listing.isSaved == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: listing.isSaved == true
                        ? AppColors.neonPink
                        : AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: images.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          controller: _pageCtrl,
                          itemCount: images.length,
                          itemBuilder: (_, i) => _buildGalleryImage(images[i]),
                        ),
                        if (images.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SmoothPageIndicator(
                                controller: _pageCtrl,
                                count: images.length,
                                effect: const WormEffect(
                                  dotHeight: 6,
                                  dotWidth: 6,
                                  activeDotColor: AppColors.neonCyan,
                                  dotColor: AppColors.border,
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.image_outlined,
                            color: AppColors.textMuted, size: 64),
                      ),
                    ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  if (listing.category != null)
                    Text(
                      listing.category!.name,
                      style: const TextStyle(
                        color: AppColors.neonCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    listing.title,
                    style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 12),

                  // Location & Rating
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 4),
                      Text(listing.city,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 14)),
                      const Spacer(),
                      if (listing.avgRating != null) ...[
                        const Icon(Icons.star,
                            color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${listing.avgRating!.toStringAsFixed(1)} (${listing.reviewsCount ?? 0})',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),

                  // Price
                  Text(
                    formatPrice(listing.pricePerDay),
                    style: GoogleFonts.syne(
                      color: AppColors.neonCyan,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text('per day',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12)),

                  const SizedBox(height: 20),

                  // Description
                  if (listing.description != null) ...[
                    Text('About this listing',
                        style: GoogleFonts.syne(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      listing.description!,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.6),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Host info + Message button ──────────────────────
                  if (listing.host != null) ...[
                    Text('Hosted by',
                        style: GoogleFonts.syne(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                getInitials(listing.host!.name),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name & city
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.host!.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15),
                                ),
                                if (listing.host!.city != null)
                                  Text(listing.host!.city!,
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12)),
                              ],
                            ),
                          ),
                          if (listing.host!.isVerified)
                            const Icon(Icons.verified,
                                color: AppColors.neonCyan, size: 18),
                          const SizedBox(width: 8),
                          // Message button — only for renters
                          if (!isOwnListing)
                            GestureDetector(
                              onTap: () => _messageHost(
                                  context, listing.host!.id, listing.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.neonCyan.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color:
                                          AppColors.neonCyan.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.chat_bubble_outline,
                                        color: AppColors.neonCyan, size: 14),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Message',
                                      style: GoogleFonts.spaceGrotesk(
                                        color: AppColors.neonCyan,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Reviews section ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reviews (${state.reviews.length})',
                        style: GoogleFonts.syne(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                      // Write review — only for renters on completed bookings
                      if (!isOwnListing)
                        GestureDetector(
                          onTap: () => _showReviewDialog(context, listing.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_outline,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  'Write Review',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (state.reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_border,
                              color: AppColors.textMuted, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'No reviews yet. Be the first!',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    ...state.reviews.take(5).map((review) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        getInitials(review.user?.name),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          review.user?.name ?? 'Anonymous',
                                          style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                        ),
                                        if (review.createdAt != null)
                                          Text(
                                            formatDate(review.createdAt),
                                            style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 10),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Stars
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i < review.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: const Color(0xFFF59E0B),
                                        size: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (review.comment != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  review.comment!,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.5),
                                ),
                              ],
                            ],
                          ),
                        )),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom bar ────────────────────────────────────────────────────
      bottomNavigationBar: _buildBottomBar(context, listing, authState),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, dynamic listing, dynamic authState) {
    final currentUser = authState.user;
    final isOwnListing = currentUser != null &&
        listing.host != null &&
        currentUser.id == listing.host!.id;

    // Host — manage button
    if (isOwnListing) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            const Icon(Icons.home_outlined,
                color: AppColors.neonViolet, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('This is your listing',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary, fontSize: 13)),
            ),
            OutlinedButton(
              onPressed: () => context.push('/my-listings'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.neonViolet,
                side: const BorderSide(color: AppColors.neonViolet),
              ),
              child: const Text('Manage'),
            ),
          ],
        ),
      );
    }

    // Renter — price + Book Now + Message
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Price
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatPrice(listing.pricePerDay),
                style: GoogleFonts.syne(
                    color: AppColors.neonCyan,
                    fontSize: 16,
                    fontWeight: FontWeight.w800),
              ),
              const Text('per day',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 12),
          // Message host
          if (listing.host != null)
            GestureDetector(
              onTap: () => _messageHost(context, listing.host!.id, listing.id),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.chat_bubble_outline,
                    color: AppColors.neonCyan, size: 20),
              ),
            ),
          const SizedBox(width: 10),
          // Book Now
          Expanded(
            child: PrimaryGlowButton(
              label: 'Book Now',
              onPressed: () {
                if (!authState.isAuthenticated) {
                  context.push('/login');
                  return;
                }
                context.push('/booking/create/${listing.id}');
              },
            ),
          ),
        ],
      ),
    );
  }
}
