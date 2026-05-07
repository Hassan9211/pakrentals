import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  // 15 second timeout for all Firebase calls
  static const _timeout = Duration(seconds: 15);

  // ── Current user ───────────────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Register ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final cred = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(_timeout,
              onTimeout: () =>
                  throw 'Connection timed out. Check your internet.');

      await cred.user?.updateDisplayName(name);

      final userData = {
        'id': cred.user!.uid,
        'name': name,
        'email': email.trim(),
        'phone': phone,
        'role': 'user',
        'is_verified': false,
        'cnic_status': 'none',
        'payment_methods': [],
        'created_at': FieldValue.serverTimestamp(),
      };

      // Save to Firestore — non-blocking, don't fail auth if this fails
      try {
        await _db
            .collection('users')
            .doc(cred.user!.uid)
            .set(userData)
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('Firestore save failed (non-fatal): $e');
        // Auth succeeded — return user data even without Firestore
      }

      return userData;
    } on FirebaseAuthException catch (e) {
      throw _parseAuthError(e);
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(_timeout,
              onTimeout: () =>
                  throw 'Connection timed out. Check your internet.');

      // Fetch Firestore profile — fallback to Auth data if fails
      Map<String, dynamic>? firestoreData;
      try {
        final doc = await _db
            .collection('users')
            .doc(cred.user!.uid)
            .get()
            .timeout(const Duration(seconds: 8));
        if (doc.exists) {
          firestoreData = {'id': cred.user!.uid, ...doc.data()!};
        }
      } catch (e) {
        debugPrint('Firestore fetch failed (non-fatal): $e');
      }

      // Return Firestore data if available, else build from Auth
      return firestoreData ?? {
        'id': cred.user!.uid,
        'name': cred.user!.displayName ?? email.split('@').first,
        'email': email.trim(),
        'role': 'user',
        'is_verified': cred.user!.emailVerified,
        'cnic_status': 'none',
        'payment_methods': [],
      };
    } on FirebaseAuthException catch (e) {
      throw _parseAuthError(e);
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  static Future<void> logout() => _auth.signOut();

  // ── Update profile ─────────────────────────────────────────────────────────
  static Future<void> updateProfile(Map<String, dynamic> data) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    if (data['name'] != null) {
      await currentUser?.updateDisplayName(data['name']);
    }

    await _db
        .collection('users')
        .doc(uid)
        .update(data)
        .timeout(_timeout);
  }

  // ── Activate host code ─────────────────────────────────────────────────────
  static Future<bool> activateHostCode(String code) async {
    const hostCode = 'PAKHOST2024';
    if (code.trim().toUpperCase() != hostCode) return false;

    final uid = currentUser?.uid;
    if (uid == null) return false;

    await _db
        .collection('users')
        .doc(uid)
        .update({'role': 'admin'}).timeout(_timeout);
    return true;
  }

  // ── Get user data from Firestore ───────────────────────────────────────────
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(_timeout);
      if (!doc.exists) return null;
      return {'id': uid, ...doc.data()!};
    } catch (e) {
      debugPrint('getUserData error: $e');
      return null;
    }
  }

  // ── Error parser ───────────────────────────────────────────────────────────
  static String _parseAuthError(FirebaseAuthException e) {
    debugPrint('FirebaseAuthException: ${e.code} — ${e.message}');
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Check your WiFi/data.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Contact support.';
      case 'configuration-not-found':
        return 'Firebase not configured correctly. Contact support.';
      default:
        return e.message ?? 'Authentication failed. (${e.code})';
    }
  }
}
