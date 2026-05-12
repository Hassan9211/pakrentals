import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _navigate();
  }

  Future<void> _navigate() async {
    // Minimum splash display time
    await Future.delayed(const Duration(milliseconds: 2600));

    // Wait until auth provider finishes its initial token check
    // (it starts loading in constructor, resolves quickly)
    int attempts = 0;
    while (mounted && attempts < 30) {
      final authState = ref.read(authProvider);
      // AuthNotifier sets isLoading=false once _checkAuth() completes.
      // Initial state has isLoading=false too, but isAuthenticated=false.
      // We wait a tick to let _checkAuth() start.
      if (attempts > 2 && !authState.isLoading) break;
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (!mounted) return;

    final isAuth = ref.read(authProvider).isAuthenticated;
    // context.go triggers the router which will also run redirect(),
    // but we navigate explicitly so the destination is clear.
    if (isAuth) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Background glow blobs ──────────────────────────────────
          _GlowBlob(
            color: AppColors.neonViolet,
            size: 320,
            top: -80,
            left: -100,
            controller: _glowCtrl,
          ),
          _GlowBlob(
            color: AppColors.neonCyan,
            size: 260,
            bottom: -60,
            right: -80,
            controller: _glowCtrl,
            reverse: true,
          ),
          _GlowBlob(
            color: AppColors.neonPink,
            size: 200,
            top: 180,
            right: 10,
            controller: _glowCtrl,
          ),

          // ── Center content ─────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan.withValues(alpha: 0.45),
                        blurRadius: 48,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.home_work_outlined,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.0, 1.0),
                      duration: 750.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 30),

                // App name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.cyanVioletGradient.createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                      child: Text(
                        'PakRentals',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.syne(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 350.ms, duration: 600.ms).slideY(
                      begin: 0.25,
                      end: 0,
                      delay: 350.ms,
                      duration: 600.ms,
                    ),

                const SizedBox(height: 10),

                Text(
                  "Pakistan's Premier Rental Marketplace",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ).animate().fadeIn(delay: 650.ms, duration: 500.ms),

                const SizedBox(height: 64),

                // Loading dots
                _LoadingDots()
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated glow blob ───────────────────────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final AnimationController controller;
  final bool reverse;

  const _GlowBlob({
    required this.color,
    required this.size,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.controller,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final t = reverse ? 1 - controller.value : controller.value;
          // Smooth pulse using sine-like approximation
          final pulse = 0.5 + 0.5 * ((t * 2 - 1).abs());
          final scale = 0.82 + 0.18 * pulse;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.28),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Animated loading dots ────────────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot is offset by 1/3 of the cycle
            final phase = ((_ctrl.value - i / 3) % 1.0 + 1.0) % 1.0;
            final opacity = phase < 0.5
                ? 0.3 + 0.7 * (phase * 2)
                : 0.3 + 0.7 * ((1 - phase) * 2);
            final yOffset =
                phase < 0.5 ? -6.0 * (phase * 2) : -6.0 * ((1 - phase) * 2);
            return Transform.translate(
              offset: Offset(0, yOffset),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonCyan.withValues(alpha: opacity),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
