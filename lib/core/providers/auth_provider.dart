import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Provider for authentication state management.
///
/// Wraps [AuthService] with ChangeNotifier for reactive UI updates.
/// Manages loading states, error messages, and user data.
/// After login/signup, ensures a Firestore user document exists.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;
  Map<String, dynamic>? _userData;
  bool _isFirstLaunch = true;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;
  bool get isFirstLaunch => _isFirstLaunch;

  /// Initialize auth state — call on app start.
  Future<void> initialize() async {
    _isFirstLaunch = await _authService.isFirstLaunch();
    _isAuthenticated = await _authService.isLoggedIn();
    if (_isAuthenticated) {
      _userData = await _authService.getCurrentUser();
    }
    notifyListeners();
  }

  /// Sign up with email, name, and password.
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _userData = await _authService.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );
      _isAuthenticated = true;

      // Ensure Firestore document exists with defaults
      await _ensureFirestoreUser();

      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Something went wrong. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Login with email and password, which triggers OTP generation.
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Note: We do NOT set _isAuthenticated = true yet.
      // We wait for the OTP verification step to complete.

      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Something went wrong. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Verify the 6-digit OTP to finalize login.
  Future<bool> verifyOTP(String otp) async {
    _setLoading(true);
    _clearError();
    try {
      _userData = await _authService.verifyOTP(otp);
      _isAuthenticated = true;

      // Ensure Firestore document exists with defaults
      await _ensureFirestoreUser();

      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Invalid credentials or verification code. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Send password reset email.
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendPasswordReset(email);
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to send reset email. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Explicitly clear user state from memory.
  void clearUserData() {
    _isAuthenticated = false;
    _userData = null;
    notifyListeners();
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _authService.signOut();
    clearUserData();
  }

  /// Temporarily login and resend validation email.
  Future<void> resendVerificationEmail(String email, String password) async {
    await _authService.resendVerificationEmail(email, password);
  }

  // ─── Profile Editing ───────────────────────────────────────────

  /// Update the user's display name.
  Future<void> updateDisplayName(String name) async {
    await _authService.updateDisplayName(name);
    if (_userData != null) {
      _userData = {..._userData!, 'name': name};
    }
    notifyListeners();
  }

  /// Update the user's avatar photo path locally.
  Future<void> updatePhotoPath(String path) async {
    await _authService.updatePhotoPath(path);
    if (_userData != null) {
      _userData = {..._userData!, 'localPhotoPath': path};
    }
    notifyListeners();
  }

  /// Get the stored local photo path.
  Future<String?> getPhotoPath() => _authService.getPhotoPath();

  /// Change the user's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  // ─── Firestore Integration ──────────────────────────────────

  /// Checks if the user has a document in the `users` collection.
  /// If they don't, creates one with default values (level 1, xp 0, streak 0).
  /// Non-blocking: the app continues even if Firestore is unreachable.
  Future<void> _ensureFirestoreUser() async {
    if (_userData == null) return;

    try {
      final uid = _userData!['uid'] as String? ?? '';
      final name = _userData!['name'] as String? ?? 'Developer';
      final email = _userData!['email'] as String? ?? '';
      final photoURL = _userData!['photoURL'] as String?;

      if (uid.isEmpty) return;

      final firestoreData = await _firestoreService.ensureUserDocument(
        uid: uid,
        name: name,
        email: email,
        photoURL: photoURL,
      );

      // Merge Firestore data back into local userData so the app
      // reflects any values already stored (e.g. returning user's XP)
      if (firestoreData != null) {
        _userData = {..._userData!, ...firestoreData};
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthProvider._ensureFirestoreUser error: $e');
      // Non-fatal — the app still works with local data
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
