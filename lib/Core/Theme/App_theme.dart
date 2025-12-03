import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================
/// ROUTELINK APP COLORS
/// Theme: Black, Yellow, Grey - Premium Ride App
/// ============================================

class AppColors {
  // ══════════════════════════════════════════
  // PRIMARY BRAND COLORS
  // ══════════════════════════════════════════
  static const Color primaryYellow = Color(0xFFFFD700);      // Main Yellow
  static const Color accentYellow = Color(0xFFFFC107);       // Accent Yellow
  static const Color brightYellow = Color(0xFFFFEB3B);       // Bright Yellow
  static const Color darkYellow = Color(0xFFE6B800);         // Darker Yellow
  static const Color goldenYellow = Color(0xFFFFAA00);       // Golden Accent

  // ══════════════════════════════════════════
  // DARK THEME COLORS
  // ══════════════════════════════════════════
  static const Color darkBackground = Color(0xFF0A0A0A);     // Pure Dark BG
  static const Color darkSurface = Color(0xFF141414);        // Cards/Surfaces
  static const Color darkCard = Color(0xFF1C1C1C);           // Elevated Cards
  static const Color darkElevated = Color(0xFF262626);       // Higher Elevation
  static const Color darkBorder = Color(0xFF2A2A2A);         // Borders

  // ══════════════════════════════════════════
  // LIGHT THEME COLORS
  // ══════════════════════════════════════════
  static const Color lightBackground = Color(0xFFF8F8F8);    // Light BG
  static const Color lightSurface = Color(0xFFFFFFFF);       // White Surface
  static const Color lightCard = Color(0xFFFFFFFF);          // Cards
  static const Color lightElevated = Color(0xFFF0F0F0);      // Elevated
  static const Color lightBorder = Color(0xFFE0E0E0);        // Borders

  // ══════════════════════════════════════════
  // GREY SCALE
  // ══════════════════════════════════════════
  static const Color grey900 = Color(0xFF121212);
  static const Color grey800 = Color(0xFF1E1E1E);
  static const Color grey700 = Color(0xFF333333);
  static const Color grey600 = Color(0xFF4A4A4A);
  static const Color grey500 = Color(0xFF6B6B6B);
  static const Color grey400 = Color(0xFF8C8C8C);
  static const Color grey300 = Color(0xFFADADAD);
  static const Color grey200 = Color(0xFFD4D4D4);
  static const Color grey100 = Color(0xFFEBEBEB);
  static const Color grey50 = Color(0xFFF5F5F5);

  // ══════════════════════════════════════════
  // SEMANTIC COLORS
  // ══════════════════════════════════════════
  static const Color success = Color(0xFF00C853);
  static const Color successLight = Color(0xFF69F0AE);
  static const Color error = Color(0xFFFF3D3D);
  static const Color errorLight = Color(0xFFFF8A80);
  static const Color warning = Color(0xFFFFAB00);
  static const Color info = Color(0xFF00B0FF);
  static const Color online = Color(0xFF00E676);

  // ══════════════════════════════════════════
  // GRADIENTS
  // ══════════════════════════════════════════
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryYellow, goldenYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [darkBackground, Color(0xFF1A1A1A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient yellowGlow = LinearGradient(
    colors: [
      Color(0x60FFD700),
      Color(0x20FFD700),
      Color(0x00FFD700),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [
      Color(0xFF1C1C1C),
      Color(0xFF141414),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient yellowRadial = RadialGradient(
    colors: [
      Color(0x40FFD700),
      Color(0x00FFD700),
    ],
    radius: 1.0,
  );
}

/// ============================================
/// APP THEME CONFIGURATION
/// ============================================

class AppTheme {
  // ══════════════════════════════════════════
  // DARK THEME
  // ══════════════════════════════════════════
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryYellow,
    scaffoldBackgroundColor: AppColors.darkBackground,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryYellow,
      secondary: AppColors.accentYellow,
      surface: AppColors.darkSurface,
      error: AppColors.error,
      onPrimary: AppColors.darkBackground,
      onSecondary: AppColors.darkBackground,
      onSurface: Colors.white,
      onError: Colors.white,
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.urbanist(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppColors.darkBorder.withOpacity(0.5),
          width: 1,
        ),
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: AppColors.darkBackground,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryYellow,
        side: const BorderSide(color: AppColors.primaryYellow, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryYellow,
        textStyle: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.darkBorder.withOpacity(0.5),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryYellow, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: GoogleFonts.urbanist(
        color: AppColors.grey500,
        fontSize: 16,
      ),
      labelStyle: GoogleFonts.urbanist(
        color: AppColors.grey400,
        fontSize: 16,
      ),
      prefixIconColor: AppColors.grey400,
      suffixIconColor: AppColors.grey400,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primaryYellow,
      unselectedItemColor: AppColors.grey500,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryYellow,
      foregroundColor: AppColors.darkBackground,
      elevation: 8,
      shape: CircleBorder(),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkCard,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkCard,
      selectedColor: AppColors.primaryYellow,
      labelStyle: GoogleFonts.urbanist(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
    ),

    // Text Theme
    textTheme: _buildTextTheme(isDark: true),
  );

  // ══════════════════════════════════════════
  // LIGHT THEME
  // ══════════════════════════════════════════
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primaryYellow,
    scaffoldBackgroundColor: AppColors.lightBackground,

    colorScheme: const ColorScheme.light(
      primary: AppColors.grey900,
      secondary: AppColors.primaryYellow,
      surface: AppColors.lightSurface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: AppColors.grey900,
      onSurface: AppColors.grey900,
      onError: Colors.white,
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.urbanist(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.grey900,
      ),
      iconTheme: const IconThemeData(color: AppColors.grey900),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppColors.lightBorder.withOpacity(0.5),
          width: 1,
        ),
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.grey900,
        foregroundColor: AppColors.primaryYellow,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.grey900,
        side: const BorderSide(color: AppColors.grey900, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.lightBorder.withOpacity(0.5),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.grey900, width: 2),
      ),
      hintStyle: GoogleFonts.urbanist(
        color: AppColors.grey500,
        fontSize: 16,
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.grey900,
      unselectedItemColor: AppColors.grey400,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Text Theme
    textTheme: _buildTextTheme(isDark: false),
  );

  // ══════════════════════════════════════════
  // TEXT THEME BUILDER
  // ══════════════════════════════════════════
  static TextTheme _buildTextTheme({required bool isDark}) {
    final Color textPrimary = isDark ? Colors.white : AppColors.grey900;
    final Color textSecondary = isDark ? AppColors.grey300 : AppColors.grey600;
    final Color textTertiary = isDark ? AppColors.grey500 : AppColors.grey400;

    return TextTheme(
      // Display Styles
      displayLarge: GoogleFonts.urbanist(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -2,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.urbanist(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -1.5,
        height: 1.15,
      ),
      displaySmall: GoogleFonts.urbanist(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -1,
        height: 1.2,
      ),

      // Headline Styles
      headlineLarge: GoogleFonts.urbanist(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.urbanist(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.urbanist(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),

      // Title Styles
      titleLarge: GoogleFonts.urbanist(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.urbanist(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.urbanist(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),

      // Body Styles
      bodyLarge: GoogleFonts.urbanist(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.urbanist(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.urbanist(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textTertiary,
        height: 1.4,
      ),

      // Label Styles
      labelLarge: GoogleFonts.urbanist(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryYellow,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.urbanist(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.urbanist(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textTertiary,
        letterSpacing: 0.5,
      ),
    );
  }
}