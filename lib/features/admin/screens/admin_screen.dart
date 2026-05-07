import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neon_gradient_text.dart';

// ── Firestore-backed admin stats ──────────────────────────────────────────────
final adminStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final db = FirebaseFirestore.instance;

  try {
    // Use get() instead of count() — more compatible with Firestore rules
    final results = await Future.wait([
      db.collection('users').get().timeout(const Duration(seconds: 10)),
      db.collection('listings').where('status', isEqualTo: 'active').get().timeout(const Duration(seconds: 10)),
      db.collection('bookings').get().timeout(const Duration(seconds: 10)),
      db.collection('reports').get().timeout(const Duration(seconds: 10)),
    ]);

    final usersSnap = results[0] as QuerySnapshot;
    final listingsSnap = results[1] as QuerySnapshot;
    final bookingsSnap = results[2] as QuerySnapshot;
    final reportsSnap = results[3] as QuerySnapshot;

    // Count open reports
    final openReports = reportsSnap.docs
        .where((d) => (d.data() as Map)['status'] == 'open')
        .length;

    // Calculate revenue from paid bookings
    double revenue = 0;
    for (final doc in bookingsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] == 'paid' || data['payment_status'] == 'paid') {
        revenue += (data['total_price'] as num?)?.toDouble() ?? 0;
      }
    }

    return {
      'total_users': usersSnap.docs.length,
      'active_listings': listingsSnap.docs.length,
      'total_bookings': bookingsSnap.docs.length,
      'pending_reports': openReports,
      'total_revenue': revenue,
    };
  } catch (e) {
    // Re-throw so FutureProvider shows error state instead of silent zeros
    throw Exception('Failed to load stats: $e');
  }
});

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(adminStatsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminStatsProvider),
        color: AppColors.neonCyan,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeonGradientText('Overview',
                  fontSize: 22, fontWeight: FontWeight.w700),
              const SizedBox(height: 16),

              statsAsync.when(
                loading: () => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(label: 'Total Users', value: '...', icon: Icons.people_outlined, color: AppColors.neonCyan),
                    _StatCard(label: 'Active Listings', value: '...', icon: Icons.home_outlined, color: AppColors.neonViolet),
                    _StatCard(label: 'Total Bookings', value: '...', icon: Icons.calendar_today_outlined, color: AppColors.neonPink),
                    _StatCard(label: 'Revenue', value: '...', icon: Icons.payments_outlined, color: AppColors.neonGreen),
                  ],
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(height: 8),
                      Text('$e', style: const TextStyle(color: AppColors.error, fontSize: 12)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(adminStatsProvider),
                        child: const Text('Retry', style: TextStyle(color: AppColors.neonCyan)),
                      ),
                    ],
                  ),
                ),
                data: (stats) => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      label: 'Total Users',
                      value: '${stats['total_users'] ?? 0}',
                      icon: Icons.people_outlined,
                      color: AppColors.neonCyan,
                    ),
                    _StatCard(
                      label: 'Active Listings',
                      value: '${stats['active_listings'] ?? 0}',
                      icon: Icons.home_outlined,
                      color: AppColors.neonViolet,
                    ),
                    _StatCard(
                      label: 'Total Bookings',
                      value: '${stats['total_bookings'] ?? 0}',
                      icon: Icons.calendar_today_outlined,
                      color: AppColors.neonPink,
                    ),
                    _StatCard(
                      label: 'Revenue',
                      value: formatPrice(stats['total_revenue'] ?? 0),
                      icon: Icons.payments_outlined,
                      color: AppColors.neonGreen,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text('Management',
                  style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _AdminMenuItem(
                      icon: Icons.people_outlined,
                      label: 'Users',
                      onTap: () {},
                    ),
                    const Divider(
                        color: AppColors.border, height: 1, indent: 56),
                    _AdminMenuItem(
                      icon: Icons.home_outlined,
                      label: 'Listings',
                      onTap: () {},
                    ),
                    const Divider(
                        color: AppColors.border, height: 1, indent: 56),
                    _AdminMenuItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Bookings',
                      onTap: () {},
                    ),
                    const Divider(
                        color: AppColors.border, height: 1, indent: 56),
                    _AdminMenuItem(
                      icon: Icons.flag_outlined,
                      label: 'Reports',
                      badgeColor: AppColors.error,
                      onTap: () {},
                    ),
                    const Divider(
                        color: AppColors.border, height: 1, indent: 56),
                    _AdminMenuItem(
                      icon: Icons.payments_outlined,
                      label: 'Payouts',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.syne(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? badgeColor;

  const _AdminMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right,
          color: AppColors.textMuted, size: 18),
      onTap: onTap,
    );
  }
}
