import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';

/// ============================================
/// RIDE REQUEST CARD
/// Card showing passenger ride request details
/// ============================================

class RideRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onChat;

  const RideRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          // Header - User info
          Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    request['name'].toString().substring(0, 1).toUpperCase(),
                    style: GoogleFonts.urbanist(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBackground,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name and rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['name'],
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Iconsax.star1,
                          size: 14,
                          color: AppColors.primaryYellow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${request['rating']}',
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.grey500,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          request['distance'],
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Offered fare
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Rs. ${request['offeredFare']}',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryYellow,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Route info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground.withOpacity(0.5)
                  : AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Pickup
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        request['pickup'],
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                      ),
                    ),
                  ],
                ),

                // Dotted line
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Column(
                    children: List.generate(3, (index) {
                      return Container(
                        width: 2,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: AppColors.grey500,
                      );
                    }),
                  ),
                ),

                // Dropoff
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryYellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        request['dropoff'],
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              // Reject button
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Decline',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

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
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Accept button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: AppColors.darkBackground,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.tick_circle, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Accept',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}