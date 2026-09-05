import '../repositories/history_repository.dart';
import '../../../../features/route_search/domain/entities/routing_entities.dart';

class SaveHistoryEntryUseCase {
  final HistoryRepository _repository;

  SaveHistoryEntryUseCase(this._repository);

  Future<void> execute({
    required String originName,
    required String destName,
    required RouteResult routeResult,
  }) async {
    await _repository.saveHistoryEntry(
      originName: originName,
      destName: destName,
      routeResult: routeResult,
    );
  }
}
