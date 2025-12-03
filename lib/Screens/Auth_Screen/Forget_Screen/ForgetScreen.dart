import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../Widgets/Custom_Textfield.dart' show CustomTextField;
import '../../../core/theme/app_theme.dart';
import 'Otp_verification.dart' show OtpVerificationScreen;


/// ============================================
/// FORGOT PASSWORD SCREEN
/// Password recovery with email
/// ============================================

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _iconAnimController;

  @override
  void initState() {
    super.initState();
    _iconAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _iconAnimController.dispose();
    super.dispose();
  }

  void _handleSendCode() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isLoading = false);

      // Navigate to OTP verification
      Get.to(
            () => OtpVerificationScreen(email: _emailController.text.trim()),
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
          // Background design
          _buildBackground(isDark),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Back button
                  _buildBackButton(isDark),

                  const SizedBox(height: 40),

                  // Lock Icon Animation
                  _buildLockIcon(isDark),

                  const SizedBox(height: 40),

                  // Header
                  _buildHeader(isDark),

                  const SizedBox(height: 40),

                  // Email form
                  _buildEmailForm(isDark),

                  const SizedBox(height: 32),

                  // Send code button
                  _buildSendCodeButton(isDark),

                  const SizedBox(height: 24),

                  // Back to login link
                  _buildBackToLoginLink(isDark),

                  const SizedBox(height: 40),

                  // Help section
                  _buildHelpSection(isDark),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Stack(
      children: [
        // Top right glow
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
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
        // Bottom left glow
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
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

  Widget _buildBackButton(bool isDark) {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Icon(
          Iconsax.arrow_left,
          color: isDark ? Colors.white : AppColors.grey900,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildLockIcon(bool isDark) {
    return Center(
      child: AnimatedBuilder(
        animation: _iconAnimController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 8 * _iconAnimController.value - 4),
            child: child,
          );
        },
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primaryYellow.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryYellow.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Iconsax.lock,
                size: 36,
                color: AppColors.darkBackground,
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forgot Password?',
          style: GoogleFonts.urbanist(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.grey900,
            letterSpacing: -0.5,
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 300.ms)
            .slideX(begin: -0.1, end: 0),

        const SizedBox(height: 12),

        Text(
          "Don't worry! It happens. Please enter the email address associated with your account.",
          style: GoogleFonts.urbanist(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.grey500,
            height: 1.5,
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 400.ms)
            .slideX(begin: -0.1, end: 0),
      ],
    );
  }

  Widget _buildEmailForm(bool isDark) {
    return Form(
      key: _formKey,
      child: CustomTextField(
        controller: _emailController,
        label: 'Email Address',
        hint: 'Enter your email',
        prefixIcon: Iconsax.sms,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return 'Please enter your email';
          }
          if (!GetUtils.isEmail(value!)) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 500.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildSendCodeButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSendCode,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.darkBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.darkBackground,
            ),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.send_1, size: 22),
            const SizedBox(width: 10),
            Text(
              'Send Reset Code',
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildBackToLoginLink(bool isDark) {
    return Center(
      child: GestureDetector(
        onTap: () => Get.back(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.arrow_left_2,
              size: 18,
              color: AppColors.primaryYellow,
            ),
            const SizedBox(width: 8),
            Text(
              'Back to Sign In',
              style: GoogleFonts.urbanist(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryYellow,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 700.ms);
  }

  Widget _buildHelpSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.info_circle,
                  color: AppColors.info,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need Help?',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "If you don't receive an email, check your spam folder or contact support.",
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        color: AppColors.grey500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Open support
              },
              icon: const Icon(Iconsax.message_question, size: 20),
              label: Text(
                'Contact Support',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.info,
                side: const BorderSide(color: AppColors.info),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 800.ms)
        .slideY(begin: 0.1, end: 0);
  }
}