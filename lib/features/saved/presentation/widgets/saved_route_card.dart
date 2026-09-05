import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/saved_route.dart';
import 'package:intl/intl.dart';

class SavedRouteCard extends StatelessWidget {
  final SavedRoute entry;

  const SavedRouteCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final route = entry.routeResult;
    final cost = route.estimatedFare ?? 0.0;
    final duration = route.durationMinutes;
    final startTime = DateFormat('h:mma').format(DateTime.now()); // Using now for display as it's a historical route

    return GestureDetector(
      onTap: () {
        context.push(
          AppRouter.details,
          extra: {
            'result': entry.routeResult,
            'origin': entry.originName,
            'dest': entry.destName,
          },
        );
      },
      child: Container(
        width: 332.w,
        height: 70.h,
        padding: EdgeInsets.fromLTRB(9.w, 13.h, 5.w, 13.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: AppColors.lightBorder, width: 1),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Heart Icon Circle
            Container(
              width: 44.w,
              height: 44.h,
              decoration: const BoxDecoration(
                color: AppColors.warningLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/favourite_icon.svg',
                  width: 24.w,
                  height: 24.h,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // Text Column
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.originName} \u2192 ${entry.destName}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black, // #000000 in Figma
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '$startTime . ${duration}min . ${cost}EGP',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12.sp,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Arrow out
            SvgPicture.asset(
              'assets/icons/arrow_outward_icon.svg',
              width: 16.w,
              height: 16.h,
            ),
          ],
        ),
      ),
    );
  }
}
