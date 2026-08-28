import 'package:equatable/equatable.dart';

/// Status of a dataset synchronization operation.
enum SyncStatusType { noChanges, updated, initialDownload, failed }

/// Result of a dataset synchronization operation.
class SyncResult extends Equatable {
  final SyncStatusType status;
  final bool routingDataChanged;
  final int collectionsDownloaded;
  final String? errorMessage;

  const SyncResult({
    required this.status,
    this.routingDataChanged = false,
    this.collectionsDownloaded = 0,
    this.errorMessage,
  });

  const SyncResult.noChanges()
      : status = SyncStatusType.noChanges,
        routingDataChanged = false,
        collectionsDownloaded = 0,
        errorMessage = null;

  const SyncResult.failed(String message)
      : status = SyncStatusType.failed,
        routingDataChanged = false,
        collectionsDownloaded = 0,
        errorMessage = message;

  @override
  List<Object?> get props =>
      [status, routingDataChanged, collectionsDownloaded, errorMessage];
}

/// Metadata about the remote dataset manifest.
class DatasetManifest extends Equatable {
  final int datasetVersion;
  final int schemaVersion;
  final DateTime updatedAt;
  final DateTime? generatedAt;
  final Map<String, CollectionMetadata> collections;

  const DatasetManifest({
    required this.datasetVersion,
    required this.schemaVersion,
    required this.updatedAt,
    this.generatedAt,
    required this.collections,
  });

  @override
  List<Object?> get props =>
      [datasetVersion, schemaVersion, updatedAt, generatedAt, collections];
}

/// Metadata about a single collection within the dataset.
class CollectionMetadata extends Equatable {
  final int count;
  final String contentHash;
  final String storage; // "firestore" or "cloud_storage"
  final String? storagePath; // Cloud Storage path, if applicable
  final int? sizeBytes;

  const CollectionMetadata({
    required this.count,
    required this.contentHash,
    required this.storage,
    this.storagePath,
    this.sizeBytes,
  });

  @override
  List<Object?> get props =>
      [count, contentHash, storage, storagePath, sizeBytes];
}
