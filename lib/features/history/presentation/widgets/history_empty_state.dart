import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_colors.dart';

class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64.w,
              color: AppColors.lightBorder,
            ),
            SizedBox(height: 16.h),
            Text(
              'No history yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your past route searches will appear here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightTextMuted,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
