import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../providers/messages_provider.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Messages', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(conversationsProvider.notifier).load(),
        color: AppColors.neonCyan,
        backgroundColor: AppColors.surface,
        child: state.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.neonCyan))
            : state.conversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            color: AppColors.textMuted, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No conversations yet',
                          style: GoogleFonts.syne(
                              color: AppColors.textMuted, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: state.conversations.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.border, height: 1),
                    itemBuilder: (context, index) {
                      final conv = state.conversations[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              getInitials(conv.otherUser?.name),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          conv.otherUser?.name ?? 'User',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conv.listingTitle,
                              style: const TextStyle(
                                color: AppColors.neonCyan,
                                fontSize: 11,
                              ),
                            ),
                            if (conv.lastMessage != null)
                              Text(
                                conv.lastMessage!.body,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (conv.lastMessage?.createdAt != null)
                              Text(
                                timeago.format(
                                    DateTime.parse(conv.lastMessage!.createdAt!)),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            if (conv.unreadCount > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.neonCyan,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${conv.unreadCount}',
                                  style: const TextStyle(
                                    color: AppColors.background,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          final otherUserId = conv.otherUser?.firestoreId ?? conv.otherUser?.id.toString() ?? '0';
                          context.push(
                            '/messages/${conv.listingId}/$otherUserId',
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
