import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../Chat/Chat_Screen.dart';
import 'Driver_BottomNav.dart';
import 'RideRequest.dart';
import 'RouteSetup.dart';

/// ============================================
/// DRIVER HOME SCREEN
/// Main screen for drivers with map and requests
/// ============================================

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;
  bool _isRouteActive = false;
  bool _showRequests = false;

  // Mock data for ride requests
  final List<Map<String, dynamic>> _rideRequests = [
    {
      'id': '1',
      'name': 'Ahmed Khan',
      'pickup': 'Model Town, Lahore',
      'dropoff': 'DHA Phase 5',
      'offeredFare': 350,
      'distance': '8.5 km',
      'rating': 4.8,
      'image': null,
    },
    {
      'id': '2',
      'name': 'Sara Ali',
      'pickup': 'Johar Town',
      'dropoff': 'Gulberg III',
      'offeredFare': 280,
      'distance': '5.2 km',
      'rating': 4.9,
      'image': null,
    },
    {
      'id': '3',
      'name': 'Usman Malik',
      'pickup': 'Faisal Town',
      'dropoff': 'Liberty Market',
      'offeredFare': 200,
      'distance': '3.8 km',
      'rating': 4.7,
      'image': null,
    },
  ];

  void _showRouteSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RouteSetupSheet(
        onPublish: () {
          setState(() {
            _isRouteActive = true;
            _showRequests = true;
          });
          Navigator.pop(context);
          Get.snackbar(
            'Route Published!',
            'Your route is now visible to passengers',
            backgroundColor: AppColors.success,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Map placeholder
          _buildMapPlaceholder(isDark),

          // Top bar
          _buildTopBar(isDark),

          // Status card
          if (_isRouteActive) _buildStatusCard(isDark),

          // Ride requests panel
          if (_showRequests) _buildRequestsPanel(isDark),

          // Set route FAB
          if (!_isRouteActive) _buildSetRouteFAB(isDark),
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

  Widget _buildMapPlaceholder(bool isDark) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightElevated,
      ),
      child: Stack(
        children: [
          // Grid pattern for map effect
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),

          // Center marker
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
                    child: const Icon(
                      Iconsax.location,
                      color: AppColors.darkBackground,
                      size: 24,
                    ),
                  ),
                )
                    .animate(
                  onPlay: (c) => c.repeat(reverse: true),
                )
                    .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 1500.ms,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Menu button
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Iconsax.menu_1,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
                onPressed: () {},
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideX(begin: -0.2, end: 0),

            const Spacer(),

            // Online status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isRouteActive ? AppColors.online : AppColors.grey500,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isRouteActive ? 'Online' : 'Offline',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.grey900,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideX(begin: 0.2, end: 0),

            const SizedBox(width: 12),

            // Profile
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryYellow.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Iconsax.user,
                color: AppColors.darkBackground,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 100.ms)
                .slideX(begin: 0.2, end: 0),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.routing,
                    color: AppColors.success,
                    size: 20,
                  ),
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
                        'Model Town → DHA Phase 5',
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRouteActive = false;
                      _showRequests = false;
                    });
                  },
                  child: Text(
                    'End',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 500.ms)
          .slideY(begin: -0.2, end: 0),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
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

              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Ride Requests',
                      style: GoogleFonts.urbanist(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_rideRequests.length}',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBackground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Request list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _rideRequests.length,
                  itemBuilder: (context, index) {
                    final request = _rideRequests[index];
                    return RideRequestCard(
                      request: request,
                      onAccept: () {
                        Get.snackbar(
                          'Ride Accepted!',
                          'You accepted ${request['name']}\'s request',
                          backgroundColor: AppColors.success,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.TOP,
                        );
                      },
                      onReject: () {
                        setState(() {
                          _rideRequests.removeAt(index);
                        });
                      },
                      onChat: () {
                        Get.to(
                              () => ChatScreen(
                            userName: request['name'],
                            isDriver: true,
                          ),
                          transition: Transition.rightToLeftWithFade,
                        );
                      },
                    )
                        .animate()
                        .fadeIn(
                      duration: 400.ms,
                      delay: (index * 100).ms,
                    )
                        .slideX(begin: 0.1, end: 0);
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: AppColors.primaryYellow.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.routing_2, size: 24),
            const SizedBox(width: 12),
            Text(
              'Set Your Route',
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 600.ms, delay: 300.ms)
          .slideY(begin: 0.3, end: 0),
    );
  }
}

/// Grid painter for map effect
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