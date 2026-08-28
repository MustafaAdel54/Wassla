import '../repositories/dataset_publish_repository.dart';

/// Use case: Publish the bundled dataset to Firebase.
/// Development/admin action only — behind kEnableDevImport flag.
class PublishDatasetUseCase {
  final DatasetPublishRepository repository;

  const PublishDatasetUseCase(this.repository);

  Future<void> execute() => repository.publishToFirebase();
}
