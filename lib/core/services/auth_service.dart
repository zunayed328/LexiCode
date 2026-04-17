import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentication service with Firebase-ready code and demo mode fallback.
///
/// When Firebase is not configured, uses SharedPreferences for local demo auth.
/// Replace with real Firebase calls once `flutterfire configure` is run.
class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';

  /// Sign up with email and password.
  /// Creates user account and stores user profile.
  Future<Map<String, dynamic>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // TODO: Replace with Firebase Auth when configured
      // final credential = await FirebaseAuth.instance
      //     .createUserWithEmailAndPassword(email: email, password: password);
      // await credential.user?.updateDisplayName(name);
      // await _createFirestoreUser(credential.user!.uid, name, email);

      // Demo mode: simulate signup with delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // Simulate validation
      if (email == 'test@test.com') {
        throw AuthException('Email already in use');
      }

      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userNameKey, name);
      await prefs.setString(_userEmailKey, email);
      await prefs.setString(_userIdKey, userId);

      return _buildUserMap(userId, name, email);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(_mapErrorMessage(e.toString()));
    }
  }

  /// Login with email and password.
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // TODO: Replace with Firebase Auth when configured
      // final credential = await FirebaseAuth.instance
      //     .signInWithEmailAndPassword(email: email, password: password);

      // Demo mode: simulate login with delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // Simulate invalid credentials
      if (password.length < 8) {
        throw AuthException('Invalid email or password');
      }

      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_userNameKey) ?? 'Developer';
      final userId = prefs.getString(_userIdKey) ??
          DateTime.now().millisecondsSinceEpoch.toString();

      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userEmailKey, email);

      return _buildUserMap(userId, savedName, email);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(_mapErrorMessage(e.toString()));
    }
  }

  /// Sign in with Google.
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // TODO: Replace with real Google Sign-In when configured
      // final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      // if (googleUser == null) throw AuthException('Google sign-in cancelled');
      // final GoogleSignInAuthentication googleAuth =
      //     await googleUser.authentication;
      // final credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth.accessToken,
      //   idToken: googleAuth.idToken,
      // );
      // final userCredential =
      //     await FirebaseAuth.instance.signInWithCredential(credential);

      // Demo mode
      await Future.delayed(const Duration(milliseconds: 1000));

      final prefs = await SharedPreferences.getInstance();
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userNameKey, 'Google User');
      await prefs.setString(_userEmailKey, 'user@gmail.com');
      await prefs.setString(_userIdKey, userId);

      return _buildUserMap(userId, 'Google User', 'user@gmail.com');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Google sign-in failed. Please try again.');
    }
  }

  /// Send password reset email.
  Future<void> resetPassword(String email) async {
    try {
      // TODO: Replace with Firebase Auth when configured
      // await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Demo mode: simulate sending email
      await Future.delayed(const Duration(milliseconds: 1500));

      if (email.isEmpty) {
        throw AuthException('Please enter your email');
      }

      debugPrint('Password reset email sent to: $email');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(_mapErrorMessage(e.toString()));
    }
  }

  /// Update the user's display name (persists to SharedPreferences).
  Future<void> updateDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  /// Update the user's local avatar photo path.
  Future<void> updatePhotoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_photo_path', path);
  }

  /// Get the locally stored avatar photo path.
  Future<String?> getPhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_photo_path');
  }

  /// Change the user's password (demo mode: validates current password length).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (currentPassword.length < 8) {
      throw AuthException('Current password is incorrect');
    }
    if (newPassword.length < 8) {
      throw AuthException('New password must be at least 8 characters');
    }
    if (currentPassword == newPassword) {
      throw AuthException('New password must be different from current');
    }

    // In demo mode, just validate and return success
    debugPrint('Password changed successfully');
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    // TODO: await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
  }

  /// Check if user is currently logged in.
  Future<bool> isLoggedIn() async {
    // TODO: return FirebaseAuth.instance.currentUser != null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Get current user data.
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogged = prefs.getBool(_isLoggedInKey) ?? false;
    if (!isLogged) return null;

    return _buildUserMap(
      prefs.getString(_userIdKey) ?? '',
      prefs.getString(_userNameKey) ?? 'Developer',
      prefs.getString(_userEmailKey) ?? '',
    );
  }

  /// Check if this is the first app launch.
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool('is_first_launch') ?? true;
    if (isFirst) {
      await prefs.setBool('is_first_launch', false);
    }
    return isFirst;
  }

  /// Build the Firestore user document map.
  Map<String, dynamic> _buildUserMap(
      String uid, String name, String email) {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoURL': null,
      'totalXP': 0,
      'currentLevel': 1,
      'currentStreak': 0,
      'longestStreak': 0,
      'hearts': 5,
      'gems': 0,
      'dailyGoal': 'regular',
      'englishLevel': 'A1',
      'isPremium': false,
      'createdAt': DateTime.now().toIso8601String(),
      'lastPracticeDate': null,
    };
  }

  /// Map Firebase error codes to user-friendly messages.
  String _mapErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Email already in use';
    } else if (error.contains('invalid-email')) {
      return 'Please enter a valid email';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak';
    } else if (error.contains('user-not-found') ||
        error.contains('wrong-password') ||
        error.contains('invalid-credential')) {
      return 'Invalid email or password';
    } else if (error.contains('network')) {
      return 'Network error. Please try again.';
    } else if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'Something went wrong. Please try again.';
  }
}

/// Custom exception for authentication errors.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
