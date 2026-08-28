import 'package:equatable/equatable.dart';

/// Base failure class for domain-layer error handling.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Failure originating from a server/remote operation.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Failure originating from local cache/storage.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Failure during dataset synchronization.
class SyncFailure extends Failure {
  const SyncFailure(super.message);
}

/// Failure during routing/search.
class RoutingFailure extends Failure {
  const RoutingFailure(super.message);
}
