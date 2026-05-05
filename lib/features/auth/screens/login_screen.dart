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
  String _role = 'user'; // 'user' = Renter | 'host' = Host/Owner

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          role: _role,
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
                const SizedBox(height: 40),

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
                              color: AppColors.neonCyan.withOpacity(0.35),
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
                      const SizedBox(height: 14),
                      NeonGradientText('PakRentals',
                              fontSize: 34, fontWeight: FontWeight.w800)
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 500.ms),
                      const SizedBox(height: 5),
                      Text(
                        "Pakistan's Premier Rental Marketplace",
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textMuted, fontSize: 12),
                      ).animate().fadeIn(delay: 350.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── Role selector ─────────────────────────────────────
                Text(
                  'Sign in as',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: 380.ms),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _RoleTab(
                        value: 'user',
                        label: 'Renter',
                        icon: Icons.person_outlined,
                        activeIcon: Icons.person,
                        description: 'Browse & book items',
                        selected: _role == 'user',
                        onTap: () => setState(() => _role = 'user'),
                      ),
                      _RoleTab(
                        value: 'host',
                        label: 'Host / Owner',
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        description: 'List & manage items',
                        selected: _role == 'host',
                        onTap: () => setState(() => _role = 'host'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 430.ms),

                const SizedBox(height: 24),

                // ── Heading ───────────────────────────────────────────
                Text(
                  _role == 'host' ? 'Host Sign In' : 'Welcome Back',
                  style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ).animate(key: ValueKey(_role)).fadeIn(duration: 300.ms),
                const SizedBox(height: 3),
                Text(
                  _role == 'host'
                      ? 'Manage your listings and bookings'
                      : 'Sign in to continue renting',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textMuted, fontSize: 13),
                ).animate(key: ValueKey('sub_$_role')).fadeIn(duration: 300.ms),

                const SizedBox(height: 22),

                // ── Form ──────────────────────────────────────────────
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
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.12),

                      const SizedBox(height: 12),

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
                      ).animate().fadeIn(delay: 570.ms).slideY(begin: 0.12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8)),
                          child: const Text('Forgot Password?',
                              style: TextStyle(
                                  color: AppColors.neonCyan, fontSize: 13)),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Sign In button — color changes with role
                      PrimaryGlowButton(
                        label: _role == 'host'
                            ? 'Sign In as Host'
                            : 'Sign In as Renter',
                        onPressed: _login,
                        isLoading: isLoading,
                        width: double.infinity,
                        icon: Icons.login_rounded,
                        gradient: _role == 'host'
                            ? const LinearGradient(
                                colors: [
                                  AppColors.neonViolet,
                                  AppColors.neonPink
                                ],
                              )
                            : null, // default cyan gradient
                      ).animate().fadeIn(delay: 640.ms).slideY(begin: 0.12),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Divider ───────────────────────────────────────────
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
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 18),

                // ── Register link ─────────────────────────────────────
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
                ).animate().fadeIn(delay: 750.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Role tab widget ───────────────────────────────────────────────────────────
class _RoleTab extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTab({
    required this.value,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHost = value == 'host';
    final activeColor = isHost ? AppColors.neonViolet : AppColors.neonCyan;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: isHost
                        ? [AppColors.neonViolet, AppColors.neonPink]
                        : [AppColors.neonCyan, AppColors.neonViolet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                selected ? activeIcon : icon,
                color: selected ? Colors.white : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: selected
                      ? Colors.white.withOpacity(0.75)
                      : AppColors.textMuted,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
