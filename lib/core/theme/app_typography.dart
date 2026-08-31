import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get smallDetail => TextStyle(
        fontFamily: 'Inter',
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        height: 12 / 10,
      );

  static TextTheme getTextTheme(Brightness brightness) {
    // Start with the default text theme for the given brightness.
    // Apply the 'Inter' fontFamily to all text styles.
    return ThemeData(brightness: brightness)
        .textTheme
        .apply(fontFamily: 'Inter')
        .copyWith(
          displayLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32.sp,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            height: 24 / 20,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            height: 19 / 16,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            height: 19 / 16,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            height: 17 / 14,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            height: 15 / 12,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            height: 15 / 12,
          ),
          labelSmall: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 8,
            fontWeight: FontWeight.w500,
            height: 10 / 8,
          ),
        );
  }
}
