import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/local_history_data_source.dart';
import '../../../../features/route_search/domain/entities/routing_entities.dart';

class LocalHistoryRepositoryImpl implements HistoryRepository {
  final LocalHistoryDataSource _dataSource;
  static const int _maxHistoryEntries = 20;

  LocalHistoryRepositoryImpl(this._dataSource);

  @override
  Future<List<HistoryEntry>> getHistory() async {
    return await _dataSource.readHistory();
  }

  @override
  Future<void> saveHistoryEntry({
    required String originName,
    required String destName,
    required RouteResult routeResult,
  }) async {
    final entries = await _dataSource.readHistory();

    final id = _generateId(originName, destName);

    // Remove any existing entry with the same normalized origin/destination
    entries.removeWhere((entry) => entry.id == id);

    // Create the new entry
    final newEntry = HistoryEntry(
      id: id,
      originName: originName,
      destName: destName,
      searchedAt: DateTime.now(),
      routeResult: routeResult,
    );

    // Prepend to the top
    entries.insert(0, newEntry);

    // Enforce capacity limit
    if (entries.length > _maxHistoryEntries) {
      entries.removeLast();
    }

    // Save
    await _dataSource.writeHistory(entries);
  }

  String _generateId(String origin, String dest) {
    final normalizedOrigin = origin.trim().toLowerCase();
    final normalizedDest = dest.trim().toLowerCase();
    final bytes = utf8.encode('$normalizedOrigin|$normalizedDest');
    return sha256.convert(bytes).toString();
  }
}
