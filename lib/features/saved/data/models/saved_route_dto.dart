import '../../domain/entities/saved_route.dart';
import '../../../../features/route_search/domain/entities/routing_entities.dart';

class SavedRouteDto {
  static Map<String, dynamic> toJson(SavedRoute route) {
    return {
      'id': route.id,
      'originName': route.originName,
      'destName': route.destName,
      'routeResult': _routeResultToJson(route.routeResult),
      'savedAt': route.savedAt.toIso8601String(),
      'userId': route.userId,
    };
  }

  static SavedRoute fromJson(Map<String, dynamic> json) {
    return SavedRoute(
      id: json['id'] as String,
      originName: json['originName'] as String,
      destName: json['destName'] as String,
      routeResult: _routeResultFromJson(json['routeResult'] as Map<String, dynamic>),
      savedAt: DateTime.parse(json['savedAt'] as String),
      userId: json['userId'] as String?,
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
