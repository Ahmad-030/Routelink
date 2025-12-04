import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:geolocator/geolocator.dart';
import 'package:routelink/Core/Theme/App_theme.dart';
import '../../Models/Ride_model.dart';

/// ============================================
/// OFFER FARE SHEET
/// Bottom sheet for passengers to offer fare
/// ============================================

class OfferFareSheet extends StatefulWidget {
  final RideModel ride;
  final Position? currentPosition;
  final Function(int fare, String pickupAddress, String dropoffAddress) onSubmit;

  const OfferFareSheet({
    super.key,
    required this.ride,
    this.currentPosition,
    required this.onSubmit,
  });

  @override
  State<OfferFareSheet> createState() => _OfferFareSheetState();
}

class _OfferFareSheetState extends State<OfferFareSheet> {
  late int _offeredFare;
  final _fareController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  bool _useDriverRoute = true;

  @override
  void initState() {
    super.initState();
    _offeredFare = widget.ride.suggestedFare ?? 200;
    _fareController.text = _offeredFare.toString();
    _pickupController.text = widget.ride.startLocation.address;
    _dropoffController.text = widget.ride.endLocation.address;
  }

  @override
  void dispose() {
    _fareController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  void _adjustFare(int amount) {
    setState(() {
      _offeredFare = (_offeredFare + amount).clamp(50, 10000);
      _fareController.text = _offeredFare.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            // Header - Driver Info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Driver avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        (widget.ride.driverName ?? 'D').substring(0, 1).toUpperCase(),
                        style: GoogleFonts.urbanist(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkBackground,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Driver info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ride.driverName ?? 'Driver',
                          style: GoogleFonts.urbanist(
                            fontSize: 20,
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
                              style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '${widget.ride.carDetails.name} • ${widget.ride.carDetails.number}',
                                style: GoogleFonts.urbanist(fontSize: 13, color: AppColors.grey500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Iconsax.close_circle, color: AppColors.grey500),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),

            // Route info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.grey50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Toggle for using driver route
                    Row(
                      children: [
                        Text(
                          'Use driver\'s route',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.grey900,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _useDriverRoute,
                          onChanged: (val) {
                            setState(() {
                              _useDriverRoute = val;
                              if (val) {
                                _pickupController.text = widget.ride.startLocation.address;
                                _dropoffController.text = widget.ride.endLocation.address;
                              }
                            });
                          },
                          activeColor: AppColors.primaryYellow,
                        ),
                      ],
                    ),

                    const Divider(height: 20),

                    // Pickup location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(width: 2, height: 30, color: AppColors.grey400),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup',
                                style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500),
                              ),
                              const SizedBox(height: 4),
                              _useDriverRoute
                                  ? Text(
                                widget.ride.startLocation.address,
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.grey900,
                                ),
                              )
                                  : TextField(
                                controller: _pickupController,
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.grey900,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter pickup location',
                                  hintStyle: GoogleFonts.urbanist(
                                    fontSize: 14,
                                    color: AppColors.grey500,
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Drop-off location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Drop-off',
                                style: GoogleFonts.urbanist(fontSize: 12, color: AppColors.grey500),
                              ),
                              const SizedBox(height: 4),
                              _useDriverRoute
                                  ? Text(
                                widget.ride.endLocation.address,
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.grey900,
                                ),
                              )
                                  : TextField(
                                controller: _dropoffController,
                                style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.grey900,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter drop-off location',
                                  hintStyle: GoogleFonts.urbanist(
                                    fontSize: 14,
                                    color: AppColors.grey500,
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

            const SizedBox(height: 20),

            // Ride stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildStatChip(
                    icon: Iconsax.location,
                    value: '${widget.ride.distance?.toStringAsFixed(1) ?? '0'} km',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildStatChip(
                    icon: Iconsax.clock,
                    value: '${widget.ride.estimatedDuration ?? 15} min',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _buildStatChip(
                    icon: Iconsax.user,
                    value: '${widget.ride.availableSeats} seats',
                    isDark: isDark,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

            const SizedBox(height: 24),

            // Offer Fare Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Your Offer',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Suggested: Rs. ${widget.ride.suggestedFare ?? 200}',
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 16),

            // Fare input with +/- buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Decrease button
                  GestureDetector(
                    onTap: () => _adjustFare(-50),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.grey100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: const Icon(Iconsax.minus, color: AppColors.grey500),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Fare display
                  Expanded(
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryYellow, width: 2),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Rs. ',
                              style: GoogleFonts.urbanist(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryYellow,
                              ),
                            ),
                            Text(
                              '$_offeredFare',
                              style: GoogleFonts.urbanist(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.grey900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Increase button
                  GestureDetector(
                    onTap: () => _adjustFare(50),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Iconsax.add, color: AppColors.darkBackground),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            // Quick amount buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildQuickAmount(100, isDark),
                  const SizedBox(width: 8),
                  _buildQuickAmount(150, isDark),
                  const SizedBox(width: 8),
                  _buildQuickAmount(200, isDark),
                  const SizedBox(width: 8),
                  _buildQuickAmount(300, isDark),
                  const SizedBox(width: 8),
                  _buildQuickAmount(500, isDark),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

            const SizedBox(height: 24),

            // Submit button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    if (_pickupController.text.isEmpty || _dropoffController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter pickup and drop-off locations'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    widget.onSubmit(
                      _offeredFare,
                      _pickupController.text,
                      _dropoffController.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    foregroundColor: AppColors.darkBackground,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.send_1, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Send Request',
                        style: GoogleFonts.urbanist(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.grey50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.grey500),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                style: GoogleFonts.urbanist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmount(int amount, bool isDark) {
    final isSelected = _offeredFare == amount;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _offeredFare = amount;
            _fareController.text = amount.toString();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryYellow
                : (isDark ? AppColors.darkCard : AppColors.grey100),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryYellow
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Center(
            child: Text(
              '$amount',
              style: GoogleFonts.urbanist(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.darkBackground
                    : (isDark ? Colors.white : AppColors.grey900),
              ),
            ),
          ),
        ),
      ),
    );
  }
}