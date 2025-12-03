import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../DriverSIde/Driver_homeScreen.dart';
import '../PassengerSide/PassengerHomeScreen.dart';

/// ============================================
/// ROLE SELECTION SCREEN
/// Choose between Driver or Passenger
/// ============================================

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with TickerProviderStateMixin {
  String? _selectedRole;
  late AnimationController _carController;

  @override
  void initState() {
    super.initState();
    _carController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _carController.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _proceedToHome() {
    if (_selectedRole == null) {
      Get.snackbar(
        'Select Role',
        'Please select your role to continue',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (_selectedRole == 'driver') {
      Get.off(
            () => const DriverHomeScreen(),
        transition: Transition.rightToLeftWithFade,
      );
    } else {
      Get.off(
            () => const PassengerHomeScreen(),
        transition: Transition.rightToLeftWithFade,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Background glow
          _buildBackgroundGlow(isDark),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Header
                  _buildHeader(isDark),

                  const SizedBox(height: 20),

                  // 3D Car Animation
                  _build3DCarSection(isDark),

                  const SizedBox(height: 30),

                  // Role Cards
                  Expanded(
                    child: _buildRoleCards(isDark),
                  ),

                  // Continue button
                  _buildContinueButton(isDark),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGlow(bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryYellow.withOpacity(isDark ? 0.12 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryYellow.withOpacity(isDark ? 0.08 : 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Role',
          style: GoogleFonts.urbanist(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.grey900,
            letterSpacing: -0.5,
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideX(begin: -0.1, end: 0),

        const SizedBox(height: 8),

        Text(
          'How would you like to use RouteLink?',
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.grey500,
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 200.ms)
            .slideX(begin: -0.1, end: 0),
      ],
    );
  }

  Widget _build3DCarSection(bool isDark) {
    return Center(
      child: AnimatedBuilder(
        animation: _carController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 8 * _carController.value - 4),
            child: child,
          );
        },
        child: Container(
          width: 200,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shadow
              Positioned(
                bottom: 0,
                child: Container(
                  width: 150,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryYellow.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),

              // 3D Car Body
              Container(
                width: 160,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryYellow,
                      AppColors.goldenYellow,
                      AppColors.darkYellow,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryYellow.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Car roof
                    Positioned(
                      top: 5,
                      left: 25,
                      right: 30,
                      child: Container(
                        height: 22,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.grey900,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(25),
                            bottomRight: Radius.circular(5),
                          ),
                        ),
                      ),
                    ),

                    // Windows
                    Positioned(
                      top: 8,
                      left: 32,
                      child: Row(
                        children: [
                          Container(
                            width: 25,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 30,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Headlights
                    Positioned(
                      right: 8,
                      top: 25,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tail lights
                    Positioned(
                      left: 8,
                      top: 25,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.6),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Front wheel
                    Positioned(
                      bottom: 2,
                      right: 25,
                      child: _buildWheel(),
                    ),

                    // Rear wheel
                    Positioned(
                      bottom: 2,
                      left: 25,
                      child: _buildWheel(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 300.ms)
        .scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildWheel() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.grey800,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.grey600, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.grey500,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCards(bool isDark) {
    return Column(
      children: [
        // Driver Card
        _buildRoleCard(
          isDark: isDark,
          role: 'driver',
          title: 'Driver',
          description: 'Share your route, accept ride requests, and earn money',
          icon: Iconsax.car,
          iconBg: AppColors.primaryYellow,
          delay: 400,
        ),

        const SizedBox(height: 16),

        // Passenger Card
        _buildRoleCard(
          isDark: isDark,
          role: 'passenger',
          title: 'Passenger',
          description: 'Find rides along your route and offer your own fare',
          icon: Iconsax.user,
          iconBg: AppColors.accentYellow,
          delay: 500,
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required bool isDark,
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required Color iconBg,
    required int delay,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => _selectRole(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryYellow
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.primaryYellow.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: iconBg.withOpacity(isSelected ? 1 : 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected
                    ? AppColors.darkBackground
                    : (isDark ? Colors.white : AppColors.grey900),
              ),
            ),

            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.urbanist(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Check indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryYellow : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryYellow
                      : AppColors.grey500,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                Icons.check,
                size: 18,
                color: AppColors.darkBackground,
              )
                  : null,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: delay.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildContinueButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _selectedRole != null ? _proceedToHome : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedRole != null
              ? AppColors.primaryYellow
              : AppColors.grey700,
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
              'Continue',
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _selectedRole != null
                    ? AppColors.darkBackground
                    : AppColors.grey400,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Iconsax.arrow_right,
              color: _selectedRole != null
                  ? AppColors.darkBackground
                  : AppColors.grey400,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }
}