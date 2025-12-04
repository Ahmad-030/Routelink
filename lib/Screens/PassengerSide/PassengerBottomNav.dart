import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';

/// ============================================
/// PASSENGER BOTTOM NAVIGATION
/// Custom bottom nav bar for passenger
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 12,
        left: 16,
        right: 16,
      ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Iconsax.home_2,
            activeIcon: Iconsax.home_15,
            label: 'Home',
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Iconsax.document,
            activeIcon: Iconsax.document,
            label: 'Requests',
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Iconsax.message,
            activeIcon: Iconsax.message,
            label: 'Chats',
            isActive: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Iconsax.clock,
            activeIcon: Iconsax.clock,
            label: 'History',
            isActive: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: Iconsax.setting_2,
            activeIcon: Iconsax.setting_2,
            label: 'Settings',
            isActive: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              color: isActive
                  ? AppColors.primaryYellow
                  : (isDark ? AppColors.grey500 : AppColors.grey600),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? AppColors.primaryYellow
                    : (isDark ? AppColors.grey500 : AppColors.grey600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}