import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/history_entry.dart';
import '../../domain/usecases/get_history_usecase.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<HistoryEntry> entries;
  const HistoryLoaded(this.entries);
  @override
  List<Object?> get props => [entries];
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);
  @override
  List<Object?> get props => [message];
}

class HistoryCubit extends Cubit<HistoryState> {
  final GetHistoryUseCase _getHistoryUseCase;

  HistoryCubit(this._getHistoryUseCase) : super(HistoryInitial());

  Future<void> loadHistory() async {
    emit(HistoryLoading());
    try {
      final entries = await _getHistoryUseCase.execute();
      emit(HistoryLoaded(entries));
    } catch (e) {
      emit(HistoryError('Failed to load history: $e'));
    }
  }
}
