import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/storage/auth_storage.dart';
import '../models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AUTH STATE
// ─────────────────────────────────────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTH NOTIFIER — MOCK MODE
// User data is persisted in SharedPreferences so it survives app restarts
// ─────────────────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthStorage _storage;
  static const _userKey = 'mock_user_data';

  AuthNotifier(this._storage) : super(const AuthState()) {
    _checkAuth();
  }

  // ── Restore session on app start ───────────────────────────────────────────
  Future<void> _checkAuth() async {
    final hasToken = await _storage.hasToken();
    if (!hasToken) return;

    // Restore the actual user who logged in / registered
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        final user = UserModel.fromJson(jsonDecode(userJson));
        state = state.copyWith(user: user, isAuthenticated: true);
        return;
      } catch (_) {}
    }
    // Fallback: clear stale token
    await _storage.deleteToken();
  }

  // ── Save user to local storage ─────────────────────────────────────────────
  Future<void> _persistUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // ── Clear user from local storage ─────────────────────────────────────────
  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password,
      {String role = 'user'}) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 700));

    if (email.trim().isEmpty || password.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Invalid credentials.');
      return false;
    }

    // Check if a previously registered user exists in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getString(_userKey);
    UserModel? existingUser;
    if (existingJson != null) {
      try {
        final decoded = UserModel.fromJson(jsonDecode(existingJson));
        if (decoded.email == email.trim()) {
          existingUser = decoded;
        }
      } catch (_) {}
    }

    // If existing user found, use their saved data but update role if changed
    final UserModel user;
    if (existingUser != null) {
      // Update role if user selected a different one on login
      user = UserModel(
        id: existingUser.id,
        name: existingUser.name,
        email: existingUser.email,
        phone: existingUser.phone,
        photo: existingUser.photo,
        cnic: existingUser.cnic,
        cnicFrontPhoto: existingUser.cnicFrontPhoto,
        cnicBackPhoto: existingUser.cnicBackPhoto,
        cnicStatus: existingUser.cnicStatus,
        paymentMethods: existingUser.paymentMethods,
        role: role, // apply selected role
        isVerified: existingUser.isVerified,
        city: existingUser.city,
        bio: existingUser.bio,
        rating: existingUser.rating,
        reviewsCount: existingUser.reviewsCount,
      );
    } else {
      // New user — create from email + selected role
      final name = email.split('@').first;
      final displayName = name[0].toUpperCase() +
          name.substring(1).replaceAll(RegExp(r'[^a-zA-Z]'), ' ').trim();
      user = UserModel(
        id: email.hashCode.abs() % 9000 + 1000,
        name: displayName,
        email: email.trim(),
        role: role,
        isVerified: false,
      );
    }

    await _storage.saveToken('mock_token_${user.id}');
    await _persistUser(user);

    state = state.copyWith(
      isLoading: false,
      user: user,
      isAuthenticated: true,
    );
    return true;
  }

  // ── Register ───────────────────────────────────────────────────────────────
  Future<bool> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 800));

    final user = UserModel(
      id: (data['email'] as String).hashCode.abs() % 9000 + 1000,
      name: data['name'] ?? 'New User',
      email: data['email'] ?? '',
      phone: data['phone'],
      role: data['role'] ?? 'user',
      isVerified: false,
      city: null,
    );

    await _storage.saveToken('mock_token_${user.id}');
    await _persistUser(user);

    state = state.copyWith(
      isLoading: false,
      user: user,
      isAuthenticated: true,
    );
    return true;
  }

  // ── Update profile ─────────────────────────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(milliseconds: 500));

    final current = state.user!;
    final updated = UserModel(
      id: current.id,
      name: data['name'] ?? current.name,
      email: current.email,
      phone: data['phone'] ?? current.phone,
      role: current.role,
      isVerified: current.isVerified,
      city: data['city'] ?? current.city,
      bio: data['bio'] ?? current.bio,
      photo: data['photo'] ?? current.photo,
      rating: current.rating,
      reviewsCount: current.reviewsCount,
    );

    await _persistUser(updated);
    state = state.copyWith(isLoading: false, user: updated);
    return true;
  }

  // ── Payment Methods ────────────────────────────────────────────────────────
  Future<bool> addPaymentMethod(SavedPaymentMethod method) async {
    final current = state.user;
    if (current == null) return false;

    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));

    // If first method, make it default
    final isFirst = current.paymentMethods.isEmpty;
    final newMethod = SavedPaymentMethod(
      id: method.id,
      type: method.type,
      title: method.title,
      account: method.account,
      isDefault: isFirst ? true : method.isDefault,
    );

    final updated = _copyUserWith(current,
        paymentMethods: [...current.paymentMethods, newMethod]);
    await _persistUser(updated);
    state = state.copyWith(isLoading: false, user: updated);
    return true;
  }

  Future<void> removePaymentMethod(String methodId) async {
    final current = state.user;
    if (current == null) return;

    var methods =
        current.paymentMethods.where((m) => m.id != methodId).toList();

    // If removed method was default, make first remaining one default
    final hadDefault =
        current.paymentMethods.any((m) => m.id == methodId && m.isDefault);
    if (hadDefault && methods.isNotEmpty) {
      methods = [
        SavedPaymentMethod(
          id: methods.first.id,
          type: methods.first.type,
          title: methods.first.title,
          account: methods.first.account,
          isDefault: true,
        ),
        ...methods.skip(1),
      ];
    }

    final updated = _copyUserWith(current, paymentMethods: methods);
    await _persistUser(updated);
    state = state.copyWith(user: updated);
  }

  Future<void> setDefaultPaymentMethod(String methodId) async {
    final current = state.user;
    if (current == null) return;

    final methods = current.paymentMethods.map((m) {
      return SavedPaymentMethod(
        id: m.id,
        type: m.type,
        title: m.title,
        account: m.account,
        isDefault: m.id == methodId,
      );
    }).toList();

    final updated = _copyUserWith(current, paymentMethods: methods);
    await _persistUser(updated);
    state = state.copyWith(user: updated);
  }

  // Helper to copy user with new payment methods list
  UserModel _copyUserWith(UserModel u,
      {List<SavedPaymentMethod>? paymentMethods}) {
    return UserModel(
      id: u.id,
      name: u.name,
      email: u.email,
      phone: u.phone,
      photo: u.photo,
      cnic: u.cnic,
      cnicFrontPhoto: u.cnicFrontPhoto,
      cnicBackPhoto: u.cnicBackPhoto,
      cnicStatus: u.cnicStatus,
      paymentMethods: paymentMethods ?? u.paymentMethods,
      role: u.role,
      isVerified: u.isVerified,
      city: u.city,
      bio: u.bio,
      rating: u.rating,
      reviewsCount: u.reviewsCount,
    );
  }

  // ── Update CNIC ────────────────────────────────────────────────────────────
  Future<bool> updateCnic({
    required String cnicNumber,
    required String frontPhotoPath,
    required String backPhotoPath,
  }) async {
    final current = state.user;
    if (current == null) return false;

    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 800));

    final updated = UserModel(
      id: current.id,
      name: current.name,
      email: current.email,
      phone: current.phone,
      photo: current.photo,
      cnic: cnicNumber,
      cnicFrontPhoto: frontPhotoPath,
      cnicBackPhoto: backPhotoPath,
      cnicStatus: 'pending', // submitted — awaiting admin review
      role: current.role,
      isVerified: current.isVerified,
      city: current.city,
      bio: current.bio,
      rating: current.rating,
      reviewsCount: current.reviewsCount,
    );

    await _persistUser(updated);
    state = state.copyWith(isLoading: false, user: updated);
    return true;
  }

  // ── Update photo (local file path) ─────────────────────────────────────────
  Future<void> updatePhoto(String localPath) async {
    final current = state.user;
    if (current == null) return;
    final updated = UserModel(
      id: current.id,
      name: current.name,
      email: current.email,
      phone: current.phone,
      role: current.role,
      isVerified: current.isVerified,
      city: current.city,
      bio: current.bio,
      photo: localPath,
      rating: current.rating,
      reviewsCount: current.reviewsCount,
    );
    await _persistUser(updated);
    state = state.copyWith(user: updated);
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _storage.deleteToken();
    await _clearUser();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(authStorageProvider);
  return AuthNotifier(storage);
});
