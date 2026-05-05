import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STRIPE CONFIGURATION
// ─────────────────────────────────────────────────────────────────────────────
// Keys are loaded from environment variables — NEVER hardcode in source code.
//
// To run locally, create a .env file or pass via --dart-define:
//   flutter run --dart-define=STRIPE_PK=pk_test_xxx --dart-define=STRIPE_SK=sk_test_xxx
//
// For CI/CD, set these as repository secrets.
// ─────────────────────────────────────────────────────────────────────────────

const String _stripePublishableKey = String.fromEnvironment(
  'STRIPE_PK',
  defaultValue: '', // set via --dart-define=STRIPE_PK=pk_test_...
);

const String _stripeSecretKey = String.fromEnvironment(
  'STRIPE_SK',
  defaultValue: '', // set via --dart-define=STRIPE_SK=sk_test_...
);

class StripeService {
  static final StripeService _instance = StripeService._internal();
  factory StripeService() => _instance;
  StripeService._internal();

  /// Creates a PaymentIntent on Stripe (test mode — direct API call)
  /// In production: call your Laravel backend which calls Stripe server-side
  Future<String?> _createPaymentIntent(int amountPKR) async {
    try {
      final dio = Dio();
      // Stripe amount is in smallest currency unit (paisa for PKR)
      // PKR is a zero-decimal currency — use amount directly
      final response = await dio.post(
        'https://api.stripe.com/v1/payment_intents',
        data: {
          'amount': amountPKR.toString(),
          'currency': 'pkr',
          'payment_method_types[]': 'card',
          'description': 'PakRentals booking payment',
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_stripeSecretKey',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );
      return response.data['client_secret'] as String?;
    } catch (e) {
      debugPrint('Stripe PaymentIntent error: $e');
      return null;
    }
  }

  /// Full payment flow:
  /// 1. Create PaymentIntent
  /// 2. Show Stripe payment sheet
  /// 3. Return result
  Future<StripePaymentResult> processPayment({
    required BuildContext context,
    required double amountPKR,
    required String customerEmail,
  }) async {
    try {
      // Step 1 — Create PaymentIntent
      final clientSecret =
          await _createPaymentIntent(amountPKR.toInt());

      if (clientSecret == null) {
        return StripePaymentResult.failed(
            'Could not initialize payment. Check your Stripe keys.');
      }

      // Step 2 — Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'PakRentals',
          billingDetails: BillingDetails(email: customerEmail),
          style: ThemeMode.dark,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF00F5FF),
              background: Color(0xFF0A0A0F),
              componentBackground: Color(0xFF16162A),
              componentText: Color(0xFFFFFFFF),
              placeholderText: Color(0xFF6B6B8A),
              icon: Color(0xFF00F5FF),
              componentBorder: Color(0xFF2A2A3E),
            ),
            shapes: PaymentSheetShape(
              borderRadius: 12,
            ),
          ),
        ),
      );

      // Step 3 — Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      return StripePaymentResult.success(clientSecret);
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return StripePaymentResult.cancelled();
      }
      return StripePaymentResult.failed(
          e.error.localizedMessage ?? 'Payment failed');
    } catch (e) {
      return StripePaymentResult.failed(e.toString());
    }
  }
}

// ── Result model ──────────────────────────────────────────────────────────────
enum StripePaymentStatus { success, failed, cancelled }

class StripePaymentResult {
  final StripePaymentStatus status;
  final String? clientSecret;
  final String? errorMessage;

  const StripePaymentResult._({
    required this.status,
    this.clientSecret,
    this.errorMessage,
  });

  factory StripePaymentResult.success(String clientSecret) =>
      StripePaymentResult._(
          status: StripePaymentStatus.success,
          clientSecret: clientSecret);

  factory StripePaymentResult.failed(String message) =>
      StripePaymentResult._(
          status: StripePaymentStatus.failed, errorMessage: message);

  factory StripePaymentResult.cancelled() =>
      StripePaymentResult._(status: StripePaymentStatus.cancelled);

  bool get isSuccess => status == StripePaymentStatus.success;
  bool get isCancelled => status == StripePaymentStatus.cancelled;
}
