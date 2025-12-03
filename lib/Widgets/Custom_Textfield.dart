import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

/// ============================================
/// CUSTOM TEXT FIELD
/// Reusable styled input field
/// ============================================

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
        ),
        const SizedBox(height: 8),

        // Text Field
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          enabled: enabled,
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : AppColors.grey900,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.urbanist(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.grey500,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
              prefixIcon,
              color: AppColors.grey500,
              size: 22,
            )
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? AppColors.darkCard : AppColors.lightElevated,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkBorder.withOpacity(0.5)
                    : AppColors.lightBorder.withOpacity(0.5),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primaryYellow,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            errorStyle: GoogleFonts.urbanist(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}