import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:routelink/Core/Theme/App_theme.dart';
import '../../Core/App_Constants.dart';
import '../../main.dart'; // Import to access AuthWrapper


/// ============================================
/// SPLASH SCREEN
/// Premium animated splash with 3D car effect
/// ============================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _carController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _carController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _carController.forward();

    await Future.delayed(const Duration(milliseconds: 2500));
    _navigateNext();
  }

  void _navigateNext() {
    // Navigate to AuthWrapper which handles authentication routing
    Get.off(
          () => const AuthWrapper(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _carController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Background gradient glow
          _buildBackgroundGlow(isDark),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo and App Name
                _buildLogo(isDark),

                const SizedBox(height: 40),

                // 3D Car Animation
                _buildCarAnimation(isDark),

                const Spacer(flex: 2),

                // Loading indicator
                _buildLoadingIndicator(isDark),

                const SizedBox(height: 40),

                // Bottom text
                _buildBottomText(isDark),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow(bool isDark) {
    return Positioned(
      top: -100,
      left: -100,
      right: -100,
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              AppColors.primaryYellow.withOpacity(isDark ? 0.15 : 0.1),
              Colors.transparent,
            ],
            radius: 0.8,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 1000.ms)
        .scale(begin: const Offset(0.8, 0.8), duration: 1500.ms);
  }

  Widget _buildLogo(bool isDark) {
    return Column(
      children: [
        // Logo Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primaryYellow,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryYellow.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.route_rounded,
              size: 50,
              color: isDark ? AppColors.darkBackground : AppColors.grey900,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 600.ms,
          curve: Curves.elasticOut,
        ),

        const SizedBox(height: 24),

        // App Name
        Text(
          AppStrings.appName,
          style: GoogleFonts.urbanist(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.grey900,
            letterSpacing: -1,
          ),
        )
            .animate(delay: 300.ms)
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.3, end: 0),

        const SizedBox(height: 8),

        // Tagline
        Text(
          AppStrings.appTagline,
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryYellow,
            letterSpacing: 2,
          ),
        )
            .animate(delay: 500.ms)
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildCarAnimation(bool isDark) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Road line
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.grey600.withOpacity(0.5),
                    AppColors.grey600.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )
              .animate(delay: 800.ms)
              .fadeIn(duration: 500.ms)
              .scaleX(begin: 0, alignment: Alignment.center),

          // 3D Car representation
          AnimatedBuilder(
            animation: _carController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  100 * (1 - _carController.value) - 50,
                  0,
                ),
                child: child,
              );
            },
            child: _build3DCar(isDark),
          ),
        ],
      ),
    );
  }

  Widget _build3DCar(bool isDark) {
    return Container(
      width: 160,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryYellow,
            AppColors.goldenYellow,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryYellow.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Car body shape
          Positioned(
            top: 8,
            left: 20,
            right: 20,
            child: Container(
              height: 25,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.grey900,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(40),
                ),
              ),
            ),
          ),

          // Window
          Positioned(
            top: 12,
            left: 30,
            child: Container(
              width: 50,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),

          // Headlights
          Positioned(
            right: 5,
            top: 30,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // Wheels
          Positioned(
            bottom: 5,
            left: 25,
            child: _buildWheel(),
          ),
          Positioned(
            bottom: 5,
            right: 25,
            child: _buildWheel(),
          ),
        ],
      ),
    )
        .animate(delay: 600.ms)
        .fadeIn(duration: 500.ms)
        .slideX(begin: -0.5, end: 0, duration: 800.ms, curve: Curves.easeOut);
  }

  Widget _buildWheel() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.grey800,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.grey600, width: 3),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.grey500,
            shape: BoxShape.circle,
          ),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .rotate(duration: 500.ms);
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              backgroundColor: isDark ? AppColors.darkCard : AppColors.grey200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryYellow,
              ),
              minHeight: 4,
            ),
          ),
        )
            .animate(delay: 1000.ms)
            .fadeIn(duration: 500.ms)
            .scaleX(begin: 0, alignment: Alignment.center),

        const SizedBox(height: 16),

        Text(
          'Preparing your journey...',
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.grey500,
          ),
        )
            .animate(delay: 1200.ms)
            .fadeIn(duration: 500.ms),
      ],
    );
  }

  Widget _buildBottomText(bool isDark) {
    return Text(
      '© 2024 RouteLink',
      style: GoogleFonts.urbanist(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.grey500,
      ),
    )
        .animate(delay: 1500.ms)
        .fadeIn(duration: 500.ms);
  }
}