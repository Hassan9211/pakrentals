import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

const String kBaseUrl = 'http://127.0.0.1:8000/api'; // Change to your server URL
const String kStorageUrl = 'http://127.0.0.1:8000/storage';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: kBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(PrettyDioLogger(
      requestHeader: false,
      requestBody: true,
      responseBody: true,
      error: true,
      compact: true,
    ));
  }

  Dio get dio => _dio;

  // Auth
  Future<Response> register(Map<String, dynamic> data) =>
      _dio.post('/register', data: data);

  Future<Response> login(Map<String, dynamic> data) =>
      _dio.post('/login', data: data);

  Future<Response> logout() => _dio.post('/logout');

  Future<Response> getUser() => _dio.get('/user');

  Future<Response> updateUser(Map<String, dynamic> data) =>
      _dio.put('/user', data: data);

  Future<Response> uploadPhoto(FormData formData) =>
      _dio.post('/user/photo', data: formData);

  // Categories
  Future<Response> getCategories() => _dio.get('/categories');

  // Listings
  Future<Response> getListings({Map<String, dynamic>? params}) =>
      _dio.get('/listings', queryParameters: params);

  Future<Response> getFeaturedListings() => _dio.get('/listings/featured');

  Future<Response> getListing(int id) => _dio.get('/listings/$id');

  Future<Response> getListingReviews(int id) =>
      _dio.get('/listings/$id/reviews');

  Future<Response> getListingAvailability(int id) =>
      _dio.get('/listings/$id/availability');

  // Wishlist
  Future<Response> getWishlist() => _dio.get('/wishlist');

  Future<Response> toggleWishlist(int listingId) =>
      _dio.post('/wishlist/$listingId');

  // Bookings
  Future<Response> getBookings() => _dio.get('/bookings');

  Future<Response> createBooking(Map<String, dynamic> data) =>
      _dio.post('/bookings', data: data);

  Future<Response> approveBooking(int id) =>
      _dio.post('/bookings/$id/approve');

  Future<Response> rejectBooking(int id) =>
      _dio.post('/bookings/$id/reject');

  Future<Response> payBooking(int id, Map<String, dynamic> data) =>
      _dio.post('/bookings/$id/pay', data: data);

  Future<Response> completeBooking(int id) =>
      _dio.post('/bookings/$id/complete');

  // Messages
  Future<Response> getConversations() => _dio.get('/conversations');

  Future<Response> getConversation(int listingId, int userId) =>
      _dio.get('/conversations/$listingId/$userId');

  Future<Response> sendMessage(Map<String, dynamic> data) =>
      _dio.post('/messages', data: data);

  Future<Response> markMessagesRead(int conversationId) =>
      _dio.post('/messages/$conversationId/read');

  // Notifications
  Future<Response> getNotifications() => _dio.get('/notifications');

  Future<Response> markNotificationRead(int id) =>
      _dio.post('/notifications/$id/read');

  // Reviews
  Future<Response> createReview(Map<String, dynamic> data) =>
      _dio.post('/reviews', data: data);

  // Reports
  Future<Response> createReport(Map<String, dynamic> data) =>
      _dio.post('/reports', data: data);

  // Admin
  Future<Response> getAdminStats() => _dio.get('/admin/stats');

  Future<Response> getAdminUsers({Map<String, dynamic>? params}) =>
      _dio.get('/admin/users', queryParameters: params);

  Future<Response> getAdminListings({Map<String, dynamic>? params}) =>
      _dio.get('/admin/listings', queryParameters: params);

  Future<Response> getAdminBookings({Map<String, dynamic>? params}) =>
      _dio.get('/admin/bookings', queryParameters: params);

  Future<Response> getAdminReports({Map<String, dynamic>? params}) =>
      _dio.get('/admin/reports', queryParameters: params);

  Future<Response> approveListing(int id) =>
      _dio.post('/admin/listings/$id/approve');

  Future<Response> rejectListing(int id) =>
      _dio.post('/admin/listings/$id/reject');

  Future<Response> processAdminPayout(int id) =>
      _dio.post('/admin/payouts/$id/process');
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});
