import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:routelink/Screens/Onboarding_Screen/Onboarding_Screen.dart';
import 'package:routelink/Screens/Splash_Screen/SplashScreen.dart';
import 'Services/Firebase Auth.dart';
import 'Core/Theme/App_theme.dart';
import 'Screens/DriverSIde/Driver_homeScreen.dart';
import 'Screens/PassengerSide/PassengerHomeScreen.dart';
import 'Models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize AuthService - this must be done BEFORE runApp
  Get.put(AuthService());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'RouteLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(), // Always start with splash screen
    );
  }
}

/// AuthWrapper - Handles automatic navigation based on authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final authService = AuthService.to;
      final firebaseUser = authService.firebaseUser;
      final currentUser = authService.currentUser;

      // Case 1: No user authenticated - show onboarding
      if (firebaseUser == null) {
        return const OnboardingScreen();
      }

      // Case 2: User authenticated but data not loaded yet - show loading
      if (currentUser == null) {
        return Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading your profile...',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Case 3: User authenticated and data loaded - navigate based on role
      if (currentUser.role == UserRole.driver) {
        return const DriverHomeScreen();
      } else {
        return const PassengerHomeScreen();
      }
    });
  }
}