import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Authentication service with real Firebase integration and Custom Email OTP.
///
/// Manages secure credential provisioning, token lifecycle, and authentication states
/// across native Email/Password schemas.
/// Features built-in email verification roadblocks, OTP verification, and password resetting utilities.
class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userIdKey = 'user_id';
  
  static String? _currentOtp;
  static Map<String, dynamic>? _pendingUserMap;

  /// Sign up with email and password.
  /// Creates user account and sends verification email.
  Future<Map<String, dynamic>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await credential.user?.updateDisplayName(name);
      await credential.user?.sendEmailVerification();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);

      return _buildUserMap(credential.user!.uid, name, email, null);
    } catch (e, stack) {
      debugPrint('=========================================');
      debugPrint('[AUTH] SIGNUP ERROR: $e');
      debugPrint('[AUTH] STACK TRACE: $stack');
      debugPrint('=========================================');
      if (e is AuthException) rethrow;
      throw AuthException(_mapErrorMessage(e.toString()));
    }
  }

  /// Login with email and password, triggering OTP generation.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null && !user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        throw const AuthException('email-not-verified');
      }

      // Generate Mock OTP
      final random = Random();
      _currentOtp = (100000 + random.nextInt(900000)).toString();
      debugPrint('=========================================');
      debugPrint('[AUTH] MOCK EMAIL OTP REQUESTED: $_currentOtp');
      debugPrint('=========================================');

      _pendingUserMap = _buildUserMap(
        user!.uid,
        user.displayName ?? 'Developer',
        user.email ?? email,
        user.photoURL,
      );
    } catch (e, stack) {
      debugPrint('=========================================');
      debugPrint('[AUTH] LOGIN ERROR: $e');
      debugPrint('[AUTH] STACK TRACE: $stack');
      debugPrint('=========================================');
      if (e is AuthException) rethrow;
      throw AuthException(_mapErrorMessage(e.toString()));
    }
  }

  /// Verify the OTP code entered by the user.
  Future<Map<String, dynamic>> verifyOTP(String inputCode) async {
    if (_currentOtp == null || _pendingUserMap == null) {
      throw const AuthException('Invalid session. Please login again.');
    }

    if (inputCode.trim() != _currentOtp) {
      throw const AuthException('Invalid credentials or verification code. Please try again.');
    }

    // OTP verified successfully
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);

    final userMap = _pendingUserMap!;
    
    // Clear pending state
    _currentOtp = null;
    _pendingUserMap = null;

    return userMap;
  }

  /// Send password reset email.
  Future<void> sendPasswordReset(String email) async {
    try {
      if (email.isEmpty) throw const AuthException('Please enter your email');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent to: $email');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(_mapErrorMessage(e.toString()));
    }
  }

  /// Temporarily login, resend verification email, and logout.
  Future<void> resendVerificationEmail(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.sendEmailVerification();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      throw AuthException(_mapErrorMessage(e.toString()));
    }
  }

  /// Update the user's display name.
  Future<void> updateDisplayName(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
    }
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

  /// Change the user's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null)
        throw const AuthException('User not logged in');

      // Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      await user.updatePassword(newPassword);
      debugPrint('Password changed successfully');
    } catch (e) {
      throw AuthException(_mapErrorMessage(e.toString()));
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
  }

  /// Check if user is currently logged in.
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final localLogin = prefs.getBool(_isLoggedInKey) ?? false;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    return localLogin && firebaseUser != null && firebaseUser.emailVerified;
  }

  /// Get current user data.
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogged = prefs.getBool(_isLoggedInKey) ?? false;
    final user = FirebaseAuth.instance.currentUser;
    if (!isLogged || user == null) return null;

    return _buildUserMap(
      user.uid,
      user.displayName ?? 'Developer',
      user.email ?? '',
      user.photoURL,
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
    String uid,
    String name,
    String email,
    String? photoURL,
  ) {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoURL': photoURL,
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
      return 'Invalid credentials or verification code. Please try again.';
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
