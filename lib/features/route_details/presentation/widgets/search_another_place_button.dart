import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class SearchAnotherPlaceButton extends StatelessWidget {
  const SearchAnotherPlaceButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          side: BorderSide(color: AppColors.darkBackgroundAlt, width: 1.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
        ),
        child: Text(
          'Search another place',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }
}
