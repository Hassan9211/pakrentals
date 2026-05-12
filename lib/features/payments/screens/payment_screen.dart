import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/payments/stripe_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bookings/providers/bookings_provider.dart';

// ── Payment methods ───────────────────────────────────────────────────────────
class _PayMethod {
  final String id;
  final String name;
  final String subtitle;
  final String emoji;
  final Color color;
  final bool hasAccountField;
  final String? accountLabel;
  final String? accountHint;
  final bool isStripe; // uses Stripe card sheet

  const _PayMethod({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.color,
    this.hasAccountField = false,
    this.accountLabel,
    this.accountHint,
    this.isStripe = false,
  });
}

const _methods = [
  _PayMethod(
    id: 'card',
    name: 'Credit / Debit Card',
    subtitle: 'Visa, Mastercard — powered by Stripe',
    emoji: '💳',
    color: AppColors.neonCyan,
    isStripe: true,
  ),
  _PayMethod(
    id: 'jazzcash',
    name: 'JazzCash',
    subtitle: 'Pay via JazzCash mobile account',
    emoji: '💚',
    color: Color(0xFF00A651),
    hasAccountField: true,
    accountLabel: 'JazzCash Mobile Number',
    accountHint: '03XX-XXXXXXX',
  ),
  _PayMethod(
    id: 'easypaisa',
    name: 'Easypaisa',
    subtitle: 'Pay via Easypaisa mobile account',
    emoji: '🟠',
    color: Color(0xFFFF6600),
    hasAccountField: true,
    accountLabel: 'Easypaisa Mobile Number',
    accountHint: '03XX-XXXXXXX',
  ),
  _PayMethod(
    id: 'bank_transfer',
    name: 'Bank Transfer',
    subtitle: 'Direct bank account transfer',
    emoji: '🏦',
    color: Color(0xFF3B82F6),
    hasAccountField: true,
    accountLabel: 'Your Bank Account / IBAN',
    accountHint: 'PK36SCBL0000001123456702',
  ),
  _PayMethod(
    id: 'cash',
    name: 'Cash on Delivery',
    subtitle: 'Pay in cash when you receive the item',
    emoji: '💵',
    color: Color(0xFF10B981),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
class PaymentScreen extends ConsumerStatefulWidget {
  final int bookingId;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedMethod = 'card';
  final _accountCtrl = TextEditingController();
  bool _isProcessing = false;
  bool _agreedToTerms = false;

  _PayMethod get _current =>
      _methods.firstWhere((m) => m.id == _selectedMethod);

  @override
  void dispose() {
    _accountCtrl.dispose();
    super.dispose();
  }

  // ── Main pay handler ───────────────────────────────────────────────────────
  Future<void> _pay() async {
    if (_current.hasAccountField && _accountCtrl.text.trim().isEmpty) {
      showSnackBar(context, 'Please enter your ${_current.accountLabel}',
          isError: true);
      return;
    }
    if (!_agreedToTerms) {
      showSnackBar(context, 'Please agree to the payment terms', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    if (_current.isStripe) {
      await _payWithStripe();
    } else {
      await _payWithLocalMethod();
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  // ── Stripe card payment ────────────────────────────────────────────────────
  Future<void> _payWithStripe() async {
    final user = ref.read(authProvider).user;
    final result = await StripeService().processPayment(
      context: context,
      amountPKR: widget.amount,
      customerEmail: user?.email ?? 'customer@pakrentals.com',
    );

    if (!mounted) return;

    if (result.isSuccess) {
      // Update booking status in provider
      await ref.read(bookingsProvider.notifier).pay(widget.bookingId, 'card');
      _showSuccessSheet();
    } else if (result.isCancelled) {
      showSnackBar(context, 'Payment cancelled');
    } else {
      showSnackBar(
        context,
        result.errorMessage ?? 'Payment failed. Please try again.',
        isError: true,
      );
    }
  }

  // ── Local method (JazzCash / Easypaisa / Bank / Cash) ─────────────────────
  Future<void> _payWithLocalMethod() async {
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    await ref
        .read(bookingsProvider.notifier)
        .pay(widget.bookingId, _selectedMethod);

    _showSuccessSheet();
  }

  // ── Success bottom sheet ───────────────────────────────────────────────────
  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.5),
                    width: 2),
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: AppColors.neonGreen, size: 44),
            )
                .animate()
                .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 500.ms,
                    curve: Curves.elasticOut)
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 20),

            Text(
              'Payment Successful!',
              style: GoogleFonts.syne(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 8),

            Text(
              '${formatPrice(widget.amount)} paid via ${_current.name}',
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 8),

            Text(
              'Your booking is confirmed. The host will be notified.',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 24),

            // Booking ref
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Booking Ref',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  Text(
                    '#${widget.bookingId.toString().padLeft(6, '0')}',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.neonCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/bookings');
                },
                child: const Text('View My Bookings'),
              ),
            ).animate().fadeIn(delay: 700.ms),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment',
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
            // ── Amount card ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A1A2E), Color(0xFF1A0A2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Text('Amount to Pay',
                      style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                    child: Text(
                      formatPrice(widget.amount),
                      style: GoogleFonts.syne(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Booking #${widget.bookingId.toString().padLeft(6, '0')}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 24),

            // ── Stripe test mode banner ────────────────────────────────
            if (_selectedMethod == 'card')
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF635BFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF635BFF).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Text('🧪', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stripe Test Mode',
                            style: GoogleFonts.spaceGrotesk(
                              color: const Color(0xFF635BFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Use card: 4242 4242 4242 4242 | Any future date | Any CVC',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

            // ── Method selector ────────────────────────────────────────
            Text('Select Payment Method',
                style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            ..._methods.asMap().entries.map((entry) {
              final i = entry.key;
              final method = entry.value;
              final isSelected = _selectedMethod == method.id;

              return GestureDetector(
                onTap: () => setState(() {
                  _selectedMethod = method.id;
                  _accountCtrl.clear();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? method.color.withValues(alpha: 0.08)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? method.color.withValues(alpha: 0.6)
                          : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: method.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(method.emoji,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  method.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? method.color
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (method.isStripe) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF635BFF)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'TEST',
                                      style: TextStyle(
                                        color: Color(0xFF635BFF),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(method.subtitle,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                      // Radio
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? method.color : AppColors.border,
                            width: 2,
                          ),
                          color: isSelected ? method.color : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 12)
                            : null,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 150 + i * 60));
            }),

            const SizedBox(height: 8),

            // ── Account field (non-Stripe methods) ─────────────────────
            if (_current.hasAccountField) ...[
              Text(
                _current.accountLabel!,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _accountCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                keyboardType: _selectedMethod == 'bank_transfer'
                    ? TextInputType.text
                    : TextInputType.phone,
                inputFormatters: _selectedMethod != 'bank_transfer'
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                decoration: InputDecoration(
                  hintText: _current.accountHint,
                  prefixIcon: Icon(
                    _selectedMethod == 'bank_transfer'
                        ? Icons.account_balance_outlined
                        : Icons.phone_outlined,
                    color: AppColors.textMuted,
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms),
              const SizedBox(height: 16),
            ],

            // ── Terms ──────────────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient:
                          _agreedToTerms ? AppColors.primaryGradient : null,
                      border: Border.all(
                        color: _agreedToTerms
                            ? Colors.transparent
                            : AppColors.border,
                      ),
                    ),
                    child: _agreedToTerms
                        ? const Icon(Icons.check, color: Colors.white, size: 13)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'I agree to the payment terms and confirm the booking details are correct.',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Pay button ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: _agreedToTerms ? AppColors.primaryGradient : null,
                  color: _agreedToTerms ? null : AppColors.surfaceVariant,
                  boxShadow: _agreedToTerms
                      ? [
                          BoxShadow(
                            color: AppColors.neonCyan.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isProcessing ? null : _pay,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _isProcessing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Processing...',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _current.isStripe
                                      ? Icons.credit_card_outlined
                                      : Icons.lock_outlined,
                                  color: _agreedToTerms
                                      ? Colors.white
                                      : AppColors.textMuted,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _current.isStripe
                                      ? 'Pay with Card'
                                      : 'Confirm Payment',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: _agreedToTerms
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Secure badge
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security_outlined,
                      color: AppColors.textMuted, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'Secured by Stripe & PakRentals',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
