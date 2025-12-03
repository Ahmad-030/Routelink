import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';

/// ============================================
/// DRIVER CARD
/// Card showing driver details for passengers
/// ============================================

class DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final VoidCallback onTap;
  final VoidCallback onChat;

  const DriverCard({
    super.key,
    required this.driver,
    required this.onTap,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header - Driver info
            Row(
              children: [
                // Avatar with car icon
                Stack(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          driver['name'].toString().substring(0, 1).toUpperCase(),
                          style: GoogleFonts.urbanist(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBackground,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.car,
                          size: 12,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Name and car info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            driver['name'],
                            style: GoogleFonts.urbanist(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.grey900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Iconsax.star1,
                                  size: 12,
                                  color: AppColors.primaryYellow,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${driver['rating']}',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryYellow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${driver['carName']} • ${driver['carNumber']}',
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chat button
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkElevated : AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: onChat,
                    icon: Icon(
                      Iconsax.message,
                      color: isDark ? Colors.white : AppColors.grey700,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Route info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground.withOpacity(0.5)
                    : AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.routing,
                    color: AppColors.primaryYellow,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      driver['route'],
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Stats row
            Row(
              children: [
                // Distance
                _buildStat(
                  icon: Iconsax.location,
                  value: driver['distance'],
                  label: 'Away',
                  isDark: isDark,
                ),

                Container(
                  width: 1,
                  height: 30,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),

                // ETA
                _buildStat(
                  icon: Iconsax.clock,
                  value: driver['eta'],
                  label: 'ETA',
                  isDark: isDark,
                ),

                Container(
                  width: 1,
                  height: 30,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),

                // Seats
                _buildStat(
                  icon: Iconsax.user,
                  value: '${driver['seats']}',
                  label: 'Seats',
                  isDark: isDark,
                ),

                const Spacer(),

                // Fare
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Rs. ${driver['suggestedFare']}',
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBackground,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.grey500,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 11,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}