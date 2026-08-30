import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:wassla/core/theme/app_colors.dart';
import 'package:wassla/core/theme/app_radius.dart';

class WasslaButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isSecondary;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const WasslaButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isSecondary = false,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = backgroundColor ?? (isSecondary
        ? Colors.transparent
        : (isDark ? AppColors.darkBackgroundAlt : AppColors.primary));
    final fgColor = foregroundColor ?? (isSecondary
        ? (isDark ? AppColors.darkTextPrimary : AppColors.primary)
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightSurface));
    final borderSide = isSecondary
        ? BorderSide(color: fgColor, width: 1.w)
        : BorderSide.none;

    final child = isLoading
        ? SizedBox(
            width: 24.w,
            height: 24.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                SizedBox(width: 8.w),
              ],
              Text(
                text,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 327.w),
        child: SizedBox(
          width: double.infinity, // stretch up to max 327.w
          height: 44.h, // Exact Figma height
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.roundedMedium, // 8px radius from theme
                side: borderSide,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
            onPressed: isLoading ? null : onPressed,
            child: child,
          ),
        ),
      ),
    );
  }
}
