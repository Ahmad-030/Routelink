import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import 'ResetPass_Screen.dart' show ResetPasswordScreen;

/// ============================================
/// OTP VERIFICATION SCREEN
/// Verify OTP code sent to email
/// ============================================

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
        (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
        (index) => FocusNode(),
  );

  bool _isLoading = false;
  int _resendTimer = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
        }
      });

      return _resendTimer > 0;
    });
  }

  void _resendCode() {
    if (!_canResend) return;

    setState(() {
      _resendTimer = 60;
      _canResend = false;
    });
    _startResendTimer();

    Get.snackbar(
      'Code Sent!',
      'A new verification code has been sent to your email',
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    // Check if all fields are filled
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 4) {
      _verifyOtp(otp);
    }
  }

  void _onKeyPressed(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _verifyOtp(String otp) async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    // Navigate to reset password screen
    Get.to(
          () => ResetPasswordScreen(email: widget.email),
      transition: Transition.rightToLeftWithFade,
    );
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 2) {
      return '$name***@$domain';
    }

    return '${name.substring(0, 2)}${'*' * (name.length - 2)}@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Background
          _buildBackground(isDark),

          // Content
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

                  // Email icon
                  _buildEmailIcon(isDark),

                  const SizedBox(height: 40),

                  // Header
                  _buildHeader(isDark),

                  const SizedBox(height: 40),

                  // OTP input fields
                  _buildOtpFields(isDark),

                  const SizedBox(height: 32),

                  // Verify button
                  _buildVerifyButton(isDark),

                  const SizedBox(height: 32),

                  // Resend code
                  _buildResendSection(isDark),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Positioned(
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

  Widget _buildEmailIcon(bool isDark) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 1500.ms,
          ),

          // Icon container
          Container(
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
              Iconsax.sms,
              size: 36,
              color: AppColors.darkBackground,
            ),
          ),

          // Notification badge
          Positioned(
            top: 15,
            right: 15,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.check,
                size: 14,
                color: Colors.white,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 600.ms)
              .scale(begin: const Offset(0, 0)),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Verify Your Email',
          textAlign: TextAlign.center,
          style: GoogleFonts.urbanist(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.grey900,
            letterSpacing: -0.5,
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 300.ms),

        const SizedBox(height: 12),

        Text(
          'We sent a 4-digit code to',
          textAlign: TextAlign.center,
          style: GoogleFonts.urbanist(
            fontSize: 15,
            color: AppColors.grey500,
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 400.ms),

        const SizedBox(height: 4),

        Text(
          _maskEmail(widget.email),
          textAlign: TextAlign.center,
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryYellow,
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 500.ms),
      ],
    );
  }

  Widget _buildOtpFields(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          width: 65,
          height: 70,
          margin: EdgeInsets.only(right: index < 3 ? 16 : 0),
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) => _onKeyPressed(event, index),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: GoogleFonts.urbanist(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primaryYellow,
                    width: 2,
                  ),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) => _onOtpChanged(value, index),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: (600 + index * 100).ms)
            .slideY(begin: 0.2, end: 0);
      }),
    );
  }

  Widget _buildVerifyButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : () {
          final otp = _controllers.map((c) => c.text).join();
          if (otp.length == 4) {
            _verifyOtp(otp);
          } else {
            Get.snackbar(
              'Invalid Code',
              'Please enter the complete 4-digit code',
              backgroundColor: AppColors.error,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.darkBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'Verify Code',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 1000.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildResendSection(bool isDark) {
    return Column(
      children: [
        Text(
          "Didn't receive the code?",
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: AppColors.grey500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _canResend ? _resendCode : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.refresh,
                size: 18,
                color: _canResend ? AppColors.primaryYellow : AppColors.grey500,
              ),
              const SizedBox(width: 8),
              Text(
                _canResend ? 'Resend Code' : 'Resend in ${_resendTimer}s',
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _canResend ? AppColors.primaryYellow : AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 1100.ms);
  }

  Widget _buildLoadingOverlay(bool isDark) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryYellow,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Verifying...',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}