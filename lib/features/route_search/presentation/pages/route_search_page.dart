import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/constants/sync_constants.dart';
import '../../../dataset_sync/presentation/cubit/sync_cubit.dart';
import '../../domain/entities/routing_entities.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../cubit/autocomplete_cubit.dart';
import '../cubit/route_search_cubit.dart';
import '../widgets/dev_tools_dialog.dart';
import '../widgets/route_search_form.dart';
import '../widgets/route_search_result_card.dart';
import '../../../route_details/presentation/pages/route_details_page.dart';

/// Simple functional route search page for data/routing validation.
/// Final visual design will be implemented later.
class RouteSearchPage extends StatefulWidget {
  final AutocompleteCubit fromCubit;
  final AutocompleteCubit toCubit;

  const RouteSearchPage({
    super.key,
    required this.fromCubit,
    required this.toCubit,
  });

  @override
  State<RouteSearchPage> createState() => _RouteSearchPageState();
}

class _RouteSearchPageState extends State<RouteSearchPage> {
  // Only used when NOT using Stop IDs
  final _originLatCtrl = TextEditingController();
  final _originLngCtrl = TextEditingController();
  final _destLatCtrl = TextEditingController();
  final _destLngCtrl = TextEditingController();

  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();

  final _originFocusNode = FocusNode();
  final _destFocusNode = FocusNode();

  bool _useStopIds = true;

  @override
  void initState() {
    super.initState();
    _originCtrl.addListener(() {
      widget.fromCubit.onQueryChanged(_originCtrl.text);
    });
    _destCtrl.addListener(() {
      widget.toCubit.onQueryChanged(_destCtrl.text);
    });
    _originFocusNode.addListener(() {
      if (!_originFocusNode.hasFocus) widget.fromCubit.onFocusLost();
    });
    _destFocusNode.addListener(() {
      if (!_destFocusNode.hasFocus) widget.toCubit.onFocusLost();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? AppColors.lightBackgroundAlt : null,
      appBar: AppBar(
        toolbarHeight: kEnableDevImport ? kToolbarHeight : 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (kEnableDevImport)
            IconButton(
              icon: const Icon(Icons.developer_board),
              tooltip: 'Developer Tools',
              onPressed: () {
                final syncCubit = context.read<SyncCubit>();
                showDialog(
                  context: context,
                  builder: (ctx) => BlocProvider.value(
                    value: syncCubit,
                    child: const DevToolsDialog(),
                  ),
                );
              },
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: RouteSearchForm(
                originCtrl: _originCtrl,
                destCtrl: _destCtrl,
                originFocusNode: _originFocusNode,
                destFocusNode: _destFocusNode,
                fromCubit: widget.fromCubit,
                toCubit: widget.toCubit,
                onSearch: _search,
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: BlocConsumer<RouteSearchCubit, RouteSearchState>(
                listener: (context, state) {
                  if (state is RouteSearchSuccess) {
                    final originName = widget.fromCubit.state.selectedPlace?.name ?? _originCtrl.text;
                    final destName = widget.toCubit.state.selectedPlace?.name ?? _destCtrl.text;
                    context.push(
                      AppRouter.details,
                      extra: {
                        'result': state.result,
                        'origin': originName,
                        'dest': destName,
                      },
                    );
                  }
                },
                builder: (context, state) {
                  if (state is EngineInitializing) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: 16.h),
                          const Text('Building routing graph...'),
                        ],
                      ),
                    );
                  }
                  if (state is RouteSearchLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is RouteSearchNoResult) {
                    return Center(
                      child: Text(
                        'No route found',
                        style: TextStyle(fontSize: 18.sp),
                      ),
                    );
                  }
                  if (state is RouteSearchError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  // For RouteSearchSuccess, we navigate away, so just show empty
                  return const SizedBox.shrink(); 
                },
              ),
            ),
          ),
          SliverPadding(padding: EdgeInsets.only(bottom: 16.h)),
        ],
      ),
    );
  }

  void _search() {
    final cubit = context.read<RouteSearchCubit>();

    final originName = widget.fromCubit.state.selectedPlace?.name ?? _originCtrl.text.trim();
    final destName = widget.toCubit.state.selectedPlace?.name ?? _destCtrl.text.trim();

    if (originName.isEmpty || destName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter origin and destination')),
        );
        return;
    }

    if (_useStopIds) {
      final originPlace = widget.fromCubit.state.selectedPlace;
      final destPlace = widget.toCubit.state.selectedPlace;
      if (originPlace == null || destPlace == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select valid places from the suggestions')),
        );
        return;
      }
      cubit.searchByStopIds(originPlace.id, destPlace.id, originName, destName);
      return;
    }

    final originLat = double.tryParse(_originLatCtrl.text);
    final originLng = double.tryParse(_originLngCtrl.text);
    final destLat = double.tryParse(_destLatCtrl.text);
    final destLng = double.tryParse(_destLngCtrl.text);

    if (originLat == null ||
        originLng == null ||
        destLat == null ||
        destLng == null) {
      return;
    }

    cubit.searchRoute(
      RouteRequest(
        origin: LocationPoint(latitude: originLat, longitude: originLng),
        destination: LocationPoint(latitude: destLat, longitude: destLng),
      ),
      originName,
      destName,
    );
  }

  @override
  void dispose() {
    _originLatCtrl.dispose();
    _originLngCtrl.dispose();
    _destLatCtrl.dispose();
    _destLngCtrl.dispose();
    _originCtrl.dispose();
    _destCtrl.dispose();
    _originFocusNode.dispose();
    _destFocusNode.dispose();
    super.dispose();
  }
}

