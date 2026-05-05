import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import '../../auth/providers/auth_provider.dart';

class CnicScreen extends ConsumerStatefulWidget {
  const CnicScreen({super.key});

  @override
  ConsumerState<CnicScreen> createState() => _CnicScreenState();
}

class _CnicScreenState extends ConsumerState<CnicScreen> {
  final _cnicCtrl = TextEditingController();
  File? _frontPhoto;
  File? _backPhoto;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if already submitted
    final user = ref.read(authProvider).user;
    if (user?.cnic != null) {
      _cnicCtrl.text = user!.cnic!;
    }
  }

  @override
  void dispose() {
    _cnicCtrl.dispose();
    super.dispose();
  }

  // ── Pick photo ─────────────────────────────────────────────────────────────
  Future<void> _pickPhoto(bool isFront) async {
    final picker = ImagePicker();
    final source = await _showSourceDialog();
    if (source == null) return;

    final file = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null) return;

    setState(() {
      if (isFront) {
        _frontPhoto = File(file.path);
      } else {
        _backPhoto = File(file.path);
      }
    });
  }

  Future<ImageSource?> _showSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.neonCyan),
              title: const Text('Take Photo',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.neonCyan),
              title: const Text('Choose from Gallery',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Validate CNIC format ───────────────────────────────────────────────────
  bool _isValidCnic(String value) {
    // Pakistani CNIC: XXXXX-XXXXXXX-X (13 digits)
    final clean = value.replaceAll('-', '');
    return clean.length == 13 && RegExp(r'^\d+$').hasMatch(clean);
  }

  String _formatCnic(String value) {
    final digits = value.replaceAll('-', '').replaceAll(' ', '');
    if (digits.length <= 5) return digits;
    if (digits.length <= 12) {
      return '${digits.substring(0, 5)}-${digits.substring(5)}';
    }
    return '${digits.substring(0, 5)}-${digits.substring(5, 12)}-${digits.substring(12)}';
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final cnic = _cnicCtrl.text.trim();

    if (!_isValidCnic(cnic)) {
      showSnackBar(context, 'Enter a valid CNIC (e.g. 35202-1234567-1)',
          isError: true);
      return;
    }
    if (_frontPhoto == null) {
      showSnackBar(context, 'Please upload front side of CNIC', isError: true);
      return;
    }
    if (_backPhoto == null) {
      showSnackBar(context, 'Please upload back side of CNIC', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await ref.read(authProvider.notifier).updateCnic(
          cnicNumber: cnic,
          frontPhotoPath: _frontPhoto!.path,
          backPhotoPath: _backPhoto!.path,
        );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.5), width: 2),
              ),
              child: const Icon(Icons.hourglass_empty_outlined,
                  color: AppColors.warning, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Submitted for Review',
              style: GoogleFonts.syne(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your CNIC has been submitted. Our team will verify it within 24-48 hours.',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  context.pop();
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final status = user?.cnicStatus ?? 'none';

    return Scaffold(
      appBar: AppBar(
        title: Text('CNIC Verification',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status banner ──────────────────────────────────────────
            _buildStatusBanner(status),

            const SizedBox(height: 24),

            // ── Why verify section ─────────────────────────────────────
            if (status == 'none') ...[
              _buildWhyVerify(),
              const SizedBox(height: 24),
            ],

            // ── Form (only if not verified) ────────────────────────────
            if (status != 'verified') ...[
              // CNIC number
              Text(
                'CNIC Number',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cnicCtrl,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    letterSpacing: 1.5),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13),
                  _CnicFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: '35202-1234567-1',
                  hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      letterSpacing: 1),
                  prefixIcon: const Icon(Icons.credit_card_outlined),
                  suffixIcon: _isValidCnic(_cnicCtrl.text)
                      ? const Icon(Icons.check_circle,
                          color: AppColors.neonGreen)
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              // ── Photo uploads ────────────────────────────────────────
              Text(
                'Upload CNIC Photos',
                style: GoogleFonts.syne(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Take clear photos of both sides. Make sure all text is readable.',
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _PhotoUploadCard(
                      label: 'Front Side',
                      icon: Icons.person_outlined,
                      hint: 'Photo & name side',
                      file: _frontPhoto,
                      existingPath:
                          status != 'none' ? user?.cnicFrontPhoto : null,
                      onTap: () => _pickPhoto(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PhotoUploadCard(
                      label: 'Back Side',
                      icon: Icons.home_outlined,
                      hint: 'Address side',
                      file: _backPhoto,
                      existingPath:
                          status != 'none' ? user?.cnicBackPhoto : null,
                      onTap: () => _pickPhoto(false),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              // ── Guidelines ───────────────────────────────────────────
              _buildGuidelines(),

              const SizedBox(height: 28),

              // ── Submit button ────────────────────────────────────────
              PrimaryGlowButton(
                label: status == 'pending'
                    ? 'Resubmit CNIC'
                    : 'Submit for Verification',
                width: double.infinity,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),
            ],

            // ── Verified state ─────────────────────────────────────────
            if (status == 'verified') ...[
              _buildVerifiedCard(user),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  // ── Status banner ──────────────────────────────────────────────────────────
  Widget _buildStatusBanner(String status) {
    final configs = {
      'none': (
        color: AppColors.textMuted,
        bg: AppColors.surfaceVariant,
        icon: Icons.shield_outlined,
        title: 'Not Verified',
        subtitle: 'Submit your CNIC to get verified',
      ),
      'pending': (
        color: AppColors.warning,
        bg: AppColors.warning,
        icon: Icons.hourglass_empty_outlined,
        title: 'Under Review',
        subtitle: 'Your CNIC is being verified (24-48 hrs)',
      ),
      'verified': (
        color: AppColors.neonGreen,
        bg: AppColors.neonGreen,
        icon: Icons.verified_user_outlined,
        title: 'Verified ✓',
        subtitle: 'Your identity has been confirmed',
      ),
      'rejected': (
        color: AppColors.error,
        bg: AppColors.error,
        icon: Icons.cancel_outlined,
        title: 'Verification Failed',
        subtitle: 'Please resubmit with clearer photos',
      ),
    };

    final cfg = configs[status] ?? configs['none']!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cfg.bg.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cfg.color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cfg.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(cfg.icon, color: cfg.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cfg.title,
                  style: GoogleFonts.syne(
                    color: cfg.color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  cfg.subtitle,
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ── Why verify ─────────────────────────────────────────────────────────────
  Widget _buildWhyVerify() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why verify your CNIC?',
            style: GoogleFonts.syne(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...[
            (
              Icons.verified_user_outlined,
              AppColors.neonCyan,
              'Build trust with hosts and renters'
            ),
            (
              Icons.lock_outlined,
              AppColors.neonViolet,
              'Access premium listings'
            ),
            (
              Icons.star_outline,
              AppColors.neonPink,
              'Get a verified badge on your profile'
            ),
            (
              Icons.security_outlined,
              AppColors.neonGreen,
              'Secure the community for everyone'
            ),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(item.$1, color: item.$2, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    item.$3,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Photo guidelines ───────────────────────────────────────────────────────
  Widget _buildGuidelines() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.neonCyan.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonCyan.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.neonCyan, size: 16),
              const SizedBox(width: 8),
              Text(
                'Photo Guidelines',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.neonCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...[
            '✓  All 4 corners of the CNIC must be visible',
            '✓  Text must be clear and readable',
            '✓  No glare or shadows on the card',
            '✓  Original CNIC only — no photocopies',
          ].map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                tip,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Verified card ──────────────────────────────────────────────────────────
  Widget _buildVerifiedCard(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2E1A), Color(0xFF0A1A0A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_user, color: AppColors.neonGreen, size: 48),
          const SizedBox(height: 12),
          Text(
            'Identity Verified',
            style: GoogleFonts.syne(
              color: AppColors.neonGreen,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'CNIC: ${user?.cnic ?? ''}',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textSecondary,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.neonGreen, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Verified by PakRentals',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.neonGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo upload card widget ──────────────────────────────────────────────────
class _PhotoUploadCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String hint;
  final File? file;
  final String? existingPath;
  final VoidCallback onTap;

  const _PhotoUploadCard({
    required this.label,
    required this.icon,
    required this.hint,
    required this.onTap,
    this.file,
    this.existingPath,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        file != null || (existingPath != null && existingPath!.isNotEmpty);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 140,
        decoration: BoxDecoration(
          color: hasPhoto
              ? AppColors.neonCyan.withOpacity(0.05)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasPhoto
                ? AppColors.neonCyan.withOpacity(0.5)
                : AppColors.border,
            width: hasPhoto ? 1.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: hasPhoto
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    // Show photo
                    file != null
                        ? Image.file(file!, fit: BoxFit.cover)
                        : (existingPath!.startsWith('http')
                            ? Image.network(existingPath!, fit: BoxFit.cover)
                            : Image.file(File(existingPath!),
                                fit: BoxFit.cover)),
                    // Overlay with label
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 8),
                        color: AppColors.background.withOpacity(0.75),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.neonCyan, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: const TextStyle(
                                color: AppColors.neonCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Tap to change
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.background.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            color: AppColors.neonCyan, size: 12),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: AppColors.textMuted, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.neonCyan.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Tap to upload',
                        style:
                            TextStyle(color: AppColors.neonCyan, fontSize: 10),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── CNIC auto-formatter ───────────────────────────────────────────────────────
class _CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('-', '');
    if (digits.length > 13) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) buffer.write('-');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
