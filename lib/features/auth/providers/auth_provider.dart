import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_auth_service.dart';
import '../../../core/firebase/storage_service.dart';
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
// AUTH NOTIFIER — Firebase Auth + Firestore
// ─────────────────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkAuth();
  }

  // ── Restore session on app start ───────────────────────────────────────────
  Future<void> _checkAuth() async {
    final firebaseUser = FirebaseAuthService.currentUser;
    if (firebaseUser == null) return;

    try {
      final data = await FirebaseAuthService.getUserData(firebaseUser.uid);

      // Determine role — admin by UID or email
      final isAdmin = firebaseUser.uid == _adminUid ||
          (firebaseUser.email?.toLowerCase() == _adminEmail);

      final userData = data ?? {
        'id': firebaseUser.uid,
        'name': firebaseUser.displayName ??
            firebaseUser.email?.split('@').first ?? 'User',
        'email': firebaseUser.email ?? '',
        'role': isAdmin ? 'admin' : 'user',
        'is_verified': firebaseUser.emailVerified,
        'cnic_status': 'none',
        'payment_methods': [],
      };

      // Override role if admin
      if (isAdmin) userData['role'] = 'admin';

      state = state.copyWith(
        user: UserModel.fromJson(userData),
        isAuthenticated: true,
      );
    } catch (_) {}
  }

  // Admin credentials — hardcoded for security
  static const _adminEmail = 'admin@pakrentals.com';
  static const _adminUid = 't41DI9ZHowUAsk9pgyFd7iJrTsA3';

  // ── Register ───────────────────────────────────────────────────────────────
  Future<bool> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userData = await FirebaseAuthService.register(
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        password: data['password'] ?? '',
        phone: data['phone'] ?? '',
      );

      if (userData != null) {
        state = state.copyWith(
          isLoading: false,
          user: UserModel.fromJson(userData),
          isAuthenticated: true,
        );
        return true;
      }
      state = state.copyWith(
          isLoading: false, error: 'Registration failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userData = await FirebaseAuthService.login(
        email: email,
        password: password,
      );

      if (userData != null) {
        // Force admin role for admin UID or email
        final isAdmin = FirebaseAuthService.currentUser?.uid == _adminUid ||
            email.trim().toLowerCase() == _adminEmail;
        if (isAdmin) userData['role'] = 'admin';

        state = state.copyWith(
          isLoading: false,
          user: UserModel.fromJson(userData),
          isAuthenticated: true,
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Login failed');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Update profile ─────────────────────────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await FirebaseAuthService.updateProfile(data);

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
        photo: current.photo,
        cnic: current.cnic,
        cnicFrontPhoto: current.cnicFrontPhoto,
        cnicBackPhoto: current.cnicBackPhoto,
        cnicStatus: current.cnicStatus,
        paymentMethods: current.paymentMethods,
        rating: current.rating,
        reviewsCount: current.reviewsCount,
      );

      state = state.copyWith(isLoading: false, user: updated);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Upload profile photo ───────────────────────────────────────────────────
  Future<void> updatePhoto(String localPath) async {
    final current = state.user;
    if (current == null) return;

    try {
      // Upload to Firebase Storage
      final url = await StorageService.uploadProfilePhoto(
          current.id.toString(), localPath);

      // Update Firestore
      await FirebaseAuthService.updateProfile({'photo': url});

      final updated = UserModel(
        id: current.id,
        name: current.name,
        email: current.email,
        phone: current.phone,
        role: current.role,
        isVerified: current.isVerified,
        city: current.city,
        bio: current.bio,
        photo: url,
        cnic: current.cnic,
        cnicFrontPhoto: current.cnicFrontPhoto,
        cnicBackPhoto: current.cnicBackPhoto,
        cnicStatus: current.cnicStatus,
        paymentMethods: current.paymentMethods,
        rating: current.rating,
        reviewsCount: current.reviewsCount,
      );
      state = state.copyWith(user: updated);
    } catch (e) {
      // Fallback to local path if upload fails
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
        cnic: current.cnic,
        cnicFrontPhoto: current.cnicFrontPhoto,
        cnicBackPhoto: current.cnicBackPhoto,
        cnicStatus: current.cnicStatus,
        paymentMethods: current.paymentMethods,
        rating: current.rating,
        reviewsCount: current.reviewsCount,
      );
      state = state.copyWith(user: updated);
    }
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
    try {
      // Upload CNIC photos to Storage
      final urls = await StorageService.uploadCnicPhotos(
        userId: current.id.toString(),
        frontPath: frontPhotoPath,
        backPath: backPhotoPath,
      );

      // Update Firestore
      await FirebaseAuthService.updateProfile({
        'cnic': cnicNumber,
        'cnic_front_photo': urls['front'],
        'cnic_back_photo': urls['back'],
        'cnic_status': 'pending',
      });

      final updated = UserModel(
        id: current.id,
        name: current.name,
        email: current.email,
        phone: current.phone,
        role: current.role,
        isVerified: current.isVerified,
        city: current.city,
        bio: current.bio,
        photo: current.photo,
        cnic: cnicNumber,
        cnicFrontPhoto: urls['front'],
        cnicBackPhoto: urls['back'],
        cnicStatus: 'pending',
        paymentMethods: current.paymentMethods,
        rating: current.rating,
        reviewsCount: current.reviewsCount,
      );

      state = state.copyWith(isLoading: false, user: updated);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Payment methods ────────────────────────────────────────────────────────
  Future<bool> addPaymentMethod(SavedPaymentMethod method) async {
    final current = state.user;
    if (current == null) return false;

    final isFirst = current.paymentMethods.isEmpty;
    final newMethod = SavedPaymentMethod(
      id: method.id,
      type: method.type,
      title: method.title,
      account: method.account,
      isDefault: isFirst ? true : method.isDefault,
    );

    final methods = [...current.paymentMethods, newMethod];
    await FirebaseAuthService.updateProfile({
      'payment_methods':
          methods.map((m) => m.toJson()).toList(),
    });

    final updated = _copyUserWith(current, paymentMethods: methods);
    state = state.copyWith(user: updated);
    return true;
  }

  Future<void> removePaymentMethod(String methodId) async {
    final current = state.user;
    if (current == null) return;

    var methods = current.paymentMethods
        .where((m) => m.id != methodId)
        .toList();

    final hadDefault = current.paymentMethods
        .any((m) => m.id == methodId && m.isDefault);
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

    await FirebaseAuthService.updateProfile({
      'payment_methods':
          methods.map((m) => m.toJson()).toList(),
    });

    final updated = _copyUserWith(current, paymentMethods: methods);
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

    await FirebaseAuthService.updateProfile({
      'payment_methods':
          methods.map((m) => m.toJson()).toList(),
    });

    final updated = _copyUserWith(current, paymentMethods: methods);
    state = state.copyWith(user: updated);
  }

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

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await FirebaseAuthService.logout();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
