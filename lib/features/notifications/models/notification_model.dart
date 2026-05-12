class NotificationModel {
  final int id;
  final String? firestoreId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String? bookingId;
  final Map<String, dynamic>? data;
  final String? createdAt;

  NotificationModel({
    required this.id,
    this.firestoreId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.bookingId,
    this.data,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final notifData = json['data'] as Map<String, dynamic>? ?? {};
    return NotificationModel(
      id: json['id'] ?? 0,
      firestoreId: json['firestore_id'],
      type: json['type'] ?? notifData['type'] ?? 'general',
      title: json['title'] ?? notifData['title'] ?? 'Notification',
      body: json['body'] ?? notifData['body'] ?? notifData['message'] ?? '',
      isRead: json['read_at'] != null || json['is_read'] == true,
      bookingId: json['booking_id']?.toString(),
      data: notifData,
      createdAt: json['created_at'],
    );
  }
}
