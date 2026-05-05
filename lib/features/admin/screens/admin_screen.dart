import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neon_gradient_text.dart';

// Mock provider — no API call
final adminStatsProvider =
    Provider<Map<String, dynamic>>((ref) => mockAdminStats);

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NeonGradientText('Overview',
                fontSize: 22, fontWeight: FontWeight.w700),
            const SizedBox(height: 16),

            // Stats grid
            GridView.count(
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
                  label: 'Total Listings',
                  value: '${stats['total_listings'] ?? 0}',
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

            const SizedBox(height: 24),

            Text(
              'Management',
              style: GoogleFonts.syne(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _AdminMenuItem(
                    icon: Icons.people_outlined,
                    label: 'Users',
                    badge: '${stats['total_users'] ?? 0}',
                    onTap: () {},
                  ),
                  const Divider(color: AppColors.border, height: 1, indent: 56),
                  _AdminMenuItem(
                    icon: Icons.home_outlined,
                    label: 'Listings Moderation',
                    badge: '${stats['active_listings'] ?? 0}',
                    onTap: () {},
                  ),
                  const Divider(color: AppColors.border, height: 1, indent: 56),
                  _AdminMenuItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Bookings',
                    badge: '${stats['total_bookings'] ?? 0}',
                    onTap: () {},
                  ),
                  const Divider(color: AppColors.border, height: 1, indent: 56),
                  _AdminMenuItem(
                    icon: Icons.flag_outlined,
                    label: 'Reports',
                    badge: '${stats['pending_reports'] ?? 0}',
                    badgeColor: AppColors.error,
                    onTap: () {},
                  ),
                  const Divider(color: AppColors.border, height: 1, indent: 56),
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
              Text(
                value,
                style: GoogleFonts.syne(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
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
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(
        label,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.neonCyan).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (badgeColor ?? AppColors.neonCyan).withOpacity(0.4),
                ),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  color: badgeColor ?? AppColors.neonCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }
}
