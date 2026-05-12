import 'package:firebase_auth/firebase_auth.dart';
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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Forgot Password ────────────────────────────────────────────────────────
  void _showForgotPassword(BuildContext context) {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icon
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan.withValues(alpha: 0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_reset_outlined,
                      color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Text(
                  'Reset Password',
                  style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Enter your email — we\'ll send a reset link',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Email field
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                onSubmitted: (_) => _sendReset(ctx, emailCtrl.text,
                    setModalState, () => isSending, (v) => isSending = v),
              ),
              const SizedBox(height: 20),

              // Send button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSending
                      ? null
                      : () => _sendReset(
                          ctx,
                          emailCtrl.text,
                          setModalState,
                          () => isSending,
                          (v) => setModalState(() => isSending = v)),
                  icon: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_outlined, size: 18),
                  label: Text(isSending ? 'Sending...' : 'Send Reset Link'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendReset(
    BuildContext ctx,
    String email,
    StateSetter setModalState,
    bool Function() getLoading,
    void Function(bool) setLoading,
  ) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      showSnackBar(ctx, 'Please enter your email', isError: true);
      return;
    }

    // Basic email validation
    if (!trimmed.contains('@') || !trimmed.contains('.')) {
      showSnackBar(ctx, 'Enter a valid email address', isError: true);
      return;
    }

    setLoading(true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: trimmed);
      if (ctx.mounted) {
        Navigator.pop(ctx); // close sheet
        // Show success dialog
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.neonGreen.withValues(alpha: 0.5),
                        width: 2),
                  ),
                  child: const Icon(Icons.mark_email_read_outlined,
                      color: AppColors.neonGreen, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  'Email Sent!',
                  style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Password reset link sent to:\n$trimmed\n\nCheck your inbox (and spam folder).',
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found with this email.';
          break;
        case 'invalid-email':
          msg = 'Invalid email address.';
          break;
        case 'too-many-requests':
          msg = 'Too many attempts. Try again later.';
          break;
        default:
          msg = e.message ?? 'Failed to send reset email.';
      }
      if (ctx.mounted) {
        if (!mounted) return;
        showSnackBar(ctx, msg, isError: true);
      }
    } catch (e) {
      setLoading(false);
      if (ctx.mounted) {
        if (!mounted) return;
        showSnackBar(ctx, 'Error: $e', isError: true);
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );

    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else {
      final error = ref.read(authProvider).error;
      showSnackBar(context, error ?? 'Login failed', isError: true);
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
                const SizedBox(height: 48),

                // ── Logo ──────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonCyan.withValues(alpha: 0.35),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.home_work_outlined,
                            color: Colors.white, size: 36),
                      ).animate().scale(
                            begin: const Offset(0.5, 0.5),
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: 16),
                      NeonGradientText('PakRentals',
                              fontSize: 34, fontWeight: FontWeight.w800)
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 500.ms),
                      const SizedBox(height: 6),
                      Text(
                        "Pakistan's Premier Rental Marketplace",
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textMuted, fontSize: 12),
                      ).animate().fadeIn(delay: 350.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 44),

                Text(
                  'Welcome Back',
                  style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.15),
                const SizedBox(height: 4),
                Text(
                  'Sign in to your account',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textMuted, fontSize: 13),
                ).animate().fadeIn(delay: 480.ms),

                const SizedBox(height: 28),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
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
                      ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.15),
                      const SizedBox(height: 14),
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
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                      ).animate().fadeIn(delay: 630.ms).slideY(begin: 0.15),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPassword(context),
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8)),
                          child: const Text('Forgot Password?',
                              style: TextStyle(
                                  color: AppColors.neonCyan, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      PrimaryGlowButton(
                        label: 'Sign In',
                        onPressed: _login,
                        isLoading: isLoading,
                        width: double.infinity,
                        icon: Icons.login_rounded,
                      ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.15),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR',
                          style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textMuted, fontSize: 12)),
                    ),
                    const Expanded(child: Divider(color: AppColors.border)),
                  ],
                ).animate().fadeIn(delay: 750.ms),

                const SizedBox(height: 20),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Don't have an account?  ",
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textMuted, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.neonCyan,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 800.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
