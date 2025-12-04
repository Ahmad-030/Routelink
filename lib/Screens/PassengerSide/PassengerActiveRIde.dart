import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../Models/Ride_model.dart';
import '../../Services/Firebase Auth.dart';
import '../Chat/Chat_Screen.dart';

/// ============================================
/// PASSENGER ACTIVE RIDE SCREEN
/// Real-time ride tracking for passengers
/// ============================================

class PassengerActiveRideScreen extends StatefulWidget {
  final RideModel ride;

  const PassengerActiveRideScreen({super.key, required this.ride});

  @override
  State<PassengerActiveRideScreen> createState() => _PassengerActiveRideScreenState();
}

class _PassengerActiveRideScreenState extends State<PassengerActiveRideScreen>
    with TickerProviderStateMixin {
  late RideModel _ride;
  StreamSubscription? _rideSubscription;
  StreamSubscription? _locationSubscription;
  late AnimationController _pulseController;
  late AnimationController _carAnimationController;
  double _rideProgress = 0.0;

  // Driver's live location
  double? _driverLat;
  double? _driverLng;
  DateTime? _lastLocationUpdate;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _carAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _listenToRideUpdates();
    _listenToDriverLocation();
  }

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _locationSubscription?.cancel();
    _pulseController.dispose();
    _carAnimationController.dispose();
    super.dispose();
  }

  void _listenToRideUpdates() {
    _rideSubscription = FirebaseFirestore.instance
        .collection('rides')
        .doc(_ride.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _ride = RideModel.fromJson({
            'id': snapshot.id,
            ...snapshot.data()!,
          });
        });

        if (_ride.status == RideStatus.completed) {
          _showCompletionDialog();
        } else if (_ride.status == RideStatus.cancelled) {
          Get.back();
          Get.snackbar(
            'Ride Cancelled',
            'The driver has cancelled this ride',
            backgroundColor: AppColors.error,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        }
      }
    });
  }

  void _listenToDriverLocation() {
    _locationSubscription = FirebaseDatabase.instance
        .ref('ride_locations/${_ride.id}')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _driverLat = data['latitude']?.toDouble();
          _driverLng = data['longitude']?.toDouble();
          _lastLocationUpdate = DateTime.now();

          // Calculate progress based on driver location
          if (_driverLat != null && _driverLng != null) {
            _calculateProgress();
          }
        });
      }
    });
  }

  void _calculateProgress() {
    if (_driverLat == null || _driverLng == null) return;

    final startLat = _ride.startLocation.latitude;
    final startLng = _ride.startLocation.longitude;
    final endLat = _ride.endLocation.latitude;
    final endLng = _ride.endLocation.longitude;

    // Calculate total distance
    final totalDist = _calculateDistance(startLat, startLng, endLat, endLng);

    // Calculate distance from start to driver
    final drivenDist = _calculateDistance(startLat, startLng, _driverLat!, _driverLng!);

    // Calculate progress percentage
    if (totalDist > 0) {
      setState(() {
        _rideProgress = (drivenDist / totalDist).clamp(0.0, 1.0);
      });
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    // Simple distance calculation (for progress estimation)
    final dLat = lat2 - lat1;
    final dLng = lng2 - lng1;
    return (dLat * dLat + dLng * dLng);
  }

  void _showCompletionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success animation
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.tick_circle, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Ride Completed! 🎉',
              style: GoogleFonts.urbanist(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for riding with RouteLink',
              style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Ride summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.grey50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Distance',
                    '${_ride.distance?.toStringAsFixed(1) ?? '0'} km',
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Duration',
                    '${_ride.estimatedDuration ?? 0} min',
                    isDark,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  _buildSummaryRow(
                    'Total Fare',
                    'Rs. ${_ride.acceptedFare ?? _ride.suggestedFare ?? 0}',
                    isDark,
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rate driver section
            Text(
              'Rate your driver',
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
            const SizedBox(height: 12),
            _RatingStars(
              onRatingSelected: (rating) {
                // TODO: Submit rating to Firebase
                debugPrint('Selected rating: $rating');
              },
            ),
            const SizedBox(height: 24),

            // Done button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back(); // Close dialog
                  Get.back(); // Go back to home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.darkBackground,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
        ),
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: isHighlighted ? 20 : 14,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            color: isHighlighted ? AppColors.primaryYellow : (isDark ? Colors.white : AppColors.grey900),
          ),
        ),
      ],
    );
  }

  Future<void> _cancelRide() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Iconsax.danger, color: AppColors.error),
            ),
            const SizedBox(width: 12),
            Text(
              'Cancel Ride',
              style: GoogleFonts.urbanist(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.grey900,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel this ride? You may be charged a cancellation fee.',
          style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'No, Keep Ride',
              style: GoogleFonts.urbanist(fontWeight: FontWeight.w600, color: AppColors.grey500),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _performCancellation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performCancellation() async {
    try {
      // Update ride status
      await FirebaseFirestore.instance.collection('rides').doc(_ride.id).update({
        'status': 'active', // Reset to active so driver can get new passengers
        'passengerId': null,
        'passengerName': null,
        'acceptedFare': null,
      });

      // Remove location tracking
      await FirebaseDatabase.instance.ref('ride_locations/${_ride.id}').remove();

      Get.back();
      Get.snackbar(
        'Ride Cancelled',
        'Your ride has been cancelled',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to cancel ride: $e',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Map with tracking visualization
          _buildMapWithTracking(isDark),

          // Top bar
          _buildTopBar(isDark),

          // Ride info panel
          _buildRideInfoPanel(isDark),
        ],
      ),
    );
  }

  Widget _buildMapWithTracking(bool isDark) {
    final screenSize = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightElevated,
      ),
      child: Stack(
        children: [
          // Grid pattern background
          CustomPaint(
            size: Size.infinite,
            painter: _GridPainter(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),

          // Route visualization
          CustomPaint(
            size: Size.infinite,
            painter: _RoutePainter(
              startPoint: Offset(screenSize.width * 0.15, screenSize.height * 0.22),
              endPoint: Offset(screenSize.width * 0.85, screenSize.height * 0.52),
              progress: _ride.status == RideStatus.inProgress ? _rideProgress : 0.0,
              isDark: isDark,
            ),
          ),

          // Pickup marker
          Positioned(
            left: screenSize.width * 0.15 - 22,
            top: screenSize.height * 0.22 - 50,
            child: _buildLocationMarker(
              color: AppColors.success,
              icon: Iconsax.location,
              label: 'Pickup',
              isDark: isDark,
            ),
          ),

          // Drop-off marker
          Positioned(
            left: screenSize.width * 0.85 - 22,
            top: screenSize.height * 0.52 - 50,
            child: _buildLocationMarker(
              color: AppColors.error,
              icon: Iconsax.location_tick,
              label: 'Drop-off',
              isDark: isDark,
            ),
          ),

          // Driver's car (animated along route)
          if (_ride.status == RideStatus.inProgress || _ride.status == RideStatus.accepted)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              left: screenSize.width * 0.15 + (screenSize.width * 0.7 * _rideProgress) - 28,
              top: screenSize.height * 0.22 + (screenSize.height * 0.3 * _rideProgress) - 28,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + (_pulseController.value * 0.12),
                    child: child,
                  );
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryYellow.withOpacity(0.5),
                        blurRadius: 24,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(Iconsax.car, color: AppColors.darkBackground, size: 28),
                ),
              ),
            ),

          // Live location indicator
          if (_driverLat != null && _lastLocationUpdate != null)
            Positioned(
              top: screenSize.height * 0.15,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live Tracking',
                      style: GoogleFonts.urbanist(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.online,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms),
            ),

          // ETA card
          if (_ride.status == RideStatus.inProgress)
            Positioned(
              top: screenSize.height * 0.38,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Arriving in',
                      style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${((1 - _rideProgress) * (_ride.estimatedDuration ?? 15)).toInt()} min',
                      style: GoogleFonts.urbanist(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2, end: 0),
            ),

          // Progress indicator
          if (_ride.status == RideStatus.inProgress)
            Positioned(
              top: screenSize.height * 0.15,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        children: [
                          CircularProgressIndicator(
                            value: _rideProgress,
                            strokeWidth: 5,
                            backgroundColor: isDark ? AppColors.darkBorder : AppColors.grey200,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                          ),
                          Center(
                            child: Text(
                              '${(_rideProgress * 100).toInt()}%',
                              style: GoogleFonts.urbanist(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.grey900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2, end: 0),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationMarker({
    required Color color,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.4), blurRadius: 14, spreadRadius: 3),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
          ),
          child: Text(
            label,
            style: GoogleFonts.urbanist(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.grey900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Icon(Iconsax.arrow_left, color: isDark ? Colors.white : AppColors.grey900),
              ),
            ),
            const Spacer(),

            // Status badge
            _buildStatusBadge(isDark),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatusBadge(bool isDark) {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    switch (_ride.status) {
      case RideStatus.accepted:
        bgColor = AppColors.info;
        textColor = Colors.white;
        text = 'Driver on the way';
        icon = Iconsax.car;
        break;
      case RideStatus.inProgress:
        bgColor = AppColors.primaryYellow;
        textColor = AppColors.darkBackground;
        text = 'Ride in Progress';
        icon = Iconsax.routing_2;
        break;
      default:
        bgColor = AppColors.grey500;
        textColor = Colors.white;
        text = 'Unknown';
        icon = Iconsax.info_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: bgColor.withOpacity(0.4), blurRadius: 12)],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildRideInfoPanel(bool isDark) {
    return DraggableScrollableSheet(
      initialChildSize: 0.42,
      minChildSize: 0.25,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey500,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Driver card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildDriverCard(isDark),
                ),
                const SizedBox(height: 16),

                // Route card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildRouteCard(isDark),
                ),
                const SizedBox(height: 16),

                // Stats card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatsCard(isDark),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildActionButtons(isDark),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriverCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                (_ride.driverName ?? 'D').substring(0, 1).toUpperCase(),
                style: GoogleFonts.urbanist(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBackground,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _ride.driverName ?? 'Driver',
                  style: GoogleFonts.urbanist(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Iconsax.star1, size: 14, color: AppColors.primaryYellow),
                    const SizedBox(width: 4),
                    Text(
                      '4.8',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.grey500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '${_ride.carDetails.name} • ${_ride.carDetails.number}',
                        style: GoogleFonts.urbanist(fontSize: 13, color: AppColors.grey500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contact buttons
          Row(
            children: [
              _buildCircleButton(
                icon: Iconsax.message,
                color: AppColors.info,
                onTap: () => Get.to(
                      () => ChatScreen(userName: _ride.driverName ?? 'Driver', isDriver: false),
                  transition: Transition.rightToLeftWithFade,
                ),
              ),
              const SizedBox(width: 10),
              _buildCircleButton(
                icon: Iconsax.call,
                color: AppColors.success,
                onTap: () {
                  Get.snackbar(
                    'Calling...',
                    'Phone feature coming soon',
                    backgroundColor: AppColors.info,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildRouteCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          // Pickup
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup',
                      style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500),
                    ),
                    Text(
                      _ride.startLocation.address,
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Dotted line
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Column(
              children: List.generate(
                3,
                    (i) => Container(
                  width: 2,
                  height: 6,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.grey500,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ),

          // Drop-off
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drop-off',
                      style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500),
                    ),
                    Text(
                      _ride.endLocation.address,
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryYellow.withOpacity(0.15),
            AppColors.primaryYellow.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryYellow.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Iconsax.location,
            value: '${_ride.distance?.toStringAsFixed(1) ?? '0'} km',
            label: 'Distance',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.primaryYellow.withOpacity(0.3),
          ),
          _buildStatItem(
            icon: Iconsax.clock,
            value: '${_ride.estimatedDuration ?? 0} min',
            label: 'Duration',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.primaryYellow.withOpacity(0.3),
          ),
          _buildStatItem(
            icon: Iconsax.money,
            value: 'Rs.${_ride.acceptedFare ?? _ride.suggestedFare ?? 0}',
            label: 'Fare',
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    bool isHighlighted = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isHighlighted ? AppColors.primaryYellow : AppColors.grey500,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isHighlighted ? AppColors.primaryYellow : null,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500),
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    // Only show cancel button if ride hasn't started yet
    if (_ride.status == RideStatus.accepted) {
      return Column(
        children: [
          // Progress info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.car, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Driver is on the way to pick you up',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : AppColors.grey700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _cancelRide,
              icon: const Icon(Iconsax.close_circle, size: 20),
              label: Text(
                'Cancel Ride',
                style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      );
    }

    // Show progress bar if ride is in progress
    if (_ride.status == RideStatus.inProgress) {
      return Column(
        children: [
          // Trip progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trip Progress',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        color: AppColors.grey500,
                      ),
                    ),
                    Text(
                      '${(_rideProgress * 100).toInt()}%',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _rideProgress,
                    backgroundColor: isDark ? AppColors.darkBorder : AppColors.grey200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Emergency button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Get.snackbar(
                  'Emergency',
                  'Emergency services contacted',
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                );
              },
              icon: const Icon(Iconsax.danger, size: 20),
              label: Text(
                'Emergency',
                style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox();
  }
}

// ==========================================
// RATING STARS WIDGET
// ==========================================

class _RatingStars extends StatefulWidget {
  final Function(int) onRatingSelected;

  const _RatingStars({required this.onRatingSelected});

  @override
  State<_RatingStars> createState() => _RatingStarsState();
}

class _RatingStarsState extends State<_RatingStars> {
  int _selectedRating = 5;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedRating = starIndex);
            widget.onRatingSelected(starIndex);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Iconsax.star1,
              size: 36,
              color: starIndex <= _selectedRating ? AppColors.primaryYellow : AppColors.grey400,
            ),
          ),
        );
      }),
    );
  }
}

// ==========================================
// GRID PAINTER
// ==========================================

class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// ROUTE PAINTER
// ==========================================

class _RoutePainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final double progress;
  final bool isDark;

  _RoutePainter({
    required this.startPoint,
    required this.endPoint,
    required this.progress,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background path (full route)
    final bgPaint = Paint()
      ..color = AppColors.grey500.withOpacity(0.3)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);

    // Create curved path
    final controlPoint1 = Offset(
      startPoint.dx + (endPoint.dx - startPoint.dx) * 0.25,
      startPoint.dy + 60,
    );
    final controlPoint2 = Offset(
      startPoint.dx + (endPoint.dx - startPoint.dx) * 0.75,
      endPoint.dy - 60,
    );
    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint.dx,
      endPoint.dy,
    );

    canvas.drawPath(path, bgPaint);

    // Progress path (completed portion)
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = AppColors.primaryYellow
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final pathMetrics = path.computeMetrics().first;
      final progressPath = pathMetrics.extractPath(0, pathMetrics.length * progress);
      canvas.drawPath(progressPath, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}