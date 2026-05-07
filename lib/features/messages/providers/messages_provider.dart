import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../../auth/models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONVERSATIONS
// ─────────────────────────────────────────────────────────────────────────────
class ConversationsState {
  final List<ConversationModel> conversations;
  final bool isLoading;

  const ConversationsState({
    this.conversations = const [],
    this.isLoading = false,
  });

  ConversationsState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
  }) {
    return ConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ConversationsNotifier extends StateNotifier<ConversationsState> {
  static final _db = FirebaseFirestore.instance;

  ConversationsNotifier() : super(const ConversationsState()) {
    load();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> load() async {
    if (_uid.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final snap = await _db
          .collection('conversations')
          .where('participants', arrayContains: _uid)
          .get()
          .timeout(const Duration(seconds: 10));

      final convs = snap.docs.map((doc) {
        final data = doc.data();
        final participants =
            List<String>.from(data['participants'] ?? []);
        final otherUid =
            participants.firstWhere((p) => p != _uid, orElse: () => '');

        return ConversationModel(
          id: doc.id.hashCode,
          listingId: (data['listing_id']?.toString() ?? '').hashCode,
          listingTitle: data['listing_title'] ?? '',
          otherUser: otherUid.isNotEmpty
              ? UserModel(
                  id: otherUid.hashCode,
                  name: data['other_user_name'] ?? 'User',
                  email: data['other_user_email'] ?? '',
                )
              : null,
          lastMessage: data['last_message'] != null
              ? MessageModel(
                  id: 0,
                  conversationId: doc.id.hashCode,
                  senderId: 0,
                  body: data['last_message'] ?? '',
                  isRead: (data['unread_count_$_uid'] ?? 0) == 0,
                  createdAt: (data['updated_at'] as dynamic)
                      ?.toDate()
                      ?.toIso8601String(),
                )
              : null,
          unreadCount: (data['unread_count_$_uid'] ?? 0) as int,
        );
      }).toList();

      // Sort by updated_at
      convs.sort((a, b) =>
          (b.lastMessage?.createdAt ?? '')
              .compareTo(a.lastMessage?.createdAt ?? ''));

      state = state.copyWith(isLoading: false, conversations: convs);
    } catch (e) {
      debugPrint('ConversationsNotifier error: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, ConversationsState>((ref) {
  return ConversationsNotifier();
});

// ─────────────────────────────────────────────────────────────────────────────
// CHAT THREAD — real-time stream from Firestore
// ─────────────────────────────────────────────────────────────────────────────
class ThreadState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isSending;

  const ThreadState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
  });

  ThreadState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isSending,
  }) {
    return ThreadState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ThreadNotifier extends StateNotifier<ThreadState> {
  final int listingId;
  final int userId;
  static final _db = FirebaseFirestore.instance;
  StreamSubscription? _sub;

  ThreadNotifier(this.listingId, this.userId)
      : super(const ThreadState()) {
    _listen();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  String get _convId {
    final sorted = [_uid, userId.toString()]..sort();
    return '${listingId}_${sorted.join('_')}';
  }

  void _listen() {
    if (_uid.isEmpty) return;
    state = state.copyWith(isLoading: true);

    _sub = _db
        .collection('conversations')
        .doc(_convId)
        .collection('messages')
        .orderBy('created_at')
        .snapshots()
        .listen((snap) {
      final msgs = snap.docs.map((doc) {
        final data = doc.data();
        final ts = data['created_at'];
        return MessageModel(
          id: doc.id.hashCode,
          conversationId: _convId.hashCode,
          senderId: (data['sender_id'] ?? '').hashCode,
          body: data['body'] ?? '',
          isRead: data['is_read'] ?? false,
          createdAt: ts is dynamic && ts != null
              ? (ts as dynamic).toDate().toIso8601String()
              : null,
        );
      }).toList();

      state = state.copyWith(isLoading: false, messages: msgs);
    }, onError: (e) {
      debugPrint('Thread stream error: $e');
      state = state.copyWith(isLoading: false);
    });
  }

  Future<bool> sendMessage(String body) async {
    if (_uid.isEmpty || body.trim().isEmpty) return false;
    state = state.copyWith(isSending: true);

    try {
      final convRef = _db.collection('conversations').doc(_convId);

      // Create/update conversation doc
      await convRef.set({
        'listing_id': listingId.toString(),
        'participants': [_uid, userId.toString()],
        'last_message': body,
        'last_sender_id': _uid,
        'updated_at': FieldValue.serverTimestamp(),
        'unread_count_${userId.toString()}': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // Add message
      await convRef.collection('messages').add({
        'sender_id': _uid,
        'body': body,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      debugPrint('sendMessage error: $e');
      state = state.copyWith(isSending: false);
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final threadProvider = StateNotifierProvider.family<ThreadNotifier,
    ThreadState, ({int listingId, int userId})>((ref, params) {
  return ThreadNotifier(params.listingId, params.userId);
});
