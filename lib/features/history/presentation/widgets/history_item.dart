import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/history_entry.dart';

class HistoryItem extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;

  const HistoryItem({
    super.key,
    required this.entry,
    required this.onTap,
  });

  String _getPrimaryMode() {
    // If the route has any non-walking segment, use the first one
    final transportSegment = entry.routeResult.segments.firstWhere(
      (s) => s.mode != 'walking',
      orElse: () => entry.routeResult.segments.first,
    );
    return transportSegment.mode;
  }

  String _getModeIconAsset(String mode) {
    switch (mode) {
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

  String _formatTime(DateTime time) {
    String period = time.hour >= 12 ? 'PM' : 'AM';
    int h = time.hour > 12 ? time.hour - 12 : time.hour;
    if (h == 0) h = 12;
    String m = time.minute.toString().padLeft(2, '0');
    return '$h:$m$period';
  }

  @override
  Widget build(BuildContext context) {
    final mode = _getPrimaryMode();
    final iconAsset = _getModeIconAsset(mode);
    final fareStr = entry.routeResult.estimatedFare != null
        ? ' . ${entry.routeResult.estimatedFare!.toInt()}EGP'
        : '';
    final metaStr = '${_formatTime(entry.searchedAt)} . ${entry.routeResult.durationMinutes}min$fareStr';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h), // small hit area padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(
                color: AppColors.lightSurfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconAsset,
                  width: 16.w,
                  height: 16.w,
                  colorFilter: const ColorFilter.mode(
                    AppColors.lightTransferModeIcon,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.originName} → ${entry.destName}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightTextPrimary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    metaStr,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.lightTextSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            SvgPicture.asset(
              'assets/icons/forward_arrow_icon.svg',
              width: 24.w,
              height: 24.w,
              colorFilter: const ColorFilter.mode(
                AppColors.lightTextPrimary,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
