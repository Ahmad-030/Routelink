import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// ============================================
/// SOCIAL BUTTON
/// Google/Apple sign-in button
/// ============================================

class SocialButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onPressed;
  final bool isApple;

  const SocialButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isApple = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              if (isApple)
                Icon(
                  Icons.apple,
                  size: 24,
                  color: isDark ? Colors.white : AppColors.grey900,
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  child: Text(
                    'G',
                    style: GoogleFonts.urbanist(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4285F4), // Google Blue
                    ),
                  ),
                ),

              const SizedBox(width: 10),

              // Label
              Text(
                label,
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}