import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import '../../../shared/widgets/neon_gradient_text.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  bool _termsError = false; // shows red error if not agreed

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Validate form fields
    final formValid = _formKey.currentState!.validate();

    // Validate terms separately
    if (!_agreedToTerms) {
      setState(() => _termsError = true);
    }

    if (!formValid || !_agreedToTerms) return;

    final success = await ref.read(authProvider.notifier).register({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'password_confirmation': _confirmCtrl.text,
      'role': 'user',
    });

    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else {
      final error = ref.read(authProvider).error;
      showSnackBar(context, error ?? 'Registration failed', isError: true);
    }
  }

  void _showTermsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Terms & Conditions',
                    style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            // Content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  _termsSection(
                    '1. Acceptance of Terms',
                    'By creating an account on PakRentals, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use our platform.',
                  ),
                  _termsSection(
                    '2. User Accounts',
                    'You must provide accurate and complete information when creating your account. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.',
                  ),
                  _termsSection(
                    '3. Listings & Rentals',
                    'Hosts are responsible for the accuracy of their listings. All items listed must be legally owned by the host. Renters must use rented items responsibly and return them in the same condition.',
                  ),
                  _termsSection(
                    '4. Payments',
                    'All payments are processed securely through our platform. PakRentals charges a service fee on each transaction. Refunds are subject to our cancellation policy.',
                  ),
                  _termsSection(
                    '5. Prohibited Activities',
                    'Users may not list illegal items, engage in fraudulent activity, harass other users, or misuse the platform in any way. Violations may result in account suspension.',
                  ),
                  _termsSection(
                    '6. Liability',
                    'PakRentals acts as a marketplace and is not responsible for the condition of listed items or disputes between users. We encourage users to verify items before completing transactions.',
                  ),
                  _termsSection(
                    '7. Privacy',
                    'Your personal information is collected and used in accordance with our Privacy Policy. We do not sell your data to third parties.',
                  ),
                  _termsSection(
                    '8. CNIC Verification',
                    'For security purposes, hosts may be required to verify their identity via CNIC. This information is stored securely and used only for verification purposes.',
                  ),
                  _termsSection(
                    '9. Dispute Resolution',
                    'In case of disputes, users should first attempt to resolve issues directly. PakRentals provides a dispute resolution mechanism through the Reports section.',
                  ),
                  _termsSection(
                    '10. Changes to Terms',
                    'PakRentals reserves the right to modify these terms at any time. Continued use of the platform after changes constitutes acceptance of the new terms.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: May 2025',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 20),
                  // Agree button inside sheet
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _agreedToTerms = true;
                        _termsError = false;
                      });
                      Navigator.pop(context);
                      showSnackBar(context, 'Terms accepted ✓');
                    },
                    child: const Text('I Agree to Terms & Conditions'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _termsSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.syne(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),

                // ── Logo ──────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonCyan.withOpacity(0.3),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.home_work_outlined,
                            color: Colors.white, size: 30),
                      ).animate().scale(
                            begin: const Offset(0.5, 0.5),
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: 12),
                      NeonGradientText('PakRentals',
                              fontSize: 28, fontWeight: FontWeight.w800)
                          .animate()
                          .fadeIn(delay: 200.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'Create Account',
                  style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.15),
                const SizedBox(height: 4),
                Text(
                  "Join Pakistan's rental community",
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textMuted, fontSize: 13),
                ).animate().fadeIn(delay: 380.ms),

                const SizedBox(height: 24),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Full Name
                      TextFormField(
                        controller: _nameCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outlined),
                        ),
                        validator: (v) => Validators.required(v, 'Name'),
                        textInputAction: TextInputAction.next,
                      ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.12),

                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: Validators.email,
                        textInputAction: TextInputAction.next,
                      ).animate().fadeIn(delay: 470.ms).slideY(begin: 0.12),

                      const SizedBox(height: 12),

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
                        validator: Validators.phone,
                        textInputAction: TextInputAction.next,
                      ).animate().fadeIn(delay: 520.ms).slideY(begin: 0.12),

                      const SizedBox(height: 12),

                      // Password
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: Validators.password,
                        textInputAction: TextInputAction.next,
                      ).animate().fadeIn(delay: 570.ms).slideY(begin: 0.12),

                      const SizedBox(height: 12),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureConfirm,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        validator: (v) =>
                            Validators.confirmPassword(v, _passwordCtrl.text),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                      ).animate().fadeIn(delay: 620.ms).slideY(begin: 0.12),

                      const SizedBox(height: 20),

                      // ── Terms & Conditions checkbox ────────────────
                      _buildTermsCheckbox(),

                      const SizedBox(height: 20),

                      // ── Info note ─────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.neonCyan.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppColors.neonCyan, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You can list items and book items with one account. Enter Host Code in profile to unlock host features.',
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 680.ms),

                      const SizedBox(height: 20),

                      PrimaryGlowButton(
                        label: 'Create Account',
                        onPressed: _register,
                        isLoading: isLoading,
                        width: double.infinity,
                        icon: Icons.person_add_outlined,
                      ).animate().fadeIn(delay: 720.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Already have an account?  ',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textMuted, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.neonCyan,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 760.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Terms & Conditions checkbox ──────────────────────────────────────────
  Widget _buildTermsCheckbox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _agreedToTerms = !_agreedToTerms;
              if (_agreedToTerms) _termsError = false;
            });
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Animated checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: _agreedToTerms ? AppColors.primaryGradient : null,
                  color: _agreedToTerms ? null : Colors.transparent,
                  border: Border.all(
                    color: _termsError
                        ? AppColors.error
                        : _agreedToTerms
                            ? Colors.transparent
                            : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: _agreedToTerms
                    ? const Icon(Icons.check,
                        color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 10),
              // Text with tappable links
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'I have read and agree to the '),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.neonCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.neonCyan,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = _showTermsDialog,
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.neonCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.neonCyan,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = _showTermsDialog,
                      ),
                      const TextSpan(text: ' of PakRentals.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Error message ──────────────────────────────────────────
        if (_termsError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 32),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 14),
                const SizedBox(width: 5),
                Text(
                  'You must agree to the Terms & Conditions',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.error,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.2),
      ],
    ).animate().fadeIn(delay: 650.ms);
  }
}
