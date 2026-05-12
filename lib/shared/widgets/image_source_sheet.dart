import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';

/// Shows a bottom sheet to choose between Camera and Gallery.
/// Returns the picked file path, or null if cancelled.
Future<String?> pickImageWithSource(
  BuildContext context, {
  int imageQuality = 85,
  double maxWidth = 1024,
  double maxHeight = 1024,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ImageSourceSheet(),
  );

  if (source == null) return null;

  final picker = ImagePicker();
  final file = await picker.pickImage(
    source: source,
    imageQuality: imageQuality,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
  );

  return file?.path;
}

/// Same but picks multiple images (gallery only for multi-pick).
Future<List<String>> pickMultipleImages(
  BuildContext context, {
  int imageQuality = 85,
  double maxWidth = 1024,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ImageSourceSheet(allowMultiple: true),
  );

  if (source == null) return [];

  final picker = ImagePicker();

  if (source == ImageSource.camera) {
    // Camera only picks one at a time
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality,
      maxWidth: maxWidth,
    );
    return file != null ? [file.path] : [];
  } else {
    // Gallery — pick multiple
    final files = await picker.pickMultiImage(
      imageQuality: imageQuality,
      maxWidth: maxWidth,
    );
    return files.map((f) => f.path).toList();
  }
}

// ── Bottom sheet widget ───────────────────────────────────────────────────────
class _ImageSourceSheet extends StatelessWidget {
  final bool allowMultiple;

  const _ImageSourceSheet({this.allowMultiple = false});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Select Photo',
              style: GoogleFonts.syne(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                // Camera
                Expanded(
                  child: _SourceButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    color: AppColors.neonCyan,
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                // Gallery
                Expanded(
                  child: _SourceButton(
                    icon: Icons.photo_library_outlined,
                    label: allowMultiple ? 'Gallery\n(Multiple)' : 'Gallery',
                    color: AppColors.neonViolet,
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Cancel
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
