import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_theme.dart';

/// ============================================
/// OFFER FARE SHEET
/// Bottom sheet for passengers to offer fare
/// ============================================

class OfferFareSheet extends StatefulWidget {
  final Map<String, dynamic> driver;
  final Function(int) onSubmit;

  const OfferFareSheet({
    super.key,
    required this.driver,
    required this.onSubmit,
  });

  @override
  State<OfferFareSheet> createState() => _OfferFareSheetState();
}

class _OfferFareSheetState extends State<OfferFareSheet> {
  late int _offeredFare;
  final _fareController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _offeredFare = widget.driver['suggestedFare'] as int;
    _fareController.text = _offeredFare.toString();
  }

  @override
  void dispose() {
    _fareController.dispose();
    super.dispose();
  }

  void _adjustFare(int amount) {
    setState(() {
      _offeredFare = (_offeredFare + amount).clamp(50, 5000);
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

          // Header
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
                      widget.driver['name'].toString().substring(0, 1).toUpperCase(),
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
                        widget.driver['name'],
                        style: GoogleFonts.urbanist(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.grey900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.star1,
                            size: 14,
                            color: AppColors.primaryYellow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.driver['rating']}',
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              color: AppColors.grey500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.driver['carName'],
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              color: AppColors.grey500,
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
                  icon: Icon(
                    Iconsax.close_circle,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms),

          // Route info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard
                    : AppColors.grey50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
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
                      Container(
                        width: 2,
                        height: 30,
                        color: AppColors.grey400,
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryYellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.driver['route'].toString().split('→')[0].trim(),
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.grey900,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.driver['route'].toString().split('→')[1].trim(),
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.grey900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Iconsax.location,
                            size: 14,
                            color: AppColors.grey500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.driver['distance'],
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.clock,
                            size: 14,
                            color: AppColors.grey500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.driver['eta'],
                            style: GoogleFonts.urbanist(
                              fontSize: 13,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 24),

          // Offer Fare Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Offer',
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Suggested fare: Rs. ${widget.driver['suggestedFare']}',
                  style: GoogleFonts.urbanist(
                    fontSize: 13,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms),

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
                    child: const Icon(
                      Iconsax.minus,
                      color: AppColors.grey500,
                    ),
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
                      border: Border.all(
                        color: AppColors.primaryYellow,
                        width: 2,
                      ),
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
                    child: const Icon(
                      Iconsax.add,
                      color: AppColors.darkBackground,
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 24),

          // Quick amount buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildQuickAmount(150, isDark),
                const SizedBox(width: 10),
                _buildQuickAmount(200, isDark),
                const SizedBox(width: 10),
                _buildQuickAmount(300, isDark),
                const SizedBox(width: 10),
                _buildQuickAmount(500, isDark),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms),

          const SizedBox(height: 24),

          // Submit button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => widget.onSubmit(_offeredFare),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.darkBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.send_1, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Send Offer',
                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 500.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 10),
        ],
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryYellow
                : (isDark ? AppColors.darkCard : AppColors.grey100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryYellow
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
          child: Center(
            child: Text(
              'Rs.$amount',
              style: GoogleFonts.urbanist(
                fontSize: 13,
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