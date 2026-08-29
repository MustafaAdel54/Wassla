import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wassla/features/dataset_sync/domain/entities/sync_entities.dart';
import 'package:wassla/features/dataset_sync/domain/usecases/sync_dataset_usecase.dart';
import 'package:wassla/features/dataset_sync/domain/usecases/publish_dataset_usecase.dart';

// --- State ---

abstract class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {
  const SyncInitial();
}

class SyncChecking extends SyncState {
  const SyncChecking();
}

class SyncDownloading extends SyncState {
  const SyncDownloading();
}

class SyncComplete extends SyncState {
  final SyncResult result;
  const SyncComplete(this.result);
  @override
  List<Object?> get props => [result];
}

class SyncError extends SyncState {
  final String message;
  const SyncError(this.message);
  @override
  List<Object?> get props => [message];
}

class PublishInProgress extends SyncState {
  final String message;
  const PublishInProgress(this.message);
  @override
  List<Object?> get props => [message];
}

class PublishComplete extends SyncState {
  const PublishComplete();
}

class PublishError extends SyncState {
  final String message;
  const PublishError(this.message);
  @override
  List<Object?> get props => [message];
}

// --- Cubit ---

class SyncCubit extends Cubit<SyncState> {
  final SyncDatasetUseCase _syncDatasetUseCase;
  final PublishDatasetUseCase? _publishDatasetUseCase;

  SyncCubit(
    this._syncDatasetUseCase, {
    PublishDatasetUseCase? publishDatasetUseCase,
    // ignore: prefer_initializing_formals
  })  : _publishDatasetUseCase = publishDatasetUseCase,
        super(const SyncInitial());

  /// Trigger an incremental sync.
  Future<SyncResult> syncDataset() async {
    emit(const SyncChecking());
    try {
      final result = await _syncDatasetUseCase.execute();
      emit(SyncComplete(result));
      return result;
    } catch (e) {
      final message = 'Sync failed: $e';
      emit(SyncError(message));
      return SyncResult.failed(message);
    }
  }

  /// Trigger the developer import (publish dataset to Firebase).
  Future<void> publishDataset() async {
    if (_publishDatasetUseCase == null) {
      emit(const PublishError('Publish use case not available'));
      return;
    }
    emit(const PublishInProgress('Starting dataset publish...'));
    try {
      await _publishDatasetUseCase.execute();
      emit(const PublishComplete());
    } catch (e) {
      emit(PublishError('Publish failed: $e'));
    }
  }
}
