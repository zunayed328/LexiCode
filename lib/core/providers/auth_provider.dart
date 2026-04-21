import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../../shared/models/user_model.dart';

/// Provider for Firebase Passwordless Email-Link authentication.
///
/// Wraps [AuthService] with ChangeNotifier for reactive UI updates.
/// Listens to [FirebaseAuth.authStateChanges] so the UI automatically
/// reflects sign-in / sign-out events.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _linkSent = false;
  String? _errorMessage;
  UserModel? _user;
  bool _isFirstLaunch = true;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get linkSent => _linkSent;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;
  bool get isFirstLaunch => _isFirstLaunch;

  /// Legacy-compatible getter — returns user as a Map for AppProvider.loadUserFromAuth().
  Map<String, dynamic>? get userData => _user?.toMap();

  // ─── Initialization ───────────────────────────────────────────────────────

  /// Initialize auth state — call on app start.
  ///
  /// Checks for a existing Firebase session and loads the user's
  /// Firestore profile if authenticated.
  Future<void> initialize() async {
    _isFirstLaunch = await _authService.isFirstLaunch();

    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      await _loadUserProfile(firebaseUser);
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
    }

    // Listen for future auth state changes
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        await _loadUserProfile(user);
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        _user = null;
      }
      notifyListeners();
    });

    notifyListeners();
  }

  /// Loads the user's Firestore profile into [_user].
  Future<void> _loadUserProfile(User firebaseUser) async {
    try {
      final data = await _firestoreService.getUserData(firebaseUser.uid);
      if (data != null) {
        // Load activity log from Firestore
        final activities =
            await _firestoreService.getActivities(firebaseUser.uid);

        _user = UserModel.fromMap(firebaseUser.uid, data)
            .copyWith(activityLog: activities);
      } else {
        // Firestore document doesn't exist yet — create it
        await _firestoreService.ensureUserDocument(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ??
              firebaseUser.email?.split('@')[0] ??
              'Developer',
          email: firebaseUser.email ?? '',
          photoURL: firebaseUser.photoURL,
        );

        _user = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ??
              firebaseUser.email?.split('@')[0] ??
              'Developer',
          email: firebaseUser.email ?? '',
        );
      }
    } catch (e) {
      debugPrint('[AuthProvider] _loadUserProfile error: $e');
    }
  }

  // ─── Send Sign-In Link ──────────────────────────────────────────────────

  /// Sends a passwordless sign-in email to [email].
  ///
  /// Sets [linkSent] to true on success so the UI can show a
  /// "check your email" message.
  Future<bool> sendSignInLink(String email) async {
    _clearError();
    _setLoading(true);

    try {
      await _authService.sendSignInLink(email);
      _linkSent = true;
      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      _setError(_firebaseErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Failed to send sign-in link. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // ─── Complete Sign-In ─────────────────────────────────────────────────────

  /// Completes the email link sign-in.
  ///
  /// [emailLink] is the deep-link URL the user clicked from their email.
  /// If [email] is null, the pending email from SharedPreferences is used.
  Future<bool> verifySignInLink(String? email, String emailLink) async {
    _clearError();
    _setLoading(true);

    try {
      // Resolve the email — either provided or fetched from local storage
      final resolvedEmail =
          email ?? await _authService.getPendingEmail();
      if (resolvedEmail == null || resolvedEmail.isEmpty) {
        _setError(
            'Could not determine your email. Please enter it again.');
        _setLoading(false);
        return false;
      }

      if (!_authService.isSignInLink(emailLink)) {
        _setError('Invalid sign-in link.');
        _setLoading(false);
        return false;
      }

      final user =
          await _authService.signInWithEmailLink(resolvedEmail, emailLink);

      await _loadUserProfile(user);
      _isAuthenticated = true;
      _linkSent = false;
      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      _setError(_firebaseErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Sign-in failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  /// Returns true if [link] is a valid Firebase email sign-in link.
  bool isSignInLink(String link) => _authService.isSignInLink(link);

  /// Returns the pending email (if one exists from a previous sendSignInLink call).
  Future<String?> getPendingEmail() => _authService.getPendingEmail();

  // ─── Google Sign-In ────────────────────────────────────────────────────────

  /// Signs in with Google (popup on web, native on mobile).
  ///
  /// On success, loads the user's Firestore profile and sets
  /// [isAuthenticated] to true.
  Future<bool> signInWithGoogle() async {
    _clearError();
    _setLoading(true);

    try {
      final user = await _authService.signInWithGoogle();
      await _loadUserProfile(user);
      _isAuthenticated = true;
      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      _setError(_firebaseErrorMessage(e.code));
      _setLoading(false);
      return false;
    } catch (e) {
      final message = e.toString();
      if (message.contains('cancelled')) {
        // User closed the popup — not an error, just clear loading
        _setLoading(false);
        return false;
      }
      _setError('Google sign-in failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // ─── Legacy bridge methods ────────────────────────────────────────────────
  // These keep the existing LoginScreen and AppProvider working during
  // the transition. They will be removed when the UI is rewritten.

  /// Legacy sign-up bridge — sends a sign-in link instead.
  Future<bool> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    return sendSignInLink(email);
  }

  /// Legacy sign-in bridge — sends a sign-in link instead.
  Future<bool> signInWithEmailPassword(String email, String password) async {
    return sendSignInLink(email);
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _authService.signOut();
    clearUserData();
  }

  void clearUserData() {
    _isAuthenticated = false;
    _linkSent = false;
    _user = null;
    notifyListeners();
  }

  // ─── Profile Editing ──────────────────────────────────────────────────────

  /// Updates the user's display name in Firestore and in-memory.
  Future<void> updateDisplayName(String name) async {
    if (_user == null) return;
    await _firestoreService.updateUserFields(_user!.id, {'name': name});
    _user = _user!.copyWith(name: name);
    notifyListeners();
  }

  /// Saves the photo URL in Firestore and in-memory.
  Future<void> updatePhotoPath(String path) async {
    if (_user == null) return;
    await _firestoreService
        .updateUserFields(_user!.id, {'photoURL': path});
    _user = _user!.copyWith(avatarUrl: path);
    notifyListeners();
  }

  /// Returns the stored avatar path.
  Future<String?> getPhotoPath() async {
    final path = _user?.avatarUrl;
    return (path != null && path.isNotEmpty) ? path : null;
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

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

  /// Maps Firebase error codes to user-friendly messages.
  String _firebaseErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-action-code':
        return 'This sign-in link has expired. Please request a new one.';
      case 'expired-action-code':
        return 'This sign-in link has expired. Please request a new one.';
      default:
        return 'Authentication error ($code). Please try again.';
    }
  }
}
