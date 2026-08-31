import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../route_search/domain/entities/routing_entities.dart';
import 'timeline_segment_item.dart';
import 'timeline_arrival_item.dart';
import 'search_another_place_button.dart';

class RouteTimelineCard extends StatelessWidget {
  final RouteResult routeResult;

  const RouteTimelineCard({
    super.key,
    required this.routeResult,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Duration Header
        Row(
          children: [
            SvgPicture.asset(
              'assets/icons/route_clock.svg',
              width: 24.w,
              height: 24.h,
            ),
            SizedBox(width: 10.w),
            Text(
              '${routeResult.durationMinutes} Minutes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        // Timeline Card
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: AppColors.lightTextSecondary, width: 1.w),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top summary
              Padding(
                padding: EdgeInsets.only(left: 26.w, right: 16.w, top: 14.h, bottom: 14.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${routeResult.transfers} Transfers',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    if (routeResult.estimatedFare != null && routeResult.estimatedFare! > 0)
                      Text(
                        '~ ${routeResult.estimatedFare!.round()} EGP',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.warningDark,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Timeline Content
              Padding(
                padding: EdgeInsets.only(left: 6.w, right: 6.w, bottom: 24.h),
                child: Column(
                  children: [
                    // Segments
                    if (routeResult.segments.isNotEmpty)
                      ...routeResult.segments.asMap().entries.map((entry) {
                        final index = entry.key;
                        final segment = entry.value;
                        return TimelineSegmentItem(
                          segment: segment,
                          isLast: false,
                        );
                      }),
                    
                    // Arrival
                    if (routeResult.segments.isNotEmpty)
                      TimelineArrivalItem(
                        destName: routeResult.segments.last.toName,
                      ),
                    
                    SizedBox(height: 32.h),
                    
                    // Bottom Button
                    const SearchAnotherPlaceButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
