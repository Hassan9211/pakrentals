import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

// ── Method type config ────────────────────────────────────────────────────────
class _MethodConfig {
  final String type;
  final String name;
  final String emoji;
  final Color color;
  final String fieldLabel;
  final String fieldHint;
  final TextInputType keyboardType;
  final List<TextInputFormatter> formatters;

  const _MethodConfig({
    required this.type,
    required this.name,
    required this.emoji,
    required this.color,
    required this.fieldLabel,
    required this.fieldHint,
    required this.keyboardType,
    this.formatters = const [],
  });
}

final _methodConfigs = [
  _MethodConfig(
    type: 'jazzcash',
    name: 'JazzCash',
    emoji: '💚',
    color: Color(0xFF00A651),
    fieldLabel: 'JazzCash Mobile Number',
    fieldHint: '03XX-XXXXXXX',
    keyboardType: TextInputType.phone,
    formatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(11)
    ],
  ),
  _MethodConfig(
    type: 'easypaisa',
    name: 'Easypaisa',
    emoji: '🟠',
    color: Color(0xFFFF6600),
    fieldLabel: 'Easypaisa Mobile Number',
    fieldHint: '03XX-XXXXXXX',
    keyboardType: TextInputType.phone,
    formatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(11)
    ],
  ),
  _MethodConfig(
    type: 'bank',
    name: 'Bank Account',
    emoji: '🏦',
    color: Color(0xFF3B82F6),
    fieldLabel: 'IBAN / Account Number',
    fieldHint: 'PK36SCBL0000001123456702',
    keyboardType: TextInputType.text,
  ),
  _MethodConfig(
    type: 'card',
    name: 'Credit / Debit Card',
    emoji: '💳',
    color: AppColors.neonCyan,
    fieldLabel: 'Card Number (last 4 digits)',
    fieldHint: '4242',
    keyboardType: TextInputType.number,
    formatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(4)
    ],
  ),
];

_MethodConfig _configFor(String type) => _methodConfigs
    .firstWhere((c) => c.type == type, orElse: () => _methodConfigs.first);

// ─────────────────────────────────────────────────────────────────────────────
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final methods = user?.paymentMethods ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Methods',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddSheet(context, ref),
            icon: const Icon(Icons.add, size: 18, color: AppColors.neonCyan),
            label: const Text('Add',
                style: TextStyle(color: AppColors.neonCyan, fontSize: 13)),
          ),
        ],
      ),
      body: methods.isEmpty
          ? _buildEmpty(context, ref)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Default method highlight
                if (user?.defaultPaymentMethod != null) ...[
                  _buildSectionLabel('Default Method'),
                  const SizedBox(height: 8),
                  _MethodCard(
                    method: user!.defaultPaymentMethod!,
                    isDefault: true,
                    onSetDefault: null,
                    onDelete: () => _confirmDelete(
                        context, ref, user.defaultPaymentMethod!.id),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 20),
                ],

                // Other methods
                if (methods.where((m) => !m.isDefault).isNotEmpty) ...[
                  _buildSectionLabel('Other Methods'),
                  const SizedBox(height: 8),
                  ...methods
                      .where((m) => !m.isDefault)
                      .toList()
                      .asMap()
                      .entries
                      .map((e) => _MethodCard(
                            method: e.value,
                            isDefault: false,
                            onSetDefault: () => ref
                                .read(authProvider.notifier)
                                .setDefaultPaymentMethod(e.value.id),
                            onDelete: () =>
                                _confirmDelete(context, ref, e.value.id),
                          ).animate().fadeIn(
                              delay: Duration(milliseconds: 150 + e.key * 60))),
                ],

                const SizedBox(height: 24),

                // Add new button
                OutlinedButton.icon(
                  onPressed: () => _showAddSheet(context, ref),
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.neonCyan, size: 18),
                  label: const Text('Add Payment Method'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonCyan,
                    side: const BorderSide(color: AppColors.neonCyan),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 16),

                // Security note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.security_outlined,
                          color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your payment information is encrypted and stored securely. We never store full card numbers.',
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.spaceGrotesk(
        color: AppColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withOpacity(0.25),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.payment_outlined,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'No Payment Methods',
              style: GoogleFonts.syne(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add JazzCash, Easypaisa, bank account or card for faster checkout.',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _showAddSheet(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Payment Method'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add method bottom sheet ────────────────────────────────────────────────
  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddMethodSheet(
        onAdd: (method) async {
          await ref.read(authProvider.notifier).addPaymentMethod(method);
          if (context.mounted) {
            showSnackBar(context, '${method.title} added!');
          }
        },
      ),
    );
  }

  // ── Delete confirm ─────────────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, WidgetRef ref, String methodId) {
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove Method',
            style: GoogleFonts.syne(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to remove this payment method?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child:
                const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(authProvider.notifier).removePaymentMethod(methodId);
        showSnackBar(context, 'Payment method removed');
      }
    });
  }
}

// ── Method card ───────────────────────────────────────────────────────────────
class _MethodCard extends StatelessWidget {
  final SavedPaymentMethod method;
  final bool isDefault;
  final VoidCallback? onSetDefault;
  final VoidCallback onDelete;

  const _MethodCard({
    required this.method,
    required this.isDefault,
    required this.onSetDefault,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _configFor(method.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDefault ? cfg.color.withOpacity(0.06) : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDefault ? cfg.color.withOpacity(0.5) : AppColors.border,
          width: isDefault ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cfg.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(cfg.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      method.title,
                      style: TextStyle(
                        color: isDefault ? cfg.color : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cfg.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Default',
                          style: TextStyle(
                            color: cfg.color,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  method.account,
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                color: AppColors.textMuted, size: 20),
            color: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'default') onSetDefault?.call();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              if (!isDefault)
                PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      const Icon(Icons.star_outline,
                          color: AppColors.neonCyan, size: 16),
                      const SizedBox(width: 8),
                      Text('Set as Default',
                          style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textPrimary, fontSize: 13)),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Text('Remove',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.error, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add method bottom sheet ───────────────────────────────────────────────────
class _AddMethodSheet extends StatefulWidget {
  final Function(SavedPaymentMethod) onAdd;

  const _AddMethodSheet({required this.onAdd});

  @override
  State<_AddMethodSheet> createState() => _AddMethodSheetState();
}

class _AddMethodSheetState extends State<_AddMethodSheet> {
  String _selectedType = 'jazzcash';
  final _accountCtrl = TextEditingController();
  final _nickCtrl = TextEditingController();
  bool _isAdding = false;

  _MethodConfig get _cfg => _configFor(_selectedType);

  @override
  void dispose() {
    _accountCtrl.dispose();
    _nickCtrl.dispose();
    super.dispose();
  }

  String _maskAccount(String account, String type) {
    if (account.length <= 4) return account;
    if (type == 'card') return '**** **** **** $account';
    if (type == 'bank') {
      return '${account.substring(0, 4)}...${account.substring(account.length - 4)}';
    }
    // Phone number
    return '${account.substring(0, 4)}-XXXXX-${account.substring(account.length - 2)}';
  }

  Future<void> _add() async {
    final account = _accountCtrl.text.trim();
    if (account.isEmpty) {
      showSnackBar(context, 'Please enter ${_cfg.fieldLabel}', isError: true);
      return;
    }

    setState(() => _isAdding = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final nick = _nickCtrl.text.trim();
    final title = nick.isNotEmpty ? nick : _cfg.name;
    final masked = _maskAccount(account, _selectedType);

    final method = SavedPaymentMethod(
      id: '${_selectedType}_${DateTime.now().millisecondsSinceEpoch}',
      type: _selectedType,
      title: title,
      account: masked,
    );

    await widget.onAdd(method);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
          const SizedBox(height: 16),

          Text(
            'Add Payment Method',
            style: GoogleFonts.syne(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // Type selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _methodConfigs.map((cfg) {
                final isSelected = _selectedType == cfg.type;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedType = cfg.type;
                    _accountCtrl.clear();
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cfg.color.withOpacity(0.15)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? cfg.color.withOpacity(0.6)
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cfg.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          cfg.name,
                          style: TextStyle(
                            color: isSelected
                                ? cfg.color
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Account field
          Text(
            _cfg.fieldLabel,
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
            keyboardType: _cfg.keyboardType,
            inputFormatters: _cfg.formatters,
            decoration: InputDecoration(
              hintText: _cfg.fieldHint,
              prefixText: _selectedType == 'card' ? '**** **** **** ' : null,
              prefixStyle: const TextStyle(color: AppColors.textMuted),
            ),
          ),

          const SizedBox(height: 12),

          // Nickname (optional)
          TextField(
            controller: _nickCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Nickname (optional)',
              hintText: 'e.g. My JazzCash, Salary Account',
              prefixIcon: const Icon(Icons.label_outline),
            ),
          ),

          const SizedBox(height: 20),

          // Add button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAdding ? null : _add,
              child: _isAdding
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Add ${_cfg.name}'),
            ),
          ),
        ],
      ),
    );
  }
}
