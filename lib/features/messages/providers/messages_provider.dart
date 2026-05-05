import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/mock/mock_data.dart';
import '../models/message_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATIONS
// ─────────────────────────────────────────────────────────────────────────────
class ConversationsState {
  final List<ConversationModel> conversations;
  final bool isLoading;
  final String? error;

  const ConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  ConversationsState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ConversationsNotifier extends StateNotifier<ConversationsState> {
  ConversationsNotifier() : super(const ConversationsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(
      isLoading: false,
      conversations: mockConversations,
    );
  }
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  return ConversationsNotifier();
});

// ─────────────────────────────────────────────────────────────────────────────
// CHAT THREAD
// ─────────────────────────────────────────────────────────────────────────────
class ThreadState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const ThreadState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  ThreadState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ThreadState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

class ThreadNotifier extends StateNotifier<ThreadState> {
  final int listingId;
  final int userId;
  final List<MessageModel> _msgs = [];

  ThreadNotifier(this.listingId, this.userId) : super(const ThreadState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 300));

    // Load mock messages for this conversation
    _msgs.clear();
    _msgs.addAll(
      mockMessages.where((m) => m.conversationId == listingId).toList(),
    );
    // If no messages found, show empty thread
    state = state.copyWith(isLoading: false, messages: List.from(_msgs));
  }

  Future<bool> sendMessage(String body) async {
    state = state.copyWith(isSending: true);
    await Future.delayed(const Duration(milliseconds: 400));

    final newMsg = MessageModel(
      id: _msgs.length + 100,
      conversationId: listingId,
      senderId: 1, // current user
      body: body,
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
      sender: mockUsers[0],
    );

    _msgs.add(newMsg);
    state = state.copyWith(
      isSending: false,
      messages: List.from(_msgs),
    );
    return true;
  }
}

final threadProvider = StateNotifierProvider.family<ThreadNotifier, ThreadState,
    ({int listingId, int userId})>((ref, params) {
  return ThreadNotifier(params.listingId, params.userId);
});
