import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:routelink/Screens/DriverSIde/DriverCHatSCreen.dart';
import 'package:routelink/Screens/DriverSIde/DriverRIdeHistory.dart';
import 'package:routelink/Screens/DriverSIde/DriverROuteScreen.dart';
import 'package:routelink/Screens/DriverSIde/DriverSetting_Screen.dart';
import '../../Core/Theme/App_theme.dart';
import '../../Models/Ride_model.dart';
import '../../Models/Ride_request_model.dart';
import '../../Services/Firebase Auth.dart';
import '../Chat/Chat_Screen.dart';
import 'Driver_BottomNav.dart';
import 'dart:async';

import 'RideRequest.dart';
import 'RouteSetup.dart';
import 'ActiveRideScreen.dart';


class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DriverHomeContent(),
          DriverRoutesScreen(),
          DriverChatsScreen(),
          DriverRideHistoryScreen(),
          DriverSettingsScreen(),
        ],
      ),
      bottomNavigationBar: DriverBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

class _DriverHomeContent extends StatefulWidget {
  const _DriverHomeContent();

  @override
  State<_DriverHomeContent> createState() => _DriverHomeContentState();
}

class _DriverHomeContentState extends State<_DriverHomeContent> {
  RideModel? _activeRide;
  bool _isLoading = true;
  String _currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkActiveRide();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5)); // PKT is UTC+5
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  void _checkActiveRide() async {
    final userId = AuthService.to.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    FirebaseFirestore.instance
        .collection('rides')
        .where('driverId', isEqualTo: userId)
        .where('status', whereIn: ['active', 'accepted', 'inProgress'])
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _activeRide = RideModel.fromJson({
            'id': snapshot.docs.first.id,
            ...snapshot.docs.first.data(),
          });
          _isLoading = false;
        });
      } else {
        setState(() {
          _activeRide = null;
          _isLoading = false;
        });
      }
    });
  }

  void _showRouteSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteSetupSheet(
        onPublish: (startLocation, endLocation, carDetails, seats, fare) {
          Navigator.pop(context);
          _publishRoute(startLocation, endLocation, carDetails, seats, fare);
        },
      ),
    );
  }

  Future<void> _publishRoute(
      LocationPoint startLocation,
      LocationPoint endLocation,
      CarDetails carDetails,
      int seats,
      int? fare,
      ) async {
    final userId = AuthService.to.currentUser?.uid;
    final userName = AuthService.to.currentUser?.name;

    if (userId == null) return;

    try {
      final rideData = {
        'driverId': userId,
        'driverName': userName,
        'startLocation': startLocation.toJson(),
        'endLocation': endLocation.toJson(),
        'viaPoints': [],
        'carDetails': carDetails.toJson(),
        'availableSeats': seats,
        'suggestedFare': fare,
        'status': 'active',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance.collection('rides').add(rideData);

      Get.snackbar(
        'Route Published!',
        'Your route is now visible to passengers',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to publish route: $e',
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
          _buildMapPlaceholder(isDark),
          _buildTopBar(isDark),
          if (_activeRide != null) _buildStatusCard(isDark),
          if (_activeRide != null && _activeRide!.status == RideStatus.active)
            _buildRequestsPanel(isDark),
          if (_activeRide != null &&
              (_activeRide!.status == RideStatus.inProgress ||
                  _activeRide!.status == RideStatus.accepted))
            _buildActiveRideBanner(isDark),
          if (_activeRide == null && !_isLoading) _buildSetRouteFAB(isDark),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder(bool isDark) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightElevated,
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.location, color: AppColors.darkBackground, size: 24),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 1500.ms,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                  ),
                  child: Text(
                    'Your Location',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    final user = AuthService.to.currentUser;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.clock,
                    color: AppColors.primaryYellow,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentTime,
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _activeRide != null ? AppColors.online : AppColors.grey500,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _activeRide != null ? 'Online' : 'Offline',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2, end: 0),
            const SizedBox(width: 12),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primaryYellow.withOpacity(0.3), blurRadius: 10)],
              ),
              child: Center(
                child: Text(
                  user?.name.substring(0, 1).toUpperCase() ?? 'D',
                  style: GoogleFonts.urbanist(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBackground,
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideX(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    return Positioned(
      top: 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Iconsax.routing, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route Active',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                  Text(
                    '${_activeRide!.startLocation.address.split(',').first} → ${_activeRide!.endLocation.address.split(',').first}',
                    style: GoogleFonts.urbanist(fontSize: 13, color: AppColors.grey500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _endRoute(),
              child: Text(
                'End',
                style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.error),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
    );
  }

  Widget _buildActiveRideBanner(bool isDark) {
    return Positioned(
      top: 120,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () => Get.to(() => ActiveRideScreen(ride: _activeRide!)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primaryYellow, AppColors.goldenYellow]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primaryYellow.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.darkBackground.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Iconsax.car, color: AppColors.darkBackground, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _activeRide!.status == RideStatus.inProgress ? 'Ride in Progress' : 'Ride Accepted',
                      style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkBackground),
                    ),
                    Text(
                      'Passenger: ${_activeRide!.passengerName ?? 'Unknown'}',
                      style: GoogleFonts.urbanist(fontSize: 13, color: AppColors.darkBackground.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              const Icon(Iconsax.arrow_right_3, color: AppColors.darkBackground),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
    );
  }

  Widget _buildRequestsPanel(bool isDark) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.grey500, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Ride Requests',
                      style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.grey900),
                    ),
                    const SizedBox(width: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('ride_requests')
                          .where('rideId', isEqualTo: _activeRide?.id)
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primaryYellow, borderRadius: BorderRadius.circular(10)),
                          child: Text('$count', style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkBackground)),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ride_requests')
                      .where('rideId', isEqualTo: _activeRide?.id)
                      .where('status', isEqualTo: 'pending')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow)));
                    }
                    final requests = snapshot.data?.docs ?? [];
                    if (requests.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.user_search, size: 48, color: AppColors.grey500),
                            const SizedBox(height: 16),
                            Text('No requests yet', style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500)),
                            Text('Waiting for passengers...', style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final requestData = requests[index].data() as Map<String, dynamic>;
                        final request = RideRequestModel.fromJson({'id': requests[index].id, ...requestData});
                        return RideRequestCard(
                          request: {
                            'id': request.id,
                            'name': request.passengerName,
                            'pickup': request.pickupAddress,
                            'dropoff': request.dropoffAddress,
                            'offeredFare': request.offeredFare,
                            'distance': '${request.distance?.toStringAsFixed(1) ?? '0'} km',
                            'rating': request.passengerRating,
                          },
                          onAccept: () => _acceptRequest(request),
                          onReject: () => _rejectRequest(request.id),
                          onChat: () => Get.to(() => ChatScreen(userName: request.passengerName, isDriver: true)),
                        ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetRouteFAB(bool isDark) {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: ElevatedButton(
        onPressed: _showRouteSetup,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.darkBackground,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: AppColors.primaryYellow.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.routing_2, size: 24),
            const SizedBox(width: 12),
            Text('Set Your Route', style: GoogleFonts.urbanist(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),
    );
  }

  void _acceptRequest(RideRequestModel request) async {
    try {
      await FirebaseFirestore.instance.collection('ride_requests').doc(request.id).update({
        'status': 'accepted',
        'respondedAt': DateTime.now().toIso8601String(),
      });
      await FirebaseFirestore.instance.collection('rides').doc(_activeRide!.id).update({
        'status': 'accepted',
        'passengerId': request.passengerId,
        'passengerName': request.passengerName,
        'acceptedFare': request.offeredFare,
      });
      final otherRequests = await FirebaseFirestore.instance
          .collection('ride_requests')
          .where('rideId', isEqualTo: _activeRide!.id)
          .where('status', isEqualTo: 'pending')
          .get();
      for (var doc in otherRequests.docs) {
        await doc.reference.update({'status': 'rejected', 'respondedAt': DateTime.now().toIso8601String()});
      }
      Get.snackbar('Request Accepted!', 'You accepted ${request.passengerName}\'s request',
          backgroundColor: AppColors.success, colorText: Colors.white, snackPosition: SnackPosition.TOP);
    } catch (e) {
      Get.snackbar('Error', 'Failed to accept request: $e', backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  void _rejectRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('ride_requests').doc(requestId).update({
        'status': 'rejected',
        'respondedAt': DateTime.now().toIso8601String(),
      });
      Get.snackbar('Request Rejected', 'The request has been rejected', backgroundColor: AppColors.grey700, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject request: $e', backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  void _endRoute() async {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('End Route', style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to end this route?', style: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600, color: AppColors.grey500)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                await FirebaseFirestore.instance.collection('rides').doc(_activeRide!.id).update({'status': 'cancelled'});
                final requests = await FirebaseFirestore.instance
                    .collection('ride_requests')
                    .where('rideId', isEqualTo: _activeRide!.id)
                    .where('status', isEqualTo: 'pending')
                    .get();
                for (var doc in requests.docs) {
                  await doc.reference.update({'status': 'cancelled'});
                }
                Get.snackbar('Route Ended', 'Your route has been cancelled', backgroundColor: AppColors.grey700, colorText: Colors.white);
              } catch (e) {
                Get.snackbar('Error', 'Failed to end route: $e', backgroundColor: AppColors.error, colorText: Colors.white);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('End Route', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

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