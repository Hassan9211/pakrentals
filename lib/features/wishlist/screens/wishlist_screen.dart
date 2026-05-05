import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/listing_card.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../providers/wishlist_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Wishlist', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(wishlistProvider.notifier).load(),
        color: AppColors.neonCyan,
        backgroundColor: AppColors.surface,
        child: state.isLoading
            ? GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 4,
                itemBuilder: (_, __) => const ListingCardShimmer(),
              )
            : state.listings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite_border,
                            color: AppColors.textMuted, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'No saved listings',
                          style: GoogleFonts.syne(
                            color: AppColors.textMuted,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Save listings you like to find them here',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.push('/browse'),
                          child: const Text('Browse Listings'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: state.listings.length,
                    itemBuilder: (context, index) {
                      final listing = state.listings[index];
                      return ListingCard(
                        listing: listing,
                        onTap: () => context.push('/listing/${listing.id}'),
                      );
                    },
                  ),
      ),
    );
  }
}
