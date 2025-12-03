import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:routelink/Core/Theme/App_theme.dart';
import 'package:routelink/Models/user_model.dart';
import 'package:routelink/Services/Firebase%20Auth.dart';

import '../../Widgets/Custom_Textfield.dart';
import '../../Widgets/Social_Button.dart';
import '../DriverSIde/Driver_homeScreen.dart';
import '../PassengerSide/PassengerHomeScreen.dart';
import 'Forget_Screen/ForgetScreen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService.to;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final success = await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        setState(() => _isLoading = false);

        if (success) {
          // Get the current user to check their role
          final currentUser = _authService.currentUser;

          if (currentUser != null) {
            Get.snackbar(
              'Success',
              'Welcome back!',
              backgroundColor: AppColors.success,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 2),
            );

            // Navigate based on user role
            await Future.delayed(const Duration(milliseconds: 300));

            if (currentUser.role == 'driver') {
              Get.offAll(() => const DriverHomeScreen(), transition: Transition.fadeIn);
            } else {
              Get.offAll(() => const PassengerHomeScreen(), transition: Transition.fadeIn);
            }
          } else {
            // User data not loaded yet, wait a bit and try again
            await Future.delayed(const Duration(milliseconds: 500));
            final retryUser = _authService.currentUser;

            if (retryUser != null) {
              if (retryUser.role == 'driver') {
                Get.offAll(() => const DriverHomeScreen(), transition: Transition.fadeIn);
              } else {
                Get.offAll(() => const PassengerHomeScreen(), transition: Transition.fadeIn);
              }
            } else {
              Get.snackbar(
                'Error',
                'Failed to load user data. Please try again.',
                backgroundColor: Colors.red,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
              );
            }
          }
        }
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        Get.snackbar(
          'Error',
          'Login failed: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          _buildBackground(isDark),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildBackButton(isDark),
                  const SizedBox(height: 30),
                  _buildHeader(isDark),
                  const SizedBox(height: 40),
                  _buildLoginForm(isDark),
                  const SizedBox(height: 24),
                  _buildForgotPassword(),
                  const SizedBox(height: 32),
                  _buildLoginButton(isDark),
                  const SizedBox(height: 32),
                  _buildDivider(isDark),
                  const SizedBox(height: 32),
                  _buildSocialButtons(isDark),
                  const SizedBox(height: 40),
                  _buildSignUpLink(isDark),
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
      right: -100,
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
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8));
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
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Icon(Iconsax.arrow_left, color: isDark ? Colors.white : AppColors.grey900),
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome', style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryYellow, letterSpacing: 1))
            .animate().fadeIn(duration: 500.ms, delay: 200.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: 8),
        Text('Sign In', style: GoogleFonts.urbanist(fontSize: 36, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.grey900, letterSpacing: -1))
            .animate().fadeIn(duration: 500.ms, delay: 300.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: 8),
        Text('Enter your credentials to continue', style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.grey500))
            .animate().fadeIn(duration: 500.ms, delay: 400.ms).slideX(begin: -0.1, end: 0),
      ],
    );
  }

  Widget _buildLoginForm(bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your email',
            prefixIcon: Iconsax.sms,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter your email';
              if (!GetUtils.isEmail(value!)) return 'Please enter a valid email';
              return null;
            },
          ).animate().fadeIn(duration: 500.ms, delay: 500.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            prefixIcon: Iconsax.lock,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Iconsax.eye_slash : Iconsax.eye, color: AppColors.grey500),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please enter your password';
              if (value!.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ).animate().fadeIn(duration: 500.ms, delay: 600.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Get.to(() => const ForgotPasswordScreen(), transition: Transition.rightToLeftWithFade),
        child: Text('Forgot Password?', style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryYellow)),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 700.ms);
  }

  Widget _buildLoginButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.darkBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkBackground)))
            : Text('Sign In', style: GoogleFonts.urbanist(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 800.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Or continue with', style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.grey500)),
        ),
        Expanded(child: Container(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 900.ms);
  }

  Widget _buildSocialButtons(bool isDark) {
    return Row(
      children: [
        Expanded(child: SocialButton(icon: 'G', label: 'Google', onPressed: () {})),
        const SizedBox(width: 16),
        Expanded(child: SocialButton(icon: '', label: 'Apple', isApple: true, onPressed: () {})),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 1000.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildSignUpLink(bool isDark) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Don't have an account? ", style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.grey500)),
          GestureDetector(
            onTap: () => Get.to(() => const SignUpScreen(), transition: Transition.rightToLeftWithFade),
            child: Text('Sign Up', style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryYellow)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 1100.ms);
  }
}