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
  String _role = 'user';

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
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'password': _passwordCtrl.text,
      'password_confirmation': _confirmCtrl.text,
      'role': _role,
    });

    if (!mounted) return;

    if (success) {
      // Router's refreshListenable auto-redirects, but we also push explicitly.
      context.go('/home');
    } else {
      final error = ref.read(authProvider).error;
      showSnackBar(context, error ?? 'Registration failed', isError: true);
    }
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
                        child: const Icon(
                          Icons.home_work_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ).animate().scale(
                            begin: const Offset(0.5, 0.5),
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: 12),
                      NeonGradientText(
                        'PakRentals',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Heading ───────────────────────────────────────────
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
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ).animate().fadeIn(delay: 380.ms),

                const SizedBox(height: 24),

                // ── Form ──────────────────────────────────────────────
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
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
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
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        validator: (v) =>
                            Validators.confirmPassword(v, _passwordCtrl.text),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                      ).animate().fadeIn(delay: 620.ms).slideY(begin: 0.12),

                      const SizedBox(height: 16),

                      // ── Role selector ─────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            _roleButton(
                                'user', 'Renter', Icons.person_outlined),
                            _roleButton(
                                'host', 'Host / Owner', Icons.home_outlined),
                          ],
                        ),
                      ).animate().fadeIn(delay: 660.ms),

                      const SizedBox(height: 24),

                      // ── Submit ────────────────────────────────────
                      PrimaryGlowButton(
                        label: 'Create Account',
                        onPressed: _register,
                        isLoading: isLoading,
                        width: double.infinity,
                        icon: Icons.person_add_outlined,
                      ).animate().fadeIn(delay: 700.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Login link ────────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Already have an account?  ',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
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
                ).animate().fadeIn(delay: 750.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton(String value, String label, IconData icon) {
    final isSelected = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
