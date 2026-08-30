import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WasslaBottomNav extends StatelessWidget {
  const WasslaBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100.h,
      child: Stack(
        children: [
          // The main dark blue bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 80.h,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF070938), // AppColors.darkBackgroundAlt
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4.r),
                  topRight: Radius.circular(4.r),
                ),
              ),
              child: Row(
                children: [
                  // Space reserved for the floating Home button
                  SizedBox(width: 100.w),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavItem(
                          iconAsset: 'assets/icons/nav_history.svg',
                          label: 'History',
                        ),
                        _NavItem(
                          iconAsset: 'assets/icons/nav_saved.svg',
                          label: 'Saved',
                        ),
                        _NavItem(
                          iconAsset: 'assets/icons/nav_profile.svg',
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w), // A bit of right padding
                ],
              ),
            ),
          ),
          // The floating Home Button
          Positioned(
            left: 32.w,
            top: 0,
            child: Container(
              width: 58.w,
              height: 58.w,
              decoration: const BoxDecoration(
                color: Color(0xFF070938), // Circle matches navbar color
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/nav_home.svg',
                  width: 24.w,
                  height: 24.w,
                  colorFilter: const ColorFilter.mode(Color(0xFF9747FF), BlendMode.srcIn), // Primary color for active
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String iconAsset;
  final String label;

  const _NavItem({
    required this.iconAsset,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 12.h), // pushes it down slightly to match Figma
        SvgPicture.asset(
          iconAsset,
          width: 24.w,
          height: 24.w,
          colorFilter: const ColorFilter.mode(Color(0xFFFFF8E6), BlendMode.srcIn), // Unselected text color
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFFFFF8E6),
              ),
        ),
      ],
    );
  }
}
