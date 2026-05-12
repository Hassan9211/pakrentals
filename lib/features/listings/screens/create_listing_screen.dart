import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/image_source_sheet.dart';
import '../../../shared/widgets/neon_gradient_text.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';
import '../models/category_model.dart';
import '../providers/listings_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CREATE LISTING SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1 — Basic info
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _selectedCategoryId;

  // Step 2 — Location & Price
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  // Step 3 — Photos
  final List<File> _photos = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ── Pick images — camera or gallery ───────────────────────────────────────
  Future<void> _pickImages() async {
    final paths = await pickMultipleImages(
      context,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (paths.isEmpty) return;
    setState(() {
      for (final path in paths) {
        if (_photos.length < 6) _photos.add(File(path));
      }
    });
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final user = ref.read(authProvider).user;
    final categories = ref.read(homeProvider).categories;
    final category = categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => categories.isNotEmpty
          ? categories.first
          : CategoryModel(id: 0, name: 'General'),
    );

    try {
      // 1. Upload images to Cloudinary if any
      List<String> imageUrls = [];
      if (_photos.isNotEmpty) {
        imageUrls = await CloudinaryService.uploadMultipleImages(_photos);
        if (imageUrls.length < _photos.length) {
          throw 'Failed to upload some images. Please check your internet.';
        }
      }

      // 2. Get host's Firebase UID directly from Firebase Auth
      final hostFirebaseUid = FirebaseAuth.instance.currentUser?.uid ?? '';

      // 3. Save listing to Firestore
      await FirebaseFirestore.instance.collection('listings').add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price_per_day': double.parse(_priceCtrl.text.trim()),
        'city': _cityCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'images': imageUrls,
        'status': 'active',
        'is_featured': false,
        'category_id': _selectedCategoryId?.toString(),
        'category_name': category.name,
        'category_icon': category.icon,
        'host_id': hostFirebaseUid,
        'host_email': user?.email ?? '',
        'host_name': user?.name ?? '',
        'avg_rating': 0.0,
        'reviews_count': 0,
        'created_at': FieldValue.serverTimestamp(),
      });

      ref.read(browseProvider.notifier).loadListings(refresh: true);
      setState(() => _isSubmitting = false);
      if (mounted) {
        showSnackBar(context, 'Listing created successfully! 🎉');
        context.go('/my-listings');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        showSnackBar(context, 'Failed to create listing: $e', isError: true);
      }
    }
  }

  // ── Step validation ────────────────────────────────────────────────────────
  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_titleCtrl.text.trim().isEmpty) {
          showSnackBar(context, 'Please enter a title', isError: true);
          return false;
        }
        if (_selectedCategoryId == null) {
          showSnackBar(context, 'Please select a category', isError: true);
          return false;
        }
        return true;
      case 1:
        if (_cityCtrl.text.trim().isEmpty) {
          showSnackBar(context, 'Please enter a city', isError: true);
          return false;
        }
        if (_priceCtrl.text.trim().isEmpty ||
            double.tryParse(_priceCtrl.text.trim()) == null) {
          showSnackBar(context, 'Please enter a valid price', isError: true);
          return false;
        }
        return true;
      case 2:
        return true;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Create Listing',
          style: GoogleFonts.syne(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          // ── Step indicator ───────────────────────────────────────────
          _StepIndicator(currentStep: _currentStep),

          // ── Step content ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: _buildStep(_currentStep),
                ),
              ),
            ),
          ),

          // ── Bottom navigation ─────────────────────────────────────────
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Steps ──────────────────────────────────────────────────────────────────
  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  // Step 1 — Basic Info
  Widget _buildStep1() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NeonGradientText('Basic Info',
            fontSize: 20, fontWeight: FontWeight.w700),
        const SizedBox(height: 4),
        const Text(
          'Tell renters what you\'re offering',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // Title
        TextFormField(
          controller: _titleCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Listing Title *',
            hintText: 'e.g. Toyota Corolla 2020 — Daily Rental',
            prefixIcon: Icon(Icons.title_outlined),
          ),
          maxLength: 80,
          textInputAction: TextInputAction.next,
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 14),

        // Description
        TextFormField(
          controller: _descCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe your item — condition, features, rules...',
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          maxLength: 500,
        ).animate().fadeIn(delay: 150.ms),

        const SizedBox(height: 14),

        // Category
        Text(
          'Category *',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ref.watch(homeProvider).categories.map((cat) {
            final isSelected = _selectedCategoryId == cat.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategoryId = cat.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  color: isSelected ? null : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat.icon ?? '', style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      cat.name,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  // Step 2 — Location & Price
  Widget _buildStep2() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NeonGradientText('Location & Price',
            fontSize: 20, fontWeight: FontWeight.w700),
        const SizedBox(height: 4),
        const Text(
          'Where is it and how much per day?',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // City
        TextFormField(
          controller: _cityCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'City *',
            hintText: 'e.g. Lahore, Karachi, Islamabad',
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
          textInputAction: TextInputAction.next,
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 14),

        // Address
        TextFormField(
          controller: _addressCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Area / Address',
            hintText: 'e.g. DHA Phase 5, Lahore',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          textInputAction: TextInputAction.next,
        ).animate().fadeIn(delay: 150.ms),

        const SizedBox(height: 14),

        // Price
        TextFormField(
          controller: _priceCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Price per Day (PKR) *',
            hintText: 'e.g. 2500',
            prefixIcon: Icon(Icons.payments_outlined),
            prefixText: 'PKR  ',
            prefixStyle: TextStyle(color: AppColors.neonCyan),
          ),
          textInputAction: TextInputAction.done,
        ).animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 20),

        // Price preview
        if (_priceCtrl.text.isNotEmpty &&
            double.tryParse(_priceCtrl.text) != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Weekly estimate',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                Text(
                  formatPrice(double.parse(_priceCtrl.text) * 7),
                  style: GoogleFonts.syne(
                    color: AppColors.neonCyan,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
      ],
    );
  }

  // Step 3 — Photos
  Widget _buildStep3() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NeonGradientText('Add Photos',
            fontSize: 20, fontWeight: FontWeight.w700),
        const SizedBox(height: 4),
        const Text(
          'Good photos get 3x more bookings',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // Photo grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _photos.length + (_photos.length < 6 ? 1 : 0),
          itemBuilder: (context, index) {
            // Add button
            if (index == _photos.length) {
              return GestureDetector(
                onTap: _pickImages,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.neonCyan.withValues(alpha: 0.4),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.neonCyan.withValues(alpha: 0.7),
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          color: AppColors.neonCyan.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            // Photo tile
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _photos[index],
                    fit: BoxFit.cover,
                  ),
                ),
                // Remove button
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _photos.removeAt(index)),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ),
                // Cover badge
                if (index == 0)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Cover',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ).animate().scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 200.ms,
                  curve: Curves.easeOut,
                );
          },
        ),

        const SizedBox(height: 16),

        if (_photos.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.textMuted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Photos are optional but highly recommended. You can add up to 6 photos.',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Bottom navigation bar ──────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final isLastStep = _currentStep == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Back button
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep--),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),

          // Next / Submit button
          Expanded(
            flex: 2,
            child: PrimaryGlowButton(
              label: isLastStep ? 'Publish Listing' : 'Continue',
              icon:
                  isLastStep ? Icons.check_circle_outline : Icons.arrow_forward,
              isLoading: _isSubmitting,
              onPressed: () {
                if (!_validateStep(_currentStep)) return;
                if (isLastStep) {
                  _submit();
                } else {
                  setState(() => _currentStep++);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step indicator widget ─────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Basic Info', 'Location & Price', 'Photos'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final label = entry.value;
          final isDone = i < currentStep;
          final isActive = i == currentStep;

          return Expanded(
            child: Row(
              children: [
                // Circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        isActive || isDone ? AppColors.primaryGradient : null,
                    color: isActive || isDone ? null : AppColors.surfaceVariant,
                    border: Border.all(
                      color: isActive || isDone
                          ? Colors.transparent
                          : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color:
                                  isActive ? Colors.white : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                // Label
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive
                          ? AppColors.textPrimary
                          : isDone
                              ? AppColors.neonCyan
                              : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Connector line
                if (i < steps.length - 1) ...[
                  const SizedBox(width: 4),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: isDone ? AppColors.primaryGradient : null,
                        color: isDone ? null : AppColors.border,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
