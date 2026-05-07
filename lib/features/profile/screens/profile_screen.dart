import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/image_source_sheet.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editMode = false;

  // Edit controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _bioCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _cityCtrl = TextEditingController(text: user?.city ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_editMode) {
      // Cancel — restore original values
      final user = ref.read(authProvider).user;
      _nameCtrl.text = user?.name ?? '';
      _phoneCtrl.text = user?.phone ?? '';
      _cityCtrl.text = user?.city ?? '';
      _bioCtrl.text = user?.bio ?? '';
    }
    setState(() => _editMode = !_editMode);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).updateProfile({
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
    });

    if (!mounted) return;

    if (success) {
      setState(() => _editMode = false);
      showSnackBar(context, 'Profile updated! ✓');
    } else {
      showSnackBar(context, 'Failed to update profile', isError: true);
    }
  }

  Future<void> _pickPhoto() async {
    final path = await pickImageWithSource(
      context,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (path == null) return;
    await ref.read(authProvider.notifier).updatePhoto(path);
    if (mounted) showSnackBar(context, 'Photo updated!');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isLoading = authState.isLoading;

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
              Text('Sign in to view your profile',
                  style: GoogleFonts.syne(
                      color: AppColors.textMuted, fontSize: 16)),
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
          // ── AppBar ────────────────────────────────────────────────────
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
                      // Avatar
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: Stack(
                          children: [
                            _buildAvatar(user.photo, user.name),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppColors.neonCyan,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.background, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Name — editable inline
                      _editMode
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: TextField(
                                controller: _nameCtrl,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.syne(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColors.neonCyan),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColors.neonCyan, width: 2),
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              user.name,
                              style: GoogleFonts.syne(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                      const SizedBox(height: 3),
                      Text(user.email,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),
                      if (!_editMode &&
                          user.phone != null &&
                          user.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(user.phone!,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // Edit / Cancel toggle
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _editMode
                    ? Row(
                        key: const ValueKey('edit_actions'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: _toggleEdit,
                            child: const Text('Cancel',
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13)),
                          ),
                          TextButton(
                            onPressed: isLoading ? null : _saveProfile,
                            child: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.neonCyan),
                                  )
                                : const Text('Save',
                                    style: TextStyle(
                                        color: AppColors.neonCyan,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                          ),
                        ],
                      )
                    : IconButton(
                        key: const ValueKey('edit_icon'),
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: _toggleEdit,
                        tooltip: 'Edit Profile',
                      ),
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
                  // Role badge
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
                        const Text('Verified',
                            style: TextStyle(
                                color: AppColors.neonCyan, fontSize: 12)),
                      ],
                    ],
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 20),

                  // ── Inline edit form ─────────────────────────────────
                  if (_editMode) ...[
                    _buildEditForm(),
                    const SizedBox(height: 20),
                  ] else ...[
                    // Bio display
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      Text(
                        user.bio!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 250.ms),
                      const SizedBox(height: 20),
                    ],
                  ],

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

  // ── Inline edit form ───────────────────────────────────────────────────────
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profile',
            style: GoogleFonts.syne(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),

          // Phone
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: '03XX-XXXXXXX',
            ),
          ),
          const SizedBox(height: 12),

          // City
          TextFormField(
            controller: _cityCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 12),

          // Bio
          TextFormField(
            controller: _bioCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio',
              hintText: 'Tell others about yourself...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // Save button
          PrimaryGlowButton(
            label: 'Save Changes',
            width: double.infinity,
            isLoading: ref.watch(authProvider).isLoading,
            onPressed: _saveProfile,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.05);
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────
  Widget _buildAvatar(String? photoPath, String name) {
    final hasPhoto = photoPath != null && photoPath.isNotEmpty;
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasPhoto ? null : AppColors.primaryGradient,
        border: Border.all(
            color: AppColors.neonCyan.withOpacity(0.4), width: 2),
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

  Widget _buildPhotoWidget(String path) {
    if (path.startsWith('http')) {
      return Image.network(path,
          fit: BoxFit.cover,
          width: 84,
          height: 84,
          errorBuilder: (_, __, ___) => _initialsPlaceholder());
    }
    return Image.file(File(path),
        fit: BoxFit.cover,
        width: 84,
        height: 84,
        errorBuilder: (_, __, ___) => _initialsPlaceholder());
  }

  Widget _initialsPlaceholder() => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
            child: Icon(Icons.person, color: AppColors.textMuted, size: 36)),
      );

  // ── Menu ───────────────────────────────────────────────────────────────────
  Widget _buildMenuSection(
      BuildContext context, WidgetRef ref, bool isAdmin) {
    final user = ref.read(authProvider).user!;
    final wishlistCount =
        ref.watch(wishlistProvider.select((s) => s.savedIds.length));

    Widget cnicBadge() {
      switch (user.cnicStatus) {
        case 'verified':
          return const Icon(Icons.verified,
              color: AppColors.neonGreen, size: 16);
        case 'pending':
          return _badge('Pending', AppColors.warning);
        case 'rejected':
          return _badge('Rejected', AppColors.error);
        default:
          return _badge('Verify', AppColors.textMuted,
              bg: AppColors.surfaceVariant);
      }
    }

    final items = [
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
            ? _badge('${user.paymentMethods.length}', AppColors.neonCyan)
            : null,
      ),
      _MenuItem(
        icon: Icons.calendar_today_outlined,
        label: 'My Bookings',
        onTap: () => context.push('/bookings'),
      ),
      _MenuItem(
        icon: Icons.home_outlined,
        label: 'My Listings',
        onTap: () => context.push('/my-listings'),
      ),
      _MenuItem(
        icon: Icons.favorite_outlined,
        label: 'My Favourites',
        onTap: () => context.push('/wishlist'),
        color: AppColors.neonPink,
        trailing: wishlistCount > 0
            ? _badge('$wishlistCount', AppColors.neonPink)
            : null,
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
                leading: Icon(item.icon,
                    color: item.color ?? AppColors.textSecondary, size: 20),
                title: Text(item.label,
                    style: TextStyle(
                        color: item.color ?? AppColors.textPrimary,
                        fontSize: 14)),
                trailing: item.trailing ??
                    const Icon(Icons.chevron_right,
                        color: AppColors.textMuted, size: 18),
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

  // ── Badge helper ───────────────────────────────────────────────────────────
  Widget _badge(String text, Color color, {Color? bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg ?? color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out',
            style: GoogleFonts.syne(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed != true) return;
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
