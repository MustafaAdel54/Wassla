import '../entities/sync_entities.dart';
import '../repositories/dataset_sync_repository.dart';

/// Use case: Synchronize the local dataset with the remote Firebase dataset.
/// Used at startup (async, non-blocking for existing installs).
class SyncDatasetUseCase {
  final DatasetSyncRepository repository;

  const SyncDatasetUseCase(this.repository);

  Future<SyncResult> execute() => repository.sync();
}
