import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/design_system/typography_system.dart';
import '../core/theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;
  final VoidCallback? onTap;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final TextDirection? textDirection;
  final TextStyle? style;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.onTap,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.textDirection,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        enabled: enabled,
        onTap: onTap,
        textAlign: textAlign,
        textDirection: textDirection,
        inputFormatters: inputFormatters,
        style: (style ?? TypographySystem.bodyLarge).copyWith(
          color: enabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          hintStyle: TypographySystem.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant.withOpacity(0.6),
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color:
                      enabled ? AppColors.primary : AppColors.onSurfaceVariant,
                  size: GoldenRatio.md,
                )
              : null,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.onSurfaceVariant.withOpacity(0.3),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.onSurfaceVariant.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(GoldenRatio.spacing12),
            borderSide: BorderSide(
              color: AppColors.onSurfaceVariant.withOpacity(0.2),
              width: 1,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: GoldenRatio.spacing16,
            vertical: GoldenRatio.spacing16,
          ),
          fillColor: enabled ? Colors.white : AppColors.surface,
          filled: true,
        ),
      ),
    );
  }
}
