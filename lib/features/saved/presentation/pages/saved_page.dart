import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/saved_routes_cubit.dart';
import '../widgets/saved_route_card.dart';

import 'package:flutter_svg/flutter_svg.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  @override
  void initState() {
    super.initState();
    context.read<SavedRoutesCubit>().loadSavedRoutes();
  }

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
          onPressed: () => context.go(AppRouter.home),
        ),
        title: Text(
          'Saved Routes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.lightTextPrimary,
                fontWeight: FontWeight.w500,
              ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<SavedRoutesCubit, SavedRoutesState>(
        builder: (context, state) {
          if (state is SavedRoutesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SavedRoutesLoaded) {
            final routes = state.routes;
            if (routes.isEmpty) {
              return const Center(child: Text('No saved routes yet.'));
            }
            return ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: (MediaQuery.of(context).size.width - 332.w) / 2, // Centered 332.w cards
                vertical: AppSpacing.md.h,
              ),
              itemCount: routes.length,
              separatorBuilder: (context, index) => SizedBox(height: 20.h),
              itemBuilder: (context, index) {
                final route = routes[index];
                return SavedRouteCard(entry: route);
              },
            );
          } else if (state is SavedRoutesError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
