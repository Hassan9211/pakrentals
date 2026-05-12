import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';

final adminUsersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('users')
      .get()
      .timeout(const Duration(seconds: 10));
  return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
});

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Users', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminUsersProvider),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error))),
        data: (users) => users.isEmpty
            ? const Center(
                child: Text('No users',
                    style: TextStyle(color: AppColors.textMuted)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final u = users[i];
                  final role = u['role'] ?? 'user';
                  final isAdmin = role == 'admin';
                  final uid = u['id']?.toString() ?? '';
                  final isDisabled = u['disabled'] == true;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? AppColors.error.withValues(alpha: 0.05)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isAdmin
                            ? AppColors.neonViolet.withValues(alpha: 0.4)
                            : isDisabled
                                ? AppColors.error.withValues(alpha: 0.3)
                                : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: isDisabled
                                    ? const LinearGradient(
                                        colors: [
                                          AppColors.textMuted,
                                          AppColors.border
                                        ],
                                      )
                                    : AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  getInitials(u['name']?.toString()),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                ),
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
                                      Expanded(
                                        child: Text(
                                          u['name'] ?? 'Unknown',
                                          style: TextStyle(
                                            color: isDisabled
                                                ? AppColors.textMuted
                                                : AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            decoration: isDisabled
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                      if (isDisabled)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.error
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text('DISABLED',
                                              style: TextStyle(
                                                  color: AppColors.error,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                    ],
                                  ),
                                  Text(u['email'] ?? '',
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12)),
                                  if (u['phone'] != null &&
                                      u['phone'].toString().isNotEmpty)
                                    Text(u['phone'].toString(),
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11)),
                                ],
                              ),
                            ),
                            // Role badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? AppColors.neonViolet
                                        .withValues(alpha: 0.15)
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isAdmin
                                      ? AppColors.neonViolet
                                          .withValues(alpha: 0.4)
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: TextStyle(
                                  color: isAdmin
                                      ? AppColors.neonViolet
                                      : AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ── Action buttons (not for admin) ─────────────
                        if (!isAdmin && uid.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Divider(color: AppColors.border, height: 1),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Disable / Enable toggle
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _toggleDisable(context, ref,
                                      uid, u['name'] ?? '', isDisabled),
                                  icon: Icon(
                                    isDisabled
                                        ? Icons.lock_open_outlined
                                        : Icons.block_outlined,
                                    size: 14,
                                  ),
                                  label:
                                      Text(isDisabled ? 'Enable' : 'Disable'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDisabled
                                        ? AppColors.neonGreen
                                        : AppColors.warning,
                                    side: BorderSide(
                                        color: isDisabled
                                            ? AppColors.neonGreen
                                            : AppColors.warning),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete button
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _confirmDelete(context, ref,
                                      uid, u['name'] ?? '', u['email'] ?? ''),
                                  icon: const Icon(Icons.delete_outline,
                                      size: 14),
                                  label: const Text('Delete'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(
                                        color: AppColors.error),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  // ── Disable / Enable user ──────────────────────────────────────────────────
  Future<void> _toggleDisable(BuildContext context, WidgetRef ref, String uid,
      String name, bool currentlyDisabled) async {
    final action = currentlyDisabled ? 'enable' : 'disable';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${action.capitalize()} User',
            style: GoogleFonts.syne(color: AppColors.textPrimary)),
        content: Text(
          currentlyDisabled
              ? 'Re-enable "$name"? They will be able to log in again.'
              : 'Disable "$name"? They will be marked as disabled in the database.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action.capitalize(),
                  style: TextStyle(
                      color: currentlyDisabled
                          ? AppColors.neonGreen
                          : AppColors.warning))),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'disabled': !currentlyDisabled,
    });
    ref.invalidate(adminUsersProvider);
    if (context.mounted) {
      showSnackBar(
          context, currentlyDisabled ? 'User enabled' : 'User disabled');
    }
  }

  // ── Delete user ────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String uid,
      String name, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete User',
            style: GoogleFonts.syne(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete "$name" and all their data from Firestore.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'To also remove from Firebase Auth, go to Firebase Console → Authentication.',
                      style: const TextStyle(
                          color: AppColors.warning, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirmed != true) return;

    final db = FirebaseFirestore.instance;

    // Delete user document
    await db.collection('users').doc(uid).delete();

    // Delete user's listings
    final listings =
        await db.collection('listings').where('host_id', isEqualTo: uid).get();
    for (final doc in listings.docs) {
      await doc.reference.delete();
    }

    // Delete user's bookings (as renter)
    final renterBookings = await db
        .collection('bookings')
        .where('renter_id', isEqualTo: uid)
        .get();
    for (final doc in renterBookings.docs) {
      await doc.reference.delete();
    }

    // Delete user's notifications
    final notifs = await db
        .collection('notifications')
        .where('user_id', isEqualTo: uid)
        .get();
    for (final doc in notifs.docs) {
      await doc.reference.delete();
    }

    // Delete user's reports
    final reports =
        await db.collection('reports').where('user_id', isEqualTo: uid).get();
    for (final doc in reports.docs) {
      await doc.reference.delete();
    }

    ref.invalidate(adminUsersProvider);

    if (context.mounted) {
      showSnackBar(context, 'User "$name" deleted from database');
      // Show Firebase Console link for Auth deletion
      _showAuthDeleteReminder(context, email);
    }
  }

  // ── Remind admin to delete from Firebase Auth ──────────────────────────────
  void _showAuthDeleteReminder(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('One More Step',
            style: GoogleFonts.syne(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.neonGreen, size: 40),
            const SizedBox(height: 12),
            Text(
              'User data deleted from database.\n\nTo fully remove "$email" from Firebase Authentication:',
              style:
                  const TextStyle(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Firebase Console → Authentication → Users → Find "$email" → Delete',
              style: const TextStyle(
                  color: AppColors.neonCyan, fontSize: 12, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Open Firebase Console
              final url = Uri.parse(
                  'https://console.firebase.google.com/project/project-3deabcf5-1dff-4acc-a9e/authentication/users');
              if (await canLaunchUrl(url)) launchUrl(url);
            },
            child: const Text('Open Firebase Console',
                style: TextStyle(color: AppColors.neonCyan)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done',
                style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
extension StringExtension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}

void showSnackBar(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: isError ? AppColors.error : AppColors.neonGreen,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}
