import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../route_search/domain/entities/routing_entities.dart';

class TimelineSegmentItem extends StatelessWidget {
  final RouteSegment segment;
  final bool isLast;

  const TimelineSegmentItem({
    super.key,
    required this.segment,
    this.isLast = false,
  });

  String _getIconAsset() {
    switch (segment.mode.toLowerCase()) {
      case 'metro':
        return 'assets/icons/mode_metro.svg';
      case 'bus':
      case 'microbus':
      case 'minibus':
        return 'assets/icons/mode_bus.svg';
      case 'walking':
      default:
        return 'assets/icons/mode_walk.svg';
    }
  }
  String formatPlaceName(String name) {
    final words = name.trim().split(RegExp(r'\s+'));

    if (words.length <= 2) {
      return name.trim();
    }

    return '${words.take(2).join(' ')}\n${words.skip(2).join(' ')}';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: Icon and connecting line
          SizedBox(
            width: 44.w,
            child: Column(
              children: [
                Container(
                  width: 44.w,
                  height: 44.h,
                  decoration: const BoxDecoration(
                    color: AppColors.lightSurfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    _getIconAsset(),
                    width: 24.w,
                    height: 24.h,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.w,
                      color: AppColors.lightTextSecondary,
                      margin: EdgeInsets.symmetric(vertical: 4.h),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 20.w),
          // Right side: Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode and Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      segment.mode.toUpperCase()[0] + segment.mode.substring(1),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '${segment.durationMinutes} Min',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.warningDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                // Origin and Destination (fromName -> toName)
                Row(
                  children: [
                    Text(
                    formatPlaceName(segment.fromName),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.lightTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: SvgPicture.asset(
                        'assets/icons/forward_arrow_icon.svg',
                        width: 16.h,
                        height: 16.h,
                        // Arrow should point right, use Transform.flip if it's naturally back
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatPlaceName(segment.toName),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.lightTextPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                // Alighting detail pin
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: SvgPicture.asset(
                        'assets/icons/pin_small.svg',
                        width: 8.w,
                        height: 10.h,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        'Get off at ${segment.toName}',
                        style: AppTypography.smallDetail.copyWith(
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLast) SizedBox(height: 32.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
