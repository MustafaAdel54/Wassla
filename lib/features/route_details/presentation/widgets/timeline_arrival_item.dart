import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';

class TimelineArrivalItem extends StatelessWidget {
  final String destName;

  const TimelineArrivalItem({
    super.key,
    required this.destName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44.w,
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/timeline_flag.svg',
              width: 24.w,
              height: 24.h,
            ),
          ),
        ),
        SizedBox(width: 20.w),
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) {
              return const LinearGradient(
                colors: [AppColors.darkBackgroundAlt, AppColors.warningDark, Colors.black],
                stops: [0.13, 0.50, 0.79],
              ).createShader(bounds);
            },
            child: Text(
              'Arrived At $destName',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
