import '../entities/sync_entities.dart';

/// Domain interface for incremental dataset synchronization.
/// Compares remote manifest with local manifest and downloads only changes.
abstract interface class DatasetSyncRepository {
  /// Perform an incremental sync.
  /// Returns a SyncResult indicating what happened.
  Future<SyncResult> sync();

  /// Whether a local dataset exists on this device.
  Future<bool> hasLocalDataset();
}
