import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/saved_route.dart';
import '../../domain/usecases/get_saved_routes_usecase.dart';
import '../../domain/usecases/save_route_usecase.dart';
import '../../domain/usecases/remove_saved_route_usecase.dart';
import '../../../../features/route_search/domain/entities/routing_entities.dart';
import '../../domain/repositories/saved_route_repository.dart'; // Needed for generateRouteId

abstract class SavedRoutesState extends Equatable {
  const SavedRoutesState();

  @override
  List<Object?> get props => [];
}

class SavedRoutesInitial extends SavedRoutesState {}

class SavedRoutesLoading extends SavedRoutesState {}

class SavedRoutesLoaded extends SavedRoutesState {
  final List<SavedRoute> routes;

  const SavedRoutesLoaded(this.routes);

  @override
  List<Object?> get props => [routes];
}

class SavedRoutesError extends SavedRoutesState {
  final String message;

  const SavedRoutesError(this.message);

  @override
  List<Object?> get props => [message];
}

class SavedRoutesCubit extends Cubit<SavedRoutesState> {
  final GetSavedRoutesUseCase _getSavedRoutes;
  final SaveRouteUseCase _saveRoute;
  final RemoveSavedRouteUseCase _removeSavedRoute;
  final SavedRouteRepository _repository; // For ID generation

  SavedRoutesCubit(
    this._getSavedRoutes,
    this._saveRoute,
    this._removeSavedRoute,
    this._repository,
  ) : super(SavedRoutesInitial());

  Future<void> loadSavedRoutes() async {
    emit(SavedRoutesLoading());
    try {
      final routes = await _getSavedRoutes();
      emit(SavedRoutesLoaded(routes));
    } catch (e) {
      emit(const SavedRoutesError('Failed to load saved routes.'));
    }
  }

  Future<void> toggleSaveRoute({
    required String originName,
    required String destName,
    required RouteResult routeResult,
  }) async {
    final id = _repository.generateRouteId(originName, destName);
    final isSaved = await _repository.isRouteSaved(id);

    try {
      if (isSaved) {
        await _removeSavedRoute(id);
      } else {
        await _saveRoute(
          originName: originName,
          destName: destName,
          routeResult: routeResult,
        );
      }
      // Refresh the list
      await loadSavedRoutes();
    } catch (e) {
      emit(const SavedRoutesError('Failed to update saved route.'));
    }
  }

  bool isRouteSavedLocal(String originName, String destName) {
    if (state is SavedRoutesLoaded) {
      final id = _repository.generateRouteId(originName, destName);
      return (state as SavedRoutesLoaded).routes.any((r) => r.id == id);
    }
    return false;
  }
}
