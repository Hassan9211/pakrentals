import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // ── Not logged in ──────────────────────────────────────────────────────
    if (!authState.isAuthenticated || user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline,
                  color: AppColors.textMuted, size: 64),
              const SizedBox(height: 16),
              Text(
                'Sign in to view your profile',
                style: GoogleFonts.syne(
                    color: AppColors.textMuted, fontSize: 16),
              ),
              const SizedBox(height: 24),
              PrimaryGlowButton(
                label: 'Sign In',
                onPressed: () => context.push('/login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A0A2E), Color(0xFF0A0A0F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                      // ── Avatar ─────────────────────────────────────
                      GestureDetector(
                        onTap: () => _pickPhoto(context, ref),
                        child: Stack(
                          children: [
                            // Photo or initials
                            _buildAvatar(user.photo, user.name),
                            // Camera badge
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppColors.neonCyan,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.background,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Name ───────────────────────────────────────
                      Text(
                        user.name,
                        style: GoogleFonts.syne(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      // ── Email — always shows the real registered email
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),

                      // ── Phone (if available) ───────────────────────
                      if (user.phone != null && user.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.phone!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/profile/edit'),
              ),
            ],
          ),

          // ── Body ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Role + verified badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.verified,
                            color: AppColors.neonCyan, size: 18),
                        const SizedBox(width: 4),
                        const Text(
                          'Verified',
                          style: TextStyle(
                              color: AppColors.neonCyan, fontSize: 12),
                        ),
                      ],
                    ],
                  ).animate().fadeIn(delay: 200.ms),

                  // Bio
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      user.bio!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 250.ms),
                  ],

                  const SizedBox(height: 24),

                  // Menu
                  _buildMenuSection(context, ref, user.isAdmin),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar widget — shows photo if available, else gradient initials ───────
  Widget _buildAvatar(String? photoPath, String name) {
    final bool hasPhoto =
        photoPath != null && photoPath.isNotEmpty;

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto ? null : AppColors.primaryGradient,
        border: Border.all(
          color: AppColors.neonCyan.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withOpacity(0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: hasPhoto
            ? _buildPhotoWidget(photoPath)
            : Center(
                child: Text(
                  getInitials(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }

  // Handles both local file paths and network URLs
  Widget _buildPhotoWidget(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: 84,
        height: 84,
        errorBuilder: (_, __, ___) => _initialsPlaceholder(),
      );
    }
    // Local file from image picker
    final file = File(path);
    return Image.file(
      file,
      fit: BoxFit.cover,
      width: 84,
      height: 84,
      errorBuilder: (_, __, ___) => _initialsPlaceholder(),
    );
  }

  Widget _initialsPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.person, color: AppColors.textMuted, size: 36),
      ),
    );
  }

  // ── Menu ──────────────────────────────────────────────────────────────────
  Widget _buildMenuSection(
      BuildContext context, WidgetRef ref, bool isAdmin) {
    final user = ref.read(authProvider).user!;
    final isHost = user.isHost;

    // CNIC status badge helper
    Widget cnicBadge() {
      switch (user.cnicStatus) {
        case 'verified':
          return const Icon(Icons.verified, color: AppColors.neonGreen, size: 16);
        case 'pending':
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.warning.withOpacity(0.4)),
            ),
            child: const Text('Pending',
                style: TextStyle(color: AppColors.warning, fontSize: 10)),
          );
        case 'rejected':
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.error.withOpacity(0.4)),
            ),
            child: const Text('Rejected',
                style: TextStyle(color: AppColors.error, fontSize: 10)),
          );
        default:
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text('Verify',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
          );
      }
    }

    final items = [
      _MenuItem(
        icon: Icons.person_outlined,
        label: 'Edit Profile',
        onTap: () => context.push('/profile/edit'),
      ),
      _MenuItem(
        icon: Icons.credit_card_outlined,
        label: 'CNIC & Verification',
        onTap: () => context.push('/profile/cnic'),
        trailing: cnicBadge(),
      ),
      _MenuItem(
        icon: Icons.payment_outlined,
        label: 'Payment Methods',
        onTap: () => context.push('/profile/payment-methods'),
        trailing: user.paymentMethods.isNotEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.neonCyan.withOpacity(0.3)),
                ),
                child: Text(
                  '${user.paymentMethods.length}',
                  style: const TextStyle(
                      color: AppColors.neonCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              )
            : null,
      ),
      // My Bookings — for renters
      if (!isHost)
        _MenuItem(
          icon: Icons.calendar_today_outlined,
          label: 'My Bookings',
          onTap: () => context.push('/bookings'),
        ),
      // My Listings — only for hosts
      if (isHost)
        _MenuItem(
          icon: Icons.home_outlined,
          label: 'My Listings',
          onTap: () => context.push('/my-listings'),
        ),
      // Booking Requests — only for hosts
      if (isHost)
        _MenuItem(
          icon: Icons.calendar_today_outlined,
          label: 'Booking Requests',
          onTap: () => context.push('/bookings'),
        ),
      _MenuItem(
        icon: Icons.favorite_border,
        label: 'Wishlist',
        onTap: () => context.push('/wishlist'),
      ),
      _MenuItem(
        icon: Icons.flag_outlined,
        label: 'Reports & Disputes',
        onTap: () => context.push('/reports'),
      ),
      _MenuItem(
        icon: Icons.privacy_tip_outlined,
        label: 'Privacy Policy',
        onTap: () {},
      ),
      if (isAdmin)
        _MenuItem(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Admin Dashboard',
          onTap: () => context.push('/admin'),
          color: AppColors.neonViolet,
        ),
      _MenuItem(
        icon: Icons.logout,
        label: 'Sign Out',
        onTap: () => _confirmLogout(context, ref),
        color: AppColors.error,
      ),
    ];

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  item.icon,
                  color: item.color ?? AppColors.textSecondary,
                  size: 20,
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    color: item.color ?? AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                trailing: item.trailing ??
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                onTap: item.onTap,
              ),
              if (i < items.length - 1)
                const Divider(
                    color: AppColors.border, height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  // ── Photo picker ──────────────────────────────────────────────────────────
  Future<void> _pickPhoto(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file == null) return;

    // Save the local file path into auth state so it persists
    await ref.read(authProvider.notifier).updatePhoto(file.path);

    if (context.mounted) {
      showSnackBar(context, 'Profile photo updated!');
    }
  }

  // ── Logout confirm ────────────────────────────────────────────────────────
  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.syne(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true) return;
      // Logout first, then navigate — using the outer context
      ref.read(authProvider.notifier).logout().then((_) {
        if (context.mounted) context.go('/login');
      });
    });
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Widget? trailing;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.trailing,
  });
}
