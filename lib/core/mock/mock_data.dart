// ─────────────────────────────────────────────────────────────────────────────
// MOCK DATA — used when backend is not connected
// Replace with real API calls once backend is ready
// ─────────────────────────────────────────────────────────────────────────────

import '../../features/auth/models/user_model.dart';
import '../../features/bookings/models/booking_model.dart';
import '../../features/listings/models/category_model.dart';
import '../../features/listings/models/listing_model.dart';
import '../../features/listings/models/review_model.dart';
import '../../features/messages/models/message_model.dart';
import '../../features/notifications/models/notification_model.dart';

// ── Users ─────────────────────────────────────────────────────────────────────
final mockUsers = [
  UserModel(
    id: 1,
    name: 'Hassan Raza',
    email: 'hassan@example.com',
    phone: '03087293939',
    role: 'user',
    isVerified: true,
    city: 'Lahore',
    bio: 'Renter from Lahore',
  ),
  UserModel(
    id: 2,
    name: 'Ali Khan',
    email: 'ali@example.com',
    phone: '03001234567',
    role: 'host',
    isVerified: true,
    city: 'Karachi',
    bio: 'Host with multiple listings',
    rating: 4.8,
    reviewsCount: 24,
  ),
  UserModel(
    id: 3,
    name: 'Sara Ahmed',
    email: 'sara@example.com',
    phone: '03219876543',
    role: 'host',
    isVerified: true,
    city: 'Islamabad',
    bio: 'Camera & electronics host',
    rating: 4.6,
    reviewsCount: 12,
  ),
];

// ── Categories ────────────────────────────────────────────────────────────────
final mockCategories = [
  CategoryModel(id: 1, name: 'Vehicles', icon: '🚗', listingsCount: 120),
  CategoryModel(id: 2, name: 'Electronics', icon: '📷', listingsCount: 85),
  CategoryModel(id: 3, name: 'Property', icon: '🏠', listingsCount: 200),
  CategoryModel(id: 4, name: 'Tools', icon: '🔧', listingsCount: 60),
  CategoryModel(id: 5, name: 'Sports', icon: '⚽', listingsCount: 45),
  CategoryModel(id: 6, name: 'Furniture', icon: '🛋️', listingsCount: 70),
  CategoryModel(id: 7, name: 'Clothing', icon: '👗', listingsCount: 30),
  CategoryModel(id: 8, name: 'Events', icon: '🎉', listingsCount: 55),
];

// ── Listings ──────────────────────────────────────────────────────────────────
final mockListings = [
  ListingModel(
    id: 1,
    title: 'Toyota Corolla 2020 — Daily Rental',
    description:
        'Well-maintained Toyota Corolla 2020 available for daily rental. Full tank provided. AC works perfectly. Suitable for city and highway travel.',
    pricePerDay: 4500,
    city: 'Lahore',
    address: 'DHA Phase 5, Lahore',
    images: [
      'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=800',
      'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=800',
    ],
    status: 'active',
    isFeatured: true,
    avgRating: 4.7,
    reviewsCount: 18,
    isSaved: false,
    category: mockCategories[0],
    host: mockUsers[1],
    createdAt: '2024-01-15T10:00:00Z',
  ),
  ListingModel(
    id: 2,
    title: 'Sony A7III Camera Kit',
    description:
        'Professional Sony A7III mirrorless camera with 24-70mm lens, 2 batteries, charger, and carrying bag. Perfect for events and photography projects.',
    pricePerDay: 3500,
    city: 'Karachi',
    address: 'Clifton Block 4, Karachi',
    images: [
      'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
      'https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=800',
    ],
    status: 'active',
    isFeatured: true,
    avgRating: 4.9,
    reviewsCount: 31,
    isSaved: true,
    category: mockCategories[1],
    host: mockUsers[2],
    createdAt: '2024-01-20T10:00:00Z',
  ),
  ListingModel(
    id: 3,
    title: '2BHK Furnished Apartment — Short Stay',
    description:
        'Fully furnished 2-bedroom apartment in F-7. WiFi, AC, kitchen, and parking included. Ideal for short stays and business trips.',
    pricePerDay: 8000,
    city: 'Islamabad',
    address: 'F-7/2, Islamabad',
    images: [
      'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
    ],
    status: 'active',
    isFeatured: true,
    avgRating: 4.5,
    reviewsCount: 9,
    isSaved: false,
    category: mockCategories[2],
    host: mockUsers[1],
    createdAt: '2024-02-01T10:00:00Z',
  ),
  ListingModel(
    id: 4,
    title: 'Honda CB150F Motorcycle',
    description:
        'Honda CB150F in excellent condition. Fuel efficient and great for city commuting. Helmet included.',
    pricePerDay: 1200,
    city: 'Lahore',
    address: 'Gulberg III, Lahore',
    images: [
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
    ],
    status: 'active',
    isFeatured: false,
    avgRating: 4.3,
    reviewsCount: 7,
    isSaved: false,
    category: mockCategories[0],
    host: mockUsers[1],
    createdAt: '2024-02-10T10:00:00Z',
  ),
  ListingModel(
    id: 5,
    title: 'DJI Mavic Air 2 Drone',
    description:
        'DJI Mavic Air 2 drone with 3 batteries, ND filters, and carrying case. 4K video, 48MP photos. Perfect for aerial photography.',
    pricePerDay: 5000,
    city: 'Islamabad',
    address: 'Blue Area, Islamabad',
    images: [
      'https://images.unsplash.com/photo-1473968512647-3e447244af8f?w=800',
    ],
    status: 'active',
    isFeatured: true,
    avgRating: 4.8,
    reviewsCount: 15,
    isSaved: true,
    category: mockCategories[1],
    host: mockUsers[2],
    createdAt: '2024-02-15T10:00:00Z',
  ),
  ListingModel(
    id: 6,
    title: 'Bosch Power Drill Set',
    description:
        'Professional Bosch power drill with full accessory set. Ideal for home renovation and construction projects.',
    pricePerDay: 800,
    city: 'Rawalpindi',
    address: 'Saddar, Rawalpindi',
    images: [
      'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=800',
    ],
    status: 'active',
    isFeatured: false,
    avgRating: 4.2,
    reviewsCount: 5,
    isSaved: false,
    category: mockCategories[3],
    host: mockUsers[1],
    createdAt: '2024-03-01T10:00:00Z',
  ),
  ListingModel(
    id: 7,
    title: 'Suzuki Alto 2022 — Self Drive',
    description:
        'Fuel-efficient Suzuki Alto 2022 for self-drive rental. Perfect for city errands and short trips.',
    pricePerDay: 2800,
    city: 'Karachi',
    address: 'North Nazimabad, Karachi',
    images: [
      'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?w=800',
    ],
    status: 'active',
    isFeatured: false,
    avgRating: 4.4,
    reviewsCount: 11,
    isSaved: false,
    category: mockCategories[0],
    host: mockUsers[2],
    createdAt: '2024-03-05T10:00:00Z',
  ),
  ListingModel(
    id: 8,
    title: 'Canon EOS 90D DSLR',
    description:
        'Canon EOS 90D with 18-135mm lens. Great for wildlife, sports, and portrait photography.',
    pricePerDay: 2500,
    city: 'Lahore',
    address: 'Model Town, Lahore',
    images: [
      'https://images.unsplash.com/photo-1510127034890-ba27508e9f1c?w=800',
    ],
    status: 'active',
    isFeatured: false,
    avgRating: 4.6,
    reviewsCount: 8,
    isSaved: false,
    category: mockCategories[1],
    host: mockUsers[1],
    createdAt: '2024-03-10T10:00:00Z',
  ),
];

// ── Reviews ───────────────────────────────────────────────────────────────────
final mockReviews = [
  ReviewModel(
    id: 1,
    listingId: 1,
    userId: 1,
    rating: 5,
    comment: 'Excellent car, very clean and well maintained. Host was very cooperative.',
    user: mockUsers[0],
    createdAt: '2024-02-01T10:00:00Z',
  ),
  ReviewModel(
    id: 2,
    listingId: 1,
    userId: 3,
    rating: 4,
    comment: 'Good experience overall. Car was in good condition. Would rent again.',
    user: mockUsers[2],
    createdAt: '2024-02-15T10:00:00Z',
  ),
  ReviewModel(
    id: 3,
    listingId: 2,
    userId: 1,
    rating: 5,
    comment: 'Amazing camera kit! Everything was in perfect condition. Highly recommended.',
    user: mockUsers[0],
    createdAt: '2024-03-01T10:00:00Z',
  ),
];

// ── Bookings ──────────────────────────────────────────────────────────────────
// renterBookings = bookings where current user is the RENTER
// hostRequests   = bookings where current user is the HOST
final mockBookings = [
  BookingModel(
    id: 1,
    listingId: 1,
    renterId: 1,
    hostId: 2,           // Ali Khan is host of listing 1
    startDate: '2024-04-10',
    endDate: '2024-04-13',
    totalDays: 3,
    totalPrice: 13500,
    status: 'completed',
    paymentMethod: 'jazzcash',
    paymentStatus: 'paid',
    listing: mockListings[0],
    renter: mockUsers[0],
    createdAt: '2024-04-05T10:00:00Z',
  ),
  BookingModel(
    id: 2,
    listingId: 2,
    renterId: 1,
    hostId: 3,           // Sara Ahmed is host of listing 2
    startDate: '2024-05-01',
    endDate: '2024-05-03',
    totalDays: 2,
    totalPrice: 7000,
    status: 'pending',
    listing: mockListings[1],
    renter: mockUsers[0],
    createdAt: '2024-04-25T10:00:00Z',
  ),
  BookingModel(
    id: 3,
    listingId: 4,
    renterId: 1,
    hostId: 2,           // Ali Khan is host of listing 4
    startDate: '2024-05-15',
    endDate: '2024-05-16',
    totalDays: 1,
    totalPrice: 1200,
    status: 'pending',
    listing: mockListings[3],
    renter: mockUsers[0],
    createdAt: '2024-05-10T10:00:00Z',
  ),
];

// Host requests — bookings on the host's own listings
final mockHostRequests = [
  BookingModel(
    id: 4,
    listingId: 1,
    renterId: 3,
    hostId: 2,           // Ali Khan is host of listing 1
    startDate: '2024-05-20',
    endDate: '2024-05-22',
    totalDays: 2,
    totalPrice: 9000,
    status: 'pending',
    listing: mockListings[0],
    renter: mockUsers[2],
    createdAt: '2024-05-12T10:00:00Z',
  ),
];

// ── Conversations ─────────────────────────────────────────────────────────────
final mockConversations = [
  ConversationModel(
    id: 1,
    listingId: 1,
    listingTitle: 'Toyota Corolla 2020 — Daily Rental',
    otherUser: mockUsers[1],
    lastMessage: MessageModel(
      id: 3,
      conversationId: 1,
      senderId: 2,
      body: 'Sure, the car is available on those dates!',
      isRead: false,
      createdAt: '2024-05-10T14:30:00Z',
    ),
    unreadCount: 1,
  ),
  ConversationModel(
    id: 2,
    listingId: 2,
    listingTitle: 'Sony A7III Camera Kit',
    otherUser: mockUsers[2],
    lastMessage: MessageModel(
      id: 5,
      conversationId: 2,
      senderId: 1,
      body: 'Can I pick it up from your location?',
      isRead: true,
      createdAt: '2024-05-09T11:00:00Z',
    ),
    unreadCount: 0,
  ),
];

// ── Messages (thread) ─────────────────────────────────────────────────────────
final mockMessages = [
  MessageModel(
    id: 1,
    conversationId: 1,
    senderId: 1,
    body: 'Hi, is the car available from April 10 to 13?',
    isRead: true,
    createdAt: '2024-05-10T14:00:00Z',
    sender: mockUsers[0],
  ),
  MessageModel(
    id: 2,
    conversationId: 1,
    senderId: 2,
    body: 'Hello! Yes it is available. What time would you like to pick it up?',
    isRead: true,
    createdAt: '2024-05-10T14:15:00Z',
    sender: mockUsers[1],
  ),
  MessageModel(
    id: 3,
    conversationId: 1,
    senderId: 2,
    body: 'Sure, the car is available on those dates!',
    isRead: false,
    createdAt: '2024-05-10T14:30:00Z',
    sender: mockUsers[1],
  ),
];

// ── Notifications ─────────────────────────────────────────────────────────────
final mockNotifications = [
  NotificationModel(
    id: 1,
    type: 'booking_approved',
    title: 'Booking Approved!',
    body: 'Your booking for Sony A7III Camera Kit has been approved.',
    isRead: false,
    createdAt: '2024-05-10T10:00:00Z',
  ),
  NotificationModel(
    id: 2,
    type: 'booking_request',
    title: 'New Booking Request',
    body: 'Sara Ahmed has requested to book your Toyota Corolla.',
    isRead: false,
    createdAt: '2024-05-12T09:00:00Z',
  ),
  NotificationModel(
    id: 3,
    type: 'payment',
    title: 'Payment Received',
    body: 'PKR 13,500 payment received for booking #1.',
    isRead: true,
    createdAt: '2024-04-10T08:00:00Z',
  ),
  NotificationModel(
    id: 4,
    type: 'message',
    title: 'New Message',
    body: 'Ali Khan sent you a message about Toyota Corolla.',
    isRead: true,
    createdAt: '2024-05-10T14:30:00Z',
  ),
];

// ── Admin stats ───────────────────────────────────────────────────────────────
final mockAdminStats = {
  'total_users': 1240,
  'total_listings': 856,
  'total_bookings': 3421,
  'total_revenue': 4850000,
  'pending_reports': 12,
  'active_listings': 720,
};
