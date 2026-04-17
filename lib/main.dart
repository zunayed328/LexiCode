import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBPP6GNZLgKts8AFZD1cyg8E7Vprs_faG8',
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

/// Auth-aware app entry point.
///
/// Flow:
/// 1. Splash (3s) → check auth state
/// 2. If first launch → Onboarding → Welcome
/// 3. If not authenticated → Welcome
/// 4. If authenticated → MainShell
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  // 0: splash, 1: onboarding, 2: welcome, 3: main
  int _screen = 0;
  bool _initialized = false;
  late final AppLifecycleListener _lifecycleListener;

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
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    final authProvider = context.read<AuthProvider>();
    final appProvider = context.read<AppProvider>();
    await authProvider.initialize();

    // Web Magic Link Intercept
    if (kIsWeb) {
      final String currentUrl = Uri.base.toString();
      if (FirebaseAuth.instance.isSignInWithEmailLink(currentUrl)) {
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString('user_email') ?? '';
        if (email.isNotEmpty) {
          await authProvider.signInWithEmailLink(email, currentUrl);
          await prefs.remove('user_email'); // Clear local cache securely
        }
      }
    }

    if (!mounted) return;

    // Load user data into AppProvider if already authenticated
    if (authProvider.isAuthenticated && authProvider.userData != null) {
      appProvider.loadUserFromAuth(authProvider.userData);
    }

    // Listen for future auth state changes (login/signup/Firestore merge)
    // so the dashboard updates live when userData changes
    authProvider.addListener(() {
      if (authProvider.isAuthenticated && authProvider.userData != null) {
        appProvider.loadUserFromAuth(authProvider.userData);
      }
    });

    // After splash finishes, this will determine where to go
    setState(() => _initialized = true);
  }

  void _onSplashFinished() {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();

    if (!_initialized) {
      // If auth hasn't finished initializing yet, wait a bit
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _onSplashFinished();
      });
      return;
    }

    setState(() {
      if (authProvider.isAuthenticated) {
        _screen = 3; // Go directly to main app
      } else if (authProvider.isFirstLaunch) {
        _screen = 1; // Show onboarding
      } else {
        _screen = 2; // Show welcome/login
      }
    });
  }

  void _onOnboardingComplete() {
    setState(() => _screen = 2); // Go to welcome
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes (e.g., after login/signup from sub-screens)
    final authProvider = context.watch<AuthProvider>();
    if (_screen == 2 && authProvider.isAuthenticated) {
      // Auto-navigate to main when auth succeeds from Welcome → Login/Signup
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _screen = 3);
      });
    }

    switch (_screen) {
      case 0:
        return SplashScreen(onFinished: _onSplashFinished);
      case 1:
        return OnboardingScreen(onComplete: _onOnboardingComplete);
      case 2:
        return const WelcomeScreen();
      default:
        return const MainShell();
    }
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
