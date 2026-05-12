import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ── Background message handler (must be top-level) ───────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background FCM: ${message.notification?.title}');
}

// ── Local notifications channel ───────────────────────────────────────────────
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'pakrentals_high',
  'PakRentals Notifications',
  description: 'Booking requests, approvals, messages',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotif =
    FlutterLocalNotificationsPlugin();

class FirebaseService {
  static final _db = FirebaseFirestore.instance;
  static Function(RemoteMessage)? _onNotificationTap;

  static Future<void> init() async {
    // 1. Init Firebase
    await Firebase.initializeApp();

    // 2. FCM background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Local notifications setup
    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        // Handle local notification tap
        if (_onNotificationTap != null && details.payload != null) {
          // You could parse the payload here if needed
        }
      },
    );

    // 4. Create Android notification channel
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Request permissions for high importance notifications (Android 13+)
    if (Platform.isAndroid) {
      final androidPlugin = _localNotif.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }

    // 5. Request FCM permission
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint(
        'User notification permission status: ${settings.authorizationStatus}');

    // 6. Foreground message handler — show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotif.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: message.data['booking_id'],
        );
      }
    });

    // 7. Handle notification click when app is in background but still running
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (_onNotificationTap != null) {
        _onNotificationTap!(message);
      }
    });

    // 8. Save FCM token when user is already logged in at startup
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await saveFcmToken(user.uid);
    }

    // 9. Listen for auth changes → save token on login
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await saveFcmToken(user.uid);
      }
    });

    // 10. Listen for token refresh → update Firestore
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _saveTokenToFirestore(uid, newToken);
      }
    });
  }

  /// Register a callback to handle notification taps
  static void setNotificationTapHandler(Function(RemoteMessage) handler) {
    _onNotificationTap = handler;

    // Check if app was opened from a terminated state via a notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        handler(message);
      }
    });
  }

  /// Save current FCM token to Firestore for this user
  static Future<void> saveFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveTokenToFirestore(uid, token);
        debugPrint('FCM token saved for $uid');
      }
    } catch (e) {
      debugPrint('saveFcmToken error (non-fatal): $e');
    }
  }

  static Future<void> _saveTokenToFirestore(String uid, String token) async {
    try {
      await _db.collection('users').doc(uid).set(
        {
          'fcm_token': token,
          'fcm_token_updated_at': FieldValue.serverTimestamp(),
          'platform': 'android', // For debugging
        },
        SetOptions(merge: true),
      ).timeout(const Duration(seconds: 8));
      debugPrint('FCM Token successfully synced to Firestore for $uid');
    } catch (e) {
      debugPrint('_saveTokenToFirestore error: $e');
    }
  }

  /// Remove FCM token on logout (so no notifications after sign-out)
  static Future<void> removeFcmToken() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _db.collection('users').doc(uid).update({
          'fcm_token': FieldValue.delete(),
        }).timeout(const Duration(seconds: 5));
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('removeFcmToken error (non-fatal): $e');
    }
  }

  /// Get current FCM token
  static Future<String?> getFcmToken() => FirebaseMessaging.instance.getToken();

  /// Show a local notification immediately (for in-app events)
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }
}
