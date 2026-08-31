import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';

class RouteSummaryHeader extends StatelessWidget {
  final String originName;
  final String destName;

  const RouteSummaryHeader({
    super.key,
    required this.originName,
    required this.destName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 327.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceAlt, // #F8F2E6
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                originName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: SvgPicture.asset(
                'assets/icons/forward_arrow_icon.svg',
                width: 20.w,
                height: 20.h,
              ),
            ),
            Expanded(
              child: Text(
                destName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: SvgPicture.asset(
                'assets/icons/heart_outline.svg',
                width: 24.w,
                height: 24.h,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
