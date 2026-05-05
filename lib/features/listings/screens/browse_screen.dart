import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/listing_card.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../providers/listings_provider.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  final int? initialCategoryId;

  const BrowseScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _sortBy = 'latest';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    if (widget.initialCategoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(browseProvider.notifier).applyFilters({
          'category_id': widget.initialCategoryId,
        });
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(browseProvider.notifier).loadListings();
    }
  }

  void _search() {
    ref.read(browseProvider.notifier).search(_searchCtrl.text.trim());
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        onApply: (filters) {
          ref.read(browseProvider.notifier).applyFilters(filters);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(browseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Browse',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search listings...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _search();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (_) => _search(),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _search,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Sort chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children:
                  ['latest', 'price_asc', 'price_desc', 'rating'].map((s) {
                final labels = {
                  'latest': 'Latest',
                  'price_asc': 'Price ↑',
                  'price_desc': 'Price ↓',
                  'rating': 'Top Rated',
                };
                final isSelected = _sortBy == s;
                return GestureDetector(
                  onTap: () {
                    setState(() => _sortBy = s);
                    ref.read(browseProvider.notifier).applyFilters({
                      ...ref.read(browseProvider).filters,
                      'sort': s,
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: isSelected ? null : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected ? Colors.transparent : AppColors.border,
                      ),
                    ),
                    child: Text(
                      labels[s]!,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${state.listings.length} listings found',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Grid
          Expanded(
            child: state.isLoading && state.listings.isEmpty
                ? GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: 6,
                    itemBuilder: (_, __) => const ListingCardShimmer(),
                  )
                : state.listings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                color: AppColors.textMuted, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'No listings found',
                              style: GoogleFonts.syne(
                                color: AppColors.textMuted,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount:
                            state.listings.length + (state.isLoading ? 2 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.listings.length) {
                            return const ListingCardShimmer();
                          }
                          final listing = state.listings[index];
                          return ListingCard(
                            listing: listing,
                            onTap: () => context.push('/listing/${listing.id}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onApply;

  const _FilterSheet({required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: GoogleFonts.syne(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cityCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration:
                      const InputDecoration(labelText: 'Min Price (PKR)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxPriceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration:
                      const InputDecoration(labelText: 'Max Price (PKR)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final filters = <String, dynamic>{};
                if (_cityCtrl.text.isNotEmpty) filters['city'] = _cityCtrl.text;
                if (_minPriceCtrl.text.isNotEmpty) {
                  filters['min_price'] = _minPriceCtrl.text;
                }
                if (_maxPriceCtrl.text.isNotEmpty) {
                  filters['max_price'] = _maxPriceCtrl.text;
                }
                widget.onApply(filters);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
