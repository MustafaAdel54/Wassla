import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wassla/features/route_search/domain/entities/routing_entities.dart';
import 'package:wassla/features/route_search/domain/repositories/routing_service.dart';
import 'package:wassla/features/route_search/domain/usecases/search_route_usecase.dart';

// --- State ---

abstract class RouteSearchState extends Equatable {
  const RouteSearchState();
  @override
  List<Object?> get props => [];
}

class RouteSearchInitial extends RouteSearchState {
  const RouteSearchInitial();
}

class RouteSearchLoading extends RouteSearchState {
  const RouteSearchLoading();
}

class EngineInitializing extends RouteSearchState {
  const EngineInitializing();
}

class RouteSearchSuccess extends RouteSearchState {
  final RouteResult result;
  const RouteSearchSuccess(this.result);
  @override
  List<Object?> get props => [result];
}

class RouteSearchNoResult extends RouteSearchState {
  const RouteSearchNoResult();
}

class RouteSearchError extends RouteSearchState {
  final String message;
  const RouteSearchError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- Cubit ---

class RouteSearchCubit extends Cubit<RouteSearchState> {
  final SearchRouteUseCase _searchRouteUseCase;
  final RoutingService _routingService;

  RouteSearchCubit(this._searchRouteUseCase, this._routingService)
      : super(const RouteSearchInitial());

  /// Initialize the routing engine.
  Future<void> initializeEngine() async {
    if (_routingService.isInitialized) return;
    emit(const EngineInitializing());
    try {
      await _routingService.initialize();
      emit(const RouteSearchInitial());
    } catch (e) {
      emit(RouteSearchError('Failed to initialize routing engine: $e'));
    }
  }

  /// Search for a route between two geographic points.
  Future<void> searchRoute(RouteRequest request) async {
    emit(const RouteSearchLoading());
    try {
      // Ensure engine is ready
      if (!_routingService.isInitialized) {
        await _routingService.initialize();
      }

      final result = await _searchRouteUseCase.execute(request);
      if (result == null) {
        emit(const RouteSearchNoResult());
      } else {
        emit(RouteSearchSuccess(result));
      }
    } catch (e) {
      emit(RouteSearchError('Route search failed: $e'));
    }
  }

  /// Search for a route between two stop/station IDs.
  Future<void> searchByStopIds(
    String originStopId,
    String destinationStopId,
  ) async {
    emit(const RouteSearchLoading());
    try {
      if (!_routingService.isInitialized) {
        emit(const EngineInitializing());
        await _routingService.initialize();
      }

      final result = await _routingService.findRouteByStopIds(
        originStopId,
        destinationStopId,
      );
      if (result == null) {
        emit(const RouteSearchNoResult());
      } else {
        emit(RouteSearchSuccess(result));
      }
    } catch (e) {
      emit(RouteSearchError('Route search failed: $e'));
    }
  }

  /// Notify the cubit that routing data was updated (sync happened).
  /// Forces engine re-initialization on next search.
  void onRoutingDataUpdated() {
    _routingService.invalidate();
    if (state is RouteSearchSuccess) {
      emit(const RouteSearchInitial());
    }
  }
}
