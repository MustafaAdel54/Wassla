import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/history/presentation/pages/history_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/route_details/presentation/pages/route_details_page.dart';
import '../../features/route_search/domain/entities/routing_entities.dart';
import '../../features/route_search/presentation/cubit/autocomplete_cubit.dart';
import '../../features/route_search/presentation/pages/route_search_page.dart';
import '../../features/saved/presentation/pages/saved_page.dart';
import '../../shared/widgets/scaffold_with_bottom_nav.dart';

class AppRouter {
  // Route Constants
  static const String bootstrap = '/';
  static const String home = '/home';
  static const String search = '/search'; // No longer used directly as main tab, but keeping if needed or redirecting
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
      initialLocation: bootstrap,
      routes: [
        GoRoute(
          path: bootstrap,
          builder: (context, state) => bootstrapBuilder(context),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ScaffoldWithBottomNav(navigationShell: navigationShell);
          },
          branches: [
            // Branch 0: Home / Route Search
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: home,
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
            ),
            // Branch 1: History
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: history,
                  builder: (context, state) => const HistoryPage(),
                ),
              ],
            ),
            // Branch 2: Saved
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: saved,
                  builder: (context, state) => const SavedPage(),
                ),
              ],
            ),
            // Branch 3: Profile
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: profile,
                  builder: (context, state) => const ProfilePage(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
