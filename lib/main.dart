import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'core/firebase/firebase_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase init ──────────────────────────────────────────────────
  await FirebaseService.init();

  // ── Stripe init ────────────────────────────────────────────────────
  try {
    const pk = String.fromEnvironment('STRIPE_PK', defaultValue: '');
    if (pk.isNotEmpty) {
      Stripe.publishableKey = pk;
      await Stripe.instance.applySettings();
    }
  } catch (e) {
    debugPrint('Stripe init error (non-fatal): $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: PakRentalsApp()));
}

class PakRentalsApp extends ConsumerWidget {
  const PakRentalsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PakRentals',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
