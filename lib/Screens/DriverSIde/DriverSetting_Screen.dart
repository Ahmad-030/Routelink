import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../Core/Theme/App_theme.dart';
import '../../Core/Theme/Theme_controller.dart';
import '../../Models/user_model.dart';
import '../../Services/Firebase Auth.dart';
import '../Auth_Screen/Login_Screen.dart';

/// ============================================
/// DRIVER SETTINGS SCREEN
/// Profile, settings, and account management
/// ============================================

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationSharing = true;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    // Ensure ThemeController is registered
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = AuthService.to.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            leading: IconButton(
              icon: Icon(Iconsax.arrow_left, color: isDark ? Colors.white : AppColors.grey900),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Settings',
                style: GoogleFonts.urbanist(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
              centerTitle: true,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  _buildProfileSection(isDark, user),
                  const SizedBox(height: 24),

                  // Stats Section
                  _buildStatsSection(isDark, user),
                  const SizedBox(height: 24),

                  // Account Settings
                  _buildSectionTitle('Account', isDark),
                  const SizedBox(height: 12),
                  _buildSettingsCard(isDark, [
                    _buildSettingsItem(
                      icon: Iconsax.user_edit,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      isDark: isDark,
                      onTap: () => _showEditProfileSheet(isDark, user),
                    ),
                    _buildSettingsItem(
                      icon: Iconsax.car,
                      title: 'Vehicle Details',
                      subtitle: 'Manage your vehicle information',
                      isDark: isDark,
                      onTap: () => _showVehicleDetailsSheet(isDark),
                    ),
                    _buildSettingsItem(
                      icon: Iconsax.document,
                      title: 'Documents',
                      subtitle: 'License, registration, insurance',
                      isDark: isDark,
                      onTap: () {},
                      showDivider: false,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Preferences
                  _buildSectionTitle('Preferences', isDark),
                  const SizedBox(height: 12),
                  _buildSettingsCard(isDark, [
                    _buildSwitchItem(
                      icon: Iconsax.notification,
                      title: 'Notifications',
                      subtitle: 'Receive ride requests and updates',
                      value: _notificationsEnabled,
                      isDark: isDark,
                      onChanged: (val) => setState(() => _notificationsEnabled = val),
                    ),
                    _buildSwitchItem(
                      icon: Iconsax.location,
                      title: 'Location Sharing',
                      subtitle: 'Share location while on a ride',
                      value: _locationSharing,
                      isDark: isDark,
                      onChanged: (val) => setState(() => _locationSharing = val),
                    ),
                    _buildSwitchItem(
                      icon: Iconsax.volume_high,
                      title: 'Sound Effects',
                      subtitle: 'Play sounds for notifications',
                      value: _soundEnabled,
                      isDark: isDark,
                      onChanged: (val) => setState(() => _soundEnabled = val),
                      showDivider: false,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Appearance
                  _buildSectionTitle('Appearance', isDark),
                  const SizedBox(height: 12),
                  _buildSettingsCard(isDark, [
                    _buildSwitchItem(
                      icon: isDark ? Iconsax.moon : Iconsax.sun_1,
                      title: 'Dark Mode',
                      subtitle: 'Toggle dark/light theme',
                      value: isDark,
                      isDark: isDark,
                      onChanged: (val) {
                        // Safely toggle theme
                        if (Get.isRegistered<ThemeController>()) {
                          ThemeController.to.toggleTheme();
                        } else {
                          Get.changeThemeMode(
                            Get.isDarkMode ? ThemeMode.light : ThemeMode.dark,
                          );
                        }
                      },
                      showDivider: false,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Support
                  _buildSectionTitle('Support', isDark),
                  const SizedBox(height: 12),
                  _buildSettingsCard(isDark, [
                    _buildSettingsItem(
                      icon: Iconsax.message_question,
                      title: 'Help Center',
                      subtitle: 'Get help and support',
                      isDark: isDark,
                      onTap: () {},
                    ),
                    _buildSettingsItem(
                      icon: Iconsax.info_circle,
                      title: 'About RouteLink',
                      subtitle: 'Version 1.0.0',
                      isDark: isDark,
                      onTap: () {},
                    ),
                    _buildSettingsItem(
                      icon: Iconsax.shield_tick,
                      title: 'Privacy Policy',
                      subtitle: 'Read our privacy policy',
                      isDark: isDark,
                      onTap: () {},
                      showDivider: false,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Logout Button
                  _buildLogoutButton(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(bool isDark, UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryYellow.withOpacity(0.15),
            AppColors.primaryYellow.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryYellow.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                user?.name.isNotEmpty == true
                    ? user!.name.substring(0, 1).toUpperCase()
                    : 'D',
                style: GoogleFonts.urbanist(
                  fontSize: 32,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user?.name ?? 'Driver',
                        style: GoogleFonts.urbanist(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.car, size: 14, color: AppColors.darkBackground),
                          const SizedBox(width: 4),
                          Text(
                            'Driver',
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkBackground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    color: AppColors.grey500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Iconsax.star1, size: 16, color: AppColors.primaryYellow),
                    const SizedBox(width: 4),
                    Text(
                      '${user?.rating ?? 5.0}',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.grey500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${user?.totalRides ?? 0} rides',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildStatsSection(bool isDark, UserModel? user) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.routing,
            value: '${user?.totalRides ?? 0}',
            label: 'Total Rides',
            color: AppColors.success,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.star1,
            value: '${user?.rating ?? 5.0}',
            label: 'Rating',
            color: AppColors.primaryYellow,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Iconsax.wallet_2,
            value: 'Rs.0',
            label: 'Earnings',
            color: AppColors.info,
            isDark: isDark,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 12,
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.urbanist(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : AppColors.grey900,
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primaryYellow, size: 22),
                ),
                const SizedBox(width: 16),
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
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Iconsax.arrow_right_3, color: AppColors.grey500, size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
            indent: 60,
          ),
      ],
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required Function(bool) onChanged,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryYellow, size: 22),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primaryYellow,
                activeTrackColor: AppColors.primaryYellow.withOpacity(0.3),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
            indent: 60,
          ),
      ],
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(isDark),
        icon: const Icon(Iconsax.logout, color: AppColors.error),
        label: Text(
          'Logout',
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  void _showLogoutDialog(bool isDark) {
    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.urbanist(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.urbanist(
            fontSize: 16,
            color: AppColors.grey500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey500,
              ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(bool isDark, UserModel? user) {
    final nameController = TextEditingController(text: user?.name ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey500,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Edit Profile',
              style: GoogleFonts.urbanist(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: GoogleFonts.urbanist(color: AppColors.grey500),
                prefixIcon: const Icon(Iconsax.user, color: AppColors.grey500),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.urbanist(
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: GoogleFonts.urbanist(color: AppColors.grey500),
                prefixIcon: const Icon(Iconsax.call, color: AppColors.grey500),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.urbanist(
                color: isDark ? Colors.white : AppColors.grey900,
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Update profile in Firebase
                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Profile updated successfully',
                    backgroundColor: AppColors.success,
                    colorText: Colors.white,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.darkBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showVehicleDetailsSheet(bool isDark) {
    final carNameController = TextEditingController();
    final carNumberController = TextEditingController();
    final carColorController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey500,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Vehicle Details',
              style: GoogleFonts.urbanist(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: carNameController,
              decoration: InputDecoration(
                labelText: 'Car Name/Model',
                labelStyle: GoogleFonts.urbanist(color: AppColors.grey500),
                prefixIcon: const Icon(Iconsax.car, color: AppColors.grey500),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.urbanist(color: isDark ? Colors.white : AppColors.grey900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: carNumberController,
              decoration: InputDecoration(
                labelText: 'License Plate',
                labelStyle: GoogleFonts.urbanist(color: AppColors.grey500),
                prefixIcon: const Icon(Iconsax.card, color: AppColors.grey500),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.urbanist(color: isDark ? Colors.white : AppColors.grey900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: carColorController,
              decoration: InputDecoration(
                labelText: 'Car Color',
                labelStyle: GoogleFonts.urbanist(color: AppColors.grey500),
                prefixIcon: const Icon(Iconsax.colorfilter, color: AppColors.grey500),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.urbanist(color: isDark ? Colors.white : AppColors.grey900),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.snackbar(
                    'Success',
                    'Vehicle details saved',
                    backgroundColor: AppColors.success,
                    colorText: Colors.white,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.darkBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Save Vehicle',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}