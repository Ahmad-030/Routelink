import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Core/Theme/App_theme.dart';
import '../../Models/Ride_model.dart';
import '../../Services/Firebase Auth.dart';
import 'ActiveRideScreen.dart';

/// ============================================
/// DRIVER ROUTES SCREEN
/// Shows driver's active and published routes
/// ============================================

class DriverRoutesScreen extends StatelessWidget {
  const DriverRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = AuthService.to.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: isDark ? Colors.white : AppColors.grey900),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'My Routes',
          style: GoogleFonts.urbanist(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        ),
        centerTitle: true,
      ),
      body: userId == null
          ? _buildEmptyState(isDark)
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rides')
            .where('driverId', isEqualTo: userId)
            .where('status', whereIn: ['active', 'accepted', 'inProgress'])
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(isDark);
          }

          if (snapshot.hasError) {
            return _buildErrorState(isDark, snapshot.error.toString());
          }

          final rides = snapshot.data?.docs ?? [];

          if (rides.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final rideData = rides[index].data() as Map<String, dynamic>;
              final ride = RideModel.fromJson({
                'id': rides[index].id,
                ...rideData,
              });
              return _buildRouteCard(ride, isDark, index, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildRouteCard(RideModel ride, bool isDark, int index, BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (ride.status) {
      case RideStatus.active:
        statusColor = AppColors.success;
        statusText = 'Active';
        statusIcon = Iconsax.tick_circle;
        break;
      case RideStatus.accepted:
        statusColor = AppColors.info;
        statusText = 'Accepted';
        statusIcon = Iconsax.user_tick;
        break;
      case RideStatus.inProgress:
        statusColor = AppColors.primaryYellow;
        statusText = 'In Progress';
        statusIcon = Iconsax.car;
        break;
      default:
        statusColor = AppColors.grey500;
        statusText = 'Unknown';
        statusIcon = Iconsax.info_circle;
    }

    return GestureDetector(
      onTap: () {
        if (ride.status == RideStatus.inProgress || ride.status == RideStatus.accepted) {
          Get.to(() => ActiveRideScreen(ride: ride));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ride.status == RideStatus.inProgress
                ? AppColors.primaryYellow.withOpacity(0.5)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: ride.status == RideStatus.inProgress ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.status == RideStatus.inProgress
                            ? 'Ride in Progress'
                            : 'Route Published',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(ride.createdAt ?? DateTime.now()),
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor == AppColors.primaryYellow
                          ? AppColors.darkBackground
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Passenger info (if accepted)
            if (ride.passengerName != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          ride.passengerName!.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Passenger',
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              color: AppColors.grey500,
                            ),
                          ),
                          Text(
                            ride.passengerName!,
                            style: GoogleFonts.urbanist(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColors.grey900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Iconsax.call, color: AppColors.info, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Route
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground.withOpacity(0.5) : AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
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
                          ride.startLocation.address,
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : AppColors.grey900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Column(
                      children: List.generate(
                        2,
                            (i) => Container(
                          width: 2,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: AppColors.grey500,
                        ),
                      ),
                    ),
                  ),
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
                          ride.endLocation.address,
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : AppColors.grey900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats & Actions
            Row(
              children: [
                _buildStat(
                  icon: Iconsax.user,
                  value: '${ride.availableSeats} seats',
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                if (ride.suggestedFare != null)
                  _buildStat(
                    icon: Iconsax.money,
                    value: 'Rs. ${ride.suggestedFare}',
                    isDark: isDark,
                  ),
                const Spacer(),
                if (ride.status == RideStatus.active)
                  TextButton(
                    onPressed: () => _cancelRoute(ride.id, context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                if (ride.status == RideStatus.inProgress)
                  ElevatedButton.icon(
                    onPressed: () => Get.to(() => ActiveRideScreen(ride: ride)),
                    icon: const Icon(Iconsax.arrow_right_3, size: 18),
                    label: Text(
                      'Track',
                      style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: AppColors.darkBackground,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grey500),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        ),
      ],
    );
  }

  void _cancelRoute(String rideId, BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel Route',
          style: GoogleFonts.urbanist(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this route?',
          style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'No',
              style: GoogleFonts.urbanist(
                fontWeight: FontWeight.w600,
                color: AppColors.grey500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await FirebaseFirestore.instance.collection('rides').doc(rideId).update({
                'status': 'cancelled',
              });
              Get.snackbar(
                'Route Cancelled',
                'Your route has been cancelled',
                backgroundColor: AppColors.error,
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.urbanist(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading routes...',
            style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.routing,
              size: 48,
              color: AppColors.primaryYellow,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Active Routes',
            style: GoogleFonts.urbanist(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Publish a route to start receiving\nride requests',
            textAlign: TextAlign.center,
            style: GoogleFonts.urbanist(
              fontSize: 16,
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildErrorState(bool isDark, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.danger, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}