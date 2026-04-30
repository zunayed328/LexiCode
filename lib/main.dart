import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/app_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/constants/app_colors.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/code_review/presentation/code_review_screen.dart';
import 'features/language_learning/screens/learning_home_screen.dart';
import 'features/language_learning/providers/learning_provider.dart';
import 'features/language_learning/providers/progress_provider.dart';
import 'features/language_learning/providers/practice_provider.dart';
import 'features/progress/presentation/progress_screen.dart';
import 'features/profile/presentation/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBPP6GNZLgKts8AFZD1cyg0E7Vprs_faG8',
          authDomain: 'flutter-ai-playground-2efdb.firebaseapp.com',
          projectId: 'flutter-ai-playground-2efdb',
          storageBucket: 'flutter-ai-playground-2efdb.firebasestorage.app',
          messagingSenderId: '1082906445426',
          appId: '1:1082906445426:web:a3242d860ff4c67eab64eb',
        ),
      );
    } else {
      // Android / iOS: uses google-services.json / GoogleService-Info.plist automatically
      await Firebase.initializeApp();
    }
  } catch (e) {
    // Firebase is optional — the app runs fully on local SQLite.
    debugPrint('[main] Firebase init skipped: $e');
  }

  // Initialize Google Sign-In (required once by google_sign_in v7+).
  // The serverClientId is the Web Client ID from the Firebase Console,
  // which lets Android receive a valid ID token for Firebase Auth.
  if (!kIsWeb) {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '1082906445426-399oisgurcol9mpk9sof646ctsf6be3j.apps.googleusercontent.com',
      );
    } catch (e) {
      debugPrint('[main] GoogleSignIn init skipped: $e');
    }
  }

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LearningProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => PracticeProvider()),
      ],
      child: const LexiCodeApp(),
    ),
  );
}

class LexiCodeApp extends StatelessWidget {
  const LexiCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return MaterialApp(
      title: 'LexiCode DualCore Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: provider.themeMode,
      home: const AppEntry(),
    );
  }
}

/// Auth-aware app entry point with deep-link handling.
///
/// Flow:
/// 1. Splash (3s) → check auth state + detect incoming email link
/// 2. If email link detected → verify and auto-sign-in
/// 3. If first launch → Onboarding → Welcome
/// 4. If not authenticated → Welcome
/// 5. If authenticated → MainShell
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  // 0: splash, 1: onboarding, 2: welcome, 3: main, 4: verifying link
  int _screen = 0;
  bool _initialized = false;
  late final AppLifecycleListener _lifecycleListener;
  StreamSubscription? _linkSub;

  @override
  void initState() {
    super.initState();
    _initializeAuth();

    // Manage usage timer based on app lifecycle
    _lifecycleListener = AppLifecycleListener(
      onInactive: () => context.read<AppProvider>().pauseTimer(),
      onPause: () => context.read<AppProvider>().pauseTimer(),
      onResume: () => context.read<AppProvider>().resumeTimer(),
      onDetach: () => context.read<AppProvider>().saveTimeSpent(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    final authProvider = context.read<AuthProvider>();
    final appProvider = context.read<AppProvider>();
    await authProvider.initialize();

    if (!mounted) return;

    // Load user data into AppProvider if already authenticated
    if (authProvider.isAuthenticated && authProvider.userData != null) {
      appProvider.loadUserFromAuth(authProvider.userData);
    }

    // Listen for future auth state changes
    authProvider.addListener(() {
      if (authProvider.isAuthenticated && authProvider.userData != null) {
        appProvider.loadUserFromAuth(authProvider.userData);
      }
    });

    // Check for email sign-in link (deep link)
    await _checkForEmailLink();

    // Listen for incoming links while app is running (mobile)
    if (!kIsWeb) {
      _setupMobileLinkListener();
    }

    setState(() => _initialized = true);
  }

  /// Checks if the app was opened via a Firebase email sign-in link.
  ///
  /// On web: reads `Uri.base` (the current browser URL).
  /// On mobile: reads the initial deep link from `app_links`.
  Future<void> _checkForEmailLink() async {
    String? incomingLink;

    if (kIsWeb) {
      // On web, the email link lands as the full browser URL
      incomingLink = Uri.base.toString();
    } else {
      // On mobile, check if the app was cold-started via a deep link
      try {
        final appLinks = AppLinks();
        final initialUri = await appLinks.getInitialLink();
        incomingLink = initialUri?.toString();
      } catch (e) {
        debugPrint('[DeepLink] getInitialLink error: $e');
      }
    }

    if (incomingLink != null) {
      await _handleEmailLink(incomingLink);
    }
  }

  /// Listens for incoming deep links while the app is already running (mobile).
  void _setupMobileLinkListener() {
    try {
      final appLinks = AppLinks();
      _linkSub = appLinks.uriLinkStream.listen((Uri uri) {
        _handleEmailLink(uri.toString());
      });
    } catch (e) {
      debugPrint('[DeepLink] uriLinkStream error: $e');
    }
  }

  /// Verifies an incoming email sign-in link.
  ///
  /// Shows a loading overlay (screen 4) while verifying.
  /// On success → navigates to MainShell.
  /// On failure → falls through to normal auth flow.
  Future<void> _handleEmailLink(String link) async {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isSignInLink(link)) return;

    debugPrint('[DeepLink] Valid sign-in link detected — verifying...');
    setState(() => _screen = 4); // Show verifying overlay

    final pendingEmail = await authProvider.getPendingEmail();
    final success = await authProvider.verifySignInLink(pendingEmail, link);

    if (!mounted) return;

    if (success) {
      // Load user data and go to main
      final appProvider = context.read<AppProvider>();
      if (authProvider.userData != null) {
        appProvider.loadUserFromAuth(authProvider.userData);
      }
      setState(() => _screen = 3);
    } else {
      // Verification failed — show welcome screen with error
      setState(() => _screen = 2);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ?? 'Sign-in link expired. Please try again.',
            ),
            backgroundColor: const Color(0xFFFF4B4B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onSplashFinished() {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();

    if (!_initialized) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _onSplashFinished();
      });
      return;
    }

    // If we're already verifying a link, don't override
    if (_screen == 4) return;

    setState(() {
      if (authProvider.isAuthenticated) {
        _screen = 3;
      } else if (authProvider.isFirstLaunch) {
        _screen = 1;
      } else {
        _screen = 2;
      }
    });
  }

  void _onOnboardingComplete() {
    setState(() => _screen = 2);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Auto-navigate to main when auth succeeds from any screen
    if ((_screen == 2 || _screen == 4) && authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _screen != 3) setState(() => _screen = 3);
      });
    }

    switch (_screen) {
      case 0:
        return SplashScreen(onFinished: _onSplashFinished);
      case 1:
        return OnboardingScreen(onComplete: _onOnboardingComplete);
      case 2:
        return const WelcomeScreen();
      case 4:
        return _buildVerifyingScreen();
      default:
        return const MainShell();
    }
  }

  /// Full-screen loading overlay shown while verifying an email link.
  Widget _buildVerifyingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Verifying your sign-in link...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.darkBorder.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  minHeight: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = const [
      DashboardScreen(),
      CodeReviewScreen(),
      LearningHomeScreen(),
      ProgressScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: provider.currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  0,
                  Icons.dashboard_rounded,
                  Icons.dashboard_outlined,
                  'Home',
                  provider,
                ),
                _buildNavItem(
                  context,
                  1,
                  Icons.code_rounded,
                  Icons.code_outlined,
                  'Review',
                  provider,
                ),
                _buildCenterNavItem(context, provider),
                _buildNavItem(
                  context,
                  3,
                  Icons.emoji_events_rounded,
                  Icons.emoji_events_outlined,
                  'Progress',
                  provider,
                ),
                _buildNavItem(
                  context,
                  4,
                  Icons.person_rounded,
                  Icons.person_outlined,
                  'Profile',
                  provider,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    AppProvider provider,
  ) {
    final isSelected = provider.currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => provider.setCurrentIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem(BuildContext context, AppProvider provider) {
    final isSelected = provider.currentIndex == 2;
    return GestureDetector(
      onTap: () => provider.setCurrentIndex(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.school_rounded : Icons.school_outlined,
              color: Colors.white,
              size: 24,
            ),
            const Text(
              'Learn',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
