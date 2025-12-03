import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../Core/Theme/App_theme.dart';
import '../../Models/Ride_model.dart';

/// Callback type for route publishing
typedef OnPublishCallback = void Function(
    LocationPoint startLocation,
    LocationPoint endLocation,
    CarDetails carDetails,
    int seats,
    int? fare,
    );

class RouteSetupSheet extends StatefulWidget {
  final OnPublishCallback onPublish;

  const RouteSetupSheet({super.key, required this.onPublish});

  @override
  State<RouteSetupSheet> createState() => _RouteSetupSheetState();
}

class _RouteSetupSheetState extends State<RouteSetupSheet> {
  final _startController = TextEditingController();
  final _destinationController = TextEditingController();
  final _carNameController = TextEditingController();
  final _carNumberController = TextEditingController();
  final _fareController = TextEditingController();

  int _availableSeats = 3;
  int _currentStep = 0;

  @override
  void dispose() {
    _startController.dispose();
    _destinationController.dispose();
    _carNameController.dispose();
    _carNumberController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  void _handlePublish() {
    if (_startController.text.isEmpty || _destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter start and destination'), backgroundColor: AppColors.error),
      );
      return;
    }

    if (_carNameController.text.isEmpty || _carNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter car details'), backgroundColor: AppColors.error),
      );
      return;
    }

    final startLocation = LocationPoint(
      latitude: 31.5204 + (DateTime.now().millisecond / 10000),
      longitude: 74.3587 + (DateTime.now().millisecond / 10000),
      address: _startController.text,
    );

    final endLocation = LocationPoint(
      latitude: 31.4697 + (DateTime.now().millisecond / 10000),
      longitude: 74.2728 + (DateTime.now().millisecond / 10000),
      address: _destinationController.text,
    );

    final carDetails = CarDetails(
      name: _carNameController.text,
      number: _carNumberController.text,
    );

    final fare = int.tryParse(_fareController.text);

    widget.onPublish(startLocation, endLocation, carDetails, _availableSeats, fare);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.grey500, borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.routing_2, color: AppColors.primaryYellow, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Your Route',
                      style: GoogleFonts.urbanist(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.grey900),
                    ),
                    Text(
                      'Step ${_currentStep + 1} of 2',
                      style: GoogleFonts.urbanist(fontSize: 14, color: AppColors.grey500),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Iconsax.close_circle, color: AppColors.grey500),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: _currentStep >= 1 ? AppColors.primaryYellow : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: _currentStep == 0 ? _buildRouteStep(isDark) : _buildCarDetailsStep(isDark),
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: isDark ? AppColors.grey600 : AppColors.grey400),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Back',
                        style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.grey900),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < 1) {
                        if (_startController.text.isEmpty || _destinationController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in all fields'), backgroundColor: AppColors.error),
                          );
                          return;
                        }
                        setState(() => _currentStep++);
                      } else {
                        _handlePublish();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: AppColors.darkBackground,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentStep < 1 ? 'Continue' : 'Publish Route',
                      style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w700),
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

  Widget _buildRouteStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where are you going?',
          style: GoogleFonts.urbanist(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.grey900),
        ),
        const SizedBox(height: 20),

        // Start location
        _buildLocationField(
          controller: _startController,
          hint: 'Pickup Location',
          icon: Iconsax.location,
          iconColor: AppColors.success,
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Route line
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            children: List.generate(3, (i) => Container(
              width: 2,
              height: 8,
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            )),
          ),
        ),
        const SizedBox(height: 16),

        // End location
        _buildLocationField(
          controller: _destinationController,
          hint: 'Drop-off Location',
          icon: Iconsax.location_tick,
          iconColor: AppColors.error,
          isDark: isDark,
        ),

        const SizedBox(height: 30),

        // Quick suggestions
        Text(
          'Popular Routes',
          style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.grey900),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSuggestionChip('Lahore → Islamabad', isDark),
            _buildSuggestionChip('DHA → Gulberg', isDark),
            _buildSuggestionChip('Model Town → Airport', isDark),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildCarDetailsStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Details',
          style: GoogleFonts.urbanist(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.grey900),
        ),
        const SizedBox(height: 20),

        // Car name
        _buildTextField(
          controller: _carNameController,
          hint: 'Car Model (e.g., Honda Civic)',
          icon: Iconsax.car,
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Car number
        _buildTextField(
          controller: _carNumberController,
          hint: 'License Plate (e.g., ABC-1234)',
          icon: Iconsax.card,
          isDark: isDark,
        ),
        const SizedBox(height: 24),

        // Available seats
        Text(
          'Available Seats',
          style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.grey900),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(4, (i) {
            final seats = i + 1;
            final isSelected = _availableSeats == seats;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _availableSeats = seats),
                child: Container(
                  margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryYellow : (isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryYellow : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Iconsax.user,
                        color: isSelected ? AppColors.darkBackground : AppColors.grey500,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$seats',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.darkBackground : (isDark ? Colors.white : AppColors.grey900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 24),

        // Suggested fare
        Text(
          'Suggested Fare (Optional)',
          style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.grey900),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _fareController,
          hint: 'Enter amount in PKR',
          icon: Iconsax.money,
          isDark: isDark,
          keyboardType: TextInputType.number,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.urbanist(fontSize: 16, color: isDark ? Colors.white : AppColors.grey900),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Iconsax.gps, color: AppColors.grey500, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: AppColors.primaryYellow, size: 22),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: GoogleFonts.urbanist(fontSize: 16, color: isDark ? Colors.white : AppColors.grey900),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.urbanist(fontSize: 16, color: AppColors.grey500),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () {
        final parts = text.split(' → ');
        if (parts.length == 2) {
          _startController.text = parts[0];
          _destinationController.text = parts[1];
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Text(
          text,
          style: GoogleFonts.urbanist(fontSize: 14, color: isDark ? Colors.white70 : AppColors.grey700),
        ),
      ),
    );
  }
}