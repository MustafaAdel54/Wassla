import 'package:equatable/equatable.dart';
import '../../../../features/route_search/domain/entities/routing_entities.dart';

class SavedRoute extends Equatable {
  final String id;
  final String originName;
  final String destName;
  final RouteResult routeResult;
  final DateTime savedAt;
  final String? userId; // For future Firebase ownership

  const SavedRoute({
    required this.id,
    required this.originName,
    required this.destName,
    required this.routeResult,
    required this.savedAt,
    this.userId,
  });

  @override
  List<Object?> get props => [
        id,
        originName,
        destName,
        routeResult,
        savedAt,
        userId,
      ];
}
