import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';

/// Premium glassmorphic authentication screen.
///
/// Two entry points:
///   1. **Magic Link** — email-only passwordless sign-in.
///   2. **Continue with Google** — OAuth popup via Firebase.
///
/// Deep-link verification is handled by [AppEntry] in main.dart.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _linkSent = false;

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _orbController;

  late Animation<double> _fadeIn;
  late Animation<double> _cardSlide;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _orbController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _cardSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  // ─── Send Magic Link ───────────────────────────────────────────────

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading || _isGoogleLoading) return;

    setState(() => _isLoading = true);
    _emailFocus.unfocus();

    final authProvider = context.read<AuthProvider>();
    final success =
        await authProvider.sendSignInLink(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _linkSent = true);
      _showSnackBar(
        '✨ Check your email for the login link!',
        isError: false,
      );
    } else {
      _showSnackBar(
        authProvider.errorMessage ?? 'Failed to send link. Please try again.',
        isError: true,
      );
    }
  }

  Future<void> _resendLink() async {
    setState(() {
      _linkSent = false;
      _isLoading = false;
    });
  }

  // ─── Google Sign-In ────────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    if (_isLoading || _isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (success) {
      // Auth state listener in AppEntry will auto-navigate to MainShell
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else if (authProvider.errorMessage != null) {
      _showSnackBar(authProvider.errorMessage!, isError: true);
    }
  }

  // ─── SnackBar ──────────────────────────────────────────────────────

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? AppColors.error.withValues(alpha: 0.9)
            : AppColors.accentGreenAuth.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 600;
    final cardMaxWidth = isWideScreen ? 440.0 : double.infinity;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Animated background orbs
          _buildBackgroundOrbs(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Back button
                _buildBackButton(),

                // Scrollable content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: cardMaxWidth),
                          child: AnimatedBuilder(
                            animation: _fadeController,
                            builder: (context, child) => Opacity(
                              opacity: _fadeIn.value,
                              child: Transform.translate(
                                offset: Offset(0, _cardSlide.value),
                                child: child,
                              ),
                            ),
                            child: _linkSent
                                ? _buildCheckEmailCard()
                                : _buildLoginCard(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Back Button ───────────────────────────────────────────────────

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, top: 8),
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Background Orbs ───────────────────────────────────────────────

  Widget _buildBackgroundOrbs() {
    return AnimatedBuilder(
      animation: _orbController,
      builder: (context, _) {
        final t = _orbController.value;
        final size = MediaQuery.of(context).size;
        return Stack(
          children: [
            Positioned(
              right: -60 + 30 * math.sin(t * 2 * math.pi),
              top: -40 + 20 * math.cos(t * 2 * math.pi * 1.3),
              child: _buildOrb(
                  200, AppColors.primary.withValues(alpha: 0.15)),
            ),
            Positioned(
              left: -80 + 25 * math.cos(t * 2 * math.pi * 0.7),
              bottom:
                  size.height * 0.15 + 30 * math.sin(t * 2 * math.pi * 1.1),
              child: _buildOrb(
                  260, const Color(0xFF8B5CF6).withValues(alpha: 0.1)),
            ),
            Positioned(
              right: -40 + 20 * math.sin(t * 2 * math.pi * 0.9),
              top: size.height * 0.45 +
                  15 * math.cos(t * 2 * math.pi * 1.5),
              child: _buildOrb(
                  140, AppColors.accent.withValues(alpha: 0.06)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }

  // ─── Login Card ────────────────────────────────────────────────────

  Widget _buildLoginCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Logo ──────────────────────────────────────────────────
        ScaleTransition(
          scale: _pulse,
          child: Container(
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '</>',
                  style: GoogleFonts.firaCode(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 32,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // ── Title ─────────────────────────────────────────────────
        Text(
          'Sign In or Sign Up',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Enter your email to sign in or create an account.\nNo passwords to remember!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.5),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // ── Google Sign-In Button (Primary CTA) ──────────────────
        _buildGoogleButton(),
        const SizedBox(height: 20),

        // ── OR Divider ────────────────────────────────────────────
        _buildOrDivider(),
        const SizedBox(height: 20),

        // ── Magic Link Glass Card ─────────────────────────────────
        _buildMagicLinkCard(),

        const SizedBox(height: 28),

        // ── Privacy Footer ────────────────────────────────────────
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.3),
              height: 1.6,
            ),
            children: [
              const TextSpan(text: 'By continuing, you agree to our '),
              TextSpan(
                text: 'Terms of Service',
                style: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.7),
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              const TextSpan(text: '\nand '),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.7),
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Google Sign-In Button ─────────────────────────────────────────

  Widget _buildGoogleButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (_isLoading || _isGoogleLoading)
                  ? null
                  : _signInWithGoogle,
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.white.withValues(alpha: 0.08),
              highlightColor: Colors.white.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _isGoogleLoading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white70,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google "G" logo
                          _buildGoogleLogo(),
                          const SizedBox(width: 14),
                          Text(
                            'Continue with Google',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Multi-color Google "G" logo in a rounded white container.
  Widget _buildGoogleLogo() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'G',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4285F4), // Google blue
          ),
        ),
      ),
    );
  }

  // ─── OR Divider ────────────────────────────────────────────────────

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.15),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.3),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Magic Link Card ──────────────────────────────────────────────

  Widget _buildMagicLinkCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: AppColors.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Passwordless Magic Link',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'We\'ll email you a secure link — just click to sign in.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 18),

                // Email label
                Text(
                  'Email Address',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Glass TextField
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _sendLink(),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: 'you@email.com',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 16,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: Icon(
                        Icons.email_outlined,
                        color: AppColors.primary.withValues(alpha: 0.7),
                        size: 22,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    errorStyle: GoogleFonts.inter(
                      color: AppColors.error.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                        .hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Send Link Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _buildPrimaryButton(
                    onPressed:
                        (_isLoading || _isGoogleLoading) ? null : _sendLink,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Send Magic Link',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Check Email Card ──────────────────────────────────────────────

  Widget _buildCheckEmailCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated envelope icon
        ScaleTransition(
          scale: _pulse,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentGreenAuth.withValues(alpha: 0.2),
                  AppColors.accent.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentGreenAuth.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 48,
              color: AppColors.accentGreenAuth,
            ),
          ),
        ),
        const SizedBox(height: 28),

        Text(
          'Check Your Email!',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We sent a magic sign-in link to',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),

        // Email display chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            _emailController.text.trim(),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryLight,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Glass instruction card
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  _buildStepRow(
                    '1',
                    'Open your email inbox',
                    Icons.inbox_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildStepRow(
                    '2',
                    'Click the sign-in link',
                    Icons.touch_app_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildStepRow(
                    '3',
                    'You\'re in! No password needed',
                    Icons.celebration_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Resend button
        TextButton(
          onPressed: _resendLink,
          child: Text(
            'Didn\'t receive it? Send again',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepRow(String number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
        Icon(
          icon,
          size: 20,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  // ─── Primary Button ────────────────────────────────────────────────

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: onPressed != null ? AppColors.primaryGradient : null,
        color: onPressed == null
            ? AppColors.primary.withValues(alpha: 0.3)
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: IconTheme(
                data: const IconThemeData(color: Colors.white),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
