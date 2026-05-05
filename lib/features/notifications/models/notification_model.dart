class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.data,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final notifData = json['data'] as Map<String, dynamic>? ?? {};
    return NotificationModel(
      id: json['id'] ?? 0,
      type: json['type'] ?? notifData['type'] ?? 'general',
      title: json['title'] ?? notifData['title'] ?? 'Notification',
      body: json['body'] ?? notifData['body'] ?? notifData['message'] ?? '',
      isRead: json['read_at'] != null || json['is_read'] == true,
      data: notifData,
      createdAt: json['created_at'],
    );
  }
}
