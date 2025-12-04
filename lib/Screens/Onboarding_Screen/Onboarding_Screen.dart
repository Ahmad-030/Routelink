import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:routelink/Core/Theme/App_theme.dart';
import 'package:slide_to_act/slide_to_act.dart';

import '../Auth_Screen/Login_Screen.dart';

/// ============================================
/// ONBOARDING SCREEN
/// Modern swipe-based onboarding with 3D car
/// ============================================

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Find Your Ride',
      description: 'Discover drivers heading your way with real-time route tracking on the map',
      icon: Icons.map_rounded,
      color: AppColors.primaryYellow,
    ),
    OnboardingData(
      title: 'Set Your Price',
      description: 'Offer your own fare and negotiate directly with drivers — no fixed prices',
      icon: Icons.payments_rounded,
      color: AppColors.accentYellow,
    ),
    OnboardingData(
      title: 'Track Live',
      description: 'Watch your ride approach in real-time with accurate ETA and distance',
      icon: Icons.gps_fixed_rounded,
      color: AppColors.goldenYellow,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _skipToLastPage() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToAuth() {
    Get.off(
          () => const LoginScreen(),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Background animated gradient
          _buildAnimatedBackground(isDark),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                _buildSkipButton(isDark),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], isDark, size, index);
                    },
                  ),
                ),

                // Page indicators
                _buildPageIndicators(isDark),

                const SizedBox(height: 30),

                // Swipe to Start button (only on last page)
                if (_currentPage == _pages.length - 1)
                  _buildSwipeToStart(isDark)
                else
                  _buildNextButton(isDark),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return Positioned(
      top: -150,
      right: -150,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              _pages[_currentPage].color.withOpacity(isDark ? 0.15 : 0.1),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _skipToLastPage, // Changed from _navigateToAuth
            child: Text(
              'Skip',
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grey500,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms);
  }

  Widget _buildPage(OnboardingData data, bool isDark, Size size, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon Container
          _buildIconContainer(data, isDark, index),

          const SizedBox(height: 60),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.grey900,
              letterSpacing: -0.5,
            ),
          )
              .animate(key: ValueKey('title_$index'))
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.grey500,
              height: 1.6,
            ),
          )
              .animate(key: ValueKey('desc_$index'))
              .fadeIn(duration: 500.ms, delay: 400.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildIconContainer(OnboardingData data, bool isDark, int index) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: data.color.withOpacity(0.3),
                width: 2,
              ),
            ),
          )
              .animate(
            key: ValueKey('ring_$index'),
            onPlay: (controller) => controller.repeat(reverse: true),
          )
              .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1.05, 1.05),
            duration: 1500.ms,
          ),

          // Icon background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.color,
                  data.color.withOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: data.color.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: 56,
              color: isDark ? AppColors.darkBackground : AppColors.grey900,
            ),
          )
              .animate(key: ValueKey('icon_$index'))
              .fadeIn(duration: 600.ms)
              .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1, 1),
            duration: 600.ms,
            curve: Curves.elasticOut,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryYellow
                : (isDark ? AppColors.grey700 : AppColors.grey300),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNextButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryYellow,
            foregroundColor: AppColors.darkBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Next',
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 600.ms)
        .slideY(begin: 0.3, end: 0);
  }

  Widget _buildSwipeToStart(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: SlideAction(
        height: 70,
        borderRadius: 20,
        elevation: 0,
        innerColor: isDark ? AppColors.darkBackground : AppColors.grey900,
        outerColor: AppColors.primaryYellow,
        sliderButtonIcon: Icon(
          Icons.arrow_forward_rounded,
          color: AppColors.primaryYellow,
          size: 28,
        ),
        text: '  Swipe to Start Riding',
        textStyle: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkBackground : AppColors.grey900,
          letterSpacing: 0.5,
        ),
        sliderRotate: false,
        onSubmit: () {
          _navigateToAuth();
          return null;
        },
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 500.ms)
        .slideY(begin: 0.5, end: 0)
        .then()
        .shimmer(
      duration: 2000.ms,
      delay: 1000.ms,
      color: Colors.white.withOpacity(0.3),
    );
  }
}

/// Data model for onboarding pages
class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}