import '../../domain/entities/history_entry.dart';
import '../../../../features/route_search/domain/entities/routing_entities.dart';

class HistoryEntryDto {
  static Map<String, dynamic> toJson(HistoryEntry entry) {
    return {
      'id': entry.id,
      'originName': entry.originName,
      'destName': entry.destName,
      'searchedAt': entry.searchedAt.toIso8601String(),
      'routeResult': _routeResultToJson(entry.routeResult),
    };
  }

  static HistoryEntry fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String,
      originName: json['originName'] as String,
      destName: json['destName'] as String,
      searchedAt: DateTime.parse(json['searchedAt'] as String),
      routeResult: _routeResultFromJson(json['routeResult'] as Map<String, dynamic>),
    );
  }

  static Map<String, dynamic> _routeResultToJson(RouteResult result) {
    return {
      'durationMinutes': result.durationMinutes,
      'walkingMinutes': result.walkingMinutes,
      'transfers': result.transfers,
      'estimatedFare': result.estimatedFare,
      'segments': result.segments.map((s) => _routeSegmentToJson(s)).toList(),
    };
  }

  static RouteResult _routeResultFromJson(Map<String, dynamic> json) {
    return RouteResult(
      durationMinutes: json['durationMinutes'] as int,
      walkingMinutes: json['walkingMinutes'] as int,
      transfers: json['transfers'] as int,
      estimatedFare: json['estimatedFare'] != null ? (json['estimatedFare'] as num).toDouble() : null,
      segments: (json['segments'] as List).map((s) => _routeSegmentFromJson(s as Map<String, dynamic>)).toList(),
    );
  }

  static Map<String, dynamic> _routeSegmentToJson(RouteSegment segment) {
    return {
      'mode': segment.mode,
      'routeId': segment.routeId,
      'routeName': segment.routeName,
      'fromName': segment.fromName,
      'toName': segment.toName,
      'durationMinutes': segment.durationMinutes,
    };
  }

  static RouteSegment _routeSegmentFromJson(Map<String, dynamic> json) {
    return RouteSegment(
      mode: json['mode'] as String,
      routeId: json['routeId'] as String?,
      routeName: json['routeName'] as String?,
      fromName: json['fromName'] as String,
      toName: json['toName'] as String,
      durationMinutes: json['durationMinutes'] as int,
    );
  }
}
