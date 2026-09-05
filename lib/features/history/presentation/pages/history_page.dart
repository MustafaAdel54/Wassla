import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/history_cubit.dart';
import '../widgets/history_empty_state.dart';
import '../widgets/history_list.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryCubit>().loadHistory();
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
          onPressed: () {
            context.go(AppRouter.home);
          },
        ),
        title: Text(
          'History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.lightTextPrimary,
              ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading || state is HistoryInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HistoryError) {
            return Center(child: Text(state.message));
          } else if (state is HistoryLoaded) {
            if (state.entries.isEmpty) {
              return const HistoryEmptyState();
            }
            return HistoryList(
              entries: state.entries,
              onItemTap: (entry) {
                context.push(
                  AppRouter.details,
                  extra: {
                    'result': entry.routeResult,
                    'origin': entry.originName,
                    'dest': entry.destName,
                  },
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
