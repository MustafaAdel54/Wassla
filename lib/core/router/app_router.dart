import 'package:go_router/go_router.dart';

import 'package:flutter/widgets.dart';

import '../../features/route_details/presentation/pages/route_details_page.dart';
import '../../features/route_search/domain/entities/routing_entities.dart';
import '../../features/route_search/presentation/cubit/autocomplete_cubit.dart';
import '../../features/route_search/presentation/pages/route_search_page.dart';

class AppRouter {
  // Route Constants
  static const String home = '/';
  static const String search = '/search';
  static const String details = '/details';
  static const String history = '/history';
  static const String saved = '/saved';
  static const String profile = '/profile';

  static GoRouter createRouter({
    required WidgetBuilder bootstrapBuilder,
    required AutocompleteCubit fromAutocompleteCubit,
    required AutocompleteCubit toAutocompleteCubit,
  }) {
    return GoRouter(
      initialLocation: home,
      routes: [
        GoRoute(
          path: home,
          builder: (context, state) => bootstrapBuilder(context),
        ),
        GoRoute(
          path: search,
          builder: (context, state) => RouteSearchPage(
            fromCubit: fromAutocompleteCubit,
            toCubit: toAutocompleteCubit,
          ),
        ),
        GoRoute(
          path: details,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return RouteDetailsPage(
              routeResult: extra['result'] as RouteResult,
              originName: extra['origin'] as String,
              destName: extra['dest'] as String,
            );
          },
        ),
      ],
    );
  }
}
