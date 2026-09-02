import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/app_colors.dart';

class WasslaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const WasslaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<String> _icons = [
    'assets/icons/nav_home.svg',
    'assets/icons/nav_history.svg',
    'assets/icons/nav_saved.svg',
    'assets/icons/nav_profile.svg',
  ];

  static const List<String> _labels = [
    'Home',
    'History',
    'Saved',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final double itemWidth = MediaQuery.of(context).size.width / 4;
    final double circleSize = 58.w;
    final double barHeight = 80.h;
    final double stackHeight = 100.h;
    final double barTop = stackHeight - barHeight; // 20.h
    final double circleTop = 6.h;
    final double circleCenterYRelativeToStack = circleTop + (circleSize / 2);
    final double circleCenterYRelativeToBar = circleCenterYRelativeToStack - barTop;

    return SizedBox(
      height: stackHeight,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: currentIndex.toDouble()),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final double notchCenterX = (value + 0.5) * itemWidth;

          return Stack(
            children: [
              // Background with animated notch
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: barHeight,
                child: ClipPath(
                  clipper: _NotchClipper(
                    notchCenterX: notchCenterX,
                    notchCenterY: circleCenterYRelativeToBar,
                    circleSize: circleSize,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkBackgroundAlt,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4.r),
                        topRight: Radius.circular(4.r),
                      ),
                    ),
                  ),
                ),
              ),

              // Unselected Items (Icons & Text)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: barHeight,
                child: Row(
                  children: List.generate(4, (index) {
                    final isSelected = index == currentIndex;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(index),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isSelected ? 0.0 : 1.0,
                          child: _NavItem(
                            iconAsset: _icons[index],
                            label: _labels[index],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Animated Yellow Circle (Selected Indicator)
              Positioned(
                left: notchCenterX - (circleSize / 2),
                top: circleTop,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      _icons[currentIndex],
                      width: 24.w,
                      height: 24.w,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotchClipper extends CustomClipper<Path> {
  final double notchCenterX;
  final double notchCenterY;
  final double circleSize;

  _NotchClipper({
    required this.notchCenterX,
    required this.notchCenterY,
    required this.circleSize,
  });

  @override
  Path getClip(Size size) {
    final host = Rect.fromLTWH(0, 0, size.width, size.height);
    final guestWidth = circleSize + 12.w; // 6.w padding on all sides for the cutout
    final guest = Rect.fromCenter(
      center: Offset(notchCenterX, notchCenterY),
      width: guestWidth,
      height: guestWidth,
    );
    return const CircularNotchedRectangle().getOuterPath(host, guest);
  }

  @override
  bool shouldReclip(_NotchClipper oldClipper) {
    return oldClipper.notchCenterX != notchCenterX ||
        oldClipper.notchCenterY != notchCenterY ||
        oldClipper.circleSize != circleSize;
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
          colorFilter: const ColorFilter.mode(
            AppColors.lightCard,
            BlendMode.srcIn,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.lightCard,
              ),
        ),
      ],
    );
  }
}
