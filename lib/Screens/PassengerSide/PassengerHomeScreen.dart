import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../Chat/Chat_Screen.dart';
import '../DriverSIde/Driver_card.dart';
import 'OfferFare.dart';
import 'PassengerBottomNav.dart';

/// ============================================
/// PASSENGER HOME SCREEN
/// Main screen for passengers to find rides
/// ============================================

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int _currentIndex = 0;
  bool _showDriverList = true;

  // Mock data for nearby drivers
  final List<Map<String, dynamic>> _nearbyDrivers = [
    {
      'id': '1',
      'name': 'Muhammad Ali',
      'carName': 'Toyota Corolla',
      'carNumber': 'LEA-4521',
      'rating': 4.9,
      'distance': '1.2 km',
      'eta': '4 min',
      'seats': 3,
      'suggestedFare': 300,
      'route': 'Model Town → DHA Phase 5',
    },
    {
      'id': '2',
      'name': 'Hassan Raza',
      'carName': 'Honda Civic',
      'carNumber': 'LHR-8834',
      'rating': 4.7,
      'distance': '2.5 km',
      'eta': '7 min',
      'seats': 2,
      'suggestedFare': 250,
      'route': 'Johar Town → Gulberg III',
    },
    {
      'id': '3',
      'name': 'Bilal Ahmed',
      'carName': 'Suzuki Alto',
      'carNumber': 'LEW-1122',
      'rating': 4.8,
      'distance': '3.1 km',
      'eta': '9 min',
      'seats': 4,
      'suggestedFare': 200,
      'route': 'Faisal Town → Liberty Market',
    },
  ];

  void _showOfferFareSheet(Map<String, dynamic> driver) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OfferFareSheet(
        driver: driver,
        onSubmit: (fare) {
          Navigator.pop(context);
          Get.snackbar(
            'Request Sent!',
            'Your offer of Rs. $fare has been sent to ${driver['name']}',
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

          // Search bar
          _buildSearchBar(isDark),

          // Driver list panel
          if (_showDriverList) _buildDriverPanel(isDark),
        ],
      ),
      bottomNavigationBar: PassengerBottomNav(
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
          // Grid pattern
          CustomPaint(
            size: Size.infinite,
            painter: MapGridPainter(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),

          // Driver markers (mock)
          ..._buildDriverMarkers(isDark),

          // User location marker
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.info.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.user,
                    color: Colors.white,
                    size: 20,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 1500.ms,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDriverMarkers(bool isDark) {
    final positions = [
      const Offset(80, 200),
      const Offset(280, 300),
      const Offset(150, 450),
    ];

    return List.generate(_nearbyDrivers.length, (index) {
      return Positioned(
        left: positions[index].dx,
        top: positions[index].dy,
        child: GestureDetector(
          onTap: () => _showOfferFareSheet(_nearbyDrivers[index]),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryYellow.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Iconsax.car,
              color: AppColors.darkBackground,
              size: 20,
            ),
          ),
        )
            .animate(delay: (index * 200).ms)
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0, 0)),
      );
    });
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

            // Nearby drivers count
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
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.online,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_nearbyDrivers.length} drivers nearby',
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

  Widget _buildSearchBar(bool isDark) {
    return Positioned(
      top: 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        child: Row(
          children: [
            const Icon(
              Iconsax.search_normal,
              color: AppColors.grey500,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Where are you going?',
                  hintStyle: GoogleFonts.urbanist(
                    fontSize: 16,
                    color: AppColors.grey500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Iconsax.microphone,
                color: AppColors.primaryYellow,
              ),
              onPressed: () {},
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 500.ms, delay: 200.ms)
          .slideY(begin: -0.2, end: 0),
    );
  }

  Widget _buildDriverPanel(bool isDark) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.15,
      maxChildSize: 0.75,
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
                      'Available Rides',
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
                        '${_nearbyDrivers.length}',
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBackground,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Iconsax.filter,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Driver list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _nearbyDrivers.length,
                  itemBuilder: (context, index) {
                    final driver = _nearbyDrivers[index];
                    return DriverCard(
                      driver: driver,
                      onTap: () => _showOfferFareSheet(driver),
                      onChat: () {
                        Get.to(
                              () => ChatScreen(
                            userName: driver['name'],
                            isDriver: false,
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
}

/// Grid painter for map placeholder
class MapGridPainter extends CustomPainter {
  final Color color;

  MapGridPainter({required this.color});

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