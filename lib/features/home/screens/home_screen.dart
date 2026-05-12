import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/listing_card.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/neon_gradient_text.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../../listings/models/category_model.dart';
import '../../listings/models/listing_model.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeProvider.notifier).loadHome(),
        color: AppColors.neonCyan,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              title: NeonGradientText(
                'PakRentals',
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.push('/notifications'),
                ),
                // Avatar only — no Sign In button
                if (authState.isAuthenticated)
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: Center(
                        child: Text(
                          getInitials(authState.user?.name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  // Show avatar placeholder that goes to profile (which shows sign-in prompt)
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceVariant,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),

            // ── Body ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero + Search in one block (no overlap)
                  _buildHeroWithSearch(context, authState.user?.name),

                  // Stats
                  _buildStatsSection(ref),

                  // Categories
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: SectionHeader(
                      title: 'Browse Categories',
                      subtitle: 'Find what you need',
                      actionLabel: 'See All',
                      onAction: () => context.push('/browse'),
                    ),
                  ),
                  homeState.isLoading
                      ? _buildCategoryShimmer()
                      : _buildCategories(context, homeState.categories),

                  // Featured / Latest Listings
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: SectionHeader(
                      title: homeState.featuredListings.any((l) => l.isFeatured)
                          ? 'Featured Listings'
                          : 'Latest Listings',
                      subtitle: 'Top picks for you',
                      actionLabel: 'View All',
                      onAction: () => context.push('/browse'),
                    ),
                  ),
                  homeState.isLoading
                      ? _buildListingsShimmer()
                      : _buildFeaturedListings(
                          context, ref, homeState.featuredListings),

                  // CTA Section
                  _buildCtaSection(context, ref),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero + Search (stacked vertically, no overlap) ──────────────────
  Widget _buildHeroWithSearch(BuildContext context, String? userName) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0A0F), Color(0xFF1A0A2E), Color(0xFF0A0A0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero text
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userName != null)
                  Text(
                    'Hello, ${userName.split(' ').first} 👋',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 8),
                NeonGradientText(
                  'Rent Anything,\nAnywhere in Pakistan',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0),
                const SizedBox(height: 10),
                Text(
                  'Cars, bikes, cameras, tools, and more — all at your fingertips.',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),

          // Search bar — sits below hero text, no overlap
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: GestureDetector(
              onTap: () => context.push('/browse'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonCyan.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search,
                        color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search listings, categories, cities...',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Search',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 400.ms),
          ),
        ],
      ),
    );
  }

  // ── Stats ────────────────────────────────────────────────────────────
  Widget _buildStatsSection(WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final stats = homeState.stats;

    // Format numbers nicely
    String fmt(int n) {
      if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M+';
      if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K+';
      return n.toString();
    }

    final items = [
      {'value': fmt(stats.totalListings), 'label': 'Listings'},
      {'value': fmt(stats.totalUsers), 'label': 'Users'},
      {'value': fmt(stats.totalCities), 'label': 'Cities'},
      {
        'value': stats.avgRating > 0
            ? '${stats.avgRating.toStringAsFixed(1)}★'
            : '—',
        'label': 'Rating'
      },
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((s) {
          return Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppColors.primaryGradient
                    .createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                child: Text(
                  s['value']!,
                  style: GoogleFonts.syne(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s['label']!,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  // ── Categories ───────────────────────────────────────────────────────
  Widget _buildCategories(
      BuildContext context, List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('No categories',
              style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () => context.push('/browse?category=${cat.id}'),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        cat.icon ?? cat.name[0],
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.name,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 80 * index));
        },
      ),
    );
  }

  // ── Featured Listings ────────────────────────────────────────────────
  Widget _buildFeaturedListings(
    BuildContext context,
    WidgetRef ref,
    List<ListingModel> listings,
  ) {
    if (listings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No listings yet',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: listings.length,
        itemBuilder: (context, index) {
          final listing = listings[index];
          return SizedBox(
            width: 220,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ListingCard(
                listing: listing,
                onTap: () => context.push('/listing/${listing.id}'),
              ),
            ),
          );
        },
      ),
    );
  }

  // -- CTA --
  Widget _buildCtaSection(BuildContext context, WidgetRef ref) {
    // Everyone can list items -- no role restriction
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A2E), Color(0xFF0A1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonViolet.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeonGradientText(
            'List Your Item',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            gradient: const LinearGradient(
              colors: [AppColors.neonViolet, AppColors.neonPink],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Earn money by renting out your unused items to people nearby.',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryGlowButton(
            label: 'Create Listing',
            width: double.infinity,
            onPressed: () => context.push('/create-listing'),
            gradient: const LinearGradient(
              colors: [AppColors.neonViolet, AppColors.neonPink],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  // -- Shimmer placeholders ─────────────────────────────────────────────
  Widget _buildCategoryShimmer() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 6,
        itemBuilder: (_, __) => const CategoryCardShimmer(),
      ),
    );
  }

  Widget _buildListingsShimmer() {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        itemBuilder: (_, __) => const SizedBox(
          width: 220,
          child: Padding(
            padding: EdgeInsets.only(right: 16),
            child: ListingCardShimmer(),
          ),
        ),
      ),
    );
  }
}
