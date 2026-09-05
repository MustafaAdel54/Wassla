import 'package:equatable/equatable.dart';

import '../../../../features/route_search/domain/entities/routing_entities.dart';

class HistoryEntry extends Equatable {
  final String id;
  final String originName;
  final String destName;
  final DateTime searchedAt;
  final RouteResult routeResult;

  const HistoryEntry({
    required this.id,
    required this.originName,
    required this.destName,
    required this.searchedAt,
    required this.routeResult,
  });

  @override
  List<Object?> get props => [
        id,
        originName,
        destName,
        searchedAt,
        routeResult,
      ];
}
