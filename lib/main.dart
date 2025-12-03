import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:routelink/Services/Firebase%20Auth.dart';
import 'package:routelink/Services/RideService.dart';
import 'package:routelink/Services/chatService.dart';
import 'firebase_options.dart';

import 'Core/Theme/Theme_controller.dart';

import 'Screens/Splash_Screen/SplashScreen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.darkBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize controllers and services
  Get.put(ThemeController());
  Get.put(AuthService());
  Get.put(RideService());
  Get.put(ChatService());

  runApp(const RouteLinkApp());
}

class RouteLinkApp extends StatelessWidget {
  const RouteLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'RouteLink',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),

      home: const SplashScreen(),

      enableLog: true,
      logWriterCallback: (text, {bool isError = false}) {
        debugPrint('GetX Log: $text');
      },
    );
  }
}