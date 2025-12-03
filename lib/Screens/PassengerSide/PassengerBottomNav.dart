import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';

/// ============================================
/// PASSENGER BOTTOM NAVIGATION BAR
/// Custom styled bottom nav for passengers
/// ============================================

class PassengerBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PassengerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Iconsax.home_2,
              activeIcon: Iconsax.home_25,
              label: 'Home',
              isDark: isDark,
            ),
            _buildNavItem(
              index: 1,
              icon: Iconsax.discover,
              activeIcon: Iconsax.discover5,
              label: 'Explore',
              isDark: isDark,
            ),
            _buildNavItem(
              index: 2,
              icon: Iconsax.message,
              activeIcon: Iconsax.message5,
              label: 'Chats',
              isDark: isDark,
            ),
            _buildNavItem(
              index: 3,
              icon: Iconsax.clock,
              activeIcon: Iconsax.clock5,
              label: 'History',
              isDark: isDark,
            ),
            _buildNavItem(
              index: 4,
              icon: Iconsax.profile_circle,
              activeIcon: Iconsax.profile_circle5,
              label: 'Profile',
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryYellow.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive
                  ? AppColors.primaryYellow
                  : AppColors.grey500,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? AppColors.primaryYellow
                    : AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}