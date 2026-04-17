import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/social_login_button.dart';
import 'login_screen.dart';

/// Signup screen with name, email, password fields, terms checkbox,
/// social login, and full form validation.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_isSubmitting) return; // Prevent double taps
    if (!_agreedToTerms) {
      _showSnackBar(AppStrings.pleaseAgreeToTerms, isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to main app — handled by parent via auth state change
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _showSnackBar(
        authProvider.errorMessage ?? AppStrings.unknownError,
        isError: true,
      );
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.googleSignIn();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _showSnackBar(
        authProvider.errorMessage ?? AppStrings.unknownError,
        isError: true,
      );
    }

    setState(() => _isSubmitting = false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? AppColors.error : AppColors.accentGreenAuth,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    AppStrings.createAccount,
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.signupSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Name field
                  CustomTextField(
                    label: AppStrings.fullName,
                    hint: 'John Doe',
                    prefixIcon: Icons.person_outline_rounded,
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.pleaseEnterName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Email field
                  CustomTextField(
                    label: AppStrings.email,
                    hint: 'example@email.com',
                    prefixIcon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.pleaseEnterEmail;
                      }
                      if (!EmailValidator.validate(value.trim())) {
                        return AppStrings.pleaseEnterValidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Password field
                  CustomTextField(
                    label: AppStrings.password,
                    hint: 'Min. 8 characters',
                    prefixIcon: Icons.lock_outline_rounded,
                    controller: _passwordController,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onTogglePassword: () {
                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                    },
                    onFieldSubmitted: (_) => _handleSignUp(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.pleaseEnterPassword;
                      }
                      if (value.length < 8) {
                        return AppStrings.passwordTooShort;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Terms checkbox
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (value) {
                            setState(() => _agreedToTerms = value ?? false);
                          },
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _agreedToTerms = !_agreedToTerms);
                          },
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(text: AppStrings.iAgreeToTerms),
                                TextSpan(
                                  text: AppStrings.termsAndConditions,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Sign Up button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_agreedToTerms && !_isSubmitting)
                          ? _handleSignUp
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: const Color(0xFFE0E0E0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(AppStrings.signUp),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // OR divider
                  _buildDivider(),
                  const SizedBox(height: 24),
                  // Google button
                  SocialLoginButton(
                    text: AppStrings.continueWithGoogle,
                    icon: Icons.g_mobiledata_rounded,
                    iconColor: const Color(0xFFDB4437),
                    onPressed: _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 12),
                  // Apple button
                  SocialLoginButton(
                    text: AppStrings.continueWithApple,
                    icon: Icons.apple_rounded,
                    isDark: true,
                    onPressed: () {
                      // TODO: Implement Apple Sign-In (iOS only)
                      _showSnackBar('Apple Sign-In coming soon!');
                    },
                  ),
                  const SizedBox(height: 32),
                  // Already have account
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const LoginScreen(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(fontSize: 14),
                          children: [
                            TextSpan(
                              text: AppStrings.alreadyHaveAccount,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextSpan(
                              text: AppStrings.login,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppStrings.or,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }
}
