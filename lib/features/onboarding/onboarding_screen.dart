import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/gradient_button.dart';

/// Onboarding screen with 2 slides per auth design spec.
///
/// Slide 1: "Learn English While Coding" (purple gradient)
/// Slide 2: "AI-Powered Code Reviews" (coral gradient)
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: AppStrings.onboardingAuthTitle1,
      description: AppStrings.onboardingAuthDesc1,
      icon: Icons.translate_rounded,
      secondaryIcon: Icons.code_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
      ),
      features: ['Tech Vocabulary', 'Bite-Sized Lessons', 'Developer-Focused'],
    ),
    _OnboardingPage(
      title: AppStrings.onboardingAuthTitle2,
      description: AppStrings.onboardingAuthDesc2,
      icon: Icons.code_rounded,
      secondaryIcon: Icons.auto_awesome_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6584), Color(0xFFFF8FA5)],
      ),
      features: ['Instant Feedback', 'Simple English', 'Best Practices'],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: widget.onComplete,
                    child: Text(
                      AppStrings.skip,
                      style: GoogleFonts.inter(
                        color: AppColors.darkTextSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),
              // Bottom section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppColors.primary,
                        dotColor: AppColors.darkBorder,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                        spacing: 6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    GradientButton(
                      text: _currentPage == _pages.length - 1
                          ? AppStrings.getStarted
                          : AppStrings.next,
                      onPressed: _nextPage,
                      width: double.infinity,
                      gradient: _pages[_currentPage].gradient,
                      icon: _currentPage == _pages.length - 1
                          ? Icons.arrow_forward_rounded
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // Icon display
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      page.gradient.colors.first.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Main icon container
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: page.gradient,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color:
                          page.gradient.colors.first.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  page.icon,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              // Floating secondary icon
              Positioned(
                right: 30,
                top: 15,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        page.gradient.colors.last.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: page.gradient.colors.first
                            .withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    page.secondaryIcon,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          // Title
          ShaderMask(
            shaderCallback: (bounds) =>
                page.gradient.createShader(bounds),
            child: Text(
              page.title,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            page.description,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.darkTextSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Feature chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: page.features.map((feature) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      page.gradient.colors.first.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        page.gradient.colors.first.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  feature,
                  style: TextStyle(
                    color: page.gradient.colors.first,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final IconData secondaryIcon;
  final LinearGradient gradient;
  final List<String> features;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.secondaryIcon,
    required this.gradient,
    required this.features,
  });
}
