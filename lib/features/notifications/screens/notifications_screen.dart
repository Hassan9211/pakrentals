import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../models/notification_model.dart';

// Mock provider — no API call
final notificationsProvider =
    StateNotifierProvider<_NotifNotifier, List<NotificationModel>>((ref) {
  return _NotifNotifier();
});

class _NotifNotifier extends StateNotifier<List<NotificationModel>> {
  _NotifNotifier() : super(mockNotifications);

  void markRead(int id) {
    state = state.map((n) {
      if (n.id == id) {
        return NotificationModel(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          isRead: true,
          data: n.data,
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
  }

  void markAllRead() {
    state = state.map((n) => NotificationModel(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          isRead: true,
          data: n.data,
          createdAt: n.createdAt,
        )).toList();
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.syne(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(color: AppColors.neonCyan, fontSize: 12),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none,
                      color: AppColors.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications',
                    style: GoogleFonts.syne(
                        color: AppColors.textMuted, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return InkWell(
                  onTap: () => ref
                      .read(notificationsProvider.notifier)
                      .markRead(notif.id),
                  child: Container(
                    color: notif.isRead
                        ? null
                        : AppColors.neonCyan.withOpacity(0.04),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: notif.isRead
                                ? AppColors.surfaceVariant
                                : AppColors.neonCyan.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: notif.isRead
                                  ? AppColors.border
                                  : AppColors.neonCyan.withOpacity(0.4),
                            ),
                          ),
                          child: Icon(
                            _getIcon(notif.type),
                            color: notif.isRead
                                ? AppColors.textMuted
                                : AppColors.neonCyan,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: notif.isRead
                                            ? FontWeight.w400
                                            : FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.neonCyan,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                notif.body,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (notif.createdAt != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  timeago.format(
                                      DateTime.parse(notif.createdAt!)),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'booking_request':
        return Icons.calendar_today_outlined;
      case 'booking_approved':
        return Icons.check_circle_outline;
      case 'booking_rejected':
        return Icons.cancel_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'report':
        return Icons.flag_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
