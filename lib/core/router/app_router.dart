import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/screens/admin_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/bookings/screens/booking_detail_screen.dart';
import '../../features/bookings/screens/bookings_screen.dart';
import '../../features/payments/screens/payment_screen.dart';
import '../../features/bookings/screens/create_booking_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/listings/screens/browse_screen.dart';
import '../../features/listings/screens/create_listing_screen.dart';
import '../../features/listings/screens/listing_detail_screen.dart';
import '../../features/listings/screens/my_listings_screen.dart';
import '../../features/messages/screens/chat_screen.dart';
import '../../features/messages/screens/messages_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/cnic_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/payment_methods_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../../shared/widgets/main_shell.dart';
import 'package:flutter/material.dart';

// ── RouterNotifier: bridges Riverpod auth state → GoRouter refresh ──────────
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _isAuthenticated = false;

  _RouterNotifier(this._ref) {
    // Listen to auth state changes and notify GoRouter to re-evaluate redirects
    _ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.isAuthenticated != next.isAuthenticated) {
        _isAuthenticated = next.isAuthenticated;
        notifyListeners();
      }
    });
    _isAuthenticated = _ref.read(authProvider).isAuthenticated;
  }

  bool get isAuthenticated => _isAuthenticated;
}

final _routerNotifierProvider = ChangeNotifierProvider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

// ── Routes that require login ────────────────────────────────────────────────
const _protectedRoutes = [
  '/bookings',
  '/booking/',
  '/payment/',
  '/messages',
  '/profile/edit',
  '/profile/cnic',
  '/profile/payment-methods',
  '/wishlist',
  '/admin',
  '/reports',
  '/create-listing',
  '/my-listings',
];

// ── Main router provider ─────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier, // re-runs redirect whenever auth changes
    redirect: (context, state) {
      final isAuth = notifier.isAuthenticated;
      final loc = state.uri.toString();

      // If on splash, let SplashScreen handle its own navigation
      if (loc == '/splash') return null;

      // Redirect unauthenticated users away from protected routes
      final isProtected = _protectedRoutes.any((r) => loc.startsWith(r));
      if (isProtected && !isAuth) return '/login';

      // If already authenticated and trying to visit login/register → go home
      if (isAuth && (loc == '/login' || loc == '/register')) return '/home';

      return null;
    },
    routes: [
      // ── Splash ──────────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Auth (no shell) ──────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // ── Main shell (bottom nav) ──────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/browse',
            builder: (context, state) {
              final catId = state.uri.queryParameters['category'];
              return BrowseScreen(
                initialCategoryId:
                    catId != null ? int.tryParse(catId) : null,
              );
            },
          ),
          GoRoute(
            path: '/bookings',
            builder: (_, __) => const BookingsScreen(),
          ),
          GoRoute(
            path: '/messages',
            builder: (_, __) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Detail / standalone routes (no shell) ───────────────────────
      GoRoute(
        path: '/listing/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ListingDetailScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/create-listing',
        builder: (_, __) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '/my-listings',
        builder: (_, __) => const MyListingsScreen(),
      ),
      GoRoute(
        path: '/payment/:bookingId',
        builder: (context, state) {
          final bookingId = int.parse(state.pathParameters['bookingId']!);
          final amount = double.tryParse(
                  state.uri.queryParameters['amount'] ?? '0') ??
              0;
          return PaymentScreen(bookingId: bookingId, amount: amount);
        },
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final isHost = state.uri.queryParameters['host'] == '1';
          return BookingDetailScreen(bookingId: id, isHost: isHost);
        },
      ),
      GoRoute(
        path: '/booking/create/:listingId',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['listingId']!);
          return CreateBookingScreen(listingId: id);
        },
      ),
      GoRoute(
        path: '/messages/:listingId/:userId',
        builder: (context, state) {
          final listingId =
              int.parse(state.pathParameters['listingId']!);
          final userId = int.parse(state.pathParameters['userId']!);
          return ChatScreen(listingId: listingId, userId: userId);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (_, __) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/cnic',
        builder: (_, __) => const CnicScreen(),
      ),
      GoRoute(
        path: '/profile/payment-methods',
        builder: (_, __) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (_, __) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Color(0xFFEF4444), size: 48),
            const SizedBox(height: 12),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
