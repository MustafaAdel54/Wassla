import '../entities/history_entry.dart';
import '../repositories/history_repository.dart';

class GetHistoryUseCase {
  final HistoryRepository _repository;

  GetHistoryUseCase(this._repository);

  Future<List<HistoryEntry>> execute() async {
    return await _repository.getHistory();
  }
}
