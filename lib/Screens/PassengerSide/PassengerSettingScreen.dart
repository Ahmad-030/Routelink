import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:routelink/Core/Theme/App_theme.dart';
import 'package:routelink/Screens/Auth_Screen/Login_Screen.dart';
import '../../Services/Firebase Auth.dart';

/// ============================================
/// PASSENGER SETTINGS SCREEN
/// Account settings and preferences
/// ============================================

class PassengerSettingsScreen extends StatefulWidget {
  const PassengerSettingsScreen({super.key});

  @override
  State<PassengerSettingsScreen> createState() => _PassengerSettingsScreenState();
}

class _PassengerSettingsScreenState extends State<PassengerSettingsScreen> {
  bool _isDarkMode = Get.isDarkMode;
  bool _notificationsEnabled = true;

  void _toggleTheme(bool value) {
    setState(() => _isDarkMode = value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _logout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.logout, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.urbanist(fontWeight: FontWeight.w600, color: AppColors.grey500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await AuthService.to.signOut();
              Get.offAll(() => const LoginScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = AuthService.to.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Settings',
          style: GoogleFonts.urbanist(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryYellow.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.darkBackground.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        user?.name.isNotEmpty == true
                            ? user!.name.substring(0, 1).toUpperCase()
                            : 'P',
                        style: GoogleFonts.urbanist(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBackground,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Passenger',
                          style: GoogleFonts.urbanist(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBackground,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'No email',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            color: AppColors.darkBackground.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Iconsax.star1, size: 16, color: AppColors.darkBackground),
                            const SizedBox(width: 4),
                            Text(
                              '${user?.rating ?? 5.0}',
                              style: GoogleFonts.urbanist(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkBackground,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.darkBackground.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Passenger',
                                style: GoogleFonts.urbanist(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkBackground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Navigate to edit profile
                    },
                    icon: const Icon(
                      Iconsax.edit,
                      color: AppColors.darkBackground,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),

            const SizedBox(height: 24),

            // Preferences section
            Text(
              'Preferences',
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grey500,
              ),
            ),
            const SizedBox(height: 12),

            // Theme toggle
            _buildSettingTile(
              icon: Iconsax.moon,
              title: 'Dark Mode',
              subtitle: 'Toggle dark/light theme',
              isDark: isDark,
              trailing: Switch(
                value: _isDarkMode,
                onChanged: _toggleTheme,
                activeColor: AppColors.primaryYellow,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 12),

            // Notifications toggle
            _buildSettingTile(
              icon: Iconsax.notification,
              title: 'Notifications',
              subtitle: 'Enable push notifications',
              isDark: isDark,
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (val) => setState(() => _notificationsEnabled = val),
                activeColor: AppColors.primaryYellow,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 24),

            // Account section
            Text(
              'Account',
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grey500,
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingTile(
              icon: Iconsax.user,
              title: 'Edit Profile',
              subtitle: 'Update your information',
              isDark: isDark,
              onTap: () {
                // TODO: Navigate to edit profile
              },
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

            const SizedBox(height: 12),

            _buildSettingTile(
              icon: Iconsax.lock,
              title: 'Change Password',
              subtitle: 'Update your password',
              isDark: isDark,
              onTap: () {
                // TODO: Navigate to change password
              },
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

            const SizedBox(height: 12),

            _buildSettingTile(
              icon: Iconsax.card,
              title: 'Payment Methods',
              subtitle: 'Manage payment options',
              isDark: isDark,
              onTap: () {
                // TODO: Navigate to payment methods
              },
            ).animate().fadeIn(duration: 400.ms, delay: 500.ms),

            const SizedBox(height: 24),

            // Support section
            Text(
              'Support',
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grey500,
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingTile(
              icon: Iconsax.message_question,
              title: 'Help Center',
              subtitle: 'Get help and support',
              isDark: isDark,
              onTap: () {},
            ).animate().fadeIn(duration: 400.ms, delay: 600.ms),

            const SizedBox(height: 12),

            _buildSettingTile(
              icon: Iconsax.document_text,
              title: 'Terms & Conditions',
              subtitle: 'View legal terms',
              isDark: isDark,
              onTap: () {},
            ).animate().fadeIn(duration: 400.ms, delay: 700.ms),

            const SizedBox(height: 12),

            _buildSettingTile(
              icon: Iconsax.shield_tick,
              title: 'Privacy Policy',
              subtitle: 'View privacy policy',
              isDark: isDark,
              onTap: () {},
            ).animate().fadeIn(duration: 400.ms, delay: 800.ms),

            const SizedBox(height: 24),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Iconsax.logout, size: 20),
                label: Text(
                  'Logout',
                  style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 900.ms),

            const SizedBox(height: 20),

            // Version info
            Center(
              child: Text(
                'Version 1.0.0',
                style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryYellow, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.urbanist(fontSize: 13, color: AppColors.grey500),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Iconsax.arrow_right_3,
                  color: AppColors.grey500,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}