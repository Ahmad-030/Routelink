import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../Widgets/Custom_Textfield.dart';
import '../../../core/theme/app_theme.dart';
import '../Login_Screen.dart';


/// ============================================
/// RESET PASSWORD SCREEN
/// Set new password after verification
/// ============================================

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Password strength
  double _passwordStrength = 0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = AppColors.grey500;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    double strength = 0;

    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.1;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.1;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

    String text;
    Color color;

    if (strength <= 0.2) {
      text = 'Very Weak';
      color = AppColors.error;
    } else if (strength <= 0.4) {
      text = 'Weak';
      color = AppColors.error;
    } else if (strength <= 0.6) {
      text = 'Medium';
      color = AppColors.warning;
    } else if (strength <= 0.8) {
      text = 'Strong';
      color = AppColors.success;
    } else {
      text = 'Very Strong';
      color = AppColors.success;
    }

    setState(() {
      _passwordStrength = strength;
      _passwordStrengthText = text;
      _passwordStrengthColor = color;
    });
  }

  void _handleResetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isLoading = false);

      // Show success dialog
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.tick_circle5,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(begin: const Offset(0, 0), duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),

              Text(
                'Password Changed!',
                style: GoogleFonts.urbanist(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Your password has been changed successfully.',
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  color: AppColors.grey500,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Get.offAll(() => const LoginScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: AppColors.darkBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Back to Sign In',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

                  // Key icon
                  _buildKeyIcon(isDark),

                  const SizedBox(height: 40),

                  // Header
                  _buildHeader(isDark),

                  const SizedBox(height: 40),

                  // Password form
                  _buildPasswordForm(isDark),

                  const SizedBox(height: 32),

                  // Reset button
                  _buildResetButton(isDark),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Positioned(
      top: -100,
      left: -100,
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

  Widget _buildKeyIcon(bool isDark) {
    return Center(
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
              Iconsax.key,
              size: 36,
              color: AppColors.darkBackground,
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
          'Create New Password',
          style: GoogleFonts.urbanist(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.grey900,
            letterSpacing: -0.5,
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 300.ms)
            .slideX(begin: -0.1, end: 0),

        const SizedBox(height: 8),

        Text(
          'Your new password must be different from previously used passwords.',
          style: GoogleFonts.urbanist(
            fontSize: 15,
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

  Widget _buildPasswordForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // New Password
          CustomTextField(
            controller: _passwordController,
            label: 'New Password',
            hint: 'Enter new password',
            prefixIcon: Iconsax.lock,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                color: AppColors.grey500,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            onChanged: _checkPasswordStrength,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a password';
              }
              if (value!.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 500.ms)
              .slideY(begin: 0.1, end: 0),

          // Password strength indicator
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _passwordStrength,
                      backgroundColor: isDark ? AppColors.darkBorder : AppColors.grey200,
                      valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _passwordStrengthText,
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _passwordStrengthColor,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Confirm Password
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Confirm new password',
            prefixIcon: Iconsax.lock_1,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye,
                color: AppColors.grey500,
              ),
              onPressed: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 600.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 20),

          // Password requirements
          _buildPasswordRequirements(isDark),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements(bool isDark) {
    final password = _passwordController.text;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.grey50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password must contain:',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
          const SizedBox(height: 12),
          _buildRequirement('At least 6 characters', password.length >= 6),
          _buildRequirement('One uppercase letter', password.contains(RegExp(r'[A-Z]'))),
          _buildRequirement('One lowercase letter', password.contains(RegExp(r'[a-z]'))),
          _buildRequirement('One number', password.contains(RegExp(r'[0-9]'))),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 700.ms);
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isMet ? Iconsax.tick_circle5 : Iconsax.close_circle,
            size: 18,
            color: isMet ? AppColors.success : AppColors.grey500,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: isMet ? AppColors.success : AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleResetPassword,
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
            const Icon(Iconsax.shield_tick, size: 22),
            const SizedBox(width: 10),
            Text(
              'Reset Password',
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
        .fadeIn(duration: 500.ms, delay: 800.ms)
        .slideY(begin: 0.2, end: 0);
  }
}