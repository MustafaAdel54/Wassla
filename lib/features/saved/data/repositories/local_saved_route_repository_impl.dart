import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../domain/entities/saved_route.dart';
import '../../domain/repositories/saved_route_repository.dart';
import '../datasources/local_saved_route_data_source.dart';
import '../../../../features/route_search/domain/entities/routing_entities.dart';

class LocalSavedRouteRepositoryImpl implements SavedRouteRepository {
  final LocalSavedRouteDataSource dataSource;
  static const int _maxSavedRoutes = 20;

  LocalSavedRouteRepositoryImpl(this.dataSource);

  @override
  String generateRouteId(String originName, String destName) {
    // Deterministic identity: normalized origin + normalized destination
    final normalizedOrigin = originName.trim().toLowerCase();
    final normalizedDest = destName.trim().toLowerCase();
    final combined = '${normalizedOrigin}_$normalizedDest';
    return sha256.convert(utf8.encode(combined)).toString();
  }

  @override
  Future<List<SavedRoute>> getSavedRoutes() async {
    return dataSource.readSavedRoutes();
  }

  @override
  Future<void> saveRoute({
    required String originName,
    required String destName,
    required RouteResult routeResult,
    String? userId,
  }) async {
    final routes = await dataSource.readSavedRoutes();
    final id = generateRouteId(originName, destName);

    // Remove if already exists (duplicate policy)
    routes.removeWhere((entry) => entry.id == id);

    // Create new entry
    final newEntry = SavedRoute(
      id: id,
      originName: originName,
      destName: destName,
      routeResult: routeResult,
      savedAt: DateTime.now().toUtc(),
      userId: userId,
    );

    // Prepend to top
    routes.insert(0, newEntry);

    // Enforce capacity limit
    if (routes.length > _maxSavedRoutes) {
      routes.removeRange(_maxSavedRoutes, routes.length);
    }

    await dataSource.writeSavedRoutes(routes);
  }

  @override
  Future<void> removeSavedRoute(String id) async {
    final routes = await dataSource.readSavedRoutes();
    final initialLength = routes.length;
    routes.removeWhere((entry) => entry.id == id);
    if (routes.length != initialLength) {
      await dataSource.writeSavedRoutes(routes);
    }
  }

  @override
  Future<bool> isRouteSaved(String id) async {
    final routes = await dataSource.readSavedRoutes();
    return routes.any((entry) => entry.id == id);
  }
}
