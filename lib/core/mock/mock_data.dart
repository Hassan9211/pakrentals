// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA — only static/seed data kept here
// All user-generated data (listings, bookings, messages) comes from Firebase
// ─────────────────────────────────────────────────────────────────────────────

import '../../features/auth/models/user_model.dart';
import '../../features/bookings/models/booking_model.dart';
import '../../features/listings/models/category_model.dart';
import '../../features/listings/models/listing_model.dart';
import '../../features/listings/models/review_model.dart';
import '../../features/messages/models/message_model.dart';
import '../../features/notifications/models/notification_model.dart';

// ── Categories — static seed data ────────────────────────────────────────────
final mockCategories = [
  CategoryModel(id: 1, name: 'Vehicles', icon: '🚗', listingsCount: 0),
  CategoryModel(id: 2, name: 'Electronics', icon: '📷', listingsCount: 0),
  CategoryModel(id: 3, name: 'Property', icon: '🏠', listingsCount: 0),
  CategoryModel(id: 4, name: 'Tools', icon: '🔧', listingsCount: 0),
  CategoryModel(id: 5, name: 'Sports', icon: '⚽', listingsCount: 0),
  CategoryModel(id: 6, name: 'Furniture', icon: '🛋️', listingsCount: 0),
  CategoryModel(id: 7, name: 'Clothing', icon: '👗', listingsCount: 0),
  CategoryModel(id: 8, name: 'Events', icon: '🎉', listingsCount: 0),
];

// ── All below are empty — data comes from Firebase ────────────────────────────
final mockUsers = <UserModel>[];
final mockListings = <ListingModel>[];
final mockReviews = <ReviewModel>[];
final mockBookings = <BookingModel>[];
final mockHostRequests = <BookingModel>[];
final mockConversations = <ConversationModel>[];
final mockMessages = <MessageModel>[];
final mockNotifications = <NotificationModel>[];

final mockAdminStats = <String, dynamic>{
  'total_users': 0,
  'total_listings': 0,
  'total_bookings': 0,
  'total_revenue': 0,
  'pending_reports': 0,
  'active_listings': 0,
};
