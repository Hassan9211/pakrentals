import '../../auth/models/user_model.dart';

class ConversationModel {
  final int id;
  final String? firestoreId;
  final String listingId;
  final String listingTitle;
  final String? listingImage;
  final UserModel? otherUser;
  final MessageModel? lastMessage;
  final int unreadCount;

  ConversationModel({
    required this.id,
    this.firestoreId,
    required this.listingId,
    required this.listingTitle,
    this.listingImage,
    this.otherUser,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? 0,
      firestoreId: json['firestore_id'],
      listingId: json['listing_id']?.toString() ?? '',
      listingTitle: json['listing']?['title'] ?? json['listing_title'] ?? '',
      listingImage: json['listing']?['images']?[0] ?? json['listing_image'],
      otherUser: json['other_user'] != null
          ? UserModel.fromJson(json['other_user'])
          : null,
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class MessageModel {
  final int id;
  final String? firestoreId;
  final String conversationId;
  final String senderId;
  final String body;
  final bool isRead;
  final String? createdAt;
  final UserModel? sender;

  MessageModel({
    required this.id,
    this.firestoreId,
    required this.conversationId,
    required this.senderId,
    required this.body,
    this.isRead = false,
    this.createdAt,
    this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      firestoreId: json['firestore_id'],
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      body: json['body'] ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at'],
      sender: json['sender'] != null ? UserModel.fromJson(json['sender']) : null,
    );
  }
}
