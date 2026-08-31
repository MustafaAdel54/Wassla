import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/wassla_bottom_nav.dart';
import '../../../route_search/domain/entities/routing_entities.dart';

import '../widgets/route_summary_header.dart';
import '../widgets/route_timeline_card.dart';

class RouteDetailsPage extends StatelessWidget {
  final RouteResult routeResult;
  final String originName;
  final String destName;

  const RouteDetailsPage({
    super.key,
    required this.routeResult,
    required this.originName,
    required this.destName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackgroundAlt,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 60.w,
        leading: IconButton(
          icon: SvgPicture.asset('assets/icons/route_back_arrow.svg'),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Route Options',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.darkBackground,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: const WasslaBottomNav(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: AppSpacing.md.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RouteSummaryHeader(
                    originName: originName,
                    destName: destName,
                  ),
                  SizedBox(height: 24.h),
                  RouteTimelineCard(routeResult: routeResult),
                ],
              ),
            ),
          ),
          SliverPadding(padding: EdgeInsets.only(bottom: 24.h)),
        ],
      ),
    );
  }
}
