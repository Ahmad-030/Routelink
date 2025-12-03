import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';
import '../../Widgets/Custom_Textfield.dart';


/// ============================================
/// ROUTE SETUP SHEET
/// Bottom sheet for setting up driver route
/// ============================================

class RouteSetupSheet extends StatefulWidget {
  final VoidCallback onPublish;

  const RouteSetupSheet({
    super.key,
    required this.onPublish,
  });

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
            decoration: BoxDecoration(
              color: AppColors.grey500,
              borderRadius: BorderRadius.circular(2),
            ),
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
                  child: const Icon(
                    Iconsax.routing_2,
                    color: AppColors.primaryYellow,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Your Route',
                      style: GoogleFonts.urbanist(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.grey900,
                      ),
                    ),
                    Text(
                      'Step ${_currentStep + 1} of 2',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms),

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
                      color: _currentStep >= 1
                          ? AppColors.primaryYellow
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
              child: _currentStep == 0
                  ? _buildRouteStep(isDark)
                  : _buildCarDetailsStep(isDark),
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
                      onPressed: () {
                        setState(() => _currentStep--);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: isDark ? AppColors.grey600 : AppColors.grey400,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Back',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentStep < 1) {
                        setState(() => _currentStep++);
                      } else {
                        widget.onPublish();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: AppColors.darkBackground,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentStep < 1 ? 'Next' : 'Publish Route',
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentStep < 1 ? Iconsax.arrow_right : Iconsax.send_1,
                          size: 20,
                        ),
                      ],
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
        // Start location
        _buildLocationField(
          controller: _startController,
          label: 'Start Location',
          hint: 'Enter pickup point',
          icon: Iconsax.location,
          iconColor: AppColors.success,
          isDark: isDark,
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 100.ms)
            .slideY(begin: 0.1, end: 0),

        // Route line
        Padding(
          padding: const EdgeInsets.only(left: 35),
          child: Container(
            width: 2,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.success,
                  AppColors.primaryYellow,
                ],
              ),
            ),
          ),
        ),

        // Destination
        _buildLocationField(
          controller: _destinationController,
          label: 'Destination',
          hint: 'Enter drop-off point',
          icon: Iconsax.location_tick,
          iconColor: AppColors.primaryYellow,
          isDark: isDark,
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideY(begin: 0.1, end: 0),

        const SizedBox(height: 24),

        // Add via point button
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Add via point functionality
          },
          icon: const Icon(Iconsax.add, size: 20),
          label: Text(
            'Add Via Point (Optional)',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryYellow,
            side: const BorderSide(color: AppColors.primaryYellow),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 300.ms),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.only(top: 28),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomTextField(
            controller: controller,
            label: label,
            hint: hint,
          ),
        ),
      ],
    );
  }

  Widget _buildCarDetailsStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Car name
        CustomTextField(
          controller: _carNameController,
          label: 'Car Name',
          hint: 'e.g., Toyota Corolla',
          prefixIcon: Iconsax.car,
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 100.ms)
            .slideY(begin: 0.1, end: 0),

        const SizedBox(height: 20),

        // Car number
        CustomTextField(
          controller: _carNumberController,
          label: 'Car Number',
          hint: 'e.g., ABC-1234',
          prefixIcon: Iconsax.card,
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms)
            .slideY(begin: 0.1, end: 0),

        const SizedBox(height: 24),

        // Available seats
        Text(
          'Available Seats',
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 300.ms),

        const SizedBox(height: 12),

        Row(
          children: List.generate(4, (index) {
            final seats = index + 1;
            final isSelected = _availableSeats == seats;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _availableSeats = seats);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: index < 3 ? 12 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryYellow
                        : (isDark ? AppColors.darkCard : AppColors.lightElevated),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryYellow
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Iconsax.user,
                        color: isSelected
                            ? AppColors.darkBackground
                            : AppColors.grey500,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$seats',
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.darkBackground
                              : (isDark ? Colors.white : AppColors.grey900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 400.ms),

        const SizedBox(height: 24),

        // Suggested fare
        CustomTextField(
          controller: _fareController,
          label: 'Suggested Fare (Optional)',
          hint: 'Enter amount in PKR',
          prefixIcon: Iconsax.money,
          keyboardType: TextInputType.number,
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 500.ms)
            .slideY(begin: 0.1, end: 0),

        const SizedBox(height: 30),
      ],
    );
  }
}