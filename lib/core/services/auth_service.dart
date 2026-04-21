import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

/// Firebase Passwordless Email-Link Authentication Service.
///
/// Flow:
///   1. User enters their email → [sendSignInLink] sends a magic link.
///   2. User clicks the link  → [signInWithEmailLink] completes auth.
///   3. On first sign-in      → a Firestore user document is created.
///
/// Session state is managed entirely by Firebase Auth. The only local
/// persistence is the pending email (stored in SharedPreferences so
/// the link can be verified when the user returns to the app).
class AuthService {
  static const String _pendingEmailKey = 'pending_sign_in_email';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // ─── Action Code Settings ───────────────────────────────────────────────

  /// Configure this URL to your authorized domain.
  /// For local dev:  http://localhost:8080
  /// For production: https://flutter-ai-playground-2efdb.web.app
  ActionCodeSettings get _actionCodeSettings => ActionCodeSettings(
        url: kIsWeb
            ? 'http://localhost:8080'
            : 'https://flutter-ai-playground-2efdb.web.app',
        handleCodeInApp: true,
        // iOS and Android settings for deep-linking (optional for web-only)
        iOSBundleId: 'com.lexicode.lexicodeApp',
        androidPackageName: 'com.lexicode.lexicode_app',
        androidInstallApp: true,
        androidMinimumVersion: '21',
      );

  // ─── Send Sign-In Link ──────────────────────────────────────────────────

  /// Sends a passwordless sign-in email to [email].
  ///
  /// The email address is persisted locally so it can be matched when the
  /// user returns via the email link.
  Future<void> sendSignInLink(String email) async {
    final trimmedEmail = email.trim().toLowerCase();

    await _auth.sendSignInLinkToEmail(
      email: trimmedEmail,
      actionCodeSettings: _actionCodeSettings,
    );

    // Persist the email locally — needed to complete sign-in when user
    // returns to the app via the link.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingEmailKey, trimmedEmail);

    debugPrint('[AuthService] Sign-in link sent to $trimmedEmail');
  }

  // ─── Complete Sign-In With Email Link ───────────────────────────────────

  /// Completes the passwordless sign-in using the [emailLink] the user
  /// clicked. If the user is new, a Firestore profile document is created.
  ///
  /// Returns the authenticated [User].
  /// Throws [FirebaseAuthException] on failure.
  Future<User> signInWithEmailLink(String email, String emailLink) async {
    final trimmedEmail = email.trim().toLowerCase();

    final credential = await _auth.signInWithEmailLink(
      email: trimmedEmail,
      emailLink: emailLink,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'Sign-in succeeded but no user was returned.',
      );
    }

    // Ensure the user has a Firestore profile document
    await _firestoreService.ensureUserDocument(
      uid: user.uid,
      name: user.displayName ?? trimmedEmail.split('@')[0],
      email: trimmedEmail,
      photoURL: user.photoURL,
    );

    // Clear the pending email
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingEmailKey);

    debugPrint('[AuthService] Signed in: ${user.uid} ($trimmedEmail)');
    return user;
  }

  // ─── Link Verification ──────────────────────────────────────────────────

  /// Returns true if [link] is a valid Firebase sign-in email link.
  bool isSignInLink(String link) {
    return _auth.isSignInWithEmailLink(link);
  }

  /// Returns the email address saved when [sendSignInLink] was called.
  /// Returns null if no pending sign-in exists.
  Future<String?> getPendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingEmailKey);
  }

  // ─── Google Sign-In ─────────────────────────────────────────────────────

  /// Signs in with Google using Firebase's popup flow.
  ///
  /// Uses [signInWithPopup] with [GoogleAuthProvider] — works on
  /// both web and mobile without manual token extraction.
  ///
  /// On first sign-in, creates a Firestore user document.
  /// Returns the authenticated [User].
  Future<User> signInWithGoogle() async {
    final googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');
    // Force account picker so the user can switch accounts after logout
    googleProvider.setCustomParameters({'prompt': 'select_account'});

    final credential = await _auth.signInWithPopup(googleProvider);

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'Google sign-in succeeded but no user was returned.',
      );
    }

    // Ensure the user has a Firestore profile document
    await _firestoreService.ensureUserDocument(
      uid: user.uid,
      name: user.displayName ?? user.email?.split('@')[0] ?? 'Developer',
      email: user.email ?? '',
      photoURL: user.photoURL,
    );

    debugPrint('[AuthService] Google sign-in: ${user.uid} (${user.email})');
    return user;
  }

  // ─── Session ────────────────────────────────────────────────────────────

  /// The currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  /// Whether a Firebase session is active.
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream of auth state changes (sign-in, sign-out, token refresh).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs out the current user.
  ///
  /// Clears both the Firebase session and the cached Google credential
  /// so the account picker shows again on the next sign-in.
  Future<void> signOut() async {
    // 1. Clear Google's cached credential (best-effort)
    try {
      if (kIsWeb) {
        // On web, disconnect() revokes the cached Google session
        // so signInWithPopup shows the account picker next time.
        await GoogleSignIn.instance.disconnect();
      } else {
        await GoogleSignIn.instance.disconnect();
      }
    } catch (e) {
      // Not all users signed in with Google — this is expected to fail
      // for email-link users. Silently continue.
      debugPrint('[AuthService] Google disconnect (non-critical): $e');
    }

    // 2. Clear the Firebase session (always runs)
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] Firebase signOut error: $e');
      rethrow;
    }

    debugPrint('[AuthService] Signed out (Firebase + Google cleared).');
  }

  // ─── First Launch ───────────────────────────────────────────────────────

  /// Returns true on the very first app launch (clears the flag after).
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool('is_first_launch') ?? true;
    if (isFirst) {
      await prefs.setBool('is_first_launch', false);
    }
    return isFirst;
  }
}

// ─── Custom Exception ─────────────────────────────────────────────────────────

class FirebaseAuthException implements Exception {
  final String code;
  final String message;
  const FirebaseAuthException({required this.code, required this.message});

  @override
  String toString() => 'FirebaseAuthException($code): $message';
}
