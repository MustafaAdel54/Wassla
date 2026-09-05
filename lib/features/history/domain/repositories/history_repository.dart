import '../entities/history_entry.dart';
import '../../../../features/route_search/domain/entities/routing_entities.dart';

abstract class HistoryRepository {
  /// Loads all history entries from local storage.
  Future<List<HistoryEntry>> getHistory();

  /// Saves a new history entry.
  /// Enforces duplicate policy and maximum capacity.
  Future<void> saveHistoryEntry({
    required String originName,
    required String destName,
    required RouteResult routeResult,
  });
}
