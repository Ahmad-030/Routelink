import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../Widgets/Custom_Textfield.dart';
import '../../Widgets/Social_Button.dart';
import '../RoleSelection/RoleSelection_Screen.dart';


/// ============================================
/// SIGNUP SCREEN
/// User registration with modern UI
/// ============================================

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptTerms) {
        Get.snackbar(
          'Terms Required',
          'Please accept the terms and conditions',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      setState(() => _isLoading = true);

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isLoading = false);

      // Navigate to role selection
      Get.off(
            () => const RoleSelectionScreen(),
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

                  const SizedBox(height: 20),

                  // Header
                  _buildHeader(isDark),

                  const SizedBox(height: 30),

                  // Sign up form
                  _buildSignUpForm(isDark),

                  const SizedBox(height: 20),

                  // Terms checkbox
                  _buildTermsCheckbox(isDark),

                  const SizedBox(height: 24),

                  // Sign up button
                  _buildSignUpButton(isDark),

                  const SizedBox(height: 24),

                  // Divider
                  _buildDivider(isDark),

                  const SizedBox(height: 24),

                  // Social buttons
                  _buildSocialButtons(isDark),

                  const SizedBox(height: 30),

                  // Sign in link
                  _buildSignInLink(isDark),

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
              AppColors.primaryYellow.withOpacity(isDark ? 0.1 : 0.08),
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

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Account',
          style: GoogleFonts.urbanist(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.grey900,
            letterSpacing: -1,
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 200.ms)
            .slideX(begin: -0.1, end: 0),

        const SizedBox(height: 8),

        Text(
          'Fill in your details to get started',
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.grey500,
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 300.ms)
            .slideX(begin: -0.1, end: 0),
      ],
    );
  }

  Widget _buildSignUpForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Full Name
          CustomTextField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'Enter your full name',
            prefixIcon: Iconsax.user,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your name';
              }
              return null;
            },
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 400.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Email
          CustomTextField(
            controller: _emailController,
            label: 'Email',
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
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 500.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Phone Number
          CustomTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter your phone number',
            prefixIcon: Iconsax.call,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your phone number';
              }
              return null;
            },
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 600.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Password
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Create a password',
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
              .fadeIn(duration: 500.ms, delay: 700.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Confirm Password
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: 'Confirm your password',
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
              .fadeIn(duration: 500.ms, delay: 800.ms)
              .slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox(bool isDark) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _acceptTerms = !_acceptTerms);
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _acceptTerms ? AppColors.primaryYellow : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _acceptTerms
                    ? AppColors.primaryYellow
                    : AppColors.grey500,
                width: 2,
              ),
            ),
            child: _acceptTerms
                ? const Icon(
              Icons.check,
              size: 16,
              color: AppColors.darkBackground,
            )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the ',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: AppColors.grey500,
              ),
              children: [
                TextSpan(
                  text: 'Terms of Service',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryYellow,
                  ),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryYellow,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 900.ms);
  }

  Widget _buildSignUpButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
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
            : Text(
          'Create Account',
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

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or sign up with',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.grey500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 1100.ms);
  }

  Widget _buildSocialButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: SocialButton(
            icon: 'G',
            label: 'Google',
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SocialButton(
            icon: '',
            label: 'Apple',
            isApple: true,
            onPressed: () {},
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 1200.ms);
  }

  Widget _buildSignInLink(bool isDark) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              color: AppColors.grey500,
            ),
          ),
          GestureDetector(
            onTap: () => Get.back(),
            child: Text(
              'Sign In',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryYellow,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 1300.ms);
  }
}